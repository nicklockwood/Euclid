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
    public var texcoord: Vector?
    public var isCurved: Bool
}

extension PathPoint: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let x = try container.decode(Double.self)
        let y = try container.decode(Double.self)
        switch container.count {
        case 2:
            self.init(Vector(x, y), texcoord: nil, isCurved: false)
        case 3:
            if let isCurved = try? container.decodeIfPresent(Bool.self) {
                self.init(Vector(x, y), texcoord: nil, isCurved: isCurved)
            } else {
                let z = try container.decode(Double.self)
                self.init(Vector(x, y, z), texcoord: nil, isCurved: false)
            }
        case 4:
            let zOrU = try container.decode(Double.self)
            if let isCurved = try? container.decodeIfPresent(Bool.self) {
                self.init(Vector(x, y, zOrU), texcoord: nil, isCurved: isCurved)
            } else {
                let v = try container.decode(Double.self)
                self.init(Vector(x, y), texcoord: Vector(zOrU, v), isCurved: false)
            }
        case 5:
            let zOrU = try container.decode(Double.self)
            let uOrV = try container.decode(Double.self)
            if let isCurved = try? container.decodeIfPresent(Bool.self) {
                self.init(Vector(x, y), texcoord: Vector(zOrU, uOrV), isCurved: isCurved)
            } else {
                let v = try container.decode(Double.self)
                self.init(Vector(x, y, zOrU), texcoord: Vector(uOrV, v), isCurved: false)
            }
        case 6:
            let z = try container.decode(Double.self)
            let u = try container.decode(Double.self)
            let v = try container.decode(Double.self)
            if let isCurved = try? container.decode(Bool.self) {
                self.init(Vector(x, y, z), texcoord: Vector(u, v), isCurved: isCurved)
            } else {
                let w = try container.decode(Double.self)
                self.init(Vector(x, y, z), texcoord: Vector(u, v, w), isCurved: false)
            }
        case 7:
            let z = try container.decode(Double.self)
            let texcoord = try Vector(from: &container)
            let isCurved = try container.decode(Bool.self)
            self.init(Vector(x, y, z), texcoord: texcoord, isCurved: isCurved)
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode path point"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        let skipZ = position.z == 0 && texcoord?.z ?? 0 == 0
        try position.encode(to: &container, skipZ: skipZ)
        if let texcoord = texcoord {
            try texcoord.encode(to: &container, skipZ: texcoord.z == 0)
        }
        try isCurved ? container.encode(true) : ()
    }
}

public extension PathPoint {
    static func point(_ position: Vector, texcoord: Vector? = nil) -> PathPoint {
        PathPoint(position, texcoord: texcoord, isCurved: false)
    }

    static func point(_ x: Double, _ y: Double, _ z: Double = 0) -> PathPoint {
        .point(Vector(x, y, z))
    }

    static func curve(_ position: Vector, texcoord: Vector? = nil) -> PathPoint {
        PathPoint(position, texcoord: texcoord, isCurved: true)
    }

    static func curve(_ x: Double, _ y: Double, _ z: Double = 0) -> PathPoint {
        .curve(Vector(x, y, z))
    }

    init(_ position: Vector, texcoord: Vector?, isCurved: Bool) {
        self.position = position.quantized()
        self.texcoord = texcoord
        self.isCurved = isCurved
    }

    func lerp(_ other: PathPoint, _ t: Double) -> PathPoint {
        let texcoord: Vector?
        switch (self.texcoord, other.texcoord) {
        case let (lhs?, rhs?):
            texcoord = lhs.lerp(rhs, t)
        case let (lhs, rhs):
            texcoord = lhs ?? rhs
        }
        let isCurved = self.isCurved || other.isCurved
        return PathPoint(
            position.lerp(other.position, t),
            texcoord: texcoord,
            isCurved: isCurved
        )
    }
}

/// A 3D path
public struct Path: Hashable {
    public let points: [PathPoint]
    public let isClosed: Bool
    public private(set) var plane: Plane?
    let subpathIndices: [Int]
}

extension Path: Codable {
    private enum CodingKeys: CodingKey {
        case points, subpaths
    }

    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            let points = try container.decodeIfPresent([PathPoint].self, forKey: .points)
            if var subpaths = try container.decodeIfPresent([Path].self, forKey: .subpaths) {
                if let points = points {
                    subpaths.insert(Path(points), at: 0)
                }
                self.init(subpaths: subpaths)
            } else {
                self.init(points ?? [])
            }
        } else {
            let points = try [PathPoint](from: decoder)
            self.init(points)
        }
    }

    public func encode(to encoder: Encoder) throws {
        let subpaths = self.subpaths
        if subpaths.count < 2 {
            try (subpaths.first?.points ?? []).encode(to: encoder)
        } else {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(subpaths, forKey: .subpaths)
        }
    }

    // TODO: Make this more robust, then make public
    var hasZeroArea: Bool {
        points.count < (isClosed ? 4 : 3)
    }
}

