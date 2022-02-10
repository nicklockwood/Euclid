//
//  TextTests.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 12/03/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import Foundation
import XCTest

class TextTests: XCTestCase {
    func testTextPaths() {
        #if canImport(CoreText)
        let text = NSAttributedString(string: "Hello")
        let paths = Path.text(text)
        XCTAssertEqual(paths.count, 5)
        XCTAssertEqual(paths.map { $0.subpaths.count }, [
            1, 2, 1, 1, 2,
        ])
        #endif
    }

    func testTextMeshWithAttributedString() {
        #if canImport(CoreText)
        let text = "Hello"
        let font = CTFontCreateWithName("Helvetica" as CFString, 12, nil)
        let attributes = [NSAttributedString.Key.font: font]
        let string = NSAttributedString(string: text, attributes: attributes)
        let mesh = Mesh.text(string, depth: 1.0)
        XCTAssertEqual(mesh.bounds.min.z, -0.5)
        XCTAssertEqual(mesh.bounds.max.z, 0.5)
        XCTAssert(mesh.bounds.max.x > 20)
        XCTAssert(mesh.polygons.count > 150)
        #endif
    }

    func testTextMeshWithString() {
        #if canImport(CoreText)
        let text = "Hello"
        let font = CTFontCreateWithName("Helvetica" as CFString, 12, nil)
        let mesh = Mesh.text(text, font: font, depth: 1.0)
        XCTAssertEqual(mesh.bounds.min.z, -0.5)
        XCTAssertEqual(mesh.bounds.max.z, 0.5)
        XCTAssert(mesh.bounds.max.x > 20)
        XCTAssert(mesh.polygons.count > 150)
        #endif
    }
}
