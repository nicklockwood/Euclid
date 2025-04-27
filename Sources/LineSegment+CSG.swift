//
//  LineSegment+CSG.swift
//  Euclid
//
//  Created by Lockwood, Nick on 14/04/2025.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

public extension LineSegment {
    /// Split the line segment along a plane.
    /// - Parameter plane: The ``Plane`` to split the line segment along.
    /// - Returns: A pair of segments representing the parts of the line segment in front and behind the plane.
    func split(along plane: Plane) -> (front: LineSegment?, back: LineSegment?) {
        switch (start.signedDistance(from: plane), end.signedDistance(from: plane)) {
        case (0..., 0...):
            return (nil, self)
        case (..<0, ..<0):
            return (self, nil)
        case let (distance, _):
            let point = start + direction * abs(distance)
            let segments = (
                LineSegment(start: start, end: point),
                LineSegment(start: point, end: end)
            )
            return distance > 0 ? segments : (segments.1, segments.0)
        }
    }

    /// Clip line segment to the specified plane.
    /// - Parameter plane: The ``Plane``  to clip the segment to.
    /// - Returns: The clipped line segment, or `nil` if the segment lies entirely behind the plane.
    func clip(to plane: Plane) -> LineSegment? {
        split(along: plane).front
    }

    /// Returns the point where the specified plane intersects the line segment.
    /// - Parameter plane: The plane to compare with.
    /// - Returns: The point of intersection, or `nil` if the line segment and plane don't intersect.
    func intersection(with plane: Plane) -> Vector? {
        linePlaneIntersection(start, direction, plane).flatMap {
            (0 ... length).contains($0) ? start + direction * $0 : nil
        }
    }

    /// Returns the point where the specified line intersects the line segment.
    /// - Parameter line: The line to compare with.
    /// - Returns: The point of intersection, or `nil` if the lines don't intersect.
    func intersection(with line: Line) -> Vector? {
        lineIntersection(
            start,
            end,
            true,
            line.origin,
            line.origin + line.direction,
            false
        )
    }

    /// Returns the point where the specified line segment intersects the receiver.
    /// - Parameter lineSegment: The line segment to compare with.
    /// - Returns: The point of intersection, or `nil` if the segments don't intersect.
    func intersection(with lineSegment: LineSegment) -> Vector? {
        lineIntersection(
            start,
            end,
            true,
            lineSegment.start,
            lineSegment.end,
            true
        )
    }

    /// Returns the points where the specified bounds intersects the line segment.
    /// - Parameter bounds: The bounds to compare with.
    /// - Returns: A set of zero or more points of intersection with the bounds.
    func intersection(with polygon: Polygon) -> Vector? {
        intersection(with: polygon.plane).flatMap {
            polygon.intersects($0) ? $0 : nil
        }
    }

    /// Returns the points where the specified bounds intersects the line segment.
    /// - Parameter bounds: The bounds to compare with.
    /// - Returns: A set of zero or more points of intersection with the bounds.
    func intersection(with bounds: Bounds) -> Set<Vector> {
        // TODO: optimize this by taking into account that planes are axis-aligned
        Set(bounds.edgePlanes.compactMap {
            intersection(with: $0).flatMap {
                bounds.intersects($0) ? $0 : nil
            }
        })
    }

    /// Returns the shortest distance between the line and the line segment.
    /// - Parameter lineSegment: The lineSegment to compare with.
    /// - Returns: The absolute distance from the nearest point on the object.
    func distance(from lineSegment: LineSegment) -> Double {
        shortestLineBetween(
            start,
            end,
            true,
            lineSegment.start,
            lineSegment.end,
            true
        ).flatMap {
            ($1 - $0).length
        } ?? 0
    }

    /// Returns a true if the line segment intersects the specified line.
    /// - Parameter lineSegment: The lineSegment to compare with.
    /// - Returns: `true` if the line and object intersect, and `false` otherwise.
    func intersects(_ lineSegment: LineSegment) -> Bool {
        intersection(with: lineSegment) != nil
    }
}
