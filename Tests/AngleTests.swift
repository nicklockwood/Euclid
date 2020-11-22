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

    func testCosSecondQuadrant() {
        let angle = Angle(degrees: 150)
        assertEqual(-sqrt(3) / 2, angle.cos)
    }

    func testCosThirdQuadrant() {
        let angle = Angle(degrees: 210)
        assertEqual(-sqrt(3) / 2, angle.cos)
    }

    func testCosFourthQuadrant() {
        let angle = Angle(degrees: -30)
        assertEqual(sqrt(3) / 2, angle.cos)
    }

    func testSinFirstQuadrant() {
        let angle = Angle(degrees: 30)
        assertEqual(0.5, angle.sin)
    }

    func testSinSecondQuadrant() {
        let angle = Angle(degrees: 150)
        assertEqual(0.5, angle.sin)
    }

    func testSinThirdQuadrant() {
        let angle = Angle(degrees: 210)
        assertEqual(-0.5, angle.sin)
    }

    func testSinFourthQuadrant() {
        let angle = Angle(degrees: -30)
        assertEqual(-0.5, angle.sin)
    }

    func testTanFirstQuadrant() {
        let angle = Angle(degrees: 30)
        assertEqual(1 / sqrt(3), angle.tan)
    }

    func testTanSecondQuadrant() {
        let angle = Angle(degrees: 150)
        assertEqual(-1 / sqrt(3), angle.tan)
    }

    func testTanThirdQuadrant() {
        let angle = Angle(degrees: 210)
        assertEqual(1 / sqrt(3), angle.tan)
    }

    func testTanFourthQuadrant() {
        let angle = Angle(degrees: -30)
        assertEqual(-1 / sqrt(3), angle.tan)
    }

    func testAcosFirstQuadrant() {
        let angle = Angle.acos(0.5)
        assertEqual(60, angle.degrees)
    }

    func testAcosSecondQuadrant() {
        let angle = Angle.acos(-0.5)
        assertEqual(120, angle.degrees)
    }

    func testAsinFirstQuadrant() {
        let angle = Angle.asin(0.5)
        assertEqual(30, angle.degrees)
    }

    func testAsinFourthQuadrant() {
        let angle = Angle.asin(-0.5)
        assertEqual(-30, angle.degrees)
    }

    func testAtanFirstQuadrant() {
        let angle = Angle.atan(x: sqrt(3), y: 1)
        assertEqual(30, angle.degrees)
    }

    func testAtanSecondQuadrant() {
        let angle = Angle.atan(x: -sqrt(3), y: 1)
        assertEqual(150, angle.degrees)
    }

    func testAtanThirdQuadrant() {
        let angle = Angle.atan(x: -sqrt(3), y: -1)
        assertEqual(-150, angle.degrees)
    }

    func testAtanFourthQuadrant() {
        let angle = Angle.atan(x: sqrt(3), y: -1)
        assertEqual(-30, angle.degrees)
    }

    func testAddition() {
        let angle1 = Angle(degrees: 30)
        let angle2 = Angle(degrees: 10)
        let sum = angle1 + angle2
        assertEqual(40, sum.degrees)
    }

    func testSubtraction() {
        let angle1 = Angle(degrees: 30)
        let angle2 = Angle(degrees: 10)
        let difference = angle1 - angle2
        assertEqual(20, difference.degrees)
    }

    func testPrefix() {
        let angle = -Angle(degrees: 30)
        assertEqual(-30, angle.degrees)
    }

    func testEquality1() {
        let angle1 = Angle(degrees: 30)
        let angle2 = Angle(degrees: 30)
        XCTAssertTrue(angle1 == angle2)
        XCTAssertFalse(angle1 != angle2)
    }

    func testEquality2() {
        let angle1 = Angle(degrees: 30)
        let angle2 = Angle(degrees: 50)
        XCTAssertFalse(angle1 == angle2)
        XCTAssertTrue(angle1 != angle2)
    }

    func testComparable1() {
        let angle1 = Angle(degrees: 10)
        let angle2 = Angle(degrees: 20)
        XCTAssertTrue(angle1 < angle2)
        XCTAssertTrue(angle1 <= angle2)
        XCTAssertFalse(angle1 > angle2)
        XCTAssertFalse(angle1 >= angle2)
    }

    func testComparable2() {
        let angle1 = Angle(degrees: 10)
        let angle2 = Angle(degrees: 10)
        XCTAssertFalse(angle1 < angle2)
        XCTAssertTrue(angle1 <= angle2)
        XCTAssertFalse(angle1 > angle2)
        XCTAssertTrue(angle1 >= angle2)
    }
}

private extension XCTestCase {
    func assertEqual(_ expression1: Double, _ expression2: Double) {
        XCTAssertTrue(expression1.isAlmostEqual(to: expression2))
    }
}
