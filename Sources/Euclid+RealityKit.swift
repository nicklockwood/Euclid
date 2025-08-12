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

#if canImport(RealityKit) && swift(>=5.4)

import CoreGraphics
import Metal
import RealityKit

@available(macOS 10.15, iOS 13.0, tvOS 26.0, *)
private class MaterialWrapper: NSObject {
    let material: RealityKit.Material

    init(_ material: Material) {
        self.material = material
    }
}

// MARK: export

@available(macOS 10.15, iOS 13.0, tvOS 26.0, *)
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

@available(macOS 12.0, iOS 15.0, tvOS 26.0, *)
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

@available(macOS 12.0, iOS 15.0, tvOS 26.0, *)
public extension MeshDescriptor {
    /// Creates a mesh descriptor from a ``Mesh`` using triangles.
    /// - Parameter triangles: The mesh to convert into a RealityKit mesh descriptor.
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
    /// - Parameter polygons: The mesh to convert into a RealityKit mesh descriptor.
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
    /// - Parameter quads: The mesh to convert into a RealityKit mesh descriptor.
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

@available(macOS 12.0, iOS 15.0, tvOS 26.0, *)
public extension ModelEntity {
    /// A closure that maps a Euclid material to a RealityKit material.
    /// - Parameter material: A Euclid material to convert, or `nil` for the default material.
    /// - Returns: A `Material` used by RealityKit.
    typealias MaterialProvider = (_ material: Polygon.Material?) -> RealityKit.Material?

    /// Creates a model entity from a ``Mesh`` using the default tessellation method.
    /// - Parameters:
    ///   - mesh: The mesh to convert into a RealityKit model entity.
    ///   - materialLookup: A closure to map the polygon material to a RealityKit material.
    convenience init(_ mesh: Mesh, materialLookup: MaterialProvider? = nil) throws {
        try self.init(triangles: mesh, materialLookup: materialLookup)
    }

    /// Creates a model entity from a ``Mesh`` using triangles.
    /// - Parameters:
    ///   - triangles: The mesh to convert into a RealityKit model entity.
    ///   - materialLookup: A closure to map the polygon material to a RealityKit material.
    convenience init(triangles mesh: Mesh, materialLookup: MaterialProvider? = nil) throws {
        let descriptor = MeshDescriptor(triangles: mesh)
        let resource = try MeshResource.generate(from: [descriptor])
        self.init(mesh: resource, materials: mesh.materials(for: materialLookup))
    }

    /// Creates a model entity from a ``Mesh`` using convex polygons.
    /// - Parameters:
    ///   - polygons: The mesh to convert into a RealityKit model entity.
    ///   - materialLookup: A closure to map the polygon material to a RealityKit material.
    convenience init(polygons mesh: Mesh, materialLookup: MaterialProvider? = nil) throws {
        let descriptor = MeshDescriptor(polygons: mesh)
        let resource = try MeshResource.generate(from: [descriptor])
        self.init(mesh: resource, materials: mesh.materials(for: materialLookup))
    }

    /// Creates a model entity from a ``Mesh`` using quads where possible (and triangles as required).
    /// - Parameters:
    ///   - quads: The mesh to convert into a RealityKit model entity.
    ///   - materialLookup: A closure to map the polygon material to a RealityKit material.
    convenience init(quads mesh: Mesh, materialLookup: MaterialProvider? = nil) throws {
        let descriptor = MeshDescriptor(quads: mesh)
        let resource = try MeshResource.generate(from: [descriptor])
        self.init(mesh: resource, materials: mesh.materials(for: materialLookup))
    }
}

private extension Mesh {
    @available(macOS 12.0, iOS 15.0, tvOS 26.0, *)
    func materials(for materialLookup: ModelEntity.MaterialProvider?) -> [RealityKit.Material] {
        let materialLookup = materialLookup ?? defaultMaterialLookup
        return materials.map { materialLookup($0) ?? SimpleMaterial() }
    }

