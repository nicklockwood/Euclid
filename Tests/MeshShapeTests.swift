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
        XCTAssertTrue(mesh.polygons.areWatertight)
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
        XCTAssertTrue(mesh.polygons.areWatertight)
    }

    func testExtrudeQRCodeLikeCompoundPath() {
        let path = Path.qrCodeLikeCompoundPath
        let mesh = Mesh.extrude(path, depth: 8)
        XCTAssertTrue(mesh.isWatertight)
        XCTAssertTrue(mesh.polygons.areWatertight)
        XCTAssertTrue(mesh.isConsistentlyWound)
        XCTAssertTrue(mesh.vertexNormalsFaceOutward)
        XCTAssertFalse(mesh.hasSmoothSideVertexNormals)
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
        let capPolygons = Mesh.extrude(path, depth: 8).makeWatertight().polygons.filter {
            $0.plane.normal.z > 0.5
        }

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
        ]))
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
        ], detail: 8))
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

    func testLatheCompoundPathUsesEvenOddRule() {
        let outer = Path([
            .point(1, 0),
            .point(3, 0),
            .point(3, 10),
            .point(1, 10),
            .point(1, 0),
        ])
        let inner = Path([
            .point(1.5, 2),
            .point(2, 2),
            .point(2, 8),
            .point(1.5, 8),
            .point(1.5, 2),
        ])
        let mesh = Mesh.lathe(Path(subpaths: [outer, inner]), slices: 8)
        let expected = Mesh.symmetricDifference([
            Mesh.lathe(outer, slices: 8),
            Mesh.lathe(inner, slices: 8),
        ])
        XCTAssertEqual(mesh.bounds, expected.bounds)
        XCTAssertEqual(mesh.polygons.surfaceArea, expected.polygons.surfaceArea)
        XCTAssertTrue(mesh.isWatertight)
        XCTAssertTrue(mesh.polygons.areWatertight)
    }

    func testLoftCompoundPathUsesEvenOddRule() {
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
        let compound = Path(subpaths: [outer, inner])
        var mesh = Mesh.loft([compound, compound.translated(by: .unitZ)])
        XCTAssertEqual(mesh.bounds, Bounds([0, 0, 0], [10, 10, 1]))
        XCTAssertEqual(mesh.polygons.surfaceArea, 192)
        XCTAssertFalse(mesh.isWatertight)
        mesh = mesh.makeWatertight()
        XCTAssertTrue(mesh.isWatertight)
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

    func testExtrudeAlongAlignment2() {
        #if canImport(CoreText)
        let mesh = Mesh.extrude(
            .square(size: 0.1),
            along: .text("w")[0]
        )
        XCTAssert(mesh.isWatertight)
        #endif
    }

    func testTwistedExtrudeAlongAlignment() {
        #if canImport(CoreText)
        let detail = 16
        for i in 0 ..< 4 {
            let twist = Angle.halfPi * Double(i)
            let mesh = Mesh.extrude(
                .square(size: 0.1),
                along: .text("w")[0].withDetail(detail, twist: twist),
                twist: twist
            )
            XCTAssert(mesh.isWatertight)
        }
        #endif
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
