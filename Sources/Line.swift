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

import Foundation

public struct LineSegment : Hashable {
    public init(_ point1: Vector, _ point2: Vector) {
        self.point1 = point1
        self.point2 = point2
    }
    
    public var point1: Vector {
        didSet { point1 = point1.quantized() }
    }
    
    public var point2: Vector {
        didSet { point2 = point2.quantized() }
    }
    
    public var direction : Vector {
        let diff = point2 - point1
        return diff.normalized()
    }
    
    public func intersects(with: LineSegment) -> Bool {
        if ((self.direction.z == 0) && (with.direction.z == 0) && (self.point1.z == with.point1.z)) {
            return lineSegmentsIntersect(self.point1, self.point2, with.point1, with.point2)
        } else if ((self.direction.y == 0) && (with.direction.y == 0) && (self.point1.y == with.point1.y)) {
            // Switch dimensions and then solve
            let p0 = Vector(self.point1.x, self.point1.z, 0)
            let p1 = Vector(self.point2.x, self.point2.z, 0)
            let p2 = Vector(with.point1.x, with.point1.z, 0)
            let p3 = Vector(with.point2.x, with.point2.z, 0)
            return lineSegmentsIntersect(p0, p1, p2, p3)
        } else if ((self.direction.x == 0) && (with.direction.x == 0) && (self.point1.x == with.point1.x)) {
            // Switch dimensions and then solve
            let p0 = Vector(self.point1.y, self.point1.z, 0)
            let p1 = Vector(self.point2.y, self.point2.z, 0)
            let p2 = Vector(with.point1.y, with.point1.z, 0)
            let p3 = Vector(with.point2.y, with.point2.z, 0)
            return lineSegmentsIntersect(p0, p1, p2, p3)
        } else {
            // TOOO: Generalize to 3D
            return false;
        }
    }
}

public struct Line : Hashable {
    public init(point: Vector, direction: Vector) {
        self.point = point
        self.direction = direction
    }
    
    public init(from: LineSegment) {
        self.point = from.point1
        self.direction = from.direction
    }
    
    public var point: Vector {
        didSet { point = point.quantized() }
    }

    public var direction: Vector {
        didSet { direction = direction.normalized() }
    }
    
    public func distance(to: Vector) -> Double {
        // See "Vector formulation" at https://en.wikipedia.org/wiki/Distance_from_a_point_to_a_line
        let aMinusP = self.point - to
        let v = aMinusP - (self.direction * aMinusP.dot(self.direction))
        return v.length
    }
    
    public func intersection(with: Line) -> Vector? {
        if ((self.direction.z == 0) && (with.direction.z == 0) && (self.point.z == with.point.z)) {
            return lineIntersection(self.point, self.point + self.direction, with.point, with.point + with.direction)
        } else if ((self.direction.y == 0) && (with.direction.y == 0) && (self.point.y == with.point.y)) {
            // Switch dimensions and then solve
            let p0 = Vector(self.point.x, self.point.z, self.point.y)
            let p1 = p0 + Vector(self.direction.x, self.direction.z, 0)
            let p2 = Vector(with.point.x, with.point.z, with.point.y)
            let p3 = p2 + Vector(with.direction.x, with.direction.z, 0)
            let solution = lineIntersection(p0, p1, p2, p3)
            if (solution != nil) {
                return Vector(solution!.x, solution!.z, solution!.y)
            } else {
                return nil;
            }
        } else if ((self.direction.x == 0) && (with.direction.x == 0) && (self.point.x == with.point.x)) {
            // Switch dimensions and then solve
            let p0 = Vector(self.point.y, self.point.z, self.point.x)
            let p1 = p0 + Vector(self.direction.y, self.direction.z, 0)
            let p2 = Vector(with.point.y, with.point.z, with.point.x)
            let p3 = p2 + Vector(with.direction.y, with.direction.z, 0)
            let solution = lineIntersection(p0, p1, p2, p3)
            if (solution != nil) {
                return Vector(solution!.z, solution!.x, solution!.y)
            } else {
                return nil;
            }
        } else {
            // TOOO: Generalize to 3D
            return nil;
        }
    }
}

// MARK: Private utility functions

// Get the intersection point between two lines
// TODO: extend this to work in 3D
// TODO: improve this using https://en.wikipedia.org/wiki/Line–line_intersection
private func lineIntersection(_ p0: Vector, _ p1: Vector,
                              _ p2: Vector, _ p3: Vector) -> Vector? {
    let x1 = p0.x, y1 = p0.y
    let x2 = p1.x, y2 = p1.y
    let x3 = p2.x, y3 = p2.y
    let x4 = p3.x, y4 = p3.y

    let x1y2 = x1 * y2, y1x2 = y1 * x2
    let x1y2minusy1x2 = x1y2 - y1x2

    let x3minusx4 = x3 - x4
    let x1minusx2 = x1 - x2

    let x3y4 = x3 * y4, y3x4 = y3 * x4
    let x3y4minusy3x4 = x3y4 - y3x4

    let y3minusy4 = y3 - y4
    let y1minusy2 = y1 - y2

    let d = x1minusx2 * y3minusy4 - y1minusy2 * x3minusx4
    if abs(d) < epsilon {
        return nil // lines are parallel
    }
    let ix = (x1y2minusy1x2 * x3minusx4 - x1minusx2 * x3y4minusy3x4) / d
    let iy = (x1y2minusy1x2 * y3minusy4 - y1minusy2 * x3y4minusy3x4) / d

    return Vector(ix, iy, p0.z).quantized()
}

// TODO: extend this to work in 3D
private func lineSegmentsIntersect(_ p0: Vector, _ p1: Vector,
                                   _ p2: Vector, _ p3: Vector) -> Bool {
    guard let pi = lineIntersection(p0, p1, p2, p3) else {
        return false // lines are parallel
    }
    // TODO: is there a cheaper way to do this?
    if pi.x < min(p0.x, p1.x) || pi.x > max(p0.x, p1.x) ||
        pi.x < min(p2.x, p3.x) || pi.x > max(p2.x, p3.x) ||
        pi.y < min(p0.y, p1.y) || pi.y > max(p0.y, p1.y) ||
        pi.y < min(p2.y, p3.y) || pi.y > max(p2.y, p3.y) {
        return false
    }
    return true
}
