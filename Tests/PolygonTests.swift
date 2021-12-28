//
//  PolygonTests.swift
//  GeometryScriptTests
//
//  Created by Nick Lockwood on 19/09/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

extension Euclid.Polygon {
    // Convenience constructor for testing
    init(unchecked vertices: [Vertex], plane: Plane? = nil) {
        self.init(
            unchecked: vertices,
            plane: plane,
            isConvex: nil,
            material: nil
        )
    }
}

class PolygonTests: XCTestCase {
    // MARK: initialization

    func testConvexPolygonAnticlockwiseWinding() {
        let normal = Direction.z
        guard let polygon = Polygon([
            Vertex(Position(-1, 1), normal),
            Vertex(Position(-1, -1), normal),
            Vertex(Position(1, -1), normal),
            Vertex(Position(1, 1), normal),
        ]) else {
            XCTFail()
            return
        }
        XCTAssertEqual(polygon.plane.normal, normal)
    }

    func testConvexPolygonClockwiseWinding() {
        let normal = -Direction.z
        guard let polygon = Polygon([
            Vertex(Position(-1, -1), normal),
            Vertex(Position(-1, 1), normal),
            Vertex(Position(1, 1), normal),
            Vertex(Position(1, -1), normal),
        ]) else {
            XCTFail()
            return
        }
        XCTAssertEqual(polygon.plane.normal, normal)
    }

    func testConcavePolygonAnticlockwiseWinding() {
        let normal = Direction.z
        guard let polygon = Polygon([
            Vertex(Position(-1, 0), normal),
            Vertex(Position(0, 0), normal),
            Vertex(Position(0, -1), normal),
            Vertex(Position(1, -1), normal),
            Vertex(Position(1, 1), normal),
            Vertex(Position(-1, 1), normal),
        ]) else {
            XCTFail()
            return
        }
        XCTAssertEqual(polygon.plane.normal, normal)
    }

    func testConcavePolygonClockwiseWinding() {
        let normal = -Direction.z
        guard let polygon = Polygon([
            Vertex(Position(-1, 0), normal),
            Vertex(Position(0, 0), normal),
            Vertex(Position(0, 1), normal),
            Vertex(Position(1, 1), normal),
            Vertex(Position(1, -1), normal),
            Vertex(Position(-1, -1), normal),
        ]) else {
            XCTFail()
            return
        }
        XCTAssertEqual(polygon.plane.normal, normal)
    }

    func testDegeneratePolygonWithColinearPoints() {
        let normal = Direction.z
        XCTAssertNil(Polygon([
            Vertex(Position(0, 1), normal),
            Vertex(Position(0, 0), normal),
            Vertex(Position(0, -2), normal),
        ]))
    }

    func testNonDegeneratePolygonWithColinearPoints() {
        let normal = Direction.z
        XCTAssertNotNil(Polygon([
            Vertex(Position(0, 1), normal),
            Vertex(Position(0, 0), normal),
            Vertex(Position(0, -2), normal),
            Vertex(Position(1.5, -1), normal),
        ]))
    }

    func testDegeneratePolygonWithSelfIntersectingPoints() {
        let normal = Direction.z
        XCTAssertNil(Polygon([
            Vertex(Position(0, 0), normal),
            Vertex(Position(1, 1), normal),
            Vertex(Position(1, 0), normal),
            Vertex(Position(0, 1), normal),
        ]))
    }

    func testPolygonWithOnlyTwoPoints() {
        let normal = Vector(0, 0, 1)
        XCTAssertNil(Polygon([
            Vertex(Vector(-1, 1), normal),
            Vertex(Vector(-1, -1), normal),
        ]))
    }

    func testZeroNormals() {
        guard let polygon = Polygon([
            Vertex(Position(-1, 1), .zero),
            Vertex(Position(-1, -1), .zero),
            Vertex(Position(1, -1), .zero),
            Vertex(Position(1, 1), .zero),
        ]) else {
            XCTFail()
            return
        }
        XCTAssert(polygon.vertices.allSatisfy {
            $0.normal == polygon.plane.normal
        })
    }

    func testPolygonFromVectors() {
        guard let polygon = Polygon([
            Position(-1, 1),
            Position(-1, -1),
            Position(1, -1),
            Position(1, 1),
        ]) else {
            XCTFail()
            return
        }
        XCTAssert(polygon.vertices.allSatisfy {
            $0.normal == polygon.plane.normal
        })
    }

