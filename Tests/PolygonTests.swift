//
//  PolygonTests.swift
//  GeometryScriptTests
//
//  Created by Nick Lockwood on 19/09/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

private extension Collection<Euclid.Polygon> {
    func detessellate() -> [Euclid.Polygon] {
        detessellate(ensureConvex: false)
    }
}

final class PolygonTests: XCTestCase {
    // MARK: initialization

    func testConvexPolygonAnticlockwiseWinding() {
        let normal = Vector.unitZ
        guard let polygon = Polygon([
            Vertex(-1, 1, normal: normal),
            Vertex(-1, -1, normal: normal),
            Vertex(1, -1, normal: normal),
            Vertex(1, 1, normal: normal),
        ]) else {
            XCTFail()
            return
        }
        XCTAssertEqual(polygon.plane.normal, normal)
    }

    func testConvexPolygonClockwiseWinding() {
        let normal = -Vector.unitZ
        guard let polygon = Polygon([
            Vertex(-1, -1, normal: normal),
            Vertex(-1, 1, normal: normal),
            Vertex(1, 1, normal: normal),
            Vertex(1, -1, normal: normal),
        ]) else {
            XCTFail()
            return
        }
        XCTAssertEqual(polygon.plane.normal, normal)
    }

    func testConcavePolygonAnticlockwiseWinding() {
        let normal = Vector.unitZ
        guard let polygon = Polygon([
            Vertex(-1, 0, normal: normal),
            Vertex(0, 0, normal: normal),
            Vertex(0, -1, normal: normal),
            Vertex(1, -1, normal: normal),
            Vertex(1, 1, normal: normal),
            Vertex(-1, 1, normal: normal),
        ]) else {
            XCTFail()
            return
        }
        XCTAssertEqual(polygon.plane.normal, normal)
    }

    func testConcavePolygonClockwiseWinding() {
        let normal = -Vector.unitZ
        guard let polygon = Polygon([
            Vertex(-1, 0, normal: normal),
            Vertex(0, 0, normal: normal),
            Vertex(0, 1, normal: normal),
            Vertex(1, 1, normal: normal),
            Vertex(1, -1, normal: normal),
            Vertex(-1, -1, normal: normal),
        ]) else {
            XCTFail()
            return
        }
        XCTAssertEqual(polygon.plane.normal, normal)
    }

    func testDegeneratePolygonWithCollinearPoints() {
        let normal = Vector.unitZ
        XCTAssertNil(Polygon([
            Vertex(0, 1, normal: normal),
            Vertex(0, 0, normal: normal),
            Vertex(0, -2, normal: normal),
        ]))
    }

    func testDegeneratePolygonWithCollinearPoints2() {
        let polygon = Polygon([
            [1.08491958885, 1.03, 1.9987],
            [1.08018965849, 1.03, 1.9987],
            [1.07600466518, 1.03, 1.9987],
        ])
        XCTAssertNil(polygon)
    }

    func testNonDegeneratePolygonWithCollinearPoints() {
        let normal = Vector.unitZ
        XCTAssertNotNil(Polygon([
            Vertex(0, 1, normal: normal),
            Vertex(0, 0, normal: normal),
            Vertex(0, -2, normal: normal),
            Vertex(1.5, -1, normal: normal),
        ]))
    }

    func testDegeneratePolygonWithSelfIntersectingPoints() {
        let normal = Vector.unitZ
        XCTAssertNil(Polygon([
            Vertex(0, 0, normal: normal),
            Vertex(1, 1, normal: normal),
            Vertex(1, 0, normal: normal),
            Vertex(0, 1, normal: normal),
        ]))
    }

    func testPolygonWithOnlyTwoPoints() {
        let normal = Vector.unitZ
        XCTAssertNil(Polygon([
            Vertex(-1, 1, normal: normal),
            Vertex(-1, -1, normal: normal),
        ]))
    }

    func testZeroNormals() {
        guard let polygon = Polygon([
            Vertex(-1, 1, normal: .zero),
            Vertex(-1, -1, normal: .zero),
            Vertex(1, -1, normal: .zero),
            Vertex(1, 1, normal: .zero),
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
            [-1, 1],
            [-1, -1],
            [1, -1],
            [1, 1],
        ]) else {
            XCTFail()
            return
        }
        XCTAssert(polygon.vertices.allSatisfy {
            $0.normal == polygon.plane.normal
        })
    }

    // MARK: intersects point

    func testConvexAnticlockwisePolygonContainsPoint() {
        let path = Path([
            .point(-1, 1),
            .point(-1, -1),
            .point(1, -1),
            .point(1, 1),
            .point(-1, 1),
        ])
        guard let polygon = Polygon(path) else {
            XCTFail()
            return
        }
        XCTAssertTrue(polygon.intersects([0, 0]))
        XCTAssertTrue(polygon.intersects([-0.999, 0.999]))
        XCTAssertTrue(polygon.intersects([0.999, 0.999]))
        XCTAssertTrue(polygon.intersects([0.999, -0.999]))
        XCTAssertTrue(polygon.intersects([-0.999, -0.999]))
        XCTAssertFalse(polygon.intersects([-1.001, 0]))
        XCTAssertFalse(polygon.intersects([1.001, 0]))
        XCTAssertFalse(polygon.intersects([0, -1.001]))
        XCTAssertFalse(polygon.intersects([0, 1.001]))
    }

