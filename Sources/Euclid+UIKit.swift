//
//  Euclid+UIKit.swift
//  Euclid
//
//  Created by Nick Lockwood on 27/08/2021.
//  Copyright © 2021 Nick Lockwood. All rights reserved.
//

#if canImport(UIKit)

import UIKit

public extension UIColor {
    /// Creates a UIKit color from a ``Color``.
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
    /// Creates a color from a `UIColor`.
    /// - Parameter uiColor: The `UIColor` to convert.
    init(_ uiColor: UIColor) {
        self.init(uiColor.cgColor)
    }
}

#endif
