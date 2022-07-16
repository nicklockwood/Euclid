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

// Tolerance used for calculating approximate equality
let epsilon = 1e-8

// Smallest valid scale factor
let scaleLimit = 1e-8

// Round-off floating point values to simplify equality checks
func quantize(_ value: Double) -> Double {
    let precision = 1e-12
    return (value / precision).rounded() * precision
}

extension Double {
    func isEqual(to other: Double, withPrecision p: Double) -> Bool {
        self == other || abs(self - other) < p
    }
}

// MARK: Vertex utilities

func verticesAreDegenerate(_ vertices: [Vertex]) -> Bool {
    guard vertices.count > 2 else {
        return true
    }
    let positions = vertices.map { $0.position }
    return pointsAreDegenerate(positions) || pointsAreSelfIntersecting(positions)
}

func verticesAreConvex(_ vertices: [Vertex]) -> Bool {
    guard vertices.count > 3 else {
        return vertices.count > 2
    }
    return pointsAreConvex(vertices.map { $0.position })
}

func verticesAreCoplanar(_ vertices: [Vertex]) -> Bool {
    if vertices.count < 4 {
        return true
    }
    return pointsAreCoplanar(vertices.map { $0.position })
}

func triangulateVertices(
    _ vertices: [Vertex],
    plane: Plane?,
    isConvex: Bool?,
    material: Mesh.Material?,
    id: Int
) -> [Polygon] {
    guard vertices.count > 3 else {
        guard vertices.count > 2 else {
            return []
        }
        return [Polygon(
            unchecked: vertices,
            plane: plane,
            isConvex: isConvex,
            material: material,
            id: id
        )]
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
            material: material,
            id: id
        ))
        return true
    }
    let positions = vertices.map { $0.position }
    let isConvex = isConvex ?? pointsAreConvex(positions)
    if !isConvex {
        // Note: this solves a problem when anticlockwise-ordered concave polygons
        // would be incorrectly triangulated. However it's not clear why this is
        // necessary, or if it will do the correct thing in all circumstances
        let flatteningPlane = FlatteningPlane(
            normal: plane?.normal ??
                faceNormalForPolygonPoints(positions, convex: false)
        )
        let flattenedPoints = vertices.map { flatteningPlane.flattenPoint($0.position) }
        let isClockwise = flattenedPointsAreClockwise(flattenedPoints)
        if !isClockwise {
            guard flattenedPointsAreClockwise(flattenedPoints.reversed()) else {
                // Points are self-intersecting, or otherwise degenerate
                return []
            }
            return triangulateVertices(
                vertices.reversed().map { $0.inverted() },
                plane: plane?.inverted(),
                isConvex: isConvex,
                material: material,
                id: id
            ).inverted()
        }
    }
    var start = 0, i = 0
    outer: while start < vertices.count {
        var attempts = 0
        var vertices = vertices
        func removeVertex() {
            attempts = 0
            vertices.remove(at: i)
            if i == vertices.count {
                i = 0
            }
        }
        while vertices.count > 3 {
            let j = (i - 1 + vertices.count) % vertices.count
            let k = (i + 1) % vertices.count
            let p0 = vertices[j], p1 = vertices[i], p2 = vertices[k]
            let triangle = Polygon([p0, p1, p2])
            if triangle == nil || vertices.enumerated().contains(where: { index, v in
                ![i, j, k].contains(index) && triangle!.containsPoint(v.position)
            }) || plane.map({ triangle!.plane.normal.dot($0.normal) <= 0 }) ?? false {
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
            } else if addTriangle(triangle!.vertices) {
                removeVertex()
            }
        }
        if addTriangle(vertices) {
            break
        }
        triangles.removeAll()
        start += 1
        i = start
    }
//    assert(triangles.count == vertices.count - 2)
    return triangles
}

// MARK: Vector utilities

func rotationBetweenVectors(_ v0: Vector, _ v1: Vector) -> Rotation {
    let axis = v0.cross(v1)
    let length = axis.length
    if length < epsilon {
        return .identity
    }
    let angle = v0.angle(with: v1)
    return Rotation(unchecked: axis / length, angle: angle)
}

