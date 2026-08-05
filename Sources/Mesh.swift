//
//  Mesh.swift
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

/// A 3D surface made of polygons.
///
/// A mesh surface can be convex or concave, and can have zero volume (for example, a flat shape such as a square)
/// but shouldn't contain holes or exposed back-faces.
///
/// The result of CSG operations on meshes that have holes or exposed back-faces is undefined.
public struct Mesh: Hashable, Sendable {
    private let storage: Storage
}

extension Mesh: CustomDebugStringConvertible {
    public var debugDescription: String {
        if polygons.isEmpty {
            return "Mesh.empty"
        }
        let p = polygons.map {
            "\n\t\("\($0)".replacingOccurrences(of: "\n", with: "\n\t")),"
        }.joined()
        return "Mesh([\(p)\n])"
    }

    public var customMirror: Mirror {
        Mirror(self, children: [
            "bounds": storage.boundsIfSet.map { "\($0)" } ?? "unset",
            "isWatertight": storage.watertightIfSet.map { "\($0)" } ?? "unset",
            "isPlanar": storage.planarIfSet.map { "\($0)" } ?? "unset",
            "isKnownConvex": storage.isKnownConvex,
            "bsp": storage.bspIfSet == nil ? "set" : "unset",
        ], displayStyle: .struct)
    }
}

extension Mesh: Codable {
    private enum CodingKeys: String, CodingKey {
        case polygons, materials
    }

    /// Creates a new mesh by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            let polygons: [Polygon]
            if let materials = try container.decodeIfPresent([CodableMaterial].self, forKey: .materials) {
                let polygonsByMaterial = try container.decode([[Polygon]].self, forKey: .polygons)
                polygons = zip(materials, polygonsByMaterial).flatMap { material, polygons in
                    polygons.mapMaterials { _ in material.value }
                }
            } else {
                polygons = try container.decode([Polygon].self, forKey: .polygons)
            }
            self.init(polygons)
        } else {
            let container = try decoder.singleValueContainer()
            let polygons = try container.decode([Polygon].self)
            self.init(polygons)
        }
    }

    /// Encodes this mesh into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if materials == [nil] {
            try container.encode(polygons, forKey: .polygons)
        } else {
            try container.encode(materials.map { CodableMaterial($0) }, forKey: .materials)
            let polygonsByMaterial = polygonsByMaterial
            try container.encode(materials.map { material -> [Polygon] in
                polygonsByMaterial[material]!.mapMaterials { _ in nil }
            }, forKey: .polygons)
        }
    }
}

public extension Mesh {
    /// Material used by the mesh polygons.
    /// See ``Polygon/Material-swift.typealias`` for details.
    typealias Material = Polygon.Material

    /// An empty mesh.
    static let empty: Mesh = .init([])

    /// A Boolean value that indicates whether the mesh is empty (has no polygons).
    /// > Note: This is not the same as checking if the mesh is watertight or has zero volume
    var isEmpty: Bool {
        polygons.isEmpty
    }

    /// All materials used by the mesh.
    /// The array may contain `nil` if some or all of the mesh uses the default material.
    var materials: [Material?] { storage.materials }

    /// The polygons that make up the mesh.
    var polygons: [Polygon] { storage.polygons }

    /// The distinct (disconnected) submeshes that make up the mesh.
    var submeshes: [Mesh] { storage.submeshes }

    /// The polygons in the mesh, grouped by material.
    var polygonsByMaterial: [Material?: [Polygon]] {
        Dictionary(uniqueKeysWithValues: polygons.groupedByMaterial())
    }

    /// A Boolean value that indicates whether the mesh includes texture coordinates.
    var hasTexcoords: Bool {
        polygons.hasTexcoords
    }

    /// A Boolean value that indicates whether the mesh includes vertex normals that differ from the face normal.
    var hasVertexNormals: Bool {
        polygons.hasVertexNormals
    }

    /// A Boolean value that indicates whether the mesh includes vertex colors.
    var hasVertexColors: Bool {
        polygons.hasVertexColors
    }

    /// The unique polygon edges in the mesh.
    /// The direction of each edge is normalized relative to the origin to simplify edge-equality comparisons.
    var uniqueEdges: Set<LineSegment> {
        polygons.uniqueEdges
    }

