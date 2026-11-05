//
//  Euclid+RealityKit.swift
//  Euclid
//
//  Created by Nick Lockwood on 05/10/2022.
//  Copyright © 2022 Nick Lockwood. All rights reserved.
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

#if canImport(RealityKit)

import CoreGraphics
import Metal
import RealityKit

@available(tvOS 26.0, *)
private final class MaterialWrapper: NSObject, @unchecked Sendable {
    let material: RealityKit.Material

    init(_ material: Material) {
        self.material = material
    }
}

// MARK: export

@available(tvOS 26.0, *)
public extension RealityKit.Transform {
    /// Creates a RealityKit`Transform` from a Euclid ``Transform``.
    /// - Parameter transform: The Euclid transform  to convert into a RealityKit transform.
    init(_ transform: Euclid.Transform) {
        self.init(
            scale: .init(transform.scale),
            rotation: .init(transform.rotation),
            translation: .init(transform.translation)
        )
    }
}

@MainActor
@available(tvOS 26.0, *)
private func defaultMaterialLookup(_ material: Polygon.Material?) -> RealityKit.Material? {
    switch material {
    case let wrapper as MaterialWrapper:
        return wrapper.material
    case let color as Color:
        return defaultMaterialLookup(OSColor(color))
    case let color as OSColor:
        var material = SimpleMaterial()
        material.color = .init(tint: color)
        return material
    case let color as CGColor where CFGetTypeID(color) == CGColor.typeID:
        return defaultMaterialLookup(OSColor(cgColor: color))
    case let image as OSImage:
        return defaultMaterialLookup(image.cgImage)
    case let image as CGImage where CFGetTypeID(image) == CGImage.typeID:
        let options = TextureResource.CreateOptions(semantic: .color)
        #if os(tvOS)
        let texture = try? TextureResource(image: image, options: options)
        #else
        let texture = try? TextureResource.generate(from: image, options: options)
        #endif
        guard let texture else { return nil }
        let descriptor = MTLSamplerDescriptor()
        descriptor.sAddressMode = .repeat
        descriptor.tAddressMode = .repeat
        descriptor.magFilter = .nearest
        descriptor.mipFilter = .linear
        var material = SimpleMaterial()
        material.color = .init(texture: .init(texture, sampler: .init(descriptor)))
        return material
    default:
        return nil
    }
}

@available(tvOS 26.0, *)
public extension MeshDescriptor {
    /// Creates a mesh descriptor from a ``Mesh`` using triangles.
    /// - Parameter mesh: The mesh to convert into a RealityKit mesh descriptor.
    init(triangles mesh: Mesh) {
        self.init()
        var counts: [UInt8]?
        let data = mesh.getVertexData(maxSides: 3, counts: &counts)
        self.positions = .init(data.positions)
        self.normals = .init(data.normals)
        self.textureCoordinates = data.texcoords.map(MeshBuffers.TextureCoordinates.init)
        self.primitives = .triangles(data.indices)
        if !data.materialIndices.isEmpty {
            self.materials = .perFace(data.materialIndices)
        } else if !mesh.materials.isEmpty {
            self.materials = .allFaces(0)
        }
    }

    /// Creates a mesh descriptor from a ``Mesh`` using convex polygons.
    /// - Parameter mesh: The mesh to convert into a RealityKit mesh descriptor.
    init(polygons mesh: Mesh) {
        self.init()
        var counts: [UInt8]? = []
        let data = mesh.getVertexData(maxSides: 255, counts: &counts)
        self.positions = .init(data.positions)
        self.normals = .init(data.normals)
        self.textureCoordinates = data.texcoords.map(MeshBuffers.TextureCoordinates.init)
        self.primitives = .polygons(counts!, data.indices)
        if !data.materialIndices.isEmpty {
            self.materials = .perFace(data.materialIndices)
        } else if !mesh.materials.isEmpty {
            self.materials = .allFaces(0)
        }
    }

    /// Creates a mesh descriptor from a ``Mesh`` using quads where possible (and triangles as required).
    /// - Parameter mesh: The mesh to convert into a RealityKit mesh descriptor.
    init(quads mesh: Mesh) {
        self.init()
        var counts: [UInt8]? = []
        let data = mesh.getVertexData(maxSides: 4, counts: &counts)
        self.positions = .init(data.positions)
        self.normals = .init(data.normals)
        self.textureCoordinates = data.texcoords.map(MeshBuffers.TextureCoordinates.init)
        var i = 0
        var quads = [UInt32]()
        var triangles = [UInt32]()
        let perFaceMaterials = !data.materialIndices.isEmpty
        for count in counts! {
            switch count {
            case 3:
                triangles += data.indices[i ..< i + 3]
            case 4:
                quads += data.indices[i ..< i + 4]
            default:
                assertionFailure()
                self.primitives = .polygons(counts!, data.indices)
                if perFaceMaterials {
                    self.materials = .perFace(data.materialIndices)
                } else if !mesh.materials.isEmpty {
                    self.materials = .allFaces(0)
                }
                return
            }
            i += Int(count)
        }
        self.primitives = .trianglesAndQuads(triangles: triangles, quads: quads)
        if perFaceMaterials {
            var triangles = [UInt32]()
            var quads = [UInt32]()
            for (count, material) in zip(counts!, data.materialIndices) {
                switch count {
                case 3:
                    triangles.append(material)
                default:
                    quads.append(material)
                }
            }
            self.materials = .perFace(triangles + quads)
        } else if !mesh.materials.isEmpty {
            self.materials = .allFaces(0)
        }
    }
}

private struct RealityKitVertexData: Sendable {
    var positions: [SIMD3<Float>]
    var normals: [SIMD3<Float>]
    var texcoords: [SIMD2<Float>]?
    var colors: [SIMD4<Float>]?
    var indices: [UInt32]
    var materialIndices: [UInt32]
}

#if compiler(>=6)

