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
    private static let radiansPerDegree = Double.pi / 180

    internal init(radians: Double) {
        self.init(degrees: radians / Angle.radiansPerDegree)
    }

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

// these are intentionally as static methods and not initialisers, in order to avoid confusion with the radians initialiser
public extension Angle {
    static func acos(_ cos: Double) -> Angle {
        return Angle(radians: os.acos(cos))
    }

    static func asin(_ sin: Double) -> Angle {
        return Angle(radians: os.asin(sin))
    }

    static func atan(x: Double, y: Double) -> Angle {
        return Angle(radians: os.atan2(x: x, y: y))
    }
}

public extension Angle {
    static func + (lhs: Angle, rhs: Angle) -> Angle { Angle(degrees: lhs.degrees + rhs.degrees) }

    static func - (lhs: Angle, rhs: Angle) -> Angle { Angle(degrees: lhs.degrees - rhs.degrees) }

    static func * (lhs: Double, rhs: Angle) -> Angle { Angle(degrees: lhs * rhs.degrees) }

    static func / (lhs: Angle, rhs: Double) -> Angle { Angle(degrees: lhs.degrees / rhs) }

    static prefix func - (angle: Angle) -> Angle { Angle(degrees: -angle.degrees) }
}

extension Angle: Equatable {
    public static func == (lhs: Angle, rhs: Angle) -> Bool {
        return lhs.degrees.isAlmostEqual(to: rhs.degrees)
    }
}

extension Angle: Comparable {
    public static func < (lhs: Angle, rhs: Angle) -> Bool {
        return lhs.degrees < rhs.degrees
    }
}

extension Angle: Hashable {}

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
