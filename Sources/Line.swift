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

/// A struct that represents an infinite line in 3D space.
///
/// A line is defined by an `origin` point and a normalized `direction` vector.
public struct Line: Hashable {
    public let origin, direction: Vector

    /// Creates a line from an origin and direction
    public init?(origin: Vector, direction: Vector) {
        let length = direction.length
        guard length.isFinite, length > epsilon else {
            return nil
        }
        self.init(unchecked: origin, direction: direction / length)
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
    /// Creates a new line with the line segments you provide.
    /// - Parameter segment: The line segments.
    init(_ segment: LineSegment) {
        self.init(unchecked: segment.start, direction: segment.direction)
    }

    /// Returns a Boolean value that indicates whether the point is on the line.
    /// - Parameter p: The point to compare.
    func containsPoint(_ p: Vector) -> Bool {
        abs(p.distance(from: self)) < epsilon
    }

    /// Returns the distance of the line from a given point in 3D.
    /// - Parameter point: The point to compare.
    /// - Returns: The distance between the point and line.
    func distance(from point: Vector) -> Double {
        vectorFromPointToLine(point, origin, direction).length
    }

    /// Returns the distance of this line from another line.
    /// - Parameter line: The line to compare.
    /// - Returns: The distance to the line.
    func distance(from line: Line) -> Double {
        guard let (p0, p1) = shortestLineBetween(
            origin,
            origin + direction,
            line.origin,
            line.origin + line.direction
        ) else {
            return 0
        }
        return (p1 - p0).length
    }

    /// Returns a point that represents the Intersection between the plane you provide and the line.
    /// - Parameter plane: The plane to compare.
    /// - Returns: Returns `nil` if the plane doesn't intersect the line.
    func intersection(with plane: Plane) -> Vector? {
        plane.intersection(with: self)
    }

    /// Returns a point that indicates the Intersection between the lines.
    /// - Parameter line: The line to compare.
    /// - Returns: Returns `nil` if the lines don't intersect.
    func intersection(with line: Line) -> Vector? {
        lineIntersection(
            origin,
            origin + direction,
            line.origin,
            line.origin + line.direction
        )
    }

    /// Returns a Boolean value that indicates whether the lines intersect.
    /// - Parameter line: The line to compare.
    func intersects(_ line: Line) -> Bool {
        intersection(with: line) != nil
    }
}

internal extension Line {
    init(unchecked origin: Vector, direction: Vector) {
        assert(direction.isNormalized)
        self.origin = origin - direction * (
            direction.x != 0 ? origin.x / direction.x :
                direction.y != 0 ? origin.y / direction.y :
                origin.z / direction.z
        )
        self.direction = direction
    }
}