    func testConvexClockwisePolygonContainsPoint() {
        let path = Path([
            .point(-1, -1),
            .point(-1, 1),
            .point(1, 1),
            .point(1, -1),
            .point(-1, -1),
        ])
        guard let polygon = Polygon(path) else {
            XCTFail()
            return
        }
        XCTAssertTrue(polygon.intersects([0, 0]))
        XCTAssertTrue(polygon.intersects([-0.999, 0.999]))
        XCTAssertTrue(polygon.intersects([0.999, 0.999]))
        XCTAssertTrue(polygon.intersects([0.999, -0.999]))
        XCTAssertTrue(polygon.intersects([-0.999, -0.999]))
        XCTAssertFalse(polygon.intersects([-1.001, 0]))
        XCTAssertFalse(polygon.intersects([1.001, 0]))
        XCTAssertFalse(polygon.intersects([0, -1.001]))
        XCTAssertFalse(polygon.intersects([0, 1.001]))
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
        guard let polygon = Polygon(path) else {
            XCTFail()
            return
        }
        XCTAssertTrue(polygon.intersects([-0.5, 0.5]))
        XCTAssertTrue(polygon.intersects([0.5, 0.5]))
        XCTAssertFalse(polygon.intersects([-0.5, -0.5]))
        XCTAssertTrue(polygon.intersects([0.5, -0.5]))
    }

    func testConcaveAnticlockwisePolygonContainsPoint2() {
        let path = Path([
            .point(0, 1),
            .point(0.5, 0),
            .point(0, -1),
            .point(1, 0),
            .point(0, 1),
        ])
        guard let polygon = Polygon(path) else {
            XCTFail()
            return
        }
        XCTAssertTrue(polygon.intersects([0.75, 0]))
        XCTAssertFalse(polygon.intersects([0.25, 0]))
        XCTAssertFalse(polygon.intersects([0.25, 0.25]))
        XCTAssertFalse(polygon.intersects([0.25, -0.25]))
        XCTAssertTrue(polygon.intersects([0.25, 0.5]))
        XCTAssertTrue(polygon.intersects([0.25, -0.5]))
    }

    // MARK: merging

    func testMerge1() {
        let normal = Vector.unitZ
        let a = Polygon(unchecked: [
            Vertex(0, 1, normal: normal),
            Vertex(0, 0, normal: normal),
            Vertex(1, 1, normal: normal),
        ])
        let b = Polygon(unchecked: [
            Vertex(1, 1, normal: normal),
            Vertex(0, 0, normal: normal),
            Vertex(1, 0, normal: normal),
        ])
        let c = Polygon(unchecked: [
            Vertex(0, 1, normal: normal),
            Vertex(0, 0, normal: normal),
            Vertex(1, 0, normal: normal),
            Vertex(1, 1, normal: normal),
        ])
        XCTAssertEqual(a.merge(b), c)
    }

    func testMerge2() {
        let normal = Vector.unitZ
        let a = Polygon(unchecked: [
            Vertex(0, 1, normal: normal),
            Vertex(1, 0, normal: normal),
            Vertex(1, 1, normal: normal),
        ])
        let b = Polygon(unchecked: [
            Vertex(2, 1, normal: normal),
            Vertex(1, 1, normal: normal),
            Vertex(1, 0, normal: normal),
        ])
        let c = Polygon(unchecked: [
            Vertex(0, 1, normal: normal),
            Vertex(1, 0, normal: normal),
            Vertex(2, 1, normal: normal),
        ])
        XCTAssertEqual(a.merge(b), c)
    }

    func testMergeL2RAdjacentRects() {
        let normal = Vector.unitZ
        let a = Polygon(unchecked: [
            Vertex(-1, 1, normal: normal),
            Vertex(-1, -1, normal: normal),
            Vertex(0, -1, normal: normal),
            Vertex(0, 1, normal: normal),
        ])
        let b = Polygon(unchecked: [
            Vertex(0, 1, normal: normal),
            Vertex(0, -1, normal: normal),
            Vertex(1, -1, normal: normal),
            Vertex(1, 1, normal: normal),
        ])
        guard let c = a.merge(b) else {
            XCTFail()
            return
        }
        XCTAssertEqual(c, Polygon(unchecked: [
            Vertex(-1, 1, normal: normal),
            Vertex(-1, -1, normal: normal),
            Vertex(1, -1, normal: normal),
            Vertex(1, 1, normal: normal),
        ]))
    }

    func testMergeR2LAdjacentRects() {
        let normal = Vector.unitZ
        let a = Polygon(unchecked: [
            Vertex(0, 1, normal: normal),
            Vertex(0, -1, normal: normal),
            Vertex(1, -1, normal: normal),
            Vertex(1, 1, normal: normal),
        ])
        let b = Polygon(unchecked: [
            Vertex(-1, 1, normal: normal),
            Vertex(-1, -1, normal: normal),
            Vertex(0, -1, normal: normal),
            Vertex(0, 1, normal: normal),
        ])
        guard let c = a.merge(b) else {
            XCTFail()
            return
        }
        XCTAssertEqual(c, Polygon(unchecked: [
            Vertex(1, -1, normal: normal),
            Vertex(1, 1, normal: normal),
            Vertex(-1, 1, normal: normal),
            Vertex(-1, -1, normal: normal),
        ]))
    }