/// A RealityKit vertex retaining Euclid's color and texture coordinates.
private struct RealityKitVertex {
    var position: SIMD3<Float>
    var normal: SIMD3<Float>
    var texcoord: SIMD2<Float>
    var color: SIMD4<Float>
}

@available(macOS 15.0, iOS 18.0, tvOS 26.0, visionOS 2.0, *)
public extension LowLevelMesh {
    /// Creates a triangle mesh preserving vertex colors, normals, texture coordinates, and materials.
    /// Vertex colors require a material that reads the geometry color attribute, such as a shader graph material.
    /// - Parameter mesh: The Euclid mesh to convert.
    convenience init(_ mesh: Mesh) throws {
        var counts: [UInt8]?
        let data = mesh.getVertexData(maxSides: 3, counts: &counts, preservingColors: true)
        try self.init(data: data, bounds: mesh.bounds)
    }
}

@available(macOS 15.0, iOS 18.0, tvOS 26.0, visionOS 2.0, *)
private extension LowLevelMesh {
    convenience init(data: RealityKitVertexData, bounds: Bounds) throws {
        var attributes: [Attribute] = [
            .init(semantic: .position, format: .float3, offset: MemoryLayout<RealityKitVertex>.offset(of: \.position)!),
            .init(semantic: .normal, format: .float3, offset: MemoryLayout<RealityKitVertex>.offset(of: \.normal)!),
        ]
        if data.texcoords != nil {
            attributes.append(.init(
                semantic: .uv0,
                format: .float2,
                offset: MemoryLayout<RealityKitVertex>.offset(of: \.texcoord)!
            ))
        }
        if data.colors != nil {
            attributes.append(.init(
                semantic: .color,
                format: .float4,
                offset: MemoryLayout<RealityKitVertex>.offset(of: \.color)!
            ))
        }
        try self.init(descriptor: .init(
            vertexCapacity: max(1, data.positions.count),
            vertexAttributes: attributes,
            vertexLayouts: [.init(bufferIndex: 0, bufferStride: MemoryLayout<RealityKitVertex>.stride)],
            indexCapacity: max(1, data.indices.count),
            indexType: .uint32
        ))
        withUnsafeMutableBytes(bufferIndex: 0) { buffer in
            let vertices = buffer.bindMemory(to: RealityKitVertex.self)
            for index in data.positions.indices {
                vertices[index] = RealityKitVertex(
                    position: data.positions[index], normal: data.normals[index],
                    texcoord: data.texcoords?[index] ?? .zero,
                    color: data.colors?[index] ?? .one
                )
            }
        }
        withUnsafeMutableIndices { buffer in
            data.indices.withUnsafeBytes { buffer.copyMemory(from: $0) }
        }
        let bounds = BoundingBox(min: .init(bounds.min), max: .init(bounds.max))
        var start = 0
        while start < data.indices.count {
            let materialIndex = data.materialIndices.isEmpty ? 0 : Int(data.materialIndices[start / 3])
            var end = start + 3
            while end < data.indices.count,
                  data.materialIndices.isEmpty || Int(data.materialIndices[end / 3]) == materialIndex
            {
                end += 3
            }
            parts.append(.init(
                indexOffset: start * MemoryLayout<UInt32>.stride, indexCount: end - start,
                materialIndex: materialIndex, bounds: bounds
            ))
            start = end
        }
    }
}

#endif

@available(tvOS 26.0, *)
public extension MeshResource {
    /// Creates a triangle mesh resource, preserving vertex colors on macOS 15, iOS 18, and visionOS 2 or later.
    @MainActor static func generate(triangles mesh: Mesh) throws -> MeshResource {
        #if compiler(>=6)
        if #available(macOS 15.0, iOS 18.0, visionOS 2.0, *), mesh.hasVertexColors {
            return try MeshResource(from: LowLevelMesh(mesh))
        }
        #endif
        return try generate(from: [MeshDescriptor(triangles: mesh)])
    }

    /// Asynchronously creates a triangle mesh resource, preserving vertex colors on supported platforms.
    nonisolated static func generate(triangles mesh: Mesh) async throws -> MeshResource {
        #if compiler(>=6)
        if #available(macOS 15.0, iOS 18.0, visionOS 2.0, *), mesh.hasVertexColors {
            var counts: [UInt8]?
            let data = mesh.getVertexData(maxSides: 3, counts: &counts, preservingColors: true)
            let lowLevelMesh = try await LowLevelMesh(data: data, bounds: mesh.bounds)
            return try await MeshResource(from: lowLevelMesh)
        }
        #endif
        return try await generate(from: [MeshDescriptor(triangles: mesh)])
    }
}

@MainActor
@available(tvOS 26.0, *)
public extension ModelEntity {
    /// A closure that maps a Euclid material to a RealityKit material.
    /// - Parameter material: A Euclid material to convert, or `nil` for the default material.
    /// - Returns: A `Material` used by RealityKit.
    typealias MaterialProvider = @MainActor @Sendable (_ material: Polygon.Material?) -> RealityKit.Material?

    /// Synchrononously creates a model entity from a ``Mesh`` using the default tessellation method.
    /// - Parameters:
    ///   - mesh: The mesh to convert into a RealityKit model entity.
    ///   - materialLookup: A closure to map the polygon material to a RealityKit material.
    convenience init(_ mesh: Mesh, materialLookup: MaterialProvider? = nil) throws {
        try self.init(triangles: mesh, materialLookup: materialLookup)
    }

    /// Asynchronously creates a model entity from a ``Mesh`` using the default tessellation method.
    ///
    /// Mesh descriptor construction is performed before switching to the main actor for RealityKit resource
    /// generation, material creation, and entity initialization.
    ///
    /// - Parameters:
    ///   - mesh: The mesh to convert into a RealityKit model entity.
    ///   - materialLookup: A closure to map the polygon material to a RealityKit material.
    nonisolated convenience init(_ mesh: Mesh, materialLookup: MaterialProvider? = nil) async throws {
        try await self.init(triangles: mesh, materialLookup: materialLookup)
    }

