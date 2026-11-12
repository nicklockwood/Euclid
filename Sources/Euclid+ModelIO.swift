//
//  Euclid+ModelIO.swift
//  Euclid
//
//  Created by Nick Lockwood on 09/11/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/Euclid
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

#if canImport(ModelIO)

import ModelIO

#if canImport(SceneKit)
import SceneKit.ModelIO
#endif

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

public extension MDLAsset {
    /// A closure that maps a Euclid material to a Model I/O material.
    /// - Parameter material: A polygon material, or `nil` for the default material.
    /// - Returns: The Model I/O material, or `nil` to use a default white material.
    typealias MDLMaterialProvider = (_ material: Polygon.Material?) throws -> MDLMaterial?

    /// Creates a Model I/O asset from a mesh, preserving polygon groups and vertex attributes.
    /// - Parameters:
    ///   - mesh: The mesh to convert.
    ///   - linearColors: Convert sRGB colors to linear light. Set to `false` for OBJ export.
    ///   - isCancelled: Return `true` to stop conversion with `CancellationError`.
    ///   - materialLookup: Maps polygon materials to Model I/O materials. Use `nil` for default mapping.
    convenience init(
        _ mesh: Mesh,
        linearColors: Bool = true,
        isCancelled: CancellationHandler = { false },
        materialLookup: MDLMaterialProvider? = nil
    ) throws {
        var cancellationCountdown = cancellationCheckInterval
        try checkCancellation(isCancelled)
        let hasTexcoords = mesh.hasTexcoords
        let hasVertexColors = mesh.hasVertexColors
        let allocator = MDLMeshBufferDataAllocator()
        let descriptor = MDLVertexDescriptor()
        var attributes: [(String, MDLVertexFormat, Int)] = [
            (MDLVertexAttributePosition, .float3, 3),
            (MDLVertexAttributeNormal, .float3, 3),
        ]
        if hasTexcoords { attributes.append((MDLVertexAttributeTextureCoordinate, .float2, 2)) }
        if hasVertexColors { attributes.append((MDLVertexAttributeColor, .float4, 4)) }
        var offset = 0
        for (index, attribute) in attributes.enumerated() {
            descriptor.attributes[index] = MDLVertexAttribute(
                name: attribute.0, format: attribute.1, offset: offset, bufferIndex: 0
            )
            offset += attribute.2 * MemoryLayout<Float>.size
        }
        descriptor.layouts[0] = MDLVertexBufferLayout(stride: offset)
        var vertices = [Float]()
        var indicesByVertex = [Vertex: UInt32]()
        var submeshes = [MDLSubmesh]()
        let polygonsByMaterial = mesh.polygonsByMaterial
        for (materialIndex, material) in mesh.materials.enumerated() {
            try checkCancellation(isCancelled, countdown: &cancellationCountdown)
            var indices = [UInt32]()
            var counts = [UInt8]()
            let polygons = polygonsByMaterial[material]?.tessellate(isCancelled: isCancelled) ?? []
            for polygon in polygons
                .flatMap({ $0.vertices.count > 255 ? $0.triangulate(isCancelled: isCancelled) : [$0] })
            {
                counts.append(UInt8(polygon.vertices.count))
                for vertex in polygon.vertices {
                    try checkCancellation(isCancelled, countdown: &cancellationCountdown)
                    if let index = indicesByVertex[vertex] {
                        indices.append(index)
                        continue
                    }
                    let index = UInt32(indicesByVertex.count)
                    indicesByVertex[vertex] = index
                    indices.append(index)
                    let p = vertex.position, n = vertex.normal, uv = vertex.texcoord
                    let c = linearColors ? vertex.color.toLinear() : vertex.color
                    vertices += [p.x, p.y, p.z, n.x, n.y, n.z].map(Float.init)
                    if hasTexcoords { vertices += [uv.x, uv.y].map(Float.init) }
                    if hasVertexColors { vertices += [c.red, c.green, c.blue, c.alpha].map(Float.init) }
                }
            }
            let topology = MDLSubmeshTopology()
            topology.faceCount = counts.count
            topology.faceTopology = allocator.newBuffer(with: Data(counts), type: .index)
            let name = "material_\(materialIndex)"
            let mapped: MDLMaterial = if let materialLookup {
                try materialLookup(material) ?? MDLMaterial(Color.white, name: name)
            } else {
                try defaultMDLMaterialLookup(material, name: name, linearColors: linearColors)
            }
            submeshes.append(MDLSubmesh(
                name: "material_\(materialIndex)",
                indexBuffer: allocator.newBuffer(with: indices.withUnsafeBytes { Data($0) }, type: .index),
                indexCount: indices.count, indexType: .uInt32, geometryType: .variableTopology,
                material: mapped,
                topology: topology
            ))
        }
        try checkCancellation(isCancelled)
        self.init(bufferAllocator: allocator)
        if !vertices.isEmpty {
            let mesh = MDLMesh(
                vertexBuffer: allocator.newBuffer(with: vertices.withUnsafeBytes { Data($0) }, type: .vertex),
                vertexCount: indicesByVertex.count, descriptor: descriptor, submeshes: submeshes
            )
            mesh.name = "mesh"
            add(mesh)
        }
    }
}

