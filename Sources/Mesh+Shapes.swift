//
//  Mesh+Shapes.swift
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
    /// Alignment mode to use when extruding along a path.
    typealias Alignment = Path.Alignment

    /// The face generation policy for Euclid to use when creating a mesh.
    enum Faces: Sendable {
        /// The default face generation behavior. Context-dependent.
        case `default`
        /// Generate front faces.
        case front
        /// Generate back faces.
        case back
        /// Generate both the front and back faces.
        case frontAndBack
    }

    /// The texture wrapping mode to use when generating a mesh.
    enum WrapMode: Sendable {
        /// The default wrap behavior. Context-dependent.
        case `default`
        /// Texture is shrink-wrapped.
        case shrink
        /// Texture is tube-wrapped.
        case tube
        /// Do not generate texture coordinates.
        case none
    }

    /// Creates an axis-aligned cuboidal mesh.
    /// - Parameters:
    ///   - center: The center point of the mesh.
    ///   - size: The size of the cuboid mesh.
    ///   - faces: The direction of the generated polygon faces.
    ///   - wrapMode: The way that texture coordinates are calculated for the cube.
    ///   - material: The optional material for the mesh.
    static func cube(
        center: Vector = .zero,
        size: Vector,
        faces: Faces = .default,
        wrapMode: WrapMode = .default,
        material: Material? = nil
    ) -> Mesh {
        let coordinates: [(indices: [Int], normal: Vector)] = [
            ([5, 1, 3, 7], .unitX),
            ([0, 4, 6, 2], -.unitX),
            ([6, 7, 3, 2], .unitY),
            ([0, 1, 5, 4], -.unitY),
            ([4, 5, 7, 6], .unitZ),
            ([1, 0, 2, 3], -.unitZ),
        ]
        let polygons: [Polygon] = coordinates.map { indices, normal in
            Polygon(
                unchecked: indices.enumerated().map { index, i in
                    let pos = center + Vector(
                        i & 1 > 0 ? 0.5 : -0.5,
                        i & 2 > 0 ? 0.5 : -0.5,
                        i & 4 > 0 ? 0.5 : -0.5
                    ).scaled(by: size)
                    let texcoord = wrapMode == .default ? Vector(
                        (1 ... 2).contains(index) ? 1 : 0,
                        (0 ... 1).contains(index) ? 1 : 0
                    ) : .zero
                    return Vertex(unchecked: pos, normal, texcoord, nil)
                },
                normal: normal,
                isConvex: true,
                sanitizeNormals: false,
                material: material
            )
        }
        let halfSize = size / 2
        let bounds = Bounds(
            min: center - halfSize,
            max: center + halfSize
        )
        let mesh = switch faces {
        case .front, .default:
            Mesh(
                unchecked: polygons,
                bounds: bounds,
                bsp: nil,
                isConvex: true,
                isWatertight: true,
                submeshes: []
            )
        case .back:
            Mesh(
                unchecked: polygons.inverted(),
                bounds: bounds,
                bsp: nil,
                isConvex: false,
                isWatertight: true,
                submeshes: []
            )
        case .frontAndBack:
            Mesh(
                unchecked: polygons + polygons.inverted(),
                bounds: bounds,
                bsp: nil,
                isConvex: false,
                isWatertight: true,
                submeshes: []
            )
        }
        switch wrapMode {
        case .default, .none:
            return mesh
        case .shrink:
            return mesh.sphereMapped()
        case .tube:
            return mesh.cylinderMapped()
        }
    }

    /// Creates an axis-aligned cubical mesh.
    /// - Parameters:
    ///   - center: The center point of the mesh.
    ///   - size: The size of the mesh.
    ///   - faces: The direction of the generated polygon faces.
    ///   - wrapMode: The way that texture coordinates are calculated for the cube.
    ///   - material: The optional material for the mesh.
    static func cube(
        center: Vector = .zero,
        size: Double = 1,
        faces: Faces = .default,
        wrapMode: WrapMode = .default,
        material: Material? = nil
    ) -> Mesh {
        cube(center: center, size: Vector(size: size), faces: faces, wrapMode: wrapMode, material: material)
    }

    /// Creates an icosahedron.
    /// - Parameters:
    ///   - radius: The radius of the icosahedron.
    ///   - faces: The direction the polygon faces.
    ///   - wrapMode: The mode in which texture coordinates are wrapped around the mesh.
    ///   - material: The optional material for the mesh.
    static func icosahedron(
        radius: Double = 0.5,
        faces: Faces = .default,
        wrapMode: WrapMode = .default,
        material: Material? = nil
    ) -> Mesh {
        let t = 1 + sqrt(2) / 2
        let coordinates: [Vector] = [
            .init(-1, t, 0),
            .init(1, t, 0),
            .init(-1, -t, 0),
            .init(1, -t, 0),

            .init(0, -1, t),
            .init(0, 1, t),
            .init(0, -1, -t),
            .init(0, 1, -t),

            .init(t, 0, -1),
            .init(t, 0, 1),
            .init(-t, 0, -1),
            .init(-t, 0, 1),
        ]
        let transform = Transform(scale: radius / sqrt(t * t + 1), rotation: .pitch(.atan(t)))
        let v = coordinates.map { Vertex($0.transformed(by: transform)) }
        func triangle(_ a: Vertex, _ b: Vertex, _ c: Vertex) -> Polygon {
            Polygon(
                unchecked: [a, b, c],
                plane: nil,
                isConvex: true,
                sanitizeNormals: true,
                material: material
            )
        }
        let triangles = [
            // 5 faces around point 0
            triangle(v[0], v[11], v[5]),
            triangle(v[0], v[5], v[1]),
            triangle(v[0], v[1], v[7]),
            triangle(v[0], v[7], v[10]),
            triangle(v[0], v[10], v[11]),

            // 5 adjacent faces
            triangle(v[1], v[5], v[9]),
            triangle(v[5], v[11], v[4]),
            triangle(v[11], v[10], v[2]),
            triangle(v[10], v[7], v[6]),
            triangle(v[7], v[1], v[8]),

            // 5 faces around point 3
            triangle(v[3], v[9], v[4]),
            triangle(v[3], v[4], v[2]),
            triangle(v[3], v[2], v[6]),
            triangle(v[3], v[6], v[8]),
            triangle(v[3], v[8], v[9]),

            // 5 adjacent faces
            triangle(v[4], v[9], v[5]),
            triangle(v[2], v[4], v[11]),
            triangle(v[6], v[2], v[10]),
            triangle(v[8], v[6], v[7]),
            triangle(v[9], v[8], v[1]),
        ]
        let mesh: Mesh
        let bounds = Bounds(triangles)
        switch faces {
        case .front, .default:
            mesh = Mesh(
                unchecked: triangles,
                bounds: bounds,
                bsp: nil,
                isConvex: true,
                isWatertight: true,
                submeshes: []
            )
        case .back:
            mesh = Mesh(
                unchecked: triangles.inverted(),
                bounds: bounds,
                bsp: nil,
                isConvex: false,
                isWatertight: true,
                submeshes: []
            )
        case .frontAndBack:
            mesh = Mesh(
                unchecked: triangles + triangles.inverted(),
                bounds: bounds,
                bsp: nil,
                isConvex: false,
                isWatertight: true,
                submeshes: []
            )
        }
        switch wrapMode {
        case .default, .shrink:
            return mesh.sphereMapped()
        case .tube:
            return mesh.cylinderMapped()
        case .none:
            return mesh
        }
    }

    /// Creates a sphere by subdividing an icosahedron.
    /// - Parameters:
    ///   - radius: The radius of the icosphere.
    ///   - subdivisions: The number of times to subdivide (each iteration quadruples the triangle count).
    ///   - faces: The direction the polygon faces.
    ///   - wrapMode: The mode in which texture coordinates are wrapped around the mesh.
    ///   - material: The optional material for the mesh.
    ///   - isCancelled: Callback used to cancel the operation.
    static func icosphere(
        radius: Double = 0.5,
        subdivisions: Int = 2,
        faces: Faces = .default,
        wrapMode: WrapMode = .default,
        material: Material? = nil,
        isCancelled: CancellationHandler = { false }
    ) -> Mesh {
        let icosahedron = icosahedron(
            radius: 1,
            faces: faces,
            wrapMode: .none,
            material: material
        )
        var triangles = icosahedron.polygons
        for _ in 0 ..< subdivisions where !isCancelled() {
            triangles = triangles.subdivide()
        }
        triangles = triangles.mapVertices {
            let direction = $0.position.normalized()
            return $0.withPosition(direction * radius).withNormal(direction)
        }
        let mesh = Mesh(
            unchecked: triangles,
            bounds: Bounds(min: .init(size: -radius), max: .init(size: radius)),
            bsp: nil,
            isConvex: true,
            isWatertight: true,
            submeshes: []
        )
        switch wrapMode {
        case .default, .shrink:
            return mesh.sphereMapped()
        case .tube:
            return mesh.cylinderMapped()
        case .none:
            return mesh
        }
    }

    /// Creates a spherical mesh.
    /// - Parameters:
    ///   - radius: The radius of the sphere.
    ///   - slices: The number of vertical slices that make up the sphere.
    ///   - stacks: The number of horizontal stacks that make up the sphere.
    ///   - poleDetail: Optionally add extra detail around poles to prevent texture warping
    ///   - faces: The direction the polygon faces.
    ///   - wrapMode: The way that texture coordinates are calculated for the sphere.
    ///   - material: The optional material for the mesh.
    ///   - isCancelled: Callback used to cancel the operation.
    static func sphere(
        radius: Double = 0.5,
        slices: Int = 16,
        stacks: Int? = nil,
        poleDetail: Int = 0,
        faces: Faces = .default,
        wrapMode: WrapMode = .default,
        material: Material? = nil,
        isCancelled: CancellationHandler = { false }
    ) -> Mesh {
        let stacks = max(2, stacks ?? (slices / 2))
        return lathe(
            unchecked: .arc(radius: radius, segments: stacks, isCancelled: isCancelled),
            slices: slices,
            poleDetail: poleDetail,
            addDetailForFlatPoles: false,
            faces: faces,
            wrapMode: wrapMode,
            material: material,
            isConvex: true,
            isWatertight: true,
            isCancelled: isCancelled
        )
    }

    /// Creates a cylindrical mesh.
    /// - Parameters:
    ///   - radius: The radius of the cylinder.
    ///   - height: The height of the cylinder.
    ///   - slices: The number of vertical slices that make up the cylinder.
    ///   - poleDetail: Optionally add extra detail around poles to prevent texture warping.
    ///   - faces: The direction of the generated polygon faces.
    ///   - wrapMode: The way that texture coordinates are calculated for the cylinder.
    ///   - material: The optional material for the mesh.
    ///   - isCancelled: Callback used to cancel the operation.
    static func cylinder(
        radius: Double = 0.5,
        height: Double = 1,
        slices: Int = 16,
        poleDetail: Int = 0,
        faces: Faces = .default,
        wrapMode: WrapMode = .default,
        material: Material? = nil,
        isCancelled: CancellationHandler = { false }
    ) -> Mesh {
        let radius = max(abs(radius), scaleLimit / 2)
        let wrapMode = wrapMode == .default ? .tube : wrapMode
        return lathe(
            unchecked: Path(unchecked: abs(height) > scaleLimit ? [
                .point(0, height / 2),
                .point(-radius, height / 2),
                .point(-radius, -height / 2),
                .point(0, -height / 2),
            ] : [
                .point(0, 0),
                .point(-radius, 0),
                .point(0, 0),
            ], plane: .xy),
            slices: slices,
            poleDetail: poleDetail,
            addDetailForFlatPoles: true,
            faces: faces,
            wrapMode: wrapMode,
            material: material,
            isConvex: true,
            isWatertight: true,
            isCancelled: isCancelled
        )
    }

    /// Creates a conical mesh.
    /// - Parameters:
    ///   - radius: The radius of the cone.
    ///   - height: The height of the cone.
    ///   - slices: The number of vertical slices that make up the cone.
    ///   - stacks: The number of horizontal stacks that make up the cone.
    ///   - poleDetail: Optionally add extra detail around top pole to prevent texture warping.
    ///   - addDetailAtBottomPole: Whether detail should be added at bottom pole.
    ///   - faces: The direction of the generated polygon faces.
    ///   - wrapMode: The way that texture coordinates are calculated for the cone.
    ///   - material: The optional material for the mesh.
    ///   - isCancelled: Callback used to cancel the operation.
    ///
    /// > Note: The default `nil` value for poleDetail will derive value automatically.
    /// Use zero instead if you wish to add no extra detail at the poles.
    static func cone(
        radius: Double = 0.5,
        height: Double = 1,
        slices: Int = 16,
        stacks: Int = 1,
        poleDetail: Int? = nil,
        addDetailAtBottomPole: Bool = false,
        faces: Faces = .default,
        wrapMode: WrapMode = .default,
        material: Material? = nil,
        isCancelled: CancellationHandler = { false }
    ) -> Mesh {
        let radius = max(abs(radius), scaleLimit / 2)
        let stacks = max(1, stacks)
        let ystep = height / Double(stacks), xstep = radius / Double(stacks)
        let points = (0 ... stacks).map { i -> PathPoint in
            .point(Double(i) * xstep, height / 2 - Double(i) * ystep)
        } + [.point(0, -height / 2)]
        return lathe(
            unchecked: Path(unchecked: points, plane: .xy),
            slices: slices,
            poleDetail: poleDetail ?? 3,
            addDetailForFlatPoles: addDetailAtBottomPole,
            faces: faces,
            wrapMode: wrapMode == .default ? .tube : wrapMode,
            material: material,
            isConvex: true,
            isWatertight: true,
            isCancelled: isCancelled
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
    ///   - wrapMode: The way that texture coordinates are calculated for the lathed mesh.
    ///   - material: The optional material for the mesh.
    ///   - isCancelled: Callback used to cancel the operation.
    static func lathe(
        _ profile: Path,
        slices: Int = 16,
        poleDetail: Int = 0,
        addDetailForFlatPoles: Bool = false,
        faces: Faces = .default,
        wrapMode: WrapMode = .default,
        material: Material? = nil,
        isCancelled: CancellationHandler = { false }
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
            isWatertight: nil, // TODO: Can we work this out?
            isCancelled: isCancelled
        )
    }

    /// Creates a mesh by extruding a path along its face normal.
    /// - Parameters:
    ///   - shape: The path to extrude in order to create the mesh.
    ///   - depth: The depth of the extrusion.
    ///   - twist: Angular twist to apply along the extrusion.
    ///   - sections: Number of sections to create along extrusion.
    ///   - faces: The direction of the generated polygon faces.
    ///   - material: The optional material for the mesh.
    ///   - isCancelled: Callback used to cancel the operation.
    static func extrude(
        _ shape: Path,
        depth: Double = 1,
        twist: Angle = .zero,
        sections: Int = 0,
        faces: Faces = .default,
        material: Material? = nil,
        isCancelled: CancellationHandler = { false }
    ) -> Mesh {
        let depth = abs(depth)
        if depth < scaleLimit {
            return fill(shape, faces: faces, material: material, isCancelled: isCancelled)
        }
        let faceNormal = shape.faceNormal
        let offset = faceNormal * depth
        let sections = max(1, sections)
        let step = offset / Double(sections)
        let rotation = Rotation(unchecked: faceNormal, angle: twist / Double(sections))
        var shape = shape.translated(by: -offset / 2)
        var shapes = [shape]
        for _ in 0 ..< sections {
            shape.translate(by: step)
            shape.rotate(by: rotation)
            shapes.append(shape)
        }
        let polygon = Polygon(shape)
        return loft(
            shapes,
            faces: faces,
            material: material,
            isConvex: polygon?.isConvex == true,
            isWatertight: polygon.map { _ in true }, // TODO: make less strict
            isCancelled: isCancelled
        )
    }

    /// Efficiently extrudes an array of paths along their respective face normals, avoiding duplicate work.
    /// - Parameters:
    ///   - shapes: The collection of paths to extrude in order to create the mesh.
    ///   - depth: The depth of the extrusion.
    ///   - twist: Angular twist to apply along the extrusion.
    ///   - sections: Number of sections to create along extrusion.
    ///   - faces: The direction of the generated polygon faces.
    ///   - material: The optional material for the mesh.
    ///   - isCancelled: Callback used to cancel the operation.
    static func extrude(
        _ shapes: some Collection<Path>,
        depth: Double = 1,
        twist: Angle = .zero,
        sections: Int = 0,
        faces: Faces = .default,
        material: Material? = nil,
        isCancelled: CancellationHandler = { false }
    ) -> Mesh {
        let material = SendableMaterial(material)
        return .union(build(shapes, using: {
            extrude(
                $0,
                depth: depth,
                twist: twist,
                sections: sections,
                faces: faces,
                material: material.value,
                isCancelled: isCancelled
            )
        }, isCancelled: isCancelled), isCancelled: isCancelled)
    }

    /// Creates a mesh by extruding one path along another path.
    /// - Parameters:
    ///   - shape: The shape to extrude into a mesh.
    ///   - along: The path along which to extrude the shape.
    ///   - twist: Angular twist to apply along the extrusion.
    ///   - align: The alignment mode to use for the extruded shape.
    ///   - faces: The direction of the generated polygon faces.
    ///   - material: The optional material for the mesh.
    ///   - isCancelled: Callback used to cancel the operation.
    static func extrude(
        _ shape: Path,
        along: Path,
        twist: Angle = .zero,
        align: Alignment = .default,
        faces: Faces = .default,
        material: Material? = nil,
        isCancelled: CancellationHandler = { false }
    ) -> Mesh {
        let subpaths = along.subpaths
        guard subpaths.count == 1 else {
            let material = SendableMaterial(material)
            return .merge(build(subpaths, using: {
                extrude(
                    shape,
                    along: $0,
                    twist: twist,
                    align: align,
                    faces: faces,
                    material: material.value,
                    isCancelled: isCancelled
                )
            }, isCancelled: isCancelled))
        }
        let shapeGroups = (shape.nonZeroFillBoundaryForLoft() ?? shape).filledSubpathGroups()
        if shapeGroups.count > 1 {
            let material = SendableMaterial(material)
            let meshes = batch(shapeGroups, stride: 1) {
                $0.map { shape in
                    isCancelled() ? .empty : loft(
                        shape.extrusionContours(
                            along: along,
                            twist: twist,
                            align: align
                        ),
                        faces: faces,
                        material: material.value,
                        isCancelled: isCancelled
                    )
                }
            }
            return .merge(meshes)
        }
        return loft(shape.extrusionContours(
            along: along,
            twist: twist,
            align: align
        ), faces: faces, material: material)
    }

    /// Creates a mesh by connecting a series of 3D paths representing the cross sections.
    /// - Parameters:
    ///   - shapes: The paths to connect.
    ///   - faces: The direction of the generated polygon faces.
    ///   - material: The optional material for the mesh.
    ///   - isCancelled: Callback used to cancel the operation.
    static func loft(
        _ shapes: [Path],
        faces: Faces = .default,
        material: Material? = nil,
        isCancelled: CancellationHandler = { false }
    ) -> Mesh {
        loft(
            shapes,
            faces: faces,
            material: material,
            isConvex: false,
            isWatertight: nil,
            isCancelled: isCancelled
        )
    }

    /// Creates a mesh by filling a path to form one or more polygons.
    /// - Parameters:
    ///   - shape: The shape to be filled.
    ///   - faces: The direction the polygon faces.
    ///   - material: The optional material for the mesh.
    ///   - isCancelled: Callback used to cancel the operation.
    static func fill(
        _ shape: Path,
        faces: Faces = .default,
        material: Material? = nil,
        isCancelled: CancellationHandler = { false }
    ) -> Mesh {
        let shape = shape.closed()
        let subpaths = shape.subpaths
        if subpaths.count > 1 {
            if let boundary = shape.nonZeroFillBoundaryForLoft(), boundary != shape {
                return fill(boundary, faces: faces, material: material, isCancelled: isCancelled)
            }
            return .symmetricDifference(subpaths.map {
                .fill($0, faces: faces, material: material, isCancelled: isCancelled)
            }, isCancelled: isCancelled)
        }
        let polygons = shape.facePolygons(material: material)
        let isConvex = polygons.count == 1 && polygons[0].isConvex
        let mesh = switch faces {
        case .front:
            Mesh(
                unchecked: polygons,
                bounds: nil,
                bsp: nil,
                isConvex: isConvex, // A single polygon counts as convex
                isWatertight: false,
                submeshes: []
            )
        case .back:
            Mesh(
                unchecked: polygons.inverted(),
                bounds: nil,
                bsp: nil,
                isConvex: isConvex, // A single polygon counts as convex
                isWatertight: false,
                submeshes: []
            )
        case .frontAndBack, .default:
            Mesh(
                unchecked: polygons + polygons.inverted(),
                bounds: nil,
                bsp: nil,
                isConvex: isConvex,
                isWatertight: true,
                submeshes: []
            )
        }
        return shape.usesNonZeroFill ? mesh.detessellate() : mesh
    }

    /// Efficiently fills an array of paths, avoiding unnecessary work if there are duplicates.
    /// - Parameters:
    ///   - shapes: The array of paths to be filled.
    ///   - faces: The direction the polygon faces.
    ///   - material: The optional material for the mesh.
    ///   - isCancelled: Callback used to cancel the operation.
    static func fill(
        _ shapes: [Path],
        faces: Faces = .default,
        material: Material? = nil,
        isCancelled: CancellationHandler = { false }
    ) -> Mesh {
        let material = SendableMaterial(material)
        return .union(build(shapes, using: {
            fill($0, faces: faces, material: material.value, isCancelled: isCancelled)
        }, isCancelled: isCancelled), isCancelled: isCancelled)
    }

    /// Creates a mesh by stroking a path with the line width, detail, and material you provide.
    /// - Parameters:
    ///   - shape: The path to stroke.
    ///   - width: The line width of the stroke.
    ///   - detail: The number of sides to use for the cross-sectional shape of the stroked mesh.
    ///   - material: The optional material for the mesh.
    ///   - isCancelled: Callback used to cancel the operation.
    static func stroke(
        _ shape: Path,
        width: Double = 0.01,
        detail: Int = 2,
        material: Material? = nil,
        isCancelled: CancellationHandler = { false }
    ) -> Mesh {
        let path: Path
        let radius = width / 2
        switch detail {
        case 1, 2:
            path = .line([-radius, 0], [radius, 0])
        case let sides:
            path = .circle(radius: radius, segments: sides)
        }
        let faces: Faces = detail == 2 ? .frontAndBack : .front
        return extrude(
            path,
            along: shape,
            faces: faces,
            material: material,
            isCancelled: isCancelled
        )
    }

    /// Efficiently strokes an array of paths, avoiding duplicate work.
    /// - Parameters:
    ///   - shapes: The paths to stroke.
    ///   - width: The line width of the stroke.
    ///   - detail: The number of sides to use for the cross-sectional shape of each stroked mesh.
    ///   - material: The optional material for the mesh.
    ///   - isCancelled: Callback used to cancel the operation.
    static func stroke(
        _ shapes: some Collection<Path>,
        width: Double = 0.01,
        detail: Int = 2,
        material: Material? = nil,
        isCancelled: CancellationHandler = { false }
    ) -> Mesh {
        let material = SendableMaterial(material)
        return .union(build(shapes, using: {
            stroke(
                $0,
                width: width,
                detail: detail,
                material: material.value,
                isCancelled: isCancelled
            )
        }, isCancelled: isCancelled), isCancelled: isCancelled)
    }

    /// Efficiently strokes a collection of line segments (useful for drawing wireframes).
    /// - Parameters:
    ///   - lines: A collection of ``LineSegment`` to stroke.
    ///   - width: The line width of the strokes.
    ///   - detail: The number of sides to use for the cross-sectional shape of the stroked mesh.
    ///   - material: The optional material for the mesh.
    ///   - isCancelled: Callback used to cancel the operation.
    static func stroke(
        _ lines: some Collection<LineSegment>,
        width: Double = 0.002,
        detail: Int = 3,
        material: Material? = nil,
        isCancelled: CancellationHandler = { false }
    ) -> Mesh {
        let radius = width / 2
        let detail = max(3, detail)
        let path = Path.circle(radius: radius, segments: detail)
        var bounds = Bounds.empty
        var polygons = [Polygon]()
        polygons.reserveCapacity(detail * lines.count)
        for line in lines where !isCancelled() {
            var shape = path
            if FlatteningPlane(normal: line.direction) == .xy {
                shape.rotate(by: .pitch(.halfPi))
            }
            shape.rotate(by: rotationBetweenNormalizedVectors(shape.faceNormal, line.direction))
            let shape0 = shape.translated(by: line.start)
            bounds.formUnion(shape0.bounds)
            let shape1 = shape.translated(by: line.end)
            bounds.formUnion(shape1.bounds)
            loft(
                unchecked: shape0, shape1,
                curvestart: true, curveend: true,
                uvstart: 0, uvend: 1,
                material: material,
                into: &polygons
            )
        }
        return Mesh(
            unchecked: polygons,
            bounds: bounds,
            bsp: nil,
            isConvex: false,
            isWatertight: nil,
            submeshes: nil
        )
    }
}

