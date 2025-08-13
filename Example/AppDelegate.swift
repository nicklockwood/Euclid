//
//  AppDelegate.swift
//  Example
//
//  Created by Nick Lockwood on 11/12/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

import SwiftUI
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        true
    }

    func application(
        _: UIApplication,
        configurationForConnecting _: UISceneSession,
        options _: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        #if os(visionOS)
        .init(name: "Default", sessionRole: .windowApplicationVolumetric)
        #else
        .init(name: "Default", sessionRole: .windowApplication)
        #endif
    }
}
