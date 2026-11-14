//
//  OFFTests.swift
//  EuclidTests
//
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

final class OFFTests: XCTestCase {
    private let vertices = "0 0 0\n1 0 0\n0 1 0"
    private let options = Mesh.ImportOptions(repairWinding: false)

    func testFaceRGBAndRGBAEncodings() throws {
        let cases: [(String, Color)] = [
            ("128 64 255", Color(red: 128 / 255, green: 64 / 255, blue: 1)),
            ("128 64 255 102", Color(red: 128 / 255, green: 64 / 255, blue: 1, alpha: 102 / 255)),
            ("0.5 0.25 1.0", Color(red: 0.5, green: 0.25, blue: 1)),
            ("0.5 0.25 1.0 0.4", Color(red: 0.5, green: 0.25, blue: 1, alpha: 0.4)),
            ("1 0 0", Color(red: 1 / 255, green: 0, blue: 0)),
            ("1.0 0 0", .red),
            ("1e0 0 0 0e0", Color(red: 1, green: 0, blue: 0, alpha: 0)),
        ]
        for (tokens, expected) in cases {
            let mesh = try XCTUnwrap(Mesh(offString: "OFF\n3 1 0\n\(vertices)\n3 0 1 2 \(tokens)", options: options))
            XCTAssertEqual(mesh.polygons.first?.material as? Color, expected, tokens)
            XCTAssertTrue(mesh.polygons[0].vertices.allSatisfy { $0.color == .white })
        }
    }

    func testCOFFPreservesVertexAndFaceColorsSeparately() throws {
        let source = """
        COFF # vertex RGBA
        3 1 0
        0 0 0 0.5 0.25 0.75 0.4
        1 0 0 1 0 0 0
        0 1 0 0 0 1 1
        3 0 1 2 0.25 0.5 0.75 0.8 # face RGBA
        """
        let mesh = try XCTUnwrap(Mesh(offString: source, options: options))
        let face = try XCTUnwrap(mesh.polygons.first)
        XCTAssertEqual(face.material as? Color, Color(red: 0.25, green: 0.5, blue: 0.75, alpha: 0.8))
        XCTAssertEqual(face.vertices.map(\.color), [
            Color(red: 0.5, green: 0.25, blue: 0.75, alpha: 0.4),
            Color(red: 1, green: 0, blue: 0, alpha: 0), .blue,
        ])
        XCTAssertEqual(Mesh(offString: mesh.coffString(), options: options), mesh)
    }

    func testFaceExportUsesExplicitFloatingPointRGBA() throws {
        let mesh = Mesh.cube().withMaterial(Color.red)
        let text = mesh.offString()
        XCTAssertTrue(text.hasPrefix("OFF\n"))
        XCTAssertTrue(text.split(separator: "\n").suffix(6).allSatisfy { $0.hasSuffix(" 1.0 0.0 0.0 1.0") })
        let imported = try XCTUnwrap(Mesh(offString: text))
        XCTAssertEqual(imported, mesh.withoutTexcoords())
    }

    func testSmallFaceColorsHaveADecimalPoint() throws {
        let color = Color(red: 0.0000001, green: 0, blue: 0, alpha: 0.0000001)
        let text = Mesh.cube().withMaterial(color).offString()
        XCTAssertTrue(text.contains("1.0e-07"), text)
        let imported = try XCTUnwrap(Mesh(offString: text))
        XCTAssertTrue(imported.polygons.allSatisfy { $0.material as? Color == color })
    }

    func testVertexColorSeamsAreNotWelded() throws {
        let face = try XCTUnwrap(Polygon([Vertex(.zero), Vertex(.unitX), Vertex(.unitY)]))
        let mesh = Mesh([face, face.inverted()]).mapVertexColors { _ in .red }
        let polygons = [mesh.polygons[0]] + mesh.polygons[1].mapVertices { $0.withColor(.blue) }
        let text = Mesh(polygons).coffString()
        XCTAssertTrue(text.hasPrefix("COFF\n6 2 0\n"), text)
        let imported = try XCTUnwrap(Mesh(offString: text, options: options))
        XCTAssertEqual(imported.polygons.map { $0.vertices.map(\.color) }, [[.red, .red, .red], [.blue, .blue, .blue]])
    }

    func testMixedFaceMaterialsExportUnmappedFacesAsWhite() throws {
        let mesh = Mesh.cube()
        let mixed = Mesh(mesh.polygons.enumerated().map { index, face in
            face.withMaterial(index == 0 ? Color.clear : nil)
        })
        let imported = try XCTUnwrap(Mesh(offString: mixed.offString()))
        XCTAssertEqual(imported.polygons[0].material as? Color, .clear)
        XCTAssertTrue(imported.polygons.dropFirst().allSatisfy { $0.material as? Color == .white })
    }

