//
//  MiterLimit.swift
//  Euclid
//
//  Created by Nick Lockwood on 31/07/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

/// The miter threshold beyond which a corner is beveled.
public struct MiterLimit: Hashable, Comparable, Sendable {
    /// The sharpest turn angle that can be mitered without beveling.
    public var angle: Angle {
        didSet { angle = Self.sanitize(angle) }
    }

    /// Creates a miter limit from a turn angle.
    /// - Parameter angle: The sharpest turn angle that can be mitered without beveling.
    public init(angle: Angle) {
        self.angle = Self.sanitize(angle)
    }
}

extension MiterLimit: CustomStringConvertible {
    public var description: String {
        "MiterLimit(angle: \(angle))"
    }
}

extension MiterLimit: Codable {
    private enum CodingKeys: CodingKey {
        case ratio, angle
    }

    /// Creates a new miter limit by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        if let ratio = try? decoder.singleValueContainer().decode(Double.self) {
            self.init(ratio: ratio)
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let angle = try container.decodeIfPresent(Angle.self, forKey: .angle) {
            self.init(angle: angle)
            return
        }
        try self.init(ratio: container.decode(Double.self, forKey: .ratio))
    }

    /// Encodes this miter limit into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        if ratio.isFinite {
            try ratio.encode(to: encoder)
        } else {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(angle, forKey: .angle)
        }
    }
}

extension MiterLimit: ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
    public init(floatLiteral value: Double) {
        self.init(ratio: value)
    }

    public init(integerLiteral value: Int) {
        self.init(ratio: Double(value))
    }
}

public extension MiterLimit {
    /// Miter limit representing no beveling.
    static let infinity = Self(angle: .pi)

    /// The maximum ratio of the miter length to the stroke width.
    var ratio: Double {
        get { angle < .pi ? 1 / cos(angle / 2) : .infinity }
        set { self = .init(ratio: newValue) }
    }

    /// Creates a miter limit from a ratio value.
    /// - Parameter ratio: The maximum ratio of the miter length to the stroke width.
    init(ratio: Double) {
        self.init(angle: Self.angle(forRatio: ratio))
    }

    /// Creates a miter limit from a ratio value.
    /// - Parameter ratio: The maximum ratio of the miter length to the stroke width.
    static func ratio(_ ratio: Double) -> MiterLimit {
        .init(ratio: ratio)
    }

    /// Creates a miter limit from a turn angle.
    /// - Parameter angle: The sharpest turn angle that can be mitered without beveling.
    static func angle(_ angle: Angle) -> MiterLimit {
        .init(angle: angle)
    }

    /// Creates a miter limit from an angle in degrees.
    /// - Parameter degrees: The angle in degrees.
    static func degrees(_ degrees: Double) -> MiterLimit {
        angle(.init(degrees: degrees))
    }

    /// Creates a miter limit from an angle in radians.
    /// - Parameter radians: The angle in radians.
    static func radians(_ radians: Double) -> MiterLimit {
        angle(.init(radians: radians))
    }

    /// Returns whether the leftmost miter limit has the lower value.
    static func < (lhs: MiterLimit, rhs: MiterLimit) -> Bool {
        lhs.angle < rhs.angle
    }
}

private extension MiterLimit {
    static func sanitize(_ angle: Angle) -> Angle {
        min(.pi, abs(angle))
    }

    static func angle(forRatio ratio: Double) -> Angle {
        ratio.isFinite ? .acos(1 / max(1, ratio)) * 2 : .pi
    }
}
