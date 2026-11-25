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

    func testOutsetSquareWithMiterLimit() {
        let square = Path.square(size: 4, color: .red)
        let beveled = square.inset(by: -1, miterLimit: 1)
        let corner = 1 + sqrt(2.0)
        let quadrant = [Vector(3, corner), Vector(corner, 3)]
        let expected = quadrant.flatMap { point -> [Vector] in
            [point, [-point.x, point.y], [point.x, -point.y], -point]
        }
        XCTAssertTrue(beveled.isClosed)
        XCTAssertEqual(beveled.points.count, 9)
        XCTAssertTrue(expected.allSatisfy { position in
            beveled.points.contains { $0.position.isApproximatelyEqual(to: position) }
        })
        XCTAssertTrue(beveled.points.allSatisfy { $0.color == .red })
        XCTAssertEqual(square.inset(by: -1, miterLimit: .degrees(100)), square.inset(by: -1))
        XCTAssertEqual(square.inset(by: 1, miterLimit: 1), square.inset(by: 1))
    }

    func testInsetBevelsConcaveCorner() {
        let path = Path([
            .point(0, 0), .point(8, 0), .point(8, 4),
            .point(4, 4), .point(4, 8), .point(0, 8),
        ]).closed()
        let result = path.inset(by: 1, miterLimit: 1)
        let corner = 5 - sqrt(2.0)
        XCTAssertTrue(result.isClosed)
        XCTAssertFalse(result.orderedEdgesContainCrossings)
        XCTAssertEqual(result.points.count, 8)
        XCTAssertTrue(result.points.contains { $0.position.isApproximatelyEqual(to: [corner, 3]) })
        XCTAssertTrue(result.points.contains { $0.position.isApproximatelyEqual(to: [3, corner]) })

        let rotation = Rotation(pitch: .pi / 5, yaw: .pi / 7)
        let rotated = path.rotated(by: rotation).inset(by: 1, miterLimit: 1)
        XCTAssertTrue(rotated.isApproximatelyEqual(to: result.rotated(by: rotation)))
    }

    func testInsetBevelsExpandingHoles() {
        let profile = Path(subpaths: [.square(size: 8), .square(size: 4)], windingRule: .evenOdd)
        let result = profile.inset(by: 0.5, miterLimit: 1)
        XCTAssertEqual(result.windingRule, .evenOdd)
        XCTAssertEqual(result.subpaths.map(\.points.count).sorted(), [5, 9])
        let cut = (2 - sqrt(2.0)) * 0.5
        XCTAssertEqual(Mesh.fill(result, faces: .front).surfaceArea, 49 - 25 + 2 * cut * cut, accuracy: epsilon)
    }

    func testOutsetOpenPathPreservesItsEndpoints() {
        let path = Path([.point(0, 4), .point(0, 0), .point(4, 0)])
        let mitered = path.inset(by: -1)
        let beveled = path.inset(by: -1, miterLimit: 1)
        XCTAssertFalse(beveled.isClosed)
        XCTAssertEqual(beveled.points.first, mitered.points.first)
        XCTAssertEqual(beveled.points.last, mitered.points.last)
        XCTAssertEqual(beveled.points.count, 4)
    }

    func testBeveledOffsetsResolveCrossingsAtNarrowBridge() {
        let path = Path([
            .point(0, 0), .point(4, 0), .point(4, 1.5), .point(7, 1.5),
            .point(7, 0), .point(11, 0), .point(11, 4), .point(7, 4),
            .point(7, 2.5), .point(4, 2.5), .point(4, 4), .point(0, 4),
        ]).closed()
        let tip = 0.5 - 0.75 * (sqrt(2.0) - 1)
        for profile in [path, path.inverted(), path.rotated(by: .pitch(.halfPi))] {
            let result = profile.inset(by: 0.75, miterLimit: 1)
            XCTAssertEqual(result.subpaths.count, 2)
            XCTAssertTrue(result.subpaths.allSatisfy { $0.isClosed && !$0.orderedEdgesContainCrossings })
            XCTAssertEqual(Mesh.fill(result, faces: .front).surfaceArea, 12.5 + 2 * tip * tip, accuracy: epsilon)
        }
        let expanded = path.inset(by: -5, miterLimit: 1)
        XCTAssertEqual(expanded.subpaths.count, 1)
        XCTAssertFalse(expanded.orderedEdgesContainCrossings)
        let cut = 5 * (2 - sqrt(2.0))
        XCTAssertEqual(Mesh.fill(expanded, faces: .front).surfaceArea, 21 * 14 - 2 * cut * cut, accuracy: epsilon)
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

    func testInsetCompoundPathRespectsExplicitWindingRule() {
        let path = Path(subpaths: [.square(size: 4), .square(size: 2)], windingRule: .nonZero)
        let inset = path.inset(by: 0.25)

        XCTAssertEqual(inset.subpaths.count, 1)
        XCTAssertEqual(inset.windingRule, .nonZero)
        XCTAssertEqual(Mesh.fill(inset, faces: .front).surfaceArea, 12.25, accuracy: epsilon)
        XCTAssertEqual(path.inset(by: 2), .empty)
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

    func testInsetCanBeCancelled() {
        nonisolated(unsafe) var cancellationChecks = 0
        let result = Path.square().inset(by: 0.1) {
            cancellationChecks += 1
            return true
        }

        XCTAssertEqual(result, .empty)
        XCTAssertEqual(cancellationChecks, 1)
    }
}