    func testMergeB2TAdjacentRects() {
        let normal = Vector.unitZ
        let a = Polygon(unchecked: [
            Vertex(-1, 0, normal: normal),
            Vertex(-1, -1, normal: normal),
            Vertex(1, -1, normal: normal),
            Vertex(1, 0, normal: normal),
        ])
        let b = Polygon(unchecked: [
            Vertex(-1, 1, normal: normal),
            Vertex(-1, 0, normal: normal),
            Vertex(1, 0, normal: normal),
            Vertex(1, 1, normal: normal),
        ])
        guard let c = a.merge(b) else {
            XCTFail()
            return
        }
        XCTAssertEqual(c, Polygon(unchecked: [
            Vertex(-1, -1, normal: normal),
            Vertex(1, -1, normal: normal),
            Vertex(1, 1, normal: normal),
            Vertex(-1, 1, normal: normal),
        ]))
    }

    func testMergeT2BAdjacentRects() {
        let normal = Vector.unitZ
        let a = Polygon(unchecked: [
            Vertex(-1, 1, normal: normal),
            Vertex(-1, 0, normal: normal),
            Vertex(1, 0, normal: normal),
            Vertex(1, 1, normal: normal),
        ])
        let b = Polygon(unchecked: [
            Vertex(-1, 0, normal: normal),
            Vertex(-1, -1, normal: normal),
            Vertex(1, -1, normal: normal),
            Vertex(1, 0, normal: normal),
        ])
        guard let c = a.merge(b) else {
            XCTFail()
            return
        }
        XCTAssertEqual(c, Polygon(unchecked: [
            Vertex(1, 1, normal: normal),
            Vertex(-1, 1, normal: normal),
            Vertex(-1, -1, normal: normal),
            Vertex(1, -1, normal: normal),
        ]))
    }

    func testMergeL2RAdjacentRectAndTriangle() {
        let normal = Vector.unitZ
        let a = Polygon(unchecked: [
            Vertex(-1, 1, normal: normal),
            Vertex(-1, -1, normal: normal),
            Vertex(0, -1, normal: normal),
            Vertex(0, 1, normal: normal),
        ])
        let b = Polygon(unchecked: [
            Vertex(0, 1, normal: normal),
            Vertex(0, -1, normal: normal),
            Vertex(1, 1, normal: normal),
        ])
        guard let c = a.merge(b) else {
            XCTFail()
            return
        }
        XCTAssertEqual(c, Polygon(unchecked: [
            Vertex(-1, 1, normal: normal),
            Vertex(-1, -1, normal: normal),
            Vertex(0, -1, normal: normal),
            Vertex(1, 1, normal: normal),
        ]))
    }

    func testMergeEdgeCase() {
        let normal = Vector.unitZ
        let a = Polygon(unchecked: [
            Vertex(-0.02, 0.8, normal: normal),
            Vertex(0.7028203230300001, 0.38267949192000006, normal: normal),
            Vertex(0.7028203230300001, -0.38267949192000006, normal: normal),
        ])
        let b = Polygon(unchecked: [
            Vertex(0.7028203230300001, -0.38267949192000006, normal: normal),
            Vertex(-0.02, -0.8, normal: normal),
            Vertex(-0.6828203230300001, -0.41732050808000004, normal: normal),
            Vertex(-0.6828203230300001, 0.41732050808000004, normal: normal),
            Vertex(-0.02, 0.8, normal: normal),
        ])
        let c = Polygon(unchecked: [
            Vertex(0.7028203230300001, 0.38267949192000006, normal: normal),
            Vertex(0.7028203230300001, -0.38267949192000006, normal: normal),
            Vertex(-0.02, -0.8, normal: normal),
            Vertex(-0.6828203230300001, -0.41732050808000004, normal: normal),
            Vertex(-0.6828203230300001, 0.41732050808000004, normal: normal),
            Vertex(-0.02, 0.8, normal: normal),
        ])
        XCTAssertEqual(a.merge(b), c)
    }

    // MARK: merging

    func testMergingVerticesCrash() throws {
        let polygon = try XCTUnwrap(Polygon([
            [0.01478207252, 0.006122934918, 0.04],
            [0.014782086265, 0.006122896504, 0.04],
            [0.01478208, 0.006122928, 0.04],
            [0.014782069226, 0.0061229441239999995, 0.04],
        ]))
        XCTAssert([polygon].mergingVertices(withPrecision: 1e-7).isEmpty)
    }

    func testMergingCubeWithModulatedFaces() {
        let threshold = 0.10778596717606788
        let polygons = Mesh.cube().polygons
        for _ in 0 ..< 10 {
            let modulated = polygons
                .transformed(by: .random())
                .map { $0.translated(by: .random(in: -threshold * 0.5 ... threshold * 0.5)) }
            XCTAssertEqual(modulated.count, polygons.count)
            let merged = modulated.mergingVertices(withPrecision: threshold)
            XCTAssert(merged.areWatertight)
            XCTAssertEqual(merged.count, polygons.count)
        }
    }

