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
    /// - Parameters:
    ///   - mesh: The mesh to form a union with.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: A new mesh representing the union of the input meshes.
    func union(_ mesh: Mesh, isCancelled: CancellationHandler = { false }) -> Mesh {
        let intersection = bounds.intersection(mesh.bounds)
        if intersection.isEmpty {
            return Mesh(
                unchecked: polygons + mesh.polygons,
                bounds: bounds.union(mesh.bounds),
                bsp: nil, // TODO: Is there a cheap way to calculate this?
                isConvex: false,
                isWatertight: watertightIfSet.flatMap { isWatertight in
                    mesh.watertightIfSet.map { $0 && isWatertight }
                },
                submeshes: submeshesIfEmpty.flatMap { _ in
                    mesh.submeshesIfEmpty.map { _ in [self, mesh] }
                }
            )
        }
        var lhs: [Polygon] = [], rhs: [Polygon] = []
        inParallel({
            var aout: [Polygon] = []
            let ap = BSP(mesh, isCancelled).clip(
                boundsTest(intersection, polygons, &aout),
                .greaterThan,
                isCancelled
            )
            lhs = aout + ap
        }, {
            var bout: [Polygon] = []
            let bp = BSP(self, isCancelled).clip(
                boundsTest(intersection, mesh.polygons, &bout),
                .greaterThanEqual,
                isCancelled
            )
            rhs = bout + bp
        })
        return Mesh(
            unchecked: lhs + rhs,
            bounds: bounds.union(mesh.bounds),
            bsp: nil, // TODO: Is there a cheap way to calculate this?
            isConvex: false,
            isWatertight: nil,
            submeshes: nil // TODO: can this be preserved?
        )
    }

    /// Efficiently forms a union from multiple meshes.
    /// - Parameters:
    ///   - meshes: A collection of meshes to be unioned.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: A new mesh representing the union of the input meshes.
    static func union(
        _ meshes: some Collection<Mesh>,
        isCancelled: CancellationHandler = { false }
    ) -> Mesh {
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
    /// - Parameters:
    ///   - mesh: The mesh to subtract from this one.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: A new mesh representing the result of the subtraction.
    func subtracting(_ mesh: Mesh, isCancelled: CancellationHandler = { false }) -> Mesh {
        let intersection = bounds.intersection(mesh.bounds)
        guard !intersection.isEmpty else {
            return self
        }
        var lhs: [Polygon] = [], rhs: [Polygon] = []
        inParallel({
            var aout: [Polygon] = []
            let ap = BSP(mesh, isCancelled).clip(
                boundsTest(intersection, polygons, &aout),
                .greaterThan,
                isCancelled
            )
            lhs = aout + ap
        }, {
            let bp = BSP(self, isCancelled).clip(
                boundsTest(intersection, mesh.polygons),
                .lessThan,
                isCancelled
            )
            rhs = bp.inverted()
        })
        return Mesh(
            unchecked: lhs + rhs,
            bounds: nil, // TODO: is there a way to preserve this efficiently?
            bsp: nil, // TODO: Is there a cheap way to calculate this?
            isConvex: false,
            isWatertight: nil,
            submeshes: nil // TODO: can this be preserved?
        )
    }

    /// Efficiently gets the difference between multiple meshes.
    /// - Parameters:
    ///   - meshes: An ordered collection of meshes. All but the first will be subtracted from the first.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: A new mesh representing the difference between the meshes.
    static func difference(
        _ meshes: some Collection<Mesh>,
        isCancelled: CancellationHandler = { false }
    ) -> Mesh {
        reduce(meshes, using: { $0.subtracting($1, isCancelled: $2) }, isCancelled)
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
    /// - Parameters:
    ///   - mesh: The mesh to be XORed with this one.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: A new mesh representing the XOR of the meshes.
    func symmetricDifference(_ mesh: Mesh, isCancelled: CancellationHandler = { false }) -> Mesh {
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
            var aout: [Polygon] = []
            let ap = boundsTest(intersection, polygons, &aout)
            let (ap1, ap2) = bbsp.split(ap, .greaterThan, .lessThan, isCancelled)
            lhs = aout + ap1 + ap2.inverted()
        }, {
            var bout: [Polygon] = []
            let bp = boundsTest(intersection, mesh.polygons, &bout)
            let (bp2, bp1) = absp.split(bp, .greaterThan, .lessThan, isCancelled)
            rhs = bout + bp2 + bp1.inverted()
        })

        return Mesh(
            unchecked: lhs + rhs,
            bounds: nil, // TODO: is there a way to efficiently preserve this?
            bsp: nil, // TODO: Is there a cheap way to calculate this?
            isConvex: false,
            isWatertight: nil,
            submeshes: nil // TODO: can this be preserved?
        )
    }

    /// Efficiently XORs multiple meshes.
    /// - Parameters:
    ///   - meshes: A collection of meshes to be XORed.
    ///   - isCancelled: Callback used to cancel the operation
    /// - Returns: A new mesh representing the XOR of the meshes.
    static func symmetricDifference(
        _ meshes: some Collection<Mesh>,
        isCancelled: CancellationHandler = { false }
    ) -> Mesh {
        merge(meshes, using: { $0.symmetricDifference($1, isCancelled: $2) }, isCancelled)
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
    /// - Parameters:
    ///   - mesh: The mesh to be intersected with this one.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: A new mesh representing the intersection of the meshes.
    func intersection(_ mesh: Mesh, isCancelled: CancellationHandler = { false }) -> Mesh {
        let intersection = bounds.intersection(mesh.bounds)
        guard !intersection.isEmpty else {
            return .empty
        }
        var lhs: [Polygon] = [], rhs: [Polygon] = []
        inParallel({
            lhs = BSP(mesh, isCancelled).clip(
                boundsTest(intersection, polygons),
                .lessThan,
                isCancelled
            )
        }, {
            rhs = BSP(self, isCancelled).clip(
                boundsTest(intersection, mesh.polygons),
                .lessThanEqual,
                isCancelled
            )
        })
        return Mesh(
            unchecked: lhs + rhs,
            bounds: nil, // TODO: is there a way to efficiently preserve this?
            bsp: nil, // TODO: Is there a cheap way to calculate this?
            isConvex: isKnownConvex && mesh.isKnownConvex,
            isWatertight: nil,
            submeshes: nil // TODO: can this be preserved?
        )
    }

    /// Efficiently computes the intersection of multiple meshes.
    /// - Parameters:
    ///   - meshes: A collection of meshes to be intersected.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: A new mesh representing the intersection of the meshes.
    static func intersection(
        _ meshes: some Collection<Mesh>,
        isCancelled: CancellationHandler = { false }
    ) -> Mesh {
        let head = meshes.first ?? .empty, tail = meshes.dropFirst()
        let bounds = tail.reduce(into: head.bounds) { $0.formUnion($1.bounds) }
        if bounds.isEmpty {
            return .empty
        }
        return tail.reduce(into: head) {
            $0 = $0.intersection($1, isCancelled: isCancelled)
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
    /// - Parameters:
    ///   - mesh: The mesh to be stencilled onto this one.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: A new mesh representing the result of stencilling.
    func stencil(_ mesh: Mesh, isCancelled: CancellationHandler = { false }) -> Mesh {
        let intersection = bounds.intersection(mesh.bounds)
        guard !intersection.isEmpty else {
            return self
        }
        var aout: [Polygon] = []
        let ap = boundsTest(bounds.intersection(mesh.bounds), polygons, &aout)
        let bsp = BSP(mesh, isCancelled)
        let (outside, inside) = bsp.split(ap, .greaterThan, .lessThanEqual, isCancelled)
        let material = mesh.polygons.first?.material
        return Mesh(
            unchecked: aout + outside + inside.mapMaterials { _ in material },
            bounds: bounds,
            bsp: nil, // TODO: Would it be safe to keep this?
            isConvex: isKnownConvex,
            isWatertight: isWatertight,
            submeshes: submeshesIfEmpty
        )
    }

    /// Efficiently performs a stencil with multiple meshes.
    /// - Parameters:
    ///   - meshes: An ordered collection of meshes. All but the first will be stencilled onto the first.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: A new mesh representing the result of stencilling.
    static func stencil(
        _ meshes: some Collection<Mesh>,
        isCancelled: CancellationHandler = { false }
    ) -> Mesh {
        reduce(meshes, using: { $0.stencil($1, isCancelled: $2) }, isCancelled)
    }

    /// Returns a new mesh representing a convex hull around the
    /// mesh parameter and the receiver, with inner faces removed.
    ///
    ///     +-------+           +-------+
    ///     |       |           |        \
    ///     |   A   |           |         \
    ///     |   +---+---+   =   |          +
    ///     +---+---+   |       +          |
    ///         |   B   |        \         |
    ///         |       |         \        |
    ///         +-------+          +-------+
    ///
    /// - Parameters:
    ///   - mesh: The mesh to form a hull with.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: A new mesh representing the convex hull around the inputs.
    func convexHull(with mesh: Mesh, isCancelled: CancellationHandler = { false }) -> Mesh {
        .convexHull(of: [self, mesh], isCancelled: isCancelled)
    }

    /// Efficiently computes the convex hull of one or more meshes.
    /// - Parameters:
    ///   - meshes: A collection of meshes to compute a hull around.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: A new mesh representing the convex hull around the inputs.
    static func convexHull(
        of meshes: some Collection<Mesh>,
        isCancelled: CancellationHandler = { false }
    ) -> Mesh {
        var best: Mesh?
        var bestIndex: Int?
        for (i, mesh) in meshes.enumerated() where mesh.isKnownConvex && mesh.isWatertight {
            if best?.polygons.count ?? 0 > mesh.polygons.count {
                continue
            }
            best = mesh
            bestIndex = i
        }
        let polygons = meshes.enumerated().flatMap { i, mesh in
            i == bestIndex ? [] : mesh.polygons
        }
        let bounds = Bounds(meshes)
        return .convexHull(of: polygons, with: best, bounds: bounds, isCancelled)
    }

    /// Computes the convex hull of a set of polygons.
    /// - Parameters:
    ///   - polygons: A collection of polygons to compute a hull around.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: A new mesh representing the convex hull around the inputs.
    static func convexHull(
        of polygons: some Collection<Polygon>,
        isCancelled: CancellationHandler = { false }
    ) -> Mesh {
        convexHull(of: Array(polygons), with: nil, bounds: nil, isCancelled)
    }

    /// Returns a new mesh representing the Minkowski sum of the
    /// mesh parameter and the receiver.
    ///
    ///     __                     ________
    ///    /A \                   /        \
    ///    \__/  +-------+   =   +          +
    ///          |       |       |          |
    ///          |   B   |       |          |
    ///          |       |       |          |
    ///          +-------+       +          +
    ///                           \________/
    ///
    /// - Parameters:
    ///   - mesh: The mesh to form a sum with.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: A new mesh representing the Minkowski sum of the input meshes.
    func minkowskiSum(with mesh: Mesh, isCancelled: CancellationHandler = { false }) -> Mesh {
        if isEmpty {
            return mesh
        } else if mesh.isEmpty {
            return self
        }
        if mesh.isConvex(isCancelled: isCancelled), mesh.isWatertight {
            let points = Set(mesh.polygons.flatMap { $0.vertices.map(\.position) }).sorted()
            return .convexHull(of: points.map(translated(by:)))
        }
        return .union([mesh] + mesh.polygons.map {
            isCancelled() ? .empty : minkowskiSum(with: $0)
        }, isCancelled: isCancelled)
    }

    /// Efficiently computes the Minkowski sum of two or more meshes.
    /// - Parameters:
    ///   - meshes: A collection of meshes to compute the sum of.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: A new mesh representing the Minkowski sum of all the inputs.
    static func minkowskiSum(
        of meshes: some Collection<Mesh>,
        isCancelled: CancellationHandler = { false }
    ) -> Mesh {
        guard let first = meshes.first else {
            return .empty
        }
        return first.minkowskiSum(
            with: .minkowskiSum(of: meshes.dropFirst(), isCancelled: isCancelled),
            isCancelled: isCancelled
        )
    }

    /// Computes the minkowskiSum sum of the receiver along the specified path.
    /// - Parameters:
    ///   - path: A ``Path`` along which to sum the mesh.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: A new mesh representing the Minkowski sum of all the inputs.
    func minkowskiSum(along path: Path, isCancelled: CancellationHandler = { false }) -> Mesh {
        .union(path.orderedEdges.map {
            isCancelled() ? .empty : minkowskiSum(along: $0)
        }, isCancelled: isCancelled)
    }

    /// Computes the Minkowski sum of the receiver and a polygon.
    /// - Parameter polygon: The polygon with which to sum the mesh.
    /// - Returns: A new mesh representing the Minkowski sum of the inputs.
    func minkowskiSum(with polygon: Polygon) -> Mesh {
        guard polygon.isConvex else {
            return .union(polygons.tessellate().map(minkowskiSum(with:)))
        }
        return .convexHull(of: polygon.vertices.map { translated(by: $0.position) })
    }

    /// Computes the minkowskiSum sum of the receiver along the specified edge.
    /// - Parameter edge: A ``LineSegment`` along which to sum the mesh.
    /// - Returns: A new mesh representing the Minkowski sum of the inputs.
    func minkowskiSum(along edge: LineSegment) -> Mesh {
        .convexHull(of: [
            translated(by: edge.start),
            translated(by: edge.end),
        ])
    }

    /// Split the mesh along a plane.
    /// - Parameter plane: The ``Plane`` to split the mesh along.
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
            for polygon in coplanar {
                plane.normal.dot(polygon.plane.normal) > 0 ?
                    front.append(polygon) : back.append(polygon)
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
                    bsp: nil, // TODO: can we compute this cheaply?
                    isConvex: isKnownConvex,
                    isWatertight: nil,
                    submeshes: nil
                ),
                Mesh(
                    unchecked: back,
                    bounds: nil,
                    bsp: nil, // TODO: can we compute this cheaply?
                    isConvex: isKnownConvex,
                    isWatertight: nil,
                    submeshes: nil
                )
            )
        }
    }

    /// Clip mesh to the specified plane and optionally fill sheared faces with specified material.
    /// - Parameters:
    ///   - plane: The plane to clip the mesh to
    ///   - fill: The material to fill the sheared face(s) with.
    ///
    /// > Note: Specifying nil for the fill material will leave the sheared face unfilled.
    func clipped(to plane: Plane, fill: Material? = nil) -> Mesh {
        guard !polygons.isEmpty else {
            return self
        }
        switch bounds.compare(with: plane) {
        case .front:
            return self
        case .back:
            return .empty
        case .spanning, .coplanar:
            // TODO: can we use BSP to improve perf here at all?
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
                bsp: nil, // TODO: can we compute this cheaply?
                isConvex: isKnownConvex,
                isWatertight: nil,
                submeshes: isKnownConvex ? submeshesIfEmpty : nil
            )
            guard let material = fill else {
                return mesh
            }
            // Project each corner of mesh bounds onto plane to find radius
            var radius = 0.0
            for corner in mesh.bounds.corners {
                let p = plane.nearestPoint(to: corner)
                radius = max(radius, p.lengthSquared)
            }
            radius = radius.squareRoot()
            // Create back face
            let rect = Polygon(
                unchecked: [
                    Vertex(unchecked: [-radius, radius], .unitZ, .zero, nil),
                    Vertex(unchecked: [-radius, -radius], .unitZ, [0, 1], nil),
                    Vertex(unchecked: [radius, -radius], .unitZ, [1, 1], nil),
                    Vertex(unchecked: [radius, radius], .unitZ, [1, 0], nil),
                ],
                normal: .unitZ,
                isConvex: true,
                sanitizeNormals: false,
                material: material
            )
            .rotated(by: rotationBetweenNormalizedVectors(.unitZ, -plane.normal))
            .translated(by: plane.normal * plane.w)
            // Clip rect
            let isCancelled: CancellationHandler = { false }
            return Mesh(
                unchecked: mesh.polygons + BSP(self, isCancelled).clip([rect], .lessThanEqual, isCancelled),
                bounds: nil,
                bsp: nil,
                isConvex: isKnownConvex,
                isWatertight: isWatertight,
                submeshes: isKnownConvex ? submeshesIfEmpty : nil
            )
        }
    }

    /// Deprecated.
    @available(*, deprecated, renamed: "clipped(to:fill:)")
    func clip(to plane: Plane, fill: Material? = nil) -> Mesh {
        clipped(to: plane, fill: fill)
    }

    /// Computes a set of edges where the mesh intersects a plane.
    /// - Parameter plane: A ``Plane`` to test against the mesh.
    /// - Returns: A `Set` of ``LineSegment`` representing the polygon edges intersections.
    func edges(intersecting plane: Plane) -> Set<LineSegment> {
        var edges = Set<LineSegment>()
        for polygon in polygons {
            polygon.intersect(with: plane, segments: &edges)
        }
        return edges
    }

    /// Clip receiver to the specified mesh.
    /// - Parameters:
    ///   - mesh: The mesh to clip the receiver to.
    ///   - isCancelled: Callback used to cancel the operation.
    ///
    /// > Note: Unlike `subtracting()`, this method does not require the receiver to be watertight,
    /// but also does not fill the hole(s) left behind by the clipping operation, and may expose backfaces.
    func clipped(to mesh: Mesh, isCancelled: CancellationHandler = { false }) -> Mesh {
        let intersection = bounds.intersection(mesh.bounds)
        guard !intersection.isEmpty else {
            return self
        }
        var aout: [Polygon] = []
        let ap = BSP(mesh, isCancelled).clip(
            boundsTest(intersection, polygons, &aout),
            .greaterThan,
            isCancelled
        )
        return Mesh(
            unchecked: aout + ap,
            bounds: nil,
            bsp: nil, // TODO: Is there a cheaper way to calculate this?
            isConvex: false,
            isWatertight: nil,
            submeshes: nil
        )
    }

    /// Computes a set of edges where the mesh intersects another mesh.
    /// - Parameters:
    ///   - mesh: A ``Mesh`` to find the edge intersections with.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: A `Set` of ``LineSegment`` representing the polygon edge intersections.
    func edges(
        intersecting mesh: Mesh,
        isCancelled: CancellationHandler = { false }
    ) -> Set<LineSegment> {
        let intersection = bounds.intersection(mesh.bounds)
        guard !intersection.isEmpty else {
            return []
        }
        var a = self, b = mesh
        if a.polygons.count > b.polygons.count {
            (a, b) = (b, a)
        }
        let bsp = BSP(a, isCancelled)
        let polygons = boundsTest(intersection, b.polygons)
        return bsp.clip(polygons, .lessThan, isCancelled).holeEdges
    }

    /// Reflects each polygon of the mesh along a plane.
    /// - Parameter plane: The ``Plane`` against which the vertices are to be reflected.
    /// - Returns: A ``Mesh`` representing the reflected mesh.
    func reflected(along plane: Plane) -> Mesh {
        Mesh(polygons.map { $0.reflected(along: plane) })
    }
}

