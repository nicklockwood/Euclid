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
        var vertex = vertex
        let point = vertex.position
        if let bucket = storage[point.hashValue(withPrecision: precision)] {
            // if exact match found, return it
            if let vertex = bucket.first(where: {
                $0.isEqual(to: vertex, withPrecision: precision)
            }) {
                return vertex
            }
            // if position match found, merge it
            if let match = bucket.first(where: {
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
        }
        // insert into hash
        for hashValue in point.hashValues(withPrecision: precision) {
            storage[hashValue, default: []].append(vertex)
        }
        return vertex
    }
}

private extension Vector {
    func hashValue(withPrecision precision: Double) -> Vector {
        let precision = precision * 2
        return [round(x / precision), round(y / precision), round(z / precision)]
    }

    func hashValues(withPrecision precision: Double) -> Set<Vector> {
        let precision = precision * 2
        let xf = floor(x / precision)
        let xc = ceil(x / precision)
        let yf = floor(y / precision)
        let yc = ceil(y / precision)
        let zf = floor(z / precision)
        let zc = ceil(z / precision)
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
