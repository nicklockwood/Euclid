//
//  DirectionTests.swift
//  EuclidTests
//
//  Created by Ioannis Kaliakatsos on 02.12.2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

private let epsilon = Double.ulpOfOne.squareRoot()

class DirectionTests: XCTestCase {
    func testNormedComponents() {
        let direction = Direction(x: 1, y: 2, z: 3)
        let componentNorm = sqrt(14)
        XCTAssertEqual(1 / componentNorm, direction.x, accuracy: epsilon)
        XCTAssertEqual(2 / componentNorm, direction.y, accuracy: epsilon)
        XCTAssertEqual(3 / componentNorm, direction.z, accuracy: epsilon)
    }

    func testZeroDirection() {
        let direction = Direction.zero
        XCTAssertEqual(0, direction.x)
        XCTAssertEqual(0, direction.y)
        XCTAssertEqual(0, direction.z)
    }

    func testNormedAdditionOnXYPlane() {
        let direction1 = Direction(x: 1)
        let direction2 = Direction(y: 1)
        let direction = direction1 + direction2
        XCTAssertEqual(sqrt(2) / 2, direction.x, accuracy: epsilon)
        XCTAssertEqual(sqrt(2) / 2, direction.y, accuracy: epsilon)
        XCTAssertEqual(0, direction.z)
    }

    func testNormedSubtractionOnXYPlane() {
        let direction1 = Direction(x: 1)
        let direction2 = Direction(y: 1)
        let direction = direction1 - direction2
        XCTAssertEqual(sqrt(2) / 2, direction.x, accuracy: epsilon)
        XCTAssertEqual(-sqrt(2) / 2, direction.y, accuracy: epsilon)
        XCTAssertEqual(0, direction.z)
    }

    func testNormedAdditionOnXZPlane() {
        let direction1 = Direction(x: 1)
        let direction2 = Direction(z: 1)
        let direction = direction1 + direction2
        XCTAssertEqual(sqrt(2) / 2, direction.x, accuracy: epsilon)
        XCTAssertEqual(0, direction.y)
        XCTAssertEqual(sqrt(2) / 2, direction.z, accuracy: epsilon)
    }

    func testNormedSubtractionOnXZPlane() {
        let direction1 = Direction(x: 1)
        let direction2 = Direction(z: 1)
        let direction = direction1 - direction2
        XCTAssertEqual(sqrt(2) / 2, direction.x, accuracy: epsilon)
        XCTAssertEqual(0, direction.y)
        XCTAssertEqual(-sqrt(2) / 2, direction.z, accuracy: epsilon)
    }

    func testNormedAdditionOnYZPlane() {
        let direction1 = Direction(y: 1)
        let direction2 = Direction(z: 1)
        let direction = direction1 + direction2
        XCTAssertEqual(0, direction.x)
        XCTAssertEqual(sqrt(2) / 2, direction.y, accuracy: epsilon)
        XCTAssertEqual(sqrt(2) / 2, direction.z, accuracy: epsilon)
    }

    func testNormedSubtractionOnYZPlane() {
        let direction1 = Direction(y: 1)
        let direction2 = Direction(z: 1)
        let direction = direction1 - direction2
        XCTAssertEqual(0, direction.x)
        XCTAssertEqual(sqrt(2) / 2, direction.y, accuracy: epsilon)
        XCTAssertEqual(-sqrt(2) / 2, direction.z, accuracy: epsilon)
    }

    func testNormedAddition() {
        let direction1 = Direction(x: 1, y: 2, z: 3)
        let direction2 = Direction(x: 5, y: 6, z: 7)
        let direction = direction1 + direction2
        XCTAssertEqual(0.37497702770252406, direction.x, accuracy: epsilon)
        XCTAssertEqual(0.55773354233061923, direction.y, accuracy: epsilon)
        XCTAssertEqual(0.74049005695871428, direction.z, accuracy: epsilon)
    }

    func testDotProductObliqueAngle() {
        let direction1 = Direction.x
        let direction2 = Direction(x: 1, y: 1)
        let dotproduct = direction1.dot(direction2)
        XCTAssertEqual(sqrt(2) / 2, dotproduct, accuracy: epsilon)
    }

    func testDotProductObtuseAngle() {
        let direction1 = Direction.x
        let direction2 = Direction(x: -1, y: 1)
        let dotproduct = direction1.dot(direction2)
        XCTAssertEqual(-sqrt(2) / 2, dotproduct, accuracy: epsilon)
    }

