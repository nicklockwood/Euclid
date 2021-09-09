//
//  LineSegmentTests.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 24/07/2021.
//  Copyright © 2021 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

class LineSegmentTests: XCTestCase {
    // MARK: Contains point

    func testContainsPoint() {
        let line = LineSegment(unchecked: Position(-2, -1, 0), Position(2, 1, 0))
        XCTAssert(line.containsPoint(Position(-1, -0.5, 0)))
    }

    func testDoesNotContainPoint() {
        let line = LineSegment(unchecked: Position(-2, -1, 0), Position(2, 1, 0))
        XCTAssertFalse(line.containsPoint(Position(-1, -0.6, 0)))
    }

    func testDoesNotContainPointBeforeStart() {
        let line = LineSegment(unchecked: Position(-2, -1, 0), Position(2, 1, 0))
        XCTAssertFalse(line.containsPoint(Position(-3, -1.5, 0)))
    }

    func testDoesNotContainPointAfterEnd() {
        let line = LineSegment(unchecked: Position(-2, -1, 0), Position(2, 1, 0))
        XCTAssertFalse(line.containsPoint(Position(4, 2, 0)))
    }
}
