//
//  PathCSGTests.swift
//  Euclid
//
//  Created by Nick Lockwood on 25/08/2025.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

final class PathCSGTests: XCTestCase {
    func testPathClippingKeepsOutsideAndSplitReturnsBothPortions() throws {
        let line = Path([.point(-3, 0), .point(3, 0)])
        let boundary = Path.square(size: 2)
        let split = try XCTUnwrap(line.split(along: boundary))
        XCTAssertEqual(split.inside.length, 2, accuracy: epsilon)
        XCTAssertEqual(split.outside.length, 4, accuracy: epsilon)
        XCTAssertEqual(split.outside.subpaths.count, 2)
        XCTAssertEqual(split.inside.length + split.outside.length, line.length, accuracy: epsilon)
        XCTAssertTrue(split.outside.points.allSatisfy { abs($0.position.x) >= 1 })
        XCTAssertEqual(try XCTUnwrap(line.clipped(to: boundary)), split.outside)
        XCTAssertTrue(try XCTUnwrap(boundary.clipped(to: boundary)).isEmpty)
        XCTAssertTrue(try XCTUnwrap(Path.square().clipped(to: boundary)).isEmpty)
        let enclosing = Path.square(size: 4)
        XCTAssertEqual(try XCTUnwrap(enclosing.clipped(to: boundary)).length, enclosing.length, accuracy: epsilon)
    }

    func testSplitPathEmptyInvalidAndCancelledInputs() throws {
        let line = Path([.point(-3, 0), .point(3, 0)])
        let emptyBoundary = try XCTUnwrap(line.split(along: Path.empty))
        XCTAssertTrue(emptyBoundary.inside.isEmpty)
        XCTAssertEqual(emptyBoundary.outside, line)
        let emptyInput = try XCTUnwrap(Path.empty.split(along: .square()))
        XCTAssertTrue(emptyInput.inside.isEmpty)
        XCTAssertTrue(emptyInput.outside.isEmpty)
        XCTAssertNil(line.split(along: line))
        XCTAssertNil(line.split(along: Path.square().translated(by: [0, 0, 1])))
        let checks = CancellationCounter()
        let cancelled = try XCTUnwrap(line.split(along: .square(), isCancelled: {
            checks.increment() > 5
        }))
        XCTAssertGreaterThan(checks.value, 5)
        XCTAssertTrue(cancelled.inside.isEmpty)
        XCTAssertTrue(cancelled.outside.isEmpty)
    }

    func testSplitOpenPathToClosedPath() throws {
        let line = Path([.point(-2, 0), .point(2, 0)])
        let clipped = try XCTUnwrap(line.split(along: .square(size: 2))?.inside)
        XCTAssertEqual(clipped.bounds, Bounds([-1, 0, 0], [1, 0, 0]))
        XCTAssertEqual(clipped.length, 2, accuracy: epsilon)
        XCTAssertFalse(clipped.isClosed)
        XCTAssertEqual(clipped.subpaths.count, 1)
        XCTAssertEqual(clipped.points.first?.position, [-1, 0, 0])
        XCTAssertEqual(clipped.points.last?.position, [1, 0, 0])
    }

    func testSplitPathPreservesMultipleCrossingsAndSubpaths() throws {
        let zigzag = Path([.point(-2, -0.5), .point(2, -0.5), .point(2, 0.5), .point(-2, 0.5)])
        let clipped = try XCTUnwrap(zigzag.split(along: .square(size: 2))?.inside)
        XCTAssertEqual(clipped.subpaths.count, 2)
        XCTAssertEqual(clipped.length, 4, accuracy: epsilon)
        let compound = Path(subpaths: [
            Path([.point(-2, -0.5), .point(2, -0.5)]),
            Path([.point(-2, 0.5), .point(2, 0.5)]),
        ])
        let result = try XCTUnwrap(compound.split(along: .square(size: 2))?.inside)
        XCTAssertEqual(result.subpaths.count, 2)
        XCTAssertEqual(result.length, 4, accuracy: epsilon)
    }

    func testSplitPathToRegionWithHole() throws {
        let ring = Path(subpaths: [.square(size: 4), .square(size: 2)])
        let line = Path([.point(-3, 0), .point(3, 0)])
        for boundary in [ring, ring.inverted()] {
            let clipped = try XCTUnwrap(line.split(along: boundary)?.inside)
            XCTAssertEqual(clipped.subpaths.count, 2)
            XCTAssertEqual(clipped.length, 2, accuracy: epsilon)
            XCTAssertEqual(clipped.bounds, Bounds([-2, 0, 0], [2, 0, 0]))
        }
    }