    func testMergingCubeWithModulatedVertices() {
        let threshold = 0.10778596717606788
        let polygons = Mesh.cube().polygons
        for _ in 0 ..< 10 {
            let modulated = polygons
                .transformed(by: .random())
                .mapVertices { $0.translated(by: .random(in: -threshold * 0.5 ... threshold * 0.5)) }
            XCTAssertGreaterThanOrEqual(modulated.count, polygons.count)
            let merged = modulated.mergingVertices(withPrecision: threshold)
            XCTAssert(merged.areWatertight)
            XCTAssertEqual(merged.count, modulated.count)
        }
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
        guard let polygon = Polygon(path) else {
            XCTFail()
            return
        }
        let polygons = polygon.tessellate()
        XCTAssertEqual(polygons.count, 2)
        guard polygons.count > 1 else {
            return
        }
        let a = Set(polygons[0].vertices.map(\.position))
        let expectedA = Set<Vector>([
            [0, 1],
            [0.5, 0],
            [1, 0],
        ])
        let b = Set(polygons[1].vertices.map(\.position))
        let expectedB = Set<Vector>([
            [0.5, 0],
            [1, 0],
            [0, -1],
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
        guard let polygon = Polygon(path)?.inverted() else {
            XCTFail()
            return
        }
        let polygons = polygon.tessellate()
        XCTAssertEqual(polygons.count, 2)
        guard polygons.count > 1 else {
            return
        }
        let a = Set(polygons[0].vertices.map(\.position))
        let expectedA = Set<Vector>([
            [0, 1],
            [1, 0],
            [0.5, 0],
        ])
        let b = Set(polygons[1].vertices.map(\.position))
        let expectedB = Set<Vector>([
            [0.5, 0],
            [1, 0],
            [0, -1],
        ])
        XCTAssert(a == expectedA || a == expectedB)
        XCTAssert(b == expectedA || b == expectedB)
    }

    func testCircleIsOptimallyTessellated() throws {
        let path = Path.circle(segments: 32)
        let polygon = try XCTUnwrap(Polygon(path))
        loop: for i in 3 ... 32 {
            let polygons = polygon.tessellate(maxSides: i)
            for polygon in polygons {
                XCTAssertLessThanOrEqual(polygon.vertices.count, i)
            }
            XCTAssertEqual(polygons.count, Int(ceil(30.0 / Double(i - 2))))
        }
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
        guard let polygon = Polygon(path) else {
            XCTFail()
            return
        }
        let triangles = polygon.triangulate()
        XCTAssertEqual(triangles.count, 2)
        guard triangles.count > 1 else {
            return
        }
        let a = Set(triangles[0].vertices.map(\.position))
        let expectedA = Set<Vector>([
            [0, 1],
            [0.5, 0],
            [1, 0],
        ])
        let b = Set(triangles[1].vertices.map(\.position))
        let expectedB = Set<Vector>([
            [0.5, 0],
            [1, 0],
            [0, -1],
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
        guard let polygon = Polygon(path)?.inverted() else {
            XCTFail()
            return
        }
        let triangles = polygon.triangulate()
        XCTAssertEqual(triangles.count, 2)
        guard triangles.count > 1 else {
            return
        }
        let a = Set(triangles[0].vertices.map(\.position))
        let expectedA = Set<Vector>([
            [0, 1],
            [1, 0],
            [0.5, 0],
        ])
        let b = Set(triangles[1].vertices.map(\.position))
        let expectedB = Set<Vector>([
            [0.5, 0],
            [1, 0],
            [0, -1],
        ])
        XCTAssert(a == expectedA || a == expectedB)
        XCTAssert(b == expectedA || b == expectedB)
    }

    func testPolygonWithCollinearPointsCorrectlyTriangulated() {
        let normal = -Vector.unitZ
        guard let polygon = Polygon([
            Vertex(0, 0, normal: normal),
            Vertex(0.5, 0, normal: normal),
            Vertex(0.5, 1, normal: normal),
            Vertex(-0.5, 1, normal: normal),
            Vertex(-0.5, 0, normal: normal),
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
            [0.461939766256, 0.191341716182, -0.25],
            [0.441341716184, 0.294895106774, -0.25],
            [0.417044659481, 0.417044659481, -0.25],
            [0.576640741219, 0.385299025038, -0.25],
            [0.5, -0.0, -0.25],
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
        var vertices: [Vector] = [
            [0.4912109375, -0.071044921875],
            [0.4248046875, 0.02783203125],
            [0.4248046875, 0.0869140625],
            [0.4248046875, 0.39599609375],
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
            [-0.091920812939, 0.5, -0.091920812941],
            [-0.072221719299, 0.5, -0.10808744129],
            [0.014089758474, 0.5, -0.178921440503],
            [0.24759816005399998, 0.5, -0.370556833159],
            [0.163974489221, 0.5, -0.47245257089299997],
            [0.050896473764, 0.5, -0.509193845326],
            [-0.23482898783199999, 0.5, 0.025360895229],
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
            [0.536172689719, -0.15625, -0.306628888565],
            [0.535144390949, -0.15625, -0.297143965055],
            [0.534721324944, -0.15625, -0.293241647158],
            [0.534352794426, -0.15625, -0.289842359053],
            [0.535684230911, -0.160917677273, -0.295354331759],
            [0.535839598175, -0.160870260488, -0.296856187422],
            [0.536427908063, -0.160690713247, -0.302543077416],
            [0.550978482581, -0.15625, -0.443196019538],
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
        guard let polygon = Polygon([
            Vertex(0, 0.5, normal: normal),
            Vertex(1, 0, normal: normal),
            Vertex(0.5, -epsilon, normal: normal),
            Vertex(0.5, -1, normal: normal),
            Vertex(-0.5, -1, normal: normal),
            Vertex(-0.5, -epsilon, normal: normal),
            Vertex(-1, 0, normal: normal),
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
        guard let polygon = Polygon(path) else {
            XCTFail()
            return
        }
        let triangles = polygon.triangulate()
        XCTAssertEqual(triangles.count, 3)
    }

    func testSlightlyNonPlanarPolygonTriangulated() {
        let offset = planeEpsilon
        let path = Path([
            .point(1.086, 0, 0.17),
            .point(1.086, 0, 0.14),
            .point(0.95, offset, 0.14),
            .point(0.935, 0, 0.1),
            .point(0.935, 0, 0.17),
            .point(1.086, 0, 0.17),
        ])
        guard let polygon = Polygon(path) else {
            XCTFail()
            return
        }
        let triangles = polygon.triangulate()
        XCTAssertEqual(triangles.count, 3)
        let points = triangles.map { $0.vertices.map(\.position) }
        XCTAssertEqual(points, [
            [
                [0.9349999999999999, 0.0, 0.16999999999999998],
                [1.086, 0.0, 0.16999999999999998],
                [1.086, 0.0, 0.13999999999999999],
            ],
            [
                [0.9349999999999999, 0.0, 0.16999999999999998],
                [1.086, 0.0, 0.13999999999999999],
                [0.95, offset, 0.13999999999999999],
            ],
            [
                [0.95, offset, 0.13999999999999999],
                [0.9349999999999999, 0.0, 0.09999999999999999],
                [0.9349999999999999, 0.0, 0.16999999999999998],
            ],
        ])
        let merged = triangles.detessellate()
        XCTAssertEqual(Set(merged.flatMap(\.vertices)), Set(polygon.vertices))
    }

    func testInvertedSlightlyNonPlanarPolygonTriangulated() {
        let offset = planeEpsilon
        let path = Path([
            .point(1.086, 0, 0.17),
            .point(1.086, 0, 0.14),
            .point(0.95, offset, 0.14),
            .point(0.935, 0, 0.1),
            .point(0.935, 0, 0.17),
            .point(1.086, 0, 0.17),
        ])
        guard let polygon = Polygon(path)?.inverted() else {
            XCTFail()
            return
        }
        let triangles = polygon.triangulate()
        XCTAssertEqual(triangles.count, 3)
        let points = triangles.map { $0.vertices.map(\.position) }
        XCTAssertEqual(points, [
            [
                [0.9349999999999999, 0.0, 0.16999999999999998],
                [0.9349999999999999, 0.0, 0.09999999999999999],
                [0.95, offset, 0.13999999999999999],
            ],
            [
                [0.9349999999999999, 0.0, 0.16999999999999998],
                [0.95, offset, 0.13999999999999999],
                [1.086, 0.0, 0.13999999999999999],
            ],
            [
                [0.9349999999999999, 0.0, 0.16999999999999998],
                [1.086, 0.0, 0.13999999999999999],
                [1.086, 0.0, 0.16999999999999998],
            ],
        ])
        let merged = triangles.detessellate()
        XCTAssertEqual(Set(merged.flatMap(\.vertices)), Set(polygon.vertices))
    }

    func testPolygonIDPreservedThroughTriangulation() {
        let path = Path([
            .point(0, 1),
            .point(0.5, 0),
            .point(0, -1),
            .point(1, 0),
            .point(0, 1),
        ])
        guard let polygon = Polygon(path)?.withID(5) else {
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
        guard let polygon = Polygon(path)?.withID(5) else {
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
        for path in paths.flatMap(\.subpaths) {
            XCTAssertFalse(path.facePolygons().triangulate().isEmpty)
        }
        #endif
    }

    func testComplexCharacterPathTriangulated2() {
        #if canImport(CoreText)
        let font = CTFontCreateWithName("Courier" as CFString, 2, nil)
        let paths = Path.text("n", font: font, width: nil, detail: 2)
        for path in paths.flatMap(\.subpaths) {
            XCTAssertFalse(path.facePolygons().triangulate().isEmpty)
        }
        #endif
    }

    func testComplexCharacterPathTriangulated3() {
        #if canImport(CoreText)
        let font = CTFontCreateWithName("Times" as CFString, 2, nil)
        let paths = Path.text("H", font: font, width: nil, detail: 2)
        for path in paths.flatMap(\.subpaths) {
            XCTAssertFalse(path.facePolygons().triangulate().isEmpty)
        }
        #endif
    }

    // MARK: edges

    func testOrderedEdges() throws {
        let circle = try XCTUnwrap(Polygon(.circle()))
        let edges = circle.orderedEdges
        XCTAssertEqual(edges.count, circle.vertices.count)
        var u = try XCTUnwrap(circle.vertices.last)
        for (e, v) in zip(edges, circle.vertices) {
            XCTAssertEqual(e.start, u.position)
            XCTAssertEqual(e.end, v.position)
            u = v
        }
    }

    func testUndirectedEdges() throws {
        let circle = try XCTUnwrap(Polygon(.circle()))
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
        guard let polygon = Polygon(path) else {
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
        guard let polygon = Polygon(path)?.inverted() else {
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
        let polygon = Polygon(unchecked: [
            [0, 0],
            [0.5, 0],
            [0.5, 1],
            [-0.5, 1],
            [-0.5, 0],
        ])
        let triangles = polygon.triangulate()
        XCTAssertEqual(triangles.count, 3)
        let result = triangles.detessellate()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.vertices.count, 4)
        XCTAssertEqual(result.first?.undirectedEdges.count, 4)
    }

    func testHouseShapedPolygonCorrectlyDetessellated() {
        let polygon = Polygon(unchecked: [
            [0, 0.5],
            [1, 0],
            [0.5, 0],
            [0.5, -1],
            [-0.5, -1],
            [-0.5, 0],
            [-1, 0],
        ])
        let triangles = polygon.triangulate()
        XCTAssertEqual(triangles.count, 5)
        let result = triangles.detessellate()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.undirectedEdges, polygon.undirectedEdges)
        XCTAssert(result.flatMap(\.vertices).allSatisfy { $0.normal == -.unitZ })
        XCTAssertEqual(Set(result.first?.vertices ?? []), Set(polygon.vertices))
    }

    func testNonWatertightPolygonsCorrectlyDetessellated() {
        let triangles = [
            Polygon(unchecked: [[0, -1], [-2, 0], [2, 0]]),
            Polygon(unchecked: [[-2, 0], [0, 1], [0, 0]]),
            Polygon(unchecked: [[2, 0], [0, 0], [0, 1]]),
        ]
        let result = triangles.detessellate()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result, [
            Polygon(unchecked: [[0, 1], [2, 0], [0, -1], [-2, 0]]),
        ])
    }

    func testDetessellateComplexCharacterPaths() {
        #if canImport(CoreText)
        let font = CTFontCreateWithName("Helvetica" as CFString, 2, nil)
        let paths = Path.text("eo", font: font, width: nil, detail: 2)
        let polygons = paths.flatMap {
            $0.subpaths.flatMap { $0.facePolygons() }
        }
        XCTAssertEqual(polygons.detessellate().count, 4)
        #endif
    }

    func testMergeRectsDoesntExceedMaxSides() {
        let normal = Vector.unitZ
        let a = Polygon(unchecked: [
            Vertex(-1, 1, normal: normal),
            Vertex(-1, 0, normal: normal),
            Vertex(1, 0, normal: normal),
            Vertex(1, 1, normal: normal),
        ])
        let b = Polygon(unchecked: [
            Vertex(-1, 0, normal: normal),
            Vertex(-1, -1, normal: normal),
            Vertex(1, -1, normal: normal),
            Vertex(1, 0, normal: normal),
        ])
        let c = [a, b].coplanarDetessellate(ensureConvex: true, maxSides: 4)
        XCTAssertEqual(c.count, 1)
        XCTAssertEqual(c.first?.vertices.count, 4)
    }

    // MARK: area

    func testAreaOfClockwiseSquare() {
        let polygon = Polygon(unchecked: [
            [0, 0],
            [0, 1],
            [1, 1],
            [1, 0],
        ])
        XCTAssertEqual(polygon.area, 1)
    }

    func testAreaOfAnticlockwiseSquare() {
        let polygon = Polygon(unchecked: [
            [0, 0],
            [0, -1],
            [1, -1],
            [1, 0],
        ])
        XCTAssertEqual(polygon.area, 1)
    }

    func testAreaOfAnticlockwiseTriangle() {
        let polygon = Polygon(unchecked: [
            [0, 0],
            [0, -1],
            [1, 0],
        ])
        XCTAssertEqual(polygon.area, 0.5)
    }

    func testAreaOfAnticlockwiseTrapezium() {
        let polygon = Polygon(unchecked: [
            [0, 0],
            [-1, -1],
            [2, -1],
            [1, 0],
        ])
        XCTAssertEqual(polygon.area, 2)
    }

    func testAreaOfLShapedClockwisePolygon() {
        let polygon = Polygon(unchecked: [
            [0, 0],
            [0, 2],
            [1, 2],
            [1, 1],
            [2, 1],
            [2, 0],
        ])
        XCTAssertEqual(polygon.area, 3)
    }

    func testAreaOfTransformedLShapedClockwisePolygon() {
        for _ in 0 ..< 10 {
            let polygon = Polygon(unchecked: [
                [0, 0],
                [0, 2],
                [1, 2],
                [1, 1],
                [2, 1],
                [2, 0],
            ]).transformed(by: .random())
            XCTAssertEqual(polygon.area, 3)
        }
    }

    func testAreaOfRotatedAnticlockwiseSquare() {
        for _ in 0 ..< 10 {
            let polygon = Polygon(unchecked: [
                [0, 0],
                [0, -1],
                [1, -1],
                [1, 0],
            ]).rotated(by: .random())
            XCTAssertEqual(polygon.area, 1)
        }
    }

    func testAreaOfFlatClockwiseSquareNotAtOrigin() {
        let polygon = Polygon(unchecked: [
            [0, 0, 1],
            [0, 1, 1],
            [1, 1, 1],
            [1, 0, 1],
        ])
        XCTAssertEqual(polygon.area, 1)
    }

    func testAreaOfRotatedAnticlockwiseSquareNotAtOrigin() {
        for _ in 0 ..< 10 {
            let polygon = Polygon(unchecked: [
                [0, 0, 1],
                [0, -1, 1],
                [1, -1, 1],
                [1, 0, 1],
            ]).transformed(by: .random())
            XCTAssertEqual(polygon.area, 1)
        }
    }

    // MARK: convexity

    func testIsConvexSensitivity() {
        let polygon = Polygon(unchecked: [
            [0.40000000596, 0.930000000033, -0.861614254425],
            [0.40000000596, 0.9846769873219999, -0.851245050793],
            [0.40000000596, 0.988997202611, -0.882256885056],
            [0.40000000596, 0.964728613386, -0.898573349831],
            [0.40000000596, 0.954697109253, -0.9053178162],
            [0.40000000596, 0.934058296138, -0.919195077007],
            [0.40000000596, 0.898350019175, -0.8676164559389999],
        ])
        XCTAssert(polygon.isConvex)
    }

    // MARK: inset

    func testInsetSquare() {
        let polygon = Polygon(unchecked: [
            [-1, 1],
            [-1, -1],
            [1, -1],
            [1, 1],
        ])
        let expected = Polygon(unchecked: [
            [-0.75, 0.75],
            [-0.75, -0.75],
            [0.75, -0.75],
            [0.75, 0.75],
        ])
        let result = polygon.inset(by: 0.25)
        XCTAssertEqual(result, expected)
    }

    func testInsetLShape() {
        let polygon = Polygon(unchecked: [
            [0, 0],
            [0, 2],
            [1, 2],
            [1, 1],
            [2, 1],
            [2, 0],
        ])
        let expected = Polygon(unchecked: [
            [0.25, 0.25],
            [0.25, 1.75],
            [0.75, 1.75],
            [0.75, 0.75],
            [1.75, 0.75],
            [1.75, 0.25],
        ])
        let result = polygon.inset(by: 0.25)
        XCTAssertEqual(result, expected)
    }

    // MARK: LineComparable

    func testDistanceFromParallelLine() {
        let polygon = Polygon(unchecked: [[-1, 1], [-1, -1], [1, -1], [1, 1]])
        let line = Line(unchecked: .unitZ, direction: .unitX)
        XCTAssertEqual(polygon.distance(from: line), 1)
    }

    func testDistanceFromIntersectingLine() {
        let polygon = Polygon(unchecked: [[-1, 1], [-1, -1], [1, -1], [1, 1]])
        let line = Line(unchecked: .zero, direction: .unitX).rotated(by: .random())
        XCTAssertEqual(polygon.distance(from: line), 0)
    }

    func testDistanceFromHorizontalCoplanarLine() {
        let polygon = Polygon(unchecked: [[-1, 1], [-1, -1], [1, -1], [1, 1]])
            .translated(by: [.random(in: -100 ... 100), 0])
        var line = Line(unchecked: .zero, direction: .unitX)
        XCTAssertEqual(polygon.distance(from: line), 0)
        line.translate(by: [0, -1])
        XCTAssertEqual(polygon.distance(from: line), 0)
        line.translate(by: [0, 2])
        XCTAssertEqual(polygon.distance(from: line), 0)
        line.translate(by: [0, 0.1])
        XCTAssertEqual(polygon.distance(from: line), 0.1)
    }

    func testDistanceFromVerticalCoplanarLine() {
        let polygon = Polygon(unchecked: [[-1, 1], [-1, -1], [1, -1], [1, 1]])
            .translated(by: [0, .random(in: -100 ... 100)])
        var line = Line(unchecked: .zero, direction: .unitY)
        XCTAssertEqual(polygon.distance(from: line), 0)
        line.translate(by: [-1, 0])
        XCTAssertEqual(polygon.distance(from: line), 0)
        line.translate(by: [2, 0])
        XCTAssertEqual(polygon.distance(from: line), 0)
        line.translate(by: [0.1, 0])
        XCTAssertEqual(polygon.distance(from: line), 0.1)
    }

    // MARK: InsertEdgePoint

    func testInsertEdgePointChangesConvexity() {
        var polygon = Polygon(unchecked: [
            [-0.496338834765, -0.17904070811, 0.600248465803],
            [-0.29941098710999997, -0.23664576933, 0.805321458235],
            [-0.299840180153, -0.235652447769, 0.799803057807],
            [-0.299574480497, -0.235690029285, 0.7998451571749999],
            [-0.493235048748, -0.17904070811, 0.59817458229],
        ])
        XCTAssertFalse(polygon.isConvex)
        XCTAssertTrue(polygon.insertEdgePoint([-0.299839394845, -0.235654265282, 0.799813155002]))
        XCTAssertTrue(polygon.isConvex)
    }

    // MARK: Overlapping and adjacent polygons

    func testSinglePolygon() {
        let polygons = [
            Polygon(unchecked: [
                [-0.5, 1.5],
                [-0.5, 0.5],
                [0.5, 0.5],
                [0.5, 1.5],
            ]),
        ]
        // TODO: should we add a `coplanarPolygonsAreWatertight` property?
        XCTAssertFalse(polygons.areWatertight)
        XCTAssertTrue(polygons.coplanarPolygonsAreConvex)

        let mesh = Mesh(polygons)
        XCTAssertFalse(mesh.isWatertight)
        XCTAssertFalse(mesh.isKnownConvex)
        XCTAssertTrue(mesh.isActuallyConvex)
    }

    func testOpposingPolygons() {
        let polygons = [
            Polygon(unchecked: [
                [-0.5, 0.5],
                [-0.5, -0.5],
                [0.5, -0.5],
                [0.5, 0.5],
            ]),
            Polygon(unchecked: [
                [0.5, -0.5],
                [-0.5, -0.5],
                [-0.5, 0.5],
                [0.5, 0.5],
            ]),
        ]
        XCTAssertTrue(polygons.areWatertight)

        let mesh = Mesh(polygons)
        XCTAssertTrue(mesh.isWatertight)
        XCTAssertFalse(mesh.isKnownConvex)
        XCTAssertTrue(mesh.isActuallyConvex)
    }

    func testCoincidentPolygons() {
        let polygons = [
            Polygon(unchecked: [
                [-0.5, 0.5],
                [-0.5, -0.5],
                [0.5, -0.5],
                [0.5, 0.5],
            ]),
            Polygon(unchecked: [
                [-0.5, -0.5],
                [0.5, -0.5],
                [0.5, 0.5],
                [-0.5, 0.5],
            ]),
        ]
        XCTAssertTrue(polygons.areWatertight) // TODO: not sure this is right?
        XCTAssertFalse(polygons.coplanarPolygonsAreConvex) // TODO: not sure this is right?
    }

    func testAdjacentPolygons() {
        let polygons = [
            Polygon(unchecked: [
                [-0.5, 1.5],
                [-0.5, 0.5],
                [0.5, 0.5],
                [0.5, 1.5],
            ]),
            Polygon(unchecked: [
                [-0.5, -0.5],
                [0.5, -0.5],
                [0.5, 0.5],
                [-0.5, 0.5],
            ]),
        ]
        XCTAssertFalse(polygons.areWatertight)
        XCTAssertTrue(polygons.coplanarPolygonsAreConvex)

        let mesh = Mesh(polygons)
        XCTAssertFalse(mesh.isWatertight)
        XCTAssertFalse(mesh.isKnownConvex)
        XCTAssertTrue(mesh.isActuallyConvex)
    }

    func testCoincidentPolygonsWithAdjacentPolygon() {
        let polygons = [
            Polygon(unchecked: [
                [-0.5, 0.5],
                [-0.5, -0.5],
                [0.5, -0.5],
                [0.5, 0.5],
            ]),
            Polygon(unchecked: [
                [-0.5, -0.5],
                [0.5, -0.5],
                [0.5, 0.5],
                [-0.5, 0.5],
            ]),
            Polygon(unchecked: [
                [-0.5, -0.5],
                [0.5, -0.5],
                [0.5, 0.5],
                [-0.5, 0.5],
            ]),
        ]
        XCTAssertFalse(polygons.areWatertight)
        XCTAssertFalse(polygons.coplanarPolygonsAreConvex) // TODO: not sure this is right?

        let mesh = Mesh(polygons)
        XCTAssertFalse(mesh.isWatertight)
        XCTAssertFalse(mesh.isKnownConvex)
        XCTAssertFalse(mesh.isActuallyConvex) // TODO: not sure this is right?
    }

    func testCoincidentPolygonsWithOpposingAdjacentPolygons() {
        let polygons = [
            Polygon(unchecked: [
                [-0.5, 0.5],
                [-0.5, -0.5],
                [0.5, -0.5],
                [0.5, 0.5],
            ]),
            Polygon(unchecked: [
                [-0.5, -0.5],
                [0.5, -0.5],
                [0.5, 0.5],
                [-0.5, 0.5],
            ]),
            Polygon(unchecked: [
                [-0.5, -0.5],
                [0.5, -0.5],
                [0.5, 0.5],
                [-0.5, 0.5],
            ]),
            Polygon(unchecked: [
                [0.5, -0.5],
                [-0.5, -0.5],
                [-0.5, 0.5],
                [0.5, 0.5],
            ]),
        ]
        XCTAssertTrue(polygons.areWatertight) // TODO: not sure this is right?

        let mesh = Mesh(polygons)
        XCTAssertTrue(mesh.isWatertight) // TODO: not sure this is right?
        XCTAssertFalse(mesh.isKnownConvex)
        XCTAssertFalse(mesh.isActuallyConvex) // TODO: not sure this is right?
    }
}
