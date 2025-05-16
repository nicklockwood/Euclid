//
//  Interpolatable.swift
//  Euclid
//
//  Created by Nick Lockwood on 16/05/2025.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

import Foundation

#if canImport(simd)
import simd
#endif

public protocol Interpolatable {
    /// Interpolate between two values.
    /// - Parameters:
    ///   - other: The value to interpolate towards.
    ///   - t: The extent of the interpolation, from `0` - `1` (unclamped)
    /// - Returns: The interpolated value.
    func interpolated(with other: Self, by t: Double) -> Self
}

extension Double: Interpolatable {
    public func interpolated(with other: Double, by t: Double) -> Double {
        self + (other - self) * t
    }
}

#if canImport(simd)

extension SIMD2: Interpolatable where Scalar: BinaryFloatingPoint {
    public func interpolated(with other: Self, by t: Double) -> Self {
        self + (other - self) * Scalar(t)
    }
}

extension SIMD3: Interpolatable where Scalar: BinaryFloatingPoint {
    public func interpolated(with other: Self, by t: Double) -> Self {
        self + (other - self) * Scalar(t)
    }
}

extension SIMD4: Interpolatable where Scalar: BinaryFloatingPoint {
    public func interpolated(with other: Self, by t: Double) -> Self {
        self + (other - self) * Scalar(t)
    }
}

#endif

extension Vector: Interpolatable {
    public func interpolated(with other: Vector, by t: Double) -> Vector {
        self + (other - self).scaled(by: t)
    }
}

extension Vertex: Interpolatable {
    /// > Note:  Interpolation is applied to the texture coordinate, normal and color, as well as the position.
    public func interpolated(with other: Vertex, by t: Double) -> Vertex {
        .init(
            unchecked: position.interpolated(with: other.position, by: t),
            normal.interpolated(with: other.normal, by: t),
            texcoord.interpolated(with: other.texcoord, by: t),
            color.interpolated(with: other.color, by: t)
        )
    }
}

extension PathPoint: Interpolatable {
    public func interpolated(with other: PathPoint, by t: Double) -> PathPoint {
        let texcoord: Vector?
        switch (self.texcoord, other.texcoord) {
        case let (lhs?, rhs?):
            texcoord = lhs.interpolated(with: rhs, by: t)
        case let (lhs, rhs):
            texcoord = lhs ?? rhs
        }
        let color: Color?
        switch (self.color, other.color) {
        case let (lhs?, rhs?):
            color = lhs.interpolated(with: rhs, by: t)
        case let (lhs, rhs):
            color = lhs ?? rhs
        }
        let isCurved = self.isCurved || other.isCurved
        return PathPoint(
            position.interpolated(with: other.position, by: t),
            texcoord: texcoord,
            color: color,
            isCurved: isCurved
        )
    }

    public static func * (lhs: Self, rhs: Double) -> Self {
        PathPoint(position: .zero, isCurved: lhs.isCurved).interpolated(with: lhs, by: rhs)
    }
}

extension Color: Interpolatable {
    public func interpolated(with other: Color, by t: Double) -> Color {
        .init(
            r.interpolated(with: other.r, by: t),
            g.interpolated(with: other.g, by: t),
            b.interpolated(with: other.b, by: t),
            a.interpolated(with: other.a, by: t)
        )
    }
}

extension Line: Interpolatable {
    public func interpolated(with other: Line, by t: Double) -> Line {
        .init(
            unchecked: origin.interpolated(with: other.origin, by: t),
            // TODO: should this be rotational rather than linear?
            direction: direction.interpolated(with: other.direction, by: t).normalized()
        )
    }
}

extension LineSegment: Interpolatable {
    public func interpolated(with other: LineSegment, by t: Double) -> LineSegment {
        let start = start.interpolated(with: other.start, by: t)
        var end = end.interpolated(with: other.end, by: t)
        if start == end {
            // Move points apart by epsilon
            end += direction.interpolated(with: other.direction, by: t) * epsilon
        }
        return .init(unchecked: start, end)
    }
}

// TODO: polygons, paths and meshes

extension Rotation: Interpolatable {
    #if canImport(simd)

    public func interpolated(with other: Rotation, by t: Double) -> Rotation {
        .init(storage: simd_slerp(storage, other.storage, t))
    }

    #else

    public func interpolated(with other: Rotation, by t: Double) -> Rotation {
        let dot = max(-1, min(1, self.dot(other)))
        if abs(abs(dot) - 1) < epsilon {
            return (self + (other - self) * t).normalized()
        }

        let theta = acos(dot) * t
        let t1 = self * cos(theta)
        let t2 = (other - (self * dot)).normalized() * sin(theta)
        return t1 + t2
    }

    func dot(_ r: Rotation) -> Double {
        x * r.x + y * r.y + z * r.z + w * r.w
    }

    func normalized() -> Rotation {
        let lengthSquared = dot(self)
        if lengthSquared == 0 || lengthSquared == 1 {
            return self
        }
        let length = sqrt(lengthSquared)
        return .init(unchecked: x / length, y / length, z / length, w / length)
    }

    static func + (lhs: Rotation, rhs: Rotation) -> Rotation {
        .init(unchecked: lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z, lhs.w + rhs.w)
    }

    static func - (lhs: Rotation, rhs: Rotation) -> Rotation {
        .init(unchecked: lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z, lhs.w - rhs.w)
    }

    #endif
}

extension Transform: Interpolatable {
    public func interpolated(with other: Transform, by t: Double) -> Transform {
        .init(
            scale: scale.interpolated(with: other.scale, by: t),
            rotation: rotation.interpolated(with: other.rotation, by: t),
            translation: translation.interpolated(with: other.translation, by: t)
        )
    }
}