    /// A Boolean value that indicates whether the mesh is watertight, meaning that every edge is
    /// attached to two polygons (or a multiple of two).
    /// > Note: A value of `true` doesn't guarantee that mesh is not self-intersecting or inside-out.
    var isWatertight: Bool {
        storage.isWatertight
    }

    /// Check if polygons all lie on the same plane (facing either direction).
    var isPlanar: Bool {
        storage.isPlanar
    }

    /// The bounds of the mesh.
    var bounds: Bounds { storage.bounds }

    /// The surface area of the mesh. Does not include polygon back-faces.
    var surfaceArea: Double {
        polygons.surfaceArea
    }

    /// The signed volume of the mesh. A negative value indicates that the mesh is inside-out.
    /// > Note: If the mesh is not watertight (has holes) then this value will not be accurate.
    var signedVolume: Double {
        polygons.signedVolume
    }

    /// Creates a new mesh from an array of polygons.
    /// - Parameter polygons: The polygons making up the mesh.
    init(_ polygons: [Polygon]) {
        self.init(
            unchecked: polygons,
            bounds: nil,
            bsp: nil,
            isConvex: false,
            isWatertight: nil,
            isPlanar: nil,
            submeshes: nil
        )
    }

    /// Creates a composite mesh from an array of submeshes.
    /// - Parameter submeshes: An array of meshes.
    init(submeshes: [Mesh]) {
        self = .merge(submeshes)
    }

    /// Returns a copy of the mesh with the specified old material replaced by a new one.
    /// - Parameters:
    ///     - old: The ``Material`` to be replaced.
    ///     - new: The ``Material`` to use instead.
    /// - Returns: a new ``Mesh`` with the material replaced.
    func replacing(_ old: Material?, with new: Material?) -> Mesh {
        Mesh(
            unchecked: polygons.mapMaterials { $0 == old ? new : $0 },
            bounds: boundsIfSet,
            bsp: nil, // TODO: Can we update this directly?
            isConvex: isKnownConvex,
            isWatertight: watertightIfSet,
            isPlanar: planarIfSet,
            submeshes: submeshesIfEmpty
        )
    }

    /// Returns a copy of the mesh with the new material applied to all polygons.
    func withMaterial(_ material: Material?) -> Mesh {
        Mesh(
            unchecked: polygons.mapMaterials { _ in material },
            bounds: boundsIfSet,
            bsp: nil, // TODO: Can we update this directly?
            isConvex: isKnownConvex,
            isWatertight: watertightIfSet,
            isPlanar: planarIfSet,
            submeshes: submeshesIfEmpty
        )
    }

    /// Returns a copy of the mesh with vertex colors removed.
    func withoutVertexColors() -> Mesh {
        Mesh(
            unchecked: polygons.withoutVertexColors(),
            bounds: boundsIfSet,
            bsp: nil, // TODO: Can we update this directly?
            isConvex: isKnownConvex,
            isWatertight: watertightIfSet,
            isPlanar: planarIfSet,
            submeshes: submeshesIfEmpty
        )
    }

    /// Returns a copy of the mesh with transformed vertex colors.
    func mapVertexColors(_ transform: (Color) -> Color?) -> Mesh {
        Mesh(
            unchecked: polygons.mapVertexColors(transform),
            bounds: boundsIfSet,
            bsp: nil, // TODO: Can we update this directly?
            isConvex: isKnownConvex,
            isWatertight: watertightIfSet,
            isPlanar: planarIfSet,
            submeshes: submeshesIfEmpty
        )
    }

    /// Returns a copy of the mesh with transformed polygons.
    /// This is potentiall cheaper than creating a new mesh from the updated polygons.
    func mapPolygons(_ transform: (Polygon) -> Polygon) -> Mesh {
        let polygons = polygons.map(transform)
        // Check if changes affect shape
        for (old, new) in zip(self.polygons, polygons) {
            for (old, new) in zip(old.vertices, new.vertices) {
                if old.position != new.position {
                    return .init(polygons)
                }
            }
        }
        return Mesh(
            unchecked: polygons,
            bounds: boundsIfSet,
            bsp: nil, // TODO: Can we update this directly?
            isConvex: isKnownConvex,
            isWatertight: watertightIfSet,
            isPlanar: planarIfSet,
            submeshes: submeshesIfEmpty
        )
    }

