//
//  RealityKitTests.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 19/12/2023.
//  Copyright © 2023 Nick Lockwood. All rights reserved.
//

#if canImport(RealityKit)

@testable import Euclid
import Metal
import RealityKit
import XCTest

@available(macOS 15.0, iOS 18.0, tvOS 26.0, *)
final class RealityKitTests: XCTestCase {
    #if compiler(>=6)
    @available(visionOS 2.0, *)
    @MainActor
    func testRenderVertexColors() async throws {
        try XCTSkipIf(MTLCreateSystemDefaultDevice() == nil, "RealityKit requires a Metal device")
        // Initialize RealityKit on the main actor before asynchronous shader loading.
        let renderer = try RealityRenderer()
        let mesh = Mesh.cube().mapVertexColors { _ in .green }
        let source = """
        #usda 1.0
        def Material "VertexColors" {
            token outputs:mtlx:surface.connect = </VertexColors/Surface.outputs:out>
            def Shader "Color" {
                uniform token info:id = "ND_geomcolor_color3"
                int inputs:index = 0
                color3f outputs:out
            }
            def Shader "Surface" {
                uniform token info:id = "ND_realitykit_unlit_surfaceshader"
                color3f inputs:color.connect = </VertexColors/Color.outputs:out>
                token outputs:out
            }
        }
        """
        let material = try await ShaderGraphMaterial(named: "/VertexColors", from: Data(source.utf8))
        let entity = try await ModelEntity(mesh, materialLookup: { _ in material })
        let camera = Entity()
        camera.components.set(PerspectiveCameraComponent())
        camera.position = [0, 0, 3]
        renderer.entities.append(entity)
        renderer.entities.append(camera)
        renderer.activeCamera = camera
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm_srgb,
            width: 32,
            height: 32,
            mipmapped: false
        )
        descriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
        descriptor.storageMode = .shared
        let device = try XCTUnwrap(MTLCreateSystemDefaultDevice())
        let texture = try XCTUnwrap(device.makeTexture(descriptor: descriptor))
        let output = try RealityRenderer.CameraOutput(.singleProjection(colorTexture: texture))
        for _ in 0 ..< 3 {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                do {
                    try renderer.updateAndRender(
                        deltaTime: 1 / 60,
                        cameraOutput: output,
                        onComplete: { _ in continuation.resume() }
                    )
                } catch { continuation.resume(throwing: error) }
            }
        }
        var pixel = [UInt8](repeating: 0, count: 4)
        texture.getBytes(&pixel, bytesPerRow: 4, from: MTLRegionMake2D(16, 16, 1, 1), mipmapLevel: 0)
        XCTAssertGreaterThan(pixel[1], 150, "\(pixel)")
        XCTAssertLessThan(pixel[0], 50, "\(pixel)")
        XCTAssertLessThan(pixel[2], 50, "\(pixel)")
    }

    @available(visionOS 2.0, *)
    @MainActor
    func testLowLevelMeshPreservesColorSeamsAndMaterialParts() throws {
        try XCTSkipIf(MTLCreateSystemDefaultDevice() == nil, "RealityKit requires a Metal device")
        let triangle = try Mesh([XCTUnwrap(Polygon([
            Vertex([0, 0, 0], [0, 0, 1], [0, 0]),
            Vertex([1, 0, 0], [0, 0, 1], [1, 0]),
            Vertex([0, 1, 0], [0, 0, 1], [0, 1]),
        ]))])
        let red = triangle.mapVertexColors { _ in Color(red: 1, green: 0, blue: 0, alpha: 0.5) }.withMaterial("red")
        let green = triangle.mapVertexColors { _ in .green }.withMaterial("green")
        let mesh = try LowLevelMesh(Mesh.merge([red, green]))
        XCTAssertEqual(mesh.vertexCapacity, 6)
        XCTAssertEqual(mesh.indexCapacity, 6)
        XCTAssertEqual(mesh.parts.count, 2)
        XCTAssertEqual(mesh.parts.map(\.indexOffset), [0, 12])
        XCTAssertEqual(mesh.parts.map(\.indexCount), [3, 3])
        XCTAssertEqual(mesh.parts.map(\.materialIndex), [0, 1])
        let color = try XCTUnwrap(mesh.descriptor.vertexAttributes.first { $0.semantic == .color })
        let stride = mesh.descriptor.vertexLayouts[color.layoutIndex].bufferStride
        var colors = [SIMD4<Float>]()
        mesh.withUnsafeBytes(bufferIndex: 0) { buffer in
            for i in 0 ..< mesh.vertexCapacity {
                colors.append(buffer.load(fromByteOffset: i * stride + color.offset, as: SIMD4<Float>.self))
            }
        }
        XCTAssertEqual(colors, Array(repeating: [1, 0, 0, 0.5], count: 3) + Array(repeating: [0, 1, 0, 1], count: 3))
        let normal = try XCTUnwrap(mesh.descriptor.vertexAttributes.first { $0.semantic == .normal })
        let uv = try XCTUnwrap(mesh.descriptor.vertexAttributes.first { $0.semantic == .uv0 })
        mesh.withUnsafeBytes(bufferIndex: 0) { buffer in
            XCTAssertEqual(buffer.load(fromByteOffset: normal.offset, as: SIMD3<Float>.self), [0, 0, 1])
            XCTAssertEqual(buffer.load(fromByteOffset: uv.offset, as: SIMD2<Float>.self), [0, 1])
            XCTAssertEqual(buffer.load(fromByteOffset: stride + uv.offset, as: SIMD2<Float>.self), [1, 1])
        }
        mesh.withUnsafeIndices { buffer in
            XCTAssertEqual(Array(buffer.bindMemory(to: UInt32.self)), [0, 1, 2, 3, 4, 5])
        }
    }

    @available(visionOS 2.0, *)
    @MainActor
    func testColoredModelEntityUsesLowLevelMesh() throws {
        try XCTSkipIf(MTLCreateSystemDefaultDevice() == nil, "RealityKit requires a Metal device")
        let mesh = Mesh.cube().mapVertexColors { _ in .red }
        for entity in try [ModelEntity(mesh), ModelEntity(triangles: mesh)] {
            XCTAssertNotNil(entity.model?.mesh.lowLevelMesh)
        }
        XCTAssertNil(try ModelEntity(Mesh.cube()).model?.mesh.lowLevelMesh)
    }

    @available(visionOS 2.0, *)
    @MainActor
    func testExplicitTessellationDoesNotUseLowLevelMesh() async throws {
        try XCTSkipIf(MTLCreateSystemDefaultDevice() == nil, "RealityKit requires a Metal device")
        let mesh = Mesh.cube().mapVertexColors { _ in .red }
        func synchronousEntities() throws -> [ModelEntity] {
            try [ModelEntity(quads: mesh), ModelEntity(polygons: mesh)]
        }
        let synchronous = try synchronousEntities()
        let asynchronous = try await [ModelEntity(quads: mesh), ModelEntity(polygons: mesh)]
        for entity in synchronous + asynchronous {
            let resource = try XCTUnwrap(entity.model?.mesh)
            XCTAssertNil(resource.lowLevelMesh)
        }
        for descriptor in [MeshDescriptor(quads: mesh), MeshDescriptor(polygons: mesh)] {
            let result = Mesh(descriptor)
            XCTAssertEqual(result.polygons.count, 6)
            XCTAssertTrue(result.polygons.allSatisfy { $0.vertices.count == 4 })
        }
        let automatic = try await ModelEntity(mesh)
        let triangles = try await ModelEntity(triangles: mesh)
        XCTAssertNotNil(automatic.model?.mesh.lowLevelMesh)
        XCTAssertNotNil(triangles.model?.mesh.lowLevelMesh)
    }

    @available(visionOS 2.0, *)
    @MainActor
    func testLowLevelMeshCollisionAndEmptyMesh() async throws {
        try XCTSkipIf(MTLCreateSystemDefaultDevice() == nil, "RealityKit requires a Metal device")
        let empty = try LowLevelMesh(Mesh.empty)
        XCTAssertTrue(empty.parts.isEmpty)
        let resource = try await MeshResource.generate(triangles: Mesh.cube().mapVertexColors { _ in .blue })
        XCTAssertNotNil(resource.lowLevelMesh)
        _ = try await ShapeResource.generateStaticMesh(from: resource)
    }
    #endif

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

    @MainActor
    func testConvertToFromModelEntity() throws {
        try XCTSkipIf(MTLCreateSystemDefaultDevice() == nil, "RealityKit requires a Metal device")
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

    func testAsyncConvertToFromModelEntity() async throws {
        try XCTSkipIf(MTLCreateSystemDefaultDevice() == nil, "RealityKit requires a Metal device")
        let cube = Mesh.cube(size: 1).triangulate()
        let modelEntity = try await ModelEntity(cube)
        let result = await Mesh(modelEntity)
        XCTAssertTrue(result.isWatertight)
        XCTAssertTrue(result.isActuallyConvex)
        XCTAssertEqual(result.polygons.count, 12)
        XCTAssertEqual(cube, result.replacing(result.materials[0], with: nil))
    }
}

#endif
