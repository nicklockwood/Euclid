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

public struct Transform: Hashable {
    public var offset: Vector
    public var rotation: Rotation
    public var scale: Vector

    public init(offset: Vector? = nil, rotation: Rotation? = nil, scale: Vector? = nil) {
        self.offset = offset ?? .zero
        self.rotation = rotation ?? .identity
        self.scale = scale ?? Vector(1, 1, 1)
    }
}

extension Transform: Codable {
    private enum CodingKeys: CodingKey {
        case offset, rotation, scale
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let offset = try container.decodeIfPresent(Vector.self, forKey: .offset)
        let rotation = try container.decodeIfPresent(Rotation.self, forKey: .rotation)
        let scale = try container.decodeIfPresent(Vector.self, forKey: .scale)
        self.init(offset: offset, rotation: rotation, scale: scale)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try offset == .zero ? () : container.encode(offset, forKey: .offset)
        try rotation == .identity ? () : container.encode(rotation, forKey: .rotation)
        try scale == Vector(1, 1, 1) ? () : container.encode(scale, forKey: .scale)
    }
}

public extension Transform {
    static let identity = Transform()

    @available(*, deprecated, message: "No longer needed")
    var isFlipped: Bool {
        var flipped = scale.x < 0
        if scale.y < 0 { flipped = !flipped }
        if scale.z < 0 { flipped = !flipped }
        return flipped
    }

    mutating func translate(by v: Vector) {
        offset = offset + v.scaled(by: scale).rotated(by: rotation)
    }

    mutating func rotate(by r: Rotation) {
        rotation *= r
    }

    mutating func scale(by v: Vector) {
        scale = scale.scaled(by: v)
    }

    static func * (lhs: Transform, rhs: Transform) -> Transform {
        var result = rhs
        result.translate(by: lhs.offset)
        result.scale(by: lhs.scale)
        result.rotation *= lhs.rotation
        return result
    }
}

public extension Mesh {
    func translated(by v: Vector) -> Mesh {
        Mesh(
            unchecked: polygons.translated(by: v),
            bounds: boundsIfSet?.translated(by: v),
            isConvex: isConvex,
            isWatertight: watertightIfSet
        )
    }

    @_disfavoredOverload
    func rotated(by r: Rotation) -> Mesh {
        Mesh(
            unchecked: polygons.rotated(by: r),
            bounds: nil,
            isConvex: isConvex,
            isWatertight: watertightIfSet
        )
    }

    func rotated(by q: Quaternion) -> Mesh {
        Mesh(
            unchecked: polygons.rotated(by: q),
            bounds: nil,
            isConvex: isConvex,
            isWatertight: watertightIfSet
        )
    }

    func scaled(by v: Vector) -> Mesh {
        if v.x == v.y, v.y == v.z {
            // optimization - avoids scaling normals
            return scaled(by: v.x)
        }
        return Mesh(
            unchecked: polygons.scaled(by: v),
            bounds: boundsIfSet?.scaled(by: v),
            isConvex: isConvex && v.x > 0 && v.y > 0 && v.y > 0,
            isWatertight: watertightIfSet
        )
    }

    func scaled(by f: Double) -> Mesh {
        Mesh(
            unchecked: polygons.scaled(by: f),
            bounds: boundsIfSet?.scaled(by: f),
            isConvex: isConvex && f > 0,
            isWatertight: watertightIfSet
        )
    }

    @available(*, deprecated, message: "No longer needed")
    func scaleCorrected(for v: Vector) -> Mesh {
        Mesh(
            unchecked: polygons.scaleCorrected(for: v),
            bounds: boundsIfSet,
            isConvex: isConvex,
            isWatertight: watertightIfSet
        )
    }

    func transformed(by t: Transform) -> Mesh {
        Mesh(
            unchecked: polygons.transformed(by: t),
            bounds: boundsIfSet.flatMap {
                t.rotation == .identity ? $0.transformed(by: t) : nil
            },
            isConvex: isConvex,
            isWatertight: watertightIfSet
        )
    }
}

public extension Polygon {
    func translated(by v: Vector) -> Polygon {
        Polygon(
            unchecked: vertices.translated(by: v),
            normal: plane.normal,
            isConvex: isConvex,
            material: material
        )
    }

    @_disfavoredOverload
    func rotated(by r: Rotation) -> Polygon {
        Polygon(
            unchecked: vertices.rotated(by: r),
            normal: plane.normal.rotated(by: r),
            isConvex: isConvex,
            material: material
        )
    }

    func rotated(by q: Quaternion) -> Polygon {
        Polygon(
            unchecked: vertices.rotated(by: q),
            normal: plane.normal.rotated(by: q),
            isConvex: isConvex,
            material: material
        )
    }

