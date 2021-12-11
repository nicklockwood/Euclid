//
//  Vector.swift
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

/// A distance or position in 3D space
public struct Vector: Hashable {
    public var x, y, z: Double

    public init(_ x: Double, _ y: Double, _ z: Double = 0) {
        self.x = x
        self.y = y
        self.z = z
    }

    public func hash(into hasher: inout Hasher) {
        let precision = 1e-6
        hasher.combine((x / precision).rounded() * precision)
        hasher.combine((y / precision).rounded() * precision)
        hasher.combine((z / precision).rounded() * precision)
    }

    public static func == (lhs: Vector, rhs: Vector) -> Bool {
        lhs.isEqual(to: rhs, withPrecision: 1e-10)
    }
}

extension Vector: Comparable {
    /// Provides a stable sort order for Vectors
    public static func < (lhs: Vector, rhs: Vector) -> Bool {
        if lhs.x < rhs.x {
            return true
        } else if lhs.x > rhs.x {
            return false
        }
        if lhs.y < rhs.y {
            return true
        } else if lhs.y > rhs.y {
            return false
        }
        return lhs.z < rhs.z
    }
}

extension Vector: Codable {
    private enum CodingKeys: CodingKey {
        case x, y, z
    }

    public init(from decoder: Decoder) throws {
        if var container = try? decoder.unkeyedContainer() {
            try self.init(from: &container)
        } else {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let x = try container.decodeIfPresent(Double.self, forKey: .x) ?? 0
            let y = try container.decodeIfPresent(Double.self, forKey: .y) ?? 0
            let z = try container.decodeIfPresent(Double.self, forKey: .z) ?? 0
            self.init(x, y, z)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try encode(to: &container, skipZ: z == 0)
    }
}

/// Returns a new vector representing the min of the components of the passed vectors
public func min(_ lhs: Vector, _ rhs: Vector) -> Vector {
    Vector(min(lhs.x, rhs.x), min(lhs.y, rhs.y), min(lhs.z, rhs.z))
}

/// Returns a new vector representing the max of the components of the passed vectors
public func max(_ lhs: Vector, _ rhs: Vector) -> Vector {
    Vector(max(lhs.x, rhs.x), max(lhs.y, rhs.y), max(lhs.z, rhs.z))
}

public extension Vector {
    static let zero = Vector(0, 0, 0)
    static let one = Vector(1, 1, 1)

    /// Create a vector from an array of coordinates.
    /// Omitted values are defaulted to zero.
    init(_ components: [Double]) {
        switch components.count {
        case 0: self = .zero
        case 1: self.init(components[0], 0)
        case 2: self.init(components[0], components[1])
        default: self.init(components[0], components[1], components[2])
        }
    }

    /// Create a size/scale vector from an array of coordinates.
    /// Omitted values are defaulted to zero.
    init(size components: [Double]) {
        switch components.count {
        case 0: self = .one
        case 1: self.init(components[0], components[0], components[0])
        case 2: self.init(components[0], components[1], components[0])
        default: self.init(components)
        }
    }

    var components: [Double] {
        [x, y, z]
    }

    static prefix func - (rhs: Vector) -> Vector {
        Vector(-rhs.x, -rhs.y, -rhs.z)
    }

