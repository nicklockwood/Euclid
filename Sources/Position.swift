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
}

public extension Position {
    static let origin = Position()
}

public extension Position {
    var distance: Distance {
        Distance(x, y, z)
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

public extension Position {
    /// Distance of the point from a plane
    /// A positive value is returned if the point lies in front of the plane
    /// A negative value is returned if the point lies behind the plane
    func distance(from plane: Plane) -> Double {
        distance.dot(plane.normal) - plane.w
    }
}
