//
//  Polygon.swift
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

/// A polygon in 3D space.
///
/// A polygon must be composed of three or more vertices, and those vertices must all lie on the same
/// plane. The edges of a polygon can be either convex or concave, but not self-intersecting.
public struct Polygon: Hashable, Sendable {
    private var storage: Storage

    // Used to track split/join.
    var id: Int
}

extension Polygon: Codable {
    private enum CodingKeys: CodingKey {
        case vertices, plane, material
    }

    /// Creates a new polygon by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        let vertices: [Vertex]
        var plane: Plane?, material: Material?
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            vertices = try container.decode([Vertex].self, forKey: .vertices)
            guard !verticesAreDegenerate(vertices) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .vertices,
                    in: container,
                    debugDescription: "Vertices are degenerate"
                )
            }
            plane = try container.decodeIfPresent(Plane.self, forKey: .plane)
            material = try container.decodeIfPresent(CodableMaterial.self, forKey: .material)?.value
        } else {
            var container = try decoder.unkeyedContainer()
            if let values = try? container.decode([Vertex].self) {
                vertices = values
                plane = try container.decode(Plane.self)
                material = try container.decodeIfPresent(CodableMaterial.self)?.value
            } else {
                vertices = try [Vertex](from: decoder)
            }
            guard !verticesAreDegenerate(vertices) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Vertices are degenerate"
                )
            }
        }
        self.init(
            unchecked: vertices,
            plane: plane,
            isConvex: nil,
            sanitizeNormals: true,
            material: material
        )
    }

    /// Encodes this polygon into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        let positions = vertices.map { $0.position }
        if material == nil, plane == Plane(
            unchecked: positions, convex: isConvex, closed: true
        ) {
            if vertices.allSatisfy({
                $0.texcoord == .zero && $0.normal == plane.normal && $0.color == .white
            }) {
                try positions.encode(to: encoder)
            } else {
                try vertices.encode(to: encoder)
            }
        } else {
            var container = encoder.unkeyedContainer()
            try container.encode(vertices)
            try container.encode(plane)
            try material.map { try container.encode(CodableMaterial($0)) }
        }
    }
}

public extension Polygon {
    /// Material used by a given polygon.
    /// This can be any type that conforms to `Hashable`, but encoding/decoding is only supported
    /// for the following types: `Color`, `String`, `Int`, `Data` or any `NSCodable` type.
    typealias Material = AnyHashable

    /// The array of vertices that make up the polygon.
    var vertices: [Vertex] { storage.vertices }
    /// The plane on which all vertices lie.
    var plane: Plane { storage.plane }
    /// The bounding box containing the polygon.
    var bounds: Bounds { Bounds(points: vertices.map { $0.position }) }
    /// A Boolean value that indicates whether the polygon is convex.
    var isConvex: Bool { storage.isConvex }

    /// An optional ``Material-swift.typealias`` associated with the polygon.
    var material: Material? {
        get { storage.material }
        set {
            if isKnownUniquelyReferenced(&storage) {
                storage.material = newValue
            } else {
                storage = Storage(
                    vertices: vertices,
                    plane: plane,
                    isConvex: isConvex,
                    material: newValue
                )
            }
        }
    }

    /// A Boolean value that indicates whether the polygon includes texture coordinates.
    var hasTexcoords: Bool {
        vertices.contains(where: { $0.texcoord != .zero })
    }

    /// A Boolean value that indicates whether the polygon includes vertex normals that differ from the face normal.
    var hasVertexNormals: Bool {
        vertices.contains(where: { !$0.normal.isEqual(to: plane.normal) && $0.normal != .zero })
    }

    /// A Boolean value that indicates whether the polygon includes vertex colors.
    var hasVertexColors: Bool {
        vertices.contains(where: { $0.color != .white })
    }

