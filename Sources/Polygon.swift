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

    /// Used to track split/join.
    var id: Int
}

extension Polygon: CustomDebugStringConvertible, CustomReflectable {
    public var debugDescription: String {
        let m = material.map { ", material: \($0)" } ?? ""
        let v = vertices.map { "\n\t\($0)," }.joined()
        return "Polygon([\(v)\n]\(m))"
    }

    public var customMirror: Mirror {
        Mirror(self, children: [
            "plane": plane,
            "isConvex": isConvex,
            "material": material as Any,
        ], displayStyle: .struct)
    }
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
            if let plane, !vertices.allSatisfy(plane.intersects) {
                throw DecodingError.dataCorruptedError(
                    forKey: .plane,
                    in: container,
                    debugDescription: "Plane is invalid"
                )
            }
            material = try container.decodeIfPresent(CodableMaterial.self, forKey: .material)?.value
        } else {
            var container = try decoder.unkeyedContainer()
            if let values = try? container.decode([Vertex].self) {
                vertices = values
                plane = try container.decodeIfPresent(Plane.self)
                if let plane, !vertices.allSatisfy(plane.intersects) {
                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "Plane is invalid"
                    )
                }
                material = try container.decodeIfPresent(CodableMaterial.self)?.value
            } else {
                let container = try decoder.singleValueContainer()
                vertices = try container.decode([Vertex].self)
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
        let positions = vertices.map(\.position)
        let positionsOnly = vertices.allSatisfy {
            $0.texcoord == .zero && $0.normal == plane.normal && $0.color == .white
        }
        if material == nil, plane.isApproximatelyEqual(to: Plane(unchecked: positions)) {
            var container = encoder.singleValueContainer()
            try positionsOnly ? container.encode(positions) : container.encode(vertices)
        } else {
            var container = encoder.unkeyedContainer()
            try positionsOnly ? container.encode(positions) : container.encode(vertices)
            try container.encode(plane)
            try material.map { try container.encode(CodableMaterial($0)) }
        }
    }
}

public extension Polygon {
    /// Material used by a given polygon.
    /// This can be any type that conforms to `Hashable`, but encoding/decoding is only supported
    /// for the following types: `Color`, `String`, `Int`, `Data` or any `NSSecureCodable` type.
    typealias Material = AnyHashable

    /// Supported `NSSecureCodable` Material base classes.
    static var codableClasses: [AnyClass] = {
        #if canImport(AppKit) || canImport(UIKit)
        return [OSImage.self, OSColor.self] + scnMaterialTypes
        #else
        return []
        #endif
    }()