    func testSplitPathToConcaveAndDisjointRegions() throws {
        let uShape = Path([
            .point(-2, -2),
            .point(2, -2),
            .point(2, 2),
            .point(1, 2),
            .point(1, -1),
            .point(-1, -1),
            .point(-1, 2),
            .point(-2, 2),
        ]).closed()
        let line = Path([.point(-4, 0), .point(4, 0)])
        let clipped = try XCTUnwrap(line.split(along: uShape)?.inside)
        XCTAssertEqual(clipped.subpaths.count, 2)
        XCTAssertEqual(clipped.length, 2, accuracy: epsilon)
        let disjoint = Path(subpaths: [.square().translated(by: [-2, 0]), .square().translated(by: [2, 0])])
        let result = try XCTUnwrap(line.split(along: disjoint)?.inside)
        XCTAssertEqual(result.subpaths.count, 2)
        XCTAssertEqual(result.length, 2, accuracy: epsilon)
    }

    func testSplitClosedPathClipsCurvesRatherThanFilledArea() throws {
        XCTAssertTrue(try XCTUnwrap(Path.square(size: 4).split(along: .square(size: 2))?.inside).isEmpty)
        let inner = Path.square()
        XCTAssertEqual(
            try XCTUnwrap(inner.split(along: .square(size: 2))?.inside).length,
            inner.length,
            accuracy: epsilon
        )
        let boundary = Path.square(size: 2)
        XCTAssertEqual(
            try XCTUnwrap(boundary.split(along: boundary)?.inside).length,
            boundary.length,
            accuracy: epsilon
        )
    }

    func testSplitPathOnObliquePlane() throws {
        let rotation = Rotation(roll: .degrees(25), yaw: .degrees(35), pitch: .degrees(45))
        let offset = Vector(3, -2, 5)
        let line = Path([.point(-2, 0), .point(2, 0)]).rotated(by: rotation).translated(by: offset)
        let boundary = Path.square(size: 2).rotated(by: rotation).translated(by: offset)
        let clipped = try XCTUnwrap(line.split(along: boundary)?.inside)
        XCTAssertEqual(clipped.length, 2, accuracy: epsilon)
        XCTAssertTrue(clipped.points.allSatisfy { boundary.plane!.intersects($0.position) })
    }

    func testSplitPathInterpolatesPointAttributes() throws {
        let a = PathPoint.curve([-2, 0], texcoord: [0, 0], color: .red)
        let b = PathPoint.curve([2, 0], texcoord: [1, 0], color: .blue)
        let clipped = try XCTUnwrap(Path([a, b]).split(along: .square(size: 2))?.inside)
        XCTAssertEqual(clipped.points.first, a.lerp(b, 0.25))
        XCTAssertEqual(clipped.points.last, a.lerp(b, 0.75))
    }

    func testClipCoplanarPathToMeshStillKeepsOutsideFragments() {
        let line = Path([.point(-2, 0), .point(2, 0)])
        let mesh = Mesh.fill(.square(size: 2), faces: .frontAndBack)
        let clipped = line.clipped(to: mesh)
        XCTAssertEqual(clipped.subpaths.count, 2)
        XCTAssertEqual(clipped.length, 2, accuracy: epsilon)
        XCTAssertTrue(clipped.subpaths.allSatisfy { $0.points.allSatisfy { abs($0.position.x) >= 1 } })
    }

    func testClipPathInvalidEmptyAndCancelledInputs() throws {
        let line = Path([.point(-2, 0), .point(2, 0)])
        XCTAssertNil(line.clipped(to: line))
        XCTAssertNil(line.clipped(to: Path.square().translated(by: [0, 0, 1])))
        let nonplanar = Path([.point(0, 0), .point(1, 0), .point(1, 1, 1), .point(0, 1)]).closed()
        XCTAssertNil(line.clipped(to: nonplanar))
        XCTAssertNil(nonplanar.clipped(to: .square(size: 4)))
        XCTAssertEqual(try XCTUnwrap(line.clipped(to: Path.empty)), line)
        XCTAssertTrue(try XCTUnwrap(Path.empty.clipped(to: .square())).isEmpty)
        XCTAssertTrue(try XCTUnwrap(line.clipped(to: .square(), isCancelled: { true })).isEmpty)
        let checks = CancellationCounter()
        let cancelled = line.clipped(to: .square(), isCancelled: {
            checks.increment() > 5
        })
        XCTAssertGreaterThan(checks.value, 5)
        XCTAssertTrue(try XCTUnwrap(cancelled).isEmpty)
    }

