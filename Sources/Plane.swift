//
//  Plane.swift
//  Euclid
//
//  Created by Nick Lockwood on 03/07/2018.
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

/// Represents a 2D plane in 3D space.
public struct Plane: Hashable {
    public let normal: Vector
    public let w: Double

    /// Creates a plane from a surface normal and a distance from the world origin
    init?(normal: Vector, w: Double) {
        let length = normal.length
        guard length.isFinite, length > epsilon else {
            return nil
        }
        self.init(unchecked: normal / length, w: w)
    }
}

extension Plane: Codable {
    private enum CodingKeys: CodingKey {
        case normal, w
    }

    public init(from decoder: Decoder) throws {
        if var container = try? decoder.unkeyedContainer() {
            let x = try container.decode(Double.self)
            let y = try container.decode(Double.self)
            let z = try container.decode(Double.self)
            normal = Vector(x, y, z).normalized()
            w = try container.decode(Double.self)
        } else {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            normal = try container.decode(Vector.self, forKey: .normal).normalized()
            w = try container.decode(Double.self, forKey: .w)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(normal.x)
        try container.encode(normal.y)
        try container.encode(normal.z)
        try container.encode(w)
    }
}

public extension Plane {
    static let yz = Plane(unchecked: Vector(1, 0, 0), w: 0)
    static let xz = Plane(unchecked: Vector(0, 1, 0), w: 0)
    static let xy = Plane(unchecked: Vector(0, 0, 1), w: 0)

    /// Creates a plane from a point and surface normal
    init?(normal: Vector, pointOnPlane: Vector) {
        let length = normal.length
        guard length.isFinite, length > epsilon else {
            return nil
        }
        self.init(unchecked: normal / length, pointOnPlane: pointOnPlane)
    }

    /// Generate a plane from a set of coplanar points describing a polygon
    /// The polygon can be convex or concave. The direction of the plane normal is
    /// based on the assumption that the points are wound in an anticlockwise direction
    init?(points: [Vector]) {
        guard let first = points.first else {
            return nil
        }
        if points.count > 3, !pointsAreDegenerate(points) {
            self.init(unchecked: points)
            // Check all points lie on this plane
            if points.contains(where: { !containsPoint($0) }) {
                return nil
            }
        } else {
            let normal = faceNormalForConvexPoints(points)
            self.init(normal: normal, pointOnPlane: first)
        }
    }

    /// Returns the flipside of the plane
    func inverted() -> Plane {
        return Plane(unchecked: -normal, w: -w)
    }

    /// Checks if point is on plane
    func containsPoint(_ p: Vector) -> Bool {
        return abs(p.distance(from: self)) < epsilon
    }

    /// Returns line of intersection between planes
    func intersection(with p: Plane) -> Line? {
        guard !normal.isEqual(to: p.normal),
              let origin = solveSimultaneousEquationsWith(self, p)
        else {
            // Planes do not intersect
            return nil
        }
        return Line(origin: origin, direction: normal.cross(p.normal))
    }
}

internal extension Plane {
    init(unchecked normal: Vector, w: Double) {
        assert(normal.isNormalized)
        self.normal = normal
        self.w = w
    }

    init(unchecked normal: Vector, pointOnPlane: Vector) {
        self.init(unchecked: normal, w: normal.dot(pointOnPlane))
    }

    init(unchecked points: [Vector], convex: Bool? = nil) {
        assert(!pointsAreDegenerate(points))
        var normal = faceNormalForConvexPoints(points)
        let convex = convex ?? pointsAreConvex(points)
        if !convex {
            let flatteningPlane = FlatteningPlane(points: points)
            let flattenedPoints = points.map { flatteningPlane.flattenPoint($0) }
            let flattenedNormal = faceNormalForConvexPoints(flattenedPoints)
            let isClockwise = flattenedPointsAreClockwise(flattenedPoints)
            if (flattenedNormal.z > 0) == isClockwise {
                normal = -normal
            }
        }
        self.init(unchecked: normal, pointOnPlane: points[0])
    }

