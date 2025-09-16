//
//  BSP.swift
//  Euclid
//
//  Created by Nick Lockwood on 20/01/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/Euclid
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

struct BSP {
    private var nodes: [BSPNode]
    private(set) var isConvex: Bool
}

extension BSP {
    typealias CancellationHandler = () -> Bool

    enum ClipRule {
        case greaterThan
        case greaterThanEqual
        case lessThan
        case lessThanEqual
    }

    init(_ mesh: Mesh, _ isCancelled: CancellationHandler) {
        self = mesh.bsp(isCancelled: isCancelled)
    }

    init(unchecked polygons: [Polygon], isKnownConvex: Bool, _ isCancelled: CancellationHandler) {
        self.nodes = [BSPNode]()
        self.isConvex = isKnownConvex
        initialize(polygons, isCancelled)
    }

    func clip(
        _ polygons: [Polygon],
        _ keeping: ClipRule,
        _ isCancelled: CancellationHandler
    ) -> [Polygon] {
        batch(polygons, stride: 50) { polygons in
            var id = 0
            var out: [Polygon]?
            return clip(polygons.map { $0.withID(0) }, keeping, &out, &id, isCancelled)
        }
    }

    func clip(
        _ edges: [LineSegment],
        _ keeping: ClipRule,
        _ isCancelled: CancellationHandler
    ) -> [LineSegment] {
        batch(edges, stride: 50) { edges in
            var out: [LineSegment]?
            return clip(edges, keeping, &out, isCancelled)
        }
    }

    func clip(
        _ path: Path,
        _ keeping: ClipRule,
        _ isCancelled: CancellationHandler
    ) -> Path {
        var out: [Path]?
        return Path(subpaths: path.subpaths.flatMap {
            clip($0, keeping, &out, isCancelled)
        })
    }

    func split(
        _ polygons: [Polygon],
        _ left: ClipRule,
        _ right: ClipRule,
        _ isCancelled: CancellationHandler
    ) -> ([Polygon], [Polygon]) {
        var id = 0
        var rhs: [Polygon]? = []
        let lhs = clip(polygons.map { $0.withID(0) }, left, &rhs, &id, isCancelled)
        switch (left, right) {
        case (.lessThan, .greaterThan),
             (.greaterThan, .lessThan):
            var ignore: [Polygon]?
            return (lhs, clip(rhs!, right, &ignore, &id, isCancelled))
        default:
            return (lhs, rhs!)
        }
    }
}

extension BSP: PointComparable {
    func nearestPoint(to point: Vector) -> Vector {
        guard var node = nodes.first else {
            return point
        }
        var result = point
        var shortest = Double.infinity
        var visited: IndexSet = [0]
        while true {
            switch point.compare(with: node.plane) {
            case .coplanar, .spanning, .front:
                let nearest = node.polygons.nearestPoint(to: point)
                let distance = nearest.distance(from: point)
                if distance < shortest {
                    shortest = distance
                    result = nearest
                }
                if !visited.contains(node.front) {
                    node = nodes[node.front]
                } else if node.back != 0 {
                    visited.insert(node.back)
                    node = nodes[node.back]
                } else {
                    // Outside
                    return result
                }
            case .back:
                guard node.back > 0 else {
                    // Inside
                    return point
                }
                node = nodes[node.back]
            }
        }
        return result
    }

    func distance(from point: Vector) -> Double {
        nodes.isEmpty ? .infinity : (nearestPoint(to: point) - point).length
    }

    func intersects(_ point: Vector) -> Bool {
        guard var node = nodes.first else {
            return false
        }
        while true {
            switch point.compare(with: node.plane) {
            case .coplanar, .spanning:
                if node.polygons.contains(where: { $0.intersects(point) }) {
                    return true
                }
                fallthrough
            case .front:
                guard node.front > 0 else {
                    return false
                }
                node = nodes[node.front]
            case .back:
                guard node.back > 0 else {
                    return true
                }
                node = nodes[node.back]
            }
        }
    }
}

private extension BSP {
    struct BSPNode {
        var front: Int = 0
        var back: Int = 0
        var polygons = [Polygon]()
        var plane: Plane

        init(plane: Plane) {
            self.plane = plane
        }

        init(polygon: Polygon) {
            self.polygons = [polygon]
            self.plane = polygon.plane
        }
    }

    /// See https://github.com/wangyi-fudan/wyhash/
    struct DeterministicRNG: RandomNumberGenerator {
        private var seed: UInt64 = 0

