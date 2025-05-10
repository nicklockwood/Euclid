//
//  Bounded.swift
//  Euclid
//
//  Created by Nick Lockwood on 08/04/2025.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
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

/// A common protocol for objects that have a bounds.
public protocol Bounded {
    /// The bounds of the object.
    var bounds: Bounds { get }
}

extension LineSegment: Bounded {
    /// The bounding box containing the line segment.
    public var bounds: Bounds { Bounds(start, end) }
}

extension Polygon: Bounded {
    public var bounds: Bounds { Bounds(vertices.map { $0.position }) }
}

extension Path: Bounded {
    public var bounds: Bounds { Bounds(points.map { $0.position }) }
}

extension Mesh: Bounded {}
