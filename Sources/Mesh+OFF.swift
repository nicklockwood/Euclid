//
//  Mesh+OFF.swift
//  Euclid
//
//  Created by Nick Lockwood on 16/09/2025.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

import Foundation

// MARK: Export

/// Configuration options for text OFF export.
public struct OFFTextOptions: Sendable {
    /// Include per-vertex normals using the N header prefix.
    public var vertexNormals: Bool
    /// Include per-vertex RGBA using the C header prefix.
    public var vertexColors: Bool
    /// Include two-dimensional texture coordinates using the ST header prefix.
    /// Texture images are not included.
    public var textureCoordinates: Bool
    /// Maps polygon materials to face colors.
    public var colorLookup: @Sendable (Mesh.Material?) -> Color?

    public init(
        vertexNormals: Bool = false,
        vertexColors: Bool = false,
        textureCoordinates: Bool = false,
        colorLookup: (@Sendable (Mesh.Material?) -> Color?)? = nil
    ) {
        self.vertexNormals = vertexNormals
        self.vertexColors = vertexColors
        self.textureCoordinates = textureCoordinates
        self.colorLookup = colorLookup ?? defaultColorMapping
    }
}

public extension Mesh {
    /// Returns OFF text with face colors. Vertex colors are omitted; use `coffString()` to preserve them.
    /// - Parameter colorLookup: Maps materials to face colors. Use `nil` for default color mapping.
    func offString(colorLookup: (@Sendable (Material?) -> Color?)? = nil) -> String {
        // This overload cannot cancel, so the throwing implementation cannot fail.
        try! offString(colorLookup: colorLookup, isCancelled: { false })
    }

    /// Returns OFF text with optional face-color mapping and cancellation. Vertex colors are omitted.
    ///
    /// Face colors are taken from polygon materials. RGB values use Euclid's sRGB convention,
    /// without gamma conversion. OFF does not declare a color space. Colors include alpha and
    /// are clamped to 0 ... 1. Normals, texture coordinates and texture images are not exported.
    /// - Parameters:
    ///   - colorLookup: Maps materials to face colors. Use `nil` for default color mapping.
    ///   - isCancelled: A closure that returns `true` to cancel export.
    /// - Throws: `CancellationError` if export is cancelled.
    func offString(
        colorLookup: (@Sendable (Material?) -> Color?)? = nil,
        isCancelled: CancellationHandler
    ) throws -> String {
        try offString(options: .init(colorLookup: colorLookup), isCancelled: isCancelled)
    }

    /// Returns COFF text with vertex RGBA and optional material-to-face-color mapping.
    /// - Parameter colorLookup: Maps materials to face colors. Use `nil` for default color mapping.
    func coffString(colorLookup: (@Sendable (Material?) -> Color?)? = nil) -> String {
        // This overload cannot cancel, so the throwing implementation cannot fail.
        try! coffString(colorLookup: colorLookup, isCancelled: { false })
    }

    /// Returns COFF text with vertex RGBA, throwing `CancellationError` when cancelled.
    /// Colors use the same convention and clamping as `offString()`.
    func coffString(
        colorLookup: (@Sendable (Material?) -> Color?)? = nil,
        isCancelled: CancellationHandler
    ) throws -> String {
        try offString(options: .init(vertexColors: true, colorLookup: colorLookup), isCancelled: isCancelled)
    }

    /// Returns OFF text with explicitly selected vertex attributes.
    /// The header reflects the selected attributes, for example NOFF or STCNOFF.
    func offString(options: OFFTextOptions) -> String {
        try! offString(options: options, isCancelled: { false })
    }

