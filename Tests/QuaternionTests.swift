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

    func testAxisAngle() {
        let q = Quaternion(axis: .unitX, angle: .halfPi)
        XCTAssertEqual(q?.axis, .unitX)
        XCTAssertEqual(q?.angle, .halfPi)
    }

    func testAxisAngle2() {
        let q = Quaternion(axis: .unitY, angle: .pi * 0.75)
        XCTAssertEqual(q?.axis, .unitY)
        XCTAssertEqual(q?.angle, .pi * 0.75)
    }

    func testAxisAngle3() {
        let q = Quaternion(axis: .unitZ, angle: .halfPi)
        XCTAssertEqual(q?.axis, .unitZ)
        XCTAssertEqual(q?.angle, .halfPi)
    }
}
