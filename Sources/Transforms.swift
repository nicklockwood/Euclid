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

// a rotation matrix
public struct Rotation: Hashable {
    var m11: Double
    var m12: Double
    var m13: Double
    var m21: Double
    var m22: Double
    var m23: Double
    var m31: Double
    var m32: Double
    var m33: Double
}

public extension Rotation {
    static let identity = Rotation()

    /// Define a rotation using 3x3 matrix coefficients
    init(_ m11: Double, _ m12: Double, _ m13: Double,
         _ m21: Double, _ m22: Double, _ m23: Double,
         _ m31: Double, _ m32: Double, _ m33: Double) {
        assert(!m11.isNaN)
        self.m11 = m11
        self.m12 = m12
        self.m13 = m13
        self.m21 = m21
        self.m22 = m22
        self.m23 = m23
        self.m31 = m31
        self.m32 = m32
        self.m33 = m33
    }

    /// Creates an identity Rotation
    init() {
        self.init(1, 0, 0, 0, 1, 0, 0, 0, 1)
    }

    /// Define a rotation around the Y axis
    init(yaw radians: Double) {
        let c = cos(radians)
        let s = sin(radians)
        self.init(
            c, -s, 0,
            s, c, 0,
            0, 0, 1
        )
    }

    /// Define a rotation around the X axis
    init(pitch radians: Double) {
        let c = cos(radians)
        let s = sin(radians)
        self.init(
            c, 0, s,
            0, 1, 0,
            -s, 0, c
        )
    }

    /// Define a rotation around the Z axis
    init(roll radians: Double) {
        let c = cos(radians)
        let s = sin(radians)
        self.init(
            1, 0, 0,
            0, c, -s,
            0, s, c
        )
    }

    /// Define a rotation from an axis vector and an angle
    init?(axis: Vector, radians: Double) {
        let length = axis.length
        if length < epsilon || length.isNaN {
            return nil
        }
        self.init(unchecked: axis / length, radians: radians)
    }

    /// Define a rotation from Euler angles
    // http://planning.cs.uiuc.edu/node102.html
    init(yaw: Double = 0, pitch: Double = 0, roll: Double = 0) {
        self.init()
        if yaw != 0 {
            self *= Rotation(yaw: yaw)
        }
        if pitch != 0 {
            self *= Rotation(pitch: pitch)
        }
        if roll != 0 {
            self *= Rotation(roll: roll)
        }
    }

    // http://planning.cs.uiuc.edu/node103.html
    var yaw: Double {
        return atan2(m21, m11)
    }

    var pitch: Double {
        return atan2(-m31, sqrt(m32 * m32 + m33 * m33))
    }

    var roll: Double {
        return atan2(m32, m33)
    }

    static prefix func - (rhs: Rotation) -> Rotation {
        // transpose matrix
        return Rotation(
            rhs.m11,
            rhs.m21,
            rhs.m31,
            rhs.m12,
            rhs.m22,
            rhs.m32,
            rhs.m13,
            rhs.m23,
            rhs.m33
        )
    }

    static func * (lhs: Rotation, rhs: Rotation) -> Rotation {
        return Rotation(
            lhs.m11 * rhs.m11 + lhs.m21 * rhs.m12 + lhs.m31 * rhs.m13,
            lhs.m12 * rhs.m11 + lhs.m22 * rhs.m12 + lhs.m32 * rhs.m13,
            lhs.m13 * rhs.m11 + lhs.m23 * rhs.m12 + lhs.m33 * rhs.m13,
            lhs.m11 * rhs.m21 + lhs.m21 * rhs.m22 + lhs.m31 * rhs.m23,
            lhs.m12 * rhs.m21 + lhs.m22 * rhs.m22 + lhs.m32 * rhs.m23,
            lhs.m13 * rhs.m21 + lhs.m23 * rhs.m22 + lhs.m33 * rhs.m23,
            lhs.m11 * rhs.m31 + lhs.m21 * rhs.m32 + lhs.m31 * rhs.m33,
            lhs.m12 * rhs.m31 + lhs.m22 * rhs.m32 + lhs.m32 * rhs.m33,
            lhs.m13 * rhs.m31 + lhs.m23 * rhs.m32 + lhs.m33 * rhs.m33
        )
    }