    /// Returns the ordered array of polygon edges.
    var orderedEdges: [LineSegment] {
        var p0 = vertices.last!.position
        return vertices.map {
            let p1 = $0.position
            defer { p0 = p1 }
            return LineSegment(unchecked: p0, p1)
        }
    }

    /// An unordered set of polygon edges.
    /// The direction of each edge is normalized relative to the origin to simplify edge-equality comparisons.
    var undirectedEdges: Set<LineSegment> {
        var p0 = vertices.last!.position
        return Set(vertices.map {
            let p1 = $0.position
            defer { p0 = p1 }
            return LineSegment(normalized: p0, p1)
        })
    }

    /// Returns the area of the polygon.
    var area: Double {
        var vertices = self.vertices
        let z = vertices.first?.position.z ?? 0
        if !vertices.allSatisfy({ abs($0.position.z - z) < epsilon }) {
            let r = rotationBetweenVectors(plane.normal, .unitZ)
            vertices = vertices.map { Vertex($0.position.rotated(by: -r)) }
            let z = vertices.first?.position.z ?? 0
            assert(vertices.allSatisfy { abs($0.position.z - z) < epsilon })
        }
        var prev = vertices.last!.position
        return abs(vertices.reduce(0) { area, v in
            defer { prev = v.position }
            return area + (prev.x - v.position.x) * (prev.y + v.position.y)
        } / 2)
    }

    /// Creates a copy of the polygon with the specified material.
    /// - Parameter material: The replacement material, or `nil` to remove the material.
    func with(material: Material?) -> Polygon {
        var polygon = self
        polygon.material = material
        return polygon
    }

    /// Creates a polygon from an array of vertices.
    /// - Parameters:
    ///   - vertices: An array of ``Vertex`` that make up the polygon.
    ///   - material: An optional ``Material-swift.typealias`` to use for the polygon.
    ///
    /// > Note: A polygon can be convex or concave, but vertices must be coplanar and non-degenerate.
    /// Vertices are assumed to be in anti-clockwise order for the purpose of deriving the face normal.
    init?(_ vertices: [Vertex], material: Material? = nil) {
        let positions = vertices.map { $0.position }
        let isConvex = pointsAreConvex(positions)
        guard positions.count > 2, !pointsAreSelfIntersecting(positions),
              // Note: Plane init includes check for degeneracy
              let plane = Plane(points: positions, convex: isConvex, closed: true)
        else {
            return nil
        }
        self.init(
            unchecked: vertices,
            plane: plane,
            isConvex: isConvex,
            sanitizeNormals: true,
            material: material
        )
    }

    /// Creates a polygon from a set of vertex positions.
    /// - Parameters:
    ///   - vertices: A collection of ``Vector`` positions for the polygon vertices.
    ///   - material: An optional ``Material-swift.typealias`` to use for the polygon.
    ///
    /// > Note: Vertex normals will be set to match the overall face normal of the polygon.
    /// Texture coordinates will be set to zero. Vertex colors will be defaulted to white.
    init?<T: Sequence>(
        _ vertices: T,
        material: Material? = nil
    ) where T.Element == Vector {
        self.init(vertices.map(Vertex.init), material: material)
    }

    /// Returns a Boolean value that indicates whether a point lies inside the polygon, on the same plane.
    /// - Parameter point: The point to test.
    /// - Returns: `true` if the point lies inside the polygon and `false` otherwise.
    func containsPoint(_ point: Vector) -> Bool {
        guard plane.containsPoint(point) else {
            return false
        }
        // https://stackoverflow.com/questions/217578/how-can-i-determine-whether-a-2d-point-is-within-a-polygon#218081
        let flatteningPlane = FlatteningPlane(normal: plane.normal)
        let points = vertices.map { flatteningPlane.flattenPoint($0.position) }
        let p = flatteningPlane.flattenPoint(point)
        let count = points.count
        var c = false
        var j = count - 1
        for i in 0 ..< count {
            if (points[i].y > p.y) != (points[j].y > p.y),
               p.x < (points[j].x - points[i].x) * (p.y - points[i].y) /
               (points[j].y - points[i].y) + points[i].x
            {
                c = !c
            }
            j = i
        }
        return c
    }

