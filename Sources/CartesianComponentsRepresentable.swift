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

public protocol CartesianComponentsRepresentable: Codable, Hashable {
    var x: Double { get }
    var y: Double { get }
    var z: Double { get }
    init(x: Double, y: Double, z: Double)
}

public extension CartesianComponentsRepresentable {
    var norm: Double {
        return (x * x + y * y + z * z).squareRoot()
    }

    static prefix func - (element: Self) -> Self {
        return self.init(
            x: -element.x,
            y: -element.y,
            z: -element.z
        )
    }

    var components: [Double] {
        return [x, y, z]
    }
}

public extension CartesianComponentsRepresentable {
    init(from decoder: Decoder) throws {
        let x, y, z: Double
        if var container = try? decoder.unkeyedContainer() {
            x = try container.decode(Double.self)
            y = try container.decode(Double.self)
            z = try container.decodeIfPresent(Double.self) ?? 0
        } else {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            x = try container.decodeIfPresent(Double.self, forKey: .x) ?? 0
            y = try container.decodeIfPresent(Double.self, forKey: .y) ?? 0
            z = try container.decodeIfPresent(Double.self, forKey: .z) ?? 0
        }
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
}
