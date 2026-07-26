//
//  PolygonInsetTests.swift
//  Euclid
//
//  Created by Nick Lockwood on 26/07/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

final class PolygonInsetTests: XCTestCase {
    func testInsetSquare() {
        let polygon = Polygon(unchecked: [
            [-1, 1],
            [-1, -1],
            [1, -1],
            [1, 1],
        ])
        let expected = Polygon(unchecked: [
            [-0.75, 0.75],
            [-0.75, -0.75],
            [0.75, -0.75],
            [0.75, 0.75],
        ])
        let result = polygon.inset(by: 0.25)
        XCTAssertEqual(result, expected)
    }

    func testInsetLShape() {
        let polygon = Polygon(unchecked: [
            [0, 0],
            [0, 2],
            [1, 2],
            [1, 1],
            [2, 1],
            [2, 0],
        ])
        let expected = Polygon(unchecked: [
            [0.25, 0.25],
            [0.25, 1.75],
            [0.75, 1.75],
            [0.75, 0.75],
            [1.75, 0.75],
            [1.75, 0.25],
        ])
        let result = polygon.inset(by: 0.25)
        XCTAssertEqual(result, expected)
    }

    func testInsetNarrowUShapeRemovesCrossingLines() {
        let polygon = Polygon(unchecked: [
            [0, 0],
            [0, 3],
            [1, 3],
            [1, 1],
            [2, 1],
            [2, 3],
            [3, 3],
            [3, 0],
        ])
        let result = polygon.inset(by: 0.6)
        XCTAssertFalse(result?.orderedEdgesContainCrossings ?? false)
    }
}
