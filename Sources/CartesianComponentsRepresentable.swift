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

public extension CartesianComponentsRepresentable {
    var norm: Double {
        return (x * x + y * y + z * z).squareRoot()
    }
}