    /// Merges this polygon with another, removing redundant vertices where possible.
    /// - Parameters:
    ///   - other: The polygon to merge with.
    ///   - ensureConvex: A Boolean indicating is the resultant polygon must be convex.
    /// - Returns: The combined polygon, or `nil` if the polygons can't be merged.
    func merge(_ other: Polygon, ensureConvex: Bool = false) -> Polygon? {
        // do they have the same material?
        guard material == other.material else {
            return nil
        }
        // are they coplanar?
        guard plane.isEqual(to: other.plane) else {
            return nil
        }
        return merge(unchecked: other, ensureConvex: ensureConvex)
    }

    /// Return a copy of the polygon without texture coordinates
    func withoutTexcoords() -> Polygon {
        Polygon(
            unchecked: vertices.withoutTexcoords(),
            plane: plane,
            isConvex: isConvex,
            sanitizeNormals: false,
            material: material,
            id: id
        )
    }

    /// Flips the polygon along its plane and reverses the order and surface normals of the vertices.
    /// - Returns: The inverted polygon.
    func inverted() -> Polygon {
        Polygon(
            unchecked: vertices.inverted(),
            plane: plane.inverted(),
            isConvex: isConvex,
            sanitizeNormals: false,
            material: material,
            id: id
        )
    }

    /// Splits a polygon into two or more convex polygons using the "ear clipping" method.
    /// - Parameter maxSides: The maximum number of sides each polygon may have.
    /// - Returns: An array of convex polygons.
    func tessellate(maxSides: Int = .max) -> [Polygon] {
        let maxSides = max(maxSides, 3)
        if vertices.count <= maxSides, isConvex {
            return [self]
        }
        var polygons = triangulate()
        if maxSides == 3 {
            return polygons
        }
        var i = polygons.count - 1
        while i > 1 {
            let a = polygons[i]
            let count = a.vertices.count
            if count < maxSides,
               let j = polygons.firstIndex(where: {
                   $0.vertices.count + count - 2 <= maxSides
               }),
               j < i,
               let merged = a.merge(unchecked: polygons[j], ensureConvex: true)
            {
                precondition(merged.vertices.count <= maxSides)
                precondition(merged.isConvex)
                polygons[j] = merged
                polygons.remove(at: i)
            }
            i -= 1
        }
        return polygons
    }

    /// Tessellates the polygon into triangles.
    /// - Returns: An array of triangles.
    ///
    /// > Note: If the polygon is already a triangle then it is returned unchanged.
    func triangulate() -> [Polygon] {
        guard vertices.count > 3 else {
            return [self]
        }
        return triangulateVertices(
            vertices,
            plane: plane,
            isConvex: isConvex,
            sanitizeNormals: false,
            material: material,
            id: id
        )
    }
}

extension Collection where Element == LineSegment {
    /// Set of all unique start/end points in edge collection.
    var endPoints: Set<Vector> {
        var endPoints = Set<Vector>()
        for edge in self {
            endPoints.insert(edge.start)
            endPoints.insert(edge.end)
        }
        return endPoints
    }

    /// Returns the largest separation distance between a set of edges endpoints.
    /// Useful for calculating the threshold to use when merging vertex coordinates to eliminate holes.
    var separationDistance: Double {
        var distance = 0.0
        for (i, a) in dropLast().enumerated() {
            var best = Double.infinity
            for b in dropFirst(i) {
                let d = Swift.max((b.start - a.start).length, (b.end - a.end).length)
                if d > 0, d < best {
                    best = d
                }
            }
            if best.isFinite, best > distance {
                distance = best
            }
        }
        return distance
    }
}

