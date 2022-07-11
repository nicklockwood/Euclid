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

/// A distance or position in 3D space.
///
/// > Note: Euclid doesn't have a 2D vector type. When working with primarily 2D shapes, such as
/// ``Path``s, you can omit the ``z`` component when constructing vector and it will default to zero.
public struct Vector: Hashable, Sendable {
    /// The X component of the vector.
    public var x: Double
    /// The Y component of the vector.
    public var y: Double
    /// The Z component of the vector.
    public var z: Double

    /// Creates a vector from the values you provide.
    /// - Parameters:
    ///   - x: The X component of the vector.
    ///   - y: The Y component of the vector.
    ///   - z: The Z component of the vector.
    public init(_ x: Double, _ y: Double, _ z: Double = 0) {
        self.x = x
        self.y = y
        self.z = z
    }
}

extension Vector: Comparable {
    /// Returns whether the leftmost vector has the lower value.
    /// This provides a stable order when sorting collections of vectors.
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

    /// Creates a new vector by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
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

    /// Encodes the vector into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try encode(to: &container, skipZ: z == 0)
    }
}

/// Returns a new vector that represents the mininum of the components of the two vectors.
public func min(_ lhs: Vector, _ rhs: Vector) -> Vector {
    Vector(min(lhs.x, rhs.x), min(lhs.y, rhs.y), min(lhs.z, rhs.z))
}

/// Returns a new vector representing the maximum of the components of the two vectors.
public func max(_ lhs: Vector, _ rhs: Vector) -> Vector {
    Vector(max(lhs.x, rhs.x), max(lhs.y, rhs.y), max(lhs.z, rhs.z))
}

public extension Vector {
    /// A zero-length vector.
    static let zero = Vector(0, 0, 0)
    /// A vector with all coordinates set to `1`.
    static let one = Vector(1, 1, 1)

    /// Creates a vector from an array of coordinates.
    /// - Parameter components: An array of vector components.
    ///
    /// Omitted values default to `0` and extra components are ignored.
    init(_ components: [Double]) {
        switch components.count {
        case 0: self = .zero
        case 1: self.init(components[0], 0)
        case 2: self.init(components[0], components[1])
        default: self.init(components[0], components[1], components[2])
        }
    }

    /// Creates a size/scale vector from an array of two coordinates.
    /// - Parameter components: An array of vector components.
    ///
    /// Omitted values are set equal to the first value specified.
    /// If no values as specified, the size defaults to ``one``.
    init(size components: [Double]) {
        switch components.count {
        case 0: self = .one
        case 1: self.init(components[0], components[0], components[0])
        case 2: self.init(components[0], components[1], components[0])
        default: self.init(components)
        }
    }

    /// Creates a vector of uniform size.
    /// - Parameter size: The value to use for all components.
    init(size: Double) {
        self.init(size, size, size)
    }

    /// An array containing the X, Y, and Z components of the vector.
    var components: [Double] {
        [x, y, z]
    }

    /// Returns a vector with all components inverted.
    static prefix func - (rhs: Vector) -> Vector {
        Vector(-rhs.x, -rhs.y, -rhs.z)
    }

