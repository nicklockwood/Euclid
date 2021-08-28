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
        let plane = Plane(points: points)!
        XCTAssertEqual(plane.normal, -.z)
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
        let plane = FlatteningPlane(normal: .z)
        XCTAssertEqual(plane, .xy)
    }

    func testFlatteningPlaneForNegativeUnitZ() {
        let plane = FlatteningPlane(normal: -.z)
        XCTAssertEqual(plane, .xy)
    }

    func testFlatteningPlaneForUnitY() {
        let plane = FlatteningPlane(normal: .y)
        XCTAssertEqual(plane, .xz)
    }

    func testFlatteningPlaneForUnitX() {
        let plane = FlatteningPlane(normal: .x)
        XCTAssertEqual(plane, .yz)
    }

    func testFlatteningPlaneForXYDiagonal() {
        let normal = Direction(x: 0.7071067811865475, y: -0.7071067811865475)
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
        let plane1 = Plane(unchecked: .y, pointOnPlane: Vector(0, 0, 0))
        let plane2 = Plane(unchecked: .y, pointOnPlane: Vector(0, 1, 0))

        XCTAssertNil(plane1.intersection(with: plane2))
    }
    
    func testIntersectionWithParallelPlaneInvertedNormal() {
        let plane1 = Plane(unchecked: .y, pointOnPlane: Vector(0, 0, 0))
        let plane2 = Plane(unchecked: -.y, pointOnPlane: Vector(0, 1, 0))

        XCTAssertNil(plane1.intersection(with: plane2))
    }

    func testIntersectionWithPerpendicularPlane() {
        let plane1 = Plane(unchecked: .y, pointOnPlane: Vector(0, 0, 0))
        let plane2 = Plane(unchecked: .x, pointOnPlane: Vector(0, 0, 0))

        guard let intersection = plane1.intersection(with: plane2) else {
            XCTFail()
            return
        }

        XCTAssert(plane1.containsPoint(intersection.origin))
        XCTAssert(plane2.containsPoint(intersection.origin))

        XCTAssert(plane1.containsPoint(intersection.origin + 1 * intersection.direction))
        XCTAssert(plane2.containsPoint(intersection.origin + 1 * intersection.direction))
    }

    func testIntersectionWithRandomPlane() {
        let plane1 = Plane(normal: Direction(1.2, 0.4, 5.7), w: 6)
        let plane2 = Plane(normal: Direction(0.5, 0.7, 0.1), w: 8)

        guard let intersection = plane1.intersection(with: plane2) else {
            XCTFail()
            return
        }

        XCTAssert(abs(intersection.origin.distance.dot(plane1.normal) - plane1.w) < epsilon)
        XCTAssert(abs(intersection.origin.distance.dot(plane2.normal) - plane2.w) < epsilon)

        XCTAssert(plane1.containsPoint(intersection.origin))
        XCTAssert(plane2.containsPoint(intersection.origin))

        XCTAssert(plane1.containsPoint(intersection.origin + 1 * intersection.direction))
        XCTAssert(plane2.containsPoint(intersection.origin + 1 * intersection.direction))
    }
    
    func testIntersectionWithRandomPlaneInvertedNormal() {
        let plane1 = Plane(normal: -Direction(1.2, 0.4, 5.7), w: 6)
        let plane2 = Plane(normal: Direction(0.5, 0.7, 0.1), w: 8)

        guard let intersection = plane1.intersection(with: plane2) else {
            XCTFail()
            return
        }

        XCTAssert(abs(intersection.origin.distance.dot(plane1.normal) - plane1.w) < epsilon)
        XCTAssert(abs(intersection.origin.distance.dot(plane2.normal) - plane2.w) < epsilon)

        XCTAssert(plane1.containsPoint(intersection.origin))
        XCTAssert(plane2.containsPoint(intersection.origin))

        XCTAssert(plane1.containsPoint(intersection.origin + 1 * intersection.direction))
        XCTAssert(plane2.containsPoint(intersection.origin + 1 * intersection.direction))
    }
    
    func testIntersectionWithRandomPlaneInvertedNormalAndDistance() {
        let plane1 = Plane(normal: -Direction(1.2, 0.4, 5.7), w: -6)
        let plane2 = Plane(normal: Direction(0.5, 0.7, 0.1), w: 8)

        guard let intersection = plane1.intersection(with: plane2) else {
            XCTFail()
            return
        }

        XCTAssert(abs(intersection.origin.distance.dot(plane1.normal) - plane1.w) < epsilon)
        XCTAssert(abs(intersection.origin.distance.dot(plane2.normal) - plane2.w) < epsilon)

        XCTAssert(plane1.containsPoint(intersection.origin))
        XCTAssert(plane2.containsPoint(intersection.origin))

        XCTAssert(plane1.containsPoint(intersection.origin + 1 * intersection.direction))
        XCTAssert(plane2.containsPoint(intersection.origin + 1 * intersection.direction))
    }

    func testIntersectWithParallelLine() {
        let line = Line(origin: .origin, direction: Direction(4, -5, 0))
        let plane = Plane(unchecked: .z, pointOnPlane: Vector(-3, 2, 0))
        XCTAssertNil(plane.intersection(with: line))
    }

    func testIntersectWithNormalLine() {
        let line = Line(origin: Position(1, 5, 60), direction: .z)
        let plane = Plane(unchecked: .z, pointOnPlane: Vector(-3, 2, 0))
        let expected = Vector(1, 5, 0)
        XCTAssertEqual(expected, plane.intersection(with: line))
    }

    func testIntersectionWithAxisLine() {
        let line = Line(origin: .origin, direction: Direction(4, 3, 0))
        let plane = Plane(normal: .y, w: 3)
        let expected = Vector(4, 3, 0)
        XCTAssertEqual(expected, plane.intersection(with: line))
    }

    func testIntersectionWithSkewedLine() {
        let line = Line(origin: Position(8, 8, 10), direction: Direction(1, 1, 1))
        let plane = Plane(unchecked: .z, pointOnPlane: Vector(5, -7, 2))
        let expected = Vector(0, 0, 2)
        XCTAssertEqual(expected, plane.intersection(with: line))
    }
}
