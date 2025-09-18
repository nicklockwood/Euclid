//
//  LineSegment.swift
//  Euclid
//
//  Created by Nick Lockwood on 20/11/2019.
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

/// A finite line segment in 3D space.
public struct LineSegment: Hashable, Sendable {
    /// The starting point of the line segment.
    public let start: Vector
    /// The end point of the line segment.
    public let end: Vector

    /// Creates a line segment with a start and end point.
    /// - Parameters:
    ///   - start: The start of the line segment.
    ///   - end: The end of the line segment.
    public init?(start: Vector, end: Vector) {
        guard start != end else {
            return nil
        }
        self.start = start
        self.end = end
    }
}

extension LineSegment: Comparable {
    /// Returns whether the leftmost line segment has the lower value.
    /// This provides a stable order when sorting collections of line segments.
    public static func < (lhs: LineSegment, rhs: LineSegment) -> Bool {
        if lhs.start == rhs.start {
            return lhs.end < rhs.end
        }
        return lhs.start < rhs.start
    }
}

extension LineSegment: Codable {
    private enum CodingKeys: CodingKey {
        case start, end
    }

    /// Creates a new line segment by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            guard let segment = try LineSegment(
                start: container.decode(Vector.self, forKey: .start),
                end: container.decode(Vector.self, forKey: .end)
            ) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .end,
                    in: container,
                    debugDescription: "LineSegment cannot have zero length"
                )
            }
            self = segment
        } else {
            var container = try decoder.unkeyedContainer()
            guard let segment = try LineSegment(
                start: Vector(from: &container),
                end: Vector(from: &container)
            ) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "LineSegment cannot have zero length"
                )
            }
            self = segment
        }
    }

    /// Encodes this line segment into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try start.encode(to: &container)
        try end.encode(to: &container)
    }
}

extension LineSegment: CustomDebugStringConvertible, CustomReflectable {
    public var debugDescription: String {
        "LineSegment(start: \(start.components), end: \(end.components))"
    }

    public var customMirror: Mirror {
        Mirror(self, children: [:], displayStyle: .struct)
    }
}

public extension LineSegment {
    /// The direction of the line segment as a normalized vector.
    var direction: Vector {
        lengthAndDirection.direction
    }

    /// The length of the line segment.
    var length: Double {
        lengthAndDirection.length
    }

    /// The length and direction of the line segment.
    var lengthAndDirection: (length: Double, direction: Vector) {
        let (length, direction) = (end - start).lengthAndDirection
        assert(direction != .zero)
        return (length, direction ?? .zero)
    }

    /// Creates an 'undirected' line segment.
    /// Undirected segments have a normalized direction such that `a -> b` and `b -> a` are equal/equivalent.
    /// - Parameters:
    ///   - a: One end of the line segment.
    ///   - b: The other end of the line segment.
    init?(undirected a: Vector, _ b: Vector) {
        if a < b {
            self.init(start: a, end: b)
        } else {
            self.init(start: b, end: a)
        }
    }

    /// Creates an 'undirected' line segment from a directional one.
    /// - Parameter segment: The input segment.
    init(undirected segment: LineSegment) {
        if segment.start < segment.end {
            self = segment
        } else {
            self.init(unchecked: segment.end, segment.start)
        }
    }

    /// Flip the direction of the line segment
    func inverted() -> LineSegment {
        .init(unchecked: end, start)
    }

    /// Deprecated.
    @available(*, deprecated, renamed: "intersects(_:)")
    func containsPoint(_ point: Vector) -> Bool {
        intersects(point)
    }

    /// Returns the point where the specified plane intersects the line segment.
    /// - Parameter plane: The plane to compare with.
    /// - Returns: The point of intersection, or `nil` if the line segment and plane don't intersect.
    func intersection(with plane: Plane) -> Vector? {
        let (length, direction) = lengthAndDirection
        return linePlaneIntersection(start, direction, plane).flatMap {
            (0 ... length).contains($0) ? start + direction * $0 : nil
        }
    }

    /// Returns the point where the specified line intersects the line segment.
    /// - Parameter line: The line to compare with.
    /// - Returns: The point of intersection, or `nil` if the line and segment don't intersect.
    func intersection(with line: Line) -> Vector? {
        lineIntersection(
            start,
            end,
            true,
            line.origin,
            line.origin + line.direction,
            false
        )
    }

    /// Returns the point where the specified line segment intersects the line segment.
    /// - Parameter lineSegment: The line segment to compare with.
    /// - Returns: The point of intersection, or `nil` if the segments don't intersect.
    func intersection(with lineSegment: LineSegment) -> Vector? {
        lineIntersection(
            start,
            end,
            true,
            lineSegment.start,
            lineSegment.end,
            true
        )
    }

    /// Returns the point where the specified polygon intersects the line segment.
    /// - Parameter polygon: The polygon to compare with.
    /// - Returns: The point of intersection, or `nil` if the line and polygon don't intersect.
    func intersection(with polygon: Polygon) -> Vector? {
        intersection(with: polygon.plane).flatMap {
            polygon.intersects($0) ? $0 : nil
        }
    }

    /// Returns the points where the specified bounds intersects the line segment.
    /// - Parameter bounds: The bounds to compare with.
    /// - Returns: A set of zero or more points of intersection with the bounds.
    func intersection(with bounds: Bounds) -> Set<Vector> {
        var intersections = Set<Vector>()
        if start.intersects(bounds) { intersections.insert(start) }
        if end.intersects(bounds) { intersections.insert(end) }
        if intersections.count == 2 {
            return intersections
        }
        // TODO: optimize this by taking into account that planes are axis-aligned
        return intersections.union(bounds.edgePlanes.compactMap {
            intersection(with: $0).flatMap(bounds.intersection(with:))
        })
    }

    /// Returns the shortest distance between the line and the line segment.
    /// - Parameter lineSegment: The lineSegment to compare with.
    /// - Returns: The absolute distance from the nearest point on the object.
    func distance(from lineSegment: LineSegment) -> Double {
        shortestLineBetween(
            start,
            end,
            true,
            lineSegment.start,
            lineSegment.end,
            true
        ).flatMap {
            ($1 - $0).length
        } ?? 0
    }

    /// Returns a true if the line segment intersects the specified line.
    /// - Parameter lineSegment: The lineSegment to compare with.
    /// - Returns: `true` if the line and segment intersect, and `false` otherwise.
    func intersects(_ lineSegment: LineSegment) -> Bool {
        intersection(with: lineSegment) != nil
    }

    /// Returns a true if the line segment intersects the specified polygon.
    /// - Parameter polygon: The polygon to compare with.
    /// - Returns: `true` if the polygon and segment intersect, and `false` otherwise.
    func intersects(_ polygon: Polygon) -> Bool {
        intersection(with: polygon) != nil
    }

    /// Returns a true if the line segment intersects the specified bounds.
    /// - Parameter bounds: The bodun to compare with.
    /// - Returns: `true` if the line and bounds intersect, and `false` otherwise.
    func intersects(_ bounds: Bounds) -> Bool {
        !intersection(with: bounds).isEmpty
    }
}

extension LineSegment {
    init(unchecked start: Vector, _ end: Vector) {
        assert(start != end)
        self.start = start
        self.end = end
    }
}
