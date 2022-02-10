//
//  ShapeTests.swift
//  GeometryScriptTests
//
//  Created by Nick Lockwood on 09/10/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

class PathShapeTests: XCTestCase {
    // MARK: Curve

    func testCurveWithConsecutiveMixedTypePointsWithSamePosition() {
        let points: [PathPoint] = [
            .point(-1, 1),
            .point(-1, -1),
            .point(1, -1),
            .curve(1, -1),
            .point(1, 1),
            .point(-1, 1),
        ]
        _ = Path(points)
        _ = Path.curve(points)
    }

    func testSimpleCurvedPath() {
        let points: [PathPoint] = [
            .point(-1, -1),
            .curve(0, 1),
            .point(1, -1),
        ]
        XCTAssertEqual(Path.curve(points, detail: 0).points, points)
        XCTAssertEqual(Path.curve(points, detail: 1).points, [
            .point(-1, -1),
            .curve(-1 / 3, -1 / 9),
            .curve(1 / 3, -1 / 9),
            .point(1, -1),
        ] as [PathPoint])
        XCTAssertEqual(Path.curve(points, detail: 2).points, [
            .point(-1, -1),
            .curve(-0.5, -0.25),
            .curve(0, 0),
            .curve(0.5, -0.25),
            .point(1, -1),
        ])
    }

    func testSimpleCurveEndedPath() {
        let points: [PathPoint] = [
            .curve(0, 1),
            .point(-1, 0),
            .curve(0, -1),
        ]
        XCTAssertEqual(Path.curve(points, detail: 0).points, points)
        XCTAssertEqual(Path.curve(points, detail: 1).points, [
            .curve(0, 0.5),
            .point(-1, 0),
            .curve(0, -0.5),
        ])
    }

    func testClosedCurvedPath() {
        let points: [PathPoint] = [
            .curve(-1, 1),
            .curve(1, 1),
            .curve(1, -1),
            .curve(-1, -1),
            .curve(-1, 1),
        ]
        XCTAssertEqual(Path.curve(points, detail: 0).points, points)
        XCTAssertEqual(Path.curve(points, detail: 1).points, [
            .curve(-1, 0),
            .curve(-0.75, 0.75),
            .curve(0, 1),
            .curve(0.75, 0.75),
            .curve(1, 0),
            .curve(0.75, -0.75),
            .curve(0, -1),
            .curve(-0.75, -0.75),
            .curve(-1, 0),
        ])
    }

    func testClosedCurvedPathWithSharpFirstCorner() {
        let points: [PathPoint] = [
            .point(-1, 1),
            .curve(1, 1),
            .curve(1, -1),
            .curve(-1, -1),
            .point(-1, 1),
        ]
        XCTAssertEqual(Path.curve(points, detail: 0).points, points)
        XCTAssertEqual(Path.curve(points, detail: 1).points, [
            .point(-1, 1),
            .curve(0.5, 0.75),
            .curve(1, 0),
            .curve(0.75, -0.75),
            .curve(0, -1),
            .curve(-0.75, -0.5),
            .point(-1, 1),
        ])
    }

    func testClosedCurvedPathWithSharpSecondCorner() {
        let points: [PathPoint] = [
            .curve(-1, 1),
            .point(1, 1),
            .curve(1, -1),
            .curve(-1, -1),
            .curve(-1, 1),
        ]
        XCTAssertEqual(Path.curve(points, detail: 0).points, points)
        XCTAssertEqual(Path.curve(points, detail: 1).points, [
            .curve(-1, 0),
            .curve(-0.5, 0.75),
            .point(1, 1),
            .curve(0.75, -0.5),
            .curve(0, -1),
            .curve(-0.75, -0.75),
            .curve(-1, 0),
        ])
    }

    func testClosedCurvedPathWithSharpSecondAndThirdCorner() {
        let points: [PathPoint] = [
            .curve(-1, 1),
            .point(1, 1),
            .point(1, -1),
            .curve(-1, -1),
            .curve(-1, 1),
        ]
        XCTAssertEqual(Path.curve(points, detail: 0).points, points)
        XCTAssertEqual(Path.curve(points, detail: 1).points, [
            .curve(-1, 0),
            .curve(-0.5, 0.75),
            .point(1, 1),
            .point(1, -1),
            .curve(-0.5, -0.75),
            .curve(-1, 0),
        ])
    }

    // MARK: Circle

    func testCircleIsClosed() {
        let path = Path.circle(radius: 0.50, segments: 25)
        XCTAssert(path.isClosed)
    }

    // MARK: Rounded rect

    func testSimpleRoundedRect() {
        let path = Path.roundedRectangle(width: 1, height: 1, radius: 0.25)
        XCTAssert(path.isClosed)
        XCTAssertEqual(path.points.count, 21)
        XCTAssertEqual(path.bounds, Bounds(
            min: Vector(-0.5, -0.5),
            max: Vector(0.5, 0.5)
        ))
    }

    func testCircularRoundedRect() {
        let path = Path.roundedRectangle(width: 1, height: 1, radius: 0.5)
        XCTAssert(path.isClosed)
        XCTAssertEqual(path.points.count, 17)
        XCTAssertEqual(path.bounds, Bounds(
            min: Vector(-0.5, -0.5),
            max: Vector(0.5, 0.5)
        ))
    }

    func testPortraitRoundedRect() {
        let path = Path.roundedRectangle(width: 1, height: 2, radius: 0.5)
        XCTAssert(path.isClosed)
        XCTAssertEqual(path.points.count, 19)
        XCTAssertEqual(path.bounds, Bounds(
            min: Vector(-0.5, -1),
            max: Vector(0.5, 1)
        ))
    }

    func testLandscapeRoundedRect() {
        let path = Path.roundedRectangle(width: 2, height: 1, radius: 0.5)
        XCTAssert(path.isClosed)
        XCTAssertEqual(path.points.count, 19)
        XCTAssertEqual(path.bounds, Bounds(
            min: Vector(-1, -0.5),
            max: Vector(1, 0.5)
        ))
    }

    func testLowResRoundedRect() {
        let path = Path.roundedRectangle(width: 1, height: 1, radius: 0.25, detail: 1)
        XCTAssert(path.isClosed)
        XCTAssertEqual(path.points.count, 9)
        XCTAssertEqual(path.bounds, Bounds(
            min: Vector(-0.5, -0.5),
            max: Vector(0.5, 0.5)
        ))
    }

    func testZeroDetailRoundedRect() {
        let path = Path.roundedRectangle(width: 1, height: 1, radius: 0.5, detail: 0)
        XCTAssertEqual(path, Path(Path.rectangle(width: 1, height: 1).points.map {
            PathPoint.curve($0.position)
        }))
    }

    func testZeroRadiusRoundedRect() {
        let path = Path.roundedRectangle(width: 1, height: 1, radius: 0)
        XCTAssertEqual(path, .rectangle(width: 1, height: 1))
    }
}