    /// The array of vertices that make up the polygon.
    var vertices: [Vertex] { storage.vertices }
    /// The plane on which all vertices lie.
    var plane: Plane { storage.plane }
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
        vertices.contains(where: { !$0.normal.isApproximatelyEqual(to: plane.normal) })
    }

    /// A Boolean value that indicates whether the polygon includes vertex colors that differ from the face normal.
    var hasVertexColors: Bool {
        vertices.contains(where: { $0.color != .white })
    }

    /// The position of the center of the polygon.
    /// This is calculated as the average of the vertex positions, and may not be equal to the center of the polygon's
    /// ``bounds``.
    var center: Vector {
        vertices.reduce(.zero) { $0 + $1.position } / Double(vertices.count)
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
        return Set(vertices.compactMap {
            let p1 = $0.position
            defer { p0 = p1 }
            return LineSegment(undirected: p0, p1)
        })
    }

    /// Returns the area of the polygon.
    var area: Double {
        vertices.vectorArea.length
    }

    /// Returns the signed volume of the polygon.
    var signedVolume: Double {
        vertices.signedVolume
    }

    /// Creates a copy of the polygon with the specified material.
    /// - Parameter material: The replacement material, or `nil` to remove the material.
    func withMaterial(_ material: Material?) -> Polygon {
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
        guard vertices.count > 2, !verticesAreDegenerate(vertices),
              let plane = Plane(points: vertices.map(\.position))
        else {
            return nil
        }
        self.init(
            unchecked: vertices,
            plane: plane,
            isConvex: nil,
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
    init?(
        _ vertices: some Collection<Vector>,
        material: Material? = nil
    ) {
        self.init(vertices.map(Vertex.init), material: material)
    }

    /// Deprecated.
    @available(*, deprecated, renamed: "intersects(_:)")
    func containsPoint(_ point: Vector) -> Bool {
        intersects(point)
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
        guard plane.isApproximatelyEqual(to: other.plane) else {
            return nil
        }
        return merge(unchecked: other, ensureConvex: ensureConvex)
    }

    /// Deprecated.
    @available(*, deprecated, message: "Use array-returning version instead")
    func mapVertices(_ transform: (Vertex) -> Vertex) -> Polygon {
        Polygon(
            unchecked: vertices.map(transform),
            plane: nil,
            isConvex: nil,
            sanitizeNormals: true,
            material: material,
            id: id
        )
    }

    /// Return a copy of the polygon with transformed vertices.
    /// - Parameter transform: A closure to be applied to each vertex in the polygon.
    ///
    /// > Note: Since altering the vertices can cause the polygon to become degenerate or non-planar
    /// this method returns an array of zero or more polygons constructed from the mapped vertices.
    func mapVertices(_ transform: (Vertex) -> Vertex) -> [Polygon] {
        let vertices = vertices.map(transform)
        // TODO: is it worth checking if positions have changed as a fast path?
        return .init(vertices, material: material, id: id)
    }

    /// Return a copy of the polygon without texture coordinates
    func withoutTexcoords() -> Polygon {
        mapTexcoords { _ in .zero }
    }

    /// Return a copy of the polygon with transformed texture coordinates
    /// - Parameter transform: A closure to be applied to each texcoord in the polygon.
    func mapTexcoords(_ transform: (Vector) -> Vector) -> Polygon {
        Polygon(
            unchecked: vertices.mapTexcoords(transform),
            plane: plane,
            isConvex: isConvex,
            sanitizeNormals: false,
            material: material,
            id: id
        )
    }

    /// Return a copy of the polygon without vertex colors
    func withoutVertexColors() -> Polygon {
        mapVertexColors { _ in nil }
    }

    /// Return a copy of the polygon with transformed vertex colors
    /// - Parameter transform: A closure to be applied to each vertex color in the polygon.
    func mapVertexColors(_ transform: (Color) -> Color?) -> Polygon {
        Polygon(
            unchecked: vertices.mapColors(transform),
            plane: plane,
            isConvex: isConvex,
            sanitizeNormals: false,
            material: material,
            id: id
        )
    }

    /// Flatten vertex normals (set them to match the face normal)
    func flatteningNormals() -> Polygon {
        Polygon(
            unchecked: vertices.mapNormals { _ in plane.normal },
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

    /// Applies a uniform inset to the edges of the polygon.
    /// - Parameter distance: The distance by which to inset the polygon edges.
    /// - Returns: A copy of the polygon, inset by the specified distance.
    ///
    /// > Note: Passing a negative `distance` will expand the polygon instead of shrinking it.
    func inset(by distance: Double) -> Polygon? {
        let count = vertices.count
        var v1 = vertices[count - 1]
        var v2 = vertices[0]
        var p1p2 = v2.position - v1.position
        var n1: Vector!
        return Polygon((0 ..< count).map { i in
            v1 = v2
            v2 = i < count - 1 ? vertices[i + 1] : vertices[0]
            let p0p1 = p1p2
            p1p2 = v2.position - v1.position
            let faceNormal = plane.normal
            let n0 = n1 ?? p0p1.cross(faceNormal).normalized()
            n1 = p1p2.cross(faceNormal).normalized()
            // TODO: do we need to inset texcoord as well? If so, by how much?
            let normal = (n0 + n1).normalized()
            return v1.translated(by: normal * -(distance / n0.dot(normal)))
        })
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
        while i > 0 {
            let a = polygons[i]
            let count = a.vertices.count
            if count < maxSides {
                for j in (0 ..< i).reversed() {
                    let b = polygons[j]
                    if b.vertices.count + count - 2 <= maxSides,
                       let merged = a.merge(unchecked: polygons[j], ensureConvex: true)
                    {
                        precondition(merged.vertices.count <= maxSides)
                        precondition(merged.isConvex)
                        polygons[j] = merged
                        polygons.remove(at: i)
                        break
                    }
                }
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

    /// Subdivides triangles and quads, leaving other polygons unchanged.
    func subdivide() -> [Polygon] {
        switch vertices.count {
        case 3:
            let (a, b, c) = (vertices[0], vertices[1], vertices[2])
            let ab = a.lerp(b, 0.5)
            let bc = b.lerp(c, 0.5)
            let ca = c.lerp(a, 0.5)
            return [
                Polygon(
                    unchecked: [a, ab, ca],
                    normal: plane.normal,
                    isConvex: true,
                    sanitizeNormals: false,
                    material: material
                ),
                Polygon(
                    unchecked: [ab, b, bc],
                    normal: plane.normal,
                    isConvex: true,
                    sanitizeNormals: false,
                    material: material
                ),
                Polygon(
                    unchecked: [bc, c, ca],
                    normal: plane.normal,
                    isConvex: true,
                    sanitizeNormals: false,
                    material: material
                ),
                Polygon(
                    unchecked: [ab, bc, ca],
                    normal: plane.normal,
                    isConvex: true,
                    sanitizeNormals: false,
                    material: material
                ),
            ]
        case 4 where isConvex:
            let (a, b, c, d) = (vertices[0], vertices[1], vertices[2], vertices[3])
            let ab = a.lerp(b, 0.5)
            let bc = b.lerp(c, 0.5)
            let cd = c.lerp(d, 0.5)
            let da = d.lerp(a, 0.5)
            let abcd = ab.lerp(cd, 0.5)
            return [
                Polygon(
                    unchecked: [a, ab, abcd, da],
                    normal: plane.normal,
                    isConvex: true,
                    sanitizeNormals: false,
                    material: material
                ),
                Polygon(
                    unchecked: [ab, b, bc, abcd],
                    normal: plane.normal,
                    isConvex: true,
                    sanitizeNormals: false,
                    material: material
                ),
                Polygon(
                    unchecked: [bc, c, cd, abcd],
                    normal: plane.normal,
                    isConvex: true,
                    sanitizeNormals: false,
                    material: material
                ),
                Polygon(
                    unchecked: [cd, d, da, abcd],
                    normal: plane.normal,
                    isConvex: true,
                    sanitizeNormals: false,
                    material: material
                ),
            ]
        default:
            return [self]
        }
    }
}

extension Collection<LineSegment> {
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
                let d = Swift.max(b.start.distance(from: a.start), b.end.distance(from: a.end))
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

extension [Polygon] {
    /// Create one or more polygons from a closed loop of vertices
    init(_ vertices: [Vertex], material: Polygon.Material?, id: Int = 0) {
        if let polygon = Polygon(vertices, material: material)?.withID(id) {
            self = [polygon]
            return
        }
        self = triangulateVertices(
            vertices,
            plane: nil,
            isConvex: nil,
            sanitizeNormals: true,
            material: material,
            id: id
        ).detessellate(ensureConvex: false)
    }
}

extension Collection<Polygon> {
    /// Does any polygon include texture coordinates?
    var hasTexcoords: Bool {
        contains(where: \.hasTexcoords)
    }

    /// Does any polygon have vertex normals that differ from the face normal?
    var hasVertexNormals: Bool {
        contains(where: \.hasVertexNormals)
    }

    /// Does any polygon have vertex colors?
    var hasVertexColors: Bool {
        contains(where: \.hasVertexColors)
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

    /// Like holeEdges, but also returns the edges of double-sided polygons
    var boundingEdges: [LineSegment] {
        var edges = [LineSegment]()
        for polygon in self {
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

    /// Assuming that polygons are coplanar, determines if they form a convex boudary
    var coplanarPolygonsAreConvex: Bool {
        assert(isEmpty || allSatisfy { $0.plane.isApproximatelyEqual(to: first!.plane) })
        let boundary = Path(boundingEdges)
        return Polygon(boundary)?.isConvex ?? false
    }

    /// Returns the combined surface area of all the polygons.
    var surfaceArea: Double {
        reduce(0) { $0 + $1.area }
    }

    /// Returns the sum of the signed volumes of all the polygons.
    var signedVolume: Double {
        reduce(0) { $0 + $1.signedVolume }
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
            for point in sortedPoints where bounds.intersects(point) {
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
    /// - Parameters:
    ///   - vertices: The vertices to consider for merging. If `nil`, all vertices will be considered.
    ///   - precision: The distance threshold for merging vertices
    func mergingVertices(
        _ vertices: Set<Vector>?,
        withPrecision precision: Double
    ) -> [Polygon] {
        var positions = VertexSet(precision: precision)
        return compactMap {
            var merged = [Vertex]()
            var modified = false
            for v in $0.vertices {
                if let vertices, !vertices.contains(v.position) {
                    merged.append(v)
                    continue
                }
                let u = positions.insert(v)
                if modified || v != u {
                    modified = true
                    if let w = merged.last, w.position == u.position {
                        merged[merged.count - 1] = w.lerp(v, 0.5).withPosition(u.position)
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

    /// Flatten vertex normals (set them to match the face normal)
    func flatteningNormals() -> [Polygon] {
        map { $0.flatteningNormals() }
    }

    /// Smooth vertex normals.
    func smoothingNormals(forAnglesGreaterThan threshold: Angle) -> [Polygon] {
        guard threshold > .zero else {
            return flatteningNormals()
        }
        var polygonsByVertex = [Vector: [Polygon]]()
        forEach { polygon in
            for vertex in polygon.vertices {
                polygonsByVertex[vertex.position, default: []].append(polygon)
            }
        }
        return map { p0 in
            let n0 = p0.plane.normal
            return Polygon(
                unchecked: p0.vertices.map { v0 in
                    let polygons = polygonsByVertex[v0.position] ?? []
                    return v0.withNormal(polygons.compactMap { p1 in
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

    /// Return polygons with materials replaced by the function
    func mapMaterials(_ transform: (Polygon.Material?) -> Polygon.Material?) -> [Polygon] {
        map { $0.withMaterial(transform($0.material)) }
    }

    /// Return polygons with transformed vertices
    func mapVertices(_ transform: (Vertex) -> Vertex) -> [Polygon] {
        flatMap { $0.mapVertices(transform) }
    }

    /// Return polygons with transformed texture coordinates
    func mapTexcoords(_ transform: (Vector) -> Vector) -> [Polygon] {
        map { $0.mapTexcoords(transform) }
    }

    /// Returns a copy of the mesh with vertex colors removed.
    func withoutVertexColors() -> [Polygon] {
        mapVertexColors { _ in nil }
    }

    /// Return polygons with transformed vertex colors
    func mapVertexColors(_ transform: (Color) -> Color?) -> [Polygon] {
        map { $0.mapVertexColors(transform) }
    }

    /// Inset along face normals
    func insetFaces(by distance: Double) -> [Polygon] {
        compactMap { p0 in
            Polygon(
                p0.vertices.map { v0 in
                    var planes: [Plane] = [p0.plane]
                    for p1 in self where p1.vertices.contains(where: {
                        $0.position.isApproximatelyEqual(to: v0.position)
                    }) {
                        let plane = p1.plane
                        if !planes.contains(where: { $0.isApproximatelyEqual(to: plane) }) {
                            planes.append(plane)
                        }
                    }
                    let position: Vector
                    switch planes.count {
                    case 2:
                        let normal = planes.map(\.normal).reduce(.zero) { $0 + $1 }.normalized()
                        let distance = -(distance / p0.plane.normal.dot(normal))
                        position = v0.position.translated(by: normal * distance)
                    case 3...:
                        planes = planes.map { $0.translated(by: $0.normal * -distance) }
                        if let line = planes[0].intersection(with: planes[1]),
                           let p = line.intersection(with: planes[2])
                        {
                            position = p
                        } else {
                            fallthrough
                        }
                    default:
                        position = v0.position.translated(by: p0.plane.normal * -distance)
                    }
                    return Vertex(unchecked: position, v0.normal, v0.texcoord, v0.color)
                },
                material: p0.material
            )
        }
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
                guard a.plane.isApproximatelyEqual(to: b.plane) else {
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

    /// Subdivides triangles and quads, leaving other polygons unchanged
    func subdivide() -> [Polygon] {
        flatMap { $0.subdivide() }
    }

    /// Group polygons by plane
    func groupedByPlane() -> [(plane: Plane, polygons: [Polygon])] {
        let polygons = sorted(by: { $0.plane.w < $1.plane.w })
        guard var plane = polygons.first?.plane else {
            return []
        }
        var sorted = [(plane: Plane, polygons: [Polygon])]()
        var groups = [(plane: Plane, polygons: [Polygon])]()
        for p in polygons {
            if p.plane.w.isApproximatelyEqual(to: plane.w, absoluteTolerance: planeEpsilon) {
                if let i = groups.lastIndex(where: { $0.plane.isApproximatelyEqual(to: p.plane) }) {
                    groups[i].polygons.append(p)
                } else {
                    groups.append((p.plane, [p]))
                }
            } else {
                sorted += groups
                groups = [(p.plane, [p])]
                plane = p.plane
            }
        }
        sorted += groups
        return sorted
    }

    /// Sort polygons by plane
    func sortedByPlane() -> [Polygon] {
        groupedByPlane().flatMap(\.polygons)
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
            let positions = Set(poly.vertices.map(\.position))
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
        let count = count
        for i in 0 ..< count - 1 {
            let p = self[i]
            let plane = p.plane
            var wasSame = true
            for j in (i + 1) ..< count {
                if self[j].plane.isApproximatelyEqual(to: plane) {
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

extension Polygon {
    /// Create polygon from vertices and face normal without performing validation
    /// Vertices may be convex or concave, but are assumed to describe a non-degenerate polygon
    init(
        unchecked vertices: [Vertex],
        normal: Vector,
        isConvex: Bool?,
        sanitizeNormals: Bool,
        material: Material?
    ) {
        self.init(
            unchecked: vertices,
            plane: Plane(unchecked: normal, pointOnPlane: vertices.centroid),
            isConvex: isConvex,
            sanitizeNormals: sanitizeNormals,
            material: material,
            id: 0
        )
    }

    /// Create polygon from vertices and (optional) plane without performing validation
    /// Vertices may be convex or concave, but are assumed to describe a non-degenerate polygon
    /// Vertices are assumed to be in anticlockwise order for the purpose of deriving the plane
    init(
        unchecked vertices: [Vertex],
        plane: Plane?,
        isConvex: Bool?,
        sanitizeNormals: Bool,
        material: Material?,
        id: Int = 0
    ) {
        assert(!verticesAreDegenerate(vertices))
        let points = vertices.map(\.position)
        assert(isConvex == nil || pointsAreConvex(points) == isConvex)
        assert(sanitizeNormals || vertices.allSatisfy { $0.normal != .zero })
        let plane = plane ?? Plane(unchecked: points)
        assert(vertices.allSatisfy(plane.intersects))
        let isConvex = isConvex ?? pointsAreConvex(points)
        self.storage = Storage(
            vertices: sanitizeNormals ? vertices.map {
                $0.withNormal($0.normal == .zero ? plane.normal : $0.normal)
            } : vertices,
            plane: plane,
            isConvex: isConvex,
            material: material
        )
        self.id = id
    }

    /// Join touching polygons (without checking they are coplanar or share the same material)
    func merge(unchecked other: Polygon, ensureConvex: Bool) -> Polygon? {
        assert(material == other.material)
        assert(plane.isApproximatelyEqual(to: other.plane))

        // get vertices
        let va = vertices
        let vb = other.vertices

        // find shared vertices
        var joins0, joins1: (Int, Int)?
        for i in va.indices {
            if let j = vb.firstIndex(where: { $0.isApproximatelyEqual(to: va[i]) }) {
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
        // TODO: add option to always preserve merge points
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

        // check result is actually planar
        let isPlanar = result.allSatisfy(plane.intersects)
        if !isPlanar {
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

    /// Create copy of polygon with specified id
    func withID(_ id: Int) -> Polygon {
        var polygon = self
        polygon.id = id
        return polygon
    }

    /// Checks if a point lies inside the polygon
    /// The point must be checked to lie on the polygon plane beforehand
    func intersectsCoplanarPoint(_ point: Vector) -> Bool {
        assert(point.intersects(plane))
        // https://stackoverflow.com/questions/217578/how-can-i-determine-whether-a-2d-point-is-within-a-polygon#218081
        let flatteningPlane = FlatteningPlane(normal: plane.normal)
        let point = flatteningPlane.flattenPoint(point)
        var p0 = flatteningPlane.flattenPoint(vertices.last!.position)
        var inside = false
        for v in vertices {
            let p1 = flatteningPlane.flattenPoint(v.position)
            if (p1.y > point.y) != (p0.y > point.y),
               point.x < (p0.x - p1.x) * (point.y - p1.y) / (p0.y - p1.y) + p1.x
            {
                inside = !inside
            }
            p0 = p1
        }
        return inside
    }

    func nearestCoplanarPoint(to point: Vector) -> Vector {
        assert(point.intersects(plane))
        if intersectsCoplanarPoint(point) {
            return point
        }
        // TODO: can we use a shortcut to exit early?
        // e.g. if nearer to edge than vertex, must be closest point
        return orderedEdges.nearestPoint(to: point)
    }

    func distanceFromCoplanarPoint(_ point: Vector) -> Double {
        assert(point.intersects(plane))
        if intersectsCoplanarPoint(point) {
            return 0
        }
        // TODO: can we use a shortcut to exit early?
        // e.g. if nearer to edge than vertex, must be closest point
        return orderedEdges.distance(from: point)
    }
}

private extension Polygon {
    final class Storage: Hashable, @unchecked Sendable {
        let vertices: [Vertex]
        let plane: Plane
        let isConvex: Bool
        var material: Material?

        static func == (lhs: Storage, rhs: Storage) -> Bool {
            lhs === rhs || (lhs.vertices == rhs.vertices && lhs.material == rhs.material)
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

    /// Attempt to a add a new edge vertex at the specified location.
    /// - Returns: `true` if a point was added or `false` if it wasn't (either because point was not on the edge, or
    /// matched existing vertex)
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
            guard !verticesAreDegenerate(vertices) else {
                return false
            }
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
                guard let value = try NSKeyedUnarchiver.unarchivedObject(
                    ofClasses: Polygon.codableClasses, from: data
                ) as? Polygon.Material else {
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
        guard let value else { return }
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
            let data = try NSKeyedArchiver.archivedData(
                withRootObject: object,
                requiringSecureCoding: true
            )
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
