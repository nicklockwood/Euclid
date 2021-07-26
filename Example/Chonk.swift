//
//  Chonk.swift
//
//  Created by Zack Brown on 16/06/2021.
//

import Euclid
import Foundation

struct Chonk: Prop {
    
    var peakCenter: Vector { (plane.normal * ((height / 2.0) + peak)) }
    var baseCenter: Vector { (plane.normal * (base + (height / 2.0))) }
    
    let plane: Plane
    
    let peak: Double
    let base: Double
    let height: Double
    
    let peakRadius: Double
    let baseRadius: Double
    
    let segments: Int
    
    func build(position: Vector) -> [Polygon] {
        
        var slices: [[Vector]] = []
        
        //
        /// Create peak and base vertices
        //
        
        let rotation = Angle(radians: (Double.pi * 2.0) / Double(segments))
        
        for slice in 0...1 {
            
            var layer: [Vector] = []
            
            let radius = slice == 0 ? baseRadius : peakRadius
            
            for segment in 0..<segments {
                
                let angle = rotation * Double(segment)
                
                let distance = (slice == 0 ? -1 : 1) * (height / 2.0)
                
                layer.append(plot(radians: angle.radians, radius: radius).project(onto: plane) + (plane.normal * distance))
            }
            
            slices.append(layer)
        }
        
        //
        /// Create faces for peak, base and edge
        //
        
        guard let upper = slices.last,
              let lower = slices.first else { return [] }
        
        var polygons: [Polygon] = []
        
        for segment in 0..<segments {
            
            let v0 = position + upper[(segment + 1) % segments]
            let v1 = position + upper[segment]
            let v2 = position + lower[segment]
            let v3 = position + lower[(segment + 1) % segments]
            
            //
            /// Create edge face
            //
            
            guard let lhs = self.polygon(vectors: [v0, v1, v2]),
                  let rhs = self.polygon(vectors: [v0, v2, v3]) else { continue }
            
            polygons.append(contentsOf: [lhs, rhs])
            
            //
            /// Create peak face
            //
            
            guard let polygon = self.polygon(vectors: [v1, v0, position + peakCenter]) else { continue }
            
            polygons.append(polygon)
            
            //
            /// Create base face
            //
            
            guard let polygon = self.polygon(vectors: [v3, v2, position - baseCenter]) else { continue }
            
            polygons.append(polygon)
        }
        
        return polygons
    }
}
