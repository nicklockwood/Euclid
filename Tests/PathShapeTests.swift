//
//  PathShapeTests.swift
//  GeometryScriptTests
//
//  Created by Nick Lockwood on 09/10/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

final class PathShapeTests: XCTestCase {
    // MARK: Curve

    func testCurveWithSinglePoint() {
        let points: [PathPoint] = [
            .point(0, 0),
        ]
        _ = Path(points)
        _ = Path.curve(points)
    }

    func testCurveWithCoincidentPoints() {
        let points: [PathPoint] = [
            .point(0, 0),
            .point(0, 0),
            .point(0, 0),
        ]
        _ = Path(points)
        _ = Path.curve(points)
    }

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

    // MARK: Arc

    func testDefault() {
        let path = Path.arc(color: .green)
        XCTAssert(path.points.allSatisfy { $0.color == .green })
        XCTAssertEqual(path.bounds, Bounds([0, -0.5, 0], [0.5, 0.5, 0]))
    }

    func testInverseArc() {
        let path = Path.arc(angle: -.pi / 2)
        XCTAssertEqual(path.bounds, Bounds([-0.5, 0.5, 0], .zero))
    }

    func testClosedArc() {
        let path = Path.arc(angle: .twoPi, radius: 2, color: .red)
        XCTAssertEqual(path, Path.circle(radius: 2, color: .red).scaled(by: [-1, 1]))
    }

    func testOverClosedArc() {
        let path = Path.arc(angle: .pi * 3, radius: 2)
        XCTAssertEqual(path, Path.circle(radius: 2).scaled(by: [-1, 1]))
    }

    func testInverseClosedArc() {
        let path = Path.arc(angle: -.twoPi, radius: 2)
        XCTAssertEqual(path, .circle(radius: 2))
    }

    func testInverseOverClosedArc() {
        let path = Path.arc(angle: -.pi * 3, radius: 2)
        XCTAssertEqual(path, .circle(radius: 2))
    }

    func testAcuteArcMinSegments() {
        let path = Path.arc(angle: .pi * 0.2, segments: 0)
        XCTAssertEqual(path.points.count, 2)
    }

    func testObtuseArcMinSegments2() {
        let path = Path.arc(angle: .pi * 0.6, segments: 0)
        XCTAssertEqual(path.points.count, 3)
    }

    func testArcCircleMinSegments() {
        let path = Path.arc(angle: -.pi * 2, radius: 2, segments: 0)
        XCTAssertEqual(path.points.count, 4)
        XCTAssertEqual(path, .circle(radius: 2, segments: 3))
    }

    func testHighDetailArcCanBeCancelled() {
        nonisolated(unsafe) var checks = 0
        let path = Path.arc(segments: 20_000_000) {
            checks += 1
            return checks > 2
        }
        XCTAssertEqual(checks, 3)
        XCTAssert(path.isEmpty)
    }

    // MARK: Circle

    func testCircleIsClosed() {
        let path = Path.circle(radius: 0.50, segments: 25)
        XCTAssert(path.isClosed)
    }

    // MARK: Rectangle

    func testSimpleRect() {
        let path = Path.rectangle(width: 1, height: 1)
        XCTAssert(path.isClosed)
        XCTAssertEqual(path.plane, .xy)
        XCTAssertEqual(path.points.count, 5)
        XCTAssertEqual(path.bounds, Bounds(
            min: [-0.5, -0.5],
            max: [0.5, 0.5]
        ))
    }

    func testReverseRect() {
        let path = Path.rectangle(width: -1, height: -1)
        XCTAssert(path.isClosed)
        XCTAssertEqual(path.plane, .xy)
        XCTAssertEqual(path.points.count, 5)
        XCTAssertEqual(path.bounds, Bounds(
            min: [-0.5, -0.5],
            max: [0.5, 0.5]
        ))
    }

    func testNegativeWidthRect() {
        let path = Path.rectangle(width: -1, height: 1)
        XCTAssert(path.isClosed)
        XCTAssertEqual(path.plane, .xy)
        XCTAssertEqual(path.points.count, 5)
        XCTAssertEqual(path.bounds, Bounds(
            min: [-0.5, -0.5],
            max: [0.5, 0.5]
        ))
    }

    func testNegativeHeightRect() {
        let path = Path.rectangle(width: 1, height: -1)
        XCTAssert(path.isClosed)
        XCTAssertEqual(path.plane, .xy)
        XCTAssertEqual(path.points.count, 5)
        XCTAssertEqual(path.bounds, Bounds(
            min: [-0.5, -0.5],
            max: [0.5, 0.5]
        ))
    }

