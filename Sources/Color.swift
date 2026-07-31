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

/// A color in RGBA format.
///
/// Color can be used as a ``Polygon/material-swift.property`` or as a ``Vertex/color``.
public struct Color: Hashable, Sendable {
    /// The red component of the color.
    public var red: Double
    /// The green component of the color.
    public var green: Double
    /// The blue component of the color.
    public var blue: Double
    /// The alpha component of the color.
    public var alpha: Double

    /// Create a color from RGB values and optional alpha component
    /// - Parameters:
    ///   - red: The red component of the color, from 0 to 1.
    ///   - green: The green component of the color, from 0 to 1.
    ///   - blue: The blue component of the color, from 0 to 1.
    ///   - alpha: The alpha component of the color. Defaults to 1 (fully opaque)
    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

extension Color: ExpressibleByArrayLiteral {
    /// Creates a color from an array of component values.
    ///
    /// The number of values specified determines how each value is interpreted. The following patterns are
    /// supported (R = red, G = green, B = blue, A = alpha, L = luminance):
    ///
    /// L
    /// LA
    /// RGB
    /// RGBA
    public init(arrayLiteral elements: Double...) {
        assert((1 ... 4).contains(elements.count), """
        Color components array must contain between 1 and 4 values
        """)
        self.init(elements)!
    }
}

extension Color: CustomDebugStringConvertible, CustomReflectable {
    public var debugDescription: String {
        "Color(\(red), \(green), \(blue)\(alpha == 1 ? "" : ", \(alpha)"))"
    }

    public var customMirror: Mirror {
        Mirror(self, children: [:], displayStyle: .struct)
    }
}

extension Color: Codable {
    private enum CodingKeys: String, CodingKey {
        case red, green, blue, alpha
        case r, g, b, a
    }

    /// Creates a new color by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        if var container = try? decoder.unkeyedContainer() {
            try self.init(from: &container)
        } else {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let red = try container.decodeIfPresent(Double.self, forKey: .red) ??
                container.decode(Double.self, forKey: .r)
            let green = try container.decodeIfPresent(Double.self, forKey: .green) ??
                container.decode(Double.self, forKey: .g)
            let blue = try container.decodeIfPresent(Double.self, forKey: .blue) ??
                container.decode(Double.self, forKey: .b)
            let alpha = try container.decodeIfPresent(Double.self, forKey: .alpha) ??
                container.decodeIfPresent(Double.self, forKey: .a)
            self.init(red: red, green: green, blue: blue, alpha: alpha ?? 1)
        }
    }

    /// Encodes this color into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try encode(to: &container, skipA: alpha == 1)
    }
}

public extension Color {
    static let clear = Color(white: 0, alpha: 0)
    static let black = Color(white: 0)
    static let darkGray = Color(white: 1.0 / 3.0)
    static let lightGray = Color(white: 2.0 / 3.0)
    static let white = Color(white: 1)
    static let gray = Color(white: 0.5)
    static let red = Color(red: 1, green: 0, blue: 0)
    static let green = Color(red: 0, green: 1, blue: 0)
    static let blue = Color(red: 0, green: 0, blue: 1)
    static let yellow = Color(red: 1, green: 1, blue: 0)
    static let cyan = Color(red: 0, green: 1, blue: 1)
    static let magenta = Color(red: 1, green: 0, blue: 1)
    static let orange = Color(red: 1, green: 0.5, blue: 0)
    static let purple = Color(red: 0.5, green: 0, blue: 0.5)
    static let brown = Color(red: 0.6, green: 0.4, blue: 0.2)
    static let mint = Color(red: 0, green: 199.0 / 255.0, blue: 190.0 / 255.0)
    static let teal = Color(red: 48.0 / 255.0, green: 176.0 / 255.0, blue: 199.0 / 255.0)
    static let indigo = Color(red: 88.0 / 255.0, green: 86.0 / 255.0, blue: 214.0 / 255.0)
    static let pink = Color(red: 1, green: 45.0 / 255.0, blue: 85.0 / 255.0)

    /// Creates a color from a luminance value and optional alpha component.
    /// - Parameters:
    ///   - white: The luminance value, from 0 to 1.
    ///   - alpha: The alpha component. Defaults to 1 (fully opaque)
    init(white: Double, alpha: Double = 1) {
        self.red = white
        self.green = white
        self.blue = white
        self.alpha = alpha
    }

    /// Creates a color from hue, saturation, brightness, and optional alpha components.
    /// - Parameters:
    ///   - hue: The hue component of the color, from 0 to 1.
    ///   - saturation: The saturation component of the color, from 0 to 1.
    ///   - brightness: The brightness component of the color, from 0 to 1.
    ///   - alpha: The alpha component. Defaults to 1 (fully opaque)
    init(hue: Double, saturation: Double, brightness: Double, alpha: Double = 1) {
        let hue = hue - hue.rounded(.down)
        let c = brightness * saturation
        let x = c * (1 - abs((hue * 6).truncatingRemainder(dividingBy: 2) - 1))
        let m = brightness - c
        switch hue * 6 {
        case 0 ..< 1: self.init(red: c + m, green: x + m, blue: m, alpha: alpha)
        case 1 ..< 2: self.init(red: x + m, green: c + m, blue: m, alpha: alpha)
        case 2 ..< 3: self.init(red: m, green: c + m, blue: x + m, alpha: alpha)
        case 3 ..< 4: self.init(red: m, green: x + m, blue: c + m, alpha: alpha)
        case 4 ..< 5: self.init(red: x + m, green: m, blue: c + m, alpha: alpha)
        default: self.init(red: c + m, green: m, blue: x + m, alpha: alpha)
        }
    }