private func boundsTest(_ bounds: Bounds, _ polygons: [Polygon]) -> [Polygon] {
    polygons.filter { $0.bounds.intersects(bounds) }
}

private func boundsTest(
    _ bounds: Bounds,
    _ polygons: [Polygon],
    _ out: inout [Polygon]
) -> [Polygon] {
    polygons.filter {
        if $0.bounds.intersects(bounds) {
            return true
        }
        out.append($0)
        return false
    }
}

private extension Mesh {
    /// Merge all the meshes into a single mesh using fn
    static func merge(
        _ meshes: some Collection<Mesh>,
        using fn: (Mesh, Mesh, CancellationHandler) -> Mesh,
        _ isCancelled: CancellationHandler
    ) -> Mesh {
        var meshes = Array(meshes)
        var i = 0
        while i < meshes.count {
            _ = reduce(&meshes, at: i, using: fn, isCancelled)
            i += 1
        }
        return .merge(meshes)
    }

    /// Merge each intersecting mesh after i into the mesh at index i using fn
    static func reduce(
        _ meshes: some Collection<Mesh>,
        using fn: (Mesh, Mesh, CancellationHandler) -> Mesh,
        _ isCancelled: CancellationHandler
    ) -> Mesh {
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

    static func convexHull(
        of polygonsToAdd: [Polygon],
        with startingMesh: Mesh?,
        bounds: Bounds?,
        _ isCancelled: CancellationHandler
    ) -> Mesh {
        assert(startingMesh?.isKnownConvex != false)
        assert(startingMesh?.isWatertight != false)
        var polygons = startingMesh?.polygons ?? []
        var verticesByPosition = [Vector: [(faceNormal: Vector, Vertex)]]()
        for p in polygonsToAdd + polygons {
            for v in p.vertices {
                verticesByPosition[v.position, default: []].append((p.plane.normal, v))
            }
        }
        var polygonsToAdd = polygonsToAdd
        if polygons.isEmpty, !polygonsToAdd.isEmpty {
            let polygon: Polygon
            if let index = polygonsToAdd.lastIndex(where: { $0.isConvex }) {
                polygon = polygonsToAdd.remove(at: index)
            } else {
                let potentiallyNonConvexPolygon = polygonsToAdd.removeLast()
                var convexPolygons = potentiallyNonConvexPolygon.tessellate()
                polygon = convexPolygons.popLast() ?? potentiallyNonConvexPolygon
                polygonsToAdd += convexPolygons
                assert(polygon.isConvex)
            }
            polygons += [polygon, polygon.inverted()]
        }
        // Add remaining polygons
        // Note: no need to use a VertexSet here as vertex positions should already
        // be unique, but perhaps there is a opportunity to merge some things?
        var pointSet = Set<Vector>()
        for polygon in polygonsToAdd where !isCancelled() {
            for vertex in polygon.vertices where pointSet.insert(vertex.position).inserted {
                polygons.addPoint(
                    vertex.position,
                    material: polygon.material,
                    verticesByPosition: verticesByPosition
                )
            }
        }
        return Mesh(
            unchecked: polygons,
            bounds: bounds,
            bsp: nil,
            isConvex: true,
            isWatertight: true,
            submeshes: []
        )
    }
}

extension [Polygon] {
    mutating func addPoint(
        _ point: Vector,
        material: Polygon.Material?,
        verticesByPosition: [Vector: [(faceNormal: Vector, Vertex)]]
    ) {
        var facing = [Polygon](), coplanar = [Vector: [Polygon]]()
        loop: for (i, polygon) in enumerated().reversed() {
            switch point.compare(with: polygon.plane) {
            case .front:
                facing.append(polygon)
                remove(at: i)
            case .coplanar where facing.isEmpty:
                // TODO: improve intersects implementation so both checks aren't needed
                if polygon.vertices.contains(where: { $0.position == point }) || polygon.intersects(point) {
                    // if point is inside an existing polygon we can skip it
                    return
                }
                coplanar[polygon.plane.normal, default: []].append(polygon)
            case .back, .spanning, .coplanar:
                continue
            }
        }
        // Create triangles from point to edges
        func addTriangles(with edges: [LineSegment], faceNormal: Vector?) {
            for edge in edges {
                guard let triangle = Polygon(
                    points: [point, edge.start, edge.end],
                    verticesByPosition: verticesByPosition,
                    faceNormal: faceNormal,
                    material: material
                ) else {
                    assertionFailure()
                    continue
                }
                append(triangle)
            }
        }
        // Extend polygons to include point
        guard facing.isEmpty else {
            addTriangles(with: facing.boundingEdges, faceNormal: nil)
            return
        }
        assert(coplanar.count <= 2)
        for (faceNormal, polygons) in coplanar {
            guard let polygon = polygons.first else { continue }
            addTriangles(with: polygons.boundingEdges.compactMap {
                let edgePlane = polygon.edgePlane(for: $0)
                if point.compare(with: edgePlane) == .front {
                    return $0.inverted()
                }
                return nil
            }, faceNormal: faceNormal)
        }
    }
}

extension Polygon {
    /// Create polygon from points with nearest matches in a vertex collection
    init?(
        points: some Collection<Vector>,
        verticesByPosition: [Vector: [(faceNormal: Vector, Vertex)]],
        faceNormal: Vector?,
        material: Polygon.Material?
    ) {
        let faceNormal = faceNormal ?? faceNormalForPoints(Array(points))
        let vertices = points.map { p -> Vertex in
            let matches = verticesByPosition[p] ?? []
            var best: Vertex?, bestDot = 1.0
            for (n, v) in matches {
                let dot = abs(1 - n.dot(faceNormal))
                if dot <= bestDot {
                    bestDot = dot
                    best = v
                }
            }
            if bestDot == 1 {
                best?.normal = .zero
            }
            return best ?? Vertex(p)
        }
        self.init(vertices, material: material)
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
