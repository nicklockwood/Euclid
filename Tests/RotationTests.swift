//
//  RotationTests.swift
//  Euclid
//
//  Created by Nick Lockwood on 16/06/2025.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

final class RotationTests: XCTestCase {
    func testAxisAngle() {
        let rotations: [(axis: Vector, angle: Angle)] = [
            (.unitX, .degrees(30)),
            (-.unitX, .degrees(30)),
            (.unitY, .degrees(10)),
            (.unitY, .degrees(17)),
            (.unitY, .degrees(135)),
            (Vector(1, 0.5, 0).normalized(), .degrees(55)),
        ]

        for (axis, angle) in rotations {
            let r = Rotation(unchecked: axis, angle: angle)
            XCTAssertEqual(r.angle, angle)
            XCTAssertEqual(r.axis, axis)
        }
    }

    func testAxisAngleWithZeroRotationDiscardsAxis() {
        let r = Rotation(unchecked: .unitX, angle: .zero)
        XCTAssertEqual(r.axis, .unitZ)
        XCTAssert(r.angle.isZero)
    }

    func testAxisAngleWith180RotationPreservesAxis() {
        let r = Rotation(unchecked: .unitX, angle: .degrees(180))
        XCTAssertEqual(r.axis, .unitX)
        XCTAssertEqual(r.angle, .pi)
    }

    func testAxisAngleWith270RotationPreservesAxis() {
        let r = Rotation(unchecked: .unitX, angle: .degrees(270))
        XCTAssertEqual(r.axis, .unitX)
        XCTAssertEqual(r.angle, .pi * 1.5)
    }

    func testRotationFromTo() {
        let r = Rotation(from: .unitY, to: .unitX)
        XCTAssertEqual(r.angle, .halfPi)
        XCTAssertEqual(r.axis, .unitZ)
        XCTAssertEqual(Vector.unitY.rotated(by: r), .unitX)
    }

    func testRotationFromZeroToX() {
        let r = Rotation(from: .zero, to: .unitX)
        XCTAssertEqual(r.angle, .zero)
        XCTAssertEqual(r.axis, .unitZ)
    }

    func testRotationFromYToZero() {
        let r = Rotation(from: .unitY, to: .zero)
        XCTAssertEqual(r.angle, .zero)
        XCTAssertEqual(r.axis, .unitZ)
    }

    func testRotationFromZeroToZero() {
        let r = Rotation(from: .zero, to: .zero)
        XCTAssertEqual(r.angle, .zero)
        XCTAssertEqual(r.axis, .unitZ)
    }

    // MARK: Vector rotation

    func testAxisAngleRotation1() {
        let r = Rotation(unchecked: .unitZ, angle: .halfPi)
        let v = Vector(0, 0.5, 0)
        let u = v.rotated(by: r)
        XCTAssertEqual(u, [0.5, 0, 0])
    }

    func testAxisAngleRotation2() {
        let r = Rotation(unchecked: .unitZ, angle: .halfPi)
        let v = Vector(0.5, 0, 0)
        let u = v.rotated(by: r)
        XCTAssertEqual(u, [0, -0.5, 0])
    }

    func testAxisAngleRotation3() {
        let r = Rotation(unchecked: .unitZ, angle: .halfPi)
        let v = Vector(0, 0, 0.5)
        let u = v.rotated(by: r)
        XCTAssertEqual(u, [0, 0, 0.5])
    }

    func testPitchRotation() {
        let r = Rotation(pitch: .halfPi)
        XCTAssertEqual(r, .pitch(.halfPi))
        XCTAssertEqual(r.pitch, .pi / 2)
        XCTAssertEqual(r.roll, .zero)
        XCTAssertEqual(r.yaw, .zero)
        let v = Vector(0, 0.5, 0), u = Vector(0, 0, -0.5)
        XCTAssertEqual(v.rotated(by: r), u)
    }

    func testYawRotation() {
        let r = Rotation(yaw: .halfPi)
        XCTAssertEqual(r, .yaw(.halfPi))
        XCTAssertEqual(r, Rotation(yaw: .halfPi))
        XCTAssertEqual(r.yaw, .halfPi)
        XCTAssertEqual(r.pitch, .zero)
        XCTAssertEqual(r.roll, .zero)
        XCTAssertEqual(Vector(0.5, 0, 0).rotated(by: r), [0, 0, 0.5])
    }

    func testRollRotation() {
        let r = Rotation(roll: .halfPi)
        XCTAssertEqual(r, .roll(.halfPi))
        XCTAssertEqual(r.roll, .pi / 2)
        XCTAssertEqual(r.pitch, .zero)
        XCTAssertEqual(r.yaw, .zero)
        XCTAssertEqual(Vector(0, 0.5, 0).rotated(by: r), [0.5, 0, 0])
    }

    func testRotationFromRollYawPitch() {
        let roll = Angle.radians(2.31)
        let yaw = Angle.radians(0.2)
        let pitch = Angle.radians(1.12)
        let r = Rotation(roll: roll, yaw: yaw, pitch: pitch)
        XCTAssertEqual(roll, r.roll)
        XCTAssertEqual(yaw, r.yaw)
        XCTAssertEqual(pitch, r.pitch)
    }

    func testReverseRotation() {
        let r = Rotation(roll: -.pi * 0.5)
        let r2 = Rotation(roll: .pi * 1.5)
        let vector = Vector(0.5, 0.5, 0.5)
        XCTAssertEqual(vector.rotated(by: r), vector.rotated(by: r2))
        XCTAssertEqual(vector.rotated(by: r).rotated(by: -r), vector)
        XCTAssertEqual(vector.rotated(by: r2).rotated(by: -r2), vector)
        XCTAssertNotEqual(vector.rotated(by: r), vector.rotated(by: -r))
        XCTAssertNotEqual(vector.rotated(by: r2), vector.rotated(by: -r2))
    }

    func testRotationDoesntAffectNormalization() {
        let v = Vector(
            -0.9667550262674225,
            -0.13739397231926284,
            -0.21565624395553415
        )
        XCTAssert(v.isNormalized)
        let r = Rotation(
            0.681812047958374,
            -0.0165534820407629,
            -0.028187578544020653,
            0.7307965755462646
        )
        let u = v.rotated(by: r)
        XCTAssert(u.isNormalized)
    }

    // MARK: Rotation axis

    func testRotationIdentityAxis() {
        let r = Rotation.identity

        XCTAssertEqual(r.right, .unitX)
        XCTAssertEqual(r.up, .unitY)
        XCTAssertEqual(r.forward, .unitZ)
        XCTAssertEqual(r.angle, .zero)
        XCTAssertEqual(r.axis, .unitZ)
    }
}