    /// Returns OFF text with explicitly selected vertex attributes and cancellation.
    /// Colors follow the same convention as `offString()`. Texture images are not exported.
    /// - Throws: `CancellationError` if export is cancelled.
    func offString(options: OFFTextOptions, isCancelled: CancellationHandler) throws -> String {
        var cancellationCountdown = cancellationCheckInterval
        try checkCancellation(isCancelled)
        let colorLookup = options.colorLookup
        let polygons = polygons.tessellate(isCancelled: isCancelled)
        var vertices = [Vertex](), indicesByVertex = [Vertex: Int]()
        var colors = [Color?]()
        let indices = try polygons.map { polygon -> [Int] in
            try checkCancellation(isCancelled, countdown: &cancellationCountdown)
            colors.append(colorLookup(polygon.material))
            return try polygon.vertices.map { vertex -> Int in
                try checkCancellation(isCancelled, countdown: &cancellationCountdown)
                // Retain seams only for the attributes included in the file.
                let vertex = Vertex(
                    unchecked: vertex.position,
                    options.vertexNormals ? vertex.normal : nil,
                    options.textureCoordinates ? Vector(vertex.texcoord.x, vertex.texcoord.y) : nil,
                    options.vertexColors ? vertex.color : nil
                )
                if let index = indicesByVertex[vertex] {
                    return index
                }
                let index = indicesByVertex.count
                indicesByVertex[vertex] = index
                vertices.append(vertex)
                return index
            }
        }
        let hasFaceColors = colors.contains { $0 != nil }
        let vertexStrings = try vertices.map {
            try checkCancellation(isCancelled, countdown: &cancellationCountdown)
            var string = $0.position.offString
            if options.vertexNormals { string += " \($0.normal.x) \($0.normal.y) \($0.normal.z)" }
            if options.vertexColors { string += " \($0.color.offString)" }
            if options.textureCoordinates { string += " \($0.texcoord.x) \($0.texcoord.y)" }
            return string
        }
        let indexStrings = try zip(indices, colors).map { indices, color in
            try checkCancellation(isCancelled, countdown: &cancellationCountdown)
            // Explicit white prevents uncolored faces becoming Geomview's gray fallback
            // when other faces in the same mesh have colors.
            let colorString = hasFaceColors ? " \((color ?? .white).offString)" : ""
            return "\(indices.count) \(indices.map(\.description).joined(separator: " "))\(colorString)"
        }
        try checkCancellation(isCancelled)
        return [
            (options.textureCoordinates ? "ST" : "") + (options.vertexColors ? "C" : "") +
                (options.vertexNormals ? "N" : "") + "OFF",
            "\(vertices.count) \(indices.count) 0",
            vertexStrings.joined(separator: "\n"),
            indexStrings.joined(separator: "\n"),
        ].joined(separator: "\n")
    }
}

private extension Color {
    var offString: String {
        // Unlike coordinates, face colors require an explicit floating-point spelling:
        // integer tokens (including 0 and 1) denote values in the 0 ... 255 range.
        components.map {
            let value = String($0.clamped(to: 0 ... 1))
            // OpenSCAD identifies floating-point colors by their decimal point,
            // including when the value uses scientific notation.
            return value.contains(".") ? value : value.replacingOccurrences(of: "e", with: ".0e")
        }.joined(separator: " ")
    }
}

private extension Vector {
    var offString: String {
        "\(x.offString) \(y.offString) \(z.offString)"
    }
}

private extension Double {
    var offString: String {
        let result = String(format: "%g", self)
        return result == "-0" ? "0" : result
    }
}

// MARK: Import

public extension Mesh {
    /// Create a mesh from an Object File Format string.
    /// - Parameters:
    ///   - offString: OFF string data, including C, N and ST header variants for vertex colors,
    ///     normals and two-dimensional texture coordinates. Face RGB(A) accepts integers in 0 ... 255
    ///     or floating-point values in 0 ... 1; COFF vertices use floating-point RGBA in 0 ... 1.
    ///     RGB values are treated as sRGB without gamma conversion. Palette indices are ignored.
    ///   - options: The import options.
    ///   - materialLookup: Maps face colors to materials. If omitted, face colors become materials.
    init?(
        offString: String,
        options: ImportOptions = .init(),
        materialLookup: (@Sendable (Color?) -> Material?)? = nil
    ) {
        try? self.init(offString: offString, options: options, materialLookup: materialLookup, isCancelled: { false })
    }

