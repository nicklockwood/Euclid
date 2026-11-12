//
//  PLYExportTests.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 09/11/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

final class PLYExportTests: XCTestCase {
    func testVertexAttributesRoundTrip() throws {
        let mesh = try Mesh([XCTUnwrap(Polygon([
            Vertex(.zero, normal: .unitZ, texcoord: .zero, color: Color(red: 0.5, green: 0.25, blue: 0.75, alpha: 0.4)),
            Vertex(.unitX, normal: .unitZ, texcoord: .unitX, color: Color(white: 0.25, alpha: 0.8)),
            Vertex(.unitY, normal: .unitZ, texcoord: .unitY, color: .white),
        ]))])
        let text = try mesh.plyString()
        XCTAssertTrue(text.contains("format ascii 1.0\n"))
        XCTAssertTrue(text.contains("128 64 191 102\n"))
        let imported = try XCTUnwrap(Mesh(plyString: text))
        let vertex = try XCTUnwrap(imported.polygons.first?.vertices.first { $0.position == .zero })
        XCTAssertEqual(vertex.normal, .unitZ)
        XCTAssertEqual(vertex.texcoord, .zero)
        XCTAssertEqual(vertex.color.red, 0.5, accuracy: 1 / 255.0)
        XCTAssertEqual(vertex.color.alpha, 0.4, accuracy: 1 / 255.0)
    }

    func testMaterialTintMultipliesVertexColorInLinearLight() throws {
        let mesh = Mesh.cube().mapVertexColors { _ in Color(white: 0.5, alpha: 0.5) }
            .withMaterial(Color(white: 0.5, alpha: 0.5))
        let text = try mesh.plyString()
        // sRGB(0.214041... squared) is about 0.237, rather than 0.25.
        XCTAssertTrue(text.contains("60 60 60 64\n"), text)
    }

    func testCustomMaterialMappingAndURLExport() throws {
        let mesh = Mesh.cube().withMaterial("paint")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".ply")
        defer { try? FileManager.default.removeItem(at: url) }
        try mesh.write(to: url, materialLookup: { material in
            material as? String == "paint" ? Color(red: 0.5, green: 0.25, blue: 0.75, alpha: 0.4) : nil
        })
        let text = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(text.contains("128 64 191 102\n"), text)
        XCTAssertEqual(try Mesh(url: url).polygons.count, 12)
    }

    func testCancellation() {
        XCTAssertThrowsError(try Mesh.cube().plyString(isCancelled: { true })) { error in
            XCTAssertTrue(error is CancellationError)
        }
    }

    func testEmptyMeshExportsEmptyTables() throws {
        let text = try Mesh([]).plyString()
        XCTAssertTrue(text.contains("element vertex 0\n"))
        XCTAssertTrue(text.contains("element face 0\n"))
    }
}
