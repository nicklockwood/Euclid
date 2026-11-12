//
//  ModelIOExportTests.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 09/11/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

#if canImport(ModelIO)

@testable import Euclid
import ImageIO
@preconcurrency import ModelIO
import XCTest

#if canImport(SceneKit)
import SceneKit
#endif

final class ModelIOExportTests: XCTestCase {
    func testPolygonTopologyAndVertexAttributes() throws {
        let source = Mesh.cube().mapVertexColors { _ in Color(white: 0.5, alpha: 0.25) }
        let asset = try MDLAsset(source)
        let mesh = try XCTUnwrap(asset.object(at: 0) as? MDLMesh)
        let submesh = try XCTUnwrap(mesh.submeshes?.firstObject as? MDLSubmesh)
        XCTAssertEqual(submesh.geometryType, .variableTopology)
        XCTAssertEqual(submesh.topology?.faceCount, 6)
        XCTAssertEqual(submesh.indexCount, 24)
        let color = try XCTUnwrap(mesh.vertexAttributeData(forAttributeNamed: MDLVertexAttributeColor))
        let values = color.dataStart.assumingMemoryBound(to: Float.self)
        XCTAssertEqual(Double(values[0]), Color(white: 0.5).toLinear().red, accuracy: 0.00001)
        XCTAssertEqual(values[3], 0.25)
        XCTAssertNotNil(mesh.vertexAttributeData(forAttributeNamed: MDLVertexAttributeNormal))
        XCTAssertNotNil(mesh.vertexAttributeData(forAttributeNamed: MDLVertexAttributeTextureCoordinate))
    }

    func testMaterialMappingAndOpacity() throws {
        let material = MDLMaterial(name: "custom", scatteringFunction: MDLScatteringFunction())
        let asset = try MDLAsset(Mesh.cube().withMaterial("paint")) { value in
            value as? String == "paint" ? material : nil
        }
        let mesh = try XCTUnwrap(asset.object(at: 0) as? MDLMesh)
        XCTAssertTrue((mesh.submeshes?.firstObject as? MDLSubmesh)?.material === material)
        let colored = try MDLAsset(Mesh.cube().withMaterial(Color(white: 0.5, alpha: 0.25)))
        let coloredMesh = try XCTUnwrap(colored.object(at: 0) as? MDLMesh)
        let tint = try XCTUnwrap((coloredMesh.submeshes?.firstObject as? MDLSubmesh)?.material)
        XCTAssertEqual(Double(tint.property(with: .baseColor)?.float3Value.x ?? 0), 0.214041, accuracy: 0.00001)
        XCTAssertEqual(tint.property(with: .opacity)?.floatValue, 0.25)
    }

    func testMaterialLookupNilAndErrors() throws {
        let source = Mesh.cube().withMaterial(Color.black)
        let asset = try MDLAsset(source) { _ in nil }
        let mesh = try XCTUnwrap(asset.object(at: 0) as? MDLMesh)
        let material = try XCTUnwrap((mesh.submeshes?.firstObject as? MDLSubmesh)?.material)
        XCTAssertEqual(material.property(with: .baseColor)?.float3Value, SIMD3<Float>(repeating: 1))
        XCTAssertThrowsError(try MDLAsset(source) { _ in throw CancellationError() }) { error in
            XCTAssertTrue(error is CancellationError)
        }
    }

    #if canImport(SceneKit)

    func testSceneKitCompatibility() throws {
        let source = SCNMaterial()
        source.diffuse.contents = CGColor(gray: 0.5, alpha: 1)
        let asset = try MDLAsset(Mesh.cube().withMaterial(source), linearColors: false)
        let mesh = try XCTUnwrap(asset.object(at: 0) as? MDLMesh)
        XCTAssertNotNil((mesh.submeshes?.firstObject as? MDLSubmesh)?.material)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("euclid-scn-\(UUID())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        for ext in ["scn", "dae"] {
            let url = directory.appendingPathComponent("mesh.\(ext)")
            try Mesh.cube().write(to: url)
            // SceneKit emits XML on macOS and a binary representation on iOS.
            #if os(macOS)
            if ext == "dae" {
                XCTAssertTrue(try String(contentsOf: url).contains("<COLLADA"))
                continue
            }
            #endif
            let imported = try Mesh(url: url)
            XCTAssertFalse(imported.isEmpty)
            XCTAssertEqual(imported.bounds, Mesh.cube().bounds)
        }
    }

    #endif

