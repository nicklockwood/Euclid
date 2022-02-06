//
//  Paths.swift
//  Euclid
//
//  Created by Nick Lockwood on 03/01/2022.
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

/// A control point that contributes to representing a path.
///
/// A path point can represent a corner or a curve, and has a ``PathPoint/position``, but no normal.
/// Instead, the ``PathPoint/isCurved`` property  indicates if a point is sharp or smooth, allowing the normal to be inferred automatically when required.
public struct PathPoint: Hashable {
    /// The position  of the path point.
    public var position: Vector
    /// The texture coordinate of the path point.
    public var texcoord: Vector?
    /// The color of the path point.
    public var color: Color?
    /// Indicates whether the point is curved.
    ///
    /// If `false`, the path point is sharp.
    public var isCurved: Bool
}

extension PathPoint: Codable {
    /// Creates a new path point by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let x = try container.decode(Double.self)
        let y = try container.decode(Double.self)
        switch container.count {
        case 2:
            self.init(Vector(x, y), texcoord: nil, color: nil, isCurved: false)
        case 3:
            if let isCurved = try? container.decodeIfPresent(Bool.self) {
                self.init(
                    Vector(x, y),
                    texcoord: nil,
                    color: nil,
                    isCurved: isCurved
                )
            } else {
                self.init(
                    Vector(x, y, try container.decode(Double.self)),
                    texcoord: nil,
                    color: nil,
                    isCurved: false
                )
            }
        case 4:
            let zOrU = try container.decode(Double.self)
            if let isCurved = try? container.decodeIfPresent(Bool.self) {
                self.init(
                    Vector(x, y, zOrU),
                    texcoord: nil,
                    color: nil,
                    isCurved: isCurved
                )
            } else {
                self.init(
                    Vector(x, y),
                    texcoord: Vector(zOrU, try container.decode(Double.self)),
                    color: nil,
                    isCurved: false
                )
            }
        case 5:
            let zOrU = try container.decode(Double.self)
            let uOrV = try container.decode(Double.self)
            if let isCurved = try? container.decodeIfPresent(Bool.self) {
                self.init(
                    Vector(x, y),
                    texcoord: Vector(zOrU, uOrV),
                    color: nil,
                    isCurved: isCurved
                )
            } else {
                self.init(
                    Vector(x, y, zOrU),
                    texcoord: Vector(uOrV, try container.decode(Double.self)),
                    color: nil,
                    isCurved: false
                )
            }
        case 6:
            let position = Vector(x, y, try container.decode(Double.self))
            let u = try container.decode(Double.self)
            let v = try container.decode(Double.self)
            if let isCurved = try? container.decode(Bool.self) {
                self.init(
                    position,
                    texcoord: Vector(u, v),
                    color: nil,
                    isCurved: isCurved
                )
            } else {
                self.init(
                    position,
                    texcoord: Vector(u, v, try container.decode(Double.self)),
                    color: nil,
                    isCurved: false
                )
            }
        case 7:
            let position = Vector(x, y, try container.decode(Double.self))
            let uOrR = try container.decode(Double.self)
            let vOrG = try container.decode(Double.self)
            let wOrB = try container.decode(Double.self)
            if let isCurved = try? container.decode(Bool.self) {
                self.init(
                    position,
                    texcoord: Vector(uOrR, vOrG, wOrB),
                    color: nil,
                    isCurved: isCurved
                )
            } else {
                self.init(
                    position,
                    texcoord: nil,
                    color: Color(uOrR, vOrG, wOrB, try container.decode(Double.self)),
                    isCurved: false
                )
            }
        case 8:
            self.init(
                Vector(x, y, try container.decode(Double.self)),
                texcoord: nil,
                color: try Color(from: &container),
                isCurved: try container.decode(Bool.self)
            )
        case 9:
            self.init(
                Vector(x, y, try container.decode(Double.self)),
                texcoord: try Vector(from: &container),
                color: try Color(from: &container),
                isCurved: false
            )
        case 10:
            let position = Vector(x, y, try container.decode(Double.self))
            let texcoord = try Vector(from: &container)
            let r = try container.decode(Double.self)
            let g = try container.decode(Double.self)
            let b = try container.decode(Double.self)
            if let isCurved = try? container.decode(Bool.self) {
                self.init(
                    position,
                    texcoord: texcoord,
                    color: Color(r, g, b),
                    isCurved: isCurved
                )
            } else {
                self.init(
                    position,
                    texcoord: texcoord,
                    color: Color(r, g, b, try container.decode(Double.self)),
                    isCurved: false
                )
            }
        case 11:
            self.init(
                Vector(x, y, try container.decode(Double.self)),
                texcoord: try Vector(from: &container),
                color: try Color(from: &container),
                isCurved: try container.decode(Bool.self)
            )
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode path point"
            )
        }
    }

    /// Encodes this path point into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        let skipTextureZ = texcoord?.z ?? 0 == 0
        let skipPositionZ = color == nil && position.z == 0 && skipTextureZ
        let skipAlpha = texcoord != nil && color?.a ?? 1 == 1
        try position.encode(to: &container, skipZ: skipPositionZ)
        try texcoord?.encode(to: &container, skipZ: skipTextureZ)
        try color?.encode(to: &container, skipA: skipAlpha)
        try isCurved ? container.encode(true) : ()
    }
}

