//
//  MeshViewModel.swift
//  Euclid
//
//  Created by Hal Mueller on 3/11/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import CoreGraphics
import Euclid
import RealityKit

@Observable
class MeshViewModel {
    var entity: Entity? = nil
    
    func prepareContent()  {
        Task.init {
            do {
                let demoBoxEntity = try await ModelEntity(euclidMesh.scaled(by: 0.5))// {
                
                // for more realism, add a shadow
                await demoBoxEntity.components.set(GroundingShadowComponent(castsShadow: true))
                
                // needed for tap detection/response
                await demoBoxEntity.generateCollisionShapes(recursive: true)
                
                // for gesture targeting
                await demoBoxEntity.components.set(InputTargetComponent())
                
                print(#function, "complete")
                entity = demoBoxEntity
            } catch {
                print("nope")
            }
        }
    }
}