private extension Collection<Path> {
    func normalizingCompoundPathsForLoft() -> (shapes: [Path], isNonZeroBoundary: Bool) {
        guard let first,
              let boundary = first.nonZeroFillBoundaryForLoft()
        else {
            return (map { shape in
                guard let boundary = shape.nonZeroFillBoundaryForLoft()
                else {
                    return shape
                }
                return boundary
            }, contains { $0.nonZeroFillBoundaryForLoft() != nil })
        }
        var normalizedShapes = [Path]()
        normalizedShapes.reserveCapacity(count)
        for shape in self {
            guard let transform = shape.sectionTransform(relativeTo: first)
            else {
                return (map { shape in
                    guard let boundary = shape.nonZeroFillBoundaryForLoft()
                    else {
                        return shape
                    }
                    return boundary
                }, false)
            }
            normalizedShapes.append(boundary.mapPoints {
                $0.withPosition(transform($0.position))
            })
        }
        return (normalizedShapes, true)
    }
}

private extension Path {
    func filledSubpathGroups() -> [Path] {
        let subpaths = subpaths.filter { !$0.isEmpty }
        guard subpaths.count > 1 else {
            return subpaths
        }

        struct Entry {
            let point: Vector?
            let bounds: Bounds
            let polygon: Polygon?
        }

        let entries = subpaths.map {
            Entry(point: $0.points.first?.position, bounds: $0.bounds, polygon: Polygon($0))
        }
        let containers = entries.indices.map { index in
            entries.indices.filter { otherIndex in
                guard otherIndex != index,
                      let point = entries[index].point,
                      entries[otherIndex].bounds.intersects(point),
                      entries[otherIndex].polygon?.intersects(point) == true
                else {
                    return false
                }
                return true
            }
        }
        let depths = containers.map(\.count)
        let outerIndexes = entries.indices.filter { depths[$0].isMultiple(of: 2) }
        guard outerIndexes.count > 1 else {
            return [self]
        }

        return outerIndexes.map { outerIndex in
            let group = entries.indices.filter { index in
                if index == outerIndex {
                    return true
                }
                guard !depths[index].isMultiple(of: 2),
                      depths[index] == depths[outerIndex] + 1
                else {
                    return false
                }
                return containers[index].contains(outerIndex)
            }
            return Path(subpaths: group.sorted().map { subpaths[$0] })
        }
    }

