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
        
        let normal = Vector(0, 1, 0)
        
        guard let plane = Plane(normal: normal, pointOnPlane: .zero) else { fatalError("Error creating plane") }
        
        var position = Vector.zero
        var mesh = Mesh([])
        
        let slices = 10
        
        let chonk = Chonk(plane: plane,
                          peak: 0.05,
                          base: 0.01,
                          height: 0.125,
                          peakRadius: 0.07,
                          baseRadius: 0.05,
                          segments: 7)
        
        for slice in 0..<slices {
            
            mesh = mesh.union(Mesh(chonk.build(position: position)))
            
            position += chonk.peakCenter
        }
        
        let fronds = 10
        
        let rotation = Angle(radians: (Double.pi * 2.0) / Double(fronds))
        
        for leaf in 0..<fronds {
            
            let angle = (rotation.radians * Double(leaf))
            
            let frond = Frond(plane: plane,
                              angle: angle,
                              radius: 0.5,
                              width: 0.1,
                              thickness: 0.02,
                              spread: 0.01,
                              segments: 7)
            
            mesh = mesh.union(Mesh(frond.build(position: position)))
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
