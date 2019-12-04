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
    public private(set) var bounds: Bounds
    public var polygons: [Polygon] {
        didSet {
            bounds = Bounds(bounds: polygons.map { $0.bounds })
        }
    }
}

public extension Mesh {
    /// Polygons grouped by material
    var polygonsByMaterial: [Polygon.Material: [Polygon]] {
        var polygonsByMaterial = [Polygon.Material: [Polygon]]()
        
        if (polygons.isEmpty) {
            return polygonsByMaterial
        }
                
        let materials = Set(polygons.map { $0.material })
        for material in materials {
            polygonsByMaterial[material] = polygons.filter { $0.material == material }
        }
        
        return polygonsByMaterial
    }

    /// Construct a Mesh from a list of `Polygon` instances.
    init(_ polygons: [Polygon]) {
        self.polygons = polygons.flatMap { $0.tessellate() }
        bounds = Bounds(bounds: polygons.map { $0.bounds })
    }

    /// Replaces one material with another
    func replacing(_ old: Polygon.Material, with new: Polygon.Material) -> Mesh {
        return Mesh(polygons.map {
            if $0.material == old {
                var polygon = $0
                polygon.material = new
                return polygon
            }
            return $0
        })
    }

    /// Returns a new Mesh that includes all polygons from both the
    /// parameter and receiver. Polygons are neither split nor removed.
    func merge(_ mesh: Mesh) -> Mesh {
        return Mesh(polygons + mesh.polygons)
    }
}
