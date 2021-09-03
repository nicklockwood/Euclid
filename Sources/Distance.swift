//
//  Distance.swift
//  Euclid
//
//  Created by Ioannis Kaliakatsos on 03.12.2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import Foundation

public struct Distance: AdditiveArithmeticCartesianComponentsRepresentable {
    public let x: Double
    public let y: Double
    public let z: Double

    public init(x: Double = 0, y: Double = 0, z: Double = 0) {
        self.x = x
        self.y = y
        self.z = z
    }
}

public extension Distance {
    static let zero = Distance()
}

public extension Distance {
    var direction: Direction {
        Direction(x: x, y: y, z: z)
    }

    func isParallel(to other: Distance) -> Bool {
        isParallel(to: other.direction)
    }

    func isParallel(to other: Direction) -> Bool {
        direction.isParallel(to: other)
    }

    func isAntiparallel(to other: Distance) -> Bool {
        isAntiparallel(to: other.direction)
    }

    func isAntiparallel(to other: Direction) -> Bool {
        direction.isAntiparallel(to: other)
    }

    func isColinear(to other: Distance) -> Bool {
        isParallel(to: other) || isAntiparallel(to: other)
    }

    func isNormal(to other: Distance) -> Bool {
        isNormal(to: other.direction)
    }

    func isNormal(to other: Direction) -> Bool {
        direction.isNormal(to: other)
    }
}

public extension Distance {
    func cross(_ other: Distance) -> Distance {
        let angle = direction.angle(with: other.direction)
        let newNorm = norm * other.norm * sin(angle)
        let normalDirection = direction.cross(other.direction)
        return newNorm * normalDirection
    }

    func dot(_ direction: Direction) -> Double {
        self.direction.dot(direction) * norm
    }
}

public extension Distance {
    var opposite: Distance {
        -self
    }
}

public extension Distance {
    static func * (lhs: Double, rhs: Distance) -> Distance {
        Distance(
            x: lhs * rhs.x,
            y: lhs * rhs.y,
            z: lhs * rhs.z
        )
    }

    static func / (lhs: Distance, rhs: Double) -> Distance {
        assert(rhs != 0)
        return Distance(
            x: lhs.x / rhs,
            y: lhs.y / rhs,
            z: lhs.z / rhs
        )
    }
}

public extension Distance {
    func projection(on direction: Direction) -> Distance {
        norm * self.direction.dot(direction) * direction
    }

    func normal(to direction: Direction) -> Distance {
        self - projection(on: direction)
    }
}
