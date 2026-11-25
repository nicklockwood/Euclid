//
//  Path+Inset.swift
//  Euclid
//
//  Created by Nick Lockwood on 26/07/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

public extension Path {
    /// Applies a uniform inset to the edges of the path, with optional beveled joins.
    /// - Parameters:
    ///   - distance: The distance by which to inset the path edges. A negative value expands the path.
    ///   - miterLimit: The threshold beyond which expanding corners are beveled. Use `1` to bevel
    ///     every expanding corner, or `.infinity` to miter every corner.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: A copy of the path, inset by the specified distance.
    func inset(
        by distance: Double,
        miterLimit: MiterLimit = .infinity,
        isCancelled: CancellationHandler = { false }
    ) -> Path {
        if windingRule != .default, requiresFillResolution, !hasResolvedFillBoundary {
            return fillBoundary(isCancelled: isCancelled)
                .inset(by: distance, miterLimit: miterLimit, isCancelled: isCancelled)
                .withWindingRule(windingRule)
        }
        guard subpaths.count <= 1 else {
            let subpaths = subpaths
            let containment = PathContainmentIndex(subpaths)
            var insetSubpaths = [Path]()
            for (index, subpath) in subpaths.enumerated() {
                guard !isCancelled() else {
                    return .empty
                }
                let distance = containment.depth(of: index).isMultiple(of: 2) ? distance : -distance
                insetSubpaths
                    .append(subpath.inset(by: distance, miterLimit: miterLimit, isCancelled: isCancelled))
            }
            return Path(subpaths: insetSubpaths, windingRule: windingRule)
        }
        guard points.count >= 2 else {
            return self
        }
        if isClosed {
            if !isSimple {
                return fillBoundary(isCancelled: isCancelled)
                    .inset(by: distance, miterLimit: miterLimit, isCancelled: isCancelled)
            } else if distance > 0, !insetHalfPlanesHaveIntersection(by: distance) {
                return .empty
            }
        }
        let source = points
        let count = source.count
        let bevelsCorners = miterLimit.angle < .pi && distance != 0
        let offsetCount = isClosed && bevelsCorners ? count - 1 : count
        let clipsContractingCorners = isClosed && bevelsCorners && plane != nil &&
            !pointsAreConvex(source.dropLast().map { flatteningPlane.flattenPoint($0.position) })
        var insetPoints = [PathPoint]()
        insetPoints.reserveCapacity(count)
        var p1 = isClosed ? source[count - 2] : (
            count > 2 ?
                extrapolate(source[2], source[1], source[0]) :
                extrapolate(source[1], source[0])
        )
        var p2 = source[0]
        var p1p2 = p2.position - p1.position
        var n1: Vector!
        for i in 0 ..< offsetCount {
            p1 = p2
            p2 = i < count - 1 ? source[i + 1] :
                (isClosed ? source[1] : (
                    count > 2 ?
                        extrapolate(source[i - 2], source[i - 1], source[i]) :
                        extrapolate(source[i - 1], source[i])
                ))
            let p0p1 = p1p2
            p1p2 = p2.position - p1.position
            let turn = p0p1.cross(p1p2)
            let faceNormal = plane?.normal ?? turn.normalized()
            let n0 = n1 ?? p0p1.cross(faceNormal).normalized()
            n1 = p1p2.cross(faceNormal).normalized()
            let isCorner = isClosed || (i > 0 && i < count - 1)
            let turnDirection = bevelsCorners && isCorner ? turn.dot(faceNormal) * distance : 0
            let angle = turnDirection < 0 ? angleBetweenNormalizedVectors(n0, n1) : .zero
            if angle > miterLimit.angle {
                // Cut the corner one offset distance along its bisector.
                let advance = abs(distance) * tan(angle / 4)
                insetPoints.append(p1.translated(by: p0p1.normalized() * advance - n0 * distance))
                insetPoints.append(p1.translated(by: -p1p2.normalized() * advance - n1 * distance))
            } else if clipsContractingCorners, turnDirection > 0 {
                // Keep the full offset edges so winding can resolve overlaps past the corner.
                insetPoints.append(p1.translated(by: -n0 * distance))
                insetPoints.append(p1)
                insetPoints.append(p1.translated(by: -n1 * distance))
            } else {
                // TODO: do we need to inset texcoord as well? If so, by how much?
                let normal = (n0 + n1).normalized()
                insetPoints.append(p1.translated(by: normal * -(distance / n0.dot(normal))))
            }
        }
        if offsetCount < count {
            insetPoints.append(insetPoints[0])
        }
        guard !isCancelled() else {
            return .empty
        }
        if isClosed, bevelsCorners, let plane {
            let offset = Path(insetPoints, windingRule: windingRule)
            if offset.isClosed, offset.subpaths.count == 1, offset.isSimple {
                return offset.faceNormal.dot(plane.normal) > 0 ? offset : .empty
            }
            // Crossed offset edges enclose reversed regions where the outline collapsed.
            let outline = Path(
                unchecked: .points(sanitizePoints(insetPoints)), plane: plane, windingRule: .nonZero
            )
            let clockwise = flattenedPointsAreClockwise(source.map {
                flatteningPlane.flattenPoint($0.position)
            })
            let polygons = outline.filledPolygons(
                clockwise: clockwise, material: nil, isCancelled: isCancelled
            )
            let aligned = polygons.insertingEdgeVertices(
                with: polygons.holeEdges(isCancelled: isCancelled), isCancelled: isCancelled
            ).mergingVertices(withPrecision: epsilon, isCancelled: isCancelled)
            return isCancelled() ? .empty : outline
                .filledAreaBoundary(from: aligned)
                .withWindingRule(windingRule)
        }
        func resolvedInset(from points: [PathPoint]) -> [PathPoint] {
            resolveInsetIntersections(
                in: points,
                isClosed: isClosed,
                normal: isClosed ? faceNormal : nil,
                collapsedDistance: abs(distance),
                position: { (point: PathPoint) in point.position },
                interpolate: { (a: PathPoint, b: PathPoint, t: Double) in a.lerp(b, t) }
            )
        }
        if isClosed, distance > 0 {
            if !bevelsCorners, let subpaths = splitCollapsedInset(insetPoints, by: distance) {
                return Path(unchecked: .subpaths(subpaths), plane: plane, windingRule: windingRule)
            } else if let subpaths = splitIntersectingInset(insetPoints, by: distance) {
                return Path(unchecked: .subpaths(subpaths), plane: plane, windingRule: windingRule)
            }
        }
        return Path(resolvedInset(from: insetPoints), windingRule: windingRule)
    }
}

