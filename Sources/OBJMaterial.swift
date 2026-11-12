//
//  OBJMaterial.swift
//  Euclid
//
//  Created by Nick Lockwood on 11/11/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

/// Dissolve maps use luminance unless MTL explicitly selects another channel.
struct OBJOpacityMap {
    enum Channel: String {
        case red = "r"
        case green = "g"
        case blue = "b"
        case alpha = "m"
        case luminance = "l"
    }

    let url: URL
    let channel: Channel
    var dissolve = 1.0

    static func read(from objURL: URL) -> [String: OBJOpacityMap] {
        guard let obj = try? String(contentsOf: objURL) else { return [:] }
        var result = [String: OBJOpacityMap]()
        for line in obj.components(separatedBy: .newlines) {
            var tokens = tokens(line)[...]
            guard tokens.popFirst() == "mtllib" else { continue }
            for path in tokens {
                let url = URL(fileURLWithPath: path, relativeTo: objURL.deletingLastPathComponent()).standardizedFileURL
                guard let text = try? String(contentsOf: url) else { continue }
                var name: String?
                var dissolve: Double? = 1
                for line in text.components(separatedBy: .newlines) {
                    var tokens = Self.tokens(line)[...]
                    switch tokens.popFirst() {
                    case "newmtl":
                        name = tokens.joined(separator: " ")
                        dissolve = 1
                        if let name { result[name] = nil }
                    case let command? where command == "d" || command == "Tr":
                        // Halo dissolve and invalid scalar values are left to the platform loader.
                        if tokens.count == 1, let value = tokens.first.flatMap(Double.init), (0 ... 1).contains(value) {
                            dissolve = command == "Tr" ? 1 - value : value
                        } else {
                            dissolve = nil
                        }
                        if let name, var map = result[name] {
                            if let dissolve { map.dissolve = dissolve; result[name] = map }
                            else { result[name] = nil }
                        }
                    case "map_d":
                        guard let name else { continue }
                        if let dissolve, var map = parse(&tokens, relativeTo: url.deletingLastPathComponent()) {
                            map.dissolve = dissolve
                            result[name] = map
                        } else {
                            result[name] = nil
                        }
                    default: break
                    }
                }
            }
        }
        return result
    }

    private static func parse(_ tokens: inout ArraySlice<String>, relativeTo directory: URL) -> OBJOpacityMap? {
        var channel = Channel.luminance
        while let option = tokens.first, option.hasPrefix("-") {
            tokens.removeFirst()
            switch option {
            case "-imfchan":
                guard let value = tokens.popFirst(), let selected = Channel(rawValue: value) else { return nil }
                channel = selected
            case "-blendu", "-blendv", "-clamp", "-cc", "-texres":
                guard tokens.popFirst() != nil else { return nil }
            case "-o", "-s", "-t":
                var count = 0
                while count < 3, let value = tokens.first, Double(value) != nil {
                    tokens.removeFirst()
                    count += 1
                }
                guard count > 0 else { return nil }
            default:
                // Leave unsupported modifiers such as value remapping (-mm) to the platform loader.
                return nil
            }
        }
        guard !tokens.isEmpty else { return nil }
        return OBJOpacityMap(
            url: URL(fileURLWithPath: tokens.joined(separator: " "), relativeTo: directory).standardizedFileURL,
            channel: channel
        )
    }

    private static func tokens(_ line: String) -> [String] {
        var tokens = [String](), token = ""
        var quote: Character?
        var characters = ArraySlice(line)
        while let character = characters.popFirst() {
            if character == "\\", let next = characters.first,
               next.isWhitespace || next == "\"" || next == "'" || next == "#"
            {
                token.append(characters.removeFirst())
            } else if character == quote {
                quote = nil
            } else if quote == nil, character == "\"" || character == "'" {
                quote = character
            } else if quote == nil, character == "#" {
                break
            } else if quote == nil, character.isWhitespace {
                if !token.isEmpty { tokens.append(token); token = "" }
            } else {
                token.append(character)
            }
        }
        guard quote == nil else { return [] }
        if !token.isEmpty { tokens.append(token) }
        return tokens
    }
}

