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
        guard !start.isEqual(to: end) else {
            return nil
        }
        self.start = start
        self.end = end
    }
}

public extension LineSegment {
    var direction: Vector {
        let d = end - start
        return d.normalized()
    }

    func intersects(_ segment: LineSegment) -> Bool {
        if direction.z == 0, segment.direction.z == 0, start.z == segment.start.z {
            return lineSegmentsIntersect(start, end, segment.start, segment.end)
        } else if direction.y == 0, segment.direction.y == 0, start.y == segment.start.y {
            // Switch dimensions and then solve
            let p0 = Vector(start.x, start.z, 0)
            let p1 = Vector(end.x, end.z, 0)
            let p2 = Vector(segment.start.x, segment.start.z, 0)
            let p3 = Vector(segment.end.x, segment.end.z, 0)
            return lineSegmentsIntersect(p0, p1, p2, p3)
        } else if direction.x == 0, segment.direction.x == 0, start.x == segment.start.x {
            // Switch dimensions and then solve
            let p0 = Vector(start.y, start.z, 0)
            let p1 = Vector(end.y, end.z, 0)
            let p2 = Vector(segment.start.y, segment.start.z, 0)
            let p3 = Vector(segment.end.y, segment.end.z, 0)
            return lineSegmentsIntersect(p0, p1, p2, p3)
        } else {
            // TOOO: Generalize to 3D
            return false
        }
    }
}

internal extension LineSegment {
    init(unchecked start: Vector, _ end: Vector) {
        assert(!start.isEqual(to: end))
        self.start = start
        self.end = end
    }
}
