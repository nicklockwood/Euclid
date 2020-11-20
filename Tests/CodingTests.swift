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

    // MARK: Vector

    func testDecodingVector3() {
        XCTAssertEqual(try decode("[1, 2, 3]"), Vector(1, 2, 3))
    }

    func testDecodingVector2() {
        XCTAssertEqual(try decode("[1, 2]"), Vector(1, 2, 0))
    }

    func testDecodingKeyedVector() {
        XCTAssertEqual(try decode("{\"z\": 1}"), Vector(0, 0, 1))
    }

    func testDecodingInvalidVectors() {
        XCTAssertThrowsError(try decode("[1]") as Vector)
    }

    func testEncodingVector3() {
        XCTAssertEqual(try encode(Vector(1, 2, 3)), "[1,2,3]")
    }

    func testEncodingVector2() {
        XCTAssertEqual(try encode(Vector(1, 2, 0)), "[1,2]")
    }

    // MARK: Vertex

    func testDecodingVertex() {
        XCTAssertEqual(try decode("""
        {
            "position": [1, 2, 2],
            "normal": [1, 0, 0],
            "texcoord": [0, 1]
        }
        """), Vertex(Vector(1, 2, 2), Vector(1, 0, 0), Vector(0, 1)))
    }

    func testDecodingVertexWithoutTexcoord() {
        XCTAssertEqual(try decode("""
        {
            "position": [1, 2, 2],
            "normal": [1, 0, 0]
        }
        """), Vertex(Vector(1, 2, 2), Vector(1, 0, 0), .zero))
    }

    func testDecodingVertexWithInvalidNormal() {
        XCTAssertEqual(try decode("""
        {
            "position": [1, 2, 2],
            "normal": [1, 2, 2]
        }
        """), Vertex(
            Vector(1, 2, 2),
            Vector(0.3333333333333333, 0.6666666666666666, 0.6666666666666666),
            .zero
        ))
    }

    // MARK: Plane

    func testDecodingKeyedPlane() {
        XCTAssertEqual(try decode("""
        {
            "normal": [0, 0, 1],
            "w": 1
        }
        """), Plane(normal: Vector(0, 0, 1), w: 1))
    }

    func testDecodingUnkeyedPlane() {
        XCTAssertEqual(try decode("[0, 0, 1, 0]"), Plane(normal: Vector(0, 0, 1), w: 0))
    }

    func testEncodingPlane() {
        XCTAssertEqual(try encode(Plane(normal: Vector(0, 0, 1), w: 0)), "[0,0,1,0]")
    }

    // MARK: Polygon

    func testDecodingPolygon() {
        XCTAssertEqual(try decode("""
        {
            "vertices": [
                {
                    "position": [0, 0],
                    "normal": [0, 0, 1],
                },
                {
                    "position": [1, 0],
                    "normal": [0, 0, 1],
                },
                {
                    "position": [1, 1],
                    "normal": [0, 0, 1],
                }
            ]
        }
        """), Polygon([
            Vertex(Vector(0, 0), Vector(0, 0, 1)),
            Vertex(Vector(1, 0), Vector(0, 0, 1)),
            Vertex(Vector(1, 1), Vector(0, 0, 1)),
        ]))
    }

    func testKeylessPolygon() {
        XCTAssertEqual(try decode("""
        [
            {
                "position": [0, 0],
                "normal": [0, 0, 1],
            },
            {
                "position": [1, 0],
                "normal": [0, 0, 1],
            },
            {
                "position": [1, 1],
                "normal": [0, 0, 1],
            }
        ]
        """), Polygon([
            Vertex(Vector(0, 0), Vector(0, 0, 1)),
            Vertex(Vector(1, 0), Vector(0, 0, 1)),
            Vertex(Vector(1, 1), Vector(0, 0, 1)),
        ]))
    }

    func testDecodingPolygonWithPlane() {
        XCTAssertEqual(
            try decode("""
            {
                "vertices": [
                    {
                        "position": [0, 0],
                        "normal": [0, 0, 1],
                    },
                    {
                        "position": [1, 0],
                        "normal": [0, 0, 1],
                    },
                    {
                        "position": [1, 1],
                        "normal": [0, 0, 1],
                    }
                ],
                "plane": [0, 0, 1, 0]
            }
            """),
            Polygon(
                unchecked: [
                    Vertex(Vector(0, 0), Vector(0, 0, 1)),
                    Vertex(Vector(1, 0), Vector(0, 0, 1)),
                    Vertex(Vector(1, 1), Vector(0, 0, 1)),
                ],
                plane: Plane(normal: Vector(0, 0, 1), w: 0)
            )
        )
    }

    // MARK: Mesh

    func testDecodingMesh() {
        XCTAssertEqual(
            try decode("""
            {
                "polygons": [
                    {
                        "vertices": [
                            {
                                "position": [0, 0],
                                "normal": [0, 0, 1],
                            },
                            {
                                "position": [1, 0],
                                "normal": [0, 0, 1],
                            },
                            {
                                "position": [1, 1],
                                "normal": [0, 0, 1],
                            }
                        ]
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
        { "points": [[1, 2, 3], [2, 0]] }
        """), Path([.point(1, 2, 3), .point(2, 0)]))
    }

    func testDecodingSubpath() {
        XCTAssertEqual(try decode("""
        {
            "subpaths": [
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
        XCTAssertEqual(try decode("[1]"), Rotation(roll: 1))
        XCTAssertEqual(try decode("""
        { "radians": 1 }
        """), Rotation(roll: 1))
    }

    func testDecodingPitchYawRollRotation() {
        XCTAssertEqual(try decode("[1, 2, 3]"), Rotation(pitch: 1, yaw: 2, roll: 3))
    }

    func testDecodingAxisAngleRotation() {
        XCTAssertEqual(try decode("[0, 0, -1, 1]"), Rotation(roll: -1))
        XCTAssertEqual(try decode("""
        { "axis": [0, 0, -1], "radians": 1 }
        """), Rotation(roll: -1))
    }

    func testEncodeAndDecodingRotation() throws {
        let rotation = Rotation(axis: Vector(1, 0, 0), radians: 2)!
        let encoded = try encode(rotation)
        XCTAssert(try rotation.isEqual(to: decode(encoded)))
    }
}
