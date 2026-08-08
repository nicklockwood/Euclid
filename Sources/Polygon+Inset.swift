//
//  Polygon+Inset.swift
//  Euclid
//
//  Created by Nick Lockwood on 26/07/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

public extension Polygon {
    /// Applies a uniform inset to the edges of the polygon.
    /// - Parameter distance: The distance by which to inset the polygon edges.
    /// - Returns: A copy of the polygon, inset by the specified distance.
    ///
    /// > Note: Passing a negative `distance` will expand the polygon instead of shrinking it.
    func inset(by distance: Double) -> Polygon? {
        let source = vertices
        let count = source.count
        var v1 = source[count - 1]
        var v2 = source[0]
        var p1p2 = v2.position - v1.position
        var n1: Vector!
        let insetVertices = (0 ..< count).map { i in
            v1 = v2
            v2 = i < count - 1 ? source[i + 1] : source[0]
            let p0p1 = p1p2
            p1p2 = v2.position - v1.position
            let faceNormal = plane.normal
            let n0 = n1 ?? p0p1.cross(faceNormal).normalized()
            n1 = p1p2.cross(faceNormal).normalized()
            // TODO: do we need to inset texcoord as well? If so, by how much?
            let normal = (n0 + n1).normalized()
            return v1.translated(by: normal * -(distance / n0.dot(normal)))
        }
        let inset = resolveInsetIntersections(
            in: insetVertices,
            isClosed: true,
            normal: plane.normal,
            position: { (vertex: Vertex) in vertex.position },
            interpolate: { (a: Vertex, b: Vertex, t: Double) in a.lerp(b, t) }
        ).dropLast()
        guard inset.count > 2, !verticesAreDegenerate(inset) else {
            return nil
        }
        return Polygon(
            unchecked: Array(inset),
            plane: plane,
            isConvex: nil,
            sanitizeNormals: false,
            material: material,
            id: id
        )
    }
}

private extension Polygon {
    /// Returns inset polygons, splitting into triangles if the moved polygon becomes invalid.
    func insetPolygons(
        using positionCache: [Vector: Vector],
        by distance: Double
    ) -> [Polygon] {
        func moved(_ polygon: Polygon) -> [Polygon] {
            let vertices = polygon.vertices.map { vertex -> Vertex in
                let key = vertex.position
                let position = positionCache[key] ?? key.translated(by: polygon.plane.normal * -distance)
                return Vertex(unchecked: position, vertex.normal, vertex.texcoord, vertex.color)
            }
            let flatteningPlane = FlatteningPlane(normal: polygon.plane.normal)
            let points = vertices.map { flatteningPlane.flattenPoint($0.position) }
            if pointsAreSelfIntersecting(points, isClosed: true) {
                let resolved = resolveInsetIntersections(
                    in: vertices,
                    isClosed: true,
                    normal: polygon.plane.normal,
                    position: { (vertex: Vertex) in vertex.position },
                    interpolate: { $0.lerp($1, $2) }
                ).dropLast()
                if resolved.count > 2, !verticesAreDegenerate(resolved) {
                    return [Polygon(
                        unchecked: Array(resolved),
                        normal: polygon.plane.normal,
                        isConvex: nil, // Inset can alter shape
                        sanitizeNormals: false,
                        material: polygon.material
                    )]
                }
            }
            if vertices.count > 2, !verticesAreDegenerate(vertices) {
                return [Polygon(
                    unchecked: vertices,
                    normal: polygon.plane.normal,
                    isConvex: nil, // Inset can alter shape
                    sanitizeNormals: false,
                    material: polygon.material
                )]
            }
            let resolved = resolveInsetIntersections(
                in: vertices,
                isClosed: true,
                normal: polygon.plane.normal,
                position: { (vertex: Vertex) in vertex.position },
                interpolate: { $0.lerp($1, $2) }
            ).dropLast()
            if resolved.count > 2, !verticesAreDegenerate(resolved) {
                return [Polygon(
                    unchecked: Array(resolved),
                    normal: polygon.plane.normal,
                    isConvex: nil, // Inset can alter shape
                    sanitizeNormals: false,
                    material: polygon.material
                )]
            }
            return polygon.splitCollapsedInset(vertices, by: distance) ?? []
        }
        let polygons = moved(self)
        if !polygons.isEmpty {
            return polygons
        }
        return triangulate().flatMap(moved)
    }

