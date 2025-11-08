//
//  Path.swift
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

/// A path made up of a sequence of straight line segments between points.
///
/// A ``Path`` can be either open (a *polyline*) or closed (a *polygon*), but should not be
/// self-intersecting or otherwise degenerate.
///
/// A path may be formed from multiple subpaths, which can be accessed via the ``Path/subpaths`` property.
/// A closed ``Path`` can be converted to one or more ``Polygon``s, but it can also be used for other
/// purposes, such as defining a cross-section or profile of a 3D shape.
///
/// Paths are typically 2-dimensional, but because ``PathPoint`` positions have a Z coordinate, they are
/// not *required* to be. Even a flat ``Path`` (where all points lie on the same plane) can be translated or
/// rotated so that its points do not necessarily lie on the *XY* plane.
public struct Path: Hashable, Sendable {
    private let storage: Storage

    /// The plane upon which all path points lie. Will be nil for non-planar paths.
    public let plane: Plane?
}

extension Path: CustomDebugStringConvertible, CustomReflectable {
    public var debugDescription: String {
        switch storage {
        case .points([]):
            return "Path.empty"
        case let .points(points):
            let v = points.map {
                "\n\t\("\($0)".dropFirst("PathPoint".count)),"
            }.joined()
            return "Path([\(v)\n])"
        case let .subpaths(subpaths):
            let p = subpaths.map {
                "\n\t\("\($0)".replacingOccurrences(of: "\n", with: "\n\t")),"
            }.joined()
            return "Path(subpaths: [\(p)\n])"
        }
    }

    public var customMirror: Mirror {
        Mirror(self, children: [
            "isClosed": isClosed,
            "plane": plane as Any,
        ], displayStyle: .struct)
    }
}

extension Path: Codable {
    private enum CodingKeys: CodingKey {
        case points, subpaths
    }

    /// Creates a new path by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            let points = try container.decodeIfPresent([PathPoint].self, forKey: .points)
            if var subpaths = try container.decodeIfPresent([Path].self, forKey: .subpaths) {
                if let points {
                    subpaths.insert(Path(points), at: 0)
                }
                self.init(subpaths: subpaths)
            } else {
                self.init(points ?? [])
            }
        } else {
            let container = try decoder.singleValueContainer()
            let points = try container.decode([PathPoint].self)
            self.init(points)
        }
    }

    /// Encodes this path into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        let subpaths = subpaths
        if subpaths.count < 2 {
            try (subpaths.first?.points ?? []).encode(to: encoder)
        } else {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(subpaths, forKey: .subpaths)
        }
    }
}

public extension Path {
    /// An empty path.
    static let empty: Path = .init([])

    /// A Boolean value that indicates whether the path is empty (has no points).
    /// > Note: This is not the same as checking if the path is closed or has zero area
    var isEmpty: Bool {
        points.isEmpty
    }

    /// The array of points that makes up this path.
    /// > Note: If the path has subpaths then the points returned may not represent a single contour
    var points: [PathPoint] {
        switch storage {
        case let .points(points): return points
        case let .subpaths(subpaths): return subpaths.flatMap(\.points)
        }
    }

    /// An array of the subpaths that make up the path.
    /// > Note: For paths without nested subpaths, this will return an array containing only `self`.
    var subpaths: [Path] {
        switch storage {
        case .points: return [self]
        case let .subpaths(subpaths): return subpaths
        }
    }

    /// Indicates whether the path is a closed path.
    /// > Note: If path is empty, will return true. If path has subpaths, will return true only if all are closed.
    var isClosed: Bool {
        switch storage {
        case let .points(points): return pointsAreClosed(unchecked: points)
        case let .subpaths(subpaths): return subpaths.allSatisfy(\.isClosed)
        }
    }

    /// A Boolean value that indicates whether all the path's points lie on a single plane.
    var isPlanar: Bool {
        plane != nil
    }

    /// A Boolean value that indicates whether any of the path's points have colors.
    var hasColors: Bool {
        points.contains(where: { $0.color != nil })
    }

    /// A Boolean value that indicates whether the path's points have texture coordinates.
    var hasTexcoords: Bool {
        points.contains(where: { $0.texcoord != nil })
    }

    /// The total length of the path.
    var length: Double {
        var prev = points.first?.position ?? .zero
        return points.dropFirst().reduce(0.0) {
            let position = $1.position
            defer { prev = position }
            return $0 + position.distance(from: prev)
        }
    }

