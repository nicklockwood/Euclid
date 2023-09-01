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
        let mesh = Mesh(box1)!.translated(by: Vector(0, 0, -0.4))
            .subtracting(Mesh(box2)!.translated(by: Vector(0, 0.12, -0.3)))
            .makeWatertight()
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
    }

    // MARK: Export

    func testExportCube() {
        let cube = Mesh.cube()
        let geometry = SCNGeometry(polygons: cube)
        XCTAssertEqual(geometry.sources.count, 2)
        XCTAssertEqual(geometry.sources.first?.vectorCount, 20)
    }

    func testExportCubeWithoutTexcoords() {
        let cube = Mesh.cube().withoutTexcoords()
        let geometry = SCNGeometry(polygons: cube)
        XCTAssertEqual(geometry.sources.count, 1)
        XCTAssertEqual(geometry.sources.first?.vectorCount, 8)
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

    func testExportSphereWithoutTexcoordsOrNormals() {
        let sphere = Mesh.sphere().withoutTexcoords().smoothNormals(.zero)
        let geometry = SCNGeometry(polygons: sphere)
        XCTAssertEqual(geometry.sources.count, 1)
        XCTAssertEqual(geometry.sources.first?.vectorCount, 114)
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
        let transform = Transform(offset: .init(1, 2, 3))
        let matrix = SCNMatrix4(transform)
        let expected = SCNMatrix4MakeTranslation(1, 2, 3)
        XCTAssert(SCNMatrix4EqualToMatrix4(matrix, expected))
        XCTAssertEqual(transform, Transform(matrix))
    }

    func testRotationTransformToFromMatrix() {
        let transform = Transform(rotation: .init(.yaw(-.pi)))
        let matrix = SCNMatrix4(transform)
        XCTAssertEqual(transform.scale, .one)
        XCTAssertEqual(transform.offset, .zero)
        XCTAssert(transform.rotation.isEqual(to: Transform(matrix).rotation))
    }
}

#endif
