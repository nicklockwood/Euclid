//
//  MeshShapeTests.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 06/02/2022.
//  Copyright © 2022 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

private extension Mesh {
    var isActuallyConvex: Bool {
        guard BSP(Mesh(polygons), { false }).isConvex else {
            return false
        }
        guard let plane = polygons.first?.plane else {
            return true
        }
        for polygon in polygons {
            if !polygon.plane.isEqual(to: plane),
               !polygon.plane.isEqual(to: plane.inverted())
            {
                return true
            }
        }
        // All polygons are planar
        let groups = polygons.groupedByPlane()
        return groups.count == 2
    }
}

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

        XCTAssert(loft.polygons.allSatisfy {
            pointsAreCoplanar($0.vertices.map { $0.position })
        })

        // Every vertex in the loft should be contained by one of our shapes
        let vertices = loft.polygons.flatMap { $0.vertices }
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

    func testLoftEmptyPathsArray() {
        let loft = Mesh.loft([])
        XCTAssertEqual(loft, .empty)
    }

    func testLoftSinglePath() {
        let loft = Mesh.loft([.circle()])
        XCTAssertEqual(loft, .fill(.circle()))
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
    }

    func testLoftCircleToOpenPath() {
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
    }

    func testLoftOpenPathToCircle() {
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
        XCTAssertEqual(mesh.bounds, Bounds(polygons: mesh.polygons))
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
        XCTAssertEqual(mesh.bounds, Bounds(polygons: mesh.polygons))
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
        XCTAssertEqual(mesh.bounds, Bounds(polygons: mesh.polygons))
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
        XCTAssertEqual(mesh.bounds, Bounds(polygons: mesh.polygons))
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
        XCTAssertEqual(mesh.bounds, Bounds(polygons: mesh.polygons))
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
        XCTAssertEqual(mesh.bounds, Bounds(polygons: mesh.polygons))
    }
}
