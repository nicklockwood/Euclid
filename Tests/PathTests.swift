//
//  PathTests.swift
//  GeometryScriptTests
//
//  Created by Nick Lockwood on 19/09/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

final class PathTests: XCTestCase {
    func testWithLength() {
        let path = Path([.point(1, 1), .point(4, 1), .point(4, 5)])
        for length in [3.5, 7, 14] {
            let scaled = path.withLength(length)
            XCTAssertEqual(scaled.length, length)
            XCTAssertEqual(scaled.points.map(\.position), path.points.map { $0.position * (length / 7) })
        }
    }

    func testWithLengthExcludesSubpathGaps() {
        let path = Path(subpaths: [
            Path([.point(0, 0), .point(1, 0)]),
            Path([.point(10, 0), .point(10, 3)]),
        ])
        let scaled = path.withLength(8)
        XCTAssertEqual(scaled.length, 8)
        XCTAssertEqual(scaled.subpaths.count, 2)
        XCTAssertEqual(scaled.subpaths[0].length, 2)
        XCTAssertEqual(scaled.subpaths[1].length, 6)
    }

    func testWithLengthForZeroLengthPaths() {
        XCTAssertEqual(Path.empty.withLength(10), .empty)
        let path = Path([.point(3, 4)])
        XCTAssertEqual(path.withLength(10), path)
    }

    // MARK: isSimple

    func testSinglePoint() {
        let path = Path([
            .point(0, 0),
        ])
        XCTAssertTrue(path.isSimple)
        XCTAssertTrue(path.isClosed)
        XCTAssertEqual(path.points.count, 1)
    }

    func testEmptyPathWithPlaneHasNoPlane() {
        let path = Path([], plane: .xy)
        XCTAssertEqual(path, .empty)
        XCTAssertTrue(path.isEmpty)
        XCTAssertNil(path.plane)
    }

    func testCoincidentPoints() {
        let path = Path([
            .point(0, 0),
            .point(0, 0),
        ])
        XCTAssertTrue(path.isSimple)
        XCTAssertTrue(path.isClosed)
        XCTAssertEqual(path.points.count, 1)
    }

    func testSimpleLine() {
        let path = Path([
            .point(0, 1),
            .point(0, -1),
        ])
        XCTAssertTrue(path.isSimple)
        XCTAssertFalse(path.isClosed)
        XCTAssertEqual(path.points.count, 2)
    }

    func testPathPointsHaveOrientations() {
        let path = Path([
            .point(0, 0),
            .point(1, 0),
            .point(1, 1),
        ])
        XCTAssertEqual(path.points[0].orientation?.forward, .unitX)
        XCTAssertEqual(path.points[0].orientation?.up, -.unitY)
        XCTAssertEqual(path.points[1].orientation?.forward, Vector(1, 1).normalized())
        XCTAssertEqual(path.points[1].orientation?.up, Vector(1, -1).normalized())
        XCTAssertEqual(path.points[2].orientation?.forward, .unitY)
        XCTAssertEqual(path.points[2].orientation?.up, .unitX)
    }

    func testClosedPathPointOrientationUsesClosingSegment() {
        let path = Path([
            .point(0, 0),
            .point(1, 0),
            .point(1, 1),
            .point(0, 1),
            .point(0, 0),
        ])
        XCTAssertEqual(path.points[0].orientation?.forward, Vector(1, -1).normalized())
        XCTAssertEqual(path.points[0].orientation?.up, Vector(-1, -1).normalized())
        XCTAssertEqual(path.points.last?.orientation?.forward, path.points[0].orientation?.forward)
        XCTAssertEqual(path.points.last?.orientation?.up, path.points[0].orientation?.up)
    }

    func testStandalonePathPointHasNoOrientation() {
        let point = PathPoint.point(0, 0)
        XCTAssertNil(point.orientation)
    }

    func testPathPointOrientation() {
        let path = Path([
            .point(0, 0, 0),
            .point(1, 2, 3),
            .point(3, 4, 2),
        ])
        let tangent = Vector(1, 2, 3).normalized()
        let orientation = path.points[0].orientation
        XCTAssertEqual(orientation?.forward, tangent)
        XCTAssertEqual(orientation?.up, tangent.cross(path.faceNormal).normalized())
        let interpolated = path.interpolatedPoint(at: 0.5)?.orientation
        XCTAssertEqual(interpolated, orientation)
    }

    func testInterpolatedPointByNormalizedDistance() {
        let path = Path([.point(0, 0), .point(1, 0), .point(10, 0)])
        XCTAssertEqual(path.interpolatedPoint(by: 0.5)?.position, [5, 0])
        XCTAssertEqual(path.interpolatedPoint(by: 0.5)?.orientation?.forward, .unitX)
        XCTAssertEqual(path.interpolatedPoint(by: -0.5)?.position, [0, 0])
        XCTAssertEqual(path.interpolatedPoint(by: 1.5)?.position, [10, 0])
    }

    func testInterpolatedPointByNormalizedDistanceWraps() {
        let path = Path([.point(0, 0), .point(1, 0), .point(1, 1), .point(0, 1), .point(0, 0)])
        XCTAssertEqual(path.interpolatedPoint(by: 1)?.position, [0, 0])
        XCTAssertEqual(path.interpolatedPoint(by: 1.125)?.position, [0.5, 0])
        XCTAssertEqual(path.interpolatedPoint(by: -0.125)?.position, [0, 0.5])
    }

    func testInterpolatedPointByNormalizedDistanceExcludesGaps() {
        let path = Path(subpaths: [
            Path([.point(0, 0), .point(1, 0)]),
            Path([.point(10, 0), .point(10, 3)]),
        ])
        XCTAssertEqual(path.interpolatedPoint(by: 0.25)?.position, [1, 0])
        XCTAssertEqual(path.interpolatedPoint(by: 0.5)?.position, [10, 1])
    }

    func testInterpolatedPointByNormalizedDistanceForEmptyAndSinglePointPaths() {
        XCTAssertNil(Path.empty.interpolatedPoint(by: 0.5))
        let path = Path([.point(3, 4)])
        XCTAssertEqual(path.interpolatedPoint(by: 0.5)?.position, [3, 4])
    }

    func testInterpolatedPointAtDistanceUsesSegmentOrientation() {
        let path = Path([
            .point(0, 0),
            .point(1, 0),
            .point(1, 1),
        ])
        let point = path.interpolatedPoint(at: 1.5)
        XCTAssertEqual(point?.position, [1, 0.5])
        XCTAssertEqual(point?.orientation?.forward, .unitY)
        XCTAssertEqual(point?.orientation?.up, .unitX)
    }

