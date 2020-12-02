//
//  positionTests.swift
//  EuclidTests
//
//  Created by Ioannis Kaliakatsos on 02.12.2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

private let epsilon = Double.ulpOfOne.squareRoot()

class PositionTests: XCTestCase {
    func testConstructor() {
        let position = Position(x: 1, y: 2, z: 3)
        XCTAssertEqual(1, position.x)
        XCTAssertEqual(2, position.y)
        XCTAssertEqual(3, position.z)
    }

    func testNorm() {
        let position = Position(x: 1, y: 2, z: 3)
        XCTAssertEqual(sqrt(14), position.norm, accuracy: epsilon)
    }

    func testNormNegativeComponent() {
        let position = Position(x: -1, y: 2, z: 3)
        XCTAssertEqual(sqrt(14), position.norm, accuracy: epsilon)
    }
}
