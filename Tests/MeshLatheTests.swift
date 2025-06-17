//
//  MeshLatheTests.swift
//  Euclid
//
//  Created by Nick Lockwood on 17/06/2025.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

class MeshLatheTests: XCTestCase {
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
        XCTAssertGreaterThan(mesh.volume, 0)
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
        XCTAssertGreaterThan(mesh.volume, 0)
        XCTAssert(mesh.isActuallyConvex)
        XCTAssertFalse(mesh.isKnownConvex) // can't determine this yet

        let mesh2 = Mesh.lathe(path, faces: .frontAndBack)
        XCTAssert(mesh2.isWatertight)
        XCTAssert(mesh2.polygons.areWatertight)
        XCTAssertEqual(mesh2.polygons.count, 96)
        XCTAssertEqual(mesh2.volume, 0, accuracy: epsilon)
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
        XCTAssertEqual(mesh.volume, 0)
        XCTAssertFalse(mesh.isActuallyConvex)
        XCTAssertFalse(mesh.isKnownConvex) // can't determine this yet

        let mesh2 = Mesh.lathe(path, faces: .front)
        XCTAssertFalse(mesh2.isWatertight)
        XCTAssertFalse(mesh2.polygons.areWatertight)
        XCTAssertEqual(mesh2.polygons.count, 32)
        XCTAssertNotEqual(mesh2.volume, 0) // should be zero, but not reliable for non-watertight shape
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
        XCTAssertEqual(mesh.volume, 0, accuracy: epsilon)
        XCTAssertFalse(mesh.isActuallyConvex)
        XCTAssertFalse(mesh.isKnownConvex) // can't determine this yet

        let mesh2 = Mesh.lathe(path, faces: .front)
        XCTAssertFalse(mesh2.isWatertight)
        XCTAssertFalse(mesh2.polygons.areWatertight)
        XCTAssertEqual(mesh2.polygons.count, 32)
        XCTAssertNotEqual(mesh2.volume, 0) // should be zero, but not reliable for non-watertight shape
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
        XCTAssertEqual(mesh.volume, 0)
        XCTAssertFalse(mesh.isActuallyConvex)
        XCTAssertFalse(mesh.isKnownConvex) // can't determine this yet

        let mesh2 = Mesh.lathe(path, faces: .front)
        XCTAssertFalse(mesh2.isWatertight)
        XCTAssertFalse(mesh2.polygons.areWatertight)
        XCTAssertEqual(mesh2.polygons.count, 16)
        XCTAssertNotEqual(mesh2.volume, 0) // should be zero, but not reliable for non-watertight shape

        let mesh3 = Mesh.lathe(path, faces: .frontAndBack)
        XCTAssert(mesh3.isWatertight)
        XCTAssert(mesh3.polygons.areWatertight)
        XCTAssertEqual(mesh3.polygons.count, 32)
        XCTAssertEqual(mesh3.volume, 0)
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
        XCTAssertGreaterThan(mesh.volume, 0)
        XCTAssertFalse(mesh.isActuallyConvex)
        XCTAssertFalse(mesh.isKnownConvex)
    }
}
