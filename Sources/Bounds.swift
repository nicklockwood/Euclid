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

    /// Creates a bounds with min and max points.
    ///
    /// If the value you provide for max is less than the value for min, the bounds is considered to be empty.
    /// - Parameters:
    ///   - min: The minimum value.
    ///   - max: The maximum value.
    public init(min: Vector, max: Vector) {
        self.min = min
        self.max = max
    }
}

extension Bounds: Codable {
    private enum CodingKeys: CodingKey {
        case min, max
    }

    /// Creates a new vector by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
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

    /// Encodes this date into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try min.encode(to: &container)
        try max.encode(to: &container)
    }
}

public extension Bounds {
    /// An empty bounds.
    static let empty = Bounds()

    /// Creates a bounds from two points.
    ///
    /// Unlike the `init(min:max:)` constructor, the order of the points doesn't matter
    /// - Parameters:
    ///   - p0: The first point.
    ///   - p1: The second point.
    init(_ p0: Vector, _ p1: Vector) {
        self.min = Euclid.min(p0, p1)
        self.max = Euclid.max(p0, p1)
    }

    /// Create a bounds from an array of points.
    /// - Parameter points: The array of points that the bounds surrounds.
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
    
    /// Create a bounds from an array of points.
    /// - Parameter polygons: The array of polygons that the bounds surrounds.
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
    
    /// Creates a bounds from a list of bounds.
    /// - Parameter bounds: The bounds to accumulate into a larger bounds.
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
    
    /// A Boolean value that indicates whether the bounds is empty.
    var isEmpty: Bool {
        size == .zero
    }
    
    /// The size of the bounds.
    var size: Vector {
        hasNegativeVolume ? .zero : max - min
    }
    
    /// The center of the bounds.
    var center: Vector {
        hasNegativeVolume ? .zero : min + size / 2
    }
    
    /// The points that make up the corners of the bounds.
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
    
    /// Creates a new bounds by joining the current bounds to another.
    /// - Parameter other: The bounds to be included.
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
    
    /// Expands the boundaries of this bounds to include the volume of it and the bounds you provide.
    /// - Parameter other: The bounds to be included.
    mutating func formUnion(_ other: Bounds) {
        self = union(other)
    }
    
    /// Returns a new bounds that is the intersection of this bounds and another you provide.
    /// - Parameter other: The bounds with which to intersect.
    func intersection(_ other: Bounds) -> Bounds {
        Bounds(
            min: Euclid.max(min, other.min),
            max: Euclid.min(max, other.max)
        )
    }
    
    /// Decreaeses the boundaries of this bounds to the intersection of it and the other bounds you provide.
    /// - Parameter other: The bounds with which to intersect.
    mutating func formIntersection(_ other: Bounds) {
        self = intersection(other)
    }
    
    /// Returns a Boolean value that indicates whether the two bounds intersect.
    /// - Parameter other: The bounds to compare.
    func intersects(_ other: Bounds) -> Bool {
        !(
            other.max.x + epsilon < min.x || other.min.x > max.x + epsilon ||
                other.max.y + epsilon < min.y || other.min.y > max.y + epsilon ||
                other.max.z + epsilon < min.z || other.min.z > max.z + epsilon
        )
    }
    
    /// Returns a Boolean value that indicates if the plane you provide intersects this bounds.
    /// - Parameter plane: The plane to compare.
    func intersects(_ plane: Plane) -> Bool {
        compare(with: plane) == .spanning
    }
    
    /// Returns a Boolean value that indicates if the point you provide is within this bounds.
    /// - Parameter p: The point to compare.
    func containsPoint(_ p: Vector) -> Bool {
        p.x >= min.x && p.x <= max.x &&
            p.y >= min.y && p.y <= max.y &&
            p.z >= min.z && p.z <= max.z
    }

    /// Returns a new bounds inset by specified amount.
    ///
    /// Use negative values to expand the bounds.
    func inset(by v: Vector) -> Bounds {
        Bounds(min: min + v, max: max - v)
    }

    /// Returns a new bounds inset by specified amount.
    ///
    /// Use a negative value to expand the bounds.
    func inset(by d: Double) -> Bounds {
        inset(by: Vector(size: d))
    }
}

extension Bounds {
    /// A Boolean value that indicates the bounds has a negative volume.
    var hasNegativeVolume: Bool {
        max.x < min.x || max.y < min.y || max.z < min.z
    }

    /// Returns a Boolean value that indicates the bounds are approximately equal based on the amount of precision you provide.
    /// - Parameters:
    ///   - other: The bounds to compare.
    ///   - p: The precision to use for the comparison.
    func isEqual(to other: Bounds, withPrecision p: Double = epsilon) -> Bool {
        min.isEqual(to: other.min, withPrecision: p) &&
            max.isEqual(to: other.max, withPrecision: p)
    }
    
    /// Compares a region defined by the bounds with a plane to determine the relationship of the points that make up the bounds to the plane.
    /// - Parameter plane: The plane to compare.
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
