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

    func testDecodingAngle() {
        XCTAssertEqual(try decode("[2]"), [Angle.radians(2)])
    }

    func testDecodingAngle2() {
        XCTAssertEqual(try decode("{\"r\": 2}"), Angle.radians(2))
    }

    func testDecodingAngle3() {
        XCTAssertEqual(try decode("{\"d\": 180}"), Angle.pi)
    }

    // MARK: Vector

    func testDecodingInvalidVectors() {
        XCTAssertThrowsError(try decode("[1]") as Vector)
    }

    func testEncodingVector3() {
        XCTAssertEqual(try encode(Vector(1, 2, 3)), "{\"x\":1,\"y\":2,\"z\":3}")
    }

    // MARK: Vertex

    func testDecodingVertex() {
        XCTAssertEqual(try decode("""
        {
            "p": {"x": 1, "y": 2, "z": 2},
            "n": {"x": 1, "y": 0, "z": 0},
            "uv": {"x": 0, "y": 1, "z": 0}
        }
        """), Vertex(Vector(1, 2, 2), Vector(1, 0, 0), Vector(0, 1, 0)))
    }

    func testDecodingVertexWithInvalidNormal() {
        XCTAssertEqual(try decode("""
                {
                    "p": {"x": 1, "y": 2, "z": 2},
                    "n": {"x": 1, "y": 2, "z": 2},
                    "uv": {"x": 0, "y": 1, "z": 0}
                }
        """), Vertex(
            Vector(1, 2, 2),
            Vector(0.3333333333333333, 0.6666666666666666, 0.6666666666666666),
            Vector(0, 1, 0)
        ))
    }

    // MARK: Plane

    func testDecodingKeyedPlane() {
        XCTAssertEqual(try decode("""
        {
            "n": {"x": 0, "y": 0, "z": 1},
            "w": 1
        }
        """), Plane(normal: Vector(0, 0, 1), w: 1))
    }

    func testEncodingPlane() {
        XCTAssertEqual(try encode(Plane(normal: Vector(0, 0, 1), w: 0)), """
        {"n":{"x":0,"y":0,"z":1},"w":0}
        """)
    }

    // MARK: Polygon

    func testDecodingPolygon() {
        
        XCTAssertEqual(try decode("""
        {
            "v": [
                {
                    "p": {"x": 0, "y": 0, "z": 0},
                    "n": {"x": 0, "y": 0, "z": 1},
                    "uv": {"x": 0, "y": 0, "z": 0}
                },
                {
                    "p": {"x": 1, "y": 0, "z": 0},
                    "n": {"x": 0, "y": 0, "z": 1},
                    "uv": {"x": 0, "y": 0, "z": 0}
                },
                {
                    "p": {"x": 1, "y": 1, "z": 1},
                    "n": {"x": 0, "y": 0, "z": 1},
                    "uv": {"x": 0, "y": 0, "z": 0}
                }
            ],
            "p": {
                "n": {"x": 0, "y": 0, "z": 1},
                "w": 1
                }
            }
        """), Polygon(
            unchecked: [
                Vertex(Vector(0, 0), Vector(0, 0, 1)),
                Vertex(Vector(1, 0), Vector(0, 0, 1)),
                Vertex(Vector(1, 1), Vector(0, 0, 1)),
            ],
            plane: Plane(normal: Vector(0, 0, 1), w: 0)
        ))
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

    func testDecodingMesh() {
        XCTAssertEqual(
            try decode("""
            {
                "p": [
                        {
                            "v": [
                                {
                                    "p": {"x": 0, "y": 0, "z": 0},
                                    "n": {"x": 0, "y": 0, "z": 1},
                                    "uv": {"x": 0, "y": 0, "z": 0}
                                },
                                {
                                    "p": {"x": 1, "y": 0, "z": 0},
                                    "n": {"x": 0, "y": 0, "z": 1},
                                    "uv": {"x": 0, "y": 0, "z": 0}
                                },
                                {
                                    "p": {"x": 1, "y": 1, "z": 1},
                                    "n": {"x": 0, "y": 0, "z": 1},
                                    "uv": {"x": 0, "y": 0, "z": 0}
                                }
                            ],
                            "p": {
                                "n": {"x": 0, "y": 0, "z": 1},
                                "w": 1
                                }
                            }
                ]
            }
            """),
            Mesh([
                Polygon(
                    unchecked: [
                        Vertex(Vector(0, 0), Vector(0, 0, 1)),
                        Vertex(Vector(1, 0), Vector(0, 0, 1)),
                        Vertex(Vector(1, 1), Vector(0, 0, 1)),
                    ],
                    plane: Plane(normal: Vector(0, 0, 1), w: 0)
                ),
            ])
        )
    }

    // MARK: PathPoint

    func testDecodingPathPoint3() {
        XCTAssertEqual(try decode("[1, 2, 3]"), PathPoint.point(1, 2, 3))
    }

    func testDecodingPathPoint2() {
        XCTAssertEqual(try decode("[1, 2]"), PathPoint.point(1, 2))
    }

    func testDecodingCurvedUnkeyedPathPoint3() {
        XCTAssertEqual(try decode("[1, 2, 3, true]"), PathPoint.curve(1, 2, 3))
    }

    func testDecodingCurvedPathPoint2() {
        XCTAssertEqual(try decode("[1, 2, true]"), PathPoint.curve(1, 2))
    }

    // MARK: Path

    func testDecodingSimplePath() {
        XCTAssertEqual(try decode("[[1, 2, 3], [2, 0]]"), Path([.point(1, 2, 3), .point(2, 0)]))
    }

    func testDecodingKeyedPath() {
        XCTAssertEqual(try decode("""
        { "p": [[1, 2, 3], [2, 0]] }
        """), Path([.point(1, 2, 3), .point(2, 0)]))
    }

    func testDecodingSubpath() {
        XCTAssertEqual(try decode("""
        {
            "s": [
                [[1, 2, 3], [2, 0]]
            ]
        }
        """), Path(subpaths: [Path([.point(1, 2, 3), .point(2, 0)])]))
    }

    // MARK: Rotation

    func testDecodingIdentityRotation() {
        XCTAssertEqual(try decode("[]"), Rotation.identity)
        XCTAssertEqual(try decode("{}"), Rotation.identity)
    }

    func testDecodingRollRotation() {
        XCTAssertEqual(try decode("[1]"), Rotation(roll: .radians(1)))
        XCTAssertEqual(try decode("""
        { "r": 1 }
        """), Rotation(roll: .radians(1)))
    }

    func testDecodingPitchYawRollRotation() {
        XCTAssertEqual(
            try decode("[1, 2, 3]"),
            Rotation(pitch: .radians(1), yaw: .radians(2), roll: .radians(3))
        )
    }

    func testDecodingAxisAngleRotation() {
        XCTAssertEqual(try decode("[0, 0, -1, 1]"), Rotation(roll: .radians(-1)))
        XCTAssertEqual(try decode("""
        { "a": [0, 0, -1], "r": 1 }
        """), Rotation(roll: .radians(-1)))
    }

    func testEncodeAndDecodingRotation() throws {
        let rotation = Rotation(axis: Vector(1, 0, 0), angle: .radians(2))!
        let encoded = try encode(rotation)
        XCTAssert(try rotation.isEqual(to: decode(encoded)))
    }
}
