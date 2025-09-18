//
//  PointComparable.swift
//  Euclid
//
//  Created by Nick Lockwood on 21/04/2025.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

/// Protocol for point-comparable types.
public protocol PointComparable {
    /// Returns the nearest point on the receiver to the specified point.
    /// - Parameter point: The point to compare with.
    /// - Returns: The nearest point on the receiver to the specified point.
    func nearestPoint(to point: Vector) -> Vector

    /// Returns the distance between the receiver and the specified point.
    /// - Parameter point: The point to compare with.
    /// - Returns: The distance between the receiver and the point. The value is always positive
    ///   if the receiver is not touching the point, or zero if it touches or intersects the point.
    func distance(from point: Vector) -> Double

    /// Returns a true if the point touches or intersects the receiver.
    /// - Parameter point: The point to compare with.
    /// - Returns: `true` if the point and receiver intersect, and `false` otherwise.
    func intersects(_ point: Vector) -> Bool
}

public extension PointComparable {
    func distance(from point: Vector) -> Double {
        nearestPoint(to: point).distance(from: point)
    }

    func intersects(_ point: Vector) -> Bool {
        nearestPoint(to: point).isApproximatelyEqual(to: point)
    }

    /// Returns the nearest point if it intersects the receiver.
    /// - Parameter point: The point to compare with.
    /// - Returns: The nearest point on the receiver that touches the point, or `nil` otherwise.
    func intersection(with point: Vector) -> Vector? {
        intersects(point) ? point : nil
    }
}

extension Bounds: PointComparable {
    public func nearestPoint(to point: Vector) -> Vector {
        hasNegativeVolume ? min : point.clamped(to: min ... max)
    }

    public func intersects(_ point: Vector) -> Bool {
        hasNegativeVolume ? false : (min ... max).contains(point)
    }
}

extension Vector: PointComparable {
    public func nearestPoint(to _: Vector) -> Vector {
        self
    }

    public func intersects(_ point: Vector) -> Bool {
        isApproximatelyEqual(to: point)
    }
}

extension Vertex: PointComparable {
    public func nearestPoint(to _: Vector) -> Vector {
        position
    }

    public func intersects(_ point: Vector) -> Bool {
        position.isApproximatelyEqual(to: point)
    }
}

extension PathPoint: PointComparable {
    public func nearestPoint(to _: Vector) -> Vector {
        position
    }

    public func intersects(_ point: Vector) -> Bool {
        position.isApproximatelyEqual(to: point)
    }
}

extension Line: PointComparable {
    public func nearestPoint(to point: Vector) -> Vector {
        origin + direction * (point - origin).dot(direction)
    }
}

extension LineSegment: PointComparable {
    public func nearestPoint(to point: Vector) -> Vector {
        let (length, direction) = lengthAndDirection
        switch (point - start).dot(direction) {
        case ..<0: return start
        case length...: return end
        case let distance: return start + direction * distance
        }
    }
}

extension Plane: PointComparable {
    public func nearestPoint(to point: Vector) -> Vector {
        point - normal * point.signedDistance(from: self)
    }

    public func distance(from point: Vector) -> Double {
        abs(point.signedDistance(from: self))
    }

    public func intersects(_ point: Vector) -> Bool {
        point.intersects(self)
    }
}

extension Polygon: PointComparable {
    public func nearestPoint(to point: Vector) -> Vector {
        let projection = plane.nearestPoint(to: point)
        return nearestCoplanarPoint(to: projection)
    }

    public func distance(from point: Vector) -> Double {
        let distance = point.signedDistance(from: plane)
        if intersectsCoplanarPoint(point - plane.normal * distance) {
            return abs(distance)
        }
        // TODO: can we use a shortcut to exit early?
        // e.g. if nearer to edge than vertex, must be closest point
        return orderedEdges.distance(from: point)
    }

    public func intersects(_ point: Vector) -> Bool {
        plane.intersects(point) ? intersectsCoplanarPoint(point) : false
    }
}

extension Mesh: PointComparable {
    public func nearestPoint(to point: Vector) -> Vector {
        guard isKnownConvex else {
            return BSP(self) { false }.nearestPoint(to: point)
        }
        var result = point
        var shortest = Double.infinity
        var outside = false
        for polygon in polygons {
            switch point.compare(with: polygon.plane) {
            case .front:
                outside = true
                fallthrough
            case .coplanar, .spanning:
                let nearest = polygon.nearestPoint(to: point)
                let distance = nearest.distance(from: point)
                if distance < shortest {
                    if distance < epsilon {
                        return point
                    }
                    shortest = distance
                    result = nearest
                }
            case .back:
                break
            }
        }
        return outside ? result : point
    }

    public func distance(from point: Vector) -> Double {
        self == .empty ? .infinity : (nearestPoint(to: point) - point).length
    }

    public func intersects(_ point: Vector) -> Bool {
        if !bounds.intersects(point) {
            return false
        }
        guard isKnownConvex else {
            return BSP(self) { false }.intersects(point)
        }
        for polygon in polygons {
            switch point.compare(with: polygon.plane) {
            case .coplanar, .spanning:
                return polygon.intersects(point)
            case .front:
                return false
            case .back:
                break
            }
        }
        return true
    }
}

extension Collection where Element: PointComparable {
    func nearestPoint(to point: Vector) -> Vector {
        var result = point
        var shortest = Double.infinity
        for element in self {
            let nearest = element.nearestPoint(to: point)
            let distance = nearest.distance(from: point)
            if distance < shortest {
                shortest = distance
                result = nearest
            }
        }
        return result
    }

    func distance(from point: Vector) -> Double {
        reduce(.infinity) { Swift.min($0, $1.distance(from: point)) }
    }
}
