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
        let componentNorm = sqrt(14)
        XCTAssertEqual(1 / componentNorm, direction.x, accuracy: epsilon)
        XCTAssertEqual(2 / componentNorm, direction.y, accuracy: epsilon)
        XCTAssertEqual(3 / componentNorm, direction.z, accuracy: epsilon)
    }

    func testZeroDirection() {
        let direction = Direction.zero
        XCTAssertEqual(0, direction.x)
        XCTAssertEqual(0, direction.y)
        XCTAssertEqual(0, direction.z)
    }

    func testNormedAdditionOnXYPlane() {
        let direction1 = Direction(x: 1)
        let direction2 = Direction(y: 1)
        let direction = direction1 + direction2
        XCTAssertEqual(sqrt(2) / 2, direction.x, accuracy: epsilon)
        XCTAssertEqual(sqrt(2) / 2, direction.y, accuracy: epsilon)
        XCTAssertEqual(0, direction.z)
    }

    func testNormedSubtractionOnXYPlane() {
        let direction1 = Direction(x: 1)
        let direction2 = Direction(y: 1)
        let direction = direction1 - direction2
        XCTAssertEqual(sqrt(2) / 2, direction.x, accuracy: epsilon)
        XCTAssertEqual(-sqrt(2) / 2, direction.y, accuracy: epsilon)
        XCTAssertEqual(0, direction.z)
    }

    func testNormedAdditionOnXZPlane() {
        let direction1 = Direction(x: 1)
        let direction2 = Direction(z: 1)
        let direction = direction1 + direction2
        XCTAssertEqual(sqrt(2) / 2, direction.x, accuracy: epsilon)
        XCTAssertEqual(0, direction.y)
        XCTAssertEqual(sqrt(2) / 2, direction.z, accuracy: epsilon)
    }

    func testNormedSubtractionOnXZPlane() {
        let direction1 = Direction(x: 1)
        let direction2 = Direction(z: 1)
        let direction = direction1 - direction2
        XCTAssertEqual(sqrt(2) / 2, direction.x, accuracy: epsilon)
        XCTAssertEqual(0, direction.y)
        XCTAssertEqual(-sqrt(2) / 2, direction.z, accuracy: epsilon)
    }

    func testNormedAdditionOnYZPlane() {
        let direction1 = Direction(y: 1)
        let direction2 = Direction(z: 1)
        let direction = direction1 + direction2
        XCTAssertEqual(0, direction.x)
        XCTAssertEqual(sqrt(2) / 2, direction.y, accuracy: epsilon)
        XCTAssertEqual(sqrt(2) / 2, direction.z, accuracy: epsilon)
    }

    func testNormedSubtractionOnYZPlane() {
        let direction1 = Direction(y: 1)
        let direction2 = Direction(z: 1)
        let direction = direction1 - direction2
        XCTAssertEqual(0, direction.x)
        XCTAssertEqual(sqrt(2) / 2, direction.y, accuracy: epsilon)
        XCTAssertEqual(-sqrt(2) / 2, direction.z, accuracy: epsilon)
    }

    func testNormedAddition() {
        let direction1 = Direction(x: 1, y: 2, z: 3)
        let direction2 = Direction(x: 5, y: 6, z: 7)
        let direction = direction1 + direction2
        XCTAssertEqual(0.37497702770252406, direction.x, accuracy: epsilon)
        XCTAssertEqual(0.55773354233061923, direction.y, accuracy: epsilon)
        XCTAssertEqual(0.74049005695871428, direction.z, accuracy: epsilon)
    }

    func testDotProductObliqueAngle() {
        let direction1 = Direction.x
        let direction2 = Direction(x: 1, y: 1)
        let dotproduct = direction1.dot(direction2)
        XCTAssertEqual(sqrt(2) / 2, dotproduct, accuracy: epsilon)
    }

    func testDotProductObtuseAngle() {
        let direction1 = Direction.x
        let direction2 = Direction(x: -1, y: 1)
        let dotproduct = direction1.dot(direction2)
        XCTAssertEqual(-sqrt(2) / 2, dotproduct, accuracy: epsilon)
    }
}