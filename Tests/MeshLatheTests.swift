//
//  MeshLatheTests.swift
//  Euclid
//
//  Created by Nick Lockwood on 17/06/2025.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

final class MeshLatheTests: XCTestCase {
    func testClosedPathTouchingOrigin() {
        let path = Path([
            .point(0, 0),
            .point(1, 0),
            .point(1, 1),
            .point(0, 1),
            .point(0, 0),
        ])

        let mesh = Mesh.lathe(path)
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
        XCTAssertEqual(mesh.polygons.count, 48)
        XCTAssertGreaterThan(mesh.signedVolume, 0)
        XCTAssert(mesh.isActuallyConvex)
        XCTAssertFalse(mesh.isKnownConvex) // can't determine this yet
    }

    func testOpenPathTouchingOriginAtBothEnds() {
        let path = Path([
            .point(0, 0),
            .point(1, 0),
            .point(1, 1),
            .point(0, 1),
        ])

        let mesh = Mesh.lathe(path)
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
        XCTAssertEqual(mesh.polygons.count, 48)
        XCTAssertGreaterThan(mesh.signedVolume, 0)
        XCTAssert(mesh.isActuallyConvex)
        XCTAssertFalse(mesh.isKnownConvex) // can't determine this yet

        let mesh2 = Mesh.lathe(path, faces: .frontAndBack)
        XCTAssert(mesh2.isWatertight)
        XCTAssert(mesh2.polygons.areWatertight)
        XCTAssertEqual(mesh2.polygons.count, 96)
        XCTAssertEqual(mesh2.signedVolume, 0)
        XCTAssertFalse(mesh2.isActuallyConvex)
        XCTAssertFalse(mesh2.isKnownConvex) // can't determine this yet
    }

    func testOpenPathTouchingOriginAtStart() {
        let path = Path([
            .point(0, 0),
            .point(1, 0),
            .point(1, 1),
        ])

        let mesh = Mesh.lathe(path)
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
        XCTAssertEqual(mesh.polygons.count, 64)
        XCTAssertEqual(mesh.signedVolume, 0)
        XCTAssertFalse(mesh.isActuallyConvex)
        XCTAssertFalse(mesh.isKnownConvex) // can't determine this yet

        let mesh2 = Mesh.lathe(path, faces: .front)
        XCTAssertFalse(mesh2.isWatertight)
        XCTAssertFalse(mesh2.polygons.areWatertight)
        XCTAssertEqual(mesh2.polygons.count, 32)
        XCTAssertNotEqual(mesh2.signedVolume, 0) // should be zero, but not reliable for non-watertight shape
    }

    func testOpenPathTouchingOriginAtEnd() {
        let path = Path([
            .point(1, 0),
            .point(1, 1),
            .point(0, 1),
        ])

        let mesh = Mesh.lathe(path)
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
        XCTAssertEqual(mesh.polygons.count, 64)
        XCTAssertEqual(mesh.signedVolume, 0)
        XCTAssertFalse(mesh.isActuallyConvex)
        XCTAssertFalse(mesh.isKnownConvex) // can't determine this yet

        let mesh2 = Mesh.lathe(path, faces: .front)
        XCTAssertFalse(mesh2.isWatertight)
        XCTAssertFalse(mesh2.polygons.areWatertight)
        XCTAssertEqual(mesh2.polygons.count, 32)
        XCTAssertNotEqual(mesh2.signedVolume, 0) // should be zero, but not reliable for non-watertight shape
    }

    func testOpenPathNotTouchingOrigin() {
        let path = Path([
            .point(1, 0),
            .point(1, 1),
        ])

        let mesh = Mesh.lathe(path)
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
        XCTAssertEqual(mesh.polygons.count, 32)
        XCTAssertEqual(mesh.signedVolume, 0)
        XCTAssertFalse(mesh.isActuallyConvex)
        XCTAssertFalse(mesh.isKnownConvex) // can't determine this yet

        let mesh2 = Mesh.lathe(path, faces: .front)
        XCTAssertFalse(mesh2.isWatertight)
        XCTAssertFalse(mesh2.polygons.areWatertight)
        XCTAssertEqual(mesh2.polygons.count, 16)
        XCTAssertNotEqual(mesh2.signedVolume, 0) // should be zero, but not reliable for non-watertight shape

        let mesh3 = Mesh.lathe(path, faces: .frontAndBack)
        XCTAssert(mesh3.isWatertight)
        XCTAssert(mesh3.polygons.areWatertight)
        XCTAssertEqual(mesh3.polygons.count, 32)
        XCTAssertEqual(mesh3.signedVolume, 0)
    }

