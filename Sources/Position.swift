//
//  PositionVector.swift
//  Euclid
//
//  Created by Ioannis Kaliakatsos on 29.11.2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import Foundation

public struct Position: CartesianComponentsRepresentable {
    public let x: Double
    public let y: Double
    public let z: Double

    public init(x: Double = 0, y: Double = 0, z: Double = 0) {
        self.x = x
        self.y = y
        self.z = z
    }

    public init(_ x: Double, _ y: Double) {
        self.init(x, y, 0)
    }
}

public extension Position {
    static let origin = Position()
}

public extension Position {
    var distance: Distance {
        Distance(x, y, z)
    }

    init(_ distance: Distance) {
        self.init(x: distance.x, y: distance.y, z: distance.z)
    }
}

public extension Position {
    static func + (lhs: Position, rhs: Distance) -> Position {
        Position(
            x: lhs.x + rhs.x,
            y: lhs.y + rhs.y,
            z: lhs.z + rhs.z
        )
    }

    static func - (lhs: Position, rhs: Distance) -> Position {
        Position(
            x: lhs.x - rhs.x,
            y: lhs.y - rhs.y,
            z: lhs.z - rhs.z
        )
    }

    static func - (lhs: Position, rhs: Position) -> Distance {
        Distance(
            x: lhs.x - rhs.x,
            y: lhs.y - rhs.y,
            z: lhs.z - rhs.z
        )
    }
}

internal extension Position {
    func compare(with plane: Plane) -> PlaneComparison {
        let t = distance(from: plane)
        return (t < -epsilon) ? .back : (t > epsilon) ? .front : .coplanar
    }
}

public extension Position {
    /// Distance of the point from a plane
    /// A positive value is returned if the point lies in front of the plane
    /// A negative value is returned if the point lies behind the plane
    func distance(from plane: Plane) -> Double {
        distance.dot(plane.normal) - plane.w
    }

    /// The nearest point to this point on the specified plane
    func project(onto plane: Plane) -> Position {
        let position = self - distance(from: plane) * plane.normal
        return position
    }

    /// Distance of the point from a line in 3D
    func distance(from line: Line) -> Double {
        line.distance(from: self)
    }

    /// The nearest point to this point on the specified line
    func project(onto line: Line) -> Position {
        self + distanceFromPointToLine(self, line)
    }

    func translated(by v: Distance) -> Position {
        Position(x + v.x, y + v.y, z + v.z)
    }

    func transformed(by t: Transform) -> Self {
        scaled(by: t.scale).rotated(by: t.rotation).translated(by: t.offset)
    }
}
