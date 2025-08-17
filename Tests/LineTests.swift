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
        let l = Line(unchecked: .zero, direction: .unitX)
        let p = Vector(15, 2, 0)
        XCTAssertEqual(l.distance(from: p), 2)
    }

    func testDistanceFromPointHarder() {
        let l = Line(unchecked: .zero, direction: .unitX)
        let p = Vector(15, 2, 3)
        XCTAssertEqual(l.distance(from: p), (2 * 2 + 3 * 3).squareRoot())
    }

    // MARK: Point projection

    func testProjectPointDown() {
        let l = Line(unchecked: .zero, direction: .unitX)
        let p = Vector(2, -2, 0)
        XCTAssertEqual(p.projected(onto: l), [2, 0, 0])
    }

    func testProjectPointUp() {
        let l = Line(unchecked: .zero, direction: .unitX)
        let p = Vector(3, 1, 0)
        XCTAssertEqual(p.projected(onto: l), [3, 0, 0])
    }

    func testProjectPointRight() {
        let l = Line(unchecked: .zero, direction: .unitY)
        let p = Vector(-3, 1, 0)
        XCTAssertEqual(p.projected(onto: l), .unitY)
    }

    func testProjectPointLeft() {
        let l = Line(unchecked: .zero, direction: .unitY)
        let p = Vector(3, -5, 0)
        XCTAssertEqual(p.projected(onto: l), [0, -5, 0])
    }

    func testProjectPointDiagonal() {
        let l = Line(unchecked: .zero, direction: Vector(1, 1, 0).normalized())
        let p = Vector(0, 2, 0)
        XCTAssert(p.projected(onto: l).isEqual(to: [1, 1, 0]))
    }

    // MARK: Line intersection

    func testLineIntersectionXY() {
        let l1 = Line(unchecked: [1, 0, 3], direction: .unitX)
        let l2 = Line(unchecked: [0, 1, 3], direction: -.unitY)

        let intersection = l1.intersection(with: l2)
        XCTAssertEqual(intersection, [0, 0, 3])
    }

    func testLineIntersectionXZ() {
        let l1 = Line(unchecked: [1, 3, 0], direction: .unitX)
        let l2 = Line(unchecked: [0, 3, 1], direction: -.unitZ)

        let intersection = l1.intersection(with: l2)
        XCTAssertEqual(intersection, [0, 3, 0])
    }

    func testLineIntersectionYZ() {
        let l1 = Line(unchecked: [3, 1, 0], direction: .unitY)
        let l2 = Line(unchecked: [3, 0, 1], direction: -.unitZ)

        let intersection = l1.intersection(with: l2)
        XCTAssertEqual(intersection, [3, 0, 0])
    }

    func testCoincidentLineIntersection() {
        let l1 = Line(unchecked: .unitX, direction: .unitX)
        XCTAssertNil(l1.intersection(with: l1))
    }

    // MARK: Contains point

    func testContainsPoint() {
        let line = Line(unchecked: [-2, -1, 0], direction: Vector(2, 1, 0).normalized())
        XCTAssert(line.intersects([-1, -0.5, 0]))
    }

    func testContainsPoint2() {
        let line = Line(unchecked: [-2, -1, 0], direction: Vector(2, 1, 0).normalized())
        XCTAssert(line.intersects([-3, -1.5, 0]))
    }

    func testDoesNotContainPoint() {
        let line = Line(unchecked: [-2, -1, 0], direction: Vector(2, 1, 0).normalized())
        XCTAssertFalse(line.intersects([-1, -0.6, 0]))
    }

    // MARK: Equality

    func testEquivalentHorizontalLinesAreEqual() {
        let l1 = Line(origin: [1, -1, 0], direction: .unitX)
        let l2 = Line(origin: [3, -1, 0], direction: .unitX)
        XCTAssertEqual(l1, l2)
        XCTAssert(Set([l1]).contains(l2))
    }

    func testEquivalentVerticalLinesAreEqual() {
        let l1 = Line(origin: [2, 5, 0], direction: .unitY)
        let l2 = Line(origin: [2, -1, 0], direction: .unitY)
        XCTAssertEqual(l1, l2)
        XCTAssert(Set([l1]).contains(l2))
    }

    func testEquivalentZLinesAreEqual() {
        let l1 = Line(origin: [2, 5, -2], direction: -.unitZ)
        let l2 = Line(origin: [2, 5, 7], direction: -.unitZ)
        XCTAssertEqual(l1, l2)
        XCTAssert(Set([l1]).contains(l2))
    }

    func testEquivalentXYLinesAreEqual() {
        let direction = Vector(1, 2, 0).normalized()
        let l1 = Line(origin: [0, 0, -1], direction: direction)
        let l2 = Line(origin: [1, 2, -1], direction: direction)
        XCTAssertEqual(l1, l2)
        XCTAssert(Set([l1]).contains(l2))
    }

    func testEquivalentYZLinesAreEqual() {
        let direction = Vector(0, -1, 2).normalized()
        let l1 = Line(origin: .zero, direction: direction)
        let l2 = Line(origin: [0, -1, 2], direction: direction)
        XCTAssertEqual(l1, l2)
        XCTAssert(Set([l1]).contains(l2))
    }
}
