//
//  Path+CSG.swift
//  Euclid
//
//  Created by Nick Lockwood on 25/08/2025.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

public extension Path {
    /// Callback used to cancel a long-running operation.
    /// - Returns: `true` if operation should be cancelled, or `false` otherwise.
    typealias CancellationHandler = () -> Bool

    /// Split the path along a plane.
    /// - Parameter plane: The ``Plane`` to split the path along.
    /// - Returns: A pair of paths representing the path fragments that lie in front and behind the plane .
    ///
    /// > Note: If the path and plane do not intersect, one of the returned paths will be empty.
    func split(along plane: Plane) -> (front: Path, back: Path) {
        var front = [Path](), back: [Path]! = [], coplanar: [Path]?
        split(along: plane, &coplanar, &front, &back)
        return (Path(subpaths: front), Path(subpaths: back))
    }

    /// Clip path to the specified plane.
    /// - Parameter plane: The plane to clip the path to
    /// - Returns: A path consisting of the parts of the original path that lie in front of the plane.
    func clipped(to plane: Plane) -> Path {
        var front = [Path](), back: [Path]?, coplanar: [Path]?
        split(along: plane, &coplanar, &front, &back)
        return Path(subpaths: front)
    }

    /// Clip path to the specified mesh.
    /// - Parameters:
    ///   - mesh: The ``Mesh``  to clip the path to.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: A path that lies outside the mesh.
    func clipped(to mesh: Mesh, isCancelled: CancellationHandler? = nil) -> Path {
        guard bounds.intersects(mesh.bounds) else {
            return self
        }
        let isCancelled = isCancelled ?? { false }
        return BSP(mesh, isCancelled).clip(self, .greaterThan, isCancelled)
    }
}

extension Path {
    func clip(
        to coplanarPolygons: [Polygon],
        _ inside: inout [Path],
        _ outside: inout [Path]
    ) {
        var toTest = [self]
        for polygon in coplanarPolygons.tessellate() where !toTest.isEmpty {
            var _outside: [Path]! = []
            toTest.forEach { polygon.clip($0, &inside, &_outside) }
            toTest = _outside
        }
        outside += toTest
    }

    func split(
        along plane: Plane,
        _ coplanar: inout [Path]?,
        _ front: inout [Path],
        _ back: inout [Path]?
    ) {
        let subpaths = subpaths
        guard subpaths.count == 1 else {
            subpaths.forEach { $0.split(along: plane, &coplanar, &front, &back) }
            return
        }
        guard var p0 = points.first else {
            return
        }
        var t0 = p0.position.compare(with: plane)
        var comparison = t0
        var points = [p0]
        for p1 in self.points.dropFirst() {
            let t1 = p1.position.compare(with: plane)
            comparison = comparison.union(t1)
            switch comparison {
            case .front, .back, .coplanar:
                points.append(p1)
            case .spanning where t0 != .coplanar:
                let t = (plane.w - plane.normal.dot(p0.position)) /
                    plane.normal.dot(p1.position - p0.position)
                points.append(p0.lerp(p1, t))
                fallthrough
            case .spanning:
                let path = Path(points)
                if t1 == .back {
                    front.append(path)
                } else {
                    back?.append(path)
                }
                points = [points.last!, p1]
                comparison = t1
            }
            p0 = p1
            t0 = t1
        }
        if !points.isEmpty {
            let path = Path(points)
            if comparison == .coplanar {
                if coplanar != nil {
                    coplanar?.append(path)
                    return
                }
                comparison = plane.normal.dot(path.faceNormal) > 0 ? .front : .back
            }
            if comparison == .back {
                back?.append(path)
            } else {
                front.append(path)
            }
        }
    }
}

private extension Polygon {
    func clip(
        _ coplanarPath: Path,
        _ inside: inout [Path],
        _ outside: inout [Path]
    ) {
        assert(isConvex)
        assert(coplanarPath.compare(with: plane) == .coplanar)
        var path = coplanarPath
        var coplanar: [Path]! = []
        for plane in edgePlanes {
            var back: [Path]! = []
            path.split(along: plane, &coplanar, &outside, &back)
            back.append(contentsOf: coplanar)
            guard let p = back.first else {
                return
            }
            path = p
        }
        inside.append(contentsOf: coplanar)
    }
}