extension Path {
    /// Returns true if the inward-offset edges of a convex path still enclose an area.
    func insetHalfPlanesHaveIntersection(by distance: Double) -> Bool {
        let flatteningPlane = flatteningPlane
        let points = Array(points.dropLast()).map {
            flatteningPlane.flattenPoint($0.position)
        }
        guard pointsAreConvex(points) else {
            return true
        }
        let bounds = Bounds(points)
        let padding = max(bounds.size.x, bounds.size.y) + distance + 1
        var polygon = [
            Vector(bounds.min.x - padding, bounds.min.y - padding),
            Vector(bounds.max.x + padding, bounds.min.y - padding),
            Vector(bounds.max.x + padding, bounds.max.y + padding),
            Vector(bounds.min.x - padding, bounds.max.y + padding),
        ]
        let winding = points.vectorArea.z >= 0 ? 1.0 : -1.0

        for i in points.indices {
            let p0 = points[i], p1 = points[(i + 1) % points.count]
            let edge = p1 - p0
            guard edge.length > epsilon else {
                continue
            }
            let direction = edge.normalized()
            let inward = Vector(-direction.y, direction.x) * winding
            let shiftedP0 = p0 + inward * distance

            func signedDistance(_ point: Vector) -> Double {
                winding * edge.cross(point - shiftedP0).z
            }

            var clipped = [Vector]()
            var previous = polygon.last!
            var previousDistance = signedDistance(previous)
            for current in polygon {
                let currentDistance = signedDistance(current)
                if currentDistance >= -epsilon {
                    if previousDistance < -epsilon {
                        let t = previousDistance / (previousDistance - currentDistance)
                        clipped.append(previous.lerp(current, t))
                    }
                    clipped.append(current)
                } else if previousDistance >= -epsilon {
                    let t = previousDistance / (previousDistance - currentDistance)
                    clipped.append(previous.lerp(current, t))
                }
                previous = current
                previousDistance = currentDistance
            }
            polygon = clipped
            guard polygon.count > 2, abs(polygon.vectorArea.z) > epsilon else {
                return false
            }
        }
        return true
    }

    /// Splits an inset path when opposing edges have collapsed into one another.
    func splitCollapsedInset(_ insetPoints: [PathPoint], by distance: Double) -> [Path]? {
        let flatteningPlane = flatteningPlane
        let source = Array(points.dropLast())
        let inset = Array(insetPoints.dropLast())
        let count = min(source.count, inset.count)
        guard count > 3 else {
            return nil
        }
        let sourcePoints = source.prefix(count).map { flatteningPlane.flattenPoint($0.position) }
        guard let (i, j) = firstCollapsedInsetEdgePair(in: sourcePoints, by: distance) else {
            return nil
        }
        let first = Array(inset[i + 1 ... j]) + [inset[i + 1]]
        let secondStart = (j + 1) % count
        let second = (j + 1 < count ? Array(inset[j + 1 ..< count]) : []) +
            Array(inset[0 ... i]) + [inset[secondStart]]
        return [first, second]
            .map {
                resolveInsetIntersections(
                    in: $0,
                    isClosed: true,
                    normal: faceNormal,
                    position: { (point: PathPoint) in point.position },
                    interpolate: { $0.lerp($1, $2) }
                )
            }
            .filter { $0.count > 3 }
            .map { Path($0, plane: plane) }
    }

