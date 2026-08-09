//
//  Utilities.swift
//  Euclid
//
//  Created by Nick Lockwood on 03/07/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/Euclid
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

/// Tolerance used for calculating approximate equality
let epsilon: Double = 1e-8

/// Plane equality threshold
let planeEpsilon: Double = 2e-8

/// Smallest valid scale factor
let scaleLimit: Double = 1e-8

/// Number of loop iterations between cancellation checks.
let cancellationCheckInterval = 500

/// Deterministic UInt64 hash
func deterministicHash(_ seed: UInt64) -> UInt64 {
    // See https://github.com/wangyi-fudan/wyhash/
    let result = seed.multipliedFullWidth(by: seed ^ 0xE7037ED1A0B428DB)
    return result.high ^ result.low
}

/// Round-off floating point values to simplify equality checks
func quantize(_ value: Double) -> Double {
    let precision = 1e-12
    return (value / precision).rounded() * precision
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }

    mutating func clamp(to range: ClosedRange<Self>) {
        self = clamped(to: range)
    }
}

extension Double {
    func clampedToScaleLimit() -> Double {
        if isFinite {
            self < 0 ? min(self, -scaleLimit) : max(self, scaleLimit)
        } else {
            self < 0 ? -1 : 1
        }
    }
}

// MARK: Vertex utilities

extension Collection<Vertex> {
    /// A vector representation of the area of the polygon formed by the points
    /// Magnitude is polygon area; direction is polygon normal
    var vectorArea: Vector {
        map(\.position).vectorArea
    }

    /// Signed volume of the polyhedron formed by connecting the vertices to the origin
    var signedVolume: Double {
        map(\.position).signedVolume
    }

    /// Average position of the vertices
    var centroid: Vector {
        map(\.position).centroid
    }
}

extension [Vertex] {
    /// Check if vertex is redundant - i.e. that the interpolated values would be the same if it were removed
    mutating func removeIfRedundant(at index: Int) -> Bool {
        guard count > 3 else { return false }
        assert(!verticesAreDegenerate(self))
        let a = self[(index == 0) ? count - 1 : index - 1]
        let b = self[index]
        let c = self[(index + 1) % count]
        let ab = b.position - a.position, bc = c.position - b.position
        let abl = ab.length, bcl = bc.length
        // check if point is geometrically redundant
        guard abs((ab / abl).dot(bc / bcl) - 1) < epsilon else {
            return false
        }
        // check that removing point won't change interpolated vertex attributes
        let t = abl / (abl + bcl)
        guard a.lerp(c, t).isApproximatelyEqual(to: b) else {
            return false
        }
        // check that removing point won't make vertices degenerate
        let removed = remove(at: index)
        if verticesAreDegenerate(self) {
            insert(removed, at: index)
            return false
        }
        return true
    }
}

func verticesAreDegenerate(_ vertices: some Collection<Vertex>) -> Bool {
    guard vertices.count > 2 else {
        return true
    }
    let positions = vertices.map(\.position)
    return pointsAreDegenerate(positions) || pointsAreSelfIntersecting(positions)
}

func verticesAreConvex(_ vertices: some Collection<Vertex>) -> Bool {
    guard vertices.count > 3 else {
        return vertices.count > 2
    }
    return pointsAreConvex(vertices.map(\.position))
}

