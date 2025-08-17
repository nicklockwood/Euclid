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
    // MARK: Import

    func testGeometryImportedWithCorrectDetail() {
        let sphere = SCNSphere(radius: 0.5)
        sphere.segmentCount = 3
        let mesh = Mesh(sphere)
        XCTAssertEqual(mesh?.polygons.count ?? 0, 12)
    }

    func testImportedSTLFileHasFixedNormals() throws {
        if #available(macOS 13, *) { // workaround for macOS 12 bug
            let cubeFile = URL(fileURLWithPath: #file)
                .deletingLastPathComponent().appendingPathComponent("Cube.stl")
            let cube = try Mesh(url: cubeFile, ignoringTransforms: false)
            XCTAssert(cube.polygons.allSatisfy { polygon in
                polygon.vertices.allSatisfy { $0.normal == polygon.plane.normal }
            })
        }
    }

    func testExportImportTriangles() throws {
        let cube = Mesh.cube().triangulate()
        let geometry = try XCTUnwrap(SCNGeometry(triangles: cube))
        let result = try XCTUnwrap(Mesh(geometry))
        XCTAssertTrue(result.isWatertight)
        XCTAssertTrue(result.isActuallyConvex)
        XCTAssertEqual(result.polygons.count, 12)
    }

    func testExportImportPolygons() throws {
        let cube = Mesh.cube()
        let geometry = try XCTUnwrap(SCNGeometry(polygons: cube))
        let result = try XCTUnwrap(Mesh(geometry))
        XCTAssertTrue(result.isWatertight)
        XCTAssertTrue(result.isActuallyConvex)
        XCTAssertEqual(result.polygons.count, 6)
    }

    func testExportImportTransformedPolygons() throws {
        var transforms = [Transform]()
        for _ in 0 ..< 10 {
            transforms.append(.random())
        }

        for transform in transforms {
            let cube = Mesh.cube(size: .random(in: 0.00001 ... 100000)).transformed(by: transform)
            let geometry = SCNGeometry(polygons: cube)
            let result = try XCTUnwrap(Mesh(geometry))
            XCTAssertTrue(result.isWatertight)
            let quads = result.polygons.filter { $0.vertices.count == 4 }.count
            let triangles = result.polygons.filter { $0.vertices.count == 3 }.count
            XCTAssertEqual(quads + triangles, result.polygons.count)
            XCTAssertEqual(quads * 2 + triangles, 12)
        }
    }

    func testSCNBoxIsWatertight() throws {
        for s in [0.01, 0.1, 0.2, 0.8, 1, 10] as [CGFloat] {
            let cube = SCNBox(width: s, height: s, length: s, chamferRadius: 0)
            let mesh = try XCTUnwrap(Mesh(cube))
            XCTAssert(mesh.isWatertight)
            XCTAssert(mesh.polygons.areWatertight)
        }
    }

    func testSCNCylinderIsWatertight() throws {
        for s in [0.2, 0.8, 3, 5, 10] as [CGFloat] {
            for r in [0.1, 0.2, 0.8, 3, 5, 10] as [CGFloat] {
                let cylinder = SCNCylinder(radius: r, height: s)
                let mesh = try XCTUnwrap(Mesh(cylinder))
                XCTAssert(mesh.isWatertight)
                XCTAssert(mesh.polygons.areWatertight)
            }
        }
    }

    func testSCNTubeIsWatertight() throws {
        for r in [0.1, 0.2, 0.8, 3, 5, 10] as [CGFloat] {
            for r2 in [0.001, 0.01, 0.1, 0.2] as [CGFloat] {
                let cylinder = SCNTube(innerRadius: r, outerRadius: r + r2, height: 1)
                let mesh = try XCTUnwrap(Mesh(cylinder))
                XCTAssert(mesh.isWatertight)
                XCTAssert(mesh.polygons.areWatertight)
            }
        }
    }

    func testSCNSphereIsWatertight() throws {
        for r in [0.01, 0.1, 0.2, 0.8, 3, 5, 10] as [CGFloat] {
            let sphere = SCNSphere(radius: r)
            let mesh = try XCTUnwrap(Mesh(sphere))
            XCTAssert(mesh.isWatertight)
            XCTAssert(mesh.polygons.areWatertight)
        }
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
        let mesh = Mesh(box1)!.translated(by: [0, 0, -0.4])
            .subtracting(Mesh(box2)!.translated(by: [0, 0.12, -0.3]))
            .makeWatertight()
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
    }

    // MARK: Export

    func testExportCube() {
        let cube = Mesh.cube()
        let geometry = SCNGeometry(polygons: cube)
        XCTAssertEqual(geometry.sources.count, 3)
        XCTAssertEqual(geometry.sources.first?.vectorCount, 24)
    }

    func testExportCubeWithoutTexcoords() {
        let cube = Mesh.cube().withoutTexcoords()
        let geometry = SCNGeometry(polygons: cube)
        XCTAssertEqual(geometry.sources.count, 2)
        XCTAssertEqual(geometry.sources.first?.vectorCount, 24)
    }

    func testExportSphere() {
        let sphere = Mesh.sphere()
        let geometry = SCNGeometry(polygons: sphere)
        XCTAssertEqual(geometry.sources.count, 3)
        XCTAssertEqual(geometry.sources.first?.vectorCount, 151)
    }

    func testExportSphereWithoutTexcoords() {
        let sphere = Mesh.sphere().withoutTexcoords()
        let geometry = SCNGeometry(polygons: sphere)
        XCTAssertEqual(geometry.sources.count, 2)
        XCTAssertEqual(geometry.sources.first?.vectorCount, 151)
    }

    func testExportMeshWithColors() throws {
        let mesh = Mesh.lathe(.curve([
            .point(.unitY, color: .red),
            .curve(-.unitX, color: .green),
            .point(-.unitY, color: .blue),
        ]))
        let geometry = SCNGeometry(polygons: mesh)
        let result = try XCTUnwrap(Mesh(geometry))
        XCTAssert(result.hasVertexColors)
        XCTAssertEqual(result.polygons.first?.vertices.first?.color, .red)
    }

    // MARK: Transforms

    func testIdentityTransformToFromMatrix() {
        let transform = Transform.identity
        let matrix = SCNMatrix4(transform)
        XCTAssert(SCNMatrix4EqualToMatrix4(matrix, SCNMatrix4Identity))
        XCTAssertEqual(transform, Transform(matrix))
    }

    func testScaleTransformToFromMatrix() {
        let transform = Transform(scale: .init(size: [1.5]))
        let matrix = SCNMatrix4(transform)
        let expected = SCNMatrix4MakeScale(1.5, 1.5, 1.5)
        XCTAssert(SCNMatrix4EqualToMatrix4(matrix, expected))
        XCTAssertEqual(transform, Transform(matrix))
    }

    func testOffsetTransformToFromMatrix() {
        let transform = Transform(translation: .init(1, 2, 3))
        let matrix = SCNMatrix4(transform)
        let expected = SCNMatrix4MakeTranslation(1, 2, 3)
        XCTAssert(SCNMatrix4EqualToMatrix4(matrix, expected))
        XCTAssertEqual(transform, Transform(matrix))
    }

    func testRotationTransformToFromMatrix() {
        let transform = Transform(rotation: .init(.yaw(-.pi)))
        let matrix = SCNMatrix4(transform)
        XCTAssertEqual(transform.scale, .one)
        XCTAssertEqual(transform.translation, .zero)
        XCTAssert(transform.rotation.isEqual(to: Transform(matrix).rotation))
    }
}

#endif
