//
//  Mesh+PLY.swift
//  Euclid
//
//  Created by Nick Lockwood on 09/11/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

// MARK: Export

public extension Mesh {
    /// Returns an ASCII PLY 1.0 representation of the mesh.
    ///
    /// Faces are triangulated. Positions, normals and UV coordinates are preserved.
    /// Vertex RGB is multiplied by the material tint in linear light, then encoded as
    /// rounded sRGB bytes. Alpha is multiplied without gamma conversion and stored as a byte.
    /// Texture images and other material properties are not embedded.
    /// - Parameters:
    ///   - colorLookup: Maps materials to tint colors. Use `nil` for default color mapping.
    ///   - isCancelled: A closure that returns `true` to cancel export.
    /// - Throws: `CancellationError` if export is cancelled.
    func plyString(
        colorLookup: (@Sendable (Material?) -> Color?)? = nil,
        isCancelled: CancellationHandler = { false }
    ) throws -> String {
        if isCancelled() { throw CancellationError() }
        let colorLookup = colorLookup ?? defaultColorMapping
        let triangles = triangulate(isCancelled: isCancelled).polygons
        try checkCancellation(isCancelled)
        var output = """
        ply
        format ascii 1.0
        comment RGB values are sRGB; alpha is linear
        element vertex \(triangles.count * 3)
        property double x
        property double y
        property double z
        property double nx
        property double ny
        property double nz
        property double s
        property double t
        property uchar red
        property uchar green
        property uchar blue
        property uchar alpha
        element face \(triangles.count)
        property list uchar int vertex_indices
        end_header

        """
        func byte(_ value: Double) -> Int {
            Int((value.clamped(to: 0 ... 1) * 255).rounded())
        }
        for triangle in triangles {
            if isCancelled() { throw CancellationError() }
            let tint = colorLookup(triangle.material) ?? .white
            for vertex in triangle.vertices {
                let color = (vertex.color.toLinear() * tint.toLinear()).toSRGB()
                let p = vertex.position, n = vertex.normal, uv = vertex.texcoord
                output += """
                \(p.x) \(p.y) \(p.z) \(n.x) \(n.y) \(n.z) \(uv.x) \(uv.y) \
                \(byte(color.red)) \(byte(color.green)) \(byte(color.blue)) \(byte(color.alpha))

                """
            }
        }
        for index in triangles.indices {
            if isCancelled() { throw CancellationError() }
            output += "3 \(index * 3) \(index * 3 + 1) \(index * 3 + 2)\n"
        }
        try checkCancellation(isCancelled)
        return output
    }
}

// MARK: Import

public extension Mesh {
    /// Creates a mesh from an ASCII PLY string.
    ///
    /// Preserves vertex positions, normals, UV coordinates and sRGB vertex colors.
    /// Byte RGB and alpha components are normalized to 0...1; floating-point components
    /// are used directly. Unknown elements and properties are skipped.
    /// - Parameters:
    ///   - plyString: ASCII PLY 1.0 data. Binary PLY is not supported by this initializer.
    ///   - options: The import options. Winding is preserved unless repair is explicitly enabled.
    /// - Returns: `nil` for invalid data, an empty mesh, or unsupported encoding.
    init?(plyString: String, options: ImportOptions = .init()) {
        try? self.init(plyString: plyString, options: options, isCancelled: { false })
    }

    /// Creates a mesh from PLY text, throwing `CancellationError` if the callback returns `true`.
    init?(
        plyString: String, options: ImportOptions = .init(), isCancelled: CancellationHandler
    ) throws {
        try checkCancellation(isCancelled)
        var lines = ArraySlice(plyString.components(separatedBy: .newlines))
        guard var mesh = try lines.readPLY(byteCount: plyString.utf8.count, isCancelled: isCancelled) else {
            return nil
        }
        if options.repairWinding == true { mesh = mesh.withConsistentWinding(isCancelled: isCancelled) }
        try checkCancellation(isCancelled)
        self = mesh
    }
}

private struct PLYProperty {
    var name: String
    var type: String
    var list: Bool
}

