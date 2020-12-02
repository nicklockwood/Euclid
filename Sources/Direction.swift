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
}
