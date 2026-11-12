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
        // This overload cannot cancel, so the throwing implementation cannot fail.
        try! offString(isCancelled: { false })
    }

    /// Returns OFF text, throwing `CancellationError` when cancelled.
    func offString(isCancelled: CancellationHandler) throws -> String {
        try checkCancellation(isCancelled)
        var vertices = [Vector](), indicesByVertex = [Vector: Int]()
        let indices = try polygons.tessellate(isCancelled: isCancelled).map { polygon -> [Int] in
            try checkCancellation(isCancelled)
            return try polygon.vertices.map { vertex -> Int in
                try checkCancellation(isCancelled)
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

        let vertexStrings = try vertices.map {
            try checkCancellation(isCancelled)
            return $0.offString
        }
        let indexStrings = try indices.map {
            try checkCancellation(isCancelled)
            return "\($0.count) \($0.map(\.description).joined(separator: " "))"
        }
        try checkCancellation(isCancelled)
        return [
            "OFF",
            "\(vertices.count) \(indices.count) 0",
            vertexStrings.joined(separator: "\n"),
            indexStrings.joined(separator: "\n"),
        ].joined(separator: "\n")
    }
}

private extension Color {
    var offString: String {
        "\(red.offString) \(green.offString) \(blue.offString)"
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
    /// - Parameters:
    ///   - offString: OFF string data.
    ///   - options: The import options.
    init?(offString: String, options: ImportOptions = .init()) {
        try? self.init(offString: offString, options: options, isCancelled: { false })
    }

    /// Creates a mesh from OFF text, throwing `CancellationError` if the callback returns `true`.
    init?(
        offString: String, options: ImportOptions = .init(), isCancelled: CancellationHandler
    ) throws {
        try checkCancellation(isCancelled)
        var lines = ArraySlice(offString.components(separatedBy: .newlines))
        guard let counts = lines.readHeader() else {
            return nil
        }
        let vertices = try (0 ..< counts.vertices).compactMap { _ in
            try checkCancellation(isCancelled)
            return lines.readVertex()
        }
        var faces = [Polygon]()
        for _ in 0 ..< counts.faces {
            try checkCancellation(isCancelled)
            guard let face = lines.readFace(with: vertices) else {
                return nil
            }
            faces += face
        }
        var mesh = Mesh(faces)
        if options.repairWinding ?? true {
            mesh = mesh.withConsistentWinding(isCancelled: isCancelled)
        }
        try checkCancellation(isCancelled)
        self = mesh
    }
}

private extension ArraySlice<String> {
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
        guard let counts = readDoubles()?.compactMap(Int.init(exactly:)),
              counts.count >= 2, counts.allSatisfy({ $0 >= 0 })
        else {
            return nil
        }
        return (counts[0], counts[1])
    }

    mutating func readDoubles() -> [Double]? {
        skipBlankLinesAndComments()
        guard let line = popFirst() else { return nil }
        return line
            .components(separatedBy: .whitespaces)
            .compactMap { Double($0) }
    }

    mutating func readVertex() -> Vector? {
        readDoubles().flatMap(Vector.init(_:))
    }

    mutating func readFace(with vertices: [Vector]) -> [Polygon]? {
        guard let doubles = readDoubles(),
              let count = doubles.first.flatMap(Int.init(exactly:)),
              count >= 0, count < doubles.count,
              case let indices = doubles.dropFirst().prefix(count).compactMap(Int.init(exactly:)),
              indices.count == count,
              indices.allSatisfy({ vertices.indices.contains($0) })
        else {
            return nil
        }
        return .init(indices.map { Vertex(vertices[$0]) }, material: nil)
    }
}
