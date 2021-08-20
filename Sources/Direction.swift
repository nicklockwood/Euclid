//
//  Direction.swift
//  Euclid
//
//  Created by Ioannis Kaliakatsos on 02.12.2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import Foundation

public struct Direction: AdditiveArithmeticCartesianComponentsRepresentable {
    public let x: Double
    public let y: Double
    public let z: Double

    public init(_ x: Double, _ y: Double, _ z: Double) {
        self.init(x: x, y: y, z: z)
    }
    
    public init(x: Double = 0, y: Double = 0, z: Double = 0) {
        let componentsNorm = (x * x + y * y + z * z).squareRoot()
        if componentsNorm > epsilon {
            self.x = x / componentsNorm
            self.y = y / componentsNorm
            self.z = z / componentsNorm
        } else {
            self.x = 0.0
            self.y = 0.0
            self.z = 0.0
        }
    }
}

public extension Direction {
    init(_ vector: Vector) {
        self.init(x: vector.x, y: vector.y, z: vector.z)
    }
}

public extension Direction {
    static let x = Direction(x: 1)
    static let y = Direction(y: 1)
    static let z = Direction(z: 1)
    static let zero = Direction()
}

public extension Direction {
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
        return abs(dot(other) - 1) <= epsilon
    }

    func isAntiparallel(to other: Direction) -> Bool {
        return abs(dot(other) + 1) <= epsilon
    }

    func isColinear(to other: Direction) -> Bool {
        return isParallel(to: other) || isAntiparallel(to: other)
    }

    func isNormal(to other: Direction) -> Bool {
        return abs(dot(other)) <= epsilon
    }
    
    func quantized() -> Direction {
        Direction(quantize(x), quantize(y), quantize(z))
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

public extension Direction {
    static func * (lhs: Double, rhs: Direction) -> Distance {
        return Distance(
            x: lhs * rhs.x,
            y: lhs * rhs.y,
            z: lhs * rhs.z
        )
    }
}
