//
//  ExampleVisionOSApp.swift
//  ExampleVisionOS
//
//  Created by Hal Mueller on 3/5/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import SwiftUI

@main
struct ExampleVisionOSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
        }.windowStyle(.volumetric)
            .defaultSize(width: 2.0, height: 2.0, depth: 2.0, in: .meters)

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }
    }
}
