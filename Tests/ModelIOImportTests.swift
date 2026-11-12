//
//  ModelIOImportTests.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 10/11/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

#if canImport(ModelIO)

@testable import Euclid
@preconcurrency import ModelIO
import XCTest

#if canImport(SceneKit)
import SceneKit
#endif

#if canImport(RealityKit)
import RealityKit
#endif

final class ModelIOImportTests: XCTestCase {
    func testRoundTripVertexAttributesAndMaterials() throws {
        let color = Color(red: 0.5, green: 0.25, blue: 0.75, alpha: 0.4)
        let source = Mesh.cube().mapVertexColors { _ in color }.withMaterial("paint")
        let material = MDLMaterial(Color(white: 0.25, alpha: 0.5))
        for linearColors in [true, false] {
            let asset = try MDLAsset(source, linearColors: linearColors) { _ in material }
            let result = try Mesh(asset, linearColors: linearColors)
            XCTAssertEqual(result.polygons.count, 6)
            XCTAssertEqual(result.bounds, source.bounds)
            XCTAssertEqual(result.surfaceArea, source.surfaceArea, accuracy: 1e-6)
            XCTAssertTrue(result.materials.first as? MDLMaterial === material)
            for vertex in result.polygons.flatMap(\.vertices) {
                let expected = try XCTUnwrap(source.polygons.flatMap(\.vertices).first {
                    $0.position == vertex.position && $0.normal == vertex.normal
                })
                XCTAssertEqual(vertex.texcoord, expected.texcoord)
                XCTAssertEqual(vertex.color, color, accuracy: 1e-6)
            }
            let mapped = try Mesh(asset) { $0.name }
            XCTAssertEqual(mapped.materials, [material.name])
            XCTAssertTrue(try Mesh(asset) { _ in nil }.polygons.allSatisfy { $0.material == nil })
            XCTAssertThrowsError(try Mesh(asset) { _ in throw CancellationError() })
        }
    }

    func testHierarchyTransformsAndIgnoringTransforms() throws {
        let asset = try MDLAsset(Mesh.cube())
        let child = asset.object(at: 0)
        let parent = MDLObject()
        parent.transform = MDLTransform(matrix: translation(2, 0, 0))
        child.transform = MDLTransform(matrix: translation(0, 3, 0))
        parent.addChild(child)
        let mesh = try Mesh(parent)
        XCTAssertEqual(mesh.bounds, Mesh.cube().translated(by: [2, 3, 0]).bounds)
        XCTAssertEqual(try Mesh(parent, ignoringTransforms: true).bounds, Mesh.cube().bounds)
        // Importing a subtree excludes the parent transform.
        XCTAssertEqual(try Mesh(child).bounds, Mesh.cube().translated(by: [0, 3, 0]).bounds)
        child.transform = MDLTransform(matrix: translation(0, 3, 0), resetsTransform: true)
        XCTAssertEqual(try Mesh(parent).bounds, try Mesh(child).bounds)
    }

    func testReflectionAndNonuniformScale() throws {
        let asset = try MDLAsset(Mesh.cube())
        let object = asset.object(at: 0)
        object.transform = MDLTransform(matrix: simd_float4x4(diagonal: [-2, 3, 4, 1]))
        let mesh = try Mesh(object)
        XCTAssertEqual(mesh.bounds, Mesh.cube().scaled(by: [-2, 3, 4]).bounds, accuracy: 1e-6)
        XCTAssertGreaterThan(mesh.signedVolume, 0)
        for polygon in mesh.polygons {
            for vertex in polygon.vertices {
                XCTAssertEqual(vertex.normal, polygon.plane.normal, accuracy: 1e-6)
            }
        }
    }

    func testRGBDefaultsToOpaqueAndMissingNormals() throws {
        let mesh = makeMesh(indices: [0, 1, 2], type: .triangles, colors: true)
        let imported = try Mesh(mesh, linearColors: false)
        XCTAssertEqual(imported.polygons.count, 1)
        for vertex in imported.polygons.flatMap(\.vertices) {
            XCTAssertEqual(vertex.color, Color(red: 0.5, green: 0.25, blue: 0.75))
            XCTAssertEqual(vertex.normal, .unitZ)
        }
    }

    func testTriangleStripsAndQuads() throws {
        for type: MDLGeometryType in [.triangleStrips, .quads] {
            let mesh = makeMesh(indices: type == .quads ? [0, 1, 3, 2] : [0, 1, 2, 3], type: type)
            let result = try Mesh(mesh)
            XCTAssertEqual(result.surfaceArea, 1, accuracy: 1e-6)
            XCTAssertEqual(result.polygons.count, type == .quads ? 1 : 2)
            XCTAssertTrue(result.polygons.allSatisfy { $0.plane.normal == .unitZ })
        }
    }

