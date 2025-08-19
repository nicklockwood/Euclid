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

    /// Clip line segment to the specified plane.
    /// - Parameter plane: The ``Plane``  to clip the segment to.
    /// - Returns: The clipped line segment, or `nil` if the segment lies entirely behind the plane.
    func clipped(to plane: Plane) -> LineSegment? {
        split(along: plane).front
    }

    /// Deprecated.
    @available(*, deprecated, renamed: "clipped(to:)")
    func clip(to plane: Plane) -> LineSegment? {
        clipped(to: plane)
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

    /// Returns the point where the specified line segment intersects the line segment.
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

    /// Returns the point where the specified polygon intersects the line segment.
    /// - Parameter polygon: The polygon to compare with.
    /// - Returns: The point of intersection, or `nil` if the line and polygon don't intersect.
    func intersection(with polygon: Polygon) -> Vector? {
        intersection(with: polygon.plane).flatMap {
            polygon.intersects($0) ? $0 : nil
        }
    }

    /// Returns the points where the specified bounds intersects the line segment.
    /// - Parameter bounds: The bounds to compare with.
    /// - Returns: A set of zero or more points of intersection with the bounds.
    func intersection(with bounds: Bounds) -> Set<Vector> {
        var intersections = Set<Vector>()
        if start.intersects(bounds) { intersections.insert(start) }
        if end.intersects(bounds) { intersections.insert(end) }
        if intersections.count == 2 {
            return intersections
        }
        // TODO: optimize this by taking into account that planes are axis-aligned
        return intersections.union(bounds.edgePlanes.compactMap {
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
    /// - Returns: `true` if the line and segment intersect, and `false` otherwise.
    func intersects(_ lineSegment: LineSegment) -> Bool {
        intersection(with: lineSegment) != nil
    }

    /// Returns a true if the line segment intersects the specified polygon.
    /// - Parameter polygon: The polygon to compare with.
    /// - Returns: `true` if the polygon and segment intersect, and `false` otherwise.
    func intersects(_ polygon: Polygon) -> Bool {
        intersection(with: polygon) != nil
    }

    /// Returns a true if the line segment intersects the specified bounds.
    /// - Parameter bounds: The bodun to compare with.
    /// - Returns: `true` if the line and bounds intersect, and `false` otherwise.
    func intersects(_ bounds: Bounds) -> Bool {
        !intersection(with: bounds).isEmpty
    }
}

public extension Collection<LineSegment> {
    /// Callback used to cancel a long-running operation.
    /// - Returns: `true` if operation should be cancelled, or `false` otherwise.
    typealias CancellationHandler = () -> Bool

    /// Returns the line segments that lie outside of the specified mesh.
    /// - Parameters:
    ///   - mesh: The mesh volume to subtract from the segments.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: The set of line segments remaining after the subtraction.
    func subtracting(
        _ mesh: Mesh,
        isCancelled: CancellationHandler = { false }
    ) -> Set<LineSegment> {
        var aout: [LineSegment]? = []
        return Set(BSP(mesh, isCancelled).clip(
            boundsTest(mesh.bounds, self, &aout),
            .greaterThan,
            isCancelled
        )).union(aout!)
    }
}

private func boundsTest(
    _ bounds: Bounds,
    _ edges: some Collection<LineSegment>,
    _ out: inout [LineSegment]?
) -> [LineSegment] {
    edges.filter {
        if $0.bounds.intersects(bounds) {
            return true
        }
        out?.append($0)
        return false
    }
}

extension LineSegment {
    func clip(
        to polygons: [Polygon],
        _ inside: inout [LineSegment],
        _ outside: inout [LineSegment]
    ) {
        var toTest = [self]
        for polygon in polygons.tessellate() where !toTest.isEmpty {
            var _outside = [LineSegment]()
            toTest.forEach { polygon.clip($0, &inside, &_outside) }
            toTest = _outside
        }
        outside += toTest
    }

    /// Put the line segment in the correct list, splitting it when necessary
    /// TODO: the logic differs slightly from the public method due to coplanar precision rules - is this a problem?
    func split(
        along plane: Plane,
        _ coplanar: inout [LineSegment],
        _ front: inout [LineSegment],
        _ back: inout [LineSegment]
    ) {
        switch (start.signedDistance(from: plane), end.signedDistance(from: plane)) {
        case (-epsilon ..< epsilon, -epsilon ..< epsilon):
            coplanar.append(self)
        case (epsilon..., epsilon...):
            front.append(self)
        case (..<(-epsilon), ..<(-epsilon)):
            back.append(self)
        case let (distance, _):
            let point = start + direction * abs(distance)
            var segments = (
                LineSegment(start: start, end: point),
                LineSegment(start: point, end: end)
            )
            if distance < 0 {
                segments = (segments.1, segments.0)
            }
            segments.0.map { front.append($0) }
            segments.1.map { back.append($0) }
        }
    }
}

extension Polygon {
    func clip(
        _ lineSegment: LineSegment,
        _ inside: inout [LineSegment],
        _ outside: inout [LineSegment]
    ) {
        assert(isConvex)
        var lineSegment = lineSegment
        var coplanar = [LineSegment]()
        for plane in edgePlanes {
            var back = [LineSegment]()
            lineSegment.split(along: plane, &coplanar, &outside, &back)
            guard let s = back.first else {
                return
            }
            lineSegment = s
        }
        inside.append(lineSegment)
    }
}
