//
//  MeshInsetTests.swift
//  Euclid
//
//  Created by Nick Lockwood on 26/07/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

#if canImport(CoreText)
import CoreText
#endif

final class MeshInsetTests: XCTestCase {
    func testInsetCanBeCancelled() {
        nonisolated(unsafe) var checks = 0
        let mesh = Mesh.cube().inset(by: 0.1) {
            checks += 1
            return checks > 1
        }

        XCTAssertGreaterThan(checks, 1)
        XCTAssertTrue(mesh.isEmpty)
    }

    func testInsetExtrudedConcaveShapeRemovesCrossingFaces() {
        let shape = Path([
            .point(0, 0),
            .point(0, 3),
            .point(1, 3),
            .point(1, 1),
            .point(2, 1),
            .point(2, 3),
            .point(3, 3),
            .point(3, 0),
            .point(0, 0),
        ])
        let mesh = Mesh.extrude(shape).inset(by: 0.6)
        XCTAssertFalse(mesh.polygons.contains { $0.orderedEdgesContainCrossings })
    }

    func testInsetFilledPathMatchesInsetPathThenFill() {
        let shape = Path.square()
        let mesh = Mesh.fill(shape).inset(by: 0.25)
        let expected = Mesh.fill(shape.inset(by: 0.25))

        XCTAssertEqual(mesh.polygons.surfaceArea, expected.polygons.surfaceArea, accuracy: epsilon)
        XCTAssertEqual(mesh.bounds, expected.bounds)
        XCTAssertEqual(mesh.materials, expected.materials)
    }

    func testInsetFilledTextDoesNotDisappear() {
        #if canImport(CoreText)
        let mesh = Mesh.fill(.text("txt")).inset(by: 0.01)

        XCTAssertFalse(mesh.isEmpty)
        XCTAssertGreaterThan(mesh.polygons.surfaceArea, 0)
        #endif
    }

    func testInsetFilledTextPreservesCharacterOffsets() {
        #if canImport(CoreText)
        let original = Mesh.fill(.text("txt"))
        let mesh = original.inset(by: 0.01)

        XCTAssertFalse(mesh.isEmpty)
        XCTAssertGreaterThan(mesh.bounds.size.x, original.bounds.size.x * 0.5)
        #endif
    }

    func testInsetExtrudedLetterHCapMatchesInsetPath() throws {
        #if canImport(CoreText)
        let font = CTFontCreateWithName("Helvetica" as CFString, 1, nil)
        let shape = try XCTUnwrap(Path.text("H", font: font).first)
        let distance = 0.047
        let mesh = Mesh.extrude(shape).inset(by: distance)
        let expected = Mesh.extrude(shape.inset(by: distance))
        let capArea = mesh.polygons.filter {
            abs($0.plane.normal.z) > 0.5
        }.surfaceArea
        let expectedCapArea = expected.polygons.filter {
            abs($0.plane.normal.z) > 0.5
        }.surfaceArea
        let crossbeamSheets = mesh.polygons.filter {
            abs($0.plane.normal.y) > 0.5 && $0.bounds.size.x > 0.4
        }

        XCTAssertFalse(mesh.polygons.contains { $0.orderedEdgesContainCrossings })
        XCTAssertEqual(capArea, expectedCapArea, accuracy: 1e-6)
        XCTAssertTrue(crossbeamSheets.isEmpty)
        #endif
    }

    func testInsetExtrudedLetterHDisappearsWhenVolumeCollapses() throws {
        #if canImport(CoreText)
        let font = CTFontCreateWithName("Helvetica" as CFString, 1, nil)
        let shape = try XCTUnwrap(Path.text("H", font: font).first)
        let mesh = Mesh.extrude(shape).inset(by: 0.05)

        XCTAssertTrue(mesh.isEmpty)
        #endif
    }

