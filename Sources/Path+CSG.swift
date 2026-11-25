//
//  Path+CSG.swift
//  Euclid
//
//  Created by Nick Lockwood on 25/08/2025.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

public extension Path {
    /// Callback used to cancel a long-running operation.
    /// - Returns: `true` if operation should be cancelled, or `false` otherwise.
    typealias CancellationHandler = Euclid.CancellationHandler

    /// Returns the boundary of the combined filled areas of two paths.
    /// - Parameters:
    ///   - path: The path to form a union with.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: A closed path, or `nil` if nonempty inputs are not closed and coplanar.
    ///   Cancellation returns an empty path. The result follows the receiver's winding.
    func union(_ path: Path, isCancelled: CancellationHandler = { false }) -> Path? {
        .union([self, path], isCancelled: isCancelled)
    }

    /// Returns the boundary of the receiver's filled area minus the other path's filled area.
    /// - Parameters:
    ///   - path: The path to subtract from the receiver.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: A closed path, or `nil` if nonempty inputs are not closed and coplanar.
    ///   Cancellation returns an empty path. The result follows the receiver's winding.
    func subtracting(_ path: Path, isCancelled: CancellationHandler = { false }) -> Path? {
        .difference([self, path], isCancelled: isCancelled)
    }

    /// Returns the boundary of the filled area shared by two paths.
    /// - Parameters:
    ///   - path: The path to intersect with the receiver.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: A closed path, or `nil` if nonempty inputs are not closed and coplanar.
    ///   Cancellation returns an empty path. The result follows the receiver's winding.
    func intersection(_ path: Path, isCancelled: CancellationHandler = { false }) -> Path? {
        .intersection([self, path], isCancelled: isCancelled)
    }

    /// Returns the boundary of the filled area belonging to either path, but not both.
    /// - Parameters:
    ///   - path: The path to XOR with the receiver.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: A closed path, or `nil` if nonempty inputs are not closed and coplanar.
    ///   Cancellation returns an empty path. The result follows the receiver's winding.
    func symmetricDifference(_ path: Path, isCancelled: CancellationHandler = { false }) -> Path? {
        .symmetricDifference([self, path], isCancelled: isCancelled)
    }

    /// Forms a union of the filled areas of a collection of paths.
    /// - Parameters:
    ///   - paths: Closed, coplanar paths. Empty paths are permitted.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: The combined boundary, or `nil` for invalid inputs. Cancellation returns an empty path.
    ///   The result follows the winding of the first nonempty input.
    static func union(
        _ paths: some Collection<Path>,
        isCancelled: CancellationHandler = { false }
    ) -> Path? {
        csg(paths, using: { .union($0, isCancelled: isCancelled) }, isCancelled: isCancelled)
    }

    /// Subtracts the filled areas of all subsequent paths from the first path.
    /// - Parameters:
    ///   - paths: An ordered collection of closed, coplanar paths. Empty paths are permitted.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: The remaining boundary, or `nil` for invalid inputs. Cancellation returns an empty path.
    ///   The result follows the winding of the first nonempty input.
    static func difference(
        _ paths: some Collection<Path>,
        isCancelled: CancellationHandler = { false }
    ) -> Path? {
        csg(paths, using: { .difference($0, isCancelled: isCancelled) }, isCancelled: isCancelled)
    }

    /// Intersects the filled areas of a collection of paths.
    /// - Parameters:
    ///   - paths: Closed, coplanar paths. Empty paths are permitted.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: The shared boundary, or `nil` for invalid inputs. Cancellation returns an empty path.
    ///   The result follows the winding of the first nonempty input.
    static func intersection(
        _ paths: some Collection<Path>,
        isCancelled: CancellationHandler = { false }
    ) -> Path? {
        csg(paths, using: { .intersection($0, isCancelled: isCancelled) }, isCancelled: isCancelled)
    }

