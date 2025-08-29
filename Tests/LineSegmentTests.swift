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

    // MARK: Line intersection

    func testSegmentCrossingLine() {
        let a = LineSegment(unchecked: [-1, -1, 0], [1, 1, 0])
        let b = Line(unchecked: [0, 0, 0], direction: [1, 0, 0])
        XCTAssertTrue(a.intersects(b))
        XCTAssertTrue(b.intersects(a))
        let intersection = a.intersection(with: b)
        XCTAssertEqual(intersection, [0, 0, 0])
        XCTAssertEqual(b.intersection(with: a), intersection)
    }

    func testSegmentTouchingLine() {
        let a = LineSegment(unchecked: [-1, -1, 0], [0, 0, 0])
        let b = Line(unchecked: [0, 0, 0], direction: [1, 0, 0])
        XCTAssertTrue(a.intersects(b))
        XCTAssertTrue(b.intersects(a))
        let intersection = a.intersection(with: b)
        XCTAssertEqual(intersection, [0, 0, 0])
        XCTAssertEqual(b.intersection(with: a), intersection)
    }

    // MARK: Line Segment intersection

    func testCoincidentSegments() {
        let a = LineSegment(unchecked: [-1, -1, 0], [1, 1, 0])
        XCTAssertTrue(a.intersects(a))
        XCTAssertEqual(a.intersection(with: a), a.start)
    }

    func testSegmentCrossingSegment() {
        let a = LineSegment(unchecked: [-1, -1, 0], [1, 1, 0])
        let b = LineSegment(unchecked: [-1, 0, 0], [1, 0, 0])
        XCTAssertTrue(a.intersects(b))
        XCTAssertTrue(b.intersects(a))
        let intersection = a.intersection(with: b)
        XCTAssertEqual(intersection, [0, 0, 0])
        XCTAssertEqual(b.intersection(with: a), intersection)
    }

    func testSegmentTouchingSegment() {
        let a = LineSegment(unchecked: [-1, -1, 0], [0, 0, 0])
        let b = LineSegment(unchecked: [-1, 0, 0], [1, 0, 0])
        XCTAssertTrue(a.intersects(b))
        XCTAssertTrue(b.intersects(a))
        let intersection = a.intersection(with: b)
        XCTAssertEqual(intersection, [0, 0, 0])
        XCTAssertEqual(b.intersection(with: a), intersection)
    }

    func testSegmentTouchingOrthogonalSegment() {
        let a = LineSegment(unchecked: [0, -1, 0], [0, 0, 0])
        let b = LineSegment(unchecked: [-1, 0, 0], [1, 0, 0])
        XCTAssertTrue(a.intersects(b))
        XCTAssertTrue(b.intersects(a))
        let intersection = a.intersection(with: b)
        XCTAssertEqual(intersection, [0, 0, 0])
        XCTAssertEqual(b.intersection(with: a), intersection)
    }
}
