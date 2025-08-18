//
//  DebugDescriptionTests.swift
//  Euclid
//
//  Created by Nick Lockwood on 18/08/2025.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

class DebugDescriptionTests: XCTestCase {
    // MARK: Vector

    func testVector() {
        let vector = Vector.unitY
        XCTAssertEqual(vector.debugDescription, "Vector(0.0, 1.0, 0.0)")
    }

    func testZeroVector() {
        let vector = Vector.zero
        XCTAssertEqual(vector.debugDescription, "Vector(0.0, 0.0, 0.0)")
    }

    // MARK: Color

    func testColor() {
        let color = Color.red
        XCTAssertEqual(color.debugDescription, "Color(1.0, 0.0, 0.0)")
    }

    func testColorWithAlpha() {
        let color = Color.red.withAlpha(0.5)
        XCTAssertEqual(color.debugDescription, "Color(1.0, 0.0, 0.0, 0.5)")
    }

    // MARK: PathPoint

    func testPathPoint() {
        let point = PathPoint.point(0.0, 0.0, 1.0)
        XCTAssertEqual(point.debugDescription, "PathPoint.point(0.0, 0.0, 1.0)")
    }

    func testPathCurve() {
        let point = PathPoint.curve(0.0, 0.0, 1.0)
        XCTAssertEqual(point.debugDescription, "PathPoint.curve(0.0, 0.0, 1.0)")
    }

    func testPathPoint2D() {
        let point = PathPoint.point(0.0, 0.0)
        XCTAssertEqual(point.debugDescription, "PathPoint.point(0.0, 0.0)")
    }

    func testPathPointWithTexcoord() {
        let vertex = PathPoint.point(0.0, 0.0, texcoord: .unitX)
        XCTAssertEqual(vertex.debugDescription, "PathPoint.point(0.0, 0.0, texcoord: [1.0, 0.0, 0.0])")
    }

    func testPathPointWithColor() {
        let vertex = PathPoint.point(0.0, 0.0, color: .red)
        XCTAssertEqual(vertex.debugDescription, "PathPoint.point(0.0, 0.0, color: [1.0, 0.0, 0.0, 1.0])")
    }

    // MARK: Path

    func testPath() {
        let point = Path.square()
        XCTAssertEqual(point.debugDescription.replacingOccurrences(of: "\t", with: "    "), """
        Path([
            .point(-0.5, 0.5),
            .point(-0.5, -0.5),
            .point(0.5, -0.5),
            .point(0.5, 0.5),
            .point(-0.5, 0.5),
        ])
        """)
    }

    func testPathWithColor() {
        let point = Path.square(color: .red)
        XCTAssertEqual(point.debugDescription.replacingOccurrences(of: "\t", with: "    "), """
        Path([
            .point(-0.5, 0.5, color: [1.0, 0.0, 0.0, 1.0]),
            .point(-0.5, -0.5, color: [1.0, 0.0, 0.0, 1.0]),
            .point(0.5, -0.5, color: [1.0, 0.0, 0.0, 1.0]),
            .point(0.5, 0.5, color: [1.0, 0.0, 0.0, 1.0]),
            .point(-0.5, 0.5, color: [1.0, 0.0, 0.0, 1.0]),
        ])
        """)
    }

    // MARK: Vertex

    func testVertex() {
        let vertex = Vertex(0.0, 0.0, 1.0)
        XCTAssertEqual(vertex.debugDescription, "Vertex(0.0, 0.0, 1.0)")
    }

    func testVertex2D() {
        let vertex = Vertex(0.0, 0.0)
        XCTAssertEqual(vertex.debugDescription, "Vertex(0.0, 0.0)")
    }

    func testVertexWithNormal() {
        let vertex = Vertex(0.0, 0.0, normal: .unitZ)
        XCTAssertEqual(vertex.debugDescription, "Vertex(0.0, 0.0, normal: [0.0, 0.0, 1.0])")
    }