public extension MDLMaterial {
    /// Creates a material with the specified base color and opacity.
    /// - Parameters:
    ///   - color: The sRGB base color, including alpha.
    ///   - name: The material name.
    ///   - linearColors: Convert sRGB components to linear light. Set to `false` for OBJ export.
    convenience init(_ color: Color, name: String = "material", linearColors: Bool = true) {
        self.init(name: name, scatteringFunction: MDLScatteringFunction())
        let rgb = linearColors ? color.toLinear() : color
        setProperty(MDLMaterialProperty(
            name: "baseColor", semantic: .baseColor,
            float3: SIMD3(Float(rgb.red), Float(rgb.green), Float(rgb.blue))
        ))
        setProperty(MDLMaterialProperty(name: "opacity", semantic: .opacity, float: Float(color.alpha)))
    }

    /// Creates a material with an sRGB image as its base color texture.
    /// - Parameters:
    ///   - image: The texture image. Its colors, alpha and orientation are preserved.
    ///   - name: The material name, also used to name the exported texture.
    /// - Throws: An error if the image cannot be converted to texture data.
    convenience init(_ image: CGImage, name: String = "material") throws {
        self.init(Color.white, name: name)
        let width = image.width, height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        guard let space = CGColorSpace(name: CGColorSpace.sRGB), let context = CGContext(
            data: &pixels, width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: width * 4, space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { throw Mesh.IOError("Cannot convert export texture") }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        // Keep premultiplied pixels: Model I/O unpremultiplies them when writing the texture.
        let sampler = MDLTextureSampler()
        sampler.texture = MDLTexture(
            data: Data(pixels), topLeftOrigin: true, name: "\(name).png",
            dimensions: SIMD2(Int32(width), Int32(height)), rowStride: width * 4,
            channelCount: 4, channelEncoding: .uInt8, isCube: false
        )
        let filter = MDLTextureFilter()
        filter.sWrapMode = .repeat
        filter.tWrapMode = .repeat
        filter.magFilter = .nearest
        sampler.hardwareFilter = filter
        setProperty(MDLMaterialProperty(name: "baseColor", semantic: .baseColor, textureSampler: sampler))
    }
}

func defaultMDLMaterialLookup(_ value: AnyHashable?, name: String, linearColors: Bool) throws -> MDLMaterial {
    if let material = value as? MDLMaterial { return material }
    #if canImport(SceneKit)
    // Compatibility for callers already supplying SceneKit materials. Geometry never passes through SceneKit.
    if let material = value as? SCNMaterial { return MDLMaterial(scnMaterial: material) }
    #endif
    if let color = defaultColorMapping(value) {
        return MDLMaterial(color, name: name, linearColors: linearColors)
    }
    var image: CGImage?
    if let value = value as CFTypeRef?, CFGetTypeID(value) == CGImage.typeID {
        image = (value as! CGImage)
    }
    #if canImport(AppKit)
    if let value = value as? NSImage { image = value.cgImage(forProposedRect: nil, context: nil, hints: nil) }
    #elseif canImport(UIKit)
    if let value = value as? UIImage { image = value.cgImage }
    #endif
    if let image { return try MDLMaterial(image, name: name) }
    return MDLMaterial(Color.white, name: name, linearColors: linearColors)
}

public extension Mesh {
    /// A closure that maps a Model I/O material to a Euclid material.
    /// - Parameter material: The Model I/O material to convert.
    /// - Returns: A Euclid material, or `nil` for the default material.
    typealias MDLMaterialProvider = (_ material: MDLMaterial) throws -> Material?

