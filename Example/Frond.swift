//
//  Frond.swift
//
//  Created by Zack Brown on 18/06/2021.
//

import Euclid
import Foundation

struct Frond: Prop {
    
    let plane: Plane
    
    let angle: Double
    let radius: Double
    let width: Double
    let thickness: Double
    let spread: Double
    
    let segments: Int

    func build(position: Vector) -> [Polygon] {
            
        let step = Double(1.0 / Double(segments))
        
        let anchor = plot(radians: angle, radius: radius)
        let control = position + anchor.project(onto: plane)
        let end = control + (-plane.normal * radius)
        let middle = curve(start: position, end: end, control: control, interpolator: 0.5)
        let perpendicular = [position, middle, end].normal()
        var length = ease(curve: .out, value: step) * width
        
        var polygons: [Euclid.Polygon] = []
        
        var sweep = (lhs: position + (-perpendicular * (length / 2.0)),
                     curve: position,
                     rhs: position + (perpendicular * (length / 2.0)))
        
        for segment in 1..<segments {

            let interpolator = step * Double(segment)

            let point = curve(start: position, end: end, control: control, interpolator: interpolator)

            length = ease(curve: .out, value: interpolator) * width

            let current = (lhs: (point + (-perpendicular * length)),
                           curve: point,
                           rhs: (point + (perpendicular * length)))
            
            let lhs = [sweep.curve, sweep.lhs, current.lhs, current.curve]
            let rhs = [sweep.rhs, sweep.curve, current.curve, current.rhs]
            
            let cut0 = Double.random(in: 0...10) <= 1
            let cut1 = Double.random(in: 0...10) <= 1
            
            polygons.append(contentsOf: face(vertices: lhs, side: .left, cut: cut0))
            polygons.append(contentsOf: face(vertices: rhs, side: .right, cut: cut1))
            
            if segment == 1 {
                
                let n0 = lhs.normal()
                let n1 = rhs.normal()
                
                let v0 = sweep.lhs - (n0 * thickness)
                let v1 = sweep.rhs - (n1 * thickness)
                let v2 = v0.lerp(v1, 0.5)
                
                guard let lf0 = polygon(vectors: [sweep.lhs, sweep.curve, v2]),
                      let lf1 = polygon(vectors: [sweep.lhs, v2, v0]),
                      let rf0 = polygon(vectors: [sweep.curve, sweep.rhs, v1]),
                      let rf1 = polygon(vectors: [sweep.curve, v1, v2]) else { continue }
                
                polygons.append(contentsOf: [lf0, lf1, rf0, rf1])
            }

            sweep = current
        }

        let upperFace = [sweep.rhs, sweep.lhs, end]
        let normal = upperFace.normal()
        let lowerFace = [end, sweep.lhs, sweep.rhs].map{ $0 - (normal * thickness) }
        let leftFace = [upperFace[2], upperFace[1], lowerFace[1], lowerFace[0]]
        let rightFace = [upperFace[0], upperFace[2], lowerFace[0], lowerFace[2]]
        
        guard let upperPolygon = self.polygon(vectors: upperFace),
              let lowerPolygon = self.polygon(vectors: lowerFace),
              let lp0 = self.polygon(vectors: [leftFace[0], leftFace[1], leftFace[2]]),
              let lp1 = self.polygon(vectors: [leftFace[0], leftFace[2], leftFace[3]]),
              let rp0 = self.polygon(vectors: [rightFace[0], rightFace[1], rightFace[2]]),
              let rp1 = self.polygon(vectors: [rightFace[0], rightFace[2], rightFace[3]]) else { return polygons }

        polygons.append(contentsOf: [upperPolygon, lowerPolygon, lp0, lp1, rp0, rp1])
        
        return polygons
    }
}

extension Frond {
    
    enum Side {
        
        case left
        case right
    }
    
    func face(vertices: [Vector], side: Side, cut: Bool) -> [Polygon] {
        
        let normal = vertices.normal()
        
        let lowerVertices = vertices.reversed().map { $0 - (normal * thickness) }
        
        let faces = (upper: (vertices: vertices, center: vertices.average()),
                     lower: (vertices: lowerVertices, center: lowerVertices.average()))
        
        guard cut else {
            
            let edgeVertices = side == .left ? [faces.lower.vertices[2],
                                                faces.lower.vertices[1],
                                                faces.upper.vertices[2],
                                                faces.upper.vertices[1]] :
                                                [faces.upper.vertices[0],
                                                 faces.upper.vertices[3],
                                                 faces.lower.vertices[0],
                                                 faces.lower.vertices[3]]
            
            guard let uf0 = polygon(vectors: [faces.upper.vertices[0], faces.upper.vertices[1], faces.upper.vertices[2]]),
                  let uf1 = polygon(vectors: [faces.upper.vertices[0], faces.upper.vertices[2], faces.upper.vertices[3]]),
                  let lf0 = polygon(vectors: [faces.lower.vertices[0], faces.lower.vertices[1], faces.lower.vertices[2]]),
                  let lf1 = polygon(vectors: [faces.lower.vertices[0], faces.lower.vertices[2], faces.lower.vertices[3]]),
                  let ef0 = polygon(vectors: [edgeVertices[0], edgeVertices[1], edgeVertices[2]]),
                  let ef1 = polygon(vectors: [edgeVertices[0], edgeVertices[2], edgeVertices[3]]) else { return [] }
            
            return [uf0, uf1, lf0, lf1, ef0, ef1]
        }
        
        let v0 = faces.upper.vertices.average()
        let v1 = faces.upper.vertices[1].lerp(faces.upper.vertices[2], 0.5)
        let v2 = faces.upper.vertices[0].lerp(faces.upper.vertices[3], 0.5)
        
        let v3 = v0 - (normal * thickness)
        let v4 = v1 - (normal * thickness)
        let v5 = v2 - (normal * thickness)
        
        let topFaces = face(vertices: [faces.upper.vertices[0], faces.upper.vertices[1], v1, v2], side: side, cut: false)
        switch side {
            
        case .left:
            
            let bottomFaces = face(vertices: [v2, v0, faces.upper.vertices[2], faces.upper.vertices[3]], side: side, cut: false)
            
            guard let ef0 = polygon(vectors: [v0, v1, v4]),
                  let ef1 = polygon(vectors: [v0, v4, v3]) else { return topFaces + bottomFaces }
            
            return topFaces + bottomFaces + [ef0, ef1]
            
        case .right:
            
            let bottomFaces = face(vertices: [v0, v1, faces.upper.vertices[2], faces.upper.vertices[3]], side: side, cut: false)
            
            guard let ef0 = polygon(vectors: [v2, v0, v3]),
                  let ef1 = polygon(vectors: [v2, v3, v5]) else { return topFaces + bottomFaces }
            
            return topFaces + bottomFaces + [ef0, ef1]
        }
    }
}