    func testInterpolatedPointAtVerticesRetainsOrientation() {
        let path = Path.square()
        for index in 0 ..< 4 {
            let distance = Double(index)
            for offset in [-4.0, 0, 4] {
                XCTAssertEqual(path.interpolatedPoint(at: distance + offset), path.points[index])
                XCTAssertEqual(
                    path.interpolatedPoint(at: distance + offset)?.orientation,
                    path.points[index].orientation
                )
            }
            XCTAssertEqual(path.interpolatedPoint(by: distance / 4), path.points[index])
            XCTAssertEqual(path.interpolatedPoint(by: distance / 4)?.orientation, path.points[index].orientation)
        }
    }

    func testInterpolatedPointNearVerticesRetainsOrientation() {
        let path = Path.square()
        for index in 0 ..< 4 {
            for offset in [-epsilon / 2, epsilon / 2] {
                XCTAssertEqual(path.interpolatedPoint(at: Double(index) + offset), path.points[index])
                XCTAssertEqual(
                    path.interpolatedPoint(at: Double(index) + offset)?.orientation,
                    path.points[index].orientation
                )
            }
        }
    }

    func testInterpolatedPointAtOpenPathCornerRetainsOrientation() {
        let path = Path([.point(0, 0), .point(1, 0), .point(1, 1)])
        for distance in [Double(1).nextDown, 1.0, Double(1).nextUp] {
            XCTAssertEqual(path.interpolatedPoint(at: distance), path.points[1])
            XCTAssertEqual(path.interpolatedPoint(at: distance)?.orientation, path.points[1].orientation)
        }
        XCTAssertEqual(path.interpolatedPoint(at: 0.5)?.orientation?.forward, .unitX)
        XCTAssertEqual(path.interpolatedPoint(at: 1.5)?.orientation?.forward, .unitY)
    }

    func testInterpolatedPointAtShortEdgeMidpointUsesSegmentOrientation() {
        let path = Path([.point(0, 0), .point(epsilon, 0)])
        let first = path.points[0].position
        let second = path.points[1].position
        let distance = (second - first).length / 2
        let sample = path.interpolatedPoint(at: distance)
        XCTAssertEqual(sample?.position, (first + second) / 2)
        XCTAssertEqual(sample?.orientation?.forward, (second - first).normalized())
    }

    func testInterpolatedPointAtDistanceClampsForOpenPath() {
        let path = Path([
            .point(0, 0),
            .point(1, 0),
            .point(1, 1),
        ])
        XCTAssertEqual(path.interpolatedPoint(at: -1)?.position, [0, 0])
        XCTAssertEqual(path.interpolatedPoint(at: 3)?.position, [1, 1])
        XCTAssertEqual(path.interpolatedPoint(at: -1)?.orientation?.forward, .unitX)
        XCTAssertEqual(path.interpolatedPoint(at: 3)?.orientation?.forward, .unitY)
    }

    func testInterpolatedPointAtDistanceWrapsForClosedPath() {
        let path = Path([
            .point(0, 0),
            .point(1, 0),
            .point(1, 1),
            .point(0, 1),
            .point(0, 0),
        ])
        let positivePoint = path.interpolatedPoint(at: 4.5)
        XCTAssertEqual(positivePoint?.position, [0.5, 0])
        XCTAssertEqual(positivePoint?.orientation?.forward, .unitX)
        XCTAssertEqual(positivePoint?.orientation?.up, -.unitY)

        let negativePoint = path.interpolatedPoint(at: -0.5)
        XCTAssertEqual(negativePoint?.position, [0, 0.5])
        XCTAssertEqual(negativePoint?.orientation?.forward, -.unitY)
        XCTAssertEqual(negativePoint?.orientation?.up, -.unitX)
    }

    func testSubpathLengthExcludesGaps() {
        let path = Path(subpaths: [
            Path([.point(0, 0), .point(1, 0)]),
            Path([.point(10, 0), .point(10, 2)]),
        ])
        XCTAssertEqual(path.length, 3)
        XCTAssertEqual(path.interpolatedPoint(at: 1)?.position, [1, 0])
        XCTAssertEqual(path.interpolatedPoint(at: 1.5)?.position, [10, 0.5])
        XCTAssertEqual(path.interpolatedPoint(at: 1.5)?.orientation?.forward, .unitY)
        XCTAssertEqual(path.interpolatedPoint(at: -1)?.position, [0, 0])
        XCTAssertEqual(path.interpolatedPoint(at: 4)?.position, [10, 2])
    }

    func testInterpolatedSubpathPointUsesSubpathNormal() {
        let first = Path([.point(0, 0), .point(1, 0), .point(1, 1)])
        let second = Path([.point(10, 0, 0), .point(10, 1, 0), .point(10, 1, 1)])
        let path = Path(subpaths: [first, second])
        let point = path.interpolatedPoint(at: first.length + 0.5)
        XCTAssertEqual(point?.position, [10, 0.5, 0])
        XCTAssertEqual(point?.orientation, second.interpolatedPoint(at: 0.5)?.orientation)
    }

    func testInterpolatedClosedSubpathsWrapAroundTotalLength() {
        let first = Path([.point(0, 0), .point(1, 0), .point(1, 1), .point(0, 1), .point(0, 0)])
        let second = first.translated(by: [10, 0])
        let path = Path(subpaths: [first, second])
        XCTAssertEqual(path.length, 8)
        XCTAssertEqual(path.interpolatedPoint(at: 4)?.position, [0, 0])
        XCTAssertEqual(path.interpolatedPoint(at: 4)?.orientation, first.points[0].orientation)
        XCTAssertEqual(path.interpolatedPoint(at: 4.5)?.position, [10.5, 0])
        XCTAssertEqual(path.interpolatedPoint(at: 8.5)?.position, [0.5, 0])
        XCTAssertEqual(path.interpolatedPoint(at: -0.5)?.position, [10, 0.5])
    }

    func testInterpolatedMixedSubpathsClampToEnds() {
        let path = Path(subpaths: [
            Path([.point(0, 0), .point(1, 0)]),
            Path([.point(10, 0), .point(11, 0), .point(11, 1), .point(10, 1), .point(10, 0)]),
        ])
        XCTAssertEqual(path.length, 5)
        XCTAssertEqual(path.interpolatedPoint(at: -0.5)?.position, [0, 0])
        XCTAssertEqual(path.interpolatedPoint(at: 1.5)?.position, [10.5, 0])
        XCTAssertEqual(path.interpolatedPoint(at: 5.5)?.position, [10, 0])
    }

    func testInterpolatedSubpathsSkipIsolatedPoints() {
        let path = Path(subpaths: [
            Path([.point(5, 0)]),
            Path([.point(10, 0), .point(11, 0)]),
            Path([.point(20, 0)]),
        ])
        XCTAssertEqual(path.length, 1)
        XCTAssertEqual(path.interpolatedPoint(at: 0.5)?.position, [10.5, 0])
        XCTAssertEqual(path.interpolatedPoint(at: 0)?.position, [5, 0])
        XCTAssertEqual(path.interpolatedPoint(at: 1)?.position, [20, 0])
    }