    static func *= (lhs: inout Rotation, rhs: Rotation) {
        lhs = lhs * rhs
    }
}

internal extension Rotation {
    // http://www.euclideanspace.com/maths/geometry/rotations/conversions/angleToMatrix/
    init(unchecked axis: Vector, radians: Double) {
        assert(axis.isNormalized)
        let c = cos(radians)
        let s = sin(radians)
        let t = 1 - c
        let x = axis.x
        let y = axis.y
        let z = axis.z
        self.init(
            t * x * x + c, t * x * y - z * s, t * x * z + y * s,
            t * x * y + z * s, t * y * y + c, t * y * z - x * s,
            t * x * z - y * s, t * y * z + x * s, t * z * z + c
        )
    }
}

public struct Transform: Hashable {
    public var offset: Vector
    public var rotation: Rotation
    public var scale: Vector

    public init(
        offset: Vector = .zero,
        rotation: Rotation = .identity,
        scale: Vector = .init(1, 1, 1)
    ) {
        self.offset = offset
        self.rotation = rotation
        self.scale = scale
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

    mutating func rotate(by yaw: Double, _ pitch: Double, _ roll: Double) {
        rotation *= Rotation(yaw: yaw, pitch: pitch, roll: roll)
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
        return Mesh(polygons.map { $0.translated(by: v) })
    }

    func rotated(by m: Rotation) -> Mesh {
        return Mesh(polygons.map { $0.rotated(by: m) })
    }

    func scaled(by v: Vector) -> Mesh {
        if v.x == v.y, v.y == v.z {
            // optimization - avoids scaling normals
            return scaled(by: v.x)
        }
        return Mesh(polygons.map { $0.scaled(by: v) })
    }

    func scaled(by f: Double) -> Mesh {
        return Mesh(polygons.map { $0.scaled(by: f) })
    }

    func scaleCorrected(for v: Vector) -> Mesh {
        return Mesh(polygons.map { $0.scaleCorrected(for: v) })
    }

    func transformed(by transform: Transform) -> Mesh {
        return scaled(by: transform.scale)
            .rotated(by: transform.rotation)
            .translated(by: transform.offset)
    }
}

public extension Polygon {
    func translated(by v: Vector) -> Polygon {
        let vertices = self.vertices.map { $0.translated(by: v) }
        return Polygon(
            unchecked: vertices,
            normal: plane.normal,
            isConvex: isConvex,
            material: material
        )
    }

    func rotated(by m: Rotation) -> Polygon {
        return Polygon(
            unchecked: vertices.map { $0.rotated(by: m) },
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

        let vertices = self.vertices.map { $0.scaled(by: v) }
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
            unchecked: vertices.map { $0.scaled(by: f) },
            normal: plane.normal,
            isConvex: isConvex,
            material: material
        )
        return f < 0 ? polygon.inverted() : polygon
    }

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
}

public extension Vector {
    func rotated(by m: Rotation) -> Vector {
        return Vector(
            x * m.m11 + y * m.m21 + z * m.m31,
            x * m.m12 + y * m.m22 + z * m.m32,
            x * m.m13 + y * m.m23 + z * m.m33
        )
    }

    func scaled(by scale: Vector) -> Vector {
        return Vector(x * scale.x, y * scale.y, z * scale.z)
    }

    func transformed(by transform: Transform) -> Vector {
        return rotated(by: transform.rotation).scaled(by: transform.scale) + transform.offset
    }
}

public extension PathPoint {
    func scaled(by scale: Vector) -> PathPoint {
        return PathPoint(position.scaled(by: scale), isCurved: isCurved)
    }

    func transformed(by transform: Transform) -> PathPoint {
        return PathPoint(position.transformed(by: transform), isCurved: isCurved)
    }
}

public extension Path {
    func scaled(by scale: Vector) -> Path {
        return Path(unchecked: points.map {
            $0.scaled(by: scale)
        })
    }

    func transformed(by transform: Transform) -> Path {
        // TODO: manually transform plane so we can make this more efficient
        return Path(unchecked: points.map {
            $0.transformed(by: transform)
        })
    }
}

public extension Bounds {
    func transformed(by transform: Transform) -> Bounds {
        return Bounds(points: corners.map {
            $0.transformed(by: transform)
        })
    }
}
