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
    public let origin: Position
    public let direction: Direction

    /// Creates a line from an origin and direction
    public init(origin: Position, direction: Direction) {
        self.init(unchecked: Vector(origin), direction: direction)
    }
}

extension Line: Codable {
    private enum CodingKeys: CodingKey {
        case origin, direction
    }

    public init(from decoder: Decoder) throws {
        let line: Line
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            line = try Line(
                origin: container.decode(Position.self, forKey: .origin),
                direction: container.decode(Direction.self, forKey: .direction)
            )
            if line.direction.norm < epsilon {
                throw DecodingError.dataCorruptedError(
                    forKey: .direction,
                    in: container,
                    debugDescription: "Line direction must have nonzero length"
                )
            }
        } else {
            var container = try decoder.unkeyedContainer()
            line = try Line(
                origin: Position(from: &container),
                direction: Direction(from: &container)
            )
            if line.direction.norm < epsilon {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Line direction must have nonzero length"
                )
            }
        }
        self = line
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
        distanceFromPointToLine(point, self).norm
    }

    /// Distance of the line from another line
    func distance(from line: Line) -> Double {
        guard let (p0, p1) = shortestLineBetween(
            Vector(origin),
            Vector(origin + 1 * direction),
            Vector(line.origin),
            Vector(line.origin + 1 * line.direction)
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
            Vector(origin),
            Vector(origin + 1 * direction),
            Vector(line.origin),
            Vector(line.origin + 1 * line.direction)
        )
    }

    /// Returns true if the lines intersect
    func intersects(_ line: Line) -> Bool {
        intersection(with: line) != nil
    }
}

internal extension Line {
    #warning("remove")
    init(unchecked origin: Vector, direction: Direction) {
        let distance = Line.distanceAlongLineToFirstValidPlane(origin, direction)
        self.origin = Position(origin) - distance * direction
        self.direction = direction
    }
    
    private static func distanceAlongLineToFirstValidPlane(_ origin: Vector, _ direction: Direction) -> Double {
        if direction.x != 0 {
            return origin.x / direction.x
        }
        
        if direction.y != 0 {
            return origin.y / direction.y
        }
        
        return origin.z / direction.z
    }
}
