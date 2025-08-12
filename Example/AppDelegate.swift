//
//  AppDelegate.swift
//  Example
//
//  Created by Nick Lockwood on 11/12/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        window = UIWindow()
        window?.rootViewController = SceneKitViewController()
        #if !os(visionOS)
        if #available(iOS 15.0, tvOS 26.0, *) {
            let tabBarController = UITabBarController()
            tabBarController.viewControllers = [
                SceneKitViewController(),
                RealityKitViewController(),
            ]
            window?.rootViewController = tabBarController
        }
        #endif
        window?.backgroundColor = UIColor.white
        window?.makeKeyAndVisible()
        return true
    }
}
