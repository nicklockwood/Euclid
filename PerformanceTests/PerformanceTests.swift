//
//  PerformanceTests.swift
//  PerformanceTests
//
//  Created by Nick Lockwood on 31/08/2025.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

import Euclid
import Foundation
import XCTest

final class PerformanceTests: XCTestCase {
    @MainActor
    func testGearCapTriangulation() throws {
        let polygon = try XCTUnwrap(Self.largeGearCapPolygon)
        let iterations = 5
        var triangleCount = 0
        let durations = (0 ..< iterations).map { _ in
            Self.duration {
                let triangles = polygon.triangulate()
                XCTAssertFalse(triangles.isEmpty)
                triangleCount = triangles.count
            }
        }
        let report = String(format: """
        Gear cap triangulation
        vertices: %d
        triangles: %d
        iterations: %d
        median: %.3fs
        min: %.3fs
        max: %.3fs
        """, polygon.vertices.count, triangleCount, iterations, durations.median(), durations.min() ?? 0, durations.max(
        ) ?? 0)
        XCTContext.runActivity(named: "Gear cap triangulation performance") {
            let attachment = XCTAttachment(string: report)
            attachment.lifetime = .keepAlways
            $0.add(attachment)
        }
        try report.write(
            toFile: "/tmp/euclid-gear-cap-triangulation-performance-report.txt",
            atomically: true,
            encoding: .utf8
        )
        print(report)
        XCTAssertGreaterThan(polygon.vertices.count, 1000)
    }

    func testGearCapTriangulationMeasurement() throws {
        let polygon = try XCTUnwrap(Self.largeGearCapPolygon)
        measure {
            let triangles = polygon.triangulate()
            XCTAssertFalse(triangles.isEmpty)
        }
    }

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
        let b = try XCTUnwrap(Path.text("G").first.flatMap { Polygon($0) })
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

    func testDetessellate() {
        let detail = 64
        let a = Mesh.cube(size: 0.8)
        let b = Mesh.sphere(slices: detail)
        let c = a.subtracting(b).makeWatertight()
        measure {
            let d = c.withoutOptimizations().detessellate()
            XCTAssert(d.polygons.count < c.polygons.count)
        }
    }

    func testDetessellateFilledText() {
        #if canImport(CoreText)
        let font = CTFontCreateWithName("Helvetica" as CFString, 2, nil)
        let mesh = Mesh.fill(Path.text("&", font: font, detail: 2)).triangulate()
        XCTAssertEqual(mesh.polygons.count, 532)
        measure {
            let detessellated = mesh.withoutOptimizations().detessellate()
            XCTAssertEqual(detessellated.polygons.count, 6)
        }
        #endif
    }

    func testDetessellateExtrudedText() {
        #if canImport(CoreText)
        let font = CTFontCreateWithName("Helvetica" as CFString, 2, nil)
        let mesh = Mesh.extrude(Path.text("Euclid", font: font, detail: 2), depth: 0.2).triangulate()
        XCTAssertEqual(mesh.polygons.count, 458)
        measure {
            let detessellated = mesh.withoutOptimizations().detessellate()
            XCTAssertEqual(detessellated.polygons.count, 167)
        }
        #endif
    }

    func testDetessellateManyPlaneGroups() {
        #if canImport(CoreText)
        let mesh = Self.stackedTextPlanes(count: 16)
        XCTAssertEqual(mesh.polygons.count, 8512)
        measure {
            let detessellated = mesh.withoutOptimizations().detessellate()
            XCTAssertEqual(detessellated.polygons.count, 352)
        }
        #endif
    }