    func testVertexWithTexcoord() {
        let vertex = Vertex(0.0, 0.0, texcoord: .unitX)
        XCTAssertEqual(vertex.debugDescription, "Vertex(0.0, 0.0, texcoord: [1.0, 0.0, 0.0])")
    }

    func testVertexWithColor() {
        let vertex = Vertex(0.0, 0.0, color: .red)
        XCTAssertEqual(vertex.debugDescription, "Vertex(0.0, 0.0, color: [1.0, 0.0, 0.0, 1.0])")
    }

    // MARK: Mesh

    func testCube() {
        let mesh = Mesh.cube()
        XCTAssertEqual(mesh.debugDescription.replacingOccurrences(of: "\t", with: "    "), """
        Mesh([
            Polygon([
                Vertex(0.5, -0.5, 0.5, normal: [1.0, 0.0, 0.0], texcoord: [0.0, 1.0, 0.0]),
                Vertex(0.5, -0.5, -0.5, normal: [1.0, 0.0, 0.0], texcoord: [1.0, 1.0, 0.0]),
                Vertex(0.5, 0.5, -0.5, normal: [1.0, 0.0, 0.0], texcoord: [1.0, 0.0, 0.0]),
                Vertex(0.5, 0.5, 0.5, normal: [1.0, 0.0, 0.0]),
            ]),
            Polygon([
                Vertex(-0.5, -0.5, -0.5, normal: [-1.0, -0.0, -0.0], texcoord: [0.0, 1.0, 0.0]),
                Vertex(-0.5, -0.5, 0.5, normal: [-1.0, -0.0, -0.0], texcoord: [1.0, 1.0, 0.0]),
                Vertex(-0.5, 0.5, 0.5, normal: [-1.0, -0.0, -0.0], texcoord: [1.0, 0.0, 0.0]),
                Vertex(-0.5, 0.5, -0.5, normal: [-1.0, -0.0, -0.0]),
            ]),
            Polygon([
                Vertex(-0.5, 0.5, 0.5, normal: [0.0, 1.0, 0.0], texcoord: [0.0, 1.0, 0.0]),
                Vertex(0.5, 0.5, 0.5, normal: [0.0, 1.0, 0.0], texcoord: [1.0, 1.0, 0.0]),
                Vertex(0.5, 0.5, -0.5, normal: [0.0, 1.0, 0.0], texcoord: [1.0, 0.0, 0.0]),
                Vertex(-0.5, 0.5, -0.5, normal: [0.0, 1.0, 0.0]),
            ]),
            Polygon([
                Vertex(-0.5, -0.5, -0.5, normal: [-0.0, -1.0, -0.0], texcoord: [0.0, 1.0, 0.0]),
                Vertex(0.5, -0.5, -0.5, normal: [-0.0, -1.0, -0.0], texcoord: [1.0, 1.0, 0.0]),
                Vertex(0.5, -0.5, 0.5, normal: [-0.0, -1.0, -0.0], texcoord: [1.0, 0.0, 0.0]),
                Vertex(-0.5, -0.5, 0.5, normal: [-0.0, -1.0, -0.0]),
            ]),
            Polygon([
                Vertex(-0.5, -0.5, 0.5, normal: [0.0, 0.0, 1.0], texcoord: [0.0, 1.0, 0.0]),
                Vertex(0.5, -0.5, 0.5, normal: [0.0, 0.0, 1.0], texcoord: [1.0, 1.0, 0.0]),
                Vertex(0.5, 0.5, 0.5, normal: [0.0, 0.0, 1.0], texcoord: [1.0, 0.0, 0.0]),
                Vertex(-0.5, 0.5, 0.5, normal: [0.0, 0.0, 1.0]),
            ]),
            Polygon([
                Vertex(0.5, -0.5, -0.5, normal: [-0.0, -0.0, -1.0], texcoord: [0.0, 1.0, 0.0]),
                Vertex(-0.5, -0.5, -0.5, normal: [-0.0, -0.0, -1.0], texcoord: [1.0, 1.0, 0.0]),
                Vertex(-0.5, 0.5, -0.5, normal: [-0.0, -0.0, -1.0], texcoord: [1.0, 0.0, 0.0]),
                Vertex(0.5, 0.5, -0.5, normal: [-0.0, -0.0, -1.0]),
            ]),
        ])
        """)
    }