        mutating func next() -> UInt64 {
            seed &+= 0xA0761D6478BD642F
            let result = seed.multipliedFullWidth(by: seed ^ 0xE7037ED1A0B428DB)
            return result.high ^ result.low
        }
    }

    mutating func initialize(_ polygons: [Polygon], _ isCancelled: CancellationHandler) {
        guard !polygons.isEmpty else {
            isConvex = true
            return
        }

        var rng = DeterministicRNG()

        guard isConvex else {
            // Randomly shuffle polygons to reduce average number of splits
            let polygons = polygons.shuffled(using: &rng)
            nodes.reserveCapacity(polygons.count)
            nodes.append(BSPNode(plane: polygons[0].plane))
            insert(polygons, isCancelled)
            return
        }

        // Create nodes
        nodes = polygons
            .groupedByPlane()
            .shuffled(using: &rng)
            .enumerated()
            .map { i, group in
                var node = BSPNode(plane: group.plane)
                node.polygons = group.polygons
                node.back = i + 1
                return node
            }

        // Fixup last node
        nodes[nodes.count - 1].back = 0
    }

    mutating func insert(_ polygons: [Polygon], _ isCancelled: CancellationHandler) {
        var isActuallyConvex = true
        var stack = [(node: 0, polygons: polygons)]
        while let (node, polygons) = stack.popLast(), !isCancelled() {
            var front = [Polygon](), back = [Polygon]()
            for polygon in polygons {
                let plane = nodes[node].plane
                switch polygon.compare(with: plane) {
                case .coplanar:
                    if plane.normal.dot(polygon.plane.normal) > 0 {
                        nodes[node].polygons.append(polygon)
                    } else {
                        back.append(polygon)
                    }
                case .front:
                    front.append(polygon)
                    isActuallyConvex = false
                case .back:
                    back.append(polygon)
                case .spanning:
                    var id = 0
                    polygon.split(spanning: plane, &front, &back, &id)
                    isActuallyConvex = false
                }
            }
            if let first = front.first {
                var next = nodes[node].front
                if next == 0 {
                    next = nodes.count
                    nodes[node].front = next
                    nodes.append(BSPNode(plane: first.plane))
                }
                stack.append((next, front))
            }
            if let first = back.first {
                var next = nodes[node].back
                if next == 0 {
                    next = nodes.count
                    nodes[node].back = next
                    nodes.append(BSPNode(plane: first.plane))
                }
                stack.append((next, back))
            }
        }
        if isActuallyConvex {
            // Check that last node wasn't coincidentally the only backface
            isActuallyConvex = polygons.allSatisfy { $0.compare(with: nodes.last!.plane) != .front }
        }
        if isActuallyConvex {
            switch nodes.count {
            case 2:
                // Shouldn't be possible to get here unless mesh is planar
                assert(nodes[0].plane.isApproximatelyEqual(to: nodes[1].plane.inverted()))
                fallthrough
            case 1:
                // Check that boundary around face polygons is convex
                // (Individual polygons in the face may still be non-convex)
                isActuallyConvex = nodes.allSatisfy(\.polygons.coplanarPolygonsAreConvex)
            default:
                break
            }
        }
        isConvex = isActuallyConvex
    }

    func clip(
        _ polygons: [Polygon],
        _ keeping: ClipRule,
        _ out: inout [Polygon]?,
        _ id: inout Int,
        _ isCancelled: CancellationHandler
    ) -> [Polygon] {
        guard !nodes.isEmpty else {
            return polygons
        }
        var total = [Polygon]()
        var rejects = [Polygon]()
        func addPolygons(_ polygons: [Polygon], to total: inout [Polygon]) {
            for a in polygons {
                guard a.id != 0 else {
                    total.append(a)
                    continue
                }
                var a = a
                for (i, b) in total.enumerated().reversed() {
                    if a.id == b.id, let c = a.merge(unchecked: b, ensureConvex: false) {
                        a = c
                        total.remove(at: i)
                    }
                }
                total.append(a)
            }
        }
        let keepFront = [.greaterThan, .greaterThanEqual].contains(keeping)
        var stack = [(node: nodes[0], polygons: polygons)]
        while let (node, polygons) = stack.popLast(), !isCancelled() {
            var coplanar = [Polygon](), front = [Polygon](), back = [Polygon]()
            for polygon in polygons {
                polygon.split(along: node.plane, &coplanar, &front, &back, &id)
            }
            for polygon in coplanar {
                switch keeping {
                case .greaterThan, .lessThanEqual:
                    polygon.clip(to: node.polygons, &back, &front, &id)
                case .greaterThanEqual, .lessThan:
                    if node.plane.normal.dot(polygon.plane.normal) > 0 {
                        front.append(polygon)
                    } else {
                        polygon.clip(to: node.polygons, &back, &front, &id)
                    }
                }
            }
            if !front.isEmpty {
                if node.front > 0 {
                    stack.append((nodes[node.front], front))
                } else if keepFront {
                    addPolygons(front, to: &total)
                } else if out != nil {
                    addPolygons(front, to: &rejects)
                }
            }
            if !back.isEmpty {
                if node.back > 0 {
                    stack.append((nodes[node.back], back))
                } else if !keepFront {
                    addPolygons(back, to: &total)
                } else if out != nil {
                    addPolygons(back, to: &rejects)
                }
            }
        }
        out = rejects
        return total
    }

