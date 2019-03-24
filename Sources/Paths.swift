//
//  Paths.swift
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

/// A control point on a path. Can represent a corner or a curve.
public struct PathPoint: Hashable {
    public var position: Vector
    public var isCurved: Bool
}

public extension PathPoint {
    static func point(_ position: Vector) -> PathPoint {
        return PathPoint(position, isCurved: false)
    }

    static func point(_ x: Double, _ y: Double, _ z: Double = 0) -> PathPoint {
        return .point(Vector(x, y, z))
    }

    static func curve(_ position: Vector) -> PathPoint {
        return PathPoint(position, isCurved: true)
    }

    static func curve(_ x: Double, _ y: Double, _ z: Double = 0) -> PathPoint {
        return .curve(Vector(x, y, z))
    }

    init(_ position: Vector, isCurved: Bool) {
        self.position = position.quantized()
        self.isCurved = isCurved
    }

    func lerp(_ other: PathPoint, _ t: Double) -> PathPoint {
        let isCurved = self.isCurved || other.isCurved
        return PathPoint(position.lerp(other.position, t), isCurved: isCurved)
    }
}

/// A 3D path
public struct Path: Hashable {
    public let points: [PathPoint]
    public let isClosed: Bool
    public let bounds: Bounds
    public private(set) var plane: Plane?
}

public extension Path {
    var isPlanar: Bool {
        return plane != nil
    }

    func closed() -> Path {
        if isClosed || points.isEmpty {
            return self
        }
        if points[0].isCurved || points.last!.isCurved {
            var points = self.points
            points[0] = .point(points[0].position)
            points[points.count - 1] = .point(points.last!.position)
            points.append(points[0])
            return Path(unchecked: points, plane: plane)
        }
        return Path(unchecked: points + [points[0]], plane: plane)
    }

    init(_ points: [PathPoint]) {
        let points = sanitizePoints(points)
        self.init(unchecked: points, plane: nil)
    }

    /// Get vertices suitable for constructing a polygon from the path
    /// vertices include normals and uv coordinates normalized to the
    /// bounding rectangle of the path
    // TODO: should this be facePolygons instead, to handle non-planar shapes?
    var faceVertices: [Vertex]? {
        guard isClosed, let normal = plane?.normal else {
            return nil
        }
        let vectors = points.dropFirst().map { $0.position }
        var min = Vector(.infinity, .infinity)
        var max = Vector(-.infinity, -.infinity)
        let flatteningPlane = FlatteningPlane(normal: normal)
        let vertices: [Vertex] = vectors.map {
            let uv = flatteningPlane.flattenPoint($0)
            min.x = Swift.min(min.x, uv.x)
            min.y = Swift.min(min.y, uv.y)
            max.x = Swift.max(max.x, uv.x)
            max.y = Swift.max(max.y, uv.y)
            return Vertex(unchecked: $0, normal, uv)
        }
        if verticesAreDegenerate(vertices) {
            return nil
        }
        let uvScale = Vector(max.x - min.x, max.y - min.y)
        return vertices.map {
            let uv = Vector(($0.texcoord.x - min.x) / uvScale.x, 1 - ($0.texcoord.y - min.y) / uvScale.y, 0)
            return Vertex(unchecked: $0.position, $0.normal, uv)
        }
    }

    var edgeVertices: [Vertex] {
        return edgeVertices(for: .default)
    }