    func testInsetExtrudedNumber8DoesNotDisappear() throws {
        #if canImport(CoreText)
        let font = CTFontCreateWithName("Helvetica" as CFString, 1, nil)
        let paths = Path.text("8", font: font)
        let shape = try XCTUnwrap(paths.first)
        let distance = 0.01
        let mesh = Mesh.extrude(shape).makeWatertight().detessellate().inset(by: distance)
        XCTAssertTrue(mesh.isWatertight)
        let expected = Mesh.extrude(shape.inset(by: distance))
        let capArea = mesh.polygons.filter {
            abs($0.plane.normal.z) > 0.5
        }.surfaceArea
        let expectedCapArea = expected.polygons.filter {
            abs($0.plane.normal.z) > 0.5
        }.surfaceArea
        let topCounter = try XCTUnwrap(shape.subpaths
            .filter { $0.flattened().points.vectorArea.z > 0 }
            .max { $0.bounds.max.y < $1.bounds.max.y })
        let upperOuterHoleEdges = mesh.polygons.holeEdges.filter {
            $0.start.lerp($0.end, 0.5).y > topCounter.bounds.max.y
        }
        let crossCuttingPolygons = mesh.polygons.filter {
            abs($0.plane.normal.z) < 0.5 &&
                $0.bounds.min.x < topCounter.bounds.min.x &&
                $0.bounds.max.x > topCounter.bounds.max.x &&
                $0.bounds.intersects(topCounter.bounds)
        }
        func sideVertices(for mesh: Mesh) -> [Vertex] {
            mesh.polygons.flatMap { polygon -> [Vertex] in
                abs(polygon.plane.normal.z) < 0.5 ? polygon.vertices : []
            }
        }
        let expectedSmoothSideNormals = Dictionary(
            grouping: sideVertices(for: expected),
            by: \.position
        ).compactMapValues { vertices -> Vector? in
            let normals = vertices.map(\.normal).filter { abs($0.z) < 0.5 }
            guard let normal = normals.first,
                  normals.allSatisfy({ $0.isApproximatelyEqual(to: normal) })
            else {
                return nil
            }
            return normal
        }
        let smoothSideNormalMatches = sideVertices(for: mesh).compactMap { vertex -> Double? in
            let position = Vector(vertex.position.x, vertex.position.y)
            let expectedNormals = expectedSmoothSideNormals.filter {
                $0.key.z.sign == vertex.position.z.sign
            }
            guard abs(vertex.normal.z) < 0.5,
                  let nearest = expectedNormals.min(by: {
                      position.distance(from: Vector($0.key.x, $0.key.y)) <
                          position.distance(from: Vector($1.key.x, $1.key.y))
                  }),
                  position.distance(from: Vector(nearest.key.x, nearest.key.y)) < distance
            else {
                return nil
            }
            return abs(vertex.normal.dot(nearest.value))
        }
        let misalignedSideNormalCount = smoothSideNormalMatches.filter { $0 < 0.95 }.count
        let splitSmoothSideNormalCount = Dictionary(
            grouping: sideVertices(for: mesh),
            by: \.position
        ).filter { position, vertices in
            let contourPosition = Vector(position.x, position.y)
            let expectedNormals = expectedSmoothSideNormals.filter {
                $0.key.z.sign == position.z.sign
            }
            guard vertices.count > 1,
                  expectedNormals.contains(where: {
                      contourPosition.distance(from: Vector($0.key.x, $0.key.y)) < distance
                  })
            else {
                return false
            }
            for (i, a) in vertices.enumerated() {
                for b in vertices.dropFirst(i + 1)
                    where angleBetweenNormalizedVectors(a.normal, b.normal) < .radians(.pi / 2)
                {
                    if !a.normal.isApproximatelyEqual(to: b.normal) {
                        return true
                    }
                }
            }
            return false
        }.count

        XCTAssertFalse(paths.isEmpty)
        XCTAssertFalse(mesh.isEmpty)
        XCTAssertGreaterThan(mesh.signedVolume, 0)
        XCTAssertTrue(mesh.vertexNormalsFaceOutward)
        XCTAssertEqual(mesh.signedVolume, expected.signedVolume * 0.98, accuracy: 1e-3)
        XCTAssertEqual(capArea, expectedCapArea, accuracy: 3e-3)
        XCTAssertFalse(smoothSideNormalMatches.isEmpty)
        XCTAssertEqual(misalignedSideNormalCount, 0)
        XCTAssertEqual(splitSmoothSideNormalCount, 0)
        XCTAssertTrue(upperOuterHoleEdges.isEmpty)
        XCTAssertTrue(crossCuttingPolygons.isEmpty)
        XCTAssertTrue(mesh.polygons.areWatertight)
        XCTAssertFalse(mesh.polygons.contains(where: \.orderedEdgesContainCrossings))
        #endif
    }

