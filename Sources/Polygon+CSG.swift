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
    typealias CancellationHandler = () -> Bool

    /// Split the polygon along a plane.
    /// - Parameter plane: The ``Plane`` to split the polygon along.
    /// - Returns: A pair of arrays representing the polygon fragments in front of and behind the plane respectively.
    ///
    /// > Note: If the plane and polygon do not intersect, one of the returned arrays will be empty.
    func split(along plane: Plane) -> (front: [Polygon], back: [Polygon]) {
        var id = 0
        var coplanar = [Polygon](), front = [Polygon](), back = [Polygon]()
        split(along: plane, &coplanar, &front, &back, &id)
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

    /// Deprecated.
    @available(*, deprecated, renamed: "clipped(to:)")
    func clip(to plane: Plane) -> [Polygon] {
        clipped(to: plane)
    }

    /// Clip polygon to the specified mesh
    /// - Parameter mesh: The ``Mesh``  to clip the polygon to.
    /// - Returns: An array of polygon fragments that lie outside the Mesh.
    func clipped(to mesh: Mesh, isCancelled: CancellationHandler? = nil) -> [Polygon] {
        guard bounds.intersects(mesh.bounds) else {
            return [self]
        }
        let isCancelled = isCancelled ?? { false }
        return BSP(mesh, isCancelled).clip([self], .greaterThan, isCancelled)
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
            plane: nil,
            isConvex: nil,
            sanitizeNormals: true,
            material: material,
            id: id
        )
    }
}

extension Polygon {
    func clip(
        to polygons: [Polygon],
        _ inside: inout [Polygon],
        _ outside: inout [Polygon],
        _ id: inout Int
    ) {
        var toTest = tessellate()
        for polygon in polygons.tessellate() where !toTest.isEmpty {
            var _outside = [Polygon]()
            toTest.forEach { polygon.clip($0, &inside, &_outside, &id) }
            toTest = _outside
        }
        outside += toTest
    }

    func clip(
        _ polygon: Polygon,
        _ inside: inout [Polygon],
        _ outside: inout [Polygon],
        _ id: inout Int
    ) {
        assert(isConvex)
        var polygon = polygon
        var coplanar = [Polygon]()
        for plane in edgePlanes {
            var back = [Polygon]()
            polygon.split(along: plane, &coplanar, &outside, &back, &id)
            guard let p = back.first else {
                return
            }
            polygon = p
        }
        inside.append(polygon)
    }

    /// Put the polygon in the correct list, splitting it when necessary
    func split(
        along plane: Plane,
        _ coplanar: inout [Polygon],
        _ front: inout [Polygon],
        _ back: inout [Polygon],
        _ id: inout Int
    ) {
        switch compare(with: plane) {
        case .coplanar:
            coplanar.append(self)
        case .front:
            front.append(self)
        case .back:
            back.append(self)
        case .spanning:
            split(spanning: plane, &front, &back, &id)
        }
    }

    func split(
        spanning plane: Plane,
        _ front: inout [Polygon],
        _ back: inout [Polygon],
        _ id: inout Int
    ) {
        assert(compare(with: plane) == .spanning)
        var polygon = self
        if polygon.id == 0 {
            id += 1
            polygon.id = id
        }
        guard polygon.isConvex else {
            var coplanar = [Polygon]()
            for polygon in polygon.tessellate() {
                polygon.split(along: plane, &coplanar, &front, &back, &id)
            }
            return
        }
        var f = [Vertex](), b = [Vertex]()
        var v0 = polygon.vertices.last!, t0 = v0.position.compare(with: plane)
        for v1 in polygon.vertices {
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

    mutating func insertEdgePoint(_ p: Vector) -> Bool {
        guard var last = vertices.last else {
            assertionFailure()
            return false
        }
        if vertices.contains(where: { $0.position.isApproximatelyEqual(to: p) }) {
            return false
        }
        for (i, v) in vertices.enumerated() {
            let s = LineSegment(unchecked: last.position, v.position)
            guard s.intersects(p) else {
                last = v
                continue
            }
            let t = p.distance(from: s.start) / s.length
            let vertex = last.lerp(v, t)
            guard !vertex.isApproximatelyEqual(to: last), !vertex.isApproximatelyEqual(to: v) else {
                return false
            }
            var vertices = vertices
            vertices.insert(vertex, at: i)
            self = Polygon(
                unchecked: vertices,
                plane: plane,
                isConvex: isConvex,
                sanitizeNormals: false,
                material: material,
                id: id
            )
            return true
        }
        return false
    }
}
