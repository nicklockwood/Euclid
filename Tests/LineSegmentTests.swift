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
    // MARK: Vector distance

    func testDistanceFromPoint() {
        let l = LineSegment(unchecked: -.unitX, .unitX)
        let p0 = Vector(0, 1, 0), p1 = Vector(-2, 1, 0), p2 = Vector(2, 1, 0)
        XCTAssertEqual(l.distance(from: p0), 1)
        XCTAssertEqual(l.distance(from: p1), sqrt(2))
        XCTAssertEqual(l.distance(from: p2), sqrt(2))
    }

    // MARK: Contains point

    func testContainsPoint() {
        let line = LineSegment(unchecked: [-2, -1, 0], [2, 1, 0])
        let point = Vector(-1, -0.5, 0)
        XCTAssert(line.intersects(point))
    }

    func testDoesNotContainPoint() {
        let line = LineSegment(unchecked: [-2, -1, 0], [2, 1, 0])
        XCTAssertFalse(line.intersects([-1, -0.6, 0]))
    }

    func testDoesNotContainPointBeforeStart() {
        let line = LineSegment(unchecked: [-2, -1, 0], [2, 1, 0])
        XCTAssertFalse(line.intersects([-3, -1.5, 0]))
    }

    func testDoesNotContainPointAfterEnd() {
        let line = LineSegment(unchecked: [-2, -1, 0], [2, 1, 0])
        XCTAssertFalse(line.intersects([4, 2, 0]))
    }
}
