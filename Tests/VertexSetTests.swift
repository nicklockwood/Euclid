//
//  VertexSetTests.swift
//  GeometryScriptTests
//
//  Created by Nick Lockwood on 20/11/2019.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

class VertexSetTests: XCTestCase {
    func testExactMapping() {
        var set = VertexSet(precision: 0)
        let vertices = Mesh.cube().translated(by: .random(in: -1 ... 1)).polygons.flatMap(\.vertices)
        XCTAssertEqual(vertices.count, 24)
        let merged = Set(vertices.map { set.insert($0) })
        XCTAssertEqual(merged.count, 24)
        let positions = Set(merged.map(\.position))
        XCTAssertEqual(positions.count, 8)
    }

    func testPositionMapping() {
        let threshold = 0.1
        var set = VertexSet(precision: threshold)
        let offsets: [Vector] = [
            [-0.009662262123631735, 0.039550497356565434, -0.012382421969926213],
            [-0.042562615323627165, 0.007534910072134603, -0.04195868256452041],
            [0.036671485838505796, 0.02332469714958646, 0.001582178869459945],
            [-0.006603645940152704, 0.006381038711193152, -0.00867347646473638],
            [0.023711747109630768, 0.013248267483144782, 0.03379861150519095],
            [-0.025101400386945586, 0.001696645088126919, 0.010186788287081014],
        ]
        let vertices = zip(Mesh.cube().polygons, offsets).flatMap {
            $0.translated(by: $1).vertices
        }
        let positions = Set(vertices.map { set.insert($0).position })
        XCTAssertEqual(positions.count, 8)
    }

    func testPositionMapping2() {
        let threshold = 0.10778596717606788
        var set = VertexSet(precision: threshold)
        let offsets: [Vector] = [
            [-0.009662262123631735, 0.039550497356565434, -0.012382421969926213],
            [-0.042562615323627165, 0.007534910072134603, -0.04195868256452041],
            [0.036671485838505796, 0.02332469714958646, 0.001582178869459945],
            [-0.006603645940152704, 0.006381038711193152, -0.00867347646473638],
            [0.023711747109630768, 0.013248267483144782, 0.03379861150519095],
            [-0.025101400386945586, 0.001696645088126919, 0.010186788287081014],
        ]
        let vertices = zip(Mesh.cube().polygons, offsets).flatMap {
            $0.translated(by: $1).vertices
        }
        let positions = Set(vertices.map { set.insert($0).position })
        XCTAssertEqual(positions.count, 8)
    }

    func testPositionMapping3() {
        let threshold = 0.10778596717606788
        let pairs: [(Vertex, Vertex)] = [
            (
                Vertex(-0.542562615324, 0.507534910072, 0.458041317435),
                Vertex(-0.463328514161, 0.52332469715, 0.501582178869)
            ),
            (
                Vertex(-0.542562615324, 0.507534910072, -0.541958682565),
                Vertex(-0.463328514161, 0.52332469715, -0.49841782113099997)
            ),
            (
                Vertex(-0.542562615324, -0.492465089928, -0.541958682565),
                Vertex(-0.525101400387, -0.498303354912, -0.48981321171299996)
            ),
        ]
        for pair in pairs {
            var set = VertexSet(precision: threshold)
            let a = set.insert(pair.0)
            let b = set.insert(pair.1)
            XCTAssertEqual(a, b)
        }
        for pair in pairs {
            var set = VertexSet(precision: threshold)
            let a = set.insert(pair.0.withNormal(.unitX))
            let b = set.insert(pair.1.withNormal(.unitZ))
            XCTAssertNotEqual(a, b)
            XCTAssertEqual(a.position, b.position)
        }
    }
}