    /// Synchrononously creates a model entity from a ``Mesh`` using triangles.
    /// - Parameters:
    ///   - mesh: The mesh to convert into a RealityKit model entity.
    ///   - materialLookup: A closure to map the polygon material to a RealityKit material.
    convenience init(triangles mesh: Mesh, materialLookup: MaterialProvider? = nil) throws {
        let resource = try MeshResource.generate(triangles: mesh)
        self.init(mesh: resource, materials: mesh.realityKitMaterials(materialLookup: materialLookup))
    }

    /// Asynchronously creates a model entity from a ``Mesh`` using triangles.
    ///
    /// Mesh descriptor construction is performed before switching to the main actor for RealityKit resource
    /// generation, material creation, and entity initialization.
    ///
    /// - Parameters:
    ///   - mesh: The mesh to convert into a RealityKit model entity.
    ///   - materialLookup: A closure to map the polygon material to a RealityKit material.
    nonisolated convenience init(triangles mesh: Mesh, materialLookup: MaterialProvider? = nil) async throws {
        let resource = try await MeshResource.generate(triangles: mesh)
        let materials = await mesh.materialList(for: materialLookup)
        await self.init(mesh: resource, materials: materials.values)
    }

    /// Synchronously creates a model entity from a ``Mesh`` using convex polygons. Vertex-color gradients are not preserved.
    /// - Parameters:
    ///   - mesh: The mesh to convert into a RealityKit model entity.
    ///   - materialLookup: A closure to map the polygon material to a RealityKit material.
    convenience init(polygons mesh: Mesh, materialLookup: MaterialProvider? = nil) throws {
        let descriptor = MeshDescriptor(polygons: mesh)
        let resource = try MeshResource.generate(from: [descriptor])
        self.init(mesh: resource, materials: mesh.realityKitMaterials(materialLookup: materialLookup))
    }

    /// Asynchronously creates a model entity from a ``Mesh`` using convex polygons. Vertex-color gradients are not preserved.
    ///
    /// Mesh descriptor construction is performed before switching to the main actor for RealityKit resource
    /// generation, material creation, and entity initialization.
    ///
    /// - Parameters:
    ///   - mesh: The mesh to convert into a RealityKit model entity.
    ///   - materialLookup: A closure to map the polygon material to a RealityKit material.
    nonisolated convenience init(polygons mesh: Mesh, materialLookup: MaterialProvider? = nil) async throws {
        let descriptor = MeshDescriptor(polygons: mesh)
        let resource = try await MeshResource.generate(from: [descriptor])
        let materials = await mesh.materialList(for: materialLookup)
        await self.init(mesh: resource, materials: materials.values)
    }

    /// Synchronously creates a model entity from a ``Mesh`` using quads where possible (and triangles as required).
    /// Vertex-color gradients are not preserved.
    /// - Parameters:
    ///   - mesh: The mesh to convert into a RealityKit model entity.
    ///   - materialLookup: A closure to map the polygon material to a RealityKit material.
    convenience init(quads mesh: Mesh, materialLookup: MaterialProvider? = nil) throws {
        let descriptor = MeshDescriptor(quads: mesh)
        let resource = try MeshResource.generate(from: [descriptor])
        self.init(mesh: resource, materials: mesh.realityKitMaterials(materialLookup: materialLookup))
    }

    /// Asynchronously creates a model entity from a ``Mesh`` using quads where possible (and triangles as required).
    /// Vertex-color gradients are not preserved.
    ///
    /// Mesh descriptor construction is performed before switching to the main actor for RealityKit resource
    /// generation, material creation, and entity initialization.
    ///
    /// - Parameters:
    ///   - mesh: The mesh to convert into a RealityKit model entity.
    ///   - materialLookup: A closure to map the polygon material to a RealityKit material.
    nonisolated convenience init(quads mesh: Mesh, materialLookup: MaterialProvider? = nil) async throws {
        let descriptor = MeshDescriptor(quads: mesh)
        let resource = try await MeshResource.generate(from: [descriptor])
        let materials = await mesh.materialList(for: materialLookup)
        await self.init(mesh: resource, materials: materials.values)
    }
}

@available(tvOS 26.0, *)
private extension Mesh {
    /// Converts the mesh's materials to RealityKit materials in mesh resource order.
    ///
    /// Uniform vertex colors are multiplied into built-in materials, including their opacity.
    /// Vertex-color gradients require a custom shader. Custom materials are returned unchanged
    /// so shaders that read vertex colors do not apply them twice.
    /// - Parameter materialLookup: Optional mapping from polygon materials to RealityKit materials.
    @MainActor
    func realityKitMaterials(materialLookup: ModelEntity.MaterialProvider? = nil) -> [RealityKit.Material] {
        let colors: [Polygon.Material?: Color] = hasVertexColors ?
            polygonsByMaterial.compactMapValues { polygons in
                guard let color = polygons.first?.vertices.first?.color,
                      polygons.allSatisfy({ $0.vertices.allSatisfy { $0.color == color } })
                else { return nil }
                return color
            } : [:]
        let materialLookup = materialLookup ?? defaultMaterialLookup
        return materials.map { material in
            let converted = materialLookup(material) ?? SimpleMaterial()
            return converted.multiplyingVertexColor(colors[material] ?? .white)
        }
    }
}

@available(tvOS 26.0, *)
private extension RealityKit.Material {
    @MainActor
    func multiplyingVertexColor(_ color: Euclid.Color) -> RealityKit.Material {
        guard color != .white else { return self }
        switch self {
        case var material as PhysicallyBasedMaterial:
            material.baseColor.tint = material.baseColor.tint.multiplyingVertexColor(color.withAlphaComponent(1))
            if color.alpha != 1 {
                switch material.blending {
                case .opaque:
                    material.blending = .transparent(opacity: .init(floatLiteral: Float(color.alpha)))
                case var .transparent(opacity):
                    opacity.scale *= Float(color.alpha)
                    material.blending = .transparent(opacity: opacity)
                @unknown default: break
                }
            }
            return material
        case var material as UnlitMaterial:
            material.color.tint = material.color.tint.multiplyingVertexColor(color.withAlphaComponent(1))
            if color.alpha != 1 {
                switch material.blending {
                case .opaque:
                    material.blending = .transparent(opacity: .init(floatLiteral: Float(color.alpha)))
                case var .transparent(opacity):
                    opacity.scale *= Float(color.alpha)
                    material.blending = .transparent(opacity: opacity)
                @unknown default: break
                }
            }
            return material
        case var material as SimpleMaterial:
            material.color.tint = material.color.tint.multiplyingVertexColor(color)
            return material
        default:
            return self
        }
    }
}

