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
            isWatertight: nil, // TODO: figure out why stencil creates holes
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

    /// Computes the convex hull of a set of paths.
    /// - Parameters:
    ///   - paths: A set of paths to compute the hull around.
    ///   - material: An optional material to apply to the mesh.
    ///   - isCancelled: Callback used to cancel the operation.
    static func convexHull(
        of paths: some Collection<Path>,
        material: Material? = nil,
        isCancelled: CancellationHandler = { false }
    ) -> Mesh {
        convexHull(of: paths.flatMap(\.edgeVertices), material: material, isCancelled: isCancelled)
    }

    /// Computes the convex hull of a set of path points.
    /// - Parameters:
    ///   - points: A set of path points to compute the hull around.
    ///   - material: An optional material to apply to the mesh.
    ///   - isCancelled: Callback used to cancel the operation.
    ///
    /// > Note: The curvature of the point is currently ignored when calculating hull surface normals.
    static func convexHull(
        of points: some Collection<PathPoint>,
        material: Material? = nil,
        isCancelled: CancellationHandler = { false }
    ) -> Mesh {
        convexHull(of: points.map(Vertex.init), material: material, isCancelled: isCancelled)
    }

    /// Computes the convex hull of a set of vertices.
    /// - Parameters:
    ///   - vertices: A set of vertices to compute the hull around.
    ///   - material: An optional material to apply to the mesh.
    ///   - isCancelled: Callback used to cancel the operation.
    static func convexHull(
        of vertices: some Collection<Vertex>,
        material: Material? = nil,
        isCancelled: CancellationHandler = { false }
    ) -> Mesh {
        var verticesByPosition = [Vector: [(faceNormal: Vector, Vertex)]]()
        for v in vertices {
            verticesByPosition[v.position, default: []].append((v.normal, v))
        }
        return convexHull(of: verticesByPosition, material: material, isCancelled)
    }

    /// Computes the convex hull of a set of points.
    /// - Parameters:
    ///   - points: An set of points to compute the hull around.
    ///   - material: An optional material to apply to the mesh.
    ///   - isCancelled: Callback used to cancel the operation.
    static func convexHull(
        of points: some Collection<Vector>,
        material: Material? = nil,
        isCancelled: CancellationHandler = { false }
    ) -> Mesh {
        convexHull(
            of: Dictionary(points.map { ($0, []) }, uniquingKeysWith: { $1 }),
            material: material,
            isCancelled
        )
    }

    /// Computes the convex hull of a set of line segments.
    /// - Parameters:
    ///   - edges: A set of line segments to compute the hull around.
    ///   - material: An optional material to apply to the mesh.
    ///   - isCancelled: Callback used to cancel the operation.
    static func convexHull(
        of edges: some Collection<LineSegment>,
        material: Material? = nil,
        isCancelled: CancellationHandler = { false }
    ) -> Mesh {
        convexHull(of: edges.flatMap { [$0.start, $0.end] }, material: material, isCancelled: isCancelled)
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
        if mesh.isConvex(isCancelled: isCancelled) {
            guard isConvex(isCancelled: isCancelled) else {
                // Preserve concavity
                return mesh.minkowskiSum(with: self)
            }
            let vertices = Set(mesh.polygons.flatMap {
                $0.vertices.map { Vertex($0.position, color: $0.color) }
            }).sorted(by: { $0.position < $1.position })
            return .convexHull(of: vertices.map { vertex in
                translated(by: vertex.position).mapVertexColors { $0 * vertex.color }
            })
        }
        return .union([mesh.translated(by: bounds.center)] + mesh.polygons.map {
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

    /// Computes the minkowskiSum sum of the receiver with the specified path.
    /// - Parameters:
    ///   - path: A ``Path`` with which to sum the mesh.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: A new mesh representing the Minkowski sum of all the inputs.
    func minkowskiSum(with path: Path, isCancelled: CancellationHandler = { false }) -> Mesh {
        guard let point = path.points.first else {
            return .empty
        }
        let subpaths = path.subpaths
        if subpaths.count > 1 {
            return .union(subpaths.map {
                minkowskiSum(with: $0, isCancelled: isCancelled)
            }, isCancelled: isCancelled)
        }
        let color = point.color ?? .white
        var a = translated(by: point.position).mapVertexColors { $0 * color }
        guard path.points.count > 1 else {
            return a
        }
        return .union(path.points.dropFirst().map { point in
            if isCancelled() { return .empty }
            let color = point.color ?? .white
            let b = translated(by: point.position).mapVertexColors { $0 * color }
            defer { a = b }
            return .convexHull(of: [a, b], isCancelled: isCancelled)
        })
    }

    /// Deprecated.
    @available(*, deprecated, renamed: "minkowskiSum(with:isCancelled:)")
    func minkowskiSum(along path: Path, isCancelled: CancellationHandler = { false }) -> Mesh {
        minkowskiSum(with: path, isCancelled: isCancelled)
    }

    /// Computes the Minkowski sum of the receiver and a polygon.
    /// - Parameter polygon: The polygon with which to sum the mesh.
    /// - Returns: A new mesh representing the Minkowski sum of the inputs.
    func minkowskiSum(with polygon: Polygon) -> Mesh {
        guard polygon.isConvex else {
            return .union(polygon.tessellate().map(minkowskiSum(with:)))
        }
        return .convexHull(of: polygon.vertices.map { vertex in
            translated(by: vertex.position).mapVertexColors { $0 * vertex.color }
        })
    }

    /// Computes the minkowskiSum sum of the receiver with the specified edge.
    /// - Parameter edge: A ``LineSegment`` with which to sum the mesh.
    /// - Returns: A new mesh representing the Minkowski sum of the inputs.
    func minkowskiSum(with edge: LineSegment) -> Mesh {
        .convexHull(of: [
            translated(by: edge.start),
            translated(by: edge.end),
        ])
    }

    /// Deprecated.
    @available(*, deprecated, renamed: "minkowskiSum(with:isCancelled:)")
    func minkowskiSum(along edge: LineSegment) -> Mesh {
        minkowskiSum(with: edge)
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
        assert(startingMesh?.isConvex() != false)
        assert(startingMesh?.isWatertight != false)
        var polygons = startingMesh?.polygons ?? []
        var polygonsToAdd = polygonsToAdd
        if polygons.isEmpty {
            let polygon: Polygon
            if let index = polygonsToAdd.lastIndex(where: { $0.isConvex }) {
                polygon = polygonsToAdd.remove(at: index)
            } else if !polygonsToAdd.isEmpty {
                let potentiallyNonConvexPolygon = polygonsToAdd.removeLast()
                var convexPolygons = potentiallyNonConvexPolygon.tessellate()
                polygon = convexPolygons.popLast() ?? potentiallyNonConvexPolygon
                polygonsToAdd += convexPolygons
                assert(polygon.isConvex)
            } else {
                return .empty
            }
            polygons = [polygon, polygon.inverted()]
        }
        var verticesByPosition = [Vector: [(faceNormal: Vector, Vertex)]]()
        for p in polygonsToAdd + polygons {
            for v in p.vertices {
                verticesByPosition[v.position, default: []].append((p.plane.normal, v))
            }
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

    static func convexHull(
        of verticesByPosition: [Vector: [(faceNormal: Vector, Vertex)]],
        material: Material?,
        _ isCancelled: CancellationHandler
    ) -> Mesh {
        var points = verticesByPosition.keys.sorted()
        var polygons = [Polygon]()
        // Form a starting triangle pair from 3 non-collinear points
        var i = 3
        while i <= points.endIndex {
            let range = i - 3 ..< i
            if let triangle = Polygon(
                points: points[range],
                verticesByPosition: verticesByPosition,
                faceNormal: nil,
                material: material
            ), let inverse = Polygon(
                // Note: not the same as triangle.inverse()
                points: points[range].reversed(),
                verticesByPosition: verticesByPosition,
                faceNormal: nil,
                material: material
            ) {
                polygons += [triangle, inverse]
                points.removeSubrange(range)
                break
            }
            i += 1
        }
        if polygons.isEmpty {
            return .empty
        }
        // Add remaining points
        // TODO: find better way to batch for cancellation purposes
        for (i, point) in points.enumerated() where i % 100 > 0 || !isCancelled() {
            polygons.addPoint(
                point,
                material: material,
                verticesByPosition: verticesByPosition
            )
        }
        return Mesh(
            unchecked: polygons,
            bounds: nil,
            bsp: nil,
            isConvex: true,
            isWatertight: nil,
            submeshes: []
        )
    }
}

private extension [Polygon] {
    mutating func addPoint(
        _ point: Vector,
        material: Polygon.Material?,
        verticesByPosition: [Vector: [(faceNormal: Vector, Vertex)]]
    ) {
        var facing = [Polygon](), coplanar = [(plane: Plane, polygons: [Polygon])]()
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
                // TODO: improve this part
                if let index = coplanar.firstIndex(where: { $0.plane.isApproximatelyEqual(to: polygon.plane) }) {
                    coplanar[index].polygons.append(polygon)
                } else {
                    coplanar.append((polygon.plane, [polygon]))
                }
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
        // Only add coplanar points if the triangle is added to both sides
        // TODO: make this check more robust, e.g. check each coplanar polygon has a counterpart
        guard !coplanar.isEmpty, coplanar.count % 2 == 0, signedVolume == 0 else {
            return
        }
        for (plane, polygons) in coplanar {
            guard let polygon = polygons.first else { continue }
            let edges = polygons.boundingEdges.compactMap {
                let edgePlane = polygon.edgePlane(for: $0)
                if point.compare(with: edgePlane) == .front {
                    return $0.inverted()
                }
                return nil
            }
            addTriangles(with: edges, faceNormal: plane.normal)
        }
        assert(groupedByPlane().allSatisfy(\.polygons.coplanarPolygonsAreConvex))
    }
}

private extension Polygon {
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
            var best = Vertex(p), bestDot = -Double.infinity
            for (n, v) in matches {
                let dot = n.dot(faceNormal)
                if dot > bestDot {
                    bestDot = dot
                    best = v
                }
            }
            return best
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