    @MainActor
    func testInsetCancellationPerformanceRegression() throws {
        let workloads = Self.insetCancellationPerformanceWorkloads
        let iterations = 3
        let cancellationDelay = 0.05
        let maximumCancellationLatency = 0.2
        let maximumUncancelledDuration = 1.0

        var result = InsetCancellationPerformanceResult()
        for workload in workloads {
            let uncancelledDurations = (0 ..< iterations).map { _ in
                Self.duration {
                    let mesh = workload.mesh.inset(by: workload.distance) { false }
                    XCTAssertFalse(mesh.isEmpty, workload.name)
                }
            }
            let cancellationLatencies = (0 ..< iterations).map { _ in
                Self.cancellationLatency(
                    for: workload.mesh,
                    distance: workload.distance,
                    cancellationDelay: cancellationDelay
                )
            }
            result.uncancelledDurationsByWorkload[workload.name] = uncancelledDurations.median()
            result.cancellationLatenciesByWorkload[workload.name] = cancellationLatencies.compactMap(\.self).median()
            result.didObserveCancellation = result.didObserveCancellation && cancellationLatencies
                .allSatisfy { $0 != nil }
        }

        let report = Self.insetCancellationPerformanceReport(
            result: result,
            maximumCancellationLatency: maximumCancellationLatency,
            maximumUncancelledDuration: maximumUncancelledDuration
        )
        XCTContext.runActivity(named: "Inset cancellation performance") {
            let attachment = XCTAttachment(string: report)
            attachment.lifetime = .keepAlways
            $0.add(attachment)
        }
        try report.write(
            toFile: "/tmp/euclid-inset-cancellation-performance-report.txt",
            atomically: true,
            encoding: .utf8
        )
        print(report)

        guard result.didObserveCancellation else {
            throw XCTSkip("Inset completed before cancellation could be requested.")
        }
        XCTAssertLessThanOrEqual(
            result.worstCancellationLatency ?? .infinity,
            maximumCancellationLatency
        )
        XCTAssertLessThanOrEqual(result.totalUncancelledDuration, maximumUncancelledDuration)
    }
}

private extension Mesh {
    /// Remove cached BSP, isConvex, etc
    func withoutOptimizations() -> Self {
        Mesh(polygons)
    }
}

private struct InsetCancellationPerformanceResult {
    var uncancelledDurationsByWorkload = [String: TimeInterval]()
    var cancellationLatenciesByWorkload = [String: TimeInterval?]()
    var didObserveCancellation = true

    var totalUncancelledDuration: TimeInterval {
        uncancelledDurationsByWorkload.values.reduce(0, +)
    }

    var worstCancellationLatency: TimeInterval? {
        let latencies = cancellationLatenciesByWorkload.values.compactMap(\.self)
        return latencies.isEmpty ? nil : latencies.max()
    }
}

private struct InsetCancellationPerformanceWorkload {
    var name: String
    var mesh: Mesh
    var distance: Double
}

private final class CancellationProbe: @unchecked Sendable {
    private let lock = NSLock()
    private var cancelled = false
    private var requestTime: TimeInterval?

    func requestCancellation() {
        lock.lock()
        cancelled = true
        requestTime = ProcessInfo.processInfo.systemUptime
        lock.unlock()
    }

    func isCancelled() -> Bool {
        lock.lock()
        let cancelled = cancelled
        lock.unlock()
        return cancelled
    }

    var requestedAt: TimeInterval? {
        lock.lock()
        let requestTime = requestTime
        lock.unlock()
        return requestTime
    }
}

private extension PerformanceTests {
    static var largeGearCapPolygon: Euclid.Polygon? {
        let toothCount = 100
        let samplesPerTooth = 38
        let vertexCount = toothCount * samplesPerTooth
        let baseRadius = 2.0
        let toothDepth = 0.06

        let points = (0 ..< vertexCount).map { i -> Vector in
            let angle = Double(i) / Double(vertexCount) * .twoPi
            let phase = Double(i % samplesPerTooth) / Double(samplesPerTooth)
            let toothProfile = 0.5 + 0.5 * cos(phase * .twoPi)
            let radius = baseRadius + toothDepth * toothProfile
            return [radius * cos(angle), radius * sin(angle)]
        }

        return .init(points)
    }

    static var insetCancellationPerformanceWorkloads: [InsetCancellationPerformanceWorkload] {
        [
            .init(
                name: "disconnected cubes",
                mesh: disconnectedCubesBenchmarkMesh,
                distance: -0.01
            ),
            .init(
                name: "connected surface",
                mesh: connectedSurfaceBenchmarkMesh,
                distance: 0.002
            ),
        ]
    }

    static var disconnectedCubesBenchmarkMesh: Mesh {
        let gridSize = 80
        let cube = Mesh.cube(size: 0.8)
        let offset = Double(gridSize - 1) / 2
        var polygons: [Euclid.Polygon] = []
        polygons.reserveCapacity(gridSize * gridSize * cube.polygons.count)
        for y in 0 ..< gridSize {
            for x in 0 ..< gridSize {
                let position = Vector(Double(x) - offset, Double(y) - offset, 0)
                let transform = Transform(translation: position)
                polygons += cube.transformed(by: transform).polygons
            }
        }
        return Mesh(polygons).withoutOptimizations()
    }

