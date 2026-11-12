//
//  Mesh+IO.swift
//  Euclid
//
//  Created by Nick Lockwood on 26/01/2024.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

#if canImport(ModelIO)
import ModelIO
#endif

#if canImport(SceneKit)
import SceneKit
#endif

public extension Mesh {
    /// Configuration options for mesh import.
    struct ImportOptions: Sendable {
        /// Should face winding be repaired after loading? Use `nil` for format-specific default.
        public var repairWinding: Bool?

        public init(repairWinding: Bool? = nil) {
            self.repairWinding = repairWinding
        }
    }

    /// Input/output error.
    struct IOError: Error, CustomNSError {
        let message: String

        init(_ message: String) {
            self.message = message
        }

        public var errorUserInfo: [String: Any] {
            [NSLocalizedDescriptionKey: message]
        }
    }

    /// Loads a mesh from a file, with optional material mapping.
    ///
    /// Uses native readers for STL, OFF and ASCII PLY, then prefers SceneKit for other formats.
    /// Falls back to Model I/O if SceneKit is unavailable or cannot load the file.
    /// - Parameters:
    ///   - url: The `URL` of the file to be loaded.
    ///   - options: The import options.
    ///   - materialLookup: Maps format-specific materials to Euclid materials. Platform loaders supply
    ///     `MDLMaterial` or `SCNMaterial`; native readers may supply colors. If omitted, materials are retained.
    init(
        url: URL,
        options: ImportOptions = .init(),
        materialLookup: (@Sendable (AnyHashable?) -> Material?)? = nil
    ) throws {
        switch url.pathExtension.lowercased() {
        case "stl", "stla":
            let data = try Data(contentsOf: url)
            guard let mesh = Mesh(stlData: data, options: options, materialLookup: materialLookup) else {
                throw IOError("Invalid STL file")
            }
            self = mesh
        case "off":
            let string = try String(contentsOf: url)
            guard let mesh = Mesh(offString: string, options: options) else {
                throw IOError("Invalid OFF file")
            }
            self = mesh
        case "ply":
            let data = try Data(contentsOf: url)
            if let string = String(data: data, encoding: .utf8),
               let mesh = Mesh(plyString: string, options: options)
            {
                self = mesh
                return
            }
            #if canImport(ModelIO)
            // Retain the platform loader for binary PLY and other supported variants.
            fallthrough
            #else
            throw IOError("Invalid or unsupported PLY file")
            #endif
        case "obj":
            #if canImport(ModelIO)
            // Platform loaders support material libraries.
            fallthrough
            #else
            let string = try String(contentsOf: url)
            guard let mesh = Mesh(objString: string, options: options) else {
                throw IOError("Invalid OBJ file")
            }
            self = mesh
            #endif
        default:
            if !FileManager.default.isReadableFile(atPath: url.path) {
                _ = try Data(contentsOf: url) // Will throw error if unreachable
            }
            var sceneKitError: Error?
            #if canImport(SceneKit)
            do {
                let sceneOptions: [SCNSceneSource.LoadingOption: Any] = [
                    .checkConsistency: true,
                    .flattenScene: true,
                    .createNormalsIfAbsent: true,
                    .convertToYUp: true,
                    .preserveOriginalTopology: true,
                ]
                let importedScene = try SCNScene(url: url, options: sceneOptions)
                if url.pathExtension.lowercased() == "obj" {
                    importedScene.restoreOBJOpacityMaps(from: url)
                }
                self.init(
                    importedScene.rootNode,
                    linearColors: !["ply", "obj"].contains(url.pathExtension.lowercased()),
                    materialLookup: materialLookup
                )
                if options.repairWinding == true {
                    self = withConsistentWinding()
                }
                return
            } catch {
                sceneKitError = error
            }
            #endif
            #if canImport(ModelIO)
            if MDLAsset.canImportFileExtension(url.pathExtension.lowercased()) {
                self = try Mesh(modelIOURL: url, options: options, materialLookup: materialLookup)
                return
            }
            #endif
            try sceneKitError.map { throw $0 }
            throw IOError("Unsupported mesh file format '\(url.pathExtension)'")
        }
    }

