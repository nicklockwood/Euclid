//
//  VectorTests.swift
//  GeometryScriptTests
//
//  Created by Nick Lockwood on 20/11/2019.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

class VectorTests: XCTestCase {
    // MARK: Vector length

    func testAxisAlignedLength() {
        let vector = Vector.unitX
        XCTAssertEqual(vector.length, 1)
    }

    func testAngledLength() {
        let vector = Vector(2, 5, 3)
        let length = (2.0 * 2.0 + 5.0 * 5.0 + 3.0 * 3.0).squareRoot()
        XCTAssertEqual(vector.length, length)
    }

    // MARK: Angle with vector

    func testRightAngle() {
        let vector1 = Vector.unitX
        let vector2 = Vector.unitY
        XCTAssertEqual(vector1.angle(with: vector2), .halfPi)
    }

    func testNonNormalizedAngle() {
        let vector1 = Vector(10, 0, 0)
        let vector2 = Vector(-10, 0, 0)
        XCTAssertEqual(vector1.angle(with: vector2), .pi)
    }

    // MARK: Angle with plane

    func testRightAngleWithPlane() {
        let vector1 = Vector.unitX
        let plane = Plane(unchecked: vector1, pointOnPlane: Vector.zero)
        XCTAssertEqual(vector1.angle(with: plane), .halfPi)
    }

    func testNonNormalizedAngleWithPlane() {
        let vector1 = Vector(7, 0, 0)
        let plane = Plane(normal: vector1, pointOnPlane: Vector.zero)!
        XCTAssertEqual(vector1.angle(with: plane), .halfPi)
    }

    // MARK: Distance from plane

    func testDistanceInFrontOfPlane() {
        let vector1 = Vector.unitX
        let vector2 = Vector(2, 1, -2)
        let plane = Plane(unchecked: vector1, pointOnPlane: Vector.zero)
        XCTAssertEqual(vector2.distance(from: plane), 2)
    }

    func testDistanceBehindPlane() {
        let vector1 = Vector.unitX
        let vector2 = Vector(-1.5, 2, 7)
        let plane = Plane(unchecked: vector1, pointOnPlane: Vector.zero)
        XCTAssertEqual(vector2.distance(from: plane), -1.5)
    }
}
