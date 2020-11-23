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
#endif

/// A type-safe struct for all API related to angles
public struct Angle {
    public let radians: Double

    public init(radians: Double) {
        self.radians = radians
    }
}

public extension Angle {
    private static let degreesPerRadian = 180 / Double.pi

    internal init(degrees: Double) {
        self.init(radians: degrees / Angle.degreesPerRadian)
    }

    var degrees: Double {
        return radians * Angle.degreesPerRadian
    }
}

public extension Angle {
    static var zero = Angle(degrees: 0)

    static var piHalf = Angle(degrees: 90)

    static var pi = Angle(degrees: 180)

    static var twoPi = Angle(degrees: 360)
}

public extension Angle {
    var cos: Double {
        return os.cos(radians)
    }

    var sin: Double {
        return os.sin(radians)
    }

    var tan: Double {
        return os.tan(radians)
    }
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
    static func + (lhs: Angle, rhs: Angle) -> Angle {
        return Angle(degrees: lhs.degrees + rhs.degrees)
    }

    static func - (lhs: Angle, rhs: Angle) -> Angle {
        return Angle(degrees: lhs.degrees - rhs.degrees)
    }

    static func * (lhs: Double, rhs: Angle) -> Angle {
        return Angle(degrees: lhs * rhs.degrees)
    }

    static func / (lhs: Angle, rhs: Double) -> Angle {
        return Angle(degrees: lhs.degrees / rhs)
    }

    static prefix func - (angle: Angle) -> Angle {
        return Angle(degrees: -angle.degrees)
    }
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
        return Foundation.cos(radians)
        #endif
    }

    static func acos(_ radians: Double) -> Double {
        #if os(Linux)
        return Glibc.acos(radians)
        #else
        return Foundation.acos(radians)
        #endif
    }

    static func sin(_ radians: Double) -> Double {
        #if os(Linux)
        return Glibc.sin(radians)
        #else
        return Foundation.sin(radians)
        #endif
    }

    static func asin(_ radians: Double) -> Double {
        #if os(Linux)
        return Glibc.asin(radians)
        #else
        return Foundation.asin(radians)
        #endif
    }

    static func tan(_ radians: Double) -> Double {
        #if os(Linux)
        return Glibc.tan(radians)
        #else
        return Foundation.tan(radians)
        #endif
    }

    static func atan2(x: Double, y: Double) -> Double {
        #if os(Linux)
        return Glibc.atan2(y, x)
        #else
        return Foundation.atan2(y, x)
        #endif
    }
}
