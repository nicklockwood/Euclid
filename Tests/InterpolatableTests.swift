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
}