    static var connectedSurfaceBenchmarkMesh: Mesh {
        let gridSize = 40
        let scale = 1.0 / Double(gridSize)
        let offset = Double(gridSize) / 2
        var positions = [[Vector]]()
        positions.reserveCapacity(gridSize + 1)
        for y in 0 ... gridSize {
            var row = [Vector]()
            row.reserveCapacity(gridSize + 1)
            for x in 0 ... gridSize {
                let px = (Double(x) - offset) * scale
                let py = (Double(y) - offset) * scale
                let z = sin(Double(x) * 0.17) * cos(Double(y) * 0.13) * scale * 2
                row.append(Vector(px, py, z))
            }
            positions.append(row)
        }
        var polygons: [Euclid.Polygon] = []
        polygons.reserveCapacity(gridSize * gridSize * 2)
        for y in 0 ..< gridSize {
            for x in 0 ..< gridSize {
                let firstTriangle = [
                    positions[y][x],
                    positions[y + 1][x],
                    positions[y + 1][x + 1],
                ]
                let secondTriangle = [
                    positions[y][x],
                    positions[y + 1][x + 1],
                    positions[y][x + 1],
                ]
                guard let a = Euclid.Polygon(firstTriangle),
                      let b = Euclid.Polygon(secondTriangle)
                else {
                    fatalError("Generated invalid connected-surface benchmark polygon")
                }
                polygons.append(a)
                polygons.append(b)
            }
        }
        return Mesh(polygons).withoutOptimizations()
    }

    #if canImport(CoreText)
    static func stackedTextPlanes(count: Int) -> Mesh {
        let font = CTFontCreateWithName("Helvetica" as CFString, 2, nil)
        let glyph = Mesh.fill(Path.text("&", font: font, detail: 2)).triangulate()
        var polygons = [Euclid.Polygon]()
        polygons.reserveCapacity(glyph.polygons.count * count)
        for i in 0 ..< count {
            let z = Double(i) * 0.01
            polygons += glyph.translated(by: [0, 0, z]).polygons
        }
        return Mesh(polygons).withoutOptimizations()
    }
    #endif

    static func duration(_ body: () -> Void) -> TimeInterval {
        let start = ProcessInfo.processInfo.systemUptime
        body()
        return ProcessInfo.processInfo.systemUptime - start
    }

    static func cancellationLatency(
        for mesh: Mesh,
        distance: Double,
        cancellationDelay: TimeInterval
    ) -> TimeInterval? {
        let probe = CancellationProbe()
        let queue = DispatchQueue.global(qos: .userInitiated)
        queue.asyncAfter(deadline: .now() + cancellationDelay) {
            probe.requestCancellation()
        }
        let endTime = ProcessInfo.processInfo.systemUptime + duration {
            _ = mesh.inset(by: distance) { probe.isCancelled() }
        }
        guard let requestedAt = probe.requestedAt else {
            return nil
        }
        return endTime - requestedAt
    }

    static func insetCancellationPerformanceReport(
        result: InsetCancellationPerformanceResult,
        maximumCancellationLatency: TimeInterval,
        maximumUncancelledDuration: TimeInterval
    ) -> String {
        let rows = result.uncancelledDurationsByWorkload.keys.sorted().map { name in
            let uncancelled = result.uncancelledDurationsByWorkload[name, default: .infinity]
            let cancellation = result.cancellationLatenciesByWorkload[name] ?? nil
            let cancellationText = cancellation.map {
                String(format: "%.1fms", $0 * 1000)
            } ?? "not observed"
            return String(
                format: "%@: %.1fms uncancelled, %@ cancellation",
                name,
                uncancelled * 1000,
                cancellationText
            )
        }
        let total = String(format: "%.1fms", result.totalUncancelledDuration * 1000)
        let worstCancellation = result.worstCancellationLatency.map {
            String(format: "%.1fms", $0 * 1000)
        } ?? "not observed"
        return """
        inset cancellation performance
        maximum uncancelled runtime: \(Int(maximumUncancelledDuration * 1000))ms
        maximum cancellation latency: \(Int(maximumCancellationLatency * 1000))ms

        total uncancelled runtime: \(total)
        worst cancellation latency: \(worstCancellation)

        \(rows.joined(separator: "\n"))
        """
    }
}

private extension [TimeInterval] {
    func median() -> TimeInterval {
        guard !isEmpty else { return .infinity }
        let values = sorted()
        let middle = values.count / 2
        if values.count.isMultiple(of: 2) {
            return (values[middle - 1] + values[middle]) / 2
        }
        return values[middle]
    }
}
