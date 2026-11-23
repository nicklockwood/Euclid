//
//  MeshFillTests.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 06/02/2022.
//  Copyright © 2022 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

final class MeshFillTests: XCTestCase {
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

    func testFillSingleShapeArrayMatchesSingleShape() {
        let shape = Path.square().translated(by: [1, 2])
        XCTAssertEqual(Mesh.fill([shape]), Mesh.fill(shape))
    }

    func testFillQRCodeLikeCompoundPathPreservesColorsAndUsesSharedTexcoordBounds() {
        let shape = Path.qrCodeLikeCompoundPath.withColor(.red)
        let vertices = Mesh.fill(shape, faces: .front).polygons.flatMap(\.vertices)
        let flatteningPlane = shape.flatteningPlane
        let bounds = Bounds(shape.points.map {
            flatteningPlane.flattenPoint($0.position)
        })

        XCTAssertFalse(vertices.isEmpty)
        XCTAssertTrue(vertices.allSatisfy { vertex in
            let point = flatteningPlane.flattenPoint(vertex.position)
            let expectedTexcoord = Vector(
                (point.x - bounds.min.x) / bounds.size.x,
                1 - (point.y - bounds.min.y) / bounds.size.y
            )
            return vertex.color == .red && vertex.texcoord.isApproximatelyEqual(
                to: expectedTexcoord,
                absoluteTolerance: 1e-9
            )
        })
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
        XCTAssertFalse(front.polygons.triangulate { false }.isEmpty)
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

    func testCompoundPathUsesExplicitWindingRule() {
        let outer = Path.square(size: 4), inner = Path.square(size: 2)
        let path = Path(subpaths: [outer, inner], windingRule: .nonZero)
        let evenOdd = path.withWindingRule(.evenOdd)
        let hole = Path(subpaths: [outer, inner.inverted()], windingRule: .nonZero)

        XCTAssertEqual(path.facePolygons().surfaceArea, 16, accuracy: epsilon)
        XCTAssertEqual(evenOdd.facePolygons().surfaceArea, 12, accuracy: epsilon)
        XCTAssertEqual(hole.facePolygons().surfaceArea, 12, accuracy: epsilon)
        XCTAssertEqual(Mesh.fill(evenOdd, faces: .front).surfaceArea, 12, accuracy: epsilon)
        XCTAssertEqual(Mesh.fill(hole, faces: .front).surfaceArea, 12, accuracy: epsilon)

        let combined = Mesh.fill([path, evenOdd.translated(by: [5, 0])], faces: .front)
        XCTAssertEqual(combined.surfaceArea, 28, accuracy: epsilon)
    }

    func testPointCollectionPathUsesExplicitWindingRule() {
        let points = Path.square(size: 4).points + Path.square(size: 2).points
        let path = Path(points, windingRule: .nonZero)
        let colored = Path(points, windingRule: .evenOdd, color: .red)

        XCTAssertEqual([points].map(Path.init), [path.withWindingRule(.default)])
        XCTAssertEqual(path.subpaths.count, 2)
        XCTAssertEqual(Mesh.fill(path, faces: .front).surfaceArea, 16, accuracy: epsilon)
        XCTAssertEqual(Mesh.fill(colored, faces: .front).surfaceArea, 12, accuracy: epsilon)
        XCTAssertTrue(colored.points.allSatisfy { $0.color == .red })
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

    func testCompoundFillPollsForCancellation() {
        let first = Path.square()
        let second = Path.square().translated(by: [0.5, 0.5])
        nonisolated(unsafe) var cancellationChecks = 0
        let mesh = Mesh.fill(Path(subpaths: [first, second])) {
            cancellationChecks += 1
            return cancellationChecks > 2
        }

        XCTAssertTrue(mesh.isEmpty)
        XCTAssertGreaterThanOrEqual(cancellationChecks, 3)
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
}
