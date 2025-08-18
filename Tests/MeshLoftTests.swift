//
//  MeshLoftTests.swift
//  Euclid
//
//  Created by Nick Lockwood on 17/06/2025.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

class MeshLoftTests: XCTestCase {
    func testLoftParallelEdges() {
        let shapes = [
            Path.square(),
            Path.square().translated(by: Vector(0.0, 1.0, 0.0)),
        ]

        let loft = Mesh.loft(shapes)
        XCTAssert(loft.isWatertight)
        XCTAssert(loft.polygons.areWatertight)
        XCTAssertEqual(loft.polygons.count, 4)
        XCTAssertEqual(loft.volume, 0)
        XCTAssert(loft.isActuallyConvex)
        XCTAssertFalse(loft.isKnownConvex) // can't determine this yet

        let loft2 = Mesh.loft(shapes, faces: .front)
        XCTAssert(loft2.isWatertight)
        XCTAssert(loft2.polygons.areWatertight)
        XCTAssertEqual(loft2.polygons.count, loft.polygons.count)
        XCTAssertEqual(loft2.volume, loft.volume)

        // Every vertex in the loft should be contained by one of our shapes
        let vertices = loft.polygons.flatMap(\.vertices)
        XCTAssert(vertices.allSatisfy { vertex in
            shapes.contains(where: {
                $0.points.contains(where: { $0.position == vertex.position })
            })
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
        XCTAssert(loft.isWatertight)
        XCTAssert(loft.polygons.areWatertight)
        XCTAssertEqual(loft.polygons.count, 10)
        XCTAssertGreaterThan(loft.volume, 0)
        XCTAssertFalse(loft.isActuallyConvex)
        XCTAssertFalse(loft.isKnownConvex)

        let loft2 = Mesh.loft(shapes, faces: .front)
        XCTAssert(loft2.isWatertight)
        XCTAssert(loft2.polygons.areWatertight)
        XCTAssertEqual(loft2.polygons.count, loft.polygons.count)
        XCTAssertEqual(loft2.volume, loft.volume)

        XCTAssert(loft.polygons.allSatisfy { polygon in
            polygon.vertices.allSatisfy(polygon.plane.intersects)
        })

        // Every vertex in the loft should be contained by one of our shapes
        let vertices = loft.polygons.flatMap(\.vertices)
        XCTAssert(vertices.allSatisfy { vertex in
            shapes.contains(where: {
                $0.points.contains(where: { $0.position == vertex.position })
            })
        })
    }

    func testLoftNonParallelEdges2() {
        let shapes = [
            Path.circle().rotated(by: Rotation(yaw: .pi / 8)),
            Path.circle().rotated(by: Rotation(yaw: -.pi / 8))
                .translated(by: Vector(0, 0, 1)),
        ]

        let loft = Mesh.loft(shapes)
        XCTAssert(loft.isWatertight)
        XCTAssert(loft.polygons.areWatertight)
        XCTAssertEqual(loft.polygons.count, 18)
        XCTAssertGreaterThan(loft.volume, 0)
        XCTAssert(loft.isActuallyConvex)
        XCTAssertFalse(loft.isKnownConvex) // can't determine this yet

        let loft2 = Mesh.loft(shapes, faces: .front)
        XCTAssert(loft2.isWatertight)
        XCTAssert(loft2.polygons.areWatertight)
        XCTAssertEqual(loft2.polygons.count, loft.polygons.count)
        XCTAssertEqual(loft2.volume, loft.volume)
    }

    func testLoftCoincidentClosedPaths() {
        let shapes = [
            Path.square(),
            Path.square(),
        ]

        let loft = Mesh.loft(shapes)
        XCTAssert(loft.isWatertight)
        XCTAssert(loft.polygons.areWatertight)
        XCTAssertEqual(loft.polygons.count, 2)
        XCTAssertEqual(loft.volume, 0)
        XCTAssert(loft.isActuallyConvex)
        XCTAssert(loft.isKnownConvex)

        let loft2 = Mesh.loft(shapes, faces: .front)
        XCTAssertEqual(loft2.polygons.count, 1)
        XCTAssertFalse(loft2.isWatertight)
        XCTAssertFalse(loft2.polygons.areWatertight)
        XCTAssertEqual(loft2.polygons.count, 1)
        XCTAssertEqual(loft2.volume, 0)
        XCTAssertFalse(loft2.isActuallyConvex)
        XCTAssertFalse(loft2.isKnownConvex)
    }

    func testLoftOffsetOpenPaths() {
        let shapes = [
            Path.line(Vector(0, 0), Vector(0, 1)),
            Path.line(Vector(0, 0, 1), Vector(0, 1, 1)),
        ]

        let loft = Mesh.loft(shapes)
        XCTAssertEqual(loft.polygons.count, 2)
        XCTAssert(loft.isWatertight)
        XCTAssert(loft.polygons.areWatertight)
        XCTAssertEqual(loft.volume, 0)
        XCTAssert(loft.isActuallyConvex)
        XCTAssertFalse(loft.isKnownConvex) // can't determine this yet

        let loft2 = Mesh.loft(shapes, faces: .front)
        XCTAssertEqual(loft2.polygons.count, 1)
        XCTAssertFalse(loft2.isWatertight)
        XCTAssertFalse(loft2.polygons.areWatertight)
        XCTAssertEqual(loft2.volume, 0)
        XCTAssertFalse(loft2.isActuallyConvex)
        XCTAssertFalse(loft2.isKnownConvex)
    }

    func testLoftCoincidentOpenPaths() {
        let shapes = [
            Path.line(Vector(0, 0), Vector(0, 1)),
            Path.line(Vector(0, 0), Vector(0, 1)),
        ]

        let loft = Mesh.loft(shapes)
        XCTAssertEqual(loft, .empty)
        XCTAssert(loft.isWatertight)
        XCTAssert(loft.polygons.areWatertight)
        XCTAssertEqual(loft.volume, 0)
        XCTAssert(loft.isActuallyConvex)
        XCTAssert(loft.isKnownConvex)
    }

    func testLoftEmptyPathsArray() {
        let loft = Mesh.loft([])
        XCTAssertEqual(loft, .empty)
    }

    func testLoftSinglePath() {
        let loft = Mesh.loft([.circle()])
        XCTAssertEqual(loft, .fill(.circle()))
        XCTAssert(loft.isWatertight)
        XCTAssert(loft.polygons.areWatertight)
        XCTAssert(loft.isActuallyConvex)
        XCTAssert(loft.isKnownConvex)
    }

    func testLoftCircleToSquare() {
        let shapes = [
            Path.circle(),
            Path.square().translated(by: Vector(0, 0, 1)),
        ]

        let loft = Mesh.loft(shapes)
        XCTAssert(loft.isWatertight)
        XCTAssert(loft.polygons.areWatertight)
        XCTAssertEqual(loft.polygons.count, 22)
    }

    func testLoftSquareToCircle() {
        let shapes = [
            Path.square(),
            Path.circle().translated(by: Vector(0, 0, 1)),
        ]

        let loft = Mesh.loft(shapes)
        XCTAssert(loft.isWatertight)
        XCTAssert(loft.polygons.areWatertight)
        XCTAssertEqual(loft.polygons.count, 22)
        XCTAssert(loft.isActuallyConvex)
        XCTAssertFalse(loft.isKnownConvex) // can't determine this yet
    }

    func testLoftCircleToClosedPath() {
        let shapes = [
            Path.circle(),
            Path([
                .point(-1, -1, 1),
                .point(1, -1, 1),
                .point(1, 1, 1),
                .point(-1, -1, 1),
            ]),
        ]

        let loft = Mesh.loft(shapes)
        XCTAssert(loft.isWatertight)
        XCTAssert(loft.polygons.areWatertight)
        XCTAssertEqual(loft.polygons.count, 21)
        XCTAssertGreaterThan(loft.volume, 0)
        XCTAssert(loft.isActuallyConvex)
        XCTAssertFalse(loft.isKnownConvex) // can't determine this yet

        let loft2 = Mesh.loft(shapes, faces: .front)
        XCTAssert(loft2.isWatertight)
        XCTAssert(loft2.polygons.areWatertight)
        XCTAssertEqual(loft2.polygons.count, loft.polygons.count)
    }

    func testLoftCircleToOpenPath() {
        let shapes = [
            Path.circle(),
            Path([
                .point(-1, -1, 1),
                .point(1, -1, 1),
                .point(1, 1, 1),
                .point(-1, 1, 1),
            ]),
        ]

        let loft = Mesh.loft(shapes)
        XCTAssert(loft.isWatertight)
        XCTAssert(loft.polygons.areWatertight)
        XCTAssertEqual(loft.polygons.count, 40)
        XCTAssertEqual(loft.volume, 0, accuracy: epsilon)
        XCTAssertFalse(loft.isActuallyConvex)
        XCTAssertFalse(loft.isKnownConvex)

        let loft2 = Mesh.loft(shapes, faces: .front)
        XCTAssertFalse(loft2.isWatertight)
        XCTAssertFalse(loft2.polygons.areWatertight)
        XCTAssertEqual(loft2.polygons.count, 20)
        XCTAssertNotEqual(loft2.volume, 0) // should be zero, but not reliable for non-watertight shape
    }

    func testLoftClosedPathToCircle() {
        let shapes = [
            Path([
                .point(-1, -1),
                .point(1, -1),
                .point(1, 1),
                .point(-1, -1),
            ]),
            Path.circle().translated(by: Vector(0, 0, 1)),
        ]

        let loft = Mesh.loft(shapes)
        XCTAssert(loft.isWatertight)
        XCTAssert(loft.polygons.areWatertight)
        XCTAssertEqual(loft.polygons.count, 21)
        XCTAssert(loft.isActuallyConvex)
        XCTAssertFalse(loft.isKnownConvex) // can't determine this yet
    }

    func testLoftOpenPathToCircle() {
        let shapes = [
            Path([
                .point(-1, -1),
                .point(1, -1),
                .point(1, 1),
                .point(-1, 1),
            ]),
            Path.circle().translated(by: Vector(0, 0, 1)),
        ]

        let loft = Mesh.loft(shapes)
        XCTAssert(loft.isWatertight)
        XCTAssert(loft.polygons.areWatertight)
        XCTAssertEqual(loft.polygons.count, 40)
        XCTAssertEqual(loft.volume, 0, accuracy: epsilon)
        XCTAssertFalse(loft.isActuallyConvex)
        XCTAssertFalse(loft.isKnownConvex)

        let loft2 = Mesh.loft(shapes, faces: .front)
        XCTAssertFalse(loft2.isWatertight)
        XCTAssertFalse(loft2.polygons.areWatertight)
        XCTAssertEqual(loft2.polygons.count, 20)
        XCTAssertGreaterThan(loft2.volume, 0) // should be zero, but not reliable for non-watertight shape
    }

    func testLoftClosedToOpenToClosedPath() {
        let shapes = [
            Path.square(),
            Path([
                .point(-1, -1, 1),
                .point(1, -1, 1),
                .point(1, 1, 1),
                .point(-1, 1, 1),
            ]),
            Path.square().translated(by: Vector(0, 0, 2)),
        ]

        let loft = Mesh.loft(shapes)
        XCTAssert(loft.isWatertight)
        XCTAssert(loft.polygons.areWatertight)
        XCTAssertEqual(loft.polygons.count, 20)
    }

    func testLoftEmptyPathToPath() {
        let shapes = [
            Path.empty,
            Path.square(),
        ]

        let loft = Mesh.loft(shapes)
        XCTAssert(loft.isWatertight)
        XCTAssert(loft.polygons.areWatertight)
        XCTAssertEqual(loft.polygons.count, 2)
    }

    func testLoftPathToEmptyPath() {
        let shapes = [
            Path.square(),
            Path.empty,
        ]

        let loft = Mesh.loft(shapes)
        XCTAssert(loft.isWatertight)
        XCTAssert(loft.polygons.areWatertight)
        XCTAssertEqual(loft.polygons.count, 2)
    }

    func testLoftSquareToLine() {
        let shapes = [
            Path.square(),
            Path([
                .point(0, 0.5, -1),
                .point(1, 0.5, -1),
                .point(0, 0.5, -1),
            ]),
        ]

        let loft = Mesh.loft(shapes)
        XCTAssert(loft.isWatertight)
        XCTAssert(loft.polygons.areWatertight)
        XCTAssertEqual(loft.polygons.count, 5)
    }

    func testLoftLineToSquare() {
        let shapes = [
            Path([
                .point(0, 0.5, -1),
                .point(1, 0.5, -1),
                .point(0, 0.5, -1),
            ]),
            Path.square(),
        ]

        let loft = Mesh.loft(shapes)
        XCTAssert(loft.isWatertight)
        XCTAssert(loft.polygons.areWatertight)
        XCTAssertEqual(loft.polygons.count, 5)
    }
}
