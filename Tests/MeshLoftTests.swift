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
    func testLoftParallelFaces() {
        let shapes = [
            Path.square(),
            Path.square().translated(by: [0.0, 1.0, 0.0]),
        ]

        let loft = Mesh.loft(shapes)
        XCTAssertTrue(loft.isWatertight) // TODO: not sure this is right?
        XCTAssertEqual(loft.watertightIfSet, true)
        XCTAssertTrue(loft.polygons.areWatertight)
        XCTAssertEqual(loft.polygons.count, 4)
        XCTAssertEqual(loft.signedVolume, 0)
        XCTAssertFalse(loft.isKnownConvex)
        XCTAssertFalse(loft.isActuallyConvex)

        let loft2 = Mesh.loft(shapes, faces: .front)
        XCTAssertTrue(loft2.isWatertight) // TODO: not sure this is right?
        XCTAssertEqual(loft2.watertightIfSet, true)
        XCTAssertTrue(loft2.polygons.areWatertight)
        XCTAssertEqual(loft2.polygons.count, loft.polygons.count)
        XCTAssertEqual(loft2.signedVolume, loft.signedVolume)
        XCTAssertFalse(loft2.isKnownConvex)
        XCTAssertFalse(loft2.isActuallyConvex)

        // Every vertex in the loft should be contained by one of our shapes
        let vertices = loft.polygons.flatMap(\.vertices)
        XCTAssert(vertices.allSatisfy { vertex in
            shapes.contains(where: {
                $0.points.contains(where: { $0.position == vertex.position })
            })
        })
    }

    func testLoftOrthogonalFaces() {
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
        XCTAssertTrue(loft.isWatertight) // TODO: not sure this is right?
        XCTAssertEqual(loft.watertightIfSet, true)
        XCTAssertTrue(loft.polygons.areWatertight)
        XCTAssertEqual(loft.polygons.count, 10)
        XCTAssertGreaterThan(loft.signedVolume, 0)
        XCTAssertFalse(loft.isKnownConvex)
        XCTAssertFalse(loft.isActuallyConvex)

        let loft2 = Mesh.loft(shapes, faces: .front)
        XCTAssertTrue(loft2.isWatertight) // TODO: not sure this is right?
        XCTAssertEqual(loft2.watertightIfSet, true)
        XCTAssertTrue(loft2.polygons.areWatertight)
        XCTAssertEqual(loft2.polygons.count, loft.polygons.count)
        XCTAssertEqual(loft2.signedVolume, loft.signedVolume)
        XCTAssertFalse(loft2.isKnownConvex)
        XCTAssertFalse(loft2.isActuallyConvex)

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

    func testLoftNonParallelFaces2() {
        let shapes = [
            Path.circle().rotated(by: Rotation(yaw: .pi / 8)),
            Path.circle().rotated(by: Rotation(yaw: -.pi / 8))
                .translated(by: [0, 0, 1]),
        ]

        let loft = Mesh.loft(shapes)
        XCTAssertTrue(loft.isWatertight)
        XCTAssertTrue(loft.polygons.areWatertight)
        XCTAssertEqual(loft.polygons.count, 18)
        XCTAssertGreaterThan(loft.signedVolume, 0)
        XCTAssertFalse(loft.isKnownConvex) // can't determine this yet
        XCTAssertTrue(loft.isActuallyConvex)

        let loft2 = Mesh.loft(shapes, faces: .front)
        XCTAssertTrue(loft2.isWatertight)
        XCTAssertTrue(loft2.polygons.areWatertight)
        XCTAssertEqual(loft2.polygons.count, loft.polygons.count)
        XCTAssertEqual(loft2.signedVolume, loft.signedVolume)
        XCTAssertFalse(loft2.isKnownConvex)
        XCTAssertTrue(loft2.isActuallyConvex)
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
        XCTAssertEqual(loft.signedVolume, 0)
        XCTAssertTrue(loft.isKnownConvex)
        XCTAssertTrue(loft.isActuallyConvex)

        let loft2 = Mesh.loft(shapes, faces: .front)
        XCTAssertEqual(loft2.polygons.count, 1)
        XCTAssertFalse(loft2.isWatertight)
        XCTAssertFalse(loft2.polygons.areWatertight)
        XCTAssertEqual(loft2.polygons.count, 1)
        XCTAssertEqual(loft2.signedVolume, 0)
        XCTAssertTrue(loft2.isKnownConvex)
        XCTAssertTrue(loft2.isActuallyConvex)
    }

    func testLoftOffsetEdges() {
        let shapes = [
            Path.line(.zero, [0, 1]),
            Path.line([0, 0, 1], [0, 1, 1]),
        ]

        let loft = Mesh.loft(shapes)
        XCTAssertEqual(loft.polygons.count, 2)
        XCTAssert(loft.isWatertight)
        XCTAssert(loft.polygons.areWatertight)
        XCTAssertEqual(loft.signedVolume, 0)
        XCTAssertFalse(loft.isKnownConvex) // can't determine this yet
        XCTAssertTrue(loft.isActuallyConvex)

        let loft2 = Mesh.loft(shapes, faces: .front)
        XCTAssertEqual(loft2.polygons.count, 1)
        XCTAssertFalse(loft2.isWatertight)
        XCTAssertFalse(loft2.polygons.areWatertight)
        XCTAssertEqual(loft2.signedVolume, 0)
        XCTAssertFalse(loft2.isKnownConvex)
        XCTAssertTrue(loft2.isActuallyConvex)
    }

    func testLoftCoincidentEdges() {
        let shapes = [
            Path.line([0, 0], [0, 1]),
            Path.line([0, 0], [0, 1]),
        ]

        let loft = Mesh.loft(shapes)
        XCTAssertEqual(loft, .empty)
        XCTAssert(loft.isWatertight)
        XCTAssert(loft.polygons.areWatertight)
        XCTAssertEqual(loft.signedVolume, 0)
        XCTAssertTrue(loft.isKnownConvex)
        XCTAssertTrue(loft.isActuallyConvex)
    }

    func testLoftEmptyPathsArray() {
        let loft = Mesh.loft([])
        XCTAssertEqual(loft, .empty)
        XCTAssertEqual(loft.signedVolume, 0)
        XCTAssertTrue(loft.isKnownConvex)
        XCTAssertTrue(loft.isActuallyConvex)
    }

    func testLoftSinglePath() {
        let loft = Mesh.loft([.circle()])
        XCTAssertEqual(loft, .fill(.circle()))
        XCTAssert(loft.isWatertight)
        XCTAssert(loft.polygons.areWatertight)
        XCTAssert(loft.isKnownConvex)
        XCTAssert(loft.isActuallyConvex)
    }

    func testLoftCircleToSquare() {
        let shapes = [
            Path.circle(),
            Path.square().translated(by: [0, 0, 1]),
        ]

        let loft = Mesh.loft(shapes)
        XCTAssert(loft.isWatertight)
        XCTAssert(loft.polygons.areWatertight)
        XCTAssertEqual(loft.polygons.count, 22)
        XCTAssertFalse(loft.isKnownConvex) // can't determine this yet
        XCTAssertTrue(loft.isActuallyConvex)
    }

    func testLoftSquareToCircle() {
        let shapes = [
            Path.square(),
            Path.circle().translated(by: [0, 0, 1]),
        ]

        let loft = Mesh.loft(shapes)
        XCTAssert(loft.isWatertight)
        XCTAssert(loft.polygons.areWatertight)
        XCTAssertEqual(loft.polygons.count, 22)
        XCTAssertFalse(loft.isKnownConvex) // can't determine this yet
        XCTAssertTrue(loft.isActuallyConvex)
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
        XCTAssertGreaterThan(loft.signedVolume, 0)
        XCTAssertFalse(loft.isKnownConvex) // can't determine this yet
        XCTAssertTrue(loft.isActuallyConvex)

        let loft2 = Mesh.loft(shapes, faces: .front)
        XCTAssert(loft2.isWatertight)
        XCTAssert(loft2.polygons.areWatertight)
        XCTAssertEqual(loft2.polygons.count, loft.polygons.count)
        XCTAssertFalse(loft2.isKnownConvex) // can't determine this yet
        XCTAssertTrue(loft2.isActuallyConvex)
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
        XCTAssertEqual(loft.signedVolume, 0)
        XCTAssertFalse(loft.isKnownConvex)
        XCTAssertFalse(loft.isActuallyConvex)

        let loft2 = Mesh.loft(shapes, faces: .front)
        XCTAssertFalse(loft2.isWatertight)
        XCTAssertFalse(loft2.polygons.areWatertight)
        XCTAssertEqual(loft2.polygons.count, 20)
        XCTAssertNotEqual(loft2.signedVolume, 0) // should be zero, but not reliable for non-watertight shape
        XCTAssertFalse(loft.isKnownConvex)
        XCTAssertFalse(loft.isActuallyConvex)
    }

    func testLoftClosedPathToCircle() {
        let shapes = [
            Path([
                .point(-1, -1),
                .point(1, -1),
                .point(1, 1),
                .point(-1, -1),
            ]),
            Path.circle().translated(by: [0, 0, 1]),
        ]

        let loft = Mesh.loft(shapes)
        XCTAssert(loft.isWatertight)
        XCTAssert(loft.polygons.areWatertight)
        XCTAssertEqual(loft.polygons.count, 21)
        XCTAssertFalse(loft.isKnownConvex) // can't determine this yet
        XCTAssertTrue(loft.isActuallyConvex)
    }

    func testLoftOpenPathToCircle() {
        let shapes = [
            Path([
                .point(-1, -1),
                .point(1, -1),
                .point(1, 1),
                .point(-1, 1),
            ]),
            Path.circle().translated(by: [0, 0, 1]),
        ]

        let loft = Mesh.loft(shapes)
        XCTAssert(loft.isWatertight)
        XCTAssert(loft.polygons.areWatertight)
        XCTAssertEqual(loft.polygons.count, 40)
        XCTAssertEqual(loft.signedVolume, 0)
        XCTAssertFalse(loft.isKnownConvex)
        XCTAssertFalse(loft.isActuallyConvex)

        let loft2 = Mesh.loft(shapes, faces: .front)
        XCTAssertFalse(loft2.isWatertight)
        XCTAssertFalse(loft2.polygons.areWatertight)
        XCTAssertEqual(loft2.polygons.count, 20)
        XCTAssertGreaterThan(loft2.signedVolume, 0) // should be zero, but not reliable for non-watertight shape
        XCTAssertFalse(loft2.isKnownConvex)
        XCTAssertFalse(loft2.isActuallyConvex)
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
            Path.square().translated(by: [0, 0, 2]),
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
        XCTAssertFalse(loft.isKnownConvex) // can't determine this yet
        XCTAssertTrue(loft.isActuallyConvex)
    }
}
