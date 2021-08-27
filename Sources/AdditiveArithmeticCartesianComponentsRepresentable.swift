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
        Self(
            x: lhs.x + rhs.x,
            y: lhs.y + rhs.y,
            z: lhs.z + rhs.z
        )
    }

    static func - (lhs: Self, rhs: Self) -> Self {
        Self(
            x: lhs.x - rhs.x,
            y: lhs.y - rhs.y,
            z: lhs.z - rhs.z
        )
    }
}
