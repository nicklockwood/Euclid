//
//  LineSegment+CSG.swift
//  Euclid
//
//  Created by Lockwood, Nick on 14/04/2025.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

public extension LineSegment {
    /// Callback used to cancel a long-running operation.
    /// - Returns: `true` if operation should be cancelled, or `false` otherwise.
    typealias CancellationHandler = () -> Bool

    /// Split the line segment along a plane.
    /// - Parameter plane: The ``Plane`` to split the line segment along.
    /// - Returns: A pair of segments representing the parts of the line segment in front and behind the plane.
    ///
    /// > Note: if the segment is coincident with the plane it will be treated as being behind the plane.
    func split(along plane: Plane) -> (front: LineSegment?, back: LineSegment?) {
        split(with: (start.signedDistance(from: plane), end.signedDistance(from: plane)))
    }

    /// Clip line segment to the specified plane.
    /// - Parameter plane: The ``Plane``  to clip the segment to.
    /// - Returns: The clipped line segment, or `nil` if the segment lies entirely behind the plane.
    ///
    /// > Note: if the segment is coincident with the plane it will be treated as being behind the plane.
    func clipped(to plane: Plane) -> LineSegment? {
        split(along: plane).front
    }

    /// Deprecated.
    @available(*, deprecated, renamed: "clipped(to:)")
    func clip(to plane: Plane) -> LineSegment? {
        clipped(to: plane)
    }

    /// Returns the parts of the line segment that lie outside of the specified mesh.
    /// - Parameters:
    ///   - mesh: The mesh volume against which to clip the segments.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: The parts of the line segment that lie outside the mesh.
    ///
    /// > Note: When clipping multiple edges, it is more efficient to call `Collection<LineSegment>.clipped(to:)`.
    func clipped(
        to mesh: Mesh,
        isCancelled: CancellationHandler = { false }
    ) -> [LineSegment] {
        guard intersects(mesh.bounds) else { return [self] }
        return BSP(mesh, isCancelled).clip([self], .greaterThan, isCancelled)
    }
}

public extension Collection<LineSegment> {
    /// Callback used to cancel a long-running operation.
    /// - Returns: `true` if operation should be cancelled, or `false` otherwise.
    typealias CancellationHandler = () -> Bool

    /// Split the line segments along a plane.
    /// - Parameter plane: The ``Plane`` to split the line segments along.
    /// - Returns: A pair of arrays representing the line segments in front of and behind the plane respectively.
    func split(along plane: Plane) -> (front: [LineSegment], back: [LineSegment]) {
        var front = [LineSegment](), back: [LineSegment]! = []
        forEach { $0.split(along: plane, &front, &back) }
        return (front, back)
    }

    /// Clip the line segments to the specified plane.
    /// - Parameter plane: The ``Plane`` to split the line segments along.
    /// - Returns: An array of line segments that lie in front of the plane.
    func clipped(to plane: Plane) -> [LineSegment] {
        var front = [LineSegment](), back: [LineSegment]?
        forEach { $0.split(along: plane, &front, &back) }
        return front
    }

    /// Deprecated.
    @available(*, deprecated, message: "Use clipped(to:isCancelled:) instead.")
    func subtracting(
        _ mesh: Mesh,
        isCancelled: CancellationHandler = { false }
    ) -> Set<LineSegment> {
        var aout: [LineSegment] = []
        return Set(BSP(mesh, isCancelled).clip(
            boundsTest(mesh.bounds, self, &aout),
            .greaterThan,
            isCancelled
        )).union(aout)
    }

    /// Returns the line segments that lie outside of the specified mesh, preserving their original order.
    /// - Parameters:
    ///   - mesh: The mesh volume against which to clip the segments.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: The line segments that lie outside the mesh (in their original order).
    func clipped(
        to mesh: Mesh,
        isCancelled: CancellationHandler = { false }
    ) -> [LineSegment] {
        var aout: [LineSegment] = []
        return BSP(mesh, isCancelled).clip(
            boundsTest(mesh.bounds, self, &aout),
            .greaterThan,
            isCancelled
        ) + aout
    }
}

private func boundsTest(
    _ bounds: Bounds,
    _ edges: some Collection<LineSegment>,
    _ out: inout [LineSegment]
) -> [LineSegment] {
    edges.filter {
        if $0.bounds.intersects(bounds) {
            return true
        }
        out.append($0)
        return false
    }
}

extension LineSegment {
    func clip(
        to coplanarPolygons: [Polygon],
        _ inside: inout [LineSegment],
        _ outside: inout [LineSegment]
    ) {
        var toTest = [self]
        for polygon in coplanarPolygons.tessellate() where !toTest.isEmpty {
            var _outside = [LineSegment]()
            toTest.forEach { polygon.clip($0, &inside, &_outside) }
            toTest = _outside
        }
        outside += toTest
    }

    /// Put the line segment in the correct list, splitting it when necessary
    /// > Note: the logic differs from the public method due to coplanar precision rules
    func split(
        along plane: Plane,
        _ coplanar: inout [LineSegment],
        _ front: inout [LineSegment],
        _ back: inout [LineSegment]
    ) {
        let distances = (start.signedDistance(from: plane), end.signedDistance(from: plane))
        if PlaneComparison(signedDistance: distances.0) == .coplanar,
           PlaneComparison(signedDistance: distances.1) == .coplanar
        {
            coplanar.append(self)
        } else {
            let segments = split(with: distances)
            segments.front.map { front.append($0) }
            segments.back.map { back.append($0) }
        }
    }

    /// Put the line segment in the correct list, splitting it when necessary
    /// > Note: coplanar segments are treated as being behind the plane.
    func split(
        along plane: Plane,
        _ front: inout [LineSegment],
        _ back: inout [LineSegment]?
    ) {
        let distances = (start.signedDistance(from: plane), end.signedDistance(from: plane))
        let segments = split(with: distances)
        segments.front.map { front.append($0) }
        segments.back.map { back?.append($0) }
    }

    /// Shared split implementation
    func split(with distances: (Double, Double)) -> (front: LineSegment?, back: LineSegment?) {
        switch distances {
        case (...0, ...0):
            return (nil, self)
        case (0..., 0...):
            return (self, nil)
        case let (a, b):
            let point = start + (end - start) * (abs(a) / (abs(a) + abs(b)))
            let segments = (
                LineSegment(start: start, end: point),
                LineSegment(start: point, end: end)
            )
            return a > 0 ? segments : (segments.1, segments.0)
        }
    }
}

private extension Polygon {
    func clip(
        _ coplanarSegment: LineSegment,
        _ inside: inout [LineSegment],
        _ outside: inout [LineSegment]
    ) {
        assert(isConvex)
        assert(coplanarSegment.compare(with: plane) == .coplanar)
        var lineSegment = coplanarSegment
        var coplanar = [LineSegment]()
        for plane in edgePlanes {
            var back = [LineSegment]()
            lineSegment.split(along: plane, &coplanar, &outside, &back)
            back.append(contentsOf: coplanar)
            guard let s = back.first else {
                return
            }
            lineSegment = s
        }
        inside.append(lineSegment)
    }
}
