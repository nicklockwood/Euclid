//
//  AdditiveArithmeticCartesianComponentsRepresentable.swift
//  Euclid
//
//  Created by Ioannis Kaliakatsos on 02.12.2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import Foundation

public protocol AdditiveArithmeticCartesianComponentsRepresentable: CartesianComponentsRepresentable {}

public extension AdditiveArithmeticCartesianComponentsRepresentable {
    static func + (lhs: Self, rhs: Self) -> Self {
        return Self(
            x: lhs.x + rhs.x,
            y: lhs.y + rhs.y,
            z: lhs.z + rhs.z
        )
    }

    static func - (lhs: Self, rhs: Self) -> Self {
        return Self(
            x: lhs.x - rhs.x,
            y: lhs.y - rhs.y,
            z: lhs.z - rhs.z
        )
    }
    
    /// Linearly interpolate between two vectors
    func lerp(_ a: Self, _ t: Double) -> Self {
        return Self(x: x + (a.x - x) * t,
                    y: y + (a.y - y) * t,
                    z: z + (a.z - z) * t)
    }
}

internal extension AdditiveArithmeticCartesianComponentsRepresentable {
    // Approximate equality
    func isEqual(to other: Self, withPrecision p: Double = epsilon) -> Bool {
        self == other ||
            (abs(x - other.x) < p && abs(y - other.y) < p && abs(z - other.z) < p)
    }
}
