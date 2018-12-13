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
        ap = BSPNode(mesh.polygons).clip(ap, .greaterThanEqual, true)
        bp = BSPNode(polygons).clip(bp, .greaterThan, true)
        return Mesh(aout! + bout! + ap + bp)
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
        ap = BSPNode(mesh.polygons).clip(ap, .greaterThan, false)
        bp = BSPNode(polygons).clip(bp, .lessThan, true)
        return Mesh(aout! + ap + bp.map { $0.inverted() })
    }

    /// Returns a new mesage solid that includes all polygons from both the
    /// parameter and receiver. Polygons are neither split nor removed.
    ///
    ///     +-------+            +-------+
    ///     |       |            |       |
    ///     |   A   |            |       |
    ///     |    +--+----+   =   |    +--+----+
    ///     +----+--+    |       +----+--+    |
    ///          |   B   |            |       |
    ///          |       |            |       |
    ///          +-------+            +-------+
    ///
    func merge(_ mesh: Mesh) -> Mesh {
        return Mesh(polygons + mesh.polygons)
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
        ap = BSPNode(mesh.polygons).clip(ap, .lessThanEqual, true)
        bp = BSPNode(polygons).clip(bp, .lessThan, true)
        return Mesh(ap + bp)
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
        /// TODO: combine clip operations
        let bsp = BSPNode(mesh.polygons)
        let outside = bsp.clip(ap, .greaterThan, false)
        let inside = bsp.clip(ap, .lessThanEqual, false)
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

    func clip(_ polygons: [Polygon], _ keeping: ClipRule, _ clipBackfaces: Bool) -> [Polygon] {
        var id = 0
        var polygons = polygons
        for (i, p) in polygons.enumerated() where p.id != 0 {
            polygons[i].id = 0
        }
        return clip(polygons, keeping, clipBackfaces, &id)
    }

    private func clip(_ polygons: [Polygon], _ keeping: ClipRule, _ clipBackfaces: Bool, _ id: inout Int) -> [Polygon] {
        var coplanar: [Polygon]?
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
        let frontFacesGoFront = [.greaterThanEqual, .lessThan].contains(keeping)
        let backFacesGoFront = (keepFront != clipBackfaces)
        while !polygons.isEmpty {
            var front = [Polygon](), back = [Polygon]()
            for polygon in polygons {
                node.splitPolygon(polygon, &coplanar, &front, &back, frontFacesGoFront, backFacesGoFront, &id)
            }
            if front.count > back.count {
                addPolygons(node.back?.clip(back, keeping, clipBackfaces, &id) ?? (keepFront ? [] : back))
                if node.front == nil {
                    addPolygons(keepFront ? front : [])
                    return total
                }
                polygons = front
                node = node.front!
            } else {
                addPolygons(node.front?.clip(front, keeping, clipBackfaces, &id) ?? (keepFront ? front : []))
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
                var coplanar: [Polygon]? = node.polygons
                for polygon in polygons {
                    node.splitPolygon(polygon, &coplanar, &front, &back, true, false, &id)
                }
                node.polygons = coplanar!
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

    fileprivate func splitPolygon(_ polygon: Polygon,
                                  _ coplanar: inout [Polygon]?,
                                  _ front: inout [Polygon],
                                  _ back: inout [Polygon],
                                  _ coplanarGoesInFront: Bool,
                                  _ reversePlanarGoesInFront: Bool,
                                  _ id: inout Int) {
        enum PolygonType: Int {
            case coplanar = 0
            case front = 1
            case back = 2
            case spanning = 3
        }

        // Ensure we have a plane
        guard let plane = plane else {
            return
        }

        // Classify each point as well as the entire polygon into one of the above
        // four classes.
        var polygonType = PolygonType.coplanar
        let types: [PolygonType] = (polygon.plane == plane) ? [] : polygon.vertices.map {
            let t = plane.normal.dot($0.position) - plane.w
            let type: PolygonType = (t < -epsilon) ? .back : (t > epsilon) ? .front : .coplanar
            polygonType = PolygonType(rawValue: polygonType.rawValue | type.rawValue)!
            return type
        }

        // Put the polygon in the correct list, splitting it when necessary.
        switch polygonType {
        case .coplanar:
            if plane.normal.dot(polygon.plane.normal) > 0 {
                if coplanar == nil {
                    if coplanarGoesInFront {
                        front.append(polygon)
                    } else {
                        back.append(polygon)
                    }
                } else {
                    coplanar?.append(polygon)
                }
            } else if reversePlanarGoesInFront {
                front.append(polygon)
            } else {
                back.append(polygon)
            }
        case .front:
            front.append(polygon)
        case .back:
            back.append(polygon)
        case .spanning:
            var polygon = polygon
            if polygon.id == 0 {
                id += 1
                polygon.id = id
            }
            if !polygon.isConvex {
                polygon.tessellate().forEach {
                    splitPolygon($0, &coplanar, &front, &back, coplanarGoesInFront, reversePlanarGoesInFront, &id)
                }
                return
            }
            var f = [Vertex](), b = [Vertex]()
            for i in polygon.vertices.indices {
                let j = (i + 1) % polygon.vertices.count
                let ti = types[i], tj = types[j]
                let vi = polygon.vertices[i], vj = polygon.vertices[j]
                if ti != .back {
                    f.append(vi)
                }
                if ti != .front {
                    b.append(vi)
                }
                if ti.rawValue | tj.rawValue == PolygonType.spanning.rawValue {
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
