//
//  PlaneTests.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 19/12/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

class PlaneTests: XCTestCase {
    func testConcavePolygonClockwiseWinding() {
        var transform = Transform.identity
        var points = [Vector]()
        let sides = 5
        for _ in 0 ..< sides {
            points.append(Vector(0, -0.5).transformed(by: transform))
            transform.rotate(by: .roll(.pi / Double(sides)))
            points.append(Vector(0, -1).transformed(by: transform))
            transform.rotate(by: .roll(.pi / Double(sides)))
        }
        let plane = Plane(points: points)
        XCTAssertEqual(plane?.normal, Vector(0, 0, -1))
    }

    func testConcavePolygonPlaneTranslation() {
        let points0: [Vector] = [
            Vector(-0.707106781187, -0.707106781187, 0.5),
            Vector(0.353553390593, 0.353553390593, 0.5),
            Vector(0.353553390593, 0.353553390593, 0),
            Vector(0.707106781187, 0.707106781187, 0),
            Vector(0.707106781187, 0.707106781187, 1),
            Vector(-0.707106781187, -0.707106781187, 1),
        ]
        let plane0 = Plane(points: points0)
        let translation = Vector(1, 0)
        let points1 = points0.translated(by: translation)
        let plane1 = Plane(points: points1)
        let expected = plane0?.translated(by: translation)
        XCTAssertEqual(plane1, expected)
    }

    // MARK: FlatteningPlane

    func testFlatteningPlaneForUnitZ() {
        let normal = Vector(0, 0, 1)
        let plane = FlatteningPlane(normal: normal)
        XCTAssertEqual(plane, .xy)
    }

    func testFlatteningPlaneForNegativeUnitZ() {
        let normal = Vector(0, 0, -1)
        let plane = FlatteningPlane(normal: normal)
        XCTAssertEqual(plane, .xy)
    }

    func testFlatteningPlaneForUnitY() {
        let normal = Vector(0, 1, 0)
        let plane = FlatteningPlane(normal: normal)
        XCTAssertEqual(plane, .xz)
    }

    func testFlatteningPlaneForUnitX() {
        let normal = Vector(1, 0, 0)
        let plane = FlatteningPlane(normal: normal)
        XCTAssertEqual(plane, .yz)
    }

    func testFlatteningPlaneForXYDiagonal() {
        let normal = Vector(0.7071067811865475, -0.7071067811865475)
        let plane = FlatteningPlane(normal: normal)
        XCTAssertNotEqual(plane, .xy)
    }

    func testFlatteningPlaneForHorizontalLine() {
        let points = [Vector(-1, 0), Vector(1, 0)]
        let plane = FlatteningPlane(points: points, convex: nil)
        XCTAssertEqual(plane, .xy)
    }

    func testFlatteningPlaneForVerticalLine() {
        let points = [Vector(0, -1), Vector(0, 1)]
        let plane = FlatteningPlane(points: points, convex: nil)
        XCTAssertEqual(plane, .xy)
    }

    // MARK: Intersections

    func testIntersectionWithParallelPlane() {
        let plane1 = Plane(unchecked: Vector(0, 1, 0), pointOnPlane: Vector(0, 0, 0))
        let plane2 = Plane(unchecked: Vector(0, 1, 0), pointOnPlane: Vector(0, 1, 0))

        XCTAssertNil(plane1.intersection(with: plane2))
    }

    func testIntersectionWithPerpendicularPlane() {
        let plane1 = Plane(unchecked: Vector(0, 1, 0), pointOnPlane: Vector(0, 0, 0))
        let plane2 = Plane(unchecked: Vector(1, 0, 0), pointOnPlane: Vector(0, 0, 0))

        guard let intersection = plane1.intersection(with: plane2) else {
            XCTFail()
            return
        }

        XCTAssert(plane1.containsPoint(intersection.origin))
        XCTAssert(plane2.containsPoint(intersection.origin))

        XCTAssert(plane1.containsPoint(intersection.origin + intersection.direction))
        XCTAssert(plane2.containsPoint(intersection.origin + intersection.direction))
    }

    func testIntersectionWithRandomPlane() {
        let plane1 = Plane(normal: Vector(1.2, 0.4, 5.7), w: 6)!
        let plane2 = Plane(normal: Vector(0.5, 0.7, 0.1), w: 8)!

        guard let intersection = plane1.intersection(with: plane2) else {
            XCTFail()
            return
        }

        XCTAssert(abs(plane1.normal.dot(intersection.origin) - plane1.w) < epsilon)
        XCTAssert(abs(plane2.normal.dot(intersection.origin) - plane2.w) < epsilon)

        XCTAssert(plane1.containsPoint(intersection.origin))
        XCTAssert(plane2.containsPoint(intersection.origin))

        XCTAssert(plane1.containsPoint(intersection.origin + intersection.direction))
        XCTAssert(plane2.containsPoint(intersection.origin + intersection.direction))
    }

    func testIntersectWithParallelLine() {
        let line = Line(unchecked: Vector(0, 0, 0), direction: Vector(4, -5, 0).normalized())
        let plane = Plane(unchecked: Vector(0, 0, 1), pointOnPlane: Vector(-3, 2, 0))
        XCTAssertNil(plane.intersection(with: line))
    }

    func testIntersectWithNormalLine() {
        let line = Line(unchecked: Vector(1, 5, 60), direction: Vector(0, 0, 1))
        let plane = Plane(unchecked: Vector(0, 0, 1), pointOnPlane: Vector(-3, 2, 0))
        let expected = Vector(1, 5, 0)
        XCTAssertEqual(expected, plane.intersection(with: line))
    }

    func testIntersectionWithAxisLine() {
        let line = Line(unchecked: Vector(0, 0, 0), direction: Vector(4, 3, 0).normalized())
        let plane = Plane(unchecked: Vector(0, 1, 0), w: 3)
        let expected = Vector(4, 3, 0)
        XCTAssertEqual(expected, plane.intersection(with: line))
    }

    func testIntersectionWithSkewedLine() {
        let line = Line(unchecked: Vector(8, 8, 10), direction: Vector(1, 1, 1).normalized())
        let plane = Plane(unchecked: Vector(0, 0, 1), pointOnPlane: Vector(5, -7, 2))
        let expected = Vector(0, 0, 2)
        XCTAssertEqual(expected, plane.intersection(with: line))
    }
}