    /// Splits an inset path when the inset edges cross and enclose separate surviving lobes.
    func splitIntersectingInset(_ insetPoints: [PathPoint], by distance: Double) -> [Path]? {
        var points = insetPoints
        if points.count > 1, points[0].position == points[points.count - 1].position {
            points.removeLast()
        }
        guard points.count > 3,
              let intersection = firstInsetSelfIntersection(in: points)
        else {
            return nil
        }
        let point = points[intersection.i].lerp(
            points[(intersection.i + 1) % points.count],
            intersection.t
        )
        let first = [point] + Array(points[intersection.i + 1 ... intersection.j]) + [point]
        let second = [point] +
            (intersection.j + 1 < points.count ? Array(points[intersection.j + 1 ..< points.count]) : []) +
            Array(points[0 ... intersection.i]) +
            [point]
        let subpaths = [first, second]
            .map {
                resolveInsetIntersections(
                    in: $0,
                    isClosed: true,
                    normal: faceNormal,
                    collapsedDistance: abs(distance),
                    position: { (point: PathPoint) in point.position },
                    interpolate: { $0.lerp($1, $2) }
                )
            }
            .map { removeFoldedInsetLoops(from: $0, distance: abs(distance)) }
            .filter { $0.count > 3 }
            .map { Path($0, plane: plane) }
        return subpaths.count > 1 ? subpaths : nil
    }

    /// Removes tiny loops created where an inset briefly folds back on itself.
    private func removeFoldedInsetLoops(
        from points: [PathPoint],
        distance: Double
    ) -> [PathPoint] {
        var points = points
        guard points.count > 4 else {
            return points
        }
        let isClosed = points[0].position == points[points.count - 1].position
        if isClosed {
            points.removeLast()
        }
        let minimumCount = isClosed ? 3 : 2
        let maximumChord = distance * 0.6
        let minimumFoldLength = distance * 0.85
        var changed = true
        while changed, points.count > minimumCount + 2 {
            changed = false
            for windowSize in stride(from: min(6, points.count), through: 4, by: -1) {
                guard points.count >= windowSize else {
                    continue
                }
                for start in 0 ... points.count - windowSize {
                    let window = Array(points[start ..< start + windowSize])
                    let chord = window[0].position.distance(from: window[window.count - 1].position)
                    let pathLength = zip(window, window.dropFirst()).reduce(0.0) {
                        $0 + $1.0.position.distance(from: $1.1.position)
                    }
                    guard chord < maximumChord,
                          pathLength > minimumFoldLength,
                          pathLength > chord * 3
                    else {
                        continue
                    }
                    points.removeSubrange(start + 1 ..< start + windowSize - 1)
                    changed = true
                    break
                }
                if changed {
                    break
                }
            }
        }
        guard isClosed, let first = points.first else {
            return points
        }
        return points + [first]
    }

    /// Finds the first non-adjacent edge crossing in an inset point loop.
    private func firstInsetSelfIntersection(
        in points: [PathPoint]
    ) -> (i: Int, j: Int, t: Double)? {
        let edgeCount = points.count
        guard edgeCount > 2 else {
            return nil
        }
        func edgesAreAdjacent(_ a: Int, _ b: Int) -> Bool {
            abs(a - b) == 1 || (a == 0 && b == edgeCount - 1)
        }
        for i in 0 ..< edgeCount {
            let a0 = points[i].position
            let a1 = points[(i + 1) % points.count].position
            for j in i + 1 ..< edgeCount where !edgesAreAdjacent(i, j) {
                let b0 = points[j].position
                let b1 = points[(j + 1) % points.count].position
                guard let p = lineIntersection(a0, a1, true, b0, b1, true) else {
                    continue
                }
                let t = a0.distance(from: p) / a0.distance(from: a1)
                let firstCount = j - i + 2
                let secondCount = edgeCount - j + i + 3
                guard firstCount > 3, secondCount > 3,
                      t > -epsilon, t < 1 + epsilon
                else {
                    continue
                }
                return (i, j, min(1, max(0, t)))
            }
        }
        return nil
    }
}
