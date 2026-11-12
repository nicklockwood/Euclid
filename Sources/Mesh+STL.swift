//
//  Mesh+STL.swift
//  Euclid
//
//  Created by Nick Lockwood on 14/04/2023.
//  Copyright © 2023 Nick Lockwood. All rights reserved.
//

import Foundation

private let headerSize = 80
private let triangleSize = 50

// MARK: Export

/// Configuration options for text/ASCII STL export.
public struct STLTextOptions: Sendable {
    /// The name to be embedded in the file.
    public var name: String
    /// A whitespace string to use as the indent value.
    public var indent: String
    /// Should normal values be zeroed out?
    public var zeroNormals: Bool

    public init(
        name: String = "",
        indent: String = "\t",
        zeroNormals: Bool = false
    ) {
        self.name = name
        self.indent = indent
        self.zeroNormals = zeroNormals
    }
}

/// Configuration options for binary STL export.
public struct STLBinaryOptions: Sendable {
    /// Data to use for file header.
    /// - Note: Data will be padded to 80 bytes. If more than 80 bytes are provided, data will be truncated.
    public var header: Data
    /// Should normal values be zeroed out?
    public var zeroNormals: Bool
    /// A closure that maps each polygon's material to an STL facet color.
    public var colorLookup: Mesh.STLColorProvider

    public init(
        header: Data = .init(),
        zeroNormals: Bool = false,
        colorLookup: Mesh.STLColorProvider? = nil
    ) {
        self.header = header
        self.zeroNormals = zeroNormals
        self.colorLookup = colorLookup ?? defaultColorMapping
    }
}

/// Configuration for exported STL file.
public enum STLFormat: Sendable {
    /// Export in ASCII format.
    case text(STLTextOptions)
    /// Export in binary format.
    case binary(STLBinaryOptions)
}

public extension Mesh {
    /// Return ASCII STL string data for the mesh.
    func stlString(name: String = "") -> String {
        stlString(options: .init(name: name))
    }

    /// Return ASCII STL string data for the mesh.
    func stlString(options: STLTextOptions) -> String {
        try! stlString(options: options, isCancelled: { false })
    }

    /// Returns ASCII STL data, throwing `CancellationError` when cancelled.
    func stlString(name: String = "", isCancelled: CancellationHandler) throws -> String {
        try stlString(options: .init(name: name), isCancelled: isCancelled)
    }

    /// Returns ASCII STL data, throwing `CancellationError` when cancelled.
    func stlString(options: STLTextOptions, isCancelled: CancellationHandler) throws -> String {
        try checkCancellation(isCancelled)
        let triangles = triangulate(isCancelled: isCancelled).polygons
        let strings = try triangles.map { polygon in
            try checkCancellation(isCancelled)
            return polygon.stlString(options: options)
        }
        try checkCancellation(isCancelled)
        return """
        solid \(options.name)
        \(strings.joined(separator: "\n"))
        endsolid \(options.name)
        """
    }

    /// A closure that maps a Euclid material to an STL facet color.
    /// - Parameter m: A Euclid material to convert, or `nil` for the default material.
    /// - Returns: A Euclid `Color` value.
    typealias STLColorProvider = @Sendable (_ m: Material?) -> Color?

    /// Return binary STL data for the mesh.
    /// - Parameter colorLookup: A closure to map Euclid materials to STL facet colors. Use `nil` for default mapping.
    /// - Returns: A Euclid `Color` value.
    func stlData(colorLookup: STLColorProvider? = nil) -> Data {
        stlData(options: .init(colorLookup: colorLookup))
    }

    /// Return binary STL data for the mesh.
    /// - Parameter options: The output ooptions for the STL file
    /// - Returns: The encoded STL data.
    /// - Note: Facet RGB components are clamped to 0...1 and quantized to 5 bits using the VisCAM/SolidView
    ///   convention, without gamma conversion. STL color extensions do not declare a color space.
    ///   Use `colorLookup` to convert components when the destination requires another convention.
    func stlData(options: STLBinaryOptions) -> Data {
        try! stlData(options: options, isCancelled: { false })
    }

