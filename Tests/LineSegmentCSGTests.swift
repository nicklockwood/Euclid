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
        XCTAssertEqual(front!.end, intersection, accuracy: epsilon)
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

    func testSubtractSphere() {
        let line = LineSegment(unchecked: [1, -2, 0], [1, 2, 0])
        let mesh = Mesh.sphere(radius: 2, slices: 16)
        XCTAssertEqual([line].subtracting(mesh), [
            LineSegment(unchecked: [1.0, 1.6909822162873716, 0.0], [1.0, 1.690982216287372, 0.0]),
            LineSegment(unchecked: [1.0, -2.0, 0.0], [1.0, -1.8010876326208531, 0.0]),
            LineSegment(unchecked: [1.0, 1.9604338701032105, 0.0], [1.0, 2.0, 0.0]),
            LineSegment(unchecked: [1.0, -1.6909822162873718, 0.0], [1.0, -1.6909822162873716, 0.0]),
            LineSegment(unchecked: [1.0, 1.690982216287372, 0.0], [1.0, 1.7927063568556971, 0.0]),
            LineSegment(unchecked: [1.0, -1.8010876326208531, 0.0], [1.0, -1.6909822162873718, 0.0]),
            LineSegment(unchecked: [1.0, 1.7927063568556971, 0.0], [1.0, 1.9604338701032105, 0.0]),
        ])
    }

    func testSubtractAdjoiningSegmentsToSphere() {
        let lines = [
            LineSegment(unchecked: [0, 0.5, 0], [0.4, 0, 0.4]),
            LineSegment(unchecked: [0.4, 0, 0.4], [0, 0, 0.5]),
        ]
        let mesh = Mesh.sphere()
        XCTAssertEqual(lines.subtracting(mesh), [
            LineSegment(
                unchecked: [0.0, 0.5, 0.0],
                [3.805313876944449e-17, 0.49999999999999994, 3.805313876944449e-17]
            ),
            LineSegment(
                unchecked: [0.34364538374122655, 0.07044327032346687, 0.34364538374122655],
                [0.34364538374122666, 0.0704432703234667, 0.34364538374122666]
            ),
            LineSegment(unchecked: [0.34364538374122666, 0.0704432703234667, 0.34364538374122666], [0.4, 0.0, 0.4]),
            LineSegment(unchecked: [0.4, 0.0, 0.4], [0.21471736097962765, 0.0, 0.4463206597550931]),
        ])
    }

    func testSubtractCoincidentEdge() {
        let line = LineSegment(unchecked: [-0.5, 0.5], [0.5, 0.5])
        let mesh = Mesh.fill(.square())
        XCTAssertEqual([line].subtracting(mesh), [])
        XCTAssertEqual([line.inverted()].subtracting(mesh), [])
    }
}