    // MARK: merging

    func testMerge1() {
        let normal = Direction.z
        let a = Polygon(unchecked: [
            Vertex(Position(0, 1), normal),
            Vertex(Position(0, 0), normal),
            Vertex(Position(1, 1), normal),
        ])
        let b = Polygon(unchecked: [
            Vertex(Position(1, 1), normal),
            Vertex(Position(0, 0), normal),
            Vertex(Position(1, 0), normal),
        ])
        let c = Polygon(unchecked: [
            Vertex(Position(0, 1), normal),
            Vertex(Position(0, 0), normal),
            Vertex(Position(1, 0), normal),
            Vertex(Position(1, 1), normal),
        ])
        XCTAssertEqual(a.merge(b), c)
    }

    func testMerge2() {
        let normal = Direction.z
        let a = Polygon(unchecked: [
            Vertex(Position(0, 1), normal),
            Vertex(Position(1, 0), normal),
            Vertex(Position(1, 1), normal),
        ])
        let b = Polygon(unchecked: [
            Vertex(Position(2, 1), normal),
            Vertex(Position(1, 1), normal),
            Vertex(Position(1, 0), normal),
        ])
        let c = Polygon(unchecked: [
            Vertex(Position(0, 1), normal),
            Vertex(Position(1, 0), normal),
            Vertex(Position(2, 1), normal),
        ])
        XCTAssertEqual(a.merge(b), c)
    }

    func testMergeL2RAdjacentRects() {
        let normal = Direction.z
        let a = Polygon(unchecked: [
            Vertex(Position(-1, 1), normal),
            Vertex(Position(-1, -1), normal),
            Vertex(Position(0, -1), normal),
            Vertex(Position(0, 1), normal),
        ])
        let b = Polygon(unchecked: [
            Vertex(Position(0, 1), normal),
            Vertex(Position(0, -1), normal),
            Vertex(Position(1, -1), normal),
            Vertex(Position(1, 1), normal),
        ])
        guard let c = a.merge(b) else {
            XCTFail()
            return
        }
        XCTAssertEqual(c, Polygon(unchecked: [
            Vertex(Position(-1, 1), normal),
            Vertex(Position(-1, -1), normal),
            Vertex(Position(1, -1), normal),
            Vertex(Position(1, 1), normal),
        ]))
    }

    func testMergeR2LAdjacentRects() {
        let normal = Direction.z
        let a = Polygon(unchecked: [
            Vertex(Position(0, 1), normal),
            Vertex(Position(0, -1), normal),
            Vertex(Position(1, -1), normal),
            Vertex(Position(1, 1), normal),
        ])
        let b = Polygon(unchecked: [
            Vertex(Position(-1, 1), normal),
            Vertex(Position(-1, -1), normal),
            Vertex(Position(0, -1), normal),
            Vertex(Position(0, 1), normal),
        ])
        guard let c = a.merge(b) else {
            XCTFail()
            return
        }
        XCTAssertEqual(c, Polygon(unchecked: [
            Vertex(Position(1, -1), normal),
            Vertex(Position(1, 1), normal),
            Vertex(Position(-1, 1), normal),
            Vertex(Position(-1, -1), normal),
        ]))
    }

    func testMergeB2TAdjacentRects() {
        let normal = Direction.z
        let a = Polygon(unchecked: [
            Vertex(Position(-1, 0), normal),
            Vertex(Position(-1, -1), normal),
            Vertex(Position(1, -1), normal),
            Vertex(Position(1, 0), normal),
        ])
        let b = Polygon(unchecked: [
            Vertex(Position(-1, 1), normal),
            Vertex(Position(-1, 0), normal),
            Vertex(Position(1, 0), normal),
            Vertex(Position(1, 1), normal),
        ])
        guard let c = a.merge(b) else {
            XCTFail()
            return
        }
        XCTAssertEqual(c, Polygon(unchecked: [
            Vertex(Position(-1, -1), normal),
            Vertex(Position(1, -1), normal),
            Vertex(Position(1, 1), normal),
            Vertex(Position(-1, 1), normal),
        ]))
    }

