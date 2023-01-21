//
//  Direction.swift
//  Euclid
//
//  Created by Nick Lockwood on 21/01/2023.
//  Copyright © 2023 Nick Lockwood. All rights reserved.
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

/// A normalized direction vector in 3D space.
public struct Direction: Hashable, Sendable {
    /// The X component of the direction.
    public var x: Double
    /// The Y component of the direction.
    public var y: Double
    /// The Z component of the direction.
    public var z: Double

    /// Creates a direction from the values you provide.
    /// - Parameters:
    ///   - x: The X component of the direction.
    ///   - y: The Y component of the direction.
    ///   - z: The Z component of the direction.
    public init?(_ x: Double, _ y: Double, _ z: Double = 0) {
        let length = Vector(x, y, z).length
        guard length > 0 else {
            return nil
        }
        self.x = x / length
        self.y = y / length
        self.z = z / length
    }
}

extension Direction: XYZConvertible {
    public var xyzComponents: (x: Double, y: Double, z: Double) {
        (x, y, z)
    }
}

extension Direction: Codable {
    /// Creates a new direction by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let vector = try container.decode(Vector.self)
        guard let direction = Direction(vector) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Decoded direction vector has zero length"
            )
        }
        self = direction
    }

    /// Encodes the direction into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try Vector(self).encode(to: &container, skipZ: z == 0)
    }
}

public extension Direction {
    /// A direction along the X axis.
    static let x: Direction = .init(unchecked: 1, 0, 0)
    /// A direction along the Y axis.
    static let y: Direction = .init(unchecked: 0, 1, 0)
    /// A direction along the Z axis.
    static let z: Direction = .init(unchecked: 0, 0, 1)

    /// Initialize with some XYZConvertible value.
    init?<T: XYZConvertible>(_ value: T) {
        let components = value.xyzComponents
        self.init(components.x, components.y, components.z)
    }

    /// Initialize with any XYZConvertible value.
    @_disfavoredOverload
    init?(_ value: XYZConvertible) {
        let components = value.xyzComponents
        self.init(components.x, components.y, components.z)
    }

    /// An array containing the X, Y, and Z components of the direction vector.
    var components: [Double] {
        [x, y, z]
    }

    /// Returns the inverse direction.
    static prefix func - (rhs: Direction) -> Direction {
        .init(unchecked: -rhs.x, -rhs.y, -rhs.z)
    }

    /// Returns a vector representing a direction multiplied by a scale factor.
    static func * (lhs: Direction, rhs: Double) -> Vector {
        Vector(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs)
    }

    /// Returns a vector representing a direction multiplied by a scale factor.
    static func * (lhs: Double, rhs: Direction) -> Vector {
        Vector(lhs * rhs.x, lhs * rhs.y, lhs * rhs.z)
    }

    /// Computes the dot-product of this vector and another.
    /// - Parameter a: The direction with which to compute the dot product.
    /// - Returns: The dot product of the two direction vectors.
    func dot(_ a: Direction) -> Double {
        x * a.x + y * a.y + z * a.z
    }

    /// Computes the cross-product of this direction and another.
    /// - Parameter a: The direction with which to compute the cross product.
    /// - Returns: Returns a direction that is orthogonal to the other two.
    func cross(_ a: Direction) -> Direction {
        .init(unchecked: y * a.z - z * a.y, z * a.x - x * a.z, x * a.y - y * a.x)
    }

    /// Returns the angle between this direction and another.
    /// - Parameter a: The vector to compare with.
    func angle(with a: Direction) -> Angle {
        .acos(dot(a))
    }

    /// Returns the angle between this direction and the specified plane.
    /// - Parameter plane: The plane to compare with.
    func angle(with plane: Plane) -> Angle {
        .asin(dot(Direction(unchecked: plane.normal)))
    }
}

extension Direction {
    init(unchecked x: Double, _ y: Double, _ z: Double) {
        assert(Vector(x, y, z).length.isEqual(to: 1))
        self.x = x
        self.y = y
        self.z = z
    }

    init<T: XYZConvertible>(unchecked value: T) {
        let components = value.xyzComponents
        self.init(unchecked: components.x, components.y, components.z)
    }

    init(unchecked value: XYZConvertible) {
        let components = value.xyzComponents
        self.init(unchecked: components.x, components.y, components.z)
    }
}
