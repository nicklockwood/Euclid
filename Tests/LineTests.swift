//
//  LineTests.swift
//  GeometryScriptTests
//
//  Created by Andy Geers on 26/11/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

final class LineTests: XCTestCase {
    // MARK: Point distance

    func testDistanceFromPointSimple() {
        let l = Line(unchecked: .unitY, direction: .unitX)
        let p = Vector(15, 2, 0)
        XCTAssertEqual(l.distance(from: p), 1)
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
        XCTAssertEqual(p.projected(onto: l), [1, 1, 0])
    }

    // MARK: Line distance

    func testIntersectingLineDistance() {
        let l1 = Line(unchecked: .random(), direction: .random().normalized())
        for _ in 0 ..< 10 {
            let l2 = Line(unchecked: l1.origin, direction: .random().normalized())
            XCTAssertEqual(l1.distance(from: l2), 0)
        }
    }

    func testNonIntersectingLineDistance() {
        let plane = Plane(unchecked: .random().normalized(), pointOnPlane: .random())
        let origin = Vector.random(in: plane)
        let l1 = Line(unchecked: origin, direction: (.random(in: plane) - origin).normalized())
        for _ in 0 ..< 10 {
            let distance = plane.normal * .random(in: -100 ... 100)
            let l2 = Line(unchecked: origin + distance, direction: (.random(in: plane) - origin).normalized())
            XCTAssertEqual(l1.distance(from: l2), distance.length, accuracy: 1e-2) // TODO: improve accuracy
        }
    }

    func testDistanceBetweenParallelLines() {
        let l1 = Line(unchecked: .random(), direction: .random().normalized())
        let plane = Plane(unchecked: l1.direction, pointOnPlane: l1.origin)
        for _ in 0 ..< 10 {
            let distance = Vector.random(in: plane) - l1.origin
            let l2 = Line(unchecked: l1.origin + distance, direction: l1.direction)
            XCTAssertEqual(l1.distance(from: l2), distance.length)
        }
    }

    // MARK: Line intersection

    func testLineIntersectionXY() {
        let l1 = Line(unchecked: [1, 0, 3], direction: .unitX)
        let l2 = Line(unchecked: [0, 1, 3], direction: -.unitY)
        XCTAssert(l1.intersects(l2))
        XCTAssert(l2.intersects(l1))

        let intersection = l1.intersection(with: l2)
        XCTAssertEqual(intersection, [0, 0, 3])
        XCTAssertEqual(l2.intersection(with: l1), intersection)
    }

    func testLineIntersectionXZ() {
        let l1 = Line(unchecked: [1, 3, 0], direction: .unitX)
        let l2 = Line(unchecked: [0, 3, 1], direction: -.unitZ)
        XCTAssert(l1.intersects(l2))
        XCTAssert(l2.intersects(l1))

        let intersection = l1.intersection(with: l2)
        XCTAssertEqual(intersection, [0, 3, 0])
        XCTAssertEqual(l2.intersection(with: l1), intersection)
    }

    func testLineIntersectionYZ() {
        let l1 = Line(unchecked: [3, 1, 0], direction: .unitY)
        let l2 = Line(unchecked: [3, 0, 1], direction: -.unitZ)
        XCTAssert(l1.intersects(l2))
        XCTAssert(l2.intersects(l1))

        let intersection = l1.intersection(with: l2)
        XCTAssertEqual(intersection, [3, 0, 0])
        XCTAssertEqual(l2.intersection(with: l1), intersection)
    }

    func testCoincidentLineIntersection() {
        let l1 = Line(unchecked: .unitX, direction: .unitX)
        XCTAssert(l1.intersects(l1))
        XCTAssertEqual(l1.intersection(with: l1), l1.origin)
    }

    func testParallelLineIntersection() {
        let l1 = Line(unchecked: .unitX, direction: .unitX)
        let distance = Vector.random(in: [0, -1, -1] ... [0, 1, 1])
        let l2 = l1.translated(by: distance)

        XCTAssertEqual(l1.distance(from: l2), distance.length)
        XCTAssertFalse(l1.intersects(l2))
        XCTAssertNil(l1.intersection(with: l2))
    }

    // MARK: Point intersection

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

    // MARK: Bounds intersection

    func testBoundsIntersection() {
        let transform = Transform(scale: .random(in: 0.1 ... 100), translation: .random())
        let line = Line(unchecked: .zero, direction: .unitX).transformed(by: transform)
        let bounds = Bounds(min: -.one, max: .one).transformed(by: transform)
        let expected = Set([Vector(-1, 0), Vector(1, 0)].transformed(by: transform))
        XCTAssertEqual(line.intersection(with: bounds), expected)
        XCTAssert(line.intersects(bounds))
    }

    func testBoundsNonIntersection() {
        let line = Line(unchecked: .unitY * 1.1, direction: .unitX).rotated(by: .random(in: .xz))
        let bounds = Bounds(min: -.one, max: .one)
        XCTAssertEqual(line.intersection(with: bounds), [])
        XCTAssertFalse(line.intersects(bounds))
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
