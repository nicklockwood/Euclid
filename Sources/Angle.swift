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
    fileprivate static let radiansPerDegree = Double.pi / 180

    public let radians: Double

    public init(radians: Double) {
        self.radians = radians
    }

    public init(degrees: Double) {
        self.radians = degrees * Angle.radiansPerDegree
    }
}

public extension Angle {
    var degrees: Double { radians / Angle.radiansPerDegree }
}

public extension Angle {
    static var zero = Angle(degrees: 0)

    static var pi = Angle(radians: .pi)

    static var twoPi = Angle(radians: 2 * .pi)
}

public extension Angle {
    var cos: Double { Darwin.cos(radians) }
}