    func testMergeT2BAdjacentRects() {
        let normal = Direction.z
        let a = Polygon(unchecked: [
            Vertex(Position(-1, 1), normal),
            Vertex(Position(-1, 0), normal),
            Vertex(Position(1, 0), normal),
            Vertex(Position(1, 1), normal),
        ])
        let b = Polygon(unchecked: [
            Vertex(Position(-1, 0), normal),
            Vertex(Position(-1, -1), normal),
            Vertex(Position(1, -1), normal),
            Vertex(Position(1, 0), normal),
        ])
        guard let c = a.merge(b) else {
            XCTFail()
            return
        }
        XCTAssertEqual(c, Polygon(unchecked: [
            Vertex(Position(1, 1), normal),
            Vertex(Position(-1, 1), normal),
            Vertex(Position(-1, -1), normal),
            Vertex(Position(1, -1), normal),
        ]))
    }

    func testMergeL2RAdjacentRectAndTriangle() {
        let normal = Direction.z
        let a = Polygon(unchecked: [
            Vertex(Position(-1, 1), normal),
            Vertex(Position(-1, -1), normal),
            Vertex(Position(0, -1), normal),
            Vertex(Position(0, 1), normal),
        ])
        let b = Polygon(unchecked: [
            Vertex(Position(0, 1), normal),
            Vertex(Position(0, -1), normal),
            Vertex(Position(1, 1), normal),
        ])
        guard let c = a.merge(b) else {
            XCTFail()
            return
        }
        XCTAssertEqual(c, Polygon(unchecked: [
            Vertex(Position(-1, 1), normal),
            Vertex(Position(-1, -1), normal),
            Vertex(Position(0, -1), normal),
            Vertex(Position(1, 1), normal),
        ]))
    }

    func testMergeEdgeCase() {
        let normal = Direction.z
        let a = Polygon(unchecked: [
            Vertex(Position(-0.02, 0.8), normal),
            Vertex(Position(0.7028203230300001, 0.38267949192000006), normal),
            Vertex(Position(0.7028203230300001, -0.38267949192000006), normal),
        ])
        let b = Polygon(unchecked: [
            Vertex(Position(0.7028203230300001, -0.38267949192000006), normal),
            Vertex(Position(-0.02, -0.8), normal),
            Vertex(Position(-0.6828203230300001, -0.41732050808000004), normal),
            Vertex(Position(-0.6828203230300001, 0.41732050808000004), normal),
            Vertex(Position(-0.02, 0.8), normal),
        ])
        let c = Polygon(unchecked: [
            Vertex(Position(0.7028203230300001, 0.38267949192000006), normal),
            Vertex(Position(0.7028203230300001, -0.38267949192000006), normal),
            Vertex(Position(-0.02, -0.8), normal),
            Vertex(Position(-0.6828203230300001, -0.41732050808000004), normal),
            Vertex(Position(-0.6828203230300001, 0.41732050808000004), normal),
            Vertex(Position(-0.02, 0.8), normal),
        ])
        XCTAssertEqual(a.merge(b), c)
    }

    // MARK: containsPoint

    func testConvexAnticlockwisePolygonContainsPoint() {
        let path = Path([
            .point(-1, 1),
            .point(-1, -1),
            .point(1, -1),
            .point(1, 1),
            .point(-1, 1),
        ])
        guard let polygon = Polygon(shape: path) else {
            XCTFail()
            return
        }
        XCTAssertTrue(polygon.containsPoint(Position(0, 0)))
        XCTAssertTrue(polygon.containsPoint(Position(-0.999, 0.999)))
        XCTAssertTrue(polygon.containsPoint(Position(0.999, 0.999)))
        XCTAssertTrue(polygon.containsPoint(Position(0.999, -0.999)))
        XCTAssertTrue(polygon.containsPoint(Position(-0.999, -0.999)))
        XCTAssertFalse(polygon.containsPoint(Position(-1.001, 0)))
        XCTAssertFalse(polygon.containsPoint(Position(1.001, 0)))
        XCTAssertFalse(polygon.containsPoint(Position(0, -1.001)))
        XCTAssertFalse(polygon.containsPoint(Position(0, 1.001)))
    }

