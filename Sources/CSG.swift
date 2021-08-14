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
    /// Callback used to cancel a long-running operation
    typealias CancellationHandler = () -> Bool

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
    func union(_ mesh: Mesh, isCancelled: CancellationHandler = { false }) -> Mesh {
        let intersection = bounds.intersection(mesh.bounds)
        guard !intersection.isEmpty else {
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
        var aout: [Polygon]? = [], bout: [Polygon]? = []
        let ap = BSP(mesh, isCancelled).clip(
            boundsTest(intersection, polygons, &aout),
            .greaterThan,
            isCancelled
        )
        let bp = BSP(self, isCancelled).clip(
            boundsTest(intersection, mesh.polygons, &bout),
            .greaterThanEqual,
            isCancelled
        )
        return Mesh(
            unchecked: aout! + bout! + ap + bp,
            bounds: bounds.union(mesh.bounds),
            isConvex: false
        )
    }

    /// Efficiently form union from multiple meshes
    static func union(
        _ meshes: [Mesh],
        isCancelled: @escaping CancellationHandler = { false }
    ) -> Mesh {
        multimerge(meshes, using: { $0.union($1, isCancelled: $2) }, isCancelled)
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
    func subtract(_ mesh: Mesh, isCancelled: CancellationHandler = { false }) -> Mesh {
        let intersection = bounds.intersection(mesh.bounds)
        guard !intersection.isEmpty else {
            return self
        }
        var aout: [Polygon]? = [], bout: [Polygon]?
        let ap = BSP(mesh, isCancelled).clip(
            boundsTest(intersection, polygons, &aout),
            .greaterThan,
            isCancelled
        )
        let bp = BSP(self, isCancelled).clip(
            boundsTest(intersection, mesh.polygons, &bout),
            .lessThan,
            isCancelled
        )
        return Mesh(
            unchecked: aout! + ap + bp.map { $0.inverted() },
            bounds: nil, // TODO: is there a way to preserve this efficiently?
            isConvex: false
        )
    }

    /// Efficiently subtract multiple meshes
    static func difference(
        _ meshes: [Mesh],
        isCancelled: @escaping CancellationHandler = { false }
    ) -> Mesh {
        reduce(meshes, using: { $0.subtract($1, isCancelled: $2) }, isCancelled)
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
    func xor(_ mesh: Mesh, isCancelled: CancellationHandler = { false }) -> Mesh {
        let intersection = bounds.intersection(mesh.bounds)
        guard !intersection.isEmpty else {
            return merge(mesh)
        }
        let absp = BSP(self, isCancelled), bbsp = BSP(mesh, isCancelled)
        var aout: [Polygon]? = [], bout: [Polygon]? = []
        let ap = boundsTest(intersection, polygons, &aout)
        let bp = boundsTest(intersection, mesh.polygons, &bout)
        let (ap1, ap2) = bbsp.split(ap, .greaterThan, .lessThan, isCancelled)
        let (bp2, bp1) = absp.split(bp, .greaterThan, .lessThan, isCancelled)
        // Avoids slow compilation from long expression
        let lhs = aout! + ap1 + bp1.map { $0.inverted() }
        let rhs = bout! + bp2 + ap2.map { $0.inverted() }
        return Mesh(
            unchecked: lhs + rhs,
            bounds: nil, // TODO: is there a way to efficiently preserve this?
            isConvex: false
        )
    }

    /// Efficiently xor multiple meshes
    static func xor(
        _ meshes: [Mesh],
        isCancelled: @escaping CancellationHandler = { false }
    ) -> Mesh {
        multimerge(meshes, using: { $0.xor($1, isCancelled: $2) }, isCancelled)
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
    func intersect(
        _ mesh: Mesh,
        isCancelled: CancellationHandler = { false }
    ) -> Mesh {
        let intersection = bounds.intersection(mesh.bounds)
        guard !intersection.isEmpty else {
            return Mesh([])
        }
        var aout: [Polygon]?, bout: [Polygon]?
        let ap = BSP(mesh, isCancelled).clip(
            boundsTest(intersection, polygons, &aout),
            .lessThan,
            isCancelled
        )
        let bp = BSP(self, isCancelled).clip(
            boundsTest(intersection, mesh.polygons, &bout),
            .lessThanEqual,
            isCancelled
        )
        return Mesh(
            unchecked: ap + bp,
            bounds: nil, // TODO: is there a way to efficiently preserve this?
            isConvex: isConvex && mesh.isConvex
        )
    }

    /// Efficiently compute intersection of multiple meshes
    static func intersection(
        _ meshes: [Mesh],
        isCancelled: @escaping CancellationHandler = { false }
    ) -> Mesh {
        reduce(meshes, using: { $0.intersect($1, isCancelled: $2) }, isCancelled)
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
    func stencil(
        _ mesh: Mesh,
        isCancelled: CancellationHandler = { false }
    ) -> Mesh {
        let intersection = bounds.intersection(mesh.bounds)
        guard !intersection.isEmpty else {
            return self
        }
        var aout: [Polygon]? = []
        let ap = boundsTest(bounds.intersection(mesh.bounds), polygons, &aout)
        let bsp = BSP(mesh, isCancelled)
        let (outside, inside) = bsp.split(ap, .greaterThan, .lessThanEqual, isCancelled)
        let material = mesh.polygons.first?.material
        return Mesh(
            unchecked: aout! + outside + inside.map { $0.with(material: material) },
            bounds: bounds,
            isConvex: isConvex
        )
    }

    /// Efficiently perform stencil with multiple meshes
    static func stencil(
        _ meshes: [Mesh],
        isCancelled: @escaping CancellationHandler = { false }
    ) -> Mesh {
        reduce(meshes, using: { $0.stencil($1, isCancelled: $2) }, isCancelled)
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
                front.isEmpty ? nil : Mesh(unchecked: front, bounds: nil, isConvex: false),
                back.isEmpty ? nil : Mesh(unchecked: back, bounds: nil, isConvex: false)
            )
        }
    }

    /// Clip mesh to a plane and optionally fill sheared faces with specified material
    func clip(to plane: Plane, fill: Material? = nil) -> Mesh {
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
            let mesh = Mesh(
                unchecked: front,
                bounds: nil,
                isConvex: false
            )
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
            if angle == .zero {
                rotation = .identity
            } else {
                let axis = normal.cross(plane.normal).normalized()
                rotation = Rotation(unchecked: axis, angle: angle)
            }
            let rect = Polygon(
                unchecked: [
                    Vertex(Vector(-radius, radius, 0), -Direction(normal), .zero),
                    Vertex(Vector(radius, radius, 0), -Direction(normal), Vector(1, 0, 0)),
                    Vertex(Vector(radius, -radius, 0), -Direction(normal), Vector(1, 1, 0)),
                    Vertex(Vector(-radius, -radius, 0), -Direction(normal), Vector(0, 1, 0)),
                ],
                normal: -normal,
                isConvex: true,
                material: material
            )
            .rotated(by: rotation)
            .translated(by: plane.normal * plane.w)
            // Clip rect
            return Mesh(
                unchecked: mesh.polygons + BSP(self) { false }
                    .clip([rect], .lessThan) { false },
                bounds: nil,
                isConvex: isConvex
            )
        }
    }
}

private func boundsTest(
    _ bounds: Bounds,
    _ polygons: [Polygon],
    _ out: inout [Polygon]?
) -> [Polygon] {
    polygons.filter {
        if $0.bounds.intersects(bounds) {
            return true
        }
        out?.append($0)
        return false
    }
}

private extension Mesh {
    // Merge all the meshes into a single mesh using fn
    static func multimerge(
        _ meshes: [Mesh],
        using fn: (Mesh, Mesh, CancellationHandler) -> Mesh,
        _ isCancelled: @escaping CancellationHandler
    ) -> Mesh {
        var mesh = Mesh([])
        var meshes = meshes
        var i = 0
        while i < meshes.count {
            mesh = mesh.merge(reduce(&meshes, at: i, using: fn, isCancelled))
            i += 1
        }
        return mesh
    }

    // Merge each intersecting mesh after i into the mesh at index i using fn
    static func reduce(
        _ meshes: [Mesh],
        using fn: (Mesh, Mesh, CancellationHandler) -> Mesh,
        _ isCancelled: @escaping CancellationHandler
    ) -> Mesh {
        var meshes = meshes
        return reduce(&meshes, at: 0, using: fn, isCancelled)
    }

    static func reduce(
        _ meshes: inout [Mesh],
        at i: Int,
        using fn: (Mesh, Mesh, CancellationHandler) -> Mesh,
        _ isCancelled: @escaping CancellationHandler
    ) -> Mesh {
        var m = meshes[i]
        var j = i + 1
        while j < meshes.count {
            let n = meshes[j]
            if m.bounds.intersects(n.bounds) {
                m = fn(m, n, isCancelled)
                meshes[i] = m
                meshes.remove(at: j)
                j = i
            }
            j += 1
        }
        return m
    }
}
