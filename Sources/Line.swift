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

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try origin.encode(to: &container)
        try direction.encode(to: &container)
    }
}

public extension Line {
    init(_ segment: LineSegment) {
        self.init(unchecked: segment.start, direction: segment.direction)
    }

    /// Check if point is on line
    func containsPoint(_ p: Vector) -> Bool {
        abs(p.distance(from: self)) < epsilon
    }

    /// Distance of the line from a given point in 3D
    func distance(from point: Vector) -> Double {
        vectorFromPointToLine(point, origin, direction).length
    }

    /// Distance of the line from another line
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

    /// Intersection point betwween plane and line (if any)
    func intersection(with plane: Plane) -> Vector? {
        plane.intersection(with: self)
    }

    /// Intersection point between lines (if any)
    func intersection(with line: Line) -> Vector? {
        lineIntersection(
            origin,
            origin + direction,
            line.origin,
            line.origin + line.direction
        )
    }

    /// Returns true if the lines intersect
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
