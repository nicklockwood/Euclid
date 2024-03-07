//
//  ImmersiveView.swift
//  ExampleVisionOS
//
//  Created by Hal Mueller on 3/5/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    let mesh = euclidMesh
    
    var body: some View {
        RealityView { content in
            // Add the initial RealityKit content
            if let scene = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                content.add(scene)
            }
        }
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
}
