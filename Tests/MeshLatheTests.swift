//
//  MeshLatheTests.swift
//  Euclid
//
//  Created by Nick Lockwood on 17/06/2025.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

final class MeshLatheTests: XCTestCase {
    func testLatheAlongWrapModes() {
        let profile = Path([
            .point(-0.5, 2), .point(-0.5, 1.2), .point(-0.8, 1.2), .point(-0.8, 0),
        ])
        let along = Path([.point(0, 0), .point(0, 0.8), .point(0, 2)])
        let closedProfile = Path([
            .point(-0.5, 0), .point(-0.5, 2), .point(-0.8, 2), .point(-0.8, 0), .point(-0.5, 0),
        ])
        for profile in [profile, profile.inverted(), closedProfile] {
            let mesh = Mesh.lathe(profile, along: along, slices: 8)
            XCTAssertEqual(mesh, Mesh.lathe(profile, along: along, slices: 8, wrapMode: .shrink))
            XCTAssertEqual(mesh.cubeMapped(), Mesh.lathe(profile, along: along, slices: 8, wrapMode: .box))
            XCTAssertEqual(mesh.withoutTexcoords(), Mesh.lathe(profile, along: along, slices: 8, wrapMode: .none))
            let tube = Mesh.lathe(profile, along: along, slices: 8, wrapMode: .tube)
            XCTAssertEqual(tube.withoutTexcoords(), mesh.withoutTexcoords())
            let sides = tube.polygons.filter { polygon in
                !polygon.vertices.allSatisfy { abs($0.position.y) < 1e-8 } &&
                    !polygon.vertices.allSatisfy { abs($0.position.y - 2) < 1e-8 }
            }
            XCTAssertFalse(sides.isEmpty)
            for vertex in sides.flatMap(\.vertices) {
                XCTAssertEqual(vertex.texcoord.y, 1 - vertex.position.y / 2, accuracy: 1e-8)
            }
        }
    }

    func testLatheAlongTubeWrapPreservesClosedBeveledSeam() throws {
        let profile = Path([.point(-0.1, 1), .point(-0.2, 0.5), .point(-0.1, 0)])
        let along = Path.square(size: 2)
        let (contours, _, axisOffsets) = profile.latheContoursWithOffsets(along: along, slices: 8, miterLimit: 1)
        let mesh = Mesh.lathe(profile, along: along, slices: 8, miterLimit: 1, wrapMode: .tube)
        XCTAssertTrue(mesh.polygons.areWatertight)
        for (contour, offset) in zip(contours, axisOffsets) {
            for point in contour.points {
                let vertices = mesh.polygons.flatMap(\.vertices).filter {
                    $0.position.isApproximatelyEqual(to: point.position)
                }
                XCTAssertTrue(vertices.contains { abs($0.texcoord.y - (1 - offset)) < 1e-8 })
            }
        }
        let first = try XCTUnwrap(contours.first)
        let seam = mesh.polygons.flatMap(\.vertices).filter {
            $0.position.isApproximatelyEqual(to: first.points[0].position)
        }
        XCTAssertTrue(seam.contains { abs($0.texcoord.y) < 1e-8 })
        XCTAssertTrue(seam.contains { abs($0.texcoord.y - 1) < 1e-8 })
    }

    func testLatheAlongRadialProfileProducesTube() {
        let profiles = [
            Path([.point(0, 0), .point(1, 0)]),
            Path([.point(1, 0), .point(0, 0)]),
            Path([.point(0, 0), .point(-0.4, 0), .point(-1, 0)]),
            Path([.point(0, 2), .point(-1, 2)]),
        ]
        let axes: [Path] = [.circle(radius: 3, segments: 16), .line(.zero, [0, 2, 0])]
        let expectedProfile = Path([.point(-1, 1), .point(-1, 0)])
        for along in axes {
            let expected = Mesh.lathe(expectedProfile, along: along, slices: 8)
            for profile in profiles {
                let mesh = Mesh.lathe(profile, along: along, slices: 8)
                XCTAssertFalse(mesh.polygons.isEmpty)
                XCTAssertEqual(mesh, expected)
                XCTAssertTrue(mesh.polygons.areWatertight)
            }
        }
    }

