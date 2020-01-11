//
//  CSG.swift
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

// Inspired by: https://github.com/evanw/csg.js

public extension Mesh {
    /// Returns a new mesh representing the combined volume of the
    /// mesh parameter and the receiver, with inner faces removed.
    ///
    ///     +-------+            +-------+
    ///     |       |            |       |
    ///     |   A   |            |       |
    ///     |    +--+----+   =   |       +----+
    ///     +----+--+    |       +----+       |
    ///          |   B   |            |       |
    ///          |       |            |       |
    ///          +-------+            +-------+
    ///
    func union(_ mesh: Mesh) -> Mesh {
        var ap = polygons
        var bp = mesh.polygons
        var aout: [Polygon]? = []
        var bout: [Polygon]? = []
        boundsTest(&ap, &bp, &aout, &bout)
        ap = BSPNode(mesh.polygons).clip(ap, .greaterThan)
        bp = BSPNode(polygons).clip(bp, .greaterThanEqual)
        return Mesh(aout! + bout! + ap + bp)
    }

    /// Efficiently form union from multiple meshes
    static func union(_ meshes: [Mesh]) -> Mesh {
        return multimerge(meshes, using: { $0.union($1) })
    }

    /// Returns a new mesh created by subtracting the volume of the
    /// mesh parameter from the receiver.
    ///
    ///     +-------+            +-------+
    ///     |       |            |       |
    ///     |   A   |            |       |
    ///     |    +--+----+   =   |    +--+
    ///     +----+--+    |       +----+
    ///          |   B   |
    ///          |       |
    ///          +-------+
    ///
    func subtract(_ mesh: Mesh) -> Mesh {
        var ap = polygons
        var bp = mesh.polygons
        var aout: [Polygon]? = []
        var bout: [Polygon]?
        boundsTest(&ap, &bp, &aout, &bout)
        ap = BSPNode(mesh.polygons).clip(ap, .greaterThan)
        bp = BSPNode(polygons).clip(bp, .lessThan)
        return Mesh(aout! + ap + bp.map { $0.inverted() })
    }

    /// Efficiently subtract multiple meshes
    static func difference(_ meshes: [Mesh]) -> Mesh {
        return reduce(meshes, using: { $0.subtract($1) })
    }

    /// Returns a new mesh reprenting only the volume exclusively occupied by
    /// one shape or the other, but not both.
    ///
    ///     +-------+            +-------+
    ///     |       |            |       |
    ///     |   A   |            |       |
    ///     |    +--+----+   =   |    ++++----+
    ///     +----+--+    |       +----++++    |
    ///          |   B   |            |       |
    ///          |       |            |       |
    ///          +-------+            +-------+
    ///
    func xor(_ mesh: Mesh) -> Mesh {
        var ap = polygons
        var bp = mesh.polygons
        var aout: [Polygon]? = []
        var bout: [Polygon]? = []
        boundsTest(&ap, &bp, &aout, &bout)
        let absp = BSPNode(polygons)
        let bbsp = BSPNode(mesh.polygons)
        // TODO: combine clip operations
        let ap1 = bbsp.clip(ap, .greaterThan)
        let bp1 = absp.clip(bp, .lessThan)
        let ap2 = bbsp.clip(ap, .lessThan)
        let bp2 = absp.clip(bp, .greaterThan)
        // Avoids slow compilation from long expression
        let lhs = aout! + ap1 + bp1.map { $0.inverted() }
        let rhs = bout! + bp2 + ap2.map { $0.inverted() }
        return Mesh(lhs + rhs)
    }

    /// Efficiently xor multiple meshes
    static func xor(_ meshes: [Mesh]) -> Mesh {
        return multimerge(meshes, using: { $0.xor($1) })
    }