    func testURLMaterialMappingAndCOFFExtension() throws {
        let color = Color(red: 0.5, green: 0.25, blue: 0.75, alpha: 0.4)
        let mesh = Mesh.cube().withMaterial("paint").mapVertexColors { _ in color }
        for ext in ["off", "coff"] {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID()).\(ext)")
            defer { try? FileManager.default.removeItem(at: url) }
            try mesh.write(to: url, materialLookup: { material in material as? String == "paint" ? color : nil })
            let text = try String(contentsOf: url, encoding: .utf8)
            XCTAssertTrue(text.hasPrefix(ext == "coff" ? "COFF\n" : "OFF\n"))
            let imported = try Mesh(url: url, options: options, materialLookup: { material in
                material as? Color == color ? "paint" : nil
            })
            XCTAssertTrue(imported.polygons.allSatisfy { $0.material as? String == "paint" })
            XCTAssertTrue(imported.polygons.flatMap(\.vertices)
                .allSatisfy { $0.color == (ext == "coff" ? color : .white) })
        }
    }

    func testCommentsAndPaletteIndicesAreNotInterpretedAsRGB() throws {
        for suffix in ["# 255 0 0", "17 # palette index"] {
            let mesh = try XCTUnwrap(Mesh(offString: "OFF 3 1 0\n\(vertices)\n3 0 1 2 \(suffix)", options: options))
            XCTAssertNil(mesh.polygons.first?.material)
        }
    }

    func testMalformedColorsAndVerticesAreRejected() {
        for color in ["0.2 0.3", "256 0 0", "-1 0 0", "2.0 0.0 0.0", "nan 0 0", "0 inf 0", "0 0 nope", "1 2 3 4 5"] {
            XCTAssertNil(Mesh(offString: "OFF\n3 1 0\n\(vertices)\n3 0 1 2 \(color)"), color)
        }
        for vertex in ["0 0 0", "0 0 0 1 0 0", "0 0 0 1 0 0 2", "0 0 0 1 nan 0 1", "0 0 0 -1 0 0 1"] {
            XCTAssertNil(Mesh(offString: "COFF\n1 0 0\n\(vertex)"), vertex)
        }
        XCTAssertNil(Mesh(offString: "OFF\n2 0 0\n0 nope 0\n0 0 0"))
        XCTAssertNil(Mesh(offString: "OFF\n3 0 0\n0 0 0\n1 0 0"))
    }

    func testExplicitHeadersAndPermissiveImport() throws {
        let mesh = Mesh.cube().mapVertexColors { _ in .red }
        XCTAssertTrue(mesh.offString().hasPrefix("OFF\n"))
        XCTAssertTrue(Mesh.cube().coffString().hasPrefix("COFF\n"))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID()).off")
        defer { try? FileManager.default.removeItem(at: url) }
        try mesh.coffString().write(to: url, atomically: true, encoding: .utf8)
        let imported = try Mesh(url: url)
        XCTAssertTrue(imported.polygons.flatMap(\.vertices).allSatisfy { $0.color == .red })
    }

    func testVertexAttributeVariantsRoundTrip() throws {
        let mesh = Mesh.cube().mapVertexColors { _ in Color(red: 0.5, green: 0.25, blue: 1, alpha: 0.4) }
        for normals in [false, true] {
            for colors in [false, true] {
                for texcoords in [false, true] {
                    let exportOptions = OFFTextOptions(
                        vertexNormals: normals,
                        vertexColors: colors,
                        textureCoordinates: texcoords
                    )
                    let header = (texcoords ? "ST" : "") + (colors ? "C" : "") + (normals ? "N" : "") + "OFF"
                    let text = mesh.offString(options: exportOptions)
                    XCTAssertTrue(text.hasPrefix(header + "\n"))
                    let imported = try XCTUnwrap(Mesh(offString: text, options: options))
                    let expected = mesh.polygons.flatMap(\.vertices)
                    let actual = imported.polygons.flatMap(\.vertices)
                    XCTAssertEqual(actual.map(\.position), expected.map(\.position), header)
                    XCTAssertEqual(actual.map(\.normal), expected.map(\.normal), header)
                    XCTAssertEqual(actual.map(\.color), expected.map { colors ? $0.color : .white }, header)
                    XCTAssertEqual(actual.map(\.texcoord), expected.map { texcoords ? $0.texcoord : .zero }, header)
                    XCTAssertEqual(text, try mesh.offString(options: exportOptions, isCancelled: { false }))
                }
            }
        }
    }

    func testImportAttributeOrderAndCustomNormals() throws {
        // Geomview orders normals before colors, despite C preceding N in the header.
        let text = """
        STCNOFF 3 1 0
        0 0 0 0 1 0 1 0 0 0.5 0.25 0.75
        1 0 0 0 1 0 0 1 0 1 0.5 0.25
        0 1 0 0 1 0 0 0 1 1 1 0
        3 0 1 2
        """
        let mesh = try XCTUnwrap(Mesh(offString: text, options: options))
        let vertices = try XCTUnwrap(mesh.polygons.first).vertices
        XCTAssertEqual(vertices.map(\.normal), [.unitY, .unitY, .unitY])
        XCTAssertEqual(vertices.map(\.color), [Color(red: 1, green: 0, blue: 0, alpha: 0.5), .green, .blue])
        XCTAssertEqual(vertices.map(\.texcoord), [Vector(0.25, 0.75), Vector(0.5, 0.25), Vector(1, 0)])
    }

    func testMalformedVertexAttributesAreRejected() {
        for (header, vertex) in [
            ("NOFF", "0 0 0 0 1"),
            ("NOFF", "0 0 0 0 nan 1"),
            ("STOFF", "0 0 0 1"),
            ("STOFF", "0 0 0 inf 0"),
            ("STCNOFF", "0 0 0 0 0 1 1 0 0 2 0 1"),
            ("NC OFF", "0 0 0"),
        ] {
            XCTAssertNil(Mesh(offString: "\(header)\n1 0 0\n\(vertex)"), header)
        }
    }

    func testAttributeExportCancellation() {
        XCTAssertThrowsError(try Mesh.cube().offString(
            options: .init(vertexNormals: true, vertexColors: true, textureCoordinates: true),
            isCancelled: { true }
        )) {
            XCTAssertTrue($0 is CancellationError)
        }
    }

    func testCOFFCancellation() {
        XCTAssertThrowsError(try Mesh(offString: "COFF\n0 0 0", isCancelled: { true })) {
            XCTAssertTrue($0 is CancellationError)
        }
        XCTAssertThrowsError(try Mesh.cube().mapVertexColors { _ in .red }.coffString(isCancelled: { true })) {
            XCTAssertTrue($0 is CancellationError)
        }
    }
}
