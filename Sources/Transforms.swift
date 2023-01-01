//
//  Transforms.swift
//  Euclid
//
//  Created by Nick Lockwood on 03/07/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/Euclid
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

/// Protocol for transformable types.
public protocol Transformable {
    /// Returns a rotated copy of the value.
    /// - Parameter rotation: A rotation to apply to the value.
    func rotated(by rotation: Rotation) -> Self

    /// Returns a translated copy of the value.
    /// - Parameter offset: An offset vector to apply to the value.
    func translated(by offset: Vector) -> Self

    /// Returns a scaled copy of the value.
    /// - Parameter scale: A scale vector to apply to the value.
    func scaled(by scale: Vector) -> Self

    /// Returns a scaled copy of the value.
    /// - Parameter factor: A uniform scale factor to apply to the value.
    func scaled(by factor: Double) -> Self

    /// Returns a transformed copy of the value.
    /// - Parameter t: A transform to apply to the value.
    func transformed(by transform: Transform) -> Self
}

public extension Transformable {
    func transformed(by transform: Transform) -> Self {
        scaled(by: transform.scale)
            .rotated(by: transform.rotation)
            .translated(by: transform.offset)
    }

    /// Rotate the value in place.
    /// - Parameter rotation: A rotation to apply to the value.
    mutating func rotate(by rotation: Rotation) {
        self = rotated(by: rotation)
    }

    /// Translate the value in place.
    /// - Parameter offset: A translation to apply to the value.
    mutating func translate(by offset: Vector) {
        self = translated(by: offset)
    }

    /// Scale the value in place.
    /// - Parameter scale: A scale vector to apply to the value.
    mutating func scale(by scale: Vector) {
        self = scaled(by: scale)
    }

    /// Scale the value in place.
    /// - Parameter scale: A uniform scale factor to apply to the value.
    mutating func scale(by factor: Double) {
        self = scaled(by: factor)
    }

    /// Transform the value in place.
    /// - Parameter transform: A transform to apply to the value.
    mutating func transform(by transform: Transform) {
        self = transformed(by: transform)
    }

    /// Returns a rotated copy of the value.
    /// - Parameter quaternion: A rotation to apply to the value.
    @_disfavoredOverload
    func rotated(by quaternion: Quaternion) -> Self {
        rotated(by: Rotation(quaternion))
    }

    /// Rotate the value in place.
    /// - Parameter quaternion: A rotation to apply to the value.
    @_disfavoredOverload
    mutating func rotate(by quaternion: Quaternion) {
        self = rotated(by: quaternion)
    }

    /// Returns a transformed copy of the value.
    static func * (lhs: Self, rhs: Transform) -> Self {
        lhs.transformed(by: rhs)
    }

    /// Transform the value in place.
    static func *= (lhs: inout Self, rhs: Transform) {
        lhs.transform(by: rhs)
    }
}

/// A combined rotation, position, and scale that can be applied to a 3D object.
///
/// Working with intermediate transform objects instead of directly updating the vertex positions of a mesh
/// is more efficient and avoids a buildup of rounding errors.
public struct Transform: Hashable {
    /// The translation or position component of the transform.
    public var offset: Vector
    /// The rotation or orientation component of the transform.
    public var rotation: Rotation
    /// The size or scale component of the transform.
    public var scale: Vector {
        didSet { scale = scale.clamped() }
    }

    /// Creates a new transform.
    /// - Parameters:
    ///   - offset: The translation or position component of the transform. Defaults to zero (no offset).
    ///   - rotation: The translation or position component of the transform. Defaults to identity (no rotation).
    ///   - scale: The scaling component of the transform. Defaults to one (no scale adjustment).
    public init(offset: Vector? = nil, rotation: Rotation? = nil, scale: Vector? = nil) {
        self.offset = offset ?? .zero
        self.rotation = rotation ?? .identity
        self.scale = scale?.clamped() ?? .one
    }
}

extension Transform: Codable {
    private enum CodingKeys: CodingKey {
        case offset, rotation, scale
    }

