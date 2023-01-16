//
//  Path+CSG.swift
//  Euclid
//
//  Created by Nick Lockwood on 29/08/2023.
//  Copyright © 2023 Nick Lockwood. All rights reserved.
//

public extension Path {
    /// Returns a new mesh representing the combined volume of the
    /// mesh parameter and the receiver, with inner faces removed.
    ///
    ///     +-------+            +-------+
    ///     |       |            |       |
    ///     |   A   |            |       |
    ///     |    +--+----+   =   |       +----+
    ///     +----+--+    |       +----+       |
    ///          |   B   |            |       |
    ///          |       |            |       |
    ///          +-------+            +-------+
    ///
    /// - Parameters
    ///   - path: The path to form a union with.
    /// - Returns: An array of paths representing the union of the input paths.
    func union(_ path: Path) -> [Path] {
        Self.union([self, path])
    }

    /// Form a union from multiple paths.
    /// - Parameters
    ///   - paths: A collection of paths to be unioned.
    /// - Returns: An array of paths representing the union of the input paths.
    static func union<T: Collection>(_ paths: T) -> [Path] where T.Element == Path {
        switch paths.count {
        case 0:
            return []
        case 1:
            let subpaths = paths.first!.subpaths
            return subpaths.count == 1 ? subpaths : xor(subpaths)
        default:
            var result = xor(paths.first!.subpaths)
            for path in paths.dropFirst() {
                result = result.union(xor(path.subpaths))
            }
            return result
        }
    }

    /// Returns the result of subtracting the area of the path parameter from the
    /// receiver. If the input path is open or does not intersect the receiver then
    /// the subtract will have no effect.
    ///
    ///     +-------+            +-------+
    ///     |       |            |       |
    ///     |   A   |            |       |
    ///     |    +--+----+   =   |    +--+
    ///     +----+--+    |       +----+
    ///          |   B   |
    ///          |       |
    ///          +-------+
    ///
    /// - Parameters
    ///   - path: The path to subtract from this one.
    /// - Returns: An array of paths representing the result of the subtraction.
    func subtracting(_ path: Path) -> [Path] {
        Self.difference([self, path])
    }

    /// Get the difference between multiple paths.
    /// - Parameters
    ///   - paths: An ordered collection of paths. All but the first will be subtracted from the first.
    /// - Returns: An array of paths representing the difference between the input paths.
    static func difference<T: Collection>(_ paths: T) -> [Path] where T.Element == Path {
        switch paths.count {
        case 0:
            return []
        case 1:
            let subpaths = paths.first!.subpaths
            return subpaths.count == 1 ? subpaths : xor(subpaths)
        default:
            var result = xor(paths.first!.subpaths)
            for path in paths.dropFirst() {
                result = result.clip(to: xor(path.subpaths))
            }
            return result
        }
    }

    /// Returns a new path reprenting only the area exclusively occupied by
    /// one path or the other, but not both. If either path is open it will be clipped to the
    /// area of the other. If both paths are open then both will be returned unmodified.
    ///
    ///     +-------+            +-------+
    ///     |       |            |       |
    ///     |   A   |            |       |
    ///     |    +--+----+   =   |    ++++----+
    ///     +----+--+    |       +----++++    |
    ///          |   B   |            |       |
    ///          |       |            |       |
    ///          +-------+            +-------+
    ///
    /// - Parameters
    ///   - path: The path to be XORed with this one.
    /// - Returns: An array of paths representing the XOR of the input paths.
    func xor(_ path: Path) -> [Path] {
        Self.xor([self, path])
    }

    /// XOR multiple paths.
    /// - Parameters
    ///   - paths: A collection of paths to be XORed.
    /// - Returns: An array of paths representing the XOR of the input paths.
    static func xor<T: Collection>(_ paths: T) -> [Path] where T.Element == Path {
        switch paths.count {
        case 0:
            return []
        case 1:
            let subpaths = paths.first!.subpaths
            return subpaths.count == 1 ? subpaths : xor(subpaths)
        default:
            var result = xor(paths.first!.subpaths)
            for path in paths.dropFirst() {
                result = result.xor(xor(path.subpaths))
            }
            return result
        }
    }

    /// Efficiently computes the intersection of multiple paths.
    /// - Parameters
    ///   - paths: A collection of paths to be intersected.
    /// - Returns: A new mesh representing the intersection of the meshes.
//    static func intersection<T: Collection>(
//        _ meshes: T,
//        isCancelled: CancellationHandler = { false }
//    ) -> Mesh where T.Element == Mesh {
//        let head = meshes.first ?? .empty, tail = meshes.dropFirst()
//        let bounds = tail.reduce(into: head.bounds) { $0.formUnion($1.bounds) }
//        if bounds.isEmpty {
//            return .empty
//        }
//        return tail.reduce(into: head) {
//            $0 = $0.intersection($1, isCancelled: isCancelled)
//        }
//    }

