//
//  Euclid+AppKit.swift
//  Euclid
//
//  Created by Nick Lockwood on 27/08/2021.
//  Copyright © 2021 Nick Lockwood. All rights reserved.
//

#if canImport(AppKit) && !canImport(UIKit) // not macCatalyst

import AppKit

public extension NSColor {
    /// Creates an `NSColor` from a ``Color``.
    /// - Parameter color: The color to convert.
    convenience init(_ color: Color) {
        self.init(
            red: CGFloat(color.r),
            green: CGFloat(color.g),
            blue: CGFloat(color.b),
            alpha: CGFloat(color.a)
        )
    }
}

public extension Color {
    /// Creates a color from an `NSColor`.
    /// - Parameter nsColor: The `NSColor` to convert.
    init(_ nsColor: NSColor) {
        self.init(nsColor.cgColor)
    }
}

#endif
