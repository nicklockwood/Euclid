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
    func testMeshClipping() {
        let detail = 64
        let a = Mesh.sphere(slices: detail)
        let b = a.translated(by: [0.5, 0, 0])
        measure {
            let c = a.withoutOptimizations().clipped(to: b.withoutOptimizations())
            XCTAssertFalse(c.isEmpty)
        }
    }

    func testDifference() {
        let detail = 64
        let a = Mesh.cube(size: 0.8)
        let b = Mesh.sphere(slices: detail)
        measure {
            let c = a.withoutOptimizations().subtracting(b.withoutOptimizations())
            XCTAssertFalse(c.isEmpty)
        }
    }

    func testUnion() {
        let detail = 64
        let a = Mesh.cube(size: 0.8)
        let b = Mesh.sphere(slices: detail)
        measure {
            let c = a.withoutOptimizations().union(b.withoutOptimizations())
            XCTAssertFalse(c.isEmpty)
        }
    }

    func testStencil() {
        let detail = 64
        let a = Mesh.cube(size: 0.8)
        let b = Mesh.sphere(slices: detail)
        measure {
            let c = a.withoutOptimizations().stencil(b.withoutOptimizations())
            XCTAssertFalse(c.isEmpty)
        }
    }

    func testConvexHullOfMeshes() {
        let detail = 64
        let a = Mesh.sphere(slices: detail)
        let b = a.translated(by: [1, 0, 0])
        measure {
            let c = a.withoutOptimizations().convexHull(with: b.withoutOptimizations())
            XCTAssertFalse(c.isEmpty)
        }
    }

    func testConvexHullOfVertices() {
        let detail = 64
        let a = Mesh.sphere(slices: detail)
        let b = a.translated(by: [1, 0, 0])
        let vertices = (a.polygons + b.polygons).flatMap(\.vertices)
        measure {
            let c = Mesh.convexHull(of: vertices)
            XCTAssertFalse(c.isEmpty)
        }
    }

    func testConvexHullOfLineSegments() {
        let detail = 64
        let a = Mesh.sphere(slices: detail)
        let b = a.translated(by: [1, 0, 0])
        let edges = (a.polygons + b.polygons).flatMap(\.orderedEdges)
        measure {
            let c = Mesh.convexHull(of: edges)
            XCTAssertFalse(c.isEmpty)
        }
    }

    func testConvexHullOfPaths() {
        let detail = 64
        let a = Mesh.sphere(slices: detail)
        let b = a.translated(by: [1, 0, 0])
        let paths = Path((a.polygons + b.polygons).flatMap(\.orderedEdges)).subpaths
        measure {
            let c = Mesh.convexHull(of: paths)
            XCTAssertFalse(c.isEmpty)
        }
    }

    func testMinkowskiSumOfConvexMeshes() {
        let detail = 32
        let a = Mesh.sphere(slices: detail)
        let b = Mesh.cube()
        measure {
            let c = a.withoutOptimizations().minkowskiSum(with: b.withoutOptimizations())
            XCTAssertFalse(c.isEmpty)
        }
    }

    func testMinkowskiSumWithNonconvexMesh() {
        #if canImport(CoreText)
        let detail = 8
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
        let b = try XCTUnwrap(Polygon(.text("G")[0]))
        measure {
            let c = a.withoutOptimizations().minkowskiSum(with: b)
            XCTAssertFalse(c.isEmpty)
        }
        #endif
    }

    func testEdgeStroke() {
        let edges = Mesh.sphere(slices: 128).uniqueEdges
        measure {
            let mesh = Mesh.stroke(edges, detail: 3)
            XCTAssertFalse(mesh.isEmpty)
        }
    }

    func testPathStroke() {
        #if canImport(CoreText)
        let detail = 32
        let paths = Path.text("hello world", detail: detail)
        measure {
            let mesh = Mesh.stroke(paths)
            XCTAssertFalse(mesh.isEmpty)
        }
        #endif
    }

    func testPathFill() {
        #if canImport(CoreText)
        let detail = 8
        let paths = Path.text("hello world", detail: detail)
        measure {
            let mesh = Mesh.fill(paths)
            XCTAssertFalse(mesh.isEmpty)
        }
        #endif
    }

    func testMakeWatertight() {
        let detail = 128
        let a = Mesh.cube(size: 0.8)
        let b = Mesh.sphere(slices: detail)
        let c = a.subtracting(b)
        XCTAssertFalse(c.isWatertight)
        measure {
            let d = c.withoutOptimizations().makeWatertight()
            XCTAssert(d.isWatertight)
        }
    }

    func testDetesselate() {
        let detail = 64
        let a = Mesh.cube(size: 0.8)
        let b = Mesh.sphere(slices: detail)
        let c = a.subtracting(b).makeWatertight()
        measure {
            let d = c.withoutOptimizations().detessellate()
            XCTAssert(d.polygons.count < c.polygons.count)
        }
    }
}

private extension Mesh {
    /// Remove cached BSP, isConvex, etc
    func withoutOptimizations() -> Self {
        Mesh(polygons)
    }
}