    /// Merges the polygons from two meshes.
    /// - Parameter mesh: The mesh to merge with this one.
    /// - Returns: A new mesh that includes all polygons from both meshes.
    ///
    /// > Note: No attempt is made to deduplicate or join meshes. Polygons are neither split nor removed.
    func merge(_ mesh: Mesh) -> Mesh {
        var boundsIfSet: Bounds?
        if let ab = self.boundsIfSet, let bb = mesh.boundsIfSet {
            boundsIfSet = ab.union(bb)
        }
        return Mesh(
            unchecked: polygons + mesh.polygons,
            bounds: boundsIfSet,
            bsp: nil, // TODO: Can we merge these directly?
            isConvex: false,
            isWatertight: nil,
            isPlanar: nil,
            submeshes: nil // TODO: can we preserve this?
        )
    }

    /// Creates a new mesh that is the combination of the polygons from all the specified meshes.
    /// - Parameter meshes: The meshes to merge.
    /// - Returns: A new mesh that includes all polygons from all meshes.
    ///
    /// > Note: No attempt is made to deduplicate or join meshes. Polygons are neither split nor removed.
    static func merge(_ meshes: some Collection<Mesh>) -> Mesh {
        if meshes.count <= 1 {
            return meshes.first ?? .empty
        }
        var allBoundsSet = true
        var polygons = [Polygon]()
        polygons.reserveCapacity(meshes.reduce(0) { $0 + $1.polygons.count })
        for mesh in meshes {
            allBoundsSet = allBoundsSet && mesh.boundsIfSet != nil
            polygons += mesh.polygons
        }
        return Mesh(
            unchecked: polygons,
            bounds: allBoundsSet ? Bounds(meshes) : nil,
            bsp: nil, // TODO: Can we merge these directly?
            isConvex: false,
            isWatertight: nil,
            isPlanar: nil,
            submeshes: nil // TODO: can we preserve this?
        )
    }

    /// Flips the face direction and vertex normals of all polygons within the mesh.
    /// - Returns: The inverted mesh.
    func inverted() -> Mesh {
        Mesh(
            unchecked: polygons.inverted(),
            bounds: boundsIfSet,
            bsp: nil, // TODO: Can we invert this directly?
            isConvex: false,
            isWatertight: watertightIfSet,
            isPlanar: planarIfSet,
            submeshes: submeshesIfEmpty
        )
    }

    /// Splits all polygons in the mesh that are concave or have more than the specified number of
    /// sides into two or more convex polygons.
    /// - Parameter maxSides: The maximum number of sides each polygon may have.
    /// - Returns: A new mesh containing the convex polygons.
    func tessellate(maxSides: Int = .max) -> Mesh {
        Mesh(
            unchecked: polygons.tessellate(maxSides: maxSides),
            bounds: boundsIfSet,
            bsp: nil, // TODO: would it be safe to preserve this?
            isConvex: isKnownConvex,
            isWatertight: watertightIfSet,
            isPlanar: planarIfSet,
            submeshes: submeshesIfEmpty
        )
    }

    /// Splits all polygons in the mesh into triangles.
    /// - Returns: A new mesh containing the triangles.
    func triangulate() -> Mesh {
        Mesh(
            unchecked: polygons.triangulate(),
            bounds: boundsIfSet,
            bsp: nil, // TODO: would it be safe to preserve this?
            isConvex: isKnownConvex,
            isWatertight: watertightIfSet,
            isPlanar: planarIfSet,
            submeshes: submeshesIfEmpty
        )
    }

    /// Merges any coplanar polygons that share one or more edges. Resultant polygons may be non-convex.
    /// - Parameter isCancelled: Callback used to cancel the operation.
    /// - Returns: A new mesh containing the merged (possibly non-convex) polygons.
    ///
    /// > Note: This method can be very time-consuming. For convex polygons use `triangulate()` instead.
    func detessellate(isCancelled: CancellationHandler = { false }) -> Mesh {
        let polygons = polygons.detessellate(
            ensureConvex: false,
            useQualityMerge: isWatertight,
            allowDisjointSharedVertices: isPlanar,
            // A vertex that is redundant within one coplanar face can still be needed by
            // adjacent non-coplanar faces to preserve matching edge segmentation.
            preserveRedundantVertices: watertightIfSet == true && !isPlanar,
            isCancelled: isCancelled
        )
        return Mesh(
            unchecked: polygons,
            bounds: boundsIfSet,
            bsp: nil, // TODO: would it be safe to preserve this?
            isConvex: isKnownConvex,
            isWatertight: watertightIfSet,
            isPlanar: planarIfSet,
            submeshes: submeshesIfEmpty
        )
    }

