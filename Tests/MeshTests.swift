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
        let a = Polygon(unchecked: [
            [0, 0],
            [0, -2],
            [2, 0],
        ])
        let b = Polygon(unchecked: [
            [2, 0],
            [1, -1],
            [2, -2],
        ])
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
            LineSegment(start: [0, 0.5, -0.5], end: [0, 0.5, 0.5]),
            LineSegment(start: [0, -0.5, -0.5], end: [0, -0.5, 0.5]),
            LineSegment(start: [0, -0.5, 0.5], end: [0, 0.5, 0.5]),
            LineSegment(start: [0, -0.5, -0.5], end: [0, 0.5, -0.5]),
        ])
    }

    func testCubeTouchingPlane() {
        let mesh = Mesh.cube().translated(by: [-0.5, 0])
        let plane = Plane(unchecked: .unitX, pointOnPlane: .zero)
        let edges = mesh.edges(intersecting: plane)
        XCTAssertEqual(edges, [
            LineSegment(start: [0, 0.5, -0.5], end: [0, 0.5, 0.5]),
            LineSegment(start: [0, -0.5, -0.5], end: [0, -0.5, 0.5]),
            LineSegment(start: [0, -0.5, 0.5], end: [0, 0.5, 0.5]),
            LineSegment(start: [0, -0.5, -0.5], end: [0, 0.5, -0.5]),
        ])
    }

    func testCubeTouchingPlane2() {
        let mesh = Mesh.cube().translated(by: [0.5, 0])
        let plane = Plane(unchecked: .unitX, pointOnPlane: .zero)
        let edges = mesh.edges(intersecting: plane)
        XCTAssertEqual(edges, [
            LineSegment(start: [0, 0.5, -0.5], end: [0, 0.5, 0.5]),
            LineSegment(start: [0, -0.5, -0.5], end: [0, -0.5, 0.5]),
            LineSegment(start: [0, -0.5, 0.5], end: [0, 0.5, 0.5]),
            LineSegment(start: [0, -0.5, -0.5], end: [0, 0.5, -0.5]),
        ])
    }

    func testPentagonSpanningPlane() {
        let mesh = Mesh.fill(.circle(segments: 5))
        let plane = Plane(unchecked: .unitX, pointOnPlane: .zero)
        let edges = mesh.edges(intersecting: plane)
        XCTAssertEqual(edges, [
            LineSegment(start: [0, -0.404508497187], end: [0, 0.5]),
        ])
    }

    func testDiamondSpanningPlane() {
        let mesh = Mesh.fill(.circle(segments: 4))
        let plane = Plane(unchecked: .unitX, pointOnPlane: .zero)
        let edges = mesh.edges(intersecting: plane)
        XCTAssertEqual(edges, [
            LineSegment(start: [0, -0.5], end: [0, 0.5]),
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

    // MARK: surfaceArea

    func testCubeArea() {
        let cube = Mesh.cube()
        XCTAssertEqual(cube.surfaceArea, 6, accuracy: epsilon)
    }

    // MARK: volume

    func testCubeVolume() {
        let cube = Mesh.cube(size: 2)
        XCTAssertEqual(cube.volume, 8, accuracy: epsilon)
    }

    func testSphereVolume() {
        let cube = Mesh.sphere(slices: 128, stacks: 64)
        XCTAssertEqual(cube.volume, (4.0 / 3) * .pi * pow(0.5, 3), accuracy: 0.001)
    }

    // MARK: containsPoint

    func testCubeContainsPoint() {
        let edgePoints: [Vector] = [
            [0.5, 0, 0],
            [0, 0.5, 0],
            [0, 0, 0.5],
            [0.5, 0.5, 0],
            [0, 0.5, 0.5],
            [0.5, 0, 0.5],
            [-0.5, 0, 0],
            [0, -0.5, 0],
            [0, 0, -0.5],
            [-0.5, -0.5, 0],
            [0, -0.5, -0.5],
            [-0.5, 0, -0.5],
        ]
        let insidePoints = [.zero] + edgePoints.map { $0 * 0.999 }
        let outsidePoints = edgePoints.map { $0 * 1.001 }
        let mesh = Mesh.cube()
        let bsp = BSP(mesh) { false }
        for point in insidePoints {
            XCTAssertTrue(mesh.intersects(point))
            XCTAssertTrue(bsp.intersects(point))
        }
        for point in outsidePoints {
            XCTAssertFalse(mesh.intersects(point))
            XCTAssertFalse(bsp.intersects(point))
        }
    }

    func testSquareContainsPoint() {
        let edgePoints: [Vector] = [
            [0.5, 0],
            [0, 0.5],
            [0.5, 0.5],
            [-0.5, 0],
            [0, -0.5],
            [-0.5, -0.5],
        ]
        let insidePoints = [.zero] + edgePoints.map { $0 * 0.999 }
        let outsidePoints = edgePoints.map { $0 * 1.001 }
            + insidePoints.translated(by: .unitZ * (planeEpsilon * 2))
            + insidePoints.translated(by: .unitZ * (-planeEpsilon * 2))
        let mesh = Mesh.fill(.square())
        let bsp = BSP(mesh) { false }
        let r = Rotation(roll: .pi / 3)
        for point in insidePoints {
            XCTAssertTrue(mesh.intersects(point))
            XCTAssertTrue(bsp.intersects(point))
            XCTAssertTrue(mesh.rotated(by: r).intersects(point.rotated(by: r)))
        }
        for point in outsidePoints {
            XCTAssertFalse(mesh.intersects(point))
            XCTAssertFalse(bsp.intersects(point))
            XCTAssertFalse(mesh.rotated(by: r).intersects(point.rotated(by: r)))
        }
    }

    func testSphereContainsPoint() {
        let edgePoints = ([
            [0.5, 0, 0],
            [0, 0.5, 0],
            [0, 0, 0.5],
            [0.5, 0.5, 0],
            [0, 0.5, 0.5],
            [0.5, 0, 0.5],
            [-0.5, 0, 0],
            [0, -0.5, 0],
            [0, 0, -0.5],
            [-0.5, -0.5, 0],
            [0, -0.5, -0.5],
            [-0.5, 0, -0.5],
        ] as [Vector]).map { $0.normalized() * 0.5 }
        let insidePoints = [.zero] + edgePoints.map { $0 * 0.999 }
        let outsidePoints = edgePoints.map { $0 * 1.001 }
        let mesh = Mesh.sphere(slices: 8, stacks: 4)
        let bsp = BSP(mesh) { false }
        for point in insidePoints {
            XCTAssertTrue(mesh.intersects(point))
            XCTAssertTrue(bsp.intersects(point))
        }
        for point in outsidePoints {
            XCTAssertFalse(mesh.intersects(point))
            XCTAssertFalse(bsp.intersects(point))
        }
    }

    func testLContainsPoint() {
        let edgePoints: [Vector] = [
            [0, 0, 0],
            [0, 0.5, 0],
            [-0.5, 0, 0],
        ].translated(by: [-0.25, 0.25])
        let insidePoints = [.zero] + edgePoints.map { $0 * 0.999 }
        let outsidePoints = edgePoints.map { $0 * 1.001 }
        let mesh = Mesh
            .cube(size: [2, 2, 1])
            .subtracting(Mesh.cube().translated(by: [-0.5, 0.5, 0]))
            .translated(by: [-0.25, 0.25])
        let bsp = BSP(mesh) { false }
        for point in insidePoints {
            XCTAssertTrue(mesh.intersects(point))
            XCTAssertTrue(bsp.intersects(point))
        }
        for point in outsidePoints {
            XCTAssertFalse(mesh.intersects(point))
            XCTAssertFalse(bsp.intersects(point))
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

    // MARK: Reflection

    func testQuadReflectionAlongPlane() {
        let quad = Polygon(unchecked: [
            Vertex(-0.5, 1.0, 0.5, normal: .unitY, texcoord: [0.0, 1.0], color: .black),
            Vertex(0.5, 1.0, 0.5, normal: .unitY, texcoord: [1.0, 1.0], color: .black),
            Vertex(0.5, 1.0, -0.5, normal: .unitY, texcoord: [1.0, 0.0], color: .white),
            Vertex(-0.5, 1.0, -0.5, normal: .unitY, texcoord: [0.0, 0.0], color: .white),
        ])

        let expected = Polygon(unchecked: [
            Vertex(-0.5, -1.0, -0.5, normal: -.unitY, texcoord: [0.0, 0.0], color: .white),
            Vertex(0.5, -1.0, -0.5, normal: -.unitY, texcoord: [1.0, 0.0], color: .white),
            Vertex(0.5, -1.0, 0.5, normal: -.unitY, texcoord: [1.0, 1.0], color: .black),
            Vertex(-0.5, -1.0, 0.5, normal: -.unitY, texcoord: [0.0, 1.0], color: .black),
        ])

        let reflection = quad.reflected(along: .xz)

        XCTAssertEqual(reflection.plane.normal, -.unitY)
        XCTAssertEqual(reflection.vertices, expected.vertices)
    }
}
