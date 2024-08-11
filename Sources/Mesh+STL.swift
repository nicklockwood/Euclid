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
public struct STLTextOptions {
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
public struct STLBinaryOptions {
    /// Data to use for file header.
    /// Note: data will be padded to 80 bytes. If more than 80 bytes are provided, data will be truncated.
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
public enum STLFormat {
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
        """
        solid \(options.name)
        \(triangulate().polygons.map {
            $0.stlString(options: options)
        }.joined(separator: "\n"))
        endsolid \(options.name)
        """
    }

    /// A closure that maps a Euclid material to an STL facet color.
    /// - Parameter m: A Euclid material to convert, or `nil` for the default material.
    /// - Returns: A Euclid `Color` value.
    typealias STLColorProvider = (_ m: Material?) -> Color?

    /// Return binary STL data for the mesh.
    /// - Parameter colorLookup: A closure to map Euclid materials to STL facet colors. Use `nil` for default mapping.
    /// - Returns: A Euclid `Color` value.
    func stlData(colorLookup: STLColorProvider? = nil) -> Data {
        stlData(options: .init(colorLookup: colorLookup))
    }

    /// Return binary STL data for the mesh.
    /// - Parameter options: The output ooptions for the STL file
    /// - Returns: The encoded STL data.
    func stlData(options: STLBinaryOptions) -> Data {
        let triangles = triangulate().polygons
        let bufferSize = headerSize + 4 + triangles.count * triangleSize
        let buffer = Buffer(capacity: bufferSize)
        options.header.copyBytes(to: buffer.buffer, count: min(options.header.count, 80))
        buffer.count = headerSize
        buffer.append(UInt32(triangles.count))
        triangles.forEach { buffer.append($0, options: options) }
        return Data(buffer)
    }

    /// Return STL data for the mesh.
    func stlData(format: STLFormat) -> Data {
        switch format {
        case let .binary(options):
            return stlData(options: options)
        case let .text(options):
            return Data(stlString(options: options).utf8)
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
        let red = UInt16(round(color.r * 31))
        let green = UInt16(round(color.g * 31))
        let blue = UInt16(round(color.b * 31))
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
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SceneKit)
import SceneKit
#endif

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
    /// - Parameter stlString: ASCII STL string data.
    init?(stlString: String) {
        var lines = ArraySlice(stlString.components(separatedBy: .newlines))
        guard let mesh = lines.readSolid() else {
            return nil
        }
        self = mesh
    }

    /// A closure that maps an STL facet color to a Euclid material.
    /// - Parameter c: A Euclid `Color` to convert, or `nil` for the default color.
    /// - Returns: A Euclid `Material` value, or `nil` for the default material.
    typealias STLMaterialProvider = (_ c: Color?) -> Material?

    /// Create a mesh from STL data.
    /// - Parameters
    ///   - stlData: binary or ASCII STL file data
    ///   - materialLookup: A closure to map STL facet colors to Euclid materials. Use `nil` for default mapping.
    init?(stlData: Data, materialLookup: STLMaterialProvider? = nil) {
        if stlData.count >= 5,
           let prefix = String(data: stlData[0 ..< 5], encoding: .utf8),
           prefix.caseInsensitiveCompare("solid") == .orderedSame,
           let string = String(data: stlData, encoding: .utf8)
        {
            self.init(stlString: string)
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
                Double(stlData[range.upperBound]) / 255,
                Double(stlData[range.upperBound + 1]) / 255,
                Double(stlData[range.upperBound + 2]) / 255,
                Double(stlData[range.upperBound + 3]) / 255
            )
        }
        let count = Int(stlData.withUnsafeBytes { $0.readUInt32(at: &offset) })
        guard stlData.count >= offset + count * triangleSize else {
            return nil
        }
        let materialLookup = materialLookup ?? { $0 }
        let triangles = stlData.withUnsafeBytes { buffer -> [Polygon] in
            (0 ..< count).compactMap { _ in
                buffer.readTriangle(at: &offset, baseColor: baseColor, materialLookup: materialLookup)
            }
        }
        self.init(triangles)
    }
}

private extension ArraySlice where Element == String {
    mutating func readCommand(_ name: String, parts: inout [String]) -> Bool {
        var line = ""
        guard readCommand(name, line: &line) else {
            return false
        }
        parts = line[name.endIndex...]
            .components(separatedBy: .whitespaces)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
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
        var parts = [String]()
        guard readCommand("vertex", parts: &parts) else {
            return nil
        }
        return Vertex(parts.compactMap(Double.init))
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

    mutating func readSolid() -> Mesh? {
        guard readCommand("solid") else {
            return nil
        }
        var triangles = [Polygon]()
        while let triangle = readTriangle() {
            triangles.append(triangle)
        }
        guard readCommand("endsolid") else {
            return nil
        }
        return Mesh(triangles)
    }
}

private extension UnsafeRawBufferPointer {
    #if swift(<5.7)
    func loadUnaligned<T>(fromByteOffset offset: Int = 0, as type: T.Type) -> T {
        // Note: this polyfill implementation only works for 4-byte types
        let source = baseAddress.map(UnsafeRawPointer.init)!
        var storage: UInt32 = 0
        return withUnsafeMutablePointer(to: &storage) {
            let raw = UnsafeMutableRawPointer($0)
            raw.copyMemory(from: source + offset, byteCount: 4)
            return raw.load(as: type)
        }
    }
    #endif

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
        return .init(red, green, blue)
    }

    func readMaterialiseMagicsColor(at offset: inout Int) -> Color? {
        let color = readUInt16(at: &offset)
        guard color & 0x8000 == 0 else {
            return nil
        }
        let red = Double(color & 31) / 31
        let green = Double((color & (31 << 5)) >> 5) / 31
        let blue = Double((color & (31 << 10)) >> 10) / 31
        return .init(red, green, blue)
    }

    func readTriangle(at offset: inout Int, baseColor: Color?, materialLookup: Mesh.STLMaterialProvider) -> Polygon? {
        _ = readVector(at: &offset) // Normal (ignored)
        let vertices = (0 ..< 3).map { _ in readVector(at: &offset) }
        let color = baseColor.map { readMaterialiseMagicsColor(at: &offset) ?? $0 } ?? readSolidViewColor(at: &offset)
        return Polygon(vertices, material: materialLookup(color))
    }
}
