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
    public let start, end: Position

    /// Creates a line segment from a start and end point
    public init?(_ start: Position, _ end: Position) {
        guard start != end else {
            return nil
        }
        self.start = start
        self.end = end
    }
}

extension LineSegment: Comparable {
    /// Provides a stable sort order for LineSegments
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

    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            guard let segment = try LineSegment(
                container.decode(Position.self, forKey: .start),
                container.decode(Position.self, forKey: .end)
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
                Position(from: &container),
                Position(from: &container)
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
        (end - start).direction
    }

    var length: Double {
        (end - start).length
    }

    /// Check if point is on line segment
    func containsPoint(_ p: Position) -> Bool {
        let v = distanceFromPointToLine(p, Line(origin: start, direction: direction))
        guard v.norm < epsilon else {
            return false
        }
        return Bounds(start, end).containsPoint(p)
    }

    /// Intersection point between lines (if any)
    func intersection(with segment: LineSegment) -> Position? {
        lineSegmentsIntersection(start, end, segment.start, segment.end)
    }

    /// Returns true if the line segments intersect
    func intersects(_ segment: LineSegment) -> Bool {
        intersection(with: segment) != nil
    }
}

internal extension LineSegment {
    init(unchecked start: Position, _ end: Position) {
        assert(start != end)
        self.start = start
        self.end = end
    }

    init(normalized start: Vector, _ end: Vector) {
        if start < end {
            self.init(unchecked: start, end)
        } else {
            self.init(unchecked: end, start)
        }
    }

    func compare(with plane: Plane) -> PlaneComparison {
        switch (start.compare(with: plane), end.compare(with: plane)) {
        case (.coplanar, .coplanar):
            return .coplanar
        case (.front, .back), (.back, .front):
            return .spanning
        case (.front, _), (_, .front):
            return .front
        case (.back, _), (_, .back):
            return .back
        case (.spanning, _), (_, .spanning):
            preconditionFailure()
        }
    }
}
