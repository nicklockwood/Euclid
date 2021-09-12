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
    // MARK: convexness

    func testConvexnessResultNotAffectedByTranslation() {
        let vectors = [
            Position(-0.10606601717798211, 0, -0.10606601717798216),
            Position(-0.0574025148547635, 0, -0.138581929876693),
            Position(-0.15648794521398243, 0, -0.1188726123511085),
            Position(-0.16970931752558446, 0, -0.09908543035921899),
            Position(-0.16346853203274558, 0, -0.06771088298918408),
        ]
        XCTAssertTrue(pointsAreConvex(vectors))
        let offset = Vector(0, 0, 3)
        let vertices = vectors.map { Vertex(Vector($0), .y).translated(by: offset) }
        XCTAssertTrue(verticesAreConvex(vertices))
    }

    func testColinearPointsDontPreventConvexness() {
        let vectors = [
            Position(0, 1),
            Position(0, 0),
            Position(0, -1),
            Position(1, -1),
        ]
        XCTAssertTrue(pointsAreConvex(vectors))
    }

    // MARK: degeneracy

    func testDegenerateColinearVertices() {
        let normal = Direction.z
        let vertices = [
            Vertex(Vector(0, 1), normal),
            Vertex(Vector(0, 0), normal),
            Vertex(Vector(0, -2), normal),
        ]
        XCTAssertTrue(verticesAreDegenerate(vertices))
    }

    func testNonDegenerateColinearVertices() {
        let normal = Direction.z
        let vertices = [
            Vertex(Vector(0, 1), normal),
            Vertex(Vector(0, 0), normal),
            Vertex(Vector(0, -2), normal),
            Vertex(Vector(1.5, -1), normal),
        ]
        XCTAssertFalse(verticesAreDegenerate(vertices))
    }

    func testDegenerateVerticesWithZeroLengthEdge() {
        let normal = Direction.z
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

    func testRemoveZeroAreaColinearPointRemoved() {
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

    // MARK: lines

    func testVectorFromPointToLine() {
        let result = distanceFromPointToLine(
            Position(2, 0, 0),
            Line(origin: Position(x: -1, y: -1, z: 0), direction: .x)
        )
        XCTAssertEqual(result, Distance(0, -1, 0))
    }

    // MARK: faceNormalForPolygonPoints

    func testFaceNormalForZAxisLine() {
        let result = faceNormalForPolygonPoints([.origin, Position(0, 0, 1)], convex: nil)
        XCTAssertEqual(result, .x)
    }

    func testFaceNormalForVerticalLine() {
        let result = faceNormalForPolygonPoints([.origin, Position(0, 1, 0)], convex: nil)
        XCTAssertEqual(result, .z)
    }

    func testFaceNormalForHorizontalLine() {
        let result = faceNormalForPolygonPoints([.origin, Position(1, 0, 0)], convex: nil)
        XCTAssertEqual(result, .z)
    }
}
