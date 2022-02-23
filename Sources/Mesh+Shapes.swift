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

public extension Mesh {
    /// A choice of the face directions that Euclid generates for polygons.
    ///
    /// ## Topics
    ///
    /// ### Faces
    ///
    /// - ``Faces/default``
    /// - ``Faces/front``
    /// - ``Faces/back``
    /// - ``Faces/frontAndBack``
    ///
    /// ### Comparing Faces
    ///
    /// - ``Faces/!=(_:_:)``
    ///
    enum Faces {
        /// The default face generation behavior. Context-dependent.
        case `default`
        /// Generate front faces.
        case front
        /// Generate back faces.
        case back
        /// Generate both the front and back faces.
        case frontAndBack
    }

    /// A choice of how texture coordinates should be generated.
    ///
    /// ## Topics
    ///
    /// ### Wrap Modes
    ///
    /// - ``WrapMode/default``
    /// - ``WrapMode/shrink``
    /// - ``WrapMode/tube``
    ///
    /// ### Comparing Wrap modes
    ///
    /// - ``WrapMode/!=(_:_:)``
    ///
    enum WrapMode {
        /// The default wrap behavior. Context-dependent.
        case `default`
        /// Texture is shrink-wrapped.
        case shrink
        /// Texture is tube-wrapped.
        case tube
    }

    /// Creates an axis-aligned cuboidal mesh.
    /// - Parameters:
    ///   - center: The center point of the mesh.
    ///   - size: The size of the cuboid mesh.
    ///   - faces: The direction of the generated polygon faces.
    ///   - material: The optional material for the mesh.
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

    /// Creates an axis-aligned cubical mesh.
    /// - Parameters:
    ///   - center: The center point of the mesh.
    ///   - size: The size of the mesh.
    ///   - faces: The direction of the generated polygon faces.
    ///   - material: The optional material for the mesh.
    static func cube(
        center c: Vector = .init(0, 0, 0),
        size s: Double = 1,
        faces: Faces = .default,
        material: Material? = nil
    ) -> Mesh {
        cube(center: c, size: Vector(s, s, s), faces: faces, material: material)
    }

    /// Creates a spherical mesh.
    /// - Parameters:
    ///   - radius: The radius of the sphere.
    ///   - slices: The number of vertical slices that make up the sphere.
    ///   - stacks: The number of horizontal stacks that make up the sphere.
    ///   - poleDetail: Optionally add extra detail around poles to prevent texture warping
    ///   - faces: The direction the polygon faces.
    ///   - wrapMode: The mode in which texture coordinates are wrapped around the mesh.
    ///   - material: The optional material for the mesh.
    static func sphere(
        radius: Double = 0.5,
        slices: Int = 16,
        stacks: Int? = nil,
        poleDetail: Int = 0,
        faces: Faces = .default,
        wrapMode: WrapMode = .default,
        material: Material? = nil
    ) -> Mesh {
        var semicircle = [PathPoint]()
        let stacks = max(2, stacks ?? (slices / 2))
        let radius = max(abs(radius), epsilon)
        for i in 0 ... stacks {
            let a = Double(i) / Double(stacks) * Angle.pi
            semicircle.append(.curve(-sin(a) * radius, cos(a) * radius))
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

    /// Creates a cylindrical mesh.
    /// - Parameters:
    ///   - radius: The radius of the cylinder.
    ///   - height: The height of the cylinder.
    ///   - slices: The number of vertical slices that make up the cylinder.
    ///   - poleDetail: Optionally add extra detail around poles to prevent texture warping.
    ///   - faces: The direction of the generated polygon faces.
    ///   - wrapMode: The mode in which texture coordinates are wrapped around the mesh.
    ///   - material: The optional material for the mesh.
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

    /// Creates a conical mesh.
    /// - Parameters:
    ///   - radius: The radius of the cone.
    ///   - height: The height of the cone.
    ///   - slices: The number of vertical slices that make up the cone.
    ///   - poleDetail: Optionally add extra detail around top pole to prevent texture warping.
    ///   - addDetailAtBottomPole: Whether detail should be added at bottom pil.
    ///   - faces: The direction of the generated polygon faces.
    ///   - wrapMode: The mode in which texture coordinates are wrapped around the mesh.
    ///   - material: The optional material for the mesh.
    ///
    /// > Note: The default `nil` value for poleDetail will derive value automatically.
    /// Use zero instead if you wish to add no extra detail at the poles.
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

    /// Creates a rotationally symmetrical mesh by turning the specified path around the Y axis.
    ///
    /// * The profile path can be open or closed. Define a closed path by ending with
    ///   the same point that you started with.
    ///
    /// * The path can be placed on either side of the `Y` axis,
    ///   however the behavior is undefined for paths that cross the axis
    ///
    /// * Open paths that do not start and end on the `Y` axis will produce
    ///   a shape with a hole in it
    ///
    /// - Parameters:
    ///   - profile: The path to use as the profile for the mesh.
    ///   - slices: The number of slices that make up the lathed mesh.
    ///   - poleDetail: The number of segments used to make the pole.
    ///   - addDetailForFlatPoles: A Boolean value that indicates whether to add detail to the poles.
    ///   - faces: The direction of the generated polygon faces.
    ///   - wrapMode: The mode in which texture coordinates are wrapped around the mesh.
    ///   - material: The optional material for the mesh.
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

    /// Creates a mesh by extruding a path along its face normal.
    /// - Parameters:
    ///   - shape: The path to extrude in order to create the mesh.
    ///   - depth: The depth of the extrusion.
    ///   - faces: The direction of the generated polygon faces.
    ///   - material: The optional material for the mesh.
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

    /// Creates a mesh by extruding one path along another path.
    /// - Parameters:
    ///   - shape: The shape to extrude into a mesh.
    ///   - along: The path along which to extrude the shape.
    ///   - faces: The direction of the generated polygon faces.
    ///   - material: The optional material for the mesh.
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

    /// Creates a mesh by connecting a series of 3D paths representing the cross sections
    /// - Parameters:
    ///   - shapes: The paths to connect.
    ///   - faces: The direction of the generated polygon faces.
    ///   - material: The optional material for the mesh.
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

    /// Creates a mesh by filling a path to form one or more polygons.
    /// - Parameters:
    ///   - shape: The shape to be filled.
    ///   - faces: The direction the polygon faces.
    ///   - material: The optional material for the mesh.
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

    /// Creates a mesh by stroking a path with the line width, detail, and material you provide.
    /// - Parameters:
    ///   - shape: The path to stroke.
    ///   - width: The line width of the stroke.
    ///   - detail: The number of sides to use for the cross-sectional shape of the stroked mesh.
    ///   - material: The optional material for the mesh.
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

    /// Efficiently strokes a set of line segments (useful for drawing wireframes)
    /// - Parameters:
    ///   - lines: A collection of ``LineSegment`` to stroke.
    ///   - width: The line width of the strokes.
    ///   - detail: The number of sides to use for the cross-sectional shape of the stroked mesh.
    ///   - material: The optional material for the mesh.
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