    func testLineShorterThanEpsilon() {
        let path = Path([
            .point(0, 1),
            .point(0, 1 + epsilon / 2),
        ])
        XCTAssertTrue(path.isSimple)
        XCTAssertFalse(path.isClosed)
        XCTAssertEqual(path.points.count, 2)
    }

    func testSimpleOpenTriangle() {
        let path = Path([
            .point(0, 1),
            .point(0, -1),
            .point(1, -1),
        ])
        XCTAssertTrue(path.isSimple)
        XCTAssertFalse(path.isClosed)
    }

    func testSimpleClosedTriangle() {
        let path = Path([
            .point(0, 1),
            .point(-1, -1),
            .point(1, -1),
            .point(0, 1),
        ])
        XCTAssertTrue(path.isSimple)
        XCTAssertTrue(path.isClosed)
    }

    func testSimpleOpenQuad() {
        let path = Path([
            .point(-1, 1),
            .point(-1, -1),
            .point(1, -1),
            .point(1, 1),
        ])
        XCTAssertTrue(path.isSimple)
        XCTAssertFalse(path.isClosed)
    }

    func testOverlappingOpenQuad() {
        let path = Path([
            .point(-1, 1),
            .point(1, -1),
            .point(-1, -1),
            .point(1, 1),
        ])
        XCTAssertFalse(path.isSimple)
        XCTAssertFalse(path.isClosed)
    }

    func testSimpleClosedQuad() {
        let path = Path([
            .point(-1, 1),
            .point(-1, -1),
            .point(1, -1),
            .point(1, 1),
            .point(-1, 1),
        ])
        XCTAssertTrue(path.isSimple)
        XCTAssertTrue(path.isClosed)
    }

    func testOverlappingClosedQuad() {
        let path = Path([
            .point(-1, 1),
            .point(1, -1),
            .point(-1, -1),
            .point(1, 1),
            .point(-1, 1),
        ])
        XCTAssertFalse(path.isSimple)
        XCTAssertTrue(path.isClosed)
    }

    func testClosedPathWithOffshoot() {
        let path = Path([
            .point(0, 0),
            .point(1, 0),
            .point(1, 1),
            .point(0, 1),
            .point(0, 0),
            .point(-1, 0),
        ])
        XCTAssertTrue(path.isSimple)
        XCTAssertFalse(path.isClosed)
    }

    func testLargeClosedPathIsSimple() {
        let path = Path.circle(segments: 300)

        XCTAssertTrue(path.isSimple)
    }

    func testLargeClosedPathWithCrossingSegmentsIsNotSimple() {
        let points = (0 ... 300).map { PathPoint.point(Double($0), 0) } + [
            .point(150.5, -1),
            .point(150.5, 1),
            .point(0, 0),
        ]
        let path = Path(points)

        XCTAssertFalse(path.isSimple)
    }

    // MARK: winding direction

    func testConvexClosedPathAnticlockwiseWinding() {
        let path = Path([
            .point(-1, 1),
            .point(-1, -1),
            .point(1, -1),
            .point(1, 1),
            .point(-1, 1),
        ])
        XCTAssertTrue(path.isClosed)
        XCTAssertEqual(path.plane?.normal, .unitZ)
    }

    func testConvexClosedPathClockwiseWinding() {
        let path = Path([
            .point(-1, -1),
            .point(-1, 1),
            .point(1, 1),
            .point(1, -1),
            .point(-1, -1),
        ])
        XCTAssertTrue(path.isClosed)
        XCTAssertEqual(path.plane?.normal, -.unitZ)
    }

    func testConvexOpenPathAnticlockwiseWinding() {
        let path = Path([
            .point(-1, 1),
            .point(-1, -1),
            .point(1, -1),
        ])
        XCTAssertFalse(path.isClosed)
        XCTAssertEqual(path.plane?.normal, .unitZ)
    }

    func testConvexOpenPathClockwiseWinding() {
        let path = Path([
            .point(-1, -1),
            .point(-1, 1),
            .point(1, 1),
        ])
        XCTAssertFalse(path.isClosed)
        XCTAssertEqual(path.plane?.normal, -.unitZ)
    }

    func testConcaveClosedPathAnticlockwiseWinding() {
        let path = Path([
            .point(-1, 0),
            .point(0, 0),
            .point(0, -1),
            .point(1, -1),
            .point(1, 1),
            .point(-1, 1),
            .point(-1, 0),
        ])
        XCTAssertTrue(path.isClosed)
        XCTAssertEqual(path.plane?.normal, .unitZ)
    }

    func testConcaveClosedPathClockwiseWinding() {
        let path = Path([
            .point(-1, 0),
            .point(0, 0),
            .point(0, 1),
            .point(1, 1),
            .point(1, -1),
            .point(-1, -1),
            .point(-1, 0),
        ])
        XCTAssertTrue(path.isClosed)
        XCTAssertEqual(path.plane?.normal, -.unitZ)
    }

    func testConcaveClosedPathClockwiseWinding2() {
        var transform = Transform.identity
        var points = [PathPoint]()
        let sides = 5
        for _ in 0 ..< sides {
            points.append(.point(0, -0.5).transformed(by: transform))
            transform.rotate(by: .roll(.pi / Double(sides)))
            points.append(.point(0, -1).transformed(by: transform))
            transform.rotate(by: .roll(.pi / Double(sides)))
        }
        points.append(.point(0, -0.5))
        let path = Path(points)
        XCTAssertEqual(path.plane?.normal, -.unitZ)
    }

    func testConcaveOpenPathAnticlockwiseWinding() {
        let path = Path([
            .point(-1, 0),
            .point(0, 0),
            .point(0, -1),
            .point(1, -1),
            .point(-1, 1),
        ])
        XCTAssertFalse(path.isClosed)
        XCTAssertEqual(path.plane?.normal, .unitZ)
    }

    func testConcaveOpenPathClockwiseWinding() {
        let path = Path([
            .point(-1, 0),
            .point(0, 0),
            .point(0, 1),
            .point(1, 1),
            .point(-1, -1),
        ])
        XCTAssertFalse(path.isClosed)
        XCTAssertEqual(path.plane?.normal, -.unitZ)
    }

    func testStraightLinePath() {
        let path = Path([
            .point(-1, 1),
            .point(-1, -1),
        ])
        XCTAssertFalse(path.isClosed)
        XCTAssertEqual(path.plane?.normal, .unitZ)
    }

    func testStraightLinePath2() {
        let path = Path([
            .point(-1, -1),
            .point(-1, 1),
        ])
        XCTAssertFalse(path.isClosed)
        XCTAssertEqual(path.plane?.normal, .unitZ)
    }

    func testStraightLinePath3() {
        let path = Path([
            .point(1, 1),
            .point(1, -1),
        ])
        XCTAssertFalse(path.isClosed)
        XCTAssertEqual(path.plane?.normal, .unitZ)
    }

    func testStraightLinePath4() {
        let path = Path([
            .point(-1, 1),
            .point(-1, -1),
            .point(-1, 1),
        ])
        XCTAssertTrue(path.isClosed)
        XCTAssertEqual(path.plane?.normal, .unitZ)
    }

