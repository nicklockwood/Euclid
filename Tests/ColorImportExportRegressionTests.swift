//
//  ColorImportExportRegressionTests.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 10/11/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import Foundation
import XCTest
#if canImport(FoundationXML)
import FoundationXML
#endif
#if canImport(ModelIO)
@preconcurrency import ModelIO
#endif
#if canImport(SceneKit)
import Metal
import SceneKit
#endif
#if canImport(RealityKit)
import RealityKit
#endif
#if canImport(ImageIO)
import ImageIO
#endif

/// Shared fixtures deliberately include midtones and independent alpha values: primary colors alone
/// cannot detect accidental sRGB conversions. No test regenerates its expected values from an export.
final class ColorImportExportRegressionTests: XCTestCase {
    private let swatches = [
        Color(red: 0, green: 0, blue: 0, alpha: 0),
        Color(red: 1, green: 1, blue: 1, alpha: 1),
        Color(red: 0.5, green: 0.25, blue: 0.75, alpha: 0.4),
        Color(red: 0.25, green: 0.5, blue: 0.125, alpha: 0.8),
        Color(red: 0.18, green: 0.18, blue: 0.18, alpha: 0.5),
        Color(red: 1, green: 0, blue: 0.5, alpha: 0.25),
    ]
    // IEC sRGB transfer function applied to the swatches above (alpha is never gamma encoded).
    private let linearSwatches = [
        Color(red: 0, green: 0, blue: 0, alpha: 0),
        Color(red: 1, green: 1, blue: 1, alpha: 1),
        Color(red: 0.2140411405, green: 0.0508760882, blue: 0.5225215540, alpha: 0.4),
        Color(red: 0.0508760882, green: 0.2140411405, blue: 0.0143498747, alpha: 0.8),
        Color(red: 0.02721178095, green: 0.02721178095, blue: 0.02721178095, alpha: 0.5),
        Color(red: 1, green: 0, blue: 0.2140411405, alpha: 0.25),
    ]
    private var directory: URL!
    private var retainArtifacts = false

