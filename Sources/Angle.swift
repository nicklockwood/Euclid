//
//  Angle.swift
//  Euclid
//
//  Created by Ioannis Kaliakatsos on 22.11.20.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import Foundation

/// A type-safe struct for all API related to angles
public struct Angle: Hashable, Comparable {
    public var radians: Double

    public init(radians: Double) {
        self.radians = radians
    }
}

extension Angle: Codable {
    private enum CodingKeys: CodingKey {
        case radians, degrees
    }

    public init(from decoder: Decoder) throws {
        guard let container = try? decoder.container(keyedBy: CodingKeys.self) else {
            self.init(radians: try Double(from: decoder))
            return
        }
        if let radians = try container.decodeIfPresent(Double.self, forKey: .radians) {
            self.init(radians: radians)
            return
        }
        self = .degrees(try container.decode(Double.self, forKey: .degrees))
    }

    public func encode(to encoder: Encoder) throws {
        try radians.encode(to: encoder)
    }
}

public func cos(_ angle: Angle) -> Double {
    return cos(angle.radians)
}

public func sin(_ angle: Angle) -> Double {
    return sin(angle.radians)
}

public func tan(_ angle: Angle) -> Double {
    return tan(angle.radians)
}

public extension Angle {
    static var zero = Angle.radians(0)
    static var halfPi = Angle.radians(.pi / 2)
    static var pi = Angle.radians(.pi)
    static var twoPi = Angle.radians(.pi * 2)

    var degrees: Double {
        get { return radians * 180 / .pi }
        set { radians = newValue / 180 * .pi }
    }

    init(degrees: Double) {
        self.init(radians: degrees / 180 * .pi)
    }

    static func degrees(_ degrees: Double) -> Angle {
        return Angle(degrees: degrees)
    }

    static func radians(_ radians: Double) -> Angle {
        return Angle(radians: radians)
    }

    static func acos(_ cos: Double) -> Angle {
        return .radians(Foundation.acos(cos))
    }

    static func asin(_ sin: Double) -> Angle {
        return .radians(Foundation.asin(sin))
    }

    static func atan(_ tan: Double) -> Angle {
        return .radians(Foundation.tan(tan))
    }

    static func atan2(y: Double, x: Double) -> Angle {
        return .radians(Foundation.atan2(y, x))
    }

    static func + (lhs: Angle, rhs: Angle) -> Angle {
        return .radians(lhs.radians + rhs.radians)
    }

    static func += (lhs: inout Angle, rhs: Angle) {
        return lhs.radians += rhs.radians
    }

    static func - (lhs: Angle, rhs: Angle) -> Angle {
        return .radians(lhs.radians - rhs.radians)
    }

    static func -= (lhs: inout Angle, rhs: Angle) {
        return lhs.radians -= rhs.radians
    }

    static func * (lhs: Angle, rhs: Double) -> Angle {
        return .radians(lhs.radians * rhs)
    }

    static func * (lhs: Double, rhs: Angle) -> Angle {
        return .radians(lhs * rhs.radians)
    }

    static func *= (lhs: inout Angle, rhs: Double) {
        return lhs.radians *= rhs
    }

    static func / (lhs: Angle, rhs: Double) -> Angle {
        return .radians(lhs.radians / rhs)
    }

    static func /= (lhs: inout Angle, rhs: Double) {
        return lhs.radians /= rhs
    }

    static prefix func - (angle: Angle) -> Angle {
        return .radians(-angle.radians)
    }

    static func < (lhs: Angle, rhs: Angle) -> Bool {
        return lhs.degrees < rhs.degrees
    }
}
