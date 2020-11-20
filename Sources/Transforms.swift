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
        return Mesh(
            unchecked: polygons.translated(by: v),
            bounds: boundsIfSet?.translated(by: v),
            isConvex: isConvex
        )
    }

    func rotated(by m: Rotation) -> Mesh {
        return Mesh(unchecked: polygons.rotated(by: m), isConvex: isConvex)
    }

    func scaled(by v: Vector) -> Mesh {
        if v.x == v.y, v.y == v.z {
            // optimization - avoids scaling normals
            return scaled(by: v.x)
        }
        return Mesh(
            unchecked: polygons.scaled(by: v),
            bounds: boundsIfSet?.scaled(by: v),
            isConvex: isConvex // TODO: what if v has negative components?
        )
    }

    func scaled(by f: Double) -> Mesh {
        return Mesh(
            unchecked: polygons.scaled(by: f),
            bounds: boundsIfSet?.scaled(by: f),
            isConvex: isConvex && f > 0
        )
    }

    func scaleCorrected(for v: Vector) -> Mesh {
        return Mesh(
            unchecked: polygons.scaleCorrected(for: v),
            bounds: boundsIfSet,
            isConvex: isConvex
        )
    }

    func transformed(by t: Transform) -> Mesh {
        return Mesh(unchecked: polygons.transformed(by: t), isConvex: isConvex)
    }
}

public extension Polygon {
    func translated(by v: Vector) -> Polygon {
        return Polygon(
            unchecked: vertices.translated(by: v),
            normal: plane.normal,
            isConvex: isConvex,
            bounds: boundsIfSet?.translated(by: v),
            material: material
        )
    }

    func rotated(by m: Rotation) -> Polygon {
        return Polygon(
            unchecked: vertices.rotated(by: m),
            normal: plane.normal.rotated(by: m),
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
            bounds: boundsIfSet?.scaled(by: v),
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
            bounds: boundsIfSet?.scaled(by: f),
            material: material
        )
        return f < 0 ? polygon.inverted() : polygon
    }

    func transformed(by t: Transform) -> Polygon {
        return scaled(by: t.scale).rotated(by: t.rotation).translated(by: t.offset)
    }

    func scaleCorrected(for v: Vector) -> Polygon {
        var flipped = v.x < 0
        if v.y < 0 { flipped = !flipped }
        if v.z < 0 { flipped = !flipped }
        return Polygon(
            unchecked: flipped ? vertices.reversed() : vertices,
            normal: plane.normal,
            isConvex: isConvex,
            bounds: boundsIfSet,
            material: material
        )
    }
}

internal extension Collection where Element == Polygon {
    func translated(by v: Vector) -> [Polygon] {
        return map { $0.translated(by: v) }
    }

    func rotated(by m: Rotation) -> [Polygon] {
        return map { $0.rotated(by: m) }
    }

    func scaled(by v: Vector) -> [Polygon] {
        return map { $0.scaled(by: v) }
    }

    func scaled(by f: Double) -> [Polygon] {
        return map { $0.scaled(by: f) }
    }

    func scaleCorrected(for v: Vector) -> [Polygon] {
        return map { $0.scaleCorrected(for: v) }
    }

    func transformed(by t: Transform) -> [Polygon] {
        return map { $0.transformed(by: t) }
    }
}

public extension Vertex {
    func translated(by v: Vector) -> Vertex {
        return Vertex(position + v, normal, texcoord)
    }

    func rotated(by m: Rotation) -> Vertex {
        return Vertex(position.rotated(by: m), normal.rotated(by: m), texcoord)
    }

    func scaled(by v: Vector) -> Vertex {
        let vn = Vector(1 / v.x, 1 / v.y, 1 / v.z)
        return Vertex(position.scaled(by: v), normal.scaled(by: vn).normalized(), texcoord)
    }

    func scaled(by f: Double) -> Vertex {
        return Vertex(position * f, normal, texcoord)
    }

    func transformed(by t: Transform) -> Vertex {
        return scaled(by: t.scale).rotated(by: t.rotation).translated(by: t.offset)
    }
}

internal extension Collection where Element == Vertex {
    func translated(by v: Vector) -> [Vertex] {
        return map { $0.translated(by: v) }
    }

    func rotated(by m: Rotation) -> [Vertex] {
        return map { $0.rotated(by: m) }
    }

    func scaled(by v: Vector) -> [Vertex] {
        return map { $0.scaled(by: v) }
    }

    func scaled(by f: Double) -> [Vertex] {
        return map { $0.scaled(by: f) }
    }

    func transformed(by t: Transform) -> [Vertex] {
        return map { $0.transformed(by: t) }
    }
}

public extension Vector {
    /// NOTE: no need for a translated() function because of the + operator

