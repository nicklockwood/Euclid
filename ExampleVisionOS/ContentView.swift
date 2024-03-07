//
//  ContentView.swift
//  ExampleVisionOS
//
//  Created by Hal Mueller on 3/5/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import RealityKit
import RealityKitContent
import SwiftUI

struct ContentView: View {
    @State private var enlarge = false
    @State private var showImmersiveSpace = false
    @State private var immersiveSpaceIsShown = false

    var body: some View {
        VolumetricView()
    }
}

#Preview(windowStyle: .volumetric) {
    ContentView()
}