    func testZeroWidthRect() {
        let path = Path.rectangle(width: 0, height: 1)
        XCTAssert(path.isClosed)
        XCTAssertEqual(path.plane, .xy)
        XCTAssertEqual(path.points.count, 3)
        XCTAssertEqual(path.bounds, Bounds(
            min: [0, -0.5],
            max: [0, 0.5]
        ))
    }

    func testTinyWidthRect() {
        let path = Path.rectangle(width: 1e-9, height: 1)
        XCTAssert(path.isClosed)
        XCTAssertEqual(path.plane, .xy)
        XCTAssertEqual(path.points.count, 3)
        XCTAssertEqual(path.bounds, Bounds(
            min: [0, -0.5],
            max: [0, 0.5]
        ))
    }

    func testZeroSizeRect() {
        let path = Path.rectangle(width: 0, height: 0)
        XCTAssert(path.isClosed)
        XCTAssertEqual(path.points.count, 1)
        XCTAssertEqual(path.bounds, Bounds(
            min: .zero,
            max: .zero
        ))
    }

    func testZeroHeightRect() {
        let path = Path.rectangle(width: 1, height: 0)
        XCTAssert(path.isClosed)
        XCTAssertEqual(path.plane, .xy)
        XCTAssertEqual(path.points.count, 3)
        XCTAssertEqual(path.bounds, Bounds(
            min: [-0.5, 0],
            max: [0.5, 0]
        ))
    }

    func testTinyHeightRect() {
        let path = Path.rectangle(width: 1, height: 1e-9)
        XCTAssert(path.isClosed)
        XCTAssertEqual(path.plane, .xy)
        XCTAssertEqual(path.points.count, 3)
        XCTAssertEqual(path.bounds, Bounds(
            min: [-0.5, 0],
            max: [0.5, 0]
        ))
    }

    // MARK: Rounded rect

    func testSimpleRoundedRect() {
        let path = Path.roundedRectangle(width: 1, height: 1, radius: 0.25)
        XCTAssert(path.isClosed)
        XCTAssertEqual(path.points.count, 21)
        XCTAssertEqual(path.bounds, Bounds(
            min: [-0.5, -0.5],
            max: [0.5, 0.5]
        ))
    }

    func testCircularRoundedRect() {
        let path = Path.roundedRectangle(width: 1, height: 1, radius: 0.5)
        XCTAssert(path.isClosed)
        XCTAssertEqual(path.points.count, 17)
        XCTAssertEqual(path.bounds, Bounds(
            min: [-0.5, -0.5],
            max: [0.5, 0.5]
        ))
    }

    func testPortraitRoundedRect() {
        let path = Path.roundedRectangle(width: 1, height: 2, radius: 0.5)
        XCTAssert(path.isClosed)
        XCTAssertEqual(path.points.count, 19)
        XCTAssertEqual(path.bounds, Bounds(
            min: [-0.5, -1],
            max: [0.5, 1]
        ))
    }

    func testLandscapeRoundedRect() {
        let path = Path.roundedRectangle(width: 2, height: 1, radius: 0.5)
        XCTAssert(path.isClosed)
        XCTAssertEqual(path.points.count, 19)
        XCTAssertEqual(path.bounds, Bounds(
            min: [-1, -0.5],
            max: [1, 0.5]
        ))
    }

    func testLowResRoundedRect() {
        let path = Path.roundedRectangle(width: 1, height: 1, radius: 0.25, detail: 1)
        XCTAssert(path.isClosed)
        XCTAssertEqual(path.points.count, 9)
        XCTAssertEqual(path.bounds, Bounds(
            min: [-0.5, -0.5],
            max: [0.5, 0.5]
        ))
    }

    func testZeroDetailRoundedRect() {
        let path = Path.roundedRectangle(width: 1, height: 1, radius: 0.5, detail: 0)
        XCTAssertEqual(path, Path(Path.rectangle(width: 1, height: 1).points.map {
            .curve($0.position)
        }))
    }

    func testZeroRadiusRoundedRect() {
        let path = Path.roundedRectangle(width: 1, height: 1, radius: 0)
        XCTAssertEqual(path, .rectangle(width: 1, height: 1))
    }

    // MARK: extrusionContours

    func testExtrusionAlongZAxis() {
        let contours = Path.circle().extrusionContours(along: .line(.zero, .unitZ))
        XCTAssertEqual(contours, [.circle(), .circle().translated(by: .unitZ)])
    }

    func testExtrusionAlongEmptyPath() {
        let contours = Path.circle().extrusionContours(along: .empty)
        XCTAssertEqual(contours, [])
    }

    func testExtrusionAlongSinglePointPath() {
        let contours = Path.circle().extrusionContours(along: .init([.point(.zero)]))
        XCTAssertEqual(contours, [.circle()])
    }