private extension OSColor {
    func multiplyingVertexColor(_ color: Euclid.Color) -> OSColor {
        OSColor(Euclid.Color(self) * color)
    }
}

@available(tvOS 26.0, *)
private extension Mesh {
    struct ModelEntityMaterials: @unchecked Sendable {
        let values: [RealityKit.Material]
    }

    @MainActor
    func materialList(for materialLookup: ModelEntity.MaterialProvider?) -> ModelEntityMaterials {
        ModelEntityMaterials(values: realityKitMaterials(materialLookup: materialLookup))
    }

    func getVertexData(
        maxSides: UInt8,
        counts: inout [UInt8]?,
        preservingColors: Bool = false
    ) -> RealityKitVertexData {
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = [] // looks bad with default normals
        var texcoords: [SIMD2<Float>]? = hasTexcoords ? [] : nil
        var colors: [SIMD4<Float>]? = preservingColors && hasVertexColors ? [] : nil
        var indices = [UInt32]()
        var materialIndices = [UInt32]()
        var indicesByVertex = [Vertex: UInt32]()
        let polygonsByMaterial = polygonsByMaterial
        let perFaceMaterials = materials.count > 1
        for (materialIndex, material) in materials.enumerated() {
            let polygons = polygonsByMaterial[material] ?? []
            for polygon in polygons.tessellate(
                maxSides: Int(maxSides),
                isCancelled: { false }
            ) {
                counts?.append(UInt8(polygon.vertices.count))
                for var vertex in polygon.vertices {
                    if !preservingColors {
                        vertex.color = .white // MeshDescriptor does not support vertex colors
                    }
                    if let index = indicesByVertex[vertex] {
                        indices.append(index)
                        continue
                    }
                    let index = UInt32(indicesByVertex.count)
                    indicesByVertex[vertex] = index
                    indices.append(index)
                    positions.append(.init(vertex.position))
                    normals.append(.init(vertex.normal))
                    colors?.append(.init(vertex.color))
                    if texcoords != nil {
                        var texcoord = vertex.texcoord
                        texcoord.y = 1 - texcoord.y
                        texcoords?.append(.init(texcoord))
                    }
                }
                if perFaceMaterials {
                    materialIndices.append(UInt32(materialIndex))
                }
            }
        }
        return RealityKitVertexData(
            positions: positions,
            normals: normals,
            texcoords: texcoords,
            colors: colors,
            indices: indices,
            materialIndices: materialIndices
        )
    }
}

// MARK: import

@available(tvOS 26.0, *)
public extension Euclid.Transform {
    /// Creates a Euclid``Transform`` from a RealityKit `Transform`.
    /// - Parameter transform: The RealityKit transform  to convert into a Euclid transform.
    init(_ transform: RealityKit.Transform) {
        self.init(
            scale: .init(transform.scale),
            rotation: .init(transform.rotation),
            translation: .init(transform.translation)
        )
    }

    /// Creates a Euclid``Transform`` from a simd matrix.
    /// - Parameter matrix: The simd matrix  to convert into a Euclid transform.
    init(_ matrix: simd_float4x4) {
        self.init(RealityKit.Transform(matrix: matrix))
    }
}

private extension [Polygon] {
    @available(tvOS 26.0, *)
    init(
        meshDescriptor: MeshDescriptor,
        indices: [UInt32],
        counts: [UInt8],
        materials: [Polygon.Material?]
    ) {
        func materialLookup(_ index: Int) -> Polygon.Material? {
            materials.isEmpty ? nil : materials[index % materials.count]
        }
        let materials: [Polygon.Material?] = switch meshDescriptor.materials {
        case let .allFaces(index):
            [materialLookup(Int(index))]
        case let .perFace(indices):
            indices.map { materialLookup(Int($0)) }
        @unknown default:
            []
        }
        self.init(
            positions: meshDescriptor.positions.elements,
            normals: meshDescriptor.normals?.elements,
            texcoords: meshDescriptor.textureCoordinates?.elements,
            indices: indices,
            counts: counts,
            materials: materials
        )
    }

    init(
        positions: [SIMD3<Float>],
        normals: [SIMD3<Float>]?,
        texcoords: [SIMD2<Float>]?,
        indices: [UInt32],
        counts: [UInt8],
        materials: [Polygon.Material?]
    ) {
        var offset = 0
        self = counts.enumerated().flatMap { index, count in
            var vertices = [Vertex]()
            for i in offset ..< (offset + Int(count)) {
                let index = Int(indices[i])
                vertices.append(Vertex(
                    Vector(positions[index]),
                    normal: Vector(normals?[index] ?? .zero),
                    texcoord: texcoords.map {
                        var texcoord = Vector($0[index])
                        texcoord.y = 1 - texcoord.y
                        return texcoord
                    }
                ))
            }
            offset += Int(count)
            let material = materials.isEmpty ? nil : materials[index % materials.count]
            return [Polygon](vertices, material: material)
        }
    }
}

