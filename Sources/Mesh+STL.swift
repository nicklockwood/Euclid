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

    /// A closure that maps a Euclid material to an STL facet color.
    /// - Parameter m: A Euclid material to convert, or `nil` for the default material.
    /// - Returns: A Euclid `Color` value.
    typealias STLColorProvider = (_ m: Material?) -> Color?

    /// Return binary STL data for the mesh.
    /// - Parameter colorLookup: A closure to map the polygon material to a SceneKit material.
    /// - Returns: A Euclid `Color` value.
    func stlData(colorLookup: STLColorProvider? = nil) -> Data {
        let headerSize = 80
        let triangleCountSize = 4
        let triangleSize = 50
        let polygons = triangulate().polygons
        let triangleCount = polygons.count

        let bufferSize = headerSize + triangleCountSize + triangleCount * triangleSize
        var data = Data(capacity: bufferSize)
        data.count = headerSize
        data.append(UInt32(triangleCount))
        let colorLookup = colorLookup ?? defaultColorMapping
        polygons.forEach { data.append($0, colorLookup: colorLookup) }
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

    mutating func append(_ color: Color) {
        let red = UInt16(round(color.r * 31))
        let green = UInt16(round(color.g * 31))
        let blue = UInt16(round(color.b * 31))
        append(0x8000 | red << 10 | green << 5 | blue)
    }

    mutating func append(_ polygon: Polygon, colorLookup: Mesh.STLColorProvider) {
        append(polygon.plane.normal)
        polygon.vertices.forEach { append($0.position) }
        if let color = colorLookup(polygon.material) {
            append(color)
        } else {
            count += 2
        }
    }
}

#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SceneKit)
import SceneKit
#endif

private func defaultColorMapping(_ material: Polygon.Material?) -> Color? {
    if let color = material as? Color {
        return color
    }
    #if canImport(AppKit) || canImport(UIKit)
    if let cfType = material as? CFTypeRef, CFGetTypeID(cfType) == CGColor.typeID {
        return Color(material as! CGColor)
    } else if let color = material as? OSColor {
        return Color(color)
    }
    #endif
    #if canImport(SceneKit)
    if let scnMaterial = material as? SCNMaterial {
        return defaultColorMapping(scnMaterial.diffuse.contents as? AnyHashable)
    }
    #endif
    return nil
}
