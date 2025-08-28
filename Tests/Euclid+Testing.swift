//
//  Euclid+Testing.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 13/06/2022.
//  Copyright © 2022 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

func XCTAssertEqual(
    _ v1: @autoclosure () throws -> Vector,
    _ v2: @autoclosure () throws -> Vector,
    accuracy: Double = epsilon,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
) {
    do {
        let v1 = try v1(), v2 = try v2()
        if v1 != v2, !v1.isEqual(to: v2, withPrecision: accuracy) {
            var m = message()
            if m.isEmpty {
                m = "\(v1) is not equal to \(v2) +/1 \(accuracy)"
            }
            XCTFail(m, file: file, line: line)
        }
    } catch {
        XCTFail(error.localizedDescription)
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
}

extension Mesh {
    var isActuallyConvex: Bool {
        guard BSP(Mesh(polygons), { false }).isConvex else {
            return false
        }
        guard let plane = polygons.first?.plane else {
            return true
        }
        for polygon in polygons {
            if !polygon.plane.isEqual(to: plane),
               !polygon.plane.isEqual(to: plane.inverted())
            {
                return true
            }
        }
        // All polygons are planar
        let groups = polygons.groupedByPlane()
        return groups.count == 2
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