private struct PLYElement {
    var name: String
    var count: Int
    var properties: [PLYProperty]
}

private extension ArraySlice<String> {
    mutating func readPLY(byteCount: Int, isCancelled: CancellationHandler) throws -> Mesh? {
        guard popFirst()?.trimmingCharacters(in: .whitespaces) == "ply" else { return nil }
        var elements = [PLYElement]()
        var ascii = false
        var endHeader = false
        while let line = popFirst() {
            try checkCancellation(isCancelled)
            if line.trimmingCharacters(in: .whitespaces) == "end_header" {
                endHeader = true
                break
            }
            let parts = line.split(whereSeparator: \.isWhitespace).map(String.init)
            guard let command = parts.first else { continue }
            switch command {
            case "format": ascii = parts == ["format", "ascii", "1.0"]
            case "element":
                guard parts.count == 3,
                      let count = Int(parts[2]),
                      count >= 0,
                      count <= byteCount
                else { return nil }
                elements.append(PLYElement(name: parts[1], count: count, properties: []))
            case "property":
                guard !elements.isEmpty else { return nil }
                if parts.count == 3 {
                    elements[elements.count - 1].properties.append(PLYProperty(
                        name: parts[2],
                        type: parts[1],
                        list: false
                    ))
                } else if parts.count == 5, parts[1] == "list" {
                    elements[elements.count - 1].properties.append(PLYProperty(
                        name: parts[4],
                        type: parts[3],
                        list: true
                    ))
                } else { return nil }
            default: break
            }
        }
        guard ascii, endHeader else { return nil }
        var tokens = try ArraySlice<Substring>(flatMap {
            try checkCancellation(isCancelled)
            return $0.split(whereSeparator: \.isWhitespace)
        })
        removeAll()
        var vertices = [Vertex]()
        var faces = [[Int]]()
        for element in elements {
            for _ in 0 ..< element.count {
                try checkCancellation(isCancelled)
                var values = [String: Double]()
                for property in element.properties {
                    if property.list {
                        guard let count = tokens.readNumber().flatMap(Int.init(exactly:)), count >= 0,
                              count <= tokens.count
                        else { return nil }
                        var indices = [Int]()
                        for _ in 0 ..< count {
                            try checkCancellation(isCancelled)
                            guard let value = tokens.readNumber() else { return nil }
                            if element.name == "face",
                               ["vertex_indices", "vertex_index"].contains(property.name)
                            {
                                guard let index = Int(exactly: value) else { return nil }
                                indices.append(index)
                            }
                        }
                        if !indices.isEmpty { faces.append(indices) }
                    } else {
                        guard var value = tokens.readNumber() else { return nil }
                        if ["red", "green", "blue", "alpha"].contains(property.name),
                           ["uchar", "uint8"].contains(property.type)
                        { value /= 255 }
                        values[property.name] = value
                    }
                }
                if element.name == "vertex" {
                    guard let x = values["x"], let y = values["y"], let z = values["z"] else { return nil }
                    vertices.append(Vertex(
                        Vector(x, y, z),
                        normal: Vector(values["nx"] ?? 0, values["ny"] ?? 0, values["nz"] ?? 0),
                        texcoord: Vector(values["s"] ?? values["u"] ?? 0, values["t"] ?? values["v"] ?? 0),
                        color: Color(
                            red: values["red"] ?? 1,
                            green: values["green"] ?? 1,
                            blue: values["blue"] ?? 1,
                            alpha: values["alpha"] ?? 1
                        )
                    ))
                }
            }
        }
        var polygons = [Polygon]()
        for face in faces {
            try checkCancellation(isCancelled)
            guard face.allSatisfy(vertices.indices.contains) else { return nil }
            if let polygon = Polygon(face.map { vertices[$0] }) { polygons.append(polygon) }
        }
        guard !polygons.isEmpty, tokens.isEmpty else { return nil }
        return Mesh(polygons)
    }
}

private extension ArraySlice<Substring> {
    mutating func readNumber() -> Double? {
        guard let token = popFirst(), let value = Double(token), value.isFinite else { return nil }
        return value
    }
}
