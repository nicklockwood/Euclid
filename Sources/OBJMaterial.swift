//
//  OBJMaterial.swift
//  Euclid
//
//  Created by Nick Lockwood on 11/11/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

#if canImport(ModelIO)
import ImageIO
import ModelIO

/// Restore numeric colors and diffuse textures omitted or altered by SceneKit's OBJ material conversion.
func restoreExportedOBJMaterials(at url: URL, materials: [String: MDLMaterial]) throws {
    let library = url.deletingPathExtension().appendingPathExtension("mtl")
    let source = try String(contentsOf: library, encoding: .utf8)
    var replacements = [String: [String: String]]()
    for (name, material) in materials {
        var properties = [String: String]()
        if let base = material.property(with: .baseColor) {
            if let color = Color(base, linearColors: false) {
                properties["Kd"] = "Kd \(color.red) \(color.green) \(color.blue)"
            } else {
                let image: CGImage? = if let texture = base.textureSamplerValue?.texture {
                    texture.imageFromTexture()?.takeUnretainedValue()
                } else if let source = base.urlValue.flatMap({ CGImageSourceCreateWithURL($0 as CFURL, nil) }) {
                    CGImageSourceCreateImageAtIndex(source, 0, nil)
                } else {
                    nil
                }
                if let image {
                    let filename = "\(name)-diffuse.png"
                    let imageURL = url.deletingLastPathComponent().appendingPathComponent(filename)
                    guard let destination = CGImageDestinationCreateWithURL(
                        imageURL as CFURL, "public.png" as CFString, 1, nil
                    ) else { throw Mesh.IOError("Cannot write OBJ diffuse texture") }
                    CGImageDestinationAddImage(destination, image, nil)
                    guard CGImageDestinationFinalize(destination)
                    else { throw Mesh.IOError("Cannot write OBJ diffuse texture") }
                    properties["map_Kd"] = "map_Kd \(filename)"
                    properties["Kd"] = "Kd 1 1 1"
                }
            }
        }
        if let emission = material.property(with: .emission).flatMap({ Color($0, linearColors: false) }) {
            properties["Ka"] = "Ka \(emission.red) \(emission.green) \(emission.blue)"
        }
        if let opacity = material.property(with: .opacity), opacity.type == .float {
            properties["d"] = "d \(opacity.floatValue)"
        }
        replacements[name] = properties
    }
    var output = [String](), replaced = Set<String>()
    for line in source.components(separatedBy: .newlines) {
        let parts = line.split(whereSeparator: \.isWhitespace)
        if parts.first == "newmtl" {
            let name = parts.dropFirst().joined(separator: " ")
            let properties = replacements[name] ?? [:]
            replaced = Set(properties.keys)
            if replaced.contains("d") { replaced.insert("Tr") }
            output.append(line)
            output += properties.keys.sorted().compactMap { properties[$0] }
        } else if !replaced.contains(parts.first.map(String.init) ?? "") {
            output.append(line)
        }
    }
    try output.joined(separator: "\n").write(to: library, atomically: true, encoding: .utf8)
}
#endif
