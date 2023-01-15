//
//  Mesh+CSG.swift
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
    /// - Returns: A new mesh representing the union of the input meshes.
    func union(_ mesh: Mesh, isCancelled: CancellationHandler = { false }) -> Mesh {
        let intersection = bounds.intersection(mesh.bounds)
        if intersection.isEmpty {
            return Mesh(
                unchecked: polygons + mesh.polygons,
                bounds: bounds.union(mesh.bounds),
                isConvex: false,
                isWatertight: watertightIfSet.flatMap { isWatertight in
                    mesh.watertightIfSet.map { $0 && isWatertight }
                },
                submeshes: [self, mesh]
            )
        }
        var lhs: [Polygon] = [], rhs: [Polygon] = []
        inParallel({
            var aout: [Polygon]? = []
            let ap = BSP(mesh, isCancelled).clip(
                boundsTest(intersection, polygons, &aout),
                .greaterThan,
                isCancelled
            )
            lhs = aout! + ap
        }, {
            var bout: [Polygon]? = []
            let bp = BSP(self, isCancelled).clip(
                boundsTest(intersection, mesh.polygons, &bout),
                .greaterThanEqual,
                isCancelled
            )
            rhs = bout! + bp
        })
        return Mesh(
            unchecked: lhs + rhs,
            bounds: bounds.union(mesh.bounds),
            isConvex: false,
            isWatertight: nil,
            submeshes: nil // TODO: can this be preserved?
        )
    }

    /// Efficiently forms a union from multiple meshes.
    /// - Parameters
    ///   - meshes: A collection of meshes to be unioned.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: A new mesh representing the union of the input meshes.
    static func union<T: Collection>(
        _ meshes: T,
        isCancelled: CancellationHandler = { false }
    ) -> Mesh where T.Element == Mesh {
        merge(meshes, using: { $0.union($1, isCancelled: $2) }, isCancelled)
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
    /// - Returns: A new mesh representing the result of the subtraction.
    func subtract(_ mesh: Mesh, isCancelled: CancellationHandler = { false }) -> Mesh {
        let intersection = bounds.intersection(mesh.bounds)
        guard !intersection.isEmpty else {
            return self
        }
        var lhs: [Polygon] = [], rhs: [Polygon] = []
        inParallel({
            var aout: [Polygon]? = []
            let ap = BSP(mesh, isCancelled).clip(
                boundsTest(intersection, polygons, &aout),
                .greaterThan,
                isCancelled
            )
            lhs = aout! + ap
        }, {
            var bout: [Polygon]?
            let bp = BSP(self, isCancelled).clip(
                boundsTest(intersection, mesh.polygons, &bout),
                .lessThan,
                isCancelled
            )
            rhs = bp.inverted()
        })
        return Mesh(
            unchecked: lhs + rhs,
            bounds: nil, // TODO: is there a way to preserve this efficiently?
            isConvex: false,
            isWatertight: nil,
            submeshes: nil // TODO: can this be preserved?
        )
    }

    /// Efficiently gets the difference between multiple meshes.
    /// - Parameters
    ///   - meshes: An ordered collection of meshes. All but the first will be subtracted from the first.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: A new mesh representing the difference between the meshes.
    static func difference<T: Collection>(
        _ meshes: T,
        isCancelled: CancellationHandler = { false }
    ) -> Mesh where T.Element == Mesh {
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
    /// - Returns: A new mesh representing the XOR of the meshes.
    func xor(_ mesh: Mesh, isCancelled: CancellationHandler = { false }) -> Mesh {
        let intersection = bounds.intersection(mesh.bounds)
        guard !intersection.isEmpty else {
            return merge(mesh)
        }
        var absp, bbsp: BSP!
        inParallel({
            absp = BSP(self, isCancelled)
        }, {
            bbsp = BSP(mesh, isCancelled)
        })
        var lhs: [Polygon] = [], rhs: [Polygon] = []
        inParallel({
            var aout: [Polygon]? = []
            let ap = boundsTest(intersection, polygons, &aout)
            let (ap1, ap2) = bbsp.split(ap, .greaterThan, .lessThan, isCancelled)
            lhs = aout! + ap1 + ap2.inverted()
        }, {
            var bout: [Polygon]? = []
            let bp = boundsTest(intersection, mesh.polygons, &bout)
            let (bp2, bp1) = absp.split(bp, .greaterThan, .lessThan, isCancelled)
            rhs = bout! + bp2 + bp1.inverted()
        })

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
    ///   - meshes: A collection of meshes to be XORed.
    ///   - isCancelled: Callback used to cancel the operation
    /// - Returns: A new mesh representing the XOR of the meshes.
    static func xor<T: Collection>(
        _ meshes: T,
        isCancelled: CancellationHandler = { false }
    ) -> Mesh where T.Element == Mesh {
        merge(meshes, using: { $0.xor($1, isCancelled: $2) }, isCancelled)
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
    /// - Returns: A new mesh representing the intersection of the meshes.
    func intersect(
        _ mesh: Mesh,
        isCancelled: CancellationHandler = { false }
    ) -> Mesh {
        let intersection = bounds.intersection(mesh.bounds)
        guard !intersection.isEmpty else {
            return .empty
        }
        var out: [Polygon]?
        var lhs: [Polygon] = [], rhs: [Polygon] = []
        inParallel({
            lhs = BSP(mesh, isCancelled).clip(
                boundsTest(intersection, polygons, &out),
                .lessThan,
                isCancelled
            )
        }, {
            rhs = BSP(self, isCancelled).clip(
                boundsTest(intersection, mesh.polygons, &out),
                .lessThanEqual,
                isCancelled
            )
        })
        return Mesh(
            unchecked: lhs + rhs,
            bounds: nil, // TODO: is there a way to efficiently preserve this?
            isConvex: isKnownConvex && mesh.isKnownConvex,
            isWatertight: nil,
            submeshes: nil // TODO: can this be preserved?
        )
    }

    /// Efficiently computes the intersection of multiple meshes.
    /// - Parameters
    ///   - meshes: A collection of meshes to be intersected.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: A new mesh representing the intersection of the meshes.
    static func intersection<T: Collection>(
        _ meshes: T,
        isCancelled: CancellationHandler = { false }
    ) -> Mesh where T.Element == Mesh {
        let head = meshes.first ?? .empty, tail = meshes.dropFirst()
        let bounds = tail.reduce(into: head.bounds) { $0.formUnion($1.bounds) }
        if bounds.isEmpty {
            return .empty
        }
        return tail.reduce(into: head) {
            $0 = $0.intersect($1, isCancelled: isCancelled)
        }
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
    /// - Returns: A new mesh representing the result of stencilling.
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
    ///   - meshes: An ordered collection of meshes. All but the first will be stencilled onto the first.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: A new mesh representing the result of stencilling.
    static func stencil<T: Collection>(
        _ meshes: T,
        isCancelled: CancellationHandler = { false }
    ) -> Mesh where T.Element == Mesh {
        reduce(meshes, using: { $0.stencil($1, isCancelled: $2) }, isCancelled)
    }

    /// Split the mesh along a plane.
    /// - Parameter along: The ``Plane`` to split the mesh along.
    /// - Returns: A pair of meshes representing the parts in front of and behind the plane respectively.
    ///
    /// > Note: If the plane and mesh do not intersect, one of the returned meshes will be `nil`.
    func split(along plane: Plane) -> (front: Mesh?, back: Mesh?) {
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
            if front.isEmpty {
                return (nil, self)
            } else if back.isEmpty {
                return (self, nil)
            }
            return (
                Mesh(
                    unchecked: front,
                    bounds: nil,
                    isConvex: false,
                    isWatertight: nil,
                    submeshes: nil
                ),
                Mesh(
                    unchecked: back,
                    bounds: nil,
                    isConvex: false,
                    isWatertight: nil,
                    submeshes: nil
                )
            )
        }
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
            let rect = Polygon(
                unchecked: [
                    Vertex(unchecked: Vector(-radius, radius), .unitZ, .zero, nil),
                    Vertex(unchecked: Vector(-radius, -radius), .unitZ, Vector(0, 1), nil),
                    Vertex(unchecked: Vector(radius, -radius), .unitZ, Vector(1, 1), nil),
                    Vertex(unchecked: Vector(radius, radius), .unitZ, Vector(1, 0), nil),
                ],
                normal: .unitZ,
                isConvex: true,
                material: material
            )
            .rotated(by: -rotationBetweenVectors(.unitZ, -plane.normal))
            .translated(by: plane.normal * plane.w)
            // Clip rect
            return Mesh(
                unchecked: mesh.polygons + BSP(self) { false }
                    .clip([rect], .lessThanEqual) { false },
                bounds: nil,
                isConvex: isKnownConvex,
                isWatertight: watertightIfSet,
                submeshes: isKnownConvex ? submeshesIfEmpty : nil
            )
        }
    }

    /// Computes a set of edges where the mesh intersects a plane.
    /// - Parameter plane: A ``Plane`` to test against the mesh.
    /// - Returns: A `Set` of ``LineSegment`` representing the polygon edges intersecting the plane.
    func edges(intersecting plane: Plane) -> Set<LineSegment> {
        var edges = Set<LineSegment>()
        for polygon in polygons {
            polygon.intersect(with: plane, edges: &edges)
        }
        return edges
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
    static func merge<T: Collection>(
        _ meshes: T,
        using fn: (Mesh, Mesh, CancellationHandler) -> Mesh,
        _ isCancelled: CancellationHandler
    ) -> Mesh where T.Element == Mesh {
        var meshes = Array(meshes)
        var i = 0
        while i < meshes.count {
            _ = reduce(&meshes, at: i, using: fn, isCancelled)
            i += 1
        }
        return .merge(meshes)
    }

    // Merge each intersecting mesh after i into the mesh at index i using fn
    static func reduce<T: Collection>(
        _ meshes: T,
        using fn: (Mesh, Mesh, CancellationHandler) -> Mesh,
        _ isCancelled: CancellationHandler
    ) -> Mesh where T.Element == Mesh {
        var meshes = Array(meshes)
        return meshes.isEmpty ? .empty : reduce(&meshes, at: 0, using: fn, isCancelled)
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

#if canImport(Dispatch) && !arch(wasm32)

import Dispatch

private func inParallel(_ op1: () -> Void, _ op2: () -> Void) {
    DispatchQueue.concurrentPerform(iterations: 2) { index in
        switch index {
        case 0: op1()
        default: op2()
        }
    }
}

#else

private func inParallel(_ op1: () -> Void, _ op2: () -> Void) {
    op1()
    op2()
}

#endif
