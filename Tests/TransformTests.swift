//
//  TransformTests.swift
//  GeometryScriptTests
//
//  Created by Nick Lockwood on 17/10/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

class TransformTests: XCTestCase {
    // MARK: Rotation

    func testAxisAngleRotation1() {
        let axis = Vector(0, 0, 1)
        let r = Rotation(unchecked: axis, angle: .halfPi)
        let v = Vector(0, 0.5, 0)
        let u = v.rotated(by: r)
        XCTAssertEqual(u, Vector(0.5, 0, 0))
    }

    func testAxisAngleRotation2() {
        let axis = Vector(0, 0, 1)
        let r = Rotation(unchecked: axis, angle: .halfPi)
        let v = Vector(0.5, 0, 0)
        let u = v.rotated(by: r)
        XCTAssertEqual(u, Vector(0, -0.5, 0))
    }

    func testAxisAngleRotation3() {
        let axis = Vector(0, 0, 1)
        let r = Rotation(unchecked: axis, angle: .halfPi)
        let v = Vector(0, 0, 0.5)
        let u = v.rotated(by: r)
        XCTAssertEqual(u, Vector(0, 0, 0.5))
    }

    func testPitchRotation() {
        let r = Rotation(pitch: .halfPi)
        XCTAssertEqual(r, .pitch(.halfPi))
        XCTAssertEqual(r.pitch.radians, .pi / 2, accuracy: epsilon)
        XCTAssertEqual(r.roll, .zero)
        XCTAssertEqual(r.yaw, .zero)
        let v = Vector(0, 0.5, 0), u = Vector(0, 0, -0.5)
        XCTAssertEqual(v.rotated(by: r), u)
    }

    func testYawRotation() {
        let r = Rotation(yaw: .halfPi)
        XCTAssertEqual(r, .yaw(.halfPi))
        XCTAssert(r.isEqual(to: Rotation(Quaternion(yaw: .halfPi))))
        XCTAssertEqual(r.yaw, .halfPi)
        XCTAssertEqual(r.pitch, .zero)
        XCTAssertEqual(r.roll, .zero)
        let v = Vector(0.5, 0, 0), u = Vector(0, 0, 0.5)
        XCTAssertEqual(v.rotated(by: r), u)
    }

    func testRollRotation() {
        let r = Rotation(roll: .halfPi)
        XCTAssertEqual(r, .roll(.halfPi))
        XCTAssertEqual(r.roll.radians, .pi / 2, accuracy: epsilon)
        XCTAssertEqual(r.pitch, .zero)
        XCTAssertEqual(r.yaw, .zero)
        let v = Vector(0, 0.5, 0), u = Vector(0.5, 0, 0)
        XCTAssertEqual(v.rotated(by: r), u)
    }

    func testRotationFromRollYawPitch() {
        let roll = Angle.radians(2.31)
        let yaw = Angle.radians(0.2)
        let pitch = Angle.radians(1.12)
        let r = Rotation(roll: roll, yaw: yaw, pitch: pitch)
        XCTAssertEqual(roll.radians, r.roll.radians, accuracy: epsilon)
        XCTAssertEqual(yaw.radians, r.yaw.radians, accuracy: epsilon)
        XCTAssertEqual(pitch.radians, r.pitch.radians, accuracy: epsilon)
    }

    func testRotationToQuaternion() {
        let roll = Angle.radians(2.31)
        let yaw = Angle.radians(0.2)
        let pitch = Angle.radians(1.12)
        let r = Rotation(roll: roll, yaw: yaw, pitch: pitch)
        let q = Quaternion(r)
        XCTAssertEqual(q.roll.radians, r.roll.radians, accuracy: 0.01)
        XCTAssertEqual(q.yaw.radians, r.yaw.radians, accuracy: 0.01)
        XCTAssertEqual(q.pitch.radians, r.pitch.radians, accuracy: 0.01)
    }

    // MARK: Quaternions

    func testAxisAngleQuaternion1() {
        let axis = Vector(0, 0, 1)
        let q = Quaternion(unchecked: axis, angle: .halfPi)
        let v = Vector(0, 0.5, 0)
        let u = v.rotated(by: Rotation(q))
        XCTAssertEqual(u, Vector(0.5, 0, 0))
    }

    func testAxisAngleQuaternion2() {
        let axis = Vector(0, 0, 1)
        let q = Quaternion(unchecked: axis, angle: .halfPi)
        let v = Vector(0.5, 0, 0)
        let u = v.rotated(by: Rotation(q))
        XCTAssertEqual(u, Vector(0, -0.5, 0))
    }

    func testAxisAngleQuaternion3() {
        let axis = Vector(0, 0, 1)
        let q = Quaternion(unchecked: axis, angle: .halfPi)
        let v = Vector(0, 0, 0.5)
        let u = v.rotated(by: Rotation(q))
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
        let q2 = Rotation(q)
        let v = Vector(0, 0.5, 0), u = Vector(0, 0, -0.5)
        XCTAssertEqual(v.rotated(by: q), u)
        XCTAssertEqual(v.rotated(by: q2), u)
        XCTAssertEqual(v.rotated(by: r), u)
        XCTAssertEqual(v.rotated(by: r2), u)
    }

    // MARK: Rotation axis

    func testRotationIdentityAxis() {
        let r = Rotation.identity

        XCTAssertEqual(r.right, Vector(1, 0, 0))
        XCTAssertEqual(r.up, Vector(0, 1, 0))
        XCTAssertEqual(r.forward, Vector(0, 0, 1))
    }

    // MARK: Transform multiplication