public extension Path {
    /// Returns true if all the path's points lie on as single plane
    var isPlanar: Bool {
        plane != nil
    }

    /// The path bounds
    var bounds: Bounds {
        Bounds(points: points.map { $0.position })
    }

    /// Face normal for shape
    /// If shape is non-planar then this is the average/approximate normal
    var faceNormal: Vector {
        plane?.normal ?? faceNormalForPolygonPoints(
            points.map { $0.position },
            convex: nil
        )
    }

    /// Returns a closed path by joining last point to first
    /// Returns `self` if already closed, or if path cannot be closed
    func closed() -> Path {
        if isClosed || self.points.isEmpty {
            return self
        }
        var points = self.points
        points.append(points[0])
        return Path(unchecked: points, plane: plane, subpathIndices: nil)
    }

    /// Create a path from an array of `PathPoint`s
    init(_ points: [PathPoint]) {
        self.init(unchecked: sanitizePoints(points))
    }

    /// Create a composite path from an array of subpaths
    init(subpaths: [Path]) {
        guard subpaths.count > 1 else {
            self = subpaths.first ?? Path([])
            return
        }
        let points = subpaths.flatMap { $0.points }
        // TODO: precompute planes/subpathIndices from existing paths
        self.init(unchecked: points, plane: nil, subpathIndices: nil)
    }

    /// Create a path from a polygon
    init(polygon: Polygon) {
        let hasTexcoords = polygon.hasTexcoords
        self.init(
            unchecked: polygon.vertices.map {
                .point($0.position, texcoord: hasTexcoords ? $0.texcoord : nil)
            },
            plane: polygon.plane,
            subpathIndices: nil
        )
    }

    /// A list of subpaths making up the path. For paths without nested
    /// subpaths, this will return an array containing only `self`
    var subpaths: [Path] {
        var startIndex = 0
        var paths = [Path]()
        for i in subpathIndices {
            let points = self.points[startIndex ... i]
            startIndex = i
            guard points.count > 1 else {
                continue
            }
            // TODO: support internal one-element line segments
            guard points.count > 2 || points.startIndex == 0 || i == self.points.count - 1 else {
                continue
            }
            do {
                // TODO: do this as part of regular sanitization step
                var points = Array(points)
                if points.last?.position == points.first?.position {
                    points[0] = points.last!
                }
                paths.append(Path(unchecked: points, plane: plane, subpathIndices: []))
            }
        }
        return paths.isEmpty && !points.isEmpty ? [self] : paths
    }

    /// Get one or more polygons needed to fill the path
    /// Polygon vertices include normals and uv coordinates normalized to the bounding rectangle of the path
    func facePolygons(material: Mesh.Material? = nil) -> [Polygon] {
        guard subpaths.count <= 1 else {
            return subpaths.flatMap { $0.facePolygons(material: material) }
        }
        guard let vertices = faceVertices else {
            return []
        }
        if plane != nil, let polygon = Polygon(vertices, material: material) {
            return [polygon]
        }
        return triangulateVertices(
            vertices,
            plane: nil,
            isConvex: nil,
            material: material,
            id: 0
        ).detessellate(ensureConvex: false)
    }

    /// Get vertices suitable for constructing a polygon from the path
    /// Vertices include normals and uv coordinates normalized to the bounding
    /// rectangle of the path. Returns nil if path is open or has subpaths
    var faceVertices: [Vertex]? {
        let count = points.count
        guard isClosed, subpaths.count <= 1, count > 1 else {
            return nil
        }
        var hasTexcoords = true
        var vertices = [Vertex]()
        var p0 = points[count - 2]
        for i in 0 ..< count - 1 {
            let p1 = points[i]
            let texcoord = p1.texcoord
            hasTexcoords = hasTexcoords && texcoord != nil
            let normal = plane?.normal ?? faceNormalForPolygonPoints(
                [p0.position, p1.position, points[i + 1].position],
                convex: true
            )
            vertices.append(Vertex(unchecked: p1.position, normal, texcoord ?? .zero))
            p0 = p1
        }
        guard !verticesAreDegenerate(vertices) else {
            return nil
        }
        if hasTexcoords {
            return vertices
        }
        var min = Vector(.infinity, .infinity)
        var max = Vector(-.infinity, -.infinity)
        let flatteningPlane = FlatteningPlane(normal: faceNormal)
        vertices = vertices.map {
            let uv = flatteningPlane.flattenPoint($0.position)
            min.x = Swift.min(min.x, uv.x)
            min.y = Swift.min(min.y, uv.y)
            max.x = Swift.max(max.x, uv.x)
            max.y = Swift.max(max.y, uv.y)
            return Vertex(unchecked: $0.position, $0.normal, uv)
        }
        let uvScale = Vector(max.x - min.x, max.y - min.y)
        return vertices.map {
            let uv = Vector(
                ($0.texcoord.x - min.x) / uvScale.x,
                1 - ($0.texcoord.y - min.y) / uvScale.y,
                0
            )
            return Vertex(unchecked: $0.position, $0.normal, uv)
        }
    }

