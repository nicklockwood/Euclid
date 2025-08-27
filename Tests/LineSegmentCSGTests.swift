//
//  LineSegmentCSGTests.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 24/07/2021.
//  Copyright © 2021 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

class LineSegmentCSGTests: XCTestCase {
    // MARK: Plane Clipping

    func testClipAbovePlane() {
        let line = LineSegment(unchecked: [0, 1, 0], [0, 2, 0])
        let plane = Plane.xz
        XCTAssertEqual(line.clipped(to: plane), line)
        XCTAssertNil(line.clipped(to: plane.inverted()))
        XCTAssertEqual(line.split(along: plane).front, line)
        XCTAssertNil(line.split(along: plane).back)
    }

    func testClipBelowPlane() {
        let line = LineSegment(unchecked: [0, -1, 0], [0, -2, 0])
        let plane = Plane.xz
        XCTAssertNil(line.clipped(to: plane))
        XCTAssertEqual(line.clipped(to: plane.inverted()), line)
        XCTAssertNil(line.split(along: plane).front)
        XCTAssertEqual(line.split(along: plane).back, line)
    }

    func testClipIntersectingPlane() {
        let line = LineSegment(unchecked: [0, -1, 0], [0, 1, 0])
        let plane = Plane.xz
        XCTAssertEqual(line.clipped(to: plane), .init(unchecked: .zero, [0, 1, 0]))
        XCTAssertEqual(line.clipped(to: plane.inverted()), .init(unchecked: [0, -1, 0], .zero))
        XCTAssertEqual(line.split(along: plane).front, .init(unchecked: .zero, [0, 1, 0]))
        XCTAssertEqual(line.split(along: plane).back, .init(unchecked: [0, -1, 0], .zero))
    }

    func testClipAlongPlane() {
        let line = LineSegment(unchecked: [-1, 0, 0], [1, 0, 0])
        let plane = Plane.xz
        XCTAssertNil(line.clipped(to: plane))
        XCTAssertNil(line.clipped(to: plane.inverted()))
        XCTAssertNil(line.split(along: plane).front)
        XCTAssertEqual(line.split(along: plane).back, line) // TODO: does this inconsistency matter?
    }

    // MARK: Mesh Subtraction

    func testSubtractCube() {
        let line = LineSegment(unchecked: [0, -2, 0], [0, 2, 0])
        let mesh = Mesh.cube()
        XCTAssertEqual([line].subtracting(mesh), [
            LineSegment(undirected: [0, -2, 0], [0, -0.5, 0]),
            LineSegment(undirected: [0, 0.5, 0], [0, 2, 0]),
        ])
    }

    func testSubtractSphere() {
        let line = LineSegment(unchecked: [1, -2, 0], [1, 2, 0])
        let mesh = Mesh.sphere(radius: 2, slices: 16)
        XCTAssertEqual([line].subtracting(mesh), [
            LineSegment(unchecked: [1.0, -2.0, 0.0], [1.0, -1.8050564051708364, 0.0]),
            LineSegment(unchecked: [1.0, -1.8050564051708364, 0.0], [1.0, -1.7107811011632634, 0.0]),
            LineSegment(unchecked: [1.0, 1.1682733327569532, 0.0], [1.0, 1.8814138401433351, 0.0]),
            LineSegment(unchecked: [1.0, -1.7107811011632634, 0.0], [1.0, -1.6944185400181435, 0.0]),
            LineSegment(unchecked: [1.0, 1.8814138401433351, 0.0], [1.0, 2.0, 0.0]),
        ])
    }

    func testSubtractCoincidentEdge() {
        let line = LineSegment(unchecked: [-0.5, 0.5], [0.5, 0.5])
        let mesh = Mesh.fill(.square())
        XCTAssertEqual([line].subtracting(mesh), [])
        XCTAssertEqual([line.inverted()].subtracting(mesh), [])
    }
}