    /// Creates a new transform by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let offset = try container.decodeIfPresent(Vector.self, forKey: .offset)
        let rotation = try container.decodeIfPresent(Rotation.self, forKey: .rotation)
        let scale = try container.decodeIfPresent(Vector.self, forKey: .scale)
        self.init(offset: offset, rotation: rotation, scale: scale)
    }

    /// Encodes this transform into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try offset.isEqual(to: .zero) ? () : container.encode(offset, forKey: .offset)
        try rotation.isIdentity ? () : container.encode(rotation, forKey: .rotation)
        try scale.isEqual(to: .one) ? () : container.encode(scale, forKey: .scale)
    }
}

extension Transform: Transformable {
    public func rotated(by rotation: Rotation) -> Transform {
        Transform(
            offset: offset,
            rotation: self.rotation * rotation,
            scale: scale
        )
    }

    public func translated(by offset: Vector) -> Transform {
        Transform(
            offset: self.offset + offset.scaled(by: scale).rotated(by: rotation),
            rotation: rotation,
            scale: scale
        )
    }

    public func scaled(by scale: Vector) -> Transform {
        Transform(
            offset: offset,
            rotation: rotation,
            scale: self.scale.scaled(by: scale)
        )
    }

    public func scaled(by factor: Double) -> Transform {
        Transform(
            offset: offset,
            rotation: rotation,
            scale: scale * factor
        )
    }

    public func transformed(by transform: Transform) -> Transform {
        transform
            .translated(by: offset)
            .scaled(by: scale)
            .rotated(by: rotation)
    }
}

public extension Transform {
    /// The identity transform (i.e. no transform).
    static let identity = Transform()

    /// Transform has no effect.
    var isIdentity: Bool {
        rotation.isIdentity && offset.isEqual(to: .zero) && scale.isEqual(to: .one)
    }

    /// Does the transform apply a mirror operation (negative scale).
    /// - Parameter v: An offset vector to apply to the transform.
    var isFlipped: Bool {
        isFlippedScale(scale)
    }
}

extension Mesh: Transformable {
    public func translated(by v: Vector) -> Mesh {
        v.isEqual(to: .zero) ? self : Mesh(
            unchecked: polygons.translated(by: v),
            bounds: boundsIfSet?.translated(by: v),
            isConvex: isKnownConvex,
            isWatertight: watertightIfSet,
            submeshes: submeshesIfEmpty
        )
    }

    public func rotated(by r: Rotation) -> Mesh {
        r.isIdentity ? self : Mesh(
            unchecked: polygons.rotated(by: r),
            bounds: nil,
            isConvex: isKnownConvex,
            isWatertight: watertightIfSet,
            submeshes: submeshesIfEmpty
        )
    }

    public func scaled(by v: Vector) -> Mesh {
        if v.x == v.y, v.y == v.z {
            // optimization - avoids scaling normals
            return scaled(by: v.x)
        }
        return Mesh(
            unchecked: polygons.scaled(by: v),
            bounds: boundsIfSet?.scaled(by: v),
            isConvex: isKnownConvex,
            isWatertight: watertightIfSet,
            submeshes: submeshesIfEmpty
        )
    }

    public func scaled(by f: Double) -> Mesh {
        f.isEqual(to: 1, withPrecision: epsilon) ? self : Mesh(
            unchecked: polygons.scaled(by: f),
            bounds: boundsIfSet?.scaled(by: f),
            isConvex: isKnownConvex,
            isWatertight: watertightIfSet,
            submeshes: submeshesIfEmpty
        )
    }

    /// Returns a transformed copy of the mesh.
    /// - Parameter t: A transform to apply to the mesh.
    public func transformed(by t: Transform) -> Mesh {
        t.isIdentity ? self : Mesh(
            unchecked: polygons.transformed(by: t),
            bounds: boundsIfSet.flatMap {
                t.rotation.isIdentity ? $0.transformed(by: t) : nil
            },
            isConvex: isKnownConvex,
            isWatertight: watertightIfSet,
            submeshes: submeshesIfEmpty
        )
    }
}

extension Polygon: Transformable {
    public func translated(by v: Vector) -> Polygon {
        v.isEqual(to: .zero) ? self : Polygon(
            unchecked: vertices.translated(by: v),
            normal: plane.normal,
            isConvex: isConvex,
            material: material
        )
    }

