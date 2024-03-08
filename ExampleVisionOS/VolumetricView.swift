//
//  VolumetricView.swift
//  ExampleVisionOS
//
//  Created by Hal Mueller on 3/6/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import RealityKit
import SwiftUI

struct VolumetricView: View {
    @State private var spinX = 0.0
    @State private var spinY = 0.0

    var body: some View {
        RealityView { content in
            if let demoBoxEntity = try? ModelEntity(euclidMesh) {
                // for more realism, add a shadow
                demoBoxEntity.components.set(GroundingShadowComponent(castsShadow: true))

                // needed for tap detection/response
                demoBoxEntity.generateCollisionShapes(recursive: true)

                // for gesture targeting
                demoBoxEntity.components.set(InputTargetComponent())

                content.add(demoBoxEntity)
            }
        } update: { content in
            guard let entity = content.entities.first else { return }

            let pitch = Transform(pitch: Float(spinX * -1)).matrix
            let yaw = Transform(yaw: Float(spinY)).matrix
            entity.transform.matrix = pitch * yaw
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .targetedToAnyEntity()
                .onChanged { value in
                    let startLocation = value.convert(value.startLocation3D, from: .local, to: .scene)
                    let currentLocation = value.convert(value.location3D, from: .local, to: .scene)
                    let delta = currentLocation - startLocation
                    spinX = Double(delta.y) * 5
                    spinY = Double(delta.x) * 5
                }
        )
    }
}

#Preview {
    VolumetricView()
}
