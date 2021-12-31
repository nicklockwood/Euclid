//
//  Shapes.swift
//  Euclid
//
//  Created by Nick Lockwood on 03/07/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
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

// MARK: 3D shapes

public extension Path {
    /// Create a path from a line segment
    static func line(_ line: LineSegment) -> Path {
        .line(line.start, line.end)
    }

    /// Create a path from a start and end point
    static func line(_ start: Vector, _ end: Vector) -> Path {
        Path([.point(start), .point(end)])
    }

    /// Create a closed circular path
    static func circle(radius r: Double = 0.5, segments: Int = 16) -> Path {
        ellipse(width: r * 2, height: r * 2, segments: segments)
    }

    /// Create a closed elliptical path
    static func ellipse(width: Double, height: Double, segments: Int = 16) -> Path {
        let segments = max(3, segments)
        let step = 2 / Double(segments) * .pi
        let to = 2 * .pi + epsilon
        let w = max(abs(width / 2), epsilon)
        let h = max(abs(height / 2), epsilon)
        return Path(unchecked: stride(from: 0, through: to, by: step).map {
            PathPoint.curve(w * -sin($0), h * cos($0))
        }, plane: .xy, subpathIndices: [])
    }

    /// Create a closed regular polygon
    static func polygon(radius: Double = 0.5, sides: Int) -> Path {
        let circle = self.circle(radius: radius, segments: sides)
        return Path(unchecked: circle.points.map {
            .point($0.position)
        }, plane: .xy, subpathIndices: [])
    }

    /// Create a closed rectangular path
    static func rectangle(width: Double, height: Double) -> Path {
        let w = width / 2, h = height / 2
        if height < epsilon {
            return .line(Vector(-w, 0), Vector(w, 0))
        } else if width < epsilon {
            return .line(Vector(0, -h), Vector(0, h))
        }
        return Path(unchecked: [
            .point(-w, h), .point(-w, -h),
            .point(w, -h), .point(w, h),
            .point(-w, h),
        ], plane: .xy, subpathIndices: [])
    }

    /// Create a closed square path
    static func square(size: Double = 1) -> Path {
        rectangle(width: size, height: size)
    }

    /// Create a quadratic bezier spline
    static func curve(_ points: [PathPoint], detail: Int = 4) -> Path {
        enum ArcRange {
            case lhs, rhs, all
        }

        func arc(
            _ p0: PathPoint,
            _ p1: PathPoint,
            _ p2: PathPoint,
            _ detail: Int,
            _ range: ArcRange = .all
        ) -> [PathPoint] {
            let detail = detail + 1
            assert(detail >= 2)
            let steps: [Double]
            switch range {
            case .all:
                // excludes start and end points
                steps = (1 ..< detail).map { Double($0) / Double(detail) }
            case .lhs:
                // includes start and end point
                let range = 0 ..< Int(ceil(Double(detail) / 2))
                steps = range.map { Double($0) / Double(detail) } + [0.5]
            case .rhs:
                // excludes end point
                let range = detail / 2 + 1 ..< detail
                steps = [0.5] + range.map { Double($0) / Double(detail) }
            }

            return steps.map {
                var texcoord: Vector?
                if let t0 = p0.texcoord, let t1 = p1.texcoord, let t2 = p2.texcoord {
                    texcoord = Vector(
                        quadraticBezier(t0.x, t1.x, t2.x, $0),
                        quadraticBezier(t0.y, t1.y, t2.y, $0),
                        quadraticBezier(t0.z, t1.z, t2.z, $0)
                    )
                }
                var color: Color?
                if p0.color != nil || p1.color != nil || p2.color != nil {
                    color = [
                        p0.color ?? .white,
                        p1.color ?? .white,
                        p2.color ?? .white,
                    ].lerp($0)
                }
                return .curve(Vector(
                    quadraticBezier(p0.position.x, p1.position.x, p2.position.x, $0),
                    quadraticBezier(p0.position.y, p1.position.y, p2.position.y, $0),
                    quadraticBezier(p0.position.z, p1.position.z, p2.position.z, $0)
                ), texcoord: texcoord, color: color)
            }
        }

        let points = sanitizePoints(points)
        guard detail > 0, !points.isEmpty else {
            return Path(unchecked: points, plane: nil, subpathIndices: nil)
        }
        var result = [PathPoint]()
        let isClosed = pointsAreClosed(unchecked: points)
        let count = points.count
        let start = isClosed ? 0 : 1
        let end = count - 1
        var p0 = isClosed ? points[count - 2] : points[0]
        var p1 = isClosed ? points[0] : points[1]
        if !isClosed {
            if p0.isCurved, count >= 3 {
                let pe = extrapolate(points[2], p1, p0)
                if p1.isCurved {
                    result += arc(pe.lerp(p0, 0.5), p0, p0.lerp(p1, 0.5), detail, .rhs)
                } else {
                    result += arc(pe, p0, p1, detail, .rhs)
                }
            } else {
                result.append(p0)
            }
        }
        for i in start ..< end {
            let p2 = points[(i + 1) % count]
            switch (p0.isCurved, p1.isCurved, p2.isCurved) {
            case (false, true, false):
                result += arc(p0, p1, p2, detail + 1)
            case (true, true, true):
                let p0p1 = p0.lerp(p1, 0.5)
                result.append(p0p1)
                result += arc(p0p1, p1, p1.lerp(p2, 0.5), detail)
            case (true, true, false):
                let p0p1 = p0.lerp(p1, 0.5)
                result.append(p0p1)
                result += arc(p0p1, p1, p2, detail)
            case (false, true, true):
                result += arc(p0, p1, p1.lerp(p2, 0.5), detail)
            case (_, false, _):
                result.append(p1)
            }
            p0 = p1
            p1 = p2
        }
        if !isClosed {
            let p2 = points.last!
            if p2.isCurved, count >= 3 {
                p1 = p0
                let pe = extrapolate(points[count - 3], p1, p2)
                if p1.isCurved {
                    result += arc(p1.lerp(p2, 0.5), p2, p2.lerp(pe, 0.5), detail, .lhs)
                } else {
                    result += arc(p1, p2, pe, detail, .lhs).dropFirst()
                }
            } else {
                result.append(p2)
            }
        } else {
            result.append(result[0])
        }
        let path = Path(unchecked: result, plane: nil, subpathIndices: nil)
        assert(path.isClosed == isClosed)
        return path
    }
}

