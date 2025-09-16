//
//  Mesh+OBJ.swift
//  Euclid
//
//  Created by Nick Lockwood on 21/08/2023.
//  Copyright © 2023 Nick Lockwood. All rights reserved.
//

import Foundation

// MARK: Export

public extension Mesh {
    /// Return Wavefront OBJ string data for the mesh.
    func objString() -> String {
        var vertices = [Vertex](), indicesByVertex = [Vertex: Int]()
        var texcoords = [Vector](), indicesByTexcoord = [Vector: Int]()
        var normals = [Vector](), indicesByNormal = [Vector: Int]()
        let hasTexcoords = hasTexcoords, hasVertexNormals = hasVertexNormals
        let hasVertexColors = hasVertexColors

        let indices = polygons.tessellate().map { polygon -> [OBJVertex] in
            polygon.vertices.map { vertex -> OBJVertex in
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
                let vertex = Vertex(vertex.position, color: vertex.color)
                let vertexIndex = indicesByVertex[vertex] ?? {
                    let index = indicesByVertex.count + 1
                    indicesByVertex[vertex] = index
                    vertices.append(vertex)
                    return index
                }()
                return (vertexIndex, texcoordIndex, normalIndex)
            }
        }

        func vertexIndexString(_ vertex: OBJVertex) -> String {
            if hasTexcoords {
                if hasVertexNormals {
                    return "\(vertex.0)/\(vertex.texcoord)/\(vertex.normal)"
                }
                return "\(vertex.vertex)/\(vertex.texcoord)"
            } else if hasVertexNormals {
                return "\(vertex.vertex)//\(vertex.normal)"
            }
            return "\(vertex.vertex)"
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

private typealias OBJVertex = (
    vertex: Int,
    texcoord: Int,
    normal: Int
)

// MARK: Import

public extension Mesh {
    /// Create a mesh from a Wavefront OBJ string.
    /// - Parameter objString: OBJ string data.
    init?(objString: String) {
        var vertices = [Vertex]()
        var normals = [Vector]()
        var texcoords = [Vector]()
        var faces = [[OBJVertex]]()

        var lines = ArraySlice(objString.components(separatedBy: .newlines))
        while let command = lines.readCommand() {
            switch command {
            case let .vertex(vertex):
                vertices.append(vertex)
            case let .normal(normal):
                normals.append(normal)
            case let .texcoord(texcoord):
                texcoords.append(texcoord)
            case let .face(indices):
                faces.append(indices)
            }
        }

        func lookup<T>(_ index: Int, in vectors: [T]) -> T? {
            index > 0 && index <= vectors.count ? vectors[index - 1] : nil
        }

        func lookup(_ index: OBJVertex) -> Vertex? {
            guard var vertex = lookup(index.vertex, in: vertices) else {
                return nil
            }
            lookup(index.texcoord, in: texcoords).map { vertex.texcoord = $0 }
            lookup(index.normal, in: normals).map { vertex.normal = $0 }
            return vertex
        }

        self = Mesh(faces.flatMap {
            [Polygon]($0.compactMap(lookup), material: nil)
        })
    }
}

private enum OBJCommand {
    case vertex(Vertex)
    case normal(Vector)
    case texcoord(Vector)
    case face([OBJVertex])
}

private extension ArraySlice where Element == String {
    mutating func skipBlankLinesAndComments() {
        while let line = first?.trimmingCharacters(in: .whitespaces),
              line.isEmpty || line.hasPrefix("#")
        {
            removeFirst()
        }
    }

    mutating func readCommand() -> OBJCommand? {
        skipBlankLinesAndComments()
        guard let line = popFirst() else { return nil }

        var parts = ArraySlice(line
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        )

        func readVector() -> Vector {
            .init(parts[1...].compactMap(Double.init(_:)))
        }

        func readVertex() -> Vertex {
            let doubles = parts[1...].compactMap(Double.init(_:))
            let vector = Vector(doubles)
            let color = doubles.count > 3 ? Color(doubles.dropFirst(3)) : nil
            return .init(vector, color: color)
        }

        func readIndex() -> OBJVertex? {
            guard let part = parts.popFirst() else {
                return nil
            }
            let indexParts = part.components(separatedBy: "/").compactMap(Int.init(_:))
            switch indexParts.count {
            case 0: return (0, 0, 0)
            case 1: return (indexParts[0], 0, 0)
            case 2: return (indexParts[0], indexParts[1], 0)
            default: return (indexParts[0], indexParts[1], indexParts[2])
            }
        }

        func readFace() -> [OBJVertex] {
            var indices = [OBJVertex]()
            while let index = readIndex() {
                indices.append(index)
            }
            return indices
        }

        switch parts.popFirst()?.lowercased() {
        case "v": return .vertex(readVertex())
        case "vn": return .normal(readVector())
        case "vt": return .texcoord(readVector())
        case "f": return .face(readFace())
        default: return readCommand()
        }
    }
}
