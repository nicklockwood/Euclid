//
//  BoundsTests.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 22/01/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

class BoundsTests: XCTestCase {
    // MARK: Union

    func testUnionOfCoincidingBounds() {
        let a = Bounds(min: Vector(-1, -1, -1), max: Vector(1, 1, 1))
        let b = Bounds(min: Vector(-1, -1, -1), max: Vector(1, 1, 1))
        let c = a.union(b)
        XCTAssertEqual(c, a)
    }

    func testUnionOfAdjacentBounds() {
        let a = Bounds(min: Vector(-1, -0.5, -0.5), max: Vector(0, 0.5, 0.5))
        let b = Bounds(min: Vector(0, -0.5, -0.5), max: Vector(1, 0.5, 0.5))
        let c = Bounds(min: Vector(-1, -0.5, -0.5), max: Vector(1, 0.5, 0.5))
        XCTAssertEqual(a.union(b), c)
    }

    func testUnionOfEmptyAndBounds() {
        let a = Bounds.empty
        let b = Bounds(min: Vector(-1, -1, -1), max: Vector(1, 1, 1))
        let c = a.union(b)
        XCTAssertEqual(c, b)
    }

    func testUnionOfBoundsAndEmpty() {
        let a = Bounds(min: Vector(-1, -1, -1), max: Vector(1, 1, 1))
        let b = Bounds.empty
        let c = a.union(b)
        XCTAssertEqual(c, a)
    }

    // MARK: Intersection

    func testIntersectionOfCoincidingBounds() {
        let a = Bounds(min: Vector(-1, -1, -1), max: Vector(1, 1, 1))
        let b = Bounds(min: Vector(-1, -1, -1), max: Vector(1, 1, 1))
        let c = a.intersection(b)
        XCTAssertEqual(c, a)
    }

    func testIntersectionOfAdjacentBounds() {
        let a = Bounds(min: Vector(-1, -0.5, -0.5), max: Vector(0, 0.5, 0.5))
        let b = Bounds(min: Vector(0, -0.5, -0.5), max: Vector(1, 0.5, 0.5))
        let c = Bounds(min: Vector(0, -0.5, -0.5), max: Vector(0, 0.5, 0.5))
        XCTAssertEqual(a.intersection(b), c)
    }

    func testIntersectionOfEmptyAndBounds() {
        let a = Bounds.empty
        let b = Bounds(min: Vector(-1, -1, -1), max: Vector(1, 1, 1))
        let c = a.intersection(b)
        XCTAssertEqual(c, .empty)
    }

    func testIntersectionOfBoundsAndEmpty() {
        let a = Bounds(min: Vector(-1, -1, -1), max: Vector(1, 1, 1))
        let b = Bounds.empty
        let c = a.intersection(b)
        XCTAssertEqual(c, .empty)
    }

    // MARK: isEmpty

    func testEmptyBoundsIsEmpty() {
        let bounds = Bounds.empty
        XCTAssert(bounds.isEmpty)
    }

    func testNegativeVolumeBoundsIsEmpty() {
        let bounds = Bounds(min: .one, max: -.one)
        XCTAssert(bounds.isEmpty)
    }

    func testZeroSizedBoundsIsEmpty() {
        let bounds = Bounds(min: .zero, max: .zero)
        XCTAssert(bounds.isEmpty)
    }

    func testBoundsWithNegativeWidthIsEmpty() {
        let bounds = Bounds(min: .zero, max: Vector(-1, 1, 1))
        XCTAssert(bounds.isEmpty)
    }

    func testBoundsWithZeroWidthIsNotEmpty() {
        let bounds = Bounds(min: .zero, max: Vector(0, 1, 1))
        XCTAssertFalse(bounds.isEmpty)
    }

    func testBoundsWithNegativeHeightIsEmpty() {
        let bounds = Bounds(min: .zero, max: Vector(1, -1, 1))
        XCTAssert(bounds.isEmpty)
    }

    func testBoundsWithZeroHeightIsNotEmpty() {
        let bounds = Bounds(min: .zero, max: Vector(1, 0, 1))
        XCTAssertFalse(bounds.isEmpty)
    }

    func testBoundsWithNegativeDepthIsEmpty() {
        let bounds = Bounds(min: .zero, max: Vector(1, 1, -1))
        XCTAssert(bounds.isEmpty)
    }

    func testBoundsWithZeroDepthIsNotEmpty() {
        let bounds = Bounds(min: .zero, max: Vector(1, 1, 0))
        XCTAssertFalse(bounds.isEmpty)
    }

    func testRotatedEmptyBoundsIsEmpty() {
        let rotation = Rotation(
            roll: .radians(-0.5 * .pi),
            yaw: .radians(-0.4999 * .pi),
            pitch: .radians(-0.5 * .pi)
        )
        XCTAssert(Bounds.empty.rotated(by: rotation).isEmpty)
        XCTAssert(Bounds.empty.transformed(by: .rotation(rotation)).isEmpty)
    }

    func testTranslatedEmptyBoundsIsEmpty() {
        let offset = Vector(2.5539, 0.5531, 0.0131)
        XCTAssert(Bounds.empty.translated(by: offset).isEmpty)
        XCTAssert(Bounds.empty.transformed(by: .translation(offset)).isEmpty)
    }

    func testScaledEmptyBoundsIsEmpty() {
        XCTAssert(Bounds.empty.scaled(by: 0).isEmpty)
        XCTAssert(Bounds.empty.scaled(by: -1).isEmpty)
        XCTAssert(Bounds.empty.transformed(by: .scale(.zero)).isEmpty)
        XCTAssert(Bounds.empty.transformed(by: .scale(-.one)).isEmpty)
    }
}