public extension Mesh {
    enum Faces {
        case front
        case back
        case frontAndBack
        case `default`
    }

    enum WrapMode {
        case shrink
        case tube
        case `default`
    }

    /// Construct an axis-aligned cuboid mesh
    static func cube(
        center c: Vector = .init(0, 0, 0),
        size s: Vector,
        faces: Faces = .default,
        material: Material? = nil
    ) -> Mesh {
        let polygons: [Polygon] = [
            [[5, 1, 3, 7], [+1, 0, 0]],
            [[0, 4, 6, 2], [-1, 0, 0]],
            [[6, 7, 3, 2], [0, +1, 0]],
            [[0, 1, 5, 4], [0, -1, 0]],
            [[4, 5, 7, 6], [0, 0, +1]],
            [[1, 0, 2, 3], [0, 0, -1]],
        ].map {
            var index = 0
            let (indexData, normalData) = ($0[0], $0[1])
            let normal = Vector(
                Double(normalData[0]),
                Double(normalData[1]),
                Double(normalData[2])
            )
            return Polygon(
                unchecked: indexData.map { i in
                    let pos = c + s.scaled(by: Vector(
                        i & 1 > 0 ? 0.5 : -0.5,
                        i & 2 > 0 ? 0.5 : -0.5,
                        i & 4 > 0 ? 0.5 : -0.5
                    ))
                    let uv = Vector(
                        (1 ... 2).contains(index) ? 1 : 0,
                        (0 ... 1).contains(index) ? 1 : 0
                    )
                    index += 1
                    return Vertex(unchecked: pos, normal, uv, nil)
                },
                normal: normal,
                isConvex: true,
                material: material
            )
        }
        let halfSize = s / 2
        let bounds = Bounds(min: c - halfSize, max: c + halfSize)
        switch faces {
        case .front, .default:
            return Mesh(
                unchecked: polygons,
                bounds: bounds,
                isConvex: true,
                isWatertight: true
            )
        case .back:
            return Mesh(
                unchecked: polygons.inverted(),
                bounds: bounds,
                isConvex: false,
                isWatertight: true
            )
        case .frontAndBack:
            return Mesh(
                unchecked: polygons + polygons.inverted(),
                bounds: bounds,
                isConvex: false,
                isWatertight: true
            )
        }
    }

    static func cube(
        center c: Vector = .init(0, 0, 0),
        size s: Double = 1,
        faces: Faces = .default,
        material: Material? = nil
    ) -> Mesh {
        cube(center: c, size: Vector(s, s, s), faces: faces, material: material)
    }

