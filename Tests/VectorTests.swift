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

    func testAngles() {
        let rotations = [
            Rotation(unchecked: .unitX, angle: .degrees(30)),
            Rotation(unchecked: -.unitX, angle: .degrees(30)),
            Rotation(unchecked: .unitY, angle: .degrees(10)),
            Rotation(unchecked: .unitY, angle: .degrees(17)),
            Rotation(unchecked: .unitY, angle: .degrees(135)),
            Rotation(unchecked: .unitY, angle: .degrees(182)),
            Rotation(axis: [1, 0.5, 0], angle: .degrees(55))!,
        ]

        for r in rotations {
            let rotated = Vector.unitZ.rotated(by: r)
            let angle = Vector.unitZ.angle(with: rotated)
            if r.angle.radians < .pi {
                XCTAssertEqual(angle, r.angle)
            } else {
                XCTAssertEqual(angle, .twoPi - r.angle)
            }
        }
    }

    func testEqualAngles() {
        let vector1 = Vector.unitX
        let vector2 = Vector.unitX
        XCTAssertEqual(vector1.angle(with: vector2), .zero)
    }

    func testInverseAngles() {
        let vector1 = Vector.unitX
        let vector2 = -Vector.unitX
        XCTAssertEqual(vector1.angle(with: vector2), .pi)
    }

    // MARK: Angle with plane

    func testRightAngleWithPlane() {
        let vector = Vector.unitX
        XCTAssertEqual(vector.angle(with: .yz), .halfPi)
    }

    func testNonNormalizedAngleWithPlane() {
        let vector = Vector(7, 0, 0)
        XCTAssertEqual(vector.angle(with: .yz), .halfPi)
    }

    func test45DegreeAngleWithPlane() {
        let vector = Vector(1, 1, 0)
        let angle = vector.angle(with: .yz)
        XCTAssertEqual(angle, .degrees(45))
    }

    func testNegative45DegreeAngleWithPlane() {
        let vector = Vector(-1, 1, 0)
        let angle = vector.angle(with: .yz)
        XCTAssertEqual(angle, .degrees(-45))
    }

    func testNegativeRightAngleWithPlane() {
        let vector = -Vector.unitX
        let angle = vector.angle(with: .yz)
        XCTAssertEqual(angle, -.halfPi)
    }

    // MARK: Distance from plane

    func testDistanceInFrontOfPlane() {
        let vector1 = Vector.unitX
        let vector2 = Vector(2, 1, -2)
        let plane = Plane(unchecked: vector1, pointOnPlane: .zero)
        XCTAssertEqual(vector2.signedDistance(from: plane), 2)
    }

    func testDistanceBehindPlane() {
        let vector1 = Vector.unitX
        let vector2 = Vector(-1.5, 2, 7)
        let plane = Plane(unchecked: vector1, pointOnPlane: .zero)
        XCTAssertEqual(vector2.signedDistance(from: plane), -1.5)
    }
}