    // Approximate equality
    func isEqual(to other: Plane, withPrecision p: Double = epsilon) -> Bool {
        return abs(w - other.w) < p && normal.isEqual(to: other.normal, withPrecision: p)
    }
}

// An enum of relationships between a group of points and a plane
enum PlaneComparison: Int {
    case coplanar = 0
    case front = 1
    case back = 2
    case spanning = 3

    func union(_ other: PlaneComparison) -> PlaneComparison {
        return PlaneComparison(rawValue: rawValue | other.rawValue)!
    }
}

// An enum of planes along the X, Y and Z axes
// Used internally for flattening 3D paths and polygons
enum FlatteningPlane: RawRepresentable {
    case xy, xz, yz

    var rawValue: Plane {
        switch self {
        case .xy: return .xy
        case .xz: return .xz
        case .yz: return .yz
        }
    }

    init(bounds: Bounds) {
        let size = bounds.size
        if size.x > size.y {
            self = size.z > size.y ? .xz : .xy
        } else {
            self = size.z > size.x ? .yz : .xy
        }
    }

    init(normal: Vector) {
        switch (abs(normal.x), abs(normal.y), abs(normal.z)) {
        case let (x, y, z) where x > y && x > z:
            self = .yz
        case let (x, y, z) where y > x && y > z:
            self = .xz
        default:
            self = .xy
        }
    }

    init(points: [Vector]) {
        self.init(bounds: Bounds(points: points))
    }

    init?(rawValue: Plane) {
        switch rawValue {
        case .xy: self = .xy
        case .xz: self = .xz
        case .yz: self = .yz
        default: return nil
        }
    }

    func flattenPoint(_ point: Vector) -> Vector {
        switch self {
        case .yz: return Vector(point.y, point.z)
        case .xz: return Vector(point.x, point.z)
        case .xy: return Vector(point.x, point.y)
        }
    }
}

// Solve simultaneous equations using Gaussian elimination
// http://mathsfirst.massey.ac.nz/Algebra/SystemsofLinEq/EMeth.htm
private func performGaussianElimination(v1: Vector, w1: Double, v2: Vector, w2: Double) -> Vector? {
    if v1.x == 0 {
        return nil
    }

    // Assume z = 0 always

    // Multiply the two equations until they have an equal leading coefficient
    let n1 = v1 * v2.x
    let n2 = v2 * v1.x
    let ww1 = w1 * v2.x
    let ww2 = w2 * v1.x

    // Subtract the second from the first
    let diff = n1 - n2
    let wdiff = ww1 - ww2

    // Solve this new equation for y:
    // diff.y * y = wdiff
    if diff.y == 0 {
        return nil
    }
    let y = wdiff / diff.y

    // Substitute this back in to the first equation
    // self.normal.x * x + self.normal.y * y = self.w
    // self.normal.x * x = self.w - self.normal.y * y
    // x = (self.w - self.normal.y * y) / self.normal.x
    let x = (w1 - v1.y * y) / v1.x

    return Vector(x, y, 0)
}

// Try all the permutations of the equations we could solve until we find a solvable combination
private func solveSimultaneousEquationsWith(_ p1: Plane, _ p2: Plane) -> Vector? {
    let n1 = p1.normal.components, n2 = p2.normal.components
    for i in 0 ... 2 {
        for j in 0 ... 2 where i != j {
            for k in 0 ... 2 where i != k && j != k {
                let v1 = Vector(n1[i], n1[j], n1[k]), v2 = Vector(n2[i], n2[j], n2[k])
                if let point = performGaussianElimination(v1: v1, w1: p1.w, v2: v2, w2: p2.w) {
                    let n = point.components
                    // Rotate the variables back in to their proper place
                    return Vector(n[i], n[j], n[k])
                }
            }
        }
    }
    return nil
}
