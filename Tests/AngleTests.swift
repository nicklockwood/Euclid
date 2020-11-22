//
//  AngleTests.swift
//  EuclidTests
//
//  Created by Ioannis Kaliakatsos on 22.11.20.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

class AngleTests: XCTestCase {
    func testConstructor() {
        let angle = Angle(degrees: 30)
        assertEqual(30, angle.degrees)
    }

    func testRadians() {
        let angle = Angle(degrees: 30)
        assertEqual(Double.pi / 6, angle.radians)
    }

    func testCosFirstQuadrant() {
        let angle = Angle(degrees: 30)
        assertEqual(sqrt(3) / 2, angle.cos)
    }

    func testSinFirstQuadrant() {
        let angle = Angle(degrees: 30)
        assertEqual(0.5, angle.sin)
    }

    func testTanFirstQuadrant() {
        let angle = Angle(degrees: 30)
        assertEqual(1 / sqrt(3), angle.tan)
    }
}

private extension XCTestCase {
    func assertEqual(_ expression1: Double, _ expression2: Double) {
        XCTAssertEqual(expression1, expression2, accuracy: 1e-10)
    }
}
