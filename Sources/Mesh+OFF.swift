//
//  Mesh+OFF.swift
//  Euclid
//
//  Created by Nick Lockwood on 16/09/2025.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

import Foundation

// MARK: Export

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

// MARK: Import

public extension Mesh {
    /// Create a mesh from an Object File Format string.
    /// - Parameter offString: OFF string data.
    init?(offString: String) {
        var lines = ArraySlice(offString.components(separatedBy: .newlines))
        guard let counts = lines.readHeader() else {
            return nil
        }
        let vertices = (0 ..< counts.vertices).compactMap { _ in
            lines.readVertex()
        }
        let faces = (0 ..< counts.faces).compactMap { _ in
            lines.readFace(with: vertices)
        }
        self = Mesh(faces)
    }
}

private extension ArraySlice where Element == String {
    mutating func skipBlankLinesAndComments() {
        while let line = first?.trimmingCharacters(in: .whitespaces),
              line.isEmpty || line.hasPrefix("#")
        {
            removeFirst()
        }
    }

    mutating func readHeader() -> (vertices: Int, faces: Int)? {
        skipBlankLinesAndComments()
        if let line = first,
           line.trimmingCharacters(in: .whitespaces).lowercased() == "off"
        {
            removeFirst()
        }
        guard let counts = readInts(), counts.count == 3,
              counts[0] >= 0, counts[1] >= 0
        else {
            return nil
        }
        return (counts[0], counts[1])
    }

    mutating func readInts() -> [Int]? {
        skipBlankLinesAndComments()
        guard let line = popFirst() else { return nil }
        return line
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .compactMap { Int($0) }
    }

    mutating func readDoubles() -> [Double]? {
        skipBlankLinesAndComments()
        guard let line = popFirst() else { return nil }
        return line
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .compactMap { Double($0) }
    }

    mutating func readVertex() -> Vector? {
        readDoubles().flatMap(Vector.init(_:))
    }

    mutating func readFace(with vertices: [Vector]) -> Polygon? {
        guard let ints = readInts(),
              let count = ints.first,
              count == ints.count - 1,
              ints[1...].allSatisfy({ $0 < vertices.count })
        else {
            return nil
        }
        return Polygon(ints[1...].map { vertices[$0] })
    }
}