    /// Construct a sphere mesh
    static func sphere(
        radius r: Double = 0.5,
        slices: Int = 16,
        stacks: Int? = nil,
        poleDetail: Int = 0,
        faces: Faces = .default,
        wrapMode: WrapMode = .default,
        material: Material? = nil
    ) -> Mesh {
        var semicircle = [PathPoint]()
        let stacks = max(2, stacks ?? (slices / 2))
        let r = max(abs(r), epsilon)
        for i in 0 ... stacks {
            let a = Double(i) / Double(stacks) * Angle.pi
            semicircle.append(.curve(-sin(a) * r, cos(a) * r))
        }
        return lathe(
            unchecked: Path(unchecked: semicircle, plane: .xy, subpathIndices: []),
            slices: slices,
            poleDetail: poleDetail,
            faces: faces,
            wrapMode: wrapMode,
            material: material,
            isConvex: true,
            isWatertight: true
        )
    }

    /// Construct a cylindrical mesh
    static func cylinder(
        radius r: Double = 0.5,
        height h: Double = 1,
        slices: Int = 16,
        poleDetail: Int = 0,
        faces: Faces = .default,
        wrapMode: WrapMode = .default,
        material: Material? = nil
    ) -> Mesh {
        let r = max(abs(r), epsilon)
        let h = max(abs(h), epsilon)
        let wrapMode = wrapMode == .default ? .tube : wrapMode
        return lathe(
            unchecked: Path(unchecked: [
                .point(0, h / 2),
                .point(-r, h / 2),
                .point(-r, -h / 2),
                .point(0, -h / 2),
            ], plane: .xy, subpathIndices: []),
            slices: slices,
            poleDetail: poleDetail,
            addDetailForFlatPoles: true,
            faces: faces,
            wrapMode: wrapMode,
            material: material,
            isConvex: true,
            isWatertight: true
        )
    }

    /// Construct as conical mesh
    static func cone(
        radius r: Double = 0.5,
        height h: Double = 1,
        slices: Int = 16,
        poleDetail: Int? = nil,
        addDetailAtBottomPole: Bool = false,
        faces: Faces = .default,
        wrapMode: WrapMode = .default,
        material: Material? = nil
    ) -> Mesh {
        let r = max(abs(r), epsilon)
        let h = max(abs(h), epsilon)
        let poleDetail = poleDetail ?? Int(sqrt(Double(slices)))
        let wrapMode = wrapMode == .default ? .tube : wrapMode
        return lathe(
            unchecked: Path(unchecked: [
                .point(0, h / 2),
                .point(-r, -h / 2),
                .point(0, -h / 2),
            ], plane: .xy, subpathIndices: []),
            slices: slices,
            poleDetail: poleDetail,
            addDetailForFlatPoles: addDetailAtBottomPole,
            faces: faces,
            wrapMode: wrapMode,
            material: material,
            isConvex: true,
            isWatertight: true
        )
    }

    /// Create a rotationally symmetrical shape by rotating the supplied path
    /// around an axis. The path consists of an array of xy coordinate pairs
    /// defining the profile of the shape. Some notes on path coordinates:
    ///
    /// * The path can be open or closed. Define a closed path by ending with
    ///   the same coordinate pair that you started with
    ///
    /// * The path can be placed on either the left or right of the Y axis,
    ///   however the behavior is undefined for paths that cross the Y axis
    ///
    /// * Open paths that do not start and end on the Y axis will produce
    ///   a shape with a hole in it
    ///
    static func lathe(
        _ profile: Path,
        slices: Int = 16,
        poleDetail: Int = 0,
        addDetailForFlatPoles: Bool = false,
        faces: Faces = .default,
        wrapMode: WrapMode = .default,
        material: Material? = nil
    ) -> Mesh {
        lathe(
            unchecked: profile,
            slices: slices,
            poleDetail: poleDetail,
            addDetailForFlatPoles: addDetailForFlatPoles,
            faces: faces,
            wrapMode: wrapMode,
            material: material,
            isConvex: false, // TODO: Can we work out if profile is convex?
            isWatertight: nil // TODO: Can we work this out?
        )
    }

    /// Extrude a path along its face normal
    static func extrude(
        _ shape: Path,
        depth: Double = 1,
        faces: Faces = .default,
        material: Material? = nil
    ) -> Mesh {
        let offset = shape.faceNormal * (depth / 2)
        if offset.isEqual(to: .zero) {
            return fill(shape, faces: faces, material: material)
        }
        let polygon = Polygon(shape: shape)
        return loft(
            unchecked: [
                shape.translated(by: offset),
                shape.translated(by: -offset),
            ],
            faces: faces,
            material: material,
            verifiedCoplanar: true,
            isConvex: polygon?.isConvex == true,
            isWatertight: polygon.map { _ in true } // TODO: make less strict
        )
    }