    /// Returns binary STL data, throwing `CancellationError` when cancelled.
    func stlData(colorLookup: STLColorProvider? = nil, isCancelled: CancellationHandler) throws -> Data {
        try stlData(options: .init(colorLookup: colorLookup), isCancelled: isCancelled)
    }

    /// Returns binary STL data, throwing `CancellationError` when cancelled.
    func stlData(options: STLBinaryOptions, isCancelled: CancellationHandler) throws -> Data {
        try checkCancellation(isCancelled)
        let triangles = triangulate(isCancelled: isCancelled).polygons
        try checkCancellation(isCancelled)
        let bufferSize = headerSize + 4 + triangles.count * triangleSize
        let buffer = Buffer(capacity: bufferSize)
        options.header.copyBytes(to: buffer.buffer, count: min(options.header.count, 80))
        buffer.count = headerSize
        buffer.append(UInt32(triangles.count))
        for triangle in triangles {
            try checkCancellation(isCancelled)
            buffer.append(triangle, options: options)
        }
        try checkCancellation(isCancelled)
        return Data(buffer)
    }

    /// Return STL data for the mesh.
    func stlData(format: STLFormat) -> Data {
        try! stlData(format: format, isCancelled: { false })
    }

    /// Returns STL data in the selected format, throwing `CancellationError` when cancelled.
    func stlData(format: STLFormat, isCancelled: CancellationHandler) throws -> Data {
        switch format {
        case let .binary(options):
            try stlData(options: options, isCancelled: isCancelled)
        case let .text(options):
            try Data(stlString(options: options, isCancelled: isCancelled).utf8)
        }
    }
}

