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

public struct LineSegment: Hashable {
    public let start, end: Vector

    /// Creates a line segment from a start and end point
    public init?(_ start: Vector, _ end: Vector) {
        guard start != end else {
            return nil
        }
        self.start = start
        self.end = end
    }
}

extension LineSegment: Codable {
    private enum CodingKeys: CodingKey {
        case start, end
    }

    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            guard let segment = try LineSegment(
                container.decode(Vector.self, forKey: .start),
                container.decode(Vector.self, forKey: .end)
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
                Vector(from: &container),
                Vector(from: &container)
            ) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "LineSegment cannot have zero length"
                )
            }
            self = segment
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try start.encode(to: &container)
        try end.encode(to: &container)
    }
}

public extension LineSegment {
    var direction: Direction {
        Direction(end - start)
    }

    /// Check if point is on line segment
    func containsPoint(_ p: Vector) -> Bool {
        let v = vectorFromPointToLine(p, start, direction)
        guard v.length < epsilon else {
            return false
        }
        return lineSegmentsContainsPoint(start, end, p + v)
    }

    /// Intersection point between lines (if any)
    func intersection(with segment: LineSegment) -> Vector? {
        lineSegmentsIntersection(start, end, segment.start, segment.end)
    }

    /// Returns true if the line segments intersect
    func intersects(_ segment: LineSegment) -> Bool {
        intersection(with: segment) != nil
    }
}

internal extension LineSegment {
    init(unchecked start: Vector, _ end: Vector) {
        assert(start != end)
        self.start = start
        self.end = end
    }
}
