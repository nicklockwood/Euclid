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
        var vertices = [Vertex](), indicesByVertex = [Vertex: Int]()
        var texcoords = [Vector](), indicesByTexcoord = [Vector: Int]()
        var normals = [Vector](), indicesByNormal = [Vector: Int]()
        let hasTexcoords = self.hasTexcoords, hasVertexNormals = self.hasVertexNormals
        let hasVertexColors = self.hasVertexColors

        let indices = polygons.tessellate().map { polygon -> [(Int, Int, Int)] in
            polygon.vertices.map { vertex -> (Int, Int, Int) in
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
                let vertex = Vertex(vertex.position, nil, nil, vertex.color)
                let vertexIndex = indicesByVertex[vertex] ?? {
                    let index = indicesByVertex.count + 1
                    indicesByVertex[vertex] = index
                    vertices.append(vertex)
                    return index
                }()
                return (vertexIndex, texcoordIndex, normalIndex)
            }
        }

        func vertexIndexString(_ vertex: (Int, Int, Int)) -> String {
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

        func vertexString(_ vertex: Vertex) -> String {
            "v \(vertex.position.objString)\(hasVertexColors ? " \(vertex.color.objString)" : "")"
        }

        func textcoordString(_ vector: Vector) -> String {
            "vt \(vector.x.objString) \(vector.y.objString)\(vector.z == 0 ? "" : " \(vector.z.objString)")"
        }

        let vertexStrings = vertices.map(vertexString)
        let texcoordStrings = hasTexcoords ? texcoords.map(textcoordString) : nil
        let normalStrings = hasVertexNormals ? normals.map { "vn \($0.objString)" } : nil
        let indexStrings = indices.map { "f \($0.map(vertexIndexString).joined(separator: " "))" }
        return [
            vertexStrings.joined(separator: "\n"),
            texcoordStrings?.joined(separator: "\n"),
            normalStrings?.joined(separator: "\n"),
            indexStrings.joined(separator: "\n"),
        ].compactMap { $0 }.joined(separator: "\n\n")
    }
}

private extension Color {
    var objString: String {
        "\(r.objString) \(g.objString) \(b.objString)"
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
