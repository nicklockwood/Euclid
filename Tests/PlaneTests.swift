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
        XCTAssertEqual(plane?.normal, -.unitZ)
    }

    func testConcavePolygonPlaneTranslation() {
        let points0: [Vector] = [
            [-0.707106781187, -0.707106781187, 0.5],
            [0.353553390593, 0.353553390593, 0.5],
            [0.353553390593, 0.353553390593, 0],
            [0.707106781187, 0.707106781187, 0],
            [0.707106781187, 0.707106781187, 1],
            [-0.707106781187, -0.707106781187, 1],
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
        let plane = FlatteningPlane(normal: .unitZ)
        XCTAssertEqual(plane, .xy)
    }

    func testFlatteningPlaneForNegativeUnitZ() {
        let plane = FlatteningPlane(normal: -.unitZ)
        XCTAssertEqual(plane, .xy)
    }

    func testFlatteningPlaneForUnitY() {
        let plane = FlatteningPlane(normal: .unitY)
        XCTAssertEqual(plane, .xz)
    }

    func testFlatteningPlaneForUnitX() {
        let plane = FlatteningPlane(normal: .unitX)
        XCTAssertEqual(plane, .yz)
    }

    func testFlatteningPlaneForXYDiagonal() {
        let plane = FlatteningPlane(normal: [0.7071067811865475, -0.7071067811865475])
        XCTAssertNotEqual(plane, .xy)
    }

    func testFlatteningPlaneForHorizontalLine() {
        let plane = FlatteningPlane(points: [[-1, 0], [1, 0]])
        XCTAssertEqual(plane, .xy)
    }

    func testFlatteningPlaneForVerticalLine() {
        let plane = FlatteningPlane(points: [[0, -1], [0, 1]])
        XCTAssertEqual(plane, .xy)
    }

    // MARK: Intersections

    func testIntersectionWithParallelPlane() {
        let plane1 = Plane(unchecked: .unitY, pointOnPlane: .zero)
        let plane2 = Plane(unchecked: .unitY, pointOnPlane: .unitY)

        XCTAssertNil(plane1.intersection(with: plane2))
    }

    func testIntersectionWithPerpendicularPlane() {
        let plane1 = Plane(unchecked: .unitZ, w: 1)
        let plane2 = Plane(unchecked: -.unitX, w: 1)

        guard let intersection = plane1.intersection(with: plane2) else {
            XCTFail()
            return
        }

        XCTAssertEqual(intersection, Line(origin: [-1, 0, 1], direction: -.unitY))
    }

    func testIntersectionWithPerpendicularPlane2() {
        let plane1 = Plane(unchecked: -.unitX, w: 1)
        let plane2 = Plane(unchecked: .unitZ, w: 1)

        guard let intersection = plane1.intersection(with: plane2) else {
            XCTFail()
            return
        }

        XCTAssertEqual(intersection, Line(origin: [-1, 0, 1], direction: .unitY))
    }

    func testIntersectionWithPerpendicularPlane3() {
        let plane1 = Plane(unchecked: .unitX, w: 1)
        let plane2 = Plane(unchecked: -.unitY, w: 1)

        guard let intersection = plane1.intersection(with: plane2) else {
            XCTFail()
            return
        }

        XCTAssertEqual(intersection, Line(origin: [1, -1, 0], direction: -.unitZ))
    }

    func testIntersectionWithRandomPlane() {
        let plane1 = Plane(normal: [1.2, 0.4, 5.7], w: 6)!
        let plane2 = Plane(normal: [0.5, 0.7, 0.1], w: 8)!

        guard let intersection = plane1.intersection(with: plane2) else {
            XCTFail()
            return
        }

        XCTAssert(abs(plane1.normal.dot(intersection.origin) - plane1.w) < epsilon)
        XCTAssert(abs(plane2.normal.dot(intersection.origin) - plane2.w) < epsilon)

        XCTAssert(plane1.intersects(intersection.origin))
        XCTAssert(plane2.intersects(intersection.origin))

        XCTAssert(plane1.intersects(intersection.origin + intersection.direction))
        XCTAssert(plane2.intersects(intersection.origin + intersection.direction))
    }

    func testIntersectWithParallelLine() {
        let line = Line(unchecked: .zero, direction: Vector(4, -5, 0).normalized())
        let plane = Plane(unchecked: .unitZ, pointOnPlane: [-3, 2, 0])
        XCTAssertNil(plane.intersection(with: line))
    }

    func testIntersectWithNormalLine() {
        let line = Line(unchecked: [1, 5, 60], direction: .unitZ)
        let plane = Plane(unchecked: .unitZ, pointOnPlane: [-3, 2, 0])
        let expected = Vector(1, 5, 0)
        XCTAssertEqual(expected, plane.intersection(with: line))
    }

    func testIntersectWithInverseNormalLine() {
        let line = Line(unchecked: [1, 5, 60], direction: -.unitZ)
        let plane = Plane(unchecked: .unitZ, pointOnPlane: [-3, 2, 0])
        let expected = Vector(1, 5, 0)
        XCTAssertEqual(expected, plane.intersection(with: line))
    }

    func testIntersectionWithAxisLine() {
        let line = Line(unchecked: .zero, direction: Vector(4, 3, 0).normalized())
        let plane = Plane(unchecked: .unitY, w: 3)
        let expected = Vector(4, 3, 0)
        XCTAssertEqual(expected, plane.intersection(with: line))
    }

    func testIntersectionWithSkewedLine() {
        let line = Line(unchecked: [8, 8, 10], direction: Vector(1, 1, 1).normalized())
        let plane = Plane(unchecked: .unitZ, pointOnPlane: [5, -7, 2])
        let expected = Vector(0, 0, 2)
        XCTAssertEqual(expected, plane.intersection(with: line))
    }

    func testIntersectionWithAxisLineSegment() {
        let segment = LineSegment(unchecked: [0, 0, 1], [0, 0, 3])
        let plane = Plane(unchecked: .unitZ, w: 2)
        let expected = Vector(0, 0, 2)
        XCTAssertEqual(expected, plane.intersection(with: segment))
    }

    func testNonIntersectionWithAxisLineSegment() {
        let segment = LineSegment(unchecked: [0, 0, 1], [0, 0, 3])
        let plane = Plane(unchecked: .unitZ, w: 0)
        XCTAssertNil(plane.intersection(with: segment))
    }

    func testNonIntersectionWithAxisLineSegment2() {
        let segment = LineSegment(unchecked: [0, 0, 1], [0, 0, 3])
        let plane = Plane(unchecked: .unitZ, w: 4)
        XCTAssertNil(plane.intersection(with: segment))
    }

    // MARK: PlaneComparable

    func testCompareIdenticalPlanes() {
        let plane = Plane(unchecked: .unitZ, w: 0)
        XCTAssertEqual(plane.compare(with: plane), .coplanar)
    }

    func testCompareOppositePlanes() {
        let plane1 = Plane(unchecked: .unitZ, w: 1)
        let plane2 = plane1.inverted()
        XCTAssertEqual(plane1.compare(with: plane2), .coplanar)
    }

    func testDistanceBetweenIdenticalPlanes() {
        for i in 0 ..< 10 {
            let plane = Plane(unchecked: .unitZ, w: Double(i)).rotated(by: .yaw(.twoPi * (Double(i) / 10)))
            XCTAssertEqual(plane.signedDistance(from: plane), 0)
        }
    }

    func testDistanceBetweenInversePlanes() {
        for i in 0 ..< 10 {
            let plane = Plane(unchecked: .unitZ, w: Double(i)).rotated(by: .yaw(.twoPi * (Double(i) / 10)))
            XCTAssertEqual(plane.signedDistance(from: plane.inverted()), 0)
        }
    }

    func testDistanceBetweenPlanes() {
        let plane1 = Plane(unchecked: .unitZ, w: 1)
        let plane2 = Plane(unchecked: .unitZ, w: -1)
        XCTAssertEqual(plane1.signedDistance(from: plane2), 2)
        XCTAssertEqual(plane2.signedDistance(from: plane1), -2)
        XCTAssertEqual(plane1.signedDistance(from: plane2.inverted()), -2)
        XCTAssertEqual(plane2.signedDistance(from: plane1.inverted()), 2)
    }

    func testDeprecatedPointPlaneDistance() {
        let point = Vector(-10, 0, 0)
        let plane = Plane(unchecked: .unitX, w: 0)
        // This should be -10 when it's calling the deprecated method
        // When the deprecated method is removed it will return 10 instead
        XCTAssertEqual(point.distance(from: plane), -10)
    }
}
