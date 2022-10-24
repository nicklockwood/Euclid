//
//  Quaternion.swift
//  Euclid
//
//  Created by Nick Lockwood on 10/09/2021.
//  Copyright © 2021 Nick Lockwood. All rights reserved.
//

import Foundation

#if canImport(simd)

import simd

/// An orientation or rotation in 3D space.
///
/// A quaternion can be created from a from a ``Rotation`` matrix, or directly from an axis vector and
/// angle, or a from a set of 3 Euler angles (pitch, yaw and roll).
///
/// In addition to being more compact than a 3x3 rotation matrix, quaternions also avoid a
/// problem known as gymbal lock.
public struct Quaternion: Sendable {
    internal var storage: simd_quatd

    /// The quaternion X component.
    public var x: Double {
        set { storage.vector.x = newValue }
        get { storage.vector.x }
    }

    /// The quaternion Y component.
    public var y: Double {
        set { storage.vector.y = newValue }
        get { storage.vector.y }
    }

    /// The quaternion Z component.
    public var z: Double {
        set { storage.vector.z = newValue }
        get { storage.vector.z }
    }

    /// The quaternion W component.
    public var w: Double {
        set { storage.vector.w = newValue }
        get { storage.vector.w }
    }

    /// Creates a quaternion from raw component values.
    public init(_ x: Double, _ y: Double, _ z: Double, _ w: Double) {
        self.storage = simd_quatd(vector: .init(x, y, z, w))
    }
}

extension Quaternion: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(storage.vector)
    }
}

public extension Quaternion {
    /// The axis of rotation.
    var axis: Vector {
        .init(-simd_axis(storage))
    }

    /// The angle of rotation.
    var angle: Angle {
        .radians(simd_angle(storage))
    }

    /// The magnitude of the quaternion.
    var length: Double {
        simd_length(storage)
    }

    /// The square of the length of the quaternion. This is less expensive to compute than the length itself.
    var lengthSquared: Double {
        simd_length_squared(storage.vector)
    }

    /// Computes the dot-product of this quaternion and another.
    /// - Parameter a: The quaternion with which to compute the dot product.
    /// - Returns: The dot product of the two quaternions.
    func dot(_ q: Quaternion) -> Double {
        simd_dot(storage, q.storage)
    }

    /// A Boolean value that indicates whether the quaternion has a length of `1`.
    var isNormalized: Bool {
        abs(lengthSquared - 1) < epsilon
    }

    /// Returns the normalized quaternion.
    /// - Returns: The normalized quaternion (with a length of `1`) or  ``zero`` if the length is `0`.
    func normalized() -> Quaternion {
        if storage.vector == .zero {
            return self
        }
        return .init(simd_normalize(storage))
    }

    // Performs a spherical interpolation between two quaternions.
    /// - Parameters:
    ///   - q: A quaternion to interpolate with.
    ///   - t: The normalized extent of interpolation, from 0 to 1.
    /// - Returns: The interpolated quaternion.
    func slerp(_ q: Quaternion, _ t: Double) -> Quaternion {
        .init(simd_slerp(storage, q.storage, t))
    }

    /// Returns the reverse quaternion rotation.
    static prefix func - (q: Quaternion) -> Quaternion {
        .init(simd_inverse(q.storage))
    }

    /// Returns the sum of two quaternion rotations.
    static func + (lhs: Quaternion, rhs: Quaternion) -> Quaternion {
        .init(lhs.storage + rhs.storage)
    }

    /// Adds the quaternion rotation on the right to the one on the left.
    static func += (lhs: inout Quaternion, rhs: Quaternion) {
        lhs.storage += rhs.storage
    }

    /// Returns the difference between two quaternion rotations,.
    static func - (lhs: Quaternion, rhs: Quaternion) -> Quaternion {
        .init(lhs.storage - rhs.storage)
    }

    /// Subtracts the quaternion rotation on the right from the one on the left.
    static func -= (lhs: inout Quaternion, rhs: Quaternion) {
        lhs.storage -= rhs.storage
    }

    /// Returns the product of two quaternions (i.e. the effect of rotating the left by the right).
    static func * (lhs: Quaternion, rhs: Quaternion) -> Quaternion {
        .init(lhs.storage * rhs.storage)
    }

    /// Multiplies the quaternion rotation on the left by the one on the right.
    static func *= (lhs: inout Quaternion, rhs: Quaternion) {
        lhs.storage *= rhs.storage
    }

    /// Returns a quaternion with its components multiplied by the specified value.
    static func * (lhs: Quaternion, rhs: Double) -> Quaternion {
        .init(lhs.storage * rhs)
    }

    /// Multiplies the components of the quaternion by the specified value.
    static func *= (lhs: inout Quaternion, rhs: Double) {
        lhs.storage *= rhs
    }

    /// Returns a quaternion with its components divided by the specified value.
    static func / (lhs: Quaternion, rhs: Double) -> Quaternion {
        .init(lhs.storage / rhs)
    }