    func testStraightLinePath5() {
        let path = Path([
            .point(-1, 1),
            .point(-1, -1),
            .point(-1, -2),
        ])
        XCTAssertFalse(path.isClosed)
        XCTAssertEqual(path.plane?.normal, .unitZ)
    }

    func testStraightLinePath6() {
        let path = Path([
            .point(-1, 1),
            .point(-1, -1),
            .point(-1, -2),
            .point(-1, 1),
        ])
        XCTAssertTrue(path.isClosed)
        XCTAssertEqual(path.plane?.normal, .unitZ)
    }

    func testStraightLinePath7() {
        let path = Path([
            .point(-1, 1),
            .point(-1, -1),
            .point(-1, -2),
            .point(-1, -3),
        ])
        XCTAssertFalse(path.isClosed)
        XCTAssertEqual(path.plane?.normal, .unitZ)
    }

    // MARK: faceVertices

    func testFaceVerticesForConcaveClockwisePath() {
        let path = Path([
            .point(0, 1),
            .point(1, 0),
            .point(0, -1),
            .point(0.5, 0),
            .point(0, 1),
        ])
        guard let vertices = path.faceVertices else {
            XCTFail()
            return
        }
        XCTAssertEqual(vertices.count, 4)
    }

    func testFaceVerticesForDegenerateClosedAnticlockwisePath() {
        let path = Path([
            .point(0, 1),
            .point(0, 0),
            .point(0, -1),
            .point(0, 1),
        ])
        XCTAssert(path.isClosed)
        XCTAssertNil(path.faceVertices)
    }

    func testFaceVerticesForNonPlanarPath() throws {
        let path = Path([
            .point(0, 1),
            .point(1, 0, 0.2),
            .point(0, -1),
            .point(-1, 0, 0.1),
            .point(0, 1),
        ])
        let vertices = try XCTUnwrap(path.faceVertices)
        XCTAssertEqual(vertices.count, 4)
        XCTAssert(vertices.allSatisfy { $0.normal.z < 0 })
    }

    // MARK: edgeVertices

    func testEdgeVerticesForSmoothedClosedRect() {
        let path = Path([
            .curve(-1, 1),
            .curve(-1, -1),
            .curve(1, -1),
            .curve(1, 1),
            .curve(-1, 1),
        ])
        let vertices = path.edgeVertices
        XCTAssertEqual(vertices.count, 8)
        guard vertices.count >= 8 else { return }
        // positions
        XCTAssertEqual(vertices[0].position, [-1, 1])
        XCTAssertEqual(vertices[1].position, [-1, -1])
        XCTAssertEqual(vertices[2].position, [-1, -1])
        XCTAssertEqual(vertices[3].position, [1, -1])
        XCTAssertEqual(vertices[4].position, [1, -1])
        XCTAssertEqual(vertices[5].position, [1, 1])
        XCTAssertEqual(vertices[6].position, [1, 1])
        XCTAssertEqual(vertices[7].position, [-1, 1])
        // texture coords
        XCTAssertEqual(vertices[0].texcoord, [0, 0])
        XCTAssertEqual(vertices[1].texcoord, [0, 0.25])
        XCTAssertEqual(vertices[2].texcoord, [0, 0.25])
        XCTAssertEqual(vertices[3].texcoord, [0, 0.5])
        XCTAssertEqual(vertices[4].texcoord, [0, 0.5])
        XCTAssertEqual(vertices[5].texcoord, [0, 0.75])
        XCTAssertEqual(vertices[6].texcoord, [0, 0.75])
        XCTAssertEqual(vertices[7].texcoord, [0, 1])
        // normals
        XCTAssertEqual(vertices[0].normal, Vector(-1, 1).normalized())
        XCTAssertEqual(vertices[1].normal, Vector(-1, -1).normalized())
        XCTAssertEqual(vertices[2].normal, Vector(-1, -1).normalized())
        XCTAssertEqual(vertices[3].normal, Vector(1, -1).normalized())
        XCTAssertEqual(vertices[4].normal, Vector(1, -1).normalized())
        XCTAssertEqual(vertices[5].normal, Vector(1, 1).normalized())
        XCTAssertEqual(vertices[6].normal, Vector(1, 1).normalized())
        XCTAssertEqual(vertices[7].normal, Vector(-1, 1).normalized())
    }

    func testEdgeVerticesForSmoothedCylinder() {
        let path = Path([
            .point(0, 1),
            .curve(-1, 1),
            .curve(-1, -1),
            .point(0, -1),
        ])
        let vertices = path.edgeVertices
        XCTAssertEqual(vertices.count, 6)
        guard vertices.count >= 6 else { return }
        // positions
        XCTAssertEqual(vertices[0].position, [0, 1])
        XCTAssertEqual(vertices[1].position, [-1, 1])
        XCTAssertEqual(vertices[2].position, [-1, 1])
        XCTAssertEqual(vertices[3].position, [-1, -1])
        XCTAssertEqual(vertices[4].position, [-1, -1])
        XCTAssertEqual(vertices[5].position, [0, -1])
        // texture coords
        XCTAssertEqual(vertices[0].texcoord, [0, 0])
        XCTAssertEqual(vertices[1].texcoord, [0, 0.25])
        XCTAssertEqual(vertices[2].texcoord, [0, 0.25])
        XCTAssertEqual(vertices[3].texcoord, [0, 0.75])
        XCTAssertEqual(vertices[4].texcoord, [0, 0.75])
        XCTAssertEqual(vertices[5].texcoord, [0, 1])
        // normals
        XCTAssertEqual(vertices[0].normal, [0, 1])
        XCTAssertEqual(vertices[1].normal, Vector(-1, 1).normalized())
        XCTAssertEqual(vertices[2].normal, Vector(-1, 1).normalized())
        XCTAssertEqual(vertices[3].normal, Vector(-1, -1).normalized())
        XCTAssertEqual(vertices[4].normal, Vector(-1, -1).normalized())
        XCTAssertEqual(vertices[5].normal, [0, -1])
    }

    func testEdgeVerticesForSharpEdgedCylinder() {
        let path = Path([
            .point(0, 1),
            .point(-1, 1),
            .point(-1, -1),
            .point(0, -1),
        ])
        let vertices = path.edgeVertices
        XCTAssertEqual(vertices.count, 6)
        guard vertices.count >= 6 else { return }
        // positions
        XCTAssertEqual(vertices[0].position, [0, 1])
        XCTAssertEqual(vertices[1].position, [-1, 1])
        XCTAssertEqual(vertices[2].position, [-1, 1])
        XCTAssertEqual(vertices[3].position, [-1, -1])
        XCTAssertEqual(vertices[4].position, [-1, -1])
        XCTAssertEqual(vertices[5].position, [0, -1])
        // texture coords
        XCTAssertEqual(vertices[0].texcoord, [0, 0])
        XCTAssertEqual(vertices[1].texcoord, [0, 0.25])
        XCTAssertEqual(vertices[2].texcoord, [0, 0.25])
        XCTAssertEqual(vertices[3].texcoord, [0, 0.75])
        XCTAssertEqual(vertices[4].texcoord, [0, 0.75])
        XCTAssertEqual(vertices[5].texcoord, [0, 1])
        // normals
        XCTAssertEqual(vertices[0].normal, [0, 1])
        XCTAssertEqual(vertices[1].normal, [0, 1])
        XCTAssertEqual(vertices[2].normal, [-1, 0])
        XCTAssertEqual(vertices[3].normal, [-1, 0])
        XCTAssertEqual(vertices[4].normal, [0, -1])
        XCTAssertEqual(vertices[5].normal, [0, -1])
    }

