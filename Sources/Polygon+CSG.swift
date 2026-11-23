//
//  Polygon+CSG.swift
//  Euclid
//
//  Created by Nick Lockwood on 09/01/2023.
//  Copyright © 2023 Nick Lockwood. All rights reserved.
//

public extension Polygon {
    /// Callback used to cancel a long-running operation.
    /// - Returns: `true` if operation should be cancelled, or `false` otherwise.
    typealias CancellationHandler = Euclid.CancellationHandler

    /// Split the polygon along a plane.
    /// - Parameters:
    ///   - plane: The ``Plane`` to split the polygon along.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: A pair of arrays representing the polygon fragments in front of and behind the plane respectively.
    /// - Note: If the plane and polygon do not intersect, one of the returned arrays will be empty.
    func split(
        along plane: Plane,
        _ isCancelled: CancellationHandler = { false }
    ) -> (front: [Polygon], back: [Polygon]) {
        var id = 0
        var coplanar = [Polygon](), front = [Polygon](), back = [Polygon]()
        split(along: plane, &coplanar, &front, &back, &id, isCancelled)
        for polygon in coplanar {
            plane.normal.dot(polygon.plane.normal) > 0 ?
                front.append(polygon) : back.append(polygon)
        }
        return (front, back)
    }

    /// Clip polygon to the specified plane
    /// - Parameter plane: The ``Plane``  to clip the polygon to.
    /// - Returns: An array of the polygon fragments that lie in front of the plane.
    func clipped(to plane: Plane) -> [Polygon] {
        split(along: plane).front
    }

    /// Clip polygon to the specified mesh
    /// - Parameters:
    ///   - mesh: The ``Mesh``  to clip the polygon to.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: An array of polygon fragments that lie outside the Mesh.
    func clipped(to mesh: Mesh, isCancelled: CancellationHandler = { false }) -> [Polygon] {
        guard bounds.intersects(mesh.bounds) else {
            return [self]
        }
        return BSP(mesh, isCancelled).clip([self], .greaterThan, isCancelled)
    }

    /// Projects the polygon orthogonally onto a plane.
    /// - Parameters:
    ///   - plane: The plane on which the returned path lies in world coordinates.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: The outline of the covered area, or a line segment for an edge-on projection.
    ///   Returns an empty path on cancellation.
    func projected(onto plane: Plane, isCancelled: CancellationHandler = { false }) -> Path {
        [self].projected(onto: plane, isCancelled: isCancelled)
    }

    /// Returns the intersection of the polygon and a plane.
    /// - Parameters:
    ///   - plane: The plane to intersect with.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: A closed outline for a coplanar intersection, or the segments and isolated
    ///   points where the plane meets the polygon. A miss or cancellation returns an empty path.
    func intersection(with plane: Plane, isCancelled: CancellationHandler = { false }) -> Path {
        guard !isCancelled() else { return .empty }
        if compare(with: plane) == .coplanar {
            return projected(onto: plane, isCancelled: isCancelled)
        }

        let project = plane.makePointProjection()
        let hasColor = hasVertexColors
        let paths = intersectionVertices(with: plane, isCancelled: isCancelled).map { vertices in
            let vertices = vertices.count > 2 && !hasColor ? [vertices[0], vertices[vertices.count - 1]] : vertices
            let points = vertices.map {
                PathPoint.point(project($0.position), color: hasColor ? $0.color : nil)
            }
            return Path(points)
        }
        return isCancelled() ? .empty : Path(subpaths: paths)
    }

    /// Computes a set of edges where the polygon intersects a plane.
    /// - Parameter plane: The ``Plane`` to test against the polygon.
    /// - Returns: A `Set` of ``LineSegment`` representing the polygon edges intersecting the plane.
    func edges(intersecting plane: Plane) -> Set<LineSegment> {
        var edges = Set<LineSegment>()
        intersect(with: plane, segments: &edges)
        return edges
    }

