//
//  SceneViewController.swift
//  Example
//
//  Created by Nick Lockwood on 11/12/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

import Euclid
import SceneKit
import UIKit

class SceneViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // create a new scene
        let scene = SCNScene()

        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)

        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 3)

        // create some geometry using Euclid
        let start = CFAbsoluteTimeGetCurrent()

        let url = Bundle.main.url(forResource: "Mesh", withExtension: "json")
        let data = try! Data(contentsOf: url!)
        let frond = try! JSONDecoder().decode(Mesh.self, from: data)

        var mesh = Mesh([]) // start with empty mesh

        // create foliage
        var a = 0.0
        for _ in 0 ..< 10 {
            let r = Rotation(axis: Vector(0, 0, 1), angle: .degrees(a))!
            a += 36
            let frond = frond.translated(by: Vector(0, -1, 0)).rotated(by: r)

            mesh = mesh.union(frond) // union into one big mesh
        }

        print("Time:", CFAbsoluteTimeGetCurrent() - start)
        print("Polys:", mesh.polygons.count)

        // create SCNNode
        let geometry = SCNGeometry(mesh)
        let node = SCNNode(geometry: geometry)
        scene.rootNode.addChildNode(node)

        // configure the SCNView
        let scnView = view as! SCNView
        scnView.scene = scene
        scnView.autoenablesDefaultLighting = true
        scnView.allowsCameraControl = true
        scnView.showsStatistics = true
        scnView.backgroundColor = .white
    }

    override var shouldAutorotate: Bool {
        true
    }

    override var prefersStatusBarHidden: Bool {
        true
    }
}