    /// Returns a new mesh reprenting the volume shared by both the mesh
    /// parameter and the receiver. If these do not intersect, an empty
    /// mesh will be returned.
    ///
    ///     +-------+
    ///     |       |
    ///     |   A   |
    ///     |    +--+----+   =   +--+
    ///     +----+--+    |       +--+
    ///          |   B   |
    ///          |       |
    ///          +-------+
    ///
    func intersect(_ mesh: Mesh) -> Mesh {
        var ap = polygons
        var bp = mesh.polygons
        var aout, bout: [Polygon]?
        boundsTest(&ap, &bp, &aout, &bout)
        ap = BSPNode(mesh.polygons).clip(ap, .lessThan)
        bp = BSPNode(polygons).clip(bp, .lessThanEqual)
        return Mesh(ap + bp)
    }

    /// Efficiently compute intersection of multiple meshes
    static func intersection(_ meshes: [Mesh]) -> Mesh {
        return reduce(meshes, using: { $0.intersect($1) })
    }

    /// Returns a new mesh that retains the shape of the receiver, but with
    /// the intersecting area colored using material from the parameter.
    ///
    ///     +-------+            +-------+
    ///     |       |            |       |
    ///     |   A   |            |       |
    ///     |    +--+----+   =   |    +--+
    ///     +----+--+    |       +----+--+
    ///          |   B   |
    ///          |       |
    ///          +-------+
    ///
    func stencil(_ mesh: Mesh) -> Mesh {
        var ap = polygons
        var bp = mesh.polygons
        var aout: [Polygon]? = []
        var bout: [Polygon]?
        boundsTest(&ap, &bp, &aout, &bout)
        // TODO: combine clip operations
        let bsp = BSPNode(mesh.polygons)
        let outside = bsp.clip(ap, .greaterThan)
        let inside = bsp.clip(ap, .lessThanEqual)
        return Mesh(aout! + outside + inside.map {
            Polygon(
                unchecked: $0.vertices,
                plane: $0.plane,
                isConvex: $0.isConvex,
                bounds: $0.bounds,
                material: bp.first?.material ?? $0.material
            )
        })
    }

    /// Efficiently perform stencil with multiple meshes
    static func stencil(_ meshes: [Mesh]) -> Mesh {
        return reduce(meshes, using: { $0.stencil($1) })
    }

    /// Split mesh along a plane
    func split(along plane: Plane) -> (Mesh?, Mesh?) {
        switch bounds.compare(with: plane) {
        case .front:
            return (self, nil)
        case .back:
            return (nil, self)
        case .spanning, .coplanar:
            var id = 0
            var coplanar = [Polygon](), front = [Polygon](), back = [Polygon]()
            for polygon in polygons {
                polygon.split(along: plane, &coplanar, &front, &back, &id)
            }
            for polygon in coplanar where plane.normal.dot(polygon.plane.normal) > 0 {
                front.append(polygon)
            }
            return (front.isEmpty ? nil : Mesh(front), back.isEmpty ? nil : Mesh(back))
        }
    }

    /// Clip mesh to a plane and optionally fill sheared aces with specified material
    func clip(to plane: Plane, fill: Polygon.Material = nil) -> Mesh {
        switch bounds.compare(with: plane) {
        case .front:
            return self
        case .back:
            return Mesh([])
        case .spanning, .coplanar:
            var id = 0
            var coplanar = [Polygon](), front = [Polygon](), back = [Polygon]()
            for polygon in polygons {
                polygon.split(along: plane, &coplanar, &front, &back, &id)
            }
            for polygon in coplanar where plane.normal.dot(polygon.plane.normal) > 0 {
                front.append(polygon)
            }
            let mesh = Mesh(front)
            guard let material = fill else {
                return mesh
            }
            // Project each corner of mesh bounds onto plan to find radius
            var radius = 0.0
            for corner in mesh.bounds.corners {
                let p = corner.project(onto: plane)
                radius = max(radius, p.lengthSquared)
            }
            radius = radius.squareRoot()
            // Create back face
            let normal = Vector(0, 0, 1)
            let angle = -normal.angle(with: plane.normal)
            let axis = normal.cross(plane.normal).normalized()
            let rotation = Rotation(unchecked: axis, radians: angle)
            let rect = Polygon(
                unchecked: [
                    Vertex(Vector(-radius, radius, 0), -normal, .zero),
                    Vertex(Vector(radius, radius, 0), -normal, Vector(1, 0, 0)),
                    Vertex(Vector(radius, -radius, 0), -normal, Vector(1, 1, 0)),
                    Vertex(Vector(-radius, -radius, 0), -normal, Vector(0, 1, 0)),
                ],
                normal: -normal,
                isConvex: true,
                material: material
            )
            .rotated(by: rotation)
            .translated(by: plane.normal * plane.w)
            // Clip rect
            return Mesh(mesh.polygons + BSPNode(polygons).clip([rect], .lessThan))
        }
    }
}

