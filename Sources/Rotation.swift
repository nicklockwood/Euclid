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

#if canImport(simd)

import simd

/// An orientation or rotation in 3D space.
///
/// A rotation can be converted to and from an axis vector and angle, or a set of 3 Euler angles (pitch, yaw and roll).
public struct Rotation: Sendable {
    var storage: simd_quatd
}

extension Rotation: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(storage.vector)
    }
}

public extension Rotation {
    /// The axis of rotation.
    var axis: Vector {
        // if angle is zero, direction doesn't matter
        abs(w) == 1 ? .unitZ : .init(-storage.axis)
    }

    /// The angle of rotation.
    var angle: Angle {
        .radians(storage.angle)
    }

    /// Rotates the specified vector relative to the origin.
    /// - Parameter vector: The Vector to be rotated.
    /// - Returns: The rotated vector.
    func rotate(_ vector: Vector) -> Vector {
        .init(simd_act(storage, simd_double3(vector)))
    }

    /// Returns the inverse rotation.
    static prefix func - (r: Rotation) -> Rotation {
        .init(storage: r.storage.inverse)
    }

    /// Combines two rotations to get the cumulative rotation.
    static func * (lhs: Rotation, rhs: Rotation) -> Rotation {
        .init(storage: lhs.storage * rhs.storage)
    }

    /// Combines with the specified rotation.
    static func *= (lhs: inout Rotation, rhs: Rotation) {
        lhs.storage *= rhs.storage
    }
}

extension Rotation {
    var x: Double { storage.vector.x }
    var y: Double { storage.vector.y }
    var z: Double { storage.vector.z }
    var w: Double { storage.vector.w }

    init(_ x: Double, _ y: Double, _ z: Double, _ w: Double) {
        let vector = simd_normalize(simd_double4(x, y, z, w))
        self.init(storage: simd_quatd(vector: vector))
    }

    init(unchecked x: Double, _ y: Double, _ z: Double, _ w: Double) {
        self.init(storage: simd_quatd(vector: simd_double4(x, y, z, w)))
        let lengthSquared = simd_dot(storage, storage)
        assert(lengthSquared == 0 || abs(lengthSquared - 1) < epsilon)
    }

    init(unchecked axis: Vector, angle: Angle) {
        assert(axis.isNormalized)
        self.init(storage: simd_quatd(
            angle: -angle.radians,
            axis: .init(axis)
        ))
    }
}

#else

/// An orientation or rotation in 3D space.
///
/// A quaternion can be created from a from a ``Rotation`` matrix, or directly from an axis vector and
/// angle, or a from a set of 3 Euler angles (pitch, yaw and roll).
///
/// In addition to being more compact than a 3x3 rotation matrix, quaternions also avoid a
/// problem known as gymbal lock.
public struct Rotation: Hashable, Sendable {
    /// The quaternion component values.
    public var x, y, z, w: Double

    /// Creates a quaternion from raw component values.
    public init(_ x: Double, _ y: Double, _ z: Double, _ w: Double) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
        self = normalized()
    }
}

public extension Rotation {
    /// The axis of rotation.
    var axis: Vector {
        let s = sqrt(1 - w * w)
        // if angle is zero, direction doesn't matter
        return s == 0 ? .unitZ : Vector(x, y, z) / -s
    }

    /// The angle of rotation.
    var angle: Angle {
        .radians(2 * acos(w))
    }

    /// Rotates the specified vector relative to the origin.
    /// - Parameter vector: The Vector to be rotated.
    /// - Returns: The rotated vector.
    func rotate(_ vector: Vector) -> Vector {
        let qv = Vector(x, y, z)
        let uv = qv.cross(vector)
        let uuv = qv.cross(uv)
        return vector + (uv * 2 * w) + (uuv * 2)
    }

    /// Returns the inverse rotation.
    static prefix func - (r: Rotation) -> Rotation {
        .init(unchecked: r.x, r.y, r.z, -r.w)
    }

    /// Combines two rotations to get the cumulative rotation.
    static func * (lhs: Rotation, rhs: Rotation) -> Rotation {
        .init(
            unchecked:
            lhs.w * rhs.x + lhs.x * rhs.w + lhs.y * rhs.z - lhs.z * rhs.y,
            lhs.w * rhs.y + lhs.y * rhs.w + lhs.z * rhs.x - lhs.x * rhs.z,
            lhs.w * rhs.z + lhs.z * rhs.w + lhs.x * rhs.y - lhs.y * rhs.x,
            lhs.w * rhs.w - lhs.x * rhs.x - lhs.y * rhs.y - lhs.z * rhs.z
        )
    }

    /// Combines with the specified rotation.
    static func *= (lhs: inout Rotation, rhs: Rotation) {
        lhs = lhs * rhs
    }
}

