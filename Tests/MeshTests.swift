//
//  MeshTests.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 24/12/2021.
//  Copyright © 2021 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

class MeshTests: XCTestCase {
    // MARK: uniqueEdges

    func testUniqueEdgesForCube() {
        let mesh = Mesh.cube()
        let edges = mesh.uniqueEdges
        XCTAssertEqual(edges.count, 12)
    }

    func testUniqueEdgesForSphere() {
        let mesh = Mesh.sphere(slices: 4)
        let edges = mesh.uniqueEdges
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

    // MARK: makeWatertight

    func testAddMissingTriangleVertex() {
        let a = Polygon([
            Vector(0, 0),
            Vector(0, -2),
            Vector(2, 0),
        ])!
        let b = Polygon([
            Vector(2, 0),
            Vector(1, -1),
            Vector(2, -2),
        ])!
        let m = Mesh([a, b])
        let m2 = m.makeWatertight()
        XCTAssertEqual(m2.polygons[0].vertices.count, 4)
    }

    func testMakeWatertightIsDeterministic() {
        let a = Mesh.cube(size: 0.8)
        let b = Mesh.sphere(slices: 16)
        let c = a.subtract(b)
        XCTAssertFalse(c.isWatertight)
        #if arch(wasm32)
        XCTAssertEqual(c.triangulate().polygons.count, 346)
        #else
        XCTAssertEqual(c.triangulate().polygons.count, 330)
        #endif
        let d = c.makeWatertight()
        XCTAssertTrue(d.isWatertight)
        XCTAssertTrue(d.polygons.areWatertight)
        #if arch(wasm32)
        XCTAssertEqual(d.triangulate().polygons.count, 462)
        #else
        XCTAssertEqual(d.triangulate().polygons.count, 429)
        #endif
    }

    // MARK: plane intersection

    func testCubePlaneIntersection() {
        let mesh = Mesh.cube()
        let plane = Plane(unchecked: .unitX, pointOnPlane: .zero)
        let edges = mesh.edges(intersecting: plane)
        XCTAssertEqual(edges, [
            LineSegment(Vector(0, 0.5, -0.5), Vector(0, 0.5, 0.5)),
            LineSegment(Vector(0, -0.5, -0.5), Vector(0, -0.5, 0.5)),
            LineSegment(Vector(0, -0.5, 0.5), Vector(0, 0.5, 0.5)),
            LineSegment(Vector(0, -0.5, -0.5), Vector(0, 0.5, -0.5)),
        ])
    }

    func testCubeTouchingPlane() {
        let mesh = Mesh.cube().translated(by: Vector(-0.5, 0, 0))
        let plane = Plane(unchecked: .unitX, pointOnPlane: .zero)
        let edges = mesh.edges(intersecting: plane)
        XCTAssertEqual(edges, [
            LineSegment(Vector(0, 0.5, -0.5), Vector(0, 0.5, 0.5)),
            LineSegment(Vector(0, -0.5, -0.5), Vector(0, -0.5, 0.5)),
            LineSegment(Vector(0, -0.5, 0.5), Vector(0, 0.5, 0.5)),
            LineSegment(Vector(0, -0.5, -0.5), Vector(0, 0.5, -0.5)),
        ])
    }

    func testCubeTouchingPlane2() {
        let mesh = Mesh.cube().translated(by: Vector(0.5, 0, 0))
        let plane = Plane(unchecked: .unitX, pointOnPlane: .zero)
        let edges = mesh.edges(intersecting: plane)
        XCTAssertEqual(edges, [
            LineSegment(Vector(0, 0.5, -0.5), Vector(0, 0.5, 0.5)),
            LineSegment(Vector(0, -0.5, -0.5), Vector(0, -0.5, 0.5)),
            LineSegment(Vector(0, -0.5, 0.5), Vector(0, 0.5, 0.5)),
            LineSegment(Vector(0, -0.5, -0.5), Vector(0, 0.5, -0.5)),
        ])
    }

    func testPentagonSpanningPlane() {
        let mesh = Mesh.fill(.circle(segments: 5))
        let plane = Plane(unchecked: .unitX, pointOnPlane: .zero)
        let edges = mesh.edges(intersecting: plane)
        XCTAssertEqual(edges, [
            LineSegment(Vector(0, -0.404508497187, 0), Vector(0, 0.5, 0)),
        ])
    }

    func testDiamondSpanningPlane() {
        let mesh = Mesh.fill(.circle(segments: 4))
        let plane = Plane(unchecked: .unitX, pointOnPlane: .zero)
        let edges = mesh.edges(intersecting: plane)
        XCTAssertEqual(edges, [
            LineSegment(Vector(0, -0.5, 0), Vector(0, 0.5, 0)),
        ])
    }
}