    public func rotated(by r: Rotation) -> Polygon {
        r.isIdentity ? self : Polygon(
            unchecked: vertices.rotated(by: r),
            normal: plane.normal.rotated(by: r),
            isConvex: isConvex,
            material: material
        )
    }

    public func scaled(by v: Vector) -> Polygon {
        if v.x == v.y, v.y == v.z {
            // optimization - avoids scaling normals
            return scaled(by: v.x)
        }

        let v = v.clamped()
        let vertices = self.vertices.scaled(by: v)
        let vn = Vector(1 / v.x, 1 / v.y, 1 / v.z)
        return Polygon(
            unchecked: isFlippedScale(v) ? vertices.reversed() : vertices,
            normal: plane.normal.scaled(by: vn).normalized(),
            isConvex: nil,
            material: material
        )
    }

    public func scaled(by f: Double) -> Polygon {
        if f.isEqual(to: 1, withPrecision: epsilon) {
            return self
        }
        let f = f.clamped()
        let vertices = self.vertices.scaled(by: f)
        return Polygon(
            unchecked: f < 0 ? vertices.reversed() : vertices,
            normal: f < 0 ? -plane.normal : plane.normal,
            isConvex: isConvex,
            material: material
        )
    }
}

extension LineSegment: Transformable {
    public func translated(by v: Vector) -> Self {
        .init(unchecked: start.translated(by: v), end.translated(by: v))
    }

    public func rotated(by r: Rotation) -> Self {
        .init(unchecked: start.rotated(by: r), end.rotated(by: r))
    }

    public func scaled(by v: Vector) -> Self {
        .init(unchecked: start.scaled(by: v), end.scaled(by: v))
    }

    public func scaled(by f: Double) -> Self {
        .init(unchecked: start.scaled(by: f), end.scaled(by: f))
    }
}

extension Vertex: Transformable {
    public func translated(by v: Vector) -> Vertex {
        Vertex(unchecked: position + v, normal, texcoord, color)
    }

    public func rotated(by q: Rotation) -> Vertex {
        Vertex(
            unchecked: position.rotated(by: q),
            normal.rotated(by: q),
            texcoord,
            color
        )
    }

    public func scaled(by v: Vector) -> Vertex {
        let vn = Vector(1 / v.x, 1 / v.y, 1 / v.z)
        return Vertex(
            unchecked: position.scaled(by: v),
            normal.scaled(by: vn).normalized(),
            texcoord,
            color
        )
    }

    public func scaled(by f: Double) -> Vertex {
        Vertex(
            unchecked: position * f,
            f < 0 ? -normal : normal,
            texcoord,
            color
        )
    }
}

extension Vector: Transformable {
    public func translated(by v: Vector) -> Vector {
        self + v
    }

    public func rotated(by r: Rotation) -> Vector {
        let q = r.quaternion
        let qv = Vector(q.x, q.y, q.z)
        let uv = qv.cross(self)
        let uuv = qv.cross(uv)
        return self + (uv * 2 * q.w) + (uuv * 2)
    }

    public func scaled(by v: Vector) -> Vector {
        Vector(x * v.x, y * v.y, z * v.z)
    }

    public func scaled(by factor: Double) -> Vector {
        self * factor
    }
}

extension PathPoint: Transformable {
    public func translated(by v: Vector) -> PathPoint {
        PathPoint(
            position + v,
            texcoord: texcoord,
            color: color,
            isCurved: isCurved
        )
    }

    public func rotated(by r: Rotation) -> PathPoint {
        PathPoint(
            position.rotated(by: r),
            texcoord: texcoord,
            color: color,
            isCurved: isCurved
        )
    }

    public func scaled(by v: Vector) -> PathPoint {
        PathPoint(
            position.scaled(by: v),
            texcoord: texcoord,
            color: color,
            isCurved: isCurved
        )
    }

    public func scaled(by f: Double) -> PathPoint {
        PathPoint(
            position * f,
            texcoord: texcoord,
            color: color,
            isCurved: isCurved
        )
    }

    public func transformed(by t: Transform) -> PathPoint {
        PathPoint(
            position.transformed(by: t),
            texcoord: texcoord,
            color: color,
            isCurved: isCurved
        )
    }
}