    func testLatheAlongClosedPathJoinsMatchingEnds() throws {
        let profile = Path([.point(-0.1, 1), .point(-0.2, 0.5), .point(-0.1, 0)])
        let axes: [Path] = [
            .square(size: 2),
            .circle(radius: 1, segments: 12),
            Path([
                .point(0, 0, 0), .point(2, 0, 0), .point(2, 1, 1),
                .point(0, 2, 0.5), .point(-1, 1, -1), .point(0, 0, 0),
            ]),
        ]
        for along in axes {
            for profile in [profile, profile.inverted()] {
                for limit in [MiterLimit.infinity, 1] {
                    let (contours, offsets, _) = profile.latheContoursWithOffsets(
                        along: along, slices: 8, miterLimit: limit
                    )
                    let first = try XCTUnwrap(contours.first)
                    let last = try XCTUnwrap(contours.last)
                    XCTAssertEqual(first, last)
                    XCTAssertEqual(offsets.first, 0)
                    XCTAssertEqual(offsets.last, 1)
                    let mesh = Mesh.lathe(profile, along: along, slices: 8, miterLimit: limit)
                    XCTAssertTrue(mesh.polygons.areWatertight)
                    XCTAssertGreaterThan(mesh.signedVolume, 0)
                    // Check there are no caps at the join
                    for polygon in mesh.polygons {
                        XCTAssertFalse(polygon.vertices.allSatisfy { vertex in
                            first.points.contains { $0.position.isApproximatelyEqual(to: vertex.position) }
                        })
                    }
                    for point in first.points {
                        let vertices = mesh.polygons.flatMap(\.vertices).filter {
                            $0.position.isApproximatelyEqual(to: point.position)
                        }
                        XCTAssertTrue(vertices.contains { abs($0.texcoord.y) < 1e-8 })
                        XCTAssertTrue(vertices.contains { abs($0.texcoord.y - 1) < 1e-8 })
                    }
                }
            }
        }
    }

    func testLatheAlongClosedPathPreservesColorAndTextureSeam() throws {
        let profile = Path([
            .point(-0.1, 1, color: .red), .point(-0.1, 0, color: .blue),
        ])
        let along = Path.square(size: 2)
        let contours = profile.latheContours(along: along, slices: 8, miterLimit: 1)
        let first = try XCTUnwrap(contours.first)
        let mesh = Mesh.lathe(profile, along: along, slices: 8, miterLimit: 1)
        XCTAssertTrue(mesh.polygons.areWatertight)
        for polygon in mesh.polygons {
            XCTAssertFalse(polygon.vertices.allSatisfy { vertex in
                first.points.contains { $0.position.isApproximatelyEqual(to: vertex.position) }
            })
        }
        for point in first.points {
            let vertices = mesh.polygons.flatMap(\.vertices).filter {
                $0.position.isApproximatelyEqual(to: point.position)
            }
            let start = try XCTUnwrap(vertices.first { abs($0.texcoord.y) < 1e-8 })
            let end = try XCTUnwrap(vertices.first { abs($0.texcoord.y - 1) < 1e-8 })
            XCTAssertEqual(start.color, .red)
            XCTAssertEqual(end.color, .blue)
            XCTAssertEqual(start.normal, end.normal, accuracy: 1e-8)
        }
    }

