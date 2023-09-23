//
//  SceneKitViewController.swift
//  Example
//
//  Created by Nick Lockwood on 11/12/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

import Euclid
import SceneKit
import UIKit

class SceneKitViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // create a new scene
        let scene = SCNScene()

        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)

        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 2)

        // create SCNNode
        let geometry = SCNGeometry(euclidMesh)
        let node = SCNNode(geometry: geometry)
        scene.rootNode.addChildNode(node)

        // configure the SCNView
        let scnView = view as! SCNView
        scnView.scene = scene
        scnView.autoenablesDefaultLighting = true
        scnView.allowsCameraControl = true
        scnView.backgroundColor = .white
    }

    override var shouldAutorotate: Bool {
        true
    }

    override var prefersStatusBarHidden: Bool {
        true
    }
}
