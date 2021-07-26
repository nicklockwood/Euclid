//
//  Prop.swift
//
//  Created by Zack Brown on 25/07/2021.
//

import Euclid
import Foundation

public enum Curve {
        
    case `in`
    case out
    case inOut
}

protocol Prop {
    
    func build(position: Vector) -> [Polygon]
}

extension Prop {
    
    func polygon(vectors: [Vector]) -> Polygon? {
            
        let normal = vectors.normal()
        
        var vertices: [Vertex] = []
        
        for index in vectors.indices {
            
            vertices.append(Vertex(vectors[index], normal))
        }
        
        return Polygon(vertices)
    }
    
    func curve(start: Vector, end: Vector, control: Vector, interpolator: Double) -> Vector {
            
        let ab = start.lerp(control, interpolator)
        let bc = control.lerp(end, interpolator)
        
        return ab.lerp(bc, interpolator)
    }
    
    func plot(radians: Double, radius: Double) -> Vector {
        
        return Vector(sin(radians) * radius, 0, cos(radians) * radius)
    }
    
    func lerp(start: Double, end: Double, interpolator: Double) -> Double {
            
        return start + (abs(end - start) * interpolator)
    }
}

extension Prop {
    
    func ease(curve: Curve, value: Double) -> Double {
        
        switch curve {
            
        case .in: return value * value
        case .out: return 1.0 - ease(curve: .in, value: 1.0 - value)
        case .inOut: return lerp(start: ease(curve: .in, value: value), end: ease(curve: .out, value: value), interpolator: value)
        }
    }
}

extension Array where Element == Vector {
    
    func average() -> Vector {
        
        guard count > 0 else { return .zero }
        
        var x = 0.0
        var y = 0.0
        var z = 0.0
        
        for i in 0..<count {
            
            let vector = self[i]
            
            x += vector.x
            y += vector.y
            z += vector.z
        }
        
        return Vector(x / Double(count), y / Double(count), z / Double(count))
    }
    
    public func normal() -> Vector {
        
        switch count {
            
        case 0, 1: return Vector(0, 0, 1)
            
        case 2:
            
            let ab = self.last! - self.first!
            
            return ab.cross(Vector(0, 0, 1)).cross(ab)
            
        default:
            
            var v0 = self.first!
            var v1: Vector?
            
            var ab = v0 - self.last!
            
            var magnitude = 0.0
            
            for vector in self {
                
                let bc = vector - v0
                
                let normal = ab.cross(bc)
                
                let squaredMagnitude = normal.lengthSquared
                
                if squaredMagnitude > magnitude {
                    
                    magnitude = squaredMagnitude
                    
                    v1 = normal / squaredMagnitude.squareRoot()
                }
                
                v0 = vector
                ab = bc
            }
            
            return v1 ?? Vector(0, 0, 1)
        }
    }
}
