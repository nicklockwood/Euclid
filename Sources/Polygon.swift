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

/// A planar polygon in 3D space.
///
/// A polygon must be composed of three or more ``Vertex``, and those vertices must all lie in the same plane.
/// The edge of a polygon can be either convex or concave, but not self-intersecting.
public struct Polygon: Hashable {
    private var storage: Storage

    // Used to track split/join
    var id: Int
}

extension Polygon: Codable {
    private enum CodingKeys: CodingKey {
        case vertices, plane, material
    }

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

    public func encode(to encoder: Encoder) throws {
        let positions = vertices.map { $0.position }
        if material == nil, plane == Plane(unchecked: positions, convex: isConvex) {
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
    /// Material used by a given polygon
    typealias Material = AnyHashable

    /// Public properties
    var vertices: [Vertex] { storage.vertices }
    var plane: Plane { storage.plane }
    var bounds: Bounds { Bounds(points: vertices.map { $0.position }) }
    var isConvex: Bool { storage.isConvex }
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

    /// Does polygon include texture coordinates?
    var hasTexcoords: Bool {
        vertices.contains(where: { $0.texcoord != .zero })
    }

    /// Does polygon include vertex colors?
    var hasVertexColors: Bool {
        vertices.contains(where: { $0.color != .white })
    }

    /// Returns a set of polygon edges
    /// The direction of each edge is normalized relative to the origin to facilitate edge-equality comparisons
    var undirectedEdges: Set<LineSegment> {
        var p0 = vertices.last!.position
        return Set(vertices.map {
            let p1 = $0.position
            defer { p0 = p1 }
            return LineSegment(normalized: p0, p1)
        })
    }

    /// Create copy of polygon with specified material
    func with(material: Material?) -> Polygon {
        var polygon = self
        polygon.material = material
        return polygon
    }

    /// Create a polygon from a set of vertices
    /// Polygon can be convex or concave, but vertices must be coplanar and non-degenerate
    /// Vertices are assumed to be in anticlockwise order for the purpose of deriving the plane
    init?(_ vertices: [Vertex], material: Material? = nil) {
        let positions = vertices.map { $0.position }
        let isConvex = pointsAreConvex(positions)
        guard positions.count > 2, !pointsAreSelfIntersecting(positions),
              // Note: Plane init includes check for degeneracy
              let plane = Plane(points: positions, convex: isConvex)
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

    /// Create a polygon from a set of vertex positions
    /// Vertex normals will be set to match face normal
    init?(_ vertices: [Vector], material: Material? = nil) {
        self.init(vertices.map { Vertex($0) }, material: material)
    }

    /// Test if point lies inside the polygon
    func containsPoint(_ p: Vector) -> Bool {
        guard plane.containsPoint(p) else {
            return false
        }
        // https://stackoverflow.com/questions/217578/how-can-i-determine-whether-a-2d-point-is-within-a-polygon#218081
        let flatteningPlane = FlatteningPlane(normal: plane.normal)
        let points = vertices.map { flatteningPlane.flattenPoint($0.position) }
        let p = flatteningPlane.flattenPoint(p)
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

    /// Merge with another polygon, removing redundant vertices if possible
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

    /// Flip the polygon along its plane
    func inverted() -> Polygon {
        Polygon(
            unchecked: vertices.reversed().map { $0.inverted() },
            plane: plane.inverted(),
            isConvex: isConvex,
            material: material,
            id: id
        )
    }

    /// Converts a concave polygon into 2 or more convex polygons using the "ear clipping" method
    func tessellate() -> [Polygon] {
        if isConvex {
            return [self]
        }
        var polygons = triangulate()
        var i = polygons.count - 1
        while i > 0 {
            let a = polygons[i]
            let b = polygons[i - 1]
            if let merged = a.merge(unchecked: b, ensureConvex: true) {
                polygons[i - 1] = merged
                polygons.remove(at: i)
            }
            i -= 1
        }
        return polygons
    }

    /// Tessellates polygon into triangles using the "ear clipping" method
    func triangulate() -> [Polygon] {
        guard vertices.count > 3 else {
            return [self]
        }
        return triangulateVertices(
            vertices,
            plane: plane,
            isConvex: isConvex,
            material: material,
            id: id
        )
    }
}

internal extension Collection where Element == Polygon {
    /// Does any polygon include texture coordinates?
    var hasTexcoords: Bool {
        contains(where: { $0.hasTexcoords })
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
        var edgeCounts = [LineSegment: Int]()
        for polygon in self {
            for edge in polygon.undirectedEdges {
                edgeCounts[edge, default: 0] += 1
            }
        }
        return edgeCounts.values.allSatisfy { $0 >= 2 && $0 % 2 == 0 }
    }

    /// Insert missing vertices needed to prevent hairline cracks
    func makeWatertight() -> [Polygon] {
        var polygonsByEdge = [LineSegment: Int]()
        for polygon in self {
            for edge in polygon.undirectedEdges {
                polygonsByEdge[edge, default: 0] += 1
            }
        }
        var points = Set<Vector>()
        let edges = polygonsByEdge.filter { !$0.value.isMultiple(of: 2) }.keys
        for edge in edges.sorted() {
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

    /// Flip each polygon along its plane
    func inverted() -> [Polygon] {
        map { $0.inverted() }
    }

    /// Decompose each concave polygon into 2 or more convex polygons
    func tessellate() -> [Polygon] {
        flatMap { $0.tessellate() }
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

    /// Sort polygons by plane
    func sortedByPlane() -> [Polygon] {
        sorted(by: { $0.plane < $1.plane })
    }

    /// Group by material
    func groupedByMaterial() -> [Polygon.Material?: [Polygon]] {
        var polygonsByMaterial = [Polygon.Material?: [Polygon]]()
        forEach { polygonsByMaterial[$0.material, default: []].append($0) }
        return polygonsByMaterial
    }
}

internal extension MutableCollection where Element == Polygon, Index == Int {
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

internal extension Polygon {
    // Create polygon from vertices and face normal without performing validation
    // Vertices may be convex or concave, but are assumed to describe a non-degenerate polygon
    init(
        unchecked vertices: [Vertex],
        normal: Vector,
        isConvex: Bool,
        material: Material?
    ) {
        self.init(
            unchecked: vertices,
            plane: Plane(unchecked: normal, pointOnPlane: vertices[0].position),
            isConvex: isConvex,
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
        sanitizeNormals: Bool = false,
        material: Material?,
        id: Int = 0
    ) {
        assert(!verticesAreDegenerate(vertices))
        let points = vertices.map { $0.position }
        assert(isConvex == nil || pointsAreConvex(points) == isConvex)
        assert(sanitizeNormals || vertices.allSatisfy { $0.normal != .zero })
        let plane = plane ?? Plane(unchecked: points, convex: isConvex)
        let isConvex = isConvex ?? pointsAreConvex(points)
        self.storage = Storage(
            vertices: vertices.map {
                $0.with(normal: $0.normal == .zero ? plane.normal : $0.normal)
            },
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
            material: material,
            id: id
        )
    }

    var edgePlanes: [Plane] {
        var planes = [Plane]()
        var p0 = vertices.last!.position
        for v1 in vertices {
            let p1 = v1.position
            let tangent = p1 - p0
            let normal = tangent.cross(plane.normal).normalized()
            guard let plane = Plane(normal: normal, pointOnPlane: p0) else {
                assertionFailure()
                return []
            }
            planes.append(plane)
            p0 = p1
        }
        return planes
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

    func clip(
        to polygons: [Polygon],
        _ inside: inout [Polygon],
        _ outside: inout [Polygon],
        _ id: inout Int
    ) {
        var toTest = tessellate()
        for polygon in polygons.tessellate() where !toTest.isEmpty {
            var _outside = [Polygon]()
            toTest.forEach { polygon.clip($0, &inside, &_outside, &id) }
            toTest = _outside
        }
        outside += toTest
    }

    func clip(
        _ polygon: Polygon,
        _ inside: inout [Polygon],
        _ outside: inout [Polygon],
        _ id: inout Int
    ) {
        assert(isConvex)
        var polygon = polygon
        var coplanar = [Polygon]()
        for plane in edgePlanes {
            var back = [Polygon]()
            polygon.split(along: plane, &coplanar, &outside, &back, &id)
            guard let p = back.first else {
                return
            }
            polygon = p
        }
        inside.append(polygon)
    }

    // Put the polygon in the correct list, splitting it when necessary
    func split(
        along plane: Plane,
        _ coplanar: inout [Polygon],
        _ front: inout [Polygon],
        _ back: inout [Polygon],
        _ id: inout Int
    ) {
        switch compare(with: plane) {
        case .coplanar:
            coplanar.append(self)
        case .front:
            front.append(self)
        case .back:
            back.append(self)
        case .spanning:
            split(spanning: plane, &front, &back, &id)
        }
    }

    func split(
        spanning plane: Plane,
        _ front: inout [Polygon],
        _ back: inout [Polygon],
        _ id: inout Int
    ) {
        assert(compare(with: plane) == .spanning)
        var polygon = self
        if polygon.id == 0 {
            id += 1
            polygon.id = id
        }
        guard polygon.isConvex else {
            var coplanar = [Polygon]()
            polygon.tessellate().forEach {
                $0.split(along: plane, &coplanar, &front, &back, &id)
            }
            return
        }
        var f = [Vertex](), b = [Vertex]()
        var v0 = polygon.vertices.last!, t0 = v0.position.compare(with: plane)
        for v1 in polygon.vertices {
            if t0 != .back {
                f.append(v0)
            }
            if t0 != .front {
                b.append(v0)
            }
            let t1 = v1.position.compare(with: plane)
            if t0.union(t1) == .spanning {
                let t = (plane.w - plane.normal.dot(v0.position)) /
                    plane.normal.dot(v1.position - v0.position)
                let v = v0.lerp(v1, t)
                if f.last?.position != v.position, f.first?.position != v.position {
                    f.append(v)
                }
                if b.last?.position != v.position, b.first?.position != v.position {
                    b.append(v)
                }
            }
            v0 = v1
            t0 = t1
        }
        if !verticesAreDegenerate(f) {
            front.append(Polygon(
                unchecked: f,
                plane: polygon.plane,
                isConvex: true,
                material: material,
                id: polygon.id
            ))
        }
        if !verticesAreDegenerate(b) {
            back.append(Polygon(
                unchecked: b,
                plane: polygon.plane,
                isConvex: true,
                material: material,
                id: polygon.id
            ))
        }
    }

    // Return all intersections with the plane
    func intersect(with plane: Plane, edges: inout Set<LineSegment>) {
        var wasFront = false, wasBack = false
        for edge in undirectedEdges {
            switch edge.compare(with: plane) {
            case .front where wasBack, .back where wasFront, .spanning:
                intersect(spanning: plane, intersections: &edges)
                return
            case .coplanar:
                edges.insert(edge)
            case .front:
                wasFront = true
            case .back:
                wasBack = true
            }
        }
    }

    func intersect(spanning plane: Plane, intersections: inout Set<LineSegment>) {
        assert(compare(with: plane) == .spanning)
        guard isConvex else {
            tessellate().forEach {
                $0.intersect(spanning: plane, intersections: &intersections)
            }
            return
        }
        var start: Vector?
        var p0 = vertices.last!.position, t0 = p0.compare(with: plane)
        for v in vertices {
            let p1 = v.position, t1 = p1.compare(with: plane)
            if t0 == .coplanar || t0.union(t1) == .spanning {
                let t = (plane.w - plane.normal.dot(p0)) / plane.normal.dot(p1 - p0)
                let p = p0.lerp(p1, t)
                if let start = start {
                    intersections.insert(LineSegment(normalized: start, p))
                    return
                }
                start = p
            }
            p0 = p1
            t0 = t1
        }
        assertionFailure()
    }

    mutating func insertEdgePoint(_ p: Vector) -> Bool {
        guard var last = vertices.last else {
            assertionFailure()
            return false
        }
        if vertices.contains(where: { $0.position == p }) {
            return false
        }
        for (i, v) in vertices.enumerated() {
            let s = LineSegment(unchecked: last.position, v.position)
            guard s.containsPoint(p) else {
                last = v
                continue
            }
            var vertices = self.vertices
            let t = (p - s.start).length / s.length
            vertices.insert(last.lerp(v, t), at: i)
            self = Polygon(
                unchecked: vertices,
                plane: plane,
                isConvex: isConvex,
                material: material,
                id: id
            )
            return true
        }
        return false
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

internal struct CodableMaterial: Codable {
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
