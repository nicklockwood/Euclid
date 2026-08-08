//
//  MeshShapeTests.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 06/02/2022.
//  Copyright © 2022 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

final class MeshShapeTests: XCTestCase {
    // MARK: Primitives

    func testCubeAppliesCenterSizeFacesAndMaterial() {
        let material = "cube"
        let mesh = Mesh.cube(
            center: [1, 1, 1],
            size: [2, 4, 6],
            faces: .frontAndBack,
            material: material
        )

        XCTAssertEqual(mesh.polygons.count, 12)
        XCTAssertEqual(mesh.bounds, Bounds(min: [0, -1, -2], max: [2, 3, 4]))
        XCTAssertEqual(mesh.materials, [material])
        XCTAssertTrue(mesh.isWatertight)
        XCTAssertFalse(mesh.isKnownConvex)
        XCTAssertEqual(mesh.planarIfSet, false)
    }

    func testCubeBackFacesAreInverted() {
        let front = Mesh.cube(faces: .front)
        let back = Mesh.cube(faces: .back)

        XCTAssertEqual(front.polygons.count, back.polygons.count)
        XCTAssertEqual(front.bounds, back.bounds)
        XCTAssertEqual(
            front.polygons.first?.plane.normal,
            back.polygons.first?.plane.inverted().normal
        )
        XCTAssertFalse(back.isKnownConvex)
    }

    func testThinCubeHasNonPlanarStateSet() {
        let mesh = Mesh.cube(size: [1, 1, epsilon / 2])
        XCTAssertEqual(mesh.planarIfSet, false)
    }

    func testIcosahedronHasExpectedTopologyAndRadius() {
        let radius = 2.0
        let material = "icosahedron"
        let mesh = Mesh.icosahedron(radius: radius, wrapMode: .none, material: material)

        XCTAssertEqual(mesh.polygons.count, 20)
        XCTAssertEqual(Set(mesh.polygons.flatMap(\.vertices).map(\.position)).count, 12)
        XCTAssertTrue(mesh.polygons.flatMap(\.vertices).allSatisfy {
            $0.position.length.isApproximatelyEqual(to: radius, absoluteTolerance: epsilon)
        })
        XCTAssertEqual(mesh.materials, [material])
        XCTAssertTrue(mesh.isWatertight)
        XCTAssertTrue(mesh.isKnownConvex)
        XCTAssertEqual(mesh.planarIfSet, false)
    }

    func testIcosphereSubdivisionsIncreaseTriangleCount() {
        XCTAssertEqual(Mesh.icosphere(subdivisions: 0, wrapMode: .none).polygons.count, 20)
        XCTAssertEqual(Mesh.icosphere(subdivisions: 1, wrapMode: .none).polygons.count, 80)
        XCTAssertEqual(Mesh.icosphere(subdivisions: 2, wrapMode: .none).polygons.count, 320)
    }

    func testIcosphereAppliesRadiusToPositionsAndNormals() {
        let radius = 3.0
        let mesh = Mesh.icosphere(radius: radius, subdivisions: 1, wrapMode: .none)

        XCTAssertEqual(mesh.bounds, Bounds(min: .init(size: -radius), max: .init(size: radius)))
        XCTAssertTrue(mesh.polygons.flatMap(\.vertices).allSatisfy {
            $0.position.length.isApproximatelyEqual(to: radius, absoluteTolerance: epsilon) &&
                $0.normal.isApproximatelyEqual(to: $0.position.normalized(), absoluteTolerance: epsilon)
        })
        XCTAssertTrue(mesh.isWatertight)
        XCTAssertTrue(mesh.isKnownConvex)
        XCTAssertEqual(mesh.planarIfSet, false)
    }

    func testSphereAppliesRadiusAndStacks() {
        let lowDetail = Mesh.sphere(radius: 2, slices: 12, stacks: 2, wrapMode: .none)
        let highDetail = Mesh.sphere(radius: 2, slices: 12, stacks: 6, wrapMode: .none)

        XCTAssertGreaterThan(highDetail.polygons.count, lowDetail.polygons.count)
        XCTAssertEqual(highDetail.bounds, Bounds(min: [-2, -2, -2], max: [2, 2, 2]), accuracy: epsilon)
        XCTAssertTrue(highDetail.polygons.flatMap(\.vertices).allSatisfy {
            $0.position.length <= 2 + epsilon
        })
        XCTAssertTrue(highDetail.isWatertight)
        XCTAssertTrue(highDetail.isKnownConvex)
        XCTAssertEqual(highDetail.planarIfSet, false)
    }

