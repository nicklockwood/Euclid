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
    public let degrees: Double

    public init(degrees: Double) {
        self.degrees = degrees
    }
}

public extension Angle {
    fileprivate static let radiansPerDegree = Double.pi / 180

    var radians: Double { degrees * Angle.radiansPerDegree }
}

public extension Angle {
    static var zero = Angle(degrees: 0)

    static var piHalf = Angle(degrees: 90)

    static var pi = Angle(degrees: 180)

    static var twoPi = Angle(degrees: 360)
}

public extension Angle {
    var cos: Double { Darwin.cos(radians) }

    var sin: Double { Darwin.sin(radians) }

    var tan: Double { Darwin.tan(radians) }

    init(x: Double, y: Double) {
        let angleAsRadians = atan2(y, x)
        self.init(degrees: angleAsRadians / Angle.radiansPerDegree)
    }
}

public extension Angle {
    static func + (lhs: Angle, rhs: Angle) -> Angle { Angle(degrees: lhs.degrees + rhs.degrees) }

    static func - (lhs: Angle, rhs: Angle) -> Angle { Angle(degrees: lhs.degrees - rhs.degrees) }
}
