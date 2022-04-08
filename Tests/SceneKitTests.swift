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
}

#endif