    /// Forms the symmetric difference of the filled areas of a collection of paths.
    /// - Parameters:
    ///   - paths: Closed, coplanar paths. Empty paths are permitted.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: The XOR boundary, or `nil` for invalid inputs. Cancellation returns an empty path.
    ///   The result follows the winding of the first nonempty input.
    static func symmetricDifference(
        _ paths: some Collection<Path>,
        isCancelled: CancellationHandler = { false }
    ) -> Path? {
        csg(paths, using: { .symmetricDifference($0, isCancelled: isCancelled) }, isCancelled: isCancelled)
    }

    /// Returns the boundary of the convex hull of two closed, coplanar paths.
    /// Returns `nil` for invalid inputs, or an empty path on cancellation.
    func convexHull(with path: Path, isCancelled: CancellationHandler = { false }) -> Path? {
        .convexHull(of: [self, path], isCancelled: isCancelled)
    }

    /// Returns the boundary of the convex hull of closed, coplanar paths.
    /// Empty paths are ignored. Returns `nil` for invalid inputs, or an empty path on cancellation.
    /// The result follows the winding of the first nonempty input.
    static func convexHull(
        of paths: some Collection<Path>,
        isCancelled: CancellationHandler = { false }
    ) -> Path? {
        csg(paths, preservingCurvature: false, using: {
            .convexHull(of: $0, isCancelled: isCancelled)
        }, isCancelled: isCancelled)
    }

    /// Returns the boundary of the Minkowski sum of two closed, coplanar paths.
    /// Empty paths are ignored, matching mesh Minkowski sums.
    /// Returns `nil` for invalid inputs, or an empty path on cancellation.
    func minkowskiSum(with path: Path, isCancelled: CancellationHandler = { false }) -> Path? {
        .minkowskiSum(of: [self, path], isCancelled: isCancelled)
    }

    /// Returns the boundary of the Minkowski sum of closed, coplanar paths.
    /// Empty paths are ignored. Returns `nil` for invalid inputs, or an empty path on cancellation.
    /// Coordinates are added in world space; the result follows the first nonempty input's winding.
    /// Curvature is preserved along contributing boundaries; new concave intersections remain sharp.
    static func minkowskiSum(
        of paths: some Collection<Path>,
        isCancelled: CancellationHandler = { false }
    ) -> Path? {
        let paths = paths.filter { !$0.isEmpty }
        guard !isCancelled(), let first = paths.first else { return .empty }
        guard let plane = csgPlane(for: paths, isCancelled: isCancelled) else {
            return isCancelled() ? .empty : nil
        }
        // Keep intermediate sums on the input plane. Restore the summed normal offset at the end.
        let offset = plane.origin
        var result = first.translated(by: -offset)
        for path in paths.dropFirst() {
            let rhs = path.translated(by: -offset)
            guard let boundary = csg([result, rhs], preservingCurvature: false, using: { meshes in
                let result = meshes[0], mesh = meshes[1]
                guard !isCancelled(), let normal = result.polygons.first?.plane.normal else { return .empty }
                // Decompose filled regions before summing, preserving concavities and holes.
                let lhs = result.polygons.filter { $0.plane.normal.dot(normal) > 0 }
                    .tessellate(isCancelled: isCancelled)
                let rhs = mesh.polygons.filter { $0.plane.normal.dot(normal) > 0 }
                    .tessellate(isCancelled: isCancelled)
                var components = [Mesh]()
                for a in lhs {
                    for b in rhs {
                        guard !isCancelled() else { return .empty }
                        let vertices = a.vertices.flatMap { a in
                            b.vertices.map { b in Vertex(a.position + b.position, color: a.color * b.color) }
                        }
                        components.append(.convexHull(of: vertices, isCancelled: isCancelled))
                    }
                }
                return .union(components, isCancelled: isCancelled)
            }, isCancelled: isCancelled) else { return nil }
            result = boundary.restoringMinkowskiCurvature(from: result, rhs, isCancelled: isCancelled)
            guard !isCancelled() else { return .empty }
        }
        return result.translated(by: offset * Double(paths.count))
    }

