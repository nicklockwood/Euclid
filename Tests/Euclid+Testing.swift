//
//  Euclid+Testing.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 13/06/2022.
//  Copyright © 2022 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

extension XCTestCase {
    @_disfavoredOverload
    func XCTAssertEqual<T: Equatable>(
        _ a: @autoclosure () throws -> T,
        _ b: @autoclosure () throws -> T,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        do {
            let a = try a(), b = try b()
            if a != b {
                var m = message()
                if m.isEmpty {
                    m = "\(a) is not equal to \(b)"
                }
                XCTFail(m, file: file, line: line)
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func XCTAssertEqual<T: ApproximateEquality>(
        _ a: @autoclosure () throws -> T,
        _ b: @autoclosure () throws -> T,
        accuracy: Double = T.absoluteTolerance,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        do {
            let a = try a(), b = try b()
            if !a.isApproximatelyEqual(to: b, absoluteTolerance: accuracy) {
                var m = message()
                if m.isEmpty {
                    m = "\(a) is not equal to \(b) +/- \(accuracy)"
                }
                XCTFail(m, file: file, line: line)
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}

extension Euclid.Polygon {
    /// Convenience constructor for testing
    init(unchecked vertices: [Vertex], plane: Plane? = nil) {
        self.init(
            unchecked: vertices,
            plane: plane,
            isConvex: nil,
            sanitizeNormals: true,
            material: nil
        )
    }

    /// Convenience constructor for testing
    init(unchecked points: [Vector]) {
        self.init(unchecked: points.map(Vertex.init))
    }

    var orderedEdgesContainCrossings: Bool {
        orderedEdges.containCrossings(isClosed: true)
    }

    func containsProjectedPoint(_ point: Vector) -> Bool {
        let positions = vertices.map(\.position)
        return positions.containProjectedPoint(point)
    }

    func containsProjectedPoint(_ point: Vector, normal: Vector) -> Bool {
        let positions = vertices.map { $0.position.projectedForTesting(along: normal) }
        return positions.containProjectedPoint(point)
    }
}

private extension Collection<Vector> {
    func containProjectedPoint(_ point: Vector) -> Bool {
        let positions = Array(self)
        var contains = false
        var previousIndex = positions.count - 1
        for index in positions.indices {
            let current = positions[index]
            let previous = positions[previousIndex]
            if (current.y > point.y) != (previous.y > point.y) {
                let x = (previous.x - current.x) * (point.y - current.y) / (previous.y - current.y) + current.x
                if point.x < x {
                    contains.toggle()
                }
            }
            previousIndex = index
        }
        return contains
    }
}

extension Collection<Euclid.Polygon> {
    func containProjectedPoint(_ point: Vector) -> Bool {
        contains { $0.containsProjectedPoint(point) }
    }

    func containProjectedPoint(_ point: Vector, normal: Vector) -> Bool {
        contains { $0.containsProjectedPoint(point, normal: normal) }
    }
}

extension Vector {
    func projectedForTesting(along normal: Vector) -> Vector {
        let normal = normal.normalized()
        let x = abs(normal.x)
        let y = abs(normal.y)
        let z = abs(normal.z)
        if x > y, x > z {
            return [self.y, self.z]
        }
        if y > z {
            return [self.x, self.z]
        }
        return [self.x, self.y]
    }
}

extension Mesh {
    var isActuallyConvex: Bool {
        Mesh(polygons).isConvex()
    }

    var hasSmoothSideVertexNormals: Bool {
        polygons.contains { polygon in
            abs(polygon.plane.normal.z) < 0.5 && polygon.vertices.contains {
                !$0.normal.isApproximatelyEqual(to: polygon.plane.normal)
            }
        }
    }
}

extension Vector {
    static func random(in range: ClosedRange<Vector>) -> Vector {
        let value = self.init(
            .random(in: range.lowerBound.x ... range.upperBound.x),
            .random(in: range.lowerBound.y ... range.upperBound.y),
            .random(in: range.lowerBound.z ... range.upperBound.z)
        )
        if value.isZero, !range.lowerBound.isZero, !range.upperBound.isZero {
            // Assume we don't want zero values unless explicitly requested
            return random(in: range)
        }
        return value
    }

    static func random(in range: ClosedRange<Double> = -100 ... 100) -> Vector {
        .random(in: .init(size: range.lowerBound) ... .init(size: range.upperBound))
    }

    static func random(in plane: Plane) -> Vector {
        let vector = Vector.random()
        return vector.projected(onto: plane)
    }
}

extension Angle {
    static func random(in range: ClosedRange<Angle> = -.pi ... .pi) -> Angle {
        // Assume we don't want zero values unless explicitly requested
        let value = Self.radians(.random(in: range.lowerBound.radians ... range.upperBound.radians))
        return value.isZero ? .random(in: range) : value
    }
}

extension Plane {
    static func random() -> Plane {
        .init(unchecked: .random().normalized(), w: .random(in: -100 ... 100))
    }
}

extension Rotation {
    static func random() -> Rotation {
        .init(unchecked: .random().normalized(), angle: .random())
    }

    static func random(in plane: Plane) -> Rotation {
        .init(unchecked: plane.normal, angle: .random())
    }
}

extension Transform {
    static func random(maxTranslation: Double = 100) -> Transform {
        .init(
            scale: 1,
            rotation: .random(),
            translation: .random(in: -maxTranslation ... maxTranslation)
        )
    }
}

extension Path {
    static func star(sides: Int) -> Path {
        var points = [PathPoint]()
        for i in 0 ..< sides {
            let innerAngle = -.pi / 2 + Double(i) * 2 * .pi / Double(sides)
            let outerAngle = innerAngle + .pi / Double(sides)
            points.append(.point(0.5 * cos(innerAngle), 0.5 * sin(innerAngle)))
            points.append(.point(cos(outerAngle), sin(outerAngle)))
        }
        points.append(points[0])
        return Path(points)
    }

    static let compoundPath: Path = .init(subpaths: [
        Path([
            .point(0, 0),
            .point(2, 0),
            .point(2, 1),
            .point(0, 1),
            .point(0, 0),
        ]),
        Path([
            .point(4, 3),
            .point(5, 3),
            .point(5, 5),
            .point(4, 5),
            .point(4, 3),
        ]),
    ])

    static let qrCodeLikeCompoundPath: Path = {
        func rectangle(
            _ x: Double,
            _ y: Double,
            _ width: Double,
            _ height: Double,
            clockwise: Bool = false
        ) -> Path {
            let points: [PathPoint] = [
                .point(x, y),
                .point(x + width, y),
                .point(x + width, y + height),
                .point(x, y + height),
                .point(x, y),
            ]
            return Path(clockwise ? points.reversed() : points)
        }
        return Path(subpaths: [
            rectangle(0, 0, 56, 56),
            rectangle(8, 8, 40, 40, clockwise: true),
            rectangle(16, 16, 24, 24),
            rectangle(144, 0, 56, 56),
            rectangle(152, 8, 40, 40, clockwise: true),
            rectangle(160, 16, 24, 24),
            rectangle(0, 144, 56, 56),
            rectangle(8, 152, 40, 40, clockwise: true),
            rectangle(16, 160, 24, 24),
            rectangle(64, 0, 8, 8),
            rectangle(80, 0, 8, 16),
            rectangle(96, 0, 24, 8),
            rectangle(72, 8, 16, 8),
            rectangle(104, 8, 8, 16),
            rectangle(64, 24, 16, 8),
            rectangle(88, 24, 32, 8),
            rectangle(120, 32, 16, 8),
            rectangle(80, 40, 24, 16),
            rectangle(64, 48, 8, 16),
            rectangle(96, 56, 16, 16),
            rectangle(120, 64, 24, 8),
            rectangle(152, 64, 16, 16),
            rectangle(176, 64, 24, 8),
            rectangle(8, 80, 32, 16),
            rectangle(48, 72, 24, 24),
            rectangle(80, 80, 16, 8),
            rectangle(104, 80, 32, 24),
            rectangle(144, 88, 24, 8),
            rectangle(176, 80, 16, 16),
            rectangle(16, 112, 24, 24),
            rectangle(48, 120, 16, 8),
            rectangle(72, 112, 32, 16),
            rectangle(112, 120, 16, 24),
            rectangle(136, 112, 24, 8),
            rectangle(168, 112, 32, 16),
            rectangle(64, 144, 16, 32),
            rectangle(88, 136, 16, 16),
            rectangle(104, 152, 24, 24),
            rectangle(136, 136, 24, 24),
            rectangle(168, 144, 8, 24),
            rectangle(184, 136, 16, 16),
            rectangle(64, 192, 8, 8),
            rectangle(80, 184, 24, 16),
            rectangle(112, 184, 16, 16),
            rectangle(144, 176, 24, 24),
            rectangle(176, 176, 8, 8),
            rectangle(192, 192, 8, 8),
        ])
    }()

    var orderedEdgesContainCrossings: Bool {
        orderedEdges.containCrossings(isClosed: isClosed)
    }
}

private extension [LineSegment] {
    func containCrossings(isClosed: Bool) -> Bool {
        for i in indices {
            for j in indices.dropFirst(i + 1) where !edgesAreAdjacent(i, j, isClosed: isClosed) {
                if let p = self[i].intersection(with: self[j]),
                   !p.isApproximatelyEqual(to: self[i].start),
                   !p.isApproximatelyEqual(to: self[i].end),
                   !p.isApproximatelyEqual(to: self[j].start),
                   !p.isApproximatelyEqual(to: self[j].end)
                {
                    return true
                }
            }
        }
        return false
    }

    func edgesAreAdjacent(_ a: Int, _ b: Int, isClosed: Bool) -> Bool {
        abs(a - b) == 1 || (isClosed && a == 0 && b == count - 1)
    }
}