    func nonZeroFillBoundaryForLoft() -> Path? {
        guard isClosed, let boundary = nonZeroFillBoundary() else {
            return nil
        }
        if subpaths.count == 1 {
            return usesNonZeroFill || (pointsAreAllCurved && boundary.subpathsShareVertices) ? boundary : nil
        }
        if hasCurvedPoints {
            return subpathsShareVertices ? boundary : nil
        }
        let preservesSubpaths = boundary.subpaths.count == subpaths.count
        return boundary.subpaths.count > 1 && (
            !subpathsShareVertices || subpathsSharePoints ||
                (subpathsHaveConsistentWinding && preservesSubpaths)
        ) ? boundary : nil
    }

    var hasCurvedPoints: Bool {
        points.contains { $0.isCurved }
    }

    var pointsAreAllCurved: Bool {
        let points = points.dropLast(isClosed ? 1 : 0)
        return !points.isEmpty && points.allSatisfy(\.isCurved)
    }

    var subpathsShareVertices: Bool {
        var previousEdges = [LineSegment]()
        var vertices = Set<Vector>()
        for subpath in subpaths {
            let positions = subpath.points.dropLast(subpath.isClosed ? 1 : 0).map(\.position)
            for position in positions {
                guard vertices.insert(position).inserted else {
                    return true
                }
            }
            for edge in subpath.orderedEdges {
                if previousEdges.contains(where: {
                    lineIntersection(edge.start, edge.end, true, $0.start, $0.end, true) != nil
                }) {
                    return true
                }
            }
            previousEdges += subpath.orderedEdges
        }
        return false
    }