extension Collection where Element == Polygon {
    /// Does any polygon include texture coordinates?
    var hasTexcoords: Bool {
        contains(where: { $0.hasTexcoords })
    }

    /// Does any polygon have vertex normals that differ from the face normal?
    var hasVertexNormals: Bool {
        contains(where: { $0.hasVertexNormals })
    }

    /// Does any polygon have vertex colors?
    var hasVertexColors: Bool {
        contains(where: { $0.hasVertexColors })
    }

    /// Return a set of all unique edges across all the polygons
    var uniqueEdges: Set<LineSegment> {
        var edges = Set<LineSegment>()
        forEach { edges.formUnion($0.undirectedEdges) }
        return edges
    }

    /// Check if polygons form a watertight mesh, i.e. every edge is attached to at least 2 polygons.
    /// Note: doesn't verify that mesh is not self-intersecting or inside-out.
    var areWatertight: Bool {
        holeEdges.isEmpty
    }

    /// Returns all edges that exist at the boundary of a hole.
    var holeEdges: Set<LineSegment> {
        var edges = Set<LineSegment>()
        for polygon in self {
            for edge in polygon.undirectedEdges {
                if let index = edges.firstIndex(of: edge) {
                    edges.remove(at: index)
                } else {
                    edges.insert(edge)
                }
            }
        }
        return edges
    }

    /// Insert missing vertices needed to prevent hairline cracks.
    func insertingEdgeVertices(with holeEdges: Set<LineSegment>) -> [Polygon] {
        var points = Set<Vector>()
        for edge in holeEdges {
            points.insert(edge.start)
            points.insert(edge.end)
        }
        var polygons = Array(self)
        let sortedPoints = points.sorted()
        for i in polygons.indices {
            let bounds = polygons[i].bounds.inset(by: -epsilon)
            for point in sortedPoints where bounds.containsPoint(point) {
                _ = polygons[i].insertEdgePoint(point)
            }
        }
        return polygons
    }

    /// Merge vertices with similar positions.
    /// - Parameter precision: The maximum distance between vertices.
    func mergingVertices(withPrecision precision: Double) -> [Polygon] {
        mergingVertices(nil, withPrecision: precision)
    }

    /// Merge vertices with similar positions.
    /// - Parameters
    ///   - vertices: The vertices to merge. If nil then all vertices are merged.
    ///   - precision: The maximum distance between vertices.
    func mergingVertices(
        _ vertices: Set<Vector>?,
        withPrecision precision: Double
    ) -> [Polygon] {
        var positions = VertexSet(precision: precision)
        return compactMap {
            var merged = [Vertex]()
            var modified = false
            for v in $0.vertices {
                if let vertices = vertices, !vertices.contains(v.position) {
                    merged.append(v)
                    continue
                }
                let u = positions.insert(v)
                if modified || v != u {
                    modified = true
                    if let w = merged.last, w.position == u.position {
                        merged[merged.count - 1] = w.lerp(v, 0.5).with(position: u.position)
                        continue
                    }
                }
                merged.append(u)
            }
            if !modified {
                return $0
            }
            if merged.count > 1, let w = merged.first,
               w.position == merged.last?.position
            {
                merged[0] = w.lerp(merged.removeLast(), 0.5)
            }
            return Polygon(merged, material: $0.material)
        }
    }

