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
        let line = LineSegment(unchecked: Vector(-2, -1, 0), Vector(2, 1, 0))
        let point = Vector(-1, -0.5, 0)
        XCTAssert(line.containsPoint(point))
    }

    func testDoesNotContainPoint() {
        let line = LineSegment(unchecked: Vector(-2, -1, 0), Vector(2, 1, 0))
        XCTAssertFalse(line.containsPoint(Vector(-1, -0.6, 0)))
    }

    func testDoesNotContainPointBeforeStart() {
        let line = LineSegment(unchecked: Vector(-2, -1, 0), Vector(2, 1, 0))
        XCTAssertFalse(line.containsPoint(Vector(-3, -1.5, 0)))
    }

    func testDoesNotContainPointAfterEnd() {
        let line = LineSegment(unchecked: Vector(-2, -1, 0), Vector(2, 1, 0))
        XCTAssertFalse(line.containsPoint(Vector(4, 2, 0)))
    }

    // MARK: Clipping

    func testClipAbovePlane() {
        let line = LineSegment(unchecked: Vector(0, 1, 0), Vector(0, 2, 0))
        let plane = Plane.xz
        XCTAssertEqual(line.clip(to: plane), line)
        XCTAssertNil(line.clip(to: plane.inverted()))
        XCTAssertEqual(line.split(along: plane).front, line)
        XCTAssertNil(line.split(along: plane).back)
    }

    func testClipBelowPlane() {
        let line = LineSegment(unchecked: Vector(0, -1, 0), Vector(0, -2, 0))
        let plane = Plane.xz
        XCTAssertNil(line.clip(to: plane))
        XCTAssertEqual(line.clip(to: plane.inverted()), line)
        XCTAssertNil(line.split(along: plane).front)
        XCTAssertEqual(line.split(along: plane).back, line)
    }

    func testClipIntersectingPlane() {
        let line = LineSegment(unchecked: Vector(0, -1, 0), Vector(0, 1, 0))
        let plane = Plane.xz
        XCTAssertEqual(line.clip(to: plane), .init(unchecked: .zero, Vector(0, 1, 0)))
        XCTAssertEqual(line.clip(to: plane.inverted()), .init(unchecked: Vector(0, -1, 0), .zero))
        XCTAssertEqual(line.split(along: plane).front, .init(unchecked: .zero, Vector(0, 1, 0)))
        XCTAssertEqual(line.split(along: plane).back, .init(unchecked: Vector(0, -1, 0), .zero))
    }

    func testClipAlongPlane() {
        let line = LineSegment(unchecked: Vector(-1, 0, 0), Vector(1, 0, 0))
        let plane = Plane.xz
        XCTAssertEqual(line.clip(to: plane), line)
        XCTAssertEqual(line.clip(to: plane), line)
        XCTAssertEqual(line.split(along: plane).front, line)
        XCTAssertNil(line.split(along: plane).back) // TODO: does this inconsistency matter?
    }

    func testClipToCube() {
        let line = LineSegment(unchecked: Vector(0, -2, 0), Vector(0, 2, 0))
        let mesh = Mesh.cube()
        XCTAssertEqual([line].subtracting(mesh), [
            LineSegment(undirected: Vector(0, -2, 0), Vector(0, -0.5, 0)),
            LineSegment(undirected: Vector(0, 0.5, 0), Vector(0, 2, 0)),
        ])
    }
}
