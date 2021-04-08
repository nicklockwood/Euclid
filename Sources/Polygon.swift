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

/// A planar polygon
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
            guard vertices.count > 2, !verticesAreDegenerate(vertices) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .vertices,
                    in: container,
                    debugDescription: "Vertices are degenerate"
                )
            }
            plane = try container.decodeIfPresent(Plane.self, forKey: .plane)
            material = try container.decodeIfPresent(CodableMaterial.self, forKey: .material)?.value
        } else {
            vertices = try [Vertex](from: decoder)
            guard vertices.count > 2, !verticesAreDegenerate(vertices) else {
                throw DecodingError.dataCorruptedError(
                    in: try decoder.unkeyedContainer(),
                    debugDescription: "Vertices are degenerate"
                )
            }
        }
        self.init(unchecked: vertices, plane: plane, material: material)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(vertices, forKey: .vertices)
        if let material = material {
            try container.encode(CodableMaterial(material), forKey: .material)
        }
        if plane != Plane(points: vertices.map { $0.position }) {
            try container.encode(plane, forKey: .plane)
        }
    }
}

public extension Polygon {
    /// Material used by a given polygon
    typealias Material = AnyHashable

    /// Public properties
    var vertices: [Vertex] { storage.vertices }
    var plane: Plane { storage.plane }
    var bounds: Bounds { storage.bounds }
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
                    bounds: bounds,
                    isConvex: isConvex,
                    material: newValue
                )
            }
        }
    }

    /// Create a polygon from a set of vertices
    /// Polygon can be convex or concave, but vertices must be coplanar and non-degenerate
    /// Vertices are assumed to be in anticlockwise order for the purpose of deriving the plane
    init?(_ vertices: [Vertex], material: Material? = nil) {
        guard vertices.count > 2, !verticesAreDegenerate(vertices),
              let plane = Plane(points: vertices.map { $0.position })
        else {
            return nil
        }
        self.init(unchecked: vertices, plane: plane, material: material)
    }

    /// Test if point lies inside the polygon
    // https://stackoverflow.com/questions/217578/how-can-i-determine-whether-a-2d-point-is-within-a-polygon#218081
    func containsPoint(_ p: Vector) -> Bool {
        guard plane.containsPoint(p), bounds.containsPoint(p) else {
            return false
        }
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
    func merge(_ other: Polygon) -> Polygon? {
        // do they have the same material?
        guard material == other.material else {
            return nil
        }
        // are they coplanar?
        guard plane.isEqual(to: other.plane) else {
            return nil
        }
        return join(unchecked: other, ensureConvex: false)
    }

    func inverted() -> Polygon {
        Polygon(
            unchecked: vertices.reversed().map { $0.inverted() },
            plane: plane.inverted(),
            isConvex: isConvex,
            bounds: bounds,
            material: material
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
            if let merged = a.join(unchecked: b, ensureConvex: true) {
                polygons[i - 1] = merged
                polygons.remove(at: i)
            }
            i -= 1
        }
        return polygons
    }

    /// Tessellates polygon into triangles using the "ear clipping" method
    func triangulate() -> [Polygon] {
        var vertices = self.vertices
        guard vertices.count > 3 else {
            assert(vertices.count > 2)
            return [self]
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
        if isConvex {
            let v0 = vertices[0]
            var v1 = vertices[1]
            for v2 in vertices[2...] {
                _ = addTriangle([v0, v1, v2])
                v1 = v2
            }
            return triangles
        }
        var i = 0
        var attempts = 0
        func removeVertex() {
            attempts = 0
            vertices.remove(at: i)
            if i == vertices.count {
                i = 0
            }
        }
        while vertices.count > 3 {
            let p0 = vertices[(i - 1 + vertices.count) % vertices.count]
            let p1 = vertices[i]
            let p2 = vertices[(i + 1) % vertices.count]
            // check for colinear points
            let p0p1 = p0.position - p1.position, p2p1 = p2.position - p1.position
            if p0p1.cross(p2p1).length < epsilon {
                // vertices are colinear, so we can't form a triangle
                if p0p1.dot(p2p1) > 0 {
                    // center point makes path degenerate - remove it
                    removeVertex()
                } else {
                    // try next point instead
                    i += 1
                    if i == vertices.count {
                        i = 0
                        attempts += 1
                        if attempts > 2 {
                            return triangles
                        }
                    }
                }
                continue
            }
            let triangle = Polygon([p0, p1, p2])
            if triangle == nil ||
                triangle!.plane.normal.dot(plane.normal) <= 0 || vertices.contains(where: {
                    !triangle!.vertices.contains($0) && triangle!.containsPoint($0.position)
                })
            {
                i += 1
                if i == vertices.count {
                    i = 0
                    attempts += 1
                    if attempts > 2 {
                        return triangles
                    }
                }
            } else if addTriangle(triangle!.vertices) {
                removeVertex()
            }
        }
        _ = addTriangle(vertices)
        return triangles
    }
}

internal extension Collection where Element == Polygon {
    func inverted() -> [Polygon] {
        map { $0.inverted() }
    }

    func tessellate() -> [Polygon] {
        flatMap { $0.tessellate() }
    }

    func triangulate() -> [Polygon] {
        flatMap { $0.triangulate() }
    }
}

internal extension Polygon {
    // Create polygon from vertices and face normal without performing validation
    // Vertices may be convex or concave, but are assumed to describe a non-degenerate polygon
    init(
        unchecked vertices: [Vertex],
        normal: Vector,
        isConvex: Bool,
        bounds: Bounds? = nil,
        material: Material?
    ) {
        self.init(
            unchecked: vertices,
            plane: Plane(unchecked: normal, pointOnPlane: vertices[0].position),
            isConvex: isConvex,
            bounds: bounds,
            material: material
        )
    }

    // Create polygon from vertices and plane without performing validation
    // Vertices may be convex or concave, but are assumed to describe a non-degenerate polygon
    // Vertices are assumed to be in anticlockwise order for the purpose of deriving the plane
    init(
        unchecked vertices: [Vertex],
        plane: Plane? = nil,
        isConvex: Bool? = nil,
        bounds: Bounds? = nil,
        material: Material? = nil,
        id: Int = 0
    ) {
        assert(vertices.count > 2)
        assert(!verticesAreDegenerate(vertices))
        assert(isConvex == nil || verticesAreConvex(vertices) == isConvex)
        let isConvex = isConvex ?? verticesAreConvex(vertices)
        let points = (plane == nil || bounds == nil) ? vertices.map { $0.position } : []
        storage = Storage(
            vertices: vertices,
            plane: plane ?? Plane(unchecked: points, convex: isConvex),
            bounds: bounds,
            isConvex: isConvex,
            material: material
        )
        self.id = id
    }

    var boundsIfSet: Bounds? {
        storage.boundsIfSet
    }

    // Join touching polygons (without checking they are coplanar or share the same material)
    func join(unchecked other: Polygon, ensureConvex: Bool) -> Polygon? {
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

    func clip(
        to polygons: [Polygon],
        _ inside: inout [Polygon],
        _ outside: inout [Polygon],
        _ id: inout Int
    ) {
        var toTest = tessellate()
        for polygon in polygons where !toTest.isEmpty {
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

    func split(
        along plane: Plane,
        _ coplanar: inout [Polygon],
        _ front: inout [Polygon],
        _ back: inout [Polygon],
        _ id: inout Int
    ) {
        // Put the polygon in the correct list, splitting it when necessary
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
        if !polygon.isConvex {
            var coplanar = [Polygon]()
            polygon.tessellate().forEach {
                $0.split(along: plane, &coplanar, &front, &back, &id)
            }
            return
        }
        var f = [Vertex](), b = [Vertex]()
        for i in polygon.vertices.indices {
            let j = (i + 1) % polygon.vertices.count
            let vi = polygon.vertices[i], vj = polygon.vertices[j]
            let ti = vi.position.compare(with: plane)
            if ti != .back {
                f.append(vi)
            }
            if ti != .front {
                b.append(vi)
            }
            let tj = vj.position.compare(with: plane)
            if ti.rawValue | tj.rawValue == PlaneComparison.spanning.rawValue {
                let t = (plane.w - plane.normal.dot(vi.position)) / plane.normal.dot(vj.position - vi.position)
                let v = vi.lerp(vj, t)
                f.append(v)
                b.append(v)
            }
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
}

private extension Polygon {
    final class Storage: Hashable {
        let vertices: [Vertex]
        let plane: Plane
        var boundsIfSet: Bounds?
        let isConvex: Bool
        var material: Material?

        var bounds: Bounds {
            if boundsIfSet == nil {
                boundsIfSet = Bounds(points: vertices.map { $0.position })
            }
            return boundsIfSet!
        }

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
            bounds: Bounds?,
            isConvex: Bool,
            material: Material?
        ) {
            self.vertices = vertices
            self.plane = plane
            self.boundsIfSet = bounds
            self.isConvex = isConvex
            self.material = material
        }
    }
}

private struct CodableMaterial: Codable {
    var value: Polygon.Material?

    init(_ value: Polygon.Material?) {
        self.value = value
    }

    enum CodingKeys: CodingKey {
        case string, int, data, nscoded
    }

    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            if let string = try container.decodeIfPresent(String.self, forKey: .string) {
                self.value = string
            } else if let int = try container.decodeIfPresent(Int.self, forKey: .int) {
                self.value = int
            } else if let data = try container.decodeIfPresent(Data.self, forKey: .data) {
                self.value = data
            } else if let data = try container.decodeIfPresent(Data.self, forKey: .nscoded) {
                self.value = NSKeyedUnarchiver.unarchiveObject(with: data) as? Polygon.Material
            }
        } else {
            let container = try decoder.singleValueContainer()
            if let string = try? container.decode(String.self) {
                self.value = string
            } else if let int = try? container.decode(Int.self) {
                self.value = int
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