    /// Creates a mesh from the objects in a Model I/O asset.
    /// - Parameters:
    ///   - asset: The asset to convert. Object transforms are sampled at time zero.
    ///   - ignoringTransforms: Ignore transforms on the asset's objects and their children.
    ///   - linearColors: Interpret vertex RGB as linear light and convert to sRGB. Use `false` for OBJ or PLY.
    ///   - isCancelled: Return `true` to stop conversion with `CancellationError`.
    ///   - materialLookup: Maps materials to Euclid materials. If omitted, retains the original `MDLMaterial`.
    /// - Throws: An error for malformed or unsupported mesh data, or from material mapping.
    init(
        _ asset: MDLAsset,
        ignoringTransforms: Bool = false,
        linearColors: Bool = true,
        isCancelled: CancellationHandler = { false },
        materialLookup: MDLMaterialProvider? = nil
    ) throws {
        try checkCancellation(isCancelled)
        self = try .merge((0 ..< asset.count).map {
            try Mesh(
                asset.object(at: $0), ignoringTransforms: ignoringTransforms,
                linearColors: linearColors, isCancelled: isCancelled, materialLookup: materialLookup
            )
        })
    }

    /// Creates a mesh from a Model I/O object and its descendants, including `MDLMesh` objects.
    /// - Parameters:
    ///   - object: The object to convert. Transforms are sampled at time zero; ancestor transforms are excluded.
    ///   - ignoringTransforms: Ignore transforms on this object and its children.
    ///   - linearColors: Interpret vertex RGB as linear light and convert to sRGB. Alpha is unchanged.
    ///   - isCancelled: Return `true` to stop conversion with `CancellationError`.
    ///   - materialLookup: Maps materials to Euclid materials. If omitted, retains the original `MDLMaterial`.
    /// - Throws: An error for malformed or unsupported mesh data, or from material mapping.
    init(
        _ object: MDLObject,
        ignoringTransforms: Bool = false,
        linearColors: Bool = true,
        isCancelled: CancellationHandler = { false },
        materialLookup: MDLMaterialProvider? = nil
    ) throws {
        try checkCancellation(isCancelled)
        var polygons = [Polygon]()
        func visit(_ object: MDLObject, transform: simd_float4x4) throws {
            try checkCancellation(isCancelled)
            let transform = ignoringTransforms ? matrix_identity_float4x4 :
                (object.transform?.resetsTransform == true ? matrix_identity_float4x4 : transform) *
                (object.transform?.localTransform?(atTime: 0) ?? object.transform?.matrix ?? matrix_identity_float4x4)
            if let mesh = object as? MDLMesh {
                polygons += try mesh.euclidPolygons(
                    transform: transform, linearColors: linearColors, isCancelled: isCancelled,
                    materialLookup: materialLookup
                )
            }
            for child in object.children.objects {
                try visit(child, transform: transform)
            }
        }
        try visit(object, transform: matrix_identity_float4x4)
        try checkCancellation(isCancelled)
        self.init(polygons)
    }
}

private extension MDLMesh {
    func euclidPolygons(
        transform: simd_float4x4,
        linearColors: Bool,
        isCancelled: CancellationHandler,
        materialLookup: Mesh.MDLMaterialProvider?
    ) throws -> [Polygon] {
        var cancellationCountdown = cancellationCheckInterval
        if vertexCount == 0 { return [] }
        guard let positions = vertexAttributeData(forAttributeNamed: MDLVertexAttributePosition, as: .float3) else {
            throw Mesh.IOError("Missing Model I/O vertex positions")
        }
        let normals = vertexAttributeData(forAttributeNamed: MDLVertexAttributeNormal, as: .float3)
        let texcoords = vertexAttributeData(forAttributeNamed: MDLVertexAttributeTextureCoordinate, as: .float2)
        let colorFormat = vertexAttributeData(forAttributeNamed: MDLVertexAttributeColor)?.format
        // Preserve the component count when converting. Expanding RGB to float4 can produce
        // an incorrect stride in Model I/O. Supply opaque alpha ourselves for RGB attributes.
        let hasAlpha = colorFormat.map { $0.rawValue & 0xFFFF == 4 } ?? false
        let colors = vertexAttributeData(
            forAttributeNamed: MDLVertexAttributeColor, as: hasAlpha ? .float4 : .float3
        )
        let basis = simd_float3x3(
            SIMD3(transform.columns.0.x, transform.columns.0.y, transform.columns.0.z),
            SIMD3(transform.columns.1.x, transform.columns.1.y, transform.columns.1.z),
            SIMD3(transform.columns.2.x, transform.columns.2.y, transform.columns.2.z)
        )
        let determinant = simd_determinant(basis)
        let normalTransform = determinant == 0 ? matrix_identity_float3x3 : simd_transpose(simd_inverse(basis))
        func values(_ data: MDLVertexAttributeData, _ index: Int, _ count: Int) throws -> [Float] {
            guard data.stride >= count * 4, data.bufferSize >= count * 4,
                  index <= (data.bufferSize - count * 4) / data.stride
            else { throw Mesh.IOError("Model I/O vertex attribute exceeds buffer size") }
            return (0 ..< count).map {
                data.dataStart.loadUnaligned(fromByteOffset: index * data.stride + $0 * 4, as: Float.self)
            }
        }
        var vertices = [Vertex]()
        for index in 0 ..< vertexCount {
            try checkCancellation(isCancelled, countdown: &cancellationCountdown)
            let p = try values(positions, index, 3)
            let position = transform * SIMD4(p[0], p[1], p[2], 1)
            var normal = Vector.zero
            if let normals, determinant != 0 {
                let n = try values(normals, index, 3)
                normal = Vector(normalTransform * SIMD3(n[0], n[1], n[2])).normalized()
            }
            var uv = Vector.zero
            if let texcoords {
                let t = try values(texcoords, index, 2)
                uv = Vector(Double(t[0]), Double(t[1]))
            }
            var color = Color.white
            if let colors {
                let c = try values(colors, index, hasAlpha ? 4 : 3)
                color = Color(SIMD4(c[0], c[1], c[2], hasAlpha ? c[3] : 1))
                if linearColors { color = color.toSRGB() }
            }
            let p3 = Vector(Double(position.x), Double(position.y), Double(position.z))
            guard p3.x.isFinite, p3.y.isFinite, p3.z.isFinite else {
                throw Mesh.IOError("Nonfinite Model I/O vertex position")
            }
            vertices.append(Vertex(p3, normal: normal, texcoord: uv, color: color))
        }
        var polygons = [Polygon]()
        for case let submesh as MDLSubmesh in submeshes ?? [] {
            try checkCancellation(isCancelled, countdown: &cancellationCountdown)
            let buffer = submesh.indexBuffer(asIndexType: .uInt32)
            guard submesh.indexCount <= buffer.length / 4 else {
                throw Mesh.IOError("Model I/O index count exceeds buffer size")
            }
            let map = buffer.map()
            let indices = try (0 ..< submesh.indexCount).map {
                try checkCancellation(isCancelled, countdown: &cancellationCountdown)
                return Int(map.bytes.loadUnaligned(fromByteOffset: $0 * 4, as: UInt32.self))
            }
            guard indices.allSatisfy({ vertices.indices.contains($0) }) else {
                throw Mesh.IOError("Model I/O index exceeds vertex count")
            }
            let material: Mesh.Material? = if let source = submesh.material {
                if let materialLookup {
                    try materialLookup(source)
                } else {
                    source
                }
            } else {
                nil
            }
            func append(_ indices: ArraySlice<Int>) throws {
                try checkCancellation(isCancelled, countdown: &cancellationCountdown)
                let face = indices.map { vertices[$0] }
                polygons += [Polygon](determinant < 0 ? Array(face.reversed()) : face, material: material)
            }
            switch submesh.geometryType {
            case .triangles, .quads:
                let count = submesh.geometryType == .triangles ? 3 : 4
                guard indices.count % count == 0 else {
                    throw Mesh.IOError("Incomplete Model I/O face")
                }
                for i in stride(from: 0, to: indices.count, by: count) {
                    try append(indices[i ..< i + count])
                }
            case .triangleStrips:
                if indices.count >= 3 {
                    for i in 0 ..< indices.count - 2 {
                        let face = i % 2 == 0 ? [indices[i], indices[i + 1], indices[i + 2]] :
                            [indices[i + 1], indices[i], indices[i + 2]]
                        try append(face[...])
                    }
                }
            case .variableTopology:
                guard let topology = submesh.topology, let buffer = topology.faceTopology,
                      topology.faceCount <= buffer.length
                else { throw Mesh.IOError("Missing or invalid Model I/O face topology") }
                let map = buffer.map()
                var offset = 0
                for i in 0 ..< topology.faceCount {
                    let count = Int(map.bytes.load(fromByteOffset: i, as: UInt8.self))
                    guard count <= indices.count - offset else {
                        throw Mesh.IOError("Model I/O face exceeds index count")
                    }
                    try append(indices[offset ..< offset + count])
                    offset += count
                }
                guard offset == indices.count else {
                    throw Mesh.IOError("Unused Model I/O face indices")
                }
            default:
                throw Mesh.IOError("Unsupported Model I/O geometry type: \(submesh.geometryType.rawValue)")
            }
        }
        return polygons
    }
}

public extension Color {
    /// Creates a color from a numeric Model I/O material property.
    /// - Parameters:
    ///   - property: A color, float3 or float4 property. Other property types return `nil`.
    ///   - linearColors: Override the RGB encoding. By default, float components are linear and
    ///     CGColors use their declared color space. Alpha is never gamma converted.
    init?(_ property: MDLMaterialProperty, linearColors: Bool? = nil) {
        let color: Color
        switch property.type {
        case .float3:
            color = Color(property.float3Value)
        case .float4:
            color = Color(property.float4Value)
        case .color:
            guard let cgColor = property.color else { return nil }
            if linearColors == nil {
                self.init(cgColor)
                return
            }
            guard let c = cgColor.components else { return nil }
            switch c.count {
            case 2:
                color = Color(white: Double(c[0]), alpha: Double(c[1]))
            case 3, 4:
                color = Color(
                    red: Double(c[0]),
                    green: Double(c[1]),
                    blue: Double(c[2]),
                    alpha: Double(cgColor.alpha)
                )
            default:
                return nil
            }
        default:
            return nil
        }
        self = linearColors ?? true ? color.toSRGB() : color
    }
}

/// Compatibility conventions for the file formats whose color paths have been checked.
/// USD uses its default linear Rec.709 space. This does not resolve authored USD color-space metadata.
enum ModelIOColorEncoding {
    case sRGB, linearSRGB

