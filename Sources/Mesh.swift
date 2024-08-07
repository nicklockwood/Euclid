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

/// A 3D surface made of polygons.
///
/// A mesh surface can be convex or concave, and can have zero volume (for example, a flat shape such as a square)
/// but shouldn't contain holes or exposed back-faces.
///
/// The result of CSG operations on meshes that have holes or exposed back-faces is undefined.
public struct Mesh: Hashable, Sendable {
    private let storage: Storage
}

extension Mesh: Codable {
    private enum CodingKeys: String, CodingKey {
        case polygons, bounds, isConvex = "convex", materials
    }

    /// Creates a new mesh by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            let boundsIfSet = try container.decodeIfPresent(Bounds.self, forKey: .bounds)
            let isConvex = try container.decodeIfPresent(Bool.self, forKey: .isConvex) ?? false
            let polygons: [Polygon]
            if let materials = try container.decodeIfPresent([CodableMaterial].self, forKey: .materials) {
                let polygonsByMaterial = try container.decode([[Polygon]].self, forKey: .polygons)
                polygons = zip(materials, polygonsByMaterial).flatMap { material, polygons in
                    polygons.mapMaterials { _ in material.value }
                }
            } else {
                polygons = try container.decode([Polygon].self, forKey: .polygons)
            }
            self.init(
                unchecked: polygons,
                bounds: boundsIfSet,
                isConvex: isConvex,
                isWatertight: nil,
                submeshes: nil
            )
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
        try container.encode(bounds, forKey: .bounds)
        try isKnownConvex ? container.encode(true, forKey: .isConvex) : ()
        if materials == [nil] {
            try container.encode(polygons, forKey: .polygons)
        } else {
            try container.encode(materials.map { CodableMaterial($0) }, forKey: .materials)
            let polygonsByMaterial = self.polygonsByMaterial
            try container.encode(materials.map { material -> [Polygon] in
                polygonsByMaterial[material]!.mapMaterials { _ in nil }
            }, forKey: .polygons)
        }
    }
}

extension Mesh: Bounded {
    /// The bounds of the mesh.
    public var bounds: Bounds { storage.bounds }
}

public extension Mesh {
    /// Material used by the mesh polygons.
    /// See ``Polygon/Material-swift.typealias`` for details.
    typealias Material = Polygon.Material

    /// An empty mesh.
    static let empty: Mesh = .init([])

    /// All materials used by the mesh.
    /// The array may contain `nil` if some or all of the mesh uses the default material.
    var materials: [Material?] { storage.materials }

    /// The polygons that make up the mesh.
    var polygons: [Polygon] { storage.polygons }

    /// The distinct (disconnected) submeshes that make up the mesh.
    var submeshes: [Mesh] { storage.submeshes }

    /// The polygons in the mesh, grouped by material.
    var polygonsByMaterial: [Material?: [Polygon]] {
        polygons.groupedByMaterial()
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
    ///
    /// > Note: A value of `true` doesn't guarantee that mesh is not self-intersecting or inside-out.
    var isWatertight: Bool {
        storage.isWatertight
    }

    /// Creates a new mesh from an array of polygons.
    /// - Parameter polygons: The polygons making up the mesh.
    init(_ polygons: [Polygon]) {
        self.init(
            unchecked: polygons,
            bounds: nil,
            isConvex: false,
            isWatertight: nil,
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
            isConvex: isKnownConvex,
            isWatertight: watertightIfSet,
            submeshes: submeshesIfEmpty
        )
    }

    /// Returns a copy of the mesh with the new material applied to all polygons.
    func withMaterial(_ material: Material?) -> Mesh {
        Mesh(
            unchecked: polygons.mapMaterials { _ in material },
            bounds: boundsIfSet,
            isConvex: isKnownConvex,
            isWatertight: watertightIfSet,
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
            isConvex: false,
            isWatertight: nil,
            submeshes: nil // TODO: can we preserve this?
        )
    }

    /// Creates a new mesh that is the combination of the polygons from all the specified meshes.
    /// - Parameter meshes: The meshes to merge.
    /// - Returns: A new mesh that includes all polygons from all meshes.
    ///
    /// > Note: No attempt is made to deduplicate or join meshes. Polygons are neither split nor removed.
    static func merge<T: Collection>(_ meshes: T) -> Mesh where T.Element == Mesh {
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
            isConvex: false,
            isWatertight: nil,
            submeshes: nil // TODO: can we preserve this?
        )
    }

    /// Flips the face direction and vertex normals of all polygons within the mesh.
    /// - Returns: The inverted mesh.
    func inverted() -> Mesh {
        Mesh(
            unchecked: polygons.inverted(),
            bounds: boundsIfSet,
            isConvex: false,
            isWatertight: watertightIfSet,
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
            isConvex: isKnownConvex,
            isWatertight: nil, // TODO: fix triangulate() then see if this is fixed
            submeshes: submeshesIfEmpty
        )
    }

    /// Splits all polygons in the mesh into triangles.
    /// - Returns: A new mesh containing the triangles.
    func triangulate() -> Mesh {
        Mesh(
            unchecked: polygons.triangulate(),
            bounds: boundsIfSet,
            isConvex: isKnownConvex,
            isWatertight: watertightIfSet,
            submeshes: submeshesIfEmpty
        )
    }

