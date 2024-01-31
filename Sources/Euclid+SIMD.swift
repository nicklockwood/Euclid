//
//  Euclid+SIMD.swift
//  Euclid
//
//  Created by Nick Lockwood on 05/10/2022.
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

#if canImport(simd)

import simd

extension SIMD3: XYZConvertible where Scalar: FloatingPoint {
    public var xyzComponents: (x: Double, y: Double, z: Double) {
        switch self {
        case let value as simd_double3:
            return (value.x, value.y, value.z)
        case let value as simd_float3:
            return (Double(value.x), Double(value.y), Double(value.z))
        default:
            preconditionFailure()
        }
    }
}

extension SIMD3: XYZRepresentable where Scalar: FloatingPoint {
    @_disfavoredOverload
    public init(x: Double, y: Double, z: Double) {
        switch Self.self {
        case let type as simd_double3.Type:
            self = type.init(x, y, z) as! Self
        case let type as simd_float3.Type:
            self = type.init(Float(x), Float(y), Float(z)) as! Self
        default:
            preconditionFailure()
        }
    }
}

extension SIMD2: XYZConvertible where Scalar: FloatingPoint {
    public var xyzComponents: (x: Double, y: Double, z: Double) {
        switch self {
        case let value as simd_double2:
            return (value.x, value.y, 0)
        case let value as simd_float2:
            return (Double(value.x), Double(value.y), 0)
        default:
            preconditionFailure()
        }
    }
}

extension SIMD2: XYZRepresentable where Scalar: FloatingPoint {
    public init(x: Double, y: Double, z _: Double) {
        switch Self.self {
        case let type as simd_double2.Type:
            self = type.init(x, y) as! Self
        case let type as simd_float2.Type:
            self = type.init(Float(x), Float(y)) as! Self
        default:
            preconditionFailure()
        }
    }
}

extension SIMD4: RGBAConvertible where Scalar: FloatingPoint {
    public var rgbaComponents: (r: Double, g: Double, b: Double, a: Double) {
        switch self {
        case let value as simd_double4:
            return (value.x, value.y, value.z, value.w)
        case let value as simd_float4:
            return (Double(value.x), Double(value.y), Double(value.z), Double(value.w))
        default:
            preconditionFailure()
        }
    }
}

extension SIMD4: RGBARepresentable where Scalar: FloatingPoint {
    public init(r: Double, g: Double, b: Double, a: Double) {
        switch Self.self {
        case let type as simd_double4.Type:
            self = type.init(r, g, b, a) as! Self
        case let type as simd_float4.Type:
            self = type.init(Float(r), Float(g), Float(b), Float(a)) as! Self
        default:
            preconditionFailure()
        }
    }
}

public extension simd_quatd {
    /// Creates a simd quaternion from a Euclid `Rotation`.
    /// - Parameter rotation: A Euclid rotation.
    init(_ rotation: Rotation) {
        self = rotation.storage
    }
}

public extension simd_quatf {
    /// Creates a simd float quaternion from a Euclid `Rotation`.
    /// - Parameter rotation: A Euclid rotation.
    init(_ rotation: Rotation) {
        self.init(vector: simd_float4(rotation.storage.vector))
    }
}

public extension Rotation {
    /// Creates a `Rotation` from a simd quaternion.
    /// - Parameter quaternion: A simd quaternion.
    init(_ quaternion: simd_quatd) {
        self.init(storage: quaternion)
    }

    /// Creates a `Rotation` from a simd quaternion.
    /// - Parameter quaternion: A simd quaternion.
    init(_ quaternion: simd_quatf) {
        self.init(simd_quatd(vector: simd_double4(quaternion.vector)))
    }
}

#endif