private func boundsTest(
    _ lhs: inout [Polygon], _ rhs: inout [Polygon],
    _ lout: inout [Polygon]?, _ rout: inout [Polygon]?
) {
    let bbb = Bounds(bounds: rhs.map { $0.bounds })
    let abb = Bounds(bounds: lhs.map { $0.bounds })
    for (i, p) in lhs.enumerated().reversed() where !p.bounds.intersects(bbb) {
        lout?.append(p)
        lhs.remove(at: i)
    }
    for (i, p) in rhs.enumerated().reversed() where !p.bounds.intersects(abb) {
        rout?.append(p)
        rhs.remove(at: i)
    }
}

// Merge all the meshes into a single mesh using fn
private func multimerge(_ meshes: [Mesh], using fn: (Mesh, Mesh) -> Mesh) -> Mesh {
    var mesh = Mesh([])
    var meshesAndBounds = meshes.map { ($0, $0.bounds) }
    var i = 0
    while i < meshesAndBounds.count {
        let m = reduce(&meshesAndBounds, at: i, using: fn)
        mesh = mesh.merge(m)
        i += 1
    }
    return mesh
}

// Merge each intersecting mesh after i into the mesh at index i using fn
private func reduce(_ meshes: [Mesh], using fn: (Mesh, Mesh) -> Mesh) -> Mesh {
    var meshesAndBounds = meshes.map { ($0, $0.bounds) }
    return reduce(&meshesAndBounds, at: 0, using: fn)
}

private func reduce(
    _ meshesAndBounds: inout [(Mesh, Bounds)],
    at i: Int,
    using fn: (Mesh, Mesh) -> Mesh
) -> Mesh {
    var (m, mb) = meshesAndBounds[i]
    var j = i + 1, count = meshesAndBounds.count
    while j < count {
        let (n, nb) = meshesAndBounds[j]
        if mb.intersects(nb) {
            m = fn(m, n)
            mb = m.bounds
            meshesAndBounds[i] = (m, mb)
            meshesAndBounds.remove(at: j)
            count -= 1
            continue
        }
        j += 1
    }
    return m
}

private class BSPNode {
    private weak var parent: BSPNode?
    private var front: BSPNode?
    private var back: BSPNode?
    private var polygons = [Polygon]()
    private var plane: Plane?

    init(_ polygons: [Polygon]) {
        plane = polygons.first?.plane
        insert(polygons)
    }

    private init(plane: Plane, parent: BSPNode?) {
        self.parent = parent
        self.plane = plane
    }

    private func enumerate(_ block: (BSPNode) -> Void) {
        var node = self
        var visited: BSPNode?
        block(node)
        while true {
            if visited == nil, let front = node.front {
                block(front)
                node = front
            } else if let back = node.back, back !== visited {
                visited = nil
                block(back)
                node = back
            } else if node !== self, let parent = node.parent {
                visited = node
                node = parent
            } else {
                return
            }
        }
    }

    enum ClipRule {
        case greaterThan
        case greaterThanEqual
        case lessThan
        case lessThanEqual
    }

    func clip(_ polygons: [Polygon], _ keeping: ClipRule) -> [Polygon] {
        var id = 0
        var polygons = polygons
        for (i, p) in polygons.enumerated() where p.id != 0 {
            polygons[i].id = 0
        }
        return clip(polygons, keeping, &id)
    }

