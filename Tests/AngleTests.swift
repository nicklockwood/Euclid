//
//  AngleTests.swift
//  EuclidTests
//
//  Created by Ioannis Kaliakatsos on 22.11.20.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

final class AngleTests: XCTestCase {
    func testConstructor() {
        let angle = Angle.degrees(30)
        XCTAssertEqual(30, angle.degrees)
    }

    func testRadians() {
        let angle = Angle.degrees(30)
        XCTAssertEqual(Double.pi / 6, angle.radians)
    }

    func testCosFirstQuadrant() {
        let angle = Angle.degrees(30)
        XCTAssertEqual(sqrt(3) / 2, cos(angle))
    }

    func testCosSecondQuadrant() {
        let angle = Angle.degrees(150)
        XCTAssertEqual(-sqrt(3) / 2, cos(angle))
    }

    func testCosThirdQuadrant() {
        let angle = Angle.degrees(210)
        XCTAssertEqual(-sqrt(3) / 2, cos(angle))
    }

    func testCosFourthQuadrant() {
        let angle = Angle.degrees(-30)
        XCTAssertEqual(sqrt(3) / 2, cos(angle))
    }

    func testSinFirstQuadrant() {
        let angle = Angle.degrees(30)
        XCTAssertEqual(0.5, sin(angle))
    }

    func testSinSecondQuadrant() {
        let angle = Angle.degrees(150)
        XCTAssertEqual(0.5, sin(angle))
    }

    func testSinThirdQuadrant() {
        let angle = Angle.degrees(210)
        XCTAssertEqual(-0.5, sin(angle))
    }

    func testSinFourthQuadrant() {
        let angle = Angle.degrees(-30)
        XCTAssertEqual(-0.5, sin(angle))
    }

    func testTanFirstQuadrant() {
        let angle = Angle.degrees(30)
        XCTAssertEqual(1 / sqrt(3), tan(angle))
    }

    func testTanSecondQuadrant() {
        let angle = Angle.degrees(150)
        XCTAssertEqual(-1 / sqrt(3), tan(angle))
    }

    func testTanThirdQuadrant() {
        let angle = Angle.degrees(210)
        XCTAssertEqual(1 / sqrt(3), tan(angle))
    }

    func testTanFourthQuadrant() {
        let angle = Angle.degrees(-30)
        XCTAssertEqual(-1 / sqrt(3), tan(angle))
    }

    func testAcosFirstQuadrant() {
        let angle = Angle.acos(0.5)
        XCTAssertEqual(60, angle.degrees)
    }

    func testAcosSecondQuadrant() {
        let angle = Angle.acos(-0.5)
        XCTAssertEqual(120, angle.degrees)
    }

    func testAsinFirstQuadrant() {
        let angle = Angle.asin(0.5)
        XCTAssertEqual(30, angle.degrees)
    }

    func testAsinFourthQuadrant() {
        let angle = Angle.asin(-0.5)
        XCTAssertEqual(-30, angle.degrees)
    }

    func testAtanFirstQuadrant() {
        let angle = Angle.atan2(y: 1, x: sqrt(3))
        XCTAssertEqual(30, angle.degrees)
    }

    func testAtanSecondQuadrant() {
        let angle = Angle.atan2(y: 1, x: -sqrt(3))
        XCTAssertEqual(150, angle.degrees)
    }

    func testAtanThirdQuadrant() {
        let angle = Angle.atan2(y: -1, x: -sqrt(3))
        XCTAssertEqual(-150, angle.degrees)
    }

    func testAtanFourthQuadrant() {
        let angle = Angle.atan2(y: -1, x: sqrt(3))
        XCTAssertEqual(-30, angle.degrees)
    }

    func testAddition() {
        let sum = Angle.degrees(30) + .degrees(10)
        XCTAssertEqual(40, sum.degrees)
    }

    func testSubtraction() {
        let difference = Angle.degrees(30) - .degrees(10)
        XCTAssertEqual(20, difference.degrees)
    }

    func testPrefix() {
        let angle = -Angle.degrees(30)
        XCTAssertEqual(-30, angle.degrees)
    }

    func testEquality1() {
        let angle1 = Angle.degrees(30)
        let angle2 = Angle.degrees(30)
        XCTAssertTrue(angle1 == angle2)
        XCTAssertFalse(angle1 != angle2)
    }

    func testEquality2() {
        let angle1 = Angle.degrees(30)
        let angle2 = Angle.degrees(50)
        XCTAssertFalse(angle1 == angle2)
        XCTAssertTrue(angle1 != angle2)
    }

    func testComparable1() {
        let angle1 = Angle.degrees(10)
        let angle2 = Angle.degrees(20)
        XCTAssertTrue(angle1 < angle2)
        XCTAssertTrue(angle1 <= angle2)
        XCTAssertFalse(angle1 > angle2)
        XCTAssertFalse(angle1 >= angle2)
    }

    func testComparable2() {
        let angle1 = Angle.degrees(10)
        let angle2 = Angle.degrees(10)
        XCTAssertFalse(angle1 < angle2)
        XCTAssertTrue(angle1 <= angle2)
        XCTAssertFalse(angle1 > angle2)
        XCTAssertTrue(angle1 >= angle2)
    }
}