    // Get edge vertices suitable for converting into a solid shape using lathe or extrusion
    func edgeVertices(for wrapMode: Mesh.WrapMode) -> [Vertex] {
        guard points.count >= 2 else {
            return []
        }

        // get path length
        var totalLength: Double = 0
        switch wrapMode {
        case .shrink, .default:
            var prev = points[0].position
            for point in points {
                let length = (point.position - prev).length
                totalLength += length
                prev = point.position
            }
            guard totalLength > 0 else {
                return []
            }
        case .tube:
            var min = Double.infinity
            var max = -Double.infinity
            for point in points {
                min = Swift.min(min, point.position.y)
                max = Swift.max(max, point.position.y)
            }
            totalLength = max - min
        }

        let count = isClosed ? points.count - 1 : points.count
        var p1 = isClosed ? points[count - 1] : (count > 2 ?
            extrapolate(points[2], points[1], points[0]) :
            extrapolate(points[1], points[0]))
        var p2 = points[0]
        var p1p2 = p2.position - p1.position
        var n1: Vector!
        var vertices = [Vertex]()
        var v = 0.0
        let endIndex = count
        for i in 0 ..< endIndex {
            p1 = p2
            p2 = i < points.count - 1 ? points[i + 1] :
                (isClosed ? points[1] : (count > 2 ?
                        extrapolate(points[i - 2], points[i - 1], points[i]) :
                        extrapolate(points[i - 1], points[i])))
            let p0p1 = p1p2
            p1p2 = p2.position - p1.position
            let faceNormal = plane?.normal ?? p0p1.cross(p1p2)
            let n0 = n1 ?? p0p1.cross(faceNormal).normalized()
            n1 = p1p2.cross(faceNormal).normalized()
            let uv = Vector(0, v, 0)
            switch wrapMode {
            case .shrink, .default:
                v += p1p2.length / totalLength
            case .tube:
                v += abs(p1p2.y) / totalLength
            }
            if p1.isCurved {
                let v = Vertex(p1.position, (n0 + n1).normalized(), uv)
                vertices.append(v)
                vertices.append(v)
            } else {
                vertices.append(Vertex(p1.position, n0, uv))
                vertices.append(Vertex(p1.position, n1, uv))
            }
        }
        var first = vertices.removeFirst()
        if isClosed {
            first.texcoord = Vector(0, v, 0)
            vertices.append(first)
        } else {
            vertices.removeLast()
        }
        return vertices
    }
}

public extension Polygon {
    /// Create a polygon from a path
    /// Path may be convex or concave, but must be closed and non-degenerate
    init?(shape: Path, material: Polygon.Material = nil) {
        guard let vertices = shape.faceVertices, let plane = shape.plane else {
            return nil
        }
        self.init(
            unchecked: vertices,
            plane: plane,
            isConvex: verticesAreConvex(vertices),
            bounds: shape.bounds,
            material: material
        )
    }
}

internal extension Path {
    init(unchecked points: [PathPoint], plane: Plane?) {
        assert(sanitizePoints(points) == points)
        self.points = points
        isClosed = pointsAreClosed(unchecked: points)
        let positions = isClosed ? points.dropLast().map { $0.position } : points.map { $0.position }
        bounds = Bounds(points: positions)
        if let plane = plane {
            self.plane = plane
            assert(self.plane == Plane(points: positions))
        } else {
            self.plane = Plane(points: positions)
        }
    }

    // Test if path is self-intersecting
    // TODO: extend this to work in 3D
    // TODO: optimize by using http://www.webcitation.org/6ahkPQIsN
    var isSimple: Bool {
        let points = flattened().points.map { $0.position }
        for i in 0 ..< points.count - 2 {
            let p0 = points[i]
            let p1 = points[i + 1]
            if p0 == p1 {
                continue
            }
            for j in i + 2 ..< points.count - 1 {
                let p2 = points[j]
                let p3 = points[j + 1]
                if p1 == p2 || p2 == p3 || p3 == p0 {
                    continue
                }
                if lineSegmentsIntersect(p0, p1, p2, p3) {
                    return false
                }
            }
        }
        return true
    }

    // flattens z-axis
    // TODO: this is a hack and should be replaced by a better solution
    func flattened() -> Path {
        if bounds.min.z == 0, bounds.max.z == 0 {
            return self
        }
        let flatteningPlane = FlatteningPlane(bounds: bounds)
        return Path(unchecked: sanitizePoints(points.map {
            PathPoint(flatteningPlane.flattenPoint($0.position), isCurved: $0.isCurved)
        }), plane: flatteningPlane.rawValue)
    }