    /// Split the path along a plane.
    /// - Parameter along: The ``Plane`` to split the path along.
    /// - Returns: A pair of arrays representing the path fragments in front of and behind the plane respectively.
    ///
    /// > Note: If the plane and polygon do not intersect, one of the returned arrays will be empty.
    func split(along plane: Plane) -> (front: [Path], back: [Path]) {
        guard subpaths.count == 1 else {
            let (front, back) = subpaths.reduce(into: (front: [Path](), back: [Path]())) {
                let (front, back) = $1.split(along: plane)
                $0.front += front
                $0.back += back
            }
            return ([Path(subpaths: front)], [Path(subpaths: back)])
        }
        if isClosed {
            var front = [Polygon](), back = [Polygon](), coplanar = [Polygon](), id = 0
            for polygon in facePolygons() {
                polygon.split(along: plane, &coplanar, &front, &back, &id)
            }
            return (
                front: (coplanar + front).makeWatertight().edgePaths(withOriginalPaths: [self]),
                back: back.makeWatertight().edgePaths(withOriginalPaths: [self])
            )
        }
        var front = [Path](), back = [Path]()
        var path = [PathPoint]()
        var lastComparison = PlaneComparison.coplanar
        for point in points {
            let comparison = point.position.compare(with: plane)
            guard var last = path.last else {
                path.append(point)
                lastComparison = comparison
                continue
            }
            switch comparison {
            case .coplanar:
                path.append(point)
            case .front where lastComparison != .back,
                 .back where lastComparison != .front:
                path.append(point)
                lastComparison = comparison
            case .front, .back:
                if last.position.compare(with: plane) != .coplanar {
                    let delta = (point.position - last.position)
                    let length = delta.length
                    let direction = delta / length
                    guard let d = linePlaneIntersection(last.position, direction, plane) else {
                        assertionFailure() // Shouldn't happen
                        path.append(point)
                        continue
                    }
                    last = last.lerp(point, d / length)
                    path.append(last)
                }
                if lastComparison == .front {
                    front.append(Path(path))
                } else {
                    back.append(Path(path))
                }
                path = [last, point]
                lastComparison = comparison
            case .spanning:
                preconditionFailure()
            }
        }
        if path.count > 1 {
            if lastComparison == .back {
                back.append(Path(path))
            } else {
                front.append(Path(path))
            }
        }
        return (front, back)
    }

    /// Clip path to the specified plane
    /// - Parameter plane: The plane to clip the path to.
    /// - Returns: An array of the path fragments that lie in front of the plane.
    func clip(to plane: Plane) -> [Path] {
        // TODO: avoid calculating back parts and discarding them
        split(along: plane).front
    }
}

private extension Array where Element == Path {
    func xor(_ paths: [Path]) -> [Path] {
        clip(to: paths) + paths.clip(to: self)
    }

    func union(_ paths: [Path]) -> [Path] {
        let allPaths = self + paths
        var polygons = flatMap { $0.facePolygons() }
        for path in paths {
            for polygon in path.facePolygons() {
                var inside = [Polygon](), outside = [Polygon](), id = 0
                polygon.clip(to: polygons, &inside, &outside, &id)
                polygons += outside
            }
        }
        let openPaths = filter { !$0.isClosed } + paths.filter { !$0.isClosed }
        return openPaths + polygons.makeWatertight().edgePaths(withOriginalPaths: allPaths)
    }

    func clip(to paths: [Path]) -> [Path] {
        let rhs = paths.flatMap { $0.facePolygons() }
        return flatMap {
            var inside = [Polygon](), outside = [Polygon](), id = 0
            for polygon in $0.facePolygons() {
                polygon.clip(to: rhs, &inside, &outside, &id)
            }
            return outside.makeWatertight().edgePaths(withOriginalPaths: [$0] + paths)
        }
    }
}

private extension Array where Element == Polygon {
    func edgePaths<T: Collection>(withOriginalPaths paths: T) -> [Path] where T.Element == Path {
        var pointMap = Dictionary(paths.flatMap { path -> [(Vector, PathPoint)] in
            path.points.map { ($0.position, $0) }
        }, uniquingKeysWith: {
            $0.lerp($1, 0.5)
        })
        var polylines = [[Vector]]()
        var edges = holeEdges.sorted()
        while let edge = edges.popLast() {
            var polyline = [edge.start, edge.end]
            while let i = edges.firstIndex(where: {
                polyline.first!.isEqual(to: $0.start) ||
                    polyline.last!.isEqual(to: $0.start) ||
                    polyline.first!.isEqual(to: $0.end) ||
                    polyline.last!.isEqual(to: $0.end)
            }) {
                let edge = edges.remove(at: i)
                if polyline.first!.isEqual(to: edge.start) {
                    polyline.insert(edge.end, at: 0)
                } else if polyline.last!.isEqual(to: edge.start) {
                    polyline.append(edge.end)
                } else if polyline.first!.isEqual(to: edge.end) {
                    polyline.insert(edge.start, at: 0)
                } else if polyline.last!.isEqual(to: edge.end) {
                    polyline.append(edge.start)
                }
            }
            polylines.append(polyline)
        }
        // TODO: this is just to recover texcoords/colors - find more efficient solution
        for polygon in self {
            for vertex in polygon.vertices where pointMap[vertex.position] == nil {
                pointMap[vertex.position] = PathPoint(vertex)
            }
        }
        return polylines.map { Path($0.map { pointMap[$0] ?? .point($0) }) }
    }
}