    /// Smooth vertex normals
    func smoothNormals(_ threshold: Angle) -> [Polygon] {
        guard threshold > .zero else {
            return map { p0 in
                let n0 = p0.plane.normal
                return Polygon(
                    unchecked: p0.vertices.map { $0.with(normal: n0) },
                    plane: p0.plane,
                    isConvex: p0.isConvex,
                    sanitizeNormals: false,
                    material: p0.material
                )
            }
        }
        var polygonsByVertex = [Vector: [Polygon]]()
        forEach { polygon in
            polygon.vertices.forEach { vertex in
                polygonsByVertex[vertex.position, default: []].append(polygon)
            }
        }
        return map { p0 in
            let n0 = p0.plane.normal
            return Polygon(
                unchecked: p0.vertices.map { v0 in
                    let polygons = polygonsByVertex[v0.position] ?? []
                    return v0.with(normal: polygons.compactMap { p1 in
                        let n1 = p1.plane.normal
                        return .acos(n0.dot(n1)) < threshold ? n1 : nil
                    }.reduce(.zero) { $0 + $1 })
                },
                plane: p0.plane,
                isConvex: p0.isConvex,
                sanitizeNormals: false,
                material: p0.material
            )
        }
    }

    /// Return polygons without texture coordinates
    func withoutTexcoords() -> [Polygon] {
        map { $0.withoutTexcoords() }
    }

    /// Flip each polygon along its plane
    func inverted() -> [Polygon] {
        map { $0.inverted() }
    }

    /// Decompose each concave polygon into 2 or more convex polygons
    func tessellate(maxSides: Int = .max) -> [Polygon] {
        flatMap { $0.tessellate(maxSides: maxSides) }
    }

    /// Decompose each polygon into triangles
    func triangulate() -> [Polygon] {
        flatMap { $0.triangulate() }
    }

    /// Merge coplanar polygons that share one or more edges
    /// Note: polygons must be sorted by plane prior to calling this method
    func detessellate(ensureConvex: Bool = false) -> [Polygon] {
        var polygons = Array(self)
        assert(polygons.areSortedByPlane)
        var i = 0
        var firstPolygonInPlane = 0
        while i < polygons.count {
            var j = i + 1
            let a = polygons[i]
            while j < polygons.count {
                let b = polygons[j]
                guard a.plane.isEqual(to: b.plane) else {
                    firstPolygonInPlane = j
                    i = firstPolygonInPlane - 1
                    break
                }
                if let merged = a.merge(b, ensureConvex: ensureConvex) {
                    polygons[i] = merged
                    polygons.remove(at: j)
                    i = firstPolygonInPlane - 1
                    break
                }
                j += 1
            }
            i += 1
        }
        return polygons
    }

    /// Group polygons by plane
    func groupedByPlane() -> [(plane: Plane, polygons: [Polygon])] {
        if isEmpty {
            return []
        }
        let polygons = sorted(by: { $0.plane.w < $1.plane.w })
        var prev = polygons[0]
        var sorted = [(Plane, [Polygon])]()
        var groups = [(Plane, [Polygon])]()
        for p in polygons {
            if p.plane.w.isEqual(to: prev.plane.w, withPrecision: planeEpsilon) {
                if let i = groups.lastIndex(where: { $0.0.isEqual(to: p.plane) }) {
                    groups[i].0 = p.plane
                    groups[i].1.append(p)
                } else {
                    groups.append((p.plane, [p]))
                }
            } else {
                sorted += groups
                groups = [(p.plane, [p])]
            }
            prev = p
        }
        sorted += groups
        return sorted
    }

    /// Sort polygons by plane
    func sortedByPlane() -> [Polygon] {
        groupedByPlane().flatMap { $0.polygons }
    }

    /// Group by material
    func groupedByMaterial() -> [Polygon.Material?: [Polygon]] {
        var polygonsByMaterial = [Polygon.Material?: [Polygon]]()
        forEach { polygonsByMaterial[$0.material, default: []].append($0) }
        return polygonsByMaterial
    }

    /// Group by touching vertices
    func groupedBySubmesh() -> [[Polygon]] {
        var submeshes = [[Polygon]]()
        var points = [Set<Vector>]()
        for poly in self {
            let positions = Set(poly.vertices.map { $0.position })
            var lastMatch: Int?
            for i in points.indices.reversed() {
                if !points[i].isDisjoint(with: positions) {
                    submeshes[i].append(poly)
                    points[i].formUnion(positions)
                    if let j = lastMatch {
                        for p in submeshes.remove(at: j) where !submeshes[i].contains(p) {
                            submeshes[i].append(p)
                        }
                        points[i].formUnion(points.remove(at: j))
                    }
                    lastMatch = i
                }
            }
            if lastMatch == nil {
                submeshes.append([poly])
                points.append(positions)
            }
        }
        return submeshes
    }
}

