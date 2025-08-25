//
//  Path+CSG.swift
//  Euclid
//
//  Created by Nick Lockwood on 25/08/2025.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

public extension Path {
    /// Split the path along a plane.
    /// - Parameter plane: The ``Plane`` to split the path along.
    /// - Returns: A pair of paths representing the path fragments that lie in front and behind the plane .
    ///
    /// > Note: If the path and plane do not intersect, one of the returned paths will be empty.
    func split(along plane: Plane) -> (front: Path, back: Path) {
        var front = [Path](), back: [Path]! = []
        split(along: plane, &front, &back)
        return (Path(subpaths: front), Path(subpaths: back))
    }

    /// Clip path to the specified plane.
    /// - Parameter plane: The plane to clip the path to
    /// - Returns: A path consisting of the parts of the original path that lie in front of the plane.
    func clipped(to plane: Plane) -> Path {
        var front = [Path](), back: [Path]?
        split(along: plane, &front, &back)
        return Path(subpaths: front)
    }
}

extension Path {
    func split(
        along plane: Plane,
        _ front: inout [Path],
        _ back: inout [Path]?
    ) {
        let subpaths = subpaths
        guard subpaths.count == 1 else {
            subpaths.forEach { $0.split(along: plane, &front, &back) }
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
