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
    /// - Parameter distance: An offset vector to apply to the value.
    func translated(by distance: Vector) -> Self

    /// Returns a scaled copy of the value.
    /// - Parameter scale: A vector scale factor to apply to the value.
    func scaled(by scale: Vector) -> Self

    /// Returns a scaled copy of the value.
    /// - Parameter factor: A uniform scale factor to apply to the value.
    func scaled(by factor: Double) -> Self

    /// Returns a transformed copy of the value.
    /// - Parameter transform: A transform to apply to the value.
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
    /// - Parameter distance: A translation to apply to the value.
    mutating func translate(by distance: Vector) {
        self = translated(by: distance)
    }

    /// Scale the value in place.
    /// - Parameter scale: A vector scale factor to apply to the value.
    mutating func scale(by scale: Vector) {
        self = scaled(by: scale)
    }

    /// Scale the value in place.
    /// - Parameter factor: A uniform scale factor to apply to the value.
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
    @available(*, deprecated)
    func rotated(by quaternion: Quaternion) -> Self {
        rotated(by: Rotation(quaternion))
    }

    /// Rotate the value in place.
    /// - Parameter quaternion: A rotation to apply to the value.
    @_disfavoredOverload
    @available(*, deprecated)
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
        try offset.isZero ? () : container.encode(offset, forKey: .offset)
        try rotation.isIdentity ? () : container.encode(rotation, forKey: .rotation)
        try scale.isOne ? () : container.encode(scale, forKey: .scale)
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

    public func translated(by distance: Vector) -> Transform {
        Transform(
            offset: offset + distance.scaled(by: scale).rotated(by: rotation),
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

    /// Creates a offset transform.
    /// - Parameter offset: An offset distance.
    static func offset(_ offset: Vector) -> Transform {
        .init(offset: offset)
    }

    /// Creates a rotation transform.
    /// - Parameter rotation: A rotation to apply.
    static func rotation(_ rotation: Rotation) -> Transform {
        .init(rotation: rotation)
    }

    /// Creates a scale transform.
    /// - Parameter scale: A vector scale factor to apply.
    static func scale(_ scale: Vector) -> Transform {
        .init(scale: scale)
    }

    /// Creates a uniform scale transform.
    /// - Parameter factor: A uniform scale factor to apply.
    static func scale(_ factor: Double) -> Transform {
        .init(scale: Vector(size: factor))
    }

    /// Transform has no effect.
    var isIdentity: Bool {
        rotation.isIdentity && offset.isZero && scale.isOne
    }

    /// Does the transform apply a mirror operation (negative scale)?
    var isFlipped: Bool {
        isFlippedScale(scale)
    }
}

extension Mesh: Transformable {
    public func translated(by distance: Vector) -> Mesh {
        distance.isZero ? self : Mesh(
            unchecked: polygons.translated(by: distance),
            bounds: boundsIfSet?.translated(by: distance),
            isConvex: isKnownConvex,
            isWatertight: watertightIfSet,
            submeshes: submeshesIfEmpty
        )
    }

    public func rotated(by rotation: Rotation) -> Mesh {
        rotation.isIdentity ? self : Mesh(
            unchecked: polygons.rotated(by: rotation),
            bounds: nil,
            isConvex: isKnownConvex,
            isWatertight: watertightIfSet,
            submeshes: submeshesIfEmpty
        )
    }

    public func scaled(by scale: Vector) -> Mesh {
        if scale.x == scale.y, scale.y == scale.z {
            // optimization - avoids scaling normals
            return scaled(by: scale.x)
        }
        return Mesh(
            unchecked: polygons.scaled(by: scale),
            bounds: boundsIfSet?.scaled(by: scale),
            isConvex: isKnownConvex,
            isWatertight: watertightIfSet,
            submeshes: submeshesIfEmpty
        )
    }

    public func scaled(by factor: Double) -> Mesh {
        factor.isEqual(to: 1, withPrecision: epsilon) ? self : Mesh(
            unchecked: polygons.scaled(by: factor),
            bounds: boundsIfSet?.scaled(by: factor),
            isConvex: isKnownConvex,
            isWatertight: watertightIfSet,
            submeshes: submeshesIfEmpty
        )
    }

    /// Returns a transformed copy of the mesh.
    /// - Parameter transform: A transform to apply to the mesh.
    public func transformed(by transform: Transform) -> Mesh {
        transform.isIdentity ? self : Mesh(
            unchecked: polygons.transformed(by: transform),
            bounds: boundsIfSet.flatMap {
                transform.rotation.isIdentity ? $0.transformed(by: transform) : nil
            },
            isConvex: isKnownConvex,
            isWatertight: watertightIfSet,
            submeshes: submeshesIfEmpty
        )
    }
}

extension Polygon: Transformable {
    public func translated(by distance: Vector) -> Polygon {
        distance.isZero ? self : Polygon(
            unchecked: vertices.translated(by: distance),
            normal: plane.normal,
            isConvex: isConvex,
            sanitizeNormals: false,
            material: material
        )
    }

    public func rotated(by rotation: Rotation) -> Polygon {
        rotation.isIdentity ? self : Polygon(
            unchecked: vertices.rotated(by: rotation),
            normal: plane.normal.rotated(by: rotation),
            isConvex: isConvex,
            sanitizeNormals: false,
            material: material
        )
    }

    public func scaled(by scale: Vector) -> Polygon {
        if scale.x == scale.y, scale.y == scale.z {
            // optimization - avoids scaling normals
            return scaled(by: scale.x)
        }

        let scale = scale.clamped()
        let vertices = self.vertices.scaled(by: scale)
        let vn = Vector(1 / scale.x, 1 / scale.y, 1 / scale.z)
        return Polygon(
            unchecked: isFlippedScale(scale) ? vertices.reversed() : vertices,
            normal: plane.normal.scaled(by: vn).normalized(),
            isConvex: nil,
            sanitizeNormals: false,
            material: material
        )
    }

    public func scaled(by factor: Double) -> Polygon {
        if factor.isEqual(to: 1, withPrecision: epsilon) {
            return self
        }
        let factor = factor.clamped()
        let vertices = self.vertices.scaled(by: factor)
        return Polygon(
            unchecked: factor < 0 ? vertices.reversed() : vertices,
            normal: factor < 0 ? -plane.normal : plane.normal,
            isConvex: isConvex,
            sanitizeNormals: false,
            material: material
        )
    }
}

extension LineSegment: Transformable {
    public func translated(by distance: Vector) -> Self {
        .init(unchecked: start.translated(by: distance), end.translated(by: distance))
    }

    public func rotated(by rotation: Rotation) -> Self {
        .init(unchecked: start.rotated(by: rotation), end.rotated(by: rotation))
    }

    public func scaled(by scale: Vector) -> Self {
        .init(unchecked: start.scaled(by: scale), end.scaled(by: scale))
    }

    public func scaled(by factor: Double) -> Self {
        .init(unchecked: start.scaled(by: factor), end.scaled(by: factor))
    }
}

extension Vertex: Transformable {
    public func translated(by distance: Vector) -> Vertex {
        Vertex(unchecked: position + distance, normal, texcoord, color)
    }

    public func rotated(by rotation: Rotation) -> Vertex {
        Vertex(
            unchecked: position.rotated(by: rotation),
            normal.rotated(by: rotation),
            texcoord,
            color
        )
    }

    public func scaled(by scale: Vector) -> Vertex {
        let vn = Vector(1 / scale.x, 1 / scale.y, 1 / scale.z)
        return Vertex(
            unchecked: position.scaled(by: scale),
            normal.scaled(by: vn).normalized(),
            texcoord,
            color
        )
    }

    public func scaled(by factor: Double) -> Vertex {
        Vertex(
            unchecked: position * factor,
            factor < 0 ? -normal : normal,
            texcoord,
            color
        )
    }
}

extension Vector: Transformable {
    public func translated(by distance: Vector) -> Vector {
        self + distance
    }

    public func rotated(by rotation: Rotation) -> Vector {
        rotation.rotate(self)
    }

    public func scaled(by scale: Vector) -> Vector {
        Vector(x * scale.x, y * scale.y, z * scale.z)
    }

    public func scaled(by factor: Double) -> Vector {
        self * factor
    }
}

extension PathPoint: Transformable {
    public func translated(by distance: Vector) -> PathPoint {
        PathPoint(
            position + distance,
            texcoord: texcoord,
            color: color,
            isCurved: isCurved
        )
    }

    public func rotated(by rotation: Rotation) -> PathPoint {
        PathPoint(
            position.rotated(by: rotation),
            texcoord: texcoord,
            color: color,
            isCurved: isCurved
        )
    }

    public func scaled(by scale: Vector) -> PathPoint {
        PathPoint(
            position.scaled(by: scale),
            texcoord: texcoord,
            color: color,
            isCurved: isCurved
        )
    }

    public func scaled(by factor: Double) -> PathPoint {
        PathPoint(
            position * factor,
            texcoord: texcoord,
            color: color,
            isCurved: isCurved
        )
    }

    public func transformed(by transform: Transform) -> PathPoint {
        PathPoint(
            position.transformed(by: transform),
            texcoord: texcoord,
            color: color,
            isCurved: isCurved
        )
    }
}

extension Path: Transformable {
    public func translated(by distance: Vector) -> Path {
        Path(
            unchecked: points.translated(by: distance),
            plane: plane?.translated(by: distance), subpathIndices: subpathIndices
        )
    }

    public func rotated(by rotation: Rotation) -> Path {
        Path(
            unchecked: points.rotated(by: rotation),
            plane: nil, // Avoids loss of precision from rotating plane
            subpathIndices: subpathIndices
        )
    }

    public func scaled(by scale: Vector) -> Path {
        let scale = scale.clamped()
        return Path(
            unchecked: points.scaled(by: scale),
            plane: plane?.scaled(by: scale), subpathIndices: subpathIndices
        )
    }

    public func scaled(by factor: Double) -> Path {
        let factor = factor.clamped()
        return Path(
            unchecked: points.scaled(by: factor),
            plane: plane?.scaled(by: factor), subpathIndices: subpathIndices
        )
    }

    public func transformed(by transform: Transform) -> Path {
        Path(
            unchecked: points.transformed(by: transform),
            plane: plane?.transformed(by: transform), subpathIndices: subpathIndices
        )
    }
}

extension Plane: Transformable {
    public func translated(by distance: Vector) -> Plane {
        Plane(unchecked: normal, pointOnPlane: normal * w + distance)
    }

    public func rotated(by rotation: Rotation) -> Plane {
        Plane(unchecked: normal.rotated(by: rotation), w: w)
    }

    public func scaled(by scale: Vector) -> Plane {
        if scale.isUniform {
            return scaled(by: scale.x)
        }
        let scale = scale.clamped()
        let p = (normal * w).scaled(by: scale)
        let vn = Vector(1 / scale.x, 1 / scale.y, 1 / scale.z)
        return Plane(unchecked: normal.scaled(by: vn).normalized(), pointOnPlane: p)
    }

    public func scaled(by factor: Double) -> Plane {
        Plane(unchecked: normal, w: w * factor.clamped())
    }
}

extension Bounds: Transformable {
    public func translated(by distance: Vector) -> Bounds {
        Bounds(min: min + distance, max: max + distance)
    }

    /// Returns a rotated copy of the bounds.
    /// - Parameter rotation: A quaternion to apply to the bounds.
    ///
    /// > Note: Because a bounds must be axially-aligned, rotating by an angle that is not a multiple of
    /// 90 degrees will result in the bounds being increased in size. Rotating it back again will not reduce
    /// the size, so this is a potentially irreversible operation. In general, after rotating a shape it is better
    /// to recalculate the bounds rather than trying to rotate the previous bounds.
    public func rotated(by rotation: Rotation) -> Bounds {
        isEmpty ? self : Bounds(corners.rotated(by: rotation))
    }

    public func scaled(by scale: Vector) -> Bounds {
        let scale = scale.clamped()
        return isEmpty ? self : Bounds(min.scaled(by: scale), max.scaled(by: scale))
    }

    public func scaled(by factor: Double) -> Bounds {
        let factor = factor.clamped()
        return isEmpty ? self : Bounds(min * factor, max * factor)
    }
}

extension Array: Transformable where Element: Transformable {
    public func translated(by distance: Vector) -> [Element] {
        distance.isZero ? self : map { $0.translated(by: distance) }
    }

    public func rotated(by rotation: Rotation) -> [Element] {
        rotation.isIdentity ? self : map { $0.rotated(by: rotation) }
    }

    public func scaled(by scale: Vector) -> [Element] {
        scale.isUniform ? scaled(by: scale.x) : map { $0.scaled(by: scale) }
    }

    public func scaled(by factor: Double) -> [Element] {
        factor.isEqual(to: 1, withPrecision: epsilon) ? self : map { $0.scaled(by: factor) }
    }

    public func transformed(by transform: Transform) -> [Element] {
        if transform.scale.isOne {
            if transform.offset == .zero {
                return rotated(by: transform.rotation)
            } else if transform.isIdentity {
                return translated(by: transform.offset)
            }
        } else if transform.rotation == .identity, transform.offset.isZero {
            return scaled(by: transform.scale)
        }
        return map { $0.transformed(by: transform) }
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
