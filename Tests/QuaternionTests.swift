//
//  QuaternionTests.swift
//  Euclid
//
//  Created by Nick Lockwood on 17/10/2022.
//  Copyright © 2022 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

@available(*, deprecated)
class QuaternionTests: XCTestCase {
    func testNormalizeZeroQuaternion() {
        let q = Quaternion.zero
        XCTAssertEqual(q.normalized(), .zero)
    }

    func testReverseQuaternionRotation() {
        let q = Quaternion(roll: -.pi * 0.5)
        let q2 = Quaternion(roll: .pi * 1.5)
        let vector = Vector(0.5, 0.5, 0.5)
        XCTAssertEqual(vector.rotated(by: q), vector.rotated(by: q2))
        XCTAssertEqual(vector.rotated(by: q).rotated(by: -q), vector)
        XCTAssertEqual(vector.rotated(by: q2).rotated(by: -q2), vector)
        XCTAssertNotEqual(vector.rotated(by: q), vector.rotated(by: -q))
        XCTAssertNotEqual(vector.rotated(by: q2), vector.rotated(by: -q2))
    }

    func testAxisAngle() {
        let q = Quaternion(unchecked: .unitX, angle: .halfPi)
        XCTAssertEqual(q.axis, .unitX)
        XCTAssert(q.angle.isEqual(to: .halfPi))
    }

    func testAxisAngle2() {
        let q = Quaternion(unchecked: .unitY, angle: .pi * 0.75)
        XCTAssertEqual(q.axis, .unitY)
        XCTAssert(q.angle.isEqual(to: .pi * 0.75))
    }

    func testAxisAngle3() {
        let q = Quaternion(unchecked: .unitZ, angle: .halfPi)
        XCTAssertEqual(q.axis, .unitZ)
        XCTAssert(q.angle.isEqual(to: .halfPi))
    }

    func testAxisAngle4() {
        let q = Quaternion(unchecked: .unitZ, angle: .zero)
        XCTAssertEqual(q.axis, .unitZ)
        XCTAssert(q.angle.isZero)
    }

    func testAxisAngleRotation() {
        let q = Quaternion(unchecked: .unitZ, angle: .halfPi)
        let v = Vector(0, 0.5, 0)
        let u = v.rotated(by: q)
        let w = v.rotated(by: Rotation(q))
        XCTAssertEqual(u, w)
        XCTAssertEqual(u, Vector(0.5, 0, 0))
    }

    func testAxisAngleRotation2() {
        let q = Quaternion(unchecked: .unitZ, angle: .halfPi)
        let v = Vector(0.5, 0, 0)
        let u = v.rotated(by: q)
        let w = v.rotated(by: Rotation(q))
        XCTAssertEqual(u, w)
        XCTAssertEqual(u, Vector(0, -0.5, 0))
    }

    func testAxisAngleRotation3() {
        let q = Quaternion(unchecked: .unitZ, angle: .halfPi)
        let v = Vector(0, 0, 0.5)
        let u = v.rotated(by: q)
        let w = v.rotated(by: Rotation(q))
        XCTAssertEqual(u, w)
        XCTAssertEqual(u, Vector(0, 0, 0.5))
    }

    func testQuaternionFromPitch() {
        let q = Quaternion(pitch: .halfPi)
        XCTAssertEqual(q.pitch.radians, .pi / 2, accuracy: epsilon)
        XCTAssertEqual(q.yaw, .zero)
        XCTAssertEqual(q.roll, .zero)
        let v = Vector(0, 0.5, 0), u = Vector(0, 0, -0.5)
        XCTAssertEqual(v.rotated(by: q), u)
    }

    func testQuaternionFromYaw() {
        let q = Quaternion(yaw: .halfPi)
        XCTAssertEqual(q.yaw, .halfPi)
        XCTAssertEqual(q.roll, .zero)
        XCTAssertEqual(q.pitch, .zero)
        let v = Vector(0.5, 0, 0), u = Vector(0, 0, 0.5)
        XCTAssertEqual(v.rotated(by: q), u)
    }

    func testQuaternionFromRoll() {
        let q = Quaternion(roll: .halfPi)
        XCTAssertEqual(q.roll.radians, .pi / 2, accuracy: epsilon)
        XCTAssertEqual(q.yaw, .zero)
        XCTAssertEqual(q.pitch, .zero)
        let v = Vector(0, 0.5, 0), u = Vector(0.5, 0, 0)
        XCTAssertEqual(v.rotated(by: q), u)
    }

    func testQuaternionFromRollYawPitch() {
        let roll = Angle.radians(2.31)
        let yaw = Angle.radians(0.2)
        let pitch = Angle.radians(1.12)
        let q = Quaternion(roll: roll, yaw: yaw, pitch: pitch)
        XCTAssertEqual(roll.radians, q.roll.radians, accuracy: epsilon)
        XCTAssertEqual(yaw.radians, q.yaw.radians, accuracy: epsilon)
        XCTAssertEqual(pitch.radians, q.pitch.radians, accuracy: epsilon)
    }

    func testQuaternionToAndFromRotation() {
        let roll = Angle.radians(2.31)
        let yaw = Angle.radians(0.2)
        let pitch = Angle.radians(1.12)
        let q = Quaternion(roll: roll, yaw: yaw, pitch: pitch)
        let r = Rotation(q)
        let q2 = Quaternion(r)
        XCTAssert(q.isEqual(to: q2))
        XCTAssertEqual(q2.roll.radians, q.roll.radians, accuracy: epsilon)
        XCTAssertEqual(q2.yaw.radians, q.yaw.radians, accuracy: epsilon)
        XCTAssertEqual(q2.pitch.radians, q.pitch.radians, accuracy: epsilon)
    }

    func testQuaternionVectorRotation() {
        let q = Quaternion(pitch: .halfPi)
        let r = Rotation(pitch: .halfPi)
        let r2 = Rotation(q)
        let q2 = Quaternion(r)
        let v = Vector(0, 0.5, 0), u = Vector(0, 0, -0.5)
        XCTAssertEqual(v.rotated(by: q), u)
        XCTAssertEqual(v.rotated(by: q2), u)
        XCTAssertEqual(v.rotated(by: r), u)
        XCTAssertEqual(v.rotated(by: r2), u)
    }
}
