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
public struct Plane: Hashable, Sendable {
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
    static let yz = Plane(unchecked: .unitX, w: 0)
    /// A plane located at the origin, aligned with the X and Z axes.
    static let xz = Plane(unchecked: .unitY, w: 0)
    /// A plane located at the origin, aligned with the X and Y axes.
    static let xy = Plane(unchecked: .unitZ, w: 0)

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
        self.init(points: points, convex: nil, closed: nil)
    }

    /// Returns the flip-side of the plane.
    func inverted() -> Plane {
        Plane(unchecked: -normal, w: -w)
    }

    /// Returns a Boolean value that indicates whether a point lies on the plane.
    /// - Parameter point: The point to test.
    /// - Returns: `true` if the point lies on the plane and `false` otherwise.
    func containsPoint(_ point: Vector) -> Bool {
        abs(point.distance(from: self)) < planeEpsilon
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
    func intersection(with p: Plane) -> Line? {
        let direction = normal.cross(p.normal)
        guard direction.length > epsilon else {
            // Planes are parallel
            return nil
        }

        let n1 = normal.components
        let n2 = p.normal.components

        // http://geomalgorithms.com/a05-_intersect-1.html
        func findCommonPoint(_ a: Int, _ b: Int) -> Vector {
            let a1 = n1[a], b1 = n1[b]
            let a2 = n2[a], b2 = n2[b]

            var result: [Double] = [0, 0, 0]
            result[a] = (b2 * w - b1 * p.w) / (a1 * b2 - a2 * b1)
            result[b] = (a1 * p.w - a2 * w) / (a1 * b2 - a2 * b1)

            return Vector(result)
        }

        let origin: Vector
        if abs(direction.z) >= abs(direction.x), abs(direction.z) >= abs(direction.y) {
            origin = findCommonPoint(0, 1)
        } else if abs(direction.y) >= abs(direction.z), abs(direction.y) >= abs(direction.x) {
            origin = findCommonPoint(2, 0)
        } else {
            origin = findCommonPoint(1, 2)
        }

        return Line(origin: origin, direction: direction)
    }

    /// Computes the point of intersection between a line and a plane.
    /// - Parameter line: The ``Line`` to compare with.
    /// - Returns: The point of intersection between the line and plane, or `nil` if they are parallel.
    func intersection(with line: Line) -> Vector? {
        linePlaneIntersection(line.origin, line.direction, self).map {
            line.origin + line.direction * $0
        }
    }

    /// Computes the point of intersection between a line segment and a plane.
    /// - Parameter line: The ``LineSegment`` to compare with.
    /// - Returns: The point of intersection between the line segment and plane, or `nil` if they do not intersect.
    func intersection(with segment: LineSegment) -> Vector? {
        linePlaneIntersection(segment.start, segment.direction, self).flatMap {
            $0 >= 0 && $0 <= segment.length ? segment.start + segment.direction * $0 : nil
        }
    }
}

extension Plane {
    init(unchecked normal: Vector, w: Double) {
        self.normal = normal.normalized()
        self.w = w
    }

    init(unchecked normal: Vector, pointOnPlane: Vector) {
        self.init(unchecked: normal, w: normal.dot(pointOnPlane))
    }

    init?(points: [Vector], convex: Bool?, closed: Bool?) {
        guard !points.isEmpty, !pointsAreDegenerate(points) else {
            return nil
        }
        self.init(unchecked: points, convex: convex, closed: closed)
        // Check all points lie on this plane
        if points.count > 3, points.contains(where: { !containsPoint($0) }) {
            return nil
        }
    }

    init(unchecked points: [Vector], convex: Bool?, closed: Bool?) {
        assert(!pointsAreDegenerate(points))
        let normal = faceNormalForPolygonPoints(points, convex: convex, closed: closed)
        self.init(unchecked: normal, pointOnPlane: points[0])
    }

    /// Approximate equality
    func isEqual(to other: Plane, withPrecision p: Double = planeEpsilon) -> Bool {
        w.isEqual(to: other.w, withPrecision: p) &&
            normal.isEqual(to: other.normal, withPrecision: p)
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

/// An enum of planes along the X, Y and Z axes
/// Used internally for flattening 3D paths and polygons
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

    init(points: [Vector]) {
        self.init(normal: faceNormalForPolygonPoints(
            points, convex: nil, closed: nil
        ))
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