extension MutableCollection where Element == Polygon, Index == Int {
    /// Merge coplanar polygons that share one or more edges
    var areSortedByPlane: Bool {
        guard !isEmpty else {
            return true
        }
        let count = self.count
        for i in 0 ..< count - 1 {
            let p = self[i]
            let plane = p.plane
            var wasSame = true
            for j in (i + 1) ..< count {
                if self[j].plane.isEqual(to: plane) {
                    if !wasSame {
                        return false
                    }
                } else {
                    wasSame = false
                }
            }
        }
        return true
    }
}

extension Array where Element == Polygon {
    mutating func addPoint(
        _ point: Vector,
        material: Polygon.Material?,
        verticesByPosition: [Vector: [(faceNormal: Vector, Vertex)]]
    ) {
        var facing = [Polygon](), coplanar = [Vector: [Polygon]]()
        loop: for (i, polygon) in enumerated().reversed() {
            switch point.compare(with: polygon.plane) {
            case .front:
                facing.append(polygon)
                remove(at: i)
            case .coplanar:
                if polygon.vertices.contains(where: { $0.position == point }) {
                    return
                }
                if polygon.containsPoint(point) {
                    coplanar[polygon.plane.normal] = [polygon]
                    break loop
                }
                coplanar[polygon.plane.normal, default: []].append(polygon)
            case .back, .spanning:
                continue
            }
        }
        // Find bounding edges
        func boundingEdges(in polygons: [Polygon]) -> [LineSegment] {
            var edges = [LineSegment]()
            for polygon in polygons {
                for edge in polygon.orderedEdges {
                    if let index = edges.firstIndex(where: {
                        $0.start == edge.end && $0.end == edge.start
                    }) {
                        edges.remove(at: index)
                    } else {
                        edges.append(edge)
                    }
                }
            }
            return edges
        }
        // Create triangles from point to edges
        func addTriangles(with edges: [LineSegment], faceNormal: Vector?) {
            for edge in edges {
                guard let triangle = Polygon(
                    points: [point, edge.start, edge.end],
                    verticesByPosition: verticesByPosition,
                    faceNormal: faceNormal,
                    material: material
                ) else {
                    assertionFailure()
                    continue
                }
                append(triangle)
            }
        }
        // Extend polygons to include point
        guard facing.isEmpty else {
            addTriangles(with: boundingEdges(in: facing), faceNormal: nil)
            return
        }
        for (faceNormal, polygons) in coplanar {
            guard let polygon = polygons.first else { continue }
            addTriangles(with: boundingEdges(in: polygons).compactMap {
                let edgePlane = polygon.edgePlane(for: $0)
                if point.compare(with: edgePlane) == .front {
                    return $0.inverted()
                }
                return nil
            }, faceNormal: faceNormal)
        }
    }
}

extension Polygon {
    // Create polygon from points with nearest matches in a vertex collection
    init?<T: Collection>(
        points: T,
        verticesByPosition: [Vector: [(faceNormal: Vector, Vertex)]],
        faceNormal: Vector?,
        material: Polygon.Material?
    ) where T.Element == Vector {
        let faceNormal = faceNormal ?? faceNormalForPolygonPoints(
            Array(points), convex: true, closed: true
        )
        let vertices = points.map { p -> Vertex in
            let matches = verticesByPosition[p] ?? []
            var best: Vertex?, bestDot = 1.0
            for (n, v) in matches {
                let dot = abs(1 - n.dot(faceNormal))
                if dot <= bestDot {
                    bestDot = dot
                    best = v
                }
            }
            if bestDot == 1 {
                best?.normal = .zero
            }
            return best ?? Vertex(p)
        }
        self.init(vertices, material: material)
    }

