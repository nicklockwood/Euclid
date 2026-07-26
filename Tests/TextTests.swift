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
    private let textInsetDetails = [1, 2, 4, 8]
    private let positiveTextInsetDistances = [0.005, 0.01, 0.015, 0.02, 0.022, 0.024, 0.026, 0.027, 0.0275, 0.028]
    private let collapsedTextInsetDistances = [0.032, 0.035]
    private let lowercaseAOutsetDistances = [-0.01, -0.032, -0.034, -0.0345]

    func testTextPaths() {
        let text = NSAttributedString(string: "Hello")
        let paths = Path.text(text)
        XCTAssertEqual(paths.count, 5)
        XCTAssertEqual(paths.map(\.subpaths.count), [
            1, 2, 1, 1, 2,
        ])
    }

    func testLowercaseTextPaths() {
        let paths = Path.text("hello")
        XCTAssertEqual(paths.count, 5)
        XCTAssertEqual(paths.map(\.subpaths.count), [
            1, 2, 1, 1, 2,
        ])
    }

    func testTextPathCollectionPreservesContextType() {
        let paths: ContiguousArray<Path> = .text("hello")
        XCTAssertEqual(paths.count, 5)
    }

    func testLowercaseTextFillIsDetessellated() {
        let filledMesh = Mesh.fill(.text("hello"))
        let detessellatedMesh = filledMesh.detessellate()
        XCTAssertLessThanOrEqual(detessellatedMesh.polygons.count, filledMesh.polygons.count)
        XCTAssertEqual(detessellatedMesh.surfaceArea, filledMesh.surfaceArea, accuracy: epsilon)
        let polygons = detessellatedMesh.polygons
        XCTAssertEqual(polygons.count, 14)
        XCTAssertEqual(polygons.flatMap { $0.triangulate() }.count, 210)
    }

    func testTextMeshWithAttributedString() {
        let font = CTFontCreateWithName("Helvetica" as CFString, 12, nil)
        let attributes = [NSAttributedString.Key.font: font]
        let string = NSAttributedString(string: "Hello", attributes: attributes)
        let mesh = Mesh.text(string, depth: 1.0)
        XCTAssertEqual(mesh.bounds.min.z, -0.5)
        XCTAssertEqual(mesh.bounds.max.z, 0.5)
        XCTAssert(mesh.bounds.max.x > 20)
        XCTAssert(mesh.polygons.count > 150)
    }

    func testTextMeshWithString() {
        let font = CTFontCreateWithName("Helvetica" as CFString, 12, nil)
        let mesh = Mesh.text("Hello", font: font, depth: 1.0)
        XCTAssertEqual(mesh.bounds.min.z, -0.5)
        XCTAssertEqual(mesh.bounds.max.z, 0.5)
        XCTAssert(mesh.bounds.max.x > 20)
        XCTAssert(mesh.polygons.count > 150)
    }

    func testTwistedExtrudedTextArrayMatchesCompoundPathBounds() {
        let paths = Path.text("Hello")
        let arrayMesh = Mesh.extrude(paths, twist: .halfPi, sections: 8)
        let compoundMesh = Mesh.extrude(Path(subpaths: paths), twist: .halfPi, sections: 8)

        XCTAssertEqual(arrayMesh.bounds.min.x, compoundMesh.bounds.min.x, accuracy: 1)
        XCTAssertEqual(arrayMesh.bounds.min.y, compoundMesh.bounds.min.y, accuracy: 1)
        XCTAssertEqual(arrayMesh.bounds.min.z, compoundMesh.bounds.min.z, accuracy: epsilon)
        XCTAssertEqual(arrayMesh.bounds.max.x, compoundMesh.bounds.max.x, accuracy: 1)
        XCTAssertEqual(arrayMesh.bounds.max.y, compoundMesh.bounds.max.y, accuracy: 1)
        XCTAssertEqual(arrayMesh.bounds.max.z, compoundMesh.bounds.max.z, accuracy: epsilon)
        XCTAssertEqual(arrayMesh.surfaceArea, compoundMesh.surfaceArea, accuracy: 10)
    }

    func testExtrudedCharacterHasCorrectWinding() {
        let mesh = Mesh.extrude(.text("e")).makeWatertight()
        XCTAssertTrue(mesh.isWatertight)
        XCTAssertTrue(mesh.isConsistentlyWound)
    }

    func testExtrudedLowercaseQAlongCurveHasCorrectWinding() {
        let mesh = Mesh.extrude(.text("q"), along: .curve([
            .point(0, 0, 0),
            .curve(1, 0, 0),
            .point(1, 0, 1),
        ])).makeWatertight()

        XCTAssertTrue(mesh.isWatertight)
        XCTAssertTrue(mesh.isConsistentlyWound)
        XCTAssertGreaterThan(mesh.signedVolume, 0)
        XCTAssertTrue(mesh.vertexNormalsFaceOutward)
    }

    func testExtrudedTextWithHoleHasOutwardRimVertexNormals() {
        let font = CTFontCreateWithName("Helvetica" as CFString, 12, nil)
        let mesh = Mesh.extrude(.text("o", font: font))
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

    func testInsetLetterHRemovesCollapsedCrossbar() throws {
        let font = CTFontCreateWithName("Helvetica" as CFString, 1, nil)
        let shape = try XCTUnwrap(Path.text("H", font: font).first)
        let inset = shape.inset(by: 0.047)

        XCTAssertEqual(inset.subpaths.count, 2)
        XCTAssertFalse(inset.orderedEdgesContainCrossings)
        XCTAssertTrue(Mesh.fill(inset).isWatertight)
    }

    func testInsetTextPathsAreValidAcrossDepthsAndDetails() throws {
        for character in ["h", "n", "m", "w", "y"] {
            for detail in textInsetDetails {
                for distance in positiveTextInsetDistances {
                    try assertInsetTextPathIsValid(character, by: distance, detail: detail)
                }
            }
        }
        for character in ["h", "n", "m"] {
            for detail in textInsetDetails {
                for distance in collapsedTextInsetDistances {
                    try assertInsetTextPathIsValid(character, by: distance, detail: detail)
                }
            }
        }
    }

    func testInsetLowercaseYDoesNotSplitBeforeCollapseAcrossDepthsAndDetails() throws {
        for detail in textInsetDetails {
            for distance in positiveTextInsetDistances {
                try assertInsetTextPathDoesNotSplit("y", by: distance, detail: detail)
            }
        }
    }

    func testOutsetLowercaseADoesNotCreateExtraCounterOrDisappear() throws {
        for distance in lowercaseAOutsetDistances {
            try assertOutsetLowercaseARetainsExpectedCounters(by: distance)
        }
    }

    func testOutsetLowercaseADoesNotDistortInnerLoopAtHigherDetails() throws {
        for detail in [4, 8] {
            try assertOutsetLowercaseARetainsExpectedCounters(by: -0.01, detail: detail)
        }
    }

    func testInsetLowercaseEIsValid() throws {
        let shape = try XCTUnwrap(Path.text("e", detail: 2).first)
        let inset = shape.inset(by: 0.01)

        XCTAssertFalse(inset.isEmpty)
        XCTAssertFalse(inset.orderedEdgesContainCrossings)
        XCTAssertTrue(inset.subpaths.allSatisfy(\.isClosed))
    }

    private func assertOutsetLowercaseARetainsExpectedCounters(
        by distance: Double,
        detail: Int = 2,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let context = "a detail \(detail), distance \(distance)"
        let shape = try XCTUnwrap(Path.text("a", detail: detail).first, file: file, line: line)
        let outset = shape.inset(by: distance)
        let sourceArea = abs(shape.subpaths.reduce(0.0) { $0 + $1.flattened().points.vectorArea.z })
        let outsetArea = abs(outset.subpaths.reduce(0.0) { $0 + $1.flattened().points.vectorArea.z })
        let meaningfulSubpaths = outset.subpaths.filter {
            abs($0.flattened().points.vectorArea.z) > distance * distance * 0.5
        }
        let sourceCounter = shape.subpaths
            .max { $0.flattened().points.vectorArea.z < $1.flattened().points.vectorArea.z }
        let outsetCounter = outset.subpaths
            .max { $0.flattened().points.vectorArea.z < $1.flattened().points.vectorArea.z }
        XCTAssertFalse(outset.isEmpty, context + ", empty", file: file, line: line)
        XCTAssertGreaterThan(outsetArea, sourceArea, context + ", area", file: file, line: line)
        XCTAssertLessThanOrEqual(meaningfulSubpaths.count, 2, context + ", extra counter", file: file, line: line)
        XCTAssertFalse(
            outset.hasLowercaseAOutsetCornerTags(notIn: shape),
            context + ", corner tags",
            file: file,
            line: line
        )
        XCTAssertFalse(outset.orderedEdgesContainCrossings, context + ", crossings", file: file, line: line)
        XCTAssertTrue(outset.subpaths.allSatisfy(\.isClosed), context + ", open subpath", file: file, line: line)
        XCTAssertNotNil(outsetCounter, context + ", missing counter", file: file, line: line)
        if let sourceCounter, let outsetCounter {
            XCTAssertGreaterThan(
                outsetCounter.bounds.size.x,
                sourceCounter.bounds.size.x * 0.5,
                context + ", counter width",
                file: file,
                line: line
            )
            XCTAssertGreaterThan(
                outsetCounter.bounds.size.y,
                sourceCounter.bounds.size.y * 0.5,
                context + ", counter height",
                file: file,
                line: line
            )
            XCTAssertFalse(
                outsetCounter.hasLongVerticalSplitArtifact,
                context + ", counter split",
                file: file,
                line: line
            )
        }
    }

    private func assertInsetTextPathDoesNotSplit(
        _ character: String,
        by distance: Double,
        detail: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let context = "\(character) detail \(detail), distance \(distance)"
        let shape = try XCTUnwrap(Path.text(character, detail: detail).first, file: file, line: line)
        let inset = shape.inset(by: distance)

        XCTAssertEqual(inset.subpaths.count, 1, context, file: file, line: line)
        XCTAssertTrue(inset.isClosed, context, file: file, line: line)
        XCTAssertFalse(inset.hasLongVerticalSplitArtifact, context, file: file, line: line)
        XCTAssertFalse(inset.orderedEdgesContainCrossings, context, file: file, line: line)
        XCTAssertTrue(inset.isContained(in: shape), context, file: file, line: line)
        XCTAssertTrue(Mesh.fill(inset).isWatertight, context, file: file, line: line)
    }

    private func assertInsetTextPathIsValid(
        _ character: String,
        by distance: Double,
        detail: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let context = "\(character) detail \(detail), distance \(distance)"
        let shape = try XCTUnwrap(Path.text(character, detail: detail).first, file: file, line: line)
        let inset = shape.inset(by: distance)

        XCTAssertFalse(inset.isEmpty, context, file: file, line: line)
        XCTAssertFalse(inset.orderedEdgesContainCrossings, context, file: file, line: line)
        XCTAssertTrue(inset.isContained(in: shape), context, file: file, line: line)
        XCTAssertTrue(Mesh.fill(inset).isWatertight, context, file: file, line: line)
    }

    func testInsetLowercaseHBeforeCollapseIsValid() throws {
        let shape = try XCTUnwrap(Path.text("h").first)
        let inset = shape.inset(by: 0.027)

        XCTAssertFalse(inset.orderedEdgesContainCrossings)
        XCTAssertTrue(inset.isContained(in: shape))
        XCTAssertTrue(Mesh.fill(inset).isWatertight)
    }

    func testInsetNumber3IsValidAtInflection() throws {
        let shape = try XCTUnwrap(Path.text("3").first)
        let inset = shape.inset(by: 0.03)

        XCTAssertFalse(inset.orderedEdgesContainCrossings)
        XCTAssertFalse(inset.orderedEdgesDoubleBack)
        XCTAssertTrue(inset.isContained(in: shape))
        XCTAssertTrue(Mesh.fill(inset).isWatertight)
    }

    func testInsetNumber3IsValidWhenCenterCollapses() throws {
        let shape = try XCTUnwrap(Path.text("3").first)
        let inset = shape.inset(by: 0.035)

        XCTAssertFalse(inset.isEmpty)
        XCTAssertTrue(inset.subpaths.allSatisfy(\.isClosed))
        XCTAssertFalse(inset.orderedEdgesContainCrossings)
        XCTAssertTrue(inset.isContained(in: shape))
        XCTAssertTrue(Mesh.fill(inset).isWatertight)
    }
}