    /// Projects the path orthogonally onto a plane, preserving point attributes and winding rule.
    /// - Parameters:
    ///   - plane: The plane on which the projected path lies in world coordinates.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: The projected path, including subpaths that collapse to a line or point.
    ///   Returns an empty path on cancellation.
    func projected(onto plane: Plane, isCancelled: CancellationHandler = { false }) -> Path {
        let project = plane.makePointProjection()
        var projected = [Path]()
        for subpath in subpaths {
            var points = [PathPoint]()
            points.reserveCapacity(subpath.points.count)
            for point in subpath.points {
                guard !isCancelled() else { return .empty }
                points.append(point.withPosition(project(point.position)))
            }
            guard let origin = points.first?.position else { continue }
            // An edge-on contour can double back along its projected line.
            // Sorting along the line retains the full span when removing duplicate points.
            if points.count > 2,
               subpath.plane.map({ abs($0.normal.dot(plane.normal)) <= epsilon }) ?? true,
               let end = points.max(by: {
                   ($0.position - origin).lengthSquared < ($1.position - origin).lengthSquared
               }),
               let direction = (end.position - origin).direction,
               points.allSatisfy({ ($0.position - origin).cross(direction).length <= epsilon })
            {
                let firstDirection = points.lazy.map { $0.position - origin }.first { !$0.isZero } ?? direction
                let axis = firstDirection.dot(direction) < 0 ? -direction : direction
                points.sort { ($0.position - origin).dot(axis) < ($1.position - origin).dot(axis) }
            }
            let path = Path(unchecked: .points(sanitizePoints(points)), plane: nil)
            projected.append(path)
        }
        return isCancelled() ? .empty : Path(unchecked: .subpaths(projected), plane: nil, windingRule: windingRule)
    }

    /// Finds the points and portions of the path that lie on a plane.
    /// - Parameters:
    ///   - plane: The plane to intersect with.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: Coplanar portions of the path and isolated crossing or tangent points.
    ///   Returns an empty path on a miss or cancellation.
    func intersection(with plane: Plane, isCancelled: CancellationHandler = { false }) -> Path {
        let project = plane.makePointProjection()
        var intersections = [Path]()
        for subpath in subpaths {
            var fragments = [[PathPoint]]()
            var coplanar = [PathPoint]()
            var previous: (point: PathPoint, distance: Double, side: PlaneComparison)?
            for point in subpath.points {
                guard !isCancelled() else { return .empty }
                let distance = point.position.signedDistance(from: plane)
                let side = PlaneComparison(signedDistance: distance)
                if side == .coplanar {
                    coplanar.append(point.withPosition(project(point.position)))
                } else if !coplanar.isEmpty {
                    fragments.append(coplanar)
                    coplanar = []
                } else if let previous, previous.side.union(side) == .spanning {
                    let t = previous.distance / (previous.distance - distance)
                    let crossing = previous.point.lerp(point, t)
                    fragments.append([crossing.withPosition(project(crossing.position))])
                }
                previous = (point, distance, side)
            }
            if !coplanar.isEmpty {
                // A coplanar run can straddle a closed contour's first point.
                if subpath.isClosed, let first = fragments.first, first.first?.position == coplanar.last?.position {
                    coplanar += first.dropFirst()
                    fragments.removeFirst()
                }
                fragments.append(coplanar)
            }
            intersections += fragments.map { Path(unchecked: .points(sanitizePoints($0)), plane: nil) }
        }
        return isCancelled() ? .empty : Path(unchecked: .subpaths(intersections), plane: nil, windingRule: windingRule)
    }

    /// Split the path along a plane.
    /// - Parameter plane: The ``Plane`` to split the path along.
    /// - Returns: A pair of paths representing the path fragments that lie in front and behind the plane .
    /// - Note: If the path and plane do not intersect, one of the returned paths will be empty.
    func split(along plane: Plane) -> (front: Path, back: Path) {
        var front = [Path](), back: [Path]! = [], coplanar: [Path]?
        split(along: plane, &coplanar, &front, &back) { false }
        return (Path(subpaths: front), Path(subpaths: back))
    }