    func clippedToYAxis() -> Path {
        var points = self.points
        guard !points.isEmpty else {
            return self
        }
        // flip path if it mostly lies right of the origin
        var leftOfOrigin = 0
        var rightOfOrigin = 0
        for p in points {
            if p.position.x > 0 {
                rightOfOrigin += 1
            } else if p.position.x < 0 {
                leftOfOrigin += 1
            }
        }
        if isClosed {
            if points[0].position.x > 0 {
                rightOfOrigin -= 1
            } else if points[0].position.x < 0 {
                leftOfOrigin -= 1
            }
        }
        var plane = self.plane
        if rightOfOrigin > leftOfOrigin {
            plane = plane?.inverted()
            points = points.map {
                var point = $0
                point.position.x = -point.position.x
                return point
            }
        }
        // clip path to Y axis
        var i = points.count - 1
        while i > 0 {
            let p0 = points[i]
            let p1 = points[i - 1]
            if p0.position.x > 0 {
                if p0 == p1 {
                    points.remove(at: i)
                } else if p1.position.x == 0 {
                    points.remove(at: i)
                } else if p1.position.x > 0 {
                    points.remove(at: i)
                    points.remove(at: i - 1)
                    i -= 1
                } else {
                    let p0p1 = p0.position - p1.position
                    let dy = p0p1.y / p0p1.x * -p1.position.x
                    points[i].position = Vector(0, p1.position.y + dy)
                    continue
                }
            } else if p1.position.x > 0 {
                if p1 == p0 {
                    points.remove(at: i - 1)
                } else if p0.position.x >= 0 {
                    if i == 1 ||
                        (p1.position.y == p0.position.y && p1.position.z == p0.position.z) {
                        points.remove(at: i - 1)
                    }
                } else {
                    let p0p1 = p1.position - p0.position
                    let dy = p0p1.y / p0p1.x * -p0.position.x
                    points[i - 1].position = Vector(0, p0.position.y + dy)
                    continue
                }
            }
            i -= 1
        }
        return Path(unchecked: points, plane: plane)
    }
}

// MARK: Private utility functions

// Get the intersection point between two lines
// TODO: extend this to work in 3D
// TODO: improve this using https://en.wikipedia.org/wiki/Line–line_intersection
private func lineIntersection(_ p0: Vector, _ p1: Vector,
                              _ p2: Vector, _ p3: Vector) -> Vector? {
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

    return Vector(ix, iy)
}

// TODO: extend this to work in 3D
private func lineSegmentsIntersect(_ p0: Vector, _ p1: Vector,
                                   _ p2: Vector, _ p3: Vector) -> Bool {
    guard let pi = lineIntersection(p0, p1, p2, p3) else {
        return false // lines are parallel
    }
    // TODO: is there a cheaper way to do this?
    if pi.x < min(p0.x, p1.x) || pi.x > max(p0.x, p1.x) ||
        pi.x < min(p2.x, p3.x) || pi.x > max(p2.x, p3.x) ||
        pi.y < min(p0.y, p1.y) || pi.y > max(p0.y, p1.y) ||
        pi.y < min(p2.y, p3.y) || pi.y > max(p2.y, p3.y) {
        return false
    }
    return true
}

// MARK: Path utility functions

func sanitizePoints(_ points: [PathPoint]) -> [PathPoint] {
    var result = [PathPoint]()
    var last: PathPoint?
    for point in points where point.position != last?.position {
        result.append(point)
        last = point
    }
    if result.first?.position == result.last?.position {
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

func pointsAreClosed(unchecked points: [PathPoint]) -> Bool {
    return points.last?.position == points.first?.position
}

func extrapolate(_ p0: PathPoint, _ p1: PathPoint, _ p2: PathPoint) -> PathPoint {
    var p0p1 = p1.position - p0.position
    let length = p0p1.length
    p0p1 = p0p1 / length
    let p1p2 = (p2.position - p1.position).normalized()
    let axis = p0p1.cross(p1p2)
    let angle = -acos(p0p1.dot(p1p2))
    let r = Rotation(axis: axis, radians: angle) ?? .identity
    let p2pe = p1p2.rotated(by: r) * length
    return .curve(p2.position + p2pe)
}

func extrapolate(_ p0: PathPoint, _ p1: PathPoint) -> PathPoint {
    let p0p1 = p1.position - p0.position
    return .point(p1.position + p0p1)
}