    func testConvexClockwisePolygonContainsPoint() {
        let path = Path([
            .point(-1, -1),
            .point(-1, 1),
            .point(1, 1),
            .point(1, -1),
            .point(-1, -1),
        ])
        guard let polygon = Polygon(shape: path) else {
            XCTFail()
            return
        }
        XCTAssertTrue(polygon.containsPoint(Position(0, 0)))
        XCTAssertTrue(polygon.containsPoint(Position(-0.999, 0.999)))
        XCTAssertTrue(polygon.containsPoint(Position(0.999, 0.999)))
        XCTAssertTrue(polygon.containsPoint(Position(0.999, -0.999)))
        XCTAssertTrue(polygon.containsPoint(Position(-0.999, -0.999)))
        XCTAssertFalse(polygon.containsPoint(Position(-1.001, 0)))
        XCTAssertFalse(polygon.containsPoint(Position(1.001, 0)))
        XCTAssertFalse(polygon.containsPoint(Position(0, -1.001)))
        XCTAssertFalse(polygon.containsPoint(Position(0, 1.001)))
    }

    func testConcaveAnticlockwisePolygonContainsPoint() {
        let path = Path([
            .point(-1, 0),
            .point(0, 0),
            .point(0, -1),
            .point(1, -1),
            .point(1, 1),
            .point(-1, 1),
            .point(-1, 0),
        ])
        guard let polygon = Polygon(shape: path) else {
            XCTFail()
            return
        }
        XCTAssertTrue(polygon.containsPoint(Position(-0.5, 0.5)))
        XCTAssertTrue(polygon.containsPoint(Position(0.5, 0.5)))
        XCTAssertFalse(polygon.containsPoint(Position(-0.5, -0.5)))
        XCTAssertTrue(polygon.containsPoint(Position(0.5, -0.5)))
    }

    func testConcaveAnticlockwisePolygonContainsPoint2() {
        let path = Path([
            .point(0, 1),
            .point(0.5, 0),
            .point(0, -1),
            .point(1, 0),
            .point(0, 1),
        ])
        guard let polygon = Polygon(shape: path) else {
            XCTFail()
            return
        }
        XCTAssertTrue(polygon.containsPoint(Position(0.75, 0)))
        XCTAssertFalse(polygon.containsPoint(Position(0.25, 0)))
        XCTAssertFalse(polygon.containsPoint(Position(0.25, 0.25)))
        XCTAssertFalse(polygon.containsPoint(Position(0.25, -0.25)))
        XCTAssertTrue(polygon.containsPoint(Position(0.25, 0.5)))
        XCTAssertTrue(polygon.containsPoint(Position(0.25, -0.5)))
    }

    // MARK: tessellation

    func testConcaveAnticlockwisePolygonCorrectlyTessellated() {
        let path = Path([
            .point(0, 1),
            .point(0.5, 0),
            .point(0, -1),
            .point(1, 0),
            .point(0, 1),
        ])
        guard let polygon = Polygon(shape: path) else {
            XCTFail()
            return
        }
        let polygons = polygon.tessellate()
        XCTAssertEqual(polygons.count, 2)
        guard polygons.count > 1 else {
            return
        }
        let a = Set(polygons[0].vertices.map { $0.position })
        let expectedA = Set([
            Position(0, 1),
            Position(0.5, 0),
            Position(1, 0),
        ])
        let b = Set(polygons[1].vertices.map { $0.position })
        let expectedB = Set([
            Position(0.5, 0),
            Position(1, 0),
            Position(0, -1),
        ])
        XCTAssert(a == expectedA || a == expectedB)
        XCTAssert(b == expectedA || b == expectedB)
    }

    func testInvertedConcaveAnticlockwisePolygonCorrectlyTessellated() {
        let path = Path([
            .point(0, 1),
            .point(0.5, 0),
            .point(0, -1),
            .point(1, 0),
            .point(0, 1),
        ])
        guard let polygon = Polygon(shape: path)?.inverted() else {
            XCTFail()
            return
        }
        let polygons = polygon.tessellate()
        XCTAssertEqual(polygons.count, 2)
        guard polygons.count > 1 else {
            return
        }
        let a = Set(polygons[0].vertices.map { $0.position })
        let expectedA = Set([
            Position(0, 1),
            Position(1, 0),
            Position(0.5, 0),
        ])
        let b = Set(polygons[1].vertices.map { $0.position })
        let expectedB = Set([
            Position(0.5, 0),
            Position(1, 0),
            Position(0, -1),
        ])
        XCTAssert(a == expectedA || a == expectedB)
        XCTAssert(b == expectedA || b == expectedB)
    }