    /// Clip path to the specified plane.
    /// - Parameter plane: The plane to clip the path to
    /// - Returns: A path consisting of the parts of the original path that lie in front of the plane.
    func clipped(to plane: Plane) -> Path {
        var front = [Path](), back: [Path]?, coplanar: [Path]?
        split(along: plane, &coplanar, &front, &back) { false }
        return Path(subpaths: front)
    }

    /// Splits the receiver's curves along a closed, coplanar path. The receiver may be open or closed.
    /// - Parameters:
    ///   - path: The closed boundary, including any holes or disjoint contours.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: A pair of paths representing the path fragments that lie inside and outside the boundary.
    func split(
        along path: Path,
        isCancelled: CancellationHandler = { false }
    ) -> (inside: Path, outside: Path)? {
        guard !isCancelled(), !isEmpty else { return (.empty, .empty) }
        guard !path.isEmpty else { return (.empty, self) }
        guard let plane = Self.csgPlane(for: [path], isCancelled: isCancelled),
              points.allSatisfy({ plane.intersects($0.position) })
        else { return isCancelled() ? (.empty, .empty) : nil }
        let polygons = Mesh.fill(path, faces: .front, isCancelled: isCancelled).polygons
        var inside = [Path](), outside = [Path]()
        clip(to: polygons, &inside, &outside, isCancelled)
        return isCancelled() ? (.empty, .empty) : (Path(subpaths: inside), Path(subpaths: outside))
    }

    /// Clips away the portions of the receiver inside a closed, coplanar path. The receiver may be open or closed.
    /// - Parameters:
    ///   - path: The closed clipping boundary, including any holes or disjoint contours.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: A path consisting of the parts of the original path that lie outside the boundary.
    func clipped(to path: Path, isCancelled: CancellationHandler = { false }) -> Path? {
        split(along: path, isCancelled: isCancelled)?.outside
    }

    /// Clip path to the specified mesh.
    /// - Parameters:
    ///   - mesh: The ``Mesh``  to clip the path to.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: A path that lies outside the mesh.
    func clipped(to mesh: Mesh, isCancelled: CancellationHandler = { false }) -> Path {
        guard bounds.intersects(mesh.bounds) else {
            return self
        }
        return BSP(mesh, isCancelled).clip(self, .greaterThan, isCancelled)
    }
}

extension Path {
    /// An outline candidate with its endpoints in both output and source coordinates.
    struct BoundaryEdge: Bounded {
        let start, end: Vector
        let sourceStart, sourceEnd: Vertex
        let faceNormal: Vector
        let hasColor: Bool

        var bounds: Bounds { Bounds(min: min(start, end), max: max(start, end)) }

        func sample(at point: Vector) -> Vertex {
            let delta = end - start
            let lengthSquared = delta.lengthSquared
            guard lengthSquared > 0 else { return sourceStart }
            let t = (point - start).dot(delta) / lengthSquared
            if t <= 0 { return sourceStart }
            if t >= 1 { return sourceEnd }
            return sourceStart.lerp(sourceEnd, t)
        }
    }