    // Create polygon from vertices and face normal without performing validation
    // Vertices may be convex or concave, but are assumed to describe a non-degenerate polygon
    init(
        unchecked vertices: [Vertex],
        normal: Vector,
        isConvex: Bool?,
        sanitizeNormals: Bool,
        material: Material?
    ) {
        self.init(
            unchecked: vertices,
            plane: Plane(unchecked: normal, pointOnPlane: vertices[0].position),
            isConvex: isConvex,
            sanitizeNormals: sanitizeNormals,
            material: material,
            id: 0
        )
    }

    // Create polygon from vertices and (optional) plane without performing validation
    // Vertices may be convex or concave, but are assumed to describe a non-degenerate polygon
    // Vertices are assumed to be in anticlockwise order for the purpose of deriving the plane
    init(
        unchecked vertices: [Vertex],
        plane: Plane?,
        isConvex: Bool?,
        sanitizeNormals: Bool,
        material: Material?,
        id: Int = 0
    ) {
        assert(!verticesAreDegenerate(vertices))
        let points = vertices.map { $0.position }
        assert(isConvex == nil || pointsAreConvex(points) == isConvex)
        assert(sanitizeNormals || vertices.allSatisfy { $0.normal != .zero })
        let plane = plane ?? Plane(unchecked: points, convex: isConvex, closed: true)
        let isConvex = isConvex ?? pointsAreConvex(points)
        self.storage = Storage(
            vertices: sanitizeNormals ? vertices.map {
                $0.with(normal: $0.normal == .zero ? plane.normal : $0.normal)
            } : vertices,
            plane: plane,
            isConvex: isConvex,
            material: material
        )
        self.id = id
    }

    // Join touching polygons (without checking they are coplanar or share the same material)
    func merge(unchecked other: Polygon, ensureConvex: Bool) -> Polygon? {
        assert(material == other.material)
        assert(plane.isEqual(to: other.plane))

        // get vertices
        let va = vertices
        let vb = other.vertices

        // find shared vertices
        var joins0, joins1: (Int, Int)?
        for i in va.indices {
            if let j = vb.firstIndex(where: { $0.isEqual(to: va[i]) }) {
                if joins0 == nil {
                    joins0 = (i, j)
                } else if joins1 == nil {
                    joins1 = (i, j)
                } else {
                    // TODO: what if 3 or more points are joined?
                    return nil
                }
            }
        }
        guard let (a0, b0) = joins0, let (a1, b1) = joins1 else {
            return nil
        }
        var result: [Vertex]
        if a1 == a0 + 1 {
            result = Array(va[(a1 + 1)...] + va[..<a0])
        } else if a0 == 0, a1 == va.count - 1 {
            result = Array(va.dropFirst().dropLast())
        } else {
            return nil
        }
        let join1 = result.count
        if b1 == b0 + 1 {
            result += vb[b1...] + vb[...b0]
        } else if b0 == b1 + 1 {
            result += vb[b0...] + vb[...b1]
        } else if (b0 == 0 && b1 == vb.count - 1) || (b1 == 0 && b0 == vb.count - 1) {
            result += vb
        } else {
            return nil
        }
        let join2 = result.count - 1

        // can the merged points be removed?
        func testPoint(_ index: Int) {
            let prev = (index == 0) ? result.count - 1 : index - 1
            let va = (result[index].position - result[prev].position).normalized()
            let vb = (result[(index + 1) % result.count].position - result[index].position).normalized()
            // check if point is redundant
            if abs(va.dot(vb) - 1) < epsilon {
                // TODO: should we check that normal and uv ~= slerp of values either side?
                result.remove(at: index)
            }
        }
        testPoint(join2)
        testPoint(join1)

        // check result is not degenerate
        guard !verticesAreDegenerate(result) else {
            return nil
        }

        // check if convex
        let isConvex = verticesAreConvex(result)
        if ensureConvex, !isConvex {
            return nil
        }

        // replace poly with merged result
        return Polygon(
            unchecked: result,
            plane: plane,
            isConvex: isConvex,
            sanitizeNormals: false,
            material: material,
            id: id
        )
    }