    func testExtrusionAlongZeroLengthPath() {
        let contours = Path.circle().extrusionContours(along: .line(.zero, .zero))
        XCTAssertEqual(contours, [.circle()])
    }

    func testExtrusionWithMiteredCornerUsesBisectingContour() {
        let contours = Path.square().extrusionContours(along: Path([
            .point(0, 0, 0),
            .point(1, 0, 0),
            .point(1, 1, 0),
        ]), miterLimit: .infinity)

        XCTAssertEqual(contours.count, 4)
        XCTAssertTrue(contours[1].faceNormal.isApproximatelyEqual(to: [sqrt(0.5), sqrt(0.5), 0]))
        XCTAssertTrue(contours[2].faceNormal.isApproximatelyEqual(to: [sqrt(0.5), sqrt(0.5), 0]))
    }

    func testExtrusionWithMiterLimitedCornerUsesBevelContours() {
        let contours = Path.square().extrusionContours(along: Path([
            .point(0, 0, 0),
            .point(1, 0, 0),
            .point(1, 1, 0),
        ]), miterLimit: 1)

        XCTAssertEqual(contours.count, 6)
        XCTAssertTrue(contours[1].faceNormal.isApproximatelyEqual(to: [sqrt(0.75), 0.5, 0]))
        XCTAssertTrue(contours[2].faceNormal.isApproximatelyEqual(to: [sqrt(0.75), 0.5, 0]))
        XCTAssertTrue(contours[3].faceNormal.isApproximatelyEqual(to: [0.5, sqrt(0.75), 0]))
        XCTAssertTrue(contours[4].faceNormal.isApproximatelyEqual(to: [0.5, sqrt(0.75), 0]))
        XCTAssertNotEqual(contours[1].bounds.center, [1, 0, 0])
        XCTAssertNotEqual(contours[3].bounds.center, [1, 0, 0])
        XCTAssertEqual(contours[1].bounds.center.y, 0)
        XCTAssertEqual(contours[3].bounds.center.x, 1)
    }

    func testClosedExtrusionWithMiteredCornersDoublesClosingContour() {
        let contours = Path.square().extrusionContours(along: .square(size: 4), miterLimit: 2)

        XCTAssertEqual(contours.count, 10)
        XCTAssertTrue(contours[0].isApproximatelyEqual(to: contours[1]))
        XCTAssertTrue(contours[2].isApproximatelyEqual(to: contours[3]))
        XCTAssertTrue(contours[4].isApproximatelyEqual(to: contours[5]))
        XCTAssertTrue(contours[6].isApproximatelyEqual(to: contours[7]))
        XCTAssertTrue(contours[8].isApproximatelyEqual(to: contours[9]))
    }

    func testSquareExtrusionWithMiterLimitedCornersPreservesBounds() {
        let shape = Path.square()
        let along = Path.square(size: 2)
        let miterLimited = Bounds(shape.extrusionContours(along: along, miterLimit: 1))
        let mitered = Bounds(shape.extrusionContours(along: along, miterLimit: 2))

        XCTAssertTrue(miterLimited.isApproximatelyEqual(to: mitered))
        XCTAssertTrue(miterLimited.isApproximatelyEqual(to: Bounds([-1.5, -1.5, -0.5], [1.5, 1.5, 0.5])))
    }

    func testSquareExtrusionWithMiterLimitedCornersPreservesInnerHole() {
        let contours = Path.square().extrusionContours(along: .square(size: 2), miterLimit: 1)
        let innerPoints = contours.flatMap(\.points).map(\.position).filter {
            abs($0.x) <= 0.5 + epsilon && abs($0.y) <= 0.5 + epsilon
        }

        XCTAssertTrue(Bounds(innerPoints).isApproximatelyEqual(to: Bounds([-0.5, -0.5, -0.5], [0.5, 0.5, 0.5])))
    }

    func testAcuteExtrusionWithMiterLimitedCornerBevelContoursTouchAtInnerCorner() {
        let contours = Path.square().extrusionContours(along: Path([
            .point(0, 0, 0),
            .point(1, 0, 0),
            .point(0.5, 0, 1),
        ]), miterLimit: 1)
        let sharedPoints = contours[1].points.filter { p0 in
            contours[3].points.contains { $0.position.isApproximatelyEqual(to: p0.position) }
        }

        XCTAssertEqual(Set(sharedPoints.map(\.position)).count, 2)
    }

