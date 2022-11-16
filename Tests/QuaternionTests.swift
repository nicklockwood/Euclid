//
//  QuaternionTests.swift
//  Euclid
//
//  Created by Nick Lockwood on 17/10/2022.
//  Copyright © 2022 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

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
        let q = Quaternion(axis: .unitX, angle: .halfPi)
        XCTAssertEqual(q?.axis, .unitX)
        XCTAssert(q?.angle.isEqual(to: .halfPi) == true)
    }

    func testAxisAngle2() {
        let q = Quaternion(axis: .unitY, angle: .pi * 0.75)
        XCTAssertEqual(q?.axis, .unitY)
        XCTAssert(q?.angle.isEqual(to: .pi * 0.75) == true)
    }

    func testAxisAngle3() {
        let q = Quaternion(axis: .unitZ, angle: .halfPi)
        XCTAssertEqual(q?.axis, .unitZ)
        XCTAssert(q?.angle.isEqual(to: .halfPi) == true)
    }

    func testAxisAngle4() {
        let q = Quaternion(axis: .unitZ, angle: .zero)
        XCTAssertEqual(q?.axis, .unitZ)
        XCTAssert(q?.angle.isEqual(to: .zero) == true)
    }
}