    func edgePlane(for edge: LineSegment) -> Plane {
        let tangent = edge.end - edge.start
        let normal = tangent.cross(plane.normal).normalized()
        return Plane(unchecked: normal, pointOnPlane: edge.start)
    }

    var edgePlanes: [Plane] {
        orderedEdges.map(edgePlane(for:))
    }

    func compare(with plane: Plane) -> PlaneComparison {
        if self.plane.isEqual(to: plane) {
            return .coplanar
        }
        var comparison = PlaneComparison.coplanar
        for vertex in vertices {
            comparison = comparison.union(vertex.position.compare(with: plane))
            if comparison == .spanning {
                break
            }
        }
        return comparison
    }

    // Create copy of polygon with specified id
    func with(id: Int) -> Polygon {
        var polygon = self
        polygon.id = id
        return polygon
    }
}

private extension Polygon {
    final class Storage: Hashable {
        let vertices: [Vertex]
        let plane: Plane
        let isConvex: Bool
        var material: Material?

        static func == (lhs: Storage, rhs: Storage) -> Bool {
            lhs === rhs ||
                (lhs.vertices == rhs.vertices && lhs.material == rhs.material)
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(vertices)
        }

        init(
            vertices: [Vertex],
            plane: Plane,
            isConvex: Bool,
            material: Material?
        ) {
            self.vertices = vertices
            self.plane = plane
            self.isConvex = isConvex
            self.material = material
        }
    }
}

#if !swift(<5.7)
extension Polygon.Storage: @unchecked Sendable {}
#endif

struct CodableMaterial: Codable {
    let value: Polygon.Material?

    init(_ value: Polygon.Material?) {
        self.value = value
    }

    enum CodingKeys: CodingKey {
        case string, int, data, color, nscoded
    }

    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            if let string = try container.decodeIfPresent(String.self, forKey: .string) {
                self.value = string
            } else if let int = try container.decodeIfPresent(Int.self, forKey: .int) {
                self.value = int
            } else if let data = try container.decodeIfPresent(Data.self, forKey: .data) {
                self.value = data
            } else if let color = try container.decodeIfPresent(Color.self, forKey: .color) {
                self.value = color
            } else if let data = try container.decodeIfPresent(Data.self, forKey: .nscoded) {
                guard let value = NSKeyedUnarchiver.unarchiveObject(with: data) as? Polygon.Material else {
                    throw DecodingError.dataCorruptedError(
                        forKey: .nscoded,
                        in: container,
                        debugDescription: "Cannot decode material"
                    )
                }
                self.value = value
            } else {
                self.value = nil
            }
        } else {
            let container = try decoder.singleValueContainer()
            if let string = try? container.decode(String.self) {
                self.value = string
            } else if let int = try? container.decode(Int.self) {
                self.value = int
            } else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Cannot decode material"
                )
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        guard let value = value else { return }
        switch value {
        case let string as String:
            try string.encode(to: encoder)
        case let int as Int:
            try int.encode(to: encoder)
        case let color as Color:
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(color, forKey: .color)
        case let data as Data:
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(data, forKey: .data)
        case let object as NSCoding:
            let data = NSKeyedArchiver.archivedData(withRootObject: object)
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(data, forKey: .nscoded)
        default:
            throw EncodingError.invalidValue(value, .init(
                codingPath: encoder.codingPath,
                debugDescription: "Cannot encode material of type \(type(of: value))"
            ))
        }
    }
}
