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

/// A vertex represents a corner of a ``Polygon`` or a point on the surface of a ``Mesh``.
public struct Vertex: Hashable {
    /// The position of the vertex.
    public var position: Vector {
        didSet { position = position._quantized() }
    }

    /// The surface normal of the vertex, used to calculate lighting.
    /// Set this to zero if you want the normal to be calculated automatically from the polygon face normal.
    public var normal: Vector {
        didSet { normal = normal.normalized() }
    }

    /// Texture coordinates for the vertex. Set this to zero if you are not using a texture map.
    public var texcoord: Vector

    /// The color for the vertex.
    /// This will be multiplied by the material color, so set it to white if you do not require per-vertex colors.
    public var color: Color

    /// Creates a new vertex.
    /// - Parameters:
    ///   - position: The position of the vertex in 3D space.
    ///   - normal: The surface normal for the vertex (defaults to zero).
    ///   - texcoord: The optional texture coordinates for the vertex (defaults to zero).
    ///   - color: The optional vertex color (defaults to white).
    public init(
        _ position: Vector,
        _ normal: Vector? = nil,
        _ texcoord: Vector? = nil,
        _ color: Color? = nil
    ) {
        self.init(unchecked: position, normal?.normalized(), texcoord, color)
    }

    /// Creates a new vertex from a position with default values for normal, texcoord and color.
    /// - Parameter position: The position of the vertex in 3D space.
    public init(_ position: Vector) {
        self.init(unchecked: position, nil, nil, nil)
    }

    /// Creates a vertex from a flat array of values.
    /// - Parameter values: The array of values.
    ///
    /// The number of values specified determines how each value is interpreted. The following patterns are
    /// supported (P = position, N = normal, T = texcoord, RGB[A] = color):
    ///
    /// PP
    /// PPP
    /// PPP NNN
    /// PPP NNN TT
    /// PPP NNN TTT
    /// PPP NNN TTT RGB
    /// PPP NNN TTT RGBA
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
        case 12:
            self.init(
                Vector(values[0], values[1], values[2]),
                Vector(values[3], values[4], values[5]),
                Vector(values[6], values[7], values[8]),
                Color(values[9], values[10], values[11])
            )
        case 13:
            self.init(
                Vector(values[0], values[1], values[2]),
                Vector(values[3], values[4], values[5]),
                Vector(values[6], values[7], values[8]),
                Color(values[9], values[10], values[11], values[12])
            )
        default:
            return nil
        }
    }
}

extension Vertex: Codable {
    private enum CodingKeys: CodingKey {
        case position, normal, texcoord, color
    }

    /// Creates a new vertex by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            try self.init(
                container.decode(Vector.self, forKey: .position),
                container.decodeIfPresent(Vector.self, forKey: .normal),
                container.decodeIfPresent(Vector.self, forKey: .texcoord),
                container.decodeIfPresent(Color.self, forKey: .color)
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

    /// Encodes this vertex into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        let hasColor = color != .white
        let hasTexcoord = hasColor || texcoord != .zero
        let hasNormal = hasTexcoord || normal != .zero
        let skipPositionZ = !hasNormal && position.z == 0
        let skipTextureZ = !hasColor && texcoord.z == 0
        try position.encode(to: &container, skipZ: skipPositionZ)
        try hasNormal ? normal.encode(to: &container, skipZ: false) : ()
        try hasTexcoord ? texcoord.encode(to: &container, skipZ: skipTextureZ) : ()
        try hasColor ? color.encode(to: &container, skipA: color.a == 1) : ()
    }
}

public extension Vertex {
    /// Returns a new vertex with the normal inverted.
    func inverted() -> Vertex {
        Vertex(unchecked: position, -normal, texcoord, color)
    }

    /// Linearly interpolates between two vertices.
    /// - Parameters:
    ///   - other: The vertex to interpolate towards.
    ///   - t: The unit value that indicates the distance between of this vertex and the target vertex.
    /// - Returns: A new vertex with values interpolated between the two vertices.
    ///
    /// > Note:  Interpolation is applied to the texture coordinate, normal and color, as well as the position.
    func lerp(_ other: Vertex, _ t: Double) -> Vertex {
        Vertex(
            unchecked: position.lerp(other.position, t),
            normal.lerp(other.normal, t),
            texcoord.lerp(other.texcoord, t),
            color.lerp(other.color, t)
        )
    }
}

internal extension Vertex {
    init(
        unchecked position: Vector,
        _ normal: Vector?,
        _ texcoord: Vector?,
        _ color: Color?
    ) {
        self.position = position._quantized()
        self.normal = normal ?? .zero
        self.texcoord = texcoord ?? .zero
        self.color = color ?? .white
    }

    /// Creates a copy of the vertex with the specified normal.
    func with(normal: Vector) -> Vertex {
        var vertex = self
        vertex.normal = normal
        return vertex
    }

    /// Creates a copy of the vertex with the specified position.
    func with(position: Vector) -> Vertex {
        var vertex = self
        vertex.position = position._quantized()
        return vertex
    }

    /// Approximate equality
    func isEqual(to other: Vertex, withPrecision p: Double = epsilon) -> Bool {
        position.isEqual(to: other.position, withPrecision: p) &&
            normal.isEqual(to: other.normal, withPrecision: p) &&
            texcoord.isEqual(to: other.texcoord, withPrecision: p) &&
            color.isEqual(to: other.color, withPrecision: p)
    }
}

internal extension Collection where Element == Vertex {
    func inverted() -> [Vertex] {
        reversed().map { $0.inverted() }
    }
}