    func rotated(by m: Rotation) -> Vector {
        return Vector(
            x * m.m11 + y * m.m21 + z * m.m31,
            x * m.m12 + y * m.m22 + z * m.m32,
            x * m.m13 + y * m.m23 + z * m.m33
        )
    }

    func scaled(by v: Vector) -> Vector {
        return Vector(x * v.x, y * v.y, z * v.z)
    }

    func transformed(by t: Transform) -> Vector {
        return scaled(by: t.scale).rotated(by: t.rotation) + t.offset
    }
}

internal extension Collection where Element == Vector {
    /// NOTE: no need for a translated() function because of the + operator

    func rotated(by m: Rotation) -> [Vector] {
        return map { $0.rotated(by: m) }
    }

    func scaled(by v: Vector) -> [Vector] {
        return map { $0.scaled(by: v) }
    }

    func scaled(by f: Double) -> [Vector] {
        return map { $0 * f }
    }

    func transformed(by t: Transform) -> [Vector] {
        return map { $0.transformed(by: t) }
    }
}

public extension PathPoint {
    func translated(by v: Vector) -> PathPoint {
        return PathPoint(position + v, isCurved: isCurved)
    }

    func rotated(by r: Rotation) -> PathPoint {
        return PathPoint(position.rotated(by: r), isCurved: isCurved)
    }

    func scaled(by v: Vector) -> PathPoint {
        return PathPoint(position.scaled(by: v), isCurved: isCurved)
    }

    func scaled(by f: Double) -> PathPoint {
        return PathPoint(position * f, isCurved: isCurved)
    }

    func transformed(by t: Transform) -> PathPoint {
        return PathPoint(position.transformed(by: t), isCurved: isCurved)
    }
}

internal extension Collection where Element == PathPoint {
    func translated(by v: Vector) -> [PathPoint] {
        return map { $0.translated(by: v) }
    }

    func rotated(by m: Rotation) -> [PathPoint] {
        return map { $0.rotated(by: m) }
    }

    func scaled(by v: Vector) -> [PathPoint] {
        return map { $0.scaled(by: v) }
    }

    func scaled(by f: Double) -> [PathPoint] {
        return map { $0.scaled(by: f) }
    }

    func transformed(by t: Transform) -> [PathPoint] {
        return map { $0.transformed(by: t) }
    }
}

public extension Path {
    func translated(by v: Vector) -> Path {
        return Path(
            unchecked: points.translated(by: v),
            plane: plane?.translated(by: v), subpathIndices: subpathIndices
        )
    }

    func rotated(by r: Rotation) -> Path {
        return Path(
            unchecked: points.rotated(by: r),
            plane: plane?.rotated(by: r), subpathIndices: subpathIndices
        )
    }

    func scaled(by v: Vector) -> Path {
        return Path(
            unchecked: points.scaled(by: v),
            plane: plane?.scaled(by: v), subpathIndices: subpathIndices
        )
    }

    func scaled(by f: Double) -> Path {
        return Path(
            unchecked: points.scaled(by: f),
            plane: plane?.scaled(by: f), subpathIndices: subpathIndices
        )
    }

    func transformed(by t: Transform) -> Path {
        // TODO: manually transform plane so we can make this more efficient
        return Path(
            unchecked: points.transformed(by: t),
            plane: plane?.transformed(by: t), subpathIndices: subpathIndices
        )
    }
}

public extension Plane {
    func translated(by v: Vector) -> Plane {
        return Plane(unchecked: normal, pointOnPlane: normal * w + v)
    }

    func rotated(by r: Rotation) -> Plane {
        return Plane(unchecked: normal.rotated(by: r), w: w)
    }

    func scaled(by v: Vector) -> Plane {
        let vn = Vector(1 / v.x, 1 / v.y, 1 / v.z)
        let p = (normal * w).scaled(by: v)
        return Plane(unchecked: normal.scaled(by: vn).normalized(), pointOnPlane: p)
    }

    func scaled(by f: Double) -> Plane {
        return Plane(unchecked: normal, w: w * f)
    }

    func transformed(by t: Transform) -> Plane {
        return scaled(by: t.scale).rotated(by: t.rotation).translated(by: t.offset)
    }
}

public extension Bounds {
    func translated(by v: Vector) -> Bounds {
        return Bounds(min: min + v, max: max + v)
    }

    func rotated(by r: Rotation) -> Bounds {
        return Bounds(points: corners.rotated(by: r))
    }

    func scaled(by v: Vector) -> Bounds {
        return Bounds(min: min.scaled(by: v), max: max.scaled(by: v))
    }

    func scaled(by f: Double) -> Bounds {
        return Bounds(min: min * f, max: max * f)
    }

    func transformed(by t: Transform) -> Bounds {
        return Bounds(points: corners.transformed(by: t))
    }
}
