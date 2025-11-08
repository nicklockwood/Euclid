//
//  MeshCSGTests.swift
//  GeometryScriptTests
//
//  Created by Nick Lockwood on 31/10/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

final class MeshCSGTests: XCTestCase {
    // MARK: Subtraction / Difference

    func testSubtractCoincidingBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube()
        let c = a.subtracting(b)
        XCTAssert(c.polygons.isEmpty)
        XCTAssertEqual(c, .difference([a, b]))
    }

    func testSubtractCoincidingBoxesWhenTriangulated() {
        let a = Mesh.cube().triangulate()
        let b = Mesh.cube().triangulate()
        let c = a.subtracting(b)
        XCTAssert(c.polygons.isEmpty)
        XCTAssertEqual(c, .difference([a, b]))
    }

    func testSubtractAdjacentBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube().translated(by: .unitX)
        let c = a.subtracting(b)
        XCTAssertEqual(c.bounds, a.bounds)
        XCTAssertEqual(c, .difference([a, b]))
    }

    func testSubtractOverlappingBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube().translated(by: [0.5, 0, 0])
        let c = a.subtracting(b)
        XCTAssertEqual(c.bounds, Bounds(
            min: [-0.5, -0.5, -0.5],
            max: [0, 0.5, 0.5]
        ))
        XCTAssertEqual(c, .difference([a, b]))
    }

    func testSubtractEmptyMesh() {
        let a = Mesh.empty
        let b = Mesh.cube()
        XCTAssertEqual(a.subtracting(b), a)
        XCTAssertEqual(b.subtracting(a), b)
        XCTAssertEqual(a.subtracting(b), .difference([a, b]))
        XCTAssertEqual(b.subtracting(a), .difference([b, a]))
    }

    func testSubtractIsDeterministic() {
        let a = Mesh.cube(size: 0.8)
        let b = Mesh.sphere(slices: 16)
        let c = a.subtracting(b)
        #if !arch(wasm32)
        XCTAssertEqual(c.polygons.count, 188)
        #endif
        XCTAssertEqual(c, .difference([a, b]))
    }

    func testDifferenceOfOne() {
        let mesh = Mesh.cube()
        XCTAssertEqual(mesh, .difference([mesh]))
    }

    func testDifferenceOfNone() {
        XCTAssertEqual(Mesh.empty, .difference([]))
    }

    // MARK: Symmetric Difference (XOR)

    func testXorCoincidingCubes() {
        let a = Mesh.cube()
        let b = Mesh.cube()
        let c = a.symmetricDifference(b)
        XCTAssert(c.polygons.isEmpty)
        XCTAssertEqual(c, .symmetricDifference([a, b]))
    }

    func testXorAdjacentCubes() {
        let a = Mesh.cube()
        let b = Mesh.cube().translated(by: .unitX)
        let c = a.symmetricDifference(b)
        XCTAssertEqual(c.bounds, a.bounds.union(b.bounds))
        XCTAssertEqual(c, .symmetricDifference([a, b]))
    }

    func testXorOverlappingCubes() {
        let a = Mesh.cube()
        let b = Mesh.cube().translated(by: [0.5, 0, 0])
        let c = a.symmetricDifference(b)
        XCTAssertEqual(c.bounds, Bounds(
            min: .init(size: -0.5),
            max: [1, 0.5, 0.5]
        ))
        XCTAssertEqual(c, .symmetricDifference([a, b]))
    }

    func testXorWithEmptyMesh() {
        let a = Mesh.empty
        let b = Mesh.cube()
        XCTAssertEqual(a.symmetricDifference(b), b)
        XCTAssertEqual(b.symmetricDifference(a), b)
        XCTAssertEqual(a.symmetricDifference(b), .symmetricDifference([a, b]))
        XCTAssertEqual(b.symmetricDifference(a), .symmetricDifference([b, a]))
    }

    func testXorIsDeterministic() {
        let a = Mesh.cube(size: 0.8)
        let b = Mesh.sphere(slices: 16)
        let c = a.symmetricDifference(b)
        #if !arch(wasm32)
        XCTAssertEqual(c.polygons.count, 322)
        #endif
        XCTAssertEqual(c, .symmetricDifference([a, b]))
    }

    func testXorOfOne() {
        let mesh = Mesh.cube()
        XCTAssertEqual(mesh, .symmetricDifference([mesh]))
    }

    func testXorOfNone() {
        XCTAssertEqual(Mesh.empty, .symmetricDifference([]))
    }

    // MARK: Union

    func testUnionOfCoincidingBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube()
        let c = a.union(b)
        XCTAssertEqual(c.bounds, a.bounds)
        XCTAssertEqual(c, .union([a, b]))
    }

    func testUnionOfAdjacentBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube().translated(by: .unitX)
        let c = a.union(b)
        XCTAssertEqual(c.bounds, a.bounds.union(b.bounds))
        XCTAssertEqual(c, .union([a, b]))
    }

    func testUnionOfOverlappingBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube().translated(by: [0.5, 0, 0])
        let c = a.union(b)
        XCTAssertEqual(c.bounds, Bounds(
            min: .init(size: -0.5),
            max: [1, 0.5, 0.5]
        ))
        XCTAssertEqual(c, .union([a, b]))
    }

    func testUnionWithEmptyMesh() {
        let a = Mesh.empty
        let b = Mesh.cube()
        XCTAssertEqual(a.union(b).bounds, b.bounds)
        XCTAssertEqual(b.union(a).bounds, b.bounds)
        XCTAssertEqual(a.union(b), .union([a, b]))
        XCTAssertEqual(b.union(a), .union([b, a]))
    }

    func testUnionIsDeterministic() {
        let a = Mesh.cube(size: 0.8)
        let b = Mesh.sphere(slices: 16)
        let c = a.union(b)
        #if !arch(wasm32)
        XCTAssertEqual(c.polygons.count, 236)
        #endif
        XCTAssertEqual(c, .union([a, b]))
    }

    func testUnionOfOne() {
        let mesh = Mesh.cube()
        XCTAssertEqual(mesh, .union([mesh]))
    }

    func testUnionOfNone() {
        XCTAssertEqual(Mesh.empty, .union([]))
    }

    // MARK: Intersection

    func testIntersectionOfCoincidingBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube()
        let c = a.intersection(b)
        XCTAssertEqual(c.bounds, a.bounds)
        XCTAssertEqual(c, .intersection([a, b]))
    }

    func testIntersectionOfAdjacentBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube().translated(by: .unitX)
        let c = a.intersection(b)
        // TODO: ideally this should probably be empty, but it's not clear
        // how to achieve that while also getting desired planar behavior
        XCTAssertEqual(c.bounds, Bounds(
            min: [0.5, -0.5, -0.5],
            max: [0.5, 0.5, 0.5]
        ))
        XCTAssertEqual(c, .intersection([a, b]))
    }

    func testIntersectionOfOverlappingBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube().translated(by: [0.5, 0, 0])
        let c = a.intersection(b)
        XCTAssertEqual(c.bounds, Bounds(
            min: [0, -0.5, -0.5],
            max: [0.5, 0.5, 0.5]
        ))
        XCTAssertEqual(c, .intersection([a, b]))
    }

    func testIntersectionOfNonOverlappingBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube().translated(by: [2, 0, 0])
        let c = a.intersection(b)
        XCTAssertEqual(c, .empty)
        XCTAssertEqual(c, .intersection([a, b]))
    }

    func testIntersectionWithEmptyMesh() {
        let a = Mesh.empty
        let b = Mesh.cube()
        XCTAssert(a.intersection(b).bounds.isEmpty)
        XCTAssert(b.intersection(a).bounds.isEmpty)
    }

    func testIntersectIsDeterministic() {
        let a = Mesh.cube(size: 0.8)
        let b = Mesh.sphere(slices: 16)
        let c = a.intersection(b)
        XCTAssertEqual(c.polygons.count, 86)
        XCTAssertEqual(c, .intersection([a, b]))
    }

    func testIntersectonOfOne() {
        let mesh = Mesh.cube()
        XCTAssertEqual(mesh, .intersection([mesh]))
    }

    func testIntersectionOfNone() {
        XCTAssertEqual(Mesh.empty, .intersection([]))
    }

    // MARK: Convex Hull

    func testConvexHullOfCubes() {
        let mesh1 = Mesh.cube().translated(by: [-1, 0.5, 0.7])
        let mesh2 = Mesh.cube().translated(by: [1, 0])
        let mesh = Mesh.convexHull(of: [mesh1, mesh2])
        XCTAssert(mesh.isKnownConvex)
        XCTAssert(mesh.isActuallyConvex)
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
        XCTAssertEqual(mesh.bounds, mesh1.bounds.union(mesh2.bounds))
        XCTAssertEqual(mesh.bounds, Bounds(mesh.polygons))
    }

    func testConvexHullOfSpheres() {
        let mesh1 = Mesh.sphere().translated(by: [-1, 0.2, -0.1])
        let mesh2 = Mesh.sphere().translated(by: [1, 0])
        let mesh = Mesh.convexHull(of: [mesh1, mesh2])
        XCTAssert(mesh.isKnownConvex)
        XCTAssert(mesh.isActuallyConvex)
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
        XCTAssertEqual(mesh.bounds, mesh1.bounds.union(mesh2.bounds))
        XCTAssertEqual(mesh.bounds, Bounds(mesh.polygons))
    }

    func testConvexHullOfCubeIsItself() {
        let cube = Mesh.cube()
        let mesh = Mesh.convexHull(of: [cube])
        XCTAssertEqual(cube, mesh)
        let mesh2 = Mesh.convexHull(of: cube.polygons)
        XCTAssertEqual(
            Set(cube.polygons.flatMap(\.vertices)),
            Set(mesh2.polygons.flatMap(\.vertices))
        )
        XCTAssertEqual(cube.polygons.count, mesh2.detessellate().polygons.count)
    }

    func testConvexHullOfNothing() {
        let mesh = Mesh.convexHull(of: [] as [Mesh])
        XCTAssertEqual(mesh, .empty)
    }

    func testConvexHullOfSingleTriangle() {
        let triangle = Polygon(unchecked: [
            [0, 0],
            [1, 0],
            [1, 1],
        ])
        let mesh = Mesh.convexHull(of: [triangle])
        XCTAssert(mesh.isKnownConvex)
        XCTAssert(mesh.isActuallyConvex)
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
        XCTAssertEqual(mesh.bounds, triangle.bounds)
        XCTAssertEqual(mesh.bounds, Bounds(mesh.polygons))
    }

    func testConvexHullOfConcavePolygon() {
        let shape = Polygon(unchecked: [
            [0, 0],
            [1, 0],
            [1, 1],
            [0.5, 1],
            [0.5, 0.5],
        ])
        let mesh = Mesh.convexHull(of: [shape])
        XCTAssert(mesh.isKnownConvex)
        XCTAssert(mesh.isActuallyConvex)
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
        XCTAssertEqual(mesh.bounds, shape.bounds)
        XCTAssertEqual(mesh.bounds, Bounds(mesh.polygons))
    }

    func testConvexHullOfConcavePolygonMesh() {
        let shape = Mesh([Polygon(unchecked: [
            [0, 0],
            [1, 0],
            [1, 1],
            [0.5, 1],
            [0.5, 0.5],
        ])])
        let mesh = Mesh.convexHull(of: [shape])
        XCTAssert(mesh.isKnownConvex)
        XCTAssert(mesh.isActuallyConvex)
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
        XCTAssertEqual(mesh.bounds, shape.bounds)
        XCTAssertEqual(mesh.bounds, Bounds(mesh.polygons))
    }

    func testConvexHullOfCoplanarTriangles() {
        let triangle1 = Polygon(unchecked: [
            [0, 0],
            [1, 0],
            [1, 1],
        ])
        let triangle2 = Polygon(unchecked: [
            [2, 0],
            [3, 0],
            [3, 1],
        ])
        let mesh = Mesh.convexHull(of: [triangle1, triangle2])
        XCTAssert(mesh.isKnownConvex)
        XCTAssert(mesh.isActuallyConvex)
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
        XCTAssertEqual(mesh.signedVolume, 0)
        XCTAssertEqual(mesh.bounds, triangle1.bounds.union(triangle2.bounds))
        XCTAssertEqual(mesh.bounds, Bounds(mesh.polygons))
    }

    func testConvexHullOfOverlappingSquares() throws {
        let square1 = try XCTUnwrap(Polygon(.square()))
        for _ in 0 ..< 10 {
            let square2 = try XCTUnwrap(Polygon(.square())?.translated(by: [0.5, 0.5]).rotated(by: .random(in: .xy)))
            let mesh = Mesh.convexHull(of: [square1, square2])
            XCTAssert(mesh.isKnownConvex)
            XCTAssert(mesh.isActuallyConvex)
            XCTAssert(mesh.isWatertight)
            XCTAssert(mesh.polygons.areWatertight)
            XCTAssertEqual(mesh.signedVolume, 0)
            XCTAssertEqual(mesh.bounds, square1.bounds.union(square2.bounds))
            XCTAssertEqual(mesh.bounds, Bounds(mesh.polygons))
        }
    }

    func testPlanarHullConvexityEdgeCase() throws {
        let square1 = try XCTUnwrap(Polygon(.square()))
        let r = Rotation(unchecked: .unitZ, angle: .radians(1.9113781280442135))
        let square2 = try XCTUnwrap(Polygon(.square())?.translated(by: [0.5, 0.5]).rotated(by: r))
        let mesh = Mesh.convexHull(of: [square1, square2])
        XCTAssert(mesh.isKnownConvex)
        XCTAssert(mesh.isActuallyConvex)
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
        XCTAssertEqual(mesh.signedVolume, 0)
        XCTAssertEqual(mesh.bounds, square1.bounds.union(square2.bounds))
        XCTAssertEqual(mesh.bounds, Bounds(mesh.polygons))
    }

    func testConvexHullOfEightSpheres() {
        let corners = Set(Mesh.cube().polygons.flatMap(\.vertices).map(\.position)).sorted()
        XCTAssertEqual(corners.count, 8)
        let spheres = corners.map { Mesh.sphere().translated(by: $0) }
        let mesh = Mesh.convexHull(of: spheres)
        XCTAssert(mesh.isKnownConvex)
        XCTAssert(mesh.isActuallyConvex)
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
        XCTAssertEqual(mesh.bounds, Bounds(spheres))
    }

    func testConvexHullVertexColorBlending() {
        let mesh1 = Mesh.cube().mapVertexColors { _ in .red }
        let mesh2 = Mesh.cube().translated(by: [1, 0]).mapVertexColors { _ in .blue }
        let mesh = Mesh.convexHull(of: [mesh1, mesh2])
        let vertices = mesh.polygons.flatMap(\.vertices)
        XCTAssert(vertices.allSatisfy { $0.color == .red || $0.color == .blue })
        XCTAssert(vertices.contains(where: { $0.color == .blue }))
        XCTAssert(vertices.contains(where: { $0.color == .red }))
    }

    func testConvexHullPathPointColorBlending() {
        let path1 = Path.square(color: .red)
        let path2 = Path.circle(color: .blue).translated(by: [1, 0])
        let mesh = Mesh.convexHull(of: [path1, path2])
        let vertices = mesh.polygons.flatMap(\.vertices)
        XCTAssert(vertices.allSatisfy { $0.color == .red || $0.color == .blue })
        XCTAssert(vertices.contains(where: { $0.color == .blue }))
        XCTAssert(vertices.contains(where: { $0.color == .red }))
    }

    func testConvexHullPathPointColorBlending2() {
        let path = Path([
            .curve(0, 1, 0.75),
            .curve(-1, 0),
            .curve(0, -1, 0.25),
            .curve(1, 0),
            .curve(1, 1),
            .curve(0, 1, 0.75),
        ], color: .green)
        let mesh = Mesh.convexHull(of: [path])
        let vertices = mesh.polygons.flatMap(\.vertices)
        XCTAssert(vertices.allSatisfy { $0.color == .green })
    }

    func testConvexHullOfVertices() {
        let detail = 16
        let a = Mesh.sphere(slices: detail)
        let b = a.translated(by: [1, 0, 0])
        let vertices = (a.polygons + b.polygons).flatMap(\.vertices)
        let mesh = Mesh.convexHull(of: vertices)
        XCTAssert(mesh.isKnownConvex)
        XCTAssert(mesh.isActuallyConvex)
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
    }

    func testConvexHullOfLineSegments() {
        let detail = 16
        let a = Mesh.sphere(slices: detail)
        let b = a.translated(by: [1, 0, 0])
        let edges = (a.polygons + b.polygons).flatMap(\.orderedEdges)
        let mesh = Mesh.convexHull(of: edges)
        XCTAssert(mesh.isKnownConvex)
        XCTAssert(mesh.isActuallyConvex)
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
    }

    func testConvexHullOfPaths() {
        let detail = 16
        let a = Mesh.sphere(slices: detail)
        let b = a.translated(by: [1, 0, 0])
        let paths = Path((a.polygons + b.polygons).flatMap(\.orderedEdges)).subpaths
        let mesh = Mesh.convexHull(of: paths)
        XCTAssert(mesh.isKnownConvex)
        XCTAssert(mesh.isActuallyConvex)
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
    }

    // MARK: Minkowski Sum

    func testMinkowskiSumOfCubes() {
        let mesh1 = Mesh.cube()
        let mesh2 = Mesh.cube()
        let mesh = mesh1.minkowskiSum(with: mesh2)
        XCTAssert(mesh.isKnownConvex)
        XCTAssert(mesh.isActuallyConvex)
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
        XCTAssertEqual(mesh, .minkowskiSum(of: [mesh1, mesh2]))
        XCTAssertEqual(mesh.bounds, mesh1.bounds.minkowskiSum(with: mesh2.bounds))
        XCTAssertEqual(mesh.bounds, Bounds(mesh.polygons))
    }

    func testMinkowskiSumOfSphereAndCube() {
        let mesh1 = Mesh.sphere()
        let mesh2 = Mesh.cube()
        let mesh = mesh1.minkowskiSum(with: mesh2)
        XCTAssert(mesh.isKnownConvex)
        XCTAssert(mesh.isActuallyConvex)
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
        XCTAssertEqual(mesh, .minkowskiSum(of: [mesh1, mesh2]))
        XCTAssertEqual(mesh.bounds, mesh1.bounds.minkowskiSum(with: mesh2.bounds))
        XCTAssertEqual(mesh.bounds, Bounds(mesh.polygons))
    }

    func testMinkowskiSumOfCubeAndSphere() {
        let mesh1 = Mesh.cube()
        let mesh2 = Mesh.sphere()
        let mesh = mesh1.minkowskiSum(with: mesh2)
        XCTAssert(mesh.isKnownConvex)
        XCTAssert(mesh.isActuallyConvex)
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
        XCTAssertEqual(mesh, .minkowskiSum(of: [mesh1, mesh2]))
        XCTAssertEqual(mesh.bounds, mesh1.bounds.minkowskiSum(with: mesh2.bounds))
        XCTAssertEqual(mesh.bounds, Bounds(mesh.polygons))
    }

    func testMinkowskiSumOfTranslatedShapes() {
        let mesh1 = Mesh.cube().translated(by: .random())
        let mesh2 = Mesh.sphere().translated(by: .random())
        let mesh = mesh1.minkowskiSum(with: mesh2)
        XCTAssert(mesh.isKnownConvex)
        XCTAssert(mesh.isActuallyConvex)
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
        XCTAssertEqual(mesh, .minkowskiSum(of: [mesh1, mesh2]))
        XCTAssertEqual(mesh.bounds, mesh1.bounds.minkowskiSum(with: mesh2.bounds))
        XCTAssertEqual(mesh.bounds, Bounds(mesh.polygons))
    }

    func testMinkowskiSumOfTransformedShaped() {
        let mesh1 = Mesh.cube().transformed(by: .random())
        let mesh2 = Mesh.sphere().transformed(by: .random())
        let mesh = mesh1.minkowskiSum(with: mesh2)
        XCTAssert(mesh.isKnownConvex)
        XCTAssert(mesh.isActuallyConvex)
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
        XCTAssertEqual(mesh, .minkowskiSum(of: [mesh1, mesh2]))
        XCTAssertEqual(mesh.bounds, mesh1.bounds.minkowskiSum(with: mesh2.bounds))
        XCTAssertEqual(mesh.bounds, Bounds(mesh.polygons))
    }

    func testMinkowskiSumWithEmptyMeshes() {
        let mesh = Mesh.cube().translated(by: .random())
        XCTAssertEqual(Mesh.empty.minkowskiSum(with: mesh), mesh)
        XCTAssertEqual(mesh.minkowskiSum(with: Mesh.empty), mesh)
    }

    func testMinkowskiSumOfConvexAndConcaveMeshes() {
        #if canImport(CoreText)
        let a = Mesh.cube(size: 0.1)
        let b = Mesh.text("G")
        let ab = a.minkowskiSum(with: b)
        let ba = b.minkowskiSum(with: a)
        XCTAssertFalse(ab.isConvex())
        XCTAssertFalse(ba.isConvex())
        XCTAssertEqual(ab, ba)
        #endif
    }

    func testMinkowskiSumOfTranslatedNonConvexShape() {
        #if canImport(CoreText)
        let a = Mesh.cube(size: 0.1).translated(by: .random())
        let b = Mesh.text("G").translated(by: .random())
        let ab = a.minkowskiSum(with: b)
        let ba = b.minkowskiSum(with: a)
        XCTAssertEqual(ab.bounds, a.bounds.minkowskiSum(with: b.bounds))
        XCTAssertEqual(ba.bounds, a.bounds.minkowskiSum(with: b.bounds))
        #endif
    }

    func testMinkowskiSumWithPolygon() throws {
        let square = try XCTUnwrap(Polygon(.square(color: .red)))
        let mesh = Mesh.cube().minkowskiSum(with: square)
        XCTAssertEqual(mesh.bounds, Bounds(min: [-1, -1, -0.5], max: [1, 1, 0.5]))
        let vertices = mesh.polygons.flatMap(\.vertices)
        XCTAssert(vertices.allSatisfy { $0.color == .red })
    }

    func testMinkowskiSumWithPath() {
        let mesh = Mesh.cube().minkowskiSum(with: .square())
        XCTAssertEqual(mesh.bounds, Bounds(min: [-1, -1, -0.5], max: [1, 1, 0.5]))
    }

    func testMinkowskiSumWithLinePath() {
        let mesh = Mesh.cube().minkowskiSum(with: .line([0, 0], [1, 0]))
        XCTAssertEqual(mesh.bounds, Bounds(min: [-0.5, -0.5, -0.5], max: [1.5, 0.5, 0.5]))
    }

    func testMinkowskiSumWithPointPath() {
        let mesh = Mesh.cube().minkowskiSum(with: Path([.point(1, 0, color: .red)]))
        XCTAssertEqual(mesh.bounds, Bounds(min: [0.5, -0.5, -0.5], max: [1.5, 0.5, 0.5]))
        let vertices = mesh.polygons.flatMap(\.vertices)
        XCTAssert(vertices.allSatisfy { $0.color == .red })
    }

    func testMinkowskiSumWithEmptyPath() {
        let mesh = Mesh.cube().minkowskiSum(with: Path.empty)
        XCTAssertEqual(mesh, .empty)
    }

    func testMinkowskiSumWithLineSegment() {
        let mesh = Mesh.cube().minkowskiSum(with: LineSegment(unchecked: [0, 0], [1, 0]))
        XCTAssertEqual(mesh.bounds, Bounds(min: [-0.5, -0.5, -0.5], max: [1.5, 0.5, 0.5]))
    }

    func testMinkowskiSumConvexMeshColorBlending() {
        let mesh1 = Mesh.cube().mapVertexColors { _ in .red }
        let mesh2 = Mesh.cube().mapVertexColors { _ in .blue }
        let mesh = mesh1.minkowskiSum(with: mesh2)
        let vertices = mesh.polygons.flatMap(\.vertices)
        let blended = Color.red * .blue
        XCTAssert(vertices.allSatisfy { $0.color == blended })
    }

    func testMinkowskiSumConcaveMeshColorBlending() {
        #if canImport(CoreText)
        let mesh1 = Mesh.cube(size: 0.1).mapVertexColors { _ in .red }
        let mesh2 = Mesh.text("G").mapVertexColors { _ in .blue }
        let mesh = mesh1.minkowskiSum(with: mesh2)
        let vertices = mesh.polygons.flatMap(\.vertices)
        let blended = Color.red * .blue
        XCTAssert(vertices.allSatisfy { $0.color == blended })
        #endif
    }

    func testMinkowskiSumPolygonColorBlending() throws {
        let square = try XCTUnwrap(Polygon(.square(color: .red)))
        let mesh = Mesh.cube().mapVertexColors { _ in .blue }.minkowskiSum(with: square)
        XCTAssertEqual(mesh.bounds, Bounds(min: [-1, -1, -0.5], max: [1, 1, 0.5]))
        let vertices = mesh.polygons.flatMap(\.vertices)
        let blended = Color.red * .blue
        XCTAssert(vertices.allSatisfy { $0.color == blended })
    }

    func testMinkowskiSumPathColorBlending() {
        let path = Path.square(color: .red)
        let mesh = Mesh.cube().mapVertexColors { _ in .blue }.minkowskiSum(with: path)
        XCTAssertEqual(mesh.bounds, Bounds(min: [-1, -1, -0.5], max: [1, 1, 0.5]))
        let vertices = mesh.polygons.flatMap(\.vertices)
        let blended = Color.red * .blue
        XCTAssert(vertices.allSatisfy { $0.color == blended })
    }

    // MARK: Planar subtraction

    func testSubtractCoincidingSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square())
        let c = a.subtracting(b)
        XCTAssert(c.polygons.isEmpty)
        XCTAssertEqual(c, .difference([a, b]))
    }

    func testSubtractAdjacentSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square()).translated(by: .unitX)
        let c = a.subtracting(b)
        XCTAssertEqual(c.bounds, a.bounds)
        XCTAssertEqual(c, .difference([a, b]))
    }

    func testSubtractOverlappingSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square()).translated(by: [0.5, 0, 0])
        let c = a.subtracting(b)
        XCTAssertEqual(c.bounds, Bounds(
            min: [-0.5, -0.5, 0],
            max: [0, 0.5, 0]
        ))
        XCTAssertEqual(c, .difference([a, b]))
    }

    // MARK: Planar Symmetric Difference (XOR)

    func testXorCoincidingSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square())
        let c = a.symmetricDifference(b)
        XCTAssert(c.polygons.isEmpty)
        XCTAssertEqual(c, .symmetricDifference([a, b]))
    }

    func testXorAdjacentSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square()).translated(by: .unitX)
        let c = a.symmetricDifference(b)
        XCTAssertEqual(c.bounds, a.bounds.union(b.bounds))
        XCTAssertEqual(c, .symmetricDifference([a, b]))
    }

    func testXorOverlappingSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square()).translated(by: [0.5, 0, 0])
        let c = a.symmetricDifference(b)
        XCTAssertEqual(c.bounds, Bounds(
            min: [-0.5, -0.5, 0],
            max: [1.0, 0.5, 0]
        ))
        XCTAssertEqual(c, .symmetricDifference([a, b]))
    }

    // MARK: Planar union

    func testUnionOfCoincidingSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square())
        let c = a.union(b)
        XCTAssertEqual(c.bounds, a.bounds)
        XCTAssertEqual(c, .union([a, b]))
    }

    func testUnionOfAdjacentSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square()).translated(by: .unitX)
        let c = a.union(b)
        XCTAssertEqual(c.bounds, a.bounds.union(b.bounds))
        XCTAssertEqual(c, .union([a, b]))
    }

    func testUnionOfOverlappingSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square()).translated(by: [0.5, 0, 0])
        let c = a.union(b)
        XCTAssertEqual(c.bounds, Bounds(
            min: [-0.5, -0.5, 0],
            max: [1, 0.5, 0]
        ))
        XCTAssertEqual(c, .union([a, b]))
    }

    // MARK: Planar intersection

    func testIntersectionOfCoincidingSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square())
        let c = a.intersection(b)
        XCTAssertEqual(c.bounds, a.bounds)
        XCTAssertEqual(c, .intersection([a, b]))
    }

    func testIntersectionOfAdjacentSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square()).translated(by: .unitX)
        let c = a.intersection(b)
        XCTAssert(c.polygons.isEmpty)
        XCTAssertEqual(c, .intersection([a, b]))
    }

    func testIntersectionOfOverlappingSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square()).translated(by: [0.5, 0, 0])
        let c = a.intersection(b)
        XCTAssertEqual(c.bounds, Bounds(
            min: [0, -0.5, 0],
            max: [0.5, 0.5, 0]
        ))
        XCTAssertEqual(c, .intersection([a, b]))
    }

    // MARK: Plane clipping

    func testSquareClippedToPlane() {
        let a = Mesh.fill(.square())
        let plane = Plane(unchecked: .unitX, pointOnPlane: .zero)
        let b = a.clipped(to: plane)
        XCTAssertEqual(b.bounds, .init([0, -0.5], [0.5, 0.5]))
    }

    func testPentagonClippedToPlane() {
        let a = Mesh.fill(.circle(segments: 5))
        let plane = Plane(unchecked: .unitX, pointOnPlane: .zero)
        let b = a.clipped(to: plane)
        XCTAssertEqual(b.bounds, .init(
            [0, -0.404508497187],
            [0.475528258148, 0.5]
        ))
    }

    func testDiamondClippedToPlane() {
        let a = Mesh.fill(.circle(segments: 4))
        let plane = Plane(unchecked: .unitX, pointOnPlane: .zero)
        let b = a.clipped(to: plane)
        XCTAssertEqual(b.bounds, .init([0, -0.5], [0.5, 0.5]))
    }

    func testSquareClippedToItsOwnPlane() {
        let a = Mesh.fill(.square())
        let plane = Plane(unchecked: .unitZ, pointOnPlane: .zero)
        let b = a.clipped(to: plane)
        XCTAssertEqual(b.polygons, [a.polygons[0]])
    }

    func testSquareClippedToItsOwnPlaneWithFill() {
        let a = Mesh.fill(.square())
        let plane = Plane(unchecked: .unitZ, pointOnPlane: .zero)
        let b = a.clipped(to: plane, fill: Color.white)
        XCTAssertEqual(b.polygons.first, a.polygons[0])
        guard b.polygons.count == 2 else {
            XCTFail()
            return
        }
        XCTAssertEqual(b.polygons[1].bounds, a.polygons[1].bounds)
    }

    func testSquareClippedToReversePlane() {
        let a = Mesh.fill(.square())
        let plane = Plane(unchecked: -.unitZ, pointOnPlane: .zero)
        let b = a.clipped(to: plane)
        XCTAssertEqual(b.polygons, [a.polygons[1]])
    }

    func testSquareClippedToReversePlaneWithFill() {
        let a = Mesh.fill(.square())
        let plane = Plane(unchecked: -.unitZ, pointOnPlane: .zero)
        let b = a.clipped(to: plane, fill: Color.white)
        XCTAssertEqual(b.polygons.first?.bounds, a.polygons[0].bounds)
        guard b.polygons.count == 2 else {
            XCTFail()
            return
        }
        XCTAssertEqual(b.polygons[1].bounds, a.polygons[1].bounds)
    }

    // MARK: Plane splitting

    func testSquareSplitAlongPlane() {
        let a = Mesh.fill(.square())
        let plane = Plane(unchecked: .unitX, pointOnPlane: .zero)
        let b = a.split(along: plane)
        XCTAssertEqual(b.0?.bounds, .init([0, -0.5], [0.5, 0.5]))
        XCTAssertEqual(b.1?.bounds, .init([-0.5, -0.5], [0, 0.5]))
        XCTAssertEqual(b.front, b.0)
        XCTAssertEqual(b.back, b.1)
    }

    func testSquareSplitAlongItsOwnPlane() {
        let a = Mesh.fill(.square())
        let plane = Plane(unchecked: .unitZ, pointOnPlane: .zero)
        let b = a.split(along: plane)
        XCTAssertEqual(b.front?.polygons, [a.polygons[0]])
        XCTAssertEqual(b.back?.polygons, [a.polygons[1]])
    }

    func testSquareSplitAlongReversePlane() {
        let a = Mesh.fill(.square())
        let plane = Plane(unchecked: -.unitZ, pointOnPlane: .zero)
        let b = a.split(along: plane)
        XCTAssertEqual(b.front?.polygons, [a.polygons[1]])
        XCTAssertEqual(b.back?.polygons, [a.polygons[0]])
    }

    // MARK: Submeshes

    func testUnionSubmeshes() {
        let a = Mesh.cube()
        let b = Mesh.cube().translated(by: [2, 0, 0])
        let c = a.union(b)
        let d = Mesh.cube().translated(by: [4, 0, 0])
        XCTAssertEqual(c.union(d).submeshes.count, 3)
    }

    func testUnionOfPrecalculatedSubmeshes() {
        let a = Mesh.cube()
        _ = a.submeshes
        let b = Mesh.cube().translated(by: [2, 0, 0])
        _ = b.submeshes
        let c = a.union(b)
        XCTAssertEqual(c.submeshes.count, 2)
        let d = Mesh.cube().translated(by: [4, 0, 0])
        XCTAssertEqual(c.union(d).submeshes.count, 3)
    }

    // MARK: Convexity

    func testConvexityFalsePositive() {
        let square = Mesh.fill(.square(), faces: .front)
        let square2 = Mesh.fill(.square(), faces: .front).translated(by: -.unitZ)
        let mesh = square.merge(square2)
        XCTAssertNil(mesh.watertightIfSet)
        XCTAssertFalse(mesh.isWatertight)
        XCTAssertFalse(mesh.polygons.areWatertight)
        let bsp = BSP(mesh) { false }
        XCTAssertFalse(bsp.isConvex)
    }
}
