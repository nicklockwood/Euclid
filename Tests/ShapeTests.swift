//
//  ShapeTests.swift
//  GeometryScriptTests
//
//  Created by Nick Lockwood on 09/10/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

class ShapeTests: XCTestCase {
    // MARK: Curve

    func testCurveWithConsecutiveMixedTypePointsWithSamePosition() {
        let points: [PathPoint] = [
            .point(-1, 1),
            .point(-1, -1),
            .point(1, -1),
            .curve(1, -1),
            .point(1, 1),
            .point(-1, 1),
        ]
        _ = Path(points)
    }

    func testSimpleCurvedPath() {
        let points: [PathPoint] = [
            .point(-1, -1),
            .curve(0, 1),
            .point(1, -1),
        ]
        XCTAssertEqual(Path.curve(points, detail: 0).points, points)
        XCTAssertEqual(Path.curve(points, detail: 1).points, [
            .point(-1, -1),
            .curve(-1 / 3, -1 / 9),
            .curve(1 / 3, -1 / 9),
            .point(1, -1),
        ] as [PathPoint])
        XCTAssertEqual(Path.curve(points, detail: 2).points, [
            .point(-1, -1),
            .curve(-0.5, -0.25),
            .curve(0, 0),
            .curve(0.5, -0.25),
            .point(1, -1),
        ])
    }

    func testSimpleCurveEndedPath() {
        let points: [PathPoint] = [
            .curve(0, 1),
            .point(-1, 0),
            .curve(0, -1),
        ]
        XCTAssertEqual(Path.curve(points, detail: 0).points, points)
        XCTAssertEqual(Path.curve(points, detail: 1).points, [
            .curve(0, 0.5),
            .point(-1, 0),
            .curve(0, -0.5),
        ])
    }

    func testClosedCurvedPath() {
        let points: [PathPoint] = [
            .curve(-1, 1),
            .curve(1, 1),
            .curve(1, -1),
            .curve(-1, -1),
            .curve(-1, 1),
        ]
        XCTAssertEqual(Path.curve(points, detail: 0).points, points)
        XCTAssertEqual(Path.curve(points, detail: 1).points, [
            .curve(-1, 0),
            .curve(-0.75, 0.75),
            .curve(0, 1),
            .curve(0.75, 0.75),
            .curve(1, 0),
            .curve(0.75, -0.75),
            .curve(0, -1),
            .curve(-0.75, -0.75),
            .curve(-1, 0),
        ])
    }

    func testClosedCurvedPathWithSharpFirstCorner() {
        let points: [PathPoint] = [
            .point(-1, 1),
            .curve(1, 1),
            .curve(1, -1),
            .curve(-1, -1),
            .point(-1, 1),
        ]
        XCTAssertEqual(Path.curve(points, detail: 0).points, points)
        XCTAssertEqual(Path.curve(points, detail: 1).points, [
            .point(-1, 1),
            .curve(0.5, 0.75),
            .curve(1, 0),
            .curve(0.75, -0.75),
            .curve(0, -1),
            .curve(-0.75, -0.5),
            .point(-1, 1),
        ])
    }

    func testClosedCurvedPathWithSharpSecondCorner() {
        let points: [PathPoint] = [
            .curve(-1, 1),
            .point(1, 1),
            .curve(1, -1),
            .curve(-1, -1),
            .curve(-1, 1),
        ]
        XCTAssertEqual(Path.curve(points, detail: 0).points, points)
        XCTAssertEqual(Path.curve(points, detail: 1).points, [
            .curve(-1, 0),
            .curve(-0.5, 0.75),
            .point(1, 1),
            .curve(0.75, -0.5),
            .curve(0, -1),
            .curve(-0.75, -0.75),
            .curve(-1, 0),
        ])
    }

    func testClosedCurvedPathWithSharpSecondAndThirdCorner() {
        let points: [PathPoint] = [
            .curve(-1, 1),
            .point(1, 1),
            .point(1, -1),
            .curve(-1, -1),
            .curve(-1, 1),
        ]
        XCTAssertEqual(Path.curve(points, detail: 0).points, points)
        XCTAssertEqual(Path.curve(points, detail: 1).points, [
            .curve(-1, 0),
            .curve(-0.5, 0.75),
            .point(1, 1),
            .point(1, -1),
            .curve(-0.5, -0.75),
            .curve(-1, 0),
        ])
    }

    // MARK: Circle

    func testCircleIsClosed() {
        let path = Path.circle(radius: 0.50, segments: 25)
        XCTAssert(path.isClosed)
    }

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
        XCTAssertEqual(mesh.polygons.first?.plane.normal, Vector(0, 0, 1))
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
        XCTAssertEqual(mesh.polygons.first?.plane.normal, Vector(0, 0, -1))
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
        XCTAssert(mesh.polygons.isEmpty)
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
}
