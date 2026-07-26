//
//  MeshShapeTests.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 06/02/2022.
//  Copyright © 2022 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

final class MeshShapeTests: XCTestCase {
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
        XCTAssertFalse(mesh.polygons.isEmpty)
        XCTAssertTrue(mesh.isWatertight)
        XCTAssertTrue(mesh.polygons.areWatertight)
    }

    func testFillSelfIntersectingCurvedPathUsesNonZeroWindingRule() {
        let path = Path([
            .curve(0, 0),
            .curve(1, 0),
            .curve(0, 2),
            .curve(1, 2),
            .curve(0, 0),
        ])
        let mesh = Mesh.fill(path)

        XCTAssertFalse(mesh.polygons.isEmpty)
        XCTAssertTrue(mesh.isWatertight)
        XCTAssertTrue(mesh.polygons.areWatertight)

        let front = Mesh.fill(path, faces: .front)
        XCTAssertFalse(front.polygons.isEmpty)
        XCTAssertFalse(front.polygons.triangulate().isEmpty)
        XCTAssertTrue(front.polygons.allSatisfy { $0.plane.normal == .unitZ })
        XCTAssertGreaterThan(front.polygons.surfaceArea, 0)
    }

    func testFillNestedCompoundPathUsesEvenOddRule() {
        let outer = Path([
            .point(0, 0),
            .point(10, 0),
            .point(10, 10),
            .point(0, 10),
            .point(0, 0),
        ])
        let inner = Path([
            .point(2, 2),
            .point(8, 2),
            .point(8, 8),
            .point(2, 8),
            .point(2, 2),
        ])
        let mesh = Mesh.fill(Path(subpaths: [outer, inner]))
        XCTAssertEqual(mesh.polygons.surfaceArea, 128)
        XCTAssertTrue(mesh.isWatertight)
        XCTAssertTrue(mesh.polygons.areWatertight)
    }

    func testFillOverlappingCompoundPathUsesEvenOddRule() {
        let first = Path([
            .point(0, 0),
            .point(10, 0),
            .point(10, 10),
            .point(0, 10),
            .point(0, 0),
        ])
        let second = Path([
            .point(5, 5),
            .point(15, 5),
            .point(15, 15),
            .point(5, 15),
            .point(5, 5),
        ])
        let mesh = Mesh.fill(Path(subpaths: [first, second]), faces: .front)
        XCTAssertEqual(mesh.polygons.surfaceArea, 150)
        XCTAssertFalse(mesh.isWatertight)
    }

    func testFillOverlappingCurvedCompoundPathUsesEvenOddRule() {
        let path = Path(subpaths: [
            .circle(segments: 32),
            .square().translated(by: [0.5, 0.5, 0]),
        ])
        let mesh = Mesh.fill(path, faces: .front)
        let evenOddMesh = Mesh.symmetricDifference(path.subpaths.map {
            Mesh.fill($0, faces: .front)
        })
        XCTAssertEqual(mesh.surfaceArea, evenOddMesh.surfaceArea, accuracy: epsilon)
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

    // MARK: Stroke

    func testStrokeLine() {
        let path = Path.line([-1, 0], [1, 0])
        let mesh = Mesh.stroke(path, detail: 2)
        XCTAssertEqual(mesh.polygons.count, 2)
    }

    func testStrokeLineSingleSided() {
        let path = Path.line([-1, 0], [1, 0])
        let mesh = Mesh.stroke(path, detail: 1)
        XCTAssertEqual(mesh.polygons.count, 1)
    }

    func testStrokeLineWithTriangle() {
        let path = Path.line([-1, 0], [1, 0])
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

    // MARK: Nearest point

    func testNearestPointOnConvexShape() {
        let cube = Mesh.cube()
        XCTAssertEqual(cube.nearestPoint(to: .zero), .zero)
        XCTAssertEqual(cube.nearestPoint(to: -.unitX), [-0.5, 0, 0])
        XCTAssertEqual(cube.nearestPoint(to: .unitZ), [0, 0, 0.5])
        XCTAssertEqual(cube.nearestPoint(to: [1, 1, 0]), [0.5, 0.5, 0])
        XCTAssertEqual(cube.nearestPoint(to: .one), [0.5, 0.5, 0.5])
    }

    func testNearestPointOnConcaveShape() {
        let detail = 16
        let radius = 0.5
        let torus = Mesh.lathe(
            .circle(radius: radius).translated(by: -.unitX * radius * 2),
            slices: detail
        )
        let shortest = cos(.pi / Double(detail)) * radius
        XCTAssertEqual(torus.nearestPoint(to: .zero).length, shortest)
        XCTAssertEqual(torus.nearestPoint(to: .unitX * radius), .unitX * radius)
        XCTAssertEqual(torus.nearestPoint(to: .unitX * radius * 2), .unitX * radius * 2)
        XCTAssertEqual(torus.nearestPoint(to: .unitX * radius * 3), .unitX * radius * 3)
        XCTAssertEqual(torus.nearestPoint(to: .unitX * radius * 4), .unitX * radius * 3)
    }
}