    /// Divides the components of the vector by the specified value.
    static func /= (lhs: inout Quaternion, rhs: Double) {
        lhs.storage /= rhs
    }
}

internal extension Quaternion {
    init(unchecked axis: Vector, angle: Angle) {
        assert(axis.isNormalized)
        self.init(simd_quatd(
            angle: -angle.radians,
            axis: .init(axis.x, axis.y, axis.z)
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
public struct Quaternion: Hashable, Sendable {
    /// The quaternion component values.
    public var x, y, z, w: Double

    /// Creates a quaternion from raw component values.
    public init(_ x: Double, _ y: Double, _ z: Double, _ w: Double) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }
}

public extension Quaternion {
    /// The axis of rotation.
    var axis: Vector {
        let s = sqrt(1 - w * w)
        guard w > epsilon else {
            // if angle close to zero, direction is not important
            return .unitZ
        }
        return Vector(x, y, z) / -s
    }

    /// The angle of rotation.
    var angle: Angle {
        .radians(2 * acos(w))
    }

    /// The magnitude of the quaternion.
    var length: Double {
        sqrt(lengthSquared)
    }

    /// The square of the length of the quaternion. This is less expensive to compute than the length itself.
    var lengthSquared: Double {
        dot(self)
    }

    /// Computes the dot-product of this quaternion and another.
    /// - Parameter a: The quaternion with which to compute the dot product.
    /// - Returns: The dot product of the two quaternions.
    func dot(_ q: Quaternion) -> Double {
        x * q.x + y * q.y + z * q.z + w * q.w
    }

    /// A Boolean value that indicates whether the quaternion has a length of `1`.
    var isNormalized: Bool {
        abs(lengthSquared - 1) < epsilon
    }

    /// Returns the normalized quaternion.
    /// - Returns: The normalized quaternion (with a length of `1`) or  ``zero`` if the length is `0`.
    func normalized() -> Quaternion {
        let lengthSquared = self.lengthSquared
        if lengthSquared == 0 || lengthSquared == 1 {
            return self
        }
        return self / sqrt(lengthSquared)
    }

    // Performs a spherical linear interpolation between two quaternions.
    /// - Parameters:
    ///   - q: The quaternion to interpolate towards.
    ///   - t: The normalized extent of interpolation, from 0 to 1.
    /// - Returns: The interpolated quaternion.
    func slerp(_ q: Quaternion, _ t: Double) -> Quaternion {
        let dot = max(-1, min(1, self.dot(q)))
        if abs(abs(dot) - 1) < epsilon {
            return (self + (q - self) * t).normalized()
        }

        let theta = acos(dot) * t
        let t1 = self * cos(theta)
        let t2 = (q - (self * dot)).normalized() * sin(theta)
        return t1 + t2
    }

    /// Returns the reverse quaternion rotation.
    static prefix func - (q: Quaternion) -> Quaternion {
        .init(q.x, q.y, q.z, -q.w)
    }

    /// Returns the sum of two quaternion rotations.
    static func + (lhs: Quaternion, rhs: Quaternion) -> Quaternion {
        .init(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z, lhs.w + rhs.w)
    }

    /// Adds the quaternion rotation on the right to the one on the left.
    static func += (lhs: inout Quaternion, rhs: Quaternion) {
        lhs = lhs + rhs
    }

    /// Returns the difference between two quaternion rotations,.
    static func - (lhs: Quaternion, rhs: Quaternion) -> Quaternion {
        .init(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z, lhs.w - rhs.w)
    }

    /// Subtracts the quaternion rotation on the right from the one on the left.
    static func -= (lhs: inout Quaternion, rhs: Quaternion) {
        lhs = lhs - rhs
    }

    /// Returns the product of two quaternions (i.e. the effect of rotating the left by the right).
    static func * (lhs: Quaternion, rhs: Quaternion) -> Quaternion {
        .init(
            lhs.w * rhs.x + lhs.x * rhs.w + lhs.y * rhs.z - lhs.z * rhs.y,
            lhs.w * rhs.y + lhs.y * rhs.w + lhs.z * rhs.x - lhs.x * rhs.z,
            lhs.w * rhs.z + lhs.z * rhs.w + lhs.x * rhs.y - lhs.y * rhs.x,
            lhs.w * rhs.w - lhs.x * rhs.x - lhs.y * rhs.y - lhs.z * rhs.z
        )
    }

    /// Multiplies the quaternion rotation on the left by the one on the right.
    static func *= (lhs: inout Quaternion, rhs: Quaternion) {
        lhs = lhs * rhs
    }

    /// Returns a quaternion with its components multiplied by the specified value.
    static func * (lhs: Quaternion, rhs: Double) -> Quaternion {
        Quaternion(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs, lhs.w * rhs)
    }

    /// Multiplies the components of the quaternion by the specified value.
    static func *= (lhs: inout Quaternion, rhs: Double) {
        lhs.x *= rhs
        lhs.y *= rhs
        lhs.z *= rhs
        lhs.w *= rhs
    }

    /// Returns a quaternion with its components divided by the specified value.
    static func / (lhs: Quaternion, rhs: Double) -> Quaternion {
        Quaternion(lhs.x / rhs, lhs.y / rhs, lhs.z / rhs, lhs.w / rhs)
    }

    /// Divides the components of the vector by the specified value.
    static func /= (lhs: inout Quaternion, rhs: Double) {
        lhs.x /= rhs
        lhs.y /= rhs
        lhs.z /= rhs
        lhs.w /= rhs
    }
}

internal extension Quaternion {
    init(unchecked axis: Vector, angle: Angle) {
        assert(axis.isNormalized)
        let r = -angle / 2
        let a = axis * sin(r)
        self.init(a.x, a.y, a.z, cos(r))
    }
}

#endif

extension Quaternion: Codable {
    private enum CodingKeys: CodingKey {
        case x, y, z, w
    }

    /// Creates a new quaternion by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        if var container = try? decoder.unkeyedContainer() {
            switch container.count {
            case 0:
                self = .identity
            default:
                try self.init(from: &container)
            }
        } else {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let x = try container.decodeIfPresent(Double.self, forKey: .x) ?? 0
            let y = try container.decodeIfPresent(Double.self, forKey: .y) ?? 0
            let z = try container.decodeIfPresent(Double.self, forKey: .z) ?? 0
            let w = try container.decodeIfPresent(Double.self, forKey: .w) ?? 1
            self.init(x, y, z, w)
        }
    }

    /// Encodes this quaternion into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        if self == .identity {
            return
        }
        try encode(to: &container)
    }
}

