//
//  CSGTests.swift
//  GeometryScriptTests
//
//  Created by Nick Lockwood on 31/10/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

class MeshCSGTests: XCTestCase {
    // MARK: Subtraction

    func testSubtractCoincidingBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube()
        let c = a.subtract(b)
        XCTAssert(c.polygons.isEmpty)
        XCTAssertEqual(c, .difference([a, b]))
    }

    func testSubtractCoincidingBoxesWhenTriangulated() {
        let a = Mesh.cube().triangulate()
        let b = Mesh.cube().triangulate()
        let c = a.subtract(b)
        XCTAssert(c.polygons.isEmpty)
        XCTAssertEqual(c, .difference([a, b]))
    }

    func testSubtractAdjacentBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube().translated(by: .unitX)
        let c = a.subtract(b)
        XCTAssertEqual(c.bounds, a.bounds)
        XCTAssertEqual(c, .difference([a, b]))
    }

    func testSubtractOverlappingBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube().translated(by: Vector(0.5, 0, 0))
        let c = a.subtract(b)
        XCTAssertEqual(c.bounds, Bounds(
            min: Vector(-0.5, -0.5, -0.5),
            max: Vector(0, 0.5, 0.5)
        ))
        XCTAssertEqual(c, .difference([a, b]))
    }

    func testSubtractEmptyMesh() {
        let a = Mesh.empty
        let b = Mesh.cube()
        XCTAssertEqual(a.subtract(b), a)
        XCTAssertEqual(b.subtract(a), b)
        XCTAssertEqual(a.subtract(b), .difference([a, b]))
        XCTAssertEqual(b.subtract(a), .difference([b, a]))
    }

    func testSubtractIsDeterministic() {
        let a = Mesh.cube(size: 0.8)
        let b = Mesh.sphere(slices: 16)
        let c = a.subtract(b)
        #if !arch(wasm32)
        XCTAssertEqual(c.polygons.count, 189)
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

    // MARK: XOR

    func testXorCoincidingCubes() {
        let a = Mesh.cube()
        let b = Mesh.cube()
        let c = a.xor(b)
        XCTAssert(c.polygons.isEmpty)
        XCTAssertEqual(c, .xor([a, b]))
    }

    func testXorAdjacentCubes() {
        let a = Mesh.cube()
        let b = Mesh.cube().translated(by: .unitX)
        let c = a.xor(b)
        XCTAssertEqual(c.bounds, a.bounds.union(b.bounds))
        XCTAssertEqual(c, .xor([a, b]))
    }

    func testXorOverlappingCubes() {
        let a = Mesh.cube()
        let b = Mesh.cube().translated(by: Vector(0.5, 0, 0))
        let c = a.xor(b)
        XCTAssertEqual(c.bounds, Bounds(
            min: Vector(-0.5, -0.5, -0.5),
            max: Vector(1.0, 0.5, 0.5)
        ))
        XCTAssertEqual(c, .xor([a, b]))
    }

    func testXorWithEmptyMesh() {
        let a = Mesh.empty
        let b = Mesh.cube()
        XCTAssertEqual(a.xor(b), b)
        XCTAssertEqual(b.xor(a), b)
        XCTAssertEqual(a.xor(b), .xor([a, b]))
        XCTAssertEqual(b.xor(a), .xor([b, a]))
    }

    func testXorIsDeterministic() {
        let a = Mesh.cube(size: 0.8)
        let b = Mesh.sphere(slices: 16)
        let c = a.xor(b)
        #if !arch(wasm32)
        XCTAssertEqual(c.polygons.count, 323)
        #endif
        XCTAssertEqual(c, .xor([a, b]))
    }

    func testXorOfOne() {
        let mesh = Mesh.cube()
        XCTAssertEqual(mesh, .xor([mesh]))
    }

    func testXorOfNone() {
        XCTAssertEqual(Mesh.empty, .xor([]))
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
        let b = Mesh.cube().translated(by: Vector(0.5, 0, 0))
        let c = a.union(b)
        XCTAssertEqual(c.bounds, Bounds(
            min: Vector(-0.5, -0.5, -0.5),
            max: Vector(1, 0.5, 0.5)
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
        XCTAssertEqual(c.polygons.count, 237)
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
        let c = a.intersect(b)
        XCTAssertEqual(c.bounds, a.bounds)
        XCTAssertEqual(c, .intersection([a, b]))
    }

    func testIntersectionOfAdjacentBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube().translated(by: .unitX)
        let c = a.intersect(b)
        // TODO: ideally this should probably be empty, but it's not clear
        // how to achieve that while also getting desired planar behavior
        XCTAssertEqual(c.bounds, Bounds(
            min: Vector(0.5, -0.5, -0.5),
            max: Vector(0.5, 0.5, 0.5)
        ))
        XCTAssertEqual(c, .intersection([a, b]))
    }

    func testIntersectionOfOverlappingBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube().translated(by: Vector(0.5, 0, 0))
        let c = a.intersect(b)
        XCTAssertEqual(c.bounds, Bounds(
            min: Vector(0, -0.5, -0.5),
            max: Vector(0.5, 0.5, 0.5)
        ))
        XCTAssertEqual(c, .intersection([a, b]))
    }

    func testIntersectionOfNonOverlappingBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube().translated(by: Vector(2, 0, 0))
        let c = a.intersect(b)
        XCTAssertEqual(c, .empty)
        XCTAssertEqual(c, .intersection([a, b]))
    }

    func testIntersectionWithEmptyMesh() {
        let a = Mesh.empty
        let b = Mesh.cube()
        XCTAssert(a.intersect(b).bounds.isEmpty)
        XCTAssert(b.intersect(a).bounds.isEmpty)
    }

    func testIntersectIsDeterministic() {
        let a = Mesh.cube(size: 0.8)
        let b = Mesh.sphere(slices: 16)
        let c = a.intersect(b)
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

    // MARK: Planar subtraction

    func testSubtractCoincidingSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square())
        let c = a.subtract(b)
        XCTAssert(c.polygons.isEmpty)
        XCTAssertEqual(c, .difference([a, b]))
    }

    func testSubtractAdjacentSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square()).translated(by: .unitX)
        let c = a.subtract(b)
        XCTAssertEqual(c.bounds, a.bounds)
        XCTAssertEqual(c, .difference([a, b]))
    }

    func testSubtractOverlappingSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square()).translated(by: Vector(0.5, 0, 0))
        let c = a.subtract(b)
        XCTAssertEqual(c.bounds, Bounds(
            min: Vector(-0.5, -0.5, 0),
            max: Vector(0, 0.5, 0)
        ))
        XCTAssertEqual(c, .difference([a, b]))
    }

    // MARK: Planar XOR

    func testXorCoincidingSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square())
        let c = a.xor(b)
        XCTAssert(c.polygons.isEmpty)
        XCTAssertEqual(c, .xor([a, b]))
    }

    func testXorAdjacentSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square()).translated(by: .unitX)
        let c = a.xor(b)
        XCTAssertEqual(c.bounds, a.bounds.union(b.bounds))
        XCTAssertEqual(c, .xor([a, b]))
    }

    func testXorOverlappingSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square()).translated(by: Vector(0.5, 0, 0))
        let c = a.xor(b)
        XCTAssertEqual(c.bounds, Bounds(
            min: Vector(-0.5, -0.5, 0),
            max: Vector(1.0, 0.5, 0)
        ))
        XCTAssertEqual(c, .xor([a, b]))
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
        let b = Mesh.fill(.square()).translated(by: Vector(0.5, 0, 0))
        let c = a.union(b)
        XCTAssertEqual(c.bounds, Bounds(
            min: Vector(-0.5, -0.5, 0),
            max: Vector(1, 0.5, 0)
        ))
        XCTAssertEqual(c, .union([a, b]))
    }

    // MARK: Planar intersection

    func testIntersectionOfCoincidingSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square())
        let c = a.intersect(b)
        XCTAssertEqual(c.bounds, a.bounds)
        XCTAssertEqual(c, .intersection([a, b]))
    }

    func testIntersectionOfAdjacentSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square()).translated(by: .unitX)
        let c = a.intersect(b)
        XCTAssert(c.polygons.isEmpty)
        XCTAssertEqual(c, .intersection([a, b]))
    }

    func testIntersectionOfOverlappingSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square()).translated(by: Vector(0.5, 0, 0))
        let c = a.intersect(b)
        XCTAssertEqual(c.bounds, Bounds(
            min: Vector(0, -0.5, 0),
            max: Vector(0.5, 0.5, 0)
        ))
        XCTAssertEqual(c, .intersection([a, b]))
    }

    // MARK: Plane clipping

    func testSquareClippedToPlane() {
        let a = Mesh.fill(.square())
        let plane = Plane(unchecked: .unitX, pointOnPlane: .zero)
        let b = a.clip(to: plane)
        XCTAssertEqual(b.bounds, .init(Vector(0, -0.5), Vector(0.5, 0.5)))
    }

    func testPentagonClippedToPlane() {
        let a = Mesh.fill(.circle(segments: 5))
        let plane = Plane(unchecked: .unitX, pointOnPlane: .zero)
        let b = a.clip(to: plane)
        XCTAssertEqual(b.bounds, .init(
            Vector(0, -0.404508497187),
            Vector(0.475528258148, 0.5)
        ))
    }

    func testDiamondClippedToPlane() {
        let a = Mesh.fill(.circle(segments: 4))
        let plane = Plane(unchecked: .unitX, pointOnPlane: .zero)
        let b = a.clip(to: plane)
        XCTAssertEqual(b.bounds, .init(Vector(0, -0.5), Vector(0.5, 0.5)))
    }

    func testSquareClippedToItsOwnPlane() {
        let a = Mesh.fill(.square())
        let plane = Plane(unchecked: .unitZ, pointOnPlane: .zero)
        let b = a.clip(to: plane)
        XCTAssertEqual(b.polygons, [a.polygons[0]])
    }

    func testSquareClippedToItsOwnPlaneWithFill() {
        let a = Mesh.fill(.square())
        let plane = Plane(unchecked: .unitZ, pointOnPlane: .zero)
        let b = a.clip(to: plane, fill: Color.white)
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
        let b = a.clip(to: plane)
        XCTAssertEqual(b.polygons, [a.polygons[1]])
    }

    func testSquareClippedToReversePlaneWithFill() {
        let a = Mesh.fill(.square())
        let plane = Plane(unchecked: -.unitZ, pointOnPlane: .zero)
        let b = a.clip(to: plane, fill: Color.white)
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
        XCTAssertEqual(b.0?.bounds, .init(Vector(0, -0.5), Vector(0.5, 0.5)))
        XCTAssertEqual(b.1?.bounds, .init(Vector(-0.5, -0.5), Vector(0, 0.5)))
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
}