    // MARK: triangulation

    func testConcaveAnticlockwisePolygonCorrectlyTriangulated() {
        let path = Path([
            .point(0, 1),
            .point(0.5, 0),
            .point(0, -1),
            .point(1, 0),
            .point(0, 1),
        ])
        guard let polygon = Polygon(shape: path) else {
            XCTFail()
            return
        }
        let triangles = polygon.triangulate()
        XCTAssertEqual(triangles.count, 2)
        guard triangles.count > 1 else {
            return
        }
        let a = Set(triangles[0].vertices.map { $0.position })
        let expectedA = Set([
            Position(0, 1),
            Position(0.5, 0),
            Position(1, 0),
        ])
        let b = Set(triangles[1].vertices.map { $0.position })
        let expectedB = Set([
            Position(0.5, 0),
            Position(1, 0),
            Position(0, -1),
        ])
        XCTAssert(a == expectedA || a == expectedB)
        XCTAssert(b == expectedA || b == expectedB)
    }

    func testInvertedConcaveAnticlockwisePolygonCorrectlyTriangulated() {
        let path = Path([
            .point(0, 1),
            .point(0.5, 0),
            .point(0, -1),
            .point(1, 0),
            .point(0, 1),
        ])
        guard let polygon = Polygon(shape: path)?.inverted() else {
            XCTFail()
            return
        }
        let triangles = polygon.triangulate()
        XCTAssertEqual(triangles.count, 2)
        guard triangles.count > 1 else {
            return
        }
        let a = Set(triangles[0].vertices.map { $0.position })
        let expectedA = Set([
            Position(0, 1),
            Position(1, 0),
            Position(0.5, 0),
        ])
        let b = Set(triangles[1].vertices.map { $0.position })
        let expectedB = Set([
            Position(0.5, 0),
            Position(1, 0),
            Position(0, -1),
        ])
        XCTAssert(a == expectedA || a == expectedB)
        XCTAssert(b == expectedA || b == expectedB)
    }

    func testPolygonWithColinearPointsCorrectlyTriangulated() {
        let normal = -Direction.z
        guard let polygon = Polygon([
            Vertex(Position(0, 0), normal),
            Vertex(Position(0.5, 0), normal),
            Vertex(Position(0.5, 1), normal),
            Vertex(Position(-0.5, 1), normal),
            Vertex(Position(-0.5, 0), normal),
        ]) else {
            XCTFail()
            return
        }
        let triangles = polygon.triangulate()
        guard triangles.count == 3 else {
            XCTFail()
            return
        }
        XCTAssertEqual(triangles[0], Polygon([
            Vertex(Position(0, 0), normal),
            Vertex(Position(0.5, 0), normal),
            Vertex(Position(0.5, 1), normal),
        ]))
        XCTAssertEqual(triangles[1], Polygon([
            Vertex(Position(0, 0), normal),
            Vertex(Position(0.5, 1), normal),
            Vertex(Position(-0.5, 1), normal),
        ]))
        XCTAssertEqual(triangles[2], Polygon([
            Vertex(Position(0, 0), normal),
            Vertex(Position(-0.5, 1), normal),
            Vertex(Position(-0.5, 0), normal),
        ]))
    }

    func testHouseShapedPolygonCorrectlyTriangulated() {
        let normal = -Direction.z
        guard let polygon = Polygon([
            Vertex(Position(0, 0.5), normal),
            Vertex(Position(1, 0), normal),
            Vertex(Position(0.5, -epsilon), normal),
            Vertex(Position(0.5, -1), normal),
            Vertex(Position(-0.5, -1), normal),
            Vertex(Position(-0.5, -epsilon), normal),
            Vertex(Position(-1, 0), normal),
        ]) else {
            XCTFail()
            return
        }
        let triangles = polygon.triangulate()
        guard triangles.count == 3 else {
            XCTFail()
            return
        }
        XCTAssertEqual(triangles[0], Polygon([
            Vertex(Position(-1, 0), normal),
            Vertex(Position(0, 0.5), normal),
            Vertex(Position(1, 0), normal),
        ]))
        XCTAssertEqual(triangles[1], Polygon([
            Vertex(Position(0.5, -epsilon), normal),
            Vertex(Position(0.5, -1), normal),
            Vertex(Position(-0.5, -1), normal),
        ]))
        XCTAssertEqual(triangles[2], Polygon([
            Vertex(Position(0.5, -epsilon), normal),
            Vertex(Position(-0.5, -1), normal),
            Vertex(Position(-0.5, -epsilon), normal),
        ]))
    }