    func testPathHullAndMinkowskiSumOfSquares() throws {
        let a = Path.square(size: 2)
        let b = a.translated(by: [3, 0, 0])
        let hull = try XCTUnwrap(a.convexHull(with: b))
        XCTAssertEqual(Mesh.fill(hull, faces: .front).surfaceArea, 10, accuracy: 1e-8)
        XCTAssertEqual(hull.bounds, Bounds([-1, -1, 0], [4, 1, 0]))
        let sum = try XCTUnwrap(a.minkowskiSum(with: b))
        XCTAssertEqual(Mesh.fill(sum, faces: .front).surfaceArea, 16, accuracy: 1e-8)
        XCTAssertEqual(sum.bounds, Bounds([1, -2, 0], [5, 2, 0]))
        let triple = try XCTUnwrap(Path.minkowskiSum(of: [a, a, a]))
        XCTAssertEqual(Mesh.fill(triple, faces: .front).surfaceArea, 36, accuracy: 1e-8)
    }

    func testPathMinkowskiSumPreservesConcavityAndHoles() throws {
        let lShape = Path([.point(0, 0), .point(2, 0), .point(2, 1), .point(1, 1), .point(1, 2), .point(0, 2)]).closed()
        let sum = try XCTUnwrap(lShape.minkowskiSum(with: .square()))
        XCTAssertEqual(Mesh.fill(sum, faces: .front).surfaceArea, 8, accuracy: 1e-8)
        let bothConcave = try XCTUnwrap(lShape.minkowskiSum(with: lShape))
        XCTAssertEqual(Mesh.fill(bothConcave, faces: .front).surfaceArea, 13, accuracy: 1e-8)
        let hull = try XCTUnwrap(Path.convexHull(of: [lShape]))
        XCTAssertEqual(Mesh.fill(hull, faces: .front).surfaceArea, 3.5, accuracy: 1e-8)
        let ring = try XCTUnwrap(Path.square(size: 4).subtracting(.square(size: 2)))
        let expanded = try XCTUnwrap(ring.minkowskiSum(with: .square()))
        XCTAssertEqual(expanded.subpaths.count, 2)
        XCTAssertEqual(Mesh.fill(expanded, faces: .front).surfaceArea, 24, accuracy: 1e-8)
        let filledHull = try XCTUnwrap(Path.convexHull(of: [ring]))
        XCTAssertEqual(filledHull.subpaths.count, 1)
        XCTAssertEqual(Mesh.fill(filledHull, faces: .front).surfaceArea, 16, accuracy: 1e-8)
    }

    func testPathHullAndSumOnObliqueTranslatedPlane() throws {
        let rotation = Rotation(roll: .degrees(25), yaw: .degrees(35), pitch: .degrees(45))
        let offset = Vector(3, -2, 5)
        let a = Path.square(size: 2).rotated(by: rotation).translated(by: offset)
        let b = Path.square().rotated(by: rotation).translated(by: offset)
        let sum = try XCTUnwrap(a.minkowskiSum(with: b))
        let expected = Path.square(size: 3).rotated(by: rotation).translated(by: offset * 2)
        XCTAssertEqual(Mesh.fill(sum, faces: .front).surfaceArea, 9, accuracy: 1e-7)
        XCTAssertTrue(sum.points.allSatisfy { expected.plane!.intersects($0.position) })
        XCTAssertTrue(sum.isPlanar)
        XCTAssertTrue(sum.isClosed)
        let reversed = try XCTUnwrap(a.inverted().minkowskiSum(with: b))
        XCTAssertGreaterThan(reversed.faceNormal.dot(-a.faceNormal), 0.999)
        let hull = try XCTUnwrap(a.convexHull(with: b))
        XCTAssertTrue(hull.points.allSatisfy { a.plane!.intersects($0.position) })
    }

