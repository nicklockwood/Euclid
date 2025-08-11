//
//  PolygonTests.swift
//  GeometryScriptTests
//
//  Created by Nick Lockwood on 19/09/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

class PolygonTests: XCTestCase {
    // MARK: initialization

    func testConvexPolygonAnticlockwiseWinding() {
        let normal = Vector.unitZ
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
        let normal = -Vector.unitZ
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
        let normal = Vector.unitZ
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
        let normal = -Vector.unitZ
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

    func testDegeneratePolygonWithCollinearPoints() {
        let normal = Vector.unitZ
        XCTAssertNil(Polygon([
            Vertex(Vector(0, 1), normal),
            Vertex(Vector(0, 0), normal),
            Vertex(Vector(0, -2), normal),
        ]))
    }

    func testNonDegeneratePolygonWithCollinearPoints() {
        let normal = Vector.unitZ
        XCTAssertNotNil(Polygon([
            Vertex(Vector(0, 1), normal),
            Vertex(Vector(0, 0), normal),
            Vertex(Vector(0, -2), normal),
            Vertex(Vector(1.5, -1), normal),
        ]))
    }

    func testDegeneratePolygonWithSelfIntersectingPoints() {
        let normal = Vector.unitZ
        XCTAssertNil(Polygon([
            Vertex(Vector(0, 0), normal),
            Vertex(Vector(1, 1), normal),
            Vertex(Vector(1, 0), normal),
            Vertex(Vector(0, 1), normal),
        ]))
    }

    func testPolygonWithOnlyTwoPoints() {
        let normal = Vector.unitZ
        XCTAssertNil(Polygon([
            Vertex(Vector(-1, 1), normal),
            Vertex(Vector(-1, -1), normal),
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
        let normal = Vector.unitZ
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
        let normal = Vector.unitZ
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
        let normal = Vector.unitZ
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
        let normal = Vector.unitZ
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
        let normal = Vector.unitZ
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
        let normal = Vector.unitZ
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
        let normal = Vector.unitZ
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
        let normal = Vector.unitZ
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
        XCTAssertTrue(polygon.intersects(Vector(0, 0)))
        XCTAssertTrue(polygon.intersects(Vector(-0.999, 0.999)))
        XCTAssertTrue(polygon.intersects(Vector(0.999, 0.999)))
        XCTAssertTrue(polygon.intersects(Vector(0.999, -0.999)))
        XCTAssertTrue(polygon.intersects(Vector(-0.999, -0.999)))
        XCTAssertFalse(polygon.intersects(Vector(-1.001, 0)))
        XCTAssertFalse(polygon.intersects(Vector(1.001, 0)))
        XCTAssertFalse(polygon.intersects(Vector(0, -1.001)))
        XCTAssertFalse(polygon.intersects(Vector(0, 1.001)))
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
        XCTAssertTrue(polygon.intersects(Vector(0, 0)))
        XCTAssertTrue(polygon.intersects(Vector(-0.999, 0.999)))
        XCTAssertTrue(polygon.intersects(Vector(0.999, 0.999)))
        XCTAssertTrue(polygon.intersects(Vector(0.999, -0.999)))
        XCTAssertTrue(polygon.intersects(Vector(-0.999, -0.999)))
        XCTAssertFalse(polygon.intersects(Vector(-1.001, 0)))
        XCTAssertFalse(polygon.intersects(Vector(1.001, 0)))
        XCTAssertFalse(polygon.intersects(Vector(0, -1.001)))
        XCTAssertFalse(polygon.intersects(Vector(0, 1.001)))
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
        XCTAssertTrue(polygon.intersects(Vector(-0.5, 0.5)))
        XCTAssertTrue(polygon.intersects(Vector(0.5, 0.5)))
        XCTAssertFalse(polygon.intersects(Vector(-0.5, -0.5)))
        XCTAssertTrue(polygon.intersects(Vector(0.5, -0.5)))
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
        XCTAssertTrue(polygon.intersects(Vector(0.75, 0)))
        XCTAssertFalse(polygon.intersects(Vector(0.25, 0)))
        XCTAssertFalse(polygon.intersects(Vector(0.25, 0.25)))
        XCTAssertFalse(polygon.intersects(Vector(0.25, -0.25)))
        XCTAssertTrue(polygon.intersects(Vector(0.25, 0.5)))
        XCTAssertTrue(polygon.intersects(Vector(0.25, -0.5)))
    }

    // MARK: merging

    func testMergingVerticesCrash() throws {
        let polygon = try XCTUnwrap(Polygon([
            Vector(0.01478207252, 0.006122934918, 0.04),
            Vector(0.014782086265, 0.006122896504, 0.04),
            Vector(0.01478208, 0.006122928, 0.04),
            Vector(0.014782069226, 0.0061229441239999995, 0.04),
        ]))
        XCTAssert([polygon].mergingVertices(withPrecision: 1e-7).isEmpty)
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

    func testPolygonWithCollinearPointsCorrectlyTriangulated() {
        let normal = -Vector.unitZ
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
        var triangles = polygon.triangulate()
        XCTAssertEqual(triangles.count, 3)
        triangles = polygon.inverted().triangulate()
        XCTAssertEqual(triangles.count, 3)
    }

    func testPolygonWithCollinearPointsCorrectlyTriangulated2() {
        guard let polygon = Polygon([
            Vector(0.461939766256, 0.191341716182, -0.25),
            Vector(0.441341716184, 0.294895106774, -0.25),
            Vector(0.417044659481, 0.417044659481, -0.25),
            Vector(0.576640741219, 0.385299025038, -0.25),
            Vector(0.5, -0.0, -0.25),
        ]) else {
            XCTFail()
            return
        }
        var triangles = polygon.triangulate()
        XCTAssertEqual(triangles.count, 3)
        triangles = polygon.inverted().triangulate()
        XCTAssertEqual(triangles.count, 3)
    }

    func testPolygonWithCollinearPointsCorrectlyTriangulated3() throws {
        var vertices = [
            Vector(0.4912109375, -0.071044921875),
            Vector(0.4248046875, 0.02783203125),
            Vector(0.4248046875, 0.0869140625),
            Vector(0.4248046875, 0.39599609375),
        ]
        for _ in 0 ..< vertices.count {
            vertices.append(vertices.removeFirst())
            let polygon = try XCTUnwrap(Polygon(vertices))
            var triangles = polygon.triangulate()
            XCTAssertEqual(triangles.count, 2)
            triangles = polygon.inverted().triangulate()
            XCTAssertEqual(triangles.count, 2)
        }
    }

    func testPolygonWithCollinearPointsCorrectlyTriangulated4() throws {
        var vertices: [Vector] = [
            Vector(-0.091920812939, 0.5, -0.091920812941),
            Vector(-0.072221719299, 0.5, -0.10808744129),
            Vector(0.014089758474, 0.5, -0.178921440503),
            Vector(0.24759816005399998, 0.5, -0.370556833159),
            Vector(0.163974489221, 0.5, -0.47245257089299997),
            Vector(0.050896473764, 0.5, -0.509193845326),
            Vector(-0.23482898783199999, 0.5, 0.025360895229),
        ]
        for _ in 0 ..< vertices.count {
            vertices.append(vertices.removeFirst())
            let polygon = try XCTUnwrap(Polygon(vertices))
            var triangles = polygon.triangulate()
            XCTAssertEqual(triangles.count, 5)
            triangles = polygon.inverted().triangulate()
            XCTAssertEqual(triangles.count, 5)
        }
    }

    func testPolygonWithCollinearPointsCorrectlyTriangulated5() throws {
        var vertices: [Vector] = [
            Vector(0.536172689719, -0.15625, -0.306628888565),
            Vector(0.535144390949, -0.15625, -0.297143965055),
            Vector(0.534721324944, -0.15625, -0.293241647158),
            Vector(0.534352794426, -0.15625, -0.289842359053),
            Vector(0.535684230911, -0.160917677273, -0.295354331759),
            Vector(0.535839598175, -0.160870260488, -0.296856187422),
            Vector(0.536427908063, -0.160690713247, -0.302543077416),
            Vector(0.550978482581, -0.15625, -0.443196019538),
        ]
        for _ in 0 ..< vertices.count {
            vertices.append(vertices.removeFirst())
            let polygon = try XCTUnwrap(Polygon(vertices))
            var triangles = polygon.triangulate()
            XCTAssertEqual(triangles.count, 6)
            triangles = polygon.inverted().triangulate()
            XCTAssertEqual(triangles.count, 6)
        }
    }

    func testHouseShapedPolygonCorrectlyTriangulated() {
        let normal = -Vector.unitZ
        let epsilon = 1e-8
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
        XCTAssertEqual(triangles.count, 5)
    }

    func testPathWithZeroAreaCollinearPointTriangulated() {
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
        let offset = epsilon / 20
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
        let offset = epsilon / 40
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
                Vector(0.9349999999999999, 0.0, 0.16999999999999998),
                Vector(0.9349999999999999, 0.0, 0.09999999999999999),
                Vector(0.95, offset, 0.13999999999999999),
            ],
            [
                Vector(0.9349999999999999, 0.0, 0.16999999999999998),
                Vector(0.95, offset, 0.13999999999999999),
                Vector(1.086, 0.0, 0.13999999999999999),
            ],
            [
                Vector(0.9349999999999999, 0.0, 0.16999999999999998),
                Vector(1.086, 0.0, 0.13999999999999999),
                Vector(1.086, 0.0, 0.16999999999999998),
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
        guard let polygon = Polygon(shape: path)?.withID(5) else {
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
        guard let polygon = Polygon(shape: path)?.withID(5) else {
            XCTFail()
            return
        }
        let polygons = polygon.tessellate()
        XCTAssert(polygons.allSatisfy { $0.id == 5 })
    }

    func testComplexCharacterPathTriangulated() {
        #if canImport(CoreText)
        let font = CTFontCreateWithName("Courier" as CFString, 2, nil)
        let paths = Path.text("p", font: font, width: nil, detail: 2)
        for path in paths.flatMap({ $0.subpaths }) {
            XCTAssertFalse(path.facePolygons().triangulate().isEmpty)
        }
        #endif
    }

    func testComplexCharacterPathTriangulated2() {
        #if canImport(CoreText)
        let font = CTFontCreateWithName("Courier" as CFString, 2, nil)
        let paths = Path.text("n", font: font, width: nil, detail: 2)
        for path in paths.flatMap({ $0.subpaths }) {
            XCTAssertFalse(path.facePolygons().triangulate().isEmpty)
        }
        #endif
    }

    func testComplexCharacterPathTriangulated3() {
        #if canImport(CoreText)
        let font = CTFontCreateWithName("Times" as CFString, 2, nil)
        let paths = Path.text("H", font: font, width: nil, detail: 2)
        for path in paths.flatMap({ $0.subpaths }) {
            XCTAssertFalse(path.facePolygons().triangulate().isEmpty)
        }
        #endif
    }

    // MARK: edges

    func testOrderedEdges() {
        let circle = Polygon(shape: .circle())!
        let edges = circle.orderedEdges
        XCTAssertEqual(edges.count, circle.vertices.count)
        var u = circle.vertices.last!
        for (e, v) in zip(edges, circle.vertices) {
            XCTAssertEqual(e.start, u.position)
            XCTAssertEqual(e.end, v.position)
            u = v
        }
    }

    func testUndirectedEdges() {
        let circle = Polygon(shape: .circle())!
        let orderedEdges = circle.orderedEdges
        let undirectedEdges = circle.undirectedEdges
        XCTAssertEqual(orderedEdges.count, undirectedEdges.count)
        for edge in orderedEdges {
            let undirected = LineSegment(undirected: edge)
            XCTAssert(undirectedEdges.contains(undirected))
        }
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

    func testPolygonWithCollinearPointsCorrectlyDetessellated() {
        let normal = -Vector.unitZ
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
        let normal = -Vector.unitZ
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
        let normal = -Vector.unitZ
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

    // MARK: area

    func testAreaOfClockwiseSquare() {
        let polygon = Polygon(unchecked: [
            Vector(0, 0),
            Vector(0, 1),
            Vector(1, 1),
            Vector(1, 0),
        ])
        XCTAssertEqual(polygon.area, 1)
    }

    func testAreaOfAnticlockwiseSquare() {
        let polygon = Polygon(unchecked: [
            Vector(0, 0),
            Vector(0, -1),
            Vector(1, -1),
            Vector(1, 0),
        ])
        XCTAssertEqual(polygon.area, 1)
    }

    func testAreaOfAnticlockwiseTriangle() {
        let polygon = Polygon(unchecked: [
            Vector(0, 0),
            Vector(0, -1),
            Vector(1, 0),
        ])
        XCTAssertEqual(polygon.area, 0.5)
    }

    func testAreaOfAnticlockwiseTrapezium() {
        let polygon = Polygon(unchecked: [
            Vector(0, 0),
            Vector(-1, -1),
            Vector(2, -1),
            Vector(1, 0),
        ])
        XCTAssertEqual(polygon.area, 2)
    }

    func testAreaOfLShapedClockwisePolygon() {
        let polygon = Polygon(unchecked: [
            Vector(0, 0),
            Vector(0, 2),
            Vector(1, 2),
            Vector(1, 1),
            Vector(2, 1),
            Vector(2, 0),
        ])
        XCTAssertEqual(polygon.area, 3)
    }

    func testAreaOfRotatedAnticlockwiseSquare() {
        for _ in 0 ..< 10 {
            guard let rotation = Rotation(
                axis: Vector(
                    .random(in: -1 ... 1),
                    .random(in: -1 ... 1),
                    .random(in: -1 ... 1)
                ),
                angle: .radians(.random(in: 0 ..< .pi * 2))
            ) else {
                continue
            }
            let polygon = Polygon(unchecked: [
                Vector(0, 0),
                Vector(0, -1),
                Vector(1, -1),
                Vector(1, 0),
            ]).rotated(by: rotation)
            XCTAssertEqual(polygon.area, 1, accuracy: epsilon)
        }
    }

    func testAreaOfFlatClockwiseSquareNotAtOrigin() {
        let polygon = Polygon(unchecked: [
            Vector(0, 0, 1),
            Vector(0, 1, 1),
            Vector(1, 1, 1),
            Vector(1, 0, 1),
        ])
        XCTAssertEqual(polygon.area, 1)
    }

    func testAreaOfRotatedAnticlockwiseSquareNotAtOrigin() {
        for _ in 0 ..< 10 {
            guard let rotation = Rotation(
                axis: Vector(
                    .random(in: -1 ... 1),
                    .random(in: -1 ... 1),
                    .random(in: -1 ... 1)
                ),
                angle: .radians(.random(in: 0 ..< .pi * 2))
            ) else {
                continue
            }
            let polygon = Polygon(unchecked: [
                Vector(0, 0, 1),
                Vector(0, -1, 1),
                Vector(1, -1, 1),
                Vector(1, 0, 1),
            ]).rotated(by: rotation)
            XCTAssertEqual(polygon.area, 1, accuracy: epsilon)
        }
    }

    // MARK: convexity

    func testIsConvexSensitivity() {
        let polygon = Polygon(unchecked: [
            .init(0.40000000596, 0.930000000033, -0.861614254425),
            .init(0.40000000596, 0.9846769873219999, -0.851245050793),
            .init(0.40000000596, 0.988997202611, -0.882256885056),
            .init(0.40000000596, 0.964728613386, -0.898573349831),
            .init(0.40000000596, 0.954697109253, -0.9053178162),
            .init(0.40000000596, 0.934058296138, -0.919195077007),
            .init(0.40000000596, 0.898350019175, -0.8676164559389999),
        ])
        XCTAssert(polygon.isConvex)
    }

    // MARK: inset

    func testInsetSquare() {
        let polygon = Polygon(unchecked: [
            Vector(-1, 1),
            Vector(-1, -1),
            Vector(1, -1),
            Vector(1, 1),
        ])
        let expected = Polygon(unchecked: [
            Vector(-0.75, 0.75),
            Vector(-0.75, -0.75),
            Vector(0.75, -0.75),
            Vector(0.75, 0.75),
        ])
        let result = polygon.inset(by: 0.25)
        XCTAssertEqual(result, expected)
    }

    func testInsetLShape() {
        let polygon = Polygon(unchecked: [
            Vector(0, 0),
            Vector(0, 2),
            Vector(1, 2),
            Vector(1, 1),
            Vector(2, 1),
            Vector(2, 0),
        ])
        let expected = Polygon(unchecked: [
            Vector(0.25, 0.25),
            Vector(0.25, 1.75),
            Vector(0.75, 1.75),
            Vector(0.75, 0.75),
            Vector(1.75, 0.75),
            Vector(1.75, 0.25),
        ])
        let result = polygon.inset(by: 0.25)
        XCTAssertEqual(result, expected)
    }
}
