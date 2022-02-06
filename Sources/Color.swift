//
//  Color.swift
//  Euclid
//
//  Created by Nick Lockwood on 01/09/2021.
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

/// A struct that represents a color in RGBA format.
///
/// Color can be used as a ``Polygon/material-swift.property``.
public struct Color: Hashable {
    /// The red component of the color.
    public var r: Double
    /// The green component of the color.
    public var g: Double
    /// The blue component of the color.
    public var b: Double
    /// The alpha component of the color.
    public var a: Double

    /// Create a color from RGB values and optional alpha component
    public init(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }
}

extension Color: Codable {
    private enum CodingKeys: String, CodingKey {
        case r, g, b, a
    }

    /// Creates a new mesh by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        if var container = try? decoder.unkeyedContainer() {
            try self.init(from: &container)
        } else {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let r = try container.decode(Double.self, forKey: .r)
            let g = try container.decode(Double.self, forKey: .g)
            let b = try container.decode(Double.self, forKey: .b)
            let a = try container.decodeIfPresent(Double.self, forKey: .a)
            self.init(r, g, b, a ?? 1)
        }
    }

    /// Encodes this mesh into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try encode(to: &container, skipA: a == 1)
    }
}

public extension Color {
    static var clear = Color(0, 0)
    static var black = Color(0)
    static var white = Color(1)
    static let gray = Color(0.5)
    static var red = Color(1, 0, 0)
    static var green = Color(0, 1, 0)
    static var blue = Color(0, 0, 1)
    static let yellow = Color(1, 1, 0)
    static let cyan = Color(0, 1, 1)
    static let magenta = Color(1, 0, 1)
    static let orange = Color(1, 0.5, 0)

    /// Creates a color from a luminance value and optional alpha component.
    init(_ rgb: Double, _ a: Double = 1) {
        self.r = rgb
        self.g = rgb
        self.b = rgb
        self.a = a
    }

    /// Creates a color from an array of components.
    init?(_ components: [Double]) {
        guard (1 ... 4).contains(components.count) else {
            return nil
        }
        self.init(unchecked: components)
    }

    /// The red, green, blue, and alpha components of the color.
    var components: [Double] {
        [r, g, b, a]
    }

    /// Creates a copy of the color updated with the alpha you provide.
    func withAlpha(_ a: Double) -> Color {
        Color(r, g, b, a)
    }

    /// Linearly interpolate between two colors
    func lerp(_ a: Color, _ t: Double) -> Color {
        self + (a - self) * t
    }
}

public extension Collection where Element == Color, Index == Int {
    /// Linearly interpolate between multiple colors
    func lerp(_ t: Double) -> Color {
        let steps = count - 1
        guard steps > -1 else {
            return .clear
        }
        let t = t * Double(steps)
        let index = Int(t)
        guard index < steps else {
            return self[steps]
        }
        return self[index].lerp(self[index + 1], t - t.rounded(.down))
    }
}

internal extension Color {
    init(unchecked components: [Double]) {
        switch components.count {
        case 1: self.init(components[0])
        case 2: self.init(components[0], components[1])
        case 3: self.init(components[0], components[1], components[2])
        case 4: self.init(components[0], components[1], components[2], components[3])
        default:
            assertionFailure()
            self = .clear
        }
    }

    init(from container: inout UnkeyedDecodingContainer) throws {
        self.r = try container.decode(Double.self)
        self.g = try container.decode(Double.self)
        self.b = try container.decode(Double.self)
        self.a = try container.decodeIfPresent(Double.self) ?? 1
    }

    func encode(to container: inout UnkeyedEncodingContainer, skipA: Bool) throws {
        try container.encode(r)
        try container.encode(g)
        try container.encode(b)
        try skipA ? () : container.encode(a)
    }

    static func - (lhs: Color, rhs: Color) -> Color {
        Color(lhs.r - rhs.r, lhs.g - rhs.g, lhs.b - rhs.b, lhs.a - rhs.a)
    }

    static func + (lhs: Color, rhs: Color) -> Color {
        Color(lhs.r + rhs.r, lhs.g + rhs.g, lhs.b + rhs.b, lhs.a + rhs.a)
    }

    static func * (lhs: Color, rhs: Double) -> Color {
        Color(lhs.r * rhs, lhs.g * rhs, lhs.b * rhs, lhs.a * rhs)
    }

    // Approximate equality
    func isEqual(to other: Color, withPrecision p: Double = epsilon) -> Bool {
        self == other ||
            (abs(r - other.r) < p && abs(g - other.g) < p && abs(b - other.b) < p && abs(a - other.a) < p)
    }
}
