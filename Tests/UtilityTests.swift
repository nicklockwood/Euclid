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
    // MARK: Clamped vectors

    func testClampedVector() {
        let point = Vector(-10, 0, 0).clamped(to: -.one ... .one)
        XCTAssertEqual(point, Vector(-1, 0, 0))
    }

    func testClampVector() {
        var point = Vector(-10, 0, 0)
        point.clamp(to: -.one ... .one)
        XCTAssertEqual(point, Vector(-1, 0, 0))
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

    func testSanitizeDuplicateCurvedPoint() {
        let points: [PathPoint] = [
            .curve(0, 0.5),
            .curve(-0.5, 0.5),
            .curve(-0.5, 0.5),
            .curve(-0.5, -0.5),
        ]
        let expected = Array(points[...1] + points[3...])
        let result = sanitizePoints(points)
        XCTAssertEqual(result.count, expected.count)
        XCTAssertEqual(result, expected)
    }

    func testSanitizeDuplicatePoint() {
        let points: [PathPoint] = [
            .point(0, 0.5),
            .point(-0.5, 0.5),
            .point(-0.5, 0.5),
            .point(-0.5, -0.5),
        ]
        let expected = Array(points[...1] + points[3...])
        let result = sanitizePoints(points)
        XCTAssertEqual(result.count, expected.count)
        XCTAssertEqual(result, expected)
    }

    func testSanitizeSharpCurvedDuplicatePoint() {
        let points: [PathPoint] = [
            .point(0, 0.5),
            .point(-0.5, 0.5),
            .curve(-0.5, 0.5),
            .point(-0.5, -0.5),
        ]
        let expected = Array(points[...1] + points[3...])
        let result = sanitizePoints(points)
        XCTAssertEqual(result.count, expected.count)
        XCTAssertEqual(result, expected)
    }

    func testSanitizeCurvedSharpDuplicatePoint() {
        let points: [PathPoint] = [
            .point(0, 0.5),
            .curve(-0.5, 0.5),
            .point(-0.5, 0.5),
            .point(-0.5, -0.5),
        ]
        let expected = Array(points[...0] + points[2...])
        let result = sanitizePoints(points)
        XCTAssertEqual(result.count, expected.count)
        XCTAssertEqual(result, expected)
    }

    func testSanitizeZeroLengthPath() {
        let points: [PathPoint] = [
            .point(0, 1),
            .point(0, 1),
        ]
        let expected = [PathPoint.point(0, 1)]
        let result = sanitizePoints(points)
        XCTAssertEqual(result.count, expected.count)
        XCTAssertEqual(result, expected)
    }

    // MARK: faceNormal

    func testFaceNormalForZAxisLine() {
        let result = faceNormalForPoints([.zero, .unitZ], convex: nil)
        XCTAssertEqual(result, .unitY)
    }

    func testFaceNormalForVerticalLine() {
        let result = faceNormalForPoints([.zero, .unitY], convex: nil)
        XCTAssertEqual(result, .unitZ)
    }

    func testFaceNormalForHorizontalLine() {
        let result = faceNormalForPoints([.zero, .unitX], convex: nil)
        XCTAssertEqual(result, .unitZ)
    }

    // MARK: rotation

    func testRotation() {
        let rotations = [
            Rotation(unchecked: .unitX, angle: .degrees(30)),
            Rotation(unchecked: -.unitX, angle: .degrees(30)),
            Rotation(unchecked: .unitY, angle: .degrees(10)),
            Rotation(unchecked: .unitY, angle: .degrees(17)),
            Rotation(unchecked: .unitY, angle: .degrees(135)),
            Rotation(axis: Vector(1, 0.5, 0), angle: .degrees(55))!,
        ]

        for r in rotations {
            let rotated = Vector.unitZ.rotated(by: r)
            let rotation = rotationBetweenNormalizedVectors(.unitZ, rotated)
            let (axis, angle) = (rotation.axis, rotation.angle)
            XCTAssert(rotation.isEqual(to: r), "\(rotation) is not equal to \(r)")
            XCTAssert(angle.isEqual(to: r.angle), "\(angle) is not equal to \(r.angle)")
            XCTAssert(axis.isEqual(to: r.axis), "\(axis) is not equal to \(r.axis)")
        }
    }

    func testRotationBetweenEqualAndOppositeVectors() {
        var testVectors = [
            Vector.unitX,
            Vector.unitY,
            Vector.unitZ,
        ]

        for _ in 0 ..< 10 {
            testVectors.append(.unitZ.rotated(by: .random()))
        }

        for v in testVectors {
            XCTAssertEqual(rotationBetweenNormalizedVectors(v, v), .identity)
            let r = rotationBetweenNormalizedVectors(v, -v)
            let rotated = v.rotated(by: r)
            XCTAssert(rotated.isEqual(to: -v), "\(rotated) is not equal to \(-v)")
        }
    }
}