    /// Saves a mesh to a file, with optional material mapping.
    ///
    /// Uses native writers for STL, OFF and ASCII PLY, then prefers SceneKit for other formats.
    /// Falls back to Model I/O if SceneKit is unavailable or cannot export the file.
    /// Platform exports accept `MDLMaterial`, `SCNMaterial`, color and image materials.
    /// Format capabilities vary;
    /// not all exporters preserve vertex colors, alpha or textures.
    /// - Parameters:
    ///   - url: The `URL` of the file to be written.
    ///   - materialLookup: A closure to map Euclid materials to format-appropriate materials. Use `nil` for default
    ///     mapping.
    func write(to url: URL, materialLookup: (@Sendable (Material?) -> AnyHashable?)? = nil) throws {
        switch url.pathExtension.lowercased() {
        case "stl":
            let colorLookup = materialLookup.map { lookup in
                { @Sendable in defaultColorMapping(lookup($0)) }
            }
            let data = stlData(colorLookup: colorLookup)
            try data.write(to: url, options: .atomic)
        case "stla":
            let string = stlString(name: "")
            try string.write(to: url, atomically: true, encoding: .utf8)
        case "off":
            let string = offString()
            try string.write(to: url, atomically: true, encoding: .utf8)
        case "ply":
            let colorLookup = materialLookup.map { lookup in
                { @Sendable in defaultColorMapping(lookup($0)) }
            }
            let string = try plyString(colorLookup: colorLookup)
            try string.write(to: url, atomically: true, encoding: .utf8)
        case "obj":
            #if canImport(ModelIO)
            fallthrough
            #else
            let string = objString()
            try string.write(to: url, atomically: true, encoding: .utf8)
            #endif
        default:
            #if canImport(SceneKit) && !os(watchOS)
            if ["scn", "scnz", "dae"].contains(url.pathExtension.lowercased()) {
                let scene = SCNScene()
                let lookup = materialLookup.map { lookup in { defaultMaterialLookup(lookup($0)) } }
                scene.rootNode.addChildNode(SCNNode(geometry: SCNGeometry(polygons: self, materialLookup: lookup)))
                if scene.write(to: url, options: nil, delegate: nil, progressHandler: nil) { return }
            }
            #endif
            #if canImport(ModelIO)
            let isUSD = ["usd", "usda", "usdc", "usdz"].contains(url.pathExtension.lowercased())
            let canExport = MDLAsset.canExportFileExtension(url.pathExtension.lowercased())
            #if canImport(SceneKit) && !os(watchOS)
            let useModelIOMaterials = true
            #else
            let useModelIOMaterials = canExport
            #endif
            if useModelIOMaterials {
                let colorEncoding = ModelIOColorEncoding(fileExtension: url.pathExtension)
                let linearColors = colorEncoding?.isLinear ?? true
                let names = Dictionary(uniqueKeysWithValues: materials.enumerated().map {
                    ($1, "material_\($0)")
                })
                let mappedMaterial: MDLAsset.MDLMaterialProvider = { material in
                    let mapped: AnyHashable? = if let materialLookup {
                        materialLookup(material)
                    } else {
                        material
                    }
                    return try defaultMDLMaterialLookup(
                        mapped,
                        name: names[material] ?? "material",
                        linearColors: linearColors
                    )
                }
                let asset: MDLAsset
                if isUSD, materials.count > 1 {
                    // Model I/O's USD writer loses per-submesh bindings. Give each material its own mesh.
                    // Build separate vertex buffers so unused vertices are not duplicated across groups.
                    asset = MDLAsset()
                    let groups = polygonsByMaterial
                    for (index, material) in materials.enumerated() {
                        let part = try MDLAsset(
                            Mesh(groups[material] ?? []), linearColors: linearColors, materialLookup: mappedMaterial
                        )
                        for objectIndex in 0 ..< part.count {
                            let object = part.object(at: objectIndex)
                            object.name = "mesh_\(index)"
                            asset.add(object)
                        }
                    }
                } else {
                    asset = try MDLAsset(self, linearColors: linearColors, materialLookup: mappedMaterial)
                }
                if let colorEncoding {
                    for case let mesh as MDLMesh in asset.childObjects(of: MDLMesh.self) {
                        for case let submesh as MDLSubmesh in mesh.submeshes ?? [] {
                            submesh.material = submesh.material?.forExport(linearColors: colorEncoding.isLinear)
                        }
                    }
                }
                #if canImport(SceneKit) && !os(watchOS)
                do {
                    // Use the material bridge to preserve texture bytes and opacity, then prefer SceneKit's writer.
                    let scene = SCNScene()
                    var objMaterials = [String: MDLMaterial]()
                    for index in 0 ..< asset.count {
                        let object = asset.object(at: index)
                        let node = SCNNode(mdlObject: object)
                        if let mesh = object as? MDLMesh, let geometry = node.geometry,
                           let submeshes = mesh.submeshes as? [MDLSubmesh]
                        {
                            for (material, submesh) in zip(geometry.materials, submeshes) {
                                if url.pathExtension.lowercased() == "obj", let source = submesh.material {
                                    let name = "material_\(objMaterials.count)"
                                    material.name = name
                                    objMaterials[name] = source
                                }
                                for (property, semantic) in [
                                    (material.diffuse, MDLMaterialSemantic.baseColor),
                                    (material.emission, .emission), (material.specular, .specular),
                                ] {
                                    // Avoid the bridge's shading-model conversion of numeric RGB.
                                    if let source = submesh.material?.property(with: semantic),
                                       let color = Color(source, linearColors: false)
                                    {
                                        property.contents = CGColor(
                                            srgbRed: color.red, green: color.green, blue: color.blue, alpha: color.alpha
                                        )
                                    }
                                }
                            }
                        }
                        scene.rootNode.addChildNode(node)
                    }
                    if scene.write(to: url, options: nil, delegate: nil, progressHandler: nil) {
                        if !objMaterials.isEmpty { try restoreExportedOBJMaterials(at: url, materials: objMaterials) }
                        return
                    }
                }
                #endif
                guard canExport else { throw IOError("Failed to export '\(url.pathExtension)' file") }
                try asset.export(to: url)
                return
            }
            #endif
            throw IOError("Unsupported mesh file format '\(url.pathExtension)'")
        }
    }
}
