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
        guard bounds.intersects(mesh.bounds) else {
            // This is basically just a merge.
            // The slightly weird logic is to replicate the boundsTest behavior.
            // It's not clear why this matters, but it breaks certain projects.
            let polys = Array(polygons.reversed()) + Array(mesh.polygons.reversed())
            return Mesh(
                unchecked: polys,
                bounds: bounds.union(mesh.bounds),
                isConvex: false
            )
        }
        var ap = polygons
        var bp = mesh.polygons
        var aout: [Polygon]? = []
        var bout: [Polygon]? = []
        boundsTest(bounds.intersection(mesh.bounds), &ap, &bp, &aout, &bout)
        ap = BSP(mesh).clip(ap, .greaterThan)
        bp = BSP(self).clip(bp, .greaterThanEqual)
        return Mesh(
            unchecked: aout! + bout! + ap + bp,
            bounds: bounds.union(mesh.bounds),
            isConvex: false
        )
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
        guard bounds.intersects(mesh.bounds) else {
            return self
        }
        var ap = polygons
        var bp = mesh.polygons
        var aout: [Polygon]? = []
        var bout: [Polygon]?
        boundsTest(bounds.intersection(mesh.bounds), &ap, &bp, &aout, &bout)
        ap = BSP(mesh).clip(ap, .greaterThan)
        bp = BSP(self).clip(bp, .lessThan)
        return Mesh(
            unchecked: aout! + ap + bp.map { $0.inverted() },
            isConvex: false
        )
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
        guard bounds.intersects(mesh.bounds) else {
            return merge(mesh)
        }
        var ap = polygons
        var bp = mesh.polygons
        var aout: [Polygon]? = []
        var bout: [Polygon]? = []
        boundsTest(bounds.intersection(mesh.bounds), &ap, &bp, &aout, &bout)
        let absp = BSP(self)
        let bbsp = BSP(mesh)
        // TODO: combine clip operations
        let ap1 = bbsp.clip(ap, .greaterThan)
        let bp1 = absp.clip(bp, .lessThan)
        let ap2 = bbsp.clip(ap, .lessThan)
        let bp2 = absp.clip(bp, .greaterThan)
        // Avoids slow compilation from long expression
        let lhs = aout! + ap1 + bp1.map { $0.inverted() }
        let rhs = bout! + bp2 + ap2.map { $0.inverted() }
        return Mesh(unchecked: lhs + rhs, isConvex: false)
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
        guard bounds.intersects(mesh.bounds) else {
            return Mesh([])
        }
        var ap = polygons
        var bp = mesh.polygons
        var aout, bout: [Polygon]?
        boundsTest(bounds.intersection(mesh.bounds), &ap, &bp, &aout, &bout)
        ap = BSP(mesh).clip(ap, .lessThan)
        bp = BSP(self).clip(bp, .lessThanEqual)
        return Mesh(unchecked: ap + bp, isConvex: isConvex && mesh.isConvex)
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
        guard bounds.intersects(mesh.bounds) else {
            return self
        }
        var ap = polygons
        var bp = mesh.polygons
        var aout: [Polygon]? = []
        var bout: [Polygon]?
        boundsTest(bounds.intersection(mesh.bounds), &ap, &bp, &aout, &bout)
        // TODO: combine clip operations
        let bsp = BSP(mesh)
        let outside = bsp.clip(ap, .greaterThan)
        let inside = bsp.clip(ap, .lessThanEqual)
        return Mesh(
            unchecked: aout! + outside + inside.map {
                Polygon(
                    unchecked: $0.vertices,
                    plane: $0.plane,
                    isConvex: $0.isConvex,
                    bounds: $0.bounds,
                    material: bp.first?.material ?? $0.material
                )
            },
            bounds: bounds,
            isConvex: isConvex
        )
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
            return (
                front.isEmpty ? nil : Mesh(unchecked: front, isConvex: false),
                back.isEmpty ? nil : Mesh(unchecked: back, isConvex: false)
            )
        }
    }

    /// Clip mesh to a plane and optionally fill sheared faces with specified material
    func clip(to plane: Plane, fill: Polygon.Material = nil) -> Mesh {
        guard !polygons.isEmpty else {
            return self
        }
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
            let mesh = Mesh(unchecked: front, isConvex: false)
            guard let material = fill else {
                return mesh
            }
            // Project each corner of mesh bounds onto plane to find radius
            var radius = 0.0
            for corner in mesh.bounds.corners {
                let p = corner.project(onto: plane)
                radius = max(radius, p.lengthSquared)
            }
            radius = radius.squareRoot()
            // Create back face
            let normal = Vector(0, 0, 1)
            let angle = -normal.angle(with: plane.normal)
            let rotation: Rotation
            if angle.isEqual(to: 0) {
                rotation = .identity
            } else {
                let axis = normal.cross(plane.normal).normalized()
                rotation = Rotation(unchecked: axis, radians: angle)
            }
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
            return Mesh(
                unchecked: mesh.polygons + BSP(self).clip([rect], .lessThan),
                isConvex: isConvex
            )
        }
    }
}

private func boundsTest(
    _ intersection: Bounds,
    _ lhs: inout [Polygon], _ rhs: inout [Polygon],
    _ lout: inout [Polygon]?, _ rout: inout [Polygon]?
) {
    for (i, p) in lhs.enumerated().reversed() where !p.bounds.intersects(intersection) {
        lout?.append(p)
        lhs.remove(at: i)
    }
    for (i, p) in rhs.enumerated().reversed() where !p.bounds.intersects(intersection) {
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