    func testCylinderNormalizesRadiusAndHeight() {
        let mesh = Mesh.cylinder(radius: -2, height: -3, slices: 8, wrapMode: .none)

        XCTAssertEqual(mesh.bounds, Bounds(min: [-2, -1.5, -2], max: [2, 1.5, 2]), accuracy: epsilon)
        XCTAssertTrue(mesh.isWatertight)
        XCTAssertTrue(mesh.isKnownConvex)
        XCTAssertEqual(mesh.planarIfSet, false)
    }

    func testCylinderWithZeroHeightBuildsFlatWatertightDisk() {
        let mesh = Mesh.cylinder(radius: 2, height: 0, slices: 8, wrapMode: .none)

        XCTAssertEqual(mesh.bounds, Bounds(min: [-2, 0, -2], max: [2, 0, 2]), accuracy: epsilon)
        XCTAssertTrue(mesh.isWatertight)
        XCTAssertTrue(mesh.isKnownConvex)
        XCTAssertEqual(mesh.planarIfSet, true)
    }

    func testConeAppliesStacksAndBottomPoleDetail() {
        let simple = Mesh.cone(radius: 2, height: 4, slices: 8, stacks: 1, poleDetail: 0, wrapMode: .none)
        let detailed = Mesh.cone(
            radius: 2,
            height: 4,
            slices: 8,
            stacks: 3,
            poleDetail: 2,
            addDetailAtBottomPole: true,
            wrapMode: .none
        )

        XCTAssertGreaterThan(detailed.polygons.count, simple.polygons.count)
        XCTAssertEqual(detailed.bounds, Bounds(min: [-2, -2, -2], max: [2, 2, 2]), accuracy: epsilon)
        XCTAssertTrue(detailed.isWatertight)
        XCTAssertTrue(detailed.isKnownConvex)
        XCTAssertEqual(detailed.planarIfSet, false)
    }

    func testConeNormalizesRadiusAndStackCount() {
        let negativeRadius = Mesh.cone(radius: -2, height: 4, slices: 8, stacks: 1, wrapMode: .none)
        let zeroStacks = Mesh.cone(radius: 2, height: 4, slices: 8, stacks: 0, wrapMode: .none)

        XCTAssertEqual(negativeRadius.bounds, zeroStacks.bounds, accuracy: epsilon)
        XCTAssertEqual(negativeRadius.polygons.count, zeroStacks.polygons.count)
        XCTAssertTrue(zeroStacks.isWatertight)
        XCTAssertTrue(zeroStacks.isKnownConvex)
    }

    // MARK: Cancellation

    func testPrimitiveGenerationCanBeCancelled() {
        for build in [
            { Mesh.cone(slices: 256, isCancelled: $0) },
            { Mesh.cylinder(slices: 256, isCancelled: $0) },
            { Mesh.sphere(slices: 256, isCancelled: $0) },
        ] {
            nonisolated(unsafe) var checks = 0
            let mesh = build {
                checks += 1
                return checks > 3
            }
            XCTAssertGreaterThan(checks, 3)
            XCTAssertLessThan(checks, 10)
            XCTAssertLessThan(mesh.polygons.count, 256 * 2)
        }
    }

    func testHighDetailPrimitiveGenerationCanBeCancelledImmediately() {
        for build in [
            { Mesh.cone(slices: 20_000_000, isCancelled: $0) },
            { Mesh.cylinder(slices: 20_000_000, isCancelled: $0) },
            { Mesh.sphere(slices: 20_000_000, isCancelled: $0) },
        ] {
            nonisolated(unsafe) var checks = 0
            let mesh = build {
                checks += 1
                return true
            }
            XCTAssertLessThan(checks, 5)
            XCTAssert(mesh.polygons.isEmpty)
        }
    }

    func testHighDetailSphereGenerationCanBeCancelledWhileBuildingProfile() {
        nonisolated(unsafe) var checks = 0
        let mesh = Mesh.sphere(slices: 20_000_000) {
            checks += 1
            return checks > 2
        }
        XCTAssertGreaterThan(checks, 2)
        XCTAssertLessThan(checks, 10)
        XCTAssert(mesh.polygons.isEmpty)
    }

    func testIcosphereGenerationCanBeCancelled() {
        nonisolated(unsafe) var checks = 0
        let mesh = Mesh.icosphere(subdivisions: 10) {
            checks += 1
            return checks > 1
        }

        XCTAssertGreaterThan(checks, 1)
        XCTAssertLessThanOrEqual(checks, 10)
        XCTAssertEqual(mesh.polygons.count, 80)
    }
}