    var subpathsSharePoints: Bool {
        var vertices = Set<Vector>()
        for subpath in subpaths {
            let positions = subpath.points.dropLast(subpath.isClosed ? 1 : 0).map(\.position)
            for position in positions {
                guard vertices.insert(position).inserted else {
                    return true
                }
            }
        }
        return false
    }

    var subpathsHaveConsistentWinding: Bool {
        let subpaths = subpaths.filter { $0.isClosed && !$0.hasZeroArea }
        guard let first = subpaths.first else {
            return false
        }
        let isClockwise = flattenedPointsAreClockwise(first.flattened().points.map(\.position))
        return subpaths.dropFirst().allSatisfy {
            flattenedPointsAreClockwise($0.flattened().points.map(\.position)) == isClockwise
        }
    }

    func sectionTransform(relativeTo other: Path) -> ((Vector) -> Vector)? {
        if self == other {
            return { $0 }
        }
        let points = points.map(\.position)
        let otherPoints = other.points.map(\.position)
        guard points.count == otherPoints.count,
              let first = points.first,
              let otherFirst = otherPoints.first
        else {
            return nil
        }

        guard let xIndex = otherPoints.indices.dropFirst().first(where: {
            !otherPoints[$0].isApproximatelyEqual(to: otherFirst)
        }) else {
            return { _ in first }
        }
        let sourceU = otherPoints[xIndex] - otherFirst
        let targetU = points[xIndex] - first
        let sourceNormal = other.faceNormal.normalized()
        let targetNormal = faceNormal.normalized()
        guard sourceU != .zero, targetU != .zero,
              sourceNormal != .zero, targetNormal != .zero
        else {
            return nil
        }

        guard let yIndex = otherPoints.indices.dropFirst().first(where: {
            let sourceV = otherPoints[$0] - otherFirst
            return sourceU.cross(sourceV).length > epsilon
        }) else {
            return nil
        }
        let sourceV = otherPoints[yIndex] - otherFirst
        let targetV = points[yIndex] - first
        let sourceUU = sourceU.dot(sourceU)
        let sourceUV = sourceU.dot(sourceV)
        let sourceVV = sourceV.dot(sourceV)
        let denominator = sourceUU * sourceVV - sourceUV * sourceUV
        guard abs(denominator) > epsilon else {
            return nil
        }

        let transform: (Vector) -> Vector = { point in
            let p = point - otherFirst
            let pU = p.dot(sourceU)
            let pV = p.dot(sourceV)
            let u = (pU * sourceVV - pV * sourceUV) / denominator
            let v = (pV * sourceUU - pU * sourceUV) / denominator
            let w = p.dot(sourceNormal)
            return first + targetU * u + targetV * v + targetNormal * w
        }
        for (point, otherPoint) in zip(points, otherPoints) {
            guard point.isApproximatelyEqual(to: transform(otherPoint), absoluteTolerance: 1e-6) else {
                return nil
            }
        }
        return transform
    }
}

