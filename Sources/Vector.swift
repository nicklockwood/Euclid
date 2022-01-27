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
/// Euclid doesn't include 2D vector types.
/// When working with primarily 2D shapes, such as  creating ``Path`` objects, omit the Z coordinate when constructing a `Vector` and it defaults to zero.
public struct Vector: Hashable {
    /// The first component of the vector, frequently representing the value on the X axis.
    public var x: Double
    /// The second component of the vector, frequently representing the value on the Y axis.
    public var y: Double
    /// The third component of the vector, frequently representing the value on the Z axis.
    public var z: Double
    
    /// Creates a vector from the values you provide.
    /// - Parameters:
    ///   - x: The ``x`` value for the vector.
    ///   - y: The ``y`` value for the vector.
    ///   - z: The ``z`` value for the vector.
    public init(_ x: Double, _ y: Double, _ z: Double = 0) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    /// Hashes the essential components of the vector by feeding them into the hasher you provide.
    /// - Parameter hasher: The hasher to use when combining the components of this instance.
    public func hash(into hasher: inout Hasher) {
        let precision = 1e-6
        hasher.combine((x / precision).rounded() * precision)
        hasher.combine((y / precision).rounded() * precision)
        hasher.combine((z / precision).rounded() * precision)
    }
    
    /// Returns a Boolean value that indicates if the two vectors are approximately equal, within a precision of 1e-10.
    public static func == (lhs: Vector, rhs: Vector) -> Bool {
        lhs.isEqual(to: rhs, withPrecision: 1e-10)
    }
}

extension Vector: Comparable {
    /// Returns a Boolean value that compares two vectors to provide a stable sort order.
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
    
    /// Encodes this date into the given encoder.
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
    /// - Parameter components: An array of coordinate positions.
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
    /// - Parameter components: An array of coordinate positions.
    ///
    /// Omitted values are defaulted to `0` and extra components are ignored.
    /// An empty array of coordinates defaults to ``one``.
    init(size components: [Double]) {
        switch components.count {
        case 0: self = .one
        case 1: self.init(components[0], components[0], components[0])
        case 2: self.init(components[0], components[1], components[0])
        default: self.init(components)
        }
    }

    /// Creates a vector of uniform size that you provide.
    init(size: Double) {
        self.init(size, size, size)
    }
    
    /// An array of the components of the vector.
    var components: [Double] {
        [x, y, z]
    }
    
    /// Returns a vector with the values inverted.
    static prefix func - (rhs: Vector) -> Vector {
        Vector(-rhs.x, -rhs.y, -rhs.z)
    }
    
