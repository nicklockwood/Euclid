//
//  Rotation.swift
//  Euclid
//
//  Created by Nick Lockwood on 04/01/2020.
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

/// A struct that represents an orientation or rotation in 3D space.
///
/// Internally, a rotation is stored as a 3x3 matrix, but that's an implementation detail that may change in future.
/// A rotation can be converted to and from an axis vector and angle, or a set of 3 Euler angles (pitch, yaw and roll).
public struct Rotation: Hashable, Sendable {
    var quaternion: Quaternion
}

extension Rotation: Codable {
    private enum CodingKeys: CodingKey {
        case axis, x, y, z, radians
    }

    private struct Matrix {
        var m11, m12, m13, m21, m22, m23, m31, m32, m33: Double

        // https://www.euclideanspace.com/maths/algebra/matrix/functions/determinant/threeD/
        private var determinant: Double {
            m11 * m22 * m33 + m12 * m23 * m31 + m13 * m21 * m32 -
                m11 * m23 * m32 - m12 * m21 * m33 - m13 * m22 * m31
        }

        private var isRotationMatrix: Bool {
            let epsilon = 0.01
            if abs(determinant - 1) > epsilon {
                return false
            }
            // check transpose == inverse
            if abs(m22 * m33 - m23 * m32 - m11) > epsilon { return false }
            if abs(m13 * m32 - m12 * m33 - m21) > epsilon { return false }
            if abs(m12 * m23 - m13 * m22 - m31) > epsilon { return false }
            if abs(m23 * m31 - m21 * m33 - m12) > epsilon { return false }
            if abs(m11 * m33 - m13 * m31 - m22) > epsilon { return false }
            if abs(m13 * m21 - m11 * m23 - m32) > epsilon { return false }
            if abs(m21 * m32 - m22 * m31 - m13) > epsilon { return false }
            if abs(m12 * m31 - m11 * m32 - m23) > epsilon { return false }
            if abs(m11 * m22 - m12 * m21 - m33) > epsilon { return false }
            return true
        }

        init(from container: inout UnkeyedDecodingContainer) throws {
            self.m11 = try container.decode(Double.self)
            self.m12 = try container.decode(Double.self)
            self.m13 = try container.decode(Double.self)
            self.m21 = try container.decode(Double.self)
            self.m22 = try container.decode(Double.self)
            self.m23 = try container.decode(Double.self)
            self.m31 = try container.decode(Double.self)
            self.m32 = try container.decode(Double.self)
            self.m33 = try container.decode(Double.self)
            guard isRotationMatrix else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Not a rotation matrix"
                )
            }
        }
    }

    private init(_ r: Matrix) {
        let x = sqrt(max(0, 1 + r.m11 - r.m22 - r.m33)) / 2
        let y = sqrt(max(0, 1 - r.m11 + r.m22 - r.m33)) / 2
        let z = sqrt(max(0, 1 - r.m11 - r.m22 + r.m33)) / 2
        let w = sqrt(max(0, 1 + r.m11 + r.m22 + r.m33)) / 2
        self.init(Quaternion(
            x * (x * (r.m32 - r.m23) < 0 ? 1 : -1),
            y * (y * (r.m13 - r.m31) < 0 ? 1 : -1),
            z * (z * (r.m21 - r.m12) < 0 ? 1 : -1),
            w
        ))
    }

    /// Creates a new rotation by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        guard var container = try? decoder.unkeyedContainer() else {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let angle = try container.decodeIfPresent(Angle.self, forKey: .radians)
            var axis = try container.decodeIfPresent(Vector.self, forKey: .axis)
            if let x = try container.decodeIfPresent(Double.self, forKey: .x) {
                let y = try container.decode(Double.self, forKey: .y)
                let z = try container.decode(Double.self, forKey: .z)
                axis = Vector(x, y, z)
            }
            self.init(unchecked: axis?.normalized() ?? .unitZ, angle: angle ?? .zero)
            return
        }
        switch container.count ?? 0 {
        case 0:
            self = .identity
        case 1:
            let roll = try container.decode(Angle.self)
            self.init(roll: roll)
        case 2 ... 3:
            let pitch = try container.decode(Angle.self)
            let yaw = try container.decode(Angle.self)
            let roll = try container.decode(Angle.self)
            self.init(pitch: pitch, yaw: yaw, roll: roll)
        case 4:
            let axis = try Vector(from: &container).normalized()
            let angle = try container.decode(Angle.self)
            self.init(unchecked: axis, angle: angle)
        default:
            try self.init(Matrix(from: &container))
        }
    }

    /// Encodes this rotation into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        if self == .identity {
            return
        }
        try axis.encode(to: &container, skipZ: false)
        try container.encode(angle)
    }
}

public extension Rotation {
    /// The identity rotation (i.e. no rotation).
    static let identity = Rotation()

    /// Creates a rotation around the X axis.
    /// - Parameter rotation: The angle to rotate by.
    static func pitch(_ rotation: Angle) -> Rotation {
        .init(.pitch(rotation))
    }

    /// Creates a rotation around the Y axis.
    /// - Parameter rotation: The angle to rotate by.
    static func yaw(_ rotation: Angle) -> Rotation {
        .init(.yaw(rotation))
    }

