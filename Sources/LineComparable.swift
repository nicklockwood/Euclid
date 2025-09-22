//
//  LineComparable.swift
//  Euclid
//
//  Created by Nick Lockwood on 24/04/2025.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

/// Protocol for line-comparable types.
public protocol LineComparable {
    /// Returns the absolute distance between the receiver and the specified line.
    /// - Parameter line: The line to compare with.
    /// - Returns: The distance between the receiver and the line. The value is positive if the receiver
    ///   lies in front or behind the line, or zero if it lies exactly on the line, or crosses it.
    func distance(from line: Line) -> Double

    /// Returns a true if the line intersects the receiver.
    /// - Parameter line: The line to compare with.
    /// - Returns: `true` if the line and receiver intersect, and `false` otherwise.
    func intersects(_ line: Line) -> Bool
}

public extension LineComparable {
    func intersects(_ line: Line) -> Bool {
        distance(from: line) < epsilon
    }
}

extension Bounds: LineComparable {
    public func distance(from line: Line) -> Double {
        corners.distance(from: line)
    }

    public func intersects(_ line: Line) -> Bool {
        !line.intersection(with: self).isEmpty
    }
}

extension Vector: LineComparable {
    public func distance(from line: Line) -> Double {
        line.distance(from: self)
    }
}

extension Vertex: LineComparable {
    public func distance(from line: Line) -> Double {
        position.distance(from: line)
    }
}

extension PathPoint: LineComparable {
    public func distance(from line: Line) -> Double {
        position.distance(from: line)
    }
}

extension Line: LineComparable {
    public func distance(from line: Line) -> Double {
        shortestLineBetween(
            origin,
            origin + direction,
            false,
            line.origin,
            line.origin + line.direction,
            false
        ).map {
            ($1 - $0).length
        } ?? 0
    }
}

extension LineSegment: LineComparable {
    public func distance(from line: Line) -> Double {
        shortestLineBetween(
            start,
            end,
            true,
            line.origin,
            line.origin + line.direction,
            false
        ).map {
            ($1 - $0).length
        } ?? 0
    }
}

extension Plane: LineComparable {
    public func distance(from line: Line) -> Double {
        line.distance(from: self)
    }

    public func intersects(_ line: Line) -> Bool {
        line.intersects(self)
    }
}

extension Path: LineComparable {
    public func distance(from line: Line) -> Double {
        switch points.count {
        case 0: return 0
        case 1: return points[0].distance(from: line)
        default: return orderedEdges.distance(from: line)
        }
    }

    public func intersects(_ line: Line) -> Bool {
        orderedEdges.intersects(line)
    }
}

extension Polygon: LineComparable {
    public func distance(from line: Line) -> Double {
        if let point = line.intersection(with: plane) {
            return distanceFromCoplanarPoint(point)
        }
        assert(line.isParallel(to: plane))
        let distance = abs(line.origin.signedDistance(from: plane))
        if distance > planeEpsilon {
            return distance
        }
        return orderedEdges.distance(from: line)
    }

    public func intersects(_ line: Line) -> Bool {
        line.intersection(with: plane).map(intersectsCoplanarPoint) ?? false
    }
}

extension Mesh: LineComparable {
    public func distance(from line: Line) -> Double {
        // TODO: this can almost certainly be optimized
        polygons.distance(from: line)
    }

    public func intersects(_ line: Line) -> Bool {
        // TODO: this can almost certainly be optimized
        polygons.intersects(line)
    }
}

extension Collection where Element: LineComparable {
    func distance(from line: Line) -> Double {
        var distance = Double.infinity
        for element in self where distance > 0 {
            distance = Swift.min(distance, element.distance(from: line))
        }
        return distance
    }

    func intersects(_ line: Line) -> Bool {
        contains(where: { $0.intersects(line) })
    }
}
