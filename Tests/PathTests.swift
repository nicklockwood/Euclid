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
        XCTAssertEqual(path.plane?.normal, .z)
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
        XCTAssertEqual(path.plane?.normal, -.z)
    }

    func testConvexOpenPathAnticlockwiseWinding() {
        let path = Path([
            .point(-1, 1),
            .point(-1, -1),
            .point(1, -1),
        ])
        XCTAssertFalse(path.isClosed)
        XCTAssertEqual(path.plane?.normal, .z)
    }

    func testConvexOpenPathClockwiseWinding() {
        let path = Path([
            .point(-1, -1),
            .point(-1, 1),
            .point(1, 1),
        ])
        XCTAssertFalse(path.isClosed)
        XCTAssertEqual(path.plane?.normal, -.z)
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
        XCTAssertEqual(path.plane?.normal, .z)
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
        XCTAssertEqual(path.plane?.normal, -.z)
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
        XCTAssertEqual(path.plane?.normal, -.z)
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
        XCTAssertEqual(path.plane?.normal, .z)
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
        XCTAssertEqual(path.plane?.normal, -.z)
    }

    func testStraightLinePathAnticlockwiseWinding() {
        let path = Path([
            .point(-1, 1),
            .point(-1, -1),
        ])
        XCTAssertFalse(path.isClosed)
        XCTAssertEqual(path.plane?.normal, .z)
    }

    func testStraightLinePathAnticlockwiseWinding2() {
        let path = Path([
            .point(-1, -1),
            .point(-1, 1),
        ])
        XCTAssertFalse(path.isClosed)
        XCTAssertEqual(path.plane?.normal, .z)
    }

    func testStraightLinePathAnticlockwiseWinding3() {
        let path = Path([
            .point(1, 1),
            .point(1, -1),
        ])
        XCTAssertFalse(path.isClosed)
        XCTAssertEqual(path.plane?.normal, .z)
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
        XCTAssertEqual(vertices[0].normal.quantized(), Direction(x: -1, y: 1).quantized())
        XCTAssertEqual(vertices[1].normal.quantized(), Direction(x: -1, y: -1).quantized())
        XCTAssertEqual(vertices[2].normal.quantized(), Direction(x: -1, y: -1).quantized())
        XCTAssertEqual(vertices[3].normal.quantized(), Direction(x: 1, y: -1).quantized())
        XCTAssertEqual(vertices[4].normal.quantized(), Direction(x: 1, y: -1).quantized())
        XCTAssertEqual(vertices[5].normal.quantized(), Direction(x: 1, y: 1).quantized())
        XCTAssertEqual(vertices[6].normal.quantized(), Direction(x: 1, y: 1).quantized())
        XCTAssertEqual(vertices[7].normal.quantized(), Direction(x: -1, y: 1).quantized())
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
        XCTAssertEqual(vertices[0].normal, Direction(x: 0, y: 1))
        XCTAssertEqual(vertices[1].normal.quantized(), Direction(x: -1, y: 1).quantized())
        XCTAssertEqual(vertices[2].normal.quantized(), Direction(x: -1, y: 1).quantized())
        XCTAssertEqual(vertices[3].normal.quantized(), Direction(x: -1, y: -1).quantized())
        XCTAssertEqual(vertices[4].normal.quantized(), Direction(x: -1, y: -1).quantized())
        XCTAssertEqual(vertices[5].normal, Direction(x: 0, y: -1))
        XCTAssertEqual(vertices[0].normal, .y)
        XCTAssertEqual(vertices[5].normal, -.y)
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
        XCTAssertEqual(vertices[0].normal, .y)
        XCTAssertEqual(vertices[1].normal, .y)
        XCTAssertEqual(vertices[2].normal, -.x)
        XCTAssertEqual(vertices[3].normal, -.x)
        XCTAssertEqual(vertices[4].normal, -.y)
        XCTAssertEqual(vertices[5].normal, -.y)
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
        XCTAssertEqual(vertices[0].normal, .y)
        XCTAssertEqual(vertices[1].normal, -.x)
        XCTAssertEqual(vertices[2].normal, -.x)
        XCTAssertEqual(vertices[3].normal, -.y)
        XCTAssertEqual(vertices[4].normal, -.y)
        XCTAssertEqual(vertices[5].normal, .x)
        XCTAssertEqual(vertices[6].normal, .x)
        XCTAssertEqual(vertices[7].normal, .y)
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
        XCTAssertEqual(vertices[0].normal, .y)
        XCTAssertEqual(vertices[1].normal, -.x)
        XCTAssertEqual(vertices[2].normal, -.x)
        XCTAssertEqual(vertices[3].normal, -.y)
        XCTAssertEqual(vertices[4].normal, -.y)
        XCTAssertEqual(vertices[5].normal, .x)
        XCTAssertEqual(vertices[6].normal, .x)
        XCTAssertEqual(vertices[7].normal, .y)
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
        XCTAssertEqual(vertices[0].normal, .y)
        XCTAssertEqual(vertices[1].normal, -.x)
        XCTAssertEqual(vertices[2].normal, -.x)
        XCTAssertEqual(vertices[3].normal, -.y)
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
        XCTAssertEqual(vertices[0].normal, -.x)
        XCTAssertEqual(vertices[1].normal, -.x)
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
        XCTAssertEqual(vertices[0].normal, Direction(x: 0, y: -1))
        XCTAssertEqual(vertices[1].normal, Direction(x: 0, y: -1))
        XCTAssert(vertices[2].normal.isEqual(to: Direction(x: 1, y: 1)))
        XCTAssert(vertices[3].normal.isEqual(to: Direction(x: 1, y: 1)))
        XCTAssertEqual(vertices[4].normal, Direction(x: 0, y: -1))
        XCTAssertEqual(vertices[5].normal, Direction(x: 0, y: -1))
        XCTAssertEqual(vertices[0].normal, -.y)
        XCTAssertEqual(vertices[1].normal, -.y)
        XCTAssertEqual(vertices[4].normal, -.y)
        XCTAssertEqual(vertices[5].normal, -.y)
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
        XCTAssertEqual(path.plane?.normal, .z)
    }

    func testSimpleClosedPathHasNoSubpaths() {
        let path = Path.square()
        XCTAssertEqual(path.subpaths, [path])
        XCTAssertEqual(path.plane?.normal, .z)
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
        XCTAssertEqual(path.plane?.normal, .z)
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
        XCTAssertEqual(path.plane?.normal, .z)
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
        XCTAssertEqual(path.plane?.normal, .z)
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
        XCTAssertEqual(path1.plane?.normal, .z)
        let path2 = Path([
            .point(5, 1),
            .point(4, -1),
            .point(5, -1),
        ])
        XCTAssertEqual(path2.plane?.normal, .z)
        let path3 = Path(subpaths: [path1, path2])
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
                .point(2, 0),
                .point(5, 1),
                .point(4, -1),
                .point(5, -1),
            ]),
        ])
        XCTAssertNil(path3.plane)
    }
}
