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

/// Protocol for types that can be converted to RGBA color components.
public protocol RGBAConvertible {
    /// Get RGBA color components.
    var rgbaComponents: (r: Double, g: Double, b: Double, a: Double) { get }
}

/// Protocol for types that can be represented by RGBA color components.
public protocol RGBARepresentable: RGBAConvertible {
    /// Initialize with RGBA components.
    /// - Parameters:
    ///   - r: The red component of the color, from 0 to 1.
    ///   - g: The green component of the color, from 0 to 1.
    ///   - b: The blue component of the color, from 0 to 1.
    ///   - a: The alpha component of the color, from 0 to 1.
    init(r: Double, g: Double, b: Double, a: Double)
}

public extension RGBARepresentable {
    /// Initialize with an RGBAConvertible value.
    init(_ value: RGBAConvertible) {
        let components = value.rgbaComponents
        self.init(r: components.r, g: components.g, b: components.b, a: components.a)
    }
}

/// A color in RGBA format.
///
/// Color can be used as a ``Polygon/material-swift.property`` or as a ``Vertex/color``.
public struct Color: Hashable, Sendable {
    /// The red component of the color.
    public var r: Double
    /// The green component of the color.
    public var g: Double
    /// The blue component of the color.
    public var b: Double
    /// The alpha component of the color.
    public var a: Double

    /// Create a color from RGB values and optional alpha component
    /// - Parameters:
    ///   - r: The red component of the color, from 0 to 1.
    ///   - g: The green component of the color, from 0 to 1.
    ///   - b: The blue component of the color, from 0 to 1.
    ///   - a: The alpha component of the color. Defaults to 1 (fully opaque)
    public init(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }
}

extension Color: Comparable {
    /// Returns whether the leftmost color has the lower value.
    /// This provides a stable order when sorting collections of colors.
    public static func < (lhs: Color, rhs: Color) -> Bool {
        guard lhs.r == rhs.r else { return lhs.r < rhs.r }
        guard lhs.g == rhs.g else { return lhs.g < rhs.g }
        guard lhs.b == rhs.b else { return lhs.b < rhs.b }
        return lhs.a < rhs.a
    }
}

extension Color: RGBARepresentable {
    public var rgbaComponents: (r: Double, g: Double, b: Double, a: Double) {
        (r, g, b, a)
    }

    public init(r: Double = 0, g: Double = 0, b: Double = 0, a: Double = 1) {
        self.init(r, g, b, a)
    }
}

extension Color: Codable {
    private enum CodingKeys: String, CodingKey {
        case r, g, b, a
    }

    /// Creates a new color by decoding from the given decoder.
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

    /// Encodes this color into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try encode(to: &container, skipA: a == 1)
    }
}

public extension Color {
    static let clear = Color(0, 0)
    static let black = Color(0)
    static let white = Color(1)
    static let gray = Color(0.5)
    static let red = Color(1, 0, 0)
    static let green = Color(0, 1, 0)
    static let blue = Color(0, 0, 1)
    static let yellow = Color(1, 1, 0)
    static let cyan = Color(0, 1, 1)
    static let magenta = Color(1, 0, 1)
    static let orange = Color(1, 0.5, 0)

    /// Creates a color from a luminance value and optional alpha component.
    /// - Parameters:
    ///   - rgb: The luminance value, from 0 to 1.
    ///   - a: The alpha component. Defaults to 1 (fully opaque)
    init(_ rgb: Double, _ a: Double = 1) {
        self.r = rgb
        self.g = rgb
        self.b = rgb
        self.a = a
    }

    /// Creates a color from an array of component values.
    ///
    /// The number of values specified determines how each value is interpreted. The following patterns are
    /// supported (R = red, G = green, B = blue, A = alpha, L = luminance):
    ///
    /// L
    /// LA
    /// RGB
    /// RGBA
    init?(_ components: [Double]) {
        guard (1 ... 4).contains(components.count) else {
            return nil
        }
        self.init(unchecked: components)
    }

    /// Returns an array containing the red, green, blue, and alpha components of the color.
    var components: [Double] {
        [r, g, b, a]
    }

    /// Creates a copy of the color updated with the specified alpha.
    func withAlpha(_ a: Double) -> Color {
        Color(r, g, b, a)
    }

    /// Linearly interpolate between two colors.
    /// - Parameters:
    ///   - a: The color to interpolate towards.
    ///   - t: The normalized extent of interpolation, from 0 to 1.
    /// - Returns: The interpolated color.
    func lerp(_ a: Color, _ t: Double) -> Color {
        self + (a - self) * max(0, min(1, t))
    }
}

public extension Collection where Element == Color, Index == Int {
    /// Linearly interpolate between multiple colors.
    /// - Parameter t: The normalized extent of interpolation between all the colors, from 0 to 1.
    /// - Returns: The interpolated color.
    func lerp(_ t: Double) -> Color {
        let steps = count - 1
        guard steps > -1 else {
            return .clear
        }
        let t = Swift.max(0, Swift.min(1, t)) * Double(steps)
        let index = Int(t)
        guard index < steps else {
            return self[steps]
        }
        return self[index].lerp(self[index + 1], t - t.rounded(.down))
    }
}

extension Color: UnkeyedCodable {
    init(from container: inout UnkeyedDecodingContainer) throws {
        self.r = try container.decode(Double.self)
        self.g = try container.decode(Double.self)
        self.b = try container.decode(Double.self)
        self.a = try container.decodeIfPresent(Double.self) ?? 1
    }

    func encode(to container: inout UnkeyedEncodingContainer) throws {
        try encode(to: &container, skipA: false)
    }

    func encode(to container: inout UnkeyedEncodingContainer, skipA: Bool) throws {
        try container.encode(r)
        try container.encode(g)
        try container.encode(b)
        try skipA ? () : container.encode(a)
    }
}

extension Color {
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

    static func - (lhs: Color, rhs: Color) -> Color {
        Color(lhs.r - rhs.r, lhs.g - rhs.g, lhs.b - rhs.b, lhs.a - rhs.a)
    }

    static func + (lhs: Color, rhs: Color) -> Color {
        Color(lhs.r + rhs.r, lhs.g + rhs.g, lhs.b + rhs.b, lhs.a + rhs.a)
    }

    static func * (lhs: Color, rhs: Double) -> Color {
        Color(lhs.r * rhs, lhs.g * rhs, lhs.b * rhs, lhs.a * rhs)
    }

    /// Approximate equality
    func isEqual(to other: Color, withPrecision p: Double = epsilon) -> Bool {
        r.isEqual(to: other.r, withPrecision: p) &&
            g.isEqual(to: other.g, withPrecision: p) &&
            b.isEqual(to: other.b, withPrecision: p) &&
            a.isEqual(to: other.a, withPrecision: p)
    }
}
