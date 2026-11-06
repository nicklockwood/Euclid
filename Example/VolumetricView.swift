//
//  VolumetricView.swift
//  Euclid
//
//  Created by Hal Mueller on 3/6/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Euclid
import RealityKit
import Spatial
import SwiftUI

#if os(visionOS)

struct VolumetricView: View {
    @State private var transform: RealityKit.Transform = .identity
    @State private var delta: RealityKit.Transform = .identity

    var body: some View {
        GeometryReader3D { geometry in
            RealityView { content in
                let mesh = euclidMesh.translated(by: -euclidMesh.bounds.center)
                guard let demoBoxEntity = try? await exampleRealityKitEntity(mesh) else { return }
                // Add a shadow for realism
                demoBoxEntity.components.set(GroundingShadowComponent(castsShadow: true))
                // Needed for tap detection/response
                // Descriptor-backed collision meshes also work on older RealityKit runtimes.
                if #available(visionOS 2.0, *) {
                    if let resource = try? await MeshResource.generate(from: [MeshDescriptor(triangles: mesh)]),
                       let shape = try? await ShapeResource.generateStaticMesh(from: resource)
                    {
                        demoBoxEntity.components.set(CollisionComponent(shapes: [shape]))
                    }
                } else {
                    demoBoxEntity.generateCollisionShapes(recursive: true)
                }
                // Add gesture targeting
                demoBoxEntity.components.set(InputTargetComponent())
                content.add(demoBoxEntity)
                fit(demoBoxEntity, geometry: geometry, content: content)
            } update: { content in
                if let entity = content.entities.first {
                    fit(entity, geometry: geometry, content: content)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .targetedToAnyEntity()
                    .onChanged { value in
                        let spin = value
                            .convert(value.translation3D, from: .local, to: .scene) * SIMD3<Float>(repeating: 10)
                        delta = RealityKit.Transform(pitch: -spin.y, yaw: spin.x)
                    }
                    .onEnded { _ in
                        transform.matrix = delta.matrix * transform.matrix
                        delta = .identity
                    }
            )
        }
    }

    private func fit(_ entity: Entity, geometry: GeometryProxy3D, content: RealityViewContent) {
        let frame = geometry.frame(in: .local)
        // Convert each edge separately: an axis-aligned scene-space bounding box grows
        // when the volume is angled, and no longer describes its actual clipping depth.
        let width = simd_length(content.convert(
            Vector3D(x: frame.size.width, y: 0, z: 0), from: .local, to: .scene
        ))
        let height = simd_length(content.convert(
            Vector3D(x: 0, y: frame.size.height, z: 0), from: .local, to: .scene
        ))
        let depth = simd_length(content.convert(
            Vector3D(x: 0, y: 0, z: frame.size.depth), from: .local, to: .scene
        ))
        // The bounding-box diagonal encloses the centered mesh at every orientation.
        let diameter = Float(euclidMesh.bounds.size.length)
        let scale = 0.9 * min(width, height, depth) / diameter
        entity.transform = RealityKit.Transform(
            scale: SIMD3<Float>(repeating: scale),
            rotation: delta.rotation * transform.rotation,
            // UIKit-hosted volumes place their depth center at SwiftUI's z=0 plane.
            translation: content.convert(
                Point3D(x: frame.center.x, y: frame.center.y, z: frame.origin.z),
                from: .local, to: .scene
            )
        )
    }
}

#endif