    /// Creates a mesh from OFF text, throwing `CancellationError` if the callback returns `true`.
    init?(
        offString: String,
        options: ImportOptions = .init(),
        materialLookup: (@Sendable (Color?) -> Material?)? = nil,
        isCancelled: CancellationHandler
    ) throws {
        var cancellationCountdown = cancellationCheckInterval
        try checkCancellation(isCancelled)
        var lines = StringLines(offString)
        guard let counts = lines.readHeader() else {
            return nil
        }
        var vertices = [Vertex]()
        for _ in 0 ..< counts.vertices {
            try checkCancellation(isCancelled, countdown: &cancellationCountdown)
            guard let vertex = lines.readVertex(options: counts.options) else { return nil }
            vertices.append(vertex)
        }
        var faces = [Polygon]()
        for _ in 0 ..< counts.faces {
            try checkCancellation(isCancelled, countdown: &cancellationCountdown)
            guard let face = lines.readFace(with: vertices, materialLookup: materialLookup ?? { $0 }) else {
                return nil
            }
            faces += face
        }
        var mesh = Mesh(faces)
        if options.repairWinding ?? true {
            mesh = mesh.withConsistentWinding(isCancelled: isCancelled)
        }
        try checkCancellation(isCancelled)
        self = mesh
    }
}

private extension StringLines {
    mutating func readParts() -> [String]? {
        while let line = popFirst() {
            let parts = line.prefix { $0 != "#" }.split(whereSeparator: \.isWhitespace).map(String.init)
            if !parts.isEmpty { return parts }
        }
        return nil
    }

    mutating func readHeader() -> (vertices: Int, faces: Int, options: OFFTextOptions)? {
        guard var parts = readParts() else { return nil }
        var options = OFFTextOptions()
        var header = parts[0].uppercased()[...]
        if header.hasPrefix("ST") {
            options.textureCoordinates = true
            header = header.dropFirst(2)
        }
        if header.hasPrefix("C") {
            options.vertexColors = true
            header = header.dropFirst()
        }
        if header.hasPrefix("N") {
            options.vertexNormals = true
            header = header.dropFirst()
        }
        if header == "OFF" {
            parts.removeFirst()
            if parts.isEmpty { parts = readParts() ?? [] }
        }
        let counts = parts.compactMap(Int.init)
        guard (2 ... 3).contains(counts.count), counts.count == parts.count,
              counts.allSatisfy({ $0 >= 0 })
        else { return nil }
        return (counts[0], counts[1], options)
    }

    mutating func readVertex(options: OFFTextOptions) -> Vertex? {
        let count = 3 + (options.vertexNormals ? 3 : 0) + (options.vertexColors ? 4 : 0) +
            (options.textureCoordinates ? 2 : 0)
        guard let parts = readParts(), parts.count == count else { return nil }
        let values = parts.compactMap(Double.init)
        guard values.count == count, values.allSatisfy(\.isFinite) else { return nil }
        var components = values[...]
        func readVector() -> Vector {
            defer { components = components.dropFirst(3) }
            return Vector(components.prefix(3))
        }
        let position = readVector()
        let normal = options.vertexNormals ? readVector() : nil
        var color: Color?
        if options.vertexColors {
            let rgba = components.prefix(4)
            guard rgba.allSatisfy({ (0 ... 1).contains($0) }) else { return nil }
            color = Color(rgba)
            components = components.dropFirst(4)
        }
        let texcoord = options.textureCoordinates ? Vector(components) : nil
        return Vertex(position, normal, texcoord, color)
    }

    mutating func readFace(
        with vertices: [Vertex],
        materialLookup: @Sendable (Color?) -> Mesh.Material?
    ) -> [Polygon]? {
        guard let parts = readParts(), let count = Int(parts[0]), count >= 0, count < parts.count else {
            return nil
        }
        let indices = parts.dropFirst().prefix(count).compactMap(Int.init)
        guard indices.count == count, indices.allSatisfy(vertices.indices.contains) else { return nil }
        let components = Array(parts.dropFirst(count + 1))
        let color: Color?
        switch components.count {
        case 0:
            color = nil
        case 1:
            // A palette index refers to an external Geomview colormap, not an RGB value.
            guard let index = Int(components[0]), index >= 0 else { return nil }
            color = nil
        case 3, 4:
            let values = components.compactMap(Double.init)
            let integerColors = components.allSatisfy { Int($0) != nil }
            let scale = integerColors ? 255.0 : 1.0
            guard values.count == components.count,
                  values.allSatisfy({ $0.isFinite && (0 ... scale).contains($0) })
            else { return nil }
            color = Color(values.map { $0 / scale })
        default:
            return nil
        }
        return .init(indices.map { vertices[$0] }, material: materialLookup(color))
    }
}
