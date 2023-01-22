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

import Foundation

/// A vertex represents a corner of a ``Polygon`` or a point on the surface of a ``Mesh``.
public struct Vertex: Hashable, Sendable {
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
        _ normal: Vector,
        _ texcoord: Vector? = nil,
        _ color: Color? = nil
    ) {
        self.init(unchecked: position, normal.normalized(), texcoord, color)
    }

    /// Creates a new vertex.
    /// - Parameters:
    ///   - position: The position of the vertex in 3D space.
    ///   - normal: The surface normal for the vertex (defaults to nil).
    ///   - texcoord: The optional texture coordinates for the vertex (defaults to zero).
    ///   - color: The optional vertex color (defaults to white).
    public init(
        _ position: Vector,
        _ normal: Direction? = nil,
        _ texcoord: Vector? = nil,
        _ color: Color? = nil
    ) {
        self.init(unchecked: position, normal.map(Vector.init), texcoord, color)
    }
}

extension Vertex: Comparable {
    /// Returns whether the leftmost vertex has the lower value.
    /// This provides a stable order when sorting collections of vertices.
    public static func < (lhs: Vertex, rhs: Vertex) -> Bool {
        guard lhs.position == rhs.position else { return lhs.position < rhs.position }
        guard lhs.normal == rhs.normal else { return lhs.normal < rhs.normal }
        guard lhs.texcoord == rhs.texcoord else { return lhs.texcoord < rhs.texcoord }
        return lhs.color < rhs.color
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
                container.decodeIfPresent(Direction.self, forKey: .normal),
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
    /// Creates a new vertex from a position with default values for normal, texcoord and color.
    /// - Parameter position: The position of the vertex in 3D space.
    init(_ position: Vector) {
        self.init(unchecked: position, nil, nil, nil)
    }

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

    /// Creates a copy of the vertex with the specified normal.
    /// - Parameter normal: The normal value to apply to the vertex.
    func withNormal(_ normal: Vector) -> Vertex {
        var vertex = self
        vertex.normal = normal
        return vertex
    }

    /// Creates a copy of the vertex with the specified texture coordinate.
    /// - Parameter texcoord: The texture coordinate to apply to the vertex.
    func withTexcoord(_ texcoord: Vector) -> Vertex {
        var vertex = self
        vertex.texcoord = texcoord
        return vertex
    }

    /// Creates a copy of the vertex with the specified position.
    /// - Parameter position: The position to apply to the vertex.
    func withPosition(_ position: Vector) -> Vertex {
        var vertex = self
        vertex.position = position
        return vertex
    }

    /// Creates a copy of the vertex with the specified color.
    /// - Parameter color: The color to apply to the vertex.
    func withColor(_ color: Color?) -> Vertex {
        var vertex = self
        vertex.color = color ?? .white
        return vertex
    }
}

extension Vertex {
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
    init?(_ values: [Double]) {
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

    /// Approximate equality
    func isEqual(to other: Vertex, withPrecision p: Double = epsilon) -> Bool {
        position.isEqual(to: other.position, withPrecision: p) &&
            normal.isEqual(to: other.normal, withPrecision: p) &&
            texcoord.isEqual(to: other.texcoord, withPrecision: p) &&
            color.isEqual(to: other.color, withPrecision: p)
    }
}

extension Collection where Element == Vertex {
    func mapTexcoords(_ transform: (Vector) -> Vector) -> [Vertex] {
        map { $0.withTexcoord(transform($0.texcoord)) }
    }

    func mapVertexColors(_ transform: (Color) -> Color?) -> [Vertex] {
        map { $0.withColor(transform($0.color)) }
    }

    func inverted() -> [Vertex] {
        reversed().map { $0.inverted() }
    }
}

struct VertexSet {
    private var storage = [Vector: [Vertex]]()

    /// The maximum distance between vertices.
    let precision: Double

    /// Creates a vertex set with specified precision.
    /// - Parameter precision: The maximum distance between vertices.
    init(precision: Double) {
        self.precision = precision
    }

    /// If vertex is unique, inserts it and returns the same value
    /// otherwise, returns nearest match
    /// - Parameter point: The point to insert.
    mutating func insert(_ vertex: Vertex) -> Vertex {
        let point = vertex.position
        let hash = Vector(
            round(point.x / precision) * precision,
            round(point.y / precision) * precision,
            round(point.z / precision) * precision
        )
        // if exact match found, return it
        if let vertex = storage[hash]?.first(where: {
            $0.isEqual(to: vertex, withPrecision: precision)
        }) {
            return vertex
        }
        // if position match found, merge it
        var vertex = vertex
        if let match = storage[hash]?.first(where: {
            $0.position.isEqual(to: point, withPrecision: precision)
        }) {
            vertex.position = match.position
            if vertex.normal.isEqual(to: match.normal, withPrecision: precision) {
                vertex.normal = match.normal
            }
            if vertex.texcoord.isEqual(to: match.texcoord, withPrecision: precision) {
                vertex.texcoord = match.texcoord
            }
            if vertex.color.isEqual(to: match.color, withPrecision: precision) {
                vertex.color = match.color
            }
        }
        // insert into hash
        for hashValue in point.hashValues(withPrecision: precision) {
            storage[hashValue, default: []].append(vertex)
        }
        return vertex
    }
}
