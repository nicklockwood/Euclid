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

    /// Deprecated.
    @available(*, deprecated, renamed: "init(start:end:)")
    public init?(_ start: Vector, _ end: Vector) {
        self.init(start: start, end: end)
    }
}

extension LineSegment: Comparable {
    /// Returns whether the leftmost line segment has the lower value.
    /// This provides a stable order when sorting collections of line segments.
    public static func < (lhs: LineSegment, rhs: LineSegment) -> Bool {
        guard lhs.start == rhs.start else { return lhs.start < rhs.start }
        return lhs.end < rhs.end
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

extension LineSegment: Bounded {
    /// The bounding box containing the line segment.
    public var bounds: Bounds { Bounds(start, end) }
}

public extension LineSegment {
    /// The direction of the line segment as a normalized vector.
    var direction: Vector {
        (end - start).normalized()
    }

    /// The length of the line segment.
    var length: Double {
        (end - start).length
    }

    /// Flip the direction of the line segment
    func inverted() -> LineSegment {
        .init(unchecked: end, start)
    }

    /// Returns a Boolean value that indicates whether the specified point lies on the line segment.
    /// - Parameter point: The point to test.
    /// - Returns: `true` if the point lies on the line segment and `false` otherwise.
    func containsPoint(_ point: Vector) -> Bool {
        guard vectorFromPointToLine(point, start, direction).isZero else {
            return false
        }
        return bounds.inset(by: -epsilon).containsPoint(point)
    }

    /// Returns the point where the specified plane intersects the line segment.
    /// - Parameter plane: The plane to compare with.
    /// - Returns: The point of intersection, or `nil` if the line segment and plane don't intersect.
    func intersection(with plane: Plane) -> Vector? {
        plane.intersection(with: self)
    }

    /// Returns the intersection point between the specified line segment and this one.
    /// - Parameter segment: The line segment to compare with.
    /// - Returns: The point of intersection, or `nil` if the line segments don't intersect.
    func intersection(with segment: LineSegment) -> Vector? {
        lineSegmentsIntersection(start, end, segment.start, segment.end)
    }

    /// Returns a Boolean value that indicates whether two line segements intersect.
    /// - Parameter segment: The line segment to compare with.
    /// - Returns: `true` if the line segments intersect and `false` otherwise.
    func intersects(_ segment: LineSegment) -> Bool {
        intersection(with: segment) != nil
    }
}

extension LineSegment {
    init(unchecked start: Vector, _ end: Vector) {
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
