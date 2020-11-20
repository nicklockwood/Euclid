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

public struct Line: Hashable, Codable {
    public let origin, direction: Vector

    /// Creates a line from an origin and direction
    public init?(origin: Vector, direction: Vector) {
        let length = direction.length
        guard length.isFinite, length > epsilon else {
            return nil
        }
        self.origin = origin
        self.direction = direction / length
    }
}

public extension Line {
    init(_ segment: LineSegment) {
        self.init(unchecked: segment.start, direction: segment.direction)
    }

    func distance(from point: Vector) -> Double {
        // See "Vector formulation" at https://en.wikipedia.org/wiki/Distance_from_a_point_to_a_line
        let d = point - origin
        let v = d - (direction * d.dot(direction))
        return v.length
    }

    func intersection(with: Line) -> Vector? {
        if direction.z == 0, with.direction.z == 0, origin.z == with.origin.z {
            return lineIntersection(origin, origin + direction, with.origin, with.origin + with.direction)
        } else if direction.y == 0, with.direction.y == 0, origin.y == with.origin.y {
            // Switch dimensions and then solve
            let p0 = Vector(origin.x, origin.z, origin.y)
            let p1 = p0 + Vector(direction.x, direction.z, 0)
            let p2 = Vector(with.origin.x, with.origin.z, with.origin.y)
            let p3 = p2 + Vector(with.direction.x, with.direction.z, 0)
            let solution = lineIntersection(p0, p1, p2, p3)
            return solution.map { Vector($0.x, $0.z, $0.y) }
        } else if direction.x == 0, with.direction.x == 0, origin.x == with.origin.x {
            // Switch dimensions and then solve
            let p0 = Vector(origin.y, origin.z, origin.x)
            let p1 = p0 + Vector(direction.y, direction.z, 0)
            let p2 = Vector(with.origin.y, with.origin.z, with.origin.x)
            let p3 = p2 + Vector(with.direction.y, with.direction.z, 0)
            let solution = lineIntersection(p0, p1, p2, p3)
            return solution.map { Vector($0.z, $0.x, $0.y) }
        } else {
            // TODO: Generalize to 3D
            return nil
        }
    }
}

internal extension Line {
    init(unchecked origin: Vector, direction: Vector) {
        assert(direction.isNormalized)
        self.origin = origin
        self.direction = direction
    }
}
