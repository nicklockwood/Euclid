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

    /// Split the path along a plane.
    /// - Parameter plane: The ``Plane`` to split the path along.
    /// - Returns: A pair of paths representing the path fragments that lie in front and behind the plane .
    ///
    /// > Note: If the path and plane do not intersect, one of the returned paths will be empty.
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
        polygons = polygons.insertingEdgeVertices(
            with: polygons.holeEdges(isCancelled: isCancelled),
            isCancelled: isCancelled
        )
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