extension Path: Transformable {
    public func translated(by v: Vector) -> Path {
        Path(
            unchecked: points.translated(by: v),
            plane: plane?.translated(by: v), subpathIndices: subpathIndices
        )
    }

    public func rotated(by r: Rotation) -> Path {
        Path(
            unchecked: points.rotated(by: r),
            plane: plane?.rotated(by: r), subpathIndices: subpathIndices
        )
    }

    public func scaled(by v: Vector) -> Path {
        let v = v.clamped()
        return Path(
            unchecked: points.scaled(by: v),
            plane: plane?.scaled(by: v), subpathIndices: subpathIndices
        )
    }

    public func scaled(by f: Double) -> Path {
        let f = f.clamped()
        return Path(
            unchecked: points.scaled(by: f),
            plane: plane?.scaled(by: f), subpathIndices: subpathIndices
        )
    }

    public func transformed(by t: Transform) -> Path {
        Path(
            unchecked: points.transformed(by: t),
            plane: plane?.transformed(by: t), subpathIndices: subpathIndices
        )
    }
}

extension Plane: Transformable {
    public func translated(by v: Vector) -> Plane {
        Plane(unchecked: normal, pointOnPlane: normal * w + v)
    }

    public func rotated(by r: Rotation) -> Plane {
        Plane(unchecked: normal.rotated(by: r), w: w)
    }

    public func scaled(by v: Vector) -> Plane {
        if v.x == v.y, v.y == v.z {
            return scaled(by: v.x)
        }
        let v = v.clamped()
        let p = (normal * w).scaled(by: v)
        let vn = Vector(1 / v.x, 1 / v.y, 1 / v.z)
        return Plane(unchecked: normal.scaled(by: vn).normalized(), pointOnPlane: p)
    }

    public func scaled(by f: Double) -> Plane {
        Plane(unchecked: normal, w: w * f.clamped())
    }
}

extension Bounds: Transformable {
    public func translated(by v: Vector) -> Bounds {
        Bounds(min: min + v, max: max + v)
    }

    /// Returns a rotated copy of the bounds.
    /// - Parameter rotation: A quaternion to apply to the bounds.
    ///
    /// > Note: Because a bounds must be axially-aligned, rotating by an angle that is not a multiple of
    /// 90 degrees will result in the bounds being increased in size. Rotating it back again will not reduce
    /// the size, so this is a potentially irreversible operation. In general, after rotating a shape it is better
    /// to recalculate the bounds rather than trying to rotate the previous bounds.
    public func rotated(by rotation: Rotation) -> Bounds {
        isEmpty ? self : Bounds(points: corners.rotated(by: rotation))
    }

    public func scaled(by v: Vector) -> Bounds {
        let v = v.clamped()
        return isEmpty ? self : Bounds(min.scaled(by: v), max.scaled(by: v))
    }

    /// Returns a scaled copy of the bounds.
    /// - Parameter f: A scale factor to apply to the bounds.
    public func scaled(by f: Double) -> Bounds {
        let f = f.clamped()
        return isEmpty ? self : Bounds(min * f, max * f)
    }
}

extension Array: Transformable where Element: Transformable {
    public func translated(by v: Vector) -> [Element] {
        v.isEqual(to: .zero) ? self : map { $0.translated(by: v) }
    }

    public func rotated(by r: Rotation) -> [Element] {
        r.isIdentity ? self : map { $0.rotated(by: r) }
    }

    public func scaled(by v: Vector) -> [Element] {
        v.isUniform ? scaled(by: v.x) : map { $0.scaled(by: v) }
    }

    public func scaled(by f: Double) -> [Element] {
        f.isEqual(to: 1, withPrecision: epsilon) ? self : map { $0.scaled(by: f) }
    }

    public func transformed(by t: Transform) -> [Element] {
        t.isIdentity ? self : map { $0.transformed(by: t) }
    }
}

private extension Double {
    func clamped() -> Double {
        self < 0 ? min(self, -scaleLimit) : max(self, scaleLimit)
    }
}

private extension Vector {
    func clamped() -> Self {
        Self(x.clamped(), y.clamped(), z.clamped())
    }
}
