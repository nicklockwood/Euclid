//
//  PerformanceTests.swift
//  PerformanceTests
//
//  Created by Nick Lockwood on 31/08/2025.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

import Euclid
import XCTest

final class PerformanceTests: XCTestCase {
    func testMeshClipping() throws {
        let detail = 64
        let a = Mesh.sphere(slices: detail)
        let b = a.translated(by: [0.5, 0, 0])
        measure {
            let c = a.withoutOptimizations().clipped(to: b.withoutOptimizations())
            XCTAssertFalse(c.isEmpty)
        }
    }

    func testConvexHullOfMeshes() throws {
        let detail = 64
        let a = Mesh.sphere(slices: detail)
        let b = a.translated(by: [1, 0, 0])
        measure {
            let c = a.withoutOptimizations().convexHull(with: b.withoutOptimizations())
            XCTAssertFalse(c.isEmpty)
        }
    }

    func testMinkowskiSumOfConvexMeshes() throws {
        let detail = 32
        let a = Mesh.sphere(slices: detail)
        let b = Mesh.cube()
        measure {
            let c = a.withoutOptimizations().minkowskiSum(with: b.withoutOptimizations())
            XCTAssertFalse(c.isEmpty)
        }
    }

    func testMinkowskiSumWithNonconvexMesh() throws {
        #if canImport(CoreText)
        let detail = 16
        let a = Mesh.sphere(radius: 0.1, slices: detail)
        let b = Mesh.text("G")
        measure {
            let c = a.withoutOptimizations().minkowskiSum(with: b.withoutOptimizations())
            XCTAssertFalse(c.isEmpty)
        }
        #endif
    }

    func testMinkowskiSumWithNonconvexPolygon() throws {
        #if canImport(CoreText)
        let detail = 16
        let a = Mesh.sphere(radius: 0.1, slices: detail)
        let b = Polygon(.text("G")[0])!
        measure {
            let c = a.withoutOptimizations().minkowskiSum(with: b)
            XCTAssertFalse(c.isEmpty)
        }
        #endif
    }
}

private extension Mesh {
    /// Remove cached BSP, isConvex, etc
    func withoutOptimizations() -> Self {
        Mesh(polygons)
    }
}
