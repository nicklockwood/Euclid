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
        switch (start.distance(from: plane), end.distance(from: plane)) {
        case (0..., 0...):
            return (self, nil)
        case (..<0, ..<0):
            return (nil, self)
        case let (distance, _):
            let point = start + direction * abs(distance)
            let segments = (
                LineSegment(start: start, end: point),
                LineSegment(start: point, end: end)
            )
            return distance > 0 ? segments : (segments.1, segments.0)
        }
    }

    /// Clip polygon to the specified plane
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
            $0 >= 0 && $0 <= length ? start + direction * $0 : nil
        }
    }

    /// Returns the intersection point between the specified line segment and this one.
    /// - Parameter segment: The line segment to compare with.
    /// - Returns: The point of intersection, or `nil` if the line segments don't intersect.
    func intersection(with segment: LineSegment) -> Vector? {
        lineSegmentsIntersection(start, end, segment.start, segment.end)
    }

    /// Returns a Boolean value that indicates whether two line segments intersect.
    /// - Parameter segment: The line segment to compare with.
    /// - Returns: `true` if the line segments intersect and `false` otherwise.
    func intersects(_ segment: LineSegment) -> Bool {
        intersection(with: segment) != nil
    }
}
