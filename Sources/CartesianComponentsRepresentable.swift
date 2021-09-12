//
//  CartesianComponentsRepresentable.swift
//  Euclid
//
//  Created by Ioannis Kaliakatsos on 29.11.2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import Foundation

private enum CodingKeys: CodingKey {
    case x, y, z
}

public protocol CartesianComponentsRepresentable: Codable, Hashable, Comparable {
    var x: Double { get }
    var y: Double { get }
    var z: Double { get }
    init(x: Double, y: Double, z: Double)
}

public extension CartesianComponentsRepresentable {
    var norm: Double {
        (x * x + y * y + z * z).squareRoot()
    }

    static prefix func - (element: Self) -> Self {
        self.init(
            x: -element.x,
            y: -element.y,
            z: -element.z
        )
    }

    var components: [Double] {
        [x, y, z]
    }

    init(_ x: Double, _ y: Double, _ z: Double) {
        self.init(x: x, y: y, z: z)
    }
}

public extension CartesianComponentsRepresentable {
    init(from decoder: Decoder) throws {
        if var container = try? decoder.unkeyedContainer() {
            try self.init(from: &container)
        } else {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let x = try container.decodeIfPresent(Double.self, forKey: .x) ?? 0
            let y = try container.decodeIfPresent(Double.self, forKey: .y) ?? 0
            let z = try container.decodeIfPresent(Double.self, forKey: .z) ?? 0
            self.init(x: x, y: y, z: z)
        }
    }

    init(from container: inout UnkeyedDecodingContainer) throws {
        let x = try container.decode(Double.self)
        let y = try container.decode(Double.self)
        let z = try container.decodeIfPresent(Double.self) ?? 0
        self.init(x: x, y: y, z: z)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try encode(to: &container, skipZ: z == 0)
    }

    /// Encode directly into an unkeyedContainer
    func encode(to container: inout UnkeyedEncodingContainer, skipZ: Bool) throws {
        try container.encode(x)
        try container.encode(y)
        try skipZ ? () : container.encode(z)
    }

    func encode(to container: inout UnkeyedEncodingContainer) throws {
        try encode(to: &container, skipZ: false)
    }
}

public extension CartesianComponentsRepresentable {
    func quantized() -> Self {
        Self(x: quantize(x), y: quantize(y), z: quantize(z))
    }
}

public extension CartesianComponentsRepresentable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.x < rhs.x {
            return true
        } else if lhs.x > rhs.x {
            return false
        }
        if lhs.y < rhs.y {
            return true
        } else if lhs.y > rhs.y {
            return false
        }
        return lhs.z < rhs.z
    }
}

internal extension CartesianComponentsRepresentable {
    // Approximate equality
    func isEqual(to other: Self, withPrecision p: Double = epsilon) -> Bool {
        self == other ||
            (abs(x - other.x) < p && abs(y - other.y) < p && abs(z - other.z) < p)
    }
}

public extension CartesianComponentsRepresentable {
    /// Linearly interpolate between two vectors
    func lerp(_ a: Self, _ t: Double) -> Self {
        Self(
            x: x + (a.x - x) * t,
            y: y + (a.y - y) * t,
            z: z + (a.z - z) * t
        )
    }
}

public extension CartesianComponentsRepresentable {
    init(_ vector: Vector) {
        self.init(x: vector.x, y: vector.y, z: vector.z)
    }

    func scaled(by vn: Vector) -> Self {
        Self(
            x: x * vn.x,
            y: y * vn.y,
            z: z * vn.z
        )
    }

    func scaled(by f: Double) -> Self {
        Self(
            x: x * f,
            y: y * f,
            z: z * f
        )
    }
}

public extension CartesianComponentsRepresentable {
    /// Returns a new instance representing the min of the components of the passed instances
    static func min(_ lhs: Self, _ rhs: Self) -> Self {
        Self(Swift.min(lhs.x, rhs.x), Swift.min(lhs.y, rhs.y), Swift.min(lhs.z, rhs.z))
    }

    /// Returns a new instance representing the max of the components of the passed instances
    static func max(_ lhs: Self, _ rhs: Self) -> Self {
        Self(Swift.max(lhs.x, rhs.x), Swift.max(lhs.y, rhs.y), Swift.max(lhs.z, rhs.z))
    }
}