    func testShallowExtrusionWithMiterLimitedCornerKeepsBevelContoursNearCorner() throws {
        let contours = Path.square(size: 0.2).extrusionContours(along: Path([
            .point(0, 0, 0),
            .point(1, 0, 0),
            .point(2, 0, 0.2),
        ]), miterLimit: 1)

        XCTAssertEqual(contours.count, 6)
        XCTAssertLessThan(contours[1].bounds.center.distance(from: [1, 0, 0]), 0.02)
        XCTAssertLessThan(contours[3].bounds.center.distance(from: [1, 0, 0]), 0.02)
        let distances = contours[1].points.flatMap { p0 in
            contours[3].points.map { $0.position.distance(from: p0.position) }
        }
        XCTAssertGreaterThan(try XCTUnwrap(distances.min()), 0)
        XCTAssertLessThan(try XCTUnwrap(distances.min()), 1e-4)
    }

    func testMiterLimitedCornerDoesNotExtendPastHalfOfShortOutgoingSegment() {
        let along = Path([
            .point(0, 0, 0),
            .point(1, 0, 0),
            .point(0.8, -0.2, 0),
        ])
        let contours = Path.circle().extrusionContours(along: along, miterLimit: 1)
        let incoming = Vector.unitX
        let outgoing = (Vector(0.8, -0.2, 0) - Vector(1, 0, 0)).normalized()
        let incomingAdvance = (Vector(1, 0, 0) - contours[1].bounds.center).dot(incoming)
        let outgoingAdvance = (contours[3].bounds.center - Vector(1, 0, 0)).dot(outgoing)
        let halfOutgoingLength = Vector(0.8, -0.2, 0).distance(from: Vector(1, 0, 0)) / 2

        XCTAssertLessThanOrEqual(outgoingAdvance, halfOutgoingLength + epsilon)
        XCTAssertEqual(incomingAdvance, outgoingAdvance, accuracy: epsilon)
    }

    func testExtrusionWithMiterLimitFallsBackWhenBevelsWouldOverlap() throws {
        #if canImport(CoreText)
        let shape = Path.square(size: 0.1)
        let along = try XCTUnwrap(Path.text("o").first?.subpaths.first)
        let sharpAlong = Path(along.points.map { PathPoint($0.position) })

        func isOnRail(_ position: Vector, _ rail: Path) -> Bool {
            let points = rail.points
            return points.indices.dropLast().contains { index in
                LineSegment(unchecked: points[index].position, points[index + 1].position)
                    .intersects(position)
            }
        }

        for rail in [along, sharpAlong] {
            let contours = shape.extrusionContours(along: rail, miterLimit: 1)
            XCTAssertTrue(contours.allSatisfy { contour in
                isOnRail(contour.bounds.center, rail)
            })
        }
        #endif
    }

    func testSmallTextEExtrusionContoursWithMiterLimitDoNotCollapse() throws {
        #if canImport(CoreText)
        for scale in [0.02, 0.01] {
            let path = try XCTUnwrap(Path.text("e").first).scaled(by: scale)
            for rail in path.subpaths {
                let contours = path.extrusionContours(along: rail, miterLimit: 1)
                let centers = contours.map(\.bounds.center)
                let badPairs = centers.indices.dropFirst().filter {
                    centers[$0].isApproximatelyEqual(to: centers[$0 - 1]) &&
                        !contours[$0].isApproximatelyEqual(to: contours[$0 - 1])
                }

                XCTAssertTrue(badPairs.isEmpty)
            }
        }
        #endif
    }

    func testExtrusionWithDuplicateInitialPoint() {
        let contours = Path.square().extrusionContours(along: Path([
            .point(0, 0, 0),
            .point(0, 0, 0),
            .point(0, 0, 1),
        ]), align: .axis)

        XCTAssertEqual(contours.count, 4)
        XCTAssertEqual(contours[0].bounds.center, .zero)
        XCTAssertEqual(contours[1].bounds.center, .zero)
        XCTAssertEqual(contours.last?.bounds.center, .unitZ)
    }

    func testExtrusionWithDuplicateInteriorPoint() {
        let contours = Path.square().extrusionContours(along: Path([
            .point(0, 0, 0),
            .point(1, 0, 0),
            .point(1, 0, 0),
            .point(1, 0, 1),
        ]))

        XCTAssertEqual(contours.count, 6)
        XCTAssertEqual(contours[1].bounds.center, [1, 0, 0])
        XCTAssertEqual(contours[2].bounds.center, [1, 0, 0])
        XCTAssertEqual(contours.last?.bounds.center, [1, 0, 1])
    }

    func testTwistedExtrudeAlongAlignment() {
        #if canImport(CoreText)
        let detail = 16
        for i in 0 ... 4 {
            let twist = Angle.halfPi * Double(i)
            let contours = Path.square(size: 0.1).extrusionContours(
                along: .text("w")[0].withDetail(detail, forTwist: twist),
                twist: twist
            )
            XCTAssertEqual(contours.first?.bounds, contours.last?.bounds)
            if i == 0 || i == 4 {
                XCTAssertEqual(contours.first, contours.last)
            }
        }
        #endif
    }
}
