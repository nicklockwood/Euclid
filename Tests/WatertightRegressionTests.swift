//
//  WatertightRegressionTests.swift
//  EuclidTests
//
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import Foundation
import XCTest

final class WatertightRegressionTests: XCTestCase {
    func testRepairRemovesCollapsedSliverWithoutAddingDuplicateCap() throws {
        let a = Vector(-1, -1, 0), b = Vector(1, 1, 0), c = Vector(0, 1e-12, 0)
        let sliver = try XCTUnwrap(Polygon([a, b, c]))
        let upper = try XCTUnwrap(Polygon([a, c, b, [-1, 1, 0]]))
        let lower = try XCTUnwrap(Polygon([a, [1, -1, 0], b, c]))
        let polygons = [upper, lower, sliver]
        let repaired = polygons.removingOverlappingSlivers { false }
        XCTAssertEqual(repaired, [upper, lower])
    }

    func testRepairPreservesThinFacesWithoutOverusedEdges() throws {
        let sliver = try XCTUnwrap(Polygon([
            Vector(-1, -1, 0), Vector(1, 1, 0), Vector(0, 1e-12, 0),
        ]))
        let polygons = [sliver, sliver.inverted()]
        XCTAssertEqual(polygons.removingOverlappingSlivers { false }, polygons)
    }

    func testRepairPreservesNonCollapsedOverlappingFaces() throws {
        let triangle = try XCTUnwrap(Polygon([Vector(0, 0), Vector(1, 0), Vector(0, 1)]))
        let polygons = [triangle, triangle, triangle]
        XCTAssertEqual(polygons.removingOverlappingSlivers { false }, polygons)
    }