    func testLatheAlongMiterLimitBevelsSharpTurns() {
        let profile = Path([.point(-0.1, 1), .point(-0.1, 0)])
        let along = Path([.point(0, -2), .point(0, 0), .point(0.5, -1)])
        let unlimited = Mesh.lathe(profile, along: along, slices: 8)
        XCTAssertEqual(unlimited, Mesh.lathe(profile, along: along, slices: 8, miterLimit: .infinity))
        XCTAssertEqual(unlimited, Mesh.lathe(profile, along: along, slices: 8, miterLimit: 10))
        let beveled = Mesh.lathe(profile, along: along, slices: 8, miterLimit: 1)
        XCTAssertLessThan(beveled.bounds.max.y, unlimited.bounds.max.y)
        XCTAssertTrue(beveled.polygons.areWatertight)
        XCTAssertGreaterThan(beveled.signedVolume, 0)
        XCTAssertEqual(profile.latheContours(along: along, slices: 8, miterLimit: 1).count, 4)
    }

    func testLatheAlongBevelSidesRemainStraightWithAdditionalProfilePoints() {
        let along = Path([.point(0, -2), .point(0, 0), .point(0.5, -1)])
        let profile = Path([.point(-0.1, 1), .point(-0.1, 0)])
        let detailed = Path([1.0, 0.8, 2 / along.length, 0.2, 0].map { PathPoint.point(-0.1, $0) })
        let expected = Mesh.lathe(profile, along: along, slices: 8, miterLimit: 1)
        let mesh = Mesh.lathe(detailed, along: along, slices: 8, miterLimit: 1)
        XCTAssertEqual(mesh.surfaceArea, expected.surfaceArea, accuracy: 1e-8)
        XCTAssertEqual(mesh.signedVolume, expected.signedVolume, accuracy: 1e-8)
        XCTAssertTrue(mesh.polygons.areWatertight)
    }

    func testLatheAlongBevelResamplesRadiusAndTextureOffsets() {
        let profile = Path([.point(-0.2, 1), .point(-0.1, 0)])
        let along = Path([.point(0, -2), .point(0, 0), .point(0.5, -1)])
        let (contours, offsets, _) = profile.latheContoursWithOffsets(along: along, slices: 8, miterLimit: 1)
        XCTAssertEqual(contours.count, 4)
        XCTAssertEqual(offsets.count, contours.count)
        XCTAssertEqual(offsets.first, 0)
        XCTAssertEqual(offsets.last, 1)
        XCTAssertEqual(offsets, offsets.sorted())
        for (contour, offset) in zip(contours, offsets) {
            XCTAssertEqual(contour.bounds.size.z / 2, 0.2 - 0.1 * offset, accuracy: 1e-8)
        }
        let mesh = Mesh.lathe(profile, along: along, slices: 8, miterLimit: 1)
        XCTAssertTrue(mesh.polygons.areWatertight)
        for (contour, offset) in zip(contours.dropFirst().dropLast(), offsets.dropFirst().dropLast()) {
            let vertices = mesh.polygons.flatMap(\.vertices).filter { vertex in
                contour.points.contains { $0.position.isApproximatelyEqual(to: vertex.position) }
            }
            XCTAssertFalse(vertices.isEmpty)
            for vertex in vertices {
                XCTAssertEqual(vertex.texcoord.y, offset, accuracy: 1e-8)
            }
        }
    }

    func testLatheAlongBevelPreservesFlatEndsAndHandlesShort3DSegments() throws {
        let profile = Path([.point(-0.1, 1), .point(-0.1, 0.5), .point(-0.1, 0)])
        let along = Path([.point(0, 0), .point(0, 0.1), .point(0.1, 0, 0.1), .point(0.2, 0.1)])
        let contours = profile.latheContours(along: along, miterLimit: 1)
        XCTAssertEqual(try abs(XCTUnwrap(contours.last).faceNormal.dot(.unitY)), 1, accuracy: 1e-8)
        let endDirection = Vector(0.1, 0.1, -0.1).normalized()
        XCTAssertEqual(try abs(XCTUnwrap(contours.first).faceNormal.dot(endDirection)), 1, accuracy: 1e-8)
        let mesh = Mesh.lathe(profile, along: along, miterLimit: 1)
        XCTAssertFalse(mesh.polygons.isEmpty)
        XCTAssertTrue(mesh.polygons.areWatertight)
    }

