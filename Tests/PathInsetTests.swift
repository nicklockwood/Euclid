//
//  PathInsetTests.swift
//  Euclid
//
//  Created by Nick Lockwood on 26/07/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

final class PathInsetTests: XCTestCase {
    func testInsetSquare() {
        let path = Path.square()
        let result = path.inset(by: 0.25)
        XCTAssertEqual(result, .square(size: 0.5))
    }

    func testInsetSquarePastRadiusIsEmpty() {
        let path = Path.square()
        XCTAssertFalse(path.inset(by: 0.25).isEmpty)
        XCTAssertFalse(path.inset(by: 0.4999).isEmpty)
        XCTAssertTrue(path.inset(by: 0.5).isEmpty)
        XCTAssertTrue(path.inset(by: 0.6).isEmpty)
        XCTAssertTrue(path.inset(by: 1.1).isEmpty)
    }

    func testInsetCircle() {
        let path = Path.circle(segments: 4)
        let result = path.inset(by: 0.25)
        let adjacent = sqrt(pow(0.5, 2) * 2) / 2
        let radius = sqrt(pow(adjacent - 0.25, 2) * 2)
        XCTAssertEqual(result, .circle(radius: radius, segments: 4))
    }

    func testInsetCirclePastRadiusIsEmpty() {
        let path = Path.circle(radius: 0.5)
        XCTAssertFalse(path.inset(by: 0.25).isEmpty)
        XCTAssertFalse(path.inset(by: 0.49).isEmpty)
        XCTAssertTrue(path.inset(by: 0.4999).isEmpty)
        XCTAssertTrue(path.inset(by: 0.6).isEmpty)
        XCTAssertTrue(path.inset(by: 1.1).isEmpty)
    }

    func testInsetLShape() {
        let path = Path([
            .point(0, 0),
            .point(0, 2),
            .point(1, 2),
            .point(1, 1),
            .point(2, 1),
            .point(2, 0),
            .point(0, 0),
        ])
        let result = path.inset(by: 0.25)
        XCTAssertEqual(result, Path([
            .point(0.25, 0.25),
            .point(0.25, 1.75),
            .point(0.75, 1.75),
            .point(0.75, 0.75),
            .point(1.75, 0.75),
            .point(1.75, 0.25),
            .point(0.25, 0.25),
        ]))
    }

    func testInsetNarrowUShapeRemovesCrossingLines() {
        let path = Path([
            .point(0, 0),
            .point(0, 3),
            .point(1, 3),
            .point(1, 1),
            .point(2, 1),
            .point(2, 3),
            .point(3, 3),
            .point(3, 0),
            .point(0, 0),
        ])
        let result = path.inset(by: 0.6)
        XCTAssertFalse(result.orderedEdgesContainCrossings)
    }

    func testInsetNarrowUShapeIsRotationInvariant() {
        let path = Path([
            .point(0, 0),
            .point(0, 3),
            .point(1, 3),
            .point(1, 1),
            .point(2, 1),
            .point(2, 3),
            .point(3, 3),
            .point(3, 0),
            .point(0, 0),
        ])
        let rotation = Rotation(roll: .pi / 3)
        let expected = path.inset(by: 0.6).rotated(by: rotation)
        let result = path.rotated(by: rotation).inset(by: 0.6)

        XCTAssertEqual(result.points.count, expected.points.count)
        XCTAssertFalse(result.orderedEdgesContainCrossings)
        XCTAssertTrue(zip(result.points, expected.points).allSatisfy {
            $0.position.isApproximatelyEqual(to: $1.position, absoluteTolerance: 1e-10)
        })
    }

    func testInsetNarrowUShapeScalesWithDistance() {
        let path = Path([
            .point(0, 0),
            .point(0, 3),
            .point(1, 3),
            .point(1, 1),
            .point(2, 1),
            .point(2, 3),
            .point(3, 3),
            .point(3, 0),
            .point(0, 0),
        ])
        let expected = path.inset(by: 0.6).scaled(by: 10)
        let result = path.scaled(by: 10).inset(by: 6)

        XCTAssertEqual(result.points.count, expected.points.count)
        XCTAssertFalse(result.orderedEdgesContainCrossings)
        XCTAssertTrue(zip(result.points, expected.points).allSatisfy {
            $0.position.isApproximatelyEqual(to: $1.position, absoluteTolerance: 1e-9)
        })
    }

    func testInsetCompoundPathExpandsHole() {
        let path = Path(subpaths: [
            .square(size: 2),
            .square(size: 0.5),
        ])
        let result = path.inset(by: 0.25)
        XCTAssertEqual(result, Path(subpaths: [
            .square(size: 1.5),
            .square(size: 1),
        ]))
    }

    func testInsetCompoundPathAlternatesNestedContours() {
        let path = Path(subpaths: [
            .square(size: 4),
            .square(size: 2),
            .square(size: 1),
        ])
        let result = path.inset(by: 0.25)
        XCTAssertEqual(result, Path(subpaths: [
            .square(size: 3.5),
            .square(size: 2.5),
            .square(size: 0.5),
        ]))
    }

    func testInsetSelfIntersectingPathUsesNonZeroFillBoundary() {
        let path = Path([
            .point(0, 0),
            .point(1, 1),
            .point(1, 0),
            .point(0, 1),
        ])
        let result = path.inset(by: 0.1)
        XCTAssertFalse(result.orderedEdgesContainCrossings)
        XCTAssertTrue(Mesh.fill(result).isWatertight)
    }

    func testInsetSelfIntersectingCurvedPathUsesNonZeroFillBoundary() {
        let path = Path([
            .curve(0, 0),
            .curve(1, 0),
            .curve(0, 2),
            .curve(1, 2),
            .curve(0, 0),
        ])
        let result = path.inset(by: 0.1)
        XCTAssertGreaterThan(result.subpaths.count, 1)
        XCTAssertFalse(result.orderedEdgesContainCrossings)
        XCTAssertTrue(Mesh.fill(result).isWatertight)
    }
}