    /// Splits a concave inset polygon around the first pair of edges that collapsed.
    func splitCollapsedInset(_ insetVertices: [Vertex], by distance: Double) -> [Polygon]? {
        let source = vertices
        let inset = insetVertices
        let count = min(source.count, inset.count)
        guard let (i, j) = collapsedInsetEdgePair(by: distance), count > j else {
            return nil
        }
        let first = Array(inset[i + 1 ... j]) + [inset[i + 1]]
        let secondStart = (j + 1) % count
        let second = (j + 1 < count ? Array(inset[j + 1 ..< count]) : []) +
            Array(inset[0 ... i]) + [inset[secondStart]]
        return [first, second].map {
            resolveInsetIntersections(
                in: $0,
                isClosed: true,
                normal: plane.normal,
                position: { (vertex: Vertex) in vertex.position },
                interpolate: { $0.lerp($1, $2) }
            ).dropLast()
        }
        .flatMap { vertices -> [Polygon] in
            let vertices = removeCollapsedVertices(from: Array(vertices))
            guard vertices.count > 2, !verticesAreDegenerate(vertices) else {
                return []
            }
            return [Polygon](
                Array(vertices),
                plane: plane,
                material: material
            )
        }
    }

    /// Returns the source edges that would cross when inset by the specified distance.
    func collapsedInsetEdges(by distance: Double) -> [LineSegment] {
        guard let (i, j) = collapsedInsetEdgePair(by: distance) else {
            return []
        }
        return [i, j].map {
            LineSegment(
                uncheckedUndirected: vertices[$0].position,
                vertices[($0 + 1) % vertices.count].position
            )
        }
    }

    /// Returns the indices of the first nonadjacent edge pair that collapses under inset.
    func collapsedInsetEdgePair(by distance: Double) -> (Int, Int)? {
        guard !isConvex, distance > 0, vertices.count > 3 else {
            return nil
        }
        let flatteningPlane = FlatteningPlane(normal: plane.normal)
        let sourcePoints = vertices.map { flatteningPlane.flattenPoint($0.position) }
        return firstCollapsedInsetEdgePair(in: sourcePoints, by: distance)
    }

    /// Removes collinear vertices introduced while resolving a collapsed inset.
    func removeCollapsedVertices(from vertices: [Vertex]) -> [Vertex] {
        var vertices = vertices
        var index = 0
        while vertices.count > 3, index < vertices.count {
            let a = vertices[index == 0 ? vertices.count - 1 : index - 1].position
            let b = vertices[index].position
            let c = vertices[(index + 1) % vertices.count].position
            let ab = b - a, bc = c - b
            guard ab.length > epsilon, bc.length > epsilon,
                  ab.normalized().cross(bc.normalized()).length < planeEpsilon
            else {
                index += 1
                continue
            }
            let removed = vertices.remove(at: index)
            if verticesAreDegenerate(vertices) {
                vertices.insert(removed, at: index)
                index += 1
            } else {
                index = max(index - 1, 0)
            }
        }
        return vertices
    }

