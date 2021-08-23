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
        let normal = Vector(0, 0, 1)
        guard let polygon = Polygon([
            Vertex(Vector(-1, 1), normal),
            Vertex(Vector(-1, -1), normal),
            Vertex(Vector(1, -1), normal),
            Vertex(Vector(1, 1), normal),
        ]) else {
            XCTFail()
            return
        }
        XCTAssertEqual(polygon.plane.normal, normal)
    }

    func testConvexPolygonClockwiseWinding() {
        let normal = Vector(0, 0, -1)
        guard let polygon = Polygon([
            Vertex(Vector(-1, -1), normal),
            Vertex(Vector(-1, 1), normal),
            Vertex(Vector(1, 1), normal),
            Vertex(Vector(1, -1), normal),
        ]) else {
            XCTFail()
            return
        }
        XCTAssertEqual(polygon.plane.normal, normal)
    }

    func testConcavePolygonAnticlockwiseWinding() {
        let normal = Vector(0, 0, 1)
        guard let polygon = Polygon([
            Vertex(Vector(-1, 0), normal),
            Vertex(Vector(0, 0), normal),
            Vertex(Vector(0, -1), normal),
            Vertex(Vector(1, -1), normal),
            Vertex(Vector(1, 1), normal),
            Vertex(Vector(-1, 1), normal),
        ]) else {
            XCTFail()
            return
        }
        XCTAssertEqual(polygon.plane.normal, normal)
    }

    func testConcavePolygonClockwiseWinding() {
        let normal = Vector(0, 0, -1)
        guard let polygon = Polygon([
            Vertex(Vector(-1, 0), normal),
            Vertex(Vector(0, 0), normal),
            Vertex(Vector(0, 1), normal),
            Vertex(Vector(1, 1), normal),
            Vertex(Vector(1, -1), normal),
            Vertex(Vector(-1, -1), normal),
        ]) else {
            XCTFail()
            return
        }
        XCTAssertEqual(polygon.plane.normal, normal)
    }

    func testDegeneratePolygonWithColinearPoints() {
        let normal = Vector(0, 0, 1)
        XCTAssertNil(Polygon([
            Vertex(Vector(0, 1), normal),
            Vertex(Vector(0, 0), normal),
            Vertex(Vector(0, -2), normal),
        ]))
    }

    func testNonDegeneratePolygonWithColinearPoints() {
        let normal = Vector(0, 0, 1)
        XCTAssertNotNil(Polygon([
            Vertex(Vector(0, 1), normal),
            Vertex(Vector(0, 0), normal),
            Vertex(Vector(0, -2), normal),
            Vertex(Vector(1.5, -1), normal),
        ]))
    }

    func testDegeneratePolygonWithSelfIntersectingPoints() {
        let normal = Vector(0, 0, 1)
        XCTAssertNil(Polygon([
            Vertex(Vector(0, 0), normal),
            Vertex(Vector(1, 1), normal),
            Vertex(Vector(1, 0), normal),
            Vertex(Vector(0, 1), normal),
        ]))
    }

    func testZeroNormals() {
        guard let polygon = Polygon([
            Vertex(Vector(-1, 1), .zero),
            Vertex(Vector(-1, -1), .zero),
            Vertex(Vector(1, -1), .zero),
            Vertex(Vector(1, 1), .zero),
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
            Vector(-1, 1),
            Vector(-1, -1),
            Vector(1, -1),
            Vector(1, 1),
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
        let normal = Vector(0, 0, 1)
        let a = Polygon(unchecked: [
            Vertex(Vector(0, 1), normal),
            Vertex(Vector(0, 0), normal),
            Vertex(Vector(1, 1), normal),
        ])
        let b = Polygon(unchecked: [
            Vertex(Vector(1, 1), normal),
            Vertex(Vector(0, 0), normal),
            Vertex(Vector(1, 0), normal),
        ])
        let c = Polygon(unchecked: [
            Vertex(Vector(0, 1), normal),
            Vertex(Vector(0, 0), normal),
            Vertex(Vector(1, 0), normal),
            Vertex(Vector(1, 1), normal),
        ])
        XCTAssertEqual(a.merge(b), c)
    }

    func testMerge2() {
        let normal = Vector(0, 0, 1)
        let a = Polygon(unchecked: [
            Vertex(Vector(0, 1), normal),
            Vertex(Vector(1, 0), normal),
            Vertex(Vector(1, 1), normal),
        ])
        let b = Polygon(unchecked: [
            Vertex(Vector(2, 1), normal),
            Vertex(Vector(1, 1), normal),
            Vertex(Vector(1, 0), normal),
        ])
        let c = Polygon(unchecked: [
            Vertex(Vector(0, 1), normal),
            Vertex(Vector(1, 0), normal),
            Vertex(Vector(2, 1), normal),
        ])
        XCTAssertEqual(a.merge(b), c)
    }

    func testMergeL2RAdjacentRects() {
        let normal = Vector(0, 0, 1)
        let a = Polygon(unchecked: [
            Vertex(Vector(-1, 1), normal),
            Vertex(Vector(-1, -1), normal),
            Vertex(Vector(0, -1), normal),
            Vertex(Vector(0, 1), normal),
        ])
        let b = Polygon(unchecked: [
            Vertex(Vector(0, 1), normal),
            Vertex(Vector(0, -1), normal),
            Vertex(Vector(1, -1), normal),
            Vertex(Vector(1, 1), normal),
        ])
        guard let c = a.merge(b) else {
            XCTFail()
            return
        }
        XCTAssertEqual(c, Polygon(unchecked: [
            Vertex(Vector(-1, 1), normal),
            Vertex(Vector(-1, -1), normal),
            Vertex(Vector(1, -1), normal),
            Vertex(Vector(1, 1), normal),
        ]))
    }

    func testMergeR2LAdjacentRects() {
        let normal = Vector(0, 0, 1)
        let a = Polygon(unchecked: [
            Vertex(Vector(0, 1), normal),
            Vertex(Vector(0, -1), normal),
            Vertex(Vector(1, -1), normal),
            Vertex(Vector(1, 1), normal),
        ])
        let b = Polygon(unchecked: [
            Vertex(Vector(-1, 1), normal),
            Vertex(Vector(-1, -1), normal),
            Vertex(Vector(0, -1), normal),
            Vertex(Vector(0, 1), normal),
        ])
        guard let c = a.merge(b) else {
            XCTFail()
            return
        }
        XCTAssertEqual(c, Polygon(unchecked: [
            Vertex(Vector(1, -1), normal),
            Vertex(Vector(1, 1), normal),
            Vertex(Vector(-1, 1), normal),
            Vertex(Vector(-1, -1), normal),
        ]))
    }

    func testMergeB2TAdjacentRects() {
        let normal = Vector(0, 0, 1)
        let a = Polygon(unchecked: [
            Vertex(Vector(-1, 0), normal),
            Vertex(Vector(-1, -1), normal),
            Vertex(Vector(1, -1), normal),
            Vertex(Vector(1, 0), normal),
        ])
        let b = Polygon(unchecked: [
            Vertex(Vector(-1, 1), normal),
            Vertex(Vector(-1, 0), normal),
            Vertex(Vector(1, 0), normal),
            Vertex(Vector(1, 1), normal),
        ])
        guard let c = a.merge(b) else {
            XCTFail()
            return
        }
        XCTAssertEqual(c, Polygon(unchecked: [
            Vertex(Vector(-1, -1), normal),
            Vertex(Vector(1, -1), normal),
            Vertex(Vector(1, 1), normal),
            Vertex(Vector(-1, 1), normal),
        ]))
    }

    func testMergeT2BAdjacentRects() {
        let normal = Vector(0, 0, 1)
        let a = Polygon(unchecked: [
            Vertex(Vector(-1, 1), normal),
            Vertex(Vector(-1, 0), normal),
            Vertex(Vector(1, 0), normal),
            Vertex(Vector(1, 1), normal),
        ])
        let b = Polygon(unchecked: [
            Vertex(Vector(-1, 0), normal),
            Vertex(Vector(-1, -1), normal),
            Vertex(Vector(1, -1), normal),
            Vertex(Vector(1, 0), normal),
        ])
        guard let c = a.merge(b) else {
            XCTFail()
            return
        }
        XCTAssertEqual(c, Polygon(unchecked: [
            Vertex(Vector(1, 1), normal),
            Vertex(Vector(-1, 1), normal),
            Vertex(Vector(-1, -1), normal),
            Vertex(Vector(1, -1), normal),
        ]))
    }

    func testMergeL2RAdjacentRectAndTriangle() {
        let normal = Vector(0, 0, 1)
        let a = Polygon(unchecked: [
            Vertex(Vector(-1, 1), normal),
            Vertex(Vector(-1, -1), normal),
            Vertex(Vector(0, -1), normal),
            Vertex(Vector(0, 1), normal),
        ])
        let b = Polygon(unchecked: [
            Vertex(Vector(0, 1), normal),
            Vertex(Vector(0, -1), normal),
            Vertex(Vector(1, 1), normal),
        ])
        guard let c = a.merge(b) else {
            XCTFail()
            return
        }
        XCTAssertEqual(c, Polygon(unchecked: [
            Vertex(Vector(-1, 1), normal),
            Vertex(Vector(-1, -1), normal),
            Vertex(Vector(0, -1), normal),
            Vertex(Vector(1, 1), normal),
        ]))
    }

    func testMergeEdgeCase() {
        let normal = Vector(0, 0, 1)
        let a = Polygon(unchecked: [
            Vertex(Vector(-0.02, 0.8), normal),
            Vertex(Vector(0.7028203230300001, 0.38267949192000006), normal),
            Vertex(Vector(0.7028203230300001, -0.38267949192000006), normal),
        ])
        let b = Polygon(unchecked: [
            Vertex(Vector(0.7028203230300001, -0.38267949192000006), normal),
            Vertex(Vector(-0.02, -0.8), normal),
            Vertex(Vector(-0.6828203230300001, -0.41732050808000004), normal),
            Vertex(Vector(-0.6828203230300001, 0.41732050808000004), normal),
            Vertex(Vector(-0.02, 0.8), normal),
        ])
        let c = Polygon(unchecked: [
            Vertex(Vector(0.7028203230300001, 0.38267949192000006), normal),
            Vertex(Vector(0.7028203230300001, -0.38267949192000006), normal),
            Vertex(Vector(-0.02, -0.8), normal),
            Vertex(Vector(-0.6828203230300001, -0.41732050808000004), normal),
            Vertex(Vector(-0.6828203230300001, 0.41732050808000004), normal),
            Vertex(Vector(-0.02, 0.8), normal),
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
        XCTAssertTrue(polygon.containsPoint(Vector(0, 0)))
        XCTAssertTrue(polygon.containsPoint(Vector(-0.999, 0.999)))
        XCTAssertTrue(polygon.containsPoint(Vector(0.999, 0.999)))
        XCTAssertTrue(polygon.containsPoint(Vector(0.999, -0.999)))
        XCTAssertTrue(polygon.containsPoint(Vector(-0.999, -0.999)))
        XCTAssertFalse(polygon.containsPoint(Vector(-1.001, 0)))
        XCTAssertFalse(polygon.containsPoint(Vector(1.001, 0)))
        XCTAssertFalse(polygon.containsPoint(Vector(0, -1.001)))
        XCTAssertFalse(polygon.containsPoint(Vector(0, 1.001)))
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
        XCTAssertTrue(polygon.containsPoint(Vector(0, 0)))
        XCTAssertTrue(polygon.containsPoint(Vector(-0.999, 0.999)))
        XCTAssertTrue(polygon.containsPoint(Vector(0.999, 0.999)))
        XCTAssertTrue(polygon.containsPoint(Vector(0.999, -0.999)))
        XCTAssertTrue(polygon.containsPoint(Vector(-0.999, -0.999)))
        XCTAssertFalse(polygon.containsPoint(Vector(-1.001, 0)))
        XCTAssertFalse(polygon.containsPoint(Vector(1.001, 0)))
        XCTAssertFalse(polygon.containsPoint(Vector(0, -1.001)))
        XCTAssertFalse(polygon.containsPoint(Vector(0, 1.001)))
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
        XCTAssertTrue(polygon.containsPoint(Vector(-0.5, 0.5)))
        XCTAssertTrue(polygon.containsPoint(Vector(0.5, 0.5)))
        XCTAssertFalse(polygon.containsPoint(Vector(-0.5, -0.5)))
        XCTAssertTrue(polygon.containsPoint(Vector(0.5, -0.5)))
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
        XCTAssertTrue(polygon.containsPoint(Vector(0.75, 0)))
        XCTAssertFalse(polygon.containsPoint(Vector(0.25, 0)))
        XCTAssertFalse(polygon.containsPoint(Vector(0.25, 0.25)))
        XCTAssertFalse(polygon.containsPoint(Vector(0.25, -0.25)))
        XCTAssertTrue(polygon.containsPoint(Vector(0.25, 0.5)))
        XCTAssertTrue(polygon.containsPoint(Vector(0.25, -0.5)))
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
            Vector(0, 1),
            Vector(0.5, 0),
            Vector(1, 0),
        ])
        let b = Set(polygons[1].vertices.map { $0.position })
        let expectedB = Set([
            Vector(0.5, 0),
            Vector(1, 0),
            Vector(0, -1),
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
            Vector(0, 1),
            Vector(1, 0),
            Vector(0.5, 0),
        ])
        let b = Set(polygons[1].vertices.map { $0.position })
        let expectedB = Set([
            Vector(0.5, 0),
            Vector(1, 0),
            Vector(0, -1),
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
            Vector(0, 1),
            Vector(0.5, 0),
            Vector(1, 0),
        ])
        let b = Set(triangles[1].vertices.map { $0.position })
        let expectedB = Set([
            Vector(0.5, 0),
            Vector(1, 0),
            Vector(0, -1),
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
            Vector(0, 1),
            Vector(1, 0),
            Vector(0.5, 0),
        ])
        let b = Set(triangles[1].vertices.map { $0.position })
        let expectedB = Set([
            Vector(0.5, 0),
            Vector(1, 0),
            Vector(0, -1),
        ])
        XCTAssert(a == expectedA || a == expectedB)
        XCTAssert(b == expectedA || b == expectedB)
    }

    func testPolygonWithColinearPointsCorrectlyTriangulated() {
        let normal = Vector(0, 0, -1)
        guard let polygon = Polygon([
            Vertex(Vector(0, 0), normal),
            Vertex(Vector(0.5, 0), normal),
            Vertex(Vector(0.5, 1), normal),
            Vertex(Vector(-0.5, 1), normal),
            Vertex(Vector(-0.5, 0), normal),
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
            Vertex(Vector(0, 0), normal),
            Vertex(Vector(0.5, 0), normal),
            Vertex(Vector(0.5, 1), normal),
        ]))
        XCTAssertEqual(triangles[1], Polygon([
            Vertex(Vector(0, 0), normal),
            Vertex(Vector(0.5, 1), normal),
            Vertex(Vector(-0.5, 1), normal),
        ]))
        XCTAssertEqual(triangles[2], Polygon([
            Vertex(Vector(0, 0), normal),
            Vertex(Vector(-0.5, 1), normal),
            Vertex(Vector(-0.5, 0), normal),
        ]))
    }

    func testHouseShapedPolygonCorrectlyTriangulated() {
        let normal = Vector(0, 0, -1)
        guard let polygon = Polygon([
            Vertex(Vector(0, 0.5), normal),
            Vertex(Vector(1, 0), normal),
            Vertex(Vector(0.5, -epsilon), normal),
            Vertex(Vector(0.5, -1), normal),
            Vertex(Vector(-0.5, -1), normal),
            Vertex(Vector(-0.5, -epsilon), normal),
            Vertex(Vector(-1, 0), normal),
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
            Vertex(Vector(-1, 0), normal),
            Vertex(Vector(0, 0.5), normal),
            Vertex(Vector(1, 0), normal),
        ]))
        XCTAssertEqual(triangles[1], Polygon([
            Vertex(Vector(0.5, -epsilon), normal),
            Vertex(Vector(0.5, -1), normal),
            Vertex(Vector(-0.5, -1), normal),
        ]))
        XCTAssertEqual(triangles[2], Polygon([
            Vertex(Vector(0.5, -epsilon), normal),
            Vertex(Vector(-0.5, -1), normal),
            Vertex(Vector(-0.5, -epsilon), normal),
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
                Vector(0.9349999999999999, 0.0, 0.16999999999999998),
                Vector(1.086, 0.0, 0.16999999999999998),
                Vector(1.086, 0.0, 0.13999999999999999),
            ],
            [
                Vector(0.9349999999999999, 0.0, 0.16999999999999998),
                Vector(1.086, 0.0, 0.13999999999999999),
                Vector(0.95, offset, 0.13999999999999999),
            ],
            [
                Vector(0.95, offset, 0.13999999999999999),
                Vector(0.9349999999999999, 0.0, 0.09999999999999999),
                Vector(0.9349999999999999, 0.0, 0.16999999999999998),
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
                Vector(1.086, 0.0, 0.13999999999999999),
                Vector(1.086, 0.0, 0.16999999999999998),
                Vector(0.9349999999999999, 0.0, 0.16999999999999998),
            ],
            [
                Vector(0.95, offset, 0.13999999999999999),
                Vector(1.086, 0.0, 0.13999999999999999),
                Vector(0.9349999999999999, 0.0, 0.16999999999999998),
            ],
            [
                Vector(0.9349999999999999, 0.0, 0.16999999999999998),
                Vector(0.9349999999999999, 0.0, 0.09999999999999999),
                Vector(0.95, offset, 0.13999999999999999),
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
        let normal = Vector(0, 0, -1)
        let polygon = Polygon(unchecked: [
            Vertex(Vector(0, 0), normal),
            Vertex(Vector(0.5, 0), normal),
            Vertex(Vector(0.5, 1), normal),
            Vertex(Vector(-0.5, 1), normal),
            Vertex(Vector(-0.5, 0), normal),
        ])
        let triangles = polygon.triangulate()
        XCTAssertEqual(triangles.count, 3)
        let result = triangles.detessellate()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.vertices.count, 4)
        XCTAssertEqual(result.first?.undirectedEdges.count, 4)
    }

    func testHouseShapedPolygonCorrectlyDetessellated() {
        let normal = Vector(0, 0, -1)
        let polygon = Polygon(unchecked: [
            Vertex(Vector(0, 0.5), normal),
            Vertex(Vector(1, 0), normal),
            Vertex(Vector(0.5, 0), normal),
            Vertex(Vector(0.5, -1), normal),
            Vertex(Vector(-0.5, -1), normal),
            Vertex(Vector(-0.5, 0), normal),
            Vertex(Vector(-1, 0), normal),
        ])
        let triangles = polygon.triangulate()
        XCTAssertEqual(triangles.count, 5)
        let result = triangles.detessellate()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.undirectedEdges, polygon.undirectedEdges)
        XCTAssertEqual(Set(result.first?.vertices ?? []), Set(polygon.vertices))
    }

    func testNonWatertightPolygonsCorrectlyDetessellated() {
        let normal = Vector(0, 0, -1)
        let triangles = [
            Polygon(unchecked: [
                Vertex(Vector(0, -1), normal),
                Vertex(Vector(-2, 0), normal),
                Vertex(Vector(2, 0), normal),
            ]),
            Polygon(unchecked: [
                Vertex(Vector(-2, 0), normal),
                Vertex(Vector(0, 1), normal),
                Vertex(Vector(0, 0), normal),
            ]),
            Polygon(unchecked: [
                Vertex(Vector(2, 0), normal),
                Vertex(Vector(0, 0), normal),
                Vertex(Vector(0, 1), normal),
            ]),
        ]
        let result = triangles.detessellate()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result, [
            Polygon(unchecked: [
                Vertex(Vector(0, -1), normal),
                Vertex(Vector(-2, 0), normal),
                Vertex(Vector(0, 1), normal),
                Vertex(Vector(2, 0), normal),
            ]),
        ])
    }

    // MARK: uniqueEdges

    func testUniqueEdgesForCube() {
        let mesh = Mesh.cube()
        let edges = mesh.uniqueEdges
        XCTAssertEqual(edges.count, 12)
    }

    func testUniqueEdgesForSphere() {
        let mesh = Mesh.sphere(slices: 4)
        let edges = Array(mesh.uniqueEdges)
        XCTAssertEqual(edges.count, 12)
    }

    // MARK: isWatertight

    func testCubeIsWatertight() {
        let mesh = Mesh.cube()
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
    }

    func testSphereIsWatertight() {
        let mesh = Mesh.sphere()
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
    }

    func testLatheIsWatertight() {
        let mesh = Mesh.lathe(.circle())
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
    }

    func testDoubleSidedFaceIsWatertight() {
        let mesh = Mesh.fill(.square())
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
    }

    func testSingleSidedFaceIsNotWatertight() {
        let mesh = Mesh.fill(.square(), faces: .front)
        XCTAssertFalse(mesh.isWatertight)
        XCTAssertFalse(mesh.polygons.areWatertight)
    }

    func testOpenShapeExtrusionIsWatertight() {
        let path = Path([.point(0, 0), .point(1, 0), .point(1, 1), .point(0, 1)])
        let mesh = Mesh.extrude(path)
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
    }

    func testSingleSidedOpenShapeExtrusionIsNotWatertight() {
        let path = Path([.point(0, 0), .point(1, 0), .point(1, 1), .point(0, 1)])
        let mesh = Mesh.extrude(path, faces: .front)
        XCTAssertFalse(mesh.isWatertight)
        XCTAssertFalse(mesh.polygons.areWatertight)
    }
}