    func testParallelDirections() {
        let direction1 = Direction(x: -1, y: 1, z: 3)
        let direction2 = Direction(x: -1, y: 1, z: 3)
        XCTAssertTrue(direction1.isParallel(to: direction2))
        XCTAssertFalse(direction1.isAntiparallel(to: direction2))
        XCTAssertTrue(direction1.isColinear(to: direction2))
        XCTAssertFalse(direction1.isNormal(to: direction2))
    }

    func testAntiparallelDirections() {
        let direction1 = Direction(x: -1, y: 2, z: 3)
        let direction2 = Direction(x: 1, y: -2, z: -3)
        XCTAssertFalse(direction1.isParallel(to: direction2))
        XCTAssertTrue(direction1.isAntiparallel(to: direction2))
        XCTAssertTrue(direction1.isColinear(to: direction2))
        XCTAssertFalse(direction1.isNormal(to: direction2))
    }

    func testNormalDirections() {
        let direction1 = Direction.x
        let direction2 = Direction.y
        XCTAssertFalse(direction1.isParallel(to: direction2))
        XCTAssertFalse(direction1.isAntiparallel(to: direction2))
        XCTAssertFalse(direction1.isColinear(to: direction2))
        XCTAssertTrue(direction1.isNormal(to: direction2))
    }

    func testGeneralDirections() {
        let direction1 = Direction(x: -1, y: 2, z: 3)
        let direction2 = Direction(x: 5, y: -9, z: 1)
        XCTAssertFalse(direction1.isParallel(to: direction2))
        XCTAssertFalse(direction1.isAntiparallel(to: direction2))
        XCTAssertFalse(direction1.isColinear(to: direction2))
        XCTAssertFalse(direction1.isNormal(to: direction2))
    }

    func testAngleWithOtherDirection45Degrees() {
        let direction1 = Direction(x: 1, y: 1)
        let direction2 = Direction.y
        let angle = direction1.angle(with: direction2)
        XCTAssertEqual(45, angle.degrees, accuracy: epsilon)
    }

    func testAngleWithOtherDirection45DegreesOppositeSide() {
        let direction1 = Direction(x: 1, y: -1)
        let direction2 = Direction.y
        let angle = direction1.angle(with: direction2)
        XCTAssertEqual(135, angle.degrees, accuracy: epsilon)
    }

    func testAngleWithOtherDirection0Degrees() {
        let direction1 = Direction.y
        let direction2 = Direction.y
        let angle = direction1.angle(with: direction2)
        XCTAssertEqual(0, angle.degrees, accuracy: epsilon)
    }

    func testAngleWithOtherDirection90Degrees() {
        let direction1 = Direction.x
        let direction2 = Direction.y
        let angle = direction1.angle(with: direction2)
        XCTAssertEqual(90, angle.degrees, accuracy: epsilon)
    }

    func testCrossProductZAxis() {
        XCTAssertEqual(Direction.z, Direction.x.cross(.y))
    }

    func testCrossProductNegativeZAxis() {
        XCTAssertEqual(Direction.z.opposite, Direction.y.cross(.x))
    }

    func testCrossProductXAxis() {
        XCTAssertEqual(Direction.x, Direction.y.cross(.z))
    }

    func testCrossProductNegativeXAxis() {
        XCTAssertEqual(Direction.x.opposite, Direction.z.cross(.y))
    }

    func testCrossProductGeneral() {
        let direction1 = Direction(x: 3, y: -3, z: 1)
        let direction2 = Direction(x: 4, y: 9, z: 2)
        let normal = direction1.cross(direction2)
        let componentNorm = sqrt(15.0 * 15.0 + 2.0 * 2.0 + 39.0 * 39.0)
        XCTAssertEqual(-15.0 / componentNorm, normal.x, accuracy: epsilon)
        XCTAssertEqual(-2.0 / componentNorm, normal.y, accuracy: epsilon)
        XCTAssertEqual(39.0 / componentNorm, normal.z, accuracy: epsilon)
    }

    func testRotateXAxis() {
        let rotated = Direction.x.rotated(around: .z, by: Angle(degrees: 30))
        XCTAssertEqual(Direction(x: sqrt(3), y: 1), rotated)
    }

    func testRotateYAxis() {
        let rotated = Direction.y.rotated(around: .x, by: Angle(degrees: 60))
        XCTAssertEqual(Direction(y: 1, z: sqrt(3)), rotated)
    }

    func testRotateAroundNonNormalDirection() {
        let direction = Direction(x: 1, z: 1)
        let rotated = direction.rotated(around: .z, by: Angle(degrees: 135))
        XCTAssertEqual(Direction(x: -1 / 2, y: 1 / 2, z: 1 / sqrt(2)), rotated)
    }
}
