//
//  TextTests.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 12/03/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

#if canImport(CoreText)

import CoreText
@testable import Euclid
import Foundation
import XCTest

final class TextTests: XCTestCase {
    func testTextPaths() {
        let text = NSAttributedString(string: "Hello")
        let paths = Path.text(text)
        XCTAssertEqual(paths.count, 5)
        XCTAssertEqual(paths.map(\.subpaths.count), [
            1, 2, 1, 1, 2,
        ])
    }

    func testTextMeshWithAttributedString() {
        let text = "Hello"
        let font = CTFontCreateWithName("Helvetica" as CFString, 12, nil)
        let attributes = [NSAttributedString.Key.font: font]
        let string = NSAttributedString(string: text, attributes: attributes)
        let mesh = Mesh.text(string, depth: 1.0)
        XCTAssertEqual(mesh.bounds.min.z, -0.5)
        XCTAssertEqual(mesh.bounds.max.z, 0.5)
        XCTAssert(mesh.bounds.max.x > 20)
        XCTAssert(mesh.polygons.count > 150)
    }

    func testTextMeshWithString() {
        let text = "Hello"
        let font = CTFontCreateWithName("Helvetica" as CFString, 12, nil)
        let mesh = Mesh.text(text, font: font, depth: 1.0)
        XCTAssertEqual(mesh.bounds.min.z, -0.5)
        XCTAssertEqual(mesh.bounds.max.z, 0.5)
        XCTAssert(mesh.bounds.max.x > 20)
        XCTAssert(mesh.polygons.count > 150)
    }

    func testExtrudedCharacterHasCorrectWinding() throws {
        let shape = try XCTUnwrap(Path.text("e").first)
        let mesh = Mesh.extrude(shape).makeWatertight()
        XCTAssertTrue(mesh.isWatertight)
        XCTAssertTrue(mesh.isConsistentlyWound)
    }

    func testExtrudedTextWithHoleHasOutwardRimVertexNormals() throws {
        let font = CTFontCreateWithName("Helvetica" as CFString, 12, nil)
        let shape = try XCTUnwrap(Path.text("o", font: font).first)
        let mesh = Mesh.extrude(shape)
        let sidePolygons = mesh.polygons.filter { abs($0.plane.normal.z) < 0.5 }
        let normalDots = sidePolygons.flatMap { polygon in
            polygon.vertices.map { $0.normal.dot(polygon.plane.normal) }
        }

        XCTAssertFalse(sidePolygons.isEmpty)
        XCTAssert(normalDots.allSatisfy { $0 > 0 }, """
        bad normals: \(normalDots.filter { $0 <= 0 }.count) / \(normalDots.count), \
        min: \(normalDots.min() ?? 0)
        """)
    }

    func testInsetLetterOExpandsInnerContour() throws {
        let font = CTFontCreateWithName("Helvetica" as CFString, 12, nil)
        let shape = try XCTUnwrap(Path.text("o", font: font).first)
        let before = shape.subpaths.sorted { $0.bounds.size.x < $1.bounds.size.x }
        let after = shape.inset(by: 0.1).subpaths.sorted { $0.bounds.size.x < $1.bounds.size.x }

        XCTAssertEqual(before.count, 2)
        XCTAssertEqual(after.count, 2)
        XCTAssertGreaterThan(after[0].bounds.size.x, before[0].bounds.size.x)
        XCTAssertLessThan(after[1].bounds.size.x, before[1].bounds.size.x)
    }
}

#endif
