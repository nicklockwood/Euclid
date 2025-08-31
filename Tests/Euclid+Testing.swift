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
}

extension Mesh {
    var isActuallyConvex: Bool {
        Mesh(polygons).isConvex()
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
