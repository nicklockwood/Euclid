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
    @MainActor
    func testUniformVertexColorsTintBuiltInMaterials() throws {
        let color = Color(red: 0.25, green: 0.5, blue: 0.75, alpha: 0.5)
        let mesh = Mesh.cube().mapVertexColors { _ in color }
        let lookups: [ModelEntity.MaterialProvider] = [
            { _ in SimpleMaterial(color: .white, isMetallic: false) },
            { _ in
                var material = UnlitMaterial(color: .white)
                material.blending = .transparent(opacity: .init(floatLiteral: 0.5))
                return material
            },
            { _ in
                var material = PhysicallyBasedMaterial()
                material.blending = .transparent(opacity: .init(floatLiteral: 0.5))
                material.roughness = .init(floatLiteral: 0.75)
                return material
            },
        ]
        let space = try XCTUnwrap(CGColorSpace(name: CGColorSpace.extendedLinearSRGB))
        for lookup in lookups {
            let converted = try XCTUnwrap(ModelEntity(triangles: mesh, materialLookup: lookup).model?.materials.first)
            let tint: OSColor
            switch converted {
            case let material as SimpleMaterial:
                tint = material.color.tint
                XCTAssertEqual(Color(tint).alpha, 0.5, accuracy: 0.000001)
            case let material as UnlitMaterial:
                tint = material.color.tint
                guard case let .transparent(opacity) = material.blending else {
                    return XCTFail("Expected transparent material")
                }
                XCTAssertEqual(opacity.scale, 0.25)
            case let material as PhysicallyBasedMaterial:
                tint = material.baseColor.tint
                guard case let .transparent(opacity) = material.blending else {
                    return XCTFail("Expected transparent material")
                }
                XCTAssertEqual(opacity.scale, 0.25)
                XCTAssertEqual(material.roughness.scale, 0.75)
            default:
                return XCTFail("Unexpected material")
            }
            let linear = Color(tint, colorSpace: space)
            XCTAssertEqual(linear.red, color.toLinear().red, accuracy: 0.000001)
            XCTAssertEqual(linear.green, color.toLinear().green, accuracy: 0.000001)
            XCTAssertEqual(linear.blue, color.toLinear().blue, accuracy: 0.000001)
        }
    }

    @MainActor
    func testVertexTintMultiplicationUsesLinearLight() throws {
        let color = Color(red: 0.5, green: 0.25, blue: 0.75, alpha: 0.5)
        let mesh = Mesh.cube().mapVertexColors { _ in color }
        let entity = try ModelEntity(triangles: mesh) { _ in
            SimpleMaterial(color: OSColor(color), isMetallic: false)
        }
        let material = try XCTUnwrap(entity.model?.materials.first as? SimpleMaterial)
        let expected = (color.toLinear() * color.toLinear()).toSRGB()
        XCTAssertEqual(Color(material.color.tint), expected, accuracy: 1e-6)
        XCTAssertEqual(Color(material.color.tint).alpha, 0.25, accuracy: 1e-6)
    }

    @MainActor
    func testVertexColorFallbackRequiresUniformColorPerMaterial() throws {
        let red = Mesh.cube(material: "red").mapVertexColors { _ in .red }
        let blue = Mesh.cube(material: "blue").mapVertexColors { _ in .blue }
        let mesh = Mesh.merge([red, blue])
        let materials = try XCTUnwrap(ModelEntity(triangles: mesh).model).materials
        XCTAssertEqual(materials.count, 2)
        for (material, color) in zip(materials, [Color.red, .blue]) {
            let material = try XCTUnwrap(material as? SimpleMaterial)
            XCTAssertEqual(Color(material.color.tint), color, accuracy: 0.000001)
        }
        // A shared material with varying vertex colors must not take just the first color.
        let mixed = Mesh.merge([red.withMaterial(nil), blue.withMaterial(nil)])
        let material = try XCTUnwrap(ModelEntity(triangles: mixed).model?.materials.first as? SimpleMaterial)
        XCTAssertEqual(Color(material.color.tint), .white, accuracy: 1e-6)
    }

    #if compiler(>=6)
    @available(visionOS 2.0, *)
    @MainActor
    func testVertexColorMaterialParametersAndTemplateIsolation() async throws {
        try XCTSkipIf(MTLCreateSystemDefaultDevice() == nil, "RealityKit requires a Metal device")
        var first = try await RealityKitVertexColorMaterial.make(
            color: Color(red: 0.5, green: 0.25, blue: 0.75, alpha: 0.4),
            emissionIntensity: 2, roughness: 0.2, metallic: 0.3, specular: 0.4
        )
        let second = try await RealityKitVertexColorMaterial.make()
        func scalar(_ material: ShaderGraphMaterial, _ name: String) throws -> Float {
            guard case let .float(value) = material.getParameter(name: name) else {
                return try XCTUnwrap(Float?.none, "Missing scalar parameter: \(name)")
            }
            return value
        }
        XCTAssertEqual(try scalar(first, "opacity"), 0.4)
        XCTAssertEqual(try scalar(first, "emissiveIntensity"), 2)
        XCTAssertEqual(try scalar(first, "roughness"), 0.2)
        XCTAssertEqual(try scalar(first, "metallic"), 0.3)
        XCTAssertEqual(try scalar(first, "specular"), 0.4)
        XCTAssertEqual(try scalar(second, "opacity"), 1)
        XCTAssertEqual(try scalar(second, "roughness"), 0.5)
        try first.setParameter(name: "opacity", value: .float(0.1))
        XCTAssertEqual(try scalar(second, "opacity"), 1)
    }

    @available(visionOS 2.0, *)
    @MainActor
    func testRenderVertexColors() async throws {
        try XCTSkipIf(MTLCreateSystemDefaultDevice() == nil, "RealityKit requires a Metal device")
        // Initialize RealityKit on the main actor before asynchronous shader loading.
        let renderer = try RealityRenderer()
        let color = Color(red: 0.5, green: 0.25, blue: 0.75, alpha: 0.6)
        let tint = Color(white: 0.8, alpha: 0.5)
        let mesh = Mesh.cube().mapVertexColors { _ in color }
        let material = try await RealityKitVertexColorMaterial.make(color: tint, unlit: true)
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
        func renderPixel() async throws -> [UInt8] {
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
            return pixel
        }
        let actual = try await renderPixel()
        let expected = (color.toLinear() * tint.toLinear()).toSRGB()
        var reference = UnlitMaterial(color: OSColor(expected.withAlphaComponent(1)))
        reference.blending = .transparent(opacity: .init(floatLiteral: Float(expected.alpha)))
        entity.model?.materials = [reference]
        let referencePixel = try await renderPixel()
        XCTAssertGreaterThan(actual[3], 0)
        for channel in 0 ..< 4 {
            XCTAssertEqual(Double(actual[channel]), Double(referencePixel[channel]), accuracy: 2)
        }
    }

    @available(visionOS 2.0, *)
    @MainActor
    func testRenderedAlphaMatchesCompositedColor() async throws {
        try XCTSkipIf(MTLCreateSystemDefaultDevice() == nil, "RealityKit requires a Metal device")
        // Initialize RealityKit on the main actor before asynchronous shader loading.
        let renderer = try RealityRenderer()
        func material(_ color: Color) -> UnlitMaterial {
            var material = UnlitMaterial(applyPostProcessToneMap: true)
            material.color = .init(tint: OSColor(color.withAlphaComponent(1)))
            if color.alpha < 1 {
                material.blending = .transparent(opacity: .init(floatLiteral: Float(color.alpha)))
            }
            return material
        }
        let mesh = Mesh.fill(.square(size: 2), faces: .front)
        let entity = try await ModelEntity(mesh, materialLookup: { _ in material(.black) })
        let foregroundEntity = try await ModelEntity(mesh, materialLookup: { _ in material(.white) })
        foregroundEntity.position.z = 0.1
        renderer.entities.append(foregroundEntity)
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
        func renderPixel() async throws -> [UInt8] {
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
            return pixel
        }
        // Compare translucent layers with an opaque, precomposited color so that
        // both results pass through the same renderer color management.
        for (foreground, background) in [
            (Color(white: 1, alpha: 0.5), Color.black),
            (Color(red: 1, green: 0, blue: 0, alpha: 0.5), Color.blue),
            (Color(red: 0.5, green: 0.25, blue: 0.75, alpha: 0.3), Color(white: 0.4)),
        ] {
            foregroundEntity.isEnabled = true
            foregroundEntity.model?.materials = [material(foreground)]
            entity.model?.materials = [material(background)]
            let actual = try await renderPixel()
            foregroundEntity.isEnabled = false
            entity.model?.materials = [material(foreground.composited(over: background))]
            let expected = try await renderPixel()
            for channel in 0 ..< 4 {
                XCTAssertEqual(Double(actual[channel]), Double(expected[channel]), accuracy: 2)
            }
        }
    }

    @available(visionOS 2.0, *)
    @MainActor
    func testTextureFilteringMatchesBuiltInMaterial() async throws {
        try XCTSkipIf(MTLCreateSystemDefaultDevice() == nil, "RealityKit requires a Metal device")
        let renderer = try RealityRenderer()
        let provider = try XCTUnwrap(CGDataProvider(data: Data([
            255, 0, 0, 255, 0, 0, 255, 255,
        ]) as CFData))
        let image = try XCTUnwrap(CGImage(
            width: 2, height: 1, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 8,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
            provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent
        ))
        let resource = try await TextureResource(image: image, options: .init(semantic: .color))
        func mesh(uvScale: Double) -> Mesh {
            Mesh(Mesh.cube().polygons.map { polygon in
                polygon.mapTexcoords { [0.45 + ($0.x - 0.5) * uvScale, 0.5] }
            }).mapVertexColors { _ in Color(white: 0.8) }
        }
        let initial = try await RealityKitVertexColorMaterial.make(unlit: true)
        let entity = try await ModelEntity(mesh(uvScale: 0), materialLookup: { _ in initial })
        let camera = Entity()
        camera.components.set(PerspectiveCameraComponent())
        camera.position = [0, 0, 3]
        renderer.entities.append(entity)
        renderer.entities.append(camera)
        renderer.activeCamera = camera
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm_srgb, width: 32, height: 32, mipmapped: false
        )
        descriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
        descriptor.storageMode = .shared
        let device = try XCTUnwrap(MTLCreateSystemDefaultDevice())
        let outputTexture = try XCTUnwrap(device.makeTexture(descriptor: descriptor))
        let output = try RealityRenderer.CameraOutput(.singleProjection(colorTexture: outputTexture))
        func renderPixel() async throws -> [UInt8] {
            for _ in 0 ..< 3 {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    do {
                        try renderer.updateAndRender(
                            deltaTime: 1 / 60, cameraOutput: output,
                            onComplete: { _ in continuation.resume() }
                        )
                    } catch { continuation.resume(throwing: error) }
                }
            }
            var pixel = [UInt8](repeating: 0, count: 4)
            outputTexture.getBytes(&pixel, bytesPerRow: 4, from: MTLRegionMake2D(16, 16, 1, 1), mipmapLevel: 0)
            return pixel
        }
        // Constant UVs exercise magnification near a texel boundary; rapidly varying
        // UVs exercise minification. Revisit nearest to also check template isolation.
        for uvScale in [0.0, 64.0] {
            entity.model?.mesh = try await MeshResource.generate(triangles: mesh(uvScale: uvScale))
            var referencePixels = [[UInt8]]()
            for filter: MTLSamplerMinMagFilter in [.nearest, .linear, .nearest] {
                let sampler = MTLSamplerDescriptor()
                sampler.sAddressMode = .repeat
                sampler.minFilter = uvScale == 0 ? .linear : filter
                sampler.magFilter = uvScale == 0 ? filter : .linear
                let texture = MaterialParameters.Texture(resource, sampler: .init(sampler))
                let material = try await RealityKitVertexColorMaterial.make(texture: texture, unlit: true)
                entity.model?.materials = [material]
                let actual = try await renderPixel()
                var reference = UnlitMaterial()
                reference.color = .init(tint: OSColor(Color(white: 0.8)), texture: texture)
                entity.model?.materials = [reference]
                let expected = try await renderPixel()
                referencePixels.append(expected)
                XCTAssertGreaterThan(expected.prefix(3).max() ?? 0, 0)
                for channel in 0 ..< 4 {
                    XCTAssertEqual(Double(actual[channel]), Double(expected[channel]), accuracy: 2)
                }
            }
            XCTAssertNotEqual(referencePixels[0], referencePixels[1])
            XCTAssertEqual(referencePixels[0], referencePixels[2])
        }
    }

    @available(visionOS 2.0, *)
    @MainActor
    func testLowLevelMeshTangentFramesHandleMirroredAndDegenerateUVs() throws {
        for scale in [1.0, -1.0, 0.0] {
            let polygon = try XCTUnwrap(Polygon([
                Vertex(.zero, normal: .unitZ, texcoord: [0.5, 0.5]),
                Vertex(.unitX, normal: .unitZ, texcoord: [0.5 + scale, 0.5]),
                Vertex(.unitY, normal: .unitZ, texcoord: [0.5, 0.5 + abs(scale)]),
            ]))
            let mesh = try LowLevelMesh(Mesh([polygon]))
            let tangent = try XCTUnwrap(mesh.descriptor.vertexAttributes.first { $0.semantic == .tangent })
            let bitangent = try XCTUnwrap(mesh.descriptor.vertexAttributes.first { $0.semantic == .bitangent })
            let stride = mesh.descriptor.vertexLayouts[tangent.layoutIndex].bufferStride
            mesh.withUnsafeBytes(bufferIndex: 0) { buffer in
                for index in 0 ..< mesh.vertexCapacity {
                    let t = buffer.load(fromByteOffset: index * stride + tangent.offset, as: SIMD3<Float>.self)
                    let b = buffer.load(fromByteOffset: index * stride + bitangent.offset, as: SIMD3<Float>.self)
                    XCTAssertEqual(Double(simd_length(t)), 1, accuracy: 1e-6)
                    XCTAssertEqual(Double(simd_length(b)), 1, accuracy: 1e-6)
                    XCTAssertEqual(Double(simd_dot(t, b)), 0, accuracy: 1e-6)
                    XCTAssertEqual(t.z, 0)
                    XCTAssertEqual(b.z, 0)
                    if scale != 0 {
                        XCTAssertEqual(t, [Float(scale), 0, 0])
                        XCTAssertEqual(b, [0, -1, 0])
                    }
                }
            }
        }
    }

    @available(visionOS 2.0, *)
    @MainActor
    func testRenderVertexColorNormalMapMatchesBuiltInMaterial() async throws {
        try XCTSkipIf(MTLCreateSystemDefaultDevice() == nil, "RealityKit requires a Metal device")
        // Initialize RealityKit on the main actor before asynchronous shader loading.
        let renderer = try RealityRenderer()
        let bytes = Data([210, 185, 210, 255])
        let provider = try XCTUnwrap(CGDataProvider(data: bytes as CFData))
        let image = try XCTUnwrap(CGImage(
            width: 1, height: 1, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
            provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent
        ))
        let resource = try await TextureResource(image: image, options: .init(semantic: .normal))
        let normal = MaterialParameters.Texture(resource)
        let mesh = Mesh.cube().mapVertexColors { _ in Color(white: 0.8) }
        let material = try await RealityKitVertexColorMaterial.make(normal: normal, specular: 0)
        let entity = try await ModelEntity(mesh, materialLookup: { _ in material })
        let light = DirectionalLight()
        light.light.intensity = 1000
        light.look(at: .zero, from: [2, 1, 3], relativeTo: nil)
        renderer.entities.append(light)
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
        func renderPixel() async throws -> [UInt8] {
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
            return pixel
        }
        let actual = try await renderPixel()
        var reference = PhysicallyBasedMaterial()
        reference.baseColor = .init(tint: OSColor(Color(white: 0.8)))
        reference.roughness = .init(floatLiteral: 0.5)
        reference.specular = .init(floatLiteral: 0)
        reference.normal = .init(texture: normal)
        entity.model = try ModelComponent(
            mesh: MeshResource.generate(from: [MeshDescriptor(triangles: mesh)]),
            materials: [reference]
        )
        let referencePixel = try await renderPixel()
        XCTAssertGreaterThan(actual[0], 0)
        for channel in 0 ..< 4 {
            XCTAssertEqual(Double(actual[channel]), Double(referencePixel[channel]), accuracy: 3)
        }
        reference.normal = .init()
        entity.model?.materials = [reference]
        let flatPixel = try await renderPixel()
        XCTAssertGreaterThan(abs(Int(flatPixel[0]) - Int(referencePixel[0])), 10)
        // Unlit variants ignore normal maps and must not try to bind an absent parameter.
        _ = try await RealityKitVertexColorMaterial.make(normal: normal, unlit: true)
    }

    @available(visionOS 2.0, *)
    @MainActor
    func testRenderAllMaterialTexturesMatchesBuiltInMaterial() async throws {
        try XCTSkipIf(MTLCreateSystemDefaultDevice() == nil, "RealityKit requires a Metal device")
        // Initialize RealityKit on the main actor before asynchronous shader loading.
        let renderer = try RealityRenderer()
        let bytes = Data([
            200, 70, 30, 200, 50, 180, 220, 100,
            200, 70, 30, 200, 50, 180, 220, 100,
        ])
        let provider = try XCTUnwrap(CGDataProvider(data: bytes as CFData))
        let image = try XCTUnwrap(try CGImage(
            width: 2, height: 2, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 8,
            space: XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB)),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
            provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent
        ))
        let sampler = MTLSamplerDescriptor()
        sampler.minFilter = .nearest
        sampler.magFilter = .nearest
        let colorResource = try await TextureResource(image: image, options: .init(semantic: .color))
        let dataResource = try await TextureResource(image: image, options: .init(semantic: .scalar))
        let colorTexture = MaterialParameters.Texture(colorResource, sampler: .init(sampler))
        let dataTexture = MaterialParameters.Texture(dataResource, sampler: .init(sampler))
        let vertexColor = Color(white: 0.8, alpha: 0.7)
        let tint = Color(white: 0.7, alpha: 0.6)
        let mesh = Mesh.cube().mapVertexColors { _ in vertexColor }
        let material = try await RealityKitVertexColorMaterial.make(
            color: tint, texture: colorTexture, opacityTexture: dataTexture,
            emissionTexture: colorTexture, roughnessTexture: dataTexture, metallicTexture: dataTexture,
            emission: .white, emissionIntensity: 0.4, roughness: 0.8, metallic: 0.6, specular: 0.3
        )
        let entity = try await ModelEntity(mesh, materialLookup: { _ in material })
        let light = DirectionalLight()
        light.light.intensity = 1000
        light.look(at: .zero, from: [2, 1, 3], relativeTo: nil)
        renderer.entities.append(light)
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
        func renderPixel() async throws -> [UInt8] {
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
            var pixels = [UInt8](repeating: 0, count: 32 * 32 * 4)
            texture.getBytes(&pixels, bytesPerRow: 32 * 4, from: MTLRegionMake2D(0, 0, 32, 32), mipmapLevel: 0)
            return pixels
        }
        let actual = try await renderPixel()
        var reference = PhysicallyBasedMaterial()
        let combined = (vertexColor.toLinear() * tint.toLinear()).toSRGB()
        reference.baseColor = .init(tint: OSColor(combined.withAlphaComponent(1)), texture: colorTexture)
        reference.blending = .transparent(opacity: .init(scale: Float(combined.alpha), texture: dataTexture))
        reference.emissiveColor = .init(texture: colorTexture)
        reference.emissiveIntensity = 0.4
        reference.roughness = .init(scale: 0.8, texture: dataTexture)
        reference.metallic = .init(scale: 0.6, texture: dataTexture)
        reference.specular = .init(floatLiteral: 0.3)
        entity.model = try ModelComponent(
            mesh: MeshResource.generate(from: [MeshDescriptor(triangles: mesh)]), materials: [reference]
        )
        let expected = try await renderPixel()
        for x in [13, 18] {
            let offset = (16 * 32 + x) * 4
            XCTAssertGreaterThan(actual[offset + 3], 0)
            for channel in 0 ..< 4 {
                XCTAssertEqual(Double(actual[offset + channel]), Double(expected[offset + channel]), accuracy: 3)
            }
        }
        let leftOffset: Int = (16 * 32 + 13) * 4 + 3
        let rightOffset: Int = (16 * 32 + 18) * 4 + 3
        let leftAlpha = actual[leftOffset]
        let rightAlpha = actual[rightOffset]
        XCTAssertNotEqual(leftAlpha, rightAlpha)
        // A differently configured cached template must not inherit these textures.
        let plain = try await RealityKitVertexColorMaterial.make()
        XCTAssertNil(plain.getParameter(name: "opacityTexture"))
        _ = try await RealityKitVertexColorMaterial.make(
            opacityTexture: dataTexture, emissionTexture: colorTexture,
            roughnessTexture: dataTexture, metallicTexture: dataTexture,
            emission: .white, unlit: true
        )
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
        let red = triangle.mapVertexColors { _ in Color(red: 0.5, green: 0, blue: 0, alpha: 0.5) }.withMaterial("red")
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
        XCTAssertEqual(
            colors,
            Array(repeating: [Float(Color(white: 0.5).toLinear().red), 0, 0, 0.5], count: 3) + Array(
                repeating: [0, 1, 0, 1],
                count: 3
            )
        )
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
    func testEmptyLowLevelMesh() throws {
        try XCTSkipIf(MTLCreateSystemDefaultDevice() == nil, "RealityKit requires a Metal device")
        let empty = try LowLevelMesh(Mesh.empty)
        XCTAssertTrue(empty.parts.isEmpty)
    }

    @available(visionOS 2.0, *)
    @MainActor
    func testColoredMeshCollisionUsesMeshDescriptor() async throws {
        try XCTSkipIf(MTLCreateSystemDefaultDevice() == nil, "RealityKit requires a Metal device")
        let mesh = Mesh.cube().mapVertexColors { _ in .blue }
        let resource = try await MeshResource.generate(triangles: mesh)
        XCTAssertNotNil(resource.lowLevelMesh)
        // Older macOS, iOS, and visionOS runtimes can render LowLevelMesh but fail collision generation.
        // Use the same geometry with MeshDescriptor for collision generation.
        let collisionResource = try MeshResource.generate(from: [MeshDescriptor(triangles: mesh)])
        XCTAssertNil(collisionResource.lowLevelMesh)
        _ = try await ShapeResource.generateStaticMesh(from: collisionResource)
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