    func testPathHullAndSumEmptyInvalidAndCancelledInputs() throws {
        let square = Path.square()
        XCTAssertTrue(try XCTUnwrap(Path.convexHull(of: [])).isEmpty)
        XCTAssertTrue(try XCTUnwrap(Path.minkowskiSum(of: [])).isEmpty)
        for path in try [XCTUnwrap(square.convexHull(with: .empty)), XCTUnwrap(square.minkowskiSum(with: .empty))] {
            XCTAssertEqual(Mesh.fill(path, faces: .front).surfaceArea, 1, accuracy: 1e-8)
        }
        let open = Path([.point(0, 0), .point(1, 0), .point(0, 1)])
        for invalid in [open, square.translated(by: [0, 0, 1])] {
            XCTAssertNil(square.convexHull(with: invalid))
            XCTAssertNil(square.minkowskiSum(with: invalid))
        }
        XCTAssertTrue(try XCTUnwrap(square.convexHull(with: square, isCancelled: { true })).isEmpty)
        let calls = CancellationCounter()
        XCTAssertTrue(try XCTUnwrap(square.minkowskiSum(with: square, isCancelled: {
            calls.increment() > 10
        })).isEmpty)
        XCTAssertGreaterThan(calls.value, 10)
    }

    func testPathHullAndMinkowskiPreserveColoursAndDisconnectedRegions() throws {
        let red = Path.square().withColor(.red)
        let sum = try XCTUnwrap(red.minkowskiSum(with: .square()))
        XCTAssertTrue(sum.points.allSatisfy { $0.color == .red })
        let hull = try XCTUnwrap(Path.convexHull(of: [red, red.translated(by: [2, 0, 0])]))
        XCTAssertTrue(hull.points.allSatisfy { $0.color == .red })
        let disconnected = Path(subpaths: [Path.square(), Path.square().translated(by: [3, 0, 0])])
        let expanded = try XCTUnwrap(disconnected.minkowskiSum(with: .square()))
        XCTAssertEqual(expanded.subpaths.count, 2)
        XCTAssertEqual(Mesh.fill(expanded, faces: .front).surfaceArea, 8, accuracy: 1e-8)
    }

    func testMinkowskiSumPreservesCurvature() throws {
        let circle = Path.circle(segments: 16)
        for other in [Path.empty, .square(), circle] {
            let sum = try XCTUnwrap(circle.minkowskiSum(with: other))
            XCTAssertFalse(sum.isEmpty)
            XCTAssertTrue(sum.points.allSatisfy(\.isCurved))
            let reversed = try XCTUnwrap(other.minkowskiSum(with: circle))
            XCTAssertTrue(reversed.points.allSatisfy(\.isCurved))
        }
        let triple = try XCTUnwrap(Path.minkowskiSum(of: [circle, .square(), circle]))
        XCTAssertTrue(triple.points.allSatisfy(\.isCurved))
        let sharp = try XCTUnwrap(Path.square().minkowskiSum(with: .square()))
        XCTAssertTrue(sharp.points.allSatisfy { !$0.isCurved })
    }

    func testMinkowskiSumKeepsNewConcaveCornersSharp() throws {
        let lShape = Path([.point(0, 0), .point(2, 0), .point(2, 1), .point(1, 1), .point(1, 2), .point(0, 2)]).closed()
        let circle = Path.circle(radius: 0.1, segments: 16)
        for (a, b) in [(lShape, circle), (circle, lShape)] {
            let sum = try XCTUnwrap(a.minkowskiSum(with: b))
            XCTAssertTrue(sum.points.contains(where: \.isCurved))
            let corner = try XCTUnwrap(sum.points.first { $0.position.isApproximatelyEqual(to: [1.1, 1.1, 0]) })
            XCTAssertFalse(corner.isCurved)
        }
    }

    func testMinkowskiCurvatureSurvivesTransforms() throws {
        let rotation = Rotation(roll: .degrees(25), yaw: .degrees(35), pitch: .degrees(45))
        let offset = Vector(3, -2, 5)
        let circle = Path.circle(segments: 16).rotated(by: rotation).translated(by: offset)
        let square = Path.square().rotated(by: rotation).translated(by: offset)
        let sum = try XCTUnwrap(circle.minkowskiSum(with: square))
        XCTAssertTrue(sum.points.allSatisfy(\.isCurved))
    }

    // MARK: Path booleans

