//
//  Angle.swift
//  Euclid
//
//  Created by Ioannis Kaliakatsos on 22.11.20.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import Foundation

/// A type-safe struct for all API related to angles
public struct Angle {
    fileprivate static let degreesPerRadian = 180 / Double.pi

    public let degrees: Double

    public init(degrees: Double) {
        self.degrees = degrees
    }
}

public extension Angle {
    var radians: Double { degrees / Angle.degreesPerRadian }
}

public extension Angle {
    static var zero = Angle(degrees: 0)

    static var pi = Angle(degrees: 180)

    static var twoPi = Angle(degrees: 360)
}

public extension Angle {
    var cos: Double { Darwin.cos(radians) }
}
