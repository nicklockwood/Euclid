//
//  Stretchable.swift
//  Euclid
//
//  Created by Nick Lockwood on 21/11/2022.
//  Copyright © 2022 Nick Lockwood. All rights reserved.
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

/// Protocol for stretchable types.
public protocol Stretchable {
    /// Returns a stretched copy of the value.
    /// - Parameters
    ///   - scaleFactor: A scale factor to apply to the value.
    ///   - along: The axis along which to apply the scale factor.
    func stretched(by scaleFactor: Double, along: Direction) -> Self
}

public extension Stretchable {
    /// Stretch the value in place.
    /// - Parameters
    ///   - scaleFactor: A scale factor to apply to the value.
    ///   - along: The axis along which to apply the scale factor.
    mutating func stretch(by scaleFactor: Double, along: Direction) {
        self = stretched(by: scaleFactor, along: along)
    }
}

extension Path: Stretchable {
    public func stretched(by scaleFactor: Double, along: Direction) -> Path {
        Path(
            unchecked: points.map { $0.stretched(by: scaleFactor, along: along) },
            plane: nil,
            subpathIndices: subpathIndices
        )
    }
}

extension PathPoint: Stretchable {
    public func stretched(by scaleFactor: Double, along: Direction) -> PathPoint {
        PathPoint(
            position: position.stretched(by: scaleFactor, along: along),
            texcoord: texcoord,
            color: color,
            isCurved: isCurved
        )
    }
}

extension Vector: Stretchable {
    public func stretched(by scaleFactor: Double, along: Direction) -> Vector {
        self + along * dot(Vector(along)) * (scaleFactor - 1)
    }
}

public extension Array where Element: Stretchable {
    func stretched(by scaleFactor: Double, along: Direction) -> Self {
        map { $0.stretched(by: scaleFactor, along: along) }
    }
}