    /// Merges coplanar polygons that share one or more edges, provided the result will be convex.
    /// - Returns: A new mesh containing the merged polygons.
    func detriangulate() -> Mesh {
        Mesh(
            unchecked: polygons.detessellate(ensureConvex: true) { false },
            bounds: boundsIfSet,
            bsp: nil, // TODO: would it be safe to preserve this?
            isConvex: isKnownConvex,
            isWatertight: watertightIfSet,
            isPlanar: planarIfSet,
            submeshes: submeshesIfEmpty
        )
    }

    /// Removes holes by inserting additional vertices and capping closed boundary loops.
    /// - Parameter isCancelled: Callback used to cancel the operation.
    /// - Returns: A new mesh with new vertices and polygons inserted if needed.
    ///
    /// > Note: This method is not always successful. Check ``Mesh/isWatertight`` after to verify.
    func makeWatertight(isCancelled: CancellationHandler = { false }) -> Mesh {
        guard !isCancelled() else { return .empty }
        if watertightIfSet == true {
            guard !polygons.areConsistentlyWound else {
                return self
            }
            return Mesh(
                unchecked: polygons.withConsistentWinding(isCancelled: isCancelled),
                bounds: boundsIfSet,
                bsp: nil,
                isConvex: isKnownConvex,
                isWatertight: true,
                isPlanar: planarIfSet,
                submeshes: submeshesIfEmpty
            )
        }
        var holeEdges = polygons.holeEdges(isCancelled: isCancelled), polygons = polygons
        var precision = epsilon
        while !holeEdges.isEmpty, !isCancelled() {
            let merged = polygons
                .insertingEdgeVertices(with: holeEdges, isCancelled: isCancelled)
                .mergingVertices(withPrecision: precision, isCancelled: isCancelled)
            let newEdges = merged.holeEdges(isCancelled: isCancelled)
            if newEdges.count < holeEdges.count {
                polygons = merged
                holeEdges = newEdges
                precision *= 10
                continue
            }
            // No improvement
            break
        }
        if !holeEdges.isEmpty {
            func capMaterial(for path: Path, in polygons: [Polygon]) -> Material? {
                capMaterial(for: path.undirectedEdges, in: polygons)
            }

            func capMaterial(for pathEdges: some Collection<LineSegment>, in polygons: [Polygon]) -> Material? {
                var weights = [(material: Material?, length: Double)]()
                for (index, polygon) in polygons.enumerated() {
                    if index.isMultiple(of: cancellationCheckInterval), isCancelled() {
                        return nil
                    }
                    for edge in polygon.undirectedEdges where pathEdges.contains(edge) {
                        if let index = weights.firstIndex(where: { $0.material == polygon.material }) {
                            weights[index].length += edge.length
                        } else {
                            weights.append((polygon.material, edge.length))
                        }
                    }
                }
                return weights.max(by: { $0.length < $1.length })?.material
            }

            func capPolygons(for path: Path, material: Material?) -> [Polygon] {
                if path.isClosed {
                    let vertices = path.points.dropLast().map(Vertex.init)
                    if vertices.count == 3, let polygon = Polygon(vertices, material: material) {
                        return [polygon]
                    }
                }
                let polygons = path.closed().facePolygons(material: material)
                if !polygons.isEmpty {
                    return polygons
                }
                guard path.isClosed else {
                    return []
                }
                let vertices = path.points.dropLast().map(Vertex.init)
                guard vertices.count > 2 else {
                    return []
                }
                let center = Vertex(vertices.centroid)
                return vertices.indices.compactMap { i in
                    if i.isMultiple(of: cancellationCheckInterval), isCancelled() {
                        return nil
                    }
                    let j = (i + 1) % vertices.count
                    guard vertices[i].position != vertices[j].position else {
                        return nil
                    }
                    return Polygon(
                        unchecked: [center, vertices[i], vertices[j]],
                        plane: nil,
                        isConvex: true,
                        sanitizeNormals: true,
                        material: material
                    )
                }
            }
            while !holeEdges.isEmpty, !isCancelled() {
                let loops = holeEdges.closedLoops
                let caps = loops.enumerated().flatMap { index, points -> [Polygon] in
                    if index.isMultiple(of: cancellationCheckInterval), isCancelled() {
                        return []
                    }
                    let material = capMaterial(for: points.undirectedEdges, in: polygons)
                    let closedVertices = points.map { position in
                        let vertices = polygons.flatMap { polygon in
                            polygon.vertices.compactMap {
                                $0.position == position ? $0 : nil
                            }
                        }
                        if let vertex = vertices.first(where: { $0.color != .white }) {
                            return vertex
                        }
                        return vertices.first ?? Vertex(position)
                    }
                    let vertices = Array(closedVertices.dropLast())
                    if vertices.count == 3, let polygon = Polygon(vertices, material: material) {
                        return [polygon.flatteningNormals()]
                    }
                    guard vertices.count > 3 else {
                        return []
                    }
                    let path = Path(closedVertices.map {
                        .point($0.position, color: $0.color == .white ? nil : $0.color)
                    })
                    return capPolygons(for: path, material: material).flatteningNormals()
                }
                guard !caps.isEmpty else {
                    break
                }
                let capped = (polygons + caps)
                    .insertingEdgeVertices(with: holeEdges, isCancelled: isCancelled)
                    .mergingVertices(withPrecision: epsilon, isCancelled: isCancelled)
                let newEdges = capped.holeEdges(isCancelled: isCancelled)
                guard newEdges.count < holeEdges.count else {
                    break
                }
                polygons = capped
                holeEdges = newEdges
            }
        }
        let isWatertight = holeEdges.isEmpty
        return Mesh(
            unchecked: isWatertight && !isCancelled() ?
                polygons.withConsistentWinding(isCancelled: isCancelled) : polygons,
            bounds: boundsIfSet,
            bsp: nil,
            isConvex: false, // TODO: can makeWatertight make this false?
            isWatertight: isWatertight,
            isPlanar: planarIfSet,
            submeshes: submeshesIfEmpty
        )
    }

