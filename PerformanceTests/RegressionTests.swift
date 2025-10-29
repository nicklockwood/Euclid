//
//  RegressionTests.swift
//  Euclid
//
//  Created by Nick Lockwood on 16/09/2025.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

import Euclid
import XCTest

final class RegressionTests: XCTestCase {
    func testMakeDifferenceWatertight() {
        let detail = 80
        var mesh = Mesh.difference([
            .extrude(
                .circle(radius: 0.025 / 2, segments: detail),
                along: .circle(
                    radius: 0.08 / 2,
                    segments: detail
                ).translated(by: [0, 0, 0.49 * 1.07])
            ),
            Mesh.sphere(radius: 1.06 / 2, slices: detail),
        ])
        XCTAssertFalse(mesh.isWatertight)
        mesh = mesh.makeWatertight()
        XCTAssertTrue(mesh.isWatertight)
    }

    func testMakeDifferenceWatertight2() {
        let detail = 190
        let height = 64.0
        let radiusBottom = 94.0
        let radiusTop = 104.8
        let depth = height / 2
        let thickness = radiusBottom / 10
        let wallThickness = 1.0
        let diameter = (thickness * (.pi / 2) - 1.0)

        let lathe = Mesh.lathe(.init([
            .point(0, height),
            .point(radiusTop / 2 + thickness, height),
            .point(radiusBottom / 2 + thickness, 0),
            .point(0, 0),
        ]), slices: detail)

        let cube = Mesh.cube()
            .scaled(by: [
                radiusTop + thickness * 2 + wallThickness,
                height - depth,
                radiusTop + thickness * 2 + wallThickness,
            ])
            .translated(by: [0, (height + diameter) - (height - depth) / 2])

        let cone = Mesh.cone(slices: detail)
            .scaled(by: [
                radiusTop + thickness * 2 + wallThickness * 2,
                thickness * 2,
                radiusTop + thickness * 2 + wallThickness * 2,
            ])
            .rotated(by: .roll(.pi))
            .translated(by: [0, height / 2 + thickness / 2])

        var mesh = Mesh.difference([lathe, cube, cone])
        XCTAssertFalse(mesh.isWatertight)

        XCTAssertEqual(lathe.polygons.count, 570)
        XCTAssertEqual(cube.polygons.count, 6)
        XCTAssertEqual(cone.polygons.count, 950)
        XCTAssertEqual(mesh.polygons.count, 1140)

        mesh = mesh.makeWatertight()
        XCTAssertTrue(mesh.isWatertight)
    }

    func testMakeExtrudedTextWatertight() throws {
        #if canImport(CoreText)
        let detail = 64
        var mesh = try Mesh.extrude(
            Path(subpaths: Path.text("Hello", detail: detail / 8))
                .scaled(by: 0.1)
                .rotated(by: XCTUnwrap(.init(axis: .unitZ, angle: -.halfPi))),
            along: .curve([
                .point(0, 0),
                .curve(0, 0, 1),
                .curve(0, 1, 1),
                .curve(1, 1, 1),
                .curve(1, 1, 2),
            ], detail: detail / 4)
        )
        XCTAssertFalse(mesh.isWatertight)
        mesh = mesh.makeWatertight()
        XCTAssertTrue(mesh.isWatertight)
        #endif
    }

    func testMakeExtrudedTextWatertight2() {
        #if canImport(CoreText)
        let detail = 16
        let font = CTFontCreateWithName("comic sans ms" as CFString, 1, nil)
        var mesh = Mesh.difference([
            .extrude(
                Path(subpaths: Path.text("Hello\nWorld!", font: font, detail: detail / 8)),
                along: .circle(radius: 0.5, segments: detail)
            ).translated(by: [6, 0]),
            .cube(size: 12),
        ])
        XCTAssertFalse(mesh.isWatertight)
        mesh = mesh.makeWatertight()
        XCTAssertTrue(mesh.isWatertight)
        #endif
    }
}