    func testLatheTextureCoordinatesFollowUnevenProfileSpacing() {
        let profile = Path([2.0, 1.2, 1, 0.8, 0].map { PathPoint.point(-0.5, $0) })
        let axis = Path([.point(0, 0), .point(0, 0.3), .point(0, 2)])
        for mesh in [Mesh.lathe(profile), Mesh.lathe(profile, along: axis)] {
            let sides = mesh.polygons.filter { abs($0.plane.normal.y) < 0.5 }
            XCTAssertFalse(sides.isEmpty)
            for vertex in sides.flatMap(\.vertices) {
                XCTAssertEqual(vertex.texcoord.y, 1 - vertex.position.y / 2, accuracy: 1e-8)
            }
        }
    }

    func testLatheTextureCoordinatesIncludeRadialProfileDistance() {
        let profile = Path([
            .point(-0.5, 2), .point(-0.5, 1.2), .point(-0.8, 1.2), .point(-0.8, 0),
        ])
        let axis = Path([.point(0, 0), .point(0, 0.8), .point(0, 2)])
        for mesh in [Mesh.lathe(profile), Mesh.lathe(profile, along: axis)] {
            // Exclude end caps
            let sides = mesh.polygons.filter { polygon in
                !polygon.vertices.allSatisfy { abs($0.position.y) < 1e-8 } &&
                    !polygon.vertices.allSatisfy { abs($0.position.y - 2) < 1e-8 }
            }
            XCTAssertFalse(sides.isEmpty)
            for vertex in sides.flatMap(\.vertices) {
                let radius = Vector(vertex.position.x, 0, vertex.position.z).length
                let distance = 2 - vertex.position.y + radius - 0.5
                XCTAssertEqual(vertex.texcoord.y, distance / 2.3, accuracy: 1e-8)
            }
        }
    }

    func testStraightAlongAxisPreservesFlatEnds() {
        let open = Path([
            .point(0, 0.6),
            .point(-0.05, 0.6),
            .point(-0.25, 0.1),
            .point(-0.25, 0),
            .point(0, 0),
        ])
        let axis = Path.line(.zero, [0, 0.6, 0])
        for profile in [open, open.inverted(), open.closed(), open.closed().inverted()] {
            for slices in [3, 5, 8, 16] {
                let expected = Mesh.lathe(profile, slices: slices)
                let mesh = Mesh.lathe(profile, along: axis, slices: slices)
                XCTAssertEqual(mesh.bounds.min, expected.bounds.min, accuracy: epsilon)
                XCTAssertEqual(mesh.bounds.max, expected.bounds.max, accuracy: epsilon)
                XCTAssertEqual(mesh.surfaceArea, expected.surfaceArea, accuracy: epsilon)
                XCTAssertEqual(mesh.signedVolume, expected.signedVolume, accuracy: epsilon)
                XCTAssertTrue(mesh.polygons.areWatertight)
            }
        }
    }

    func testClosedPathTouchingOrigin() {
        let path = Path([
            .point(0, 0),
            .point(1, 0),
            .point(1, 1),
            .point(0, 1),
            .point(0, 0),
        ])

        let mesh = Mesh.lathe(path)
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
        XCTAssertEqual(mesh.polygons.count, 48)
        XCTAssertGreaterThan(mesh.signedVolume, 0)
        XCTAssert(mesh.isActuallyConvex)
        XCTAssertFalse(mesh.isKnownConvex) // can't determine this yet
    }

    func testOpenPathTouchingOriginAtBothEnds() {
        let path = Path([
            .point(0, 0),
            .point(1, 0),
            .point(1, 1),
            .point(0, 1),
        ])

        let mesh = Mesh.lathe(path)
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
        XCTAssertEqual(mesh.polygons.count, 48)
        XCTAssertGreaterThan(mesh.signedVolume, 0)
        XCTAssert(mesh.isActuallyConvex)
        XCTAssertFalse(mesh.isKnownConvex) // can't determine this yet

        let mesh2 = Mesh.lathe(path, faces: .frontAndBack)
        XCTAssert(mesh2.isWatertight)
        XCTAssert(mesh2.polygons.areWatertight)
        XCTAssertEqual(mesh2.polygons.count, 96)
        XCTAssertEqual(mesh2.signedVolume, 0)
        XCTAssertFalse(mesh2.isActuallyConvex)
        XCTAssertFalse(mesh2.isKnownConvex) // can't determine this yet
    }

