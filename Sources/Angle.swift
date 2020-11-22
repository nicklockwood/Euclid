//
//  Angle.swift
//  Euclid
//
//  Created by Ioannis Kaliakatsos on 22.11.20.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import Foundation

#if os(Linux)
import Glibc
#else
import Darwin
#endif

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
    var cos: Double { os.cos(radians) }

    var sin: Double { os.sin(radians) }

    var tan: Double { os.tan(radians) }
}

public extension Angle {
    static func acos(_ cos: Double) -> Angle {
        return fromRadians(os.acos(cos))
    }

    static func atan(x: Double, y: Double) -> Angle {
        return fromRadians(atan2(y, x))
    }

    private static func fromRadians(_ radians: Double) -> Angle {
        return Angle(degrees: radians / Angle.radiansPerDegree)
    }
}

public extension Angle {
    static func + (lhs: Angle, rhs: Angle) -> Angle { Angle(degrees: lhs.degrees + rhs.degrees) }

    static func - (lhs: Angle, rhs: Angle) -> Angle { Angle(degrees: lhs.degrees - rhs.degrees) }
}

private struct os {
    static func cos(_ radians: Double) -> Double {
        #if os(Linux)
        return Glibc.cos(radians)
        #else
        return Darwin.cos(radians)
        #endif
    }

    static func acos(_ radians: Double) -> Double {
        #if os(Linux)
        return Glibc.acos(radians)
        #else
        return Darwin.acos(radians)
        #endif
    }

    static func sin(_ radians: Double) -> Double {
        #if os(Linux)
        return Glibc.sin(radians)
        #else
        return Darwin.sin(radians)
        #endif
    }

    static func asin(_ radians: Double) -> Double {
        #if os(Linux)
        return Glibc.asin(radians)
        #else
        return Darwin.asin(radians)
        #endif
    }

    static func tan(_ radians: Double) -> Double {
        #if os(Linux)
        return Glibc.tan(radians)
        #else
        return Darwin.tan(radians)
        #endif
    }

    static func atan2(x: Double, y: Double) -> Double {
        #if os(Linux)
        return Glibc.atan2(y, x)
        #else
        return Darwin.atan2(y, x)
        #endif
    }
}
