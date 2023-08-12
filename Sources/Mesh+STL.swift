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
        let headerSize: Int = 80
        let triangleCountSize: Int = 4
        let triangleSize: Int = 50
        let polygons = triangulate().polygons
        let triangleCount = polygons.count

        let bufferSize = headerSize + triangleCountSize + triangleCount * triangleSize

        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        buffer.initialize(repeating: 0, count: bufferSize)
        defer {
            buffer.deinitialize(count: bufferSize)
            buffer.deallocate()
        }
        let triangleCountInt32 = UInt32(triangleCount)

        var index = headerSize
        triangleCountInt32.output(to: buffer, at: &index)

        for polygon in polygons {
            polygon.output(to: buffer, at: &index)
        }

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

    func output(to buffer: UnsafeMutablePointer<UInt8>, at index: inout Int) {
        plane.normal.output(to: buffer, at: &index)
        guard vertices.count == 3 else {
            fatalError("Polygons must be triangles after being triangulated.")
        }
        for vertex in self.vertices {
            vertex.position.output(to: buffer, at: &index)
        }
        // 2 bytes of 'attribute byte count' which we leave to be 0
        index += 2
    }
}

private extension Vector {
    var stlString: String {
        "\(x.stlString) \(y.stlString) \(z.stlString)"
    }

    func output(to buffer: UnsafeMutablePointer<UInt8>, at index: inout Int) {
        x.output(to: buffer, at: &index)
        y.output(to: buffer, at: &index)
        z.output(to: buffer, at: &index)
    }
}

private extension Double {
    var stlString: String {
        let result = String(format: "%g", self)
        return result == "-0" ? "0" : result
    }

    func output(to buffer: UnsafeMutablePointer<UInt8>, at index: inout Int) {
        let value: UInt32 = Float(self).bitPattern
        value.output(to: buffer, at: &index)
    }
}

private extension UInt32 {
    func output(to buffer: UnsafeMutablePointer<UInt8>, at index: inout Int) {
        var value = self
        withUnsafePointer(to: &value) {
            let unsafePointer8 = $0.withMemoryRebound(to: UInt8.self, capacity: 4, {$0})
            for i in 0 ..< 4 {
                buffer[index + i] = unsafePointer8[i]
            }
        }
        index += 4
    }
}
