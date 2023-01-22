//
//  Position.swift
//  Euclid
//
//  Created by Nick Lockwood on 22/01/2023.
//  Copyright © 2023 Nick Lockwood. All rights reserved.
//
//  Created by Nick Lockwood on 21/01/2023.
//  Copyright © 2023 Nick Lockwood. All rights reserved.
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

/// A position in 3D space.
public struct Position: Hashable, Sendable {
    /// The X component of the position.
    public var x: Double
    /// The Y component of the position.
    public var y: Double
    /// The Z component of the position.
    public var z: Double

    /// Creates a position from the values you provide.
    /// - Parameters:
    ///   - x: The X component of the position.
    ///   - y: The Y component of the position.
    ///   - z: The Z component of the position.
    public init(_ x: Double, _ y: Double, _ z: Double = 0) {
        self.x = x
        self.y = y
        self.z = z
    }
}

extension Position: XYZRepresentable {
    public var xyzComponents: (x: Double, y: Double, z: Double) {
        (x, y, z)
    }

    public init(x: Double = 0, y: Double = 0, z: Double = 0) {
        self.init(x, y, z)
    }
}

extension Position: Codable {
    /// Creates a new direction by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        try self.init(container.decode(Vector.self))
    }

    /// Encodes the direction into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try Vector(self).encode(to: &container, skipZ: z == 0)
    }
}

public extension Position {
    /// A position located at the origin
    static let origin: Position = .init(0, 0, 0)

    /// An array containing the X, Y, and Z components of the direction vector.
    var components: [Double] {
        [x, y, z]
    }
}