    func testImageMaterialExport() throws {
        let pixels: [UInt8] = [128, 0, 0, 128, 0, 255, 0, 255, 0, 0, 255, 255, 255, 255, 255, 255]
        let space = try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB))
        let provider = try XCTUnwrap(CGDataProvider(data: Data(pixels) as CFData))
        let image = try XCTUnwrap(CGImage(
            width: 2, height: 2, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 8,
            space: space,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent
        ))
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("euclid-texture-\(UUID())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try Mesh.cube().withMaterial(image).write(to: directory.appendingPathComponent("mesh.obj"))
        let mtl = try String(contentsOf: directory.appendingPathComponent("mesh.mtl"))
        let textureLine = try XCTUnwrap(mtl.components(separatedBy: "\n").first {
            $0.trimmingCharacters(in: .whitespaces).hasPrefix("map_Kd ")
        })
        let path = textureLine.trimmingCharacters(in: .whitespaces).dropFirst(7)
        let url = directory.appendingPathComponent(String(path))
        let source = try XCTUnwrap(CGImageSourceCreateWithURL(url as CFURL, nil))
        let exported = try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
        XCTAssertEqual(exported.width, 2)
        XCTAssertEqual(exported.height, 2)
        var result = [UInt8](repeating: 0, count: 16)
        let context = try XCTUnwrap(CGContext(
            data: &result, width: 2, height: 2, bitsPerComponent: 8, bytesPerRow: 8,
            space: space,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.draw(exported, in: CGRect(x: 0, y: 0, width: 2, height: 2))
        XCTAssertEqual(result, pixels)
    }

    func testUSDMaterialLookupPreservesBindingsAndGeometry() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("euclid-usd-bindings-\(UUID())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let mesh = Mesh.merge([
            Mesh.cube(material: "paint").translated(by: [-1, 0, 0]),
            Mesh.cube(material: "default").translated(by: [1, 0, 0]),
        ])
        for ext in ["usd", "usda", "usdc"] where MDLAsset.canExportFileExtension(ext) {
            let url = directory.appendingPathComponent("mesh.\(ext)")
            try mesh.write(to: url) { value in
                value as? String == "paint" ? Color(red: 0.5, green: 0.25, blue: 0.75, alpha: 0.4) : nil
            }
            let asset = MDLAsset(url: url)
            let imported = try Mesh(asset)
            XCTAssertEqual(imported.bounds, mesh.bounds, accuracy: 1e-5)
            XCTAssertEqual(imported.surfaceArea, mesh.surfaceArea, accuracy: 1e-5)
            XCTAssertTrue(imported.hasTexcoords)
            for polygon in imported.polygons {
                let material = try XCTUnwrap(polygon.material as? MDLMaterial)
                let property = try XCTUnwrap(material.property(with: .baseColor))
                let color = try XCTUnwrap(Color(property, linearColors: true))
                let opacity = try XCTUnwrap(material.property(with: .opacity))
                let expected: Color = polygon.bounds.center.x < 0 ?
                    Color(red: 0.5, green: 0.25, blue: 0.75, alpha: 0.4) : .white
                XCTAssertEqual(color.withAlphaComponent(Double(opacity.floatValue)), expected, accuracy: 1e-5)
                for vertex in polygon.vertices {
                    XCTAssertEqual(vertex.normal.length, 1, accuracy: 1e-5)
                }
            }
        }
    }

    func testOBJAndUSDExport() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("euclid-modelio-\(UUID())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let mesh = Mesh.cube().withMaterial(Color(red: 0.5, green: 0.25, blue: 0.75, alpha: 0.4))
        for ext in ["obj", "usda"] {
            let url = directory.appendingPathComponent("mesh.\(ext)")
            if ext == "obj" {
                try mesh.withMaterial("paint").write(to: url) { material in
                    material as? String == "paint" ? Color(red: 0.5, green: 0.25, blue: 0.75, alpha: 0.4) : nil
                }
            } else {
                try mesh.write(to: url)
            }
            let text = try String(contentsOf: url)
            XCTAssertFalse(text.isEmpty)
            let loaded = MDLAsset(url: url)
            XCTAssertFalse(loaded.childObjects(of: MDLMesh.self).isEmpty)
            XCTAssertEqual(Double(loaded.boundingBox.minBounds.x), -0.5, accuracy: 0.00001)
            XCTAssertEqual(Double(loaded.boundingBox.maxBounds.z), 0.5, accuracy: 0.00001)
            if ext == "obj" {
                let mtl = try String(contentsOf: directory.appendingPathComponent("mesh.mtl"))
                XCTAssertTrue(mtl.contains("0.5 0.25 0.75"), mtl)
                XCTAssertTrue(mtl.contains("0.4"), mtl)
            } else {
                XCTAssertTrue(text.contains("0.214"), text)
                XCTAssertTrue(text.contains("inputs:opacity = 0.4"), text)
            }
        }
    }
}

#endif
