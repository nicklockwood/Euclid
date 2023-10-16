//
//  RealityKitViewController.swift
//  Example
//
//  Created by Nick Lockwood on 22/10/2022.
//  Copyright © 2022 Nick Lockwood. All rights reserved.
//

import Combine
import Euclid
import RealityKit
import UIKit

class RealityKitViewController: UIViewController, UIGestureRecognizerDelegate {
    var updateSubscription: Cancellable!
    var modelPosition: Vector = .zero
    var modelPitch = 0.0
    var modelYaw = 0.0
    var cameraRoll = 0.0
    var cameraFOV = 60.0
    var cameraDistance = 2.0

    @objc private func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        let scale = recognizer.scale
        cameraFOV = max(5, min(120, cameraFOV / scale))
        recognizer.scale = 1.0
    }

    @objc private func handleRotate(_ recognizer: UIRotationGestureRecognizer) {
        cameraRoll -= recognizer.rotation
        recognizer.rotation = 0
    }

    @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: recognizer.view)
        if recognizer.numberOfTouches == 2 {
            modelPosition.x += translation.x * 0.002
            modelPosition.y -= translation.y * 0.002
        } else {
            modelYaw -= translation.x * 0.005
            modelPitch -= translation.y * 0.005
        }
        recognizer.setTranslation(.zero, in: recognizer.view)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let arView = ARView(
            frame: view.frame,
            cameraMode: .nonAR,
            automaticallyConfigureSession: false
        )
        arView.environment.background = .color(.white)
        arView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(arView)

        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinchRecognizer.delegate = self
        arView.addGestureRecognizer(pinchRecognizer)

        let rotateRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(handleRotate(_:)))
        rotateRecognizer.delegate = self
        arView.addGestureRecognizer(rotateRecognizer)

        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panRecognizer.delegate = self
        arView.addGestureRecognizer(panRecognizer)

        var modelEntity: ModelEntity?
        if #available(macOS 12.0, iOS 15.0, *) {
            // create ModelEntity
            if let entity = try? ModelEntity(euclidMesh) {
                modelEntity = entity
                let anchor = AnchorEntity(world: .zero)
                anchor.addChild(entity)
                arView.scene.anchors.append(anchor)
            }
        } else {
            let alert = UIAlertController(
                title: "Unsupported",
                message: "Euclid RealityKit support requires a minimum of iOS 15.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            present(alert, animated: true)
        }

        let cameraEntity = PerspectiveCamera()
        let cameraAnchor = AnchorEntity(world: .zero)
        cameraAnchor.addChild(cameraEntity)
        arView.scene.addAnchor(cameraAnchor)

        updateSubscription = arView.scene.subscribe(to: SceneEvents.Update.self) { [weak self] _ in
            guard let self = self else { return }

            modelEntity?.transform = Transform(
                scale: .one,
                rotation: simd_quatf(Rotation(pitch: .radians(self.modelPitch), yaw: .radians(self.modelYaw))),
                translation: .init(self.modelPosition)
            )

            cameraEntity.camera.fieldOfViewInDegrees = Float(cameraFOV)
            cameraEntity.transform = Transform(
                scale: .one,
                rotation: simd_quatf(Rotation(roll: .radians(self.cameraRoll))),
                translation: .init(0, 0, Float(cameraDistance))
            )
        }
    }
}
