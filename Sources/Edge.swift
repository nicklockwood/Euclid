//
//  Edge.swift
//  Euclid
//
//  Created by Nick Lockwood on 12/01/2023.
//  Copyright © 2023 Nick Lockwood. All rights reserved.
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

/// A polygon edge.
public struct Edge: Hashable, Sendable {
    /// The starting point of the line segment.
    public let start: Vertex
    /// The end point of the line segment.
    public let end: Vertex

    /// Creates an edge with a start and end vertex.
    /// - Parameters:
    ///   - start: The start of the edge
    ///   - end: The end of the edge
    public init?(_ start: Vertex, _ end: Vertex) {
        guard start != end else {
            return nil
        }
        self.start = start
        self.end = end
    }
}

extension Edge: Comparable {
    /// Returns whether the leftmost edge has the lower value.
    /// This provides a stable order when sorting collections of edges.
    public static func < (lhs: Edge, rhs: Edge) -> Bool {
        guard lhs.start == rhs.start else { return lhs.start < rhs.start }
        return lhs.end < rhs.end
    }
}

extension Edge: Codable {
    private enum CodingKeys: CodingKey {
        case start, end
    }

    /// Creates a new line segment by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            guard let edge = try Edge(
                container.decode(Vertex.self, forKey: .start),
                container.decode(Vertex.self, forKey: .end)
            ) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .end,
                    in: container,
                    debugDescription: "Edge cannot have zero length"
                )
            }
            self = edge
        } else {
            var container = try decoder.unkeyedContainer()
            guard let edge = try Edge(
                container.decode(Vertex.self),
                container.decode(Vertex.self)
            ) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Edge cannot have zero length"
                )
            }
            self = edge
        }
    }

    /// Encodes this line segment into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(start)
        try container.encode(end)
    }
}

public extension Edge {
    /// The direction of the line segment as a normalized vector.
    var direction: Vector {
        (end.position - start.position).normalized()
    }

    /// The length of the line segment.
    var length: Double {
        (end.position - start.position).length
    }

    /// Flip the direction of the line segment
    func inverted() -> Edge {
        .init(unchecked: end, start)
    }

//    /// Returns a Boolean value that indicates whether the specified point lies on the line segment.
//    /// - Parameter point: The point to test.
//    /// - Returns: `true` if the point lies on the line segment and `false` otherwise.
//    func containsPoint(_ point: Vector) -> Bool {
//        let v = vectorFromPointToLine(point, start, direction)
//        guard v.isEqual(to: .zero, withPrecision: epsilon) else {
//            return false
//        }
//        return Bounds(start, end).inset(by: -epsilon).containsPoint(point)
//    }
//
//    /// Returns the intersection point between the specified line segment and this one.
//    /// - Parameter segment: The line segment to compare with.
//    /// - Returns: The point of intersection, or `nil` if the line segments don't intersect.
//    func intersection(with segment: Edge) -> Vector? {
//        lineSegmentsIntersection(start, end, segment.start, segment.end)
//    }
//
//    /// Returns a Boolean value that indicates whether two line segements intersect.
//    /// - Parameter segment: The line segment to compare with.
//    /// - Returns: `true` if the line segments intersect and `false` otherwise.
//    func intersects(_ segment: LineSegment) -> Bool {
//        intersection(with: segment) != nil
//    }
}

extension Edge {
    init(unchecked start: Vertex, _ end: Vertex) {
        assert(start != end)
        self.start = start
        self.end = end
    }

    init(normalized start: Vertex, _ end: Vertex) {
        if start < end {
            self.init(unchecked: start, end)
        } else {
            self.init(unchecked: end, start)
        }
    }

//    func compare(with plane: Plane) -> PlaneComparison {
//        switch (start.compare(with: plane), end.compare(with: plane)) {
//        case (.coplanar, .coplanar):
//            return .coplanar
//        case (.front, .back), (.back, .front):
//            return .spanning
//        case (.front, _), (_, .front):
//            return .front
//        case (.back, _), (_, .back):
//            return .back
//        case (.spanning, _), (_, .spanning):
//            preconditionFailure()
//        }
//    }
}