    override func setUpWithError() throws {
        try super.setUpWithError()
        let output = ProcessInfo.processInfo.environment["EUCLID_COLOR_REGRESSION_OUTPUT"]
        retainArtifacts = output != nil
        let parent = output.map { URL(fileURLWithPath: $0, isDirectory: true) } ?? FileManager.default
            .temporaryDirectory
        directory = parent.appendingPathComponent("\(name)-\(UUID())", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        if retainArtifacts {
            let manifest = swatches.enumerated().map { index, color in
                ["index": index, "sRGB": [color.red, color.green, color.blue], "alpha": color.alpha] as [String: Any]
            }
            try JSONSerialization.data(withJSONObject: manifest, options: [.prettyPrinted, .sortedKeys])
                .write(to: directory.appendingPathComponent("expected-swatches.json"))
            #if canImport(SceneKit) && !os(watchOS)
            try fixture(vertexColors: true).write(to: directory.appendingPathComponent("reference.scn"))
            #endif
            print("Color regression artifacts: \(directory.path)")
        }
    }

    override func tearDownWithError() throws {
        if !retainArtifacts, let directory { try FileManager.default.removeItem(at: directory) }
        try super.tearDownWithError()
    }

    private func fixture(vertexColors: Bool) throws -> Mesh {
        try Mesh(swatches.enumerated().map { index, color in
            let x = Double(index % 3) * 1.25, y = Double(index / 3) * 1.25
            let positions: [Vector] = [[x, y, 0], [x + 1, y, 0], [x + 1, y + 1, 0], [x, y + 1, 0]]
            let uv: [Vector] = [[0, 0], [1, 0], [1, 1], [0, 1]]
            return try XCTUnwrap(Polygon(zip(positions, uv).map {
                Vertex($0.0, normal: .unitZ, texcoord: $0.1, color: vertexColors ? color : .white)
            }, material: vertexColors ? nil : color))
        })
    }

    private func export(_ mesh: Mesh, name: String, format: String) throws -> URL {
        let folder = directory.appendingPathComponent("\(name)-\(format)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appendingPathComponent("model.\(format)")
        try mesh.write(to: url)
        XCTAssertGreaterThan(try Data(contentsOf: url).count, 0, url.path)
        return url
    }

    private func assertColor(
        _ actual: Color, _ expected: Color, accuracy: Double = 1e-6,
        _ context: String, file: StaticString = #filePath, line: UInt = #line
    ) {
        let actualValues = [actual.red, actual.green, actual.blue, actual.alpha]
        let expectedValues = [expected.red, expected.green, expected.blue, expected.alpha]
        XCTAssertTrue(
            zip(actualValues, expectedValues).allSatisfy { abs($0 - $1) <= accuracy },
            "\(context): RGBA \(actualValues), expected \(expectedValues), tolerance \(accuracy)",
            file: file,
            line: line
        )
    }

    private func knownIssue(_ reason: String, _ body: () -> Void) {
        #if canImport(Darwin)
        let options = XCTExpectedFailure.Options.nonStrict()
        options.isEnabled = ProcessInfo.processInfo.environment["EUCLID_COLOR_REGRESSION_STRICT"] != "1"
        XCTExpectFailure(reason, options: options, failingBlock: body)
        #else
        body()
        #endif
    }

    private func assertVertexColors(
        _ actual: Mesh, _ expected: Mesh, accuracy: Double, context: String, issue: String? = nil
    ) throws {
        XCTAssertFalse(actual.isEmpty, context)
        XCTAssertEqual(actual.bounds, expected.bounds, accuracy: 1e-6, context)
        XCTAssertEqual(actual.surfaceArea, expected.surfaceArea, accuracy: 1e-6, context)
        let vertices = expected.polygons.flatMap(\.vertices)
        for vertex in actual.polygons.flatMap(\.vertices) {
            let reference = try XCTUnwrap(vertices.first { $0.position.isApproximatelyEqual(to: vertex.position) })
            if let issue {
                knownIssue(issue) { assertColor(vertex.color, reference.color, accuracy: accuracy, context) }
            } else {
                assertColor(vertex.color, reference.color, accuracy: accuracy, context)
            }
        }
    }

    func testPLYMaterialAndVertexSwatches() throws {
        let expected = try fixture(vertexColors: true)
        for useVertices in [false, true] {
            let url = try export(
                fixture(vertexColors: useVertices),
                name: useVertices ? "vertices" : "materials",
                format: "ply"
            )
            let imported = try Mesh(url: url)
            try assertVertexColors(imported, expected, accuracy: 0.5 / 255 + 1e-8, context: "PLY")
            // Independently inspect the stored bytes: paired reader/writer gamma bugs must not cancel out.
            let text = try String(contentsOf: url, encoding: .utf8)
            let body = try XCTUnwrap(text.components(separatedBy: "end_header\n").last)
            let rows = body.split(separator: "\n").prefix(36)
            XCTAssertEqual(rows.count, 36)
            for (index, row) in rows.enumerated() {
                let components = row.split(whereSeparator: \.isWhitespace).suffix(4).compactMap(Double.init)
                let actual = try XCTUnwrap(Color(components.map { $0 / 255 }))
                assertColor(actual, swatches[index / 6], accuracy: 0.5 / 255 + 1e-8, "PLY stored bytes")
            }
        }
    }

    func testPLYTintAndGradient() throws {
        let mesh = try Mesh([XCTUnwrap(Polygon([
            Vertex([0, 0, 0], color: Color(white: 0.5, alpha: 0.5)),
            Vertex([1, 0, 0], color: .white),
            Vertex([0, 1, 0], color: Color(white: 0, alpha: 0)),
        ], material: Color(white: 0.5, alpha: 0.5)))])
        let url = try export(mesh, name: "tinted-gradient", format: "ply")
        let imported = try Mesh(url: url)
        let expected = [
            Color(white: 60 / 255.0, alpha: 64 / 255.0),
            Color(white: 128 / 255.0, alpha: 128 / 255.0),
            .clear,
        ]
        for (index, position) in [Vector.zero, .unitX, .unitY].enumerated() {
            let color = try XCTUnwrap(imported.polygons.flatMap(\.vertices).first { $0.position == position }?.color)
            assertColor(color, expected[index], "PLY tinted gradient")
        }
    }

    func testNativeOBJVertexRGB() throws {
        let mesh = try fixture(vertexColors: true)
        let text = mesh.objString()
        try text.write(to: directory.appendingPathComponent("native.obj"), atomically: true, encoding: .utf8)
        let imported = try XCTUnwrap(Mesh(objString: text))
        let expected = mesh.mapVertexColors { $0.withAlphaComponent(1) } // OBJ's RGB extension has no alpha.
        try assertVertexColors(imported, expected, accuracy: 1e-6, context: "Native OBJ")
        let rows = text.split(separator: "\n").filter { $0.hasPrefix("v ") }
        XCTAssertEqual(rows.count, 24)
        for (index, row) in rows.enumerated() {
            let values = row.split(whereSeparator: \.isWhitespace).dropFirst(4).compactMap(Double.init)
            let color = try XCTUnwrap(Color(values))
            assertColor(color, swatches[index / 4].withAlphaComponent(1), "Native OBJ stored RGB")
        }
    }

    func testSTLFacetRGBQuantization() throws {
        let mesh = try fixture(vertexColors: false)
        let url = try export(mesh, name: "materials", format: "stl")
        let data = try Data(contentsOf: url)
        let imported = try Mesh(url: url, materialLookup: { $0 })
        XCTAssertEqual(imported.polygons.count, 12)
        for (index, polygon) in imported.polygons.enumerated() {
            let expected = swatches[index / 2].withAlphaComponent(1)
            try assertColor(XCTUnwrap(polygon.material as? Color), expected, accuracy: 0.5 / 31 + 1e-8, "STL facet")
            let offset = 84 + index * 50 + 48
            let bits = UInt16(data[offset]) | UInt16(data[offset + 1]) << 8
            XCTAssertNotEqual(bits & 0x8000, 0)
            let stored = Color(
                red: Double((bits >> 10) & 31) / 31,
                green: Double((bits >> 5) & 31) / 31,
                blue: Double(bits & 31) / 31
            )
            assertColor(stored, expected, accuracy: 0.5 / 31 + 1e-8, "STL stored RGB")
        }
    }

    func testGeometryOnlyNativeFormats() throws {
        let mesh = try fixture(vertexColors: true)
        for format in ["off", "stla"] {
            let url = try export(mesh, name: "vertices", format: format)
            let imported = try Mesh(url: url)
            try assertVertexColors(imported, mesh.mapVertexColors { _ in .white }, accuracy: 1e-6, context: format)
            XCTAssertTrue(imported.polygons.allSatisfy { $0.material == nil }, format)
        }
    }

    #if canImport(ModelIO)

    func testOBJMaterialSwatches() throws { try checkModelIOMaterials(format: "obj") }
    func testUSDAMaterialSwatches() throws { try checkModelIOMaterials(format: "usda") }
    func testUSDCMaterialSwatches() throws { try checkModelIOMaterials(format: "usdc") }
    func testUSDMaterialSwatches() throws { try checkModelIOMaterials(format: "usd") }
    func testUSDZMaterialSwatches() throws { try checkModelIOMaterials(format: "usdz") }

    private func checkModelIOMaterials(format: String) throws {
        guard format == "usdz" || MDLAsset.canExportFileExtension(format)
        else { throw XCTSkip("Model I/O cannot export \(format) on this OS") }
        let url = try export(fixture(vertexColors: false), name: "materials", format: format)
        let asset = MDLAsset(url: url)
        let meshes = asset.childObjects(of: MDLMesh.self).compactMap { $0 as? MDLMesh }
        XCTAssertFalse(meshes.isEmpty)
        var seen = Set<Int>()
        for mesh in meshes {
            let positions = try XCTUnwrap(mesh.vertexAttributeData(forAttributeNamed: MDLVertexAttributePosition))
            for submesh in mesh.submeshes as? [MDLSubmesh] ?? [] {
                let index = Int(submesh.indexBuffer(asIndexType: .uInt32).map().bytes.load(as: UInt32.self))
                let position = positions.dataStart.advanced(by: index * positions.stride)
                let x = Double(position.loadUnaligned(as: Float.self))
                let y = Double(position.loadUnaligned(fromByteOffset: 4, as: Float.self))
                let swatch = Int(floor(x / 1.25)) + Int(floor(y / 1.25)) * 3
                XCTAssertTrue(swatches.indices.contains(swatch))
                guard swatches.indices.contains(swatch) else { continue }
                seen.insert(swatch)
                let material = try XCTUnwrap(submesh.material)
                let base = try XCTUnwrap(material.property(with: .baseColor))
                let rgb: SIMD3<Float>
                if base.type == .color {
                    let color = try XCTUnwrap(base.color)
                    let components = try XCTUnwrap(color.components)
                    XCTAssertGreaterThanOrEqual(components.count, 3)
                    guard components.count >= 3 else { continue }
                    rgb = SIMD3(Float(components[0]), Float(components[1]), Float(components[2]))
                } else {
                    XCTAssertEqual(base.type, .float3)
                    rgb = base.float3Value
                }
                let opacity = material.property(with: .opacity)?.floatValue ?? 1
                let expected = format == "obj" ? swatches[swatch] : linearSwatches[swatch]
                let actual = Color(
                    red: Double(rgb.x),
                    green: Double(rgb.y),
                    blue: Double(rgb.z),
                    alpha: Double(opacity)
                )
                assertColor(actual, expected, accuracy: 1e-5, "\(format) swatch \(swatch)")
            }
        }
        XCTAssertEqual(seen, Set(swatches.indices))
        if format == "usda" {
            // Check authored shader values independently of the platform reader.
            let text = try String(contentsOf: url, encoding: .utf8)
            let colors = text.components(separatedBy: "\n").filter { $0.contains("inputs:diffuseColor =") }
            let alphas = text.components(separatedBy: "\n").filter { $0.contains("inputs:opacity =") }
            XCTAssertEqual(colors.count, swatches.count)
            XCTAssertEqual(alphas.count, swatches.count)
            var authored = [Color]()
            for pair in zip(colors, alphas) {
                let values = try XCTUnwrap(pair.0.components(separatedBy: "=").last)
                    .split { "(), ".contains($0) }.compactMap(Double.init)
                let alphaText = try XCTUnwrap(pair.1.components(separatedBy: "=").last)
                let alpha = try XCTUnwrap(Double(alphaText.trimmingCharacters(in: .whitespaces)))
                try authored.append(XCTUnwrap(Color(values + [alpha])))
            }
            for expected in linearSwatches {
                XCTAssertTrue(
                    authored.contains { $0.isApproximatelyEqual(to: expected, absoluteTolerance: 1e-6) },
                    "Missing USD authored shader color \(expected)"
                )
            }
        }
    }

    #if canImport(ImageIO)

    func testOBJTextureRGBA() throws { try checkTexture(format: "obj") }
    func testUSDATextureRGBA() throws { try checkTexture(format: "usda") }
    func testUSDCTextureRGBA() throws { try checkTexture(format: "usdc") }
    func testUSDTextureRGBA() throws { try checkTexture(format: "usd") }

    func testOBJLinearTextureProfile() throws {
        try checkTexture(format: "obj", colorSpace: CGColorSpace.linearSRGB)
    }

    func testOBJDisplayP3TextureProfile() throws {
        try checkTexture(format: "obj", colorSpace: CGColorSpace.displayP3)
    }

    private func checkTexture(format: String, colorSpace: CFString = CGColorSpace.sRGB) throws {
        guard MDLAsset.canExportFileExtension(format) else { throw XCTSkip("Exporter unavailable: \(format)") }
        let space = try XCTUnwrap(CGColorSpace(name: colorSpace))
        let pixels = swatches.flatMap { color in
            [color.red * color.alpha, color.green * color.alpha, color.blue * color.alpha, color.alpha]
                .map { UInt8(($0 * 255).rounded()) }
        }
        let provider = try XCTUnwrap(CGDataProvider(data: Data(pixels) as CFData))
        let image = try XCTUnwrap(CGImage(
            width: 3, height: 2, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 12,
            space: space, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent
        ))
        // Resolve the source profile independently of export, into the comparison space.
        let comparisonSpace = try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB))
        var expectedPixels = [UInt8](repeating: 0, count: pixels.count)
        let reference = try XCTUnwrap(CGContext(
            data: &expectedPixels, width: 3, height: 2, bitsPerComponent: 8, bytesPerRow: 12,
            space: comparisonSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        reference.draw(image, in: CGRect(x: 0, y: 0, width: 3, height: 2))
        let mesh = Mesh.cube().withMaterial(image)
        let url = try export(mesh, name: "texture", format: format)
        let files = try XCTUnwrap(FileManager.default.enumerator(
            at: url.deletingLastPathComponent(), includingPropertiesForKeys: nil
        )).allObjects.compactMap { $0 as? URL }.filter { $0.pathExtension == "png" }
        XCTAssertFalse(files.isEmpty, "Missing exported base-color texture")
        for file in files {
            let source = try XCTUnwrap(CGImageSourceCreateWithURL(file as CFURL, nil))
            let decoded = try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
            XCTAssertEqual(decoded.width, 3)
            XCTAssertEqual(decoded.height, 2)
            var actual = [UInt8](repeating: 0, count: pixels.count)
            let context = try XCTUnwrap(CGContext(
                data: &actual, width: 3, height: 2, bitsPerComponent: 8, bytesPerRow: 12,
                space: comparisonSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ))
            context.draw(decoded, in: CGRect(x: 0, y: 0, width: 3, height: 2))
            for (index, pair) in zip(actual, expectedPixels).enumerated() {
                if index % 4 == 3 {
                    XCTAssertEqual(pair.0, pair.1, "\(format) texture alpha byte \(index)")
                } else {
                    XCTAssertLessThanOrEqual(
                        abs(Int(pair.0) - Int(pair.1)),
                        1,
                        "\(format) texture byte \(index): \(pair.0), expected \(pair.1)"
                    )
                }
            }
        }
        // Inspect the material reached from geometry, not just orphan image files in the directory.
        let asset = MDLAsset(url: url)
        asset.loadTextures()
        let meshes = asset.childObjects(of: MDLMesh.self).compactMap { $0 as? MDLMesh }
        XCTAssertFalse(meshes.isEmpty)
        for mesh in meshes {
            let submeshes = try XCTUnwrap(mesh.submeshes as? [MDLSubmesh])
            XCTAssertFalse(submeshes.isEmpty)
            for submesh in submeshes {
                let material = try XCTUnwrap(submesh.material)
                let base = material.property(with: .baseColor)
                XCTAssertNotNil(base?.textureSamplerValue?.texture, "\(format) texture connection")
            }
        }
        // Pixel alpha and texture connectivity are checked separately from rendered opacity.
    }

    #endif

    func testAlembicGeometryOnly() throws {
        guard MDLAsset.canExportFileExtension("abc") else { throw XCTSkip("Alembic exporter unavailable") }
        let mesh = try fixture(vertexColors: true)
        let url = try export(mesh, name: "vertices", format: "abc")
        let asset = MDLAsset(url: url)
        XCTAssertFalse(asset.childObjects(of: MDLMesh.self).isEmpty)
        knownIssue("Model I/O Alembic round trip reports an empty bounding box for polygon topology") {
            XCTAssertEqual(Double(asset.boundingBox.maxBounds.x), mesh.bounds.max.x, accuracy: 1e-6)
        }
        // Apple's Alembic exporter is geometry-only. Do not assert that it preserves appearance.
    }

    #endif

    #if canImport(SceneKit) && !os(watchOS)

    func testOBJVertexSwatches() throws { try checkPlatformVertices(format: "obj") }
    func testUSDAVertexSwatches() throws { try checkPlatformVertices(format: "usda") }
    func testUSDCVertexSwatches() throws { try checkPlatformVertices(format: "usdc") }

    private func checkPlatformVertices(format: String) throws {
        let mesh = try fixture(vertexColors: true)
        let url = try export(mesh, name: "vertices", format: format)
        let imported = try Mesh(url: url)
        try assertVertexColors(
            imported.mapVertexColors { $0.withAlphaComponent(1) }, mesh.mapVertexColors { $0.withAlphaComponent(1) },
            accuracy: 1e-5, context: "\(format) RGB",
            issue: format == "obj" ? nil :
                "SceneKit USD import does not restore exported displayColor vertex data"
        )
        if format != "obj" {
            // Isolate alpha from the independently checked RGB limitation.
            try assertVertexColors(
                imported.mapVertexColors { Color(white: 1, alpha: $0.alpha) },
                mesh.mapVertexColors { Color(white: 1, alpha: $0.alpha) },
                accuracy: 1e-5, context: "\(format) alpha", issue: "Model I/O USD export drops vertex alpha"
            )
            if format == "usda" {
                let text = try String(contentsOf: url, encoding: .utf8)
                let line = try XCTUnwrap(text.components(separatedBy: "\n")
                    .first { $0.contains("primvars:displayColor =") })
                let body = try XCTUnwrap(line.components(separatedBy: "=").last)
                let values = body.split { "[](), ".contains($0) }.compactMap(Double.init)
                XCTAssertEqual(values.count, 24 * 3)
                for index in 0 ..< min(24, values.count / 3) {
                    let color = try XCTUnwrap(Color(values[(index * 3) ..< (index * 3 + 3)]))
                    assertColor(
                        color,
                        linearSwatches[index / 4].withAlphaComponent(1),
                        accuracy: 1e-6,
                        "USD stored displayColor"
                    )
                }
            }
        }
    }

    func testColladaVertexSwatches() throws {
        let mesh = try fixture(vertexColors: true)
        let url = try export(mesh, name: "vertices", format: "dae")
        #if os(macOS)
        let text = try String(contentsOf: url, encoding: .utf8)
        let parser = XMLParser(data: Data(text.utf8))
        let arrays = ColladaColorArrays()
        parser.delegate = arrays
        XCTAssertTrue(parser.parse(), parser.parserError?.localizedDescription ?? "Invalid Collada XML")
        XCTAssertFalse(arrays.colorSources.isEmpty, "No Collada color source found")
        for source in arrays.colorSources {
            let values = try XCTUnwrap(arrays.values[source])
            XCTAssertEqual(values.count, 24 * 4)
            guard values.count == 24 * 4 else { continue }
            for index in 0 ..< 24 {
                let color = try XCTUnwrap(Color(values[(index * 4) ..< (index * 4 + 4)]))
                // Verify SceneKit serializes the linear RGB supplied by our adapter.
                // This is a platform compatibility check, not a universal Collada color-space requirement.
                assertColor(color, linearSwatches[index / 4], accuracy: 1e-6, "SceneKit Collada stored vertex")
            }
        }
        #else
        // iOS SceneKit emits its binary scene representation under the DAE extension.
        try assertVertexColors(Mesh(url: url), mesh, accuracy: 1e-6, context: "Binary SceneKit DAE")
        #endif
    }

    func testColladaMaterialSwatches() throws {
        #if os(macOS)
        let url = try export(fixture(vertexColors: false), name: "materials", format: "dae")
        let xml = try XMLDocument(contentsOf: url)
        let effects = try xml.nodes(forXPath: "//*[local-name()='effect']")
        XCTAssertEqual(effects.count, swatches.count)
        let materials = try xml.nodes(forXPath: "//*[local-name()='material']")
        let bindings = try xml.nodes(forXPath: "//*[local-name()='instance_material']")
        XCTAssertEqual(materials.count, swatches.count)
        XCTAssertEqual(bindings.count, swatches.count)
        let triangles = try xml.nodes(forXPath: "//*[local-name()='triangles']")
        let sources = try xml.nodes(forXPath: "//*[local-name()='source']")
        let vertices = try xml.nodes(forXPath: "//*[local-name()='vertices']")
        var seen = Set<Int>()
        for binding in bindings {
            let symbol = try XCTUnwrap((binding as? XMLElement)?.attribute(forName: "symbol")?.stringValue)
            let primitive = try XCTUnwrap(triangles.first {
                ($0 as? XMLElement)?.attribute(forName: "material")?.stringValue == symbol
            })
            let indices = try XCTUnwrap(primitive.nodes(forXPath: "./*[local-name()='p']").first?.stringValue)
            let vertexIndex = try XCTUnwrap(indices.split(whereSeparator: { $0.isWhitespace }).first
                .flatMap { Int($0) })
            let vertexURL = try XCTUnwrap(primitive
                .nodes(forXPath: "./*[local-name()='input'][@semantic='VERTEX']/@source").first?.stringValue)
            let vertexSource = try XCTUnwrap(vertices.first {
                ($0 as? XMLElement)?.attribute(forName: "id")?.stringValue == String(vertexURL.dropFirst())
            })
            let positionURL = try XCTUnwrap(vertexSource
                .nodes(forXPath: "./*[local-name()='input'][@semantic='POSITION']/@source").first?.stringValue)
            let positions = try XCTUnwrap(sources.first {
                ($0 as? XMLElement)?.attribute(forName: "id")?.stringValue == String(positionURL.dropFirst())
            })
            let values = try XCTUnwrap(positions.nodes(forXPath: "./*[local-name()='float_array']").first?.stringValue)
                .split(whereSeparator: { $0.isWhitespace }).compactMap { Double($0) }
            XCTAssertTrue(values.indices.contains(vertexIndex * 3 + 1))
            guard vertexIndex >= 0, values.indices.contains(vertexIndex * 3 + 1) else { continue }
            let index = Int(floor(values[vertexIndex * 3] / 1.25)) + Int(floor(values[vertexIndex * 3 + 1] / 1.25)) * 3
            XCTAssertTrue(swatches.indices.contains(index))
            guard swatches.indices.contains(index) else { continue }
            seen.insert(index)
            let target = try XCTUnwrap((binding as? XMLElement)?.attribute(forName: "target")?.stringValue)
            let material = try XCTUnwrap(materials.first {
                ($0 as? XMLElement)?.attribute(forName: "id")?.stringValue == String(target.dropFirst())
            })
            let effectURL = try XCTUnwrap(material.nodes(forXPath: "./*[local-name()='instance_effect']/@url").first?
                .stringValue)
            let effect = try XCTUnwrap(effects.first {
                ($0 as? XMLElement)?.attribute(forName: "id")?.stringValue == String(effectURL.dropFirst())
            })
            let colorText = try XCTUnwrap(effect.nodes(forXPath: ".//*[local-name()='diffuse']/*[local-name()='color']")
                .first?.stringValue)
            let color =
                try XCTUnwrap(Color(colorText.split(whereSeparator: { $0.isWhitespace }).compactMap { Double($0) }))
            assertColor(color, swatches[index], "Collada authored material RGBA")
            let opacity = try XCTUnwrap(effect
                .nodes(forXPath: ".//*[local-name()='transparency']/*[local-name()='float']").first?.stringValue)
            XCTAssertEqual(Double(opacity), 1, "Diffuse alpha must not be applied twice")
        }
        XCTAssertEqual(seen, Set(swatches.indices))
        #else
        try checkSceneKitSwatches(format: "dae")
        #endif
    }

    @MainActor
    private func pixelRenderer(ambientLight: Bool = false) throws -> (SCNGeometry) throws -> [UInt8] {
        try XCTSkipIf(MTLCreateSystemDefaultDevice() == nil, "SceneKit requires a Metal device")
        let device = try XCTUnwrap(MTLCreateSystemDefaultDevice())
        let queue = try XCTUnwrap(device.makeCommandQueue())
        let renderer = SCNRenderer(device: device, options: nil)
        let scene = SCNScene()
        let node = SCNNode()
        scene.rootNode.addChildNode(node)
        if ambientLight {
            let light = SCNNode()
            light.light = SCNLight()
            light.light?.type = .ambient
            light.light?.intensity = 1000
            scene.rootNode.addChildNode(light)
        }
        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.position = SCNVector3(0, 0, 3)
        scene.rootNode.addChildNode(camera)
        renderer.scene = scene
        renderer.pointOfView = camera
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm_srgb, width: 32, height: 32, mipmapped: false
        )
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .shared
        let texture = try XCTUnwrap(device.makeTexture(descriptor: descriptor))
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = texture
        pass.colorAttachments[0].loadAction = .clear
        pass.colorAttachments[0].storeAction = .store
        let depthDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .depth32Float_stencil8, width: 32, height: 32, mipmapped: false
        )
        depthDescriptor.usage = .renderTarget
        depthDescriptor.storageMode = .private
        let depth = try XCTUnwrap(device.makeTexture(descriptor: depthDescriptor))
        pass.depthAttachment.texture = depth
        pass.depthAttachment.loadAction = .clear
        pass.depthAttachment.clearDepth = 1
        pass.stencilAttachment.texture = depth
        pass.stencilAttachment.loadAction = .clear
        func renderPixel(_ geometry: SCNGeometry) throws -> [UInt8] {
            node.geometry = geometry
            SCNTransaction.flush()
            let buffer = try XCTUnwrap(queue.makeCommandBuffer())
            renderer.render(
                atTime: 0, viewport: CGRect(x: 0, y: 0, width: 32, height: 32),
                commandBuffer: buffer, passDescriptor: pass
            )
            buffer.commit()
            buffer.waitUntilCompleted()
            XCTAssertNil(buffer.error)
            var pixel = [UInt8](repeating: 0, count: 4)
            texture.getBytes(&pixel, bytesPerRow: 4, from: MTLRegionMake2D(16, 16, 1, 1), mipmapLevel: 0)
            return pixel
        }

        return renderPixel
    }