    func testTubeEdgeVerticesAreDistributedByHeight() {
        let path = Path([
            .point(0, 1),
            .point(-2, 1),
            .point(-1, 0),
            .point(-3, -1),
            .point(0, -1),
        ])
        let vertices = path.edgeVertices(for: .tube)
        XCTAssertEqual(vertices.count, 8)
        guard vertices.count >= 8 else { return }
        // texture coords
        XCTAssertEqual(vertices[0].texcoord, [0, 0])
        XCTAssertEqual(vertices[1].texcoord, [0, 0])
        XCTAssertEqual(vertices[2].texcoord, [0, 0])
        XCTAssertEqual(vertices[3].texcoord, [0, 0.5])
        XCTAssertEqual(vertices[4].texcoord, [0, 0.5])
        XCTAssertEqual(vertices[5].texcoord, [0, 1])
        XCTAssertEqual(vertices[6].texcoord, [0, 1])
        XCTAssertEqual(vertices[7].texcoord, [0, 1])
    }

    func testTubeEdgeVerticesWithNoHeightHaveZeroTexcoords() {
        let path = Path([
            .point(-1, 1),
            .point(1, 1),
        ])
        let vertices = path.edgeVertices(for: .tube)
        XCTAssertEqual(vertices.count, 2)
        XCTAssertEqual(vertices.map(\.texcoord), [.zero, .zero])
    }

    func testEdgeVerticesForCircle() {
        let path = Path.circle(radius: 1, segments: 4)
        let vertices = path.edgeVertices
        XCTAssertEqual(vertices.count, 8)
        guard vertices.count >= 8 else { return }
        // positions
        XCTAssertEqual(vertices[0].position, [0, 1])
        XCTAssertEqual(vertices[1].position, [-1, 0])
        XCTAssertEqual(vertices[2].position, [-1, 0])
        XCTAssertEqual(vertices[3].position, [0, -1])
        XCTAssertEqual(vertices[4].position, [0, -1])
        XCTAssertEqual(vertices[5].position, [1, 0])
        XCTAssertEqual(vertices[6].position, [1, 0])
        XCTAssertEqual(vertices[7].position, [0, 1])
        // texture coords
        XCTAssertEqual(vertices[0].texcoord, [0, 0])
        XCTAssertEqual(vertices[1].texcoord, [0, 0.25])
        XCTAssertEqual(vertices[2].texcoord, [0, 0.25])
        XCTAssertEqual(vertices[3].texcoord, [0, 0.5])
        XCTAssertEqual(vertices[4].texcoord, [0, 0.5])
        XCTAssertEqual(vertices[5].texcoord, [0, 0.75])
        XCTAssertEqual(vertices[6].texcoord, [0, 0.75])
        XCTAssertEqual(vertices[7].texcoord, [0, 1])
        // normals
        XCTAssertEqual(vertices[0].normal, [0, 1])
        XCTAssertEqual(vertices[1].normal, [-1, 0])
        XCTAssertEqual(vertices[2].normal, [-1, 0])
        XCTAssertEqual(vertices[3].normal, [0, -1])
        XCTAssertEqual(vertices[4].normal, [0, -1])
        XCTAssertEqual(vertices[5].normal, [1, 0])
        XCTAssertEqual(vertices[6].normal, [1, 0])
        XCTAssertEqual(vertices[7].normal, [0, 1])
    }

    func testEdgeVerticesForEllipse() {
        let path = Path.ellipse(width: 4, height: 2, segments: 4)
        let vertices = path.edgeVertices
        XCTAssertEqual(vertices.count, 8)
        guard vertices.count >= 8 else { return }
        // positions
        XCTAssertEqual(vertices[0].position, [0, 1])
        XCTAssertEqual(vertices[1].position, [-2, 0])
        XCTAssertEqual(vertices[2].position, [-2, 0])
        XCTAssertEqual(vertices[3].position, [0, -1])
        XCTAssertEqual(vertices[4].position, [0, -1])
        XCTAssertEqual(vertices[5].position, [2, 0])
        XCTAssertEqual(vertices[6].position, [2, 0])
        XCTAssertEqual(vertices[7].position, [0, 1])
        // texture coords
        XCTAssertEqual(vertices[0].texcoord, [0, 0])
        XCTAssertEqual(vertices[1].texcoord, [0, 0.25])
        XCTAssertEqual(vertices[2].texcoord, [0, 0.25])
        XCTAssertEqual(vertices[3].texcoord, [0, 0.5])
        XCTAssertEqual(vertices[4].texcoord, [0, 0.5])
        XCTAssertEqual(vertices[5].texcoord, [0, 0.75])
        XCTAssertEqual(vertices[6].texcoord, [0, 0.75])
        XCTAssertEqual(vertices[7].texcoord, [0, 1])
        // normals
        XCTAssertEqual(vertices[0].normal, [0, 1])
        XCTAssertEqual(vertices[1].normal, [-1, 0])
        XCTAssertEqual(vertices[2].normal, [-1, 0])
        XCTAssertEqual(vertices[3].normal, [0, -1])
        XCTAssertEqual(vertices[4].normal, [0, -1])
        XCTAssertEqual(vertices[5].normal, [1, 0])
        XCTAssertEqual(vertices[6].normal, [1, 0])
        XCTAssertEqual(vertices[7].normal, [0, 1])
    }

    func testEdgeVerticesForSemicircle() {
        let path = Path([
            .curve(0, 1),
            .curve(-1, 0),
            .curve(0, -1),
        ])
        let vertices = path.edgeVertices
        XCTAssertEqual(vertices.count, 4)
        guard vertices.count >= 4 else { return }
        // positions
        XCTAssertEqual(vertices[0].position, [0, 1])
        XCTAssertEqual(vertices[1].position, [-1, 0])
        XCTAssertEqual(vertices[2].position, [-1, 0])
        XCTAssertEqual(vertices[3].position, [0, -1])
        // texture coords
        XCTAssertEqual(vertices[0].texcoord, [0, 0])
        XCTAssertEqual(vertices[1].texcoord, [0, 0.5])
        XCTAssertEqual(vertices[2].texcoord, [0, 0.5])
        XCTAssertEqual(vertices[3].texcoord, [0, 1])
        // normals
        XCTAssertEqual(vertices[0].normal, [0, 1])
        XCTAssertEqual(vertices[1].normal, [-1, 0])
        XCTAssertEqual(vertices[2].normal, [-1, 0])
        XCTAssertEqual(vertices[3].normal, [0, -1])
    }

