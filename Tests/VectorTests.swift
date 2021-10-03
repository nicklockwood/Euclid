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
        let vector = Vector(1, 0, 0)
        XCTAssertEqual(vector.length, 1)
    }

    func testAngledLength() {
        let vector = Vector(2, 5, 3)
        let length = (2.0 * 2.0 + 5.0 * 5.0 + 3.0 * 3.0).squareRoot()
        XCTAssertEqual(vector.length, length)
    }

    // MARK: Angle with vector

    func testRightAngle() {
        let vector1 = Vector(1, 0, 0)
        let vector2 = Vector(0, 1, 0)
        XCTAssertEqual(vector1.angle(with: vector2), .halfPi)
    }

    func testNonNormalizedAngle() {
        let vector1 = Vector(10, 0, 0)
        let vector2 = Vector(-10, 0, 0)
        XCTAssertEqual(vector1.angle(with: vector2), .pi)
    }

    // MARK: Angle with plane

    func testRightAngleWithPlane() {
        let direction = Vector(1, 0, 0)
        let plane = Plane(unchecked: .x, pointOnPlane: .origin)
        XCTAssertEqual(direction.angle(with: plane), .halfPi)
    }
}
