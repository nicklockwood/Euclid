//
//  LineTests.swift
//  GeometryScriptTests
//
//  Created by Andy Geers on 26/11/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

class LineTests: XCTestCase {
    // MARK: Vector distance

    func testDistanceFromPointSimple() {
        let l = Line(origin: .origin, direction: .x)
        let p = Position(15, 2, 0)
        XCTAssertEqual(l.distance(from: p), 2)
    }

    func testDistanceFromPointHarder() {
        let l = Line(origin: .origin, direction: .x)
        let p = Position(15, 2, 3)
        XCTAssertEqual(l.distance(from: p), (2 * 2 + 3 * 3).squareRoot())
    }

    // MARK: Point projection

    func testProjectPointDown() {
        let l = Line(origin: .origin, direction: .x)
        let p = Position(2, -2, 0)
        XCTAssertEqual(p.project(onto: l), Position(2, 0, 0))
    }

    func testProjectPointUp() {
        let l = Line(origin: .origin, direction: .x)
        let p = Position(3, 1, 0)
        XCTAssertEqual(p.project(onto: l), Position(3, 0, 0))
    }

    func testProjectPointRight() {
        let l = Line(origin: .origin, direction: .y)
        let p = Position(-3, 1, 0)
        XCTAssertEqual(p.project(onto: l), Position(0, 1, 0))
    }

    func testProjectPointLeft() {
        let l = Line(origin: .origin, direction: .y)
        let p = Position(3, -5, 0)
        XCTAssertEqual(p.project(onto: l), Position(0, -5, 0))
    }

    func testProjectPointDiagonal() {
        let l = Line(origin: .origin, direction: Direction(1, 1, 0))
        let p = Position(0, 2, 0)
        XCTAssert(p.project(onto: l).isEqual(to: Position(1, 1, 0)))
    }

    // MARK: Line intersection

    func testLineIntersectionXY() {
        let l1 = Line(origin: Position(1, 0, 3), direction: .x)
        let l2 = Line(origin: Position(0, 1, 3), direction: -.y)

        let intersection = l1.intersection(with: l2)
        XCTAssertEqual(intersection, Position(0, 0, 3))
    }

    func testLineIntersectionXZ() {
        let l1 = Line(origin: Position(1, 3, 0), direction: .x)
        let l2 = Line(origin: Position(0, 3, 1), direction: -.z)

        let intersection = l1.intersection(with: l2)
        XCTAssertEqual(intersection, Position(0, 3, 0))
    }

    func testLineIntersectionYZ() {
        let l1 = Line(origin: Position(3, 1, 0), direction: .y)
        let l2 = Line(origin: Position(3, 0, 1), direction: -.z)

        let intersection = l1.intersection(with: l2)
        XCTAssertEqual(intersection, Position(3, 0, 0))
    }

    func testCoincidentLineIntersection() {
        let l1 = Line(origin: Position(x: 1, y: 0, z: 0), direction: .x)
        XCTAssertNil(l1.intersection(with: l1))
    }

    // MARK: Contains point

    func testContainsPoint() {
        let line = Line(origin: Position(-2, -1, 0), direction: Direction(2, 1, 0))
        XCTAssert(line.containsPoint(Position(-1, -0.5, 0)))
    }

    func testContainsPoint2() {
        let line = Line(origin: Position(-2, -1, 0), direction: Direction(2, 1, 0))
        XCTAssert(line.containsPoint(Position(-3, -1.5, 0)))
    }

    func testDoesNotContainPoint() {
        let line = Line(origin: Position(-2, -1, 0), direction: Direction(2, 1, 0))
        XCTAssertFalse(line.containsPoint(Position(-1, -0.6, 0)))
    }

    // MARK: Equality

    func testEquivalentHorizontalLinesAreEqual() {
        let l1 = Line(origin: Position(1, -1, 0), direction: .x)
        let l2 = Line(origin: Position(3, -1, 0), direction: .x)
        XCTAssertEqual(l1, l2)
        XCTAssert(Set([l1]).contains(l2))
    }

    func testEquivalentVerticalLinesAreEqual() {
        let l1 = Line(origin: Position(2, 5, 0), direction: .y)
        let l2 = Line(origin: Position(2, -1, 0), direction: .y)
        XCTAssertEqual(l1, l2)
        XCTAssert(Set([l1]).contains(l2))
    }

    func testEquivalentZLinesAreEqual() {
        let l1 = Line(origin: Position(2, 5, -2), direction: -.z)
        let l2 = Line(origin: Position(2, 5, 7), direction: -.z)
        XCTAssertEqual(l1, l2)
        XCTAssert(Set([l1]).contains(l2))
    }

    func testEquivalentXYLinesAreEqual() {
        let direction = Direction(1, 2, 0)
        let l1 = Line(origin: Position(0, 0, -1), direction: direction)
        let l2 = Line(origin: Position(1, 2, -1), direction: direction)
        XCTAssertEqual(l1, l2)
        XCTAssert(Set([l1]).contains(l2))
    }

    func testEquivalentYZLinesAreEqual() {
        let direction = Direction(0, -1, 2)
        let l1 = Line(origin: Position(0, 0, 0), direction: direction)
        let l2 = Line(origin: Position(0, -1, 2), direction: direction)
        XCTAssertEqual(l1, l2)
        XCTAssert(Set([l1]).contains(l2))
    }
}