    func testEdgeVerticesForVerticalPath() {
        let path = Path([
            .point(-1, 1),
            .point(-1, -1),
        ])
        let vertices = path.edgeVertices
        XCTAssertEqual(vertices.count, 2)
        guard vertices.count >= 2 else { return }
        // positions
        XCTAssertEqual(vertices[0].position, [-1, 1])
        XCTAssertEqual(vertices[1].position, [-1, -1])
        // texture coords
        XCTAssertEqual(vertices[0].texcoord, [0, 0])
        XCTAssertEqual(vertices[1].texcoord, [0, 1])
        // normals
        XCTAssertEqual(vertices[0].normal, [-1, 0])
        XCTAssertEqual(vertices[1].normal, [-1, 0])
    }

    func testEdgeVerticesForZigZag() {
        let path = Path([
            .point(0, 0),
            .point(1, 0),
            .point(0, 1),
            .point(1, 1),
        ])
        let vertices = path.edgeVertices
        XCTAssertEqual(vertices.count, 6)
        guard vertices.count >= 6 else { return }
        // positions
        XCTAssertEqual(vertices[0].position, [0, 0])
        XCTAssertEqual(vertices[1].position, [1, 0])
        XCTAssertEqual(vertices[2].position, [1, 0])
        XCTAssertEqual(vertices[3].position, [0, 1])
        XCTAssertEqual(vertices[4].position, [0, 1])
        XCTAssertEqual(vertices[5].position, [1, 1])
        // texture coords
        XCTAssertEqual(vertices[0].texcoord, [0, 0])
        XCTAssertEqual(vertices[5].texcoord, [0, 1])
        // normals
        XCTAssertEqual(vertices[0].normal, [0, -1])
        XCTAssertEqual(vertices[1].normal, [0, -1])
        XCTAssertEqual(vertices[2].normal, Vector(1, 1).normalized())
        XCTAssertEqual(vertices[3].normal, Vector(1, 1).normalized())
        XCTAssertEqual(vertices[4].normal, [0, -1])
        XCTAssertEqual(vertices[5].normal, [0, -1])
    }

    func testNonZeroFillBoundaryKeepsCurveIntersectionsSharp() throws {
        let path = Path(subpaths: [
            .circle(segments: 16),
            .circle(radius: 0.25, segments: 16).translated(by: [0.5, 0]),
        ])
        let boundary = try XCTUnwrap(path.nonZeroFillBoundary)
        let connectorEndpoints = boundary.points.filter {
            (abs(abs($0.position.x) - 0.4318) < 0.001 &&
                abs(abs($0.position.y) - 0.2364) < 0.001) ||
                (abs($0.position.x - 0.5682) < 0.001 &&
                    abs(abs($0.position.y) - 0.2364) < 0.001)
        }

        XCTAssertFalse(connectorEndpoints.isEmpty)
        XCTAssertTrue(connectorEndpoints.allSatisfy { !$0.isCurved })
    }

    func testNonZeroFillBoundaryPreservesCurvedArcPoints() throws {
        let path = Path(subpaths: [
            .circle(segments: 16),
            .circle(radius: 0.25, segments: 16).translated(by: [0.5, 0]),
        ])
        let boundary = try XCTUnwrap(path.nonZeroFillBoundary)
        let arcPoints = boundary.points.filter {
            $0.position.isApproximatelyEqual(to: [-0.5, 0], absoluteTolerance: 0.001) ||
                $0.position.isApproximatelyEqual(to: [0, -0.5], absoluteTolerance: 0.001) ||
                $0.position.isApproximatelyEqual(to: [0.5, -0.25], absoluteTolerance: 0.001)
        }

        XCTAssertFalse(arcPoints.isEmpty)
        XCTAssertTrue(arcPoints.allSatisfy(\.isCurved))
    }

    // MARK: Y-axis clipping

    func testClipClosedClockwiseTriangleToRightOfAxis() {
        let path = Path([
            .point(0, 0),
            .point(1, 1),
            .point(1, 0),
            .point(0, 0),
        ])
        let result = path.clippedToYAxis()
        XCTAssertEqual(result.points, [
            .point(0, 0),
            .point(-1, 1),
            .point(-1, 0),
            .point(0, 0),
        ])
    }

    func testClipClosedClockwiseTriangleMostlyRightOfAxis() {
        let path = Path([
            .point(-1, 0),
            .point(1, 1),
            .point(1, 0),
            .point(-1, 0),
        ])
        let result = path.clippedToYAxis()
        XCTAssertEqual(result.points, [
            .point(0, 0.5),
            .point(-1, 1),
            .point(-1, 0),
            .point(0, 0),
        ])
    }

    func testClipClosedRectangleSpanningAxis() {
        let path = Path([
            .point(-1, 1),
            .point(1, 1),
            .point(1, -1),
            .point(-1, -1),
            .point(-1, 1),
        ])
        let result = path.clippedToYAxis()
        XCTAssertEqual(result.points, [
            .point(-1, 1),
            .point(0, 1),
            .point(0, -1),
            .point(-1, -1),
            .point(-1, 1),
        ])
    }

    func testClosedAnticlockwiseTriangleLeftOfAxis() {
        let path = Path([
            .point(0, 1),
            .point(-1, -1),
            .point(0, -1),
        ])
        let result = path.clippedToYAxis()
        XCTAssertEqual(result.points, [
            .point(0, 1),
            .point(-1, -1),
            .point(0, -1),
        ])
    }

    // MARK: subpaths

    func testSimpleOpenPathHasNoSubpaths() {
        let path = Path([
            .point(0, 1),
            .point(-1, -1),
            .point(0, -1),
        ])
        XCTAssertEqual(path.subpaths, [path])
        XCTAssertEqual(path.plane?.normal, .unitZ)
    }

    func testSimpleClosedPathHasNoSubpaths() {
        let path = Path.square()
        XCTAssertEqual(path.subpaths, [path])
        XCTAssertEqual(path.plane?.normal, .unitZ)
    }

    func testPathWithLineEndingInLoopHasCorrectSubpaths() {
        let path = Path([
            .point(0, 0),
            .point(1, 0),
            .point(2, 0),
            .point(2, 1),
            .point(1, 1),
            .point(1, 0),
        ])
        XCTAssertEqual(path.subpaths, [
            Path([
                .point(0, 0),
                .point(1, 0),
            ]),
            Path([
                .point(1, 0),
                .point(2, 0),
                .point(2, 1),
                .point(1, 1),
                .point(1, 0),
            ]),
        ])
        XCTAssertEqual(path.plane?.normal, .unitZ)
    }