    /// Creates a rotation around the Z axis.
    /// - Parameter rotation: The angle to rotate by.
    static func roll(_ rotation: Angle) -> Rotation {
        .init(.roll(rotation))
    }

    /// Creates a new identity rotation.
    init() {
        self.init(.identity)
    }

    /// Creates a rotation from an axis and angle.
    /// - Parameters:
    ///   - axis: A vector defining the axis of rotation.
    ///   - end: The angle of rotation around the axis.
    init?(axis: Vector, angle: Angle) {
        guard let quaternion = Quaternion(axis: axis, angle: angle) else {
            return nil
        }
        self.init(quaternion)
    }

    /// Creates a rotation from a quaternion.
    /// - Parameter quaternion: A quaternion defining a rotation.
    init(_ quaternion: Quaternion) {
        self.quaternion = quaternion
    }

    /// Creates a rotation from Euler angles applied in pitch/yaw/roll order.
    /// - Parameters:
    ///   - pitch: The angle of rotation around the X axis. This is applied first.
    ///   - yaw: The angle of rotation around the Y axis. This is applied second.
    ///   - roll: The angle of rotation around the Z axis. This is applied last.
    init(pitch: Angle, yaw: Angle = .zero, roll: Angle = .zero) {
        self = .pitch(pitch) * .yaw(yaw) * .roll(roll)
    }

    /// Creates a rotation from Euler angles applied in yaw/pitch/roll order.
    /// - Parameters:
    ///   - yaw: The angle of rotation around the Y axis. This is applied first.
    ///   - pitch: The angle of rotation around the X axis. This is applied second.
    ///   - roll: The angle of rotation around the Z axis. This is applied last.
    init(yaw: Angle, pitch: Angle = .zero, roll: Angle = .zero) {
        self = .yaw(yaw) * .pitch(pitch) * .roll(roll)
    }

    /// Creates a rotation from Euler angles applied in roll/yaw/pitch order.
    /// - Parameters:
    ///   - roll: The angle of rotation around the Z axis. This is applied first.
    ///   - yaw: The angle of rotation around the Y axis. This is applied second.
    ///   - pitch: The angle of rotation around the X axis. This is applied last.
    init(roll: Angle, yaw: Angle = .zero, pitch: Angle = .zero) {
        self = .roll(roll) * .yaw(yaw) * .pitch(pitch)
    }

    /// Rotation has no effect.
    var isIdentity: Bool {
        quaternion.isIdentity
    }

    /// The angle of rotation around the X-axis.
    var pitch: Angle {
        quaternion.pitch
    }

    /// The angle of rotation around the Y-axis.
    var yaw: Angle {
        quaternion.yaw
    }

    /// The angle of rotation around the Z-axis.
    var roll: Angle {
        quaternion.roll
    }

    /// Axis of rotation
    var axis: Vector {
        quaternion.axis
    }

    /// The angle of rotation.
    var angle: Angle {
        quaternion.angle
    }

    /// A normalized direction vector pointing rightwards relative to the current rotation.
    var right: Vector {
        Vector.unitX.rotated(by: self)
    }

    /// A normalized direction vector pointing upwards relative to the current rotation.
    var up: Vector {
        Vector.unitY.rotated(by: self)
    }

    /// A normalized direction vector pointing forwards relative to the current rotation.
    var forward: Vector {
        Vector.unitZ.rotated(by: self)
    }

    /// Performs a spherical linear interpolation between two rotations.
    /// - Parameters:
    ///   - r: The rotation to interpolate towards.
    ///   - t: The normalized extent of interpolation, from 0 to 1.
    /// - Returns: The interpolated rotation.
    func slerp(_ r: Rotation, _ t: Double) -> Rotation {
        .init(quaternion.slerp(r.quaternion, t))
    }

    /// Returns the reverse (aka transpose) rotation.
    static prefix func - (rhs: Rotation) -> Rotation {
        .init(-rhs.quaternion)
    }

    /// Combines two rotations to get the cumulative rotation.
    static func * (lhs: Rotation, rhs: Rotation) -> Rotation {
        .init(lhs.quaternion * rhs.quaternion)
    }

    /// Combines with the specified rotation.
    static func *= (lhs: inout Rotation, rhs: Rotation) {
        lhs.quaternion *= rhs.quaternion
    }

    /// Returns a rotation multiplied by the specified value.
    static func * (lhs: Rotation, rhs: Double) -> Rotation {
        .init(unchecked: lhs.axis, angle: lhs.angle * rhs)
    }

    /// Multiplies the rotation angle by the specified value.
    static func *= (lhs: inout Rotation, rhs: Double) {
        lhs = lhs * rhs
    }

    /// Returns a rotation divided by the specified value.
    static func / (lhs: Rotation, rhs: Double) -> Rotation {
        .init(unchecked: lhs.axis, angle: lhs.angle / rhs)
    }

    /// Divides the rotation angle by the specified value.
    static func /= (lhs: inout Rotation, rhs: Double) {
        lhs = lhs / rhs
    }
}

extension Rotation {
    init(unchecked axis: Vector, angle: Angle) {
        self.init(.init(unchecked: axis, angle: angle))
    }

    // Approximate equality
    func isEqual(to other: Rotation, withPrecision p: Double = epsilon) -> Bool {
        quaternion.isEqual(to: other.quaternion, withPrecision: p)
    }
}
