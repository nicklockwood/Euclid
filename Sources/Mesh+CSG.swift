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
    /// Callback used to cancel a long-running operation.
    /// - Returns: `true` if operation should be cancelled, or `false` otherwise.
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
    /// - Parameters
    ///   - mesh: The mesh to form a union with.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: a new mesh representing the union of the input meshes.
    func union(_ mesh: Mesh, isCancelled: CancellationHandler = { false }) -> Mesh {
        let intersection = bounds.intersection(mesh.bounds)
        guard !intersection.isEmpty else {
            // This is basically just a merge.
            // The slightly weird logic is to replicate the boundsTest behavior.
            // It's not clear why this matters, but it breaks certain projects.
            let polys = polygons.reversed() + Array(mesh.polygons.reversed())
            return Mesh(
                unchecked: polys,
                bounds: bounds.union(mesh.bounds),
                isConvex: false,
                isWatertight: nil,
                submeshes: nil // TODO: can this be preserved?
            )
        }
        var out: [Polygon]? = []
        let ap = BSP(mesh, isCancelled).clip(
            boundsTest(intersection, polygons, &out),
            .greaterThan,
            isCancelled
        )
        let bp = BSP(self, isCancelled).clip(
            boundsTest(intersection, mesh.polygons, &out),
            .greaterThanEqual,
            isCancelled
        )
        return Mesh(
            unchecked: out! + ap + bp,
            bounds: bounds.union(mesh.bounds),
            isConvex: false,
            isWatertight: nil,
            submeshes: nil // TODO: can this be preserved?
        )
    }

    /// Efficiently forms a union from multiple meshes.
    /// - Parameters
    ///   - meshes: The meshes to form a union from.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: a new mesh representing the union of the input meshes.
    static func union(
        _ meshes: [Mesh],
        isCancelled: CancellationHandler = { false }
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
    /// - Parameters
    ///   - mesh: The mesh to subtract from this one.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: a new mesh representing the result of the subtraction.
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
            isConvex: false,
            isWatertight: nil,
            submeshes: nil // TODO: can this be preserved?
        )
    }

    /// Efficiently gets the difference between multiple meshes.
    /// - Parameters
    ///   - meshes: An array of meshes. All but the first will be subtracted from the first.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: a new mesh representing the difference between the meshes.
    static func difference(
        _ meshes: [Mesh],
        isCancelled: CancellationHandler = { false }
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
    /// - Parameters
    ///   - mesh: The mesh to be XORed with this one.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: a new mesh representing the XOR of the meshes.
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
            isConvex: false,
            isWatertight: nil,
            submeshes: nil // TODO: can this be preserved?
        )
    }

    /// Efficiently XORs multiple meshes.
    /// - Parameters
    ///   - meshes: An array of meshes. All but the first will be subtracted from the first.
    ///   - isCancelled: Callback used to cancel the operation
    /// - Returns: a new mesh representing the XOR of the meshes.
    static func xor(
        _ meshes: [Mesh],
        isCancelled: CancellationHandler = { false }
    ) -> Mesh {
        multimerge(meshes, using: { $0.xor($1, isCancelled: $2) }, isCancelled)
    }

    /// Returns a new mesh representing the volume shared by both the mesh
    /// parameter and the receiver. If these do not intersect, an empty mesh will be returned.
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
    /// - Parameters
    ///   - mesh: The mesh to be intersected with this one.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: a new mesh representing the intersection of the meshes.
    func intersect(
        _ mesh: Mesh,
        isCancelled: CancellationHandler = { false }
    ) -> Mesh {
        let intersection = bounds.intersection(mesh.bounds)
        guard !intersection.isEmpty else {
            return .empty
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
            isConvex: isKnownConvex && mesh.isKnownConvex,
            isWatertight: nil,
            submeshes: nil // TODO: can this be preserved?
        )
    }

    /// Efficiently computes the intersection of multiple meshes.
    /// - Parameters
    ///   - meshes: An array of meshes to intersect.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: a new mesh representing the intersection of the meshes.
    static func intersection(
        _ meshes: [Mesh],
        isCancelled: CancellationHandler = { false }
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
    /// - Parameters
    ///   - mesh: The mesh to be stencilled onto this one.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: a new mesh representing the result of stencilling.
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
            isConvex: isKnownConvex,
            isWatertight: nil,
            submeshes: submeshesIfEmpty
        )
    }

    /// Efficiently performs a stencil with multiple meshes.
    /// - Parameters
    ///   - meshes: An array of meshes. All but the first will be stencilled onto the first.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: a new mesh representing the result of stencilling.
    static func stencil(
        _ meshes: [Mesh],
        isCancelled: CancellationHandler = { false }
    ) -> Mesh {
        reduce(meshes, using: { $0.stencil($1, isCancelled: $2) }, isCancelled)
    }

    /// Clip mesh to the specified plane and optionally fill sheared faces with specified material.
    /// - Parameters
    ///   - plane: The plane to clip the mesh to
    ///   - fill: The material to fill the sheared face(s) with.
    ///
    /// > Note: Specifying nil for the fill material will leave the sheared face unfilled.
    func clip(to plane: Plane, fill: Material? = nil) -> Mesh {
        guard !polygons.isEmpty else {
            return self
        }
        switch bounds.compare(with: plane) {
        case .front:
            return self
        case .back:
            return .empty
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
                isConvex: false,
                isWatertight: nil,
                submeshes: isKnownConvex ? submeshesIfEmpty : nil
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
            let normal = Vector.unitZ
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
                    Vertex(unchecked: Vector(-radius, radius), -normal, .zero, nil),
                    Vertex(unchecked: Vector(radius, radius), -normal, Vector(1, 0), nil),
                    Vertex(unchecked: Vector(radius, -radius), -normal, Vector(1, 1), nil),
                    Vertex(unchecked: Vector(-radius, -radius), -normal, Vector(0, 1), nil),
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
                isConvex: isKnownConvex,
                isWatertight: watertightIfSet,
                submeshes: isKnownConvex ? submeshesIfEmpty : nil
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
        _ isCancelled: CancellationHandler
    ) -> Mesh {
        var meshes = meshes
        var i = 0
        while i < meshes.count {
            _ = reduce(&meshes, at: i, using: fn, isCancelled)
            i += 1
        }
        return .merge(meshes)
    }

    // Merge each intersecting mesh after i into the mesh at index i using fn
    static func reduce(
        _ meshes: [Mesh],
        using fn: (Mesh, Mesh, CancellationHandler) -> Mesh,
        _ isCancelled: CancellationHandler
    ) -> Mesh {
        var meshes = meshes
        return reduce(&meshes, at: 0, using: fn, isCancelled)
    }

    static func reduce(
        _ meshes: inout [Mesh],
        at i: Int,
        using fn: (Mesh, Mesh, CancellationHandler) -> Mesh,
        _ isCancelled: CancellationHandler
    ) -> Mesh {
        var m = meshes[i]
        var j = i + 1
        while j < meshes.count {
            let n = meshes[j]
            if m.bounds.intersects(n.bounds) {
                withoutActuallyEscaping(isCancelled) { isCancelled in
                    m = fn(m, n, isCancelled)
                }
                meshes[i] = m
                meshes.remove(at: j)
                j = i
            }
            j += 1
        }
        return m
    }
}