    func testPathWithLoopEndingInLineHasCorrectSubpaths() {
        let path = Path([
            .point(0, 0),
            .point(1, 0),
            .point(1, 1),
            .point(0, 1),
            .point(0, 0),
            .point(-1, 0),
        ])
        XCTAssertEqual(path.subpaths, [
            Path([
                .point(0, 0),
                .point(1, 0),
                .point(1, 1),
                .point(0, 1),
                .point(0, 0),
            ]),
            Path([
                .point(0, 0),
                .point(-1, 0),
            ]),
        ])
        XCTAssertEqual(path.plane?.normal, .unitZ)
    }

    func testPathWithLoopEndingInLineHasCorrectSubpaths2() {
        let path = Path([
            .curve(24, -32),
            .point(16, -32),
            .curve(16, -37.333333259259),
            .curve(16, -42.666666740741),
            .point(16, -48),
            .point(24, -48),
            .curve(24, -42.666666740741),
            .curve(24, -37.333333259259),
            .curve(24, -32),
            .point(16, -48),
            .point(10, -48),
        ])
        XCTAssertEqual(path.subpaths, [
            Path([
                .curve(24, -32),
                .point(16, -32),
                .curve(16, -37.333333259259),
                .curve(16, -42.666666740741),
                .point(16, -48),
                .point(24, -48),
                .curve(24, -42.666666740741),
                .curve(24, -37.333333259259),
                .curve(24, -32),
            ]),
            Path([
                .point(16, -48),
                .point(10, -48),
            ]),
        ])
    }

    func testPathWithConjoinedLoopsHasCorrectSubpaths() {
        let path = Path([
            .point(0, 0),
            .point(1, 1),
            .point(2, 0),
            .point(1, -1),
            .point(0, 0),
            .point(-1, 1),
            .point(-2, 0),
            .point(-1, -1),
            .point(0, 0),
        ])
        XCTAssertEqual(path.subpaths, [
            Path([
                .point(0, 0),
                .point(1, 1),
                .point(2, 0),
                .point(1, -1),
                .point(0, 0),
            ]),
            Path([
                .point(0, 0),
                .point(-1, 1),
                .point(-2, 0),
                .point(-1, -1),
                .point(0, 0),
            ]),
        ])
        XCTAssertEqual(path.plane, .xy.inverted())
    }

    func testInvertedPathFlipsPlaneNormal() {
        let path = Path.square()
        let inverted = path.inverted()

        XCTAssertEqual(path.faceNormal, .unitZ)
        XCTAssertEqual(inverted.faceNormal, -.unitZ)
        XCTAssertEqual(inverted.plane, path.plane?.inverted())
    }

    func testPathWithTwoSeparateLoopsHasCorrectSubpaths() {
        let path = Path([
            .point(0, 0),
            .point(1, 0),
            .point(1, 1),
            .point(0, 1),
            .point(0, 0),
            .point(2, 0),
            .point(3, 0),
            .point(3, 1),
            .point(2, 1),
            .point(2, 0),
        ])
        XCTAssertEqual(path.subpaths, [
            Path([
                .point(0, 0),
                .point(1, 0),
                .point(1, 1),
                .point(0, 1),
                .point(0, 0),
            ]),
            Path([
                .point(2, 0),
                .point(3, 0),
                .point(3, 1),
                .point(2, 1),
                .point(2, 0),
            ]),
        ])
        XCTAssertEqual(path.plane?.normal, .unitZ)
    }

    func testLinkedArcSubpathsAreJoinedCorrectly() {
        let quarterTurn = Angle.pi / 2
        let first = Path.arc(angle: quarterTurn, segments: 4)
        let second = Path.arc(angle: quarterTurn, segments: 4)
            .rotated(by: .roll(quarterTurn))
        let path = Path(subpaths: [first, second])
        XCTAssertEqual(path.subpaths.count, 1)
        XCTAssertEqual(path.points, Path.arc(angle: .pi, segments: 8).points)
    }

    func testLinkedSubpathsPreserveCurvedEndpoint() {
        let first = Path([
            .point(-1, 0),
            .point(0, 0),
        ])
        let second = Path([
            .curve(0, 0),
            .curve(1, 0),
        ])
        let path = Path(subpaths: [first, second])
        XCTAssertEqual(path.subpaths.count, 1)
        XCTAssertEqual(path.points.map(\.isCurved), [false, true, true])
    }

    func testTouchingClosedPathsNotLinked() {
        let first = Path([
            .point(0, 0),
            .point(0, 1),
            .point(1, 1),
            .point(1, 0),
            .point(0, 0),
        ])
        let second = Path([
            .point(0, 0),
            .point(0, -1),
            .point(1, -1),
            .point(1, 0),
            .point(0, 0),
        ])
        let path = Path(subpaths: [first, second])
        XCTAssertEqual(path.subpaths, [first, second])
    }

    func testNestedSubpathsAreFlattenedCorrectly() {
        let path1 = Path([
            .point(0, 0),
            .point(1, 0),
            .point(1, 1),
            .point(0, 1),
            .point(0, 0),
            .point(2, 0),
            .point(3, 0),
            .point(3, 1),
            .point(2, 1),
            .point(2, 0),
        ])
        XCTAssertEqual(path1.plane?.normal, .unitZ)
        XCTAssertEqual(path1.subpaths.count, 2)
        XCTAssertEqual(path1.subpaths, [
            Path([
                .point(0, 0),
                .point(1, 0),
                .point(1, 1),
                .point(0, 1),
                .point(0, 0),
            ]),
            Path([
                .point(2, 0),
                .point(3, 0),
                .point(3, 1),
                .point(2, 1),
                .point(2, 0),
            ]),
        ])
        let path2 = Path([
            .point(5, 1),
            .point(4, -1),
            .point(5, -1),
        ])
        XCTAssertEqual(path2.plane?.normal, .unitZ)
        XCTAssertEqual(path2.subpaths.count, 1)
        let path3 = Path(subpaths: [path1, path2])
        XCTAssertEqual(path3.subpaths.count, 3)
        XCTAssertEqual(path3.subpaths, [
            Path([
                .point(0, 0),
                .point(1, 0),
                .point(1, 1),
                .point(0, 1),
                .point(0, 0),
            ]),
            Path([
                .point(2, 0),
                .point(3, 0),
                .point(3, 1),
                .point(2, 1),
                .point(2, 0),
            ]),
            Path([
                .point(5, 1),
                .point(4, -1),
                .point(5, -1),
            ]),
        ])
        XCTAssertEqual(path3.plane?.normal, .unitZ)
    }

    func testClosedPathWithOffshootSubpaths() {
        let path = Path([
            .point(0, 0),
            .point(1, 0),
            .point(1, 1),
            .point(0, 1),
            .point(0, 0),
            .point(-1, 0),
        ])
        XCTAssertEqual(path.subpaths, [
            Path([
                .point(0, 0),
                .point(1, 0),
                .point(1, 1),
                .point(0, 1),
                .point(0, 0),
            ]),
            Path([
                .point(0, 0),
                .point(-1, 0),
            ]),
        ])
    }

