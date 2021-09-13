//
//  Quaternion.swift
//  Euclid
//
//  Created by Nick Lockwood on 10/09/2021.
//  Copyright © 2021 Nick Lockwood. All rights reserved.
//

import Foundation

public struct Quaternion: Hashable {
    public var x, y, z, w: Double

    public init(_ x: Double, _ y: Double, _ z: Double, _ w: Double) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }
}

extension Quaternion: Codable {
    private enum CodingKeys: CodingKey {
        case x, y, z, w
    }

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

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        if self == .identity {
            return
        }
        try encode(to: &container)
    }
}

public extension Quaternion {
    static let zero = Quaternion(0, 0, 0, 0)
    static let identity = Quaternion(0, 0, 0, 1)

    /// Define a quaternion from an axis direction and an angle
    init(axis: Direction, angle: Angle) {
        let r = -angle / 2
        let a = axis * sin(r)
        self.init(a.x, a.y, a.z, cos(r))
    }

    /// Define a rotation around the X axis
    static func pitch(_ rotation: Angle) -> Quaternion {
        let r = -rotation * 0.5
        return Quaternion(sin(r), 0, 0, cos(r))
    }

    /// Define a rotation around the Y axis
    static func yaw(_ rotation: Angle) -> Quaternion {
        let r = -rotation * 0.5
        return Quaternion(0, sin(r), 0, cos(r))
    }

    /// Define a rotation around the Z axis
    static func roll(_ rotation: Angle) -> Quaternion {
        let r = -rotation * 0.5
        return Quaternion(0, 0, sin(r), cos(r))
    }

    /// Define a quaternion from Euler angles
    /// `roll` is the angle around the Z axis, `yaw` is the angle around Y, and `pitch` is the angle around X.
    init(roll: Angle = .zero, yaw: Angle = .zero, pitch: Angle = .zero) {
        self = .roll(roll) * .yaw(yaw) * .pitch(pitch)
    }

    // Create a quaternion from a rotation matrix
    init(_ r: Rotation) {
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

    // Create a quaternion from components
    init?(_ components: [Double]) {
        guard components.count == 4 else {
            return nil
        }
        self.init(components[0], components[1], components[2], components[3])
    }

    var components: [Double] {
        [x, y, z]
    }

    var lengthSquared: Double {
        dot(self)
    }

    var length: Double {
        sqrt(lengthSquared)
    }

    // Rotation around Z-axis
    var roll: Angle {
        -.atan2(y: 2 * (w * z + x * y), x: 1 - 2 * (y * y + z * z))
    }

    // Rotation around Y-axis
    var yaw: Angle {
        -.asin(min(1, max(-1, 2 * (w * y - z * x))))
    }

    // Rotation around X-axis
    var pitch: Angle {
        -.atan2(y: 2 * (w * x + y * z), x: 1 - 2 * (x * x + y * y))
    }

    func dot(_ q: Quaternion) -> Double {
        x * q.x + y * q.y + z * q.z + w * q.w
    }

    var isNormalized: Bool {
        abs(lengthSquared - 1) < epsilon
    }

    func normalized() -> Quaternion {
        let lengthSquared = self.lengthSquared
        if lengthSquared == 0 || lengthSquared == 1 {
            return self
        }
        return self / sqrt(lengthSquared)
    }

    // Spherical interpolation between two quaternions
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

    static prefix func - (q: Quaternion) -> Quaternion {
        Quaternion(-q.x, -q.y, -q.z, q.w)
    }

    static func + (lhs: Quaternion, rhs: Quaternion) -> Quaternion {
        Quaternion(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z, lhs.w + rhs.w)
    }

    static func += (lhs: inout Quaternion, rhs: Quaternion) {
        lhs = lhs + rhs
    }

    static func - (lhs: Quaternion, rhs: Quaternion) -> Quaternion {
        Quaternion(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z, lhs.w - rhs.w)
    }

    static func -= (lhs: inout Quaternion, rhs: Quaternion) {
        lhs = lhs - rhs
    }

    static func * (lhs: Quaternion, rhs: Quaternion) -> Quaternion {
        Quaternion(
            lhs.w * rhs.x + lhs.x * rhs.w + lhs.y * rhs.z - lhs.z * rhs.y,
            lhs.w * rhs.y + lhs.y * rhs.w + lhs.z * rhs.x - lhs.x * rhs.z,
            lhs.w * rhs.z + lhs.z * rhs.w + lhs.x * rhs.y - lhs.y * rhs.x,
            lhs.w * rhs.w - lhs.x * rhs.x - lhs.y * rhs.y - lhs.z * rhs.z
        )
    }

    static func *= (lhs: inout Quaternion, rhs: Quaternion) {
        lhs = lhs * rhs
    }

    static func * <T: CartesianComponentsRepresentable>(lhs: T, rhs: Quaternion) -> T {
        let v = Vector(lhs)
        let qv = Vector(rhs.x, rhs.y, rhs.z)
        let uv = qv.cross(v)
        let uuv = qv.cross(uv)
        return T(v + (uv * 2 * rhs.w) + (uuv * 2))
    }

    static func * (lhs: Quaternion, rhs: Double) -> Quaternion {
        Quaternion(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs, lhs.w * rhs)
    }

    static func *= (lhs: inout Quaternion, rhs: Double) {
        lhs.x *= rhs
        lhs.y *= rhs
        lhs.z *= rhs
        lhs.w *= rhs
    }

    static func / (lhs: Quaternion, rhs: Double) -> Quaternion {
        Quaternion(lhs.x / rhs, lhs.y / rhs, lhs.z / rhs, lhs.w / rhs)
    }

    static func /= (lhs: inout Quaternion, rhs: Double) {
        lhs.x /= rhs
        lhs.y /= rhs
        lhs.z /= rhs
        lhs.w /= rhs
    }
}

internal extension Quaternion {
    // Approximate equality
    func isEqual(to other: Quaternion, withPrecision p: Double = epsilon) -> Bool {
        self == other || (
            abs(x - other.x) < p && abs(y - other.y) < p &&
                abs(z - other.z) < p && abs(w - other.w) < p
        )
    }

    /// Encode directly into an unkeyedContainer
    func encode(to container: inout UnkeyedEncodingContainer) throws {
        try container.encode(x)
        try container.encode(y)
        try container.encode(z)
        try container.encode(w)
    }

    /// Decode directly from an unkeyedContainer
    init(from container: inout UnkeyedDecodingContainer) throws {
        self.x = try container.decode(Double.self)
        self.y = try container.decode(Double.self)
        self.z = try container.decode(Double.self)
        self.w = try container.decode(Double.self)
    }
}
