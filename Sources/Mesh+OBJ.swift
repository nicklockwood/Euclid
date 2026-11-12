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
        // This overload cannot cancel, so the throwing implementation cannot fail.
        try! objString(isCancelled: { false })
    }

    /// Returns OBJ text, throwing `CancellationError` when cancelled.
    func objString(isCancelled: CancellationHandler) throws -> String {
        var cancellationCountdown = cancellationCheckInterval
        try checkCancellation(isCancelled)
        var vertices = [Vertex](), indicesByVertex = [Vertex: Int]()
        var texcoords = [Vector](), indicesByTexcoord = [Vector: Int]()
        var normals = [Vector](), indicesByNormal = [Vector: Int]()
        let hasTexcoords = hasTexcoords, hasVertexNormals = hasVertexNormals
        let hasVertexColors = hasVertexColors

        let indices = try polygons.tessellate(isCancelled: isCancelled).map { polygon -> [OBJVertex] in
            try checkCancellation(isCancelled, countdown: &cancellationCountdown)
            return try polygon.vertices.map { vertex -> OBJVertex in
                try checkCancellation(isCancelled, countdown: &cancellationCountdown)
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

        let vertexStrings = try vertices.map {
            try checkCancellation(isCancelled, countdown: &cancellationCountdown)
            return vertexString($0)
        }
        let texcoordStrings = try hasTexcoords ? texcoords.map {
            try checkCancellation(isCancelled, countdown: &cancellationCountdown)
            return textcoordString($0)
        } : nil
        let normalStrings = try hasVertexNormals ? normals.map {
            try checkCancellation(isCancelled, countdown: &cancellationCountdown)
            return "vn \($0.objString)"
        } : nil
        let indexStrings = try indices.map {
            try checkCancellation(isCancelled, countdown: &cancellationCountdown)
            return "f \($0.map(vertexIndexString).joined(separator: " "))"
        }
        try checkCancellation(isCancelled)
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
        "\(red.objString) \(green.objString) \(blue.objString)"
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
    /// - Parameters:
    ///   - objString: OBJ string data.
    ///   - options: The import options.
    init?(objString: String, options: ImportOptions = .init()) {
        try? self.init(objString: objString, options: options, isCancelled: { false })
    }

    /// Creates a mesh from OBJ text, throwing `CancellationError` if the callback returns `true`.
    init?(
        objString: String, options: ImportOptions = .init(), isCancelled: CancellationHandler
    ) throws {
        var cancellationCountdown = cancellationCheckInterval
        try checkCancellation(isCancelled)
        var vertices = [Vertex]()
        var normals = [Vector]()
        var texcoords = [Vector]()
        var faces = [[OBJVertex]]()

        var lines = ArraySlice(objString.components(separatedBy: .newlines))
        while let command = try lines.readCommand(isCancelled: isCancelled) {
            try checkCancellation(isCancelled, countdown: &cancellationCountdown)
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

        var mesh = try Mesh(faces.flatMap {
            try checkCancellation(isCancelled, countdown: &cancellationCountdown)
            return [Polygon]($0.compactMap(lookup), material: nil)
        })
        if options.repairWinding ?? false {
            mesh = mesh.withConsistentWinding(isCancelled: isCancelled)
        }
        try checkCancellation(isCancelled)
        self = mesh
    }
}

private enum OBJCommand {
    case vertex(Vertex)
    case normal(Vector)
    case texcoord(Vector)
    case face([OBJVertex])
}

private extension ArraySlice<String> {
    mutating func skipBlankLinesAndComments(isCancelled: CancellationHandler) throws {
        var cancellationCountdown = cancellationCheckInterval
        while let line = first?.trimmingCharacters(in: .whitespaces),
              line.isEmpty || line.hasPrefix("#")
        {
            try checkCancellation(isCancelled, countdown: &cancellationCountdown)
            removeFirst()
        }
    }

    mutating func readCommand(isCancelled: CancellationHandler) throws -> OBJCommand? {
        var cancellationCountdown = cancellationCheckInterval
        while true {
            try checkCancellation(isCancelled, countdown: &cancellationCountdown)
            try skipBlankLinesAndComments(isCancelled: isCancelled)
            guard let line = popFirst() else { return nil }

            var parts = ArraySlice(line
                .components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
            )

            func readVector() -> Vector {
                .init(parts.compactMap(Double.init(_:)))
            }

            func readVertex() -> Vertex {
                let doubles = parts.compactMap(Double.init(_:))
                let vector = Vector(doubles)
                // Four components are the standard x/y/z/w vertex, not a grayscale color.
                let color = (6 ... 7).contains(doubles.count) ? Color(doubles.dropFirst(3)) : nil
                return .init(vector, color: color)
            }

            func readIndex() -> OBJVertex? {
                guard let part = parts.popFirst() else {
                    return nil
                }
                let indexParts = part.components(separatedBy: "/")
                func index(at position: Int) -> Int {
                    indexParts.indices.contains(position) ? Int(indexParts[position]) ?? 0 : 0
                }
                return (index(at: 0), index(at: 1), index(at: 2))
            }

            func readFace() throws -> [OBJVertex] {
                var indices = [OBJVertex]()
                while let index = readIndex() {
                    try checkCancellation(isCancelled, countdown: &cancellationCountdown)
                    indices.append(index)
                }
                return indices
            }

            switch parts.popFirst()?.lowercased() {
            case "v": return .vertex(readVertex())
            case "vn": return .normal(readVector())
            case "vt": return .texcoord(readVector())
            case "f": return try .face(readFace())
            default: continue
            }
        }
    }
}