private extension Polygon {
    func stlString(options: STLTextOptions) -> String {
        """
        facet normal \((options.zeroNormals ? .zero : plane.normal).stlString)
        \(options.indent)outer loop
        \(vertices.map {
            "\(options.indent)\(options.indent)vertex \($0.position.stlString)"
        }.joined(separator: "\n"))
        \(options.indent)endloop
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

private extension Buffer {
    func append(_ vector: Vector) {
        append(Float(vector.x))
        append(Float(vector.y))
        append(Float(vector.z))
    }

    func append(_ color: Color) {
        let red = UInt16(round(color.red.clamped(to: 0 ... 1) * 31))
        let green = UInt16(round(color.green.clamped(to: 0 ... 1) * 31))
        let blue = UInt16(round(color.blue.clamped(to: 0 ... 1) * 31))
        append(0x8000 | red << 10 | green << 5 | blue)
    }

    func append(_ polygon: Polygon, options: STLBinaryOptions) {
        append(options.zeroNormals ? .zero : polygon.plane.normal)
        polygon.vertices.forEach { append($0.position) }
        if let color = options.colorLookup(polygon.material) {
            append(color)
        } else {
            count += 2
        }
    }
}

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

#if canImport(ModelIO)
import ModelIO
#endif

#if canImport(SceneKit)
import SceneKit
#endif

@Sendable
func defaultColorMapping(_ material: Polygon.Material?) -> Color? {
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
    #if canImport(ModelIO)
    if let mdlMaterial = material as? MDLMaterial,
       let color = mdlMaterial.property(with: .baseColor).flatMap({ Color($0) })
    {
        let opacity = mdlMaterial.property(with: .opacity)
        let alpha = opacity?.type == .float ? Double(opacity?.floatValue ?? 1) : 1
        return color.withAlphaComponent(color.alpha * alpha)
    }
    #endif
    #if canImport(SceneKit)
    if let scnMaterial = material as? SCNMaterial {
        return defaultColorMapping(scnMaterial.diffuse.contents as? AnyHashable)
    }
    #endif
    return nil
}

// MARK: Import

public extension Mesh {
    /// Create a mesh from an STL string.
    /// - Parameters:
    ///   - stlString: ASCII STL string data.
    ///   - options: The import options.
    init?(stlString: String, options: ImportOptions = .init()) {
        try? self.init(stlString: stlString, options: options, isCancelled: { false })
    }

    /// Creates a mesh from STL text, throwing `CancellationError` if the callback returns `true`.
    init?(
        stlString: String,
        options: ImportOptions = .init(),
        isCancelled: CancellationHandler
    ) throws {
        try checkCancellation(isCancelled)
        var lines = ArraySlice(stlString.components(separatedBy: .newlines))
        guard let mesh = try lines.readSolid(isCancelled: isCancelled) else {
            return nil
        }
        self = (options.repairWinding ?? true) ? mesh.withConsistentWinding(isCancelled: isCancelled) : mesh
        try checkCancellation(isCancelled)
    }

    /// A closure that maps an STL facet color to a Euclid material.
    /// - Parameter c: A Euclid `Color` to convert, or `nil` for the default color.
    /// - Returns: A Euclid `Material` value, or `nil` for the default material.
    typealias STLMaterialProvider = @Sendable (_ c: Color?) -> Material?

    /// Create a mesh from STL data.
    /// - Parameters:
    ///   - stlData: binary or ASCII STL file data
    ///   - options: The import options.
    ///   - materialLookup: A closure to map STL facet colors to Euclid materials. Use `nil` for default mapping.
    /// - Note: Binary facet and header color components are normalized without gamma conversion.
    ///   STL color extensions do not declare a color space. Colors use Euclid's sRGB convention
    ///   unless `materialLookup` supplies a source-specific conversion.
    init?(
        stlData: Data,
        options: ImportOptions = .init(),
        materialLookup: STLMaterialProvider? = nil
    ) {
        try? self.init(
            stlData: stlData,
            options: options,
            materialLookup: materialLookup,
            isCancelled: { false }
        )
    }

    /// Creates a mesh from STL data, throwing `CancellationError` when cancelled.
    init?(
        stlData: Data,
        options: ImportOptions = .init(),
        materialLookup: STLMaterialProvider? = nil,
        isCancelled: CancellationHandler
    ) throws {
        try checkCancellation(isCancelled)
        if stlData.count >= 5,
           let prefix = String(data: stlData[0 ..< 5], encoding: .utf8),
           prefix.caseInsensitiveCompare("solid") == .orderedSame,
           let string = String(data: stlData, encoding: .utf8)
        {
            try self.init(stlString: string, options: options, isCancelled: isCancelled)
            return
        }
        var offset = headerSize
        guard stlData.count >= offset + 4 else {
            return nil
        }
        var baseColor: Color?
        let colorPrefix = "COLOR=".data(using: .utf8)!
        if let range = stlData[0 ..< headerSize].range(of: colorPrefix) {
            baseColor = Color(
                red: Double(stlData[range.upperBound]) / 255,
                green: Double(stlData[range.upperBound + 1]) / 255,
                blue: Double(stlData[range.upperBound + 2]) / 255,
                alpha: Double(stlData[range.upperBound + 3]) / 255
            )
        }
        let count = Int(stlData.withUnsafeBytes { $0.readUInt32(at: &offset) })
        guard stlData.count >= offset + count * triangleSize else {
            return nil
        }
        let materialLookup = materialLookup ?? { $0 }
        let triangles = try stlData.withUnsafeBytes { buffer -> [Polygon] in
            try (0 ..< count).compactMap { _ in
                try checkCancellation(isCancelled)
                return buffer.readTriangle(
                    at: &offset,
                    baseColor: baseColor,
                    materialLookup: materialLookup
                )
            }
        }
        var mesh = Mesh(triangles)
        if options.repairWinding ?? true {
            mesh = mesh.withConsistentWinding(isCancelled: isCancelled)
        }
        try checkCancellation(isCancelled)
        self = mesh
    }
}

private extension ArraySlice<String> {
    mutating func readCommand(_ name: String, parts: inout [Double]) -> Bool {
        var line = ""
        guard readCommand(name, line: &line) else {
            return false
        }
        parts = line[name.endIndex...]
            .components(separatedBy: .whitespaces)
            .compactMap { Double($0) }
        return true
    }

    mutating func readCommand(_ name: String) -> Bool {
        var line = ""
        return readCommand(name, line: &line)
    }

    mutating func readCommand(_ name: String, line: inout String) -> Bool {
        while let line = first?.trimmingCharacters(in: .whitespaces), line.isEmpty {
            removeFirst()
        }
        line = first?.trimmingCharacters(in: .whitespaces) ?? ""
        if line.prefix(name.count).caseInsensitiveCompare(name) == .orderedSame {
            removeFirst()
            return true
        }
        return false
    }

    mutating func readVertex() -> Vertex? {
        var parts = [Double]()
        guard readCommand("vertex", parts: &parts) else {
            return nil
        }
        return Vertex(parts)
    }

    mutating func readTriangle() -> Polygon? {
        guard readCommand("facet"),
              readCommand("outer"),
              let a = readVertex(),
              let b = readVertex(),
              let c = readVertex(),
              readCommand("endloop"),
              readCommand("endfacet")
        else {
            return nil
        }
        return Polygon([a, b, c])
    }

    mutating func readSolid(isCancelled: CancellationHandler) throws -> Mesh? {
        guard readCommand("solid") else {
            return nil
        }
        var triangles = [Polygon]()
        while let triangle = readTriangle() {
            try checkCancellation(isCancelled)
            triangles.append(triangle)
        }
        guard readCommand("endsolid") else {
            return nil
        }
        return Mesh(triangles)
    }
}

private extension UnsafeRawBufferPointer {
    func readUInt16(at offset: inout Int) -> UInt16 {
        defer { offset += 2 }
        return load(fromByteOffset: offset, as: UInt16.self)
    }

    func readUInt32(at offset: inout Int) -> UInt32 {
        defer { offset += 4 }
        return loadUnaligned(fromByteOffset: offset, as: UInt32.self)
    }

    func readFloat(at offset: inout Int) -> Float {
        defer { offset += 4 }
        return loadUnaligned(fromByteOffset: offset, as: Float.self)
    }

    func readVector(at offset: inout Int) -> Vector {
        .init(
            Double(readFloat(at: &offset)),
            Double(readFloat(at: &offset)),
            Double(readFloat(at: &offset))
        )
    }

    func readSolidViewColor(at offset: inout Int) -> Color? {
        let color = readUInt16(at: &offset)
        guard color & 0x8000 > 0 else {
            return nil
        }
        let blue = Double(color & 31) / 31
        let green = Double((color & (31 << 5)) >> 5) / 31
        let red = Double((color & (31 << 10)) >> 10) / 31
        return .init(red: red, green: green, blue: blue)
    }

    func readMaterialiseMagicsColor(at offset: inout Int) -> Color? {
        let color = readUInt16(at: &offset)
        guard color & 0x8000 == 0 else {
            return nil
        }
        let red = Double(color & 31) / 31
        let green = Double((color & (31 << 5)) >> 5) / 31
        let blue = Double((color & (31 << 10)) >> 10) / 31
        return .init(red: red, green: green, blue: blue)
    }

    func readTriangle(
        at offset: inout Int,
        baseColor: Color?,
        materialLookup: Mesh.STLMaterialProvider
    ) -> Polygon? {
        _ = readVector(at: &offset) // Normal (ignored)
        let vertices = (0 ..< 3).map { _ in readVector(at: &offset) }
        let color = baseColor.map { readMaterialiseMagicsColor(at: &offset) ?? $0 } ?? readSolidViewColor(at: &offset)
        return Polygon(vertices, material: materialLookup(color))
    }
}
