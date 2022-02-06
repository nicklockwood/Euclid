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

/// A 3D surface made up of multiple polygons.
///
/// A mesh surface can be convex or concave, and can have zero volume (for example, a flat shape such as a square) but shouldn't contain holes or exposed back-faces.
/// The result of constructive solid geometry operations on meshes that have holes or exposed back-faces is undefined.
public struct Mesh: Hashable {
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
                    polygons.map { $0.with(material: material.value) }
                }
            } else {
                polygons = try container.decode([Polygon].self, forKey: .polygons)
            }
            self.init(
                unchecked: polygons,
                bounds: boundsIfSet,
                isConvex: isConvex,
                isWatertight: nil
            )
        } else {
            let polygons = try [Polygon](from: decoder)
            self.init(polygons)
        }
    }

    /// Encodes this mesh into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(bounds, forKey: .bounds)
        try isConvex ? container.encode(true, forKey: .isConvex) : ()
        if materials == [nil] {
            try container.encode(polygons, forKey: .polygons)
        } else {
            try container.encode(materials.map { CodableMaterial($0) }, forKey: .materials)
            let polygonsByMaterial = self.polygonsByMaterial
            try container.encode(materials.map { material -> [Polygon] in
                polygonsByMaterial[material]!.map { $0.with(material: nil) }
            }, forKey: .polygons)
        }
    }
}

public extension Mesh {
    /// The type used as a material for a given polygon.
    typealias Material = Polygon.Material

    /// The collection of materials used for the mash.
    var materials: [Material?] { storage.materials }
    /// The collection of polygons that make up the mesh.
    var polygons: [Polygon] { storage.polygons }
    /// The bounds of the mesh.
    var bounds: Bounds { storage.bounds }

    /// The polygons of the mesh, grouped by material.
    var polygonsByMaterial: [Material?: [Polygon]] {
        polygons.groupedByMaterial()
    }

    /// A Boolean value that indicates whether the mesh includes texture coordinates.
    var hasTexcoords: Bool {
        polygons.hasTexcoords
    }

    /// A Boolean value that indicates whether the mesh includes vertex colors.
    var hasVertexColors: Bool {
        polygons.hasVertexColors
    }

    /// The unique polygon edges in the mesh.
    var uniqueEdges: Set<LineSegment> {
        polygons.uniqueEdges
    }

    /// A Boolean value that indicates whether the mesh is watertight.
    ///
    /// For example, the value is `true` if every edge is attached to at least 2 polygons.
    /// > Note: A mesh being watertight doesn't verify that mesh is not self-intersecting or inside-out.
    var isWatertight: Bool {
        storage.isWatertight
    }

    /// Creates a new mesh from an array of polygons.
    init(_ polygons: [Polygon]) {
        self.init(
            unchecked: polygons,
            bounds: nil,
            isConvex: false,
            isWatertight: nil
        )
    }

    /// Replaces a material with another that you provide.
    func replacing(_ old: Material?, with new: Material?) -> Mesh {
        Mesh(
            unchecked: polygons.map {
                $0.material == old ? $0.with(material: new) : $0
            },
            bounds: boundsIfSet,
            isConvex: isConvex,
            isWatertight: watertightIfSet
        )
    }

    /// Returns a new mesh that includes all polygons from both this mesh and the mesh you provide.
    ///
    /// Polygons are neither split nor removed.
    func merge(_ mesh: Mesh) -> Mesh {
        var boundsIfSet: Bounds?
        if let ab = self.boundsIfSet, let bb = mesh.boundsIfSet {
            boundsIfSet = ab.union(bb)
        }
        return Mesh(
            unchecked: polygons + mesh.polygons,
            bounds: boundsIfSet,
            isConvex: false,
            isWatertight: watertightIfSet
        )
    }