    /// The face normal vector for the path.
    /// > Note: If path is non-planar then this returns an average/approximate normal.
    var faceNormal: Vector {
        plane?.normal ?? faceNormalForPoints(points.map(\.position))
    }

    /// Returns a copy of the polygon with transformed point colors
    /// - Parameter transform: A closure to be applied to each color in the path.
    func mapColors(_ transform: (Color?) -> Color?) -> Path {
        switch storage {
        case let .points(points):
            return .init(unchecked: .points(points.map { $0.withColor(transform($0.color)) }), plane: plane)
        case let .subpaths(subpaths):
            return .init(unchecked: .subpaths(subpaths.map { $0.mapColors(transform) }), plane: plane)
        }
    }

    /// Returns a copy of the path with the specified color applied to each point.
    /// - Parameter color: The color to apply to each point in the path.
    func withColor(_ color: Color?) -> Path {
        mapColors { _ in color }
    }

    /// Closes the path by joining last point to first.
    /// - Returns: The closed path, or `self` if the path is already closed or empty.
    func closed() -> Path {
        if isClosed || points.isEmpty {
            return self
        }
        switch storage {
        case let .points(points):
            return .init(unchecked: .points(points + [points[0]]), plane: plane)
        case let .subpaths(subpaths):
            return .init(unchecked: .subpaths(subpaths.map { $0.closed() }), plane: plane)
        }
    }

    /// Flips the path along its plane and reverses the path points.
    /// - Returns: The inverted path.
    func inverted() -> Path {
        switch storage {
        case let .points(points):
            return .init(unchecked: .points(points.reversed()), plane: plane)
        case let .subpaths(subpaths):
            return .init(unchecked: .subpaths(subpaths.map { $0.inverted() }), plane: plane)
        }
    }

    /// Creates a path from a collection of  path points.
    /// - Parameter points: An ordered collection of ``PathPoint`` making up the path.
    init(_ points: some Collection<PathPoint>) {
        self.init(Array(points), plane: nil)
    }

    /// Creates a composite path from a collection of subpaths.
    /// - Parameter subpaths: A collection of paths.
    init(subpaths: some Collection<Path>) {
        let subpaths = subpaths.flatMap(\.subpaths).filter { !$0.isEmpty }
        guard subpaths.count > 1 else {
            self = subpaths.first ?? .empty
            return
        }
        let d = subpaths.flatMap(\.undirectedEdges).reduce(epsilon) { min($0, $1.length / 2) }
        var pathpoints: [[PathPoint]] = subpaths.map { $0.points }
        outer: do {
            for (i, p) in pathpoints.enumerated() where !pointsAreClosed(unchecked: p) {
                for (j, q) in pathpoints.enumerated() where i != j && !pointsAreClosed(unchecked: q) {
                    let p = p.last!.position
                    if p.isApproximatelyEqual(to: q.first!.position, absoluteTolerance: d) {
                        pathpoints[i] += q.dropFirst()
                    } else if p.isApproximatelyEqual(to: q.last!.position, absoluteTolerance: d) {
                        pathpoints[i] += q.dropLast().reversed()
                    } else {
                        continue
                    }
                    pathpoints.remove(at: j)
                    continue outer
                }
            }
        }
        self.init(unchecked: .subpaths(pathpoints.map {
            Path(unchecked: .points(sanitizePoints($0)), plane: nil)
        }), plane: nil)
    }

    /// Creates a closed path from a polygon.
    /// - Parameter polygon: A ``Polygon`` to convert to a path.
    init(_ polygon: Polygon) {
        let hasTexcoords = polygon.hasTexcoords
        let hasVertexColors = polygon.hasVertexColors
        let points = polygon.vertices.map {
            PathPoint(
                $0.position,
                texcoord: hasTexcoords ? $0.texcoord : nil,
                color: hasVertexColors ? $0.color : nil
            )
        }
        self.init(unchecked: points + [points[0]], plane: polygon.plane)
    }

    /// Creates a path from a collection of  path points with a common color.
    /// - Parameters:
    ///   - points: An ordered collection of ``PathPoint`` making up the path.
    ///   - color: A ``Color`` to apply to the path's points.
    init(_ points: some Collection<PathPoint>, color: Color?) {
        self.init(points.map { $0.withColor(color) })
    }

