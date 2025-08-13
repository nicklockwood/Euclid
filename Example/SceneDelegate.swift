//
//  SceneDelegate.swift
//  Euclid
//
//  Created by Nick Lockwood on 13/08/2025.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

import SwiftUI
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo _: UISceneSession,
        options _: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else {
            fatalError("Expected scene of type UIWindowScene but got an unexpected type")
        }

        window = UIWindow(windowScene: windowScene)
        #if os(visionOS)
        window?.rootViewController = TransparentHostingController(rootView: VolumetricView())
        #else
        window?.backgroundColor = UIColor.white
        window?.rootViewController = SceneKitViewController()
        if #available(iOS 15.0, tvOS 26.0, *) {
            let tabBarController = UITabBarController()
            tabBarController.viewControllers = [
                SceneKitViewController(),
                RealityKitViewController(),
            ]
            window?.rootViewController = tabBarController
        }
        #endif
        window?.makeKeyAndVisible()
    }
}

#if os(visionOS)

private final class TransparentHostingController<Content: View>: UIHostingController<Content> {
    override var preferredContainerBackgroundStyle: UIContainerBackgroundStyle {
        .hidden
    }
}

#endif
