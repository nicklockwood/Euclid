//
//  ShapeTests.swift
//  GeometryScriptTests
//
//  Created by Nick Lockwood on 09/10/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

class PathShapeTests: XCTestCase {
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
        _ = Path.curve(points)
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

    // MARK: Rounded rect

    func testSimpleRoundedRect() {
        let path = Path.roundedRectangle(width: 1, height: 1, radius: 0.25)
        XCTAssert(path.isClosed)
        XCTAssertEqual(path.points.count, 21)
        XCTAssertEqual(path.bounds, Bounds(
            min: Vector(-0.5, -0.5),
            max: Vector(0.5, 0.5)
        ))
    }

    func testCircularRoundedRect() {
        let path = Path.roundedRectangle(width: 1, height: 1, radius: 0.5)
        XCTAssert(path.isClosed)
        XCTAssertEqual(path.points.count, 17)
        XCTAssertEqual(path.bounds, Bounds(
            min: Vector(-0.5, -0.5),
            max: Vector(0.5, 0.5)
        ))
    }

    func testPortraitRoundedRect() {
        let path = Path.roundedRectangle(width: 1, height: 2, radius: 0.5)
        XCTAssert(path.isClosed)
        XCTAssertEqual(path.points.count, 19)
        XCTAssertEqual(path.bounds, Bounds(
            min: Vector(-0.5, -1),
            max: Vector(0.5, 1)
        ))
    }

    func testLandscapeRoundedRect() {
        let path = Path.roundedRectangle(width: 2, height: 1, radius: 0.5)
        XCTAssert(path.isClosed)
        XCTAssertEqual(path.points.count, 19)
        XCTAssertEqual(path.bounds, Bounds(
            min: Vector(-1, -0.5),
            max: Vector(1, 0.5)
        ))
    }

    func testLowResRoundedRect() {
        let path = Path.roundedRectangle(width: 1, height: 1, radius: 0.25, detail: 1)
        XCTAssert(path.isClosed)
        XCTAssertEqual(path.points.count, 9)
        XCTAssertEqual(path.bounds, Bounds(
            min: Vector(-0.5, -0.5),
            max: Vector(0.5, 0.5)
        ))
    }

    func testZeroDetailRoundedRect() {
        let path = Path.roundedRectangle(width: 1, height: 1, radius: 0.5, detail: 0)
        XCTAssertEqual(path, Path(Path.rectangle(width: 1, height: 1).points.map {
            PathPoint.curve($0.position)
        }))
    }

    func testZeroRadiusRoundedRect() {
        let path = Path.roundedRectangle(width: 1, height: 1, radius: 0)
        XCTAssertEqual(path, .rectangle(width: 1, height: 1))
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

    func testStrokeSqaureWithTriangle() {
        let mesh = Mesh.stroke(.square(), detail: 3)
        XCTAssertEqual(mesh.polygons.count, 12)
    }
}