    /// Returns true for antiparallel, overlapping faces close enough to be duplicate
    /// internal sheets left behind by an inset collapse.
    func isCollapsedInsetSheetPair(with other: Polygon, by distance: Double) -> Bool {
        guard plane.isAntiparallel(to: other.plane) else {
            return false
        }
        let separation = abs(plane.w + other.plane.w)
        guard separation < distance + epsilon else {
            return false
        }
        let flatteningPlane = FlatteningPlane(normal: plane.normal)
        let a = Bounds(vertices.map { flatteningPlane.flattenPoint($0.position) })
        let b = Bounds(other.vertices.map { flatteningPlane.flattenPoint($0.position) })
        guard !a.isEmpty, !b.isEmpty, a.intersects(b) else {
            return false
        }
        let intersection = a.intersection(b)
        let overlapArea = intersection.size.x * intersection.size.y
        let smallerArea = min(a.size.x * a.size.y, b.size.x * b.size.y)
        guard smallerArea > epsilon else {
            return false
        }
        return overlapArea / smallerArea > 1 - epsilon
    }
}

extension [Polygon] {
    /// Returns true if all polygon vertices lie behind every face plane.
    var isConvexSurface: Bool {
        let points = flatMap { $0.vertices.map(\.position) }
        return allSatisfy { polygon in
            points.allSatisfy { $0.signedDistance(from: polygon.plane) < epsilon }
        }
    }

    /// Inset along face normals
    func insetFaces(
        by distance: Double,
        isCancelled: Polygon.CancellationHandler = { false }
    ) -> [Polygon] {
        guard !isCancelled() else { return [] }
        let source = Array(self).mergingVertices(withPrecision: epsilon)
        var vertexInfo = [Vector: (planes: [Plane], neighbors: Set<Vector>)]()
        for (index, polygon) in source.enumerated() {
            if index.isMultiple(of: cancellationCheckInterval), isCancelled() { return [] }
            for i in polygon.vertices.indices {
                let position = polygon.vertices[i].position
                let previous = polygon.vertices[i == 0 ? polygon.vertices.count - 1 : i - 1].position
                let next = polygon.vertices[(i + 1) % polygon.vertices.count].position
                var info = vertexInfo[position] ?? ([], [])
                if !info.planes.contains(where: { $0.isApproximatelyEqual(to: polygon.plane) }) {
                    info.planes.append(polygon.plane)
                }
                info.neighbors.insert(previous)
                info.neighbors.insert(next)
                vertexInfo[position] = info
            }
        }

        /// Finds the longest straight neighbor chain passing through a vertex.
        func straightChain(
            for position: Vector,
            in vertexInfo: [Vector: (planes: [Plane], neighbors: Set<Vector>)]
        ) -> (Vector, Vector, Double)? {
            guard let info = vertexInfo[position] else {
                return nil
            }
            let neighbors = [Vector](info.neighbors)
            var best: (Vector, Vector)?
            var bestLengthSquared = 0.0
            for i in neighbors.indices {
                if i.isMultiple(of: cancellationCheckInterval), isCancelled() { return nil }
                for j in neighbors.indices.dropFirst(i + 1) {
                    let a = neighbors[i], b = neighbors[j]
                    guard pointsAreCollinear(a, position, b),
                          (a - position).dot(b - position) < 0
                    else {
                        continue
                    }
                    let lengthSquared = (b - a).lengthSquared
                    if lengthSquared > bestLengthSquared {
                        best = (a, b)
                        bestLengthSquared = lengthSquared
                    }
                }
            }
            guard let best else {
                return nil
            }
            let a = chainEndpoint(from: best.0, through: position, in: vertexInfo)
            let b = chainEndpoint(from: best.1, through: position, in: vertexInfo)
            let ab = b - a
            let lengthSquared = ab.lengthSquared
            guard lengthSquared > epsilon else {
                return nil
            }
            let t = (position - a).dot(ab) / lengthSquared
            guard t > epsilon, t < 1 - epsilon else {
                return nil
            }
            return (a, b, t)
        }

        /// Walks from a vertex to the end of a straight chain.
        func chainEndpoint(
            from neighbor: Vector,
            through position: Vector,
            in vertexInfo: [Vector: (planes: [Plane], neighbors: Set<Vector>)]
        ) -> Vector {
            var previous = position
            var current = neighbor
            var steps = 0
            while let next = vertexInfo[current]?.neighbors.first(where: {
                $0 != previous && pointsAreCollinear(previous, current, $0) &&
                    ($0 - current).dot(current - previous) > 0
            }) {
                if steps.isMultiple(of: cancellationCheckInterval), isCancelled() { break }
                previous = current
                current = next
                steps += 1
            }
            return current
        }

        var positionCache = [Vector: Vector]()
        for (index, element) in vertexInfo.enumerated() {
            if index.isMultiple(of: cancellationCheckInterval), isCancelled() { return [] }
            let (position, info) = element
            positionCache[position] = info.planes.insetPosition(for: position, by: distance)
        }
        let sourceBounds = Bounds(source.flatMap(\.vertices))
        let isConvexSurface = source.isConvexSurface
        if isConvexSurface {
            for (index, position) in positionCache.keys.enumerated() {
                if index.isMultiple(of: cancellationCheckInterval), isCancelled() { return [] }
                guard let (a, b, t) = straightChain(for: position, in: vertexInfo),
                      let a1 = positionCache[a],
                      let b1 = positionCache[b]
                else {
                    continue
                }
                positionCache[position] = a1 + (b1 - a1) * t
            }
        }
        guard !isCancelled() else { return [] }
        var wasCancelled = false
        let polygons: [Polygon] = source.enumerated().flatMap { index, polygon in
            if wasCancelled || index.isMultiple(of: cancellationCheckInterval) && isCancelled() {
                wasCancelled = true
                return [Polygon]()
            }
            return polygon.insetPolygons(
                using: positionCache,
                by: distance
            )
        }.removingCollapsedInsetSheets(by: distance, isCancelled: isCancelled)
        guard distance > 0, isConvexSurface else {
            return polygons.mergingVertices(withPrecision: epsilon)
        }
        let insetBounds = Bounds(polygons.flatMap(\.vertices))
        return sourceBounds.contains(insetBounds) ? polygons
            .mergingVertices(withPrecision: epsilon) : []
    }