    func testSnowflakeUnionRepair() throws {
        let arm: [(Double, Double)] = [
            (1.5, 4.76969600708), (2.025, 14.090673326), (3.66562820044, 15.0378904592),
            (6.22649309339, 13.5593744239), (7.40861776956, 14.2418744239), (4.8477528766, 15.7203904592),
            (5.89731873896, 16.3263575924), (7.19247615857, 15.5785981075), (8.37460083474, 16.2610981075),
            (7.07944341513, 17.0088575924), (8.72007161557, 17.9560747255), (7.67007161557, 19.7747280735),
            (6.02944341513, 18.8275109403), (6.02944341513, 21.262713822), (4.84731873896, 20.580213822),
            (4.84731873896, 18.1450109403), (3.987782227, 17.6487573037), (6.39096098036, 28.6113620733),
            (7.9020280032, 29.4837770257), (10.9582006895, 27.7192949026), (12.1403253656, 28.4017949026),
            (9.08415267936, 30.1662770257), (11.7271355119, 31.6922038755), (10.6771355119, 33.5108572235),
            (8.03415267936, 31.9849303737), (8.03415267936, 35.5138946199), (6.8520280032, 34.8313946199),
            (6.8520280032, 31.3024303737), (5.34096098036, 30.4300154213), (5.08166353667, 39.8554388417),
            (5.96232808661, 40.3638907567), (8.10199256228, 39.1285548957), (9.28411723844, 39.8110548957),
            (7.14445276278, 41.0463907567), (8.81758563704, 42.0123744721), (7.76758563704, 43.83102782),
            (6.09445276278, 42.8650441047), (6.09445276278, 44.6501044238), (4.91232808661, 43.9676044238),
            (4.91232808661, 42.1825441047), (3.83025755043, 41.5578103893), (3.83025755043, 44.557911766),
            (2.64813287426, 43.875411766), (2.64813287426, 40.8753103893), (0.975, 39.909326674),
            (1.5, 43.5), (2.75545529808e-15, 45), (-1.5, 43.5),
            (-0.975, 39.909326674), (-2.64813287426, 40.8753103893), (-2.64813287426, 43.875411766),
            (-3.83025755043, 44.557911766), (-3.83025755043, 41.5578103893), (-4.91232808661, 42.1825441047),
            (-4.91232808661, 43.9676044238), (-6.09445276278, 44.6501044238), (-6.09445276278, 42.8650441047),
            (-7.76758563704, 43.83102782), (-8.81758563704, 42.0123744721), (-7.14445276278, 41.0463907567),
            (-9.28411723844, 39.8110548957), (-8.10199256228, 39.1285548957), (-5.96232808661, 40.3638907567),
            (-5.08166353667, 39.8554388417), (-5.34096098036, 30.4300154213), (-6.8520280032, 31.3024303737),
            (-6.8520280032, 34.8313946199), (-8.03415267936, 35.5138946199), (-8.03415267936, 31.9849303737),
            (-10.6771355119, 33.5108572235), (-11.7271355119, 31.6922038755), (-9.08415267936, 30.1662770257),
            (-12.1403253656, 28.4017949026), (-10.9582006895, 27.7192949026), (-7.9020280032, 29.4837770257),
            (-6.39096098036, 28.6113620733), (-3.987782227, 17.6487573037), (-4.84731873896, 18.1450109403),
            (-4.84731873896, 20.580213822), (-6.02944341513, 21.262713822), (-6.02944341513, 18.8275109403),
            (-7.67007161557, 19.7747280735), (-8.72007161557, 17.9560747255), (-7.07944341513, 17.0088575924),
            (-8.37460083474, 16.2610981075), (-7.19247615857, 15.5785981075), (-5.89731873896, 16.3263575924),
            (-4.8477528766, 15.7203904592), (-7.40861776956, 14.2418744239), (-6.22649309339, 13.5593744239),
            (-3.66562820044, 15.0378904592), (-2.025, 14.090673326), (-1.5, 4.76969600708),
            (-1.75865295211, 4.68050636086), (-2.01204006517, 4.57730212856), (-2.2594026359, 4.46039232903),
            (-2.5, 4.33012701892), (-2.73311174983, 4.18689624458), (-2.95803989155, 4.03112887415),
            (-3.17411093502, 3.8632913134),
        ]
        let points = (0 ..< 6).flatMap { k in
            let a = Double(k) * .pi / 3
            return arm.map { x, y in Vector(x * cos(a) - y * sin(a), x * sin(a) + y * cos(a), 0) }
        }
        let plate = Mesh.extrude(Path(points.map { .point($0) } + [.point(points[0])]), depth: 3)
        let center = try XCTUnwrap(points.max(by: { $0.y < $1.y }))
        let sides = 32
        func circle(_ radius: Double) -> [Vector] {
            (0 ..< sides).map { i in
                let a = 2 * .pi * Double(i) / Double(sides)
                return center + Vector(cos(a) * radius, sin(a) * radius, 0)
            }
        }
        let o = circle(4), h = circle(1.8)
        let lo = Vector(0, 0, -1.5), hi = Vector(0, 0, 1.5)
        var quads = [[Vector]]()
        for i in 0 ..< sides {
            let j = (i + 1) % sides
            quads += [
                [o[i] + lo, o[j] + lo, o[j] + hi, o[i] + hi],
                [h[j] + lo, h[i] + lo, h[i] + hi, h[j] + hi],
                [o[i] + hi, o[j] + hi, h[j] + hi, h[i] + hi],
                [o[j] + lo, o[i] + lo, h[i] + lo, h[j] + lo],
            ]
        }
        let ring = try Mesh(quads.map { try XCTUnwrap(Polygon($0)) })
        let joined = plate.union(ring)
        let repaired = joined.makeWatertight()
        var uses = [LineSegment: Int]()
        for polygon in repaired.polygons {
            for edge in polygon.orderedEdges {
                uses[LineSegment(undirected: edge), default: 0] += 1
            }
        }
        XCTAssertTrue(plate.isWatertight)
        XCTAssertTrue(ring.isWatertight)
        XCTAssertTrue(repaired.isWatertight)
        XCTAssertEqual(uses.values.filter { $0 != 2 }.count, 0)
    }
}
