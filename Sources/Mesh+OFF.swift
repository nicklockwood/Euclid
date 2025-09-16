//
//  Mesh+OFF.swift
//  Euclid
//
//  Created by Nick Lockwood on 16/09/2025.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

import Foundation

public extension Mesh {
    /// Return Object File Format string data for the mesh.
    func offString() -> String {
        var vertices = [Vector](), indicesByVertex = [Vector: Int]()
        let indices = polygons.tessellate().map { polygon -> [Int] in
            polygon.vertices.map { vertex -> Int in
                let position = vertex.position
                if let index = indicesByVertex[position] {
                    return index
                }
                let index = indicesByVertex.count
                indicesByVertex[position] = index
                vertices.append(position)
                return index
            }
        }

        let vertexStrings = vertices.map(\.offString)
        let indexStrings = indices.map { "\($0.count) \($0.map(\.description).joined(separator: " "))" }
        return [
            "OFF",
            "\(vertices.count) \(indices.count) 0",
            vertexStrings.joined(separator: "\n"),
            indexStrings.joined(separator: "\n"),
        ].compactMap { $0 }.joined(separator: "\n")
    }
}

private extension Color {
    var offString: String {
        "\(r.offString) \(g.offString) \(b.offString)"
    }
}

private extension Vector {
    var offString: String {
        "\(x.offString) \(y.offString) \(z.offString)"
    }
}

private extension Double {
    var offString: String {
        let result = String(format: "%g", self)
        return result == "-0" ? "0" : result
    }
}