    /// Get edge vertices suitable for converting into a solid shape using lathe or extrusion
    /// Returns an empty array if path has subpaths
    var edgeVertices: [Vertex] {
        edgeVertices(for: .default)
    }

    /// Get edge vertices suitable for converting into a solid shape using lathe or extrusion
    /// Returns an empty array if path has subpaths
    func edgeVertices(for wrapMode: Mesh.WrapMode) -> [Vertex] {
        guard subpaths.count <= 1, points.count >= 2 else {
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
        var p1 = isClosed ? points[count - 1] : (
            count > 2 ?
                extrapolate(points[2], points[1], points[0]) :
                extrapolate(points[1], points[0])
        )
        var p2 = points[0]
        var p1p2 = p2.position - p1.position
        var n1: Vector!
        var vertices = [Vertex]()
        var v = 0.0
        let endIndex = count
        let faceNormal = self.faceNormal
        for i in 0 ..< endIndex {
            p1 = p2
            p2 = i < points.count - 1 ? points[i + 1] :
                (isClosed ? points[1] : (
                    count > 2 ?
                        extrapolate(points[i - 2], points[i - 1], points[i]) :
                        extrapolate(points[i - 1], points[i])
                ))
            let p0p1 = p1p2
            p1p2 = p2.position - p1.position
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
    /// Path may be convex or concave, but must be closed, planar and non-degenerate
    init?(shape: Path, material: Material? = nil) {
        guard let vertices = shape.faceVertices, let plane = shape.plane else {
            return nil
        }
        self.init(
            unchecked: vertices,
            plane: plane,
            isConvex: nil,
            material: material
        )
    }
}

internal extension Path {
    init(unchecked points: [PathPoint], plane: Plane?, subpathIndices: [Int]?) {
        assert(points == sanitizePoints(points))
        self.points = points
        self.isClosed = pointsAreClosed(unchecked: points)
        let positions = isClosed ? points.dropLast().map { $0.position } : points.map { $0.position }
        let subpathIndices = subpathIndices ?? subpathIndicesFor(points)
        self.subpathIndices = subpathIndices
        if let plane = plane {
            self.plane = plane
            assert({
                guard positions.count > 2, let expectedPlane = Path(
                    unchecked: points,
                    plane: nil,
                    subpathIndices: subpathIndices
                ).plane else {
                    return true
                }
                return plane.isEqual(to: expectedPlane, withPrecision: epsilon * 10)
            }())
        } else if subpathIndices.isEmpty {
            self.plane = Plane(points: positions)
        } else {
            for path in subpaths {
                guard let plane = path.plane else {
                    self.plane = nil
                    break
                }
                if let existing = self.plane {
                    guard existing.isEqual(to: plane) else {
                        self.plane = nil
                        break
                    }
                }
                self.plane = plane
            }
        }
    }

    // Convenience initializer
    init(unchecked points: [PathPoint]) {
        self.init(unchecked: points, plane: nil, subpathIndices: nil)
    }

    // Test if path is self-intersecting
    var isSimple: Bool {
        // TODO: what should we do about subpaths?
        !pointsAreSelfIntersecting(points.map { $0.position })
    }

    // Returns the most suitable FlatteningPlane for the path
    var flatteningPlane: FlatteningPlane {
        if let plane = plane {
            return FlatteningPlane(normal: plane.normal)
        }
        let positions = isClosed ? points.dropLast().map { $0.position } : points.map { $0.position }
        return FlatteningPlane(points: positions, convex: nil)
    }

    // flattens z-axis
    // TODO: this is a hack and should be replaced by a better solution
    func flattened() -> Path {
        guard subpathIndices.isEmpty else {
            return Path(subpaths: subpaths.map { $0.flattened() })
        }
        if points.allSatisfy({ $0.position.z == 0 }) {
            return self
        }
        let flatteningPlane = self.flatteningPlane
        return Path(unchecked: sanitizePoints(points.map {
            PathPoint(
                flatteningPlane.flattenPoint($0.position),
                texcoord: $0.texcoord,
                isCurved: $0.isCurved
            )
        }), plane: flatteningPlane.rawValue, subpathIndices: [])
    }

    func clippedToYAxis() -> Path {
        guard subpathIndices.isEmpty else {
            return Path(subpaths: subpaths.map { $0.clippedToYAxis() })
        }
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
        if rightOfOrigin > leftOfOrigin {
            // Mirror the path about Y axis
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
                        (p1.position.y == p0.position.y && p1.position.z == p0.position.z)
                    {
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
        return Path(
            unchecked: points,
            plane: nil, // Might have changed if path is self-intersecting
            subpathIndices: nil
        )
    }
}

// MARK: Path utility functions

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
            let b = result[i].position
            let c = result[i + 1].position
            let bc = c - b
            if ab.cross(bc).length < epsilon, ab.dot(bc) <= epsilon {
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
