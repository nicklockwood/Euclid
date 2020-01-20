//
//  BSP.swift
//  Euclid
//
//  Created by Nick Lockwood on 20/01/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

class BSPNode {
    private weak var parent: BSPNode?
    private var front: BSPNode?
    private var back: BSPNode?
    private var polygons = [Polygon]()
    private var plane: Plane?

    init(_ polygons: [Polygon]) {
        plane = polygons.first?.plane
        insert(polygons)
    }

    private init(plane: Plane, parent: BSPNode?) {
        self.parent = parent
        self.plane = plane
    }

    private func enumerate(_ block: (BSPNode) -> Void) {
        var node = self
        var visited: BSPNode?
        block(node)
        while true {
            if visited == nil, let front = node.front {
                block(front)
                node = front
            } else if let back = node.back, back !== visited {
                visited = nil
                block(back)
                node = back
            } else if node !== self, let parent = node.parent {
                visited = node
                node = parent
            } else {
                return
            }
        }
    }

    enum ClipRule {
        case greaterThan
        case greaterThanEqual
        case lessThan
        case lessThanEqual
    }

    func clip(_ polygons: [Polygon], _ keeping: ClipRule) -> [Polygon] {
        var id = 0
        var polygons = polygons
        for (i, p) in polygons.enumerated() where p.id != 0 {
            polygons[i].id = 0
        }
        return clip(polygons, keeping, &id)
    }

    private func clip(
        _ polygons: [Polygon],
        _ keeping: ClipRule,
        _ id: inout Int
    ) -> [Polygon] {
        var polygons = polygons
        var node = self
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
                    if a.id == b.id, let c = a.join(unchecked: b) {
                        a = c
                        total.remove(at: i)
                    }
                }
                total.append(a)
            }
        }
        let keepFront = [.greaterThan, .greaterThanEqual].contains(keeping)
        while !polygons.isEmpty {
            var coplanar = [Polygon](), front = [Polygon](), back = [Polygon]()
            for polygon in polygons {
                polygon.split(along: node.plane!, &coplanar, &front, &back, &id)
            }
            for polygon in coplanar {
                switch keeping {
                case .greaterThan, .lessThanEqual:
                    polygon.clip(to: node.polygons, &back, &front, &id)
                case .greaterThanEqual, .lessThan:
                    if node.plane!.normal.dot(polygon.plane.normal) > 0 {
                        front.append(polygon)
                    } else {
                        polygon.clip(to: node.polygons, &back, &front, &id)
                    }
                }
            }
            if front.count > back.count {
                addPolygons(node.back?.clip(back, keeping, &id) ?? (keepFront ? [] : back))
                if node.front == nil {
                    addPolygons(keepFront ? front : [])
                    return total
                }
                polygons = front
                node = node.front!
            } else {
                addPolygons(node.front?.clip(front, keeping, &id) ?? (keepFront ? front : []))
                if node.back == nil {
                    addPolygons(keepFront ? [] : back)
                    return total
                }
                polygons = back
                node = node.back!
            }
        }
        return total
    }

    func insert(_ polygons: [Polygon]) {
        var polygons = polygons
        var node = self
        while !polygons.isEmpty {
            if node.plane == nil {
                node.plane = polygons.first?.plane
            }
            var front = [Polygon](), back = [Polygon]()
            do {
                var id = 0
                var coplanar = [Polygon]()
                for polygon in polygons {
                    polygon.split(along: node.plane!, &coplanar, &front, &back, &id)
                }
                for polygon in coplanar {
                    if node.plane!.normal.dot(polygon.plane.normal) > 0 {
                        node.polygons.append(polygon)
                    } else {
                        back.append(polygon)
                    }
                }
            }

            node.front = node.front ?? front.first.map {
                BSPNode(plane: $0.plane, parent: node)
            }
            node.back = node.back ?? back.first.map {
                BSPNode(plane: $0.plane, parent: node)
            }

            if front.count > back.count {
                node.back?.insert(back)
                polygons = front
                node = node.front!
            } else {
                node.front?.insert(front)
                polygons = back
                node = node.back ?? node
            }
        }
    }
}
