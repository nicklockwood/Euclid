//
//  PathTests.swift
//  GeometryScriptTests
//
//  Created by Nick Lockwood on 19/09/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

class PathTests: XCTestCase {
    // MARK: isSimple

    func testSinglePoint() {
        let path = Path([
            .point(0, 0),
        ])
        XCTAssertTrue(path.isSimple)
        XCTAssertTrue(path.isClosed)
        XCTAssertEqual(path.points.count, 1)
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
            points.append(PathPoint.point(0, -0.5).transformed(by: transform))
            transform.rotate(by: .roll(.pi / Double(sides)))
            points.append(PathPoint.point(0, -1).transformed(by: transform))
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

    func testStraightLinePathAnticlockwiseWinding() {
        let path = Path([
            .point(-1, 1),
            .point(-1, -1),
        ])
        XCTAssertFalse(path.isClosed)
        XCTAssertEqual(path.plane?.normal, .unitZ)
    }

    func testStraightLinePathAnticlockwiseWinding2() {
        let path = Path([
            .point(-1, -1),
            .point(-1, 1),
        ])
        XCTAssertFalse(path.isClosed)
        XCTAssertEqual(path.plane?.normal, .unitZ)
    }

    func testStraightLinePathAnticlockwiseWinding3() {
        let path = Path([
            .point(1, 1),
            .point(1, -1),
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
        XCTAssertEqual(vertices[0].position, Vector(-1, 1))
        XCTAssertEqual(vertices[1].position, Vector(-1, -1))
        XCTAssertEqual(vertices[2].position, Vector(-1, -1))
        XCTAssertEqual(vertices[3].position, Vector(1, -1))
        XCTAssertEqual(vertices[4].position, Vector(1, -1))
        XCTAssertEqual(vertices[5].position, Vector(1, 1))
        XCTAssertEqual(vertices[6].position, Vector(1, 1))
        XCTAssertEqual(vertices[7].position, Vector(-1, 1))
        // texture coords
        XCTAssertEqual(vertices[0].texcoord, Vector(0, 0))
        XCTAssertEqual(vertices[1].texcoord, Vector(0, 0.25))
        XCTAssertEqual(vertices[2].texcoord, Vector(0, 0.25))
        XCTAssertEqual(vertices[3].texcoord, Vector(0, 0.5))
        XCTAssertEqual(vertices[4].texcoord, Vector(0, 0.5))
        XCTAssertEqual(vertices[5].texcoord, Vector(0, 0.75))
        XCTAssertEqual(vertices[6].texcoord, Vector(0, 0.75))
        XCTAssertEqual(vertices[7].texcoord, Vector(0, 1))
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
        XCTAssertEqual(vertices[0].position, Vector(0, 1))
        XCTAssertEqual(vertices[1].position, Vector(-1, 1))
        XCTAssertEqual(vertices[2].position, Vector(-1, 1))
        XCTAssertEqual(vertices[3].position, Vector(-1, -1))
        XCTAssertEqual(vertices[4].position, Vector(-1, -1))
        XCTAssertEqual(vertices[5].position, Vector(0, -1))
        // texture coords
        XCTAssertEqual(vertices[0].texcoord, Vector(0, 0))
        XCTAssertEqual(vertices[1].texcoord, Vector(0, 0.25))
        XCTAssertEqual(vertices[2].texcoord, Vector(0, 0.25))
        XCTAssertEqual(vertices[3].texcoord, Vector(0, 0.75))
        XCTAssertEqual(vertices[4].texcoord, Vector(0, 0.75))
        XCTAssertEqual(vertices[5].texcoord, Vector(0, 1))
        // normals
        XCTAssertEqual(vertices[0].normal, Vector(0, 1))
        XCTAssertEqual(vertices[1].normal, Vector(-1, 1).normalized())
        XCTAssertEqual(vertices[2].normal, Vector(-1, 1).normalized())
        XCTAssertEqual(vertices[3].normal, Vector(-1, -1).normalized())
        XCTAssertEqual(vertices[4].normal, Vector(-1, -1).normalized())
        XCTAssertEqual(vertices[5].normal, Vector(0, -1))
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
        XCTAssertEqual(vertices[0].position, Vector(0, 1))
        XCTAssertEqual(vertices[1].position, Vector(-1, 1))
        XCTAssertEqual(vertices[2].position, Vector(-1, 1))
        XCTAssertEqual(vertices[3].position, Vector(-1, -1))
        XCTAssertEqual(vertices[4].position, Vector(-1, -1))
        XCTAssertEqual(vertices[5].position, Vector(0, -1))
        // texture coords
        XCTAssertEqual(vertices[0].texcoord, Vector(0, 0))
        XCTAssertEqual(vertices[1].texcoord, Vector(0, 0.25))
        XCTAssertEqual(vertices[2].texcoord, Vector(0, 0.25))
        XCTAssertEqual(vertices[3].texcoord, Vector(0, 0.75))
        XCTAssertEqual(vertices[4].texcoord, Vector(0, 0.75))
        XCTAssertEqual(vertices[5].texcoord, Vector(0, 1))
        // normals
        XCTAssertEqual(vertices[0].normal, Vector(0, 1))
        XCTAssertEqual(vertices[1].normal, Vector(0, 1))
        XCTAssertEqual(vertices[2].normal, Vector(-1, 0))
        XCTAssertEqual(vertices[3].normal, Vector(-1, 0))
        XCTAssertEqual(vertices[4].normal, Vector(0, -1))
        XCTAssertEqual(vertices[5].normal, Vector(0, -1))
    }

    func testEdgeVerticesForCircle() {
        let path = Path.circle(radius: 1, segments: 4)
        let vertices = path.edgeVertices
        XCTAssertEqual(vertices.count, 8)
        guard vertices.count >= 8 else { return }
        // positions
        XCTAssertEqual(vertices[0].position, Vector(0, 1))
        XCTAssertEqual(vertices[1].position, Vector(-1, 0))
        XCTAssertEqual(vertices[2].position, Vector(-1, 0))
        XCTAssertEqual(vertices[3].position, Vector(0, -1))
        XCTAssertEqual(vertices[4].position, Vector(0, -1))
        XCTAssertEqual(vertices[5].position, Vector(1, 0))
        XCTAssertEqual(vertices[6].position, Vector(1, 0))
        XCTAssertEqual(vertices[7].position, Vector(0, 1))
        // texture coords
        XCTAssertEqual(vertices[0].texcoord, Vector(0, 0))
        XCTAssertEqual(vertices[1].texcoord, Vector(0, 0.25))
        XCTAssertEqual(vertices[2].texcoord, Vector(0, 0.25))
        XCTAssertEqual(vertices[3].texcoord, Vector(0, 0.5))
        XCTAssertEqual(vertices[4].texcoord, Vector(0, 0.5))
        XCTAssertEqual(vertices[5].texcoord, Vector(0, 0.75))
        XCTAssertEqual(vertices[6].texcoord, Vector(0, 0.75))
        XCTAssertEqual(vertices[7].texcoord, Vector(0, 1))
        // normals
        XCTAssertEqual(vertices[0].normal, Vector(0, 1))
        XCTAssertEqual(vertices[1].normal, Vector(-1, 0))
        XCTAssertEqual(vertices[2].normal, Vector(-1, 0))
        XCTAssertEqual(vertices[3].normal, Vector(0, -1))
        XCTAssertEqual(vertices[4].normal, Vector(0, -1))
        XCTAssertEqual(vertices[5].normal, Vector(1, 0))
        XCTAssertEqual(vertices[6].normal, Vector(1, 0))
        XCTAssertEqual(vertices[7].normal, Vector(0, 1))
    }

    func testEdgeVerticesForEllipse() {
        let path = Path.ellipse(width: 4, height: 2, segments: 4)
        let vertices = path.edgeVertices
        XCTAssertEqual(vertices.count, 8)
        guard vertices.count >= 8 else { return }
        // positions
        XCTAssertEqual(vertices[0].position, Vector(0, 1))
        XCTAssertEqual(vertices[1].position, Vector(-2, 0))
        XCTAssertEqual(vertices[2].position, Vector(-2, 0))
        XCTAssertEqual(vertices[3].position, Vector(0, -1))
        XCTAssertEqual(vertices[4].position, Vector(0, -1))
        XCTAssertEqual(vertices[5].position, Vector(2, 0))
        XCTAssertEqual(vertices[6].position, Vector(2, 0))
        XCTAssertEqual(vertices[7].position, Vector(0, 1))
        // texture coords
        XCTAssertEqual(vertices[0].texcoord, Vector(0, 0))
        XCTAssertEqual(vertices[1].texcoord, Vector(0, 0.25))
        XCTAssertEqual(vertices[2].texcoord, Vector(0, 0.25))
        XCTAssertEqual(vertices[3].texcoord, Vector(0, 0.5))
        XCTAssertEqual(vertices[4].texcoord, Vector(0, 0.5))
        XCTAssertEqual(vertices[5].texcoord, Vector(0, 0.75))
        XCTAssertEqual(vertices[6].texcoord, Vector(0, 0.75))
        XCTAssertEqual(vertices[7].texcoord, Vector(0, 1))
        // normals
        XCTAssertEqual(vertices[0].normal, Vector(0, 1))
        XCTAssertEqual(vertices[1].normal, Vector(-1, 0))
        XCTAssertEqual(vertices[2].normal, Vector(-1, 0))
        XCTAssertEqual(vertices[3].normal, Vector(0, -1))
        XCTAssertEqual(vertices[4].normal, Vector(0, -1))
        XCTAssertEqual(vertices[5].normal, Vector(1, 0))
        XCTAssertEqual(vertices[6].normal, Vector(1, 0))
        XCTAssertEqual(vertices[7].normal, Vector(0, 1))
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
        XCTAssertEqual(vertices[0].position, Vector(0, 1))
        XCTAssertEqual(vertices[1].position, Vector(-1, 0))
        XCTAssertEqual(vertices[2].position, Vector(-1, 0))
        XCTAssertEqual(vertices[3].position, Vector(0, -1))
        // texture coords
        XCTAssertEqual(vertices[0].texcoord, Vector(0, 0))
        XCTAssertEqual(vertices[1].texcoord, Vector(0, 0.5))
        XCTAssertEqual(vertices[2].texcoord, Vector(0, 0.5))
        XCTAssertEqual(vertices[3].texcoord, Vector(0, 1))
        // normals
        XCTAssertEqual(vertices[0].normal, Vector(0, 1))
        XCTAssertEqual(vertices[1].normal, Vector(-1, 0))
        XCTAssertEqual(vertices[2].normal, Vector(-1, 0))
        XCTAssertEqual(vertices[3].normal, Vector(0, -1))
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
        XCTAssertEqual(vertices[0].position, Vector(-1, 1))
        XCTAssertEqual(vertices[1].position, Vector(-1, -1))
        // texture coords
        XCTAssertEqual(vertices[0].texcoord, Vector(0, 0))
        XCTAssertEqual(vertices[1].texcoord, Vector(0, 1))
        // normals
        XCTAssertEqual(vertices[0].normal, Vector(-1, 0))
        XCTAssertEqual(vertices[1].normal, Vector(-1, 0))
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
        XCTAssertEqual(vertices[0].position, Vector(0, 0))
        XCTAssertEqual(vertices[1].position, Vector(1, 0))
        XCTAssertEqual(vertices[2].position, Vector(1, 0))
        XCTAssertEqual(vertices[3].position, Vector(0, 1))
        XCTAssertEqual(vertices[4].position, Vector(0, 1))
        XCTAssertEqual(vertices[5].position, Vector(1, 1))
        // texture coords
        XCTAssertEqual(vertices[0].texcoord, Vector(0, 0))
        XCTAssertEqual(vertices[5].texcoord, Vector(0, 1))
        // normals
        XCTAssertEqual(vertices[0].normal, Vector(0, -1))
        XCTAssertEqual(vertices[1].normal, Vector(0, -1))
        XCTAssert(vertices[2].normal.isEqual(to: Vector(1, 1).normalized()))
        XCTAssert(vertices[3].normal.isEqual(to: Vector(1, 1).normalized()))
        XCTAssertEqual(vertices[4].normal, Vector(0, -1))
        XCTAssertEqual(vertices[5].normal, Vector(0, -1))
    }

    // MARK: inset

    func testInsetSquare() {
        let path = Path.square()
        let result = path.inset(by: 0.25)
        XCTAssertEqual(result, .square(size: 0.5))
    }

    func testInsetCircle() {
        let path = Path.circle(segments: 4)
        let result = path.inset(by: 0.25)
        let adjacent = sqrt(pow(0.5, 2) * 2) / 2
        let radius = sqrt(pow(adjacent - 0.25, 2) * 2)
        XCTAssertEqual(result, .circle(radius: radius, segments: 4))
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
        XCTAssertNil(path.plane)
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
        XCTAssertEqual(path.points, Path.arc(angle: .pi, segments: 8).points)
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
}
