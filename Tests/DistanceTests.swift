//
//  DistanceTests.swift
//  EuclidTests
//
//  Created by Ioannis Kaliakatsos on 03.12.2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

class DistanceTests: XCTestCase {
    func testComponents() {
        let distance = Distance(x: 1, y: 2, z: 3)
        XCTAssertEqual(1, distance.x)
        XCTAssertEqual(2, distance.y)
        XCTAssertEqual(3, distance.z)
    }

    func testZeroDistance() {
        XCTAssertEqual(0, Distance.zero.x)
        XCTAssertEqual(0, Distance.zero.y)
        XCTAssertEqual(0, Distance.zero.z)
    }

    func testAddition() {
        let distance1 = Distance(x: 1, y: 2, z: 3)
        let distance2 = Distance(x: 4, y: 5, z: 6)
        let sum = distance1 + distance2
        let expected = Distance(x: 5, y: 7, z: 9)
        XCTAssertEqual(expected, sum)
    }

    func testSubtraction() {
        let distance1 = Distance(x: 1, y: 2, z: 3)
        let distance2 = Distance(x: 4, y: 9, z: 2)
        let difference = distance1 - distance2
        let expected = Distance(x: -3, y: -7, z: 1)
        XCTAssertEqual(expected, difference)
    }

    func testDistance() {
        let distance = Distance(x: 1, y: 2, z: 3)
        let expected = Direction(x: 1 / sqrt(14), y: 2 / sqrt(14), z: 3 / sqrt(14))
        XCTAssertEqual(expected, distance.direction)
    }

    func testParallelDistances() {
        let distance1 = Distance(x: -1, y: 1, z: 3)
        let distance2 = Distance(x: -1, y: 1, z: 3)
        XCTAssertTrue(distance1.isParallel(to: distance2))
        XCTAssertFalse(distance1.isAntiparallel(to: distance2))
        XCTAssertTrue(distance1.isColinear(to: distance2))
        XCTAssertFalse(distance1.isNormal(to: distance2))
    }

    func testAntiparallelDistances() {
        let distance1 = Distance(x: -1, y: 2, z: 3)
        let distance2 = Distance(x: 1, y: -2, z: -3)
        XCTAssertFalse(distance1.isParallel(to: distance2))
        XCTAssertTrue(distance1.isAntiparallel(to: distance2))
        XCTAssertTrue(distance1.isColinear(to: distance2))
        XCTAssertFalse(distance1.isNormal(to: distance2))
    }

    func testNormalDistances() {
        let distance1 = Distance(x: 5)
        let distance2 = Distance(y: -1)
        XCTAssertFalse(distance1.isParallel(to: distance2))
        XCTAssertFalse(distance1.isAntiparallel(to: distance2))
        XCTAssertFalse(distance1.isColinear(to: distance2))
        XCTAssertTrue(distance1.isNormal(to: distance2))
    }

    func testGeneralDistances() {
        let distance1 = Distance(x: -1, y: 2, z: 3)
        let distance2 = Distance(x: 5, y: -9, z: 1)
        XCTAssertFalse(distance1.isParallel(to: distance2))
        XCTAssertFalse(distance1.isAntiparallel(to: distance2))
        XCTAssertFalse(distance1.isColinear(to: distance2))
        XCTAssertFalse(distance1.isNormal(to: distance2))
    }

    func testNorm() {
        let distance = Distance(x: 1, y: 2, z: 3)
        XCTAssertEqual(sqrt(14), distance.norm)
    }

    func testOperatorDoubleMultiplyWithDirection() {
        let direction = Direction(x: 1, y: 2, z: 3)
        let distance = sqrt(14) * direction
        let expexted = Distance(x: 1, y: 2, z: 3)
        XCTAssertEqual(expexted, distance)
    }

    func testCrossProduct1() {
        let distance1 = Distance(x: 5)
        let distance2 = Distance(x: 2, y: 1)
        let expected = Distance(z: 5)
        XCTAssertEqual(expected, distance1.cross(distance2))
    }

    func testCrossProduct1DifferentOrder() {
        let distance1 = Distance(x: 5)
        let distance2 = Distance(x: 2, y: 1)
        let expected = Distance(z: -5)
        XCTAssertEqual(expected, distance2.cross(distance1))
    }

    func testCrossProduct2() {
        let distance1 = Distance(x: 5)
        let distance2 = Distance(x: -2, y: 1)
        let expected = Distance(z: 5)
        XCTAssertEqual(expected, distance1.cross(distance2))
    }

    func testCrossProduct2DifferentOrder() {
        let distance1 = Distance(x: 5)
        let distance2 = Distance(x: -2, y: 1)
        let expected = Distance(z: -5)
        XCTAssertEqual(expected, distance2.cross(distance1))
    }

    func testRotated() {
        let distance = Distance(x: 2, z: 1)
        let rotated = distance.rotated(around: .z, by: Angle(degrees: 150))
        XCTAssertEqual(Distance(x: -sqrt(3), y: 1, z: 1), rotated)
    }

    func testScalarMultiply() {
        let distance = Distance(x: 1, y: 2, z: 3)
        let result = 2 * distance
        let expected = Distance(x: 2, y: 4, z: 6)
        XCTAssertEqual(expected, result)
    }

    func testScalarDivide() {
        let distance = Distance(x: 1, y: 2, z: 3)
        let result = distance / 2
        let expected = Distance(x: 0.5, y: 1, z: 1.5)
        XCTAssertEqual(expected, result)
    }
}
