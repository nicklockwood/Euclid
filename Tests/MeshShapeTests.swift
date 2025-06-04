//
//  MeshShapeTests.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 06/02/2022.
//  Copyright © 2022 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

class MeshShapeTests: XCTestCase {
    // MARK: Fill

    func testFillClockwiseQuad() {
        let shape = Path([
            .point(0, 0),
            .point(1, 0),
            .point(1, 1),
            .point(0, 1),
            .point(0, 0),
        ])
        let mesh = Mesh.fill(shape)
        XCTAssertEqual(mesh.polygons.count, 2)
        XCTAssertEqual(mesh.polygons.first?.plane.normal, .unitZ)
    }

    func testFillAnticlockwiseQuad() {
        let shape = Path([
            .point(1, 0),
            .point(0, 0),
            .point(0, 1),
            .point(1, 1),
            .point(1, 0),
        ])
        let mesh = Mesh.fill(shape)
        XCTAssertEqual(mesh.polygons.count, 2)
        XCTAssertEqual(mesh.polygons.first?.plane.normal, -.unitZ)
    }

    func testFillSelfIntersectingPath() {
        let path = Path([
            .point(0, 0),
            .point(1, 1),
            .point(1, 0),
            .point(0, 1),
        ])
        let mesh = Mesh.fill(path)
        XCTAssert(mesh.polygons.isEmpty)
    }

    func testFillNonPlanarQuad() {
        let shape = Path([
            .point(0, 0),
            .point(1, 0),
            .point(1, 1, 1),
            .point(0, 1),
            .point(0, 0),
        ])
        let mesh = Mesh.fill(shape)
        XCTAssertEqual(mesh.polygons.count, 4)
    }

    // MARK: Lathe (see MeshLatheTests)

    // MARK: Loft (see MeshLoftTests)

    // MARK: Extrude

    func testExtrudeSelfIntersectingPath() {
        let path = Path([
            .point(0, 0),
            .point(1, 1),
            .point(1, 0),
            .point(0, 1),
        ])
        let mesh = Mesh.extrude(path)
        XCTAssertFalse(mesh.polygons.isEmpty)
        XCTAssertEqual(mesh, .extrude(path, faces: .frontAndBack))
    }

    func testExtrudeClosedLine() {
        let path = Path([
            .point(0, 0),
            .point(0, 1),
            .point(0, 0),
        ])
        let mesh = Mesh.extrude(path)
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
        XCTAssertEqual(mesh.polygons.count, 2)
        XCTAssertEqual(mesh, .extrude(path, faces: .front))
    }

    func testExtrudeOpenLine() {
        let path = Path([
            .point(0, 0),
            .point(0, 1),
        ])
        let mesh = Mesh.extrude(path)
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
        XCTAssertEqual(mesh.polygons.count, 2)
        XCTAssertEqual(mesh, .extrude(path, faces: .frontAndBack))
    }

    func testExtrudeOpenLineAlongClosedPath() {
        let path = Path([
            .point(0, 0),
            .point(0, 1),
        ])
        let mesh = Mesh.extrude(path, along: .square())
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
        XCTAssertEqual(mesh.polygons.count, 8)
        XCTAssertEqual(mesh, .extrude(path, along: .square(), faces: .frontAndBack))
    }

    func testExtrudeOpenLineAlongOpenPath() {
        let path = Path([
            .point(0, 0),
            .point(0, 1),
        ])
        let mesh = Mesh.extrude(path, along: path)
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
        XCTAssertEqual(mesh.polygons.count, 2)
        XCTAssertEqual(mesh, .extrude(path, along: path, faces: .frontAndBack))
    }

    func testExtrudeAlongEmptyPath() {
        let mesh = Mesh.extrude(.circle(), along: .empty)
        XCTAssertEqual(mesh, .empty)
    }

    func testExtrudeAlongSinglePointPath() {
        let mesh = Mesh.extrude(.circle(), along: .init([.point(1, 0.5)]))
        XCTAssertEqual(mesh, .fill(Path.circle().translated(by: .init(1, 0.5))))
    }

    // MARK: Stroke

    func testStrokeLine() {
        let path = Path.line(Vector(-1, 0), Vector(1, 0))
        let mesh = Mesh.stroke(path, detail: 2)
        XCTAssertEqual(mesh.polygons.count, 2)
    }

    func testStrokeLineSingleSided() {
        let path = Path.line(Vector(-1, 0), Vector(1, 0))
        let mesh = Mesh.stroke(path, detail: 1)
        XCTAssertEqual(mesh.polygons.count, 1)
    }

    func testStrokeLineWithTriangle() {
        let path = Path.line(Vector(-1, 0), Vector(1, 0))
        let mesh = Mesh.stroke(path, detail: 3)
        XCTAssertEqual(mesh.polygons.count, 5)
    }

    func testStrokeSquareWithTriangle() {
        let mesh = Mesh.stroke(.square(), detail: 3)
        XCTAssertEqual(mesh.polygons.count, 12)
    }

    func testStrokePathWithCollinearPoints() {
        let path = Path([
            .point(0, 0),
            .point(0.5, 0),
            .point(0.5, 1),
            .point(-0.5, 1),
            .point(-0.5, 0),
            .point(0, 0),
        ])
        let mesh = Mesh.stroke(path, detail: 3)
        XCTAssertEqual(mesh.polygons.count, 15)
    }

    // MARK: Convex Hull

