//
//  Direction.swift
//  Euclid
//
//  Created by Ioannis Kaliakatsos on 02.12.2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import Foundation

public struct Direction: AdditiveArithmeticCartesianComponentsRepresentable, Hashable {
    public let x: Double
    public let y: Double
    public let z: Double

    public init(x: Double = 0, y: Double = 0, z: Double = 0) {
        let componentsNorm = (x * x + y * y + z * z).squareRoot()
        if componentsNorm != 0 {
            self.x = x / componentsNorm
            self.y = y / componentsNorm
            self.z = z / componentsNorm
        } else {
            self.x = 0
            self.y = 0
            self.z = 0
        }
    }
}

public extension Direction {
    static let zero = Direction()
    static let x = Direction(x: 1)
    static let y = Direction(y: 1)
    static let z = Direction(z: 1)
}

extension Direction: Equatable {
    public static func == (lhs: Direction, rhs: Direction) -> Bool {
        return abs(lhs.x - rhs.x) < tolerance
            && abs(lhs.y - rhs.y) < tolerance
            && abs(lhs.z - rhs.z) < tolerance
    }
}

public extension Direction {
    fileprivate static var tolerance = Double.ulpOfOne.squareRoot()

    func dot(_ other: Direction) -> Double {
        return x * other.x
            + y * other.y
            + z * other.z
    }

    func cross(_ other: Direction) -> Direction {
        return Direction(
            x: y * other.z - z * other.y,
            y: z * other.x - x * other.z,
            z: x * other.y - y * other.x
        )
    }

    func isParallel(to other: Direction) -> Bool {
        return abs(dot(other) - 1) <= Direction.tolerance
    }

    func isAntiparallel(to other: Direction) -> Bool {
        return abs(dot(other) + 1) <= Direction.tolerance
    }

    func isColinear(to other: Direction) -> Bool {
        return isParallel(to: other) || isAntiparallel(to: other)
    }

    func isNormal(to other: Direction) -> Bool {
        return abs(dot(other)) <= Direction.tolerance
    }
}

public extension Direction {
    func angle(with other: Direction) -> Angle {
        return Angle.acos(dot(other))
    }
}

public extension Direction {
    var opposite: Direction {
        return -self
    }
}
