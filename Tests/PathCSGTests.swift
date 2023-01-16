//
//  PathCSGTests.swift
//  Euclid
//
//  Created by Nick Lockwood on 01/09/2023.
//  Copyright © 2023 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

class PathCSGTests: XCTestCase {
    // MARK: XOR

    func testXorCoincidingSquares() {
        let a = Path.square()
        let b = Path.square()
        let c = a.xor(b)
        XCTAssert(c.isEmpty)
    }

    func testXorAdjacentSquares() {
        let a = Path.square()
        let b = a.translated(by: .unitX)
        let c = a.xor(b)
        XCTAssertEqual(Bounds(c), a.bounds.union(b.bounds))
    }

    func testXorOverlappingSquares() {
        let a = Path.square()
        let b = a.translated(by: Vector(0.5, 0, 0))
        let c = a.xor(b)
        XCTAssertEqual(Bounds(c), Bounds(
            min: Vector(-0.5, -0.5, 0),
            max: Vector(1.0, 0.5, 0)
        ))
    }

    // MARK: Plane splitting

    func testSquareSplitAlongPlane() {
        let a = Path.square()
        let plane = Plane(unchecked: .unitX, pointOnPlane: .zero)
        let b = a.split(along: plane)
        XCTAssertEqual(
            Bounds(b.0),
            .init(Vector(0, -0.5), Vector(0.5, 0.5))
        )
        XCTAssertEqual(
            Bounds(b.1),
            .init(Vector(-0.5, -0.5), Vector(0, 0.5))
        )
        XCTAssertEqual(b.front, b.0)
        XCTAssertEqual(b.back, b.1)
    }

    func testSplitLineAlongPlane() {
        let a = Path.line(Vector(-0.5, 0), Vector(0.5, 0))
        let plane = Plane(unchecked: .unitX, pointOnPlane: .zero)
        let b = a.split(along: plane)
        XCTAssertEqual(b.front, [Path.line(Vector(0, 0), Vector(0.5, 0))])
        XCTAssertEqual(b.back, [Path.line(Vector(-0.5, 0), Vector(0, 0))])
    }

    func testSquareSplitAlongItsOwnPlane() {
        let a = Path.square()
        let plane = Plane(unchecked: .unitZ, pointOnPlane: .zero)
        let b = a.split(along: plane)
        XCTAssertEqual(Bounds(b.front), a.bounds)
        XCTAssert(b.back.isEmpty)
    }

    func testSquareSplitAlongReversePlane() {
        let a = Path.square()
        let plane = Plane(unchecked: -.unitZ, pointOnPlane: .zero)
        let b = a.split(along: plane)
        XCTAssertEqual(Bounds(b.front), a.bounds)
        XCTAssert(b.back.isEmpty)
    }
}
