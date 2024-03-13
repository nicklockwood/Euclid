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

    private var viewModel = MeshViewModel()

    var body: some View {
        let _ = Self._printChanges()

        RealityView { content in
            // In this demo we'll skip adding content at init time. But if you have other content
            // that you want visible while the EuclidMesh is being built, add it in this closure.
            // A simulated expensive, long-running Mesh generation happens on its own Task.
            debugPrint(content)
        } update: { content in
            if viewModel.contentReady,
               !viewModel.contentAdded,
               let box = viewModel.entity
            {
                content.add(box)
                viewModel.contentAdded = true
            }
            guard let entity = content.entities.first else {
                return
            }

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
        .task {
            viewModel.prepareContent()
            print("content preparation launched...")
        }
    }
}

#Preview {
    VolumetricView()
}
