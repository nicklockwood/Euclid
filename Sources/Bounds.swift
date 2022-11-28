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

/// An axially-aligned bounding box in 3D space.
///
/// Used for efficient intersection elimination between more complex shapes.
public struct Bounds: Hashable, Sendable {
    /// The minimum coordinate of the bounds.
    public let min: Vector
    /// The maximum coordinate of the bounds.
    public let max: Vector

    /// Creates a bounds with min and max coordinates.
    /// - Parameters:
    ///   - min: The minimum coordinate value.
    ///   - max: The maximum coordinate value.
    ///
    /// > Note: If the value for max is less than the value for min, the bounds is considered to be empty.
    public init(min: Vector, max: Vector) {
        self.min = min
        self.max = max
    }
}

/// A common protocol for objects that have a bounds.
public protocol Bounded {
    /// The bounds of the object.
    var bounds: Bounds { get }
}

extension Bounds: CustomStringConvertible {
    public var description: String {
        "Bounds(min: [\(min.components)], max: [\(max.components)])"
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

    /// Encodes this bounds into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try min.encode(to: &container)
        try max.encode(to: &container)
    }
}

public extension Bounds {
    /// An empty bounds.
    static let empty: Bounds = .init(
        min: Vector(.infinity, .infinity, .infinity),
        max: Vector(-.infinity, -.infinity, -.infinity)
    )

    /// Creates a bounds from two points.
    /// - Parameters:
    ///   - p0: The first point.
    ///   - p1: The second point.
    ///
    /// > Note: Unlike the `init(min:max:)` constructor, the order of the points doesn't matter.
    init(_ p0: Vector, _ p1: Vector) {
        self.min = Euclid.min(p0, p1)
        self.max = Euclid.max(p0, p1)
    }

    /// Creates a bounds from a collection of ``Bounded`` objects.
    /// - Parameter bounded: A collection of bounded objects.
    init<T: Collection>(_ bounded: T) where T.Element: Bounded {
        self = bounded.reduce(.empty) { $0.union($1.bounds) }
    }

    /// Creates a bounds from a collection of points.
    /// - Parameter points: A collection of points that the bounds contains.
    init<T: Collection>(_ points: T) where T.Element == Vector {
        self = points.reduce(.empty) {
            Bounds(min: Euclid.min($0.min, $1), max: Euclid.max($0.max, $1))
        }
    }

    /// Creates a bounds from a collection of bounds.
    /// - Parameter bounds: A collection of existing bounds that the bounds contains.
    init<T: Collection>(_ bounds: T) where T.Element == Bounds {
        self = bounds.reduce(.empty) {
            Bounds(min: Euclid.min($0.min, $1.min), max: Euclid.max($0.max, $1.max))
        }
    }

    /// Deprecated.
    @available(*, deprecated, renamed: "init(_:)")
    init(points: [Vector] = []) {
        self = points.reduce(.empty) {
            Bounds(min: Euclid.min($0.min, $1), max: Euclid.max($0.max, $1))
        }
    }

    /// Deprecated.
    @available(*, deprecated, renamed: "init(_:)")
    init(polygons: [Polygon]) {
        self.init(polygons)
    }

    /// Deprecated.
    @available(*, deprecated, renamed: "init(_:)")
    init(bounds: [Bounds]) {
        self.init(bounds)
    }

    /// A Boolean value that indicates whether the bounds is empty (has zero volume).
    var isEmpty: Bool {
        size == .zero
    }

    /// The size of the bounds. The minimum returned size is zero, even if max < min.
    var size: Vector {
        hasNegativeVolume ? .zero : max - min
    }

    /// The center of the bounds. If the bounds is empty this will return the zero vector.
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

    /// Creates a new bounds that contains both the specified bounds and this one.
    /// - Parameter other: The other bounds to be included.
    /// - Returns: The combined bounds.
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

    /// Expands this bounds (if necessary) to contain the specified bounds.
    /// - Parameter other: The bounds to be included.
    mutating func formUnion(_ other: Bounds) {
        self = union(other)
    }

    /// Creates a new bounds representing the intersection between the specified bounds and this one.
    /// - Parameter other: The bounds with which to intersect.
    /// - Returns: The combined bounds, which may be empty if the bounds don't intersect.
    func intersection(_ other: Bounds) -> Bounds {
        Bounds(min: Euclid.max(min, other.min), max: Euclid.min(max, other.max))
    }

    /// Reduces the bounds to contain just the intersection of itself and the specified bounds.
    /// - Parameter other: The bounds with which to intersect.
    mutating func formIntersection(_ other: Bounds) {
        self = intersection(other)
    }

    /// Returns a Boolean value that indicates whether the two bounds intersect.
    /// - Parameter other: The bounds to compare.
    /// - Returns: `true` if the bounds intersect, and `false` otherwise.
    func intersects(_ other: Bounds) -> Bool {
        !(
            other.max.x + epsilon < min.x || other.min.x > max.x + epsilon ||
                other.max.y + epsilon < min.y || other.min.y > max.y + epsilon ||
                other.max.z + epsilon < min.z || other.min.z > max.z + epsilon
        )
    }

    /// Returns a Boolean value that indicates if the bounds intersects the specified plane.
    /// - Parameter plane: The plane to compare.
    /// - Returns: `true` if the plane intersects the bounds, and `false` otherwise.
    func intersects(_ plane: Plane) -> Bool {
        compare(with: plane) == .spanning
    }

    /// Returns a Boolean value that indicates if the specified point is within the bounds.
    /// - Parameter point: The point to compare.
    /// - Returns: `true` if the point lies inside the bounds, and `false` otherwise.
    func containsPoint(_ point: Vector) -> Bool {
        point.x >= min.x && point.x <= max.x &&
            point.y >= min.y && point.y <= max.y &&
            point.z >= min.z && point.z <= max.z
    }

    /// Returns a new bounds inset by the specified distance.
    /// - Parameter v: The distance to inset the bounds by. Use negative values to expand the bounds.
    /// - Returns: The inset bounds.
    func inset(by v: Vector) -> Bounds {
        Bounds(min: min + v, max: max - v)
    }

    /// Returns a new bounds inset by the specified amount.
    /// - Parameter d: The amount to inset the bounds by. Use a negative value to expand the bounds.
    /// - Returns: The inset bounds.
    func inset(by d: Double) -> Bounds {
        inset(by: Vector(size: d))
    }
}

extension Bounds {
    /// A Boolean value that indicates the bounds has a negative volume.
    var hasNegativeVolume: Bool {
        max.x < min.x || max.y < min.y || max.z < min.z
    }

    /// Approximate equality
    func isEqual(to other: Bounds, withPrecision p: Double = epsilon) -> Bool {
        min.isEqual(to: other.min, withPrecision: p) &&
            max.isEqual(to: other.max, withPrecision: p)
    }

    /// Compares a region defined by the bounds with a plane to determine the
    /// relationship of the points that make up the bounds to the plane.
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
