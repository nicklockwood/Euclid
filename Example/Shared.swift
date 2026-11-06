//
//  Shared.swift
//  Example
//
//  Created by Nick Lockwood on 20/09/2023.
//  Copyright © 2023 Nick Lockwood. All rights reserved.
//

import Euclid
import RealityKit
import SceneKit
import UIKit

func framingCameraDistance(for bounds: Bounds, fov: Angle, aspectRatio: Double = 1) -> Double {
    let halfSize = bounds.size / 2
    let tangent = tan(fov.radians / 2)
    let distance = max(halfSize.x / (tangent * max(aspectRatio, 0.1)), halfSize.y / tangent) + halfSize.z
    return max(distance * 1.2, 2)
}

private enum ExampleMaterial {
    static let vaseColor = UIColor(red: 0.85, green: 0.5, blue: 0.2, alpha: 1)

    case vertexColors, lathe
}

let euclidMesh: Mesh = {
    let start = CFAbsoluteTimeGetCurrent()
    let tilt = Rotation(pitch: .degrees(15), yaw: .degrees(-25))

    // Boolean subtraction preserves the subtracted shape's material on the new interior faces.
    let cutout = Mesh.cube(size: 0.95, material: Color(red: 0.08, green: 0.55, blue: 0.7))
        .subtracting(Mesh.sphere(radius: 0.6, slices: 48, material: CGImage.checkerboard()))
        .makeWatertight()
        .rotated(by: tilt)
        .translated(by: [-0.8, 0.75, 0])

    // Color individual vertices by position. The renderer interpolates between them.
    let sphere = Mesh.sphere(radius: 0.6, slices: 48, material: ExampleMaterial.vertexColors)
    let gradient = Mesh(sphere.polygons.flatMap { polygon in
        polygon.mapVertices { vertex in
            let t = (vertex.position.y / 0.6 + 1) / 2
            let color = Color(red: 1 - t * 0.8, green: 0.2 + t * 0.6, blue: 0.3 + t * 0.7)
            return vertex.withColor(color)
        }
    }).translated(by: [0.8, 0.75, 0])

    // Loft matching cross-sections, rotating and scaling each one to create a twist.
    let sections = (0 ... 16).map { index -> Path in
        let t = Double(index) / 16
        return Path.polygon(radius: 0.45, sides: 6)
            .scaled(by: 0.75 + 0.25 * cos(t * .pi * 2))
            .rotated(by: Rotation(roll: .degrees(t * 100)))
            .translated(by: [0, 0, t * 1.1 - 0.55])
    }
    let loft = Mesh.loft(sections, material: Color(red: 0.7, green: 0.2, blue: 0.45))
        .rotated(by: Rotation(pitch: .degrees(75), yaw: .degrees(-20)))
        .translated(by: [-0.8, -0.75, 0])

    // Revolve a curved profile around the Y axis to create a vase with a closed base.
    let profile = Path.curve([
        .point(0, -0.55), .point(0.3, -0.55),
        .curve(0.45, -0.35), .curve(0.4, 0), .curve(0.2, 0.3),
        .point(0.3, 0.55), .point(0.24, 0.55),
        .curve(0.15, 0.3), .curve(0.34, 0), .curve(0.38, -0.35),
        .point(0.25, -0.48), .point(0, -0.48), .point(0, -0.55),
    ], detail: 6)
    let lathe = Mesh.lathe(profile, slices: 64, material: ExampleMaterial.lathe)
        .rotated(by: Rotation(pitch: .degrees(-15)))
        .translated(by: [0.8, -0.75, 0])

    // Merge combines separate objects into one mesh without performing a boolean union.
    let mesh = Mesh.merge([cutout, gradient, loft, lathe])
    print("Time:", CFAbsoluteTimeGetCurrent() - start)
    print("Polygons:", mesh.polygons.count)
    print("Triangles:", mesh.triangulate().polygons.count)
    print("Watertight:", mesh.isWatertight)
    return mesh
}()

@MainActor
func exampleSceneKitGeometry(_ mesh: Mesh) -> SCNGeometry {
    let vase = SCNMaterial()
    vase.lightingModel = .physicallyBased
    vase.diffuse.contents = ExampleMaterial.vaseColor
    vase.roughness.contents = 0.25
    vase.metalness.contents = 0.8
    // SceneKit handles vertex colors, Color and CGImage materials automatically.
    return SCNGeometry(mesh.replacing(ExampleMaterial.lathe, with: vase))
}

@MainActor
@available(tvOS 26.0, *)
func exampleRealityKitEntity(_ mesh: Mesh) async throws -> ModelEntity {
    var renderMesh = mesh
    var preservesVertexColors = false
    #if compiler(>=6)
    if #available(iOS 18.0, visionOS 2.0, *) {
        preservesVertexColors = true
    }
    #endif
    if !preservesVertexColors {
        // Older RealityKit versions lack vertex color. Approximate gradient per face.
        renderMesh = Mesh(mesh.polygons.map { polygon in
            guard polygon.material as? ExampleMaterial == .vertexColors else { return polygon }
            return polygon.withMaterial(polygon.vertices[0].color).withoutVertexColors()
        })
    }

    // Let Euclid handle colors, textures and vertex gradients, then customize the metallic vase.
    let entity = try await ModelEntity(renderMesh)
    if let index = renderMesh.materials.firstIndex(of: ExampleMaterial.lathe) {
        var vase = PhysicallyBasedMaterial()
        vase.baseColor = .init(tint: ExampleMaterial.vaseColor)
        vase.roughness = .init(floatLiteral: 0.25)
        vase.metallic = .init(floatLiteral: 0.8)
        entity.model?.materials[index] = vase
    }
    return entity
}

@MainActor
func addExampleCaption(to view: UIView) {
    let caption = UILabel()
    caption.text = "Top: CSG cutout · Vertex colors\nBottom: Twisted loft · Lathed profile"
    caption.font = .preferredFont(forTextStyle: .caption1)
    caption.adjustsFontForContentSizeCategory = true
    caption.textAlignment = .center
    caption.numberOfLines = 0
    caption.textColor = .darkGray
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)
    NSLayoutConstraint.activate([
        caption.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
        caption.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
        caption.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
    ])
}
