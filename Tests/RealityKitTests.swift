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

@available(macOS 15.0, iOS 18.0, tvOS 26.0, *)
final class RealityKitTests: XCTestCase {
    func testConvertQuadsToFromMeshDescriptor() {
        let cube = Mesh.cube(size: 1)
        let meshDescriptor = MeshDescriptor(quads: cube)
        XCTAssertEqual(meshDescriptor.positions.count, 24)
        XCTAssertEqual(meshDescriptor.normals?.count, 24)
        XCTAssertEqual(meshDescriptor.textureCoordinates?.count, 24)
        let result = Mesh(meshDescriptor)
        XCTAssertTrue(result.isWatertight)
        XCTAssertTrue(result.isActuallyConvex)
        XCTAssertEqual(result.polygons.count, 6)
        XCTAssertEqual(cube, result)
    }

    func testConvertTrianglesToFromMeshDescriptor() {
        let cube = Mesh.cube(size: 1).triangulate()
        let meshDescriptor = MeshDescriptor(quads: cube)
        XCTAssertEqual(meshDescriptor.positions.count, 24)
        XCTAssertEqual(meshDescriptor.normals?.count, 24)
        XCTAssertEqual(meshDescriptor.textureCoordinates?.count, 24)
        let result = Mesh(meshDescriptor)
        XCTAssertTrue(result.isWatertight)
        XCTAssertTrue(result.isActuallyConvex)
        XCTAssertEqual(result.polygons.count, 12)
        XCTAssertEqual(cube, result)
    }

    func testConvertQuadsFromTransformedMeshDescriptor() {
        var transforms = [
            Transform(
                rotation: .init(
                    axis: .init(size: 0.5773502691896258),
                    angle: .radians(2.7805734991561257)
                ),
                translation: .init(size: 400)
            ),
        ]

        for _ in 0 ..< 10 {
            transforms.append(.random())
        }

        for transform in transforms {
            let cube = Mesh.cube(size: .random(in: 0.00001 ... 100000)).transformed(by: transform)
            let meshDescriptor = MeshDescriptor(quads: cube)
            XCTAssertEqual(meshDescriptor.positions.count, 24)
            XCTAssertEqual(meshDescriptor.normals?.count, 24)
            XCTAssertEqual(meshDescriptor.textureCoordinates?.count, 24)
            let result = Mesh(meshDescriptor)
            XCTAssertTrue(result.isWatertight)
            let quads = result.polygons.filter { $0.vertices.count == 4 }.count
            let triangles = result.polygons.filter { $0.vertices.count == 3 }.count
            XCTAssertEqual(quads + triangles, result.polygons.count)
            XCTAssertEqual(quads * 2 + triangles, 12)
        }
    }

    func testConvertFromTransformedMeshDescriptor() {
        var transforms = [Euclid.Transform]()
        for _ in 0 ..< 10 {
            transforms.append(.random())
        }

        for transform in transforms {
            let cube = Mesh.cube(size: .random(in: 0.00001 ... 100000)).triangulate().transformed(by: transform)
            let meshDescriptor = MeshDescriptor(quads: cube)
            XCTAssertEqual(meshDescriptor.positions.count, 24)
            XCTAssertEqual(meshDescriptor.normals?.count, 24)
            XCTAssertEqual(meshDescriptor.textureCoordinates?.count, 24)
            let result = Mesh(meshDescriptor)
            XCTAssertTrue(result.isWatertight)
            XCTAssertEqual(result.polygons.count, 12)
        }
    }

    func testConvertToFromModelEntity() throws {
        let cube = Mesh.cube(size: 1).triangulate()
        let modelEntity = try ModelEntity(cube)
        let contents = try XCTUnwrap(modelEntity.model).mesh.contents
        let instances = contents.instances.compactMap { contents.models[$0.model] }
        let part = try XCTUnwrap(instances.first?.parts.map { $0 }.first)
        XCTAssertEqual(part.positions.count, 24)
        XCTAssertEqual(part.normals?.count, 24)
        XCTAssertEqual(part.textureCoordinates?.count, 24)
        let result = Mesh(modelEntity)
        XCTAssertTrue(result.isWatertight)
        XCTAssertTrue(result.isActuallyConvex)
        XCTAssertEqual(result.polygons.count, 12)
        XCTAssertEqual(cube, result.replacing(result.materials[0], with: nil))
    }
}

#endif