    func testCubeWithMaterial() {
        let mesh = Mesh.cube(material: Color.blue)
        XCTAssertEqual(mesh.debugDescription.replacingOccurrences(of: "\t", with: "    "), """
        Mesh([
            Polygon([
                Vertex(0.5, -0.5, 0.5, normal: [1.0, 0.0, 0.0], texcoord: [0.0, 1.0, 0.0]),
                Vertex(0.5, -0.5, -0.5, normal: [1.0, 0.0, 0.0], texcoord: [1.0, 1.0, 0.0]),
                Vertex(0.5, 0.5, -0.5, normal: [1.0, 0.0, 0.0], texcoord: [1.0, 0.0, 0.0]),
                Vertex(0.5, 0.5, 0.5, normal: [1.0, 0.0, 0.0]),
            ], material: Color(0.0, 0.0, 1.0)),
            Polygon([
                Vertex(-0.5, -0.5, -0.5, normal: [-1.0, -0.0, -0.0], texcoord: [0.0, 1.0, 0.0]),
                Vertex(-0.5, -0.5, 0.5, normal: [-1.0, -0.0, -0.0], texcoord: [1.0, 1.0, 0.0]),
                Vertex(-0.5, 0.5, 0.5, normal: [-1.0, -0.0, -0.0], texcoord: [1.0, 0.0, 0.0]),
                Vertex(-0.5, 0.5, -0.5, normal: [-1.0, -0.0, -0.0]),
            ], material: Color(0.0, 0.0, 1.0)),
            Polygon([
                Vertex(-0.5, 0.5, 0.5, normal: [0.0, 1.0, 0.0], texcoord: [0.0, 1.0, 0.0]),
                Vertex(0.5, 0.5, 0.5, normal: [0.0, 1.0, 0.0], texcoord: [1.0, 1.0, 0.0]),
                Vertex(0.5, 0.5, -0.5, normal: [0.0, 1.0, 0.0], texcoord: [1.0, 0.0, 0.0]),
                Vertex(-0.5, 0.5, -0.5, normal: [0.0, 1.0, 0.0]),
            ], material: Color(0.0, 0.0, 1.0)),
            Polygon([
                Vertex(-0.5, -0.5, -0.5, normal: [-0.0, -1.0, -0.0], texcoord: [0.0, 1.0, 0.0]),
                Vertex(0.5, -0.5, -0.5, normal: [-0.0, -1.0, -0.0], texcoord: [1.0, 1.0, 0.0]),
                Vertex(0.5, -0.5, 0.5, normal: [-0.0, -1.0, -0.0], texcoord: [1.0, 0.0, 0.0]),
                Vertex(-0.5, -0.5, 0.5, normal: [-0.0, -1.0, -0.0]),
            ], material: Color(0.0, 0.0, 1.0)),
            Polygon([
                Vertex(-0.5, -0.5, 0.5, normal: [0.0, 0.0, 1.0], texcoord: [0.0, 1.0, 0.0]),
                Vertex(0.5, -0.5, 0.5, normal: [0.0, 0.0, 1.0], texcoord: [1.0, 1.0, 0.0]),
                Vertex(0.5, 0.5, 0.5, normal: [0.0, 0.0, 1.0], texcoord: [1.0, 0.0, 0.0]),
                Vertex(-0.5, 0.5, 0.5, normal: [0.0, 0.0, 1.0]),
            ], material: Color(0.0, 0.0, 1.0)),
            Polygon([
                Vertex(0.5, -0.5, -0.5, normal: [-0.0, -0.0, -1.0], texcoord: [0.0, 1.0, 0.0]),
                Vertex(-0.5, -0.5, -0.5, normal: [-0.0, -0.0, -1.0], texcoord: [1.0, 1.0, 0.0]),
                Vertex(-0.5, 0.5, -0.5, normal: [-0.0, -0.0, -1.0], texcoord: [1.0, 0.0, 0.0]),
                Vertex(0.5, 0.5, -0.5, normal: [-0.0, -0.0, -1.0]),
            ], material: Color(0.0, 0.0, 1.0)),
        ])
        """)
    }