    /// Extrude a path along another path
    static func extrude(
        _ shape: Path,
        along: Path,
        faces: Faces = .default,
        material: Material? = nil
    ) -> Mesh {
        let subpaths = along.subpaths
        guard subpaths.count == 1 else {
            return .merge(subpaths.map {
                extrude(
                    shape,
                    along: $0,
                    faces: faces,
                    material: material
                )
            })
        }
        let points = along.points
        guard var p0 = points.first else {
            return Mesh([])
        }
        var shape = shape
        let shapePlane = shape.flatteningPlane
        let pathPlane = along.flatteningPlane
        let shapeNormal: Vector
        switch (shapePlane, pathPlane) {
        case (.xy, .xy):
            shape = shape.rotated(by: .pitch(.halfPi))
            shapeNormal = shapePlane.rawValue.normal.rotated(by: .pitch(.halfPi))
        case (.yz, .yz), (.xz, .xz):
            shape = shape.rotated(by: .roll(.halfPi))
            shapeNormal = shapePlane.rawValue.normal.rotated(by: .roll(.halfPi))
        default:
            shapeNormal = shapePlane.rawValue.normal
        }
        var shapes = [Path]()
        let count = points.count
        var p1 = points[1]
        var p0p1 = (p1.position - p0.position).normalized()
        func addShape(_ p2: PathPoint, _ _p0p2: inout Vector?) {
            let p1p2 = (p2.position - p1.position).normalized()
            let p0p2 = (p0p1 + p1p2).normalized()
            let r: Rotation
            if let _p0p2 = _p0p2 {
                r = rotationBetweenVectors(p0p2, _p0p2)
            } else {
                r = rotationBetweenVectors(p0p2, shapeNormal)
            }
            shape = shape.rotated(by: r)
            if let color = p2.color {
                shape = shape.with(color: color)
            }
            if p0p1.isEqual(to: p1p2) {
                shapes.append(shape.translated(by: p1.position))
            } else {
                let axis = p0p1.cross(p1p2)
                let a = (1 / p0p1.dot(p0p2)) - 1
                var scale = axis.cross(p0p2).normalized() * a
                scale.x = abs(scale.x)
                scale.y = abs(scale.y)
                scale.z = abs(scale.z)
                scale = scale + Vector(1, 1, 1)
                shapes.append(shape.scaled(by: scale).translated(by: p1.position))
            }
            p0 = p1
            p1 = p2
            p0p1 = p1p2
            _p0p2 = p0p2
        }
        if along.isClosed {
            var _p0p2: Vector?
            for i in 1 ..< count {
                let p2 = points[(i < count - 1) ? i + 1 : 1]
                addShape(p2, &_p0p2)
            }
            shapes.append(shapes[0])
        } else {
            var _p0p2: Vector! = p0p1
            shape = shape.rotated(by: rotationBetweenVectors(p0p1, shapeNormal))
            if let color = p0.color {
                shape = shape.with(color: color)
            }
            shapes.append(shape.translated(by: p0.position))
            for i in 1 ..< count - 1 {
                let p2 = points[i + 1]
                addShape(p2, &_p0p2)
            }
            shape = shape.rotated(by: rotationBetweenVectors(p0p1, _p0p2))
            if let color = points.last?.color {
                shape = shape.with(color: color)
            }
            shapes.append(shape.translated(by: points.last!.position))
        }
        return loft(shapes, faces: faces, material: material)
    }

    /// Connect multiple 3D paths
    static func loft(
        _ shapes: [Path],
        faces: Faces = .default,
        material: Material? = nil
    ) -> Mesh {
        loft(
            unchecked: shapes,
            faces: faces,
            material: material,
            verifiedCoplanar: false,
            isConvex: false,
            isWatertight: nil
        )
    }

