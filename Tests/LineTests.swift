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
        let l = Line(unchecked: Vector(0, 0, 0), direction: Vector(1, 0, 0))
        let p = Vector(15, 2, 0)
        XCTAssertEqual(l.distance(from: p), 2)
    }

    func testDistanceFromPointHarder() {
        let l = Line(unchecked: Vector(0, 0, 0), direction: Vector(1, 0, 0))
        let p = Vector(15, 2, 3)
        XCTAssertEqual(l.distance(from: p), (2 * 2 + 3 * 3).squareRoot())
    }

    // MARK: Point projection

    func testProjectPointDown() {
        let l = Line(unchecked: Vector(0, 0, 0), direction: Vector(1, 0, 0))
        let p = Vector(2, -2, 0)
        XCTAssertEqual(p.project(onto: l), Vector(2, 0, 0))
    }

    func testProjectPointUp() {
        let l = Line(unchecked: Vector(0, 0, 0), direction: Vector(1, 0, 0))
        let p = Vector(3, 1, 0)
        XCTAssertEqual(p.project(onto: l), Vector(3, 0, 0))
    }

    func testProjectPointRight() {
        let l = Line(unchecked: Vector(0, 0, 0), direction: Vector(0, 1, 0))
        let p = Vector(-3, 1, 0)
        XCTAssertEqual(p.project(onto: l), Vector(0, 1, 0))
    }

    func testProjectPointLeft() {
        let l = Line(unchecked: Vector(0, 0, 0), direction: Vector(0, 1, 0))
        let p = Vector(3, -5, 0)
        XCTAssertEqual(p.project(onto: l), Vector(0, -5, 0))
    }

    func testProjectPointDiagonal() {
        let l = Line(unchecked: Vector(0, 0, 0), direction: Vector(1, 1, 0).normalized())
        let p = Vector(0, 2, 0)
        XCTAssert(p.project(onto: l).isEqual(to: Vector(1, 1, 0)))
    }

    // MARK: Line intersection

    func testLineIntersectionXY() {
        let l1 = Line(unchecked: Vector(1, 0, 3), direction: Vector(1, 0, 0))
        let l2 = Line(unchecked: Vector(0, 1, 3), direction: Vector(0, -1, 0))

        let intersection = l1.intersection(with: l2)
        XCTAssertEqual(intersection, Vector(0, 0, 3))
    }

    func testLineIntersectionXZ() {
        let l1 = Line(unchecked: Vector(1, 3, 0), direction: Vector(1, 0, 0))
        let l2 = Line(unchecked: Vector(0, 3, 1), direction: Vector(0, 0, -1))

        let intersection = l1.intersection(with: l2)
        XCTAssertEqual(intersection, Vector(0, 3, 0))
    }

    func testLineIntersectionYZ() {
        let l1 = Line(unchecked: Vector(3, 1, 0), direction: Vector(0, 1, 0))
        let l2 = Line(unchecked: Vector(3, 0, 1), direction: Vector(0, 0, -1))

        let intersection = l1.intersection(with: l2)
        XCTAssertEqual(intersection, Vector(3, 0, 0))
    }

    func testCoincidentLineIntersection() {
        let l1 = Line(unchecked: Vector(1, 0), direction: Vector(1, 0))
        XCTAssertNil(l1.intersection(with: l1))
    }
}