    func clip(
        _ edges: [LineSegment],
        _ keeping: ClipRule,
        _ out: inout [LineSegment]?,
        _ isCancelled: CancellationHandler
    ) -> [LineSegment] {
        guard !nodes.isEmpty else {
            return edges
        }
        var total = [LineSegment]()
        var rejects = [LineSegment]()
        func addEdges(_ edges: [LineSegment], to total: inout [LineSegment]) {
            // TODO: we only need to try to rejoin edges which were actually split
            outer: for var a in edges {
                for (i, b) in total.enumerated().reversed() {
                    if b.end == a.start {
                        // TODO: is this check needed and/or is there a cheaper way?
                        if a.direction.isApproximatelyEqual(to: b.direction) {
                            a = LineSegment(unchecked: b.start, a.end)
                            total.remove(at: i)
                        }
                    } else if b.start == a.end {
                        // TODO: is this check needed and/or is there a cheaper way?
                        if a.direction.isApproximatelyEqual(to: b.direction) {
                            a = LineSegment(unchecked: a.start, b.end)
                            total.remove(at: i)
                        }
                    }
                }
                total.append(a)
            }
        }
        let keepFront = [.greaterThan, .greaterThanEqual].contains(keeping)
        var stack = [(node: nodes[0], edges: edges)]
        while let (node, edges) = stack.popLast(), !isCancelled() {
            var coplanar = [LineSegment](), front = [LineSegment](), back = [LineSegment]()
            for edge in edges {
                edge.split(along: node.plane, &coplanar, &front, &back)
            }
            for edge in coplanar {
                edge.clip(to: node.polygons, &back, &front)
            }
            if !front.isEmpty {
                if node.front > 0 {
                    stack.append((nodes[node.front], front))
                } else if keepFront {
                    addEdges(front, to: &total)
                } else if out != nil {
                    addEdges(front, to: &rejects)
                }
            }
            if !back.isEmpty {
                if node.back > 0 {
                    stack.append((nodes[node.back], back))
                } else if !keepFront {
                    addEdges(back, to: &total)
                } else if out != nil {
                    addEdges(back, to: &rejects)
                }
            }
        }
        out = rejects
        return total
    }

    func clip(
        _ path: Path,
        _ keeping: ClipRule,
        _ out: inout [Path]?,
        _ isCancelled: CancellationHandler
    ) -> [Path] {
        assert(path.subpaths.count == 1)
        guard !nodes.isEmpty else {
            return [path]
        }
        var total = [Path]()
        let keepFront = [.greaterThan, .greaterThanEqual].contains(keeping)
        var stack = [(node: nodes[0], paths: [path])]
        while let (node, paths) = stack.popLast(), !isCancelled() {
            var coplanar: [Path]! = [], front = [Path](), back: [Path]! = []
            for path in paths {
                path.split(along: node.plane, &coplanar, &front, &back)
            }
            for path in coplanar {
                path.clip(to: node.polygons, &back, &front)
            }
            if !front.isEmpty {
                if node.front > 0 {
                    stack.append((nodes[node.front], front))
                } else if keepFront {
                    total.append(contentsOf: front)
                } else {
                    out?.append(contentsOf: front)
                }
            }
            if !back.isEmpty {
                if node.back > 0 {
                    stack.append((nodes[node.back], back))
                } else if !keepFront {
                    total.append(contentsOf: back)
                } else {
                    out?.append(contentsOf: front)
                }
            }
        }
        return total
    }
}
