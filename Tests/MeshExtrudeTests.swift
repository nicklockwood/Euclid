//
//  MeshExtrudeTests.swift
//  Euclid
//
//  Created by Nick Lockwood on 26/07/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

final class MeshExtrudeTests: XCTestCase {
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
    }

    func testExtrudeSingleShapeArrayMatchesSingleShape() {
        let shape = Path.circle(segments: 8).translated(by: [1, 2])

        XCTAssertEqual(
            Mesh.extrude([shape], depth: 2, twist: .degrees(90), sections: 2),
            Mesh.extrude(shape, depth: 2, twist: .degrees(90), sections: 2)
        )
    }

    func testExtrudeClosedPathWithRepeatedPrefixTailMatchesTrimmedPath() {
        let expected = Path.circle(segments: 300)
        let path = Path(expected.points + expected.points.dropFirst().prefix(8))

        XCTAssertEqual(Mesh.extrude(path), Mesh.extrude(expected))
    }

    func testZeroDepthExtrudeClosedPathWithRepeatedPrefixTailMatchesTrimmedFill() {
        let expected = Path.circle(segments: 300)
        let path = Path(expected.points + expected.points.dropFirst().prefix(8))

        XCTAssertEqual(Mesh.extrude(path, depth: 0), Mesh.fill(expected))
    }

    func testExtrudeCompoundPathWithRepeatedPrefixTailMatchesTrimmedPath() {
        let expected = Path.circle(segments: 300)
        let path = Path(subpaths: [
            expected,
            Path(Array(expected.points.dropFirst().prefix(8))),
        ])

        XCTAssertEqual(Mesh.extrude(path), Mesh.extrude(expected))
    }

    func testTwistedExtrudeCalculatesSectionsIfUnspecified() {
        let shape = Path.square()

        XCTAssertEqual(
            Mesh.extrude(shape, twist: .pi),
            Mesh.extrude(shape, twist: .pi, sections: 8)
        )
    }

    func testNegativeTwistedExtrudeCalculatesSectionsFromMagnitude() {
        let shape = Path.square()

        XCTAssertEqual(
            Mesh.extrude(shape, twist: -.halfPi),
            Mesh.extrude(shape, twist: -.halfPi, sections: 4)
        )
    }

    func testTwistedExtrudeSingleShapeArrayCalculatesSectionsIfUnspecified() {
        let shape = Path.square().translated(by: [1, 2])

        XCTAssertEqual(
            Mesh.extrude([shape], twist: .twoPi),
            Mesh.extrude(shape, twist: .twoPi, sections: 16)
        )
    }

    func testTwistedExtrudeShapeCollectionPreservesPathOffsets() {
        let shapes = [
            Path.square().translated(by: [-2, 0]),
            Path.square().translated(by: [2, 0]),
        ]

        XCTAssertEqual(
            Mesh.extrude(shapes, twist: .pi, sections: 8),
            Mesh.union(shapes.map { Mesh.extrude($0, twist: .pi, sections: 8) })
        )
    }

    func testExtrudeSelfIntersectingCurvedPathUsesNonZeroWindingRule() {
        let path = Path.curve([
            .curve(0, 0),
            .curve(1, 0),
            .curve(0, 2),
            .curve(1, 2),
            .curve(0, 0),
        ])
        let mesh = Mesh.extrude(path, depth: 1)
        XCTAssertFalse(mesh.polygons.isEmpty)
        XCTAssertTrue(mesh.isWatertight)
        XCTAssertTrue(mesh.isConsistentlyWound)
        XCTAssertTrue(mesh.vertexNormalsFaceOutward)
    }

    func testSelfIntersectingExtrudedPathAlignsNonZeroFillBoundaryEdges() {
        let points: [PathPoint] = [
            .point(0, 0),
            .point(1, 0),
            .point(1, 4),
            .point(3, 4),
            .point(3, 3),
            .point(0.5, 3),
            .point(0.5, 2),
            .point(4, 2),
            .point(4, 5),
            .point(0, 5),
            .point(0, 0),
        ]
        let path = Path(unchecked: points, plane: .xy)
        let fillPolygons = path.nonZeroFillPolygons(material: nil)
        let rawBoundaryEdges = fillPolygons.boundingEdges
        let alignedBoundaryEdges = fillPolygons
            .insertingEdgeVertices(with: fillPolygons.holeEdges)
            .boundingEdges

        func signature(for polygon: Euclid.Polygon) -> [Vector] {
            polygon.vertices.map {
                Vector(
                    ($0.position.x * 1e10).rounded() / 1e10,
                    ($0.position.y * 1e10).rounded() / 1e10
                )
            }.sorted()
        }
        func signature(for edge: LineSegment) -> [Vector] {
            [edge.start, edge.end].map {
                Vector(
                    ($0.x * 1e10).rounded() / 1e10,
                    ($0.y * 1e10).rounded() / 1e10
                )
            }.sorted()
        }
        func sideEdgeSignatures(in mesh: Mesh) -> Set<[Vector]> {
            Set(mesh.polygons.compactMap { polygon in
                guard abs(polygon.plane.normal.z) < 0.5 else {
                    return nil
                }
                let positions = Set(polygon.vertices.map {
                    Vector(
                        ($0.position.x * 1e10).rounded() / 1e10,
                        ($0.position.y * 1e10).rounded() / 1e10
                    )
                })
                guard positions.count == 2 else {
                    return nil
                }
                return positions.sorted()
            })
        }
        func boundaryEdgeSignatures(for polygons: [Euclid.Polygon]) -> Set<[Vector]> {
            Set(polygons.boundingEdges.map(signature))
        }
        func totalArea(of polygons: [Euclid.Polygon]) -> Double {
            (polygons.reduce(0) { $0 + $1.area } * 1e10).rounded() / 1e10
        }
        let filledPolygons = Mesh.fill(path, faces: .front).polygons
        let extrudedMesh = Mesh.extrude(path).makeWatertight()
        let extrudedCapPolygons = extrudedMesh.polygons.filter {
            abs($0.plane.normal.z) > 0.5
        }
        let along = Path.line([0, 0, -0.5], [0, 0, 0.5])
        let extrudedAlongMesh = Mesh.extrude(path, along: along).makeWatertight()
        let extrudedAlongCapPolygons = extrudedAlongMesh.polygons.filter {
            abs($0.plane.normal.z) > 0.5
        }
        let expectedSideEdges = Set(alignedBoundaryEdges.map(signature))

        XCTAssertTrue(path.usesNonZeroFill)
        XCTAssertEqual(Set(rawBoundaryEdges.map(signature)), expectedSideEdges)
        XCTAssertEqual(path.nonZeroFillBoundaryWithAlignedEdges?.subpaths.count, 2)
        XCTAssertEqual(boundaryEdgeSignatures(for: extrudedCapPolygons), expectedSideEdges)
        XCTAssertEqual(boundaryEdgeSignatures(for: extrudedAlongCapPolygons), expectedSideEdges)
        XCTAssertEqual(totalArea(of: extrudedCapPolygons), totalArea(of: filledPolygons) * 2)
        XCTAssertEqual(totalArea(of: extrudedAlongCapPolygons), totalArea(of: filledPolygons) * 2)
        XCTAssertEqual(sideEdgeSignatures(in: extrudedMesh), expectedSideEdges)
        XCTAssertEqual(sideEdgeSignatures(in: extrudedAlongMesh), expectedSideEdges)
    }

    func testExtrudeCurvedCompoundPathWithDegenerateSubpath() {
        let path = Path(subpaths: [
            Path([.point(0, 0)]),
            Path.circle(segments: 8),
        ])

        let mesh = Mesh.extrude(path, depth: 1)
        XCTAssertFalse(mesh.polygons.isEmpty)
        XCTAssertTrue(mesh.isWatertight)
        XCTAssertTrue(mesh.polygons.areWatertight)
    }

    func testExtrudeNestedCompoundPathUsesEvenOddRule() {
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
        var mesh = Mesh.extrude(Path(subpaths: [outer, inner]), depth: 1)
        XCTAssertEqual(mesh.polygons.surfaceArea, 192)
        XCTAssertFalse(mesh.isWatertight)
        mesh = mesh.makeWatertight()
        XCTAssertTrue(mesh.isWatertight)
    }

    func testExtrudeNestedCompoundPathWithDoubledBackSegmentDoesNotAssert() {
        let outer = Path([
            .point(0, 0),
            .point(20, 0),
            .point(20, 20),
            .point(0, 20),
            .point(0, 0),
        ])
        let inner = Path([
            .point(4, 4),
            .point(16, 4),
            .point(16, 10),
            .point(10, 10),
            .point(16, 10),
            .point(16, 16),
            .point(4, 16),
            .point(4, 4),
        ])
        let path = Path(subpaths: [outer, inner])
        let mesh = Mesh.extrude(path, depth: 8).makeWatertight()
        let capArea = Mesh(mesh.polygons.filter {
            abs($0.plane.normal.z) > 0.5
        }).surfaceArea

        XCTAssertFalse(mesh.polygons.isEmpty)
        XCTAssertTrue(mesh.isWatertight)
        XCTAssertTrue(mesh.isConsistentlyWound)
        XCTAssertEqual(capArea, Mesh.fill(path).surfaceArea, accuracy: epsilon)
    }

    func testExtrudeInvertedNestedCompoundPathWithDoubledBackSegmentDoesNotAssert() {
        let outer = Path([
            .point(0, 0),
            .point(20, 0),
            .point(20, 20),
            .point(0, 20),
            .point(0, 0),
        ])
        let inner = Path([
            .point(4, 4),
            .point(16, 4),
            .point(16, 10),
            .point(10, 10),
            .point(16, 10),
            .point(16, 16),
            .point(4, 16),
            .point(4, 4),
        ])
        let path = Path(subpaths: [outer, inner]).inverted()
        let mesh = Mesh.extrude(path, depth: 8).makeWatertight()
        XCTAssertFalse(mesh.polygons.isEmpty)
        XCTAssertTrue(mesh.isWatertight)
        XCTAssertTrue(mesh.isConsistentlyWound)
    }

    func testExtrudeOverlappingCompoundPathUsesEvenOddRule() {
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
        var mesh = Mesh.extrude(Path(subpaths: [first, second]), depth: 1)
        XCTAssertEqual(mesh.polygons.surfaceArea, 380)
        XCTAssertFalse(mesh.isWatertight)
        mesh = mesh.makeWatertight()
        XCTAssertTrue(mesh.isWatertight)
    }

    func testExtrudeOverlappingMultiCompoundPathUsesEvenOddRule() {
        let path = Path(subpaths: [
            .square(),
            .square().translated(by: [0.5, 0.5, 0]),
            .square().translated(by: [0.5, -0.5, 0]),
        ])
        let mesh = Mesh.extrude(path, depth: 8).makeWatertight()
        let expected = Mesh.symmetricDifference(path.subpaths.map {
            Mesh.extrude($0, depth: 8)
        }).makeWatertight()

        XCTAssertEqual(mesh.surfaceArea, expected.surfaceArea, accuracy: epsilon)
    }

    func testExtrudeOverlappingCurvedCompoundPathCapUsesEvenOddRule() {
        let path = Path(subpaths: [
            .circle(segments: 32),
            .circle(segments: 32).translated(by: [0.5, 0.5, 0]),
        ])
        let mesh = Mesh.extrude(path, depth: 8).makeWatertight()
        let capArea = Mesh(mesh.polygons.filter {
            abs($0.plane.normal.z) > 0.5
        }).surfaceArea

        XCTAssertEqual(capArea, Mesh.fill(path).surfaceArea, accuracy: epsilon)
    }

    func testExtrudeOverlappingMixedCompoundPathCapUsesEvenOddRule() {
        let path = Path(subpaths: [
            .circle(segments: 32),
            .square().translated(by: [0.5, 0.5, 0]),
        ])
        let mesh = Mesh.extrude(path, depth: 8).makeWatertight()
        let capArea = Mesh(mesh.polygons.filter {
            abs($0.plane.normal.z) > 0.5
        }).surfaceArea

        XCTAssertEqual(capArea, Mesh.fill(path).surfaceArea, accuracy: epsilon)
    }

    func testExtrudeOverlappingMixedMultiCompoundPathUsesEvenOddRule() {
        let path = Path(subpaths: [
            .circle(segments: 32),
            .square().translated(by: [0.5, 0.5, 0]),
            .square().translated(by: [0.5, -0.5, 0]),
        ])
        let mesh = Mesh.extrude(path, depth: 8).makeWatertight()
        let expected = Mesh.symmetricDifference(path.subpaths.map {
            Mesh.extrude($0, depth: 8)
        }).makeWatertight()

        XCTAssertEqual(mesh.surfaceArea, expected.surfaceArea, accuracy: epsilon)
    }

    func testExtrudeQRCodeLikeCompoundPath() {
        let path = Path.qrCodeLikeCompoundPath
        let mesh = Mesh.extrude(path, depth: 8)
        XCTAssertTrue(mesh.isWatertight)
        XCTAssertTrue(mesh.polygons.areWatertight)
        XCTAssertTrue(mesh.isConsistentlyWound)
        XCTAssertTrue(mesh.vertexNormalsFaceOutward)
        XCTAssertFalse(mesh.hasSmoothSideVertexNormals)
        XCTAssertEqual(mesh.polygons.filter { abs($0.plane.normal.z) > 0.5 }.count, 80)
    }

    func testCompoundPathCapDoesNotRetainScanlineSplits() {
        func rectangle(_ min: Vector, _ max: Vector, clockwise: Bool = false) -> Path {
            let points: [PathPoint] = [
                .point(min.x, min.y),
                .point(max.x, min.y),
                .point(max.x, max.y),
                .point(min.x, max.y),
                .point(min.x, min.y),
            ]
            return Path(clockwise ? points.reversed() : points)
        }
        let path = Path(subpaths: [
            rectangle([0, 0], [10, 10]),
            rectangle([3, 3], [7, 7], clockwise: true),
            rectangle([12, 1], [14, 2]),
        ])

        let polygons = Mesh.fill(path, faces: .front).polygons

        // The ring is represented by one weakly-simple polygon and the separate rectangle by another.
        // Neither the hole nor the separate rectangle should leave horizontal scanline seams.
        XCTAssertEqual(polygons.count, 2)
        XCTAssertEqual(polygons.surfaceArea, 86, accuracy: epsilon)
    }

    func testExtrudeQRCodeLikeCompoundPathCapAreaMatchesFilledArea() {
        let path = Path.qrCodeLikeCompoundPath
        let mesh = Mesh.extrude(path, depth: 8).makeWatertight()
        let capArea = Mesh(mesh.polygons.filter {
            abs($0.plane.normal.z) > 0.5
        }).surfaceArea

        XCTAssertEqual(capArea, Mesh.fill(path).surfaceArea, accuracy: epsilon)
    }

    func testExtrudeQRCodeLikeCompoundPathCapShapeMatchesFilledShape() {
        let path = Path.qrCodeLikeCompoundPath
        let filledPolygons = Mesh.fill(path, faces: .front).polygons
        let capPolygons = Mesh.extrude(path, depth: 8)
            .makeWatertight().polygons.filter { $0.plane.normal.z > 0.5 }

        for x in stride(from: 4.0, to: 200, by: 8) {
            for y in stride(from: 4.0, to: 200, by: 8) {
                let point = Vector(x, y)
                XCTAssertEqual(
                    capPolygons.containProjectedPoint(point),
                    filledPolygons.containProjectedPoint(point),
                    "Mismatch at \(point)"
                )
            }
        }
    }

    func testExtrudeQRCodeLikeCompoundPathAlongBentPath() {
        let path = Path.qrCodeLikeCompoundPath
        let mesh = Mesh.extrude(path, along: Path([
            .point(1, 20),
            .point(0, 10),
            .point(0, -10),
        ])).makeWatertight()
        XCTAssertTrue(mesh.isWatertight)
        XCTAssertTrue(mesh.polygons.areWatertight)
        XCTAssertTrue(mesh.isConsistentlyWound)
        XCTAssertTrue(mesh.vertexNormalsFaceOutward)
    }

    func testExtrudeQRCodeLikeCompoundPathAlongBentPathCapAreaMatchesFilledArea() {
        let path = Path.qrCodeLikeCompoundPath
        let along = Path([
            .point(1, 20),
            .point(0, 10),
            .point(0, -10),
        ])
        let mesh = Mesh.extrude(path, along: along)
        let firstContour = path.extrusionContours(along: along)[0]
        let normal = firstContour.faceNormal.normalized()
        let capPlane = Plane(unchecked: normal, pointOnPlane: firstContour.points[0].position)
        let capArea = Mesh(mesh.polygons.filter {
            abs($0.plane.normal.normalized().dot(normal)) > 0.999 &&
                abs(capPlane.distance(from: $0)) < epsilon
        }).surfaceArea

        XCTAssertEqual(capArea, Mesh.fill(firstContour, faces: .front).surfaceArea, accuracy: epsilon)
    }

    func testExtrudeQRCodeLikeCompoundPathAlongBentPathCapShapeMatchesFilledShape() {
        let path = Path.qrCodeLikeCompoundPath
        let along = Path([
            .point(1, 20),
            .point(0, 10),
            .point(0, -10),
        ])
        let mesh = Mesh.extrude(path, along: along)
        let firstContour = path.extrusionContours(along: along)[0]
        let normal = firstContour.faceNormal.normalized()
        let capPlane = Plane(unchecked: normal, pointOnPlane: firstContour.points[0].position)
        let expectedPolygons = Mesh.fill(firstContour, faces: .front).polygons
        let capPolygons = mesh.polygons.filter {
            abs($0.plane.normal.normalized().dot(normal)) > 0.999 &&
                abs(capPlane.distance(from: $0)) < epsilon
        }
        let bounds = Bounds(firstContour.points.map {
            $0.position.projectedForTesting(along: normal)
        })

        for x in stride(from: bounds.min.x + 4, to: bounds.max.x, by: 8) {
            for y in stride(from: bounds.min.y + 4, to: bounds.max.y, by: 8) {
                let point = Vector(x, y)
                XCTAssertEqual(
                    capPolygons.containProjectedPoint(point, normal: normal),
                    expectedPolygons.containProjectedPoint(point, normal: normal),
                    "Mismatch at \(point)"
                )
            }
        }
    }

    func testTextEightExtrudedAlongBentPathDoesNotCrimpHoleWalls() throws {
        #if canImport(CoreText)
        let shape = try XCTUnwrap(Path.text("8").first)
        let along = Path([.point([0]), .point([1]), .point([1, 0, 1])])
        let mesh = Mesh.extrude(shape, along: along).makeWatertight()
        let contours = shape.extrusionContours(along: along)
        let capPlanes = try [XCTUnwrap(contours.first), XCTUnwrap(contours.last)].map {
            Plane(unchecked: $0.faceNormal.normalized(), pointOnPlane: $0.points[0].position)
        }
        let sidePolygons = mesh.polygons.filter { polygon in
            !capPlanes.contains { plane in
                abs(plane.normal.dot(polygon.plane.normal)) > 1 - epsilon &&
                    abs(plane.distance(from: polygon)) < epsilon
            }
        }

        XCTAssertFalse(mesh.isEmpty)
        XCTAssertTrue(mesh.isWatertight)
        XCTAssertGreaterThanOrEqual(sidePolygons.count, shape.orderedEdges.count * 2)
        #endif
    }

    func testExtrudeAlongSharpMiterLimitedPathDoesNotInvertGeometry() {
        let shape = Path.square(size: 0.6)
        let along = Path([
            .point(0, 0, 0),
            .point(1, 0, 0),
            .point(1.1, 0, 1),
        ])
        let mesh = Mesh.extrude(shape, along: along, miterLimit: 1.25)

        XCTAssertFalse(mesh.isEmpty)
        XCTAssertTrue(mesh.makeWatertight().isWatertight)
        XCTAssertTrue(mesh.isConsistentlyWound)
        XCTAssertTrue(mesh.vertexNormalsFaceOutward)
    }

    func testExtrudeAlongAcuteMiterLimitedPathDoesNotInvertGeometry() {
        let shape = Path.square()
        let along = Path([
            .point(0, 0, 0),
            .point(1, 0, 0),
            .point(0.5, 0, 1),
        ])
        let mesh = Mesh
            .extrude(shape, along: along, miterLimit: 1)
            .makeWatertight()

        XCTAssertFalse(mesh.isEmpty)
        XCTAssertTrue(mesh.isWatertight)
        XCTAssertTrue(mesh.isConsistentlyWound)
        XCTAssertTrue(mesh.vertexNormalsFaceOutward)
    }

    func testExtrudeTextOAlongItselfWithMiterLimitDoesNotInvertOuterRing() throws {
        #if canImport(CoreText)
        let path = try XCTUnwrap(Path.text("o").first).scaled(by: 0.1)
        let mesh = Mesh.extrude(path, along: path, miterLimit: 1)

        XCTAssertFalse(mesh.isEmpty)
        XCTAssertNotEqual(mesh.signedVolume, 0)
        XCTAssertTrue(mesh.vertexNormalsFaceOutward)
        XCTAssertTrue(mesh.hasSmoothSideVertexNormals)
        #endif
    }

    func testExtrudeTextEAroundTextOWithMiterLimitDoesNotInvertInnerRing() throws {
        #if canImport(CoreText)
        let shape = try XCTUnwrap(Path.text("e").first).scaled(by: 0.1)
        let along = try XCTUnwrap(Path.text("o").first).scaled(by: 0.1)
        let mesh = Mesh.extrude(shape, along: along, miterLimit: 1)

        XCTAssertFalse(mesh.isEmpty)
        XCTAssertNotEqual(mesh.signedVolume, 0)
        XCTAssertTrue(mesh.vertexNormalsFaceOutward)
        XCTAssertTrue(mesh.hasSmoothSideVertexNormals)
        #endif
    }

    func testExtrudeSmallTextEAroundTextEWithMiterLimitPreservesInnerRing() throws {
        #if canImport(CoreText)
        for scale in [0.05, 0.02, 0.01] {
            let path = try XCTUnwrap(Path.text("e").first).scaled(by: scale)
            let mesh = Mesh.extrude(path, along: path, miterLimit: 1)

            XCTAssertFalse(mesh.isEmpty)
            XCTAssertNotEqual(mesh.signedVolume, 0)
            XCTAssertTrue(mesh.vertexNormalsFaceOutward)
            XCTAssertTrue(mesh.hasSmoothSideVertexNormals)
        }
        #endif
    }

    func testExtrudeAlongCompoundTextPreservesRailLoopWinding() throws {
        #if canImport(CoreText)
        func check(shape shapeGlyph: String, along railGlyph: String, scale: Double) throws {
            let shape = try XCTUnwrap(Path.text(shapeGlyph).first).scaled(by: scale)
            let along = try XCTUnwrap(Path.text(railGlyph).first).scaled(by: scale)
            let expected = Mesh.merge(along.subpaths.map { rail in
                Mesh.extrude(shape, along: rail, miterLimit: 1)
            })

            let result = Mesh.extrude(shape, along: along, miterLimit: 1)
            XCTAssertFalse(result.isEmpty)
            XCTAssertEqual(result.signedVolume, expected.signedVolume, accuracy: 1e-6)
            for rail in along.subpaths {
                let railMesh = Mesh.extrude(shape, along: rail, miterLimit: 1)
                XCTAssertGreaterThan(railMesh.signedVolume, 0)
                XCTAssertTrue(railMesh.vertexNormalsFaceOutward)
            }
        }
        try check(shape: "o", along: "o", scale: 0.1)
        try check(shape: "e", along: "o", scale: 0.1)
        try check(shape: "e", along: "e", scale: 0.05)
        try check(shape: "e", along: "e", scale: 0.02)
        try check(shape: "e", along: "e", scale: 0.01)
        #endif
    }

    func testExtrudeNestedCompoundPathAlongCurvedPath() {
        func rectangle(
            _ x: Double,
            _ y: Double,
            _ width: Double,
            _ height: Double,
            clockwise: Bool = false
        ) -> Path {
            let points: [PathPoint] = [
                .point(x, y),
                .point(x + width, y),
                .point(x + width, y + height),
                .point(x, y + height),
                .point(x, y),
            ]
            return Path(clockwise ? points.reversed() : points)
        }
        let path = Path(subpaths: [
            rectangle(0, 0, 56, 56),
            rectangle(8, 8, 40, 40, clockwise: true),
            rectangle(16, 16, 24, 24),
        ])
        let mesh = Mesh.extrude(path, along: Path.curve([
            .curve(10, 20),
            .curve(0, 10),
            .curve(0, -10),
        ], detail: 8)).makeWatertight()
        XCTAssertTrue(mesh.isWatertight)
        XCTAssertTrue(mesh.polygons.areWatertight)
        XCTAssertTrue(mesh.isConsistentlyWound)
        XCTAssertTrue(mesh.vertexNormalsFaceOutward)
    }

    func testExtrudeCurvedCompoundPathPreservesSmoothSideNormals() {
        let path = Path(subpaths: [
            .circle(radius: 10, segments: 16),
            .square(size: 8).translated(by: [20, 0]),
        ])
        let mesh = Mesh.extrude(path, depth: 8)
        XCTAssertTrue(mesh.isConsistentlyWound)
        XCTAssertTrue(mesh.vertexNormalsFaceOutward)
        XCTAssertTrue(mesh.hasSmoothSideVertexNormals)
    }

    func testExtrudeCompoundCircleTreatsCrossingsAsSharpCorners() {
        let path = Path(subpaths: [
            .circle(segments: 16),
            .circle(radius: 0.25, segments: 16).translated(by: [0.5, 0]),
        ])
        let mesh = Mesh.extrude(path)
        let sidePolygons = mesh.polygons.filter { abs($0.plane.normal.z) < 0.5 }
        var outerVertexCount = 0
        var crossingNormals = [Vector]()

        for polygon in sidePolygons {
            for vertex in polygon.vertices {
                let radial = Vector(vertex.position.x, vertex.position.y, 0)
                if radial.length.isApproximatelyEqual(to: 0.5) {
                    outerVertexCount += 1
                    XCTAssertEqual(vertex.normal.dot(radial.normalized()), 1, accuracy: epsilon)
                }
                if abs(vertex.position.x - 0.4375) < 0.02,
                   abs(abs(vertex.position.y) - 0.242) < 0.02
                {
                    crossingNormals.append(vertex.normal)
                }
            }
        }

        XCTAssertGreaterThan(outerVertexCount, 0)
        XCTAssertTrue(crossingNormals.contains { normal in
            crossingNormals.contains {
                normal.dot($0) < 0.99
            }
        })
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

    func testExtrudeAlongAlignment() {
        let detail = 64
        let mesh = Mesh.extrude(
            .square(size: 0.1),
            along: .curve([
                .curve(0, 1),
                .curve(-1, 0, 0.75),
                .curve(0, -1, 0.25),
                .curve(1, 0, 1),
                .curve(1, 1, 1),
                .curve(0, 1),
            ], detail: detail)
        )
        XCTAssert(mesh.isWatertight)
    }

    func testExtrudeAlongAlignment2() throws {
        #if canImport(CoreText)
        let path = try XCTUnwrap(Path.text("w").first)
        let mesh = Mesh.extrude(.square(size: 0.1), along: path)
        XCTAssert(mesh.isWatertight)
        #endif
    }

    func testExtrudeHighDetailGearProfileWithRepeatedFinalTooth() {
        let expectedProfile = Self.gearProfile(detail: 62, includesRepeatedFinalTooth: false)
        let profile = Self.gearProfile(detail: 62, includesRepeatedFinalTooth: true)
        let expectedOuter = Mesh.extrude(expectedProfile, depth: 0.2)
        let expectedInner = Mesh.extrude(expectedProfile.scaled(by: 0.5), depth: 0.2)
        let outer = Mesh.extrude(profile, depth: 0.2)
        let inner = Mesh.extrude(profile.scaled(by: 0.5), depth: 0.2)

        XCTAssertEqual(outer.polygons.count, expectedOuter.polygons.count)
        XCTAssertEqual(inner.polygons.count, expectedInner.polygons.count)
        XCTAssertTrue(outer.isWatertight, "hole edges: \(outer.polygons.holeEdges.count)")
        XCTAssertTrue(inner.isWatertight, "hole edges: \(inner.polygons.holeEdges.count)")
    }

    func testExtrudeZeroDetailGearProfileWithRepeatedFinalTooth() {
        let expectedProfile = Self.gearProfile(detail: 0, includesRepeatedFinalTooth: false)
        let profile = Self.gearProfile(detail: 0, includesRepeatedFinalTooth: true)
        let expectedOuter = Mesh.extrude(expectedProfile, depth: 0.2)
        let expectedInner = Mesh.extrude(expectedProfile.scaled(by: 0.5), depth: 0.2)
        let outer = Mesh.extrude(profile, depth: 0.2)
        let inner = Mesh.extrude(profile.scaled(by: 0.5), depth: 0.2)

        XCTAssertEqual(outer.polygons.count, expectedOuter.polygons.count)
        XCTAssertEqual(inner.polygons.count, expectedInner.polygons.count)
        XCTAssertTrue(outer.isWatertight, "hole edges: \(outer.polygons.holeEdges.count)")
        XCTAssertTrue(inner.isWatertight, "hole edges: \(inner.polygons.holeEdges.count)")
    }

    func testTwistedExtrudeAlongAlignment() throws {
        #if canImport(CoreText)
        let detail = 16
        for i in 0 ..< 4 {
            let twist = Angle.halfPi * Double(i)
            let path = try XCTUnwrap(Path.text("w").first)
            let mesh = Mesh.extrude(
                .square(size: 0.1),
                along: path.withDetail(detail, forTwist: twist),
                twist: twist
            )
            XCTAssert(mesh.isWatertight)
        }
        #endif
    }
}