func triangulateVertices(
    _ vertices: [Vertex],
    plane: Plane?,
    isConvex: Bool?,
    sanitizeNormals: Bool,
    material: Mesh.Material?,
    id: Int,
    flipped: Bool = false
) -> [Polygon] {
    guard vertices.count > 3 else {
        guard !verticesAreDegenerate(vertices) else {
            return []
        }
        return [Polygon(
            unchecked: vertices,
            plane: plane,
            isConvex: true,
            sanitizeNormals: sanitizeNormals,
            material: material,
            id: id
        )]
    }

    /// Triangulates directly in 3D for non-planar or numerically awkward boundaries.
    func triangulatePossiblyNonPlanarVertices(
        _ vertices: [Vertex],
        plane: Plane?,
        isConvex: Bool?,
        sanitizeNormals: Bool,
        material: Mesh.Material?,
        id: Int,
        flipped: Bool = false
    ) -> [Polygon] {
        var triangles = [Polygon]()
        func addTriangle(_ vertices: [Vertex]) -> Bool {
            guard !verticesAreDegenerate(vertices) else {
                return false
            }
            triangles.append(Polygon(
                unchecked: vertices,
                plane: plane,
                isConvex: true,
                sanitizeNormals: sanitizeNormals,
                material: material,
                id: id
            ))
            return true
        }
        let isConvex = isConvex ?? verticesAreConvex(vertices)
        if isConvex {
            var vertices = vertices
            var i = 0
            var attempts = 0
            while vertices.count > 3 {
                let a = vertices[i]
                let b = vertices[(i + 1) % vertices.count]
                let c = vertices[(i + 2) % vertices.count]
                let d = vertices[(i + 3) % vertices.count]
                if LineSegment(start: c.position, end: a.position)?.intersects(d.position) == false,
                   addTriangle([a, b, c])
                {
                    vertices.remove(at: (i + 1) % vertices.count)
                    i = i % vertices.count
                    attempts = 0
                } else {
                    i = (i + 1) % vertices.count
                    attempts += 1
                }
                if attempts > vertices.count * 2 {
                    assert(plane == nil || triangles.allSatisfy { $0.plane == plane })
                    return triangles
                }
            }
            if addTriangle(vertices) {
                assert(plane == nil || triangles.allSatisfy { $0.plane == plane })
                return triangles
            }
            triangles.removeAll()
        }
        let faceNormal = plane?.normal ?? faceNormalForPoints(vertices.map(\.position))
        var start = 0, i = 0
        outer: while start < vertices.count {
            var attempts = 0
            var vertices = vertices
            while vertices.count > 3 {
                let j = (i - 1 + vertices.count) % vertices.count
                let k = (i + 1) % vertices.count
                let p0 = vertices[j], p1 = vertices[i], p2 = vertices[k]
                let triangle = Polygon([p0, p1, p2], material: material)
                if triangle == nil || vertices.enumerated().contains(where: { index, v in
                    ![i, j, k].contains(index) && triangle!.intersects(v.position)
                }) || (triangle!.plane.normal.dot(faceNormal) <= 0) || !addTriangle([p0, p1, p2]) {
                    i += 1
                    if i == vertices.count {
                        i = 0
                        attempts += 1
                        if attempts > 2 {
                            triangles.removeAll()
                            start += 1
                            i = start
                            continue outer
                        }
                    }
                } else {
                    attempts = 0
                    vertices.remove(at: i)
                    if i == vertices.count {
                        i = 0
                    }
                }
            }
            if vertices.count == 3, addTriangle(vertices) || flipped {
                break
            }
            triangles.removeAll()
            start += 1
            i = start
        }
        if !flipped, triangles.isEmpty {
            return triangulatePossiblyNonPlanarVertices(
                vertices.inverted(),
                plane: plane?.inverted(),
                isConvex: isConvex,
                sanitizeNormals: sanitizeNormals,
                material: material,
                id: id,
                flipped: true
            ).inverted()
        }
        assert(plane == nil || triangles.allSatisfy { $0.plane == plane })
        return triangles
    }

    if vertices.count == 4, isConvex ?? verticesAreConvex(vertices) {
        // Preserve established quad diagonals for stable serialized output.
        return triangulatePossiblyNonPlanarVertices(
            vertices,
            plane: plane,
            isConvex: true,
            sanitizeNormals: sanitizeNormals,
            material: material,
            id: id,
            flipped: flipped
        )
    }

    var triangles = [Polygon]()
    func addTriangle(_ vertices: [Vertex]) -> Bool {
        guard !verticesAreDegenerate(vertices) else {
            return false
        }
        triangles.append(Polygon(
            unchecked: vertices,
            plane: plane,
            isConvex: true,
            sanitizeNormals: sanitizeNormals,
            material: material,
            id: id
        ))
        return true
    }

    struct Ear {
        let ringIndex: Int
        let previous: Int
        let current: Int
        let next: Int
        let score: Double
    }

    /// Returns the signed 2D area of a triangle in flattened polygon space.
    func signedArea(_ a: Vector, _ b: Vector, _ c: Vector) -> Double {
        (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
    }

    /// Checks whether a flattened point lies inside a flattened triangle.
    func containsPoint(_ point: Vector, inTriangle triangle: (Vector, Vector, Vector), winding: Double) -> Bool {
        let (a, b, c) = triangle
        let tolerance = -epsilon
        return signedArea(a, b, point) * winding >= tolerance &&
            signedArea(b, c, point) * winding >= tolerance &&
            signedArea(c, a, point) * winding >= tolerance
    }

    /// Scores a flattened triangle by compactness so ear clipping prefers less narrow triangles.
    func triangleScore(_ a: Vector, _ b: Vector, _ c: Vector) -> Double {
        let ab = (b - a).lengthSquared
        let bc = (c - b).lengthSquared
        let ca = (a - c).lengthSquared
        let area = abs(signedArea(a, b, c))
        let perimeterSquared = ab + bc + ca
        guard area > epsilon, perimeterSquared > epsilon else {
            return 0
        }
        return area / perimeterSquared
    }

    /// Triangulates via 2D projection, preferring compact ears over first-valid ears.
    func triangulateProjected() -> [[Int]] {
        let faceNormal = plane?.normal ?? faceNormalForPoints(vertices.map(\.position))
        let flatteningPlane = FlatteningPlane(normal: faceNormal)
        let points = vertices.map { flatteningPlane.flattenPoint($0.position) }
        let winding = flattenedPointsSignedArea(points)
        guard abs(winding) > epsilon else {
            return []
        }

        let windingSign = winding < 0 ? -1.0 : 1.0
        let knownConvex = isConvex ?? verticesAreConvex(vertices)

        func ear(previous: Int, current: Int, next: Int, ringIndex: Int) -> Ear? {
            let a = points[previous], b = points[current], c = points[next]
            guard signedArea(a, b, c) * windingSign > epsilon,
                  !verticesAreDegenerate([vertices[previous], vertices[current], vertices[next]])
            else {
                return nil
            }
            let score = triangleScore(a, b, c)
            guard score > 0 else {
                return nil
            }
            return Ear(ringIndex: ringIndex, previous: previous, current: current, next: next, score: score)
        }

        var ring = Array(vertices.indices)
        var result = [[Int]]()
        result.reserveCapacity(vertices.count - 2)

        func ear(at ringIndex: Int) -> Ear? {
            let count = ring.count
            let previousRingIndex = (ringIndex + count - 1) % count
            let nextRingIndex = (ringIndex + 1) % count
            let previous = ring[previousRingIndex]
            let current = ring[ringIndex]
            let next = ring[nextRingIndex]
            guard let ear = ear(previous: previous, current: current, next: next, ringIndex: ringIndex) else {
                return nil
            }
            if !knownConvex {
                let a = points[previous], b = points[current], c = points[next]
                for pointIndex in ring where pointIndex != previous && pointIndex != current && pointIndex != next {
                    if containsPoint(points[pointIndex], inTriangle: (a, b, c), winding: windingSign) {
                        return nil
                    }
                }
            }
            return ear
        }

        while ring.count > 3 {
            var bestEar: Ear?
            for ringIndex in ring.indices {
                guard let candidate = ear(at: ringIndex) else {
                    continue
                }
                guard let best = bestEar else {
                    bestEar = candidate
                    continue
                }
                if !candidate.score.isApproximatelyEqual(to: best.score) {
                    if candidate.score > best.score {
                        bestEar = candidate
                    }
                } else if candidate.ringIndex < best.ringIndex {
                    bestEar = candidate
                }
            }
            guard let bestEar else {
                return []
            }
            result.append([bestEar.previous, bestEar.current, bestEar.next])
            ring.remove(at: bestEar.ringIndex)
        }

        guard ring.count == 3 else {
            return []
        }
        result.append(ring)
        return result
    }

    let triangleIndices = triangulateProjected()
    for indices in triangleIndices {
        guard addTriangle(indices.map { vertices[$0] }) else {
            triangles.removeAll()
            break
        }
    }

    if triangles.isEmpty {
        // Keep the older 3D ear clipping as a fallback for numerically awkward boundaries.
        return triangulatePossiblyNonPlanarVertices(
            vertices,
            plane: plane,
            isConvex: isConvex,
            sanitizeNormals: sanitizeNormals,
            material: material,
            id: id,
            flipped: flipped
        )
    }
    assert(plane == nil || triangles.allSatisfy { $0.plane == plane })
    return triangles
}

// MARK: Vector utilities

extension [Vector] {
    /// A vector representation of the area of the polygon formed by the points
    /// Magnitude is polygon area; direction is polygon normal
    var vectorArea: Vector {
        guard count > 2, let a = first else {
            return .zero
        }
        var ab = self[1] - a
        return dropFirst(2).reduce(.zero) { area, c in
            let ac = c - a
            defer { ab = ac }
            return area + ab.cross(ac)
        } / 2
    }

    /// Signed volume of the polyhedron formed by connecting the points to the origin
    var signedVolume: Double {
        guard count > 2, let a = first else {
            return 0
        }
        var b = self[1]
        return dropFirst(2).reduce(0) { volume, c in
            defer { b = c }
            return volume + a.dot(b.cross(c))
        } / 6
    }

    /// Average position of the points, ignoring duplicate closing point
    var centroid: Vector {
        var last = last ?? .zero
        var count = count
        return reduce(.zero) { total, point in
            if point == last {
                count -= 1
                return total
            }
            last = point
            return total + point
        } / Double(Swift.max(1, count))
    }

    func removingAdjacentDuplicates() -> [Vector] {
        var result = [Vector]()
        for point in self where result.last?.isApproximatelyEqual(to: point) != true {
            result.append(point)
        }
        if result.count > 1, result[0].isApproximatelyEqual(to: result[result.count - 1]) {
            result.removeLast()
        }
        return result
    }
}

extension Vector {
    var leastParallelAxis: Vector {
        switch (abs(x), abs(y), abs(z)) {
        case let (x, y, z) where x <= y && x <= z:
            .unitX
        case let (_, y, z) where y <= z:
            .unitY
        default:
            .unitZ
        }
    }

    var mostParallelAxis: Vector {
        switch (abs(x), abs(y), abs(z)) {
        case let (x, y, z) where x > y && x > z:
            .unitX
        case let (x, y, z) where x > z || y > z:
            .unitY
        default:
            .unitZ
        }
    }

    func clampedToScaleLimit() -> Self {
        Self(x.clampedToScaleLimit(), y.clampedToScaleLimit(), z.clampedToScaleLimit())
    }
}

func isFlippedScale(_ scale: Vector) -> Bool {
    var flipped = scale.x < 0
    if scale.y < 0 { flipped = !flipped }
    if scale.z < 0 { flipped = !flipped }
    return flipped
}

func angleBetweenNormalizedVectors(_ v0: Vector, _ v1: Vector) -> Angle {
    assert(v0.isNormalized && v1.isNormalized)
    return .acos(v0.dot(v1))
}

func angleBetweenNormalizedVectorAndPlane(_ v: Vector, _ p: Plane) -> Angle {
    assert(v.isNormalized)
    return .asin(v.dot(p.normal))
}

func axisAndAngleBetweenNormalizedVectors(_ v0: Vector, _ v1: Vector) -> (axis: Vector, angle: Angle) {
    assert(v0.isNormalized && v1.isNormalized)
    let axis = v0.cross(v1)
    if axis != .zero {
        let cross = axis.length
        let angle = Angle.atan2(y: cross, x: v0.dot(v1))
        return (axis / -cross, angle: angle)
    } else if v0.isApproximatelyEqual(to: v1) {
        let identity = Rotation.identity
        return (identity.axis, identity.angle)
    } else {
        let orthonormal = v0.cross(v0.leastParallelAxis).normalized()
        return (orthonormal, .pi)
    }
}

func rotationBetweenNormalizedVectors(_ v0: Vector, _ v1: Vector) -> Rotation {
    let (axis, angle) = axisAndAngleBetweenNormalizedVectors(v0, v1)
    return Rotation(unchecked: axis, angle: angle)
}

func pointsAreDegenerate(_ points: [Vector]) -> Bool {
    let count = points.count
    guard count > 2, var a = points.last else {
        return false
    }
    var ab = (points[0] - a).normalized()
    for i in 0 ..< count {
        let b = points[i]
        let c = points[(i + 1) % count]
        if b == c || a == b {
            return true
        }
        let bc = (c - b).normalized()
        guard abs(ab.dot(bc) + 1) > 0 else {
            return true
        }
        a = b
        ab = bc
    }
    return false
}

/// Returns true if the three points lie on the same line.
func pointsAreCollinear(_ a: Vector, _ b: Vector, _ c: Vector) -> Bool {
    let ab = b - a
    let bc = c - b
    let scale = ab.lengthSquared * bc.lengthSquared
    guard scale > epsilon else {
        return false
    }
    return ab.cross(bc).lengthSquared / scale < epsilon
}

/// Note: assumes points are not degenerate and do not contain duplicates
func pointsAreConvex(_ points: [Vector]) -> Bool {
    assert(!pointsAreClosed(unchecked: points))
    let count = points.count
    guard count > 3, let a = points.last else {
        return count > 2
    }
    var normal: Vector?
    var ab = points[0] - a
    for i in 0 ..< count {
        let b = points[i]
        let c = points[(i + 1) % count]
        let bc = c - b
        var n = ab.cross(bc)
        let length = n.length
        // check result is large enough to be reliable
        if length > planeEpsilon {
            n = n / length
            if let normal {
                if n.dot(normal) < 0 {
                    return false
                }
            } else {
                normal = n
            }
        }
        ab = bc
    }
    return true
}

// Test if path is self-intersecting
// TODO: optimize by using http://www.webcitation.org/6ahkPQIsN
func pointsAreSelfIntersecting(_ points: [Vector], isClosed: Bool? = nil) -> Bool {
    let isClosed = isClosed ?? pointsAreClosed(unchecked: points)
    let points = isClosed && !pointsAreClosed(unchecked: points) ? points + [points[0]] : points
    guard points.count > 3 else {
        // A triangle can't be self-intersecting (is this true?)
        return false
    }
    for i in 0 ..< points.count - 2 {
        let p0 = points[i], p1 = points[i + 1]
        guard let l1 = LineSegment(start: p0, end: p1) else {
            continue
        }
        for j in i + 2 ..< points.count - 1 {
            guard !isClosed || i != 0 || j != points.count - 2 else {
                continue
            }
            let p2 = points[j], p3 = points[j + 1]
            let tolerance = 1e-6
            guard !p1.isApproximatelyEqual(to: p2, absoluteTolerance: tolerance),
                  !p1.isApproximatelyEqual(to: p3, absoluteTolerance: tolerance),
                  !p0.isApproximatelyEqual(to: p2, absoluteTolerance: tolerance),
                  !p0.isApproximatelyEqual(to: p3, absoluteTolerance: tolerance),
                  let l2 = LineSegment(start: p2, end: p3)
            else {
                continue
            }
            if l1.intersects(l2) {
                return true
            }
        }
    }
    return false
}

/// Computes the face normal for a collection of points
/// Points are assumed to be ordered in a counter-clockwise direction
/// Points are not required to be coplanar or non-degenerate
/// Points are not required to form a convex polygon
func faceNormalForPoints(_ points: [Vector]) -> Vector {
    // Try vectorArea first (Newell's method)
    let vectorArea = points.vectorArea
    if let normal = vectorArea.direction {
        return normal
    }

    // If vectorArea is zero or near-zero, normal will not be reliable
    // Instead we'll use a modified version of Newell's method
    if points.count > 2, let a = points.first {
        var ab = points[1] - a
        let vectorArea: Vector = points.dropFirst(2).reduce(.zero) { area, c in
            let ac = c - a
            defer { ab = ac }
            let cross = ab.cross(ac)
            if area.dot(cross) < 0 {
                return area - cross
            } else {
                return area + cross
            }
        }
        if let normal = vectorArea.direction {
            return normal
        }
    }

    // Points must be linear, so find what line they lie on
    // and then return the orthogonal vector to that one
    let ab = points.count > 1 ? points[1] - points[0] : .zero
    if let normal = ab.cross(.unitZ).cross(ab).direction {
        return normal
    }

    // Points lie along z axis
    return .unitY
}

func flattenedPointsSignedArea(_ points: [Vector]) -> Double {
    assert(!points.contains(where: { $0.z != 0 }))
    let points = pointsAreClosed(unchecked: points) ? Array(points.dropLast()) : points
    guard points.count > 2 else {
        return 0
    }
    return points.vectorArea.z
}

func flattenedPointsAreClockwise(_ points: [Vector]) -> Bool {
    flattenedPointsSignedArea(points) < 0
}

func pointsAreClockwise(_ points: [Vector], relativeTo axis: Vector) -> Bool {
    assert(axis.isNormalized)
    return faceNormalForPoints(points).dot(axis) < 0
}

func pointsAreClosed(unchecked points: [Vector]) -> Bool {
    points.last == points.first
}

// MARK: Curve utilities

func quadraticBezier(_ p0: Double, _ p1: Double, _ p2: Double, _ t: Double) -> Double {
    let oneMinusT = 1 - t
    let c0 = oneMinusT * oneMinusT * p0
    let c1 = 2 * oneMinusT * t * p1
    let c2 = t * t * p2
    return c0 + c1 + c2
}

func cubicBezier(_ p0: Double, _ p1: Double, _ p2: Double, _ p3: Double, _ t: Double) -> Double {
    let oneMinusT = 1 - t
    let oneMinusTSquared = oneMinusT * oneMinusT
    let c0 = oneMinusTSquared * oneMinusT * p0
    let c1 = 3 * oneMinusTSquared * t * p1
    let c2 = 3 * oneMinusT * t * t * p2
    let c3 = t * t * t * p3
    return c0 + c1 + c2 + c3
}

// MARK: Line utilities

/// Shortest line segment between two lines
/// http://paulbourke.net/geometry/pointlineplane/
func shortestLineBetween(
    _ p1: Vector,
    _ p2: Vector,
    _ aIsSegment: Bool,
    _ p3: Vector,
    _ p4: Vector,
    _ bIsSegment: Bool
) -> (Vector, Vector)? {
    let v12 = p2 - p1
    assert(v12.length > 0)
    let v34 = p4 - p3
    assert(v34.length > 0)
    let v31 = p1 - p3

    let d3134 = v31.dot(v34)
    let d3412 = v34.dot(v12)
    let d3434 = v34.dot(v34) // length squared
    let d1212 = v12.dot(v12) // length squared
    let denominator = d1212 * d3434 - d3412 * d3412

    // Closest point along v12
    var mua = 0.0
    if denominator != 0 {
        let numerator = d3134 * d3412 - v31.dot(v12) * d3434
        mua = numerator / denominator
    }

    // Closest point along v34
    var mub = (d3134 + d3412 * mua) / d3434

    if aIsSegment { mua.clamp(to: 0 ... 1) }
    if bIsSegment { mub.clamp(to: 0 ... 1) }

    return (p1 + mua * v12, p3 + mub * v34)
}

func lineIntersection(
    _ p0: Vector,
    _ p1: Vector,
    _ aIsSegment: Bool,
    _ p2: Vector,
    _ p3: Vector,
    _ bIsSegment: Bool
) -> Vector? {
    shortestLineBetween(
        p0, p1, aIsSegment,
        p2, p3, bIsSegment
    ).flatMap {
        $0.isApproximatelyEqual(to: $1) ? $0 : nil
    }
}

/// Returns distance of plane intersection along a line (or nil if parallel)
func linePlaneIntersection(_ origin: Vector, _ direction: Vector, _ plane: Plane) -> Double? {
    // TODO: optimize for axis-aligned plane
    // https://en.wikipedia.org/wiki/Line–plane_intersection#Algebraic_form
    let lineDotPlaneNormal = direction.dot(plane.normal)
    guard lineDotPlaneNormal != 0 else {
        // Line and plane are parallel
        return nil
    }
    let planeOrigin = plane.normal * plane.w
    return (planeOrigin - origin).dot(plane.normal) / lineDotPlaneNormal
}

// MARK: Plane utilities

extension Collection<Plane> {
    /// Finds the least-squares intersection point for a set of planes.
    var bestFitIntersection: Vector? {
        var xColumn = Vector.zero
        var yColumn = Vector.zero
        var zColumn = Vector.zero
        var offset = Vector.zero
        for plane in self {
            let normal = plane.normal
            xColumn += normal * normal.x
            yColumn += normal * normal.y
            zColumn += normal * normal.z
            offset += normal * plane.w
        }
        let determinant = xColumn.dot(yColumn.cross(zColumn))
        guard abs(determinant) > epsilon else {
            return nil
        }
        return Vector(
            offset.dot(yColumn.cross(zColumn)) / determinant,
            xColumn.dot(offset.cross(zColumn)) / determinant,
            xColumn.dot(yColumn.cross(offset)) / determinant
        )
    }
}

// MARK: Path utilities

extension Collection<PathPoint> {
    /// A vector representation of the area of the polygon formed by the points
    /// Magnitude is polygon area; direction is polygon normal
    var vectorArea: Vector {
        map(\.position).vectorArea
    }

    /// Average position of the points, ignoring duplicate closing point
    var centroid: Vector {
        map(\.position).centroid
    }

    /// Returns the ordered array of path edges
    var orderedEdges: [LineSegment] {
        var p0 = first?.position
        return dropFirst().compactMap {
            let p1 = $0.position
            defer { p0 = p1 }
            return LineSegment(start: p0!, end: p1)
        }
    }
}

/// Sanitize a set of path points by removing duplicates and invalid points
/// Should be safe to use on sets of points representing a compound path (with subpaths)
func sanitizePoints(_ points: some Collection<PathPoint>) -> [PathPoint] {
    var result = [PathPoint]()
    // Remove duplicate points
    // TODO: In future, compound paths may support duplicate points
    for point in points {
        if let last = result.last, point.position == last.position {
            if !point.isCurved, last.isCurved {
                result[result.count - 1].isCurved = false
            }
        } else {
            result.append(point)
        }
    }
    // Remove invalid points
    var pointsWereRemoved = false
    let isClosed = pointsAreClosed(unchecked: result)
    if result.count > (isClosed ? 3 : 2), let a = result.first?.position {
        var ab = result[1].position - a
        var i = 1
        while i < result.count - 1 {
            let bc = result[i + 1].position - result[i].position
            if ab.cross(bc).isZero, ab.dot(bc) < epsilon {
                // center point makes path degenerate - remove it
                result.remove(at: i)
                pointsWereRemoved = true
                ab = result[i].position - result[i - 1].position
                continue
            }
            i += 1
            ab = bc
        }
    }
    if pointsWereRemoved {
        // Removing points may result in neighboring duplicates
        return sanitizePoints(result)
    }
    // Ensure closed path start and end match
    if isClosed {
        if result.count == 2 {
            return [result[0]]
        }
        if result.first != result.last {
            result[0] = result.last!
        }
    }
    return result
}

func subpathsFor(_ _points: [PathPoint]) -> [Path] {
    let subpathIndices = subpathIndicesFor(_points)

    var startIndex = 0
    var paths = [Path]()
    for i in subpathIndices {
        var points = _points[startIndex ... i]
        // Avoid duplicate first point in loop
        if paths.last?.isClosed ?? false, points.count > 2,
           points[startIndex + 1].position == points.last?.position
        {
            points.removeFirst()
        }
        startIndex = i
        guard points.count > 1 else {
            continue
        }
        // Ensure offshoots are properly separated
        if i < _points.count - 1 {
            let next = _points[i + 1]
            if points.contains(where: { $0.position == next.position }) {
                startIndex += 1
            }
        }
        // TODO: support internal one-element line segments
        guard points.count > 2 || points.startIndex == 0 || i == _points.count - 1 else {
            continue
        }
        // TODO: do this as part of regular sanitization step?
        if points.last?.position == points.first?.position {
            points[points.startIndex] = points.last!
        }
        paths.append(Path(unchecked: .points(sanitizePoints(points)), plane: nil))
    }
    return paths.isEmpty && !_points.isEmpty ? [
        Path(unchecked: .points(sanitizePoints(_points)), plane: nil),
    ] : paths
}

/// Finds repeated-point boundaries that split a point array into subpaths.
private func subpathIndicesFor(_ points: [PathPoint]) -> [Int] {
    // TODO: ensure closing points are of the same type as the opening point;
    // should this be part of the sanitize function?
    var lastIndex = 0
    var indices = [Int]()
    for (i, p) in points.enumerated() {
        for j in lastIndex ..< i {
            if points[j].position == p.position {
                if j > lastIndex, j < i - 1 {
                    indices.append(j)
                }
                indices.append(i)
                lastIndex = i + 1
                break
            }
        }
    }
    if !indices.isEmpty, indices.last != points.count - 1 {
        indices.append(points.count - 1)
        return indices
    }
    // If only one path, return an empty array
    return indices.count > 1 ? indices : []
}

func pointsAreClosed(unchecked points: [PathPoint]) -> Bool {
    points.last?.position == points.first?.position
}

func extrapolate(_ p0: PathPoint, _ p1: PathPoint, _ p2: PathPoint) -> PathPoint {
    let (length, p0p1) = (p1.position - p0.position).lengthAndDirection
    guard let p0p1, let p1p2 = (p2.position - p1.position).direction else {
        return .curve(p2.position)
    }
    let r = rotationBetweenNormalizedVectors(p0p1, p1p2)
    let p2pe = p1p2.rotated(by: r) * length
    return .curve(p2.position + p2pe)
}

func extrapolate(_ p0: PathPoint, _ p1: PathPoint) -> PathPoint {
    let p0p1 = p1.position - p0.position
    return .point(p1.position + p0p1)
}

/// Finds opposing source edges that would cross after both are inset by the specified distance.
func firstCollapsedInsetEdgePair(in sourcePoints: [Vector], by distance: Double) -> (Int, Int)? {
    let count = sourcePoints.count
    guard count > 3 else {
        return nil
    }
    let winding = sourcePoints.vectorArea.z >= 0 ? 1.0 : -1.0

    func edgesAreAdjacent(_ a: Int, _ b: Int) -> Bool {
        abs(a - b) == 1 || (a == 0 && b == count - 1)
    }

    for i in 0 ..< count {
        let p0 = sourcePoints[i], p1 = sourcePoints[(i + 1) % count]
        let edge = p1 - p0
        guard edge.length > epsilon else {
            continue
        }
        let direction = edge.normalized()
        let inward = Vector(-direction.y, direction.x) * winding

        for j in i + 1 ..< count where !edgesAreAdjacent(i, j) {
            let q0 = sourcePoints[j], q1 = sourcePoints[(j + 1) % count]
            let otherEdge = q1 - q0
            guard otherEdge.length > epsilon else {
                continue
            }
            let otherDirection = otherEdge.normalized()
            guard direction.dot(otherDirection) < -1 + planeEpsilon else {
                continue
            }
            let otherInward = Vector(-otherDirection.y, otherDirection.x) * winding
            guard inward.dot(otherInward) < -1 + planeEpsilon,
                  inward.dot(q0 - p0) > 0,
                  otherInward.dot(p0 - q0) > 0
            else {
                continue
            }
            let separation = abs((q0 - p0).dot(inward))
            guard separation <= distance * 2 + epsilon else {
                continue
            }
            let projected0 = 0.0 ... edge.length
            let projected1 = [q0, q1].map { ($0 - p0).dot(direction) }
            guard projected0.upperBound > projected1.min()! + epsilon,
                  projected1.max()! > projected0.lowerBound + epsilon
            else {
                continue
            }
            return (i, j)
        }
    }
    return nil
}

func resolveInsetIntersections<T>(
    in points: [T],
    isClosed: Bool,
    normal: Vector?,
    collapsedDistance: Double? = nil,
    position: (T) -> Vector,
    interpolate: (T, T, Double) -> T
) -> [T] {
    var points = points
    if isClosed, points.count > 1,
       position(points[0]) == position(points[points.count - 1])
    {
        points.removeLast()
    }
    while let intersection = firstInsetIntersection(
        in: points,
        isClosed: isClosed,
        position: position
    ) {
        let point = interpolate(
            points[intersection.i],
            points[(intersection.i + 1) % points.count],
            intersection.t
        )
        points.replaceSubrange(intersection.i + 1 ... intersection.j, with: [point])
        if points.count < (isClosed ? 3 : 2) {
            return []
        }
    }
    if let collapsedDistance {
        points = removeCollapsedInsetVertices(
            from: points,
            isClosed: isClosed,
            collapsedDistance: collapsedDistance,
            position: position
        )
    }
    guard !isClosed else {
        guard normal.map({ faceNormalForPoints(points.map(position)).dot($0) > 0 }) ?? true,
              let first = points.first
        else {
            return []
        }
        return points + [first]
    }
    return points
}

/// Removes near-180-degree inset vertices left behind by collapsed joins.
private func removeCollapsedInsetVertices<T>(
    from points: [T],
    isClosed: Bool,
    collapsedDistance: Double,
    position: (T) -> Vector
) -> [T] {
    let minimumCount = isClosed ? 3 : 2
    guard points.count > minimumCount else {
        return points
    }
    var points = points
    let collapsedVertexDotLimit = -0.5
    var i = isClosed ? 0 : 1
    while points.count > minimumCount, i < (isClosed ? points.count : points.count - 1) {
        let previous = position(points[(i + points.count - 1) % points.count])
        let current = position(points[i])
        let next = position(points[(i + 1) % points.count])
        let edgeA = current - previous
        let edgeB = next - current
        let directionA = edgeA.normalized()
        let directionB = edgeB.normalized()
        guard directionA != .zero, directionB != .zero else {
            points.remove(at: i)
            i = max(isClosed ? 0 : 1, i - 1)
            continue
        }
        if directionA.dot(directionB) < collapsedVertexDotLimit,
           min(edgeA.length, edgeB.length) <= collapsedDistance
        {
            points.remove(at: i)
            i = max(isClosed ? 0 : 1, i - 1)
            continue
        }
        i += 1
    }
    return points
}

/// Finds the first non-adjacent edge crossing in an inset point sequence.
private func firstInsetIntersection<T>(
    in points: [T],
    isClosed: Bool,
    position: (T) -> Vector
) -> (i: Int, j: Int, t: Double)? {
    let edgeCount = isClosed ? points.count : points.count - 1
    guard edgeCount > 2 else {
        return nil
    }
    func insetEdgesAreAdjacent(_ a: Int, _ b: Int, edgeCount: Int, isClosed: Bool) -> Bool {
        abs(a - b) == 1 || (isClosed && a == 0 && b == edgeCount - 1)
    }
    for i in 0 ..< edgeCount {
        let a0 = position(points[i])
        let a1 = position(points[(i + 1) % points.count])
        for j in i + 1 ..< edgeCount where !insetEdgesAreAdjacent(i, j, edgeCount: edgeCount, isClosed: isClosed) {
            let b0 = position(points[j])
            let b1 = position(points[(j + 1) % points.count])
            guard let p = lineIntersection(a0, a1, true, b0, b1, true),
                  !p.isApproximatelyEqual(to: a0),
                  !p.isApproximatelyEqual(to: a1),
                  !p.isApproximatelyEqual(to: b0),
                  !p.isApproximatelyEqual(to: b1)
            else {
                continue
            }
            return (i, j, a0.distance(from: p) / a0.distance(from: a1))
        }
    }
    return nil
}

// MARK: Coding

/// Protocol for types that can be encoded directly into an unkeyed
/// buffer. Typically applies to vectors with a fixed size.
protocol UnkeyedCodable {
    /// Decode directly from an unkeyedContainer
    init(from container: inout UnkeyedDecodingContainer) throws
    /// Encode directly into an unkeyedContainer
    func encode(to container: inout UnkeyedEncodingContainer) throws
}

// MARK: Data

final class Buffer {
    private(set) var buffer: UnsafeMutablePointer<UInt8>
    let capacity: Int
    var count: Int = 0 {
        didSet { assert((0 ... capacity).contains(count)) }
    }

    init(capacity: Int) {
        self.capacity = capacity
        self.buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: capacity)
        buffer.initialize(repeating: 0, count: capacity)
    }

    deinit {
        buffer.deallocate()
    }

    func append(_ int: UInt16) {
        assert(count <= capacity - 2)
        var int = int
        withUnsafeMutablePointer(to: &int) {
            let pointer = $0.withMemoryRebound(to: UInt8.self, capacity: 2) { $0 }
            for i in 0 ..< 2 {
                buffer[count] = pointer[i]
                count += 1
            }
        }
    }

    func append(_ int: UInt32) {
        assert(count <= capacity - 4)
        var int = int
        withUnsafeMutablePointer(to: &int) {
            let pointer = $0.withMemoryRebound(to: UInt8.self, capacity: 4) { $0 }
            for i in 0 ..< 4 {
                buffer[count] = pointer[i]
                count += 1
            }
        }
    }

    func append(_ float: Float) {
        append(float.bitPattern)
    }
}