    func testSelfIntersectingPath() {
        let path = Path([
            .point(0, 0),
            .point(1, 1),
            .point(1, 0),
            .point(0, 1),
        ])

        let mesh = Mesh.lathe(path)
        XCTAssert(mesh.isWatertight) // should be false, ideally
        XCTAssert(mesh.polygons.areWatertight) // should be false, ideally
        XCTAssertEqual(mesh.polygons.count, 48)
        XCTAssertGreaterThan(mesh.signedVolume, 0)
        XCTAssertFalse(mesh.isActuallyConvex)
        XCTAssertFalse(mesh.isKnownConvex)
    }

    func testLatheCompoundPathUsesEvenOddRule() {
        let outer = Path([
            .point(1, 0),
            .point(3, 0),
            .point(3, 10),
            .point(1, 10),
            .point(1, 0),
        ])
        let inner = Path([
            .point(1.5, 2),
            .point(2, 2),
            .point(2, 8),
            .point(1.5, 8),
            .point(1.5, 2),
        ])
        let mesh = Mesh.lathe(Path(subpaths: [outer, inner]), slices: 8)
        let submeshes = mesh.submeshes

        XCTAssertEqual(
            mesh.polygons.count,
            Mesh.lathe(outer, slices: 8).polygons.count +
                Mesh.lathe(inner, slices: 8).polygons.count
        )
        XCTAssertEqual(submeshes.count, 2)
        XCTAssertEqual(submeshes.filter { $0.signedVolume < 0 }.count, 1)
        XCTAssertTrue(mesh.isWatertight)
        XCTAssertTrue(mesh.polygons.areWatertight)
    }

    func testLatheOverlappingCompoundPathUsesEvenOddRule() {
        let first = Path([
            .point(1, 0), .point(3, 0), .point(3, 4), .point(1, 4), .point(1, 0),
        ])
        let second = Path([
            .point(2, 0), .point(4, 0), .point(4, 4), .point(2, 4), .point(2, 0),
        ])
        let mesh = Mesh.lathe(Path(subpaths: [first, second]), slices: 8)
        let submeshes = mesh.submeshes

        XCTAssertEqual(mesh.polygons.count, 64)
        XCTAssertEqual(submeshes.count, 2)
        XCTAssertTrue(submeshes.allSatisfy { $0.signedVolume > 0 })
        XCTAssertTrue(mesh.isWatertight)
        XCTAssertTrue(mesh.polygons.areWatertight)
    }

    func testLatheMatchesCircularExtrusion() {
        let outer = Path([
            .point(1, -5), .point(3, -5), .point(3, 5), .point(1, 5), .point(1, -5),
        ])
        let inner = Path([
            .point(1.5, -3), .point(2.5, -3), .point(2.5, 3), .point(1.5, 3), .point(1.5, -3),
        ])
        let profile = Path(subpaths: [outer, inner])
        let lathed = Mesh.lathe(profile, slices: 8)
        let rail = Path.circle(radius: 2, segments: 8).rotated(by: .pitch(.halfPi))
        // Compensate for the circular extrusion's polygon miter so its radial edges align with the lathe.
        let scale = cos(Double.pi / 8)
        let crossSection = profile.translated(by: [-2, 0]).scaled(by: [scale, 1])
        let extruded = Mesh.extrude(crossSection, along: rail)

        XCTAssertEqual(lathed.bounds, extruded.bounds)
        XCTAssertEqual(lathed.surfaceArea, extruded.surfaceArea, accuracy: 1e-6)
        XCTAssertEqual(lathed.signedVolume, extruded.signedVolume, accuracy: 1e-6)
        XCTAssertEqual(lathed.polygons.count, extruded.polygons.count)
        XCTAssertEqual(
            lathed.submeshes.map(\.signedVolume.sign),
            extruded.submeshes.map(\.signedVolume.sign)
        )
    }
}