#if canImport(CoreGraphics)

import CoreGraphics

extension CGImage {
    /// Reads ordinary 8-bit grayscale/RGB maps as data, without gamma or profile conversion.
    /// Unsupported layouts remain with the platform loader rather than guessing their encoding.
    func objOpacityImage(for channel: OBJOpacityMap.Channel) -> CGImage? {
        guard bitsPerComponent == 8, !bitmapInfo.contains(.floatComponents), decode == nil,
              let model = colorSpace?.model, model == .rgb || model == .monochrome,
              let data = dataProvider?.data as Data?
        else { return nil }
        let components = bitsPerPixel / 8
        let colorComponents = model == .rgb ? 3 : 1
        let alpha: Int?
        let start: Int
        switch alphaInfo {
        case .none: alpha = nil; start = 0
        case .last, .premultipliedLast: alpha = components - 1; start = 0
        case .first, .premultipliedFirst: alpha = 0; start = 1
        case .noneSkipLast: alpha = nil; start = 0
        case .noneSkipFirst: alpha = nil; start = 1
        default: return nil
        }
        guard components == colorComponents + (alphaInfo == .none ? 0 : 1) else { return nil }
        let (rowBytes, rowOverflow) = width.multipliedReportingOverflow(by: components)
        let (dataBytes, dataOverflow) = bytesPerRow.multipliedReportingOverflow(by: height)
        let (pixelCount, pixelOverflow) = width.multipliedReportingOverflow(by: height)
        let (outputBytes, outputOverflow) = pixelCount.multipliedReportingOverflow(by: 4)
        guard !rowOverflow, !dataOverflow, !pixelOverflow, !outputOverflow,
              bytesPerRow >= rowBytes, data.count >= dataBytes
        else { return nil }
        let order = bitmapInfo.intersection(.byteOrderMask)
        let reversed: Bool
        switch order {
        case .byteOrderDefault: reversed = false
        case .byteOrder32Big where components == 4: reversed = false
        case .byteOrder32Little where components == 4: reversed = true
        case .byteOrder16Big where components == 2: reversed = false
        case .byteOrder16Little where components == 2: reversed = true
        default: return nil
        }
        let premultiplied = alphaInfo == .premultipliedFirst || alphaInfo == .premultipliedLast
        var pixels = [UInt8](repeating: 0, count: outputBytes)
        data.withUnsafeBytes { bytes in
            let bytes = bytes.bindMemory(to: UInt8.self)
            for y in 0 ..< self.height {
                for x in 0 ..< self.width {
                    let offset = y * self.bytesPerRow + x * components
                    func component(_ index: Int) -> Double {
                        Double(bytes[offset + (reversed ? components - 1 - index : index)]) / 255
                    }
                    let a = alpha.map(component) ?? 1
                    func color(_ index: Int) -> Double {
                        let value = component(start + (model == .monochrome ? 0 : index))
                        return premultiplied ? (a > 0 ? min(value / a, 1) : 0) : value
                    }
                    let value: Double = switch channel {
                    case .red: color(0)
                    case .green: color(1)
                    case .blue: color(2)
                    case .alpha: a
                    case .luminance: 0.2126 * color(0) + 0.7152 * color(1) + 0.0722 * color(2)
                    }
                    let opacity = UInt8((value * 255).rounded())
                    let output = (y * self.width + x) * 4
                    for index in 0 ..< 4 {
                        pixels[output + index] = opacity
                    }
                }
            }
        }
        guard let provider = CGDataProvider(data: Data(pixels) as CFData),
              let space = CGColorSpace(name: CGColorSpace.sRGB)
        else { return nil }
        return CGImage(
            width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
            bytesPerRow: width * 4, space: space,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider, decode: nil, shouldInterpolate: shouldInterpolate, intent: .defaultIntent
        )
    }
}

#endif

#if canImport(ModelIO)

import ImageIO
import ModelIO