    /// Creates a path from a line segment.
    /// - Parameters:
    ///   - segment: The ``LineSegment`` defining the path.
    ///   - color: An optional ``Color`` to apply to the path's points.
    init(_ segment: LineSegment, color: Color? = nil) {
        self.init([.point(segment.start, color: color), .point(segment.end, color: color)])
    }

    /// Creates a path from a set of line segments.
    /// - Parameters:
    ///   - segments: An unsorted, undirected collection of``LineSegment``s to convert to a path.
    ///   - color: An optional ``Color`` to apply to the path's points.
    init(_ segments: some Collection<LineSegment>, color: Color? = nil) {
        self.init(subpaths: segments.map { Path($0, color: color) })
    }

    /// Returns one or more polygons needed to fill the path.
    /// - Parameter material: An optional ``Polygon/Material-swift.typealias`` to apply to the polygons.
    /// - Returns: An array of polygons needed to fill the path, or an empty array if path is not closed.
    ///
    /// > Note: Polygon normals are calculated automatically based on the curvature of the path points.
    /// If the path points do not include textcoords, they will be calculated automatically based on the
    /// path point positions relative to the bounding rectangle of the path.
    func facePolygons(material: Mesh.Material? = nil) -> [Polygon] {
        guard subpaths.count <= 1 else {
            return subpaths.flatMap { $0.facePolygons(material: material) }
        }
        guard let vertices = faceVertices else {
            return []
        }
        return .init(vertices, material: material)
    }

    /// An array of vertices suitable for constructing a polygon from the path.
    /// > Note: Vertices include normals and uv coordinates normalized to the bounding
    /// rectangle of the path. Returns `nil` if path is not closed, or has subpaths.
    var faceVertices: [Vertex]? {
        let count = points.count
        guard isClosed, subpaths.count <= 1, count > 1 else {
            return nil
        }
        var hasTexcoords = true
        var vertices = (0 ..< count - 1).map { i in
            let p1 = points[i]
            let texcoord = p1.texcoord
            hasTexcoords = hasTexcoords && texcoord != nil
            let normal = plane?.normal ?? faceNormalForPoints(
                [points[i > 0 ? i - 1 : count - 2].position, p1.position, points[i + 1].position]
            )
            return Vertex(
                unchecked: p1.position,
                normal,
                texcoord,
                p1.color
            )
        }
        guard !verticesAreDegenerate(vertices) else {
            return nil
        }
        if hasTexcoords {
            return vertices
        }
        var min = Vector(.infinity, .infinity)
        var max = Vector(-.infinity, -.infinity)
        let flatteningPlane = flatteningPlane
        vertices = vertices.map {
            let uv = flatteningPlane.flattenPoint($0.position)
            min.x = Swift.min(min.x, uv.x)
            min.y = Swift.min(min.y, uv.y)
            max.x = Swift.max(max.x, uv.x)
            max.y = Swift.max(max.y, uv.y)
            return Vertex(unchecked: $0.position, $0.normal, uv, $0.color)
        }
        let uvScale = Vector(max.x - min.x, max.y - min.y)
        return vertices.map {
            let uv = Vector(
                ($0.texcoord.x - min.x) / uvScale.x,
                1 - ($0.texcoord.y - min.y) / uvScale.y,
                0
            )
            return Vertex(unchecked: $0.position, $0.normal, uv, $0.color)
        }
    }

    /// An array of vertices suitable for constructing a set of edge polygons for the path.
    /// > Note: Returns an empty array if the path has subpaths.
    var edgeVertices: [Vertex] {
        edgeVertices(for: .default)
    }

