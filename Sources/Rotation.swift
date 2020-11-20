//
//  Rotation.swift
//  Euclid
//
//  Created by Nick Lockwood on 04/01/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import Foundation

// a rotation matrix
public struct Rotation: Hashable {
    var m11, m12, m13, m21, m22, m23, m31, m32, m33: Double

    /// Define a rotation using 3x3 matrix coefficients
    fileprivate init(
        _ m11: Double,
        _ m12: Double,
        _ m13: Double,
        _ m21: Double,
        _ m22: Double,
        _ m23: Double,
        _ m31: Double,
        _ m32: Double,
        _ m33: Double
    ) {
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
}

extension Rotation: Codable {
    private enum CodingKeys: CodingKey {
        case axis, x, y, z, radians
    }

    public init(from decoder: Decoder) throws {
        guard var container = try? decoder.unkeyedContainer() else {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let radians = try container.decodeIfPresent(Double.self, forKey: .radians) ?? 0
            var axis = try container.decodeIfPresent(Vector.self, forKey: .axis)
            if let x = try container.decodeIfPresent(Double.self, forKey: .x) {
                let y = try container.decode(Double.self, forKey: .y)
                let z = try container.decode(Double.self, forKey: .z)
                axis = Vector(x, y, z)
            }
            self.init(unchecked: axis?.normalized() ?? Vector(0, 0, 1), radians: radians)
            return
        }
        switch container.count ?? 0 {
        case 0:
            self = .identity
        case 1:
            let roll = try container.decode(Double.self)
            self.init(roll: roll)
        case 2 ... 3:
            let pitch = try container.decode(Double.self)
            let yaw = try container.decode(Double.self)
            let roll = try container.decode(Double.self)
            self.init(pitch: pitch, yaw: yaw, roll: roll)
        case 4:
            let x = try container.decode(Double.self)
            let y = try container.decode(Double.self)
            let z = try container.decode(Double.self)
            let axis = Vector(x, y, z).normalized()
            let radians = try container.decode(Double.self)
            self.init(unchecked: axis, radians: radians)
        default:
            let m11 = try container.decode(Double.self)
            let m12 = try container.decode(Double.self)
            let m13 = try container.decode(Double.self)
            let m21 = try container.decode(Double.self)
            let m22 = try container.decode(Double.self)
            let m23 = try container.decode(Double.self)
            let m31 = try container.decode(Double.self)
            let m32 = try container.decode(Double.self)
            let m33 = try container.decode(Double.self)
            self.init(m11, m12, m13, m21, m22, m23, m31, m32, m33)
            guard isRotationMatrix else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Not a rotation matrix"
                )
            }
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(m11)
        try container.encode(m12)
        try container.encode(m13)
        try container.encode(m21)
        try container.encode(m22)
        try container.encode(m23)
        try container.encode(m31)
        try container.encode(m32)
        try container.encode(m33)
    }
}

public extension Rotation {
    static let identity = Rotation()

    /// Define a rotation around the X axis
    static func pitch(_ radians: Double) -> Rotation {
        let c = cos(radians)
        let s = sin(radians)
        return self.init(
            1, 0, 0,
            0, c, -s,
            0, s, c
        )
    }

    /// Define a rotation around the Y axis
    static func yaw(_ radians: Double) -> Rotation {
        let c = cos(radians)
        let s = sin(radians)
        return self.init(
            c, 0, s,
            0, 1, 0,
            -s, 0, c
        )
    }

    /// Define a rotation around the Z axis
    static func roll(_ radians: Double) -> Rotation {
        let c = cos(radians)
        let s = sin(radians)
        return self.init(
            c, -s, 0,
            s, c, 0,
            0, 0, 1
        )
    }

    /// Creates an identity Rotation
    init() {
        self.init(1, 0, 0, 0, 1, 0, 0, 0, 1)
    }

    /// Define a rotation from an axis vector and an angle
    init?(axis: Vector, radians: Double) {
        let length = axis.length
        guard length.isFinite, length > epsilon else {
            return nil
        }
        self.init(unchecked: axis / length, radians: radians)
    }

    /// Define a rotation from Euler angles
    // http://planning.cs.uiuc.edu/node102.html
    init(pitch: Double, yaw: Double = 0, roll: Double = 0) {
        self = .pitch(pitch)
        if yaw != 0 {
            self *= .yaw(yaw)
        }
        if roll != 0 {
            self *= .roll(roll)
        }
    }

    init(yaw: Double, pitch: Double = 0, roll: Double = 0) {
        self = .yaw(yaw)
        if pitch != 0 {
            self *= .pitch(pitch)
        }
        if roll != 0 {
            self *= .roll(roll)
        }
    }

    init(roll: Double, yaw: Double = 0, pitch: Double = 0) {
        self = .roll(roll)
        if yaw != 0 {
            self *= .yaw(yaw)
        }
        if pitch != 0 {
            self *= .pitch(pitch)
        }
    }

    // http://planning.cs.uiuc.edu/node103.html
    var pitch: Double {
        return atan2(m32, m33)
    }

    var yaw: Double {
        return atan2(-m31, sqrt(m32 * m32 + m33 * m33))
    }

    var roll: Double {
        return atan2(m21, m11)
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
    // https://www.euclideanspace.com/maths/algebra/matrix/functions/determinant/threeD/
    var determinant: Double {
        return m11 * m22 * m33
            + m12 * m23 * m31
            + m13 * m21 * m32
            - m11 * m23 * m32
            - m12 * m21 * m33
            - m13 * m22 * m31
    }

    // https://www.euclideanspace.com/maths/algebra/matrix/orthogonal/rotation/
    var isRotationMatrix: Bool {
        let epsilon = 0.01
        if abs(m11 * m12 + m12 * m22 + m13 * m23) > epsilon { return false }
        if abs(m11 * m31 + m12 * m32 + m13 * m33) > epsilon { return false }
        if abs(m21 * m31 + m22 * m32 + m23 * m33) > epsilon { return false }
        if abs(m11 * m11 + m12 * m12 + m13 * m13 - 1) > epsilon { return false }
        if abs(m21 * m21 + m22 * m22 + m23 * m23 - 1) > epsilon { return false }
        if abs(m31 * m31 + m32 * m32 + m33 * m33 - 1) > epsilon { return false }
        return abs(determinant - 1) < epsilon
    }

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

    // Approximate equality
    func isEqual(to other: Rotation, withPrecision p: Double = epsilon) -> Bool {
        return abs(m11 - other.m11) < p
            && abs(m12 - other.m12) < p
            && abs(m13 - other.m13) < p
            && abs(m21 - other.m21) < p
            && abs(m22 - other.m22) < p
            && abs(m23 - other.m23) < p
            && abs(m31 - other.m31) < p
            && abs(m32 - other.m32) < p
            && abs(m33 - other.m33) < p
    }
}