    func testSubpathsSeparatedCorrectly() {
        let a = Path([
            .point(0, 0.5, 0),
            .point(-0.353553390593, 0.353553390593, 0.0),
            .point(-0.5, 0, 0),
            .point(-0.353553390593, -0.353553390593, 0),
            .point(0, -0.5, 0),
            .point(0, 0.5, 0),
        ])
        let b = Path([
            .point(1, 0.085786437626, 0),
            .point(1, 0.5, 0),
            .point(0, 0.5, 0),
            .point(0.353553390593, 0.353553390593, 0),
            .point(0.5, -0, 0),
            .point(0.353553390593, -0.353553390593, 0),
            .point(0, -0.5, 0),
            .point(1, -0.5, 0),
            .point(1, -0.085786437626, 0),
            .point(1, 0.085786437626, 0),
        ])
        let c = Path(subpaths: [a, b])
        XCTAssertEqual(c.subpaths.count, 2)
        XCTAssertEqual(c.subpaths.first, a)
        XCTAssertEqual(c.subpaths.last, b)
    }

    func testCrashOnEmptySubpath() {
        let a = Path.empty
        let b = Path(subpaths: [a, .square()])
        XCTAssertEqual(a.subpaths.count, 1)
        XCTAssertEqual(b.subpaths.count, 1)
    }

    // MARK: miter limit

    func testWithInfiniteMiterLimitReturnsOriginalPath() {
        let path = Path([
            .curve(0, 0),
            .curve(1, 0),
            .curve(1, 1),
        ])

        XCTAssertEqual(path.withMiterLimit(.infinity, forStrokeWidth: 1), path)
    }

    func testWithMiterLimitSplitsOverLimitCorner() {
        let path = Path([
            .curve(0, 0),
            .curve(1, 0, texcoord: [1, 0], color: .red),
            .curve(1, 1, texcoord: [1, 1], color: .blue),
        ])
        let limited = path.withMiterLimit(1, forStrokeWidth: 1)

        XCTAssertEqual(limited.points.count, 4)
        XCTAssertEqual(limited.points[0], .curve(0, 0))
        XCTAssertEqual(limited.points[1].position, [0.75, 0])
        XCTAssertEqual(limited.points[2].position, [1, 0.25])
        XCTAssertEqual(limited.points[3].position, [1, 1])
        XCTAssertTrue(limited.points[1].isCurved)
        XCTAssertTrue(limited.points[2].isCurved)
        XCTAssertEqual(limited.points[1].texcoord, [1, 0])
        XCTAssertEqual(limited.points[2].texcoord, [1, 0.25])
        XCTAssertEqual(limited.points[1].color, .red)
        XCTAssertEqual(limited.points[2].color, Color(red: 0.75, green: 0, blue: 0.25, alpha: 1))
    }

    func testWithMiterLimitUsesStrokeWidthForBevelDistance() {
        let path = Path([
            .curve(0, 0),
            .curve(1, 0),
            .curve(1, 1),
        ])
        let narrow = path.withMiterLimit(1, forStrokeWidth: 0.5)
        let wide = path.withMiterLimit(1, forStrokeWidth: 1)

        XCTAssertEqual(narrow.points[1].position, [0.875, 0])
        XCTAssertEqual(narrow.points[2].position, [1, 0.125])
        XCTAssertEqual(wide.points[1].position, [0.75, 0])
        XCTAssertEqual(wide.points[2].position, [1, 0.25])
    }

    func testWithMiterLimitLeavesUnderLimitCornerUnchanged() {
        let path = Path([
            .point(0, 0),
            .point(1, 0),
            .point(1, 1),
        ])

        XCTAssertEqual(path.withMiterLimit(2, forStrokeWidth: 1), path)
    }

    func testWithMiterLimitPreservesClosedPath() {
        let path = Path([
            .point(-1, -1),
            .point(1, -1),
            .point(1, 1),
            .point(-1, 1),
            .point(-1, -1),
        ])
        let limited = path.withMiterLimit(1, forStrokeWidth: 1)

        XCTAssertTrue(limited.isClosed)
        XCTAssertEqual(limited.points.count, 9)
        XCTAssertEqual(limited.points.first, limited.points.last)
        XCTAssertEqual(limited.points[0].position, [-1, -0.75])
        XCTAssertEqual(limited.points[1].position, [-0.75, -1])
    }

    func testWithMiterLimitProcessesSubpaths() {
        let path = Path(subpaths: [
            Path([.point(0, 0), .point(1, 0), .point(1, 1)]),
            Path([.point(2, 0), .point(3, 0), .point(3, 1)]),
        ])
        let limited = path.withMiterLimit(1, forStrokeWidth: 0.5)

        XCTAssertEqual(limited.subpaths.count, 2)
        XCTAssertEqual(limited.subpaths[0].points.count, 4)
        XCTAssertEqual(limited.subpaths[1].points.count, 4)
    }

    // MARK: flattening

    func testFlattenVerticalPath() {
        let p = Path([
            .point(0, 0, 0),
            .point(0, 0, 1),
            .point(0, 1, 1),
        ])
        let q = p.flattened()
        // Flattened path is always on xy
        XCTAssertEqual(q.plane, .xy)
    }

    // MARK: edges

    func testEdgesForEmptyPath() {
        XCTAssertEqual(Path.empty.orderedEdges, [])
        XCTAssertEqual(Path.empty.undirectedEdges, [])
    }

    func testEdgesForUnclosedPath() {
        let path = Path([.point(0, 0), .point(1, 0), .point(1, 1)])
        XCTAssertEqual(path.orderedEdges.count, 2)
        XCTAssertEqual(path.undirectedEdges.count, 2)
    }

    func testOrderedEdgesForLetterG() throws {
        #if canImport(CoreText)
        let text = try XCTUnwrap(Path.text("G").first)
        let edges = text.orderedEdges
        let path = Path(edges)
        XCTAssertEqual(path.subpaths.count, 1)
        XCTAssertEqual(path.points.map(\.position), text.points.map(\.position))
        #endif
    }

    func testOrderedEdgesForLetterO() throws {
        #if canImport(CoreText)
        let text = try XCTUnwrap(Path.text("O").first)
        let edges = text.orderedEdges
        XCTAssertEqual(edges.count, 32)
        let path = Path(edges)
        XCTAssertEqual(path.subpaths.count, 2)
        XCTAssertEqual(path.points.map(\.position), text.points.map(\.position))
        #endif
    }

    func testFacePolygonsCanBeCancelled() {
        nonisolated(unsafe) var cancellationChecks = 0
        let path = Path([
            .point(0, 0), .point(1, 1), .point(1, 0), .point(0, 1), .point(0, 0),
        ])
        let polygons = path.facePolygons {
            cancellationChecks += 1
            return true
        }

        XCTAssertTrue(polygons.isEmpty)
        XCTAssertEqual(cancellationChecks, 1)
    }
}