    func applyingBoundaryAttributes(
        from edges: [BoundaryEdge],
        normal: Vector,
        isCancelled: CancellationHandler
    ) -> Path {
        guard !isCancelled() else { return .empty }
        guard !isEmpty, !edges.isEmpty else { return self }
        guard let index = BoundaryEdgeIndex(edges, isCancelled: isCancelled) else { return .empty }

        struct Span {
            let edge: BoundaryEdge
            let lower, upper: Double
        }
        struct Sample {
            let vertex: Vertex
            let faceNormal: Vector
            let color: Color?
        }
        // Prefer the source on the normal-facing side when projected edges coincide.
        func bestSample(at point: Vector, from candidates: some Sequence<BoundaryEdge>) -> Sample? {
            var best: Sample?
            var bestDepth = -Double.infinity
            var bestFacing = -Double.infinity
            for edge in candidates {
                let vertex = edge.sample(at: point)
                let depth = vertex.position.dot(normal)
                let facing = edge.faceNormal.dot(normal)
                if depth > bestDepth + planeEpsilon ||
                    (abs(depth - bestDepth) <= planeEpsilon && facing > bestFacing)
                {
                    best = Sample(
                        vertex: vertex,
                        faceNormal: edge.faceNormal,
                        color: edge.hasColor ? vertex.color : nil
                    )
                    bestDepth = depth
                    bestFacing = facing
                }
            }
            return best
        }
        func isCurved(_ incoming: Sample?, _ outgoing: Sample?) -> Bool {
            guard let a = incoming, let b = outgoing,
                  a.vertex.position.isApproximatelyEqual(to: b.vertex.position, absoluteTolerance: planeEpsilon),
                  let aNormal = a.vertex.normal.direction, let bNormal = b.vertex.normal.direction,
                  aNormal.isApproximatelyEqual(to: bNormal),
                  !aNormal.isApproximatelyEqual(to: a.faceNormal),
                  !bNormal.isApproximatelyEqual(to: b.faceNormal)
            else { return false }
            return aNormal.cross(normal).length > planeEpsilon
        }
        struct EdgeSamples {
            let start, end: Sample?
            let interior: [PathPoint]
        }
        func samples(between a: Vector, and b: Vector) -> EdgeSamples {
            let delta = b - a
            let length = delta.length
            let direction = delta / length
            let spans: [Span] = index.edges(in: Bounds([a, b]).inset(by: -planeEpsilon)).compactMap { edge in
                let start = edge.start - a, end = edge.end - a
                guard start.cross(direction).length <= planeEpsilon,
                      end.cross(direction).length <= planeEpsilon else { return nil }
                let t0 = start.dot(direction), t1 = end.dot(direction)
                let lower = max(0, min(t0, t1)), upper = min(length, max(t0, t1))
                return upper - lower > epsilon ? Span(edge: edge, lower: lower, upper: upper) : nil
            }
            func sample(at distance: Double, after: Bool) -> Sample? {
                let candidates = spans.lazy.filter { span in
                    after ? span.lower <= distance + epsilon && span.upper > distance + epsilon :
                        span.lower < distance - epsilon && span.upper >= distance - epsilon
                }
                return bestSample(at: a + direction * distance, from: candidates.map(\.edge))
            }
            var interior = [PathPoint]()
            if spans.contains(where: \.edge.hasColor) {
                let breaks = spans.flatMap { [$0.lower, $0.upper] }.sorted()
                let starting = spans.sorted { $0.lower < $1.lower }
                var next = 0
                var active = [Span]()
                var previous = 0.0
                for distance in breaks where distance < length - epsilon && distance > previous + epsilon {
                    while next < starting.count, starting[next].lower <= distance + epsilon {
                        active.append(starting[next])
                        next += 1
                    }
                    let position = a + direction * distance
                    let continuing = active.lazy.filter { $0.upper > distance + epsilon }
                    let ending = active.lazy.filter { $0.upper >= distance - epsilon }
                    let attributes = bestSample(at: position, from: continuing.map(\.edge)) ??
                        bestSample(at: position, from: ending.map(\.edge))
                    interior.append(.point(position, color: attributes?.color))
                    active.removeAll { $0.upper <= distance + epsilon }
                    previous = distance
                }
            }
            return EdgeSamples(
                start: sample(at: 0, after: true),
                end: sample(at: length, after: false),
                interior: interior
            )
        }

        var paths = [Path]()
        for subpath in subpaths {
            let points = subpath.points
            guard let first = points.first else { continue }
            if points.count == 1 {
                let position = first.position
                let nearby = index.edges(in: Bounds([position]).inset(by: -planeEpsilon))
                let touching = nearby.filter {
                    LineSegment(start: $0.start, end: $0.end).map {
                        $0.distance(from: position) <= planeEpsilon
                    } ?? $0.start.isApproximatelyEqual(to: position, absoluteTolerance: planeEpsilon)
                }
                paths.append(Path([first.withColor(bestSample(at: position, from: touching)?.color)]))
                continue
            }
            var attributes = [EdgeSamples]()
            for (a, b) in zip(points, points.dropFirst()) {
                guard !isCancelled() else { return .empty }
                attributes.append(samples(between: a.position, and: b.position))
            }
            var attributed = [PathPoint]()
            var incoming = subpath.isClosed ? attributes.last?.end : nil
            for (point, edge) in zip(points, attributes) {
                let color = (edge.start ?? incoming)?.color
                attributed.append(point.withColor(color).curved(isCurved(incoming, edge.start)))
                attributed += edge.interior
                incoming = edge.end
            }
            if subpath.isClosed {
                attributed.append(attributed[0])
            } else if let last = points.last {
                attributed.append(last.withColor(incoming?.color))
            }
            paths.append(Path(unchecked: .points(sanitizePoints(attributed)), plane: subpath.plane))
        }
        return isCancelled() ? .empty : Path(unchecked: .subpaths(paths), plane: plane, windingRule: windingRule)
    }

