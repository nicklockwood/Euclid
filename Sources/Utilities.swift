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
let epsilon = 1e-6

// Round-off floating point values to simplify equality checks
func quantize(_ value: Double) -> Double {
    let precision = 1e-8 * 1e-3
    return (value / precision).rounded() * precision
}

// MARK: Vertex utilities

func verticesAreDegenerate(_ vertices: [Vertex]) -> Bool {
    guard vertices.count > 1 else {
        return false
    }
    return pointsAreDegenerate(vertices.map { $0.position })
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

func faceNormalForConvexVertices(_ vertices: [Vertex]) -> Vector? {
    assert(verticesAreConvex(vertices))
    return faceNormalForConvexPoints(vertices.map { $0.position })
}

func faceNormalForConvexVertices(unchecked vertices: [Vertex]) -> Vector {
    let ab = vertices[1].position - vertices[0].position
    let bc = vertices[2].position - vertices[1].position
    let normal = ab.cross(bc)
    assert(normal.length > epsilon)
    return normal.normalized()
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

func pointsAreDegenerate(_ points: [Vector]) -> Bool {
    let threshold = 1e-10
    let count = points.count
    guard count > 1, let a = points.last else {
        return false
    }
    var ab = points[0] - a
    var length = ab.length
    guard length > threshold else {
        return true
    }
    ab = ab / length
    for i in 0 ..< count {
        let b = points[i]
        let c = points[(i + 1) % count]
        var bc = c - b
        length = bc.length
        guard length > threshold else {
            return true
        }
        bc = bc / length
        guard abs(ab.dot(bc) + 1) > threshold else {
            return true
        }
        ab = bc
    }
    return false
}

func pointsAreConvex(_ points: [Vector]) -> Bool {
    assert(!pointsAreDegenerate(points))
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

func faceNormalForConvexPoints(_ points: [Vector]) -> Vector {
    let count = points.count
    let unitZ = Vector(0, 0, 1)
    switch count {
    case 0, 1:
        return unitZ
    case 2:
        let ab = points[1] - points[0]
        return ab.cross(unitZ).cross(ab)
    default:
        var b = points[0]
        var ab = b - points.last!
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

// TODO: extend this to work in 3D
// TODO: improve this using https://en.wikipedia.org/wiki/Line–line_intersection
func lineIntersection(
    _ p0: Vector,
    _ p1: Vector,
    _ p2: Vector,
    _ p3: Vector
) -> Vector? {
    let x1 = p0.x, y1 = p0.y
    let x2 = p1.x, y2 = p1.y
    let x3 = p2.x, y3 = p2.y
    let x4 = p3.x, y4 = p3.y

    let x1y2 = x1 * y2, y1x2 = y1 * x2
    let x1y2minusy1x2 = x1y2 - y1x2

    let x3minusx4 = x3 - x4
    let x1minusx2 = x1 - x2

    let x3y4 = x3 * y4, y3x4 = y3 * x4
    let x3y4minusy3x4 = x3y4 - y3x4

    let y3minusy4 = y3 - y4
    let y1minusy2 = y1 - y2

    let d = x1minusx2 * y3minusy4 - y1minusy2 * x3minusx4
    if abs(d) < epsilon {
        return nil // lines are parallel
    }
    let ix = (x1y2minusy1x2 * x3minusx4 - x1minusx2 * x3y4minusy3x4) / d
    let iy = (x1y2minusy1x2 * y3minusy4 - y1minusy2 * x3y4minusy3x4) / d

    return Vector(ix, iy, p0.z).quantized()
}

// TODO: extend this to work in 3D
func lineSegmentsIntersect(
    _ p0: Vector,
    _ p1: Vector,
    _ p2: Vector,
    _ p3: Vector
) -> Bool {
    guard let pi = lineIntersection(p0, p1, p2, p3) else {
        return false // lines are parallel
    }
    // TODO: is there a cheaper way to do this?
    if pi.x < min(p0.x, p1.x) || pi.x > max(p0.x, p1.x) ||
        pi.x < min(p2.x, p3.x) || pi.x > max(p2.x, p3.x) ||
        pi.y < min(p0.y, p1.y) || pi.y > max(p0.y, p1.y) ||
        pi.y < min(p2.y, p3.y) || pi.y > max(p2.y, p3.y)
    {
        return false
    }
    return true
}

func directionsAreParallel(_ d0: Vector, _ d1: Vector) -> Bool {
    assert(d0.isNormalized)
    assert(d1.isNormalized)
    return abs(d0.dot(d1) - 1) <= epsilon
}

func directionsAreAntiparallel(_ d0: Vector, _ d1: Vector) -> Bool {
    assert(d0.isNormalized)
    assert(d1.isNormalized)
    return abs(d0.dot(d1) + 1) <= epsilon
}

func directionsAreColinear(_ d0: Vector, _ d1: Vector) -> Bool {
    assert(d0.isNormalized)
    assert(d1.isNormalized)
    return directionsAreParallel(d0, d1) || directionsAreAntiparallel(d0, d1)
}

func directionsAreNormal(_ d0: Vector, _ d1: Vector) -> Bool {
    assert(d0.isNormalized)
    assert(d1.isNormalized)
    return abs(d0.dot(d1)) <= epsilon
}
