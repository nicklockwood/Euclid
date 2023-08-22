//
//  Mesh+OBJ.swift
//  Euclid
//
//  Created by Nick Lockwood on 21/08/2023.
//  Copyright © 2023 Nick Lockwood. All rights reserved.
//

import Foundation

public extension Mesh {
    /// Return Wavefront OBJ string data for the mesh.
    func objString() -> String {
        var vertices = [Vector](), indicesByVertex = [Vector: Int]()
        var texcoords = [Vector](), indicesByTexcoord = [Vector: Int]()
        var normals = [Vector](), indicesByNormal = [Vector: Int]()
        let hasTexcoords = self.hasTexcoords, hasVertexNormals = self.hasVertexNormals

        let indices = polygons.tessellate().map { polygon -> [(Int, Int, Int)] in
            polygon.vertices.map { vertex -> (Int, Int, Int) in
                let vertexIndex = indicesByVertex[vertex.position] ?? {
                    let index = indicesByVertex.count + 1
                    indicesByVertex[vertex.position] = index
                    vertices.append(vertex.position)
                    return index
                }()
                let texcoordIndex = hasTexcoords ? indicesByTexcoord[vertex.texcoord] ?? {
                    let index = indicesByTexcoord.count + 1
                    indicesByTexcoord[vertex.texcoord] = index
                    texcoords.append(vertex.texcoord)
                    return index
                }() : 0
                let normalIndex = hasVertexNormals ? indicesByNormal[vertex.normal] ?? {
                    let index = indicesByNormal.count + 1
                    indicesByNormal[vertex.normal] = index
                    normals.append(vertex.normal)
                    return index
                }() : 0
                return (vertexIndex, texcoordIndex, normalIndex)
            }
        }

        func vertexString(_ vertex: (Int, Int, Int)) -> String {
            if hasTexcoords {
                if hasVertexNormals {
                    return "\(vertex.0)/\(vertex.1)/\(vertex.2)"
                }
                return "\(vertex.0)/\(vertex.1)"
            } else if hasVertexNormals {
                return "\(vertex.0)//\(vertex.2)"
            }
            return "\(vertex.0)"
        }

        func textcoordString(_ vector: Vector) -> String {
            "vt \(vector.x.objString) \(vector.y.objString)\(vector.z == 0 ? "" : " \(vector.z.objString)")"
        }

        return """
        # Vertices
        \(vertices.map { "v \($0.objString)" }.joined(separator: "\n"))
        \(hasTexcoords ? """

        # Texcoords
        \(texcoords.map(textcoordString).joined(separator: "\n"))
        """ : "")
        \(hasVertexNormals ? """

        # Normals
        \(normals.map { "vn \($0.objString)" }.joined(separator: "\n"))
        """ : "")

        # Faces
        \(indices.map { "f \($0.map(vertexString).joined(separator: " "))" }.joined(separator: "\n"))
        """
    }
}

private extension Vector {
    var objString: String {
        "\(x.objString) \(y.objString) \(z.objString)"
    }
}

private extension Double {
    var objString: String {
        let result = String(format: "%g", self)
        return result == "-0" ? "0" : result
    }
}
