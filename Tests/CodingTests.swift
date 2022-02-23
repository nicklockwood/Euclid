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
        XCTAssertEqual(try decode("{\"radians\": 2}"), Angle.radians(2))
    }

    func testDecodingAngle3() {
        XCTAssertEqual(try decode("{\"degrees\": 180}"), Angle.pi)
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
        """), Vertex(Vector(1, 2, 2), .unitX, .unitY))
    }

    func testDecodingVertexWithColor() {
        XCTAssertEqual(try decode("""
        {
            "position": [1, 2, 2],
            "normal": [1, 0, 0],
            "texcoord": [0, 1],
            "color": [1, 0, 0],
        }
        """), Vertex(Vector(1, 2, 2), .unitX, .unitY, .red))
    }

    func testDecodingVertexWithTexcoord3D() {
        XCTAssertEqual(try decode("""
        {
            "position": [1, 2, 2],
            "normal": [1, 0, 0],
            "texcoord": [0, 1, 2]
        }
        """), Vertex(Vector(1, 2, 2), .unitX, Vector(0, 1, 2)))
    }

    func testDecodingFlattenedVertex() {
        XCTAssertEqual(
            try decode("[1, 2, 2, 1, 0, 0, 0, 1]"),
            Vertex(Vector(1, 2, 2), .unitX, .unitY)
        )
    }

    func testDecodingFlattenedVertexWithOpaqueColor() {
        XCTAssertEqual(
            try decode("[1, 2, 2, 1, 0, 0, 0, 1, 0, 1, 0, 0]"),
            Vertex(Vector(1, 2, 2), .unitX, .unitY, .red)
        )
    }

    func testDecodingFlattenedVertexWithTranslucentColor() {
        XCTAssertEqual(
            try decode("[1, 2, 2, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0.5]"),
            Vertex(Vector(1, 2, 2), .unitX, .unitY, Color(1, 0, 0, 0.5))
        )
    }

    func testDecodingFlattenedVertexWithTexcoord3D() {
        XCTAssertEqual(
            try decode("[1, 2, 2, 1, 0, 0, 0, 1, 2]"),
            Vertex(Vector(1, 2, 2), .unitX, Vector(0, 1, 2))
        )
    }

    func testEncodingVertex() {
        XCTAssertEqual(
            try encode(Vertex(Vector(1, 2, 2), .unitX, .unitY)),
            "[1,2,2,1,0,0,0,1]"
        )
    }

    func testEncodingVertexWithTexcoord3D() {
        XCTAssertEqual(
            try encode(Vertex(Vector(1, 2, 2), .unitX, Vector(0, 1, 2))),
            "[1,2,2,1,0,0,0,1,2]"
        )
    }

    func testDecodingVertexWithoutTexcoord() {
        XCTAssertEqual(try decode("""
        {
            "position": [1, 2, 2],
            "normal": [1, 0, 0]
        }
        """), Vertex(Vector(1, 2, 2), .unitX, .zero))
    }

    func testDecodingFlattenedVertexWithoutTexcoord() {
        XCTAssertEqual(
            try decode("[1, 2, 2, 1, 0, 0]"),
            Vertex(Vector(1, 2, 2), .unitX)
        )
    }

    func testEncodingVertexWithoutTexcoordOrColor() {
        XCTAssertEqual(
            try encode(Vertex(Vector(1, 2, 2), .unitX)),
            "[1,2,2,1,0,0]"
        )
    }

    func testEncodingVertex2DWithoutTexcoord() {
        XCTAssertEqual(
            try encode(Vertex(Vector(1, 2), .unitX)),
            "[1,2,0,1,0,0]"
        )
    }

    func testDecodingVertexWithoutNormal() {
        XCTAssertEqual(try decode("""
        {
            "position": [1, 2, 2],
            "texcoord": [1, 0]
        }
        """), Vertex(Vector(1, 2, 2), nil, .unitX))
    }

    func testDecodingVertexWithoutNormalWithTexcoord3D() {
        XCTAssertEqual(try decode("""
        {
            "position": [1, 2, 2],
            "texcoord": [1, 0, 2]
        }
        """), Vertex(Vector(1, 2, 2), nil, Vector(1, 0, 2)))
    }

    func testDecodingFlattenedVertexWithoutNormal() {
        XCTAssertEqual(try decode("[1, 2, 2]"), Vertex(Vector(1, 2, 2)))
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

    func testEncodingVertexWithoutNormal() {
        XCTAssertEqual(
            try encode(Vertex(Vector(1, 2, 2))),
            "[1,2,2]"
        )
    }

    func testEncodingVertex2DWithoutNormal() {
        XCTAssertEqual(
            try encode(Vertex(Vector(1, 2))),
            "[1,2]"
        )
    }

    func testEncodeDecodeVertexWithTexcoordButWithoutNormal() throws {
        let vertex = Vertex(.zero, .zero, .unitY)
        let encoded = try encode(vertex)
        XCTAssertEqual(encoded, "[0,0,0,0,0,0,0,1]")
        XCTAssertEqual(try decode(encoded), vertex)
    }

    func testEncodingVertex2DWithOpaqueColor() {
        XCTAssertEqual(
            try encode(Vertex(
                Vector(1, 2),
                Vector(1, 0, 0),
                Vector(0, 1),
                .green
            )),
            "[1,2,0,1,0,0,0,1,0,0,1,0]"
        )
    }

    func testEncodingVertex3DWithTranslucentColor() {
        XCTAssertEqual(
            try encode(Vertex(
                Vector(1, 2, 2),
                Vector(1, 0, 0),
                Vector(0, 1),
                Color(0, 1, 0, 0.5)
            )),
            "[1,2,2,1,0,0,0,1,0,0,1,0,0.5]"
        )
    }

    func testEncodeDecodeVertexWithZeroTexcoord() throws {
        let vertex = Vertex(.zero, .unitY, .zero, .black)
        let encoded = try encode(vertex)
        XCTAssertEqual(encoded, "[0,0,0,0,1,0,0,0,0,0,0,0]")
        XCTAssertEqual(try decode(encoded), vertex)
    }

    func testEncodeDecodeVertexWithZeroNormalAndTexcoord() throws {
        let vertex = Vertex(.zero, .zero, .zero, .black)
        let encoded = try encode(vertex)
        XCTAssertEqual(encoded, "[0,0,0,0,0,0,0,0,0,0,0,0]")
        XCTAssertEqual(try decode(encoded), vertex)
    }

    // MARK: Plane

    func testDecodingKeyedPlane() {
        XCTAssertEqual(try decode("""
        {
            "normal": [0, 0, 1],
            "w": 1
        }
        """), Plane(normal: .unitZ, w: 1))
    }

    func testDecodingUnkeyedPlane() {
        XCTAssertEqual(try decode("[0, 0, 1, 0]"), Plane(normal: .unitZ, w: 0))
    }

    func testEncodingPlane() {
        XCTAssertEqual(try encode(Plane(normal: .unitZ, w: 0)), "[0,0,1,0]")
    }

    // MARK: Line

    func testDecodingKeyedLine() {
        XCTAssertEqual(try decode("""
        {
            "origin": [0, 0, 1],
            "direction": [0, 1, 0]
        }
        """), Line(origin: .unitZ, direction: .unitY))
    }

    func testDecodingKeyedZeroLengthLine() {
        XCTAssertThrowsError(try decode("""
        {
            "origin": [0, 0, 1],
            "direction": [0, 0, 0]
        }
        """) as Line)
    }

    func testDecodingUnkeyedLine() {
        XCTAssertEqual(
            try decode("[0, 0, 1, 0, 1, 0]"),
            Line(origin: .unitZ, direction: .unitY)
        )
    }

    func testDecodingUnkeyedZeroLengthLine() {
        XCTAssertThrowsError(try decode("[0, 0, 1, 0, 0, 0]") as Line)
    }

    func testEncodingLine() {
        XCTAssertEqual(
            try encode(Line(origin: .unitZ, direction: .unitY)),
            "[0,0,1,0,1,0]"
        )
    }

    // MARK: LineSegment

    func testDecodingKeyedLineSegment() {
        XCTAssertEqual(try decode("""
        {
            "start": [0, 0, 1],
            "end": [0, 1, 0]
        }
        """), LineSegment(.unitZ, .unitY))
    }

    func testDecodingKeyedZeroLengthLineSegment() {
        XCTAssertThrowsError(try decode("""
        {
            "start": [0, 0, 1],
            "end": [0, 0, 1]
        }
        """) as LineSegment)
    }

    func testDecodingUnkeyedLineSegment() {
        XCTAssertEqual(
            try decode("[0, 0, 1, 0, 1, 0]"),
            LineSegment(.unitZ, .unitY)
        )
    }

    func testDecodingUnkeyedZeroLengthLineSegment() {
        XCTAssertThrowsError(try decode("[0, 0, 1, 0, 0, 1]") as LineSegment)
    }

    func testEncodingLineSegment() {
        XCTAssertEqual(
            try encode(LineSegment(.unitZ, .unitY)),
            "[0,0,1,0,1,0]"
        )
    }

    // MARK: Polygon

    func testDecodingPolygon() {
        XCTAssertEqual(try decode("""
        {
            "vertices": [
                {
                    "position": [0, 0],
                    "normal": [0, 0, 1],
                    "texcoord": [0, 1],
                },
                {
                    "position": [1, 0],
                    "normal": [0, 0, 1],
                    "texcoord": [1, 1],
                },
                {
                    "position": [1, 1],
                    "normal": [0, 0, 1],
                    "texcoord": [1, 0],
                }
            ]
        }
        """), Polygon([
            Vertex(Vector(0, 0), .unitZ, Vector(0, 1)),
            Vertex(Vector(1, 0), .unitZ, Vector(1, 1)),
            Vertex(Vector(1, 1), .unitZ, Vector(1, 0)),
        ]))
    }

    func testDecodingUnkeyedPolygon() {
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
            },
        ]
        """), Polygon([
            Vertex(Vector(0, 0), .unitZ),
            Vertex(Vector(1, 0), .unitZ),
            Vertex(Vector(1, 1), .unitZ),
        ]))
    }

    func testDecodingUnkeyedPolygonWithUnkeyedVertices() {
        XCTAssertEqual(try decode("""
        [
            [0, 0, 0, 0, 0, 1],
            [1, 0, 0, 0, 0, 1],
            [1, 1, 0, 0, 0, 1],
        ]
        """), Polygon([
            Vertex(Vector(0, 0), .unitZ),
            Vertex(Vector(1, 0), .unitZ),
            Vertex(Vector(1, 1), .unitZ),
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
                    Vertex(Vector(0, 0), .unitZ),
                    Vertex(Vector(1, 0), .unitZ),
                    Vertex(Vector(1, 1), .unitZ),
                ],
                plane: Plane(normal: .unitZ, w: 0)
            )
        )
    }

    func testDecodingPolygonWithoutNormals() {
        XCTAssertEqual(try decode("""
        {
            "vertices": [
                {
                    "position": [0, 0],
                    "texcoord": [0, 1],
                },
                {
                    "position": [1, 0],
                    "texcoord": [1, 1],
                },
                {
                    "position": [1, 1],
                    "texcoord": [1, 0],
                }
            ]
        }
        """), Polygon([
            Vertex(Vector(0, 0), .unitZ, Vector(0, 1)),
            Vertex(Vector(1, 0), .unitZ, Vector(1, 1)),
            Vertex(Vector(1, 1), .unitZ, Vector(1, 0)),
        ]))
    }

    func testDecodingUnkeyedPolygonWithUnkeyedVerticesWithoutVertexNormal() {
        XCTAssertEqual(try decode("""
        [
            [0, 0],
            [1, 0],
            [1, 1],
        ]
        """), Polygon([
            Vertex(Vector(0, 0), .unitZ),
            Vertex(Vector(1, 0), .unitZ),
            Vertex(Vector(1, 1), .unitZ),
        ]))
    }

    func testEncodingPolygonWithTexcoordsWhereVertexNormalsMatchPlane() throws {
        let polygon = Polygon(
            unchecked: [
                Vertex(Vector(0, 0, 1), .unitZ, Vector(0, 1)),
                Vertex(Vector(1, 0, 1), .unitZ, Vector(1, 1)),
                Vertex(Vector(1, 1, 1), .unitZ, Vector(1, 0)),
            ],
            plane: Plane(normal: .unitZ, w: 1)
        )
        let encoded = try encode(polygon)
        XCTAssertEqual(try decode(encoded), polygon)
        XCTAssertEqual(encoded, "[[0,0,1,0,0,1,0,1],[1,0,1,0,0,1,1,1],[1,1,1,0,0,1,1,0]]")
    }

    func testEncodingPolygonWithoutTexcoordsWhereVertexNormalsMatchPlane() throws {
        let polygon = Polygon(
            unchecked: [
                Vertex(Vector(0, 0, 1), .unitZ),
                Vertex(Vector(1, 0, 1), .unitZ),
                Vertex(Vector(1, 1, 1), .unitZ),
            ],
            plane: Plane(normal: .unitZ, w: 1)
        )
        let encoded = try encode(polygon)
        XCTAssertEqual(try decode(encoded), polygon)
        XCTAssertEqual(encoded, "[[0,0,1],[1,0,1],[1,1,1]]")
    }

    func testEncodingPolygonWhereVertexNormalsDoNotMatchPlane() throws {
        let polygon = Polygon(
            unchecked: [
                Vertex(Vector(0, 0, 1), .unitZ),
                Vertex(Vector(1, 0, 1), .unitZ),
                Vertex(Vector(1, 1, 1), .unitZ),
            ],
            plane: Plane(normal: Vector(0, 0, -1), w: 1)
        )
        let encoded = try encode(polygon)
        XCTAssertEqual(try decode(encoded), polygon)
        XCTAssertEqual(encoded, "[[[0,0,1,0,0,1],[1,0,1,0,0,1],[1,1,1,0,0,1]],[0,0,-1,1]]")
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

    func testEncodingPolygonWithColorMaterial() throws {
        let polygon = Polygon(shape: .square(), material: Color.red)
        let encoded = try encode(polygon)
        let decoded = try decode(encoded) as Euclid.Polygon
        XCTAssertEqual(decoded.material, polygon?.material)
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

    // MARK: Color

    func testDecodingRGBAColor() {
        XCTAssertEqual(try decode("[1, 0, 0, 0.5]"), Color.red.withAlpha(0.5))
    }

    func testEncodingRGBAColor() {
        XCTAssertEqual(try encode(Color.gray.withAlpha(0.5)), "[0.5,0.5,0.5,0.5]")
    }

    func testDecodingRGBColor() {
        XCTAssertEqual(try decode("[1, 1, 0]"), Color.yellow)
    }

    func testEncodingRGBColor() {
        XCTAssertEqual(try encode(Color.cyan), "[0,1,1]")
    }

    func testDecodingInvalidColor() {
        XCTAssertThrowsError(try decode("[1]") as Color)
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
                        Vertex(Vector(0, 0), .unitZ),
                        Vertex(Vector(1, 0), .unitZ),
                        Vertex(Vector(1, 1), .unitZ),
                    ],
                    plane: Plane(normal: .unitZ, w: 0)
                ),
            ])
        )
    }

    func testEncodingMeshWithoutMaterial() throws {
        let mesh = Mesh.extrude(.square())
        let encoded = try encode(mesh)
        let decoded = try decode(encoded) as Euclid.Mesh
        XCTAssertEqual(decoded, mesh)
    }

    func testEncodingMeshWithMaterial() throws {
        let mesh = Mesh.extrude(.square(), material: "foo")
        let encoded = try encode(mesh)
        let decoded = try decode(encoded) as Euclid.Mesh
        XCTAssertEqual(decoded, mesh)
    }

    func testEncodingMeshWithMixedMaterials() throws {
        let mesh = Mesh([
            Polygon(shape: .square(), material: "foo"),
            Polygon(shape: .square()),
            Polygon(shape: .square(), material: "bar"),
        ].compactMap { $0 })
        let encoded = try encode(mesh)
        let decoded = try decode(encoded) as Euclid.Mesh
        XCTAssertEqual(decoded, mesh)
    }

    // MARK: PathPoint

    func testDecodingPathPoint2D() {
        XCTAssertEqual(try decode("[1, 2]"), PathPoint.point(1, 2))
    }

    func testEncodingPathPoint2D() throws {
        let encoded = try encode(PathPoint.point(Vector(1, 2)))
        XCTAssertEqual(encoded, "[1,2]")
    }

    func testDecodingPathPoint3D() {
        XCTAssertEqual(try decode("[1, 2, 3]"), PathPoint.point(1, 2, 3))
    }

    func testEncodingPathPoint3D() throws {
        let encoded = try encode(PathPoint.point(Vector(1, 2, 3)))
        XCTAssertEqual(encoded, "[1,2,3]")
    }

    func testDecodingCurvedPathPoint2D() {
        XCTAssertEqual(try decode("[1, 2, true]"), PathPoint.curve(1, 2))
    }

    func testEncodingCurvedPathPoint2D() throws {
        let encoded = try encode(PathPoint.curve(Vector(1, 2)))
        XCTAssertEqual(encoded, "[1,2,true]")
    }

    func testDecodingCurvedPathPoint3D() {
        XCTAssertEqual(try decode("[1, 2, 3, true]"), PathPoint.curve(1, 2, 3))
    }

    func testEncodingCurvedPathPoint3D() throws {
        let encoded = try encode(PathPoint.curve(Vector(1, 2, 3)))
        XCTAssertEqual(encoded, "[1,2,3,true]")
    }

    func testDecodingPathPoint2DWithTexcoord() {
        XCTAssertEqual(
            try decode("[1, 2, 3, 4]"),
            PathPoint.point(Vector(1, 2), texcoord: Vector(3, 4))
        )
    }

    func testEncodingPathPoint2DWithTexcoord() throws {
        let encoded = try encode(PathPoint.point(Vector(1, 2), texcoord: Vector(3, 4)))
        XCTAssertEqual(encoded, "[1,2,3,4]")
    }

    func testEncodingPathPoint2DWithTexcoord3D() throws {
        let encoded = try encode(PathPoint.point(Vector(1, 2), texcoord: Vector(3, 4, 5)))
        XCTAssertEqual(encoded, "[1,2,0,3,4,5]")
    }

    func testEncodingPathPoint2DWithOpaqueColor() throws {
        let encoded = try encode(PathPoint.point(Vector(1, 2), color: .red))
        XCTAssertEqual(encoded, "[1,2,0,1,0,0,1]")
    }

    func testDecodingPathPoint3DWithTexcoord() {
        XCTAssertEqual(
            try decode("[1, 2, 3, 4, 5]"),
            PathPoint.point(Vector(1, 2, 3), texcoord: Vector(4, 5))
        )
    }

    func testDecodingPathPoint3DWithOpaqueColor() {
        XCTAssertEqual(
            try decode("[1, 2, 3, 1, 0, 0, 1]"),
            PathPoint.point(Vector(1, 2, 3), color: .red)
        )
    }

    func testDecodingPathPoint3DWithTranslucentColor() {
        XCTAssertEqual(
            try decode("[1, 2, 3, 1, 0, 0, 0.5]"),
            PathPoint.point(Vector(1, 2, 3), color: Color.red.withAlpha(0.5))
        )
    }

    func testDecodingPathPoint3DWithTexcoord3D() {
        XCTAssertEqual(
            try decode("[1, 2, 3, 4, 5, 6]"),
            PathPoint.point(Vector(1, 2, 3), texcoord: Vector(4, 5, 6))
        )
    }

    func testEncodingPathPoint3DWithTexcoord() throws {
        let encoded = try encode(PathPoint.point(Vector(1, 2, 3), texcoord: Vector(4, 5)))
        XCTAssertEqual(encoded, "[1,2,3,4,5]")
    }

    func testEncodingPathPoint3DWithTexcoord3D() throws {
        let encoded = try encode(PathPoint.point(Vector(1, 2, 3), texcoord: Vector(4, 5, 6)))
        XCTAssertEqual(encoded, "[1,2,3,4,5,6]")
    }

    func testDecodingCurvedPathPoint2DWithTexcoord() {
        XCTAssertEqual(
            try decode("[1, 2, 3, 4, true]"),
            PathPoint.curve(Vector(1, 2), texcoord: Vector(3, 4))
        )
    }

    func testDecodingCurvedPathPoint2DWithOpaqueColor() {
        XCTAssertEqual(
            try decode("[1, 2, 0, 1, 0, 0, 1, true]"),
            PathPoint.curve(Vector(1, 2, 0), color: .red)
        )
    }

    func testDecodingCurvedPathPoint2DWithTranslucentColor() {
        XCTAssertEqual(
            try decode("[1, 2, 0, 1, 0, 0, 0.5, true]"),
            PathPoint.curve(Vector(1, 2), color: Color.red.withAlpha(0.5))
        )
    }

    func testEncodingCurvedPathPoint2DWithTexcoord() throws {
        let encoded = try encode(PathPoint.curve(Vector(1, 2), texcoord: Vector(3, 4)))
        XCTAssertEqual(encoded, "[1,2,3,4,true]")
    }

    func testEncodingCurvedPathPoint2DWithTexcoord3D() throws {
        let encoded = try encode(PathPoint.curve(Vector(1, 2), texcoord: Vector(3, 4, 5)))
        XCTAssertEqual(encoded, "[1,2,0,3,4,5,true]")
    }

    func testEncodingCurvedPathPoint2DWithOpaqueColor() throws {
        let encoded = try encode(PathPoint.curve(Vector(1, 2), color: .red))
        XCTAssertEqual(encoded, "[1,2,0,1,0,0,1,true]")
    }

    func testDecodingCurvedPathPoint3DWithTexcoord() {
        XCTAssertEqual(
            try decode("[1, 2, 3, 4, 5, true]"),
            PathPoint.curve(Vector(1, 2, 3), texcoord: Vector(4, 5))
        )
    }

    func testDecodingCurvedPathPoint3DWithTexcoord3D() {
        XCTAssertEqual(
            try decode("[1, 2, 3, 4, 5, 6, true]"),
            PathPoint.curve(Vector(1, 2, 3), texcoord: Vector(4, 5, 6))
        )
    }

    func testDecodingCurvedPathPoint3DWithTexcoord3DAndOpaqueColor() {
        XCTAssertEqual(
            try decode("[1, 2, 3, 4, 5, 6, 1, 0, 0, true]"),
            PathPoint.curve(Vector(1, 2, 3), texcoord: Vector(4, 5, 6), color: .red)
        )
    }

    func testDecodingCurvedPathPoint3DWithTexcoord3DAndTranslucentColor() {
        XCTAssertEqual(
            try decode("[1, 2, 3, 4, 5, 6, 1, 0, 0, 0.5, true]"),
            PathPoint.curve(
                Vector(1, 2, 3),
                texcoord: Vector(4, 5, 6),
                color: Color.red.withAlpha(0.5)
            )
        )
    }

    func testEncodingCurvedPathPoint3DWithTexcoord() throws {
        let encoded = try encode(PathPoint.curve(Vector(1, 2, 3), texcoord: Vector(4, 5)))
        XCTAssertEqual(encoded, "[1,2,3,4,5,true]")
    }

    func testEncodingCurvedPathPoint3DWithTexcoordAndOpaqueColor() throws {
        let encoded = try encode(PathPoint.curve(
            Vector(1, 2, 3),
            texcoord: Vector(4, 5),
            color: .red
        ))
        XCTAssertEqual(encoded, "[1,2,3,4,5,1,0,0,true]")
    }

    func testEncodingCurvedPathPoint3DWithTexcoordAndTranslucentColor() throws {
        let encoded = try encode(PathPoint.curve(
            Vector(1, 2, 3),
            texcoord: Vector(4, 5),
            color: Color.red.withAlpha(0.5)
        ))
        XCTAssertEqual(encoded, "[1,2,3,4,5,1,0,0,0.5,true]")
    }

    func testEncodingCurvedPathPoint3DWithTexcoord3D() throws {
        let encoded = try encode(PathPoint.curve(Vector(1, 2, 3), texcoord: Vector(4, 5, 6)))
        XCTAssertEqual(encoded, "[1,2,3,4,5,6,true]")
    }

    func testEncodingCurvedPathPoint3DWithTexcoord3DAndOpaqueColor() throws {
        let encoded = try encode(PathPoint.curve(
            Vector(1, 2, 3),
            texcoord: Vector(4, 5, 6),
            color: .red
        ))
        XCTAssertEqual(encoded, "[1,2,3,4,5,6,1,0,0,true]")
    }

    func testEncodingCurvedPathPoint3DWithTexcoord3DAndTranslucentColor() throws {
        let encoded = try encode(PathPoint.curve(
            Vector(1, 2, 3),
            texcoord: Vector(4, 5, 6),
            color: Color.red.withAlpha(0.5)
        ))
        XCTAssertEqual(encoded, "[1,2,3,4,5,6,1,0,0,0.5,true]")
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

    func testEncodingIdentityRotation() {
        XCTAssertEqual(try encode(Rotation.identity), "[]")
    }

    func testDecodingRollRotation() {
        XCTAssertEqual(try decode("[1]"), Rotation(roll: .radians(1)))
        XCTAssertEqual(try decode("""
        { "radians": 1 }
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
        { "axis": [0, 0, -1], "radians": 1 }
        """), Rotation(roll: .radians(-1)))
    }

    func testEncodingAndDecodingRotation() throws {
        let rotation = Rotation(axis: .unitX, angle: .radians(2))!
        let encoded = try encode(rotation)
        XCTAssert(try rotation.isEqual(to: decode(encoded)))
    }

    func testEncodingAndDecodingPitchYawRollRotation() throws {
        let rotation = Rotation(pitch: .degrees(10), yaw: .degrees(20), roll: .degrees(30))
        let encoded = try encode(rotation)
        XCTAssert(try rotation.isEqual(to: decode(encoded)))
    }

    // MARK: Quaternion

    func testDecodingIdentityQuaternion() {
        XCTAssertEqual(try decode("[]"), Quaternion.identity)
        XCTAssertEqual(try decode("{}"), Quaternion.identity)
    }

    func testEncodingIdentityQuaternion() {
        XCTAssertEqual(try encode(Rotation.identity), "[]")
    }

    func testEncodingAndDecodingQuaternion() throws {
        let q = Quaternion(axis: .unitX, angle: .radians(2))!
        let encoded = try encode(q)
        XCTAssert(try q.isEqual(to: decode(encoded)))
    }

    func testEncodingAndDecodingPitchYawRollQuaternion() throws {
        let q = Quaternion(roll: .degrees(30), yaw: .degrees(20), pitch: .degrees(10))
        let encoded = try encode(q)
        XCTAssert(try q.isEqual(to: decode(encoded)))
    }
}