    /// Creates a new mesh that is the combination of the provided meshes.
    static func merge(_ meshes: [Mesh]) -> Mesh {
        if meshes.count == 1 {
            return meshes[0]
        }
        var allBoundsSet = true
        var polygons = [Polygon]()
        polygons.reserveCapacity(meshes.reduce(0) { $0 + $1.polygons.count })
        for mesh in meshes {
            allBoundsSet = allBoundsSet && mesh.boundsIfSet != nil
            polygons += mesh.polygons
        }
        var boundsIfSet: Bounds?
        if allBoundsSet {
            boundsIfSet = meshes.reduce(into: Bounds.empty) {
                $0.formUnion($1.bounds)
            }
        }
        return Mesh(
            unchecked: polygons,
            bounds: boundsIfSet,
            isConvex: false,
            isWatertight: nil
        )
    }

    /// Split mesh along a plane.
    ///
    /// If the plane doesn't intersect the mesh, one of the returning meshes will be `nil`.
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
                    isWatertight: nil
                ),
                Mesh(
                    unchecked: back,
                    bounds: nil,
                    isConvex: false,
                    isWatertight: nil
                )
            )
        }
    }

    /// Returns a set of edges where the mesh intersects the plane.
    func edges(intersecting plane: Plane) -> Set<LineSegment> {
        var edges = Set<LineSegment>()
        for polygon in polygons {
            polygon.intersect(with: plane, edges: &edges)
        }
        return edges
    }

    /// Flips face direction of polygons within the mesh.
    func inverted() -> Mesh {
        Mesh(
            unchecked: polygons.inverted(),
            bounds: boundsIfSet,
            isConvex: false,
            isWatertight: watertightIfSet
        )
    }

    /// Splits concave polygons into 2 or more convex polygons.
    func tessellate() -> Mesh {
        Mesh(
            unchecked: polygons.tessellate(),
            bounds: boundsIfSet,
            isConvex: isConvex,
            isWatertight: nil // TODO: fix triangulate() then see if this is fixed
        )
    }

    /// Tessellates the meshes polygons into triangles.
    func triangulate() -> Mesh {
        Mesh(
            unchecked: polygons.triangulate(),
            bounds: boundsIfSet,
            isConvex: isConvex,
            isWatertight: nil // TODO: work out why this sometimes introduces holes
        )
    }

    /// Merges coplanar polygons that share one or more edges.
    func detessellate() -> Mesh {
        Mesh(
            unchecked: polygons.sortedByPlane().detessellate(),
            bounds: boundsIfSet,
            isConvex: isConvex,
            isWatertight: nil // TODO: can this be done without introducing holes?
        )
    }

    /// Removes hairline cracks by inserting additional vertices without altering the shape.
    ///
    /// > Note: This method is not always be successful in making a mesh watertight. Check ``Mesh/isWatertight`` afterwards to verify.
    func makeWatertight() -> Mesh {
        isWatertight ? self : Mesh(
            unchecked: polygons.makeWatertight(),
            bounds: boundsIfSet,
            isConvex: isConvex,
            isWatertight: nil
        )
    }
}

internal extension Mesh {
    init(
        unchecked polygons: [Polygon],
        bounds: Bounds?,
        isConvex: Bool,
        isWatertight: Bool?
    ) {
        self.storage = polygons.isEmpty ? .empty : Storage(
            polygons: polygons,
            bounds: bounds,
            isConvex: isConvex,
            isWatertight: isWatertight
        )
    }

    var boundsIfSet: Bounds? { storage.boundsIfSet }
    var watertightIfSet: Bool? { storage.watertightIfSet }
    var isConvex: Bool { storage.isConvex }
}

private extension Mesh {
    final class Storage: Hashable {
        let polygons: [Polygon]
        let isConvex: Bool

        static let empty = Storage(
            polygons: [],
            bounds: .empty,
            isConvex: true,
            isWatertight: true
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
                boundsIfSet = Bounds(polygons: polygons)
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
            isWatertight: Bool?
        ) {
            assert(isWatertight == nil || isWatertight == polygons.areWatertight)
            self.polygons = polygons
            self.boundsIfSet = polygons.isEmpty ? .empty : bounds
            self.isConvex = isConvex || polygons.isEmpty
            self.watertightIfSet = polygons.isEmpty ? true : isWatertight
        }
    }
}
