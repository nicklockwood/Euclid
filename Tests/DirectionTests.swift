//
//  DirectionTests.swift
//  EuclidTests
//
//  Created by Ioannis Kaliakatsos on 02.12.2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

private let epsilon = Double.ulpOfOne.squareRoot()

class DirectionTests: XCTestCase {
    func testNormedComponents() {
        let direction = Direction(x: 1, y: 2, z: 3)
        XCTAssertEqual(1.0 / sqrt(14.0), direction.x, accuracy: epsilon)
        XCTAssertEqual(2.0 / sqrt(14.0), direction.y, accuracy: epsilon)
        XCTAssertEqual(3.0 / sqrt(14.0), direction.z, accuracy: epsilon)
    }

    func testZeroDirection() {
        let direction = Direction.zero
        XCTAssertEqual(0, direction.x)
        XCTAssertEqual(0, direction.y)
        XCTAssertEqual(0, direction.z)
    }
}
