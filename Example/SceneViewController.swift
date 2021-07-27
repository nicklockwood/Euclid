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
        
        let mesh = Mesh(build(position: .zero))

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

extension SceneViewController: Prop {
    
    func build(position: Vector) -> [Polygon] {
        
        //
        /// Params
        //
        
        let trunk = (slices: 7,
                     height: 1.0,
                     spread: 0.1,
                     crown: (segments: 7,
                             peak: 0.056,
                             base: 0.01,
                             baseRadius: 0.042,
                             peakRadius: 0.077),
                     segment: (segments: 7,
                               peak: 0.049,
                               base: 0.01,
                               baseRadius: 0.014,
                               peakRadius: 0.035),
                     throne: (segments: 7,
                              peak: 0.07,
                              base: 0.08,
                              baseRadius: 0.1,
                              peakRadius: 0.09))
        
        let foliage = (frond: (segments: 7,
                               radius: 0.42,
                               width: 0.14,
                               thickness: 0.014,
                               spread: 0.014),
                       fronds: 7)
        
        //
        /// Create plam tree trunk and throne
        //
        
        guard let plane = Plane(normal: Vector(0, 1, 0), pointOnPlane: .zero) else { return [] }
        
        let sample = Double.random(in: 0..<1, using: &rng)
        
        let yStep = Double(1.0 / Double(trunk.slices))
        let segmentHeight = Double(((trunk.height / Double(trunk.slices))) - (trunk.segment.peak + trunk.segment.base))
        let offset = Vector(sample * trunk.spread, trunk.height, sample * trunk.spread)
        let control = Vector(0, trunk.height, 0)
         
        var node = Chonk(plane: plane, peak: trunk.throne.peak, base: trunk.throne.base, height: segmentHeight, peakRadius: trunk.throne.peakRadius, baseRadius: trunk.throne.baseRadius, segments: trunk.throne.segments)
        
        var center = position + Vector(0, 0.05, 0)
        
        var mesh = Mesh(node.build(position: center))
        
        center = center + node.peakCenter
        
        for slice in 0..<trunk.slices {
            
            let position = curve(start: node.peakCenter, end: offset, control: control, interpolator: Double(slice + 1) * yStep)
            
            guard let plane = Plane(normal: position.normalized(), pointOnPlane: .zero) else { continue }
            
            let segment = Chonk(plane: plane, peak: trunk.segment.peak, base: trunk.segment.base, height: segmentHeight, peakRadius: trunk.segment.peakRadius, baseRadius: trunk.segment.baseRadius, segments: trunk.segment.segments)
            
            mesh = mesh.union(Mesh(segment.build(position: center)))
            
            center = center + segment.peakCenter

            node = segment
        }
        
        node = Chonk(plane: node.plane, peak: trunk.crown.peak, base: trunk.crown.base, height: (segmentHeight / 2.0), peakRadius: trunk.crown.peakRadius, baseRadius: trunk.crown.baseRadius, segments: trunk.crown.segments)
        
        mesh = mesh.union(Mesh(node.build(position: center)))
        
        //
        /// Create palm tree leaves
        //
        
        let rotation = Angle(radians: (Double.pi * 2.0) / Double(foliage.fronds))
        
        for leaf in 0..<foliage.fronds {
            
            let angle = (rotation.radians * Double(leaf))
            
            let frond = Frond(plane: node.plane, angle: angle, radius: foliage.frond.radius, width: foliage.frond.width, thickness: foliage.frond.thickness, spread: foliage.frond.spread, segments: foliage.frond.segments)
            
            mesh = mesh.union(Mesh(frond.build(position: center + node.peakCenter)))
        }
        
        return mesh.polygons
    }
}
