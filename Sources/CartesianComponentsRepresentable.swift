//
//  CartesianComponentsRepresentable.swift
//  Euclid
//
//  Created by Ioannis Kaliakatsos on 29.11.2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import Foundation

public protocol CartesianComponentsRepresentable {
    var x: Double { get }
    var y: Double { get }
    var z: Double { get }
    init(x: Double, y: Double, z: Double)
}

public func + <T: CartesianComponentsRepresentable>(lhs: T, rhs: T) -> T {
    return T(
        x: lhs.x + rhs.x,
        y: lhs.y + rhs.y,
        z: lhs.z + rhs.z
    )
}
