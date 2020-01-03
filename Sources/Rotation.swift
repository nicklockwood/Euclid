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
    init(
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
}
