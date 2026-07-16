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

final class SceneKitViewController: UIViewController {
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        title = "SceneKit"
    }

    required init?(coder _: NSCoder) {
        nil
    }

    override func loadView() {
        view = SCNView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // create a new scene
        let scene = SCNScene()

        let bounds = euclidMesh.bounds
        let fieldOfView = Angle.degrees(60)
        let cameraDistance = framingCameraDistance(for: bounds, fov: fieldOfView)

        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = fieldOfView.degrees
        cameraNode.camera?.zNear = 0.01
        cameraNode.camera?.zFar = max(cameraDistance + bounds.size.length * 2, 100)
        scene.rootNode.addChildNode(cameraNode)

        // place the camera
        cameraNode.position = SCNVector3(
            x: Float(bounds.center.x),
            y: Float(bounds.center.y),
            z: Float(bounds.center.z + cameraDistance)
        )

        // create SCNNode
        let geometry = SCNGeometry(euclidMesh)
        let node = SCNNode(geometry: geometry)
        scene.rootNode.addChildNode(node)

        // configure the SCNView
        let scnView = view as! SCNView
        scnView.scene = scene
        scnView.pointOfView = cameraNode
        scnView.autoenablesDefaultLighting = true
        scnView.allowsCameraControl = true
        scnView.backgroundColor = .white
        scnView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    #if !os(tvOS)

    override var shouldAutorotate: Bool {
        true
    }

    #endif
}
