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

    func testMergedMeshNotAssumedToBeWatertight() {
        let cube = Mesh.cube()
        XCTAssert(cube.isWatertight)
        let mesh = cube.merge(.sphere())
        XCTAssertNil(mesh.watertightIfSet)
        XCTAssert(mesh.isWatertight)
    }

    func testMultimergedMeshesNotAssumedToBeWatertight() {
        let cube = Mesh.cube()
        XCTAssert(cube.isWatertight)
        let mesh = Mesh.merge([cube, .sphere(), .cylinder()])
        XCTAssertNil(mesh.watertightIfSet)
        XCTAssert(mesh.isWatertight)
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
        let c = a.subtracting(b)
        XCTAssertFalse(c.isWatertight)
        #if !arch(wasm32)
        XCTAssertEqual(c.triangulate().polygons.count, 338)
        #endif
        let d = c.makeWatertight()
        XCTAssertTrue(d.isWatertight)
        XCTAssertTrue(d.polygons.areWatertight)
        #if !arch(wasm32)
        XCTAssertEqual(d.triangulate().polygons.count, 526)
        #endif
    }

    // MARK: plane intersection

    func testCubePlaneIntersection() {
        let mesh = Mesh.cube()
        let plane = Plane(unchecked: .unitX, pointOnPlane: .zero)
        let edges = mesh.edges(intersecting: plane)
        XCTAssertEqual(edges, [
            LineSegment(start: Vector(0, 0.5, -0.5), end: Vector(0, 0.5, 0.5)),
            LineSegment(start: Vector(0, -0.5, -0.5), end: Vector(0, -0.5, 0.5)),
            LineSegment(start: Vector(0, -0.5, 0.5), end: Vector(0, 0.5, 0.5)),
            LineSegment(start: Vector(0, -0.5, -0.5), end: Vector(0, 0.5, -0.5)),
        ])
    }

    func testCubeTouchingPlane() {
        let mesh = Mesh.cube().translated(by: Vector(-0.5, 0, 0))
        let plane = Plane(unchecked: .unitX, pointOnPlane: .zero)
        let edges = mesh.edges(intersecting: plane)
        XCTAssertEqual(edges, [
            LineSegment(start: Vector(0, 0.5, -0.5), end: Vector(0, 0.5, 0.5)),
            LineSegment(start: Vector(0, -0.5, -0.5), end: Vector(0, -0.5, 0.5)),
            LineSegment(start: Vector(0, -0.5, 0.5), end: Vector(0, 0.5, 0.5)),
            LineSegment(start: Vector(0, -0.5, -0.5), end: Vector(0, 0.5, -0.5)),
        ])
    }

    func testCubeTouchingPlane2() {
        let mesh = Mesh.cube().translated(by: Vector(0.5, 0, 0))
        let plane = Plane(unchecked: .unitX, pointOnPlane: .zero)
        let edges = mesh.edges(intersecting: plane)
        XCTAssertEqual(edges, [
            LineSegment(start: Vector(0, 0.5, -0.5), end: Vector(0, 0.5, 0.5)),
            LineSegment(start: Vector(0, -0.5, -0.5), end: Vector(0, -0.5, 0.5)),
            LineSegment(start: Vector(0, -0.5, 0.5), end: Vector(0, 0.5, 0.5)),
            LineSegment(start: Vector(0, -0.5, -0.5), end: Vector(0, 0.5, -0.5)),
        ])
    }

    func testPentagonSpanningPlane() {
        let mesh = Mesh.fill(.circle(segments: 5))
        let plane = Plane(unchecked: .unitX, pointOnPlane: .zero)
        let edges = mesh.edges(intersecting: plane)
        XCTAssertEqual(edges, [
            LineSegment(start: Vector(0, -0.404508497187, 0), end: Vector(0, 0.5, 0)),
        ])
    }

    func testDiamondSpanningPlane() {
        let mesh = Mesh.fill(.circle(segments: 4))
        let plane = Plane(unchecked: .unitX, pointOnPlane: .zero)
        let edges = mesh.edges(intersecting: plane)
        XCTAssertEqual(edges, [
            LineSegment(start: Vector(0, -0.5, 0), end: Vector(0, 0.5, 0)),
        ])
    }

    // MARK: submeshes

    func testSubmeshes() {
        let sphere = Mesh.sphere()
        let cube = Mesh.cube(size: 0.8)
        let mesh = sphere.merge(cube)
        XCTAssertEqual(mesh.submeshes.count, 2)
        XCTAssertEqual(mesh.submeshes.first, sphere)
        XCTAssertEqual(Set(mesh.submeshes.last?.polygons ?? []), Set(cube.polygons))
    }

    func testSubmeshesDontCreateCircularReference() {
        weak var material: AnyObject?
        do {
            let temp = NSObject()
            material = temp
            let mesh = Mesh.sphere(material: temp)
            XCTAssertEqual(mesh.submeshes, [mesh])
        }
        XCTAssertNil(material)
    }

    func testSubmeshesDontCreateCircularReference2() {
        weak var material: AnyObject?
        do {
            let temp = NSObject()
            material = temp
            let mesh = Mesh.sphere(material: temp)
            XCTAssertEqual(mesh.submeshes, [mesh])
            let mesh2 = Mesh(
                unchecked: mesh.polygons,
                bounds: mesh.bounds,
                isConvex: true,
                isWatertight: mesh.isWatertight,
                submeshes: mesh.submeshes
            )
            XCTAssertEqual(mesh2.submeshes, [mesh2])
            XCTAssertEqual(mesh2.submeshes, [mesh])
        }
        XCTAssertNil(material)
    }

    // MARK: containsPoint

    func testCubeContainsPoint() {
        let edgePoints: [Vector] = [
            Vector(0.5, 0, 0),
            Vector(0, 0.5, 0),
            Vector(0, 0, 0.5),
            Vector(0.5, 0.5, 0),
            Vector(0, 0.5, 0.5),
            Vector(0.5, 0, 0.5),
            Vector(-0.5, 0, 0),
            Vector(0, -0.5, 0),
            Vector(0, 0, -0.5),
            Vector(-0.5, -0.5, 0),
            Vector(0, -0.5, -0.5),
            Vector(-0.5, 0, -0.5),
        ]
        let insidePoints = [.zero] + edgePoints.map { $0 * 0.999 }
        let outsidePoints = edgePoints.map { $0 * 1.001 }
        let mesh = Mesh.cube()
        let bsp = BSP(mesh) { false }
        for point in insidePoints {
            XCTAssertTrue(mesh.containsPoint(point))
            XCTAssertTrue(bsp.containsPoint(point))
        }
        for point in outsidePoints {
            XCTAssertFalse(mesh.containsPoint(point))
            XCTAssertFalse(bsp.containsPoint(point))
        }
    }

    func testSquareContainsPoint() {
        let edgePoints: [Vector] = [
            Vector(0.5, 0),
            Vector(0, 0.5),
            Vector(0.5, 0.5),
            Vector(-0.5, 0),
            Vector(0, -0.5),
            Vector(-0.5, -0.5),
        ]
        let insidePoints = [.zero] + edgePoints.map { $0 * 0.999 }
        let outsidePoints = edgePoints.map { $0 * 1.001 }
            + insidePoints.translated(by: Vector(0, 0, planeEpsilon))
            + insidePoints.translated(by: Vector(0, 0, -planeEpsilon))
        let mesh = Mesh.fill(.square())
        let bsp = BSP(mesh) { false }
        let r = Rotation(roll: .pi / 3)
        for point in insidePoints {
            XCTAssertTrue(mesh.containsPoint(point))
            XCTAssertTrue(bsp.containsPoint(point))
            XCTAssertTrue(mesh.rotated(by: r).containsPoint(point.rotated(by: r)))
        }
        for point in outsidePoints {
            XCTAssertFalse(mesh.containsPoint(point))
            XCTAssertFalse(bsp.containsPoint(point))
            XCTAssertFalse(mesh.rotated(by: r).containsPoint(point.rotated(by: r)))
        }
    }

    func testSphereContainsPoint() {
        let edgePoints: [Vector] = [
            Vector(0.5, 0, 0),
            Vector(0, 0.5, 0),
            Vector(0, 0, 0.5),
            Vector(0.5, 0.5, 0),
            Vector(0, 0.5, 0.5),
            Vector(0.5, 0, 0.5),
            Vector(-0.5, 0, 0),
            Vector(0, -0.5, 0),
            Vector(0, 0, -0.5),
            Vector(-0.5, -0.5, 0),
            Vector(0, -0.5, -0.5),
            Vector(-0.5, 0, -0.5),
        ].map { $0.normalized() * 0.5 }
        let insidePoints = [.zero] + edgePoints.map { $0 * 0.999 }
        let outsidePoints = edgePoints.map { $0 * 1.001 }
        let mesh = Mesh.sphere(slices: 8, stacks: 4)
        let bsp = BSP(mesh) { false }
        for point in insidePoints {
            XCTAssertTrue(mesh.containsPoint(point))
            XCTAssertTrue(bsp.containsPoint(point))
        }
        for point in outsidePoints {
            XCTAssertFalse(mesh.containsPoint(point))
            XCTAssertFalse(bsp.containsPoint(point))
        }
    }

    func testLContainsPoint() {
        let edgePoints: [Vector] = [
            Vector(0, 0, 0),
            Vector(0, 0.5, 0),
            Vector(-0.5, 0, 0),
        ].translated(by: Vector(-0.25, 0.25))
        let insidePoints = [.zero] + edgePoints.map { $0 * 0.999 }
        let outsidePoints = edgePoints.map { $0 * 1.001 }
        let mesh = Mesh
            .cube(size: Vector(2, 2, 1))
            .subtracting(Mesh.cube().translated(by: Vector(-0.5, 0.5, 0)))
            .translated(by: Vector(-0.25, 0.25))
        let bsp = BSP(mesh) { false }
        for point in insidePoints {
            XCTAssertTrue(mesh.containsPoint(point))
            XCTAssertTrue(bsp.containsPoint(point))
        }
        for point in outsidePoints {
            XCTAssertFalse(mesh.containsPoint(point))
            XCTAssertFalse(bsp.containsPoint(point))
        }
    }

    // MARK: Optimization

    func testMeshWithoutTexcoords() {
        let mesh = Mesh.cube().withoutTexcoords()
        XCTAssertFalse(mesh.hasTexcoords)
    }

    func testMeshWithoutVertexNormals() {
        let cube = Mesh.cube()
        XCTAssertFalse(cube.hasVertexNormals)
        let sphere = Mesh.sphere().smoothingNormals(forAnglesGreaterThan: .zero)
        XCTAssertFalse(sphere.hasVertexNormals)
    }

    func testInvertedMeshContainsPoint() {
        let insidePoints = [Vector(-1, -1, -1)]
        let outsidePoints = [Vector.zero]
        let mesh = Mesh.sphere().inverted()
        let bsp = BSP(mesh) { false }
        for point in insidePoints {
            XCTAssertTrue(mesh.containsPoint(point))
            XCTAssertTrue(bsp.containsPoint(point))
        }
        for point in outsidePoints {
            XCTAssertFalse(mesh.containsPoint(point))
            XCTAssertFalse(bsp.containsPoint(point))
        }
    }
}
