//
//  TransformTests.swift
//  GeometryScriptTests
//
//  Created by Nick Lockwood on 17/10/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

class TransformTests: XCTestCase {
    // MARK: Transform multiplication

    func testRotationMultipliedByTranslation() {
        let r = Rotation(roll: .zero, yaw: .pi / 4, pitch: .zero)
        let a = Transform(rotation: r)
        let b = Transform(offset: .unitX)
        let c = a * b
        XCTAssertEqual(c.offset, .unitX)
        XCTAssertEqual(c.rotation, r)
    }

    func testTranslationMultipliedByRotation() {
        let r = Rotation(roll: .zero, yaw: .pi / 4, pitch: .zero)
        let a = Transform(offset: .unitX)
        let b = Transform(rotation: r)
        let c = a * b
        XCTAssertEqual(c.offset, Vector(sqrt(2) / 2, 0, sqrt(2) / 2))
        XCTAssertEqual(c.offset, a.offset.rotated(by: r))
        XCTAssertEqual(c.rotation, r)
    }

    func testRotationMultipliedByScale() {
        let r = Rotation(roll: .zero, yaw: .pi / 4, pitch: .zero)
        let a = Transform(rotation: r)
        let b = Transform(scale: Vector(2, 1, 1))
        let c = a * b
        XCTAssertEqual(c.scale, Vector(2, 1, 1)) // scale is unaffected by rotation
        XCTAssertEqual(c.rotation, r)
    }

    func testScaleMultipliedByRotation() {
        let r = Rotation(roll: .zero, yaw: .pi / 4, pitch: .zero)
        let a = Transform(scale: Vector(2, 1, 1))
        let b = Transform(rotation: r)
        let c = a * b
        XCTAssertEqual(c.scale, Vector(2, 1, 1))
        XCTAssertEqual(c.rotation, r)
    }

    func testTranslationMultipliedByScale() {
        let a = Transform(offset: .unitX)
        let b = Transform(scale: Vector(2, 1, 1))
        let c = a * b
        XCTAssertEqual(c.offset, Vector(2, 0, 0))
        XCTAssertEqual(c.scale, Vector(2, 1, 1))
    }

    func testRotationMultipliedByDouble() {
        var r = Rotation(roll: .zero, yaw: .halfPi, pitch: .zero)
        XCTAssertEqual(r.angle.radians, .pi / 2, accuracy: epsilon)
        r /= 3
        XCTAssertEqual(r.angle.radians, .pi / 6, accuracy: epsilon)
        r *= 2
        XCTAssertEqual(r.angle.radians, .pi / 3, accuracy: epsilon)
    }

    // MARK: Vector transform

    func testTransformVector() {
        let v = Vector(1, 1, 1)
        let t = Transform(
            offset: Vector(0.5, 0, 0),
            rotation: .roll(.halfPi),
            scale: Vector(1, 0.1, 0.1)
        )
        XCTAssertEqual(v.transformed(by: t), Vector(0.6, -1.0, 0.1))
    }

    // MARK: Plane transforms

    func testTranslatePlane() {
        let normal = Vector(0.5, 1, 0.5).normalized()
        let position = Vector(10, 5, -3)
        let plane = Plane(unchecked: normal, pointOnPlane: position)
        let offset = Vector(12, 3, 4)
        let expected = Plane(unchecked: normal, pointOnPlane: position + offset)
        XCTAssert(plane.translated(by: offset).isEqual(to: expected))
    }

    func testRotatePlane() {
        let normal = Vector(0.5, 1, 0.5).normalized()
        let position = Vector(10, 5, -3)
        let plane = Plane(unchecked: normal, pointOnPlane: position)
        let rotation = Rotation(axis: Vector(12, 3, 4), angle: .radians(0.2))!
        let rotatedNormal = normal.rotated(by: rotation)
        let rotatedPosition = position.rotated(by: rotation)
        let expected = Plane(unchecked: rotatedNormal, pointOnPlane: rotatedPosition)
        XCTAssert(plane.rotated(by: rotation).isEqual(to: expected))
    }

    func testScalePlane() {
        let normal = Vector(0.5, 1, 0.5).normalized()
        let position = Vector(10, 5, -3)
        let plane = Plane(unchecked: normal, pointOnPlane: position)
        let scale = Vector(0.5, 3.0, 0.1)
        let expectedNormal = normal.scaled(by: Vector(1 / scale.x, 1 / scale.y, 1 / scale.z)).normalized()
        let expected = Plane(unchecked: expectedNormal, pointOnPlane: position.scaled(by: scale))
        XCTAssert(plane.scaled(by: scale).isEqual(to: expected))
    }

    func testScalePlaneUniformly() {
        let normal = Vector(0.5, 1, 0.5).normalized()
        let position = Vector(10, 5, -3)
        let plane = Plane(unchecked: normal, pointOnPlane: position)
        let scale = 0.5
        let expected = Plane(unchecked: normal, pointOnPlane: position * scale)
        XCTAssert(plane.scaled(by: scale).isEqual(to: expected))
    }

    func testTransformPlane() throws {
        let path = Path([
            .point(1, 2, 3),
            .point(7, -2, 12),
            .point(-2, 7, 14),
        ])
        let plane = try XCTUnwrap(path.plane)
        let transform = Transform(
            offset: Vector(-7, 3, 4.5),
            rotation: Rotation(axis: Vector(11, 3, -1), angle: .radians(1.3))!,
            scale: Vector(7, 2.0, 0.3)
        )
        let expected = try XCTUnwrap(path.transformed(by: transform).plane)
        XCTAssert(plane.transformed(by: transform).isEqual(to: expected))
    }

    // MARK: Path transforms

    func testPathScaleZero() {
        let path = Path([
            .point(1, 2, 3),
            .point(7, -2, 12),
            .point(-2, 7, 14),
        ])
        let zeroPath = path.scaled(by: .zero)
        XCTAssertFalse(zeroPath.edgeVertices.isEmpty)
    }

    // MARK: Mesh transforms

    func testBoundsNotPreservedWhenMeshRotated() {
        let mesh = Mesh.cube()
        let transform = Transform(
            offset: Vector(-7, 3, 4.5),
            rotation: Rotation(axis: Vector(11, 3, -1), angle: .radians(1.3))!,
            scale: Vector(7, 2.0, 0.3)
        )
        XCTAssertNil(mesh.transformed(by: transform).boundsIfSet)
    }

    func testBoundsPreservedWhenTransformingMeshWithoutRotation() {
        let mesh = Mesh.cube()
        let transform = Transform(
            offset: Vector(-7, 3, 4.5),
            rotation: .identity,
            scale: Vector(7, 2.0, 0.3)
        )
        XCTAssertNotNil(mesh.transformed(by: transform).boundsIfSet)
    }

    // MARK: Bounds transforms

    func testBoundsInvertedScale() {
        let bounds = Bounds(min: -.one, max: .one)
        let transform = Transform(scale: -.one)
        XCTAssertEqual(bounds.transformed(by: transform), bounds)
    }

    func testBoundsInvertedScale2() {
        let bounds = Bounds(min: -.one, max: .one)
        let transform = Transform(scale: -Vector(-1, 1, 1))
        XCTAssertEqual(bounds.transformed(by: transform), bounds)
    }
}
