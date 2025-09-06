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
    // MARK: Plane Splitting

    func testSplitAlongPlaneConsistentWithIntersection() {
        let line = LineSegment(unchecked: [0.40685660304473714, 0.3725735878210516, 0.0], [0.5, 0, 0])
        let plane = Plane(
            unchecked: [0.7670920387775096, 0.5573249890665806, -0.31773992604974827],
            w: 0.4508853875443005
        )
        let (front, back) = line.split(along: plane)
        let intersection = line.intersection(with: plane)!
        XCTAssertEqual(front?.end, back?.start)
        XCTAssertEqual(front?.end, intersection)
    }

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

    // MARK: Mesh Clipping

    func testClipToCube() {
        let line = LineSegment(unchecked: [0, -2, 0], [0, 2, 0])
        let mesh = Mesh.cube()
        XCTAssertEqual(line.clipped(to: mesh), [
            LineSegment(start: [0, -2, 0], end: [0, -0.5, 0]),
            LineSegment(start: [0, 0.5, 0], end: [0, 2, 0]),
        ])
    }

    func testClipToSphere() {
        let line = LineSegment(unchecked: [1, -2, 0], [1, 2, 0])
        let mesh = Mesh.sphere(radius: 2, slices: 16)
        #if !arch(wasm32)
        XCTAssertEqual(line.clipped(to: mesh), [
            LineSegment(unchecked: [1.0, -2.0, 0], [1.0, -1.6909822162873713, 0]),
            LineSegment(unchecked: [1.0, 1.6909822162873713, 0], [1.0, 2.0, 0]),
        ])
        #endif
    }

    func testClipAdjoiningSegmentsToSphere() {
        let lines = [
            LineSegment(unchecked: [0, 0.5, 0], [0.4, 0, 0.4]),
            LineSegment(unchecked: [0.4, 0, 0.4], [0, 0, 0.5]),
        ]
        let mesh = Mesh.sphere()
        #if !arch(wasm32)
        XCTAssertEqual(lines.clipped(to: mesh), [
            LineSegment(unchecked: [0.4, 0.0, 0.4], [0.30698031713380675, 0.0, 0.42325492071654836]),
            LineSegment(unchecked: [0.3436453837412266, 0.07044327032346681, 0.3436453837412266], [0.4, 0.0, 0.4]),
            LineSegment(
                unchecked: [0.30698031713380675, 0.0, 0.42325492071654836],
                [0.3069803171338066, 0.0, 0.4232549207165484]
            ),
            LineSegment(
                unchecked: [0.3069803171338066, 0.0, 0.4232549207165484],
                [0.21471736097962746, 0.0, 0.44632065975509316]
            ),
        ])
        #endif
    }

    func testClipCoincidentEdge() {
        let line = LineSegment(unchecked: [-0.5, 0.5], [0.5, 0.5])
        let mesh = Mesh.fill(.square())
        XCTAssertEqual(line.clipped(to: mesh), [])
        XCTAssertEqual(line.inverted().clipped(to: mesh), [])
    }

    func testClipAlongTopOfSquare() {
        let line = LineSegment(unchecked: [-2, 0.5], [2, 0.5])
        let mesh = Mesh.fill(.square())
        #if !arch(wasm32)
        XCTAssertEqual(line.clipped(to: mesh), [
            LineSegment(unchecked: [-2.0, 0.5, 0.0], [-0.5, 0.5, 0.0]),
            LineSegment(unchecked: [0.5, 0.5, 0.0], [2.0, 0.5, 0.0]),
        ])
        #endif
    }

    func testClipAlongBottomOfSquare() {
        let line = LineSegment(unchecked: [-2, -0.5], [2, -0.5])
        let mesh = Mesh.fill(.square())
        #if !arch(wasm32)
        XCTAssertEqual(line.clipped(to: mesh), [
            LineSegment(unchecked: [-2.0, -0.5, 0.0], [-0.5, -0.5, 0.0]),
            LineSegment(unchecked: [0.5, -0.5, 0.0], [2.0, -0.5, 0.0]),
        ])
        #endif
    }

    func testClipAlongLeftOfSquare() {
        let line = LineSegment(unchecked: [-0.5, 2], [-0.5, -2])
        let mesh = Mesh.fill(.square())
        XCTAssertEqual(line.clipped(to: mesh), [
            LineSegment(unchecked: [-0.5, 2.0, 0.0], [-0.5, 0.5, 0.0]),
            LineSegment(unchecked: [-0.5, -0.5, 0.0], [-0.5, -2.0, 0.0]),
        ])
    }

    func testClipAlongRightOfSquare() {
        let line = LineSegment(unchecked: [0.5, 2], [0.5, -2])
        let mesh = Mesh.fill(.square())
        XCTAssertEqual(line.clipped(to: mesh), [
            LineSegment(unchecked: [0.5, 2.0, 0.0], [0.5, 0.5, 0.0]),
            LineSegment(unchecked: [0.5, -0.5, 0.0], [0.5, -2.0, 0.0]),
        ])
    }

    func testClipAlongSeamBetweenSquares() {
        let line = LineSegment(unchecked: [-2, -0.5], [2, -0.5])
        let mesh = Mesh.fill(.square()).merge(Mesh.fill(.square().translated(by: [0, 1])))
        XCTAssertEqual(line.clipped(to: mesh), [
            LineSegment(unchecked: [-2.0, -0.5, 0.0], [-0.5, -0.5, 0.0]),
            LineSegment(unchecked: [0.5, -0.5, 0.0], [2.0, -0.5, 0.0]),
        ])
    }
}