    func testPathWithZeroAreaColinearPointTriangulated() {
        let path = Path([
            .point(0.18, 0.245),
            .point(0.18, 0.255),
            .point(0.17, 0.255),
            .point(0.16, 0.247),
            .point(0.16, 0.244),
            .point(0.16, 0.245),
            .point(0.18, 0.245),
        ])
        guard let polygon = Polygon(shape: path) else {
            XCTFail()
            return
        }
        let triangles = polygon.triangulate()
        XCTAssertEqual(triangles.count, 3)
    }

    func testSlightlyNonPlanarPolygonTriangulated() {
        let offset = epsilon / 2
        let path = Path([
            .point(1.086, 0, 0.17),
            .point(1.086, 0, 0.14),
            .point(0.95, offset, 0.14),
            .point(0.935, 0, 0.1),
            .point(0.935, 0, 0.17),
            .point(1.086, 0, 0.17),
        ])
        guard let polygon = Polygon(shape: path) else {
            XCTFail()
            return
        }
        let triangles = polygon.triangulate()
        XCTAssertEqual(triangles.count, 3)
        let points = triangles.map { $0.vertices.map { $0.position } }
        XCTAssertEqual(points, [
            [
                Position(0.9349999999999999, 0.0, 0.16999999999999998),
                Position(1.086, 0.0, 0.16999999999999998),
                Position(1.086, 0.0, 0.13999999999999999),
            ],
            [
                Position(0.9349999999999999, 0.0, 0.16999999999999998),
                Position(1.086, 0.0, 0.13999999999999999),
                Position(0.95, offset, 0.13999999999999999),
            ],
            [
                Position(0.95, offset, 0.13999999999999999),
                Position(0.9349999999999999, 0.0, 0.09999999999999999),
                Position(0.9349999999999999, 0.0, 0.16999999999999998),
            ],
        ])
        let merged = triangles.detessellate(ensureConvex: false)
        XCTAssertEqual(Set(merged.flatMap { $0.vertices }), Set(polygon.vertices))
    }

    func testInvertedSlightlyNonPlanarPolygonTriangulated() {
        let offset = epsilon / 2
        let path = Path([
            .point(1.086, 0, 0.17),
            .point(1.086, 0, 0.14),
            .point(0.95, offset, 0.14),
            .point(0.935, 0, 0.1),
            .point(0.935, 0, 0.17),
            .point(1.086, 0, 0.17),
        ])
        guard let polygon = Polygon(shape: path)?.inverted() else {
            XCTFail()
            return
        }
        let triangles = polygon.triangulate()
        XCTAssertEqual(triangles.count, 3)
        let points = triangles.map { $0.vertices.map { $0.position } }
        XCTAssertEqual(points, [
            [
                Position(1.086, 0.0, 0.13999999999999999),
                Position(1.086, 0.0, 0.16999999999999998),
                Position(0.9349999999999999, 0.0, 0.16999999999999998),
            ],
            [
                Position(0.95, offset, 0.13999999999999999),
                Position(1.086, 0.0, 0.13999999999999999),
                Position(0.9349999999999999, 0.0, 0.16999999999999998),
            ],
            [
                Position(0.9349999999999999, 0.0, 0.16999999999999998),
                Position(0.9349999999999999, 0.0, 0.09999999999999999),
                Position(0.95, offset, 0.13999999999999999),
            ],
        ])
        let merged = triangles.detessellate(ensureConvex: false)
        XCTAssertEqual(Set(merged.flatMap { $0.vertices }), Set(polygon.vertices))
    }

    func testPolygonIDPreservedThroughTriangulation() {
        let path = Path([
            .point(0, 1),
            .point(0.5, 0),
            .point(0, -1),
            .point(1, 0),
            .point(0, 1),
        ])
        guard let polygon = Polygon(shape: path)?.with(id: 5) else {
            XCTFail()
            return
        }
        let triangles = polygon.triangulate()
        XCTAssert(triangles.allSatisfy { $0.id == 5 })
    }

