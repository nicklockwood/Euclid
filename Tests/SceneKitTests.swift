//
//  SceneKitTests.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 06/09/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

#if canImport(SceneKit)

@testable import Euclid
import SceneKit
import XCTest

class SceneKitTests: XCTestCase {
    func testGeometryImportedWithCorrectDetail() {
        let sphere = SCNSphere(radius: 0.5)
        sphere.segmentCount = 3
        let mesh = Mesh(sphere)
        XCTAssertEqual(mesh?.polygons.count ?? 0, 12)
    }

    func testImportedSTLFileHasFixedNormals() throws {
        let cubeFile = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().appendingPathComponent("Cube.stl")
        let cube = try Mesh(url: cubeFile, ignoringTransforms: false)
        XCTAssert(cube.polygons.allSatisfy { polygon in
            polygon.vertices.allSatisfy { $0.normal == polygon.plane.normal }
        })
    }

    func testExportImportTriangles() throws {
        let cube = Mesh.cube()
        let geometry = try XCTUnwrap(SCNGeometry(
            triangles: cube, materialLookup: nil
        ))
        XCTAssertNotNil(Mesh(geometry, materialLookup: nil))
    }

    @available(OSX 10.12, iOS 10.0, tvOS 10.0, *)
    func testExportImportPolygons() throws {
        let cube = Mesh.cube()
        let geometry = try XCTUnwrap(SCNGeometry(
            polygons: cube, materialLookup: nil
        ))
        XCTAssertNotNil(Mesh(geometry, materialLookup: nil))
    }

    func testSCNBoxIsWatertight() throws {
        for s in [0.2, 0.8, 1, 10] as [CGFloat] {
            let cube = SCNBox(width: s, height: s, length: s, chamferRadius: 0)
            let mesh = try XCTUnwrap(Mesh(cube))
            XCTAssert(mesh.isWatertight)
            XCTAssert(mesh.polygons.areWatertight)
        }
    }

    func testSCNSphereIsWatertight() throws {
        let sphere = SCNSphere(radius: 0.2)
        let mesh = try XCTUnwrap(Mesh(sphere))
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
    }

    func testSCNTextIsWatertight() throws {
        let text = SCNText(string: "Hello", extrusionDepth: 0.2)
        let mesh = try XCTUnwrap(Mesh(text))
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
    }

    func testSCNBoxSubtractedFromSCNBoxCanBeMadeWatertight() throws {
        let box1 = SCNBox(width: 0.2, height: 0.2, length: 0.2, chamferRadius: 0)
        let box2 = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        let mesh = Mesh(box1)!.translated(by: Vector(0, 0, -0.4))
            .subtract(Mesh(box2)!.translated(by: Vector(0, 0.12, -0.3)))
            .makeWatertight()
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
    }
}

#endif