    /// Returns the componentwise sum of two vectors.
    static func + (lhs: Vector, rhs: Vector) -> Vector {
        Vector(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
    }

    /// Adds the components of the vector on the right to the ones on the left.
    static func += (lhs: inout Vector, rhs: Vector) {
        lhs.x += rhs.x
        lhs.y += rhs.y
        lhs.z += rhs.z
    }

    /// Returns the componentwise difference between two vectors.
    static func - (lhs: Vector, rhs: Vector) -> Vector {
        Vector(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z)
    }

    /// Subtracts the components of the vector on the right from the ones on the left.
    static func -= (lhs: inout Vector, rhs: Vector) {
        lhs.x -= rhs.x
        lhs.y -= rhs.y
        lhs.z -= rhs.z
    }

    /// Returns a vector with its components multiplied by the specified value.
    static func * (lhs: Vector, rhs: Double) -> Vector {
        Vector(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs)
    }

    /// Returns a vector with its components multiplied by the specified value.
    static func * (lhs: Double, rhs: Vector) -> Vector {
        Vector(lhs * rhs.x, lhs * rhs.y, lhs * rhs.z)
    }

    /// Multiplies the components of the vector by the specified value.
    static func *= (lhs: inout Vector, rhs: Double) {
        lhs.x *= rhs
        lhs.y *= rhs
        lhs.z *= rhs
    }

    /// Returns a vector with its components divided by the specified value.
    static func / (lhs: Vector, rhs: Double) -> Vector {
        Vector(lhs.x / rhs, lhs.y / rhs, lhs.z / rhs)
    }

    /// Divides the components of the vector by the value you provide.
    static func /= (lhs: inout Vector, rhs: Double) {
        lhs.x /= rhs
        lhs.y /= rhs
        lhs.z /= rhs
    }

    /// The magnitude of the vector.
    var length: Double {
        lengthSquared.squareRoot()
    }

    /// The square of the length of the vector. This is less expensive to compute than the length itself.
    var lengthSquared: Double {
        dot(self)
    }

    /// Computes the dot-product of this vector and another.
    /// - Parameter a: The vector with which to compute the dot product.
    /// - Returns: The dot product of the two vectors.
    func dot(_ a: Vector) -> Double {
        x * a.x + y * a.y + z * a.z
    }

    /// Computes the cross-product of this vector and another.
    /// - Parameter a: The vector with which to compute the cross product.
    /// - Returns: Returns a vector that is orthogonal to the two vectors used to compute the cross product.
    func cross(_ a: Vector) -> Vector {
        Vector(y * a.z - z * a.y, z * a.x - x * a.z, x * a.y - y * a.x)
    }

    /// A Boolean value that indicates whether the vector has a length of `1`.
    var isNormalized: Bool {
        abs(lengthSquared - 1) < epsilon
    }

    /// Returns a normalized vector.
    /// - Returns: The normalized vector (with a length of `1`) or the ``zero`` vector if the length is `0`.
    func normalized() -> Vector {
        let length = self.length
        return length == 0 ? .zero : self / length
    }

    /// Linearly interpolate between this vector and another.
    /// - Parameters:
    ///   - a: The vector to interpolate towards.
    ///   - t: The normalized extent of interpolation, from 0 to 1.
    func lerp(_ a: Vector, _ t: Double) -> Vector {
        self + (a - self) * t
    }

    @available(*, deprecated, message: "Obsolete. Do not use.")
    func quantized() -> Vector { _quantized() }

    /// Returns the angle between this vector and another.
    /// - Parameter a: The vector to compare with.
    func angle(with a: Vector) -> Angle {
        .acos(normalized().dot(a.normalized()))
    }

    /// Returns the angle between this vector and the specified plane.
    /// - Parameter plane: The plane to compare with.
    func angle(with plane: Plane) -> Angle {
        .asin(normalized().dot(plane.normal))
    }

    /// Returns the distance between the vector (representing a position in space) from the specified plane.
    /// - Parameter plane: The plane to compare with.
    /// - Returns: The distance between the point and the plane. The value is positive if the point lies
    ///   in front of the plane, and negative if behind.
    func distance(from plane: Plane) -> Double {
        plane.normal.dot(self) - plane.w
    }

    /// Returns the nearest point on the specified plane to the vector (representing a position in space).
    /// - Parameter plane: The plane to project onto.
    /// - Returns: The nearest point in 3D space that lies on the plane.
    func project(onto plane: Plane) -> Vector {
        self - plane.normal * distance(from: plane)
    }

    /// Returns the distance between the vector (representing a position in space) from the specified line.
    /// - Parameter line: The line to compare with.
    /// - Returns: The absolute perpendicular distance between the point and line.
    func distance(from line: Line) -> Double {
        line.distance(from: self)
    }

    /// Returns the nearest point on the specified line to the vector (representing a position in space).
    /// - Parameter line: The line to project onto.
    /// - Returns: The nearest point in 3D space that lies on the line.
    func project(onto line: Line) -> Vector {
        self + vectorFromPointToLine(self, line.origin, line.direction)
    }
}

internal extension Vector {
    static let unitX = Vector(1, 0, 0)
    static let unitY = Vector(0, 1, 0)
    static let unitZ = Vector(0, 0, 1)

    func _quantized() -> Vector {
        Vector(quantize(x), quantize(y), quantize(z))
    }

    func hashValues(withPrecision precision: Double) -> Set<Vector> {
        let xf = floor(x / precision) * precision
        let xc = ceil(x / precision) * precision
        let yf = floor(y / precision) * precision
        let yc = ceil(y / precision) * precision
        let zf = floor(z / precision) * precision
        let zc = ceil(z / precision) * precision
        return [
            Vector(xf, yf, zf),
            Vector(xf, yf, zc),
            Vector(xf, yc, zf),
            Vector(xf, yc, zc),
            Vector(xc, yf, zf),
            Vector(xc, yf, zc),
            Vector(xc, yc, zf),
            Vector(xc, yc, zc),
        ]
    }

    // Approximate equality
    func isEqual(to other: Vector, withPrecision p: Double = epsilon) -> Bool {
        x.isEqual(to: other.x, withPrecision: p) &&
            y.isEqual(to: other.y, withPrecision: p) &&
            z.isEqual(to: other.z, withPrecision: p)
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