extension MDLAsset {
    /// Normalize OBJ opacity before passing materials to callbacks or rendering adapters.
    func restoreOBJOpacityMaps(from url: URL) {
        let maps = OBJOpacityMap.read(from: url)
        guard !maps.isEmpty else { return }
        var visited = Set<ObjectIdentifier>()
        var textures = [String: MDLTexture]()
        for case let mesh as MDLMesh in self.childObjects(of: MDLMesh.self) {
            for case let submesh as MDLSubmesh in mesh.submeshes ?? [] {
                guard let material = submesh.material, visited.insert(ObjectIdentifier(material)).inserted,
                      let map = maps[material.name],
                      let property = material.property(with: .opacity),
                      let originalSampler = property.textureSamplerValue
                else { continue }
                let key = map.url.absoluteString + "#" + map.channel.rawValue + "#" + String(map.dissolve)
                let texture: MDLTexture
                if let cached = textures[key] {
                    texture = cached
                } else {
                    guard let source = CGImageSourceCreateWithURL(map.url as CFURL, nil),
                          let original = CGImageSourceCreateImageAtIndex(source, 0, nil),
                          let mask = original.objOpacityImage(for: map.channel),
                          let pixels = mask.dataProvider?.data as Data?,
                          let width = Int32(exactly: mask.width), let height = Int32(exactly: mask.height)
                    else { continue }
                    // Store data in one channel, including the scalar once. Both rendering adapters
                    // otherwise lose the scalar when the material property contains a texture.
                    let opacity = stride(from: 3, to: pixels.count, by: 4).map {
                        UInt8((Double(pixels[$0]) * map.dissolve).rounded())
                    }
                    texture = MDLTexture(
                        data: Data(opacity), topLeftOrigin: true, name: "opacity_\(textures.count).png",
                        dimensions: SIMD2(width, height), rowStride: mask.width,
                        channelCount: 1, channelEncoding: .uInt8, isCube: false
                    )
                    textures[key] = texture
                }
                let sampler = MDLTextureSampler()
                sampler.texture = texture
                sampler.hardwareFilter = originalSampler.hardwareFilter
                sampler.transform = originalSampler.transform
                material.setProperty(MDLMaterialProperty(
                    name: property.name,
                    semantic: .opacity,
                    textureSampler: sampler
                ))
            }
        }
    }
}

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

#if canImport(SceneKit)

import SceneKit

extension SCNScene {
    /// Put OBJ scalar dissolve values into alpha, which is what SceneKit's opacity shader samples.
    func restoreOBJOpacityMaps(from url: URL) {
        var visited = Set<ObjectIdentifier>()
        var materials = [SCNMaterial]()
        func visit(_ node: SCNNode) {
            for material in node.geometry?.materials ?? [] {
                guard visited.insert(ObjectIdentifier(material)).inserted,
                      material.transparencyMode == .aOne,
                      let contents = material.transparent.contents,
                      !(contents is NSNumber), defaultColorMapping(contents as? AnyHashable) == nil
                else { continue }
                materials.append(material)
            }
        }
        visit(rootNode)
        rootNode.enumerateChildNodes { node, _ in visit(node) }
        guard !materials.isEmpty else { return }
        let maps = OBJOpacityMap.read(from: url)
        var images = [String: CGImage]()
        for material in materials {
            guard let name = material.name, let map = maps[name] else { continue }
            if map.channel == .alpha {
                material.transparency = CGFloat(map.dissolve)
                continue
            }
            let key = map.url.absoluteString + "#" + map.channel.rawValue
            let image: CGImage
            if let cached = images[key] {
                image = cached
            } else {
                guard let source = CGImageSourceCreateWithURL(map.url as CFURL, nil),
                      let original = CGImageSourceCreateImageAtIndex(source, 0, nil),
                      let mask = original.objOpacityImage(for: map.channel)
                else { continue }
                image = mask
                images[key] = mask
            }
            material.transparent.contents = image
            material.transparent.textureComponents = .all
            material.transparency = CGFloat(map.dissolve)
        }
    }
}

#endif
