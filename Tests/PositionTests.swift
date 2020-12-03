//
//  positionTests.swift
//  EuclidTests
//
//  Created by Ioannis Kaliakatsos on 02.12.2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

class PositionTests: XCTestCase {
    func testConstructor() {
        let position = Position(x: 1, y: 2, z: 3)
        XCTAssertEqual(1, position.x)
        XCTAssertEqual(2, position.y)
        XCTAssertEqual(3, position.z)
    }

    func testNorm() {
        let position = Position(x: -1, y: 2, z: 3)
        XCTAssertEqual(sqrt(14), position.norm)
    }

    func testAddDistanceToPosition() {
        let position = Position(x: 1, y: 3, z: 9)
        let distance = Distance(x: -2, y: 5, z: -2)
        let expected = Position(x: -1, y: 8, z: 7)
        XCTAssertEqual(expected, position + distance)
    }

    func testSubtractDistanceToPosition() {
        let position = Position(x: 1, y: 3, z: 9)
        let distance = Distance(x: -2, y: 5, z: -2)
        let expected = Position(x: 3, y: -2, z: 11)
        XCTAssertEqual(expected, position - distance)
    }

    func testDistanceFromPositions() {
        let position1 = Position(x: 1, y: 2, z: 3)
        let position2 = Position(x: 2, y: -5, z: 9)
        let expected = Distance(x: 1, y: -7, z: 6)
        XCTAssertEqual(expected, position2 - position1)
    }
}
