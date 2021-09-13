//
//  CSGTests.swift
//  GeometryScriptTests
//
//  Created by Nick Lockwood on 31/10/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

class CSGTests: XCTestCase {
    // MARK: Subtraction

    func testSubtractCoincidingBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube()
        let c = a.subtract(b)
        XCTAssert(c.polygons.isEmpty)
    }

    func testSubtractCoincidingBoxesWhenTriangulated() {
        let a = Mesh.cube().triangulate()
        let b = Mesh.cube().triangulate()
        let c = a.subtract(b)
        XCTAssert(c.polygons.isEmpty)
    }

    func testSubtractAdjacentBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube().translated(by: Distance(1, 0, 0))
        let c = a.subtract(b)
        XCTAssertEqual(c.bounds, a.bounds)
    }

    func testSubtractOverlappingBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube().translated(by: Distance(0.5, 0, 0))
        let c = a.subtract(b)
        XCTAssertEqual(c.bounds, Bounds(
            min: Position(-0.5, -0.5, -0.5),
            max: Position(0, 0.5, 0.5)
        ))
    }

    func testSubtractEmptyMesh() {
        let a = Mesh([])
        let b = Mesh.cube()
        XCTAssertEqual(a.subtract(b), a)
        XCTAssertEqual(b.subtract(a), b)
    }

    // MARK: XOR

    func testXorCoincidingCubes() {
        let a = Mesh.cube()
        let b = Mesh.cube()
        let c = a.xor(b)
        XCTAssert(c.polygons.isEmpty)
    }

    func testXorAdjacentCubes() {
        let a = Mesh.cube()
        let b = Mesh.cube().translated(by: Distance(1, 0, 0))
        let c = a.xor(b)
        XCTAssertEqual(c.bounds, a.bounds.union(b.bounds))
    }

    func testXorOverlappingCubes() {
        let a = Mesh.cube()
        let b = Mesh.cube().translated(by: Distance(0.5, 0, 0))
        let c = a.xor(b)
        XCTAssertEqual(c.bounds, Bounds(
            min: Position(-0.5, -0.5, -0.5),
            max: Position(1.0, 0.5, 0.5)
        ))
    }

    func testXorWithEmptyMesh() {
        let a = Mesh([])
        let b = Mesh.cube()
        XCTAssertEqual(a.xor(b), b)
        XCTAssertEqual(b.xor(a), b)
    }

    // MARK: Union

    func testUnionOfCoincidingBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube()
        let c = a.union(b)
        XCTAssertEqual(c.bounds, a.bounds)
    }

    func testUnionOfAdjacentBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube().translated(by: Distance(1, 0, 0))
        let c = a.union(b)
        XCTAssertEqual(c.bounds, a.bounds.union(b.bounds))
    }

    func testUnionOfOverlappingBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube().translated(by: Distance(0.5, 0, 0))
        let c = a.union(b)
        XCTAssertEqual(c.bounds, Bounds(
            min: Position(-0.5, -0.5, -0.5),
            max: Position(1, 0.5, 0.5)
        ))
    }

    func testUnionWithEmptyMesh() {
        let a = Mesh([])
        let b = Mesh.cube()
        XCTAssertEqual(a.union(b).bounds, b.bounds)
        XCTAssertEqual(b.union(a).bounds, b.bounds)
    }

    // MARK: Intersection

    func testIntersectionOfCoincidingBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube()
        let c = a.intersect(b)
        XCTAssertEqual(c.bounds, a.bounds)
    }

    func testIntersectionOfAdjacentBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube().translated(by: Distance(1, 0, 0))
        let c = a.intersect(b)
        // TODO: ideally this should probably be empty, but it's not clear
        // how to achieve that while also getting desired planar behavior
        XCTAssertEqual(c.bounds, Bounds(
            min: Position(0.5, -0.5, -0.5),
            max: Position(0.5, 0.5, 0.5)
        ))
    }

    func testIntersectionOfOverlappingBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube().translated(by: Distance(0.5, 0, 0))
        let c = a.intersect(b)
        XCTAssertEqual(c.bounds, Bounds(
            min: Position(0, -0.5, -0.5),
            max: Position(0.5, 0.5, 0.5)
        ))
    }

    func testIntersectionWithEmptyMesh() {
        let a = Mesh([])
        let b = Mesh.cube()
        XCTAssert(a.intersect(b).bounds.isEmpty)
        XCTAssert(b.intersect(a).bounds.isEmpty)
    }

    // MARK: Planar subtraction

    func testSubtractCoincidingSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square())
        let c = a.subtract(b)
        XCTAssert(c.polygons.isEmpty)
    }

    func testSubtractAdjacentSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square()).translated(by: Distance(1, 0, 0))
        let c = a.subtract(b)
        XCTAssertEqual(c.bounds, a.bounds)
    }

    func testSubtractOverlappingSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square()).translated(by: Distance(0.5, 0, 0))
        let c = a.subtract(b)
        XCTAssertEqual(c.bounds, Bounds(
            min: Position(-0.5, -0.5, 0),
            max: Position(0, 0.5, 0)
        ))
    }

    // MARK: Planar XOR

    func testXorCoincidingSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square())
        let c = a.xor(b)
        XCTAssert(c.polygons.isEmpty)
    }

    func testXorAdjacentSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square()).translated(by: Distance(1, 0, 0))
        let c = a.xor(b)
        XCTAssertEqual(c.bounds, a.bounds.union(b.bounds))
    }

    func testXorOverlappingSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square()).translated(by: Distance(0.5, 0, 0))
        let c = a.xor(b)
        XCTAssertEqual(c.bounds, Bounds(
            min: Position(-0.5, -0.5, 0),
            max: Position(1.0, 0.5, 0)
        ))
    }

    // MARK: Planar union

    func testUnionOfCoincidingSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square())
        let c = a.union(b)
        XCTAssertEqual(c.bounds, a.bounds)
    }

    func testUnionOfAdjacentSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square()).translated(by: Distance(1, 0, 0))
        let c = a.union(b)
        XCTAssertEqual(c.bounds, a.bounds.union(b.bounds))
    }

    func testUnionOfOverlappingSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square()).translated(by: Distance(0.5, 0, 0))
        let c = a.union(b)
        XCTAssertEqual(c.bounds, Bounds(
            min: Position(-0.5, -0.5, 0),
            max: Position(1, 0.5, 0)
        ))
    }

    // MARK: Planar intersection

    func testIntersectionOfCoincidingSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square())
        let c = a.intersect(b)
        XCTAssertEqual(c.bounds, a.bounds)
    }

    func testIntersectionOfAdjacentSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square()).translated(by: Distance(1, 0, 0))
        let c = a.intersect(b)
        XCTAssert(c.polygons.isEmpty)
    }

    func testIntersectionOfOverlappingSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square()).translated(by: Distance(0.5, 0, 0))
        let c = a.intersect(b)
        XCTAssertEqual(c.bounds, Bounds(
            min: Position(0, -0.5, 0),
            max: Position(0.5, 0.5, 0)
        ))
    }
}