    /// Returns a copy of the mesh with winding made consistent across shared edges.
    ///
    /// For closed, non-planar submeshes, the result is also oriented so that the signed volume is positive.
    /// Open or planar surfaces will have locally consistent winding, but their absolute orientation is ambiguous.
    /// - Parameter isCancelled: Callback used to cancel the operation.
    /// - Returns: A new mesh with consistently wound polygons.
    func withConsistentWinding(isCancelled: CancellationHandler = { false }) -> Mesh {
        guard !isCancelled() else { return .empty }
        let groups = polygons.groupedSubmeshIndices
        var result = polygons
        for (index, indices) in groups.enumerated() {
            if index.isMultiple(of: cancellationCheckInterval), isCancelled() {
                return self
            }
            let group = indices.map { polygons[$0] }
            var repaired = group.withConsistentWinding(isCancelled: isCancelled)
            if repaired.areWatertight, !repaired.arePlanar, repaired.signedVolume < 0 {
                repaired = repaired.inverted()
            }
            for (index, polygon) in zip(indices, repaired) {
                result[index] = polygon
            }
        }
        return Mesh(
            unchecked: result,
            bounds: boundsIfSet,
            bsp: nil,
            isConvex: isKnownConvex && groups.count <= 1,
            isWatertight: watertightIfSet,
            isPlanar: planarIfSet,
            submeshes: nil
        )
    }

    /// Flatten vertex normals (set them to match the face normals of each polygon).
    func flatteningNormals() -> Mesh {
        Mesh(
            unchecked: polygons.flatteningNormals(),
            bounds: boundsIfSet,
            bsp: nil, // TODO: would it be safe to preserve this?
            isConvex: isKnownConvex,
            isWatertight: watertightIfSet,
            isPlanar: planarIfSet,
            submeshes: submeshesIfEmpty
        )
    }

    /// Smooth vertex normals for corners with angles greater (more obtuse) than the specified threshold.
    /// - Parameter threshold: The minimum corner angle that should appear smooth.
    ///   Values should be in the range zero (no smoothing) to pi (smooth all edges).
    func smoothingNormals(forAnglesGreaterThan threshold: Angle) -> Mesh {
        Mesh(
            unchecked: polygons.smoothingNormals(forAnglesGreaterThan: threshold),
            bounds: boundsIfSet,
            bsp: nil, // TODO: would it be safe to preserve this?
            isConvex: isKnownConvex,
            isWatertight: watertightIfSet,
            isPlanar: planarIfSet,
            submeshes: submeshesIfEmpty
        )
    }