public extension PathPoint {
    /// Creates a path point at the provided position using the location you provide.
    /// - Parameters:
    ///   - position: The location of the path point.
    ///   - texcoord: The texture coordinate corresponding to this path point.
    static func point(
        _ position: Vector,
        texcoord: Vector? = nil,
        color: Color? = nil
    ) -> PathPoint {
        PathPoint(position, texcoord: texcoord, color: color, isCurved: false)
    }

    /// Creates a path point at the provided position using the location coordinates you provide.
    /// - Parameters:
    ///   - x: The X coordinate of the path point.
    ///   - y: The Y coordinate of the path point.
    ///   - z: The Z coordinate of the path point.
    static func point(
        _ x: Double,
        _ y: Double,
        _ z: Double = 0,
        texcoord: Vector? = nil,
        color: Color? = nil
    ) -> PathPoint {
        .point(Vector(x, y, z), texcoord: texcoord, color: color)
    }

    /// Creates a curved path point at the provided position using the location you provide.
    /// - Parameters:
    ///   - position: The location of the path point.
    ///   - texcoord: The texture coordinate corresponding to this path point.
    static func curve(
        _ position: Vector,
        texcoord: Vector? = nil,
        color: Color? = nil
    ) -> PathPoint {
        PathPoint(position, texcoord: texcoord, color: color, isCurved: true)
    }

    /// Creates a curved path point at the provided position using the location coordinates you provide.
    /// - Parameters:
    ///   - x: The X coordinate of the path point.
    ///   - y: The Y coordinate of the path point.
    ///   - z: The Z coordinate of the path point.
    static func curve(
        _ x: Double,
        _ y: Double,
        _ z: Double = 0,
        texcoord: Vector? = nil,
        color: Color? = nil
    ) -> PathPoint {
        .curve(Vector(x, y, z), texcoord: texcoord, color: color)
    }

    @available(*, deprecated, message: "Use init(_:texcoord:color:isCurved:) instead")
    init(_ position: Vector, texcoord: Vector?, isCurved: Bool) {
        self.init(position, texcoord: texcoord, color: nil, isCurved: isCurved)
    }

    init(_ position: Vector, texcoord: Vector?, color: Color?, isCurved: Bool) {
        self.position = position.quantized()
        self.texcoord = texcoord
        self.color = color
        self.isCurved = isCurved
    }

    /// Linearly interpolate between this path point and another, at the unit interval you provide.
    /// - Parameters:
    ///   - other: The path point to interpolate towards.
    ///   - t: The unit interval between this point and the path point provided.
    /// - Returns: A new path at the linearly interpolated position.
    func lerp(_ other: PathPoint, _ t: Double) -> PathPoint {
        let texcoord: Vector?
        switch (self.texcoord, other.texcoord) {
        case let (lhs?, rhs?):
            texcoord = lhs.lerp(rhs, t)
        case let (lhs, rhs):
            texcoord = lhs ?? rhs
        }
        let color: Color?
        switch (self.color, other.color) {
        case let (lhs?, rhs?):
            color = lhs.lerp(rhs, t)
        case let (lhs, rhs):
            color = lhs ?? rhs
        }
        let isCurved = self.isCurved || other.isCurved
        return PathPoint(
            position.lerp(other.position, t),
            texcoord: texcoord,
            color: color,
            isCurved: isCurved
        )
    }
}

internal extension PathPoint {
    /// Replace/remove point color
    func with(color: Color?) -> PathPoint {
        var point = self
        point.color = color
        return point
    }
}
