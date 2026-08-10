//
//  Mesh+IO.swift
//  Euclid
//
//  Created by Nick Lockwood on 26/01/2024.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation
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
    /// - Parameters:
    ///   - url: The `URL` of the file to be loaded.
    ///   - options: The import options.
    ///   - materialLookup: A closure to map format-specific materials to Euclid materials. Use `nil` for default
    ///     mapping.
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
        case "obj":
            #if canImport(SceneKit)
            // SceneKit supports materials, etc.
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
            #if canImport(SceneKit)
            let sceneOptions: [SCNSceneSource.LoadingOption: Any] = [
                .checkConsistency: true,
                .flattenScene: true,
                .createNormalsIfAbsent: true,
                .convertToYUp: true,
                .preserveOriginalTopology: true,
            ]
            let importedScene = try SCNScene(url: url, options: sceneOptions)
            self.init(importedScene.rootNode, materialLookup: materialLookup)
            if options.repairWinding == true {
                self = withConsistentWinding()
            }
            #else
            throw IOError("Unsupported mesh file format '\(url.pathExtension)'")
            #endif
        }
    }

    /// Saves a mesh to a file, with optional material mapping.
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
        case "obj":
            #if canImport(SceneKit) && !os(watchOS)
            // SceneKit supports materials, etc.
            fallthrough
            #else
            let string = objString()
            try string.write(to: url, atomically: true, encoding: .utf8)
            #endif
        default:
            #if os(watchOS)
            throw IOError("Cannot export '\(url.pathExtension)' on watchOS.")
            #elseif canImport(SceneKit)
            let scnScene = SCNScene()
            let materialLookup = materialLookup.map { lookup in { defaultMaterialLookup(lookup($0)) } }
            let geometry = SCNGeometry(polygons: self, materialLookup: materialLookup)
            scnScene.rootNode.addChildNode(SCNNode(geometry: geometry))
            guard scnScene.write(
                to: url,
                options: [:],
                delegate: nil,
                progressHandler: nil
            ) else {
                throw IOError("Failed to export file")
            }
            #else
            throw IOError("Unsupported mesh file format '\(url.pathExtension)'")
            #endif
        }
    }
}
