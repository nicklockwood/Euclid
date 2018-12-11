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

    func testSubtractAdjacentBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube().translated(by: Vector(1, 0, 0))
        let c = a.subtract(b)
        XCTAssertEqual(c.bounds, a.bounds)
    }

    func testSubtractOverlappingBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube().translated(by: Vector(0.5, 0, 0))
        let c = a.subtract(b)
        XCTAssertEqual(c.bounds, Bounds(
            min: Vector(-0.5, -0.5, -0.5),
            max: Vector(0, 0.5, 0.5)
        ))
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
        let b = Mesh.cube().translated(by: Vector(1, 0, 0))
        let c = a.union(b)
        XCTAssertEqual(c.bounds, a.bounds.union(b.bounds))
    }

    func testUnionOfOverlappingBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube().translated(by: Vector(0.5, 0, 0))
        let c = a.union(b)
        XCTAssertEqual(c.bounds, Bounds(
            min: Vector(-0.5, -0.5, -0.5),
            max: Vector(1, 0.5, 0.5)
        ))
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
        let b = Mesh.cube().translated(by: Vector(1, 0, 0))
        let c = a.intersect(b)
        XCTAssert(c.polygons.isEmpty)
    }

    func testIntersectionOfOverlappingBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube().translated(by: Vector(0.5, 0, 0))
        let c = a.intersect(b)
        XCTAssertEqual(c.bounds, Bounds(
            min: Vector(0, -0.5, -0.5),
            max: Vector(0.5, 0.5, 0.5)
        ))
    }
}