    /// Reflects each vertex of the polygon along a plane.
    /// - Parameter plane: The ``Plane`` against which the vertices are to be reflected.
    /// - Returns: A ``Polygon`` representing the reflected vertices.
    func reflected(along plane: Plane) -> Polygon {
        Polygon(
            unchecked: vertices.inverted().map { $0.reflected(along: plane) },
            plane: nil, // TODO: can we compute this cheaply?
            isConvex: isConvex,
            sanitizeNormals: false,
            material: material,
            id: id
        )
    }
}

extension Polygon {
    /// Returns contacts as runs of source vertices, interpolating along crossed edges.
    func intersectionVertices(with plane: Plane, isCancelled: CancellationHandler) -> [[Vertex]] {
        guard !isCancelled(), let first = vertices.first, var previous = vertices.last else { return [] }
        if compare(with: plane) == .coplanar {
            return [vertices + [first]]
        }
        var previousDistance = previous.position.signedDistance(from: plane)
        var contacts = [Vertex]()
        for vertex in vertices {
            guard !isCancelled() else { return [] }
            let distance = vertex.position.signedDistance(from: plane)
            let side = PlaneComparison(signedDistance: distance)
            if side == .coplanar {
                contacts.append(vertex)
            } else if side.union(.init(signedDistance: previousDistance)) == .spanning {
                contacts.append(previous.lerp(vertex, previousDistance / (previousDistance - distance)))
            }
            previous = vertex
            previousDistance = distance
        }
        guard let origin = contacts.first?.position else { return [] }
        let direction = self.plane.normal.cross(plane.normal)
        contacts.sort { ($0.position - origin).dot(direction) < ($1.position - origin).dot(direction) }

        // A concave polygon can cover several separate intervals of the intersection line.
        var runs = [[Vertex]]()
        var start = 0
        for (index, vertex) in contacts.enumerated() {
            guard !isCancelled() else { return [] }
            let next = index + 1
            if next == contacts.count || distanceFromCoplanarPoint(
                vertex.position.lerp(contacts[next].position, 0.5)
            ) > epsilon {
                runs.append(Array(contacts[start ... index]))
                start = next
            }
        }
        return runs
    }
}

extension Polygon {
    func clip(
        to polygons: [Polygon],
        _ inside: inout [Polygon],
        _ outside: inout [Polygon],
        _ id: inout Int,
        _ isCancelled: CancellationHandler
    ) {
        var toTest = tessellate()
        for (index, polygon) in polygons.tessellate(isCancelled: isCancelled).enumerated()
            where !toTest.isEmpty
        {
            if index.isMultiple(of: cancellationCheckInterval), isCancelled() {
                return
            }
            var _outside = [Polygon]()
            for (index, testedPolygon) in toTest.enumerated() {
                if index.isMultiple(of: cancellationCheckInterval), isCancelled() {
                    return
                }
                polygon.clip(testedPolygon, &inside, &_outside, &id, isCancelled)
            }
            toTest = _outside
        }
        outside += toTest
    }

    /// Put the polygon in the correct list, splitting it when necessary
    func split(
        along plane: Plane,
        _ coplanar: inout [Polygon],
        _ front: inout [Polygon],
        _ back: inout [Polygon],
        _ id: inout Int,
        _ isCancelled: CancellationHandler
    ) {
        switch compare(with: plane) {
        case .coplanar:
            coplanar.append(self)
        case .front:
            front.append(self)
        case .back:
            back.append(self)
        case .spanning:
            split(spanning: plane, &front, &back, &id, isCancelled)
        }
    }