    /// Returns a vector that is the sum of the vectors you provide.
    /// - Parameters:
    ///   - lhs: The first vector.
    ///   - rhs: The second vector.
    static func + (lhs: Vector, rhs: Vector) -> Vector {
        Vector(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
    }
    
    /// Extends the vector by a vector you provide.
    static func += (lhs: inout Vector, rhs: Vector) {
        lhs.x += rhs.x
        lhs.y += rhs.y
        lhs.z += rhs.z
    }
    
    /// Returns a vector that is the difference of the vectors you provide.
    /// - Parameters:
    ///   - lhs: The first vector.
    ///   - rhs: The second vector.
    static func - (lhs: Vector, rhs: Vector) -> Vector {
        Vector(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z)
    }
    
    /// Reduces the vector by a vector you provide.
    static func -= (lhs: inout Vector, rhs: Vector) {
        lhs.x -= rhs.x
        lhs.y -= rhs.y
        lhs.z -= rhs.z
    }
    
    /// Returns a vector with its components multiplied by the value you provide.
    static func * (lhs: Vector, rhs: Double) -> Vector {
        Vector(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs)
    }

    /// Returns a vector with its components multiplied by the value you provide.
    static func * (lhs: Double, rhs: Vector) -> Vector {
        Vector(lhs * rhs.x, lhs * rhs.y, lhs * rhs.z)
    }
    
    /// Multiplies the components of the vector by the value you provide.
    static func *= (lhs: inout Vector, rhs: Double) {
        lhs.x *= rhs
        lhs.y *= rhs
        lhs.z *= rhs
    }
    
    /// Returns a vector with its components divided by the value you provide.
    static func / (lhs: Vector, rhs: Double) -> Vector {
        Vector(lhs.x / rhs, lhs.y / rhs, lhs.z / rhs)
    }
    
    /// Divides the components of the vector by the value you provide.
    static func /= (lhs: inout Vector, rhs: Double) {
        lhs.x /= rhs
        lhs.y /= rhs
        lhs.z /= rhs
    }
    
    /// The length of vector, squared.
    var lengthSquared: Double {
        dot(self)
    }

    /// The length of vector.
    var length: Double {
        lengthSquared.squareRoot()
    }
    
    /// Computes the dot-product of this vector and another you provide.
    /// - Parameter a: The vector against which to compute a dot product.
    /// - Returns: A double that indicates the value to which one vector applies to another.
    func dot(_ a: Vector) -> Double {
        x * a.x + y * a.y + z * a.z
    }
    
    /// Computes the cross-product of this vector and another you provide.
    /// - Parameter a: The vector against which to compute a cross product.
    /// - Returns: Returns a vector that is orthogonal to the two vectors used to compute the cross product.
    func cross(_ a: Vector) -> Vector {
        Vector(
            y * a.z - z * a.y,
            z * a.x - x * a.z,
            x * a.y - y * a.x
        )
    }
    
    /// A Boolean value that indicates the vector has a length effectively equivalent to `1`.
    var isNormalized: Bool {
        abs(lengthSquared - 1) < epsilon
    }
    
    /// Returns a normalized vector..
    /// - Returns: The normalized vector with a length of `1`, or the ``zero`` vector if the length is `0`.
    func normalized() -> Vector {
        let length = self.length
        return length == 0 ? .zero : self / length
    }

    /// Linearly interpolate between this vector and another you provide.
    /// - Parameters:
    ///   - a: The vector to interpolate towards.
    ///   - t: A value, typically between `0` and `1`, to indicate the position  to interpolate between the two vectors.
    /// - Returns: <#description#>
    func lerp(_ a: Vector, _ t: Double) -> Vector {
        self + (a - self) * t
    }
    
    /// Returns a vectors with its component values explicitly rounded to the nearest quanta.
    ///
    /// The precion of the quantized value is defined within Euclid to round off values to avoid cracks, breaks, and math errors while computing surface within constructive solid geometry operations.
    func quantized() -> Vector {
        Vector(quantize(x), quantize(y), quantize(z))
    }
    
    /// Returns the angle between this vector and another that you provide.
    /// - Parameter a: The vector to compare.
    func angle(with a: Vector) -> Angle {
        let cosineAngle = (dot(a) / (length * a.length))
        return Angle.acos(cosineAngle)
    }
    
    /// Returns the angle between this vector and the plane that you provide.
    /// - Parameter plane: The plane to compare.
    func angle(with plane: Plane) -> Angle {
        // We know that plane.normal.length == 1
        let complementeryAngle = dot(plane.normal) / length
        return Angle.asin(complementeryAngle)
    }

    /// Returns the distance of the vector represented as a point from the plane you provide.
    /// - Parameter plane: The plane to compare.
    /// - Returns: The distance between the point and the plane. The value is positive if the point lies in front of the plane, and negative if behind.
    func distance(from plane: Plane) -> Double {
        plane.normal.dot(self) - plane.w
    }

    /// Returns the nearest point to the vector representing a point on the specified plane.
    /// - Parameter plane: The plane to compare.
    func project(onto plane: Plane) -> Vector {
        self - plane.normal * distance(from: plane)
    }

    /// Returns the distance of the vector representing a point to a line in 3D.
    /// - Parameter line: The line to compare.
    func distance(from line: Line) -> Double {
        line.distance(from: self)
    }

    /// Returns a vector that represents the nearest point on the line you provide.
    /// - Parameter line: The line to compare.
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