    /// Fill a path to form one or more polygons
    static func fill(
        _ shape: Path,
        faces: Faces = .default,
        material: Material? = nil
    ) -> Mesh {
        let subpaths = shape.subpaths
        if subpaths.count > 1 {
            return .xor(subpaths.map { .fill($0, faces: faces, material: material) })
        }

        let polygons = shape.closed().facePolygons(material: material)
        switch faces {
        case .front:
            return Mesh(
                unchecked: polygons,
                bounds: nil,
                isConvex: false,
                isWatertight: false
            )
        case .back:
            return Mesh(
                unchecked: polygons.map { $0.inverted() },
                bounds: nil,
                isConvex: false,
                isWatertight: false
            )
        case .frontAndBack, .default:
            return Mesh(
                unchecked: polygons + polygons.map { $0.inverted() },
                bounds: nil,
                isConvex: polygons.count == 1 && polygons[0].isConvex,
                isWatertight: true
            )
        }
    }

    /// Stroke a path with the specified line width, depth and material
    @available(*, deprecated, message: "Use `stroke(width:detail:)` instead")
    static func stroke(
        _ shape: Path,
        width: Double,
        depth: Double,
        faces: Faces = .default,
        material: Material? = nil
    ) -> Mesh {
        extrude(
            .rectangle(width: width, height: depth),
            along: shape,
            faces: faces,
            material: material
        )
    }

    /// Stroke a path with the specified line width, detail and material
    static func stroke(
        _ shape: Path,
        width: Double = 0.01,
        detail: Int = 2,
        material: Material? = nil
    ) -> Mesh {
        let path: Path
        let radius = width / 2
        switch detail {
        case 1, 2:
            path = .line(Vector(-radius, 0), Vector(radius, 0))
        case let sides:
            path = .circle(radius: radius, segments: sides)
        }
        let faces: Faces = detail == 2 ? .frontAndBack : .front
        return extrude(path, along: shape, faces: faces, material: material)
    }

    /// Efficiently stroke a set of line segments (useful for drawing wireframes)
    static func stroke<T: Collection>(
        _ lines: T,
        width: Double = 0.002,
        detail: Int = 3,
        material: Material? = nil
    ) -> Mesh where T.Element == LineSegment {
        let radius = width / 2
        let detail = max(3, detail)
        let path = Path.circle(radius: radius, segments: detail)
        var bounds = Bounds.empty
        var polygons = [Polygon]()
        polygons.reserveCapacity(detail * lines.count)
        for line in lines {
            var shape = path
            let along = Path.line(line)
            if along.flatteningPlane == .xy {
                shape = shape.rotated(by: .pitch(.halfPi))
            }
            shape = shape.rotated(by: rotationBetweenVectors(line.direction, shape.faceNormal))
            let shape0 = shape.translated(by: line.start)
            bounds.formUnion(shape0.bounds)
            let shape1 = shape.translated(by: line.end)
            bounds.formUnion(shape1.bounds)
            loft(
                unchecked: shape0, shape1,
                uvstart: 0, uvend: 1,
                verifiedCoplanar: false,
                material: material,
                into: &polygons
            )
        }
        return Mesh(
            unchecked: polygons,
            bounds: bounds,
            isConvex: false,
            isWatertight: nil
        )
    }
}