    /// An array of vertices suitable for constructing a set of edge polygons for the path.
    /// - Parameter wrapMode: The wrap mode to use for generating texture coordinates.
    /// - Returns: The edge vertices, or an empty array if path has subpaths.
    func edgeVertices(for wrapMode: Mesh.WrapMode) -> [Vertex] {
        guard subpaths.count <= 1, points.count > 1 else {
            return points.first.map { [Vertex($0)] } ?? []
        }

        // get path length
        var totalLength = 0.0
        switch wrapMode {
        case .shrink, .default:
            var prev = points[0].position
            totalLength = points.dropFirst().reduce(0) { total, point in
                defer { prev = point.position }
                return total + point.distance(from: prev)
            }
        case .tube:
            var min = Double.infinity
            var max = -Double.infinity
            for point in points {
                min = Swift.min(min, point.position.y)
                max = Swift.max(max, point.position.y)
            }
            totalLength = max - min
        case .none:
            break
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
        let faceNormal = faceNormal
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
            case .none:
                break
            }
            if p1.isCurved {
                let v = Vertex(
                    unchecked: p1.position,
                    (n0 + n1).normalized(),
                    uv,
                    p1.color
                )
                vertices.append(v)
                vertices.append(v)
            } else {
                vertices.append(Vertex(unchecked: p1.position, n0, uv, p1.color))
                vertices.append(Vertex(unchecked: p1.position, n1, uv, p1.color))
            }
        }
        var first = vertices.removeFirst()
        if isClosed {
            first.texcoord = [0, v, 0]
            vertices.append(first)
        } else {
            vertices.removeLast()
        }
        return vertices
    }

    /// Returns the ordered array of path edges.
    var orderedEdges: [LineSegment] {
        switch storage {
        case let .subpaths(subpaths):
            return subpaths.flatMap(\.orderedEdges)
        case let .points(points):
            return points.orderedEdges
        }
    }

    /// An unordered set of path edges.
    /// The direction of each edge is normalized relative to the origin to simplify edge-equality comparisons.
    var undirectedEdges: Set<LineSegment> {
        Set(orderedEdges.map(LineSegment.init(undirected:)))
    }

    /// Applies a uniform inset to the edges of the path.
    /// - Parameter distance: The distance by which to inset the path edges.
    /// - Returns: A copy of the path, inset by the specified distance.
    ///
    /// > Note: Passing a negative `distance` will expand the path instead of shrinking it.
    func inset(by distance: Double) -> Path {
        guard subpaths.count <= 1, points.count >= 2 else {
            return Path(subpaths: subpaths.map { $0.inset(by: distance) })
        }
        let count = points.count
        var p1 = isClosed ? points[count - 2] : (
            count > 2 ?
                extrapolate(points[2], points[1], points[0]) :
                extrapolate(points[1], points[0])
        )
        var p2 = points[0]
        var p1p2 = p2.position - p1.position
        var n1: Vector!
        return Path((0 ..< count).map { i in
            p1 = p2
            p2 = i < count - 1 ? points[i + 1] :
                (isClosed ? points[1] : (
                    count > 2 ?
                        extrapolate(points[i - 2], points[i - 1], points[i]) :
                        extrapolate(points[i - 1], points[i])
                ))
            let p0p1 = p1p2
            p1p2 = p2.position - p1.position
            let faceNormal = plane?.normal ?? p0p1.cross(p1p2).normalized()
            let n0 = n1 ?? p0p1.cross(faceNormal).normalized()
            n1 = p1p2.cross(faceNormal).normalized()
            // TODO: do we need to inset texcoord as well? If so, by how much?
            let normal = (n0 + n1).normalized()
            return p1.translated(by: normal * -(distance / n0.dot(normal)))
        })
    }

    /// Returns the path recentered on the origin.
    func withNormalizedPosition() -> (path: Path, offset: Vector) {
        let offset = points.centroid
        return offset.isZero ? (self, .zero) : (translated(by: -offset), offset)
    }

    /// Increase path detail in proportion to twist angle
    func withDetail(_ detail: Int, twist: Angle) -> Path {
        guard detail > 2, twist != .zero, var prev = points.first else {
            return self
        }
        let subpaths = subpaths
        guard subpaths.count == 1 else {
            return Path(subpaths: subpaths.map {
                $0.withDetail(detail, twist: twist)
            })
        }
        let total = length
        let maxStep = Angle.twoPi / max(1, Double(detail / 2))
        var split = false
        let path = Path([prev] + points.dropFirst().flatMap { point -> [PathPoint] in
            defer { prev = point }
            let length = (point.position - prev.position).length
            let step = twist * (length / total)
            if step >= maxStep {
                split = true
                return [prev.lerp(point, 0.5).curved(), point]
            }
            return [point]
        })
        return split ? path.withDetail(detail, twist: twist) : path
    }
}

