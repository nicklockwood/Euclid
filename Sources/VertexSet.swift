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
        if precision == 0 {
            if let match = storage[point]?.first(where: { $0 == vertex }) {
                return match
            }
            storage[point, default: []].append(vertex)
            return vertex
        }
        if let bucket = storage[point.hashValue(withPrecision: precision)] {
            // if exact match found, return it
            if let vertex = bucket.first(where: {
                $0.isApproximatelyEqual(to: vertex, absoluteTolerance: precision)
            }) {
                return vertex
            }
            // if position match found, merge it
            if let match = bucket.first(where: {
                $0.position.isApproximatelyEqual(to: point, absoluteTolerance: precision)
            }) {
                vertex.position = match.position
                if vertex.normal.isApproximatelyEqual(to: match.normal, absoluteTolerance: precision) {
                    vertex.normal = match.normal
                }
                if vertex.texcoord.isApproximatelyEqual(to: match.texcoord, absoluteTolerance: precision) {
                    vertex.texcoord = match.texcoord
                }
                if vertex.color.isApproximatelyEqual(to: match.color, absoluteTolerance: precision) {
                    vertex.color = match.color
                }
            }
        }
        // insert into hash
        point.forEachHashValue(withPrecision: precision) {
            storage[$0, default: []].append(vertex)
        }
        return vertex
    }
}

private extension Vector {
    func hashValue(withPrecision precision: Double) -> Vector {
        let precision = precision * 2
        return [round(x / precision), round(y / precision), round(z / precision)]
    }

    func forEachHashValue(withPrecision precision: Double, _ body: (Vector) -> Void) {
        let precision = precision * 2
        let xf = floor(x / precision)
        let xc = ceil(x / precision)
        let yf = floor(y / precision)
        let yc = ceil(y / precision)
        let zf = floor(z / precision)
        let zc = ceil(z / precision)
        body([xf, yf, zf])
        if zc != zf {
            body([xf, yf, zc])
        }
        if yc != yf {
            body([xf, yc, zf])
            if zc != zf {
                body([xf, yc, zc])
            }
        }
        if xc != xf {
            body([xc, yf, zf])
            if zc != zf {
                body([xc, yf, zc])
            }
            if yc != yf {
                body([xc, yc, zf])
                if zc != zf {
                    body([xc, yc, zc])
                }
            }
        }
    }
}