public extension Quaternion {
    /// The zero quaternion.
    static let zero = Quaternion(0, 0, 0, 0)
    /// The identity quaternion (i.e. no rotation).
    static let identity = Quaternion(0, 0, 0, 1)

    /// Creates a quaternion from an axis and angle.
    /// - Parameters:
    ///   - axis: A vector defining the axis of rotation.
    ///   - angle: The angle of rotation around the axis.
    init?(axis: Vector, angle: Angle) {
        let length = axis.length
        guard length.isFinite, length > epsilon else {
            return nil
        }
        self.init(unchecked: axis / length, angle: angle)
    }

    /// Creates a quaternion representing a rotation around the X axis.
    /// - Parameter rotation: The angle to rotate by.
    static func pitch(_ rotation: Angle) -> Quaternion {
        let r = -rotation.radians * 0.5
        return Quaternion(sin(r), 0, 0, cos(r))
    }

    /// Creates a quaternion representing a rotation around the Y axis.
    /// - Parameter rotation: The angle to rotate by.
    static func yaw(_ rotation: Angle) -> Quaternion {
        let r = -rotation.radians * 0.5
        return Quaternion(0, sin(r), 0, cos(r))
    }

    /// Creates a quaternion representing a rotation around the Z axis.
    /// - Parameter rotation: The angle to rotate by.
    static func roll(_ rotation: Angle) -> Quaternion {
        let r = -rotation.radians * 0.5
        return Quaternion(0, 0, sin(r), cos(r))
    }

    /// Creates a rotation from Euler angles applied in roll/yaw/pitch order.
    /// - Parameters:
    ///   - roll: The angle of rotation around the Z axis. This is applied first.
    ///   - yaw: The angle of rotation around the Y axis. This is applied second.
    ///   - pitch: The angle of rotation around the X axis. This is applied last.
    init(roll: Angle = .zero, yaw: Angle = .zero, pitch: Angle = .zero) {
        self = .roll(roll) * .yaw(yaw) * .pitch(pitch)
    }

    /// Creates a quaternion from a rotation matrix.
    /// - Parameter rotation: A rotation matrix.
    init(_ rotation: Rotation) {
        self = rotation.quaternion
    }

    /// Creates a quaternion from raw components.
    /// - Parameter components: An array of 4 floating-point values.
    init?(_ components: [Double]) {
        guard components.count == 4 else {
            return nil
        }
        self.init(components[0], components[1], components[2], components[3])
    }

    /// An array containing the raw components of the quaternion.
    var components: [Double] {
        [x, y, z, w]
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
}

internal extension Quaternion {
    // Approximate equality
    func isEqual(to other: Quaternion, withPrecision p: Double = epsilon) -> Bool {
        w.isEqual(to: other.w, withPrecision: p) &&
            x.isEqual(to: other.x, withPrecision: p) &&
            y.isEqual(to: other.y, withPrecision: p) &&
            z.isEqual(to: other.z, withPrecision: p)
    }

    // Encode directly into an unkeyedContainer
    func encode(to container: inout UnkeyedEncodingContainer) throws {
        try container.encode(x)
        try container.encode(y)
        try container.encode(z)
        try container.encode(w)
    }

    // Decode directly from an unkeyedContainer
    init(from container: inout UnkeyedDecodingContainer) throws {
        let x = try container.decode(Double.self)
        let y = try container.decode(Double.self)
        let z = try container.decode(Double.self)
        let w = try container.decode(Double.self)
        self.init(x, y, z, w)
    }
}
