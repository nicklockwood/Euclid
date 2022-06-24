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

    // MARK: Lathe

    func testLatheSelfIntersectingPath() {
        let path = Path([
            .point(0, 0),
            .point(1, 1),
            .point(1, 0),
            .point(0, 1),
        ])
        let mesh = Mesh.lathe(path)
        XCTAssert(!mesh.polygons.isEmpty)
    }

    // MARK: Loft

    func testLoftParallelEdges() {
        let shapes = [
            Path.square(),
            Path.square().translated(by: Vector(0.0, 1.0, 0.0)),
        ]

        let loft = Mesh.loft(shapes)

        // Every vertex in the loft should be contained by one of our shapes
        let vertices = loft.polygons.flatMap { $0.vertices }
        XCTAssert(vertices.allSatisfy { vertex in
            shapes.contains(where: { $0.points.contains(where: { $0.position == vertex.position }) })
        })
    }

    func testLoftNonParallelEdges() {
        let shapes = [
            Path.square(),
            Path([
                PathPoint.point(-2.0, 1.0, 1.0),
                PathPoint.point(-2.0, 1.0, -1.0),
                PathPoint.point(2.0, 1.0, -1.0),
                PathPoint.point(2.0, 1.0, 1.0),
                PathPoint.point(-2.0, 1.0, 1.0),
            ]),
        ]

        let loft = Mesh.loft(shapes)

        XCTAssert(loft.polygons.allSatisfy { pointsAreCoplanar($0.vertices.map { $0.position }) })

        // Every vertex in the loft should be contained by one of our shapes
        let vertices = loft.polygons.flatMap { $0.vertices }
        XCTAssert(vertices.allSatisfy { vertex in
            shapes.contains(where: { $0.points.contains(where: { $0.position == vertex.position }) })
        })
    }

    func testLoftCoincidentClosedPaths() {
        let shapes = [
            Path.square(),
            Path.square(),
        ]

        let loft = Mesh.loft(shapes)
        XCTAssertEqual(loft.polygons.count, 2)
        XCTAssert(loft.polygons.areWatertight)
    }

    func testLoftOffsetOpenPaths() {
        let shapes = [
            Path.line(Vector(0, 0), Vector(0, 1)),
            Path.line(Vector(0, 0, 1), Vector(0, 1, 1)),
        ]

        let loft = Mesh.loft(shapes)
        XCTAssertEqual(loft.polygons.count, 2)
        XCTAssert(loft.polygons.areWatertight)
    }

    func testLoftCoincidentOpenPaths() {
        let shapes = [
            Path.line(Vector(0, 0), Vector(0, 1)),
            Path.line(Vector(0, 0), Vector(0, 1)),
        ]

        let loft = Mesh.loft(shapes)
        XCTAssertEqual(loft, .empty)
    }

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
        XCTAssertEqual(mesh.polygons.count, 2)
        XCTAssertEqual(mesh, .extrude(path, faces: .front))
    }

    func testExtrudeOpenLine() {
        let path = Path([
            .point(0, 0),
            .point(0, 1),
        ])
        let mesh = Mesh.extrude(path)
        XCTAssertEqual(mesh.polygons.count, 2)
        XCTAssertEqual(mesh, .extrude(path, faces: .frontAndBack))
    }

    func testExtrudeOpenLineAlongClosedPath() {
        let path = Path([
            .point(0, 0),
            .point(0, 1),
        ])
        let mesh = Mesh.extrude(path, along: .square())
        XCTAssertEqual(mesh.polygons.count, 8)
        XCTAssertEqual(mesh, .extrude(path, along: .square(), faces: .frontAndBack))
    }

    func testExtrudeOpenLineAlongOpenPath() {
        let path = Path([
            .point(0, 0),
            .point(0, 1),
        ])
        let mesh = Mesh.extrude(path, along: path)
        XCTAssertEqual(mesh.polygons.count, 2)
        XCTAssertEqual(mesh, .extrude(path, along: path, faces: .frontAndBack))
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
}
