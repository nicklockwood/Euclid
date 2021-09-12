//
//  Vertex.swift
//  Euclid
//
//  Created by Nick Lockwood on 03/07/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/Euclid
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

/// A polygon vertex
public struct Vertex: Hashable {
    public var position: Vector {
        didSet { position = position.quantized() }
    }

    public var normal: Direction

    public var texcoord: Vector

    public init(
        _ position: Vector,
        _ normal: Direction? = nil,
        _ texcoord: Vector? = nil
    ) {
        self.init(
            unchecked: position,
            normal ?? .zero,
            texcoord ?? .zero
        )
    }

    public init?(_ values: [Double]) {
        switch values.count {
        case 2:
            self.init(Vector(values[0], values[1]))
        case 3:
            self.init(Vector(values[0], values[1], values[2]))
        case 6:
            self.init(
                Vector(values[0], values[1], values[2]),
                Direction(x: values[3], y: values[4], z: values[5])
            )
        case 8:
            self.init(
                Vector(values[0], values[1], values[2]),
                Direction(x: values[3], y: values[4], z: values[5]),
                Vector(values[6], values[7])
            )
        case 9:
            self.init(
                Vector(values[0], values[1], values[2]),
                Direction(x: values[3], y: values[4], z: values[5]),
                Vector(values[6], values[7], values[8])
            )
        default:
            return nil
        }
    }
}

extension Vertex: Codable {
    private enum CodingKeys: CodingKey {
        case position, normal, texcoord
    }

    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            try self.init(
                container.decode(Vector.self, forKey: .position),
                container.decodeIfPresent(Direction.self, forKey: .normal),
                container.decodeIfPresent(Vector.self, forKey: .texcoord)
            )
        } else {
            let container = try decoder.singleValueContainer()
            let values = try container.decode([Double].self)
            guard let vertex = Vertex(values) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Cannot decode vertex"
                )
            }
            self = vertex
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        let hasTexcoord = texcoord != .zero
        let hasNormal = hasTexcoord || normal != .zero
        let skipZ = !hasNormal && position.z == 0
        try position.encode(to: &container, skipZ: skipZ)
        try hasNormal ? normal.encode(to: &container, skipZ: skipZ) : ()
        try hasTexcoord ? texcoord.encode(to: &container, skipZ: texcoord.z == 0) : ()
    }
}

public extension Vertex {
    /// Invert all orientation-specific data (e.g. vertex normal). Called when the
    /// orientation of a polygon is flipped.
    func inverted() -> Vertex {
        Vertex(unchecked: position, -normal, texcoord)
    }

    /// Linearly interpolate between two vertices.
    /// Interpolation is applied to the position, texture coordinate and normal.
    func lerp(_ other: Vertex, _ t: Double) -> Vertex {
        Vertex(
            unchecked: position.lerp(other.position, t),
            normal.lerp(other.normal, t),
            texcoord.lerp(other.texcoord, t)
        )
    }
}

internal extension Vertex {
    init(unchecked position: Vector, _ normal: Direction, _ texcoord: Vector = .zero) {
        self.position = position.quantized()
        self.normal = normal
        self.texcoord = texcoord
    }

    /// Create copy of vertex with specified normal
    func with(normal: Direction) -> Vertex {
        var vertex = self
        vertex.normal = normal
        return vertex
    }

    // Approximate equality
    func isEqual(to other: Vertex, withPrecision p: Double = epsilon) -> Bool {
        position.isEqual(to: other.position, withPrecision: p) &&
            normal.isEqual(to: other.normal, withPrecision: p) &&
            texcoord.isEqual(to: other.texcoord, withPrecision: p)
    }
}
