//
//  PLYImportTests.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 09/11/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

final class PLYImportTests: XCTestCase {
    private let source = """
    ply
    format ascii 1.0
    comment end_header in a comment is not the header terminator
    element vertex 3
    property uchar alpha
    property float x
    property float y
    property float z
    property uchar blue
    property uchar red
    property uchar green
    property float confidence
    property float nx
    property float ny
    property float nz
    property float s
    property float t
    element edge 1
    property list uchar int endpoints
    element face 1
    property float quality
    property list uchar int vertex_indices
    end_header
    102 0 0 0 191 128 64 0.9 0 0 1 0 0
    204 1 0 0 32 64 128 0.8 0 0 1 1 0
    153 0 1 0 255 255 255 0.7 0 0 1 0 1
    2 0 1
    0.9 3 0 1 2
    """

    func testPreservesRGBAUVsAndNormalsWithReorderedProperties() throws {
        let mesh = try XCTUnwrap(Mesh(plyString: source))
        let polygon = try XCTUnwrap(mesh.polygons.first)
        XCTAssertEqual(polygon.vertices.count, 3)
        let vertex = try XCTUnwrap(polygon.vertices.first { $0.position == .zero })
        XCTAssertEqual(vertex.color.red, 128 / 255.0, accuracy: 1e-8)
        XCTAssertEqual(vertex.color.green, 64 / 255.0, accuracy: 1e-8)
        XCTAssertEqual(vertex.color.blue, 191 / 255.0, accuracy: 1e-8)
        XCTAssertEqual(vertex.color.alpha, 0.4, accuracy: 1e-8)
        let second = try XCTUnwrap(polygon.vertices.first { $0.position == .unitX })
        XCTAssertEqual(second.texcoord, .unitX)
        XCTAssertEqual(second.normal, .unitZ)
        XCTAssertEqual(second.color.alpha, 0.8, accuracy: 1e-8)
    }

    func testFloatingPointColorsAreNotDividedBy255() throws {
        var text = source
        for name in ["alpha", "red", "green", "blue"] {
            text = text.replacingOccurrences(of: "property uchar \(name)", with: "property float \(name)")
        }
        text = text.replacingOccurrences(of: "102 0 0 0 191 128 64", with: "0.4 0 0 0 0.75 0.5 0.25")
        let mesh = try XCTUnwrap(Mesh(plyString: text))
        let color = try XCTUnwrap(mesh.polygons.first?.vertices.first { $0.position == .zero }?.color)
        XCTAssertEqual(color, Color(red: 0.5, green: 0.25, blue: 0.75, alpha: 0.4))
    }

    func testURLImportUsesNativePLYReader() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".ply")
        defer { try? FileManager.default.removeItem(at: url) }
        try source.write(to: url, atomically: true, encoding: .utf8)
        XCTAssertEqual(try Mesh(url: url), Mesh(plyString: source))
    }

    func testRejectsBinaryAndUnsupportedVersions() {
        XCTAssertNil(Mesh(plyString: source.replacingOccurrences(of: "ascii 1.0", with: "binary_little_endian 1.0")))
        XCTAssertNil(Mesh(plyString: source.replacingOccurrences(of: "ascii 1.0", with: "ascii 2.0")))
    }

    func testRejectsInvalidHeader() {
        XCTAssertNil(Mesh(plyString: source.replacingOccurrences(of: "ply\n", with: "ply_invalid\n")))
        XCTAssertNil(Mesh(plyString: source.replacingOccurrences(of: "\nend_header\n", with: "\n")))
    }

    func testRejectsTruncatedDataAndInvalidIndices() {
        XCTAssertNil(Mesh(plyString: String(source.dropLast(2))))
        XCTAssertNil(Mesh(plyString: source.replacingOccurrences(of: "0.9 3 0 1 2", with: "0.9 3 0 1 3")))
        XCTAssertNil(Mesh(plyString: source.replacingOccurrences(of: "0.9 3 0 1 2", with: "0.9 3 -1 1 2")))
        XCTAssertNil(Mesh(plyString: source.replacingOccurrences(of: "0.9 3 0 1 2", with: "0.9 3 0.5 1 2")))
    }

    func testRejectsInvalidCountsAndNonFiniteValues() {
        XCTAssertNil(Mesh(plyString: source.replacingOccurrences(of: "element vertex 3", with: "element vertex -1")))
        XCTAssertNil(Mesh(plyString: source.replacingOccurrences(of: "2 0 1\n", with: "-1 0 1\n")))
        XCTAssertNil(Mesh(plyString: source.replacingOccurrences(of: "102 0 0 0", with: "102 nan 0 0")))
    }

    func testAcceptsCRLFLineEndings() {
        XCTAssertEqual(Mesh(plyString: source.replacingOccurrences(of: "\n", with: "\r\n")), Mesh(plyString: source))
    }

    func testWindingRepairIsOptIn() throws {
        let source = """
        ply
        format ascii 1.0
        element vertex 4
        property float x
        property float y
        property float z
        element face 2
        property list uchar int vertex_indices
        end_header
        0 0 0
        1 0 0
        0 1 0
        1 1 0
        3 0 1 2
        3 1 2 3
        """
        let original = try XCTUnwrap(Mesh(plyString: source))
        XCTAssertLessThan(original.polygons[0].plane.normal.dot(original.polygons[1].plane.normal), 0)
        let repaired = try XCTUnwrap(Mesh(plyString: source, options: .init(repairWinding: true)))
        XCTAssertGreaterThan(repaired.polygons[0].plane.normal.dot(repaired.polygons[1].plane.normal), 0)
        XCTAssertFalse(original.hasVertexColors)
    }
}