extension Data {
    init(_ buffer: Buffer) {
        // TODO: any way to avoid the copy here?
        self.init(bytes: buffer.buffer, count: buffer.count)
    }
}

// MARK: Parallel processing

#if canImport(Dispatch) && !arch(wasm32)

import Dispatch

private let minBatchCount = 2
private let cpuCores = ProcessInfo.processInfo.activeProcessorCount

func batch<T: Sendable, U>(
    _ elements: [T],
    stride minBatchSize: Int,
    fn: @Sendable ([T]) -> [U]
) -> [U] {
    let batchCount = min(max(elements.count / minBatchSize, 1), cpuCores * 3, 24)
    let batchSize = Int(ceil(Double(elements.count) / Double(batchCount)))
    if batchCount < minBatchCount || batchSize < minBatchSize {
        return fn(elements)
    }
    #if DEBUG
    print("batch: \(batchSize)×\(batchCount)/\(cpuCores)")
    #endif
    let parts = stride(from: 0, to: elements.count, by: batchSize).map {
        Array(elements[$0 ..< min($0 + batchSize, elements.count)])
    }
    nonisolated(unsafe)
    var a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x: [U]?
    DispatchQueue.concurrentPerform(iterations: parts.count) { index in
        let result = fn(parts[index])
        switch index {
        case 0: a = result
        case 1: b = result
        case 2: c = result
        case 3: d = result
        case 4: e = result
        case 5: f = result
        case 6: g = result
        case 7: h = result
        case 8: i = result
        case 9: j = result
        case 10: k = result
        case 11: l = result
        case 12: m = result
        case 13: n = result
        case 14: o = result
        case 15: p = result
        case 16: q = result
        case 17: r = result
        case 18: s = result
        case 19: t = result
        case 20: u = result
        case 21: v = result
        case 22: w = result
        case 23: x = result
        default: preconditionFailure()
        }
    }
    let z = [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x]
    return z[..<parts.count].flatMap { $0! }
}

#else

func batch<T, U>(
    _ elements: [T],
    stride _: Int,
    fn: ([T]) -> [U]
) -> [U] {
    fn(elements)
}

#endif
