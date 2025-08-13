//
//  VolumetricView.swift
//  Euclid
//
//  Created by Hal Mueller on 3/6/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import RealityKit
import SwiftUI

#if os(visionOS)

struct VolumetricView: View {
    @State private var transform: Transform = .identity
    @State private var delta: Transform = .identity

    var body: some View {
        RealityView { content in
            guard let demoBoxEntity = try? ModelEntity(euclidMesh.scaled(by: 0.4)) else {
                return
            }
            // Add a shadow for realism
            demoBoxEntity.components.set(GroundingShadowComponent(castsShadow: true))
            // Needed for tap detection/response
            demoBoxEntity.generateCollisionShapes(recursive: true)
            // Add gesture targeting
            demoBoxEntity.components.set(InputTargetComponent())
            content.add(demoBoxEntity)
        } update: { content in
            content.entities.first?.transform.matrix = delta.matrix * transform.matrix
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .targetedToAnyEntity()
                .onChanged { value in
                    let spin = value.convert(value.translation3D, from: .local, to: .scene) * .init(10)
                    delta = Transform(pitch: -spin.y, yaw: spin.x)
                }
                .onEnded { _ in
                    transform.matrix = delta.matrix * transform.matrix
                    delta = .identity
                }
        )
    }
}

#endif
