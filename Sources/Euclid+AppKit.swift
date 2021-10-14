//
//  Euclid+AppKit.swift
//  Euclid
//
//  Created by Nick Lockwood on 27/08/2021.
//  Copyright © 2021 Nick Lockwood. All rights reserved.
//

#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

public extension NSColor {
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
    init(_ nsColor: NSColor) {
        self.init(nsColor.cgColor)
    }
}

#endif