@MainActor
@available(tvOS 26.0, *)
private func defaultMaterialLookup(_ material: RealityKit.Material) -> Polygon.Material? {
    switch material {
    case let simpleMaterial as SimpleMaterial:
        var material = SimpleMaterial()
        material.color = simpleMaterial.color
        material.roughness = simpleMaterial.roughness
        material.metallic = simpleMaterial.metallic
        #if compiler(>=6)
        if #available(macOS 15.0, iOS 18.0, *) {
            material.triangleFillMode = simpleMaterial.triangleFillMode
            if #available(visionOS 2.0, *) {
                material.faceCulling = simpleMaterial.faceCulling
            }
        }
        #endif
        return MaterialWrapper(material)
    case let unlitMaterial as UnlitMaterial:
        var material = UnlitMaterial()
        material.color = unlitMaterial.color
        material.opacityThreshold = unlitMaterial.opacityThreshold
        material.blending = unlitMaterial.blending
        #if compiler(>=6)
        if #available(macOS 15.0, iOS 18.0, *) {
            material.triangleFillMode = unlitMaterial.triangleFillMode
            if #available(visionOS 2.0, *) {
                material.faceCulling = unlitMaterial.faceCulling
            }
        }
        #endif
        return MaterialWrapper(material)
    case let occlusionMaterial as OcclusionMaterial:
        #if os(visionOS)
        let material = OcclusionMaterial()
        #else
        let material = OcclusionMaterial(receivesDynamicLighting: occlusionMaterial.receivesDynamicLighting)
        #endif
        return MaterialWrapper(material)
    case let videoMaterial as VideoMaterial:
        guard let avPlayer = videoMaterial.avPlayer else { return nil }
        var material = VideoMaterial(avPlayer: avPlayer)
        #if compiler(>=6)
        if #available(macOS 15.0, iOS 18.0, *) {
            material.controller.preferredViewingMode = videoMaterial.controller.preferredViewingMode
            material.triangleFillMode = videoMaterial.triangleFillMode
            if #available(visionOS 2.0, *) {
                material.faceCulling = videoMaterial.faceCulling
            }
        }
        #endif
        return MaterialWrapper(material)
    case let pbrMaterial as PhysicallyBasedMaterial:
        var material = PhysicallyBasedMaterial()
        material.baseColor = pbrMaterial.baseColor
        material.metallic = pbrMaterial.metallic
        material.roughness = pbrMaterial.roughness
        material.emissiveColor = pbrMaterial.emissiveColor
        material.emissiveIntensity = pbrMaterial.emissiveIntensity
        material.specular = pbrMaterial.specular
        material.clearcoat = pbrMaterial.clearcoat
        material.clearcoatRoughness = pbrMaterial.clearcoatRoughness
        material.opacityThreshold = pbrMaterial.opacityThreshold
        material.faceCulling = pbrMaterial.faceCulling
        material.blending = pbrMaterial.blending
        material.normal = pbrMaterial.normal
        material.ambientOcclusion = pbrMaterial.ambientOcclusion
        material.anisotropyLevel = pbrMaterial.anisotropyLevel
        material.anisotropyAngle = pbrMaterial.anisotropyAngle
        material.sheen = pbrMaterial.sheen
        material.textureCoordinateTransform = pbrMaterial.textureCoordinateTransform
        material.secondaryTextureCoordinateTransform = pbrMaterial.secondaryTextureCoordinateTransform
        #if compiler(>=6)
        if #available(macOS 15.0, iOS 18.0, *) {
            material.triangleFillMode = pbrMaterial.triangleFillMode
            if #available(visionOS 2.0, *) {
                material.faceCulling = pbrMaterial.faceCulling
            }
        }
        #endif
        return MaterialWrapper(material)
    default:
        #if compiler(>=6)
        if #available(macOS 15.0, iOS 18.0, *),
           let portalMaterial = material as? PortalMaterial
        {
            var material = PortalMaterial()
            material.triangleFillMode = portalMaterial.triangleFillMode
            if #available(visionOS 2.0, *) {
                material.faceCulling = portalMaterial.faceCulling
            }
            return MaterialWrapper(material)
        }
        #endif
        // Not supported
        return nil
    }
}

#if compiler(>=6.1) && compiler(<6.2)
// Workaround for Xcode 16.3 bug
@available(visionOS 2.0, macOS 15.0, iOS 18.0, tvOS 26.0, *)
#else
@available(tvOS 26.0, *)
#endif
public extension Mesh {
    /// A closure that converts a RealityKit material to a Euclid material.
    /// - Parameter material: A RealityKit material to convert.
    /// - Returns: A Euclid `Material`.
    typealias RealityKitMaterialProvider = @MainActor @Sendable (_ material: RealityKit.Material) -> Polygon.Material?

    /// Synchronously creates a mesh from a RealityKit `MeshDescriptor` with optional material.
    /// - Parameters:
    ///   - meshDescriptor: The `MeshDescriptor` to convert into a mesh.
    ///   - materials: An array of materials to apply to the mesh.
    init(_ meshDescriptor: MeshDescriptor, materials: [Polygon.Material?] = []) {
        guard let primitives = meshDescriptor.primitives else {
            self = .empty
            return
        }
        let polygons: [Polygon] = switch primitives {
        case let .triangles(indices):
            .init(
                meshDescriptor: meshDescriptor,
                indices: indices,
                counts: [UInt8](repeating: 3, count: indices.count / 3),
                materials: materials
            )
        case let .trianglesAndQuads(triangles, quads):
            .init(
                meshDescriptor: meshDescriptor,
                indices: triangles,
                counts: [UInt8](repeating: 3, count: triangles.count / 3),
                materials: materials
            ) + .init(
                meshDescriptor: meshDescriptor,
                indices: quads,
                counts: [UInt8](repeating: 4, count: quads.count / 4),
                materials: materials
            )
        case let .polygons(counts, indices):
            .init(
                meshDescriptor: meshDescriptor,
                indices: indices,
                counts: counts,
                materials: materials
            )
        @unknown default:
            // TODO: throw for unknown type?
            []
        }
        self.init(polygons)
    }