    func clip(
        to coplanarPolygons: [Polygon],
        _ inside: inout [Path],
        _ outside: inout [Path],
        _ isCancelled: CancellationHandler
    ) {
        var toTest = [self]
        for (index, polygon) in coplanarPolygons.tessellate(isCancelled: isCancelled).enumerated()
            where !toTest.isEmpty
        {
            if index.isMultiple(of: cancellationCheckInterval), isCancelled() {
                return
            }
            var _outside: [Path]! = []
            for (index, path) in toTest.enumerated() {
                if index.isMultiple(of: cancellationCheckInterval), isCancelled() {
                    return
                }
                polygon.clip(path, &inside, &_outside, isCancelled)
            }
            toTest = _outside
        }
        outside += toTest
    }

    func split(
        along plane: Plane,
        _ coplanar: inout [Path]?,
        _ front: inout [Path],
        _ back: inout [Path]?,
        _ isCancelled: CancellationHandler
    ) {
        let subpaths = subpaths
        guard subpaths.count == 1 else {
            for (index, subpath) in subpaths.enumerated() {
                if index.isMultiple(of: cancellationCheckInterval), isCancelled() {
                    return
                }
                subpath.split(along: plane, &coplanar, &front, &back, isCancelled)
            }
            return
        }
        guard var p0 = points.first else {
            return
        }
        var t0 = p0.position.compare(with: plane)
        var comparison = t0
        var points = [p0]
        for (index, p1) in self.points.dropFirst().enumerated() {
            if index.isMultiple(of: cancellationCheckInterval), isCancelled() {
                return
            }
            let t1 = p1.position.compare(with: plane)
            comparison = comparison.union(t1)
            switch comparison {
            case .front, .back, .coplanar:
                points.append(p1)
            case .spanning where t0 != .coplanar:
                let t = (plane.w - plane.normal.dot(p0.position)) /
                    plane.normal.dot(p1.position - p0.position)
                points.append(p0.lerp(p1, t))
                fallthrough
            case .spanning:
                let path = Path(points)
                if t1 == .back {
                    front.append(path)
                } else {
                    back?.append(path)
                }
                points = [points.last!, p1]
                comparison = t1
            }
            p0 = p1
            t0 = t1
        }
        if !points.isEmpty {
            let path = Path(points)
            if comparison == .coplanar {
                if coplanar != nil {
                    coplanar?.append(path)
                    return
                }
                comparison = plane.normal.dot(path.faceNormal) > 0 ? .front : .back
            }
            if comparison == .back {
                back?.append(path)
            } else {
                front.append(path)
            }
        }
    }
}

private enum BoundaryEdgeIndex {
    case leaf(Bounds, [Path.BoundaryEdge])
    indirect case branch(Bounds, BoundaryEdgeIndex, BoundaryEdgeIndex)