    func testPolygonIDPreservedThroughTessellation() {
        let path = Path([
            .point(0, 1),
            .point(0.5, 0),
            .point(0, -1),
            .point(1, 0),
            .point(0, 1),
        ])
        guard let polygon = Polygon(shape: path)?.with(id: 5) else {
            XCTFail()
            return
        }
        let polygons = polygon.tessellate()
        XCTAssert(polygons.allSatisfy { $0.id == 5 })
    }

    // MARK: detessellation

    func testConcaveAnticlockwisePolygonCorrectlyDetessellated() {
        let path = Path([
            .point(0, 1),
            .point(0.5, 0),
            .point(0, -1),
            .point(1, 0),
            .point(0, 1),
        ])
        guard let polygon = Polygon(shape: path) else {
            XCTFail()
            return
        }
        let polygons = polygon.tessellate()
        XCTAssertEqual(polygons.count, 2)
        let result = polygons.detessellate()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.undirectedEdges, polygon.undirectedEdges)
        XCTAssertEqual(Set(result.first?.vertices ?? []), Set(polygon.vertices))
    }

    func testInvertedConcaveAnticlockwisePolygonCorrectlyDetessellated() {
        let path = Path([
            .point(0, 1),
            .point(0.5, 0),
            .point(0, -1),
            .point(1, 0),
            .point(0, 1),
        ])
        guard let polygon = Polygon(shape: path)?.inverted() else {
            XCTFail()
            return
        }
        let polygons = polygon.tessellate()
        XCTAssertEqual(polygons.count, 2)
        let result = polygons.detessellate()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.undirectedEdges, polygon.undirectedEdges)
        XCTAssertEqual(Set(result.first?.vertices ?? []), Set(polygon.vertices))
    }

    func testPolygonWithColinearPointsCorrectlyDetessellated() {
        let normal = -Direction.z
        let polygon = Polygon(unchecked: [
            Vertex(Position(0, 0), normal),
            Vertex(Position(0.5, 0), normal),
            Vertex(Position(0.5, 1), normal),
            Vertex(Position(-0.5, 1), normal),
            Vertex(Position(-0.5, 0), normal),
        ])
        let triangles = polygon.triangulate()
        XCTAssertEqual(triangles.count, 3)
        let result = triangles.detessellate()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.vertices.count, 4)
        XCTAssertEqual(result.first?.undirectedEdges.count, 4)
    }

    func testHouseShapedPolygonCorrectlyDetessellated() {
        let normal = -Direction.z
        let polygon = Polygon(unchecked: [
            Vertex(Position(0, 0.5), normal),
            Vertex(Position(1, 0), normal),
            Vertex(Position(0.5, 0), normal),
            Vertex(Position(0.5, -1), normal),
            Vertex(Position(-0.5, -1), normal),
            Vertex(Position(-0.5, 0), normal),
            Vertex(Position(-1, 0), normal),
        ])
        let triangles = polygon.triangulate()
        XCTAssertEqual(triangles.count, 5)
        let result = triangles.detessellate()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.undirectedEdges, polygon.undirectedEdges)
        XCTAssertEqual(Set(result.first?.vertices ?? []), Set(polygon.vertices))
    }

    func testNonWatertightPolygonsCorrectlyDetessellated() {
        let normal = -Direction.z
        let triangles = [
            Polygon(unchecked: [
                Vertex(Position(0, -1), normal),
                Vertex(Position(-2, 0), normal),
                Vertex(Position(2, 0), normal),
            ]),
            Polygon(unchecked: [
                Vertex(Position(-2, 0), normal),
                Vertex(Position(0, 1), normal),
                Vertex(Position(0, 0), normal),
            ]),
            Polygon(unchecked: [
                Vertex(Position(2, 0), normal),
                Vertex(Position(0, 0), normal),
                Vertex(Position(0, 1), normal),
            ]),
        ]
        let result = triangles.detessellate()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result, [
            Polygon(unchecked: [
                Vertex(Position(0, -1), normal),
                Vertex(Position(-2, 0), normal),
                Vertex(Position(0, 1), normal),
                Vertex(Position(2, 0), normal),
            ]),
        ])
    }
}