private extension Mesh {
    static func lathe(
        unchecked profile: Path,
        slices: Int = 16,
        poleDetail: Int = 0,
        addDetailForFlatPoles: Bool = false,
        faces: Faces = .default,
        wrapMode: WrapMode = .default,
        material: Material? = nil,
        isConvex: Bool,
        isWatertight: Bool?
    ) -> Mesh {
        let subpaths = profile.subpaths
        if subpaths.count > 1 {
            return .xor(subpaths.map {
                .lathe(
                    $0,
                    slices: slices,
                    poleDetail: poleDetail,
                    addDetailForFlatPoles: addDetailForFlatPoles,
                    faces: faces,
                    wrapMode: wrapMode,
                    material: material
                )
            })
        }

        var profile = profile
        if profile.points.count < 2 {
            return Mesh([])
        }

        // min slices
        let slices = max(3, slices)

        // normalize profile
        profile = profile.flattened().clippedToYAxis()
        guard let normal = profile.plane?.normal else {
            return Mesh([])
        }
        if normal.z < 0 {
            profile = Path(
                unchecked: profile.points.reversed(),
                plane: profile.plane?.inverted(),
                subpathIndices: []
            )
        }

        // get profile vertices
        var vertices = profile.edgeVertices(for: wrapMode)

        // add more detail around poles automatically
        if poleDetail > 0 {
            func subdivide(_ times: Int, _ v0: Vertex, _ v1: Vertex) -> [Vertex] {
                guard times > 0 else {
                    return [v0, v1]
                }
                let v0v1 = v0.lerp(v1, 0.5)
                return subdivide(times - 1, v0, v0v1) + [v0v1, v1]
            }
            func isVertical(_ normal: Vector) -> Bool {
                abs(normal.x) < epsilon && abs(normal.z) < epsilon
            }
            var i = 0
            while i < vertices.count {
                let v0 = vertices[i]
                let v1 = vertices[i + 1]
                if v0.position.x == 0 {
                    if v1.position.x != 0, addDetailForFlatPoles || !isVertical(v0.normal) {
                        let s = subdivide(poleDetail, v0, v1)
                        vertices.replaceSubrange(i ... i + 1, with: s)
                        i += s.count - 2
                    }
                } else if v1.position.x == 0, addDetailForFlatPoles || !isVertical(v1.normal) {
                    let s = subdivide(poleDetail, v1, v0).reversed()
                    vertices.replaceSubrange(i ... i + 1, with: s)
                    i += s.count - 2
                }
                i += 2
            }
        }

        var polygons = [Polygon]()
        for i in 0 ..< slices {
            let t0 = Double(i) / Double(slices)
            let t1 = Double(i + 1) / Double(slices)
            let a0 = t0 * Angle.twoPi
            let a1 = t1 * Angle.twoPi
            let cos0 = cos(a0)
            let cos1 = cos(a1)
            let sin0 = sin(a0)
            let sin1 = sin(a1)
            for j in stride(from: 1, to: vertices.count, by: 2) {
                let v0 = vertices[j - 1], v1 = vertices[j]
                if v0.position.x == 0 {
                    if abs(v1.position.x) >= epsilon {
                        // top triangle
                        let v0 = Vertex(
                            unchecked: v0.position,
                            Vector(cos0 * v0.normal.x, v0.normal.y, sin0 * -v0.normal.x),
                            Vector(v0.texcoord.x + (t0 + t1) / 2, v0.texcoord.y, 0),
                            v0.color
                        )
                        let v2 = Vertex(
                            unchecked:
                            Vector(cos0 * v1.position.x, v1.position.y, sin0 * -v1.position.x),
                            Vector(cos0 * v1.normal.x, v1.normal.y, sin0 * -v1.normal.x),
                            Vector(v1.texcoord.x + t0, v1.texcoord.y, 0),
                            v1.color
                        )
                        let v3 = Vertex(
                            unchecked:
                            Vector(cos1 * v1.position.x, v1.position.y, sin1 * -v1.position.x),
                            Vector(cos1 * v1.normal.x, v1.normal.y, sin1 * -v1.normal.x),
                            Vector(v1.texcoord.x + t1, v1.texcoord.y, 0),
                            v1.color
                        )
                        polygons.append(Polygon(
                            unchecked: [v0, v2, v3],
                            plane: nil,
                            isConvex: true,
                            material: material
                        ))
                    }
                } else if v1.position.x == 0 {
                    // bottom triangle
                    let v1 = Vertex(
                        unchecked: v1.position,
                        Vector(cos0 * v1.normal.x, v1.normal.y, sin0 * -v1.normal.x),
                        Vector(v1.texcoord.x + (t0 + t1) / 2, v1.texcoord.y, 0),
                        v1.color
                    )
                    let v2 = Vertex(
                        unchecked:
                        Vector(cos1 * v0.position.x, v0.position.y, sin1 * -v0.position.x),
                        Vector(cos1 * v0.normal.x, v0.normal.y, sin1 * -v0.normal.x),
                        Vector(v0.texcoord.x + t1, v0.texcoord.y, 0),
                        v0.color
                    )
                    let v3 = Vertex(
                        unchecked:
                        Vector(cos0 * v0.position.x, v0.position.y, sin0 * -v0.position.x),
                        Vector(cos0 * v0.normal.x, v0.normal.y, sin0 * -v0.normal.x),
                        Vector(v0.texcoord.x + t0, v0.texcoord.y, 0),
                        v0.color
                    )
                    polygons.append(Polygon(
                        unchecked: [v2, v3, v1],
                        plane: nil,
                        isConvex: true,
                        material: material
                    ))
                } else {
                    // quad face
                    let v2 = Vertex(
                        unchecked:
                        Vector(cos1 * v0.position.x, v0.position.y, sin1 * -v0.position.x),
                        Vector(cos1 * v0.normal.x, v0.normal.y, sin1 * -v0.normal.x),
                        Vector(v0.texcoord.x + t1, v0.texcoord.y, 0),
                        v0.color
                    )
                    let v3 = Vertex(
                        unchecked:
                        Vector(cos0 * v0.position.x, v0.position.y, sin0 * -v0.position.x),
                        Vector(cos0 * v0.normal.x, v0.normal.y, sin0 * -v0.normal.x),
                        Vector(v0.texcoord.x + t0, v0.texcoord.y, 0),
                        v0.color
                    )
                    let v4 = Vertex(
                        unchecked:
                        Vector(cos0 * v1.position.x, v1.position.y, sin0 * -v1.position.x),
                        Vector(cos0 * v1.normal.x, v1.normal.y, sin0 * -v1.normal.x),
                        Vector(v1.texcoord.x + t0, v1.texcoord.y, 0),
                        v1.color
                    )
                    let v5 = Vertex(
                        unchecked:
                        Vector(cos1 * v1.position.x, v1.position.y, sin1 * -v1.position.x),
                        Vector(cos1 * v1.normal.x, v1.normal.y, sin1 * -v1.normal.x),
                        Vector(v1.texcoord.x + t1, v1.texcoord.y, 0),
                        v1.color
                    )
                    let vertices = [v2, v3, v4, v5]
                    if !verticesAreDegenerate(vertices) {
                        polygons.append(Polygon(
                            unchecked: vertices,
                            plane: nil,
                            isConvex: true,
                            material: material
                        ))
                    }
                }
            }
        }

        let isSealed = (isWatertight == true) || (
            isConvex &&
                !pointsAreSelfIntersecting(profile.points.map { $0.position })
        )
        let isWatertight = isSealed ? true : isWatertight
        switch faces {
        case .default where isSealed, .front:
            return Mesh(
                unchecked: polygons,
                bounds: nil, // TODO: can we calculate this efficiently?
                isConvex: isConvex,
                isWatertight: isWatertight
            )
        case .back:
            return Mesh(
                unchecked: polygons.inverted(),
                bounds: nil, // TODO: can we calculate this efficiently?
                isConvex: false,
                isWatertight: isWatertight
            )
        case .frontAndBack:
            return Mesh(
                unchecked: polygons + polygons.inverted(),
                bounds: nil, // TODO: can we calculate this efficiently?
                isConvex: false,
                isWatertight: isWatertight
            )
        case .default:
            // seal loose ends
            // TODO: improve this by not adding backfaces inside closed subsectors
            if let first = vertices.first?.position,
               let last = vertices.last?.position,
               first != last, first.x != 0 || last.x != 0
            {
                polygons += polygons.inverted()
            }
            return Mesh(
                unchecked: polygons,
                bounds: nil, // TODO: can we calculate this efficiently?
                isConvex: false,
                isWatertight: isWatertight
            )
        }
    }

