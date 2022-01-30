//
//  Bounds.swift
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

/// An axially-aligned bounding box for a 3D shape or collection of shapes.
public struct Bounds: Hashable {
    /// The minimum location for the bounds.
    public let min: Vector
    /// The maximum location for the bounds.
    public let max: Vector

    /// Create a bounds with min and max points
    /// If max < min, bounds is considered to be empty
    public init(min: Vector, max: Vector) {
        self.min = min
        self.max = max
    }
}

extension Bounds: Codable {
    private enum CodingKeys: CodingKey {
        case min, max
    }

    public init(from decoder: Decoder) throws {
        let min, max: Vector
        if var container = try? decoder.unkeyedContainer() {
            min = try Vector(from: &container)
            max = try Vector(from: &container)
        } else {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            min = try container.decode(Vector.self, forKey: .min)
            max = try container.decode(Vector.self, forKey: .max)
        }
        self.init(min: min, max: max)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try min.encode(to: &container)
        try max.encode(to: &container)
    }
}

public extension Bounds {
    static let empty = Bounds()

    /// Create a bounds from two points
    /// Unlike the `init(min:max:)` constructor, the order of the points doesn't matter
    init(_ p0: Vector, _ p1: Vector) {
        self.min = Euclid.min(p0, p1)
        self.max = Euclid.max(p0, p1)
    }

    /// Create a bounds from an array of points.
    init(points: [Vector] = []) {
        var min = Vector(.infinity, .infinity, .infinity)
        var max = Vector(-.infinity, -.infinity, -.infinity)
        for p in points {
            min = Euclid.min(min, p)
            max = Euclid.max(max, p)
        }
        self.min = min
        self.max = max
    }

    init(polygons: [Polygon]) {
        var min = Vector(.infinity, .infinity, .infinity)
        var max = Vector(-.infinity, -.infinity, -.infinity)
        for p in polygons {
            for v in p.vertices {
                min = Euclid.min(min, v.position)
                max = Euclid.max(max, v.position)
            }
        }
        self.min = min
        self.max = max
    }

    init(bounds: [Bounds]) {
        var min = Vector(.infinity, .infinity, .infinity)
        var max = Vector(-.infinity, -.infinity, -.infinity)
        for b in bounds {
            min = Euclid.min(min, b.min)
            max = Euclid.max(max, b.max)
        }
        self.min = min
        self.max = max
    }

    var isEmpty: Bool {
        size == .zero
    }

    var size: Vector {
        hasNegativeVolume ? .zero : max - min
    }

    var center: Vector {
        hasNegativeVolume ? .zero : min + size / 2
    }

    var corners: [Vector] {
        [
            min,
            Vector(min.x, max.y, min.z),
            Vector(max.x, max.y, min.z),
            Vector(max.x, min.y, min.z),
            Vector(min.x, min.y, max.z),
            Vector(min.x, max.y, max.z),
            max,
            Vector(max.x, min.y, max.z),
        ]
    }

    func union(_ other: Bounds) -> Bounds {
        if isEmpty {
            return other
        } else if other.isEmpty {
            return self
        }
        return Bounds(
            min: Euclid.min(min, other.min),
            max: Euclid.max(max, other.max)
        )
    }

    mutating func formUnion(_ other: Bounds) {
        self = union(other)
    }

    func intersection(_ other: Bounds) -> Bounds {
        Bounds(
            min: Euclid.max(min, other.min),
            max: Euclid.min(max, other.max)
        )
    }

    mutating func formIntersection(_ other: Bounds) {
        self = intersection(other)
    }

    func intersects(_ other: Bounds) -> Bool {
        !(
            other.max.x + epsilon < min.x || other.min.x > max.x + epsilon ||
                other.max.y + epsilon < min.y || other.min.y > max.y + epsilon ||
                other.max.z + epsilon < min.z || other.min.z > max.z + epsilon
        )
    }

    func intersects(_ plane: Plane) -> Bool {
        compare(with: plane) == .spanning
    }

    func containsPoint(_ p: Vector) -> Bool {
        p.x >= min.x && p.x <= max.x &&
            p.y >= min.y && p.y <= max.y &&
            p.z >= min.z && p.z <= max.z
    }

    /// Returns bounds inset by specified amount.
    /// Use negative values to expand the bounds.
    func inset(by v: Vector) -> Bounds {
        Bounds(min: min + v, max: max - v)
    }

    /// Returns bounds inset by specified amount.
    /// Use a negative value to expand the bounds.
    func inset(by d: Double) -> Bounds {
        inset(by: Vector(size: d))
    }
}

extension Bounds {
    var hasNegativeVolume: Bool {
        max.x < min.x || max.y < min.y || max.z < min.z
    }

    // Approximate equality
    func isEqual(to other: Bounds, withPrecision p: Double = epsilon) -> Bool {
        min.isEqual(to: other.min, withPrecision: p) &&
            max.isEqual(to: other.max, withPrecision: p)
    }

    func compare(with plane: Plane) -> PlaneComparison {
        var comparison = PlaneComparison.coplanar
        for point in corners {
            comparison = comparison.union(point.compare(with: plane))
            if comparison == .spanning {
                break
            }
        }
        return comparison
    }
}