    func testMalformedIndicesAndUnsupportedPrimitives() {
        XCTAssertThrowsError(try Mesh(makeMesh(indices: [0, 1, 99], type: .triangles)))
        XCTAssertThrowsError(try Mesh(makeMesh(indices: [0, 1], type: .triangles)))
        XCTAssertThrowsError(try Mesh(makeMesh(indices: [0, 1], type: .lines)))
    }

    func testEmptyAssetAndObject() throws {
        XCTAssertTrue(try Mesh(MDLAsset()).isEmpty)
        XCTAssertTrue(try Mesh(MDLObject()).isEmpty)
    }

    func testNormalsUnderNonuniformScale() throws {
        let polygon = try XCTUnwrap(Polygon([
            Vertex([0, 0, 0]), Vertex([1, 0, 1]), Vertex([0, 1, 1]),
        ]))
        let asset = try MDLAsset(Mesh([polygon]))
        asset.object(at: 0).transform = MDLTransform(matrix: simd_float4x4(diagonal: [2, 3, 4, 1]))
        let result = try Mesh(asset)
        let face = try XCTUnwrap(result.polygons.first)
        for vertex in face.vertices {
            XCTAssertEqual(vertex.normal, face.plane.normal, accuracy: 1e-6)
        }
    }

    func testOBJAssetImport() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("euclid-modelio-\(UUID()).obj")
        defer { try? FileManager.default.removeItem(at: url) }
        try """
        v 0 0 0 0.5 0.25 0.75
        v 1 0 0 0.5 0.25 0.75
        v 0 1 0 0.5 0.25 0.75
        f 1 2 3
        """.write(to: url, atomically: true, encoding: .utf8)
        let result = try Mesh(MDLAsset(url: url), linearColors: false)
        XCTAssertEqual(result.polygons.count, 1)
        XCTAssertEqual(result.surfaceArea, 0.5, accuracy: 1e-6)
        for vertex in result.polygons.flatMap(\.vertices) {
            XCTAssertEqual(vertex.color, Color(red: 0.5, green: 0.25, blue: 0.75), accuracy: 1e-6)
        }
    }

    func testMalformedVariableTopology() throws {
        let asset = try MDLAsset(Mesh.cube())
        let mesh = try XCTUnwrap(asset.object(at: 0) as? MDLMesh)
        let submesh = try XCTUnwrap(mesh.submeshes?.firstObject as? MDLSubmesh)
        submesh.topology?.faceCount = 7
        XCTAssertThrowsError(try Mesh(mesh))
    }

    func testModelIOMaterialColorsAndMapping() throws {
        let color = Color(red: 0.5, green: 0.25, blue: 0.75, alpha: 0.4)
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("euclid-mdl-\(UUID())")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        for ext in ["obj", "usda"] {
            let url = folder.appendingPathComponent("mesh.\(ext)")
            try Mesh.cube().withMaterial(color).write(to: url)
            let result = try loadModelIO(url)
            let material = try XCTUnwrap(result.materials.first as? MDLMaterial)
            let base = try XCTUnwrap(material.property(with: .baseColor).flatMap { Color($0) })
            XCTAssertEqual(base, color.withAlphaComponent(1), accuracy: 1e-5)
            XCTAssertEqual(try XCTUnwrap(defaultColorMapping(material)), color, accuracy: 1e-5)
            XCTAssertEqual(Double(material.property(with: .opacity)?.floatValue ?? 0), 0.4, accuracy: 1e-6)
            XCTAssertTrue(try Mesh(MDLAsset(url: url)) { _ in nil }.polygons.allSatisfy { $0.material == nil })
            let exported = folder.appendingPathComponent("roundtrip.\(ext)")
            try result.write(to: exported)
            let roundtrip = try loadModelIO(exported)
            XCTAssertEqual(try XCTUnwrap(defaultColorMapping(roundtrip.materials.first ?? nil)), color, accuracy: 1e-5)
            let mapped = try Mesh(MDLAsset(url: url)) { _ in "mapped" }
            XCTAssertEqual(mapped.materials, ["mapped"])
            #if canImport(SceneKit)
            let scn = SCNGeometry(result).materials.first
            let displayed = try XCTUnwrap(defaultColorMapping(scn?.diffuse.contents as? AnyHashable))
            XCTAssertEqual(displayed.withAlphaComponent(1), color.withAlphaComponent(1), accuracy: 1e-5)
            XCTAssertEqual((scn?.transparent.contents as? NSNumber)?.doubleValue ?? 0, color.alpha, accuracy: 1e-6)
            #endif
        }
    }

    #if canImport(RealityKit)

    @MainActor
    @available(tvOS 26.0, *)
    func testRealityKitModelIOMaterial() {
        let source = MDLMaterial(Color(red: 0.5, green: 0.25, blue: 0.75, alpha: 0.4))
        source.setProperty(MDLMaterialProperty(name: "roughness", semantic: .roughness, float: 0.3))
        source.setProperty(MDLMaterialProperty(name: "metallic", semantic: .metallic, float: 0.7))
        let material = PhysicallyBasedMaterial(source)
        XCTAssertEqual(Color(material.baseColor.tint), Color(red: 0.5, green: 0.25, blue: 0.75), accuracy: 1e-5)
        XCTAssertEqual(material.roughness.scale, 0.3)
        XCTAssertEqual(material.metallic.scale, 0.7)
        guard case let .transparent(opacity) = material.blending else { return XCTFail("Missing opacity") }
        XCTAssertEqual(Double(opacity.scale), 0.4, accuracy: 1e-6)
        let sampler = MDLTextureSampler()
        sampler.texture = MDLTexture(
            data: Data([64, 32, 96, 128]), topLeftOrigin: true, name: "texture",
            dimensions: [1, 1], rowStride: 4, channelCount: 4, channelEncoding: .uInt8, isCube: false
        )
        source.setProperty(MDLMaterialProperty(name: "baseColor", semantic: .baseColor, textureSampler: sampler))
        XCTAssertNotNil(PhysicallyBasedMaterial(source).baseColor.texture)
    }

    #endif

    func testColorMaterialPropertyInitializer() throws {
        let property = MDLMaterialProperty(
            name: "color", semantic: .baseColor, float4: [0.21404114, 0.05087609, 0.52252155, 0.4]
        )
        XCTAssertEqual(
            try XCTUnwrap(Color(property)),
            Color(red: 0.5, green: 0.25, blue: 0.75, alpha: 0.4),
            accuracy: 1e-6
        )
        XCTAssertEqual(try XCTUnwrap(Color(property, linearColors: false)).red, 0.21404114, accuracy: 1e-6)
        XCTAssertNil(Color(MDLMaterialProperty(name: "roughness", semantic: .roughness, float: 0.5)))
        let cg = CGColor(srgbRed: 0.5, green: 0.25, blue: 0.75, alpha: 0.4)
        let tagged = MDLMaterialProperty(name: "color", semantic: .baseColor, color: cg)
        XCTAssertEqual(try XCTUnwrap(Color(tagged)), Color(cg), accuracy: 1e-6)
    }

    func testModelIOLoadsTexture() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("euclid-mdl-texture-\(UUID())")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let provider = try XCTUnwrap(CGDataProvider(data: Data([64, 32, 96, 128]) as CFData))
        let space = try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB))
        let image = try XCTUnwrap(CGImage(
            width: 1, height: 1, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 4,
            space: space, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent
        ))
        let url = folder.appendingPathComponent("mesh.obj")
        try Mesh.cube().withMaterial(image).write(to: url)
        let mesh = try loadModelIO(url)
        let material = try XCTUnwrap(mesh.materials.first as? MDLMaterial)
        let texture = try XCTUnwrap(material.property(with: .baseColor)?.textureSamplerValue?.texture)
        XCTAssertEqual(texture.dimensions, [1, 1])
        #if canImport(SceneKit)
        let contents = try XCTUnwrap(SCNGeometry(mesh).materials.first?.diffuse.contents)
        XCTAssertTrue(contents is MDLTexture || contents is OSImage || CFGetTypeID(contents as CFTypeRef) == CGImage
            .typeID)
        #endif
    }

    func testURLConvertsUpAxis() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("euclid-up-\(UUID()).usda")
        defer { try? FileManager.default.removeItem(at: url) }
        try """
        #usda 1.0
        (upAxis = "Z")
        def Mesh "triangle" {
            point3f[] points = [(0, 0, 0), (1, 0, 0), (0, 0, 1)]
            int[] faceVertexCounts = [3]
            int[] faceVertexIndices = [0, 1, 2]
            uniform token subdivisionScheme = "none"
        }
        """.write(to: url, atomically: true, encoding: .utf8)
        let mesh = try Mesh(url: url)
        XCTAssertEqual(mesh.bounds, Bounds(min: .zero, max: [1, 1, 0]), accuracy: 1e-6)
    }

    #if canImport(SceneKit)

    func testURLPrefersSceneKitMaterials() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("euclid-scn-priority-\(UUID())")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("mesh.obj")
        try Mesh.cube().withMaterial(Color(white: 0.5, alpha: 0.4)).write(to: url)
        let mesh = try Mesh(url: url)
        XCTAssertFalse(mesh.isEmpty)
        XCTAssertTrue(mesh.materials.allSatisfy { $0 is SCNMaterial })
        let mapped = try Mesh(url: url) { $0 is SCNMaterial ? "SceneKit" : "wrong" }
        XCTAssertEqual(mapped.materials, ["SceneKit"])
        XCTAssertTrue(try Mesh(url: url) { _ in nil }.polygons.allSatisfy { $0.material == nil })
    }

    #endif

    func testMaterialNormalizationRespectsDeclaredColorSpace() throws {
        let colors = try [
            CGColor(srgbRed: 0.5, green: 0.5, blue: 0.5, alpha: 0.4),
            XCTUnwrap(CGColor(
                colorSpace: XCTUnwrap(CGColorSpace(name: CGColorSpace.linearSRGB)),
                components: [0.21404114, 0.21404114, 0.21404114, 0.4]
            )),
        ]
        for color in colors {
            for linearColors in [false, true] {
                let material = MDLMaterial(name: "paint", scatteringFunction: MDLScatteringFunction())
                material.setProperty(MDLMaterialProperty(name: "baseColor", semantic: .baseColor, color: color))
                normalizeModelIOColors(material, linearColors: linearColors)
                let property = try XCTUnwrap(material.property(with: .baseColor))
                XCTAssertEqual(try XCTUnwrap(Color(property)), Color(white: 0.5, alpha: 0.4), accuracy: 1e-5)
            }
        }
    }

    func testExportColorConversionPreservesDataProperties() throws {
        let source = MDLMaterial(name: "paint", scatteringFunction: MDLScatteringFunction())
        let color = CGColor(srgbRed: 0.5, green: 0.25, blue: 0.75, alpha: 1)
        source.setProperty(MDLMaterialProperty(name: "baseColor", semantic: .baseColor, color: color))
        let dataSemantics: [MDLMaterialSemantic] = [.roughness, .opacity, .tangentSpaceNormal, .ambientOcclusion]
        for semantic in dataSemantics {
            source.setProperty(MDLMaterialProperty(name: "data-\(semantic.rawValue)", semantic: semantic, color: color))
        }
        let exported = source.forExport(linearColors: true)
        let base = try XCTUnwrap(exported.property(with: .baseColor))
        XCTAssertEqual(base.type, .float3)
        XCTAssertEqual(Double(base.float3Value.x), 0.21404114, accuracy: 1e-6)
        for semantic in dataSemantics {
            let property = try XCTUnwrap(exported.property(with: semantic))
            XCTAssertEqual(property.type, .color)
            XCTAssertEqual(property.color?.components, color.components)
        }
        XCTAssertEqual(source.property(with: .baseColor)?.type, .color)
        XCTAssertEqual(source.property(with: .baseColor)?.color?.components, color.components)
    }

    private func loadModelIO(_ url: URL) throws -> Mesh {
        let asset = MDLAsset(url: url)
        asset.loadTextures()
        let linearColors = url.pathExtension != "obj"
        var seen = Set<ObjectIdentifier>()
        return try Mesh(asset, linearColors: linearColors) { material in
            if seen.insert(ObjectIdentifier(material)).inserted {
                normalizeModelIOColors(material, linearColors: linearColors)
            }
            return material
        }
    }

    private func translation(_ x: Float, _ y: Float, _ z: Float) -> simd_float4x4 {
        var matrix = matrix_identity_float4x4
        matrix.columns.3 = [x, y, z, 1]
        return matrix
    }

    private func makeMesh(indices: [UInt16], type: MDLGeometryType, colors: Bool = false) -> MDLMesh {
        let allocator = MDLMeshBufferDataAllocator()
        let descriptor = MDLVertexDescriptor()
        descriptor.attributes[0] = MDLVertexAttribute(
            name: MDLVertexAttributePosition, format: .float3, offset: 0, bufferIndex: 0
        )
        var vertices: [Float] = []
        for position: [Float] in [[0, 0, 0], [1, 0, 0], [0, 1, 0], [1, 1, 0]] {
            vertices += position
            if colors { vertices += [0.5, 0.25, 0.75] }
        }
        if colors {
            descriptor.attributes[1] = MDLVertexAttribute(
                name: MDLVertexAttributeColor, format: .float3, offset: 12, bufferIndex: 0
            )
        }
        descriptor.layouts[0] = MDLVertexBufferLayout(stride: colors ? 24 : 12)
        return MDLMesh(
            vertexBuffer: allocator.newBuffer(with: vertices.withUnsafeBytes { Data($0) }, type: .vertex),
            vertexCount: 4, descriptor: descriptor, submeshes: [
                MDLSubmesh(
                    indexBuffer: allocator.newBuffer(with: indices.withUnsafeBytes { Data($0) }, type: .index),
                    indexCount: indices.count, indexType: .uInt16, geometryType: type, material: nil
                ),
            ]
        )
    }
}

#endif