    static func + (lhs: Vector, rhs: Vector) -> Vector {
        Vector(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
    }

    static func += (lhs: inout Vector, rhs: Vector) {
        lhs.x += rhs.x
        lhs.y += rhs.y
        lhs.z += rhs.z
    }

    static func - (lhs: Vector, rhs: Vector) -> Vector {
        Vector(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z)
    }

    static func -= (lhs: inout Vector, rhs: Vector) {
        lhs.x -= rhs.x
        lhs.y -= rhs.y
        lhs.z -= rhs.z
    }

    static func * (lhs: Vector, rhs: Double) -> Vector {
        Vector(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs)
    }

    static func * (lhs: Double, rhs: Vector) -> Vector {
        Vector(lhs * rhs.x, lhs * rhs.y, lhs * rhs.z)
    }

    static func *= (lhs: inout Vector, rhs: Double) {
        lhs.x *= rhs
        lhs.y *= rhs
        lhs.z *= rhs
    }

    static func / (lhs: Vector, rhs: Double) -> Vector {
        Vector(lhs.x / rhs, lhs.y / rhs, lhs.z / rhs)
    }

    static func /= (lhs: inout Vector, rhs: Double) {
        lhs.x /= rhs
        lhs.y /= rhs
        lhs.z /= rhs
    }

    var lengthSquared: Double {
        dot(self)
    }

    var length: Double {
        lengthSquared.squareRoot()
    }

    func dot(_ a: Vector) -> Double {
        x * a.x + y * a.y + z * a.z
    }

    func cross(_ a: Vector) -> Vector {
        Vector(
            y * a.z - z * a.y,
            z * a.x - x * a.z,
            x * a.y - y * a.x
        )
    }

    var isNormalized: Bool {
        abs(lengthSquared - 1) < epsilon
    }

    func normalized() -> Vector {
        let length = self.length
        return length == 0 ? .zero : self / length
    }

    /// Linearly interpolate between two vectors
    func lerp(_ a: Vector, _ t: Double) -> Vector {
        self + (a - self) * t
    }

    func quantized() -> Vector {
        Vector(quantize(x), quantize(y), quantize(z))
    }

    func angle(with a: Vector) -> Angle {
        let cosineAngle = (dot(a) / (length * a.length))
        return Angle.acos(cosineAngle)
    }

    func angle(with plane: Plane) -> Angle {
        // We know that plane.normal.length == 1
        let complementeryAngle = dot(plane.normal) / length
        return Angle.asin(complementeryAngle)
    }

    /// Distance of the point from a plane
    /// A positive value is returned if the point lies in front of the plane
    /// A negative value is returned if the point lies behind the plane
    func distance(from plane: Plane) -> Double {
        plane.normal.dot(self) - plane.w
    }

    /// The nearest point to this point on the specified plane
    func project(onto plane: Plane) -> Vector {
        self - plane.normal * distance(from: plane)
    }

    /// Distance of the point from a line in 3D
    func distance(from line: Line) -> Double {
        line.distance(from: self)
    }

    /// The nearest point to this point on the specified line
    func project(onto line: Line) -> Vector {
        self + vectorFromPointToLine(self, line.origin, line.direction)
    }
}

internal extension Vector {
    func isIdentical(to other: Vector) -> Bool {
        x == other.x && y == other.y && z == other.z
    }

    // Approximate equality
    func isEqual(to other: Vector, withPrecision p: Double = epsilon) -> Bool {
        isIdentical(to: other) || (
            x.isEqual(to: other.x, withPrecision: p) &&
                y.isEqual(to: other.y, withPrecision: p) &&
                z.isEqual(to: other.z, withPrecision: p)
        )
    }

    func compare(with plane: Plane) -> PlaneComparison {
        let t = distance(from: plane)
        return (t < -epsilon) ? .back : (t > epsilon) ? .front : .coplanar
    }

    /// Encode directly into an unkeyedContainer
    func encode(to container: inout UnkeyedEncodingContainer) throws {
        try encode(to: &container, skipZ: false)
    }

    /// Encode directly into an unkeyedContainer
    func encode(to container: inout UnkeyedEncodingContainer, skipZ: Bool) throws {
        try container.encode(x)
        try container.encode(y)
        try skipZ ? () : container.encode(z)
    }

    /// Decode directly from an unkeyedContainer
    init(from container: inout UnkeyedDecodingContainer) throws {
        self.x = try container.decode(Double.self)
        self.y = try container.decode(Double.self)
        self.z = try container.decodeIfPresent(Double.self) ?? 0
    }
}