    func scaled(by v: Vector) -> Polygon {
        var v = v
        let limit = 0.001
        v.x = v.x < 0 ? min(v.x, -limit) : max(v.x, limit)
        v.y = v.y < 0 ? min(v.y, -limit) : max(v.y, limit)
        v.z = v.z < 0 ? min(v.z, -limit) : max(v.z, limit)

        var flipped = v.x < 0
        if v.y < 0 { flipped = !flipped }
        if v.z < 0 { flipped = !flipped }

        let vertices = self.vertices.scaled(by: v)
        let vn = Vector(1 / v.x, 1 / v.y, 1 / v.z)
        return Polygon(
            unchecked: flipped ? vertices.reversed() : vertices,
            normal: plane.normal.scaled(by: vn).normalized(),
            isConvex: isConvex,
            material: material
        )
    }

    func scaled(by f: Double) -> Polygon {
        let limit = 0.001
        let f = f < 0 ? min(f, -limit) : max(f, limit)
        let polygon = Polygon(
            unchecked: vertices.scaled(by: f),
            normal: plane.normal,
            isConvex: isConvex,
            material: material
        )
        return f < 0 ? polygon.inverted() : polygon
    }

    func transformed(by t: Transform) -> Polygon {
        scaled(by: t.scale).rotated(by: t.rotation).translated(by: t.offset)
    }

    @available(*, deprecated, message: "No longer needed")
    func scaleCorrected(for v: Vector) -> Polygon {
        var flipped = v.x < 0
        if v.y < 0 { flipped = !flipped }
        if v.z < 0 { flipped = !flipped }
        return Polygon(
            unchecked: flipped ? vertices.reversed() : vertices,
            normal: plane.normal,
            isConvex: isConvex,
            material: material
        )
    }
}

internal extension Collection where Element == Polygon {
    func translated(by v: Vector) -> [Polygon] {
        map { $0.translated(by: v) }
    }

    @_disfavoredOverload
    func rotated(by r: Rotation) -> [Polygon] {
        map { $0.rotated(by: r) }
    }

    func rotated(by q: Quaternion) -> [Polygon] {
        map { $0.rotated(by: q) }
    }

    func scaled(by v: Vector) -> [Polygon] {
        map { $0.scaled(by: v) }
    }

    func scaled(by f: Double) -> [Polygon] {
        map { $0.scaled(by: f) }
    }

    @available(*, deprecated, message: "No longer needed")
    func scaleCorrected(for v: Vector) -> [Polygon] {
        map { $0.scaleCorrected(for: v) }
    }

    func transformed(by t: Transform) -> [Polygon] {
        map { $0.transformed(by: t) }
    }
}

public extension Vertex {
    func translated(by v: Vector) -> Vertex {
        Vertex(position + v, normal, texcoord)
    }

    @_disfavoredOverload
    func rotated(by r: Rotation) -> Vertex {
        Vertex(position.rotated(by: r), normal.rotated(by: r), texcoord)
    }

    func rotated(by q: Quaternion) -> Vertex {
        Vertex(position.rotated(by: q), normal.rotated(by: q), texcoord)
    }

    func scaled(by v: Vector) -> Vertex {
        let vn = Vector(1 / v.x, 1 / v.y, 1 / v.z)
        return Vertex(position.scaled(by: v), normal.scaled(by: vn).normalized(), texcoord)
    }

    func scaled(by f: Double) -> Vertex {
        Vertex(position * f, normal, texcoord)
    }

    func transformed(by t: Transform) -> Vertex {
        scaled(by: t.scale).rotated(by: t.rotation).translated(by: t.offset)
    }
}

internal extension Collection where Element == Vertex {
    func translated(by v: Vector) -> [Vertex] {
        map { $0.translated(by: v) }
    }

    @_disfavoredOverload
    func rotated(by r: Rotation) -> [Vertex] {
        map { $0.rotated(by: r) }
    }

    func rotated(by q: Quaternion) -> [Vertex] {
        map { $0.rotated(by: q) }
    }

    func scaled(by v: Vector) -> [Vertex] {
        map { $0.scaled(by: v) }
    }

    func scaled(by f: Double) -> [Vertex] {
        map { $0.scaled(by: f) }
    }

    func transformed(by t: Transform) -> [Vertex] {
        map { $0.transformed(by: t) }
    }
}

public extension Vector {
    func translated(by v: Vector) -> Vector {
        self + v
    }

    @_disfavoredOverload
    func rotated(by r: Rotation) -> Vector {
        Vector(
            x * r.m11 + y * r.m21 + z * r.m31,
            x * r.m12 + y * r.m22 + z * r.m32,
            x * r.m13 + y * r.m23 + z * r.m33
        )
    }

    func rotated(by q: Quaternion) -> Vector {
        let qv = Vector(q.x, q.y, q.z)
        let uv = qv.cross(self)
        let uuv = qv.cross(uv)
        return self + (uv * 2 * q.w) + (uuv * 2)
    }

    func scaled(by v: Vector) -> Vector {
        Vector(x * v.x, y * v.y, z * v.z)
    }

    func transformed(by t: Transform) -> Vector {
        scaled(by: t.scale).rotated(by: t.rotation) + t.offset
    }
}

internal extension Collection where Element == Vector {
    func translated(by v: Vector) -> [Vector] {
        map { $0.translated(by: v) }
    }

    @_disfavoredOverload
    func rotated(by r: Rotation) -> [Vector] {
        map { $0.rotated(by: r) }
    }

