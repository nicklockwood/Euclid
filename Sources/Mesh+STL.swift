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
        var data = Data(capacity: bufferSize)
        data.count = headerSize
        data.append(UInt32(triangleCount))
        polygons.forEach { data.append($0) }
        return data
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
}

private extension Vector {
    var stlString: String {
        "\(x.stlString) \(y.stlString) \(z.stlString)"
    }
}

private extension Double {
    var stlString: String {
        let result = String(format: "%g", self)
        return result == "-0" ? "0" : result
    }
}

private extension Data {
    mutating func append(_ vector: Vector) {
        append(Float(vector.x))
        append(Float(vector.y))
        append(Float(vector.z))
    }

    mutating func append(_ polygon: Polygon) {
        append(polygon.plane.normal)
        polygon.vertices.forEach { append($0.position) }
        // attribute byte count field
        count += 2
    }
}