    func testEmptyMesh() {
        let mesh = Mesh.empty
        XCTAssertEqual(mesh.debugDescription, "Mesh.empty")
    }

    // MARK: Bounds

    func testBounds() {
        let bounds = Bounds(min: .zero, max: .one)
        XCTAssertEqual(bounds.debugDescription, "Bounds(min: [0.0, 0.0, 0.0], max: [1.0, 1.0, 1.0])")
    }

    func testEmptyBounds() {
        let bounds = Bounds.empty
        XCTAssertEqual(bounds.debugDescription, "Bounds.empty")
    }

    // MARK: Plane

    func testPlane() {
        let plane = Plane(unchecked: .unitZ, w: 1.5)
        XCTAssertEqual(plane.debugDescription, "Plane(normal: [0.0, 0.0, 1.0], w: 1.5)")
    }

    func testXYPlane() {
        let plane = Plane.xy
        XCTAssertEqual(plane.debugDescription, "Plane(normal: [0.0, 0.0, 1.0], w: 0.0)")
    }

    // MARK: Line

    func testLine() {
        let line = Line(unchecked: .zero, direction: .unitY)
        XCTAssertEqual(line.debugDescription, "Line(origin: [0.0, 0.0, 0.0], direction: [0.0, 1.0, 0.0])")
    }

    // MARK: LineSegment

    func testLineSegment() {
        let line = LineSegment(unchecked: -.unitX, .unitY)
        XCTAssertEqual(line.debugDescription, "LineSegment(start: [-1.0, -0.0, -0.0], end: [0.0, 1.0, 0.0])")
    }

    // MARK: Rotation

    func testRotation() {
        let rotation = Rotation(unchecked: .unitX, angle: .pi)
        XCTAssertEqual(rotation.debugDescription, """
        Rotation(axis: [1.0, 0.0, 0.0], angle: Angle(radians: 3.141592653589793))
        """)
    }

    func testIdentityRotation() {
        let rotation = Rotation.identity
        XCTAssertEqual(rotation.debugDescription, "Rotation.identity")
    }

    // MARK: Transform

    func testTransform() {
        let transform = Transform(
            scale: .one * 2,
            rotation: .init(axis: .unitZ, angle: .pi),
            translation: .unitX
        )
        XCTAssertEqual(transform.debugDescription.replacingOccurrences(of: "\t", with: "    "), """
        Transform(
            scale: [2.0, 2.0, 2.0],
            rotation: Rotation(axis: [0.0, 0.0, 1.0], angle: Angle(radians: 3.141592653589793)),
            translation: [1.0, 0.0, 0.0]
        )
        """)
    }

    func testScaleAndTranslation() {
        let transform = Transform(scale: .one * 2, translation: .unitX)
        XCTAssertEqual(transform.debugDescription.replacingOccurrences(of: "\t", with: "    "), """
        Transform(scale: [2.0, 2.0, 2.0], translation: [1.0, 0.0, 0.0])
        """)
    }

    func testRotationTransform() {
        let transform = Transform.rotation(Rotation(unchecked: .unitZ, angle: .pi))
        XCTAssertEqual(transform.debugDescription.replacingOccurrences(of: "\t", with: "    "), """
        Transform(rotation: Rotation(axis: [0.0, 0.0, 1.0], angle: Angle(radians: 3.141592653589793)))
        """)
    }
}