    /// Merges any coplanar polygons that share one or more edges.
    /// - Returns: A new mesh containing the merged (possibly non-convex) polygons.
    func detessellate() -> Mesh {
        Mesh(
            unchecked: polygons.sortedByPlane().detessellate(),
            bounds: boundsIfSet,
            isConvex: isKnownConvex,
            isWatertight: nil, // TODO: can this be done without introducing holes?
            submeshes: submeshesIfEmpty
        )
    }

    /// Merges coplanar polygons that share one or more edges, provided the result will be convex.
    /// - Returns: A new mesh containing the merged polygons.
    func detriangulate() -> Mesh {
        Mesh(
            unchecked: polygons.sortedByPlane().detessellate(ensureConvex: true),
            bounds: boundsIfSet,
            isConvex: isKnownConvex,
            isWatertight: nil, // TODO: can this be done without introducing holes?
            submeshes: submeshesIfEmpty
        )
    }

    /// Removes hairline cracks by inserting additional vertices without altering the shape.
    /// - Returns: A new mesh with new vertices inserted if needed.
    ///
    /// > Note: This method is not always successful. Check ``Mesh/isWatertight`` after to verify.
    func makeWatertight() -> Mesh {
        if watertightIfSet == true {
            return self
        }
        var holeEdges = polygons.holeEdges
        return Mesh(
            unchecked: polygons.makeWatertight(with: &holeEdges),
            bounds: boundsIfSet,
            isConvex: false, // TODO: can makeWatertight make this false?
            isWatertight: holeEdges.isEmpty,
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
            isConvex: isKnownConvex,
            isWatertight: watertightIfSet,
            submeshes: submeshesIfEmpty
        )
    }

    /// Deprecated.
    @available(*, deprecated, renamed: "smoothingNormals(forAnglesGreaterThan:)")
    func smoothNormals(_ threshold: Angle) -> Mesh {
        smoothingNormals(forAnglesGreaterThan: threshold)
    }

    /// Subdivides triangles and quads, leaving other polygons unchanged.
    func subdivide() -> Mesh {
        Mesh(
            unchecked: polygons.subdivide(),
            bounds: boundsIfSet,
            isConvex: isKnownConvex,
            isWatertight: watertightIfSet,
            submeshes: submeshesIfEmpty
        )
    }

    /// Returns a Boolean value that indicates if the specified point is inside the mesh.
    /// - Parameter point: The point to compare.
    /// - Returns: `true` if the point lies inside the mesh, and `false` otherwise.
    func containsPoint(_ point: Vector) -> Bool {
        if !bounds.containsPoint(point) {
            return false
        }
        guard isKnownConvex else {
            return BSP(self) { false }.containsPoint(point)
        }
        for polygon in polygons {
            switch point.compare(with: polygon.plane) {
            case .coplanar, .spanning:
                return polygon.containsPoint(point)
            case .front:
                return false
            case .back:
                break
            }
        }
        return true
    }
}

extension Mesh {
    init(
        unchecked polygons: [Polygon],
        bounds: Bounds?,
        isConvex: Bool,
        isWatertight: Bool?,
        submeshes: [Mesh]?
    ) {
        self.storage = polygons.isEmpty ? .empty : Storage(
            polygons: polygons,
            bounds: bounds,
            isConvex: isConvex,
            isWatertight: isWatertight,
            submeshes: submeshes
        )
    }

    var boundsIfSet: Bounds? { storage.boundsIfSet }
    var watertightIfSet: Bool? { storage.watertightIfSet }
    var isKnownConvex: Bool { storage.isConvex }
    /// Note: we don't expose submeshesIfSet because it's unsafe to reuse
    var submeshesIfEmpty: [Mesh]? {
        storage.submeshesIfSet.flatMap { $0.isEmpty ? [] : nil }
    }
}

private extension Mesh {
    final class Storage: Hashable, Bounded {
        let polygons: [Polygon]
        let isConvex: Bool

        static let empty = Storage(
            polygons: [],
            bounds: .empty,
            isConvex: true,
            isWatertight: true,
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

        private(set) var watertightIfSet: Bool?
        var isWatertight: Bool {
            if watertightIfSet == nil {
                watertightIfSet = polygons.areWatertight
            }
            return watertightIfSet!
        }

        private(set) var submeshesIfSet: [Mesh]?
        var submeshes: [Mesh] {
            if submeshesIfSet == nil {
                let groups = isConvex ? [] : polygons.groupedBySubmesh()
                submeshesIfSet = groups.count <= 1 ? [] : groups.map(Mesh.init)
            }
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
            isConvex: Bool,
            isWatertight: Bool?,
            submeshes: [Mesh]?
        ) {
            assert(isWatertight == nil || isWatertight == polygons.areWatertight)
            assert(!isConvex || polygons.groupedBySubmesh().count <= 1)
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
            assert(!isConvex || submeshes?.count ?? 0 <= 1)
            self.polygons = polygons
            self.boundsIfSet = polygons.isEmpty ? .empty : bounds
            self.isConvex = isConvex || polygons.isEmpty
            self.watertightIfSet = polygons.isEmpty ? true : isWatertight
            self.submeshesIfSet = submeshes ?? (isConvex ? [] : nil)
        }
    }
}

#if !swift(<5.7)
extension Mesh.Storage: @unchecked Sendable {}
#endif
