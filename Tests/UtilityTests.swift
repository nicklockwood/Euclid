//
//  UtilityTests.swift
//  GeometryScriptTests
//
//  Created by Nick Lockwood on 07/11/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

class UtilityTests: XCTestCase {
    // MARK: collinearity

    func testRightAngleNotCollinear() {
        let a = Vector(0, 1)
        let b = Vector(0, 0)
        let c = Vector(1, 0)
        XCTAssertFalse(pointsAreCollinear(a, b, c))
    }

    func testVerticalPointsCollinear() {
        let a = Vector(0, 1)
        let b = Vector(0, 0)
        let c = Vector(0, -1)
        XCTAssert(pointsAreCollinear(a, b, c))
    }

    func testHorizontalPointsCollinear() {
        let a = Vector(1, 0)
        let b = Vector(0, 0)
        let c = Vector(-1, 0)
        XCTAssert(pointsAreCollinear(a, b, c))
    }

    func testOverlappingPointsCollinear() {
        let a = Vector(1, 0)
        let b = Vector(0, 0)
        let c = Vector(1, 0)
        XCTAssert(pointsAreCollinear(a, b, c))
    }

    // MARK: convexness

    func testConvexnessResultNotAffectedByTranslation() {
        let vectors = [
            Vector(-0.10606601717798211, 0, -0.10606601717798216),
            Vector(-0.0574025148547635, 0, -0.138581929876693),
            Vector(-0.15648794521398243, 0, -0.1188726123511085),
            Vector(-0.16970931752558446, 0, -0.09908543035921899),
            Vector(-0.16346853203274558, 0, -0.06771088298918408),
        ]
        XCTAssertTrue(pointsAreConvex(vectors))
        let normal = Vector.unitY
        let offset = Vector(0, 0, 3)
        let vertices = vectors.map { Vertex($0, normal).translated(by: offset) }
        XCTAssertTrue(verticesAreConvex(vertices))
    }

    func testCollinearPointsDontPreventConvexness() {
        let vectors = [
            Vector(0, 1),
            Vector(0, 0),
            Vector(0, -1),
            Vector(1, -1),
        ]
        XCTAssertTrue(pointsAreConvex(vectors))
    }

    // MARK: degeneracy

    func testDegenerateCollinearVertices() {
        let normal = Vector.unitZ
        let vertices = [
            Vertex(Vector(0, 1), normal),
            Vertex(Vector(0, 0), normal),
            Vertex(Vector(0, -2), normal),
        ]
        XCTAssertTrue(verticesAreDegenerate(vertices))
    }

    func testNonDegenerateCollinearVertices() {
        let normal = Vector.unitZ
        let vertices = [
            Vertex(Vector(0, 1), normal),
            Vertex(Vector(0, 0), normal),
            Vertex(Vector(0, -2), normal),
            Vertex(Vector(1.5, -1), normal),
        ]
        XCTAssertFalse(verticesAreDegenerate(vertices))
    }

    func testDegenerateVerticesWithZeroLengthEdge() {
        let normal = Vector.unitZ
        let vertices = [
            Vertex(Vector(0, 1), normal),
            Vertex(Vector(0, -1), normal),
            Vertex(Vector(0, -1), normal),
            Vertex(Vector(1.5, 0), normal),
        ]
        XCTAssertTrue(verticesAreDegenerate(vertices))
    }

    // MARK: path sanitization

    func testSanitizeInvalidClosedPath() {
        let points: [PathPoint] = [
            .point(0, 1),
            .point(0, 0),
            .point(0, -1),
            .point(0, 1),
        ]
        let result = sanitizePoints(points)
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result, [
            .point(0, 1),
            .point(0, 0),
            .point(0, 1),
        ])
        let result2 = sanitizePoints(result)
        XCTAssertEqual(result.count, result2.count)
    }

    func testRemoveZeroAreaCollinearPointRemoved() {
        let points: [PathPoint] = [
            .point(0.18, 0.245),
            .point(0.18, 0.255),
            .point(0.17, 0.255),
            .point(0.16, 0.247),
            .point(0.16, 0.244),
            .point(0.16, 0.245),
            .point(0.18, 0.245),
        ]
        let result = sanitizePoints(points)
        XCTAssertEqual(result.count, 6)
        XCTAssertEqual(result, [
            .point(0.18, 0.245),
            .point(0.18, 0.255),
            .point(0.17, 0.255),
            .point(0.16, 0.247),
            .point(0.16, 0.245),
            .point(0.18, 0.245),
        ])
    }

    func testSanitizeValidClosedPath() {
        var points: [PathPoint] = [
            .point(-0.0, 0.0025),
            .point(-0.002377641291, 0.000772542486),
            .point(-0.001469463131, -0.002022542486),
            .point(0.001469463131, -0.002022542486),
            .point(0.002377641291, 0.000772542486),
            .point(0.0, 0.0025),
        ]
        for _ in 0 ..< 5 {
            let result = sanitizePoints(points)
            XCTAssertEqual(result.count, points.count)
            XCTAssertEqual(result, points)
            points.scale(by: 0.5)
        }
    }

    func testSanitizeValidOpenPath() {
        let points: [PathPoint] = [
            .point(0, 0.5),
            .point(-0.5, 0.5),
            .point(-0.5, -0.5),
            .point(0, -0.5),
        ]
        let result = sanitizePoints(points)
        XCTAssertEqual(result.count, points.count)
        XCTAssertEqual(result, points)
    }

    // MARK: lines

    func testVectorFromPointToLine() {
        let result = vectorFromPointToLine(
            Vector(2, 0),
            Vector(-1, -1),
            Vector(1, 0)
        )
        XCTAssertEqual(result, -.unitY)
    }

    // MARK: faceNormalForPolygonPoints

    func testFaceNormalForZAxisLine() {
        let result = faceNormalForPolygonPoints(
            [.zero, .unitZ], convex: nil, closed: nil
        )
        XCTAssertEqual(result, .unitY)
    }

    func testFaceNormalForVerticalLine() {
        let result = faceNormalForPolygonPoints(
            [.zero, .unitY], convex: nil, closed: nil
        )
        XCTAssertEqual(result, .unitZ)
    }

    func testFaceNormalForHorizontalLine() {
        let result = faceNormalForPolygonPoints(
            [.zero, .unitX], convex: nil, closed: nil
        )
        XCTAssertEqual(result, .unitZ)
    }
}
