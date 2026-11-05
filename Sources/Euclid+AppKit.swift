//
//  Euclid+AppKit.swift
//  Euclid
//
//  Created by Nick Lockwood on 27/08/2021.
//  Copyright © 2021 Nick Lockwood. All rights reserved.
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

#if canImport(AppKit) && !canImport(UIKit) // not macCatalyst

import AppKit

typealias OSColor = NSColor
typealias OSImage = NSImage
typealias OSColorComponent = Double

extension OSImage {
    var cgImage: CGImage? {
        cgImage(forProposedRect: nil, context: nil, hints: nil)
    }
}

public extension NSColor {
    /// Creates an AppKit color from a ``Color``.
    /// - Parameter color: The color to convert.
    convenience init(_ color: Color) {
        self.init(color, colorSpace: CGColorSpace(name: CGColorSpace.extendedSRGB)!)
    }

    /// Creates an AppKit color from a ``Color`` by interpreting its components in the specified color space.
    /// - Parameters:
    ///   - color: The color components to interpret in the specified color space.
    ///   - colorSpace: An RGB color space, or `nil` to use the platform's default RGB initializer.
    convenience init(_ color: Color, colorSpace: CGColorSpace?) {
        if let colorSpace {
            precondition(colorSpace.model == .rgb, "Expected an RGB color space")
            let cgColor = CGColor(colorSpace: colorSpace, components: [
                CGFloat(color.red), CGFloat(color.green), CGFloat(color.blue), CGFloat(color.alpha),
            ])!
            self.init(cgColor: cgColor)!
        } else {
            self.init(
                red: CGFloat(color.red),
                green: CGFloat(color.green),
                blue: CGFloat(color.blue),
                alpha: CGFloat(color.alpha)
            )
        }
    }
}

public extension Color {
    /// Creates a color from an `NSColor`.
    /// - Parameter nsColor: The `NSColor` to convert.
    init(_ nsColor: NSColor) {
        self.init(nsColor.cgColor)
    }

    /// Creates a color from an `NSColor` by converting it to the specified RGB color space.
    /// - Parameters:
    ///   - nsColor: The `NSColor` to convert.
    ///   - colorSpace: The destination RGB color space, or `nil` to copy the original components without conversion.
    init(_ nsColor: NSColor, colorSpace: CGColorSpace?) {
        self.init(nsColor.cgColor, colorSpace: colorSpace)
    }
}

#endif