func vectorsAreCollinear(_ v0: Vector, _ v1: Vector) -> Bool {
    v0.cross(v1).isEqual(to: .zero, withPrecision: epsilon)
}

func pointsAreCollinear(_ a: Vector, _ b: Vector, _ c: Vector) -> Bool {
    vectorsAreCollinear(b - a, c - a)
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

// Note: assumes points are not degenerate
func pointsAreConvex(_ points: [Vector]) -> Bool {
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
        if length > epsilon {
            n = n / length
            if let normal = normal {
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
func pointsAreSelfIntersecting(_ points: [Vector]) -> Bool {
    guard points.count > 2 else {
        // A triangle can't be self-intersecting
        return false
    }
    for i in 0 ..< points.count - 2 {
        let p0 = points[i], p1 = points[i + 1]
        guard let l1 = LineSegment(p0, p1) else {
            continue
        }
        for j in i + 2 ..< points.count - 1 {
            let p2 = points[j], p3 = points[j + 1]
            guard !p1.isEqual(to: p2), !p1.isEqual(to: p3),
                  !p0.isEqual(to: p2), !p0.isEqual(to: p3),
                  let l2 = LineSegment(p2, p3)
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

// Computes the face normal for a collection of points
// Points are assumed to be ordered in a counter-clockwise direction
// Points are not verified to be coplanar or non-degenerate
// Points are not required to form a convex polygon
func faceNormalForPolygonPoints(_ points: [Vector], convex: Bool?) -> Vector {
    let count = points.count
    let unitZ = Vector(0, 0, 1)
    switch count {
    case 0, 1:
        return unitZ
    case 2:
        let ab = points[1] - points[0]
        let normal = ab.cross(unitZ).cross(ab)
        let length = normal.length
        guard length > 0 else {
            // Points lie along z axis
            return Vector(1, 0, 0)
        }
        return normal / length
    default:
        func faceNormalForConvexPoints(_ points: [Vector]) -> Vector {
            let count = points.count
            var b = points[count - 1]
            var ab = b - points[count - 2]
            var bestLengthSquared = 0.0
            var best: Vector?
            for c in points {
                let bc = c - b
                let normal = ab.cross(bc)
                let lengthSquared = normal.lengthSquared
                if lengthSquared > bestLengthSquared {
                    bestLengthSquared = lengthSquared
                    best = normal / lengthSquared.squareRoot()
                }
                b = c
                ab = bc
            }
            return best ?? Vector(0, 0, 1)
        }
        let normal = faceNormalForConvexPoints(points)
        let convex = convex ?? pointsAreConvex(points)
        if !convex {
            let flatteningPlane = FlatteningPlane(normal: normal)
            let flattenedPoints = points.map { flatteningPlane.flattenPoint($0) }
            let flattenedNormal = faceNormalForConvexPoints(flattenedPoints)
            let isClockwise = flattenedPointsAreClockwise(flattenedPoints)
            if (flattenedNormal.z > 0) == isClockwise {
                return -normal
            }
        }
        return normal
    }
}

func pointsAreCoplanar(_ points: [Vector]) -> Bool {
    if points.count < 4 {
        return true
    }
    let b = points[1]
    let ab = b - points[0]
    let bc = points[2] - b
    let normal = ab.cross(bc)
    let length = normal.length
    if length < epsilon {
        return false
    }
    let plane = Plane(unchecked: normal / length, pointOnPlane: b)
    for p in points[3...] where !plane.containsPoint(p) {
        return false
    }
    return true
}

// https://stackoverflow.com/questions/1165647/how-to-determine-if-a-list-of-polygon-points-are-in-clockwise-order#1165943
func flattenedPointsAreClockwise(_ points: [Vector]) -> Bool {
    assert(!points.contains(where: { $0.z != 0 }))
    let points = (points.first == points.last) ? points.dropLast() : [Vector].SubSequence(points)
    guard points.count > 2, var a = points.last else {
        return false
    }
    var sum = 0.0
    for b in points {
        sum += (b.x - a.x) * (b.y + a.y)
        a = b
    }
    // abs(sum / 2) is the area of the polygon
    return sum > 0
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

// Shortest line segment between two lines
// http://paulbourke.net/geometry/pointlineplane/
func shortestLineBetween(
    _ p1: Vector,
    _ p2: Vector,
    _ p3: Vector,
    _ p4: Vector
) -> (Vector, Vector)? {
    let p21 = p2 - p1
    assert(p21.length > 0)
    let p43 = p4 - p3
    assert(p43.length > 0)
    let p13 = p1 - p3

    let d1343 = p13.dot(p43)
    let d4321 = p43.dot(p21)
    let d1321 = p13.dot(p21)
    let d4343 = p43.dot(p43)
    let d2121 = p21.dot(p21)

    let denominator = d2121 * d4343 - d4321 * d4321
    guard abs(denominator) > epsilon else {
        // Lines are coincident
        return nil
    }

    let numerator = d1343 * d4321 - d1321 * d4343
    let mua = numerator / denominator
    let mub = (d1343 + d4321 * mua) / d4343

    return (p1 + mua * p21, p3 + mub * p43)
}

// See "Vector formulation" at https://en.wikipedia.org/wiki/Distance_from_a_point_to_a_line
func vectorFromPointToLine(
    _ point: Vector,
    _ lineOrigin: Vector,
    _ lineDirection: Vector
) -> Vector {
    assert(lineDirection.isNormalized)
    let d = point - lineOrigin
    return lineDirection * d.dot(lineDirection) - d
}

func lineIntersection(
    _ p0: Vector,
    _ p1: Vector,
    _ p2: Vector,
    _ p3: Vector
) -> Vector? {
    guard let (p0, p1) = shortestLineBetween(p0, p1, p2, p3) else {
        return nil
    }
    return p0.isEqual(to: p1) ? p0 : nil
}

func lineSegmentsIntersection(
    _ p0: Vector,
    _ p1: Vector,
    _ p2: Vector,
    _ p3: Vector
) -> Vector? {
    guard let pi = lineIntersection(p0, p1, p2, p3) else {
        return nil // lines don't intersect
    }
    return Bounds(p0, p1).containsPoint(pi) && Bounds(p2, p3).containsPoint(pi) ? pi : nil
}

// MARK: Path utilities

// Sanitize a set of path points by removing duplicates and invalid points
// Should be safe to use on sets of points representing a compound path (with subpaths)
func sanitizePoints(_ points: [PathPoint]) -> [PathPoint] {
    var result = [PathPoint]()
    var last: PathPoint?
    // Remove duplicate points
    // TODO: In future, compound paths may support duplicate points
    for point in points where point.position != last?.position {
        result.append(point)
        last = point
    }
    // Remove invalid points
    let isClosed = pointsAreClosed(unchecked: result)
    if result.count > (isClosed ? 3 : 2), let a = result.first?.position {
        var ab = result[1].position - a
        var i = 1
        while i < result.count - 1 {
            let bc = result[i + 1].position - result[i].position
            if ab.cross(bc).isEqual(to: .zero), ab.dot(bc) < epsilon {
                // center point makes path degenerate - remove it
                result.remove(at: i)
                ab = result[i].position - result[i - 1].position
                continue
            }
            i += 1
            ab = bc
        }
    }
    // Ensure closed path start and end match
    if isClosed {
        if result.first != result.last {
            result[0] = result.last!
        }
        if result.count < 3 {
            return []
        }
    } else if result.count < 2 {
        return []
    }
    return result
}

func subpathIndicesFor(_ points: [PathPoint]) -> [Int] {
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
                lastIndex = i
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
    var p0p1 = p1.position - p0.position
    let length = p0p1.length
    p0p1 = p0p1 / length
    let p1p2 = (p2.position - p1.position).normalized()
    let axis = p0p1.cross(p1p2)
    let angle = -p0p1.angle(with: p1p2)
    let r = Rotation(axis: axis, angle: angle) ?? .identity
    let p2pe = p1p2.rotated(by: r) * length
    return .curve(p2.position + p2pe)
}

func extrapolate(_ p0: PathPoint, _ p1: PathPoint) -> PathPoint {
    let p0p1 = p1.position - p0.position
    return .point(p1.position + p0p1)
}