    static func directionBetweenShapes(_ s0: Path, _ s1: Path) -> Vector? {
        if let p0 = s0.points.first, let p1 = s1.points.first {
            // TODO: what if p0p1 length is zero? We should try other points
            return (p1.position - p0.position).normalized()
        }
        return nil
    }

    static func loft(
        unchecked shapes: [Path],
        faces: Faces = .default,
        material: Material?,
        verifiedCoplanar: Bool,
        isConvex: Bool,
        isWatertight: Bool?
    ) -> Mesh {
        var subpathCount = 0
        let arrayOfSubpaths: [[Path]] = shapes.map {
            let subpaths = $0.subpaths
            subpathCount = max(subpathCount, subpaths.count)
            return subpaths
        }
        if subpathCount > 1 {
            var subshapes = Array(repeating: [Path](), count: subpathCount)
            for subpaths in arrayOfSubpaths {
                for (i, subpath) in subpaths.enumerated() {
                    subshapes[i].append(subpath)
                }
            }
            return .xor(subshapes.map { .loft($0, faces: faces, material: material) })
        }
        let shapes = shapes
        if shapes.isEmpty {
            return Mesh([])
        }
        let count = shapes.count
        let isClosed = (shapes.first == shapes.last)
        if count < 3, isClosed {
            return fill(shapes[0], faces: faces, material: material)
        }
        var polygons = [Polygon]()
        polygons.reserveCapacity(shapes.reduce(0) { $0 + $1.points.count })
        var prev = shapes[0]
        var isCapped = true
        if !isClosed {
            let facePolygons = prev.facePolygons(material: material)
            if facePolygons.isEmpty {
                isCapped = false
            } else if let p0p1 = directionBetweenShapes(prev, shapes[1]) {
                polygons += facePolygons.map {
                    p0p1.dot($0.plane.normal) > 0 ? $0.inverted() : $0
                }
            } else {
                polygons += facePolygons
            }
        }
        var uvx0 = 0.0
        let uvstep = Double(1) / Double(count - 1)
        for shape in shapes.dropFirst() {
            let uvx1 = uvx0 + uvstep
            loft(
                unchecked: prev, shape,
                uvstart: uvx0, uvend: uvx1,
                verifiedCoplanar: verifiedCoplanar,
                material: material,
                into: &polygons
            )
            prev = shape
            uvx0 = uvx1
        }
        if !isClosed {
            let facePolygons = prev.facePolygons(material: material)
            if facePolygons.isEmpty {
                isCapped = false
            } else if let p0p1 = directionBetweenShapes(shapes[shapes.count - 2], prev) {
                polygons += facePolygons.map {
                    p0p1.dot($0.plane.normal) < 0 ? $0.inverted() : $0
                }
            } else {
                polygons += facePolygons
            }
        }
        let isWatertight = isCapped ? true : isWatertight
        if !isCapped, count > 1, let first = shapes.first, let last = shapes.last {
            isCapped = first.isClosed && first.hasZeroArea &&
                last.isClosed && last.hasZeroArea
        }
        switch faces {
        case .default where isCapped, .front:
            return Mesh(
                unchecked: polygons,
                bounds: nil, // TODO: can we calculate this efficiently?
                isConvex: isConvex,
                isWatertight: isWatertight
            )
        case .back:
            return Mesh(
                unchecked: polygons.inverted(),
                bounds: nil, // TODO: can we calculate this efficiently?
                isConvex: false,
                isWatertight: isWatertight
            )
        case .frontAndBack, .default:
            return Mesh(
                unchecked: polygons + polygons.inverted(),
                bounds: nil, // TODO: can we calculate this efficiently?
                isConvex: false,
                isWatertight: isWatertight
            )
        }
    }

