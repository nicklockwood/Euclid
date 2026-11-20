//
//  PolygonCSGTests.swift
//  Euclid
//
//  Created by Nick Lockwood on 15/01/2023.
//  Copyright © 2023 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

final class PolygonCSGTests: XCTestCase {
    func testPolygonProjectionOntoPlane() throws {
        let polygon = try XCTUnwrap(Polygon([[-1, -1], [1, -1], [1, 1], [-1, 1]]))
        let plane = Plane(unchecked: Vector(0, 1, 1).normalized(), w: 3)
        let path = polygon.projected(onto: plane)
        XCTAssertTrue(path.isClosed)
        XCTAssertTrue(path.points.allSatisfy { plane.intersects($0.position) })
        XCTAssertEqual(path.facePolygons().surfaceArea, 2 * 2.0.squareRoot(), accuracy: epsilon)
        let line = polygon.projected(onto: .yz)
        XCTAssertFalse(line.isClosed)
        XCTAssertEqual(Set(line.points.map(\.position)), Set([[0, -1, 0], [0, 1, 0]]))
        let horizontal = polygon.projected(onto: Plane(unchecked: .unitZ, w: 3))
        XCTAssertEqual(horizontal.bounds, Bounds([-1, -1, 3], [1, 1, 3]))
        XCTAssertEqual(horizontal.facePolygons().surfaceArea, 4, accuracy: epsilon)
        XCTAssertTrue(polygon.projected(onto: plane) { true }.isEmpty)
    }

    func testProjectionAndPlaneIntersectionPreserveVertexColors() throws {
        let polygon = try XCTUnwrap(Polygon([
            Vertex(-1, -1, texcoord: [0, 0], color: .red),
            Vertex(1, -1, texcoord: [1, 0], color: .blue),
            Vertex(1, 1, texcoord: [1, 1], color: .green),
            Vertex(-1, 1, texcoord: [0, 1], color: .green),
        ]))
        let target = Plane(unchecked: Vector(1, 0, 1).normalized(), w: 2)
        for path in [polygon.projected(onto: target), polygon.intersection(with: .xy)] {
            XCTAssertEqual(Set(path.points.compactMap(\.color)), [.red, .blue, .green])
            XCTAssertFalse(path.hasTexcoords)
            XCTAssertFalse(path.points.contains(where: \.isCurved))
        }
        let edge = polygon.projected(onto: .yz)
        XCTAssertFalse(edge.isClosed)
        XCTAssertEqual(Set(edge.points.compactMap(\.color)), [.blue, .green])
        let section = polygon.intersection(with: .yz)
        let first = try XCTUnwrap(section.points.first { $0.position.y < 0 })
        let last = try XCTUnwrap(section.points.first { $0.position.y > 0 })
        XCTAssertEqual(first.color, Color.red.toLinear().lerp(Color.blue.toLinear(), 0.5).toSRGB())
        XCTAssertEqual(last.color, .green)
        XCTAssertFalse(section.hasTexcoords)
    }

    func testPolygonPlaneIntersectionWithDisjointSegments() throws {
        let polygon = try XCTUnwrap(Polygon([
            [-3, -2], [3, -2], [3, 2], [1, 2],
            [1, -1], [-1, -1], [-1, 2], [-3, 2],
        ]))
        let path = polygon.intersection(with: .xz)
        XCTAssertEqual(path.subpaths.count, 2)
        XCTAssertEqual(Set(path.points.map(\.position)), Set([[-3, 0], [-1, 0], [1, 0], [3, 0]]))
        XCTAssertEqual(path.length, 4, accuracy: epsilon)
    }

    func testPolygonPlaneIntersectionWithFaceEdgeAndPoint() throws {
        let polygon = try XCTUnwrap(Polygon([[0, 0], [1, 0], [1, 1], [0, 1]]))
        let face = polygon.intersection(with: .xy.inverted())
        XCTAssertTrue(face.isClosed)
        XCTAssertEqual(face.facePolygons().surfaceArea, 1, accuracy: epsilon)

        let edge = polygon.intersection(with: .xz)
        XCTAssertEqual(Set(edge.points.map(\.position)), Set([[0, 0], [1, 0]]))
        XCTAssertEqual(edge.length, 1, accuracy: epsilon)

        let tangent = Plane(unchecked: Vector(1, 1, 0).normalized(), w: 0)
        XCTAssertEqual(polygon.intersection(with: tangent).points.map(\.position), [.zero])
        XCTAssertTrue(polygon.intersection(with: Plane(unchecked: .unitZ, w: 1)).isEmpty)
        XCTAssertTrue(polygon.intersection(with: .xy) { true }.isEmpty)
    }

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

    func testSplittingPreservesIntentionallyThinPolygon() throws {
        let polygon = try XCTUnwrap(Polygon([
            [-1, 0], [1, 0], [1, 1e-9], [-1, 1e-9],
        ], material: Color.red))
        let split = polygon.split(along: Plane(unchecked: .unitX, pointOnPlane: .zero))
        XCTAssertEqual(split.front.count, 1)
        XCTAssertEqual(split.back.count, 1)
        XCTAssertEqual(split.front.first?.material, polygon.material)
        XCTAssertEqual(split.back.first?.material, polygon.material)
        XCTAssertEqual((split.front + split.back).reduce(0) { $0 + $1.area }, polygon.area, accuracy: 1e-12)
    }

    func testSquareSplitAlongPlane() {
        let a = Path.square().facePolygons()[0]
        let plane = Plane(unchecked: .unitX, pointOnPlane: .zero)
        let b = a.split(along: plane)
        XCTAssertEqual(Bounds(b.front), Bounds([0, -0.5], [0.5, 0.5]))
        XCTAssertEqual(Bounds(b.back), Bounds([-0.5, -0.5], [0, 0.5]))
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