    func testOpenPathTouchingOriginAtStart() {
        let path = Path([
            .point(0, 0),
            .point(1, 0),
            .point(1, 1),
        ])

        let mesh = Mesh.lathe(path)
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
        XCTAssertEqual(mesh.polygons.count, 64)
        XCTAssertEqual(mesh.signedVolume, 0)
        XCTAssertFalse(mesh.isActuallyConvex)
        XCTAssertFalse(mesh.isKnownConvex) // can't determine this yet

        let mesh2 = Mesh.lathe(path, faces: .front)
        XCTAssertFalse(mesh2.isWatertight)
        XCTAssertFalse(mesh2.polygons.areWatertight)
        XCTAssertEqual(mesh2.polygons.count, 32)
        XCTAssertNotEqual(mesh2.signedVolume, 0) // should be zero, but not reliable for non-watertight shape
    }

    func testOpenPathTouchingOriginAtEnd() {
        let path = Path([
            .point(1, 0),
            .point(1, 1),
            .point(0, 1),
        ])

        let mesh = Mesh.lathe(path)
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
        XCTAssertEqual(mesh.polygons.count, 64)
        XCTAssertEqual(mesh.signedVolume, 0)
        XCTAssertFalse(mesh.isActuallyConvex)
        XCTAssertFalse(mesh.isKnownConvex) // can't determine this yet

        let mesh2 = Mesh.lathe(path, faces: .front)
        XCTAssertFalse(mesh2.isWatertight)
        XCTAssertFalse(mesh2.polygons.areWatertight)
        XCTAssertEqual(mesh2.polygons.count, 32)
        XCTAssertNotEqual(mesh2.signedVolume, 0) // should be zero, but not reliable for non-watertight shape
    }

    func testOpenPathNotTouchingOrigin() {
        let path = Path([
            .point(1, 0),
            .point(1, 1),
        ])

        let mesh = Mesh.lathe(path)
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
        XCTAssertEqual(mesh.polygons.count, 32)
        XCTAssertEqual(mesh.signedVolume, 0)
        XCTAssertFalse(mesh.isActuallyConvex)
        XCTAssertFalse(mesh.isKnownConvex) // can't determine this yet

        let mesh2 = Mesh.lathe(path, faces: .front)
        XCTAssertFalse(mesh2.isWatertight)
        XCTAssertFalse(mesh2.polygons.areWatertight)
        XCTAssertEqual(mesh2.polygons.count, 16)
        XCTAssertNotEqual(mesh2.signedVolume, 0) // should be zero, but not reliable for non-watertight shape

        let mesh3 = Mesh.lathe(path, faces: .frontAndBack)
        XCTAssert(mesh3.isWatertight)
        XCTAssert(mesh3.polygons.areWatertight)
        XCTAssertEqual(mesh3.polygons.count, 32)
        XCTAssertEqual(mesh3.signedVolume, 0)
    }

    func testSelfIntersectingPath() {
        let path = Path([
            .point(0, 0),
            .point(1, 1),
            .point(1, 0),
            .point(0, 1),
        ])

        let mesh = Mesh.lathe(path)
        XCTAssert(mesh.isWatertight) // should be false, ideally
        XCTAssert(mesh.polygons.areWatertight) // should be false, ideally
        XCTAssertEqual(mesh.polygons.count, 48)
        XCTAssertGreaterThan(mesh.signedVolume, 0)
        XCTAssertFalse(mesh.isActuallyConvex)
        XCTAssertFalse(mesh.isKnownConvex)
    }