    static func loft(
        unchecked p0: Path, _ p1: Path,
        uvstart: Double, uvend: Double,
        verifiedCoplanar: Bool,
        material: Material?,
        into polygons: inout [Polygon]
    ) {
        let invert: Bool
        if let p0p1 = directionBetweenShapes(p0, p1), p0p1.dot(p0.faceNormal) > 0 {
            invert = false
        } else {
            invert = true
        }
        let e0 = p0.edgeVertices, e1 = p1.edgeVertices
        // TODO: better handling of case where e0 and e1 counts don't match
        for j in stride(from: 0, to: min(e0.count, e1.count), by: 2) {
            var vertices = [e0[j], e0[j + 1], e1[j + 1], e1[j]]
            vertices[0].texcoord = Vector(vertices[0].texcoord.y, uvstart)
            vertices[1].texcoord = Vector(vertices[1].texcoord.y, uvstart)
            vertices[2].texcoord = Vector(vertices[2].texcoord.y, uvend)
            vertices[3].texcoord = Vector(vertices[3].texcoord.y, uvend)
            if vertices[0].position == vertices[1].position {
                vertices.remove(at: 0)
            } else if vertices[2].position == vertices[3].position {
                vertices.remove(at: 3)
            } else {
                if vertices[0].position == vertices[3].position {
                    vertices[0].normal = vertices[0].normal + vertices[3].normal // auto-normalized
                    vertices.remove(at: 3)
                }
                if vertices[1].position == vertices[2].position {
                    vertices[1].normal = vertices[1].normal + vertices[2].normal // auto-normalized
                    vertices.remove(at: 2)
                }
            }
            let degenerate = verifiedCoplanar ? false : verticesAreDegenerate(vertices)
            assert(!verifiedCoplanar || !verticesAreDegenerate(vertices))
            guard !degenerate else {
                // This is a hack to make the best of a bad edge case
                // TODO: find a better solution
                polygons += triangulateVertices(
                    vertices,
                    plane: nil,
                    isConvex: nil,
                    material: material,
                    id: 0
                )
                continue
            }
            let coplanar = verifiedCoplanar || verticesAreCoplanar(vertices)
            assert(!verifiedCoplanar || verticesAreCoplanar(vertices))
            if !coplanar {
                let vertices2 = [vertices[0], vertices[2], vertices[3]]
                vertices.remove(at: 3)
                polygons.append(Polygon(
                    unchecked: invert ? vertices2.reversed() : vertices2,
                    plane: nil,
                    isConvex: true,
                    material: material
                ))
            }
            polygons.append(Polygon(
                unchecked: invert ? vertices.reversed() : vertices,
                plane: nil,
                isConvex: nil,
                material: material
            ))
        }
    }
}