    /// Synchronously creates a mesh from a RealityKit `MeshResource`.
    /// - Parameters:
    ///   - meshResource: The `MeshResource` to convert into a mesh.
    ///   - materials: An array of materials to apply to the mesh.
    @MainActor
    init(_ meshResource: MeshResource, materials: [Polygon.Material?] = []) {
        var models = [String: Mesh]()
        self.init(submeshes: meshResource.contents.instances.compactMap {
            var mesh = models[$0.model]
            if mesh == nil, let model = meshResource.contents.models[$0.model] {
                let modelMesh = Mesh(model, materials: materials)
                models[$0.model] = modelMesh
                mesh = modelMesh
            }
            return mesh?.transformed(by: Transform($0.transform))
        })
    }

    /// Asynchronously creates a mesh from a RealityKit `MeshResource`.
    ///
    /// The RealityKit mesh contents are read on the main actor, then Euclid mesh construction is performed
    /// in a child task.
    ///
    /// - Parameters:
    ///   - meshResource: The `MeshResource` to convert into a mesh.
    ///   - materials: An array of materials to apply to the mesh.
    init(_ meshResource: MeshResource, materials: [Polygon.Material?] = []) async {
        let contents = await Mesh.contents(of: meshResource)
        let materials = MaterialList(values: materials)
        async let mesh = Mesh(contents, materials: materials)
        self = await mesh
    }

    /// Synchronously creates a mesh from a RealityKit `MeshResource.Model`.
    /// - Parameters:
    ///   - model: The `MeshResource.Model` to convert into a mesh.
    ///   - materials: An array of materials to apply to the mesh.
    init(_ model: MeshResource.Model, materials: [Polygon.Material?]) {
        var polygons = [Polygon]()
        for part in model.parts {
            guard let indices = part.triangleIndices?.elements else {
                continue
            }
            polygons += .init(
                positions: part.positions.elements,
                normals: part.normals?.elements,
                texcoords: part.textureCoordinates?.elements,
                indices: indices,
                counts: [UInt8](repeating: 3, count: indices.count / 3),
                materials: materials.isEmpty ? [] : [materials[part.materialIndex % materials.count]]
            )
        }
        self.init(polygons)
    }

    /// Synchronously creates a mesh from a RealityKit `ModelEntity` with optional material mapping.
    /// - Parameters:
    ///   - modelEntity: The `ModelEntity` to convert into a mesh.
    ///   - materialLookup: An optional closure to map the RealityKit materials to Euclid materials.
    @MainActor
    init(_ modelEntity: ModelEntity, materialLookup: RealityKitMaterialProvider? = nil) {
        guard let model = modelEntity.model else {
            self = .empty
            return
        }
        self.init(model, materialLookup: materialLookup)
        transform(by: .init(modelEntity.transform))
    }

    /// Asynchronously creates a mesh from a RealityKit `ModelEntity` with optional material mapping.
    ///
    /// The RealityKit model component, transform, mesh contents, and materials are read on the main actor.
    /// Euclid mesh construction is then performed in a child task.
    ///
    /// - Parameters:
    ///   - modelEntity: The `ModelEntity` to convert into a mesh.
    ///   - materialLookup: An optional closure to map the RealityKit materials to Euclid materials.
    init(_ modelEntity: ModelEntity, materialLookup: RealityKitMaterialProvider? = nil) async {
        guard let snapshot = await Mesh.snapshot(
            modelEntity: modelEntity,
            materialLookup: materialLookup
        ) else {
            self = .empty
            return
        }
        async let mesh = Mesh(snapshot)
        self = await mesh
    }

    /// Synchronously creates a mesh from a RealityKit `ModelComponent` with optional material mapping.
    /// - Parameters:
    ///   - component: The `ModelComponent` to convert into a mesh.
    ///   - materialLookup: An optional closure to map the RealityKit materials to Euclid materials.
    @MainActor
    init(_ component: ModelComponent, materialLookup: RealityKitMaterialProvider? = nil) {
        let materialLookup = materialLookup ?? defaultMaterialLookup
        self.init(component.mesh, materials: component.materials.map { materialLookup($0) })
    }

    /// Asynchronously creates a mesh from a RealityKit `ModelComponent` with optional material mapping.
    ///
    /// The RealityKit mesh contents and materials are read on the main actor, then Euclid mesh construction
    /// is performed in a child task.
    ///
    /// - Parameters:
    ///   - component: The `ModelComponent` to convert into a mesh.
    ///   - materialLookup: An optional closure to map the RealityKit materials to Euclid materials.
    @MainActor
    init(_ component: ModelComponent, materialLookup: RealityKitMaterialProvider? = nil) async {
        let contents = MeshResourceContents(value: component.mesh.contents)
        let materials = Mesh.materials(
            for: RealityKitMaterialList(values: component.materials),
            materialLookup: materialLookup
        )
        let snapshot = ModelComponentSnapshot(contents: contents, materials: materials)
        async let mesh = Mesh(snapshot)
        self = await mesh
    }
}

#if compiler(>=6.1) && compiler(<6.2)
// Workaround for Xcode 16.3 bug
@available(visionOS 2.0, macOS 15.0, iOS 18.0, tvOS 26.0, *)
#else
@available(tvOS 26.0, *)
#endif
private extension Mesh {
    struct MaterialList: @unchecked Sendable {
        let values: [Polygon.Material?]
    }

    struct RealityKitMaterialList: @unchecked Sendable {
        let values: [RealityKit.Material]
    }

    struct MeshResourceContents: @unchecked Sendable {
        let value: MeshResource.Contents
    }

    struct ModelComponentSnapshot: @unchecked Sendable {
        let contents: MeshResourceContents
        let materials: MaterialList
    }

    struct ModelEntitySnapshot: @unchecked Sendable {
        let component: ModelComponentSnapshot
        let transform: Euclid.Transform
    }

    @MainActor
    static func contents(of meshResource: MeshResource) -> MeshResourceContents {
        MeshResourceContents(value: meshResource.contents)
    }

    @MainActor
    static func materials(
        for materials: RealityKitMaterialList,
        materialLookup: RealityKitMaterialProvider?
    ) -> MaterialList {
        let materialLookup = materialLookup ?? defaultMaterialLookup
        return MaterialList(values: materials.values.map { materialLookup($0) })
    }

