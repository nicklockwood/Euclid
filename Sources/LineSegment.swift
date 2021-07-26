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

public struct LineSegment: Hashable, Codable {
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

public extension LineSegment {
    var direction: Vector {
        (end - start).normalized()
    }

    /// Check if point is on line segment
    func containsPoint(_ p: Vector) -> Bool {
        let v = vectorFromPointToLine(p, start, direction)
        guard v.length < epsilon else {
            return false
        }
        let p = p + v
        return p.x >= min(start.x, end.x) && p.x <= max(start.x, end.x) &&
            p.y >= min(start.y, end.y) && p.y <= max(start.y, end.y) &&
            p.z >= min(start.z, end.z) && p.z <= max(start.z, end.z)
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
