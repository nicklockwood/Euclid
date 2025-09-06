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
        XCTAssertEqual(point, [-1, 0, 0])
    }

    func testClampVector() {
        var point = Vector(-10, 0, 0)
        point.clamp(to: -.one ... .one)
        XCTAssertEqual(point, [-1, 0, 0])
    }

    // MARK: convexness

    func testConvexnessResultNotAffectedByTranslation() {
        let vectors: [Vector] = [
            [-0.10606601717798211, 0, -0.10606601717798216],
            [-0.0574025148547635, 0, -0.138581929876693],
            [-0.15648794521398243, 0, -0.1188726123511085],
            [-0.16970931752558446, 0, -0.09908543035921899],
            [-0.16346853203274558, 0, -0.06771088298918408],
        ]
        XCTAssertTrue(pointsAreConvex(vectors))
        let vertices = vectors.map { Vertex($0, .unitY).translated(by: [0, 0, 3]) }
        XCTAssertTrue(verticesAreConvex(vertices))
    }

    func testCollinearPointsDontPreventConvexness() {
        let vectors: [Vector] = [
            [0, 1],
            [0, 0],
            [0, -1],
            [1, -1],
        ]
        XCTAssertTrue(pointsAreConvex(vectors))
    }

    // MARK: degeneracy

    func testDegenerateCollinearVertices() {
        let normal = Vector.unitZ
        let vertices = [
            Vertex(0, 1, normal: normal),
            Vertex(0, 0, normal: normal),
            Vertex(0, -2, normal: normal),
        ]
        XCTAssertTrue(verticesAreDegenerate(vertices))
    }

    func testNonDegenerateCollinearVertices() {
        let normal = Vector.unitZ
        let vertices = [
            Vertex(0, 1, normal: normal),
            Vertex(0, 0, normal: normal),
            Vertex(0, -2, normal: normal),
            Vertex(1.5, -1, normal: normal),
        ]
        XCTAssertFalse(verticesAreDegenerate(vertices))
    }

    func testDegenerateVerticesWithZeroLengthEdge() {
        let normal = Vector.unitZ
        let vertices = [
            Vertex(0, 1, normal: normal),
            Vertex(0, -1, normal: normal),
            Vertex(0, -1, normal: normal),
            Vertex(1.5, 0, normal: normal),
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

    // MARK: vectorArea

    func testAreaOfClockwiseSquare() {
        let points: [Vector] = [
            [0, 0],
            [0, 1],
            [1, 1],
            [1, 0],
        ]
        XCTAssertEqual(points.vectorArea, -.unitZ)
    }

    func testAreaOfAnticlockwiseSquare() {
        let points: [Vector] = [
            [0, 0],
            [0, -1],
            [1, -1],
            [1, 0],
        ]
        XCTAssertEqual(points.vectorArea, .unitZ)
    }

    func testAreaOfClockwiseTriangle() {
        let points: [Vector] = [
            [0, 0],
            [0, 1],
            [1, 0],
        ]
        XCTAssertEqual(points.vectorArea, [0, 0, -0.5])
    }

    func testAreaOfAnticlockwiseTriangle() {
        let points: [Vector] = [
            [0, 0],
            [0, -1],
            [1, 0],
        ]
        XCTAssertEqual(points.vectorArea, [0, 0, 0.5])
    }

    func testAreaOfAnticlockwiseTrapezium() {
        let points: [Vector] = [
            [0, 0],
            [-1, -1],
            [2, -1],
            [1, 0],
        ]
        XCTAssertEqual(points.vectorArea, [0, 0, 2])
    }

    func testAreaOfLShapedClockwisePolygon() {
        let points: [Vector] = [
            [0, 0],
            [0, 2],
            [1, 2],
            [1, 1],
            [2, 1],
            [2, 0],
        ]
        XCTAssertEqual(points.vectorArea, [0, 0, -3])
    }

    func testAreaOfTransformedLShapedClockwisePolygon() {
        for _ in 0 ..< 10 {
            let points: [Vector] = [
                [0, 0],
                [0, 2],
                [1, 2],
                [1, 1],
                [2, 1],
                [2, 0],
            ].transformed(by: .random())
            XCTAssertEqual(points.vectorArea.length, 3)
        }
    }

    func testAreaOfRotatedAnticlockwiseSquare() {
        for _ in 0 ..< 10 {
            let points: [Vector] = [
                [0, 0],
                [0, -1],
                [1, -1],
                [1, 0],
            ].rotated(by: .random())
            XCTAssertEqual(points.vectorArea.length, 1)
        }
    }

    func testAreaOfFlatClockwiseSquareNotAtOrigin() {
        let points: [Vector] = [
            [0, 0, 1],
            [0, 1, 1],
            [1, 1, 1],
            [1, 0, 1],
        ]
        XCTAssertEqual(points.vectorArea, -.unitZ)
    }

    func testAreaOfRotatedAnticlockwiseSquareNotAtOrigin() {
        for _ in 0 ..< 10 {
            let points: [Vector] = [
                [0, 0, 1],
                [0, -1, 1],
                [1, -1, 1],
                [1, 0, 1],
            ].transformed(by: .random())
            XCTAssertEqual(points.vectorArea.length, 1)
        }
    }

    func testNearCollinearPoints() {
        let points = [
            Vector(1.08491958885, 1.0304781148239999, 1.998713339563),
            Vector(1.08018965849, 1.030469437032, 1.998785005174),
            Vector(1.07600466518, 1.030461759012, 1.998848414164),
        ]
        let (area, normal) = points.vectorArea.lengthAndDirection
        let ca = points[0] - points[2]
        let ab = points[1] - points[0]
        let bc = points[2] - points[1]
        let n0 = ca.cross(ab).normalized()
        let n1 = ab.cross(bc).normalized()
        let n2 = bc.cross(ca).normalized()
        XCTAssertEqual(n0, n1)
        XCTAssertEqual(n0, n2)
        XCTAssertEqual(n0, normal)
        let ac = points[2] - points[0]
        let n3 = ab.cross(ac) / 2
        XCTAssertEqual(n0, n3.normalized())
        XCTAssertEqual(n3.length, area)
        XCTAssertEqual(normal, faceNormalForPoints(points))
    }

    func testAreaEdgeCase() {
        let points = [
            Vector(1.1131483498699999, 1.036774574811, 1.998285631061),
            Vector(1.113483743323, 1.035669689018, 1.9982805493459999),
            Vector(1.1133381034779999, 1.036258030631, 1.9982827560079999),
        ]
        let (area, normal) = points.vectorArea.lengthAndDirection
        let ca = points[0] - points[2]
        let ab = points[1] - points[0]
        let bc = points[2] - points[1]
        let n0 = ca.cross(ab).normalized()
        let n1 = ab.cross(bc).normalized()
        let n2 = bc.cross(ca).normalized()
        XCTAssertEqual(n0, n1)
        XCTAssertEqual(n0, n2)
        XCTAssertEqual(n0, normal)
        let ac = points[2] - points[0]
        let n3 = ab.cross(ac) / 2
        XCTAssertEqual(n0, n3.normalized())
        XCTAssertEqual(n3.length, area)
    }

    // MARK: faceNormal

    func testFaceNormalForZAxisLine() {
        let result = faceNormalForPoints([.zero, .unitZ])
        XCTAssertEqual(result, .unitY)
    }

    func testFaceNormalForZAxisZeroAreaPolygon() {
        let result = faceNormalForPoints([.zero, .unitZ, .unitZ / 2])
        XCTAssertEqual(result, .unitY)
    }

    func testFaceNormalForLShapedZeroAreaPolygon() {
        let result = faceNormalForPoints([.zero, .unitZ, .unitX, .unitZ])
        XCTAssertEqual(result, .unitY)
    }

    func testFaceNormalForVerticalLine() {
        let result = faceNormalForPoints([.zero, .unitY])
        XCTAssertEqual(result, .unitZ)
    }

    func testFaceNormalForVerticalZeroAreaPolygon() {
        let result = faceNormalForPoints([.zero, .unitY, .unitY / 2])
        XCTAssertEqual(result, .unitZ)
    }

    func testFaceNormalForHorizontalLine() {
        let result = faceNormalForPoints([.zero, .unitX])
        XCTAssertEqual(result, .unitZ)
    }

    func testFaceNormalForHorizontalZeroAreaPolygon() {
        let result = faceNormalForPoints([.zero, .unitX, .unitX / 2])
        XCTAssertEqual(result, .unitZ)
    }

    func testFaceNormalForPathMatchesPolygon() throws {
        for _ in 0 ..< 10 {
            let path = Path.square().transformed(by: .random())
            let poly = try XCTUnwrap(Polygon(shape: path))
            let a = faceNormalForPoints(path.points.map(\.position))
            let b = faceNormalForPoints(poly.vertices.map(\.position))
            XCTAssertEqual(a, b)
        }
    }

    func testFaceNormalForNearlyColinearPoints() {
        let points = [
            Vector(1.08491958885, 1.0304781148239999, 1.998713339563),
            Vector(1.08018965849, 1.030469437032, 1.998785005174),
            Vector(1.07600466518, 1.030461759012, 1.998848414164),
        ]
        let result = faceNormalForPoints(points)
        let ab = points[1] - points[0]
        let bc = points[2] - points[1]
        let ca = points[0] - points[2]
        let n0 = ab.cross(bc).normalized()
        let n1 = bc.cross(ca).normalized()
        let n2 = ca.cross(ab).normalized()
        XCTAssertEqual(n0, n1)
        XCTAssertEqual(n1, n2)
        XCTAssertEqual(result, n1)
        XCTAssertEqual(result, points.vectorArea.normalized())
    }

    func testFaceNormalForNearlyColinearPoints2() {
        let points = [
            Vector(1.1131483498699999, 1.036774574811, 1.998285631061),
            Vector(1.113483743323, 1.035669689018, 1.9982805493459999),
            Vector(1.1133381034779999, 1.036258030631, 1.9982827560079999),
        ]
        let result = faceNormalForPoints(points)
        XCTAssertEqual(result, points.vectorArea.normalized())
    }

    // MARK: rotation

    func testRotation() {
        let rotations = [
            Rotation(unchecked: .unitX, angle: .degrees(30)),
            Rotation(unchecked: -.unitX, angle: .degrees(30)),
            Rotation(unchecked: .unitY, angle: .degrees(10)),
            Rotation(unchecked: .unitY, angle: .degrees(17)),
            Rotation(unchecked: .unitY, angle: .degrees(135)),
            Rotation(axis: [1, 0.5, 0], angle: .degrees(55))!,
        ]

        for r in rotations {
            let rotated = Vector.unitZ.rotated(by: r)
            let rotation = rotationBetweenNormalizedVectors(.unitZ, rotated)
            let (axis, angle) = (rotation.axis, rotation.angle)
            XCTAssertEqual(rotation, r)
            XCTAssertEqual(angle, r.angle)
            XCTAssertEqual(axis, r.axis)
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
            XCTAssertEqual(rotated, -v)
        }
    }
}
