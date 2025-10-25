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
        guard let direction = normal.direction else {
            return nil
        }
        self.init(unchecked: direction, w: w)
    }
}

extension Plane: CustomDebugStringConvertible, CustomReflectable {
    public var debugDescription: String {
        "Plane(normal: \(normal.components), w: \(w))"
    }

    public var customMirror: Mirror {
        Mirror(self, children: [:], displayStyle: .struct)
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

    /// The closest point on the plane to the world origin.
    var origin: Vector {
        normal * w
    }

    /// Creates a plane from a point and surface normal.
    /// - Parameters:
    ///   - normal: The surface normal of the plane.
    ///   - pointOnPlane: An arbitrary point on the plane.
    init?(normal: Vector, pointOnPlane: Vector) {
        guard let direction = normal.direction else {
            return nil
        }
        self.init(unchecked: direction, pointOnPlane: pointOnPlane)
    }

    /// Creates a plane from a set of points.
    /// - Parameter points: A set of coplanar points describing a polygon.
    ///
    /// > Note: The polygon can be convex or concave. The direction of the plane normal is
    /// based on the assumption that the points are wound in an anti-clockwise direction.
    init?(points: [Vector]) {
        guard !points.isEmpty else {
            return nil
        }
        self.init(unchecked: points)
        // Check all points lie on this plane
        // Note: can't assume that even 3 points will form a valid/precise triangle
        if !points.allSatisfy(intersects) {
            return nil
        }
    }

    /// Returns the flip-side of the plane.
    func inverted() -> Plane {
        Plane(unchecked: -normal, w: -w)
    }

    /// Deprecated.
    @available(*, deprecated, renamed: "intersects(_:)")
    func containsPoint(_ point: Vector) -> Bool {
        intersects(point)
    }

    /// Returns the signed distance between the plane and a `PlaneComparable` object.
    /// - Parameter object: The object to compare with.
    /// - Returns: The distance between the object and the plane. The value will be positive if the object lies
    ///   in front of the plane, negative if it lies behind it, or zero if it lies exactly on the plane, or crosses it.
    func signedDistance(from object: some PlaneComparable) -> Double {
        object.signedDistance(from: self)
    }

    /// Returns the absolute distance between the plane and a `PlaneComparable` object.
    /// - Parameter object: The object to compare with.
    /// - Returns: The absolute distance between the object and the plane. The value will be
    ///   positive if the object lies in front or behind the plane, or zero if they intersect.
    func distance(from object: some PlaneComparable) -> Double {
        object.distance(from: self)
    }

    /// Determines if the plane intersects a `PlaneComparable` object.
    /// - Parameter object: The object to compare with.
    /// - Returns: `true` if the plane intersects the object, and `false` otherwise.
    func intersects(_ object: some PlaneComparable) -> Bool {
        object.intersects(self)
    }

    /// Computes the line of intersection between two planes.
    /// - Parameter plane: The plane to compare with.
    /// - Returns: The line of intersection between the planes, or `nil` if the planes are parallel.
    func intersection(with plane: Plane) -> Line? {
        if isParallel(to: plane) || isAntiparallel(to: plane) {
            return nil
        }

        let n1 = normal.components
        let n2 = plane.normal.components

        // http://geomalgorithms.com/a05-_intersect-1.html
        func findCommonPoint(_ a: Int, _ b: Int) -> Vector {
            let a1 = n1[a], b1 = n1[b]
            let a2 = n2[a], b2 = n2[b]

            var result: [Double] = [0, 0, 0]
            result[a] = (b2 * w - b1 * plane.w) / (a1 * b2 - a2 * b1)
            result[b] = (a1 * plane.w - a2 * w) / (a1 * b2 - a2 * b1)

            return Vector(result)
        }

        let origin: Vector
        let direction = normal.cross(plane.normal)
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
        line.intersection(with: self)
    }

    /// Computes the point of intersection between a line segment and a plane.
    /// - Parameter segment: The ``LineSegment`` to compare with.
    /// - Returns: The point of intersection between the line segment and plane, or `nil` if they do not intersect.
    func intersection(with segment: LineSegment) -> Vector? {
        segment.intersection(with: self)
    }
}

extension Plane {
    init(unchecked normal: Vector, w: Double) {
        assert(normal.isNormalized)
        self.normal = normal
        self.w = w
    }

    init(unchecked normal: Vector, pointOnPlane: Vector) {
        self.init(unchecked: normal, w: normal.dot(pointOnPlane))
    }

    /// Points are assumed to be ordered in a counter-clockwise direction
    /// Points are assumed to be coplanar
    init(unchecked points: [Vector]) {
        let normal = faceNormalForPoints(points)
        self.init(unchecked: normal, pointOnPlane: points.centroid)
    }

    func signedPerpendicularDistance(from plane: Plane) -> Double? {
        if isParallel(to: plane) {
            return w - plane.w
        } else if isAntiparallel(to: plane) {
            return -w - plane.w
        }
        return nil
    }

    func isParallel(to plane: Plane, absoluteTolerance: Double = planeEpsilon) -> Bool {
        normal.isApproximatelyEqual(to: plane.normal, absoluteTolerance: absoluteTolerance)
    }

    func isAntiparallel(to plane: Plane, absoluteTolerance: Double = planeEpsilon) -> Bool {
        normal.isApproximatelyEqual(to: -plane.normal, absoluteTolerance: absoluteTolerance)
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
        self.init(rawValue: .init(unchecked: normal.mostParallelAxis, w: 0))!
    }

    init(points: [Vector]) {
        self.init(normal: faceNormalForPoints(points))
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
        case .yz: return [point.y, point.z]
        case .xz: return [point.x, point.z]
        case .xy: return [point.x, point.y]
        }
    }
}
