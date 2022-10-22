//
//  Euclid+SIMD.swift
//  Euclid
//
//  Created by Nick Lockwood on 05/10/2022.
//  Copyright © 2022 Nick Lockwood. All rights reserved.
//

#if canImport(simd)

import simd

public extension simd_double3 {
    /// Creates a simd vector 3 from a Euclid `Vector`.
    /// - Parameter vector: A Euclid vector.
    init(_ vector: Vector) {
        self.init(vector.x, vector.y, vector.z)
    }
}

public extension Vector {
    /// Creates a `Vector` from a simd vector 3.
    /// - Parameter vector: A simd vector.
    init(_ vector: simd_double3) {
        self.init(vector.x, vector.y, vector.z)
    }
}

public extension simd_quatd {
    /// Creates a simd quaternion from a Euclid `Quaternion`.
    /// - Parameter quaternion: A Euclid quaternion.
    init(_ quaternion: Quaternion) {
        self = quaternion.storage
    }
}

public extension Quaternion {
    /// Creates a `Quaternion` from a simd quaternion.
    /// - Parameter quaternion: A simd quaternion.
    init(_ quaternion: simd_quatd) {
        self.storage = quaternion
    }
}

#endif