    func rotated(by q: Quaternion) -> [Vector] {
        map { $0.rotated(by: q) }
    }

    func scaled(by v: Vector) -> [Vector] {
        map { $0.scaled(by: v) }
    }

    func scaled(by f: Double) -> [Vector] {
        map { $0 * f }
    }

    func transformed(by t: Transform) -> [Vector] {
        map { $0.transformed(by: t) }
    }
}

public extension PathPoint {
    func translated(by v: Vector) -> PathPoint {
        PathPoint(position + v, texcoord: texcoord, isCurved: isCurved)
    }

    @_disfavoredOverload
    func rotated(by r: Rotation) -> PathPoint {
        PathPoint(position.rotated(by: r), texcoord: texcoord, isCurved: isCurved)
    }

    func rotated(by q: Quaternion) -> PathPoint {
        PathPoint(position.rotated(by: q), texcoord: texcoord, isCurved: isCurved)
    }

    func scaled(by v: Vector) -> PathPoint {
        PathPoint(position.scaled(by: v), texcoord: texcoord, isCurved: isCurved)
    }

    func scaled(by f: Double) -> PathPoint {
        PathPoint(position * f, texcoord: texcoord, isCurved: isCurved)
    }

    func transformed(by t: Transform) -> PathPoint {
        PathPoint(position.transformed(by: t), texcoord: texcoord, isCurved: isCurved)
    }
}

internal extension Collection where Element == PathPoint {
    func translated(by v: Vector) -> [PathPoint] {
        map { $0.translated(by: v) }
    }

    @_disfavoredOverload
    func rotated(by r: Rotation) -> [PathPoint] {
        map { $0.rotated(by: r) }
    }

    func rotated(by q: Quaternion) -> [PathPoint] {
        map { $0.rotated(by: q) }
    }

    func scaled(by v: Vector) -> [PathPoint] {
        map { $0.scaled(by: v) }
    }

    func scaled(by f: Double) -> [PathPoint] {
        map { $0.scaled(by: f) }
    }

    func transformed(by t: Transform) -> [PathPoint] {
        map { $0.transformed(by: t) }
    }
}

public extension Path {
    func translated(by v: Vector) -> Path {
        Path(
            unchecked: points.translated(by: v),
            plane: plane?.translated(by: v), subpathIndices: subpathIndices
        )
    }

    @_disfavoredOverload
    func rotated(by r: Rotation) -> Path {
        Path(
            unchecked: points.rotated(by: r),
            plane: plane?.rotated(by: r), subpathIndices: subpathIndices
        )
    }

    func rotated(by q: Quaternion) -> Path {
        Path(
            unchecked: points.rotated(by: q),
            plane: plane?.rotated(by: q), subpathIndices: subpathIndices
        )
    }

    func scaled(by v: Vector) -> Path {
        Path(
            unchecked: points.scaled(by: v),
            plane: plane?.scaled(by: v), subpathIndices: subpathIndices
        )
    }

    func scaled(by f: Double) -> Path {
        Path(
            unchecked: points.scaled(by: f),
            plane: plane?.scaled(by: f), subpathIndices: subpathIndices
        )
    }

    func transformed(by t: Transform) -> Path {
        Path(
            unchecked: points.transformed(by: t),
            plane: plane?.transformed(by: t), subpathIndices: subpathIndices
        )
    }
}

public extension Plane {
    func translated(by v: Vector) -> Plane {
        Plane(unchecked: normal, pointOnPlane: normal * w + v)
    }

    @_disfavoredOverload
    func rotated(by r: Rotation) -> Plane {
        Plane(unchecked: normal.rotated(by: r), w: w)
    }

    func rotated(by q: Quaternion) -> Plane {
        Plane(unchecked: normal.rotated(by: q), w: w)
    }

    func scaled(by v: Vector) -> Plane {
        let vn = Vector(1 / v.x, 1 / v.y, 1 / v.z)
        let p = (normal * w).scaled(by: v)
        return Plane(unchecked: normal.scaled(by: vn).normalized(), pointOnPlane: p)
    }

    func scaled(by f: Double) -> Plane {
        Plane(unchecked: normal, w: w * f)
    }

    func transformed(by t: Transform) -> Plane {
        scaled(by: t.scale).rotated(by: t.rotation).translated(by: t.offset)
    }
}

public extension Bounds {
    func translated(by v: Vector) -> Bounds {
        Bounds(min: min + v, max: max + v)
    }

    @_disfavoredOverload
    func rotated(by r: Rotation) -> Bounds {
        Bounds(points: corners.rotated(by: r))
    }

    func rotated(by q: Quaternion) -> Bounds {
        Bounds(points: corners.rotated(by: q))
    }

    func scaled(by v: Vector) -> Bounds {
        Bounds(min: min.scaled(by: v), max: max.scaled(by: v))
    }

    func scaled(by f: Double) -> Bounds {
        Bounds(min: min * f, max: max * f)
    }

    func transformed(by t: Transform) -> Bounds {
        Bounds(points: corners.transformed(by: t))
    }
}
