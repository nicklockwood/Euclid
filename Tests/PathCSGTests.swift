//
//  PathCSGTests.swift
//  Euclid
//
//  Created by Nick Lockwood on 25/08/2025.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

class PathCSGTests: XCTestCase {
    // MARK: Plane clipping

    func testSquareClippedToPlane() {
        let a = Path.square()
        let plane = Plane(unchecked: .unitX, pointOnPlane: .zero)
        let b = a.clipped(to: plane)
        XCTAssertEqual(b, Path([
            .point(0.0, -0.5),
            .point(0.5, -0.5),
            .point(0.5, 0.5),
            .point(0.0, 0.5),
        ]))
    }

    func testPentagonClippedToPlane() {
        let a = Path.circle(segments: 5)
        let plane = Plane(unchecked: .unitX, pointOnPlane: .zero)
        let b = a.clipped(to: plane)
        XCTAssertEqual(b, Path([
            .curve(0.0, -0.404508497187),
            .curve(0.293892626146, -0.404508497187),
            .curve(0.475528258148, 0.154508497187),
            .curve(0.0, 0.5),
        ]))
    }

    func testDiamondClippedToPlane() {
        let a = Path.circle(segments: 4)
        let plane = Plane(unchecked: .unitX, pointOnPlane: .zero)
        let b = a.clipped(to: plane)
        XCTAssertEqual(b, Path([
            .curve(-0.0, -0.5),
            .curve(0.5, -0.0),
            .curve(0.0, 0.5),
        ]))
    }

    // MARK: Plane splitting

    func testSquareSplitAlongPlane() {
        let a = Path.square()
        let plane = Plane(unchecked: .unitX, pointOnPlane: .zero)
        let b = a.split(along: plane)
        XCTAssertEqual(Bounds(b.front), Bounds([0, -0.5], [0.5, 0.5]))
        XCTAssertEqual(Bounds(b.back), Bounds([-0.5, -0.5], [0, 0.5]))
        XCTAssertEqual(b.front, b.0)
        XCTAssertEqual(b.back, b.1)
    }

    func testDiamondSplitAlongPlane() {
        let a = Path.circle(segments: 4)
        let plane = Plane(unchecked: .unitX, pointOnPlane: .zero)
        let b = a.split(along: plane)
        XCTAssertEqual(b.front, Path([
            .curve(0.0, -0.5),
            .curve(0.5, 0.0),
            .curve(0.0, 0.5),
        ]))
        XCTAssertEqual(b.back, Path([
            .curve(0.0, 0.5),
            .curve(-0.5, 0.0),
            .curve(0.0, -0.5),
        ]))
    }

    func testSquareSplitAlongItsOwnPlane() {
        let a = Path.square()
        let plane = Plane(unchecked: .unitZ, pointOnPlane: .zero)
        let b = a.split(along: plane)
        XCTAssertEqual(b.front, a)
        XCTAssert(b.back.isEmpty)
    }

    func testSquareSplitAlongReversePlane() {
        let a = Path.square()
        let plane = Plane(unchecked: -.unitZ, pointOnPlane: .zero)
        let b = a.split(along: plane)
        XCTAssertEqual(b.back, a)
        XCTAssert(b.front.isEmpty)
    }
}