public extension Polygon {
    /// Creates a single polygon from a path.
    /// - Parameters:
    ///   - shape: The ``Path`` to convert to a polygon.
    ///   - material: An optional ``Material-swift.typealias`` to apply to the polygon.
    ///
    /// Path may be convex or concave, but must be closed, planar and non-degenerate, and must not
    /// include subpaths. For a non-planar path, or one with subpaths, use ``Path/facePolygons(material:)``.
    init?(_ shape: Path, material: Material? = nil) {
        guard let vertices = shape.faceVertices, let plane = shape.plane else {
            return nil
        }
        self.init(
            unchecked: vertices,
            plane: plane,
            isConvex: nil,
            sanitizeNormals: false,
            material: material
        )
    }

    /// Deprecated
    @available(*, deprecated, renamed: "init(_:material:)")
    init?(shape: Path, material: Material? = nil) {
        self.init(shape, material: material)
    }
}

extension Path {
    enum Storage: Hashable, Sendable {
        case points([PathPoint])
        case subpaths([Path])
    }

    /// Used by Transformable functions
    /// This method validates the points and will create sub-paths if needed
    init(_ points: [PathPoint], plane: Plane?) {
        let subpaths = subpathsFor(points)
        self.init(unchecked: .subpaths(subpaths), plane: plane)
    }

    /// This method assumed points do not have subpaths and may assert if they do
    init(unchecked points: [PathPoint], plane: Plane?) {
        assert(subpathsFor(points).count <= 1)
        self.init(unchecked: .points(points), plane: plane)
    }

    init(unchecked storage: Storage, plane: Plane?) {
        switch storage {
        case let .points(points):
            assert(sanitizePoints(points) == points)
            self.storage = storage
            if let plane {
                assert(points.map(\.position).allSatisfy { plane.intersects($0) })
            }
            self.plane = plane ?? Plane(points: points.map(\.position))
        case let .subpaths(subpaths):
            switch subpaths.count {
            case 0:
                assert(plane == nil)
                self.storage = .points([])
                self.plane = nil
            case 1:
                self = subpaths[0]
            default:
                assert(subpaths.allSatisfy { sanitizePoints($0.points) == $0.points })
                self.storage = storage
                if let plane {
                    self.plane = plane
                    assert(points.map(\.position).allSatisfy { plane.intersects($0) })
                } else {
                    let plane = subpaths.first?.plane
                    if subpaths.dropFirst().allSatisfy({
                        $0.plane.isApproximatelyEqual(to: plane) ||
                            // TODO: if plane is inverted, should we invert the path?
                            $0.plane.isApproximatelyEqual(to: plane?.inverted())
                    }) {
                        self.plane = plane
                    } else {
                        self.plane = nil
                    }
                }
            }
        }
    }

    /// Test if path is self-intersecting
    var isSimple: Bool {
        // TODO: what should we do about subpaths?
        !pointsAreSelfIntersecting(points.map(\.position))
    }

    /// Returns the most suitable FlatteningPlane for the path
    var flatteningPlane: FlatteningPlane {
        FlatteningPlane(normal: faceNormal)
    }

    // TODO: Make this more robust, then make public
    // TODO: Could this make use of Polygon.area?
    var hasZeroArea: Bool {
        points.count < (isClosed ? 4 : 3)
    }

    // flattens z-axis
    // TODO: this is a hack and should be replaced by a better solution
    func flattened() -> Path {
        guard subpaths.count == 1 else {
            return Path(subpaths: subpaths.map { $0.flattened() })
        }
        if points.allSatisfy({ $0.position.z == 0 }) {
            return self
        }
        let flatteningPlane = flatteningPlane
        return Path(unchecked: sanitizePoints(points.map {
            PathPoint(
                flatteningPlane.flattenPoint($0.position),
                texcoord: $0.texcoord,
                color: $0.color,
                isCurved: $0.isCurved
            )
        }), plane: .xy)
    }

    func clippedToYAxis() -> Path {
        guard subpaths.count == 1 else {
            return Path(subpaths: subpaths.map { $0.clippedToYAxis() })
        }
        var points = points
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
                } else if abs(p1.position.x) < epsilon {
                    points.remove(at: i)
                } else if p1.position.x > 0 {
                    points.remove(at: i)
                    points.remove(at: i - 1)
                    i -= 1
                } else {
                    let p0p1 = p0.position - p1.position
                    let dy = p0p1.y / p0p1.x * -p1.position.x
                    points[i].position = [0, p1.position.y + dy]
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
                    points[i - 1].position = [0, p0.position.y + dy]
                    continue
                }
            }
            i -= 1
        }
        return Path(
            unchecked: points,
            plane: nil // Might have changed if path is self-intersecting
        )
    }
}
