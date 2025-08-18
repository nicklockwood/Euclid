//
//  Line.swift
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

/// An infinite line in 3D space.
public struct Line: Hashable, Sendable {
    /// An arbitrary point on the line selected as the origin.
    public let origin: Vector
    /// The normalized direction of the line.
    public let direction: Vector

    /// Creates a line from an origin and direction.
    /// - Parameters:
    ///   - origin: An arbitrary point on the line selected as the origin.
    ///   - direction: The direction of the line, emanating from the origin.
    public init?(origin: Vector, direction: Vector) {
        let length = direction.length
        guard length.isFinite, length > epsilon else {
            return nil
        }
        self.init(unchecked: origin, direction: direction / length)
    }
}

extension Line: CustomDebugStringConvertible, CustomReflectable {
    public var debugDescription: String {
        "Line(origin: \(origin.components), direction: \(direction.components))"
    }

    public var customMirror: Mirror {
        Mirror(self, children: [:], displayStyle: .struct)
    }
}

extension Line: Codable {
    private enum CodingKeys: CodingKey {
        case origin, direction
    }

    /// Creates a new line by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            guard let line = try Line(
                origin: container.decode(Vector.self, forKey: .origin),
                direction: container.decode(Vector.self, forKey: .direction)
            ) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .direction,
                    in: container,
                    debugDescription: "Line direction must have nonzero length"
                )
            }
            self = line
        } else {
            var container = try decoder.unkeyedContainer()
            guard let line = try Line(
                origin: Vector(from: &container),
                direction: Vector(from: &container)
            ) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Line direction must have nonzero length"
                )
            }
            self = line
        }
    }

    /// Encodes this line into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try origin.encode(to: &container)
        try direction.encode(to: &container)
    }
}

public extension Line {
    /// Creates a new line from the specified line segment.
    /// - Parameter segment: A segment somewhere on the line.
    init(_ segment: LineSegment) {
        self.init(unchecked: segment.start, direction: segment.direction)
    }

    /// Deprecated.
    @available(*, deprecated, renamed: "intersects(_:)")
    func containsPoint(_ point: Vector) -> Bool {
        intersects(point)
    }

    /// Returns the point where the specified line intersects this one.
    /// - Parameter line: The line to compare with.
    /// - Returns: The point of intersection, or `nil` if the lines don't intersect.
    func intersection(with line: Line) -> Vector? {
        lineIntersection(
            origin,
            origin + direction,
            false,
            line.origin,
            line.origin + line.direction,
            false
        )
    }

    /// Returns the point where the specified plane intersects the line.
    /// - Parameter plane: The plane to compare with.
    /// - Returns: The point of intersection, or `nil` if the line and plane are parallel (don't intersect).
    func intersection(with plane: Plane) -> Vector? {
        linePlaneIntersection(origin, direction, plane).map {
            origin + direction * $0
        }
    }

    /// Returns the points where the specified bounds intersects the line.
    /// - Parameter bounds: The bounds to compare with.
    /// - Returns: A set of zero or more points of intersection with the bounds.
    func intersection(with polygon: Polygon) -> Vector? {
        intersection(with: polygon.plane).flatMap {
            polygon.intersects($0) ? $0 : nil
        }
    }

    /// Returns the points where the specified bounds intersects the line.
    /// - Parameter bounds: The bounds to compare with.
    /// - Returns: A set of zero or more points of intersection with the bounds.
    func intersection(with bounds: Bounds) -> Set<Vector> {
        // TODO: optimize this by taking into account that planes are axis-aligned
        Set(bounds.edgePlanes.compactMap {
            intersection(with: $0).flatMap {
                bounds.intersects($0) ? $0 : nil
            }
        })
    }

    /// Returns the shortest distance between the line and the specified object.
    /// - Parameter object: The object to compare with.
    /// - Returns: The absolute distance from the nearest point on the object.
    func distance(from object: some LineComparable) -> Double {
        object.distance(from: self)
    }

    /// Returns a true if the line intersects the specified object.
    /// - Parameter object: The object to compare with.
    /// - Returns: `true` if the line and object intersect, and `false` otherwise.
    func intersects(_ object: some LineComparable) -> Bool {
        object.intersects(self)
    }
}

extension Line {
    init(unchecked origin: Vector, direction: Vector) {
        assert(direction.isNormalized)
        self.origin = origin - direction * (
            direction.x != 0 ? origin.x / direction.x :
                direction.y != 0 ? origin.y / direction.y :
                origin.z / direction.z
        )
        self.direction = direction
    }

    func signedPerpendicularDistance(from plane: Plane) -> Double? {
        isParallel(to: plane) ? origin.signedDistance(from: plane) : nil
    }

    func isParallel(to plane: Plane) -> Bool {
        direction.dot(plane.normal) < planeEpsilon
    }
}