private extension Path {
    func isContained(in source: Path) -> Bool {
        guard let polygon = Polygon(source) else {
            return false
        }
        return subpaths.allSatisfy { subpath in
            let points = subpath.points.map(\.position)
            return zip(points, points.dropFirst()).allSatisfy { a, b in
                (0 ... 4).allSatisfy { step in
                    let t = Double(step) / 4
                    return polygon.intersects(a.lerp(b, t))
                }
            }
        }
    }

    func hasLowercaseAOutsetCornerTags(notIn source: Path) -> Bool {
        let bounds = bounds
        return orderedEdges.contains { edge in
            let midpoint = (edge.start + edge.end) / 2
            let dx = abs(edge.end.x - edge.start.x)
            let dy = abs(edge.end.y - edge.start.y)
            let isLongShallowMiddleCut = dx > bounds.size.x * 0.2 &&
                dy > bounds.size.y * 0.015 &&
                dy < bounds.size.y * 0.05 &&
                midpoint.x > bounds.min.x + bounds.size.x * 0.25 &&
                midpoint.x < bounds.min.x + bounds.size.x * 0.65 &&
                midpoint.y > bounds.min.y + bounds.size.y * 0.35 &&
                midpoint.y < bounds.min.y + bounds.size.y * 0.7
            let isCornerTag = dx > bounds.size.x * 0.08 &&
                dy > bounds.size.y * 0.035 &&
                edge.length > bounds.size.x * 0.1 &&
                midpoint.x > bounds.min.x + bounds.size.x * 0.45 &&
                midpoint.x < bounds.min.x + bounds.size.x * 0.85 &&
                midpoint.y > bounds.min.y + bounds.size.y * 0.25 &&
                midpoint.y < bounds.min.y + bounds.size.y * 0.7
            guard isLongShallowMiddleCut || isCornerTag else {
                return false
            }
            return !source.orderedEdges.contains { sourceEdge in
                abs(edge.direction.dot(sourceEdge.direction)) > 0.98 &&
                    edge.length < sourceEdge.length * 1.4 &&
                    sourceEdge.distance(from: edge) < bounds.size.x * 0.08
            }
        }
    }