    init?(_ edges: [Path.BoundaryEdge], isCancelled: CancellationHandler) {
        guard !isCancelled() else { return nil }
        let bounds = Bounds(edges)
        guard edges.count > 8 else {
            self = .leaf(bounds, edges)
            return
        }
        let axis = bounds.size.mostParallelAxis
        let midpoint = bounds.center.dot(axis)
        var left = [Path.BoundaryEdge](), right = [Path.BoundaryEdge]()
        for edge in edges {
            if ((edge.start + edge.end) / 2).dot(axis) < midpoint {
                left.append(edge)
            } else {
                right.append(edge)
            }
        }
        guard !left.isEmpty, !right.isEmpty else {
            self = .leaf(bounds, edges)
            return
        }
        guard let a = Self(left, isCancelled: isCancelled), let b = Self(right, isCancelled: isCancelled) else {
            return nil
        }
        self = .branch(bounds, a, b)
    }

    func edges(in bounds: Bounds) -> [Path.BoundaryEdge] {
        var matches = [Path.BoundaryEdge]()
        collectEdges(in: bounds, into: &matches)
        return matches
    }

    private func collectEdges(in bounds: Bounds, into matches: inout [Path.BoundaryEdge]) {
        switch self {
        case let .leaf(region, edges) where region.intersects(bounds):
            matches.append(contentsOf: edges.lazy.filter { $0.bounds.intersects(bounds) })
        case let .branch(region, left, right) where region.intersects(bounds):
            left.collectEdges(in: bounds, into: &matches)
            right.collectEdges(in: bounds, into: &matches)
        default:
            break
        }
    }
}

private extension Path {
    static func csgPlane(for paths: some Collection<Path>, isCancelled: CancellationHandler) -> Plane? {
        guard let plane = paths.first(where: { !$0.isEmpty })?.plane else { return nil }
        for path in paths {
            guard !isCancelled(), path.isEmpty || (
                path.isClosed && path.plane != nil && path.points.allSatisfy { plane.intersects($0.position) }
            ) else { return nil }
        }
        return plane
    }

    func restoringMinkowskiCurvature(from lhs: Path, _ rhs: Path, isCancelled: CancellationHandler) -> Path {
        struct Corner {
            let point: PathPoint
            let incoming, outgoing: Vector
        }
        struct Contribution {
            let position: Vector
            let directions: [Vector]
        }
        func corners(of path: Path) -> [Corner] {
            path.subpaths.flatMap { subpath in
                let points = Array(subpath.points.dropLast())
                return points.indices.map { i in
                    Corner(
                        point: points[i],
                        incoming: (
                            points[i].position - points[(i + points.count - 1) % points.count].position
                        ).normalized(),
                        outgoing: (
                            points[(i + 1) % points.count].position - points[i].position
                        ).normalized()
                    )
                }
            }
        }
        let left = corners(of: lhs), right = corners(of: rhs)
        guard left.contains(where: \.point.isCurved) || right.contains(where: \.point.isCurved) else {
            return self
        }
        var contributions = [Contribution]()
        var curvedEdges = [LineSegment]()
        // Boundary vertices are sums of input vertices. Match their incident edges as well, so
        // intersections created by clipping aren't smoothed just because their positions coincide.
        for a in left {
            for b in right where a.point.isCurved || b.point.isCurved {
                guard !isCancelled() else { return .empty }
                contributions.append(Contribution(
                    position: a.point.position + b.point.position,
                    directions: [a.incoming, a.outgoing, b.incoming, b.outgoing]
                ))
            }
        }
        // Clipping can also insert collinear vertices into a translated curved edge.
        for (source, other) in [(lhs, right), (rhs, left)] {
            for subpath in source.subpaths {
                for (a, b) in zip(subpath.points, subpath.points.dropFirst()) where a.isCurved || b.isCurved {
                    for corner in other {
                        guard !isCancelled() else { return .empty }
                        if let edge = LineSegment(
                            start: a.position + corner.point.position,
                            end: b.position + corner.point.position
                        ) {
                            curvedEdges.append(edge)
                        }
                    }
                }
            }
        }
        let subpaths = subpaths.map { subpath -> Path in
            let corners = corners(of: subpath)
            var points = corners.map { corner -> PathPoint in
                var point = corner.point
                guard !isCancelled() else { return point }
                point.isCurved = contributions.contains { contribution in
                    (contribution.position - point.position).lengthSquared < epsilon * epsilon &&
                        contribution.directions.contains { $0.isParallel(to: corner.incoming) } &&
                        contribution.directions.contains { $0.isParallel(to: corner.outgoing) }
                } || curvedEdges.contains { edge in
                    edge.intersects(point.position) && edge.direction.isParallel(to: corner.incoming) &&
                        edge.direction.isParallel(to: corner.outgoing)
                }
                return point
            }
            if let first = points.first { points.append(first) }
            return Path(unchecked: points, plane: subpath.plane)
        }
        return isCancelled() ? .empty : Path(unchecked: .subpaths(subpaths), plane: plane)
    }