    func testInsetRotatedExtrudedRoundedRectanglePreservesSmoothSideNormals() {
        let shape = Path.roundedRectangle(width: 2, height: 1, radius: 0.25, detail: 4)
        let source = Mesh.extrude(shape).makeWatertight().detessellate()
        let distance = 0.01
        let rotation = Rotation(pitch: .radians(.pi / 5), yaw: .radians(.pi / 7), roll: .radians(.pi / 9))
        let capNormal = shape.faceNormal.rotated(by: rotation)
        let expected = source.inset(by: distance).rotated(by: rotation)
        let mesh = source.rotated(by: rotation).inset(by: distance)

        func planarDistance(from a: Vector, to b: Vector) -> Double {
            let offset = a - b
            return (offset - capNormal * offset.dot(capNormal)).length
        }
        func sideVertices(for mesh: Mesh) -> [Vertex] {
            mesh.polygons.flatMap { polygon -> [Vertex] in
                abs(polygon.plane.normal.dot(capNormal)) < 0.5 ? polygon.vertices : []
            }
        }

        let expectedSmoothSideNormals = Dictionary(
            grouping: sideVertices(for: expected),
            by: \.position
        ).compactMapValues { vertices -> Vector? in
            let normals = vertices.map(\.normal).filter { abs($0.dot(capNormal)) < 0.5 }
            guard let normal = normals.first,
                  normals.allSatisfy({ $0.isApproximatelyEqual(to: normal) })
            else {
                return nil
            }
            return normal
        }
        let smoothSideNormalMatches = sideVertices(for: mesh).compactMap { vertex -> Double? in
            let expectedNormals = expectedSmoothSideNormals.filter {
                abs($0.key.dot(capNormal) - vertex.position.dot(capNormal)) < distance
            }
            guard abs(vertex.normal.dot(capNormal)) < 0.5,
                  let nearest = expectedNormals.min(by: {
                      planarDistance(from: vertex.position, to: $0.key) <
                          planarDistance(from: vertex.position, to: $1.key)
                  }),
                  planarDistance(from: vertex.position, to: nearest.key) < distance
            else {
                return nil
            }
            return abs(vertex.normal.dot(nearest.value))
        }
        let misalignedSideNormalCount = smoothSideNormalMatches.filter { $0 < 0.95 }.count

        XCTAssertTrue(mesh.isWatertight)
        XCTAssertTrue(mesh.vertexNormalsFaceOutward)
        XCTAssertFalse(smoothSideNormalMatches.isEmpty)
        XCTAssertEqual(misalignedSideNormalCount, 0)
    }

    func testInsetRotatedExtrudedConcaveShapeMatchesInsetProfile() {
        let shape = Path([
            .point(0, 0),
            .point(0, 1),
            .point(0.4, 1),
            .point(0.4, 0.4),
            .point(1, 0.4),
            .point(1, 0),
            .point(0, 0),
        ])
        let distance = 0.08
        let depth = 1.2
        let rotation = Rotation(pitch: .radians(.pi / 6), yaw: .radians(.pi / 5), roll: .radians(.pi / 8))
        let capNormal = shape.faceNormal.rotated(by: rotation)
        let mesh = Mesh.extrude(shape, depth: depth).rotated(by: rotation).inset(by: distance)
        let expected = Mesh.extrude(shape.inset(by: distance), depth: depth - distance * 2).rotated(by: rotation)

        let capArea = mesh.polygons.filter {
            abs($0.plane.normal.dot(capNormal)) > 0.5
        }.surfaceArea
        let expectedCapArea = expected.polygons.filter {
            abs($0.plane.normal.dot(capNormal)) > 0.5
        }.surfaceArea

        XCTAssertTrue(mesh.isWatertight)
        XCTAssertTrue(mesh.vertexNormalsFaceOutward)
        XCTAssertEqual(mesh.signedVolume, expected.signedVolume, accuracy: epsilon)
        XCTAssertEqual(capArea, expectedCapArea, accuracy: epsilon)
        XCTAssertFalse(mesh.polygons.contains { $0.orderedEdgesContainCrossings })
    }

    func testInsetMixedMaterialExtrusionPreservesFaceMaterials() {
        let red = Color(red: 1, green: 0, blue: 0)
        let blue = Color(red: 0, green: 0, blue: 1)
        let mesh = Mesh.extrude(.rectangle(width: 2, height: 1), depth: 1).mapPolygons {
            $0.withMaterial(abs($0.plane.normal.z) > 0.5 ? red : blue)
        }.inset(by: 0.1)
        let materials = Set(mesh.polygons.map(\.material))

        XCTAssertTrue(mesh.isWatertight)
        XCTAssertEqual(materials, [red, blue])
        XCTAssertFalse(materials.contains(nil))
    }

    func testInsetExtrusionPreservesCapVertexAttributes() {
        let color = Color(red: 1, green: 0, blue: 0)
        let shape = Path([
            .point(-1, -1, texcoord: [0.2, 0.3], color: color),
            .point(1, -1, texcoord: [0.8, 0.3], color: color),
            .point(1, 1, texcoord: [0.8, 0.7], color: color),
            .point(-1, 1, texcoord: [0.2, 0.7], color: color),
            .point(-1, -1, texcoord: [0.2, 0.3], color: color),
        ])
        let mesh = Mesh.extrude(shape).inset(by: 0.1)
        let capVertices = mesh.polygons.filter {
            abs($0.plane.normal.z) > 0.5
        }.flatMap(\.vertices)

        XCTAssertTrue(mesh.hasVertexColors)
        XCTAssertFalse(capVertices.isEmpty)
        XCTAssertTrue(capVertices.allSatisfy { $0.color == color })
        XCTAssertTrue(capVertices.contains { $0.texcoord == [0.2, 0.3] })
        XCTAssertTrue(capVertices.contains { $0.texcoord == [0.8, 0.7] })
    }

