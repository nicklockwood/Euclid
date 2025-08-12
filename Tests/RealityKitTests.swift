//
//  RealityKitTests.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 19/12/2023.
//  Copyright © 2023 Nick Lockwood. All rights reserved.
//

#if canImport(RealityKit)

@testable import Euclid
import RealityKit
import XCTest

class RealityKitTests: XCTestCase {
    func testConvertQuadsToFromMeshDescriptor() {
        guard #available(macOS 15.0, iOS 18.0, tvOS 26.0, *) else { return }
        let cube = Mesh.cube(size: 1)
        let meshDescriptor = MeshDescriptor(quads: cube)
        XCTAssertEqual(meshDescriptor.positions.count, 24)
        XCTAssertEqual(meshDescriptor.normals?.count, 24)
        XCTAssertEqual(meshDescriptor.textureCoordinates?.count, 24)
        let result = Mesh(meshDescriptor)
        XCTAssertEqual(result.polygons.count, 6)
        XCTAssertEqual(cube, result)
    }

    func testConvertTrianglesToFromMeshDescriptor() {
        guard #available(macOS 15.0, iOS 18.0, tvOS 26.0, *) else { return }
        let cube = Mesh.cube(size: 1).triangulate()
        let meshDescriptor = MeshDescriptor(quads: cube)
        XCTAssertEqual(meshDescriptor.positions.count, 24)
        XCTAssertEqual(meshDescriptor.normals?.count, 24)
        XCTAssertEqual(meshDescriptor.textureCoordinates?.count, 24)
        let result = Mesh(meshDescriptor)
        XCTAssertEqual(result.polygons.count, 12)
        XCTAssertEqual(cube, result)
    }

    func testConvertToFromModelEntity() throws {
        guard #available(macOS 15.0, iOS 18.0, tvOS 26.0, *) else { return }
        let cube = Mesh.cube(size: 1).triangulate()
        let modelEntity = try ModelEntity(cube)
        let contents = try XCTUnwrap(modelEntity.model).mesh.contents
        let instances = contents.instances.compactMap { contents.models[$0.model] }
        let part = try XCTUnwrap(instances.first?.parts.map { $0 }.first)
        XCTAssertEqual(part.positions.count, 24)
        XCTAssertEqual(part.normals?.count, 24)
        XCTAssertEqual(part.textureCoordinates?.count, 24)
        let result = Mesh(modelEntity)
        XCTAssertEqual(result.polygons.count, 12)
        XCTAssertEqual(cube, result.replacing(result.materials[0], with: nil))
    }
}

#endif