    @MainActor
    static func snapshot(
        modelEntity: ModelEntity,
        materialLookup: RealityKitMaterialProvider?
    ) async -> ModelEntitySnapshot? {
        guard let component = modelEntity.model else {
            return nil
        }
        let materials = materials(
            for: RealityKitMaterialList(values: component.materials),
            materialLookup: materialLookup
        )
        return ModelEntitySnapshot(
            component: ModelComponentSnapshot(
                contents: MeshResourceContents(value: component.mesh.contents),
                materials: materials
            ),
            transform: Transform(modelEntity.transform)
        )
    }

    init(_ contents: MeshResourceContents, materials: MaterialList) {
        var models = [String: Mesh]()
        self.init(submeshes: contents.value.instances.compactMap {
            var mesh = models[$0.model]
            if mesh == nil, let model = contents.value.models[$0.model] {
                let modelMesh = Mesh(model, materials: materials.values)
                models[$0.model] = modelMesh
                mesh = modelMesh
            }
            return mesh?.transformed(by: Transform($0.transform))
        })
    }

    init(_ snapshot: ModelComponentSnapshot) {
        self.init(snapshot.contents, materials: snapshot.materials)
    }

    init(_ snapshot: ModelEntitySnapshot) {
        self.init(snapshot.component)
        transform(by: snapshot.transform)
    }
}

#if compiler(>=6)

/// Creates shader graph materials that display Euclid's RealityKit vertex colors.
///
/// RGB is multiplied in linear light by the base color and optional texture. Vertex, base-color,
/// and texture alpha are multiplied without gamma conversion. Emission is added independently.
/// Supports a base-color texture and scalar PBR properties; normal maps and other material
/// features are not supported. Existing materials are never converted automatically.
@available(macOS 15.0, iOS 18.0, tvOS 26.0, visionOS 2.0, *)
@MainActor
public enum RealityKitVertexColorMaterial {
    private struct TemplateKey: Hashable {
        var unlit: Bool
        var textured: Bool
    }

    private static var templates = [TemplateKey: Task<ShaderGraphMaterial, Error>]()

    /// Creates a material that reads the mesh's vertex colors, including gradients and alpha.
    /// - Parameters:
    ///   - color: An sRGB base tint. Its alpha multiplies vertex and texture alpha.
    ///   - texture: An optional base-color texture, sampled using the mesh's texture coordinates.
    ///   - emission: An sRGB emission color. Its alpha is ignored.
    ///   - emissionIntensity: A multiplier for the emission color.
    ///   - roughness: The scalar surface roughness, ignored for unlit materials.
    ///   - metallic: The scalar metallic fraction, ignored for unlit materials.
    ///   - specular: The scalar specular level, ignored for unlit materials.
    ///   - unlit: Whether to display colors without scene lighting.
    /// - Returns: An independent material value that can be customized further.
    /// - Note: Requires a mesh with vertex-color attributes, such as `LowLevelMesh(mesh)`.
    public static func make(
        color: Color = .white,
        texture: MaterialParameters.Texture? = nil,
        emission: Color = .black,
        emissionIntensity: Float = 1,
        roughness: Float = 0.5,
        metallic: Float = 0,
        specular: Float = 0.5,
        unlit: Bool = false
    ) async throws -> ShaderGraphMaterial {
        let key = TemplateKey(unlit: unlit, textured: texture != nil)
        if templates[key] == nil {
            // Initialize RealityKit on the main actor before asynchronous shader loading.
            _ = PhysicallyBasedMaterial()
            templates[key] = Task { try await ShaderGraphMaterial(
                named: "/VertexColors",
                from: Data(source(unlit: unlit, textured: key.textured).utf8)
            ) }
        }
        var shader: ShaderGraphMaterial
        do {
            shader = try await templates[key]!.value
        } catch {
            templates[key] = nil
            throw error
        }
        if let texture {
            try shader.setParameter(name: "baseTexture", value: .texture(texture))
        }
        // Managed primaries map linear sRGB vertex attributes into the shader's working space.
        try shader.setParameter(name: "redBasis", value: .color(OSColor(Color.red).cgColor))
        try shader.setParameter(name: "greenBasis", value: .color(OSColor(Color.green).cgColor))
        try shader.setParameter(name: "blueBasis", value: .color(OSColor(Color.blue).cgColor))
        try shader.setParameter(name: "baseColor", value: .color(OSColor(color.withAlphaComponent(1)).cgColor))
        try shader.setParameter(name: "emissiveColor", value: .color(OSColor(emission.withAlphaComponent(1)).cgColor))
        try shader.setParameter(name: "emissiveIntensity", value: .float(emissionIntensity))
        if !unlit {
            try shader.setParameter(name: "roughness", value: .float(roughness))
            try shader.setParameter(name: "metallic", value: .float(metallic))
            try shader.setParameter(name: "specular", value: .float(specular))
        }
        try shader.setParameter(name: "opacity", value: .float(Float(color.alpha)))
        return shader
    }