    func getVertexData(maxSides: UInt8, counts: inout [UInt8]?) -> (
        positions: [SIMD3<Float>],
        normals: [SIMD3<Float>],
        texcoords: [SIMD2<Float>]?,
        indices: [UInt32],
        materialIndices: [UInt32]
    ) {
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = [] // looks bad with default normals
        var texcoords: [SIMD2<Float>]? = hasTexcoords ? [] : nil
        var indices = [UInt32]()
        var materialIndices = [UInt32]()
        var indicesByVertex = [Vertex: UInt32]()
        let polygonsByMaterial = polygonsByMaterial
        let perFaceMaterials = materials.count > 1
        for (materialIndex, material) in materials.enumerated() {
            let polygons = polygonsByMaterial[material] ?? []
            for polygon in polygons.tessellate(maxSides: Int(maxSides)) {
                counts?.append(UInt8(polygon.vertices.count))
                for var vertex in polygon.vertices {
                    vertex.color = .white // Note: vertex colors are not supported
                    if let index = indicesByVertex[vertex] {
                        indices.append(index)
                        continue
                    }
                    let index = UInt32(indicesByVertex.count)
                    indicesByVertex[vertex] = index
                    indices.append(index)
                    positions.append(.init(vertex.position))
                    normals.append(.init(vertex.normal))
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
        return (
            positions: positions,
            normals: normals,
            texcoords: texcoords,
            indices: indices,
            materialIndices: materialIndices
        )
    }
}

// MARK: import

@available(macOS 10.15, iOS 13.0, tvOS 26.0, *)
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
    @available(macOS 12.0, iOS 15.0, tvOS 26.0, *)
    init(
        meshDescriptor: MeshDescriptor,
        indices: [UInt32],
        counts: [UInt8],
        materials: [Polygon.Material?]
    ) {
        func materialLookup(_ index: Int) -> Polygon.Material? {
            materials.isEmpty ? nil : materials[index % materials.count]
        }
        var materials: [Polygon.Material?]
        switch meshDescriptor.materials {
        case let .allFaces(index):
            materials = [materialLookup(Int(index))]
        case let .perFace(indices):
            materials = indices.map { materialLookup(Int($0)) }
        @unknown default:
            materials = []
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
        self = counts.enumerated().compactMap { index, count in
            var vertices = [Vertex]()
            for i in offset ..< (offset + Int(count)) {
                let index = Int(indices[i])
                vertices.append(Vertex(
                    Vector(positions[index]),
                    Vector(normals?[index] ?? .zero),
                    texcoords.map {
                        var texcoord = Vector($0[index])
                        texcoord.y = 1 - texcoord.y
                        return texcoord
                    }
                ))
            }
            offset += Int(count)
            let material = materials.isEmpty ? nil : materials[index % materials.count]
            return Polygon(vertices, material: material)
        }
    }
}

#if compiler(>=6.1) && compiler(<6.2)
// Workaround for Xcode 16.3 bug
@available(visionOS 2.0, macOS 15.0, iOS 18.0, tvOS 26.0, *)
#else
@available(macOS 12.0, iOS 15.0, tvOS 26.0, *)
#endif
public extension Mesh {
    /// A closure that converts a RealityKit material to a Euclid material.
    /// - Parameter material: A RealityKit material to convert.
    /// - Returns: A Euclid `Material`.
    typealias RealityKitMaterialProvider = (_ material: RealityKit.Material) -> Polygon.Material?

    /// Creates a mesh from a RealityKit `MeshDescriptor` with optional material.
    /// - Parameters:
    ///   - meshDescriptor: The `MeshDescriptor` to convert into a mesh.
    ///   - materials: An array of materials to apply to the mesh.
    init(_ meshDescriptor: MeshDescriptor, materials: [Polygon.Material?] = []) {
        guard let primitives = meshDescriptor.primitives else {
            self = .empty
            return
        }
        let polygons: [Polygon]
        switch primitives {
        case let .triangles(indices):
            polygons = .init(
                meshDescriptor: meshDescriptor,
                indices: indices,
                counts: [UInt8](repeating: 3, count: indices.count / 3),
                materials: materials
            )
        case let .trianglesAndQuads(triangles, quads):
            polygons = .init(
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
            polygons = .init(
                meshDescriptor: meshDescriptor,
                indices: indices,
                counts: counts,
                materials: materials
            )
        @unknown default:
            // TODO: throw for unknown type?
            polygons = []
        }
        self.init(polygons)
    }

    /// Creates a mesh from a RealityKit `MeshResource`.
    /// - Parameters:
    ///   - meshResource: The `MeshResource` to convert into a mesh.
    ///   - materials: An array of materials to apply to the mesh.
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

    /// Creates a mesh from a RealityKit `MeshResource.Model`.
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

    /// Creates a mesh from a RealityKit `ModelEntity` with optional material mapping.
    /// - Parameters:
    ///   - modelEntity: The `ModelEntity` to convert into a mesh.
    ///   - materialLookup: An optional closure to map the RealityKit materials to Euclid materials.
    init(_ modelEntity: ModelEntity, materialLookup: RealityKitMaterialProvider? = nil) {
        guard let model = modelEntity.model else {
            self = .empty
            return
        }
        self.init(model, materialLookup: materialLookup)
        transform(by: .init(modelEntity.transform))
    }

    /// Creates a mesh from a RealityKit `ModelComponent` with optional material mapping.
    /// - Parameters:
    ///   - component: The `ModelComponent` to convert into a mesh.
    ///   - materialLookup: An optional closure to map the RealityKit materials to Euclid materials.
    init(_ component: ModelComponent, materialLookup: RealityKitMaterialProvider? = nil) {
        let materialLookup = materialLookup ?? {
            switch $0 {
            case let simpleMaterial as SimpleMaterial:
                var material = SimpleMaterial()
                material.color = simpleMaterial.color
                material.roughness = simpleMaterial.roughness
                material.metallic = simpleMaterial.metallic
                #if compiler(>=6)
                if #available(visionOS 1.0, macOS 15.0, iOS 18.0, *) {
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
                if #available(visionOS 1.0, macOS 15.0, iOS 18.0, *) {
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
                if #available(visionOS 1.0, macOS 15.0, iOS 18.0, *) {
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
                if #available(visionOS 1.0, macOS 15.0, iOS 18.0, *) {
                    material.triangleFillMode = pbrMaterial.triangleFillMode
                    if #available(visionOS 2.0, *) {
                        material.faceCulling = pbrMaterial.faceCulling
                    }
                }
                #endif
                return MaterialWrapper(material)
            default:
                #if compiler(>=6)
                if #available(visionOS 1.0, macOS 15.0, iOS 18.0, *),
                   let portalMaterial = $0 as? PortalMaterial
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
        self.init(component.mesh, materials: component.materials.map { materialLookup($0) })
    }
}

#endif
