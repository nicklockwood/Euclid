//
//  BSP.swift
//  Euclid
//
//  Created by Nick Lockwood on 20/01/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

struct BSP {
    private let root: BSPNode?

    enum ClipRule {
        case greaterThan
        case greaterThanEqual
        case lessThan
        case lessThanEqual
    }

    init(_ mesh: Mesh) {
        self.root = BSPNode(mesh.polygons, isConvex: mesh.isConvex)
    }

    func clip(_ polygons: [Polygon], _ keeping: ClipRule) -> [Polygon] {
        var id = 0
        var polygons = polygons
        for (i, p) in polygons.enumerated() where p.id != 0 {
            polygons[i].id = 0
        }
        return root?.clip(polygons, keeping, &id) ?? polygons
    }
}

// See https://github.com/wangyi-fudan/wyhash/
private struct DeterministicRNG: RandomNumberGenerator {
    private var seed: UInt64 = 0

    mutating func next() -> UInt64 {
        seed &+= 0xA0761D6478BD642F
        let result = seed.multipliedFullWidth(by: seed ^ 0xE7037ED1A0B428DB)
        return result.high ^ result.low
    }
}

private class BSPNode {
    private var front: BSPNode?
    private var back: BSPNode?
    private var polygons = [Polygon]()
    private let plane: Plane

    public init?(_ polygons: [Polygon], isConvex: Bool) {
        guard !polygons.isEmpty else {
            return nil
        }

        // Randomly shuffle polygons to reduce average number of splits
        var rng = DeterministicRNG()
        var polygons = polygons.shuffled(using: &rng)

        guard isConvex else {
            self.plane = polygons[0].plane
            insert(polygons)
            return
        }

        // Sort polygons by plane
        let count = polygons.count
        for i in 0 ..< count - 2 {
            let p = polygons[i]
            let plane = p.plane
            var k = i + 1
            for j in k ..< count where k < j && polygons[j].plane.isEqual(to: plane) {
                polygons.swapAt(j, k)
                k += 1
            }
        }

        // Use fast bsp construction
        self.plane = polygons[0].plane
        var parent = self
        parent.polygons = [polygons[0]]
        for polygon in polygons.dropFirst() {
            if polygon.plane.isEqual(to: parent.plane) {
                parent.polygons.append(polygon)
                continue
            }
            let node = BSPNode(plane: polygon.plane)
            node.polygons = [polygon]
            parent.back = node
            parent = node
        }
    }

    private init(plane: Plane) {
        self.plane = plane
    }

    public func clip(
        _ polygons: [Polygon],
        _ keeping: BSP.ClipRule,
        _ id: inout Int
    ) -> [Polygon] {
        var total = [Polygon]()
        func addPolygons(_ polygons: [Polygon]) {
            for a in polygons {
                guard a.id != 0 else {
                    total.append(a)
                    continue
                }
                var a = a
                for i in total.indices.reversed() {
                    let b = total[i]
                    if a.id == b.id, let c = a.join(unchecked: b, ensureConvex: true) {
                        a = c
                        total.remove(at: i)
                    }
                }
                total.append(a)
            }
        }
        let keepFront = [.greaterThan, .greaterThanEqual].contains(keeping)
        var stack = [(node: self, polygons: polygons)]
        while let (node, polygons) = stack.popLast() {
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
                if let next = node.front {
                    stack.append((next, front))
                } else {
                    addPolygons(keepFront ? front : [])
                }
            }
            if !back.isEmpty {
                if let next = node.back {
                    stack.append((next, back))
                } else {
                    addPolygons(keepFront ? [] : back)
                }
            }
        }
        return total
    }

    private func insert(_ polygons: [Polygon]) {
        var stack = [(node: self, polygons: polygons)]
        while let (node, polygons) = stack.popLast() {
            var front = [Polygon](), back = [Polygon]()
            for polygon in polygons {
                switch polygon.compare(with: node.plane) {
                case .coplanar:
                    if node.plane.normal.dot(polygon.plane.normal) > 0 {
                        node.polygons.append(polygon)
                    } else {
                        back.append(polygon)
                    }
                case .front:
                    front.append(polygon)
                case .back:
                    back.append(polygon)
                case .spanning:
                    var id = 0
                    polygon.split(spanning: node.plane, &front, &back, &id)
                }
            }
            if let first = front.first {
                let next = node.front ?? BSPNode(plane: first.plane)
                node.front = next
                stack.append((next, front))
            }
            if let first = back.first {
                let next = node.back ?? BSPNode(plane: first.plane)
                node.back = next
                stack.append((next, back))
            }
        }
    }
}
