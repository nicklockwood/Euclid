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
    func testZero() {
        let zero = Angle.zero
        XCTAssertEqual(0, zero.degrees)
        XCTAssertEqual(0, zero.radians)
    }

    func testPi() {
        let pi = Angle.pi
        XCTAssertEqual(180, pi.degrees)
        XCTAssertEqual(Double.pi, pi.radians)
    }

    func testTwoPi() {
        let twoPi = Angle.twoPi
        XCTAssertEqual(360, twoPi.degrees)
        XCTAssertEqual(2 * Double.pi, twoPi.radians)
    }

    func test45Degrees() {
        let fortyFiveDegrees = Angle(degrees: 45)
        XCTAssertEqual(45, fortyFiveDegrees.degrees)
        XCTAssertEqual(Double.pi / 4, fortyFiveDegrees.radians)
    }
}
