//
//  InterpolatableTests.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 11/10/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

final class InterpolatableTests: XCTestCase {
    func testCollectionInterpolation() {
        let values = [0.0, 10, 30]
        XCTAssertEqual(values.interpolated(by: 0), 0)
        XCTAssertEqual(values.interpolated(by: 0.25), 5)
        XCTAssertEqual(values.interpolated(by: 0.5), 10)
        XCTAssertEqual(values.interpolated(by: 0.75), 20)
        XCTAssertEqual(values.interpolated(by: 1), 30)
    }

    func testCollectionInterpolationClamps() {
        let values = [0.0, 10, 30]
        XCTAssertEqual(values.interpolated(by: -1), 0)
        XCTAssertEqual(values.interpolated(by: 2), 30)
    }

    func testEmptyAndSingleValueCollections() {
        XCTAssertNil([Double]().interpolated(by: 0.5))
        for t in [-1.0, 0, 0.5, 1, 2] {
            XCTAssertEqual([5.0].interpolated(by: t), 5)
        }
    }

    func testSliceInterpolation() {
        let values = [0.0, 10, 30, 50][1...]
        XCTAssertEqual(values.interpolated(by: 0), 10)
        XCTAssertEqual(values.interpolated(by: 0.25), 20)
        XCTAssertEqual(values.interpolated(by: 1), 50)
    }

    func testRotationCollectionInterpolation() {
        let values: [Rotation] = [.identity, .yaw(.degrees(90)), .yaw(.degrees(180))]
        XCTAssertEqual(values.interpolated(by: 0.75), .yaw(.degrees(135)))
    }

    func testRotationInterpolation() {
        let start = Rotation.yaw(.degrees(90))
        let end = Rotation.yaw(.degrees(180))
        for t in [-0.5, 0, 0.25, 0.5, 0.75, 1, 1.5] {
            let result = start.interpolated(with: end, by: t)
            XCTAssertEqual(result, .yaw(.degrees(90 + 90 * t)))
            XCTAssertEqual(
                result.x * result.x + result.y * result.y +
                    result.z * result.z + result.w * result.w,
                1,
                accuracy: 1e-12
            )
        }
    }

    func testRotationInterpolationTakesShortestArc() {
        let start = Rotation.yaw(.degrees(170))
        let end = Rotation.yaw(.degrees(-170))
        for t in [0.0, 0.25, 0.5, 0.75, 1] {
            let result = start.interpolated(with: end, by: t)
            let expected = Rotation.yaw(.degrees(170 + 20 * t))
            XCTAssertEqual(result.forward, expected.forward)
            XCTAssertEqual(result.right, expected.right)
        }
    }

    func testRotationInterpolationWithEquivalentQuaternions() {
        let rotation = Rotation.yaw(.degrees(90))
        let opposite = Rotation(unchecked: -rotation.x, -rotation.y, -rotation.z, -rotation.w)
        for other in [rotation, opposite] {
            for t in [0.0, 0.25, 0.5, 0.75, 1] {
                let result = rotation.interpolated(with: other, by: t)
                XCTAssertEqual(result.forward, rotation.forward)
                XCTAssertEqual(result.right, rotation.right)
            }
        }
    }

    func testRotationInterpolationWithNearlyEqualRotations() {
        let start = Rotation.yaw(.degrees(90))
        let end = Rotation.yaw(.degrees(90.001))
        for t in [0.0, 0.25, 0.5, 0.75, 1] {
            XCTAssertEqual(start.interpolated(with: end, by: t), .yaw(.degrees(90 + 0.001 * t)))
        }
    }
}