    /// Subdivides triangles and quads, leaving other polygons unchanged.
    func subdivide() -> Mesh {
        Mesh(
            unchecked: polygons.subdivide(),
            bounds: boundsIfSet,
            bsp: nil, // TODO: would it be safe to preserve this?
            isConvex: isKnownConvex,
            isWatertight: watertightIfSet,
            isPlanar: planarIfSet,
            submeshes: submeshesIfEmpty
        )
    }
}

extension Mesh {
    init(
        unchecked polygons: [Polygon],
        bounds: Bounds?,
        bsp: BSP?,
        isConvex: Bool,
        isWatertight: Bool?,
        isPlanar: Bool?,
        submeshes: [Mesh]?
    ) {
        self.storage = polygons.isEmpty ? .empty : Storage(
            polygons: polygons,
            bounds: bounds,
            bsp: bsp,
            isKnownConvex: isConvex,
            isWatertight: isWatertight,
            isPlanar: isPlanar,
            submeshes: submeshes
        )
    }

    func bsp(isCancelled: CancellationHandler = { false }) -> BSP {
        storage.bsp(isCancelled: isCancelled)
    }

    func isConvex(isCancelled: CancellationHandler = { false }) -> Bool {
        storage.isConvex(isCancelled: isCancelled)
    }

    /// Checks whether all polygon windings are consistent across shared edges.
    var isConsistentlyWound: Bool {
        assert(polygons.areWatertight) // always returns false otherwise
        return polygons.areConsistentlyWound
    }

    var vertexNormalsFaceOutward: Bool {
        polygons.allSatisfy { polygon in
            polygon.vertices.allSatisfy {
                $0.normal.dot(polygon.plane.normal) > 0
            }
        }
    }

    var boundsIfSet: Bounds? { storage.boundsIfSet }
    var bspIfSet: BSP? { storage.bspIfSet }
    var watertightIfSet: Bool? { storage.watertightIfSet }
    var planarIfSet: Bool? { storage.planarIfSet }
    /// > Note: a mesh can be convex without being watertight
    var isKnownConvex: Bool { storage.isKnownConvex }
    /// > Note: we don't expose submeshesIfSet because it's unsafe to reuse
    var submeshesIfEmpty: [Mesh]? {
        storage.submeshesIfSet.flatMap { $0.isEmpty ? [] : nil }
    }
}

private extension Mesh {
    final class Storage: Hashable, Bounded, @unchecked Sendable {
        let polygons: [Polygon]
        private let bspLock = NSLock()
        private let watertightLock = NSLock()
        private let planarLock = NSLock()
        private let submeshesLock = NSLock()

        static let empty = Storage(
            polygons: [],
            bounds: .empty,
            bsp: nil,
            isKnownConvex: true,
            isWatertight: true,
            isPlanar: true,
            submeshes: []
        )

        private(set) var materialsIfSet: [Material?]?
        var materials: [Material?] {
            if materialsIfSet == nil {
                var materials = [Material?]()
                for polygon in polygons {
                    let material = polygon.material
                    if !materials.contains(material) {
                        materials.append(material)
                    }
                }
                materialsIfSet = materials
            }
            return materialsIfSet!
        }

        private(set) var boundsIfSet: Bounds?
        var bounds: Bounds {
            if boundsIfSet == nil {
                boundsIfSet = Bounds(polygons)
            }
            return boundsIfSet!
        }

        private(set) var isKnownConvex: Bool
        func isConvex(isCancelled: CancellationHandler = { false }) -> Bool {
            if !isKnownConvex, bspIfSet == nil {
                _ = bsp(isCancelled: isCancelled)
            }
            return isKnownConvex
        }

        private(set) var bspIfSet: BSP?
        func bsp(isCancelled: CancellationHandler = { false }) -> BSP {
            bspLock.lock()
            if bspIfSet == nil {
                let bsp = BSP(unchecked: polygons, isKnownConvex: isKnownConvex, isCancelled)
                if isCancelled() { return bsp }
                bspIfSet = bsp
                isKnownConvex = bsp.isConvex
            }
            bspLock.unlock()
            return bspIfSet!
        }

        private(set) var watertightIfSet: Bool?
        var isWatertight: Bool {
            watertightLock.lock()
            if watertightIfSet == nil {
                watertightIfSet = polygons.areWatertight
            }
            watertightLock.unlock()
            return watertightIfSet!
        }

