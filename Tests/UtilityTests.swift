//
//  UtilityTests.swift
//  GeometryScriptTests
//
//  Created by Nick Lockwood on 07/11/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

class UtilityTests: XCTestCase {
    func testLinuxTestSuiteIncludesAllTests() {
        #if os(macOS)
        let thisClass = type(of: self)
        let linuxCount = thisClass.__allTests.count
        let darwinCount = thisClass.defaultTestSuite.testCaseCount
        XCTAssertEqual(linuxCount, darwinCount, "run swift test --generate-linuxmain")
        #endif
    }

    // MARK: convexness

    func testConvexnessResultNotAffectedByTranslation() {
        let vectors = [
            Vector(-0.10606601717798211, 0, -0.10606601717798216),
            Vector(-0.0574025148547635, 0, -0.138581929876693),
            Vector(-0.15648794521398243, 0, -0.1188726123511085),
            Vector(-0.16970931752558446, 0, -0.09908543035921899),
            Vector(-0.16346853203274558, 0, -0.06771088298918408),
        ]
        XCTAssertTrue(pointsAreConvex(vectors))
        let normal = Vector(0, 1, 0)
        let offset = Vector(0, 0, 3)
        let vertices = vectors.map { Vertex($0, normal).translated(by: offset) }
        XCTAssertTrue(verticesAreConvex(vertices))
    }

    func testColinearPointsDontPreventConvexness() {
        let vectors = [
            Vector(0, 1),
            Vector(0, 0),
            Vector(0, -1),
            Vector(1, -1),
        ]
        XCTAssertTrue(pointsAreConvex(vectors))
    }

    // MARK: degeneracy

    func testDegenerateColinearVertices() {
        let normal = Vector(0, 0, 1)
        let vertices = [
            Vertex(Vector(0, 1), normal),
            Vertex(Vector(0, 0), normal),
            Vertex(Vector(0, -2), normal),
        ]
        XCTAssertTrue(verticesAreDegenerate(vertices))
    }

    func testNonDegenerateColinearVertices() {
        let normal = Vector(0, 0, 1)
        let vertices = [
            Vertex(Vector(0, 1), normal),
            Vertex(Vector(0, 0), normal),
            Vertex(Vector(0, -2), normal),
            Vertex(Vector(1.5, -1), normal),
        ]
        XCTAssertFalse(verticesAreDegenerate(vertices))
    }

    func testDegenerateVerticesWithZeroLengthEdge() {
        let normal = Vector(0, 0, 1)
        let vertices = [
            Vertex(Vector(0, 1), normal),
            Vertex(Vector(0, -1), normal),
            Vertex(Vector(0, -1), normal),
            Vertex(Vector(1.5, 0), normal),
        ]
        XCTAssertTrue(verticesAreDegenerate(vertices))
    }
}