    private func clip(
        _ polygons: [Polygon],
        _ keeping: ClipRule,
        _ id: inout Int
    ) -> [Polygon] {
        var polygons = polygons
        var node = self
        var total = [Polygon]()
        func addPolygons(_ polygons: [Polygon]) {
            for a in polygons {
                guard a.id != 0 else {
                    total.append(a)
                    continue
                }
                var a = a
                for i in total.indices.reversed() {
                    let b = total[i]
                    if a.id == b.id, let c = a.join(unchecked: b) {
                        a = c
                        total.remove(at: i)
                    }
                }
                total.append(a)
            }
        }
        let keepFront = [.greaterThan, .greaterThanEqual].contains(keeping)
        while !polygons.isEmpty {
            var coplanar = [Polygon](), front = [Polygon](), back = [Polygon]()
            for polygon in polygons {
                polygon.split(along: node.plane!, &coplanar, &front, &back, &id)
            }
            for polygon in coplanar {
                switch keeping {
                case .greaterThan, .lessThanEqual:
                    polygon.clip(to: node.polygons, &back, &front, &id)
                case .greaterThanEqual, .lessThan:
                    if node.plane!.normal.dot(polygon.plane.normal) > 0 {
                        front.append(polygon)
                    } else {
                        polygon.clip(to: node.polygons, &back, &front, &id)
                    }
                }
            }
            if front.count > back.count {
                addPolygons(node.back?.clip(back, keeping, &id) ?? (keepFront ? [] : back))
                if node.front == nil {
                    addPolygons(keepFront ? front : [])
                    return total
                }
                polygons = front
                node = node.front!
            } else {
                addPolygons(node.front?.clip(front, keeping, &id) ?? (keepFront ? front : []))
                if node.back == nil {
                    addPolygons(keepFront ? [] : back)
                    return total
                }
                polygons = back
                node = node.back!
            }
        }
        return total
    }

    func insert(_ polygons: [Polygon]) {
        var polygons = polygons
        var node = self
        while !polygons.isEmpty {
            if node.plane == nil {
                node.plane = polygons.first?.plane
            }
            var front = [Polygon](), back = [Polygon]()
            do {
                var id = 0
                var coplanar = [Polygon]()
                for polygon in polygons {
                    polygon.split(along: node.plane!, &coplanar, &front, &back, &id)
                }
                for polygon in coplanar {
                    if node.plane!.normal.dot(polygon.plane.normal) > 0 {
                        node.polygons.append(polygon)
                    } else {
                        back.append(polygon)
                    }
                }
            }

            node.front = node.front ?? front.first.map {
                BSPNode(plane: $0.plane, parent: node)
            }
            node.back = node.back ?? back.first.map {
                BSPNode(plane: $0.plane, parent: node)
            }

            if front.count > back.count {
                node.back?.insert(back)
                polygons = front
                node = node.front!
            } else {
                node.front?.insert(front)
                polygons = back
                node = node.back ?? node
            }
        }
    }
}

extension Polygon {
    func clip(
        to polygons: [Polygon],
        _ inside: inout [Polygon],
        _ outside: inout [Polygon],
        _ id: inout Int
    ) {
        precondition(isConvex)
        var toTest = [self]
        for polygon in polygons where !toTest.isEmpty {
            precondition(polygon.isConvex)
            var _outside = [Polygon]()
            for p in toTest {
                polygon.clip(p, &inside, &_outside, &id)
            }
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
        precondition(isConvex)
        guard polygon.isConvex else {
            polygon.tessellate().forEach {
                clip($0, &inside, &outside, &id)
            }
            return
        }
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
            var polygon = self
            if polygon.id == 0 {
                id += 1
                polygon.id = id
            }
            if !polygon.isConvex {
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
                    material: polygon.material,
                    id: polygon.id
                ))
            }
            if !verticesAreDegenerate(b) {
                back.append(Polygon(
                    unchecked: b,
                    plane: polygon.plane,
                    isConvex: true,
                    material: polygon.material,
                    id: polygon.id
                ))
            }
        }
    }
}