    func testLatheCompoundPathUsesEvenOddRule() {
        let outer = Path([
            .point(1, 0),
            .point(3, 0),
            .point(3, 10),
            .point(1, 10),
            .point(1, 0),
        ])
        let inner = Path([
            .point(1.5, 2),
            .point(2, 2),
            .point(2, 8),
            .point(1.5, 8),
            .point(1.5, 2),
        ])
        let mesh = Mesh.lathe(Path(subpaths: [outer, inner]), slices: 8)
        let submeshes = mesh.submeshes

        XCTAssertEqual(
            mesh.polygons.count,
            Mesh.lathe(outer, slices: 8).polygons.count +
                Mesh.lathe(inner, slices: 8).polygons.count
        )
        XCTAssertEqual(submeshes.count, 2)
        XCTAssertEqual(submeshes.filter { $0.signedVolume < 0 }.count, 1)
        XCTAssertTrue(mesh.isWatertight)
        XCTAssertTrue(mesh.polygons.areWatertight)
    }

    func testLatheOverlappingCompoundPathUsesEvenOddRule() {
        let first = Path([
            .point(1, 0), .point(3, 0), .point(3, 4), .point(1, 4), .point(1, 0),
        ])
        let second = Path([
            .point(2, 0), .point(4, 0), .point(4, 4), .point(2, 4), .point(2, 0),
        ])
        let mesh = Mesh.lathe(Path(subpaths: [first, second]), slices: 8)
        let submeshes = mesh.submeshes

        XCTAssertEqual(mesh.polygons.count, 64)
        XCTAssertEqual(submeshes.count, 2)
        XCTAssertTrue(submeshes.allSatisfy { $0.signedVolume > 0 })
        XCTAssertTrue(mesh.isWatertight)
        XCTAssertTrue(mesh.polygons.areWatertight)
    }

    func testLatheOverlappingCompoundPathPropagatesCancellationDuringNormalization() {
        let first = Path([
            .point(1, 0), .point(3, 0), .point(3, 4), .point(1, 4), .point(1, 0),
        ])
        let second = Path([
            .point(2, 0), .point(4, 0), .point(4, 4), .point(2, 4), .point(2, 0),
        ])
        nonisolated(unsafe) var cancellationChecks = 0
        let mesh = Mesh.lathe(Path(subpaths: [first, second]), slices: 128) {
            cancellationChecks += 1
            return cancellationChecks > 1
        }

        XCTAssertEqual(mesh, .empty)
        XCTAssertGreaterThanOrEqual(cancellationChecks, 2)
    }

    func testLatheMatchesCircularExtrusion() {
        let outer = Path([
            .point(1, -5), .point(3, -5), .point(3, 5), .point(1, 5), .point(1, -5),
        ])
        let inner = Path([
            .point(1.5, -3), .point(2.5, -3), .point(2.5, 3), .point(1.5, 3), .point(1.5, -3),
        ])
        let profile = Path(subpaths: [outer, inner])
        let lathed = Mesh.lathe(profile, slices: 8)
        let rail = Path.circle(radius: 2, segments: 8).rotated(by: .pitch(.halfPi))
        // Compensate for the circular extrusion's polygon miter so its radial edges align with the lathe.
        let scale = cos(Double.pi / 8)
        let crossSection = profile.translated(by: [-2, 0]).scaled(by: [scale, 1])
        let extruded = Mesh.extrude(crossSection, along: rail)

        XCTAssertEqual(lathed.bounds, extruded.bounds)
        XCTAssertEqual(lathed.surfaceArea, extruded.surfaceArea, accuracy: 1e-6)
        XCTAssertEqual(lathed.signedVolume, extruded.signedVolume, accuracy: 1e-6)
        XCTAssertEqual(lathed.polygons.count, extruded.polygons.count)
        XCTAssertEqual(
            lathed.submeshes.map(\.signedVolume.sign),
            extruded.submeshes.map(\.signedVolume.sign)
        )
    }
}
