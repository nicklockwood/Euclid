//
//  AngleTests.swift
//  EuclidTests
//
//  Created by Ioannis Kaliakatsos on 22.11.2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

private let epsilon = Double.ulpOfOne.squareRoot()

class AngleTests: XCTestCase {
    func testConstructor() {
        let angle = Angle.degrees(30)
        XCTAssertEqual(30, angle.degrees, accuracy: epsilon)
    }

    func testRadians() {
        let angle = Angle.degrees(30)
        XCTAssertEqual(Double.pi / 6, angle.radians, accuracy: epsilon)
    }

    func testCosFirstQuadrant() {
        let angle = Angle.degrees(30)
        XCTAssertEqual(sqrt(3) / 2, cos(angle), accuracy: epsilon)
    }

    func testCosSecondQuadrant() {
        let angle = Angle.degrees(150)
        XCTAssertEqual(-sqrt(3) / 2, cos(angle), accuracy: epsilon)
    }

    func testCosThirdQuadrant() {
        let angle = Angle.degrees(210)
        XCTAssertEqual(-sqrt(3) / 2, cos(angle), accuracy: epsilon)
    }

    func testCosFourthQuadrant() {
        let angle = Angle.degrees(-30)
        XCTAssertEqual(sqrt(3) / 2, cos(angle), accuracy: epsilon)
    }

    func testSinFirstQuadrant() {
        let angle = Angle.degrees(30)
        XCTAssertEqual(0.5, sin(angle), accuracy: epsilon)
    }

    func testSinSecondQuadrant() {
        let angle = Angle.degrees(150)
        XCTAssertEqual(0.5, sin(angle), accuracy: epsilon)
    }

    func testSinThirdQuadrant() {
        let angle = Angle.degrees(210)
        XCTAssertEqual(-0.5, sin(angle), accuracy: epsilon)
    }

    func testSinFourthQuadrant() {
        let angle = Angle.degrees(-30)
        XCTAssertEqual(-0.5, sin(angle), accuracy: epsilon)
    }

    func testTanFirstQuadrant() {
        let angle = Angle.degrees(30)
        XCTAssertEqual(1 / sqrt(3), tan(angle), accuracy: epsilon)
    }

    func testTanSecondQuadrant() {
        let angle = Angle.degrees(150)
        XCTAssertEqual(-1 / sqrt(3), tan(angle), accuracy: epsilon)
    }

    func testTanThirdQuadrant() {
        let angle = Angle.degrees(210)
        XCTAssertEqual(1 / sqrt(3), tan(angle), accuracy: epsilon)
    }

    func testTanFourthQuadrant() {
        let angle = Angle.degrees(-30)
        XCTAssertEqual(-1 / sqrt(3), tan(angle), accuracy: epsilon)
    }

    func testAcosFirstQuadrant() {
        let angle = Angle.acos(0.5)
        XCTAssertEqual(60, angle.degrees, accuracy: epsilon)
    }

    func testAcosSecondQuadrant() {
        let angle = Angle.acos(-0.5)
        XCTAssertEqual(120, angle.degrees, accuracy: epsilon)
    }

    func testAsinFirstQuadrant() {
        let angle = Angle.asin(0.5)
        XCTAssertEqual(30, angle.degrees, accuracy: epsilon)
    }

    func testAsinFourthQuadrant() {
        let angle = Angle.asin(-0.5)
        XCTAssertEqual(-30, angle.degrees, accuracy: epsilon)
    }

    func testAtan() {
        let angle = Angle.atan(1)
        XCTAssertEqual(45, angle.degrees, accuracy: epsilon)
    }

    func testAtan2FirstQuadrant() {
        let angle = Angle.atan2(y: 1, x: sqrt(3))
        XCTAssertEqual(30, angle.degrees, accuracy: epsilon)
    }

    func testAtan2SecondQuadrant() {
        let angle = Angle.atan2(y: 1, x: -sqrt(3))
        XCTAssertEqual(150, angle.degrees, accuracy: epsilon)
    }

    func testAtan2ThirdQuadrant() {
        let angle = Angle.atan2(y: -1, x: -sqrt(3))
        XCTAssertEqual(-150, angle.degrees, accuracy: epsilon)
    }

    func testAtan2FourthQuadrant() {
        let angle = Angle.atan2(y: -1, x: sqrt(3))
        XCTAssertEqual(-30, angle.degrees, accuracy: epsilon)
    }

    func testAddition() {
        let sum = Angle.degrees(30) + .degrees(10)
        XCTAssertEqual(40, sum.degrees, accuracy: epsilon)
    }

    func testSubtraction() {
        let difference = Angle.degrees(30) - .degrees(10)
        XCTAssertEqual(20, difference.degrees, accuracy: epsilon)
    }

    func testPrefix() {
        let angle = -Angle.degrees(30)
        XCTAssertEqual(-30, angle.degrees, accuracy: epsilon)
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
