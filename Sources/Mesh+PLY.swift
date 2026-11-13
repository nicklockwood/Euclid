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
    /// - Parameter colorLookup: Maps materials to face colors. Use `nil` for default color mapping.
    func plyString(colorLookup: (@Sendable (Material?) -> Color?)? = nil) -> String {
        // This overload cannot cancel, so the throwing implementation cannot fail.
        try! plyString(colorLookup: colorLookup, isCancelled: { false })
    }

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
        isCancelled: CancellationHandler
    ) throws -> String {
        var cancellationCountdown = cancellationCheckInterval
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
            try checkCancellation(isCancelled, countdown: &cancellationCountdown)
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
            try checkCancellation(isCancelled, countdown: &cancellationCountdown)
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
    /// Byte RGB and alpha components are normalized to 0...1. Floating-point components
    /// are used directly. Common `diffuse_red`, `diffuse_green`, `diffuse_blue` and
    /// `diffuse_alpha` properties are also supported. Unknown elements and properties are skipped.
    /// - Parameters:
    ///   - plyString: ASCII PLY 1.0 data. Binary PLY is not supported by this initializer.
    ///   - options: The import options. Winding is preserved unless repair is explicitly enabled.
    init?(plyString: String, options: ImportOptions = .init()) {
        try? self.init(plyString: plyString, options: options, isCancelled: { false })
    }

    /// Creates a mesh from PLY text, throwing `CancellationError` if the callback returns `true`.
    init?(
        plyString: String, options: ImportOptions = .init(), isCancelled: CancellationHandler
    ) throws {
        try checkCancellation(isCancelled)
        var lines = StringLines(plyString)
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

private extension StringLines {
    mutating func readPLY(byteCount: Int, isCancelled: CancellationHandler) throws -> Mesh? {
        var cancellationCountdown = cancellationCheckInterval
        guard popFirst()?.trimmingCharacters(in: .whitespaces) == "ply" else { return nil }
        var elements = [PLYElement]()
        var ascii = false
        var endHeader = false
        while let line = popFirst() {
            try checkCancellation(isCancelled, countdown: &cancellationCountdown)
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
        var tokens = ArraySlice<Substring>()
        func readNumber() throws -> Double? {
            while tokens.isEmpty {
                try checkCancellation(isCancelled, countdown: &cancellationCountdown)
                guard let line = popFirst() else { return nil }
                tokens = ArraySlice(line.split(whereSeparator: \.isWhitespace))
            }
            return tokens.readNumber()
        }
        var vertexCount = 0
        for element in elements where element.name == "vertex" {
            guard element.count <= byteCount - vertexCount else { return nil }
            vertexCount += element.count
        }
        var vertices = [Vertex]()
        vertices.reserveCapacity(vertexCount)
        var faces = [[Int]]()
        var polygons = [Polygon]()
        func appendFace(_ indices: [Int]) -> Bool {
            guard indices.allSatisfy(vertices.indices.contains) else { return false }
            if let polygon = Polygon(indices.map { vertices[$0] }) { polygons.append(polygon) }
            return true
        }
        let fields = ["x", "y", "z", "nx", "ny", "nz", "u", "v", "s", "t", "red", "green", "blue", "alpha"]
        for element in elements {
            let names = Set(element.properties.filter { !$0.list }.map(\.name))
            let slots = element.properties.map { property -> Int? in
                guard !property.list else { return nil }
                var name = property.name
                if name.hasPrefix("diffuse_") {
                    name = String(name.dropFirst(8))
                    if names.contains(name) { return nil }
                }
                return fields.firstIndex(of: name)
            }
            let hasS = names.contains("s"), hasT = names.contains("t")
            let hasPosition = [0, 1, 2].allSatisfy { slots.contains($0) }
            var values = [Double](repeating: 0, count: fields.count)
            for i in 10 ..< 14 {
                values[i] = 1
            }
            for _ in 0 ..< element.count {
                try checkCancellation(isCancelled, countdown: &cancellationCountdown)
                for (propertyIndex, property) in element.properties.enumerated() {
                    if property.list {
                        guard let count = try readNumber().flatMap(Int.init(exactly:)), count >= 0,
                              count <= byteCount else { return nil }
                        let isFace = element.name == "face" && ["vertex_indices", "vertex_index"]
                            .contains(property.name)
                        var indices = [Int]()
                        if isFace { indices.reserveCapacity(min(count, 4096)) }
                        for _ in 0 ..< count {
                            try checkCancellation(isCancelled, countdown: &cancellationCountdown)
                            guard let value = try readNumber() else { return nil }
                            if isFace {
                                guard let index = Int(exactly: value) else { return nil }
                                indices.append(index)
                            }
                        }
                        if !indices.isEmpty {
                            if vertices.count == vertexCount {
                                guard appendFace(indices) else { return nil }
                            } else { faces.append(indices) }
                        }
                    } else {
                        guard var value = try readNumber() else { return nil }
                        if let slot = slots[propertyIndex] {
                            if slot >= 10, ["uchar", "uint8"].contains(property.type) { value /= 255 }
                            values[slot] = value
                        }
                    }
                }
                if element.name == "vertex" {
                    guard hasPosition else { return nil }
                    vertices.append(Vertex(
                        Vector(values[0], values[1], values[2]),
                        normal: Vector(values[3], values[4], values[5]),
                        texcoord: Vector(values[hasS ? 8 : 6], values[hasT ? 9 : 7]),
                        color: Color(red: values[10], green: values[11], blue: values[12], alpha: values[13])
                    ))
                }
            }
            if vertices.count == vertexCount, !faces.isEmpty {
                for face in faces {
                    try checkCancellation(isCancelled, countdown: &cancellationCountdown)
                    guard appendFace(face) else { return nil }
                }
                faces.removeAll()
            }
        }
        while tokens.isEmpty, let line = popFirst() {
            try checkCancellation(isCancelled, countdown: &cancellationCountdown)
            tokens = ArraySlice(line.split(whereSeparator: \.isWhitespace))
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
