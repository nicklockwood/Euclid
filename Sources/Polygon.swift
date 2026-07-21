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
    nonisolated(unsafe) static var codableClasses: [AnyClass] = {
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

    /// The position of the centroid of the polygon.
    /// This is calculated as the average of the vertex positions, and may not be equal to `bounds.center`.
    var centroid: Vector {
        vertices.reduce(.zero) { $0 + $1.position } / Double(vertices.count)
    }

    /// Deprecated.
    @available(*, deprecated, renamed: "centroid")
    var center: Vector {
        centroid
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
            return LineSegment(uncheckedUndirected: p0, p1)
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
    init?(_ vertices: some Collection<Vector>, material: Material? = nil) {
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
    ///   - ensureConvex: A Boolean indicating if the resultant polygon must be convex.
    /// - Returns: The combined polygon, or `nil` if the polygons can't be merged.
    func merge(_ other: Polygon, ensureConvex: Bool = false) -> Polygon? {
        guard material == other.material,
              plane.isApproximatelyEqual(to: other.plane)
        else {
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
        // Check if changes affect shape
        for (old, new) in zip(self.vertices, vertices) where old.position != new.position {
            return .init(
                vertices,
                plane: nil,
                ensureConvex: false,
                maxSides: .max,
                material: material,
                id: id
            )
        }
        return [Polygon(
            unchecked: vertices,
            plane: plane,
            isConvex: isConvex,
            sanitizeNormals: true,
            material: material,
            id: id
        )]
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

    /// Splits a polygon into two or more convex polygons using the "ear clipping" method.
    /// - Parameter maxSides: The maximum number of sides each polygon may have.
    /// - Returns: An array of convex polygons.
    func tessellate(maxSides: Int = .max) -> [Polygon] {
        let maxSides = max(maxSides, 3)
        if vertices.count <= maxSides, isConvex {
            return [self]
        }
        let polygons = triangulate()
        if maxSides == 3 {
            return polygons
        }
        return polygons.coplanarDetessellate(ensureConvex: true, maxSides: maxSides)
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

private extension Polygon {
    /// Returns inset polygons, splitting into triangles if the moved polygon becomes invalid.
    func insetPolygons(using positionCache: [Vector: Vector], by distance: Double) -> [Polygon] {
        func moved(_ polygon: Polygon) -> Polygon? {
            let vertices = polygon.vertices.map { vertex -> Vertex in
                let key = vertex.position
                let position = positionCache[key] ?? key.translated(by: polygon.plane.normal * -distance)
                return Vertex(unchecked: position, vertex.normal, vertex.texcoord, vertex.color)
            }
            guard vertices.count > 2, !verticesAreDegenerate(vertices) else {
                return nil
            }
            return Polygon(
                unchecked: vertices,
                normal: polygon.plane.normal,
                isConvex: nil, // Inset can alter shape
                sanitizeNormals: false,
                material: polygon.material
            )
        }
        if let polygon = moved(self) {
            return [polygon]
        }
        return triangulate().compactMap(moved)
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

private struct MergeCandidate {
    let i: Int
    let j: Int
    let polygon: Polygon
    let quality: Double
    let sharedEdgeLength: Double

    func isBetter(than other: MergeCandidate) -> Bool {
        if !quality.isApproximatelyEqual(to: other.quality) {
            return quality > other.quality
        }
        if !sharedEdgeLength.isApproximatelyEqual(to: other.sharedEdgeLength) {
            return sharedEdgeLength > other.sharedEdgeLength
        }
        return false
    }
}

private struct IndexPair: Hashable {
    let i, j: Int

    init(_ i: Int, _ j: Int) {
        (self.i, self.j) = i > j ? (i, j) : (j, i)
    }
}

extension [Polygon] {
    /// Create one or more polygons from a closed loop of vertices
    init(
        _ vertices: [Vertex],
        plane: Plane? = nil,
        ensureConvex: Bool = false,
        maxSides: Int = .max,
        material: Polygon.Material?,
        id: Int = 0
    ) {
        if let polygon = Polygon(vertices, material: material)?.withID(id) {
            self = [polygon]
            return
        }
        let triangles = triangulateVertices(
            vertices,
            plane: plane,
            isConvex: nil,
            sanitizeNormals: true,
            material: material,
            id: id
        )
        let groupedByPlane = plane.map { [($0, triangles)] } ?? triangles.groupedByPlane()
        self = groupedByPlane.flatMap {
            $0.polygons.coplanarDetessellate(ensureConvex: ensureConvex, maxSides: maxSides)
        }
    }

    /// Returns a copy of the polygons with winding made consistent across shared edges.
    ///
    /// The repair is propagated through two-polygon shared edges first, then makes
    /// bounded balancing passes over non-manifold edges that are shared by more
    /// than two polygons.
    ///
    /// - Parameter isLocked: A predicate that returns `true` for polygons whose
    ///   current orientation should be preserved. Components containing locked
    ///   polygons are used as fixed references when neighboring polygons are
    ///   inverted to resolve inconsistent winding.
    /// - Returns: A copy of the receiver with polygons inverted as needed to make
    ///   shared-edge winding consistent.
    func withConsistentWinding(isLocked: (Polygon) -> Bool = { _ in false }) -> [Polygon] {
        let edgeMap = windingEdgeMap
        var adjacency = [[(index: Int, parity: Int)]](repeating: [], count: count)
        for matches in edgeMap.values where matches.count == 2 {
            let parity = -matches[0].sign * matches[1].sign
            adjacency[matches[0].index].append((matches[1].index, parity))
            adjacency[matches[1].index].append((matches[0].index, parity))
        }
        let locked = map(isLocked)
        var signs = [Int](repeating: 0, count: count)
        var componentIDs = [Int](repeating: -1, count: count)
        var components = [[Int]]()
        func addComponent(from start: Int) {
            let componentID = components.count
            var component = [Int]()
            signs[start] = 1
            componentIDs[start] = componentID
            var queue = [start]
            while let index = queue.popLast() {
                component.append(index)
                for neighbor in adjacency[index] {
                    let expectedSign = signs[index] * neighbor.parity
                    if componentIDs[neighbor.index] < 0 {
                        signs[neighbor.index] = expectedSign
                        componentIDs[neighbor.index] = componentID
                        queue.append(neighbor.index)
                    }
                }
            }
            components.append(component)
        }
        for start in indices where locked[start] && componentIDs[start] < 0 {
            addComponent(from: start)
        }
        for start in indices where componentIDs[start] < 0 {
            addComponent(from: start)
        }
        let componentIsLocked = components.map { component in
            component.contains { locked[$0] }
        }
        var componentSigns = [Int](repeating: 1, count: components.count)
        let multiEdgeMatches = inconsistentWindingEdges(in: edgeMap).compactMap {
            edgeMap[$0]
        }.filter {
            $0.count != 2
        }
        let maxPasses = multiEdgeMatches.count
        for _ in 0 ..< maxPasses {
            var changed = false
            for matches in multiEdgeMatches {
                let balance = matches.reduce(0) {
                    $0 + componentSigns[componentIDs[$1.index]] * signs[$1.index] * $1.sign
                }
                guard balance != 0 else {
                    continue
                }
                let signToFlip = balance > 0 ? 1 : -1
                if let match = matches.first(where: {
                    let componentID = componentIDs[$0.index]
                    return !componentIsLocked[componentID] &&
                        componentSigns[componentID] * signs[$0.index] * $0.sign == signToFlip
                }) {
                    componentSigns[componentIDs[match.index]] *= -1
                    changed = true
                }
            }
            if !changed {
                break
            }
        }
        return enumerated().map { index, polygon in
            let sign = signs[index] * componentSigns[componentIDs[index]]
            return sign < 0 ? polygon.inverted() : polygon
        }
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

    /// Check if polygons have consistent winding, i.e. that they are not showing any back faces.
    var areConsistentlyWound: Bool {
        inconsistentlyWoundEdges.isEmpty
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

    /// Like holeEdges, but preserves edge directionality
    /// > Note: only suitable for use with polygons that are coplanar or don't include reverse faces
    var boundingEdges: [LineSegment] {
        var edgesByInvertedEdge = [LineSegment: Int]()
        var edges = [LineSegment?]()
        for polygon in self {
            for edge in polygon.orderedEdges {
                if let index = edgesByInvertedEdge[edge] {
                    edges[index] = nil
                    edgesByInvertedEdge[edge] = nil
                } else {
                    edgesByInvertedEdge[edge.inverted()] = edges.count
                    edges.append(edge)
                }
            }
        }
        return edges.compactMap { $0 }
    }

    /// Returns all edges that are wound inconsistently.
    var inconsistentlyWoundEdges: [LineSegment] {
        inconsistentWindingEdges(in: windingEdgeMap)
    }

    /// Check if polygons all lie on the same plane.
    var areCoplanar: Bool {
        guard let plane = first?.plane else { return true }
        return allSatisfy { $0.plane.isApproximatelyEqual(to: plane) }
    }

    /// Assuming that polygons are coplanar, determines if they form a convex boudary
    var coplanarPolygonsAreConvex: Bool {
        assert(areCoplanar)
        let boundary = Path(Set(boundingEdges))
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

    /// Create copy of polygons with specified id
    func withID(_ id: Int) -> [Polygon] {
        map { $0.withID(id) }
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

        let polygons = Array(self)
        var edgesToPolygons = [LineSegment: [Int]]()
        for (index, polygon) in polygons.enumerated() {
            for edge in polygon.undirectedEdges.sorted() {
                edgesToPolygons[edge, default: []].append(index)
            }
        }

        var polygonGroups = Array(repeating: -1, count: polygons.count)
        var groupPolygons = [[Int]]()
        for start in polygons.indices where polygonGroups[start] < 0 {
            let group = groupPolygons.count
            var members = [Int]()
            var queue = [start]
            polygonGroups[start] = group
            while let index = queue.popLast() {
                members.append(index)
                for edge in polygons[index].undirectedEdges.sorted() {
                    for neighbor in edgesToPolygons[edge] ?? [] where polygonGroups[neighbor] < 0 {
                        guard polygons[index].plane.isApproximatelyEqual(to: polygons[neighbor].plane) else {
                            continue
                        }
                        polygonGroups[neighbor] = group
                        queue.append(neighbor)
                    }
                }
            }
            groupPolygons.append(members)
        }

        let groupNormals = groupPolygons.map { polygons[$0[0]].plane.normal }
        let groupWeights = groupPolygons.map { group -> Double in
            let area = group.reduce(0) { $0 + polygons[$1].area }
            return area > 0 ? area : 1
        }

        var groupsByVertex = [Vector: Set<Int>]()
        for (index, polygon) in polygons.enumerated() {
            let group = polygonGroups[index]
            for vertex in polygon.vertices {
                groupsByVertex[vertex.position, default: []].insert(group)
            }
        }

        func smoothedNormal(for group: Int, at vertex: Vector) -> Vector {
            let normal = groupNormals[group]
            let groups = (groupsByVertex[vertex] ?? [group])
                .filter {
                    angleBetweenNormalizedVectors(normal, groupNormals[$0]) < threshold
                }
                .sorted { lhs, rhs in
                    if groupNormals[lhs] != groupNormals[rhs] {
                        return groupNormals[lhs] < groupNormals[rhs]
                    }
                    if groupWeights[lhs] != groupWeights[rhs] {
                        return groupWeights[lhs] < groupWeights[rhs]
                    }
                    return lhs < rhs
                }
            let sum = groups.reduce(Vector.zero) {
                $0 + groupNormals[$1] * groupWeights[$1]
            }
            return sum == .zero ? normal : sum
        }

        return polygons.enumerated().map { index, p0 in
            let group = polygonGroups[index]
            return Polygon(
                unchecked: p0.vertices.map { v0 in
                    v0.withNormal(smoothedNormal(for: group, at: v0.position))
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
        let source = Array(self).mergingVertices(withPrecision: epsilon)
        var vertexInfo = [Vector: (planes: [Plane], neighbors: Set<Vector>)]()
        for polygon in source {
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

        var positionCache = [Vector: Vector]()
        for (position, info) in vertexInfo {
            positionCache[position] = insetPosition(
                for: position,
                planes: info.planes,
                by: distance
            )
        }
        let sourceBounds = Bounds(source.flatMap(\.vertices))
        let isConvexSurface = source.isConvexSurface
        if isConvexSurface {
            for position in positionCache.keys {
                guard let (a, b, t) = straightChain(for: position, in: vertexInfo),
                      let a1 = positionCache[a],
                      let b1 = positionCache[b]
                else {
                    continue
                }
                positionCache[position] = a1 + (b1 - a1) * t
            }
        }
        let polygons = source.flatMap { polygon in
            polygon.insetPolygons(using: positionCache, by: distance)
        }
        guard distance > 0, isConvexSurface else {
            return polygons.mergingVertices(withPrecision: epsilon)
        }
        let insetBounds = Bounds(polygons.flatMap(\.vertices))
        return sourceBounds.contains(insetBounds) ? polygons
            .mergingVertices(withPrecision: epsilon) : []
    }

    /// Returns true if all polygon vertices lie behind every face plane.
    private var isConvexSurface: Bool {
        let points = flatMap { $0.vertices.map(\.position) }
        return allSatisfy { polygon in
            points.allSatisfy { $0.signedDistance(from: polygon.plane) < epsilon }
        }
    }

    /// Finds the longest straight neighbor chain passing through a vertex.
    private func straightChain(
        for position: Vector,
        in vertexInfo: [Vector: (planes: [Plane], neighbors: Set<Vector>)]
    ) -> (Vector, Vector, Double)? {
        guard let info = vertexInfo[position] else {
            return nil
        }
        let neighbors = Array(info.neighbors)
        var best: (Vector, Vector)?
        var bestLengthSquared = 0.0
        for i in neighbors.indices {
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
    private func chainEndpoint(
        from neighbor: Vector,
        through position: Vector,
        in vertexInfo: [Vector: (planes: [Plane], neighbors: Set<Vector>)]
    ) -> Vector {
        var previous = position
        var current = neighbor
        while let next = vertexInfo[current]?.neighbors.first(where: {
            $0 != previous && pointsAreCollinear(previous, current, $0) &&
                ($0 - current).dot(current - previous) > 0
        }) {
            previous = current
            current = next
        }
        return current
    }

    /// Calculates the inset position produced by offsetting the adjacent planes.
    private func insetPosition(for position: Vector, planes: [Plane], by distance: Double) -> Vector {
        let planes = planes.map { $0.translated(by: $0.normal * -distance) }
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
            return bestFitIntersection(of: planes) ?? position
        default:
            return bestFitIntersection(of: planes) ?? position
        }
    }

    /// Finds the least-squares intersection point for a set of planes.
    private func bestFitIntersection(of planes: [Plane]) -> Vector? {
        var m00 = 0.0, m01 = 0.0, m02 = 0.0
        var m11 = 0.0, m12 = 0.0, m22 = 0.0
        var b0 = 0.0, b1 = 0.0, b2 = 0.0
        for plane in planes {
            let n = plane.normal
            m00 += n.x * n.x
            m01 += n.x * n.y
            m02 += n.x * n.z
            m11 += n.y * n.y
            m12 += n.y * n.z
            m22 += n.z * n.z
            b0 += n.x * plane.w
            b1 += n.y * plane.w
            b2 += n.z * plane.w
        }
        let determinant = m00 * (m11 * m22 - m12 * m12) -
            m01 * (m01 * m22 - m12 * m02) +
            m02 * (m01 * m12 - m11 * m02)
        guard abs(determinant) > epsilon else {
            return nil
        }
        return Vector(
            (b0 * (m11 * m22 - m12 * m12) -
                m01 * (b1 * m22 - m12 * b2) +
                m02 * (b1 * m12 - m11 * b2)) / determinant,
            (m00 * (b1 * m22 - m12 * b2) -
                b0 * (m01 * m22 - m12 * m02) +
                m02 * (m01 * b2 - b1 * m02)) / determinant,
            (m00 * (m11 * b2 - b1 * m12) -
                m01 * (m01 * b2 - b1 * m02) +
                b0 * (m01 * m12 - m11 * m02)) / determinant
        )
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

    /// Merge polygons
    ///
    /// - Parameters:
    ///   - useQualityMerge: When `true`, prefer the best available merge candidate to preserve polygon
    ///     quality when the other detessellation options permit it. When `false`, use the faster greedy
    ///     merge path.
    ///   - allowDisjointSharedVertices: When `true`, allow polygons to merge across multiple separated
    ///     shared vertex chains. When `false`, only merge polygons whose shared vertices form a single
    ///     contiguous shared boundary.
    func detessellate(
        ensureConvex: Bool,
        maxSides: Int = .max,
        useQualityMerge: Bool = true,
        allowDisjointSharedVertices: Bool = true
    ) -> [Polygon] {
        groupedByMaterial().flatMap {
            $0.polygons.groupedByPlane().flatMap {
                $0.polygons.coplanarDetessellate(
                    ensureConvex: ensureConvex,
                    maxSides: maxSides,
                    useQualityMerge: useQualityMerge,
                    allowDisjointSharedVertices: allowDisjointSharedVertices
                )
            }
        }
    }

    /// Merge coplanar polygons that share one or more edges
    ///
    /// - Parameters:
    ///   - useQualityMerge: When `true`, prefer the best available merge candidate to preserve polygon
    ///     quality when the other detessellation options permit it. When `false`, use the faster greedy
    ///     merge path.
    ///   - allowDisjointSharedVertices: When `true`, allow polygons to merge across multiple separated
    ///     shared vertex chains. When `false`, only merge polygons whose shared vertices form a single
    ///     contiguous shared boundary.
    func coplanarDetessellate(
        ensureConvex: Bool,
        maxSides: Int,
        useQualityMerge: Bool = true,
        allowDisjointSharedVertices: Bool = true
    ) -> [Polygon] {
        assert(areCoplanar)
        assert(allSatisfy { $0.material == first?.material })
        assert(allSatisfy { $0.vertices.count <= maxSides })
        assert(!ensureConvex || allSatisfy(\.isConvex))

        var polygons = Array(self)
        let shouldUseQualityMerge = useQualityMerge && allowDisjointSharedVertices && maxSides == .max && !ensureConvex
        guard shouldUseQualityMerge else {
            return polygons.greedyDetessellate(
                ensureConvex: ensureConvex,
                maxSides: maxSides,
                allowDisjointSharedVertices: allowDisjointSharedVertices,
                insertingEdgeVertices: allowDisjointSharedVertices
            )
        }
        let maxQualityDetessellationPolygons = 64
        if polygons.count > maxQualityDetessellationPolygons {
            polygons = polygons.greedyDetessellate(
                ensureConvex: ensureConvex,
                maxSides: maxSides,
                allowDisjointSharedVertices: allowDisjointSharedVertices
            )
            polygons.alignSharedEdgePoints()
            return polygons.greedyDetessellate(
                ensureConvex: ensureConvex,
                maxSides: maxSides,
                allowDisjointSharedVertices: allowDisjointSharedVertices
            )
        }
        while let candidate = polygons.bestMergeCandidate(
            ensureConvex: ensureConvex,
            maxSides: maxSides,
            allowDisjointSharedVertices: allowDisjointSharedVertices
        ) {
            polygons[candidate.i] = candidate.polygon
            polygons.remove(at: candidate.j)
        }
        polygons.alignSharedEdgePoints()
        while let candidate = polygons.bestMergeCandidate(
            ensureConvex: ensureConvex,
            maxSides: maxSides,
            allowDisjointSharedVertices: allowDisjointSharedVertices
        ) {
            polygons[candidate.i] = candidate.polygon
            polygons.remove(at: candidate.j)
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
                if let i = groups.lastIndex(where: {
                    $0.plane.isApproximatelyEqual(to: p.plane)
                        && p.vertices.allSatisfy($0.plane.intersects)
                }) {
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

    /// Group by material
    func groupedByMaterial() -> [(Polygon.Material?, polygons: [Polygon])] {
        var indicesByMaterial = [Polygon.Material?: Int]()
        var polygonsByMaterial = [(Polygon.Material?, polygons: [Polygon])]()
        for polygon in self {
            if let index = indicesByMaterial[polygon.material] {
                polygonsByMaterial[index].polygons.append(polygon)
            } else {
                indicesByMaterial[polygon.material] = polygonsByMaterial.count
                polygonsByMaterial.append((polygon.material, [polygon]))
            }
        }
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

private extension [Polygon] {
    /// Repeatedly merge the first compatible polygon pairs until no more matches are found
    ///
    /// - Parameters:
    ///   - allowDisjointSharedVertices: When `true`, allow polygon pairs to merge across multiple
    ///     separated shared vertex chains. When `false`, only merge pairs whose shared vertices form a
    ///     single contiguous shared boundary.
    ///   - insertingEdgeVertices: When `true`, insert matching vertices along shared edges before each
    ///     merge pass when the detessellation constraints permit it, allowing neighboring polygons with
    ///     subdivided edges to merge.
    func greedyDetessellate(
        ensureConvex: Bool,
        maxSides: Int,
        allowDisjointSharedVertices: Bool = true,
        insertingEdgeVertices: Bool = false
    ) -> [Polygon] {
        let shouldInsertEdgeVertices = insertingEdgeVertices && !ensureConvex && maxSides == .max
        var polygons = self
        var shouldContinue = true
        while shouldContinue {
            shouldContinue = false
            if shouldInsertEdgeVertices {
                polygons = polygons.insertingEdgeVertices(with: polygons.uniqueEdges)
            }
            var i = polygons.count - 1
            while i > 0 {
                let a = polygons[i]
                let count = a.vertices.count
                if count <= maxSides {
                    for j in (0 ..< i).reversed() {
                        let b = polygons[j]
                        let combinedCount = b.vertices.count + count - 2
                        if shouldInsertEdgeVertices || combinedCount - 2 <= maxSides,
                           let merged = a.merge(
                               unchecked: b,
                               ensureConvex: ensureConvex,
                               allowDisjointSharedVertices: allowDisjointSharedVertices
                           ),
                           merged.vertices.count <= maxSides
                        {
                            polygons[i] = merged
                            polygons.remove(at: j)
                            shouldContinue = true
                            break
                        }
                    }
                }
                i -= 1
            }
        }
        return polygons
    }

    /// Insert matching edge points into neighboring polygons
    mutating func alignSharedEdgePoints() {
        var points = Set<Vector>()
        for polygon in self {
            for vertex in polygon.vertices {
                points.insert(vertex.position)
            }
        }
        let sortedPoints = points.sorted()
        for i in indices {
            let bounds = self[i].bounds.inset(by: -epsilon)
            self[i].insertEdgePoints(sortedPoints.filter { bounds.intersects($0) })
        }
    }

    /// Find the best currently mergeable polygon pair
    ///
    /// - Parameter allowDisjointSharedVertices: When `true`, consider polygon pairs that share multiple
    ///   separated vertex chains. When `false`, only consider pairs whose shared vertices form a single
    ///   contiguous shared boundary.
    func bestMergeCandidate(
        ensureConvex: Bool,
        maxSides: Int,
        allowDisjointSharedVertices: Bool
    ) -> MergeCandidate? {
        var best: MergeCandidate?
        for pair in mergeCandidatePairs {
            let a = self[pair.i], b = self[pair.j]
            guard let merged = a.merge(
                unchecked: b,
                ensureConvex: ensureConvex,
                allowDisjointSharedVertices: allowDisjointSharedVertices
            ),
                merged.vertices.count <= maxSides
            else {
                continue
            }
            let candidate = MergeCandidate(
                i: pair.i,
                j: pair.j,
                polygon: merged,
                quality: merged.detessellationQuality,
                sharedEdgeLength: a.sharedEdgeLength(with: b)
            )
            if best.map({ candidate.isBetter(than: $0) }) ?? true {
                best = candidate
            }
        }
        return best
    }

    /// Polygon pairs with at least two matching vertex positions.
    ///
    /// A valid merge still goes through `merge(unchecked:ensureConvex:)`; this
    /// only avoids trying pairs that cannot share a complete edge.
    var mergeCandidatePairs: [IndexPair] {
        var indicesByVertex = [Vector: [Int]]()
        for (index, polygon) in enumerated() {
            for position in Set(polygon.vertices.map(\.position)) {
                indicesByVertex[position, default: []].append(index)
            }
        }

        var sharedVertexCounts = [IndexPair: Int]()
        for indices in indicesByVertex.values where indices.count > 1 {
            for a in indices.indices.dropFirst() {
                for b in indices.indices[..<a] {
                    sharedVertexCounts[IndexPair(indices[a], indices[b]), default: 0] += 1
                }
            }
        }

        return sharedVertexCounts.compactMap { pair, count in
            count > 1 ? pair : nil
        }.sorted {
            $0.i == $1.i ? $0.j > $1.j : $0.i > $1.i
        }
    }
}

private extension Collection<Polygon> {
    typealias EdgeIndexMap = [LineSegment: [(index: Index, sign: Int)]]

    /// Returns a map of undirected polygon edges to the polygons that contain them.
    ///
    /// Each map value preserves the collection index for the containing polygon
    /// and a sign indicating whether that polygon uses the normalized edge
    /// direction (`1`) or the opposite direction (`-1`).
    var windingEdgeMap: EdgeIndexMap {
        var edgeMap = EdgeIndexMap()
        for index in indices {
            for edge in self[index].orderedEdges {
                let undirectedEdge = LineSegment(undirected: edge)
                let sign = edge == undirectedEdge ? 1 : -1
                edgeMap[undirectedEdge, default: []].append((index, sign))
            }
        }
        return edgeMap
    }

    /// Returns edges whose matched polygon directions do not balance.
    ///
    /// Consistently wound two-polygon edges have one `1` sign and one `-1` sign.
    /// Non-manifold edges are considered balanced when their signed uses sum to
    /// zero.
    ///
    /// - Parameter edgeMap: A map produced by `windingEdgeMap`.
    /// - Returns: The undirected edges whose signed uses do not cancel out.
    func inconsistentWindingEdges(in edgeMap: EdgeIndexMap) -> [LineSegment] {
        edgeMap.compactMap { edge, matches in
            let balance = matches.reduce(0) { $0 + $1.sign }
            return balance == 0 ? nil : edge
        }
    }
}

private extension Collection<Polygon> where Index == Int {
    /// Merge coplanar polygons that share one or more edges
    /// > Note: this method is On^2 - do not use outside of debug mode
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
        plane _plane: Plane?,
        isConvex: Bool?,
        sanitizeNormals: Bool,
        material: Material?,
        id: Int = 0
    ) {
        assert(!verticesAreDegenerate(vertices))
        let points = vertices.map(\.position)
        assert(isConvex == nil || pointsAreConvex(points) == isConvex)
        assert(sanitizeNormals || vertices.allSatisfy { $0.normal != .zero })
        let plane = _plane ?? Plane(unchecked: points)
        assert(_plane?.isApproximatelyEqual(to: plane) ?? true)
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

    /// Join touching polygons (without checking they are coplanar)
    ///
    /// - Parameter allowDisjointSharedVertices: When `true`, allow the polygons to share additional
    ///   matching vertices outside the chosen merge boundary, provided the merged area still matches the
    ///   source area. When `false`, require all shared vertices to lie on one contiguous boundary chain.
    func merge(
        unchecked other: Polygon,
        ensureConvex: Bool,
        allowDisjointSharedVertices: Bool = true
    ) -> Polygon? {
        assert(material == other.material)
        // TODO: figure out why this can fail while plane.intersects passes
        // assert(plane.isApproximatelyEqual(to: other.plane))
        assert(other.vertices.allSatisfy(plane.intersects))

        // get vertices
        let va = vertices
        let vb = other.vertices

        // find shared boundary chain
        let matches = va.indices.compactMap { i -> (a: Int, b: Int)? in
            guard let j = vb.firstIndex(where: { $0.isApproximatelyEqual(to: va[i]) }) else {
                return nil
            }
            return (i, j)
        }
        guard matches.count >= 2 else {
            return nil
        }
        guard allowDisjointSharedVertices || matches.count == 2 else {
            return nil
        }

        var result: [Vertex]
        let join1: Int
        let join2: Int
        if matches.count == 2 {
            let (a0, b0) = matches[0]
            let (a1, b1) = matches[1]
            var merged: [Vertex]
            if a1 == a0 + 1 {
                merged = Array(va[(a1 + 1)...] + va[..<a0])
            } else if a0 == 0, a1 == va.count - 1 {
                merged = Array(va.dropFirst().dropLast())
            } else {
                return nil
            }
            join1 = merged.count
            if b1 == b0 + 1 {
                merged += vb[b1...] + vb[...b0]
            } else if b0 == b1 + 1 {
                merged += vb[b0...] + vb[...b1]
            } else if (b0 == 0 && b1 == vb.count - 1) || (b1 == 0 && b0 == vb.count - 1) {
                merged += vb
            } else {
                return nil
            }
            result = merged
            join2 = result.count - 1
        } else {
            let matchingBIndexByA = Dictionary(uniqueKeysWithValues: matches.map { ($0.a, $0.b) })
            var bestChain: [(a: Int, b: Int)]?
            for match in matches {
                var chain = [match]
                while chain.count < matches.count {
                    let nextA = (chain.last!.a + 1) % va.count
                    let nextB = (chain.last!.b + vb.count - 1) % vb.count
                    guard matchingBIndexByA[nextA] == nextB else {
                        break
                    }
                    chain.append((nextA, nextB))
                }
                if chain.count > (bestChain?.count ?? 0) {
                    bestChain = chain
                }
            }

            guard let sharedChain = bestChain,
                  sharedChain.count >= 2,
                  allowDisjointSharedVertices || sharedChain.count == matches.count
            else {
                return nil
            }

            func verticesBetween(in source: [Vertex], after start: Int, before end: Int) -> [Vertex] {
                var result = [Vertex]()
                var index = (start + 1) % source.count
                while index != end {
                    result.append(source[index])
                    index = (index + 1) % source.count
                }
                return result
            }

            func verticesThrough(in source: [Vertex], from start: Int, through end: Int) -> [Vertex] {
                var result = [source[start]]
                var index = start
                while index != end {
                    index = (index + 1) % source.count
                    result.append(source[index])
                }
                return result
            }

            let (a0, b0) = sharedChain.first!
            let (a1, b1) = sharedChain.last!
            var merged = verticesBetween(in: va, after: a1, before: a0)
            join1 = merged.count
            merged += verticesThrough(in: vb, from: b0, through: b1)
            result = merged
            join2 = result.count - 1
        }

        // check result is not degenerate
        guard !verticesAreDegenerate(result) else {
            return nil
        }
        if allowDisjointSharedVertices {
            let mergedArea = result.vectorArea.length
            let sourceArea = area + other.area
            if !mergedArea.isApproximatelyEqual(
                to: sourceArea,
                absoluteTolerance: max(epsilon, sourceArea * 1e-6)
            ) {
                let triangulatedArea = triangulateVertices(
                    result,
                    plane: plane,
                    isConvex: nil,
                    sanitizeNormals: false,
                    material: material,
                    id: id
                ).surfaceArea
                guard triangulatedArea.isApproximatelyEqual(
                    to: sourceArea,
                    absoluteTolerance: max(epsilon, sourceArea * 1e-6)
                ) else {
                    return nil
                }
            }
        }

        // Check if merged points can be removed
        // TODO: add option to always preserve merged points
        _ = result.removeIfRedundant(at: max(join1, join2))
        _ = result.removeIfRedundant(at: min(join1, join2))

        // Reject non-simple polygons that loop back through an existing vertex.
        for i in result.indices.dropFirst() {
            if result[..<i].contains(where: { $0.position.isApproximatelyEqual(to: result[i].position) }) {
                return nil
            }
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

    /// A heuristic score used to prefer compact, evenly proportioned detessellation results.
    var detessellationQuality: Double {
        let edges = orderedEdges
        let perimeter = edges.reduce(0) { $0 + $1.length }
        guard perimeter > epsilon else {
            return 0
        }
        let longestEdge = edges.reduce(0) { Swift.max($0, $1.length) }
        let shortestEdge = edges.reduce(Double.infinity) { Swift.min($0, $1.length) }
        let compactness = area / (perimeter * perimeter)
        let edgeRatio = shortestEdge.isFinite && longestEdge > epsilon ? shortestEdge / longestEdge : 0
        return compactness + edgeRatio * 0.01
    }

    /// Returns the total length of all undirected edges shared with another polygon.
    func sharedEdgeLength(with other: Polygon) -> Double {
        let otherEdges = other.undirectedEdges
        return undirectedEdges.reduce(0) { length, edge in
            otherEdges.contains(edge) ? length + edge.length : length
        }
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
            assert(plane.intersects(vertex))
            var vertices = vertices
            vertices.insert(vertex, at: i)
            guard !verticesAreDegenerate(vertices) else {
                return false
            }
            self = Polygon(
                unchecked: vertices,
                plane: plane,
                isConvex: nil, // Inserting a point can alter convexity
                sanitizeNormals: false,
                material: material,
                id: id
            )
            return true
        }
        return false
    }

    /// Attempt to add new edge vertices at the specified locations in a single pass.
    mutating func insertEdgePoints(_ points: [Vector]) {
        guard var last = vertices.last else {
            assertionFailure()
            return
        }
        var result = [Vertex]()
        var didInsert = false
        result.reserveCapacity(vertices.count + points.count)
        let points = points.filter { point in
            !vertices.contains(where: { $0.position.isApproximatelyEqual(to: point) })
        }

        for v in vertices {
            let edge = LineSegment(unchecked: last.position, v.position)
            let edgePoints = points.compactMap { p -> (point: Vector, t: Double)? in
                guard edge.intersects(p) else {
                    return nil
                }
                let t = p.distance(from: edge.start) / edge.length
                return (p, t)
            }.sorted { $0.t < $1.t }
            for point in edgePoints {
                let vertex = last.lerp(v, point.t)
                guard !vertex.isApproximatelyEqual(to: last),
                      !vertex.isApproximatelyEqual(to: v),
                      result.last.map({ !$0.isApproximatelyEqual(to: vertex) }) ?? true
                else {
                    continue
                }
                assert(plane.intersects(vertex))
                result.append(vertex)
                didInsert = true
            }
            result.append(v)
            last = v
        }

        guard didInsert, !verticesAreDegenerate(result) else {
            return
        }
        self = Polygon(
            unchecked: result,
            plane: plane,
            isConvex: nil, // Inserting points can alter convexity
            sanitizeNormals: false,
            material: material,
            id: id
        )
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