    func testOverlappingSquareBooleans() throws {
        let a = Path.square(size: 2)
        let b = a.translated(by: [1, 0, 0])
        let union = try XCTUnwrap(a.union(b))
        let difference = try XCTUnwrap(a.subtracting(b))
        let intersection = try XCTUnwrap(a.intersection(b))
        let xor = try XCTUnwrap(a.symmetricDifference(b))
        for path in [union, difference, intersection, xor] {
            XCTAssertTrue(path.isClosed)
            XCTAssertTrue(path.isPlanar)
        }
        XCTAssertEqual(Mesh.fill(union, faces: .front).surfaceArea, 6, accuracy: 1e-8)
        XCTAssertEqual(Mesh.fill(difference, faces: .front).surfaceArea, 2, accuracy: 1e-8)
        XCTAssertEqual(Mesh.fill(intersection, faces: .front).surfaceArea, 2, accuracy: 1e-8)
        XCTAssertEqual(Mesh.fill(xor, faces: .front).surfaceArea, 4, accuracy: 1e-8)
        XCTAssertEqual(union.subpaths.count, 1)
        XCTAssertEqual(xor.subpaths.count, 2)
    }

    func testPathDifferenceCreatesHole() throws {
        let result = try XCTUnwrap(Path.square(size: 4).subtracting(.square(size: 2)))
        XCTAssertTrue(result.isClosed)
        XCTAssertEqual(result.subpaths.count, 2)
        XCTAssertLessThan(result.subpaths[0].faceNormal.dot(result.subpaths[1].faceNormal), 0)
        XCTAssertEqual(Mesh.fill(result, faces: .front).surfaceArea, 12, accuracy: 1e-8)
        let restored = try XCTUnwrap(result.union(.square(size: 2)))
        XCTAssertEqual(restored.subpaths.count, 1)
        XCTAssertEqual(Mesh.fill(restored, faces: .front).surfaceArea, 16, accuracy: 1e-8)
    }

    func testDisconnectedPathBooleans() throws {
        let a = Path.square()
        let b = a.translated(by: [2, 0, 0])
        let union = try XCTUnwrap(a.union(b))
        XCTAssertEqual(union.subpaths.count, 2)
        XCTAssertEqual(Mesh.fill(union, faces: .front).surfaceArea, 2, accuracy: 1e-8)
        XCTAssertTrue(try XCTUnwrap(a.intersection(b)).isEmpty)
        XCTAssertEqual(try Mesh.fill(XCTUnwrap(a.subtracting(b)), faces: .front).surfaceArea, 1, accuracy: 1e-8)
    }

    func testIdenticalAndOppositeWindingPathBooleans() throws {
        let a = Path.square()
        for b in [a, a.inverted()] {
            XCTAssertEqual(try Mesh.fill(XCTUnwrap(a.union(b)), faces: .front).surfaceArea, 1, accuracy: 1e-8)
            XCTAssertEqual(try Mesh.fill(XCTUnwrap(a.intersection(b)), faces: .front).surfaceArea, 1, accuracy: 1e-8)
            XCTAssertTrue(try XCTUnwrap(a.subtracting(b)).isEmpty)
            XCTAssertTrue(try XCTUnwrap(a.symmetricDifference(b)).isEmpty)
        }
        let reversed = try XCTUnwrap(a.inverted().union(a))
        XCTAssertEqual(reversed.faceNormal, -.unitZ)
    }

    func testEdgeAndVertexTouchingPaths() throws {
        let a = Path.square()
        for offset: Vector in [[1, 0, 0], [1, 1, 0]] {
            let b = a.translated(by: offset)
            let result = try XCTUnwrap(a.union(b))
            XCTAssertTrue(result.isClosed)
            XCTAssertEqual(Mesh.fill(result, faces: .front).surfaceArea, 2, accuracy: 1e-8)
            XCTAssertTrue(try XCTUnwrap(a.intersection(b)).isEmpty)
        }
        XCTAssertEqual(try XCTUnwrap(a.union(a.translated(by: [1, 0, 0]))).subpaths.count, 1)
    }

