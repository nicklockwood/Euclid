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

public extension Collection where Element == LineSegment {
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

private func boundsTest<T: Collection>(
    _ bounds: Bounds,
    _ edges: T,
    _ out: inout [LineSegment]?
) -> [LineSegment] where T.Element == LineSegment {
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
        switch (start.distance(from: plane), end.distance(from: plane)) {
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