    @MainActor
    func testSceneKitTexturedTintAndVertexAlphaRoundTrip() throws {
        let renderPixel = try pixelRenderer()
        let pixels: [UInt8] = [96, 48, 144, 192] // Premultiplied, with independent texture alpha.
        let image = try XCTUnwrap(CGImage(
            width: 1, height: 1, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 4,
            space: XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB)),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: XCTUnwrap(CGDataProvider(data: Data(pixels) as CFData)),
            decode: nil, shouldInterpolate: false, intent: .defaultIntent
        ))
        let material = SCNMaterial()
        material.lightingModel = .constant
        material.diffuse.contents = image
        material.multiply.contents = CGColor(srgbRed: 0.75, green: 0.5, blue: 0.25, alpha: 0.8)
        material.transparency = 0.7
        let mesh = Mesh.fill(.square(size: 2), faces: .front, material: material)
            .mapVertexColors { _ in Color(red: 0.5, green: 0.75, blue: 0.25, alpha: 0.6) }
        let expected = try renderPixel(SCNGeometry(mesh))
        XCTAssertGreaterThan(expected[3], 0, "Reference must actually render")
        XCTAssertGreaterThan(expected.prefix(3).reduce(0) { $0 + Int($1) }, 0)
        material.transparency = 0
        let invisible = try renderPixel(SCNGeometry(mesh))
        XCTAssertNotEqual(
            Array(expected.prefix(3)),
            Array(invisible.prefix(3)),
            "Opacity must affect the rendered color"
        )
        material.transparency = 0.7
        for format in ["scn", "scnz"] {
            let url = try export(mesh, name: "textured-tint-alpha", format: format)
            let imported = try Mesh(url: url)
            let actual = try renderPixel(SCNGeometry(imported))
            for channel in 0 ..< 4 {
                XCTAssertEqual(
                    Double(actual[channel]),
                    Double(expected[channel]),
                    accuracy: 2,
                    "\(format) rendered BGRA channel \(channel)"
                )
            }
        }
    }

    func testSceneKitCombinedVertexTintAndOpacity() throws {
        for format in ["scn", "scnz"] {
            let tint = Color(red: 0.5, green: 0.25, blue: 0.75, alpha: 0.4)
            let source = try fixture(vertexColors: true).withMaterial(tint)
            let url = try export(source, name: "combined", format: format)
            let imported = try Mesh(url: url)
            try assertVertexColors(imported, source, accuracy: 1e-5, context: "\(format) independent vertex RGBA")
            for polygon in imported.polygons {
                let material = try XCTUnwrap(polygon.material as? SCNMaterial)
                let color = try XCTUnwrap(defaultColorMapping(material.diffuse.contents as? AnyHashable))
                assertColor(
                    color.withAlphaComponent(color.alpha * Double(material.transparency)),
                    tint,
                    accuracy: 1e-5,
                    "\(format) independent material RGBA"
                )
            }
        }
    }

    @MainActor
    func testOBJExportedTextureRenderedOpacity() throws { try checkExportedTextureOpacity(format: "obj") }

    @MainActor
    func testUSDExportedTextureRenderedOpacity() throws { try checkExportedTextureOpacity(format: "usda") }

    @MainActor
    private func checkExportedTextureOpacity(format: String) throws {
        let pixels: [UInt8] = [32, 16, 48, 64]
        let image = try XCTUnwrap(CGImage(
            width: 1, height: 1, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 4,
            space: XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB)),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: XCTUnwrap(CGDataProvider(data: Data(pixels) as CFData)),
            decode: nil, shouldInterpolate: false, intent: .defaultIntent
        ))
        let mesh = Mesh.fill(.square(size: 2), faces: .front, material: image)
        let reference = SCNGeometry(mesh)
        reference.firstMaterial?.lightingModel = .constant
        let renderPixel = try pixelRenderer()
        let expected = try renderPixel(reference)
        XCTAssertGreaterThan(expected.prefix(3).reduce(0) { $0 + Int($1) }, 0)
        let url = try export(mesh, name: "rendered-texture-opacity", format: format)
        let geometry = try SCNGeometry(Mesh(url: url))
        for material in geometry.materials {
            material.lightingModel = .constant
        }
        let actual = try renderPixel(geometry)
        for channel in 0 ..< 4 {
            let check = { [self] in
                XCTAssertEqual(
                    Double(actual[channel]),
                    Double(expected[channel]),
                    accuracy: 2,
                    "\(format) exported texture BGRA channel \(channel): \(actual) versus \(expected)"
                )
            }
            check()
        }
    }

    private func independentFixture(
        format: String,
        textured: Bool,
        opacityChannel: String? = nil,
        dissolve: Double = 1
    ) throws -> URL {
        if textured {
            let opacity: [UInt8] = opacityChannel == nil ? [64, 64, 64, 255] : [16, 48, 96, 192]
            for (name, pixels) in [("color", [UInt8(128), 64, 192, 255]), ("opacity", opacity)] {
                let image = try XCTUnwrap(CGImage(
                    width: 1, height: 1, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 4,
                    space: XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB)),
                    bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                    provider: XCTUnwrap(CGDataProvider(data: Data(pixels) as CFData)),
                    decode: nil, shouldInterpolate: false, intent: .defaultIntent
                ))
                let url = directory.appendingPathComponent("\(name).png")
                let destination = try XCTUnwrap(CGImageDestinationCreateWithURL(
                    url as CFURL,
                    "public.png" as CFString,
                    1,
                    nil
                ))
                CGImageDestinationAddImage(destination, image, nil)
                XCTAssertTrue(CGImageDestinationFinalize(destination))
            }
        }
        let contents: String
        switch format {
        case "obj":
            contents = ColorImportFixtures.obj
            let mtl = ColorImportFixtures.texturedMTL.replacingOccurrences(
                of: "map_d opacity.png", with: "map_d \(opacityChannel.map { "-imfchan \($0) " } ?? "")opacity.png"
            ).replacingOccurrences(of: "d 1\n", with: "d \(dissolve)\n")
            try mtl.write(
                to: directory.appendingPathComponent("input.mtl"),
                atomically: true,
                encoding: .utf8
            )
        case "usda": contents = ColorImportFixtures.usd(textured: textured)
        case "dae": contents = ColorImportFixtures.collada(textured: textured)
        default: throw Mesh.IOError("Unsupported test fixture")
        }
        let url = directory.appendingPathComponent("input.\(format)")
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func importIndependentFixture(_ url: URL) throws -> Mesh {
        do { return try Mesh(url: url) } catch {
            let nsError = error as NSError
            if url.pathExtension == "dae" {
                if nsError.domain == NSCocoaErrorDomain, nsError.code == 4864 {
                    throw XCTSkip("SceneKit's Collada XPC loader is unavailable: \(error)")
                }
                #if !os(macOS)
                // These platforms can load SceneKit's binary DAE export but reject raw Collada XML.
                // SCNScene's nil result and the cancellable SCNSceneSource loader report this
                // unsupported input differently. Keep other loading errors visible.
                let isCorruptFile = nsError.domain == NSCocoaErrorDomain &&
                    nsError.code == CocoaError.fileReadCorruptFile.rawValue
                if String(describing: error) == "nilError" || isCorruptFile {
                    throw XCTSkip("SceneKit cannot load raw Collada XML on this OS: \(error)")
                }
                #endif
            }
            throw error
        }
    }

    func testIndependentUSDMaterialImport() throws {
        let url = try independentFixture(format: "usda", textured: false)
        let mesh = try Mesh(MDLAsset(url: url))
        XCTAssertFalse(mesh.isEmpty)
        XCTAssertEqual(mesh.surfaceArea, 4, accuracy: 1e-6)
        for polygon in mesh.polygons {
            let material = try XCTUnwrap(polygon.material as? MDLMaterial)
            let property = try XCTUnwrap(material.property(with: .baseColor))
            let color = try XCTUnwrap(Color(property, linearColors: true))
            let opacity = try XCTUnwrap(material.property(with: .opacity))
            XCTAssertEqual(opacity.type, .float)
            assertColor(
                color.withAlphaComponent(Double(opacity.floatValue)),
                swatches[2],
                accuracy: 1e-5,
                "Independent USD Model I/O material"
            )
        }
    }

    @MainActor
    func testUSDMaterialColorSpaceMetadata() throws {
        let cases: [(String, String?, String?, String?, CFString)] = [
            ("default", nil, nil, nil, CGColorSpace.linearSRGB),
            ("attribute_rec709", nil, nil, "lin_rec709_scene", CGColorSpace.linearSRGB),
            ("attribute_p3", nil, nil, "lin_p3d65_scene", CGColorSpace.linearDisplayP3),
            ("attribute_acescg", nil, nil, "lin_ap1_scene", CGColorSpace.acescgLinear),
            ("attribute_srgb", nil, nil, "srgb_rec709_scene", CGColorSpace.sRGB),
            ("shader_p3", nil, "lin_p3d65_scene", nil, CGColorSpace.linearDisplayP3),
            ("inherited_acescg", "lin_ap1_scene", nil, nil, CGColorSpace.acescgLinear),
            ("shader_overrides_root", "lin_p3d65_scene", "lin_rec709_scene", nil, CGColorSpace.linearSRGB),
            (
                "attribute_overrides_both",
                "lin_ap1_scene",
                "lin_p3d65_scene",
                "lin_rec709_scene",
                CGColorSpace.linearSRGB
            ),
            (
                "attribute_p3_overrides_both",
                "lin_rec709_scene",
                "lin_ap1_scene",
                "lin_p3d65_scene",
                CGColorSpace.linearDisplayP3
            ),
        ]
        var records = [[String: Any]]()
        for (name, root, shader, attribute, space) in cases {
            let text = ColorImportFixtures.usdColorSpace(root: root, shader: shader, attribute: attribute)
            let color = try XCTUnwrap(CGColor(
                colorSpace: XCTUnwrap(CGColorSpace(name: space)), components: [0.2, 0.35, 0.5, 1]
            ))
            records += try auditUSDColorSpace(name: name, text: text, expected: Color(color), textured: false)
        }
        try writeColorSpaceReport(records, name: "material-color-spaces")
    }

    @MainActor
    func testUSDTextureColorSpaceMetadata() throws {
        // Use identical sRGB-tagged PNG bytes. Explicit declarations must override those defaults.
        _ = try independentFixture(format: "usda", textured: true)
        let cases: [(String, String?, String?, String?, String?, CFString)] = [
            ("texture_auto", nil, nil, nil, "auto", CGColorSpace.sRGB),
            ("texture_srgb", nil, nil, nil, "sRGB", CGColorSpace.sRGB),
            ("texture_raw", nil, nil, nil, "raw", CGColorSpace.linearSRGB),
            ("texture_attribute_srgb", nil, nil, "srgb_rec709_scene", nil, CGColorSpace.sRGB),
            ("texture_attribute_data", nil, nil, "data", nil, CGColorSpace.linearSRGB),
            ("texture_attribute_p3", nil, nil, "srgb_p3d65_scene", nil, CGColorSpace.displayP3),
            ("texture_attribute_acescg", nil, nil, "lin_ap1_scene", nil, CGColorSpace.acescgLinear),
            ("texture_shader_p3", nil, "srgb_p3d65_scene", nil, nil, CGColorSpace.displayP3),
            ("texture_inherited_p3", "srgb_p3d65_scene", nil, nil, nil, CGColorSpace.displayP3),
            ("texture_attribute_overrides_root", "srgb_p3d65_scene", nil, "srgb_rec709_scene", nil, CGColorSpace.sRGB),
        ]
        var records = [[String: Any]]()
        for (name, root, shader, attribute, source, space) in cases {
            let text = ColorImportFixtures.usdColorSpace(
                textured: true, root: root, shader: shader, attribute: attribute, sourceColorSpace: source
            )
            let color = try XCTUnwrap(CGColor(
                colorSpace: XCTUnwrap(CGColorSpace(name: space)), components: [128 / 255.0, 64 / 255.0, 192 / 255.0, 1]
            ))
            records += try auditUSDColorSpace(name: name, text: text, expected: Color(color), textured: true)
        }
        try writeColorSpaceReport(records, name: "texture-color-spaces")
    }

    private func writeColorSpaceReport(_ records: [[String: Any]], name: String) throws {
        let report: [String: Any] = [
            "os": ProcessInfo.processInfo.operatingSystemVersionString,
            "observations": records,
        ]
        let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: directory.appendingPathComponent("\(name).json"))
        let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.json")
        attachment.name = "\(name).json"
        attachment.lifetime = .keepAlways
        add(attachment)
        print("USD_COLOR_METADATA_OS \(ProcessInfo.processInfo.operatingSystemVersionString)")
        for record in records {
            let data = try JSONSerialization.data(withJSONObject: record, options: [.sortedKeys])
            print("USD_COLOR_METADATA \(String(decoding: data, as: UTF8.self))")
        }
    }

    @MainActor
    private func auditUSDColorSpace(
        name: String, text: String, expected: Color, textured: Bool
    ) throws -> [[String: Any]] {
        let url = directory.appendingPathComponent("\(name).usda")
        try text.write(to: url, atomically: true, encoding: .utf8)
        var urls = [url]
        #if os(macOS)
        // Apple's usdcat preserves authored metadata while changing only the storage encoding.
        // Keep ASCII coverage available on machines without this optional audit tool.
        if FileManager.default.isExecutableFile(atPath: "/usr/bin/usdcat") {
            let binary = url.deletingPathExtension().appendingPathExtension("usdc")
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/usdcat")
            process.arguments = [url.path, "-o", binary.path]
            try process.run()
            process.waitUntilExit()
            XCTAssertEqual(process.terminationStatus, 0)
            urls.append(binary)
        }
        #endif
        let render = try pixelRenderer()
        let renderLit = try pixelRenderer(ambientLight: true)
        let reference = SCNGeometry(Mesh.fill(.square(size: 2), faces: .front, material: expected))
        reference.firstMaterial?.lightingModel = .constant
        let expectedPixel = try render(reference)
        var records = [[String: Any]]()
        for url in urls {
            for modelIO in [false, true] {
                var details = [String: Any]()
                let material: SCNMaterial
                if modelIO {
                    let asset = MDLAsset(url: url)
                    asset.loadTextures()
                    let meshes = asset.childObjects(of: MDLMesh.self).compactMap { $0 as? MDLMesh }
                    let submesh = try XCTUnwrap(meshes.first?.submeshes?.firstObject as? MDLSubmesh)
                    let mdlMaterial = try XCTUnwrap(submesh.material)
                    let property = try XCTUnwrap(mdlMaterial.property(with: .baseColor))
                    details["mdlPropertyType"] = property.type.rawValue
                    if let color = Color(property) {
                        details["mdlSRGB"] = [color.red, color.green, color.blue]
                        knownIssue("Model I/O returns USD numeric colors without resolving their authored color space") {
                            assertColor(color, expected, accuracy: 0.002, "\(name): Model I/O numeric color")
                        }
                    }
                    details["mdlPropertyNames"] = (0 ..< mdlMaterial.count).compactMap { mdlMaterial[$0]?.name }
                    if let cgColor = property.color {
                        details["mdlColorSpace"] = cgColor.colorSpace?.name as String? ?? "unnamed"
                        details["mdlComponents"] = cgColor.components
                    } else if property.type == .float3 {
                        details["mdlComponents"] = [
                            property.float3Value.x,
                            property.float3Value.y,
                            property.float3Value.z,
                        ]
                    }
                    material = SCNMaterial(mdlMaterial: mdlMaterial)
                } else {
                    let scene = try SCNScene(url: url)
                    var found: SCNMaterial?
                    scene.rootNode.enumerateChildNodes { node, _ in
                        found = found ?? node.geometry?.firstMaterial
                    }
                    material = try XCTUnwrap(found)
                }
                if !textured {
                    #if canImport(UIKit)
                    let color = material.diffuse.contents as? UIColor
                    #else
                    let color = material.diffuse.contents as? NSColor
                    #endif
                    let directColor: CGColor? = switch material.diffuse.contents {
                    case let value as CGColor where CFGetTypeID(value) == CGColor.typeID: value
                    default: nil
                    }
                    let cgColor = try XCTUnwrap(color?.cgColor ?? directColor)
                    details["scnColorSpace"] = cgColor.colorSpace?.name as String? ?? "unnamed"
                    details["scnComponents"] = cgColor.components
                    let actual = Color(cgColor)
                    details["scnSRGB"] = [actual.red, actual.green, actual.blue]
                    knownIssue("Apple USD import does not reliably resolve authored color-space metadata") {
                        assertColor(actual, expected, accuracy: 0.002, "\(name): numeric color")
                    }
                } else {
                    details["scnTextureContentsType"] = material.diffuse.contents
                        .map { String(describing: type(of: $0)) } ?? "nil"
                }
                // Also retain the original shading model: switching to constant must not be
                // the reason a texture's transfer-function declaration appears to be lost.
                let litGeometry = SCNGeometry(Mesh.fill(.square(size: 2), faces: .front, material: material))
                let litActual = try renderLit(litGeometry)
                let litReference = try XCTUnwrap(material.copy() as? SCNMaterial)
                litReference.diffuse.contents = CGColor(
                    srgbRed: expected.red, green: expected.green, blue: expected.blue, alpha: 1
                )
                let litExpected = try renderLit(SCNGeometry(Mesh.fill(
                    .square(size: 2), faces: .front, material: litReference
                )))
                XCTAssertGreaterThan(litExpected.prefix(3).map(Int.init).reduce(0, +), 0)
                details["originalShadingBGRA"] = litActual
                details["expectedOriginalShadingBGRA"] = litExpected
                details["originalShadingMatches"] = zip(litActual, litExpected)
                    .allSatisfy { abs(Int($0) - Int($1)) <= 2 }
                // Compare under identical unlit rendering, avoiding BRDF and environment differences.
                material.lightingModel = .constant
                let geometry = SCNGeometry(Mesh.fill(.square(size: 2), faces: .front, material: material))
                let actualPixel = try render(geometry)
                details["fixture"] = name
                details["format"] = url.pathExtension
                details["loader"] = modelIO ? "ModelIO" : "SceneKit"
                details["expectedSRGB"] = [expected.red, expected.green, expected.blue]
                details["expectedBGRA"] = expectedPixel
                details["actualBGRA"] = actualPixel
                details["renderMatches"] = zip(actualPixel, expectedPixel).allSatisfy { abs(Int($0) - Int($1)) <= 2 }
                knownIssue("Apple USD import does not reliably render authored color-space metadata") {
                    for channel in 0 ..< 4 {
                        XCTAssertEqual(
                            Double(actualPixel[channel]),
                            Double(expectedPixel[channel]),
                            accuracy: 2,
                            "\(name), \(modelIO ? "ModelIO" : "SceneKit"), \(url.pathExtension)"
                        )
                    }
                }
                records.append(details)
            }
        }
        return records
    }

    @MainActor
    func testIndependentUSDMaterialRenderedOpacity() throws {
        try checkIndependentRenderedAppearance(format: "usda", textured: false)
    }

    @MainActor
    func testIndependentColladaMaterialRenderedOpacity() throws {
        try checkIndependentRenderedAppearance(format: "dae", textured: false)
    }

    @MainActor
    func testIndependentColladaTextureRenderedOpacity() throws {
        try checkIndependentRenderedAppearance(format: "dae", textured: true)
    }

    @MainActor
    func testIndependentOBJTextureRenderedOpacity() throws {
        try checkIndependentRenderedAppearance(format: "obj", textured: true)
    }

    @MainActor
    func testOBJScalarAndTextureRenderedOpacity() throws {
        try checkIndependentRenderedAppearance(format: "obj", textured: true, dissolve: 0.4)
        try checkIndependentRenderedAppearance(
            format: "obj",
            textured: true,
            opacityChannel: "m",
            opacity: 192 / 255.0,
            dissolve: 0.4
        )
    }

    @MainActor
    func testOBJExplicitDissolveChannelsRenderedOpacity() throws {
        // Independent straight RGB after PNG unpremultiplication is (21, 64, 128); alpha is 192.
        for (channel, opacity) in [("r", 21.0), ("g", 64.0), ("b", 128.0), ("m", 192.0), ("l", 59.0)] {
            try checkIndependentRenderedAppearance(
                format: "obj",
                textured: true,
                opacityChannel: channel,
                opacity: opacity / 255
            )
        }
    }

    @MainActor
    func testModelIOOBJDissolveChannelsRenderedOpacity() throws {
        try checkIndependentRenderedAppearance(format: "obj", textured: true, dissolve: 0.4, modelIO: true)
        for (channel, opacity) in [("r", 21.0), ("g", 64.0), ("b", 128.0), ("m", 192.0), ("l", 59.0)] {
            for dissolve in [1.0, 0.4] {
                try checkIndependentRenderedAppearance(
                    format: "obj",
                    textured: true,
                    opacityChannel: channel,
                    opacity: opacity / 255,
                    dissolve: dissolve,
                    modelIO: true
                )
            }
        }
    }

    func testModelIOOBJOpacityNormalizedBeforeMaterialLookup() throws {
        let url = try independentFixture(format: "obj", textured: true, opacityChannel: "g", dissolve: 0.4)
        let mesh = try Mesh(modelIOURL: url) { material in
            guard let material = material as? MDLMaterial,
                  let texture = material.property(with: .opacity)?.textureSamplerValue?.texture,
                  texture.channelCount == 1,
                  let bytes = texture.texelDataWithTopLeftOrigin()
            else { return nil }
            // The callback sees normalized data, not a renderer-specific workaround.
            return Color(white: 1, alpha: Double(bytes[0]) / 255)
        }
        XCTAssertFalse(mesh.isEmpty)
        for polygon in mesh.polygons {
            try assertColor(
                XCTUnwrap(polygon.material as? Color),
                Color(white: 1, alpha: 26 / 255.0),
                "Model I/O normalized opacity callback"
            )
        }
    }

    #if canImport(RealityKit)

    @MainActor
    @available(tvOS 26.0, *)
    func testModelIOOBJOpacityRealityKitTexture() throws {
        guard #available(macOS 15, iOS 18, visionOS 2, *) else {
            throw XCTSkip("Inspecting RealityKit texture pixel formats requires a newer OS")
        }
        try XCTSkipIf(MTLCreateSystemDefaultDevice() == nil, "RealityKit texture inspection requires Metal")
        let device = try XCTUnwrap(MTLCreateSystemDefaultDevice())
        for (channel, expected) in [("g", 26), ("m", 77)] {
            let url = try independentFixture(format: "obj", textured: true, opacityChannel: channel, dissolve: 0.4)
            let mesh = try Mesh(modelIOURL: url)
            let source = try XCTUnwrap(mesh.polygons.first?.material as? MDLMaterial)
            let material = PhysicallyBasedMaterial(source)
            guard case let .transparent(opacity) = material.blending else { return XCTFail("Missing opacity") }
            XCTAssertEqual(opacity.scale, 1, "The scalar is already baked into the opacity data")
            let resource = try XCTUnwrap(opacity.texture?.resource)
            XCTAssertTrue([MTLPixelFormat.r8Unorm, .rgba8Unorm, .bgra8Unorm].contains(resource.pixelFormat))
            let descriptor = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: resource.pixelFormat, width: 1, height: 1, mipmapped: false
            )
            descriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
            descriptor.storageMode = .shared
            let texture = try XCTUnwrap(device.makeTexture(descriptor: descriptor))
            try resource.copy(to: texture)
            var pixel = [UInt8](repeating: 0, count: 4)
            texture.getBytes(&pixel, bytesPerRow: 4, from: MTLRegionMake2D(0, 0, 1, 1), mipmapLevel: 0)
            XCTAssertEqual(Int(pixel[0]), expected, "RealityKit raw opacity must retain the selected data channel")
        }
    }

    #endif

    @MainActor
    func testIndependentUSDTextureRenderedOpacity() throws {
        try checkIndependentRenderedAppearance(format: "usda", textured: true)
    }

    @MainActor
    private func checkIndependentRenderedAppearance(
        format: String, textured: Bool, opacityChannel: String? = nil, opacity: Double? = nil, dissolve: Double = 1,
        modelIO: Bool = false
    ) throws {
        let url = try independentFixture(
            format: format,
            textured: textured,
            opacityChannel: opacityChannel,
            dissolve: dissolve
        )
        let mesh = try modelIO ? Mesh(modelIOURL: url) : importIndependentFixture(url)
        XCTAssertFalse(mesh.isEmpty)
        XCTAssertEqual(mesh.surfaceArea, 4, accuracy: 1e-6)
        let geometry = SCNGeometry(mesh)
        // Isolate color and opacity from differing BRDFs and default lighting.
        for material in geometry.materials {
            material.lightingModel = .constant
        }
        let expectedColor = textured ? Color(
            red: 128 / 255.0,
            green: 64 / 255.0,
            blue: 192 / 255.0,
            alpha: (opacity ?? (format == "dae" ? 0.4 : 64 / 255.0)) * dissolve
        ) : swatches[2]
        let reference = SCNGeometry(Mesh.fill(
            .square(size: 2),
            faces: .front,
            material: expectedColor.withAlphaComponent(1)
        ))
        let material = try XCTUnwrap(reference.firstMaterial)
        material.lightingModel = .constant
        material.transparency = CGFloat(expectedColor.alpha)
        let renderPixel = try pixelRenderer()
        let expected = try renderPixel(reference)
        XCTAssertGreaterThan(expected.prefix(3).reduce(0) { $0 + Int($1) }, 0)
        material.transparency = 1
        let opaque = try renderPixel(reference)
        XCTAssertNotEqual(Array(expected.prefix(3)), Array(opaque.prefix(3)), "Reference must exercise opacity")
        let actual = try renderPixel(geometry)

        for channel in 0 ..< 4 {
            let check = { [self] in
                XCTAssertEqual(
                    Double(actual[channel]),
                    Double(expected[channel]),
                    accuracy: 2,
                    "\(format) independent rendered BGRA channel \(channel): \(actual) versus \(expected)"
                )
            }
            if channel < 3, format == "usda", !textured {
                knownIssue(
                    "SceneKit USD import tags default linear Rec.709 material values as linear Display P3",
                    check
                )
            } else {
                check()
            }
        }
    }

    func testIndependentOBJMaterialImportThroughBothLoaders() throws {
        // Hand-authored input, independent of Euclid and Apple's exporters.
        let url = directory.appendingPathComponent("input.obj")
        try """
        mtllib input.mtl
        v 0 0 0
        v 1 0 0
        v 0 1 0
        usemtl paint
        f 1 2 3

        """.write(to: url, atomically: true, encoding: .utf8)
        try """
        newmtl paint
        Kd 0.5 0.25 0.75
        Ka 0 0 0
        Ks 0 0 0
        illum 2
        d 0.4

        """.write(to: directory.appendingPathComponent("input.mtl"), atomically: true, encoding: .utf8)
        let expected = swatches[2]
        let scene = try SCNScene(url: url)
        let scn = Mesh(scene.rootNode, linearColors: false)
        XCTAssertFalse(scn.isEmpty)
        for polygon in scn.polygons {
            let material = try XCTUnwrap(polygon.material as? SCNMaterial)
            let color = try XCTUnwrap(defaultColorMapping(material.diffuse.contents as? AnyHashable))
            let opacity = (material.transparent.contents as? NSNumber)?.doubleValue ?? 1
            XCTAssertEqual(
                color.alpha * Double(material.transparency) * opacity,
                expected.alpha,
                accuracy: 1e-5,
                "Independent OBJ opacity"
            )
            // Compare against Apple's material bridge: conversion to PBR can change Kd.
            // Equality with the original MTL diffuse RGB is not the contract of that conversion.
            let asset = MDLAsset(url: url)
            let mdlMesh = try XCTUnwrap(asset.childObjects(of: MDLMesh.self).first as? MDLMesh)
            let mdlMaterial = try XCTUnwrap((mdlMesh.submeshes?.firstObject as? MDLSubmesh)?.material)
            let bridged = SCNMaterial(mdlMaterial: mdlMaterial)
            let bridgedColor = try XCTUnwrap(defaultColorMapping(bridged.diffuse.contents as? AnyHashable))
            XCTAssertEqual(material.lightingModel, bridged.lightingModel)
            assertColor(color, bridgedColor, accuracy: 1e-5, "OBJ SceneKit material bridge compatibility")
        }
        let mdl = try Mesh(MDLAsset(url: url), linearColors: false)
        XCTAssertFalse(mdl.isEmpty)
        for polygon in mdl.polygons {
            let material = try XCTUnwrap(polygon.material as? MDLMaterial)
            let property = try XCTUnwrap(material.property(with: .baseColor))
            let color = try XCTUnwrap(Color(property, linearColors: false))
            let opacity = try XCTUnwrap(material.property(with: .opacity))
            XCTAssertEqual(opacity.type, .float)
            assertColor(
                color.withAlphaComponent(Double(opacity.floatValue)),
                expected,
                accuracy: 1e-5,
                "Independent OBJ Model I/O material"
            )
        }
    }

    func testSceneKitSwatches() throws { try checkSceneKitSwatches(format: "scn") }
    func testCompressedSceneKitSwatches() throws { try checkSceneKitSwatches(format: "scnz") }

    private func checkSceneKitSwatches(format: String) throws {
        for useVertices in [false, true] {
            let mesh = try fixture(vertexColors: useVertices)
            let url = try export(mesh, name: useVertices ? "vertices" : "materials", format: format)
            let imported = try Mesh(url: url, materialLookup: { material in
                guard let material = material as? SCNMaterial else { return nil }
                return defaultColorMapping(material.diffuse.contents as? AnyHashable)
            })
            try assertVertexColors(imported, mesh, accuracy: 1e-6, context: "SCN")
            if !useVertices {
                for polygon in imported.polygons {
                    let original = try XCTUnwrap(mesh.polygons.first { $0.bounds == polygon.bounds })
                    try assertColor(
                        XCTUnwrap(polygon.material as? Color),
                        XCTUnwrap(original.material as? Color),
                        "\(format) material"
                    )
                }
            }
        }
    }

    #endif
}

#if canImport(SceneKit) && os(macOS)

/// Resolve the COLOR input through XML IDs instead of assuming exporter-generated names.
private final class ColladaColorArrays: NSObject, XMLParserDelegate {
    var colorSources = Set<String>()
    var values = [String: [Double]]()
    private var source: String?
    private var text: String?

    func parser(
        _: XMLParser,
        didStartElement elementName: String,
        namespaceURI _: String?,
        qualifiedName _: String?,
        attributes attributeDict: [String: String]
    ) {
        if elementName == "source" { source = attributeDict["id"] }
        if elementName == "float_array" { text = "" }
        if elementName == "input", attributeDict["semantic"] == "COLOR", let id = attributeDict["source"] {
            colorSources.insert(String(id.dropFirst()))
        }
    }

    func parser(_: XMLParser, foundCharacters string: String) {
        text? += string
    }

    func parser(
        _: XMLParser,
        didEndElement elementName: String,
        namespaceURI _: String?,
        qualifiedName _: String?
    ) {
        if elementName == "float_array", let source, let text {
            values[source] = text.split(whereSeparator: \.isWhitespace).compactMap(Double.init)
            self.text = nil
        }
        if elementName == "source" { source = nil }
    }
}

#endif