    func testPathBooleansOnObliqueTranslatedPlane() throws {
        let rotation = Rotation(roll: .degrees(25), yaw: .degrees(35), pitch: .degrees(45))
        let offset = Vector(3, -2, 5)
        let a = Path.square(size: 2).rotated(by: rotation).translated(by: offset)
        let b = Path.square(size: 2).translated(by: [1, 0, 0]).rotated(by: rotation).translated(by: offset)
        let results = try [
            (XCTUnwrap(a.union(b)), 6.0),
            (XCTUnwrap(a.subtracting(b)), 2.0),
            (XCTUnwrap(a.intersection(b)), 2.0),
            (XCTUnwrap(a.symmetricDifference(b)), 4.0),
        ]
        for (result, area) in results {
            XCTAssertTrue(result.isClosed)
            XCTAssertTrue(result.points.allSatisfy { a.plane!.intersects($0.position) })
            XCTAssertEqual(Mesh.fill(result, faces: .front).surfaceArea, area, accuracy: 1e-8)
        }
    }

    func testInvalidPathBooleanInputs() {
        let square = Path.square()
        let open = Path([.point(0, 0), .point(1, 0), .point(0, 1)])
        let nonplanar = Path([.point(0, 0, 0), .point(1, 0, 0), .point(1, 1, 1), .point(0, 1, 0)]).closed()
        for invalid in [open, nonplanar, square.translated(by: [0, 0, 1]), square.rotated(by: .pitch(.halfPi))] {
            XCTAssertNil(square.union(invalid))
            XCTAssertNil(square.subtracting(invalid))
            XCTAssertNil(square.intersection(invalid))
            XCTAssertNil(square.symmetricDifference(invalid))
        }
    }

    func testEmptyPathBooleanInputs() throws {
        let square = Path.square()
        XCTAssertTrue(try XCTUnwrap(Path.union([])).isEmpty)
        XCTAssertTrue(try XCTUnwrap(Path.intersection([])).isEmpty)
        XCTAssertTrue(try XCTUnwrap(Path.difference([])).isEmpty)
        XCTAssertTrue(try XCTUnwrap(Path.symmetricDifference([])).isEmpty)
        XCTAssertEqual(try Mesh.fill(XCTUnwrap(square.union(.empty)), faces: .front).surfaceArea, 1, accuracy: 1e-8)
        XCTAssertEqual(
            try Mesh.fill(XCTUnwrap(square.subtracting(.empty)), faces: .front).surfaceArea,
            1,
            accuracy: 1e-8
        )
        XCTAssertTrue(try XCTUnwrap(Path.empty.subtracting(square)).isEmpty)
        XCTAssertTrue(try XCTUnwrap(square.intersection(.empty)).isEmpty)
    }

    func testCollectionPathBooleans() throws {
        let paths = [
            Path.square(size: 2),
            Path.square(size: 2).translated(by: [1, 0, 0]),
            Path.square(size: 2).translated(by: [2, 0, 0]),
        ]
        XCTAssertEqual(try Mesh.fill(XCTUnwrap(Path.union(paths)), faces: .front).surfaceArea, 8, accuracy: 1e-8)
        XCTAssertEqual(try Mesh.fill(XCTUnwrap(Path.difference(paths)), faces: .front).surfaceArea, 2, accuracy: 1e-8)
        XCTAssertTrue(try XCTUnwrap(Path.intersection(paths)).isEmpty)
        XCTAssertEqual(
            try Mesh.fill(XCTUnwrap(Path.symmetricDifference(paths)), faces: .front).surfaceArea,
            4,
            accuracy: 1e-8
        )
    }

    func testPathBooleanCancellation() throws {
        let a = Path.circle(segments: 64)
        XCTAssertTrue(try XCTUnwrap(a.union(a, isCancelled: { true })).isEmpty)
        let calls = CancellationCounter()
        let result = try XCTUnwrap(a.subtracting(a.translated(by: [0.2, 0, 0]), isCancelled: {
            calls.increment() > 10
        }))
        XCTAssertTrue(result.isEmpty)
        XCTAssertGreaterThan(calls.value, 10)
    }

    func testPathBooleansPreserveCurvatureAndColors() throws {
        let a = Path.circle(segments: 16).withColor(.red)
        let result = try XCTUnwrap(a.union(.empty))
        XCTAssertTrue(result.points.allSatisfy(\.isCurved))
        XCTAssertTrue(result.points.allSatisfy { $0.color == .red })
        let clipped = try XCTUnwrap(a.intersection(.square()))
        XCTAssertTrue(clipped.isClosed)
        XCTAssertTrue(clipped.points.contains { !$0.isCurved })
    }

    func testUncoloredPathBooleansRemainUncolored() throws {
        let result = try XCTUnwrap(Path.square().union(.square().translated(by: [0.5, 0, 0])))
        XCTAssertTrue(result.points.allSatisfy { $0.color == nil })
    }