    var hasLongVerticalSplitArtifact: Bool {
        let bounds = bounds
        return orderedEdges.contains { edge in
            let midpoint = (edge.start + edge.end) / 2
            let dx = abs(edge.end.x - edge.start.x)
            let dy = abs(edge.end.y - edge.start.y)
            return dx < 0.006 &&
                dy > bounds.size.y * 0.25 &&
                midpoint.x > bounds.min.x + bounds.size.x * 0.1 &&
                midpoint.x < bounds.min.x + bounds.size.x * 0.5 &&
                midpoint.y > bounds.min.y + bounds.size.y * 0.2 &&
                midpoint.y < bounds.min.y + bounds.size.y * 0.85
        }
    }

    var orderedEdgesDoubleBack: Bool {
        let subpaths = subpaths
        guard subpaths.count == 1 else {
            return subpaths.contains(where: \.orderedEdgesDoubleBack)
        }
        let edges = orderedEdges
        let count = isClosed ? edges.count : edges.count - 1
        guard count > 0 else {
            return false
        }
        for i in 0 ..< count {
            let first = edges[i].direction
            let second = edges[(i + 1) % edges.count].direction
            if first.dot(second) < -0.5,
               min(edges[i].length, edges[(i + 1) % edges.count].length) <= 0.03
            {
                return true
            }
        }
        return false
    }
}

#endif