    func testConvexHullOfCubes() {
        let mesh1 = Mesh.cube().translated(by: Vector(-1, 0.5, 0.7))
        let mesh2 = Mesh.cube().translated(by: Vector(1, 0))
        let mesh = Mesh.convexHull(of: [mesh1, mesh2])
        XCTAssert(mesh.isKnownConvex)
        XCTAssert(mesh.isActuallyConvex)
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
        XCTAssertEqual(mesh.bounds, mesh1.bounds.union(mesh2.bounds))
        XCTAssertEqual(mesh.bounds, Bounds(mesh.polygons))
    }

    func testConvexHullOfSpheres() {
        let mesh1 = Mesh.sphere().translated(by: Vector(-1, 0.2, -0.1))
        let mesh2 = Mesh.sphere().translated(by: Vector(1, 0))
        let mesh = Mesh.convexHull(of: [mesh1, mesh2])
        XCTAssert(mesh.isKnownConvex)
        XCTAssert(mesh.isActuallyConvex)
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
        XCTAssertEqual(mesh.bounds, mesh1.bounds.union(mesh2.bounds))
        XCTAssertEqual(mesh.bounds, Bounds(mesh.polygons))
    }

    func testConvexHullOfCubeIsItself() {
        let cube = Mesh.cube()
        let mesh = Mesh.convexHull(of: [cube])
        XCTAssertEqual(cube, mesh)
        let mesh2 = Mesh.convexHull(of: cube.polygons)
        XCTAssertEqual(
            Set(cube.polygons.flatMap { $0.vertices }),
            Set(mesh2.polygons.flatMap { $0.vertices })
        )
        XCTAssertEqual(cube.polygons.count, mesh2.detessellate().polygons.count)
    }

    func testConvexHullOfNothing() {
        let mesh = Mesh.convexHull(of: [] as [Mesh])
        XCTAssertEqual(mesh, .empty)
    }

    func testConvexHullOfSingleTriangle() {
        let triangle = Polygon(unchecked: [
            Vector(0, 0),
            Vector(1, 0),
            Vector(1, 1),
        ])
        let mesh = Mesh.convexHull(of: [triangle])
        XCTAssert(mesh.isKnownConvex)
        XCTAssert(mesh.isActuallyConvex)
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
        XCTAssertEqual(mesh.bounds, triangle.bounds)
        XCTAssertEqual(mesh.bounds, Bounds(mesh.polygons))
    }

    func testConvexHullOfConcavePolygon() {
        let shape = Polygon(unchecked: [
            Vector(0, 0),
            Vector(1, 0),
            Vector(1, 1),
            Vector(0.5, 1),
            Vector(0.5, 0.5),
        ])
        let mesh = Mesh.convexHull(of: [shape])
        XCTAssert(mesh.isKnownConvex)
        XCTAssert(mesh.isActuallyConvex)
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
        XCTAssertEqual(mesh.bounds, shape.bounds)
        XCTAssertEqual(mesh.bounds, Bounds(mesh.polygons))
    }

    func testConvexHullOfConcavePolygonMesh() {
        let shape = Mesh([Polygon(unchecked: [
            Vector(0, 0),
            Vector(1, 0),
            Vector(1, 1),
            Vector(0.5, 1),
            Vector(0.5, 0.5),
        ])])
        let mesh = Mesh.convexHull(of: [shape])
        XCTAssert(mesh.isKnownConvex)
        XCTAssert(mesh.isActuallyConvex)
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
        XCTAssertEqual(mesh.bounds, shape.bounds)
        XCTAssertEqual(mesh.bounds, Bounds(mesh.polygons))
    }

    func testConvexHullOfCoplanarTriangles() {
        let triangle1 = Polygon(unchecked: [
            Vector(0, 0),
            Vector(1, 0),
            Vector(1, 1),
        ])
        let triangle2 = Polygon(unchecked: [
            Vector(2, 0),
            Vector(3, 0),
            Vector(3, 1),
        ])
        let mesh = Mesh.convexHull(of: [triangle1, triangle2])
        XCTAssert(mesh.isKnownConvex)
        XCTAssert(mesh.isActuallyConvex)
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
        XCTAssertEqual(mesh.bounds, triangle1.bounds.union(triangle2.bounds))
        XCTAssertEqual(mesh.bounds, Bounds(mesh.polygons))
    }

    // MARK: Nearest point

    func testNearestPointOnConvexShape() {
        let cube = Mesh.cube()
        XCTAssertEqual(cube.nearestPoint(to: .zero), .zero)
        XCTAssertEqual(cube.nearestPoint(to: -.unitX), Vector(-0.5, 0, 0))
        XCTAssertEqual(cube.nearestPoint(to: .unitZ), Vector(0, 0, 0.5))
        XCTAssertEqual(cube.nearestPoint(to: Vector(1, 1, 0)), Vector(0.5, 0.5, 0))
        XCTAssertEqual(cube.nearestPoint(to: .one), Vector(size: 0.5))
    }

    func testNearestPointOnConcaveShape() {
        let detail = 16
        let radius = 0.5
        let torus = Mesh.lathe(
            .circle(radius: radius).translated(by: -.unitX * radius * 2),
            slices: detail
        )
        let shortest = cos(.pi / Double(detail)) * radius
        XCTAssertEqual(torus.nearestPoint(to: .zero).length, shortest, accuracy: epsilon)
        XCTAssertEqual(torus.nearestPoint(to: .unitX * radius), .unitX * radius)
        XCTAssertEqual(torus.nearestPoint(to: .unitX * radius * 2), .unitX * radius * 2)
        XCTAssertEqual(torus.nearestPoint(to: .unitX * radius * 3), .unitX * radius * 3)
        XCTAssertEqual(torus.nearestPoint(to: .unitX * radius * 4), .unitX * radius * 3)
    }
}