        private(set) var planarIfSet: Bool?
        var isPlanar: Bool {
            planarLock.lock()
            if planarIfSet == nil {
                planarIfSet = polygons.arePlanar
            }
            planarLock.unlock()
            return planarIfSet!
        }

        private(set) var submeshesIfSet: [Mesh]?
        var submeshes: [Mesh] {
            submeshesLock.lock()
            if submeshesIfSet == nil {
                let groups = isKnownConvex ? [] : polygons.groupedBySubmesh()
                submeshesIfSet = groups.count <= 1 ? [] : groups.map(Mesh.init)
            }
            submeshesLock.unlock()
            return submeshesIfSet.map {
                $0.isEmpty ? [Mesh(storage: self)] : $0
            } ?? []
        }

        static func == (lhs: Storage, rhs: Storage) -> Bool {
            lhs === rhs || lhs.polygons == rhs.polygons
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(polygons)
        }

        init(
            polygons: [Polygon],
            bounds: Bounds?,
            bsp: BSP?,
            isKnownConvex: Bool,
            isWatertight: Bool?,
            isPlanar: Bool?,
            submeshes: [Mesh]?
        ) {
            assert(isWatertight == nil || isWatertight == polygons.areWatertight)
            assert(!isKnownConvex || polygons.groupedBySubmesh().count <= 1)
            let submeshes: [Mesh]? = submeshes.map { submeshes -> [Mesh] in
                guard submeshes.count > 1 else {
                    return []
                }
                return submeshes.flatMap { mesh -> [Mesh] in
                    switch mesh.submeshes.count {
                    case 0, 1: return [mesh]
                    default: return mesh.submeshes
                    }
                }
            }
            assert(!isKnownConvex || submeshes?.count ?? 0 <= 1)
            assert(bsp?.isConvex ?? isKnownConvex == isKnownConvex)
            self.polygons = polygons
            self.boundsIfSet = polygons.isEmpty ? .empty : bounds
            self.bspIfSet = bsp
            self.isKnownConvex = polygons.isEmpty || bsp?.isConvex ?? isKnownConvex
            self.watertightIfSet = polygons.isEmpty ? true : isWatertight
            self.planarIfSet = polygons.isEmpty ? true : isPlanar
            self.submeshesIfSet = submeshes ?? (isKnownConvex ? [] : nil)
        }
    }
}

private extension [Polygon] {
    /// Group by touching vertices, returning polygon indices in original order.
    var groupedSubmeshIndices: [[Int]] {
        var submeshes = [[Int]]()
        var points = [Set<Vector>]()
        for (index, poly) in enumerated() {
            let positions = Set(poly.vertices.map(\.position))
            var lastMatch: Int?
            for i in points.indices.reversed() {
                if !points[i].isDisjoint(with: positions) {
                    if !submeshes[i].contains(index) {
                        submeshes[i].append(index)
                    }
                    points[i].formUnion(positions)
                    if let j = lastMatch {
                        for index in submeshes.remove(at: j) where !submeshes[i].contains(index) {
                            submeshes[i].append(index)
                        }
                        points[i].formUnion(points.remove(at: j))
                    }
                    lastMatch = i
                }
            }
            if lastMatch == nil {
                submeshes.append([index])
                points.append(positions)
            }
        }
        return submeshes.map { $0.sorted() }
    }
}

private extension Set<LineSegment> {
    var closedLoops: [[Vector]] {
        var edges = sorted()
        var loops = [[Vector]]()
        while !edges.isEmpty {
            let first = edges.removeFirst()
            var points = [first.start, first.end]
            while points.last != points.first {
                guard let last = points.last,
                      let index = edges.firstIndex(where: {
                          $0.start == last || $0.end == last
                      })
                else {
                    break
                }
                let edge = edges.remove(at: index)
                points.append(edge.start == last ? edge.end : edge.start)
            }
            guard points.count > 3, points.last == points.first else {
                continue
            }
            loops.append(points)
        }
        return loops
    }
}

private extension Collection<Vector> {
    var undirectedEdges: [LineSegment] {
        let points = Array(self)
        guard points.count > 1 else {
            return []
        }
        let endIndex = points.last == points.first ? points.index(before: points.endIndex) : points.endIndex
        return points[..<endIndex].indices.compactMap { i in
            let j = i == points.index(before: points.endIndex) ? points.startIndex : points.index(after: i)
            guard points[i] != points[j] else {
                return nil
            }
            return LineSegment(uncheckedUndirected: points[i], points[j])
        }
    }
}