    func testInsetHandBuiltBoxMatchesExpectedBounds() {
        let material = "box"
        let mesh = Mesh(Mesh.cube(size: [2, 3, 4], material: material).polygons).inset(by: 0.25)

        XCTAssertTrue(mesh.isWatertight)
        XCTAssertEqual(mesh.bounds, Bounds(min: [-0.75, -1.25, -1.75], max: [0.75, 1.25, 1.75]), accuracy: 1e-12)
        XCTAssertEqual(mesh.signedVolume, 1.5 * 2.5 * 3.5, accuracy: 1e-12)
        XCTAssertEqual(Set(mesh.polygons.map(\.material)), [material])
    }

    func testInsetConeDoesNotTurnTipInsideOut() {
        let cone = Mesh.cone()
        let mesh = cone.inset(by: 0.1)
        XCTAssertEqual(mesh.polygons.count, cone.polygons.count)
        XCTAssertTrue(mesh.isWatertight)
        XCTAssertTrue(mesh.polygons.areWatertight)
        XCTAssertFalse(mesh.polygons.contains { $0.orderedEdgesContainCrossings })
    }

    func testInsetConeKeepsSideEdgesStraight() throws {
        let mesh = Mesh.cone().inset(by: 0.1)
        let positions = Set(mesh.polygons.flatMap { $0.vertices.map(\.position) })
        let side = positions.filter {
            let radius = Vector($0.x, $0.z).length
            return radius > epsilon && $0.y > mesh.bounds.min.y + epsilon
        }
        let directions = Dictionary(grouping: side) { position in
            let angle = atan2(position.z, position.x)
            return Int((angle / (Double.pi * 2) * 16).rounded())
        }
        for line in directions.values where line.count > 2 {
            let sorted = line.sorted { $0.y < $1.y }
            let edge = try XCTUnwrap(sorted.last) - sorted.first!
            for position in sorted.dropFirst().dropLast() {
                XCTAssert(edge.cross(position - sorted.first!).length < 1e-6)
            }
        }
    }

    func testInsetConePreservesAspectRatio() {
        let cone = Mesh.cone()
        let mesh = cone.inset(by: 0.1)
        let coneSize = cone.bounds.size
        let meshSize = mesh.bounds.size
        XCTAssertEqual(meshSize.x / coneSize.x, meshSize.y / coneSize.y, accuracy: epsilon)
        XCTAssertEqual(meshSize.z / coneSize.z, meshSize.y / coneSize.y, accuracy: epsilon)
    }

    func testInsetConeDisappearsWhenInsetPastRadius() {
        let mesh = Mesh.cone().inset(by: 0.5)
        XCTAssertTrue(mesh.isEmpty)
    }

    func testInsetPreservesMaterial() {
        let material = Mesh.Material("foo")
        let mesh = Mesh.cube(material: material).inset(by: 0.1)
        XCTAssertEqual(mesh.materials, [material])
        XCTAssertFalse(mesh.polygons.contains { $0.material != material })
    }

    func testInsetCubeSubtractingSphereDoesNotDisappear() {
        let source = Mesh.cube(size: 0.8).subtracting(Mesh.sphere()).makeWatertight()
        let mesh = source.inset(by: 0.01)
        XCTAssertTrue(source.isWatertight)
        XCTAssertFalse(mesh.isEmpty)
        XCTAssertGreaterThanOrEqual(mesh.polygons.count, source.polygons.count)
        XCTAssertTrue(mesh.isWatertight)
        XCTAssertTrue(mesh.polygons.areWatertight)
        XCTAssertFalse(mesh.polygons.contains { $0.orderedEdgesContainCrossings })
    }

    func testInsetCubeSubtractingSphereIsDeterministic() {
        let source = Mesh.cube(size: 0.8).subtracting(Mesh.sphere()).makeWatertight()
        let expected = source.inset(by: 0.01).orderedFingerprint

        for _ in 0 ..< 20 {
            XCTAssertEqual(source.inset(by: 0.01).orderedFingerprint, expected)
        }
    }

    func testInsetExtrudedTextPastStrokeWidthIsEmpty() throws {
        #if canImport(CoreText)
        let font = CTFontCreateWithName("comic sans ms" as CFString, 1, nil)
        let shape = try XCTUnwrap(Path.text("8", font: font, detail: 2).first)
        let mesh = Mesh.extrude(shape).inset(by: 0.06)

        XCTAssertTrue(mesh.isEmpty)
        #endif
    }
}
