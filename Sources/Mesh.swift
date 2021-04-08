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

/// A 3D surface constructed from polygons
public struct Mesh: Hashable {
    private let storage: Storage
}

extension Mesh: Codable {
    private enum CodingKeys: String, CodingKey {
        case polygons = "p"
        case bounds = "b"
        case isConvex = "c"
    }

    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            let polygons = try container.decode([Polygon].self, forKey: .polygons)
            let bounds = try container.decodeIfPresent(Bounds.self, forKey: .bounds)
            let isConvex = try container.decodeIfPresent(Bool.self, forKey: .isConvex) ?? false
            self.init(
                unchecked: polygons.flatMap { $0.tessellate() },
                bounds: bounds,
                isConvex: isConvex
            )
        } else {
            let polygons = try [Polygon](from: decoder)
            self.init(polygons)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(polygons, forKey: .polygons)
        try container.encode(bounds, forKey: .bounds)
        try container.encode(isConvex, forKey: .isConvex)
    }
}

public extension Mesh {
    /// Material used by a given polygon
    typealias Material = Polygon.Material

    /// Public properties
    var polygons: [Polygon] { storage.polygons }
    var bounds: Bounds { storage.bounds }

    /// Polygons grouped by material
    var polygonsByMaterial: [Material?: [Polygon]] {
        var polygonsByMaterial = [Material?: [Polygon]]()
        for polygon in polygons {
            let material = polygon.material
            if polygonsByMaterial[material] == nil {
                polygonsByMaterial[material] = polygons.filter { $0.material == material }
            }
        }
        return polygonsByMaterial
    }

    /// Construct a Mesh from a list of `Polygon` instances.
    init(_ polygons: [Polygon]) {
        self.init(unchecked: polygons.flatMap { $0.tessellate() }, isConvex: false)
    }

    /// Replaces one material with another
    func replacing(_ old: Material?, with new: Material?) -> Mesh {
        Mesh(
            unchecked: polygons.map {
                if $0.material == old {
                    var polygon = $0
                    polygon.material = new
                    return polygon
                }
                return $0
            },
            bounds: boundsIfSet,
            isConvex: isConvex
        )
    }

    /// Returns a new Mesh that includes all polygons from both the
    /// parameter and receiver. Polygons are neither split nor removed.
    func merge(_ mesh: Mesh) -> Mesh {
        var bounds: Bounds?
        if let ab = boundsIfSet, let bb = mesh.boundsIfSet {
            bounds = ab.union(bb)
        }
        return Mesh(
            unchecked: polygons + mesh.polygons,
            bounds: bounds,
            isConvex: false
        )
    }

    /// Flips face direction of polygons.
    func inverted() -> Mesh {
        Mesh(unchecked: polygons.inverted(), isConvex: false)
    }

    /// Split concave polygons into 2 or more convex polygons.
    func tessellate() -> Mesh {
        Mesh(unchecked: polygons.tessellate(), isConvex: isConvex)
    }

    /// Tessellate polygons into triangles.
    func triangulate() -> Mesh {
        Mesh(unchecked: polygons.triangulate(), isConvex: isConvex)
    }
}

internal extension Mesh {
    init(unchecked polygons: [Polygon], bounds: Bounds? = nil, isConvex: Bool) {
        assert(polygons.allSatisfy { $0.isConvex })
        self.storage = Storage(polygons: polygons, bounds: bounds, isConvex: isConvex)
    }

    var boundsIfSet: Bounds? { storage.boundsIfSet }
    var isConvex: Bool { storage.isConvex }
}

private extension Mesh {
    final class Storage: Hashable {
        let polygons: [Polygon]
        var boundsIfSet: Bounds?
        let isConvex: Bool

        var bounds: Bounds {
            if boundsIfSet == nil {
                boundsIfSet = Bounds(bounds: polygons.map { $0.bounds })
            }
            return boundsIfSet!
        }

        static func == (lhs: Storage, rhs: Storage) -> Bool {
            lhs === rhs || lhs.polygons == rhs.polygons
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(polygons)
        }

        init(polygons: [Polygon], bounds: Bounds?, isConvex: Bool) {
            self.polygons = polygons
            self.boundsIfSet = bounds
            self.isConvex = isConvex
        }
    }
}
