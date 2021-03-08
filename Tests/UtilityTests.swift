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
            Vector(-0.10606601717798211, 0, -0.10606601717798216),
            Vector(-0.0574025148547635, 0, -0.138581929876693),
            Vector(-0.15648794521398243, 0, -0.1188726123511085),
            Vector(-0.16970931752558446, 0, -0.09908543035921899),
            Vector(-0.16346853203274558, 0, -0.06771088298918408),
        ]
        XCTAssertTrue(pointsAreConvex(vectors))
        let normal = Vector(0, 1, 0)
        let offset = Vector(0, 0, 3)
        let vertices = vectors.map { Vertex($0, normal).translated(by: offset) }
        XCTAssertTrue(verticesAreConvex(vertices))
    }

    func testColinearPointsDontPreventConvexness() {
        let vectors = [
            Vector(0, 1),
            Vector(0, 0),
            Vector(0, -1),
            Vector(1, -1),
        ]
        XCTAssertTrue(pointsAreConvex(vectors))
    }

    // MARK: degeneracy

    func testDegenerateColinearVertices() {
        let normal = Vector(0, 0, 1)
        let vertices = [
            Vertex(Vector(0, 1), normal),
            Vertex(Vector(0, 0), normal),
            Vertex(Vector(0, -2), normal),
        ]
        XCTAssertTrue(verticesAreDegenerate(vertices))
    }

    func testNonDegenerateColinearVertices() {
        let normal = Vector(0, 0, 1)
        let vertices = [
            Vertex(Vector(0, 1), normal),
            Vertex(Vector(0, 0), normal),
            Vertex(Vector(0, -2), normal),
            Vertex(Vector(1.5, -1), normal),
        ]
        XCTAssertFalse(verticesAreDegenerate(vertices))
    }

    func testDegenerateVerticesWithZeroLengthEdge() {
        let normal = Vector(0, 0, 1)
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

    // MARK: directions

    func testParallelDirections() {
        let direction1 = Vector(-1, 1, 3).normalized()
        let direction2 = Vector(-1, 1, 3).normalized()
        XCTAssertTrue(directionsAreParallel(direction1, direction2))
        XCTAssertFalse(directionsAreAntiparallel(direction1, direction2))
        XCTAssertTrue(directionsAreColinear(direction1, direction2))
        XCTAssertFalse(directionsAreNormal(direction1, direction2))
    }

    func testAntiparallelDirections() {
        let direction1 = Vector(-1, 2, 3).normalized()
        let direction2 = Vector(1, -2, -3).normalized()
        XCTAssertFalse(directionsAreParallel(direction1, direction2))
        XCTAssertTrue(directionsAreAntiparallel(direction1, direction2))
        XCTAssertTrue(directionsAreColinear(direction1, direction2))
        XCTAssertFalse(directionsAreNormal(direction1, direction2))
    }

    func testNormalDirections() {
        let direction1 = Vector(1, 0, 0).normalized()
        let direction2 = Vector(0, 1, 0).normalized()
        XCTAssertFalse(directionsAreParallel(direction1, direction2))
        XCTAssertFalse(directionsAreAntiparallel(direction1, direction2))
        XCTAssertFalse(directionsAreColinear(direction1, direction2))
        XCTAssertTrue(directionsAreNormal(direction1, direction2))
    }

    func testGeneralDirections() {
        let direction1 = Vector(-1, 2, 3).normalized()
        let direction2 = Vector(5, -9, 1).normalized()
        XCTAssertFalse(directionsAreParallel(direction1, direction2))
        XCTAssertFalse(directionsAreAntiparallel(direction1, direction2))
        XCTAssertFalse(directionsAreColinear(direction1, direction2))
        XCTAssertFalse(directionsAreNormal(direction1, direction2))
    }
}