    /// Removes paired sheets left behind when opposing faces collapse through an inset.
    func removingCollapsedInsetSheets(
        by distance: Double,
        isCancelled: Polygon.CancellationHandler = { false }
    ) -> [Polygon] {
        guard !isCancelled(), distance > 0, count > 1 else {
            return self
        }
        let polygons = self
        let originalHoleCount = polygons.holeEdges.count
        var removed = Set<Int>()
        for i in polygons.indices where !removed.contains(i) {
            if i.isMultiple(of: cancellationCheckInterval), isCancelled() { break }
            for j in polygons.indices.dropFirst(i + 1) where !removed.contains(j) {
                if j.isMultiple(of: cancellationCheckInterval), isCancelled() { break }
                guard polygons[i].isCollapsedInsetSheetPair(with: polygons[j], by: distance) else {
                    continue
                }
                var candidateRemoved = removed
                candidateRemoved.insert(i)
                candidateRemoved.insert(j)
                let candidate = polygons.indices.compactMap {
                    candidateRemoved.contains($0) ? nil : polygons[$0]
                }
                if candidate.holeEdges.count <= originalHoleCount {
                    removed = candidateRemoved
                    break
                }
            }
        }
        return removed.isEmpty ? polygons : polygons.indices.compactMap {
            removed.contains($0) ? nil : polygons[$0]
        }
    }
}

private extension Collection<Plane> {
    /// Calculates the inset position produced by offsetting the adjacent planes.
    func insetPosition(for position: Vector, by distance: Double) -> Vector {
        let planes = map { $0.translated(by: $0.normal * -distance) }
        switch planes.count {
        case 0:
            return position
        case 1:
            return planes[0].nearestPoint(to: position)
        case 2:
            return planes[0].intersection(with: planes[1])?.nearestPoint(to: position) ?? position
        case 3:
            if let line = planes[0].intersection(with: planes[1]),
               let point = line.intersection(with: planes[2])
            {
                return point
            }
            fallthrough
        default:
            return planes.bestFitIntersection ?? position
        }
    }
}