    /// Creates a color from an array of component values.
    /// - Parameter components: An array of vector components.
    ///
    /// The number of values specified determines how each value is interpreted. The following patterns are
    /// supported (R = red, G = green, B = blue, A = alpha, L = luminance):
    ///
    /// L
    /// LA
    /// RGB
    /// RGBA
    init?<T: Collection>(_ components: T) where T.Element == Double, T.Index == Int {
        guard (1 ... 4).contains(components.count) else {
            return nil
        }
        self.init(unchecked: components)
    }

    /// Returns an array containing the red, green, blue, and alpha components of the color.
    var components: [Double] {
        [red, green, blue, alpha]
    }

    /// The hue component of the color, from 0 to 1.
    var hue: Double {
        hsbComponents.hue
    }

    /// The saturation component of the color, from 0 to 1.
    var saturation: Double {
        hsbComponents.saturation
    }

    /// The brightness component of the color, from 0 to 1.
    var brightness: Double {
        hsbComponents.brightness
    }

    /// Creates a copy of the color updated with the specified alpha component.
    func withAlphaComponent(_ alpha: Double) -> Color {
        .init(red: red, green: green, blue: blue, alpha: alpha)
    }

    /// Linearly interpolate between two colors.
    /// - Parameters:
    ///   - other: The color to interpolate towards.
    ///   - t: The normalized extent of interpolation, from 0 to 1.
    /// - Returns: The interpolated color.
    func lerp(_ other: Color, _ t: Double) -> Color {
        interpolated(with: other, by: t)
    }

    /// Returns a color with its components multiplied by the specified color.
    static func * (lhs: Color, rhs: Color) -> Color {
        .init(
            red: lhs.red * rhs.red,
            green: lhs.green * rhs.green,
            blue: lhs.blue * rhs.blue,
            alpha: lhs.alpha * rhs.alpha
        )
    }

    /// Multiplies the components of the color by the specified color.
    static func *= (lhs: inout Color, rhs: Color) {
        lhs = lhs * rhs
    }
}

public extension Collection<Color> where Index == Int {
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
        self.red = try container.decode(Double.self)
        self.green = try container.decode(Double.self)
        self.blue = try container.decode(Double.self)
        self.alpha = try container.decodeIfPresent(Double.self) ?? 1
    }

    func encode(to container: inout UnkeyedEncodingContainer) throws {
        try encode(to: &container, skipA: false)
    }

    func encode(to container: inout UnkeyedEncodingContainer, skipA: Bool) throws {
        try container.encode(red)
        try container.encode(green)
        try container.encode(blue)
        try skipA ? () : container.encode(alpha)
    }
}

extension Color {
    init<T: Collection>(unchecked components: T) where T.Element == Double, T.Index == Int {
        let i = components.startIndex
        switch components.count {
        case 1: self.init(white: components[i])
        case 2: self.init(white: components[i], alpha: components[i + 1])
        case 3: self.init(red: components[i], green: components[i + 1], blue: components[i + 2])
        case 4:
            self.init(
                red: components[i],
                green: components[i + 1],
                blue: components[i + 2],
                alpha: components[i + 3]
            )
        default:
            assertionFailure()
            self = .clear
        }
    }

    /// Returns the hue, saturation, brightness, and alpha components of the color.
    var hsbComponents: (hue: Double, saturation: Double, brightness: Double, alpha: Double) {
        let max = Swift.max(red, green, blue)
        let min = Swift.min(red, green, blue)
        let delta = max - min
        let hue: Double = if delta == 0 {
            0
        } else if max == red {
            ((green - blue) / delta).truncatingRemainder(dividingBy: 6) / 6
        } else if max == green {
            ((blue - red) / delta + 2) / 6
        } else {
            ((red - green) / delta + 4) / 6
        }
        return (
            hue: hue < 0 ? hue + 1 : hue,
            saturation: max == 0 ? 0 : delta / max,
            brightness: max,
            alpha: alpha
        )
    }
}

public extension Color {
    @available(*, deprecated, renamed: "red")
    var r: Double {
        get { red }
        set { red = newValue }
    }

    @available(*, deprecated, renamed: "green")
    var g: Double {
        get { green }
        set { green = newValue }
    }

    @available(*, deprecated, renamed: "blue")
    var b: Double {
        get { blue }
        set { blue = newValue }
    }

    @available(*, deprecated, renamed: "alpha")
    var a: Double {
        get { alpha }
        set { alpha = newValue }
    }

    @available(*, deprecated, renamed: "init(red:green:blue:alpha:)")
    init(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) {
        self.init(red: r, green: g, blue: b, alpha: a)
    }

    @available(*, deprecated, renamed: "init(white:alpha:)")
    init(_ rgb: Double, _ a: Double = 1) {
        self.init(white: rgb, alpha: a)
    }

    @available(*, deprecated, renamed: "withAlphaComponent(_:)")
    func withAlpha(_ a: Double) -> Color {
        withAlphaComponent(a)
    }
}
