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
        let b = Transform(translation: .unitX)
        let c = a * b
        XCTAssertEqual(c.translation, .unitX)
        XCTAssertEqual(c.rotation, r)
    }

    func testTranslationMultipliedByRotation() {
        let r = Rotation(roll: .zero, yaw: .pi / 4, pitch: .zero)
        let a = Transform(translation: .unitX)
        let b = Transform(rotation: r)
        let c = a * b
        XCTAssertEqual(c.translation, [sqrt(2) / 2, 0, sqrt(2) / 2])
        XCTAssertEqual(c.translation, a.translation.rotated(by: r))
        XCTAssertEqual(c.rotation, r)
    }

    func testRotationMultipliedByScale() {
        let r = Rotation(roll: .zero, yaw: .pi / 4, pitch: .zero)
        let a = Transform(rotation: r)
        let b = Transform(scale: [2, 1, 1])
        let c = a * b
        XCTAssertEqual(c.scale, [2, 1, 1]) // scale is unaffected by rotation
        XCTAssertEqual(c.rotation, r)
    }

    func testScaleMultipliedByRotation() {
        let r = Rotation(roll: .zero, yaw: .pi / 4, pitch: .zero)
        let a = Transform(scale: [2, 1, 1])
        let b = Transform(rotation: r)
        let c = a * b
        XCTAssertEqual(c.scale, [2, 1, 1])
        XCTAssertEqual(c.rotation, r)
    }

    func testTranslationMultipliedByScale() {
        let a = Transform(translation: .unitX)
        let b = Transform(scale: [2, 1, 1])
        let c = a * b
        XCTAssertEqual(c.translation, [2, 0, 0])
        XCTAssertEqual(c.scale, [2, 1, 1])
    }

    func testRotationMultipliedByDouble() {
        var r = Rotation(roll: .zero, yaw: .halfPi, pitch: .zero)
        XCTAssertEqual(r.angle, .pi / 2)
        r /= 3
        XCTAssertEqual(r.angle, .pi / 6)
        r *= 2
        XCTAssertEqual(r.angle, .pi / 3)
    }

    // MARK: Vector transform

    func testTransformVector() {
        let v = Vector(1, 1, 1)
        let t = Transform(
            scale: [1, 0.1, 0.1],
            rotation: .roll(.halfPi),
            translation: [0.5, 0, 0]
        )
        XCTAssertEqual(v.transformed(by: t), [0.6, -1.0, 0.1])
    }

    // MARK: Plane transforms

    func testTranslatePlane() {
        let normal = Vector(0.5, 1, 0.5).normalized()
        let position = Vector(10, 5, -3)
        let plane = Plane(unchecked: normal, pointOnPlane: position)
        let offset = Vector(12, 3, 4)
        let expected = Plane(unchecked: normal, pointOnPlane: position + offset)
        XCTAssertEqual(plane.translated(by: offset), expected)
    }

    func testRotatePlane() {
        let normal = Vector(0.5, 1, 0.5).normalized()
        let position = Vector(10, 5, -3)
        let plane = Plane(unchecked: normal, pointOnPlane: position)
        let rotation = Rotation(axis: [12, 3, 4], angle: .radians(0.2))!
        let rotatedNormal = normal.rotated(by: rotation)
        let rotatedPosition = position.rotated(by: rotation)
        let expected = Plane(unchecked: rotatedNormal, pointOnPlane: rotatedPosition)
        XCTAssertEqual(plane.rotated(by: rotation), expected)
    }

    func testScalePlane() {
        let normal = Vector(0.5, 1, 0.5).normalized()
        let position = Vector(10, 5, -3)
        let plane = Plane(unchecked: normal, pointOnPlane: position)
        let scale = Vector(0.5, 3.0, 0.1)
        let expectedNormal = normal.scaled(by: [1 / scale.x, 1 / scale.y, 1 / scale.z]).normalized()
        let expected = Plane(unchecked: expectedNormal, pointOnPlane: position.scaled(by: scale))
        XCTAssertEqual(plane.scaled(by: scale), expected)
    }

    func testScalePlaneUniformly() {
        let normal = Vector(0.5, 1, 0.5).normalized()
        let position = Vector(10, 5, -3)
        let plane = Plane(unchecked: normal, pointOnPlane: position)
        let scale = 0.5
        let expected = Plane(unchecked: normal, pointOnPlane: position * scale)
        XCTAssertEqual(plane.scaled(by: scale), expected)
    }

    func testTransformPlane() throws {
        let path = Path([
            .point(1, 2, 3),
            .point(7, -2, 12),
            .point(-2, 7, 14),
        ])
        let plane = try XCTUnwrap(path.plane)
        let transform = Transform(
            scale: [7, 2.0, 0.3],
            rotation: Rotation(axis: [11, 3, -1], angle: .radians(1.3)),
            translation: [-7, 3, 4.5]
        )
        let expected = try XCTUnwrap(path.transformed(by: transform).plane)
        XCTAssertEqual(plane.transformed(by: transform), expected)
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
            scale: [7, 2.0, 0.3],
            rotation: Rotation(axis: [11, 3, -1], angle: .radians(1.3)),
            translation: [-7, 3, 4.5]
        )
        XCTAssertNil(mesh.transformed(by: transform).boundsIfSet)
    }

    func testBoundsPreservedWhenTransformingMeshWithoutRotation() {
        let mesh = Mesh.cube()
        let transform = Transform(
            scale: [7, 2.0, 0.3],
            rotation: .identity,
            translation: [-7, 3, 4.5]
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
        let transform = Transform(scale: -[-1, 1, 1])
        XCTAssertEqual(bounds.transformed(by: transform), bounds)
    }
}
