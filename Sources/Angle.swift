//
//  Angle.swift
//  Euclid
//
//  Created by Ioannis Kaliakatsos on 22.11.20.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
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

/// An angle or 2D rotation.
public struct Angle: Hashable, Comparable, Sendable, AdditiveArithmetic {
    /// The angle in radians.
    public var radians: Double {
        didSet { radians = radians.isFinite ? radians : 0 }
    }

    /// Creates an angle from a radians value.
    /// - Parameter radians: The angle in radians.
    public init(radians: Double) {
        self.radians = radians.isFinite ? radians : 0
    }
}

extension Angle: CustomStringConvertible {
    public var description: String {
        "Angle(radians: \(radians))"
    }
}

extension Angle: Codable {
    private enum CodingKeys: CodingKey {
        case radians, degrees
    }

    /// Creates a new angle by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        if let radians = try? decoder.singleValueContainer().decode(Double.self) {
            self.init(radians: radians)
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let degrees = try container.decodeIfPresent(Double.self, forKey: .degrees) {
            self.init(degrees: degrees)
            return
        }
        try self.init(radians: container.decode(Double.self, forKey: .radians))
    }

    /// Encodes this angle into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        try radians.encode(to: encoder)
    }
}

/// Computes the trigonometric cosine of an angle.
/// - Parameter angle: The angle to calculate the cosine for.
/// - Returns: The trigonometric cosine of the angle.
@_disfavoredOverload
public func cos(_ angle: Angle) -> Double {
    cos(angle.radians)
}

/// Computes the trigonometric sine of an angle.
/// - Parameter angle: The angle to calculate the sine for.
/// - Returns: The trigonometric sine of the angle.
@_disfavoredOverload
public func sin(_ angle: Angle) -> Double {
    sin(angle.radians)
}

/// Computes the trigonometric tangent of an angle.
/// - Parameter angle: The angle to calculate the tangent for.
/// - Returns: The trigonometric tangent of the angle.
@_disfavoredOverload
public func tan(_ angle: Angle) -> Double {
    tan(angle.radians)
}

public extension Angle {
    /// Angle representing a zero (identity) rotation.
    static let zero = Angle.radians(0)
    /// Angle representing a quarter rotation.
    static let halfPi = Angle.radians(.pi / 2)
    /// Angle representing a half-rotation.
    static let pi = Angle.radians(.pi)
    /// Angle representing a full rotation.
    static let twoPi = Angle.radians(.pi * 2)

    /// The angle in degrees.
    var degrees: Double {
        get { radians * 180 / .pi }
        set { radians = newValue / 180 * .pi }
    }

    /// The angle is zero (or close to zero).
    var isZero: Bool {
        isEqual(to: .zero)
    }

    /// Creates an Angle from a degrees value.
    /// - Parameter degrees: The angle in degrees.
    init(degrees: Double) {
        self.init(radians: degrees / 180 * .pi)
    }

    /// Creates an angle from a degrees value.
    /// - Parameter degrees: The angle in degrees.
    static func degrees(_ degrees: Double) -> Angle {
        Angle(degrees: degrees)
    }

    /// Creates an angle from a radians value.
    /// - Parameter radians: The angle in radians.
    static func radians(_ radians: Double) -> Angle {
        Angle(radians: radians)
    }

    /// Creates an angle representing the trigonometric arc cosine of the value you provide.
    /// - Parameter cos: The cosine value to use to calculate the angle.
    static func acos(_ cos: Double) -> Angle {
        .radians(Foundation.acos(min(1, max(-1, cos))))
    }

    /// Creates an angle representing the trigonometric arc sine of the value you provide.
    /// - Parameter sin: The sine value to use to calculate the angle.
    static func asin(_ sin: Double) -> Angle {
        .radians(Foundation.asin(min(1, max(-1, sin))))
    }

    /// Creates an angle representing the trigonometric arc tangent of the value you provide.
    /// - Parameter tan: The tangent value to use to calculate the angle.
    static func atan(_ tan: Double) -> Angle {
        .radians(Foundation.atan(tan))
    }

    /// Creates an angle representing the trigonometric arc tangent of the vector you provide.
    /// - Parameters:
    ///   - y: The Y component of the input vector
    ///   - x: The X component of the input vector
    static func atan2(y: Double, x: Double) -> Angle {
        .radians(Foundation.atan2(y, x))
    }

    /// Returns the sum of two angles.
    static func + (lhs: Angle, rhs: Angle) -> Angle {
        .radians(lhs.radians + rhs.radians)
    }

    /// Returns the difference between two angles.
    static func - (lhs: Angle, rhs: Angle) -> Angle {
        .radians(lhs.radians - rhs.radians)
    }

    /// Returns the product of an angle and numeric multiplier.
    static func * (lhs: Angle, rhs: Double) -> Angle {
        .radians(lhs.radians * rhs)
    }

    /// Returns the product of a numeric multiplier and an angle.
    static func * (lhs: Double, rhs: Angle) -> Angle {
        .radians(lhs * rhs.radians)
    }

    /// Multiplies the angle by a numeric value.
    static func *= (lhs: inout Angle, rhs: Double) {
        lhs.radians *= rhs
    }

    /// Returns the angle divided by a numeric denominator.
    static func / (lhs: Angle, rhs: Double) -> Angle {
        .radians(lhs.radians / rhs)
    }

    /// Divides the angle by a numeric denominator.
    static func /= (lhs: inout Angle, rhs: Double) {
        lhs.radians /= rhs
    }

    /// Returns the inverse angle.
    static prefix func - (angle: Angle) -> Angle {
        .radians(-angle.radians)
    }

    /// Returns whether the leftmost angle has the lower value.
    static func < (lhs: Angle, rhs: Angle) -> Bool {
        lhs.radians < rhs.radians
    }
}

extension Angle {
    /// Approximate equality
    func isEqual(to other: Angle, withPrecision p: Double = epsilon) -> Bool {
        radians.isEqual(to: other.radians, withPrecision: p)
    }
}
