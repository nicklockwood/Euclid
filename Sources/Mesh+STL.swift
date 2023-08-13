//
//  Mesh+STL.swift
//  Euclid
//
//  Created by Nick Lockwood on 14/04/2023.
//  Copyright © 2023 Nick Lockwood. All rights reserved.
//

import Foundation

public extension Mesh {
    /// Return ASCII STL string data for the mesh.
    func stlString(name: String) -> String {
        """
        solid \(name)
        \(triangulate().polygons.map {
            $0.stlString
        }.joined(separator: "\n"))
        endsolid \(name)
        """
    }

    /// Return binary STL data for the mesh.
    func stlData() -> Data {
        let headerSize = 80
        let triangleCountSize = 4
        let triangleSize = 50
        let polygons = triangulate().polygons
        let triangleCount = polygons.count

        let bufferSize = headerSize + triangleCountSize + triangleCount * triangleSize
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        buffer.initialize(repeating: 0, count: bufferSize)
        defer {
            buffer.deinitialize(count: bufferSize)
            buffer.deallocate()
        }

        var index = headerSize
        UInt32(triangleCount).write(to: buffer, at: &index)
        polygons.forEach { $0.write(to: buffer, at: &index) }

        let bufferPointer = UnsafeBufferPointer(start: buffer, count: bufferSize)
        return Data(buffer: bufferPointer)
    }
}

private extension Polygon {
    var stlString: String {
        """
        facet normal \(plane.normal.stlString)
        \touter loop
        \(vertices.map {
            "\t\tvertex \($0.position.stlString)"
        }.joined(separator: "\n"))
        \tendloop
        endfacet
        """
    }

    func write(to buffer: UnsafeMutablePointer<UInt8>, at index: inout Int) {
        plane.normal.write(to: buffer, at: &index)
        assert(vertices.count == 3)
        vertices.forEach { $0.position.write(to: buffer, at: &index) }
        // attribute byte count field
        index += 2
    }
}

private extension Vector {
    var stlString: String {
        "\(x.stlString) \(y.stlString) \(z.stlString)"
    }

    func write(to buffer: UnsafeMutablePointer<UInt8>, at index: inout Int) {
        x.write(to: buffer, at: &index)
        y.write(to: buffer, at: &index)
        z.write(to: buffer, at: &index)
    }
}

private extension Double {
    var stlString: String {
        let result = String(format: "%g", self)
        return result == "-0" ? "0" : result
    }

    func write(to buffer: UnsafeMutablePointer<UInt8>, at index: inout Int) {
        let value: UInt32 = Float(self).bitPattern
        value.write(to: buffer, at: &index)
    }
}

private extension UInt32 {
    func write(to buffer: UnsafeMutablePointer<UInt8>, at index: inout Int) {
        var value = self
        withUnsafePointer(to: &value) {
            let unsafePointer8 = $0.withMemoryRebound(to: UInt8.self, capacity: 4) { $0 }
            for i in 0 ..< 4 {
                buffer[index + i] = unsafePointer8[i]
            }
        }
        index += 4
    }
}
