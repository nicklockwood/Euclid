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

/// An infinite 2D plane in 3D space.
public struct Plane: Hashable {
    /// A surface normal vector, perpendicular to the plane.
    public let normal: Vector
    /// The perpendicular distance from the world origin to the plane.
    public let w: Double

    /// Creates a plane from a surface normal and a distance from the world origin.
    /// - Parameters:
    ///   - normal: The surface normal of the plane.
    ///   - w: The perpendicular distance from the world origin to the plane.
    init?(normal: Vector, w: Double) {
        let length = normal.length
        guard length.isFinite, length > epsilon else {
            return nil
        }
        self.init(unchecked: normal / length, w: w)
    }
}

extension Plane: Comparable {
    /// Returns whether the leftmost plane has the lower value.
    /// This provides a stable order when sorting collections of planes.
    public static func < (lhs: Plane, rhs: Plane) -> Bool {
        if lhs.normal == rhs.normal {
            return lhs.w < rhs.w
        }
        return lhs.normal < rhs.normal
    }
}

extension Plane: Codable {
    private enum CodingKeys: CodingKey {
        case normal, w
    }

    /// Creates a new plane by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        if var container = try? decoder.unkeyedContainer() {
            self.normal = try Vector(from: &container).normalized()
            self.w = try container.decode(Double.self)
        } else {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.normal = try container.decode(Vector.self, forKey: .normal).normalized()
            self.w = try container.decode(Double.self, forKey: .w)
        }
    }

    /// Encodes this plane into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try normal.encode(to: &container)
        try container.encode(w)
    }
}

public extension Plane {
    /// A plane located at the origin, aligned with the Y and Z axes.
    static let yz = Plane(unchecked: Vector(1, 0, 0), w: 0)
    /// A plane located at the origin, aligned with the X and Z axes.
    static let xz = Plane(unchecked: Vector(0, 1, 0), w: 0)
    /// A plane located at the origin, aligned with the X and Y axes.
    static let xy = Plane(unchecked: Vector(0, 0, 1), w: 0)

    /// Creates a plane from a point and surface normal.
    /// - Parameters:
    ///   - normal: The surface normal of the plane.
    ///   - pointOnPlane: An arbitrary point on the plane.
    init?(normal: Vector, pointOnPlane: Vector) {
        let length = normal.length
        guard length.isFinite, length > epsilon else {
            return nil
        }
        self.init(unchecked: normal / length, pointOnPlane: pointOnPlane)
    }

    /// Creates a plane from a set of points.
    /// - Parameter points: A set of coplanar points describing a polygon.
    ///
    /// > Note: The polygon can be convex or concave. The direction of the plane normal is
    /// based on the assumption that the points are wound in an anti-clockwise direction.
    init?(points: [Vector]) {
        self.init(points: points, convex: nil)
    }

    /// Returns the flip-side of the plane.
    func inverted() -> Plane {
        Plane(unchecked: -normal, w: -w)
    }

    /// Returns a Boolean value that indicates whether a point lies on the plane.
    /// - Parameter point: The point to test.
    /// - Returns: `true` if the point lies on the plane and `false` otherwise.
    func containsPoint(_ point: Vector) -> Bool {
        abs(point.distance(from: self)) < epsilon
    }

    /// Returns the distance between a point and the plane.
    /// - Parameter point: The point to compare with.
    /// - Returns: The distance between the point and the plane. The value is positive if the point lies
    ///   in front of the plane, and negative if behind.
    func distance(from point: Vector) -> Double {
        normal.dot(point) - w
    }

    /// Computes the line of intersection between two planes.
    /// - Parameter plane: The plane to compare with.
    /// - Returns: The line of intersection between the planes, or `nil` if the planes are parallel.
    func intersection(with plane: Plane) -> Line? {
        guard !normal.isEqual(to: plane.normal),
              let origin = solveSimultaneousEquationsWith(self, plane)
        else {
            // Planes do not intersect
            return nil
        }
        return Line(origin: origin, direction: normal.cross(plane.normal))
    }

    /// Computes the point of intersection between a line and a place.
    /// - Parameter line: The ``Line`` to compare with.
    /// - Returns: The point of intersection between the line and plane, or `nil` if they are parallel.
    func intersection(with line: Line) -> Vector? {
        // https://en.wikipedia.org/wiki/Line–plane_intersection#Algebraic_form
        let lineDotPlaneNormal = line.direction.dot(normal)
        guard abs(lineDotPlaneNormal) > epsilon else {
            // Line and plane are parallel
            return nil
        }
        let planePoint = normal * w
        let d = (planePoint - line.origin).dot(normal) / lineDotPlaneNormal
        let intersection = line.origin + line.direction * d
        return intersection
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

    init?(points: [Vector], convex: Bool?) {
        guard !points.isEmpty, !pointsAreDegenerate(points) else {
            return nil
        }
        self.init(unchecked: points, convex: convex)
        // Check all points lie on this plane
        if points.contains(where: { !containsPoint($0) }) {
            return nil
        }
    }

    init(unchecked points: [Vector], convex: Bool?) {
        assert(!pointsAreDegenerate(points))
        let normal = faceNormalForPolygonPoints(points, convex: convex)
        self.init(unchecked: normal, pointOnPlane: points[0])
    }

    // Approximate equality
    func isEqual(to other: Plane, withPrecision p: Double = epsilon) -> Bool {
        abs(w - other.w) < p && normal.isEqual(to: other.normal, withPrecision: p)
    }
}

/// The relationship between a group of points and a plane.
enum PlaneComparison: Int {
    /// The values all reside on the same plane.
    case coplanar = 0
    /// The values reside in front of the plane.
    case front = 1
    /// The values reside behind the plane.
    case back = 2
    /// The values span both the front and back of the plane.
    case spanning = 3

    func union(_ other: PlaneComparison) -> PlaneComparison {
        PlaneComparison(rawValue: rawValue | other.rawValue)!
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

    init(normal: Vector) {
        switch (abs(normal.x), abs(normal.y), abs(normal.z)) {
        case let (x, y, z) where x > y && x > z:
            self = .yz
        case let (x, y, z) where x > z || y > z:
            self = .xz
        default:
            self = .xy
        }
    }

    init(points: [Vector], convex: Bool?) {
        self.init(normal: faceNormalForPolygonPoints(points, convex: convex))
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
