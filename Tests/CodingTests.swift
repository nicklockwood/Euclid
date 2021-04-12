//
//  CodingTests.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 20/11/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

class CodingTests: XCTestCase {
    private func decode<T: Decodable>(_ string: String) throws -> T {
        let data = string.data(using: .utf8)!
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func encode<T: Encodable>(_ value: T) throws -> String {
        let data = try JSONEncoder().encode(value)
        return String(data: data, encoding: .utf8)!
    }

    // MARK: Angle

    func testDecodingAngle() throws {
        let angle = Angle.pi
        let encoded = try encode(angle)
        XCTAssert(try angle == decode(encoded))
    }

    func testDecodingAngle2() throws {
        let angle = Angle.degrees(180)
        let encoded = try encode(angle)
        XCTAssert(try angle == decode(encoded))
    }

    // MARK: Vector

    func testEncodingVector3() throws {
        let vector = Vector(1, 2, 3)
        let encoded = try encode(vector)
        XCTAssert(try vector.isEqual(to: decode(encoded)))
    }

    // MARK: Vertex

    func testDecodingVertex() throws {
        let vertex = Vertex(Vector(1, 2, 2), Vector(1, 0, 0), Vector(0, 1, 0))
        let encoded = try encode(vertex)
        XCTAssert(try vertex.isEqual(to: decode(encoded)))
    }

    // MARK: Plane

    func testDecodingKeyedPlane() throws {
        let plane = Plane(normal: Vector(0, 0, 1), w: 1)!
        let encoded = try encode(plane)
        XCTAssert(try plane.isEqual(to: decode(encoded)))
    }

    // MARK: Polygon

    func testDecodingPolygon() throws {
        let polygon = Polygon(
            unchecked: [
                Vertex(Vector(0, 0), Vector(0, 0, 1)),
                Vertex(Vector(1, 0), Vector(0, 0, 1)),
                Vertex(Vector(1, 1), Vector(0, 0, 1)),
            ],
            plane: Plane(normal: Vector(0, 0, 1), w: 0)
        )
        let encoded = try encode(polygon)
        XCTAssert(try polygon == decode(encoded))
    }

    // MARK: Material

    func testEncodingPolygonWithNilMaterial() throws {
        let polygon = Polygon(shape: .square(), material: nil)
        let encoded = try encode(polygon)
        let decoded = try decode(encoded) as Euclid.Polygon
        XCTAssertNil(decoded.material)
    }

    func testEncodingPolygonWithStringMaterial() throws {
        let polygon = Polygon(shape: .square(), material: "foo")
        let encoded = try encode(polygon)
        let decoded = try decode(encoded) as Euclid.Polygon
        XCTAssertEqual(decoded.material, polygon?.material)
    }

    func testEncodingPolygonWithIntMaterial() throws {
        let polygon = Polygon(shape: .square(), material: 5)
        let encoded = try encode(polygon)
        let decoded = try decode(encoded) as Euclid.Polygon
        XCTAssertEqual(decoded.material, polygon?.material)
    }

    func testEncodingPolygonWithDataMaterial() throws {
        let polygon = Polygon(shape: .square(), material: "foo".data(using: .utf8))
        let encoded = try encode(polygon)
        let decoded = try decode(encoded) as Euclid.Polygon
        XCTAssertEqual(decoded.material, polygon?.material)
    }

    func testEncodingPolygonWithUnsupportedMaterial() throws {
        struct Foo: Hashable {}
        let polygon = Polygon(shape: .square(), material: Foo())
        XCTAssertThrowsError(try encode(polygon))
    }

    func testEncodingPolygonWithOSColorMaterial() throws {
        #if canImport(UIKit)
        let polygon = Polygon(shape: .square(), material: UIColor.red)
        XCTAssertEqual(polygon?.material, polygon?.material)
        #elseif canImport(AppKit)
        let polygon = Polygon(shape: .square(), material: NSColor.red)
        #else
        let polygon = Polygon(shape: .square())
        #endif
        let encoded = try encode(polygon)
        let decoded = try decode(encoded) as Euclid.Polygon
        XCTAssertEqual(decoded.material, polygon?.material)
    }

    // MARK: Mesh

    func testDecodingMesh() throws {
        let mesh = Mesh([
            Polygon(
                unchecked: [
                    Vertex(Vector(0, 0), Vector(0, 0, 1)),
                    Vertex(Vector(1, 0), Vector(0, 0, 1)),
                    Vertex(Vector(1, 1), Vector(0, 0, 1)),
                ],
                plane: Plane(normal: Vector(0, 0, 1), w: 0)
            ),
        ])
        let encoded = try encode(mesh)
        XCTAssert(try mesh == decode(encoded))
    }

    // MARK: PathPoint

    func testDecodingPathPoint() throws {
        let point = PathPoint.curve(1, 2, 3)
        let encoded = try encode(point)
        XCTAssert(try point == decode(encoded))
    }

    // MARK: Path

    func testDecodingSimplePath() throws {
        let path = Path([.point(1, 2, 3), .point(2, 0)])
        let encoded = try encode(path)
        XCTAssert(try path == decode(encoded))
    }

    func testDecodingSubpath() throws {
        let path = Path(subpaths: [Path([.point(1, 2, 3), .point(2, 0)])])
        let encoded = try encode(path)
        XCTAssert(try path == decode(encoded))
    }

    // MARK: Rotation

    func testEncodeAndDecodingRotation() throws {
        let rotation = Rotation(axis: Vector(1, 0, 0), angle: .radians(2))!
        let encoded = try encode(rotation)
        XCTAssert(try rotation.isEqual(to: decode(encoded)))
    }
}