private extension MeshExtrudeTests {
    static func gearProfile(detail: Int, includesRepeatedFinalTooth: Bool) -> Path {
        let toothCount = 10
        let toothSpacing = 0.12566
        let toothDepth = toothSpacing / 2
        let radius = Double(toothCount) * toothSpacing / (2 * .pi)
        let innerRadius = radius - toothDepth / 2
        let outerRadius = radius + toothDepth / 2
        let innerToothHalfturns = 2 / (Double(toothCount) * 3)
        let innerArcLength = innerToothHalfturns * .pi * innerRadius
        let outerToothHalfturns = innerArcLength / (.pi * outerRadius)
        let stepHalfturns = (innerToothHalfturns + innerToothHalfturns - outerToothHalfturns) / 2
        let approachHalfturns = stepHalfturns * 0.5
        let contactHalfturns = stepHalfturns * 0.5
        var points = [PathPoint]()
        var rotation = 0.0

        func rotatedPoint(radius: Double, isCurved: Bool) -> PathPoint {
            let position = Vector(radius, 0).rotated(
                by: Rotation(unchecked: .unitZ, angle: .radians(rotation * .pi))
            )
            return isCurved ? .curve(position) : .point(position)
        }

        for _ in 0 ..< toothCount {
            points.append(rotatedPoint(radius: outerRadius, isCurved: false))
            rotation += approachHalfturns
            points.append(rotatedPoint(radius: radius, isCurved: true))
            rotation += contactHalfturns
            points.append(rotatedPoint(radius: innerRadius, isCurved: false))
            rotation += innerToothHalfturns
            points.append(rotatedPoint(radius: innerRadius, isCurved: false))
            rotation += contactHalfturns
            points.append(rotatedPoint(radius: radius, isCurved: true))
            rotation += approachHalfturns
            points.append(rotatedPoint(radius: outerRadius, isCurved: false))
            rotation += outerToothHalfturns
        }
        points.append(rotatedPoint(radius: outerRadius, isCurved: false))
        if includesRepeatedFinalTooth {
            rotation += approachHalfturns
            points.append(rotatedPoint(radius: radius, isCurved: true))
            rotation += contactHalfturns
            points.append(rotatedPoint(radius: innerRadius, isCurved: false))
            rotation += innerToothHalfturns
            points.append(rotatedPoint(radius: innerRadius, isCurved: false))
            rotation += contactHalfturns
            points.append(rotatedPoint(radius: radius, isCurved: true))
            rotation += approachHalfturns
            points.append(rotatedPoint(radius: outerRadius, isCurved: false))
        }

        return Path.curve(points, detail: detail)
    }
}
