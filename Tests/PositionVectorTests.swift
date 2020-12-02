//
//  PositionVectorTests.swift
//  EuclidTests
//
//  Created by Ioannis Kaliakatsos on 02.12.2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

private let epsilon = Double.ulpOfOne.squareRoot()

class PositionVectorTests: XCTestCase {
    func testConstructor() {
        let positionVector = PositionVector(x: 1, y: 2, z: 3)
        XCTAssertEqual(1, positionVector.x)
        XCTAssertEqual(2, positionVector.y)
        XCTAssertEqual(3, positionVector.z)
    }

    func testNorm() {
        let positionVector = PositionVector(x: 1, y: 2, z: 3)
        XCTAssertEqual(sqrt(14), positionVector.norm, accuracy: epsilon)
    }

    func testNormNegativeComponent() {
        let positionVector = PositionVector(x: -1, y: 2, z: 3)
        XCTAssertEqual(sqrt(14), positionVector.norm, accuracy: epsilon)
    }
}