    // swiftformat:disable indent -- Preserve indentation of nested multiline string literals.
    private static func source(unlit: Bool, textured: Bool) -> String {
        """
        #usda 1.0
        def Material "VertexColors" {
            \(textured ? "asset inputs:baseTexture" : "")
            color3f inputs:baseColor = (1, 1, 1)
            color3f inputs:redBasis = (1, 0, 0)
            color3f inputs:greenBasis = (0, 1, 0)
            color3f inputs:blueBasis = (0, 0, 1)
            color3f inputs:emissiveColor = (0, 0, 0)
            float inputs:emissiveIntensity = 1
            float inputs:opacity = 1
            float inputs:roughness = 0.5
            float inputs:metallic = 0
            float inputs:specular = 0
            token outputs:mtlx:surface.connect = </VertexColors/Surface.outputs:out>
            def Shader "Color" {
                uniform token info:id = "ND_geomcolor_color3"
                int inputs:index = 0
                color3f outputs:out
            }
            def Shader "ColorWithAlpha" {
                uniform token info:id = "ND_geomcolor_color4"
                int inputs:index = 0
                color4f outputs:out
            }
            def Shader "Alpha" {
                uniform token info:id = "ND_extract_color4"
                color4f inputs:in.connect = </VertexColors/ColorWithAlpha.outputs:out>
                int inputs:index = 3
                float outputs:out
            }
            def Shader "RedComponent" {
                uniform token info:id = "ND_extract_color3"
                color3f inputs:in.connect = </VertexColors/Color.outputs:out>
                int inputs:index = 0
                float outputs:out
            }
            def Shader "RedContribution" {
                uniform token info:id = "ND_multiply_color3FA"
                color3f inputs:in1.connect = </VertexColors.inputs:redBasis>
                float inputs:in2.connect = </VertexColors/RedComponent.outputs:out>
                color3f outputs:out
            }
            def Shader "GreenComponent" {
                uniform token info:id = "ND_extract_color3"
                color3f inputs:in.connect = </VertexColors/Color.outputs:out>
                int inputs:index = 1
                float outputs:out
            }
            def Shader "GreenContribution" {
                uniform token info:id = "ND_multiply_color3FA"
                color3f inputs:in1.connect = </VertexColors.inputs:greenBasis>
                float inputs:in2.connect = </VertexColors/GreenComponent.outputs:out>
                color3f outputs:out
            }
            def Shader "BlueComponent" {
                uniform token info:id = "ND_extract_color3"
                color3f inputs:in.connect = </VertexColors/Color.outputs:out>
                int inputs:index = 2
                float outputs:out
            }
            def Shader "BlueContribution" {
                uniform token info:id = "ND_multiply_color3FA"
                color3f inputs:in1.connect = </VertexColors.inputs:blueBasis>
                float inputs:in2.connect = </VertexColors/BlueComponent.outputs:out>
                color3f outputs:out
            }
            def Shader "RedGreen" {
                uniform token info:id = "ND_add_color3"
                color3f inputs:in1.connect = </VertexColors/RedContribution.outputs:out>
                color3f inputs:in2.connect = </VertexColors/GreenContribution.outputs:out>
                color3f outputs:out
            }
            def Shader "ManagedColor" {
                uniform token info:id = "ND_add_color3"
                color3f inputs:in1.connect = </VertexColors/RedGreen.outputs:out>
                color3f inputs:in2.connect = </VertexColors/BlueContribution.outputs:out>
                color3f outputs:out
            }
            def Shader "Tint" {
                uniform token info:id = "ND_multiply_color3"
                color3f inputs:in1.connect = </VertexColors/\(textured ? "TexturedColor" : "ManagedColor").outputs:out>
                color3f inputs:in2.connect = </VertexColors.inputs:baseColor>
                color3f outputs:out
            }
            def Shader "Opacity" {
                uniform token info:id = "ND_multiply_float"
                float inputs:in1.connect = </VertexColors/\(textured ? "TexturedAlpha" : "Alpha").outputs:out>
                float inputs:in2.connect = </VertexColors.inputs:opacity>
                float outputs:out
            }
            def Shader "Emission" {
                uniform token info:id = "ND_multiply_color3FA"
                color3f inputs:in1.connect = </VertexColors.inputs:emissiveColor>
                float inputs:in2.connect = </VertexColors.inputs:emissiveIntensity>
                color3f outputs:out
            }
            \(textured ? """
            def Shader "BaseTexture" {
                uniform token info:id = "ND_image_color4"
                asset inputs:file.connect = </VertexColors.inputs:baseTexture>
                color4f inputs:default = (1, 1, 1, 1)
                color4f outputs:out
            }
            def Shader "TextureColor" {
                uniform token info:id = "ND_convert_color4_color3"
                color4f inputs:in.connect = </VertexColors/BaseTexture.outputs:out>
                color3f outputs:out
            }
            def Shader "TextureAlpha" {
                uniform token info:id = "ND_extract_color4"
                color4f inputs:in.connect = </VertexColors/BaseTexture.outputs:out>
                int inputs:index = 3
                float outputs:out
            }
            def Shader "TexturedColor" {
                uniform token info:id = "ND_multiply_color3"
                color3f inputs:in1.connect = </VertexColors/ManagedColor.outputs:out>
                color3f inputs:in2.connect = </VertexColors/TextureColor.outputs:out>
                color3f outputs:out
            }
            def Shader "TexturedAlpha" {
                uniform token info:id = "ND_multiply_float"
                float inputs:in1.connect = </VertexColors/Alpha.outputs:out>
                float inputs:in2.connect = </VertexColors/TextureAlpha.outputs:out>
                float outputs:out
            }
            """ : "")
            \(unlit ? """
            def Shader "UnlitColor" {
                uniform token info:id = "ND_add_color3"
                color3f inputs:in1.connect = </VertexColors/Tint.outputs:out>
                color3f inputs:in2.connect = </VertexColors/Emission.outputs:out>
                color3f outputs:out
            }
            def Shader "Surface" {
                uniform token info:id = "ND_realitykit_unlit_surfaceshader"
                color3f inputs:color.connect = </VertexColors/UnlitColor.outputs:out>
                float inputs:opacity.connect = </VertexColors/Opacity.outputs:out>
                token outputs:out
            }
            """ : """
            def Shader "Surface" {
                uniform token info:id = "ND_realitykit_pbr_surfaceshader"
                color3f inputs:baseColor.connect = </VertexColors/Tint.outputs:out>
                color3f inputs:emissiveColor.connect = </VertexColors/Emission.outputs:out>
                float inputs:opacity.connect = </VertexColors/Opacity.outputs:out>
                float inputs:roughness.connect = </VertexColors.inputs:roughness>
                float inputs:metallic.connect = </VertexColors.inputs:metallic>
                float inputs:specular.connect = </VertexColors.inputs:specular>
                token outputs:out
            }
            """)
        }
        """
    }
    // swiftformat:enable indent
}

#endif
#endif