    func testRotationMultipliedByTranslation() {
        let r = Rotation(roll: .zero, yaw: .pi / 4, pitch: .zero)
        let a = Transform(rotation: r)
        let b = Transform(offset: Vector(1, 0, 0))
        let c = a * b
        XCTAssertEqual(c.offset, Vector(1, 0, 0))
        XCTAssertEqual(c.rotation, r)
    }

    func testTranslationMultipliedByRotation() {
        let r = Rotation(roll: .zero, yaw: .pi / 4, pitch: .zero)
        let a = Transform(offset: Vector(1, 0, 0))
        let b = Transform(rotation: r)
        let c = a * b
        XCTAssertEqual(c.offset, Vector(sqrt(2) / 2, 0, sqrt(2) / 2))
        XCTAssertEqual(c.offset, a.offset.rotated(by: r))
        XCTAssertEqual(c.rotation, r)
    }

    func testRotationMultipliedByScale() {
        let r = Rotation(roll: .zero, yaw: .pi / 4, pitch: .zero)
        let a = Transform(rotation: r)
        let b = Transform(scale: Vector(2, 1, 1))
        let c = a * b
        XCTAssertEqual(c.scale, Vector(2, 1, 1)) // scale is unaffected by rotation
        XCTAssertEqual(c.rotation, r)
    }

    func testScaleMultipliedByRotation() {
        let r = Rotation(roll: .zero, yaw: .pi / 4, pitch: .zero)
        let a = Transform(scale: Vector(2, 1, 1))
        let b = Transform(rotation: r)
        let c = a * b
        XCTAssertEqual(c.scale, Vector(2, 1, 1))
        XCTAssertEqual(c.rotation, r)
    }

    func testTranslationMultipliedByScale() {
        let a = Transform(offset: Vector(1, 0, 0))
        let b = Transform(scale: Vector(2, 1, 1))
        let c = a * b
        XCTAssertEqual(c.offset, Vector(2, 0, 0))
        XCTAssertEqual(c.scale, Vector(2, 1, 1))
    }

    // MARK: Vector transform

    func testTransformVector() {
        let v = Vector(1, 1, 1)
        let t = Transform(
            offset: Vector(0.5, 0, 0),
            rotation: .roll(.halfPi),
            scale: Vector(1, 0.1, 0.1)
        )
        XCTAssertEqual(v.transformed(by: t), Vector(0.6, -1.0, 0.1))
    }

    // MARK: Plane transforms

    func testTranslatePlane() {
        let normal = Vector(0.5, 1, 0.5).normalized()
        let position = Vector(10, 5, -3)
        let plane = Plane(unchecked: normal, pointOnPlane: position)
        let offset = Vector(12, 3, 4)
        let expected = Plane(unchecked: normal, pointOnPlane: position + offset)
        XCTAssert(plane.translated(by: offset).isEqual(to: expected))
    }

    func testRotatePlane() {
        let normal = Vector(0.5, 1, 0.5).normalized()
        let position = Vector(10, 5, -3)
        let plane = Plane(unchecked: normal, pointOnPlane: position)
        let rotation = Rotation(axis: Vector(12, 3, 4).normalized(), angle: .radians(0.2))!
        let rotatedNormal = normal.rotated(by: rotation)
        let rotatedPosition = position.rotated(by: rotation)
        let expected = Plane(unchecked: rotatedNormal, pointOnPlane: rotatedPosition)
        XCTAssert(plane.rotated(by: rotation).isEqual(to: expected))
    }

    func testScalePlane() {
        let normal = Vector(0.5, 1, 0.5).normalized()
        let position = Vector(10, 5, -3)
        let plane = Plane(unchecked: normal, pointOnPlane: position)
        let scale = Vector(0.5, 3.0, 0.1)
        let expectedNormal = normal.scaled(by: Vector(1 / scale.x, 1 / scale.y, 1 / scale.z)).normalized()
        let expected = Plane(unchecked: expectedNormal, pointOnPlane: position.scaled(by: scale))
        XCTAssert(plane.scaled(by: scale).isEqual(to: expected))
    }

    func testScalePlaneUniformly() {
        let normal = Vector(0.5, 1, 0.5).normalized()
        let position = Vector(10, 5, -3)
        let plane = Plane(unchecked: normal, pointOnPlane: position)
        let scale = 0.5
        let expected = Plane(unchecked: normal, pointOnPlane: position * scale)
        XCTAssert(plane.scaled(by: scale).isEqual(to: expected))
    }

    func testTransformPlane() {
        let path = Path(unchecked: [
            .point(1, 2, 3),
            .point(7, -2, 12),
            .point(-2, 7, 14),
        ])
        let plane = path.plane!
        let transform = Transform(
            offset: Vector(-7, 3, 4.5),
            rotation: Rotation(axis: Vector(11, 3, -1).normalized(), angle: .radians(1.3))!,
            scale: Vector(7, 2.0, 0.3)
        )
        let expected = path.transformed(by: transform).plane!
        XCTAssert(plane.transformed(by: transform).isEqual(to: expected))
    }

    // MARK: Mesh transforms

    func testBoundsNotPreservedWhenMeshRotated() {
        let mesh = Mesh.cube()
        let transform = Transform(
            offset: Vector(-7, 3, 4.5),
            rotation: Rotation(axis: Vector(11, 3, -1).normalized(), angle: .radians(1.3))!,
            scale: Vector(7, 2.0, 0.3)
        )
        XCTAssertNil(mesh.transformed(by: transform).boundsIfSet)
    }

    func testBoundsPreservedWhenTransformingMeshWithoutRotation() {
        let mesh = Mesh.cube()
        let transform = Transform(
            offset: Vector(-7, 3, 4.5),
            rotation: .identity,
            scale: Vector(7, 2.0, 0.3)
        )
        XCTAssertNotNil(mesh.transformed(by: transform).boundsIfSet)
    }
}
