//
//  PolygonCSGTests.swift
//  Euclid
//
//  Created by Nick Lockwood on 15/01/2023.
//  Copyright © 2023 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

class PolygonCSGTests: XCTestCase {
    // MARK: Plane clipping

    func testSquareClippedToPlane() {
        let a = Path.square().facePolygons()[0]
        let plane = Plane(unchecked: .unitX, pointOnPlane: .zero)
        let b = a.clipped(to: plane)
        XCTAssertEqual(Bounds(b), Bounds([0, -0.5], [0.5, 0.5]))
    }

    func testPentagonClippedToPlane() {
        let a = Path.circle(segments: 5).facePolygons()[0]
        let plane = Plane(unchecked: .unitX, pointOnPlane: .zero)
        let b = a.clipped(to: plane)
        XCTAssertEqual(Bounds(b), Bounds(
            [0, -0.404508497187],
            [0.475528258148, 0.5]
        ))
    }

    func testDiamondClippedToPlane() {
        let a = Path.circle(segments: 4).facePolygons()[0]
        let plane = Plane(unchecked: .unitX, pointOnPlane: .zero)
        let b = a.clipped(to: plane)
        XCTAssertEqual(Bounds(b), Bounds([0, -0.5], [0.5, 0.5]))
    }

    // MARK: Plane splitting

    func testSquareSplitAlongPlane() {
        let a = Path.square().facePolygons()[0]
        let plane = Plane(unchecked: .unitX, pointOnPlane: .zero)
        let b = a.split(along: plane)
        XCTAssertEqual(
            Bounds(b.0),
            Bounds([0, -0.5], [0.5, 0.5])
        )
        XCTAssertEqual(
            Bounds(b.1),
            Bounds([-0.5, -0.5], [0, 0.5])
        )
        XCTAssertEqual(b.front, b.0)
        XCTAssertEqual(b.back, b.1)
    }

    func testSquareSplitAlongItsOwnPlane() {
        let a = Path.square().facePolygons()[0]
        let plane = Plane(unchecked: .unitZ, pointOnPlane: .zero)
        let b = a.split(along: plane)
        XCTAssertEqual(b.front, [a])
        XCTAssert(b.back.isEmpty)
    }

    func testSquareSplitAlongReversePlane() {
        let a = Path.square().facePolygons()[0]
        let plane = Plane(unchecked: -.unitZ, pointOnPlane: .zero)
        let b = a.split(along: plane)
        XCTAssertEqual(b.back, [a])
        XCTAssert(b.front.isEmpty)
    }
}
