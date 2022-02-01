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

/// A vertex represent a point in three dimension space with additional characteristics.
///
/// The additional characteristics (``Vertex/normal`` and ``Vertex/texcoord``) define how to represent the point in space when combined with other vertex instances to create a polygon.
///
/// The ``Vertex/position`` of each ``Vertex`` is automatically *quantized* (rounded to the nearest point in a very fine grid) in order to avoid the creation of very tiny polygons, or hairline cracks in surfaces.
/// To avoid accumulating rounding errors avoid applying multiple ``Transform`` to the same geometry in sequence.
public struct Vertex: Hashable {
    /// The position of the vertex.
    public var position: Vector {
        didSet { position = position.quantized() }
    }
    
    /// The normal for the vertex.
    public var normal: Vector {
        didSet { normal = normal.normalized() }
    }
    
    /// Texture coordinates for the vertex.
    public var texcoord: Vector
    
    /// Creates a new vertex.
    /// - Parameters:
    ///   - position: The position of the vertex.
    ///   - normal: The normal for the vertex.
    ///   - texcoord: The texture coordinates for the vertex.
    public init(
        _ position: Vector,
        _ normal: Vector? = nil,
        _ texcoord: Vector? = nil
    ) {
        self.init(
            unchecked: position,
            normal?.normalized() ?? .zero,
            texcoord ?? .zero
        )
    }
    
    /// Creates a vertex from a flat array of values.
    /// - Parameter values: The array of values.
    ///
    /// The first three values are applies as the position of the vertex, the second three are applied as the vertex normal, and the last two make up the texture coordinates.
    /// Values beyond the eighth element are ignored.
    public init?(_ values: [Double]) {
        switch values.count {
        case 2:
            self.init(Vector(values[0], values[1]))
        case 3:
            self.init(Vector(values[0], values[1], values[2]))
        case 6:
            self.init(
                Vector(values[0], values[1], values[2]),
                Vector(values[3], values[4], values[5])
            )
        case 8:
            self.init(
                Vector(values[0], values[1], values[2]),
                Vector(values[3], values[4], values[5]),
                Vector(values[6], values[7])
            )
        case 9:
            self.init(
                Vector(values[0], values[1], values[2]),
                Vector(values[3], values[4], values[5]),
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

    /// Creates a new vector by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            try self.init(
                container.decode(Vector.self, forKey: .position),
                container.decodeIfPresent(Vector.self, forKey: .normal),
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

    /// Encodes this date into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        let hasTexcoord = texcoord != .zero
        let hasNormal = hasTexcoord || normal != .zero
        let skipZ = !hasNormal && position.z == 0
        try position.encode(to: &container, skipZ: skipZ)
        try hasNormal ? normal.encode(to: &container) : ()
        try hasTexcoord ? texcoord.encode(to: &container, skipZ: texcoord.z == 0) : ()
    }
}

public extension Vertex {
    /// Returns a new vertex with normal inverted.
    ///
    /// Called when the orientation of a polygon is flipped.
    func inverted() -> Vertex {
        Vertex(unchecked: position, -normal, texcoord)
    }

    /// Linearly interpolate between two vertices.
    ///
    /// Interpolation is applied to the position, texture coordinate and normal.
    /// - Parameters:
    ///   - other: The vertex to interpolate towards.
    ///   - t: The unit value that indicates the distance between of this vertex and the target vertex.
    /// - Returns: A new vertex with values interpolated between the two vertices.
    func lerp(_ other: Vertex, _ t: Double) -> Vertex {
        Vertex(
            unchecked: position.lerp(other.position, t),
            normal.lerp(other.normal, t),
            texcoord.lerp(other.texcoord, t)
        )
    }
}

internal extension Vertex {
    init(unchecked position: Vector, _ normal: Vector, _ texcoord: Vector = .zero) {
        self.position = position.quantized()
        self.normal = normal
        self.texcoord = texcoord
    }

    /// Create copy of vertex with specified normal
    func with(normal: Vector) -> Vertex {
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