    func split(
        spanning plane: Plane,
        _ front: inout [Polygon],
        _ back: inout [Polygon],
        _ id: inout Int,
        _ isCancelled: CancellationHandler
    ) {
        assert(compare(with: plane) == .spanning)
        var polygon = self
        if polygon.id == 0 {
            id += 1
            polygon.id = id
        }
        guard polygon.isConvex else {
            var coplanar = [Polygon]()
            for (index, polygon) in polygon.tessellate(isCancelled: isCancelled).enumerated() {
                if index.isMultiple(of: cancellationCheckInterval), isCancelled() {
                    return
                }
                polygon.split(along: plane, &coplanar, &front, &back, &id, isCancelled)
            }
            return
        }
        var f = [Vertex](), b = [Vertex]()
        var v0 = polygon.vertices.last!, t0 = v0.position.compare(with: plane)
        for (index, v1) in polygon.vertices.enumerated() {
            if index.isMultiple(of: cancellationCheckInterval), isCancelled() {
                return
            }
            if t0 != .back {
                f.append(v0)
            }
            if t0 != .front {
                b.append(v0)
            }
            let t1 = v1.position.compare(with: plane)
            if t0.union(t1) == .spanning {
                let t = (plane.w - plane.normal.dot(v0.position)) /
                    plane.normal.dot(v1.position - v0.position)
                let v = v0.lerp(v1, t)
                if f.last?.position != v.position, f.first?.position != v.position {
                    f.append(v)
                }
                if b.last?.position != v.position, b.first?.position != v.position {
                    b.append(v)
                }
            }
            v0 = v1
            t0 = t1
        }
        if !verticesAreDegenerate(f) {
            front.append(Polygon(
                unchecked: f,
                plane: polygon.plane,
                isConvex: true,
                sanitizeNormals: false,
                material: material,
                id: polygon.id
            ))
        }
        if !verticesAreDegenerate(b) {
            back.append(Polygon(
                unchecked: b,
                plane: polygon.plane,
                isConvex: true,
                sanitizeNormals: false,
                material: material,
                id: polygon.id
            ))
        }
    }

    /// Get all edges intersecting the plane
    func intersect(with plane: Plane, segments: inout Set<LineSegment>) {
        var wasFront = false, wasBack = false
        for segment in undirectedEdges {
            switch segment.compare(with: plane) {
            case .front where wasBack, .back where wasFront, .spanning:
                intersect(spanning: plane, segments: &segments)
                return
            case .coplanar:
                segments.insert(segment)
            case .front:
                wasFront = true
            case .back:
                wasBack = true
            }
        }
    }

    func intersect(spanning plane: Plane, segments: inout Set<LineSegment>) {
        guard isConvex else {
            for polygon in tessellate() {
                polygon.intersect(spanning: plane, segments: &segments)
            }
            return
        }
        var start: Vector?
        var p0 = vertices.last!.position, t0 = p0.compare(with: plane)
        for v in vertices {
            let p1 = v.position, t1 = p1.compare(with: plane)
            if t0 == .coplanar || t0.union(t1) == .spanning {
                let t = (plane.w - plane.normal.dot(p0)) / plane.normal.dot(p1 - p0)
                let p = p0.lerp(p1, t)
                if let start {
                    LineSegment(undirected: start, p).map { _ = segments.insert($0) }
                    return
                }
                start = p
            }
            p0 = p1
            t0 = t1
        }
        assertionFailure()
    }
}

private extension Polygon {
    func clip(
        _ coplanarPolygon: Polygon,
        _ inside: inout [Polygon],
        _ outside: inout [Polygon],
        _ id: inout Int,
        _ isCancelled: CancellationHandler
    ) {
        assert(isConvex)
        assert(coplanarPolygon.compare(with: plane) == .coplanar)
        var polygon = coplanarPolygon
        var coplanar = [Polygon]()
        for (index, plane) in edgePlanes.enumerated() {
            if index.isMultiple(of: cancellationCheckInterval), isCancelled() {
                return
            }
            var back = [Polygon]()
            polygon.split(along: plane, &coplanar, &outside, &back, &id, isCancelled)
            guard let p = back.first else {
                return
            }
            polygon = p
        }
        inside.append(polygon)
    }
}
