//
//  VertexSet.swift
//  Euclid
//
//  Created by Nick Lockwood on 26/08/2025.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

import Foundation

struct VertexSet {
    private var storage = [Vector: [Vertex]]()

    /// The maximum distance between vertices.
    let precision: Double

    /// Creates a vertex set with specified precision.
    /// - Parameter precision: The maximum distance between vertices.
    init(precision: Double) {
        self.precision = precision
    }

    /// If vertex is unique, inserts it and returns the same value
    /// otherwise, returns nearest match
    /// - Parameter point: The point to insert.
    mutating func insert(_ vertex: Vertex) -> Vertex {
        let point = vertex.position
        let hash = Vector(
            round(point.x / precision) * precision,
            round(point.y / precision) * precision,
            round(point.z / precision) * precision
        )
        // if exact match found, return it
        if let vertex = storage[hash]?.first(where: {
            $0.isEqual(to: vertex, withPrecision: precision)
        }) {
            return vertex
        }
        // if position match found, merge it
        var vertex = vertex
        if let match = storage[hash]?.first(where: {
            $0.position.isEqual(to: point, withPrecision: precision)
        }) {
            vertex.position = match.position
            if vertex.normal.isEqual(to: match.normal, withPrecision: precision) {
                vertex.normal = match.normal
            }
            if vertex.texcoord.isEqual(to: match.texcoord, withPrecision: precision) {
                vertex.texcoord = match.texcoord
            }
            if vertex.color.isEqual(to: match.color, withPrecision: precision) {
                vertex.color = match.color
            }
        }
        // insert into hash
        for hashValue in point.hashValues(withPrecision: precision) {
            storage[hashValue, default: []].append(vertex)
        }
        return vertex
    }
}

private extension Vector {
    func hashValues(withPrecision precision: Double) -> Set<Vector> {
        let xf = floor(x / precision) * precision
        let xc = ceil(x / precision) * precision
        let yf = floor(y / precision) * precision
        let yc = ceil(y / precision) * precision
        let zf = floor(z / precision) * precision
        let zc = ceil(z / precision) * precision
        return [
            [xf, yf, zf],
            [xf, yf, zc],
            [xf, yc, zf],
            [xf, yc, zc],
            [xc, yf, zf],
            [xc, yf, zc],
            [xc, yc, zf],
            [xc, yc, zc],
        ]
    }
}
