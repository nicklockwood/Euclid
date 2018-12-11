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
        let r = Rotation(unchecked: axis, radians: Double.pi / 2)
        let v = Vector(0, 0.5, 0)
        let u = v.rotated(by: r)
        XCTAssertEqual(u.quantized(), Vector(0.5, 0, 0))
    }

    func testAxisAngleRotation2() {
        let axis = Vector(0, 0, 1)
        let r = Rotation(unchecked: axis, radians: Double.pi / 2)
        let v = Vector(0.5, 0, 0)
        let u = v.rotated(by: r)
        XCTAssertEqual(u.quantized(), Vector(0, -0.5, 0))
    }

    func testAxisAngleRotation3() {
        let axis = Vector(0, 0, 1)
        let r = Rotation(unchecked: axis, radians: Double.pi / 2)
        let v = Vector(0, 0, 0.5)
        let u = v.rotated(by: r)
        XCTAssertEqual(u.quantized(), Vector(0, 0, 0.5))
    }

    // MARK: Transform multiplication

    func testRotationMultipliedByTranslation() {
        let r = Rotation(yaw: 0, pitch: Double.pi / 4, roll: 0)
        let a = Transform(rotation: r)
        let b = Transform(offset: Vector(1, 0, 0))
        let c = a * b
        XCTAssertEqual(c.offset, Vector(1, 0, 0))
        XCTAssertEqual(c.rotation, r)
    }

    func testTranslationMultipliedByRotation() {
        let r = Rotation(yaw: 0, pitch: Double.pi / 4, roll: 0)
        let a = Transform(offset: Vector(1, 0, 0))
        let b = Transform(rotation: r)
        let c = a * b
        XCTAssertEqual(c.offset.quantized(), Vector(sqrt(2) / 2, 0, sqrt(2) / 2).quantized())
        XCTAssertEqual(c.offset, a.offset.rotated(by: r))
        XCTAssertEqual(c.rotation, r)
    }

    func testRotationMultipliedByScale() {
        let r = Rotation(yaw: 0, pitch: Double.pi / 4, roll: 0)
        let a = Transform(rotation: r)
        let b = Transform(scale: Vector(2, 1, 1))
        let c = a * b
        XCTAssertEqual(c.scale, Vector(2, 1, 1)) // scale is unaffected by rotation
        XCTAssertEqual(c.rotation, r)
    }

    func testScaleMultipliedByRotation() {
        let r = Rotation(yaw: 0, pitch: Double.pi / 4, roll: 0)
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
}