extension Rotation {
    init(unchecked x: Double, _ y: Double, _ z: Double, _ w: Double) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
        let lengthSquared = dot(self)
        assert(lengthSquared == 0 || abs(lengthSquared - 1) < epsilon)
    }

    init(unchecked axis: Vector, angle: Angle) {
        assert(axis.isNormalized)
        let r = -angle / 2
        let a = axis * sin(r)
        self.init(unchecked: a.x, a.y, a.z, cos(r))
    }

    func dot(_ r: Rotation) -> Double {
        x * r.x + y * r.y + z * r.z + w * r.w
    }

    func normalized() -> Rotation {
        let lengthSquared = dot(self)
        if lengthSquared == 0 || lengthSquared == 1 {
            return self
        }
        let length = sqrt(lengthSquared)
        return .init(unchecked: x / length, y / length, z / length, w / length)
    }
}

#endif

extension Rotation: CustomDebugStringConvertible {
    public var debugDescription: String {
        self == .identity ? "Rotation.identity" : "Rotation(axis: \(axis.components), angle: \(angle))"
    }
}

extension Rotation: Codable {
    private enum CodingKeys: CodingKey {
        case axis, x, y, z, w, radians
    }

    private struct Matrix {
        var m11, m12, m13, m21, m22, m23, m31, m32, m33: Double

        /// https://www.euclideanspace.com/maths/algebra/matrix/functions/determinant/threeD/
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
        self.init(
            x * (x * (r.m32 - r.m23) < 0 ? 1 : -1),
            y * (y * (r.m13 - r.m31) < 0 ? 1 : -1),
            z * (z * (r.m21 - r.m12) < 0 ? 1 : -1),
            w
        )
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
                if let w = try container.decodeIfPresent(Double.self, forKey: .w) {
                    self.init(x, y, z, w)
                    return
                }
                axis = [x, y, z]
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
            try self.init(from: &container)
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
        try encode(to: &container)
    }
}

public extension Rotation {
    /// The identity rotation (i.e. no rotation).
    static let identity: Rotation = .init()

    /// Creates a new identity rotation.
    init() {
        self.init(unchecked: 0, 0, 0, 1)
    }

    /// Creates a rotation from an axis and angle.
    /// - Parameters:
    ///   - axis: A vector defining the axis of rotation.
    ///   - angle: The angle of rotation around the axis.
    init?(axis: Vector, angle: Angle) {
        guard let direction = axis.direction else {
            return nil
        }
        self.init(unchecked: direction, angle: angle)
    }

    /// Creates a rotation between two direction vectors.
    /// - Parameters:
    ///   - a: The first vector
    ///   - b: The second vector
    init(from a: Vector, to b: Vector) {
        if let a = a.direction, let b = b.direction {
            self = rotationBetweenNormalizedVectors(a, b)
        } else {
            self = .identity
        }
    }

    /// Creates a rotation around the X axis.
    /// - Parameter rotation: The angle to rotate by.
    static func pitch(_ rotation: Angle) -> Rotation {
        let r = -rotation.radians * 0.5
        return .init(unchecked: sin(r), 0, 0, cos(r))
    }

    /// Creates a rotation around the Y axis.
    /// - Parameter rotation: The angle to rotate by.
    static func yaw(_ rotation: Angle) -> Rotation {
        let r = -rotation.radians * 0.5
        return .init(unchecked: 0, sin(r), 0, cos(r))
    }

    /// Creates a rotation around the Z axis.
    /// - Parameter rotation: The angle to rotate by.
    static func roll(_ rotation: Angle) -> Rotation {
        let r = -rotation.radians * 0.5
        return .init(unchecked: 0, 0, sin(r), cos(r))
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
        abs(1 - w) < epsilon
    }

    /// The angle of rotation around the Z-axis.
    var roll: Angle {
        -.atan2(y: 2 * (w * z + x * y), x: 1 - 2 * (y * y + z * z))
    }

    /// The angle of rotation around the Y-axis.
    var yaw: Angle {
        -.asin(min(1, max(-1, 2 * (w * y - z * x))))
    }

    /// The angle of rotation around the X-axis.
    var pitch: Angle {
        -.atan2(y: 2 * (w * x + y * z), x: 1 - 2 * (x * x + y * y))
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

    /// Performs a spherical linear interpolation between two rotations.
    /// - Parameters:
    ///   - other: The rotation to interpolate towards.
    ///   - t: The normalized extent of interpolation, from 0 to 1.
    /// - Returns: The interpolated rotation.
    func slerp(_ other: Rotation, _ t: Double) -> Rotation {
        interpolated(with: other, by: t)
    }
}

extension Rotation: UnkeyedCodable {
    func encode(to container: inout UnkeyedEncodingContainer) throws {
        try axis.encode(to: &container, skipZ: false)
        try container.encode(angle)
    }

    init(from container: inout UnkeyedDecodingContainer) throws {
        let axis = try Vector(from: &container).normalized()
        let angle = try container.decode(Angle.self)
        self.init(unchecked: axis, angle: angle)
    }
}

extension Rotation {
    /// Approximate equality
    func isEqual(to other: Rotation, withPrecision p: Double = epsilon) -> Bool {
        w.isEqual(to: other.w, withPrecision: p) &&
            x.isEqual(to: other.x, withPrecision: p) &&
            y.isEqual(to: other.y, withPrecision: p) &&
            z.isEqual(to: other.z, withPrecision: p)
    }
}
