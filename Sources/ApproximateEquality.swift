//
//  ApproximateEquality.swift
//  Euclid
//
//  Created by Nick Lockwood on 29/08/2025.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

protocol ApproximateEquality: Equatable {
    static var absoluteTolerance: Double { get }

    func isApproximatelyEqual(to other: Self, absoluteTolerance: Double) -> Bool
}

extension ApproximateEquality {
    static var absoluteTolerance: Double { epsilon }

    func isApproximatelyEqual(to other: Self) -> Bool {
        isApproximatelyEqual(to: other, absoluteTolerance: Self.absoluteTolerance)
    }
}

extension Angle: ApproximateEquality {
    func isApproximatelyEqual(to other: Angle, absoluteTolerance: Double) -> Bool {
        radians.isApproximatelyEqual(to: other.radians, absoluteTolerance: absoluteTolerance)
    }
}

extension Bounds: ApproximateEquality {
    func isApproximatelyEqual(to other: Bounds, absoluteTolerance: Double) -> Bool {
        min.isApproximatelyEqual(to: other.min, absoluteTolerance: absoluteTolerance) &&
            max.isApproximatelyEqual(to: other.max, absoluteTolerance: absoluteTolerance)
    }
}

extension Color: ApproximateEquality {
    func isApproximatelyEqual(to other: Color, absoluteTolerance: Double) -> Bool {
        r.isApproximatelyEqual(to: other.r, absoluteTolerance: absoluteTolerance) &&
            g.isApproximatelyEqual(to: other.g, absoluteTolerance: absoluteTolerance) &&
            b.isApproximatelyEqual(to: other.b, absoluteTolerance: absoluteTolerance) &&
            a.isApproximatelyEqual(to: other.a, absoluteTolerance: absoluteTolerance)
    }
}

extension Double: ApproximateEquality {
    func isApproximatelyEqual(to other: Double, absoluteTolerance: Double) -> Bool {
        self == other || abs(self - other) < absoluteTolerance
    }
}

extension Path: ApproximateEquality {
    func isApproximatelyEqual(to other: Path, absoluteTolerance: Double) -> Bool {
        points.count == other.points.count && zip(points, other.points).allSatisfy {
            $0.isApproximatelyEqual(to: $1, absoluteTolerance: absoluteTolerance)
        }
    }
}

extension PathPoint: ApproximateEquality {
    func isApproximatelyEqual(to other: PathPoint, absoluteTolerance: Double) -> Bool {
        isCurved == other.isCurved &&
            position.isApproximatelyEqual(to: other.position, absoluteTolerance: absoluteTolerance) &&
            texcoord.isApproximatelyEqual(to: other.texcoord) && color.isApproximatelyEqual(to: other.color)
    }
}

extension Plane: ApproximateEquality {
    static var absoluteTolerance: Double { planeEpsilon }

    func isApproximatelyEqual(to other: Plane, absoluteTolerance: Double) -> Bool {
        w.isApproximatelyEqual(to: other.w, absoluteTolerance: absoluteTolerance) &&
            isParallel(to: other, absoluteTolerance: absoluteTolerance)
    }
}

extension Rotation: ApproximateEquality {
    func isApproximatelyEqual(to other: Rotation, absoluteTolerance: Double) -> Bool {
        w.isApproximatelyEqual(to: other.w, absoluteTolerance: absoluteTolerance) &&
            x.isApproximatelyEqual(to: other.x, absoluteTolerance: absoluteTolerance) &&
            y.isApproximatelyEqual(to: other.y, absoluteTolerance: absoluteTolerance) &&
            z.isApproximatelyEqual(to: other.z, absoluteTolerance: absoluteTolerance)
    }
}

extension Vector: ApproximateEquality {
    func isApproximatelyEqual(to other: Vector, absoluteTolerance: Double) -> Bool {
        x.isApproximatelyEqual(to: other.x, absoluteTolerance: absoluteTolerance) &&
            y.isApproximatelyEqual(to: other.y, absoluteTolerance: absoluteTolerance) &&
            z.isApproximatelyEqual(to: other.z, absoluteTolerance: absoluteTolerance)
    }
}

extension Vertex: ApproximateEquality {
    func isApproximatelyEqual(to other: Vertex, absoluteTolerance: Double) -> Bool {
        position.isApproximatelyEqual(to: other.position, absoluteTolerance: absoluteTolerance) &&
            normal.isApproximatelyEqual(to: other.normal, absoluteTolerance: absoluteTolerance) &&
            texcoord.isApproximatelyEqual(to: other.texcoord, absoluteTolerance: absoluteTolerance) &&
            color.isApproximatelyEqual(to: other.color, absoluteTolerance: absoluteTolerance)
    }
}

extension Optional: ApproximateEquality where Wrapped: ApproximateEquality {
    static var absoluteTolerance: Double { Wrapped.absoluteTolerance }

    func isApproximatelyEqual(to other: Self, absoluteTolerance: Double) -> Bool {
        switch (self, other) {
        case let (lhs?, rhs?):
            return lhs.isApproximatelyEqual(to: rhs, absoluteTolerance: absoluteTolerance)
        case (nil, _), (_, nil):
            return other == nil
        }
    }
}
