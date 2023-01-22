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

        // create some geometry using Euclid
        let start = CFAbsoluteTimeGetCurrent()
//        let cube = Mesh.cube(size: 0.8, material: UIColor.red)
//        let sphere = Mesh.sphere(slices: 120, material: UIColor.blue)
//        let mesh = cube.subtracting(sphere).makeWatertight()

//        print("Time:", CFAbsoluteTimeGetCurrent() - start)
//        print("Polygons:", mesh.polygons.count)
//        print("Triangles:", mesh.triangulate().polygons.count)
//        print("Watertight:", mesh.isWatertight)

        let polygon1 = Path.square(color: .red)
        let polygon2 = Path.square(color: .green).translated(by: Vector(0.5, 0.5, 0)) // .rotated(by: .yaw(.pi / 5))
        let polygon3 = Path.square(color: .blue).translated(by: Vector(0.25, -0.25, 0)) // .rotated(by: .yaw(.pi / 5))
        let result = Path.difference([polygon1, polygon2, polygon3])
        let mesh = Mesh.fill(result)

        // create SCNNode
        let geometry = SCNGeometry(mesh)
        let node = SCNNode(geometry: geometry)
        scene.rootNode.addChildNode(node)

        // configure the SCNView
        let scnView = view as! SCNView
        scnView.scene = scene
//        scnView.autoenablesDefaultLighting = true
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