private extension Mesh {
    static func lathe(
        unchecked profile: Path,
        slices: Int,
        poleDetail: Int,
        addDetailForFlatPoles: Bool,
        faces: Faces,
        wrapMode: WrapMode,
        material: Material?,
        isConvex: Bool,
        isWatertight: Bool?,
        isCancelled: CancellationHandler
    ) -> Mesh {
        let subpaths = profile.subpaths
        if subpaths.count > 1 {
            if let boundary = profile.closed().nonZeroFillBoundaryForLoft() {
                return .merge(boundary.subpaths.map {
                    .lathe(
                        $0,
                        slices: slices,
                        poleDetail: poleDetail,
                        addDetailForFlatPoles: addDetailForFlatPoles,
                        faces: faces,
                        wrapMode: wrapMode,
                        material: material,
                        isCancelled: isCancelled
                    )
                })
            }
            return .symmetricDifference(subpaths.map {
                .lathe(
                    $0,
                    slices: slices,
                    poleDetail: poleDetail,
                    addDetailForFlatPoles: addDetailForFlatPoles,
                    faces: faces,
                    wrapMode: wrapMode,
                    material: material,
                    isCancelled: isCancelled
                )
            }, isCancelled: isCancelled)
        }

        // normalize profile
        let profile = profile.latheProfile
        if profile.points.count < 2 {
            return .empty
        }

        // min slices
        let slices = max(3, slices)

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
                if abs(v0.position.x) < epsilon {
                    if v1.position.x != 0, addDetailForFlatPoles || !isVertical(v0.normal) {
                        let s = subdivide(poleDetail, v0, v1)
                        vertices.replaceSubrange(i ... i + 1, with: s)
                        i += s.count - 2
                    }
                } else if abs(v1.position.x) < 0, addDetailForFlatPoles || !isVertical(v1.normal) {
                    let s = subdivide(poleDetail, v1, v0).reversed()
                    vertices.replaceSubrange(i ... i + 1, with: s)
                    i += s.count - 2
                }
                i += 2
            }
        }

        var polygons = [Polygon]()
        var completedSlices = 0
        for i in 0 ..< slices {
            if isCancelled() { break }
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
                if abs(v0.position.x) < epsilon {
                    if abs(v1.position.x) >= epsilon {
                        // top triangle
                        let v0 = Vertex(
                            unchecked: v0.position,
                            [cos0 * v0.normal.x, v0.normal.y, sin0 * -v0.normal.x],
                            [v0.texcoord.x + (t0 + t1) / 2, v0.texcoord.y, 0],
                            v0.color
                        )
                        let v2 = Vertex(
                            unchecked:
                            [cos0 * v1.position.x, v1.position.y, sin0 * -v1.position.x],
                            [cos0 * v1.normal.x, v1.normal.y, sin0 * -v1.normal.x],
                            [v1.texcoord.x + t0, v1.texcoord.y, 0],
                            v1.color
                        )
                        let v3 = Vertex(
                            unchecked:
                            [cos1 * v1.position.x, v1.position.y, sin1 * -v1.position.x],
                            [cos1 * v1.normal.x, v1.normal.y, sin1 * -v1.normal.x],
                            [v1.texcoord.x + t1, v1.texcoord.y, 0],
                            v1.color
                        )
                        polygons.append(Polygon(
                            unchecked: [v0, v2, v3],
                            plane: nil,
                            isConvex: true,
                            sanitizeNormals: false,
                            material: material
                        ))
                    }
                } else if abs(v1.position.x) < epsilon {
                    // bottom triangle
                    let v1 = Vertex(
                        unchecked: v1.position,
                        [cos0 * v1.normal.x, v1.normal.y, sin0 * -v1.normal.x],
                        [v1.texcoord.x + (t0 + t1) / 2, v1.texcoord.y, 0],
                        v1.color
                    )
                    let v2 = Vertex(
                        unchecked: [cos1 * v0.position.x, v0.position.y, sin1 * -v0.position.x],
                        [cos1 * v0.normal.x, v0.normal.y, sin1 * -v0.normal.x],
                        [v0.texcoord.x + t1, v0.texcoord.y, 0],
                        v0.color
                    )
                    let v3 = Vertex(
                        unchecked: [cos0 * v0.position.x, v0.position.y, sin0 * -v0.position.x],
                        [cos0 * v0.normal.x, v0.normal.y, sin0 * -v0.normal.x],
                        [v0.texcoord.x + t0, v0.texcoord.y, 0],
                        v0.color
                    )
                    polygons.append(Polygon(
                        unchecked: [v2, v3, v1],
                        plane: nil,
                        isConvex: true,
                        sanitizeNormals: false,
                        material: material
                    ))
                } else {
                    // quad face
                    let v2 = Vertex(
                        unchecked: [cos1 * v0.position.x, v0.position.y, sin1 * -v0.position.x],
                        [cos1 * v0.normal.x, v0.normal.y, sin1 * -v0.normal.x],
                        [v0.texcoord.x + t1, v0.texcoord.y, 0],
                        v0.color
                    )
                    let v3 = Vertex(
                        unchecked: [cos0 * v0.position.x, v0.position.y, sin0 * -v0.position.x],
                        [cos0 * v0.normal.x, v0.normal.y, sin0 * -v0.normal.x],
                        [v0.texcoord.x + t0, v0.texcoord.y, 0],
                        v0.color
                    )
                    let v4 = Vertex(
                        unchecked: [cos0 * v1.position.x, v1.position.y, sin0 * -v1.position.x],
                        [cos0 * v1.normal.x, v1.normal.y, sin0 * -v1.normal.x],
                        [v1.texcoord.x + t0, v1.texcoord.y, 0],
                        v1.color
                    )
                    let v5 = Vertex(
                        unchecked: [cos1 * v1.position.x, v1.position.y, sin1 * -v1.position.x],
                        [cos1 * v1.normal.x, v1.normal.y, sin1 * -v1.normal.x],
                        [v1.texcoord.x + t1, v1.texcoord.y, 0],
                        v1.color
                    )
                    let vertices = [v2, v3, v4, v5]
                    if !verticesAreDegenerate(vertices) {
                        polygons.append(Polygon(
                            unchecked: vertices,
                            plane: nil,
                            isConvex: true,
                            sanitizeNormals: false,
                            material: material
                        ))
                    }
                }
            }
            completedSlices += 1
        }

        let wasCancelled = completedSlices < slices
        let isConvex = isConvex && !wasCancelled
        let isSealed = isConvex && !pointsAreSelfIntersecting(profile.points.map(\.position))
        let isWatertight = wasCancelled ? nil : isSealed ? true : isWatertight
        switch faces {
        case .default where isSealed, .front:
            return Mesh(
                unchecked: polygons,
                bounds: nil, // TODO: can we calculate this efficiently?
                bsp: nil,
                isConvex: isConvex,
                isWatertight: isWatertight,
                submeshes: nil // TODO: Can we calculate this efficiently?
            )
        case .back:
            return Mesh(
                unchecked: polygons.inverted(),
                bounds: nil, // TODO: can we calculate this efficiently?
                bsp: nil,
                isConvex: false,
                isWatertight: isWatertight,
                submeshes: nil // TODO: Can we calculate this efficiently?
            )
        case .frontAndBack:
            return Mesh(
                unchecked: polygons + polygons.inverted(),
                bounds: nil, // TODO: can we calculate this efficiently?
                bsp: nil,
                isConvex: false,
                isWatertight: isWatertight,
                submeshes: nil // TODO: Can we calculate this efficiently?
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
                bsp: nil,
                isConvex: false,
                isWatertight: isWatertight,
                submeshes: nil // TODO: Can we calculate this efficiently?
            )
        }
    }

    static func directionBetweenShapes(_ s0: Path, _ s1: Path) -> Vector {
        (s1.bounds.center - s0.bounds.center).normalized()
    }

    static func compoundLoft(
        originalShapes: [Path],
        boundarySubshapes: [[Path]],
        faces: Faces,
        material: Material?,
        isCancelled: CancellationHandler
    ) -> Mesh {
        let faceNormal = originalShapes.first?.faceNormal ?? .zero
        let shapes = originalShapes.filter { !$0.isEmpty }
        let first = shapes.first
        let firstBoundary = first?.nonZeroFillBoundary()
        let firstFacePolygons = firstBoundary?.facePolygons(material: material) ??
            first?.facePolygons(material: material) ?? []
        let firstCapPolygons: [Polygon] = first.flatMap { first in
            shapes.first(where: { $0 != first }).map { next in
                let p0p1 = directionBetweenShapes(first, next)
                return firstFacePolygons.map {
                    p0p1.dot($0.plane.normal) >= 0 ? $0.inverted() : $0
                }
            }
        } ?? []
        let capNormal = firstCapPolygons.first?.plane.normal ?? faceNormal
        let transforms = first.map { first in
            shapes.map { $0.sectionTransform(relativeTo: first) }
        } ?? []
        let canBuildMappedSides = transforms.allSatisfy { $0 != nil }
        var polygons: [Polygon]
        if canBuildMappedSides, let boundary = firstBoundary {
            polygons = []
            func transformedVertex(_ vertex: Vertex, by transform: (Vector) -> Vector) -> Vertex {
                let position = transform(vertex.position)
                let normal = vertex.normal == .zero ? .zero :
                    (transform(vertex.position + vertex.normal) - position).normalized()
                return Vertex(unchecked: position, normal, vertex.texcoord, vertex.color)
            }
            func sidePolygons(_ vertices: [Vertex]) -> [Polygon] {
                guard !verticesAreDegenerate(vertices) else {
                    return triangulateVertices(
                        vertices,
                        plane: nil,
                        isConvex: nil,
                        sanitizeNormals: true,
                        material: material,
                        id: 0
                    )
                }
                func triangulatedSidePolygons(_ vertices: [Vertex]) -> [Polygon] {
                    triangulateVertices(
                        vertices,
                        plane: nil,
                        isConvex: nil,
                        sanitizeNormals: false,
                        material: material,
                        id: 0
                    ).withVertexNormalsFacingPlane()
                }
                if vertices.count == 4 {
                    let c = vertices[0], d = vertices[1], b = vertices[2], a = vertices[3]
                    guard let bcd = Polygon([b, c, d], material: material) else {
                        return triangulatedSidePolygons([c, d, b, a])
                    }
                    switch a.position.compare(with: bcd.plane) {
                    case .coplanar, .spanning:
                        return Polygon([c, d, b, a], material: material)
                            .map { [$0.withVertexNormalsFacingPlane()] } ??
                            triangulatedSidePolygons([c, d, b, a])
                    case .back:
                        let polygons = [Polygon([c, b, a], material: material), bcd].compactMap { $0 }
                        return polygons.count == 2 ? polygons : triangulatedSidePolygons([c, d, b, a])
                    case .front:
                        let polygons = [
                            Polygon([c, d, a], material: material),
                            Polygon([b, a, d], material: material),
                        ].compactMap { $0 }
                        return polygons.count == 2 ? polygons : triangulatedSidePolygons([c, d, b, a])
                    }
                } else if let polygon = Polygon(vertices, material: material) {
                    return [polygon]
                }
                return []
            }
            for boundarySubpath in boundary.subpaths {
                let boundaryVertices = boundarySubpath.edgeVertices(
                    for: .default,
                    resolvingNonZeroFill: false
                )
                var loopPolygons = [Polygon]()
                func capUsesBoundaryEdgeForward(_ edge: LineSegment) -> Bool? {
                    for polygon in firstCapPolygons {
                        for capEdge in polygon.orderedEdges {
                            if capEdge.start == edge.start, capEdge.end == edge.end {
                                return true
                            }
                            if capEdge.start == edge.end, capEdge.end == edge.start {
                                return false
                            }
                        }
                    }
                    return nil
                }
                for ((shape0, shape1), (transform0, transform1)) in zip(
                    zip(shapes, shapes.dropFirst()),
                    zip(transforms, transforms.dropFirst())
                ) where shape0 != shape1 {
                    let transform0 = transform0!, transform1 = transform1!
                    for i in stride(from: 0, to: boundaryVertices.count, by: 2) {
                        let v0 = boundaryVertices[i]
                        let v1 = boundaryVertices[i + 1]
                        let sidePolygons = sidePolygons([
                            transformedVertex(v0, by: transform0),
                            transformedVertex(v1, by: transform0),
                            transformedVertex(v1, by: transform1),
                            transformedVertex(v0, by: transform1),
                        ])
                        let edge = LineSegment(unchecked: v0.position, v1.position)
                        if capUsesBoundaryEdgeForward(edge) == true {
                            loopPolygons += sidePolygons.map { $0.inverted() }
                        } else {
                            loopPolygons += sidePolygons
                        }
                    }
                }
                polygons += loopPolygons.withVertexNormalsFacingPlane()
            }
        } else {
            polygons = boundarySubshapes.flatMap { subshapes in
                let capNormals = [subshapes.first, subshapes.last].flatMap {
                    $0?.facePolygons(material: material).map(\.plane.normal) ?? []
                }
                return loft(subshapes, faces: .front, material: material, isCancelled: isCancelled)
                    .polygons.filter { polygon in
                        !capNormals.contains {
                            abs($0.dot(polygon.plane.normal)) > 0.5
                        }
                    }
            }
        }
        if let first = shapes.first, let last = shapes.last, first != last {
            if !firstCapPolygons.isEmpty {
                polygons += firstCapPolygons
            }
            if let prev = shapes.last(where: { $0 != last }) {
                let p0p1 = directionBetweenShapes(prev, last)
                let lastFacePolygons = last.sectionTransform(relativeTo: first).map { transform in
                    firstFacePolygons.compactMap {
                        Polygon($0.vertices.map { transform($0.position) }, material: material)
                    }
                } ?? last.facePolygons(material: material)
                polygons += lastFacePolygons.map {
                    p0p1.dot($0.plane.normal) < 0 ? $0.inverted() : $0
                }
            }
        }
        polygons = polygons
            .withConsistentWinding { abs($0.plane.normal.dot(capNormal)) > 0.5 }
            .withVertexNormalsFacingPlane()
        switch faces {
        case .front, .default:
            return Mesh(
                unchecked: polygons,
                bounds: nil,
                bsp: nil,
                isConvex: false,
                isWatertight: nil,
                submeshes: nil
            )
        case .back:
            return Mesh(
                unchecked: polygons.inverted(),
                bounds: nil,
                bsp: nil,
                isConvex: false,
                isWatertight: nil,
                submeshes: nil
            )
        case .frontAndBack:
            return Mesh(
                unchecked: polygons + polygons.inverted(),
                bounds: nil,
                bsp: nil,
                isConvex: false,
                isWatertight: true,
                submeshes: nil
            )
        }
    }

    static func loft(
        _ shapes: [Path],
        faces: Faces,
        material: Material?,
        isConvex: Bool,
        isWatertight: Bool?,
        isCancelled: CancellationHandler
    ) -> Mesh {
        let (normalizedShapes, isNonZeroBoundary) = shapes.normalizingCompoundPathsForLoft()
        var subpathCount = 0
        let arrayOfSubpaths: [[Path]] = normalizedShapes.map {
            let subpaths = $0.subpaths
            subpathCount = max(subpathCount, subpaths.count)
            return subpaths
        }
        if isNonZeroBoundary || subpathCount > 1 {
            var subshapes = Array(repeating: [Path](), count: subpathCount)
            for subpaths in arrayOfSubpaths {
                for (i, subpath) in subpaths.enumerated() {
                    subshapes[i].append(subpath)
                }
            }
            if isNonZeroBoundary {
                return compoundLoft(
                    originalShapes: shapes,
                    boundarySubshapes: subshapes,
                    faces: faces,
                    material: material,
                    isCancelled: isCancelled
                )
            }
            return Mesh.symmetricDifference(subshapes.map {
                Mesh.loft($0, faces: faces, material: material, isCancelled: isCancelled)
            }, isCancelled: isCancelled)
        }
        // TODO: could we split the extrusion at empty shapes instead?
        let shapes = normalizedShapes.filter { !$0.isEmpty }
        guard let first = shapes.first, let last = shapes.last else {
            return .empty
        }
        var count = 1
        var prev = first
        for shape in shapes.dropFirst() where shape != prev {
            count += 1
            prev = shape
        }
        let allShapesAreClosed = shapes.allSatisfy(\.isClosed)
        let isClosed = allShapesAreClosed && (shapes.first == shapes.last)
        if count < 3, isClosed {
            return fill(first, faces: faces, material: material)
        }
        var polygons = [Polygon]()
        polygons.reserveCapacity(shapes.reduce(0) { $0 + $1.points.count })
        var isCapped = true
        if !isClosed {
            let facePolygons = first.facePolygons(material: material)
            if facePolygons.isEmpty {
                isCapped = isCapped && first.isClosed && first.hasZeroArea
            } else if let next = shapes.first(where: { $0 != first }) {
                let p0p1 = directionBetweenShapes(first, next)
                polygons += facePolygons.map {
                    p0p1.dot($0.plane.normal) >= 0 ? $0.inverted() : $0
                }
            }
        }
        var uvx0 = 0.0
        let uvstep = Double(1) / Double(count - 1)
        prev = first
        var curvestart = true
        for (i, shape) in shapes.enumerated().dropFirst() where !isCancelled() {
            let uvx1 = uvx0 + uvstep
            if shape == prev {
                curvestart = false
                continue
            }
            var curveend = true
            if i < shapes.count - 1, shape == shapes[i + 1] {
                curveend = false
            }
            loft(
                unchecked: prev, shape,
                curvestart: curvestart, curveend: curveend,
                uvstart: uvx0, uvend: uvx1,
                material: material,
                into: &polygons
            )
            prev = shape
            curvestart = true
            uvx0 = uvx1
        }
        if !isClosed {
            let facePolygons = last.facePolygons(material: material)
            if facePolygons.isEmpty {
                isCapped = isCapped && last.isClosed && last.hasZeroArea
            } else if let prev = shapes.last(where: { $0 != last }) {
                let p0p1 = directionBetweenShapes(prev, last)
                polygons += facePolygons.map {
                    p0p1.dot($0.plane.normal) < 0 ? $0.inverted() : $0
                }
            }
        }
        let isSealed = isCapped && allShapesAreClosed
        switch faces {
        case .default where isSealed, .front:
            return Mesh(
                unchecked: polygons,
                bounds: nil, // TODO: can we calculate this efficiently?
                bsp: nil,
                isConvex: isConvex,
                isWatertight: isWatertight,
                submeshes: nil // TODO: Can we calculate this efficiently?
            )
        case .back:
            return Mesh(
                unchecked: polygons.inverted(),
                bounds: nil, // TODO: can we calculate this efficiently?
                bsp: nil,
                isConvex: false,
                isWatertight: isWatertight,
                submeshes: nil // TODO: Can we calculate this efficiently?
            )
        case .frontAndBack, .default:
            return Mesh(
                unchecked: polygons + polygons.inverted(),
                bounds: nil, // TODO: can we calculate this efficiently?
                bsp: nil,
                isConvex: false,
                isWatertight: true, // double sided shapes are always watertight
                submeshes: nil // TODO: Can we calculate this efficiently?
            )
        }
    }

    static func loft(
        unchecked p0: Path, _ p1: Path,
        curvestart: Bool, curveend: Bool,
        uvstart: Double, uvend: Double,
        material: Material?,
        into polygons: inout [Polygon]
    ) {
        assert(p0.subpaths.count == 1)
        assert(p1.subpaths.count == 1)
        var p0 = p0, p1 = p1
        let direction = directionBetweenShapes(p0, p1)
        var n0 = p0.points.count < 2 ? direction : p0.faceNormal
        if direction.dot(n0) < 0 {
            p0 = p0.inverted()
            n0 = -n0
        }
        var n1 = p1.points.count < 2 ? direction : p1.faceNormal
        if direction.dot(n1) < 0 {
            p1 = p1.inverted()
            n1 = -n1
        }
        var invert = false
        func makePolygon(_ vertices: [Vertex]) -> Polygon? {
            Polygon(invert ? vertices.reversed() : vertices, material: material)?
                .withVertexNormalsFacingPlane()
        }
        func addTriangulatedFace(_ vertices: [Vertex]) {
            polygons += triangulateVertices(
                vertices,
                plane: nil,
                isConvex: nil,
                sanitizeNormals: false,
                material: material,
                id: 0
            ).withVertexNormalsFacingPlane()
        }
        var uvstart = uvstart, uvend = uvend
        func addFace(_ a: Vertex, _ b: Vertex, _ c: Vertex, _ d: Vertex) {
            var vertices = [a, b, c, d]
            if !curvestart {
                let r = rotationBetweenNormalizedVectors(n0, direction)
                vertices[0].normal.rotate(by: r)
                vertices[1].normal.rotate(by: r)
            }
            if !curveend {
                let r = rotationBetweenNormalizedVectors(n1, direction)
                vertices[2].normal.rotate(by: r)
                vertices[3].normal.rotate(by: r)
            }
            vertices[0].texcoord = [vertices[0].texcoord.y, uvstart]
            vertices[1].texcoord = [vertices[1].texcoord.y, uvstart]
            vertices[2].texcoord = [vertices[2].texcoord.y, uvend]
            vertices[3].texcoord = [vertices[3].texcoord.y, uvend]
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
            guard !verticesAreDegenerate(vertices) else {
                // This is a hack to make the best of a bad edge case
                // TODO: find a better solution
                addTriangulatedFace(vertices)
                return
            }
            if vertices.count == 4 {
                let c = vertices[0], d = vertices[1], b = vertices[2], a = vertices[3]
                guard let bcd = makePolygon([b, c, d]) else {
                    addTriangulatedFace([c, d, b, a])
                    return
                }
                switch a.position.compare(with: bcd.plane) {
                case .coplanar, .spanning:
                    makePolygon([c, d, b, a]).map { polygons.append($0) } ??
                        addTriangulatedFace([c, d, b, a])
                case .back:
                    let split = [makePolygon([c, b, a]), bcd].compactMap { $0 }
                    split.count == 2 ? polygons += split : addTriangulatedFace([c, d, b, a])
                case .front:
                    let split = [makePolygon([c, d, a]), makePolygon([b, a, d])].compactMap { $0 }
                    split.count == 2 ? polygons += split : addTriangulatedFace([c, d, b, a])
                }
            } else if let polygon = makePolygon(vertices) {
                polygons.append(polygon)
            }
        }
        var e0 = p0.edgeVertices, e1 = p1.edgeVertices
        guard e0.count > 1 || e1.count > 1 else {
            return
        }
        var t0 = -p0.bounds.center, t1 = -p1.bounds.center
        var r = rotationBetweenNormalizedVectors(n1, n0)
        var closed0 = p0.isClosed, closed1 = p1.isClosed
        // e1 count must be > than e0, so swap everything if not
        if e0.count > e1.count {
            invert = !invert
            (t0, t1, r) = (t1, t0, -r)
            (e0, e1, uvstart, uvend) = (e1, e0, uvend, uvstart)
            (closed0, closed1) = (closed1, closed0)
        }
        if e0.count == 1 {
            for j in stride(from: 0, to: e1.count, by: 2) {
                addFace(e0[0], e0[0], e1[j + 1], e1[j])
            }
            return
        }
        let shouldAlignClosedRings = closed0 && closed1 && abs(n0.dot(n1)) > 1 - epsilon
        if e0.count == e1.count, !shouldAlignClosedRings {
            for j in stride(from: 0, to: e0.count, by: 2) {
                addFace(e0[j], e0[j + 1], e1[j + 1], e1[j])
            }
            return
        }
        let fp0 = p0.flatteningPlane, fp1 = p1.flatteningPlane
        // Ensure edges have the same orientation
        if flattenedPointsAreClockwise(e0.map {
            fp0.flattenPoint($0.position)
        }) != flattenedPointsAreClockwise(e1.map {
            fp1.flattenPoint($0.position)
        }) {
            e0.reverse()
            // TODO: fix mirrored texture coords
        }
        if e0.count == e1.count {
            if shouldAlignClosedRings {
                let count = e0.count / 2
                var bestOffset = 0
                var bestDistance = Double.infinity
                let positions0 = stride(from: 0, to: e0.count, by: 2).map {
                    e0[$0].position.translated(by: t0)
                }
                let positions1 = stride(from: 0, to: e1.count, by: 2).map {
                    e1[$0].position.translated(by: t1).rotated(by: r)
                }
                for offset in 0 ..< count {
                    var distance = 0.0
                    for i in 0 ..< count {
                        distance += (positions0[i] - positions1[(i + offset) % count]).lengthSquared
                    }
                    if distance < bestDistance {
                        bestOffset = offset
                        bestDistance = distance
                    }
                }
                if bestOffset > 0 {
                    let index = bestOffset * 2
                    e1 = Array(e1[index ..< e1.count]) + Array(e1[0 ..< index])
                }
            }
            for j in stride(from: 0, to: e0.count, by: 2) {
                addFace(e0[j], e0[j + 1], e1[j + 1], e1[j])
            }
            return
        }
        let sparseCount = e0.count / 2
        let denseCount = e1.count / 2
        let sparsePositions = stride(from: 0, to: e0.count, by: 2).map {
            e0[$0].position.translated(by: t0)
        }
        var densePositions = stride(from: 0, to: e1.count, by: 2).map {
            e1[$0].position.translated(by: t1).rotated(by: r)
        }
        densePositions.append(e1.last!.position.translated(by: t1).rotated(by: r))

        func nearestSparseIndex(to point: Vector) -> Int {
            var closestIndex = 0
            var best = Double.infinity
            for i in 0 ..< sparseCount {
                let distanceSquared = (point - sparsePositions[i]).lengthSquared
                if distanceSquared < best {
                    closestIndex = i
                    best = distanceSquared
                }
            }
            return closestIndex
        }

        // Map dense vertices to nearest sparse vertices, then unwrap and
        // clamp the indices so correspondence never moves backwards
        var mapping = densePositions.map {
            nearestSparseIndex(to: $0)
        }
        if closed0, closed1 {
            let start = mapping[0]
            for j in 1 ..< denseCount {
                let expected = start + j * sparseCount / denseCount
                let wrapped = mapping[j] + sparseCount
                if abs(wrapped - expected) < abs(mapping[j] - expected) {
                    mapping[j] = wrapped
                }
                let lowerBound = start + sparseCount - (denseCount - j)
                mapping[j] = min(
                    mapping[j - 1] + 1,
                    max(lowerBound, mapping[j - 1], mapping[j])
                )
            }
            mapping[denseCount] = start + sparseCount
        } else {
            mapping[0] = 0
            for j in 1 ..< denseCount {
                let lowerBound = sparseCount - (denseCount - j)
                mapping[j] = min(
                    mapping[j - 1] + 1,
                    max(lowerBound, mapping[j - 1], mapping[j])
                )
            }
            mapping[denseCount] = sparseCount
        }

        for j in 0 ..< denseCount {
            let a = e1[j * 2], b = e1[j * 2 + 1]
            let start = mapping[j], end = mapping[j + 1]
            if start == end {
                let c = closed0 ? e0[(start % sparseCount) * 2] :
                    (start == sparseCount ? e0.last! : e0[start * 2])
                addFace(c, c, b, a)
                continue
            }
            assert(end == start + 1)
            let c = e0[(start % sparseCount) * 2]
            let d = e0[(start % sparseCount) * 2 + 1]
            addFace(c, d, b, a)
        }
    }

    static func build(
        _ shapes: some Collection<Path>,
        using fn: @Sendable (Path) -> Mesh,
        isCancelled: CancellationHandler
    ) -> [Mesh] {
        var uniquePaths = [Path]()
        let indexesAndOffsets = shapes.map { path -> (Int, Vector) in
            let (p, offset) = path.withNormalizedPosition()
            if let index = uniquePaths.firstIndex(where: { p.isApproximatelyEqual(to: $0) }) {
                return (index, offset)
            }
            uniquePaths.append(p)
            return (uniquePaths.count - 1, offset)
        }
        let meshes = batch(uniquePaths, stride: 1) { paths -> [Mesh] in
            paths.map { isCancelled() ? .empty : fn($0) }
        }
        return isCancelled() ? [] : indexesAndOffsets.map { index, offset in
            meshes[index].translated(by: offset)
        }
    }
}

private struct SendableMaterial: @unchecked Sendable {
    let value: Mesh.Material?

    init(_ value: Mesh.Material?) {
        self.value = value
    }
}

private extension Collection<Polygon> {
    func withVertexNormalsFacingPlane() -> [Polygon] {
        map { $0.withVertexNormalsFacingPlane() }
    }
}

private extension Polygon {
    func withVertexNormalsFacingPlane() -> Polygon {
        Polygon(
            unchecked: vertices.map {
                let normal = $0.normal.dot(plane.normal) < 0 ? -$0.normal : $0.normal
                return $0.withNormal(normal)
            },
            plane: plane,
            isConvex: isConvex,
            sanitizeNormals: false,
            material: material
        )
    }
}