    static func csg(
        _ paths: some Collection<Path>,
        preservingCurvature: Bool = true,
        using operation: ([Mesh]) -> Mesh,
        isCancelled: CancellationHandler
    ) -> Path? {
        guard paths.contains(where: { !$0.isEmpty }) else {
            return .empty
        }
        guard let plane = csgPlane(for: paths, isCancelled: isCancelled) else {
            return isCancelled() ? .empty : nil
        }
        var meshes = [Mesh]()
        for path in paths {
            if isCancelled() {
                return .empty
            }
            // Both faces are needed so planar meshes bound a filled region for BSP clipping.
            meshes.append(.fill(path, faces: .frontAndBack, isCancelled: isCancelled))
        }
        let mesh = operation(meshes)
        guard !isCancelled() else {
            return .empty
        }
        // Extract only one side, avoiding cancellation of the coincident front and back edges.
        var polygons = mesh.polygons.filter { $0.plane.normal.dot(plane.normal) > 0 }
        polygons = polygons.mergingVertices(withPrecision: epsilon, isCancelled: isCancelled)
        // Edge insertion interpolates positions, so weld again before matching exact endpoints.
        polygons = polygons.insertingEdgeVertices(
            with: polygons.holeEdges(isCancelled: isCancelled),
            isCancelled: isCancelled
        ).mergingVertices(withPrecision: epsilon, isCancelled: isCancelled)
        guard !isCancelled() else {
            return .empty
        }
        let source = Path(subpaths: paths.flatMap(\.subpaths))
        var boundary = Path(unchecked: .subpaths(polygons.outlinePaths), plane: polygons.first?.plane ?? plane)
        if preservingCurvature {
            boundary = boundary.restoringCurvature(from: source)
        }
        if source.points.contains(where: { $0.color != nil }) {
            var colors = [Vector: Color]()
            for polygon in polygons {
                for vertex in polygon.vertices {
                    colors[vertex.position] = colors[vertex.position] ?? vertex.color
                }
            }
            boundary = boundary.mapPoints { $0.withColor(colors[$0.position]) }
        }
        return isCancelled() ? .empty : boundary
    }
}

private extension Polygon {
    func clip(
        _ coplanarPath: Path,
        _ inside: inout [Path],
        _ outside: inout [Path],
        _ isCancelled: CancellationHandler
    ) {
        assert(isConvex)
        assert(coplanarPath.compare(with: plane) == .coplanar)
        var path = coplanarPath
        for (index, plane) in edgePlanes.enumerated() {
            if index.isMultiple(of: cancellationCheckInterval), isCancelled() {
                return
            }
            var coplanar: [Path]! = [], back: [Path]! = []
            path.split(along: plane, &coplanar, &outside, &back, isCancelled)
            back.append(contentsOf: coplanar)
            guard !back.isEmpty else { return }
            path = Path(subpaths: back)
        }
        inside.append(contentsOf: path.subpaths)
    }
}