    func testCompoundPathBooleans() throws {
        let ring = Path(subpaths: [.square(size: 4), Path.square(size: 2).inverted()])
        let strip = Path.square(size: 2).translated(by: [1, 0, 0])
        let intersection = try XCTUnwrap(ring.intersection(strip))
        let difference = try XCTUnwrap(ring.subtracting(strip))
        let union = try XCTUnwrap(ring.union(strip))
        XCTAssertTrue(intersection.isClosed)
        XCTAssertTrue(difference.isClosed)
        XCTAssertTrue(union.isClosed)
        XCTAssertEqual(Mesh.fill(intersection, faces: .front).surfaceArea, 2, accuracy: 1e-8)
        XCTAssertEqual(Mesh.fill(difference, faces: .front).surfaceArea, 10, accuracy: 1e-8)
        XCTAssertEqual(Mesh.fill(union, faces: .front).surfaceArea, 14, accuracy: 1e-8)
    }

    func testConcavePathBooleansAndTessellationBoundaries() throws {
        let a = Path([
            .point(-2, -2), .point(2, -2), .point(2, 0),
            .point(0, 0), .point(0, 2), .point(-2, 2),
        ]).closed()
        let b = Path.square(size: 2)
        let intersection = try XCTUnwrap(a.intersection(b))
        let difference = try XCTUnwrap(a.subtracting(b))
        let union = try XCTUnwrap(a.union(b))
        XCTAssertTrue(intersection.isClosed)
        XCTAssertTrue(difference.isClosed)
        XCTAssertTrue(union.isClosed)
        XCTAssertEqual(intersection.subpaths.count, 1)
        XCTAssertEqual(difference.subpaths.count, 1)
        XCTAssertEqual(union.subpaths.count, 1)
        XCTAssertEqual(Mesh.fill(intersection, faces: .front).surfaceArea, 3, accuracy: 1e-8)
        XCTAssertEqual(Mesh.fill(difference, faces: .front).surfaceArea, 9, accuracy: 1e-8)
        XCTAssertEqual(Mesh.fill(union, faces: .front).surfaceArea, 13, accuracy: 1e-8)
    }

    func testCurvedPathBooleanAreaIdentities() throws {
        let a = Path.circle(radius: 2, segments: 32)
        let b = Path.circle(radius: 1.5, segments: 24).translated(by: [1, 0.3, 0])
        let areaA = Mesh.fill(a, faces: .front).surfaceArea
        let areaB = Mesh.fill(b, faces: .front).surfaceArea
        let union = try XCTUnwrap(a.union(b))
        let intersection = try XCTUnwrap(a.intersection(b))
        let difference = try XCTUnwrap(a.subtracting(b))
        let xor = try XCTUnwrap(a.symmetricDifference(b))
        for path in [union, intersection, difference, xor] {
            XCTAssertTrue(path.isClosed)
        }
        let sharedArea = Mesh.fill(intersection, faces: .front).surfaceArea
        XCTAssertEqual(Mesh.fill(union, faces: .front).surfaceArea, areaA + areaB - sharedArea, accuracy: 1e-8)
        XCTAssertEqual(Mesh.fill(difference, faces: .front).surfaceArea, areaA - sharedArea, accuracy: 1e-8)
        XCTAssertEqual(Mesh.fill(xor, faces: .front).surfaceArea, areaA + areaB - 2 * sharedArea, accuracy: 1e-8)
    }

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

    // MARK: Mesh clipping

    func testPathClippedToMeshReturnsRejectedFragments() {
        let path = Path.line([-1, 0, 0], [1, 0, 0])
        let bsp = BSP(Mesh.cube()) { false }
        var rejected: [Path]? = []
        let kept = bsp.clip(path, .greaterThan, &rejected) { false }
        XCTAssertEqual(Set(kept), Set([
            .line([-1, 0, 0], [-0.5, 0, 0]),
            .line([0.5, 0, 0], [1, 0, 0]),
        ]))
        XCTAssertEqual(Path(subpaths: rejected ?? []), .line([-0.5, 0, 0], [0.5, 0, 0]))
    }
}

private final class CancellationCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return count
    }

    func increment() -> Int {
        lock.lock()
        defer { lock.unlock() }
        count += 1
        return count
    }
}