    init?(fileExtension: String) {
        switch fileExtension.lowercased() {
        case "obj", "ply": self = .sRGB
        case "usd", "usda", "usdc", "usdz": self = .linearSRGB
        default: return nil
        }
    }

    var isLinear: Bool {
        self == .linearSRGB
    }
}

private let modelIOColorSemantics: Set<MDLMaterialSemantic> = [.baseColor, .emission, .specular]

/// Gives untagged numeric colors a known file convention, preserving declared CGColor profiles.
func normalizeModelIOColors(_ material: MDLMaterial, linearColors: Bool) {
    for semantic in modelIOColorSemantics {
        if let property = material.property(with: semantic),
           let color = Color(property, linearColors: property.type == .color ? nil : linearColors)
        {
            property.setProperties(MDLMaterialProperty(
                name: property.name, semantic: semantic, color: CGColor(
                    srgbRed: color.red,
                    green: color.green,
                    blue: color.blue,
                    alpha: color.alpha
                )
            ))
        }
    }
}

extension MDLMaterial {
    /// The inspected OBJ and USD exporters serialize raw color components, so prepare their RGB encoding.
    func forExport(linearColors: Bool) -> MDLMaterial {
        let scattering = scatteringFunction is MDLPhysicallyPlausibleScatteringFunction ?
            MDLPhysicallyPlausibleScatteringFunction() : MDLScatteringFunction()
        let result = MDLMaterial(name: name, scatteringFunction: scattering)
        result.base = base?.forExport(linearColors: linearColors)
        for index in 0 ..< count {
            guard let property = self[index] else { continue }
            if modelIOColorSemantics.contains(property.semantic), property.type == .color, let color = Color(property) {
                let rgb = linearColors ? color.toLinear() : color
                result.setProperty(MDLMaterialProperty(
                    name: property.name, semantic: property.semantic,
                    float3: SIMD3(Float(rgb.red), Float(rgb.green), Float(rgb.blue))
                ))
            } else {
                let copy = MDLMaterialProperty(name: property.name, semantic: property.semantic)
                copy.setProperties(property)
                result.setProperty(copy)
            }
        }
        if let base = property(with: .baseColor), base.type == .color,
           let color = Color(base), color.alpha != 1
        {
            let opacity = property(with: .opacity)
            if opacity == nil || opacity?.type == .float {
                result.setProperty(MDLMaterialProperty(
                    name: opacity?.name ?? "opacity", semantic: .opacity,
                    float: Float(color.alpha) * (opacity?.floatValue ?? 1)
                ))
            }
        }
        return result
    }
}

extension Mesh {
    /// The Model I/O file-loading fallback, including format-specific material normalization.
    init(
        modelIOURL url: URL,
        options: ImportOptions = .init(),
        isCancelled: CancellationHandler = { false },
        materialLookup: (@Sendable (AnyHashable?) -> Material?)? = nil
    ) throws {
        try checkCancellation(isCancelled)
        var error: NSError?
        let asset = MDLAsset(
            url: url,
            vertexDescriptor: nil,
            bufferAllocator: nil,
            preserveTopology: true,
            error: &error
        )
        try checkCancellation(isCancelled)
        if let error { throw error }
        asset.loadTextures()
        if url.pathExtension.lowercased() == "obj" {
            try asset.restoreOBJOpacityMaps(from: url, isCancelled: isCancelled)
        }
        let colorEncoding = ModelIOColorEncoding(fileExtension: url.pathExtension)
        let linearColors = colorEncoding?.isLinear ?? true
        var mappedMaterials = Set<ObjectIdentifier>()
        var mesh = try Mesh(asset, linearColors: linearColors, isCancelled: isCancelled) { material in
            if colorEncoding != nil, mappedMaterials.insert(ObjectIdentifier(material)).inserted {
                normalizeModelIOColors(material, linearColors: linearColors)
            }
            if let materialLookup { return materialLookup(material) }
            return material
        }
        let up = Vector(asset.upAxis)
        if up.lengthSquared > 0, !up.isApproximatelyEqual(to: .unitY) {
            mesh = mesh.rotated(by: Rotation(from: up, to: .unitY))
        }
        if options.repairWinding == true { mesh = mesh.withConsistentWinding(isCancelled: isCancelled) }
        try checkCancellation(isCancelled)
        self = mesh
    }
}

#endif
