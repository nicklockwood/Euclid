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
    func testLinuxTestSuiteIncludesAllTests() {
        #if os(macOS)
        let thisClass = type(of: self)
        let linuxCount = thisClass.__allTests.count
        let darwinCount = thisClass.defaultTestSuite.testCaseCount
        XCTAssertEqual(linuxCount, darwinCount, "run swift test --generate-linuxmain")
        #endif
    }

    // MARK: Rotation

    func testAxisAngleRotation1() {
        let axis = Vector(0, 0, 1)
        let r = Rotation(unchecked: axis, radians: .pi / 2)
        let v = Vector(0, 0.5, 0)
        let u = v.rotated(by: r)
        XCTAssertEqual(u.quantized(), Vector(0.5, 0, 0))
    }

    func testAxisAngleRotation2() {
        let axis = Vector(0, 0, 1)
        let r = Rotation(unchecked: axis, radians: .pi / 2)
        let v = Vector(0.5, 0, 0)
        let u = v.rotated(by: r)
        XCTAssertEqual(u.quantized(), Vector(0, -0.5, 0))
    }

    func testAxisAngleRotation3() {
        let axis = Vector(0, 0, 1)
        let r = Rotation(unchecked: axis, radians: .pi / 2)
        let v = Vector(0, 0, 0.5)
        let u = v.rotated(by: r)
        XCTAssertEqual(u.quantized(), Vector(0, 0, 0.5))
    }

    func testPitch() {
        let r = Rotation(pitch: .pi / 2)
        XCTAssertEqual(r.pitch, .pi / 2)
        XCTAssertEqual(r.roll, 0)
        XCTAssertEqual(r.yaw, 0)
        let v = Vector(0, 0.5, 0)
        let u = v.rotated(by: r)
        XCTAssertEqual(u.quantized(), Vector(0, 0, -0.5))
    }

    func testYaw() {
        let r = Rotation(yaw: .pi / 2)
        XCTAssertEqual(r.pitch, 0)
        XCTAssertEqual(r.roll, 0)
        XCTAssertEqual(r.yaw, .pi / 2)
        let v = Vector(0.5, 0, 0)
        let u = v.rotated(by: r)
        XCTAssertEqual(u.quantized(), Vector(0, 0, 0.5))
    }

    func testRoll() {
        let r = Rotation(roll: .pi / 2)
        XCTAssertEqual(r.pitch, 0)
        XCTAssertEqual(r.roll, .pi / 2)
        XCTAssertEqual(r.yaw, 0)
        let v = Vector(0, 0.5, 0)
        let u = v.rotated(by: r)
        XCTAssertEqual(u.quantized(), Vector(0.5, 0, 0))
    }

    // MARK: Transform multiplication

    func testRotationMultipliedByTranslation() {
        let r = Rotation(roll: 0, yaw: .pi / 4, pitch: 0)
        let a = Transform(rotation: r)
        let b = Transform(offset: Vector(1, 0, 0))
        let c = a * b
        XCTAssertEqual(c.offset, Vector(1, 0, 0))
        XCTAssertEqual(c.rotation, r)
    }

    func testTranslationMultipliedByRotation() {
        let r = Rotation(roll: 0, yaw: .pi / 4, pitch: 0)
        let a = Transform(offset: Vector(1, 0, 0))
        let b = Transform(rotation: r)
        let c = a * b
        XCTAssertEqual(c.offset.quantized(), Vector(sqrt(2) / 2, 0, sqrt(2) / 2).quantized())
        XCTAssertEqual(c.offset, a.offset.rotated(by: r))
        XCTAssertEqual(c.rotation, r)
    }

    func testRotationMultipliedByScale() {
        let r = Rotation(roll: 0, yaw: .pi / 4, pitch: 0)
        let a = Transform(rotation: r)
        let b = Transform(scale: Vector(2, 1, 1))
        let c = a * b
        XCTAssertEqual(c.scale, Vector(2, 1, 1)) // scale is unaffected by rotation
        XCTAssertEqual(c.rotation, r)
    }

    func testScaleMultipliedByRotation() {
        let r = Rotation(roll: 0, yaw: .pi / 4, pitch: 0)
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
            rotation: .roll(.pi / 2),
            scale: Vector(1, 0.1, 0.1)
        )
        XCTAssertEqual(v.transformed(by: t).quantized(), Vector(0.6, -1.0, 0.1).quantized())
    }
}
