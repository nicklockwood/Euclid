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
    public let normal: Direction
    public let w: Double

    /// Creates a plane from a surface normal and a distance from the world origin
    init(normal: Direction, w: Double) {
        self.normal = normal
        self.w = w
    }
}

extension Plane: Comparable {
    /// Provides a stable sort order for Planes
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

    public init(from decoder: Decoder) throws {
        if var container = try? decoder.unkeyedContainer() {
            self.normal = try Direction(from: &container)
            self.w = try container.decode(Double.self)
        } else {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.normal = try container.decode(Direction.self, forKey: .normal)
            self.w = try container.decode(Double.self, forKey: .w)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try normal.encode(to: &container)
        try container.encode(w)
    }
}

public extension Plane {
    static let yz = Plane(normal: .x, w: 0)
    static let xz = Plane(normal: .y, w: 0)
    static let xy = Plane(normal: .z, w: 0)

    /// Creates a plane from a point and surface normal
    init?(normal: Direction, pointOnPlane: Position) {
        guard normal.norm > epsilon else {
            return nil
        }
        self.init(unchecked: normal, pointOnPlane: pointOnPlane)
    }

    /// Generate a plane from a set of coplanar points describing a polygon
    /// The polygon can be convex or concave. The direction of the plane normal is
    /// based on the assumption that the points are wound in an anticlockwise direction
    init?(points: [Position]) {
        self.init(points: points, convex: nil)
    }

    /// Returns the flipside of the plane
    func inverted() -> Plane {
        Plane(normal: -normal, w: -w)
    }

    /// Checks if point is on plane
    func containsPoint(_ p: Position) -> Bool {
        abs(p.distance(from: self)) < epsilon
    }

    /// Distance of the point from a plane
    /// A positive value is returned if the point lies in front of the plane
    /// A negative value is returned if the point lies behind the plane
    func distance(from p: Position) -> Double {
        p.distance.dot(normal) - w
    }

    /// Returns line of intersection between planes
    func intersection(with p: Plane) -> Line? {
        // https://en.wikipedia.org/wiki/Plane_(geometry)#Line_of_intersection_between_two_planes
        guard !normal.isColinear(to: p.normal) else {
            return nil
        }

        // the planes need to be in the Hesse normal form
        // https://en.wikipedia.org/wiki/Hesse_normal_form
        func toHessianNormalForm(_ plane: Plane) -> Plane {
            let isHesseNormalForm = (plane.w * plane.normal)
                .projection(on: plane.normal)
                .direction
                .isParallel(to: plane.normal)

            return isHesseNormalForm
                ? Plane(normal: plane.normal, w: abs(plane.w))
                : Plane(normal: -plane.normal, w: abs(plane.w))
        }

        let p1 = toHessianNormalForm(self)
        let p2 = toHessianNormalForm(p)

        let h1 = p1.w
        let h2 = p2.w

        let dotProduct = p1.normal.dot(p2.normal)
        let denominator = 1 - dotProduct * dotProduct

        let c1 = (h1 - h2 * dotProduct) / denominator
        let c2 = (h2 - h1 * dotProduct) / denominator

        let linePoint = Position.origin + c1 * p1.normal + c2 * p2.normal
        let lineDirection = p1.normal.cross(p2.normal)
        return Line(origin: linePoint, direction: lineDirection)
    }

    /// Returns point intersection between plane and line
    func intersection(with line: Line) -> Position? {
        // https://en.wikipedia.org/wiki/Line–plane_intersection#Algebraic_form
        let lineDirectionDotPlaneNormal = line.direction.dot(normal)
        guard abs(lineDirectionDotPlaneNormal) > epsilon else {
            // Line and plane are parallel
            return nil
        }
        let planePoint = Position.origin + w * normal
        let d = (planePoint - line.origin).dot(normal) / lineDirectionDotPlaneNormal
        let intersection = line.origin + d * line.direction
        return intersection
    }
}

internal extension Plane {
    init(unchecked normal: Direction, pointOnPlane: Position) {
        self.init(normal: normal, w: pointOnPlane.distance.dot(normal))
    }

    init?(points: [Position], convex: Bool?) {
        guard !points.isEmpty, !pointsAreDegenerate(points) else {
            return nil
        }
        self.init(unchecked: points, convex: convex)
        // Check all points lie on this plane
        if points.contains(where: { !containsPoint($0) }) {
            return nil
        }
    }

    init(unchecked points: [Position], convex: Bool?) {
        assert(!pointsAreDegenerate(points))
        let normal = faceNormalForPolygonPoints(points, convex: convex)
        self.init(unchecked: normal, pointOnPlane: points[0])
    }

    // Approximate equality
    func isEqual(to other: Plane, withPrecision p: Double = epsilon) -> Bool {
        abs(w - other.w) < p && normal.isEqual(to: other.normal, withPrecision: p)
    }
}

// An enum of relationships between a group of points and a plane
enum PlaneComparison: Int {
    case coplanar = 0
    case front = 1
    case back = 2
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

    init(normal: Direction) {
        switch (abs(normal.x), abs(normal.y), abs(normal.z)) {
        case let (x, y, z) where x > y && x > z:
            self = .yz
        case let (x, y, z) where x > z || y > z:
            self = .xz
        default:
            self = .xy
        }
    }

    init(points: [Position], convex: Bool?) {
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

    func flattenPoint(_ point: Position) -> Position {
        switch self {
        case .yz: return Position(point.y, point.z)
        case .xz: return Position(point.x, point.z)
        case .xy: return Position(point.x, point.y)
        }
    }
}
