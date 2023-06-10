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
        self.nodes = [BSPNode]()
        self.isConvex = mesh.isKnownConvex
        initialize(mesh.polygons, isCancelled)
    }

    func clip(
        _ polygons: [Polygon],
        _ keeping: ClipRule,
        _ isCancelled: CancellationHandler
    ) -> [Polygon] {
        batch(polygons, stride: 50) { polygons in
            var id = 0
            var out: [Polygon]?
            return clip(polygons.map { $0.with(id: 0) }, keeping, &out, &id, isCancelled)
        }
    }

    func split(
        _ polygons: [Polygon],
        _ left: ClipRule,
        _ right: ClipRule,
        _ isCancelled: CancellationHandler
    ) -> ([Polygon], [Polygon]) {
        var id = 0
        var rhs: [Polygon]? = []
        let lhs = clip(polygons.map { $0.with(id: 0) }, left, &rhs, &id, isCancelled)
        switch (left, right) {
        case (.lessThan, .greaterThan),
             (.greaterThan, .lessThan):
            var ignore: [Polygon]?
            return (lhs, clip(rhs!, right, &ignore, &id, isCancelled))
        default:
            return (lhs, rhs!)
        }
    }

    func containsPoint(_ point: Vector) -> Bool {
        guard var node = nodes.first else {
            return false
        }
        while true {
            switch point.compare(with: node.plane) {
            case .coplanar, .spanning:
                if node.polygons.contains(where: { $0.containsPoint(point) }) {
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

    // See https://github.com/wangyi-fudan/wyhash/
    struct DeterministicRNG: RandomNumberGenerator {
        private var seed: UInt64 = 0

        mutating func next() -> UInt64 {
            seed &+= 0xA0761D6478BD642F
            let result = seed.multipliedFullWidth(by: seed ^ 0xE7037ED1A0B428DB)
            return result.high ^ result.low
        }
    }

    mutating func initialize(_ polygons: [Polygon], _ isCancelled: CancellationHandler) {
        var rng = DeterministicRNG()

        guard isConvex else {
            guard !polygons.isEmpty else {
                return
            }
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
        isConvex = isActuallyConvex
    }

    func clip(
        _ polygons: [Polygon],
        _ keeping: BSP.ClipRule,
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
                for i in total.indices.reversed() {
                    let b = total[i]
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
}
