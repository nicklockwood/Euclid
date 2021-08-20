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
            let angle = try container.decodeIfPresent(Angle.self, forKey: .radians)
            var axis = try container.decodeIfPresent(Vector.self, forKey: .axis)
            if let x = try container.decodeIfPresent(Double.self, forKey: .x) {
                let y = try container.decode(Double.self, forKey: .y)
                let z = try container.decode(Double.self, forKey: .z)
                axis = Vector(x, y, z)
            }
            self.init(unchecked: axis?.normalized() ?? Vector(0, 0, 1), angle: angle ?? .zero)
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
        if self == .identity {
            return
        }
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
    static func pitch(_ rotation: Angle) -> Rotation {
        let c = cos(rotation)
        let s = sin(rotation)
        return self.init(
            1, 0, 0,
            0, c, -s,
            0, s, c
        )
    }

    /// Define a rotation around the Y axis
    static func yaw(_ rotation: Angle) -> Rotation {
        let c = cos(rotation)
        let s = sin(rotation)
        return self.init(
            c, 0, s,
            0, 1, 0,
            -s, 0, c
        )
    }

    /// Define a rotation around the Z axis
    static func roll(_ rotation: Angle) -> Rotation {
        let c = cos(rotation)
        let s = sin(rotation)
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
    init?(axis: Vector, angle: Angle) {
        let length = axis.length
        guard length.isFinite, length > epsilon else {
            return nil
        }
        self.init(unchecked: axis / length, angle: angle)
    }

    /// Define a rotation from an axis direction and an angle
    init(axis: Direction, angle: Angle) {
        // http://www.euclideanspace.com/maths/geometry/rotations/conversions/angleToMatrix/
        let c = cos(angle)
        let s = sin(angle)
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

    /// Define a rotation from Euler angles
    // http://planning.cs.uiuc.edu/node102.html
    init(pitch: Angle, yaw: Angle = .zero, roll: Angle = .zero) {
        self = .pitch(pitch)
        if yaw != .zero {
            self *= .yaw(yaw)
        }
        if roll != .zero {
            self *= .roll(roll)
        }
    }

    init(yaw: Angle, pitch: Angle = .zero, roll: Angle = .zero) {
        self = .yaw(yaw)
        if pitch != .zero {
            self *= .pitch(pitch)
        }
        if roll != .zero {
            self *= .roll(roll)
        }
    }

    init(roll: Angle, yaw: Angle = .zero, pitch: Angle = .zero) {
        self = .roll(roll)
        if yaw != .zero {
            self *= .yaw(yaw)
        }
        if pitch != .zero {
            self *= .pitch(pitch)
        }
    }

    // http://planning.cs.uiuc.edu/node103.html
    var pitch: Angle {
        .atan2(y: m32, x: m33)
    }

    var yaw: Angle {
        .atan2(y: -m31, x: sqrt(m32 * m32 + m33 * m33))
    }

    var roll: Angle {
        .atan2(y: m21, x: m11)
    }

    var right: Vector {
        Vector(m11, m12, m13)
    }

    var up: Vector {
        Vector(m21, m22, m23)
    }

    var forward: Vector {
        Vector(m31, m32, m33)
    }

    static prefix func - (rhs: Rotation) -> Rotation {
        // transpose matrix
        Rotation(
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
        Rotation(
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
    
    static func * <T: CartesianComponentsRepresentable>(lhs: T, rhs: Rotation) -> T {
        let x = lhs.x * rhs.m11
            + lhs.y * rhs.m21
            + lhs.z * rhs.m31
        
        let y = lhs.x * rhs.m12
            + lhs.y * rhs.m22
            + lhs.z * rhs.m32
        
        let z = lhs.x * rhs.m13
            + lhs.y * rhs.m23
            + lhs.z * rhs.m33
        
        return T(x: x, y: y, z: z)
    }
}

internal extension Rotation {
    // https://www.euclideanspace.com/maths/algebra/matrix/functions/determinant/threeD/
    var determinant: Double {
        m11 * m22 * m33
            + m12 * m23 * m31
            + m13 * m21 * m32
            - m11 * m23 * m32
            - m12 * m21 * m33
            - m13 * m22 * m31
    }

    var adjugate: Rotation {
        Rotation(
            m22 * m33 - m23 * m32,
            m13 * m32 - m12 * m33,
            m12 * m23 - m13 * m22,
            m23 * m31 - m21 * m33,
            m11 * m33 - m13 * m31,
            m13 * m21 - m11 * m23,
            m21 * m32 - m22 * m31,
            m12 * m31 - m11 * m32,
            m11 * m22 - m12 * m21
        )
    }

    var transpose: Rotation {
        Rotation(m11, m21, m31, m12, m22, m32, m13, m23, m33)
    }

    var inverse: Rotation {
        let a = adjugate
        let d = determinant
        return Rotation(
            a.m11 / d, a.m12 / d, a.m13 / d,
            a.m21 / d, a.m22 / d, a.m23 / d,
            a.m31 / d, a.m32 / d, a.m33 / d
        )
    }

    var isRotationMatrix: Bool {
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

    // TODO: is this still needed?
    // http://www.euclideanspace.com/maths/geometry/rotations/conversions/angleToMatrix/
    init(unchecked axis: Vector, angle: Angle) {
        assert(axis.isNormalized)
        self.init(
            axis: Direction(x: axis.x, y: axis.y, z: axis.z),
            angle: angle
        )
    }

    // Approximate equality
    func isEqual(to other: Rotation, withPrecision p: Double = epsilon) -> Bool {
        abs(m11 - other.m11) < p
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
