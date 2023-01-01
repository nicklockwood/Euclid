//
//  Euclid+SceneKit.swift
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

#if canImport(SceneKit)

import SceneKit

public extension SCNVector3 {
    /// Creates a 3D SceneKit vector from a vector.
    /// - Parameter v: The vector to convert.
    init(_ v: Vector) {
        self.init(v.x, v.y, v.z)
    }
}

public extension SCNVector4 {
    /// Creates a 4D SceneKit vector from a color.
    /// - Parameter c: The color to convert.
    init(_ c: Color) {
        self.init(c.r, c.g, c.b, c.a)
    }
}

public extension SCNQuaternion {
    /// Creates a new SceneKit quaternion from a `Rotation`
    /// - Parameter rotation: The rotation to convert.
    ///
    /// > Note: ``SCNQuaternion`` is actually just a typealias for ``SCNVector4`` so be
    /// careful to avoid type ambiguity when using this value.
    init(_ rotation: Rotation) {
        self.init(rotation.quaternion)
    }

    /// Creates a new SceneKit quaternion from a Euclid `Quaternion`
    /// - Parameter quaternion: The quaternion to convert.
    ///
    /// > Note: ``SCNQuaternion`` is actually just a typealias for ``SCNVector4`` so be
    /// careful to avoid type ambiguity when using this value.
    init(_ quaternion: Quaternion) {
        self.init(quaternion.x, quaternion.y, quaternion.z, quaternion.w)
    }
}

public extension SCNMatrix4 {
    /// Creates a new SceneKit matrix from a `Transform`
    /// - Parameter transform: The transform to convert
    init(_ transform: Transform) {
        let node = SCNNode()
        node.setTransform(transform)
        self = node.transform
    }
}

private extension Data {
    mutating func append(_ int: UInt32) {
        var int = int
        withUnsafeMutablePointer(to: &int) { pointer in
            append(UnsafeBufferPointer(start: pointer, count: 1))
        }
    }
}

public extension SCNNode {
    /// Applies the transform to the node.
    ///
    /// The transform applies to the orientation, scale, and position of the node.
    /// - Parameter transform: The transform to apply.
    func setTransform(_ transform: Transform) {
        orientation = SCNQuaternion(transform.rotation)
        scale = SCNVector3(transform.scale)
        position = SCNVector3(transform.offset)
    }
}

private func defaultMaterialLookup(_ material: Polygon.Material?) -> SCNMaterial? {
    switch material {
    case let scnMaterial as SCNMaterial:
        return scnMaterial
    case let color as Color:
        return defaultMaterialLookup(OSColor(color))
    case let cfType as CFTypeRef where [
        CGImage.typeID, CGColor.typeID,
    ].contains(CFGetTypeID(cfType)):
        fallthrough
    case is OSColor, is OSImage:
        let scnMaterial = SCNMaterial()
        scnMaterial.diffuse.contents = material
        return scnMaterial
    default:
        return nil
    }
}

extension SCNGeometrySource {
    convenience init(colors: [SCNVector4]) {
        let data = Data(bytes: colors, count: colors.count * MemoryLayout<SCNVector4>.size)

        self.init(
            data: data,
            semantic: .color,
            vectorCount: colors.count,
            usesFloatComponents: true,
            componentsPerVector: 4,
            bytesPerComponent: MemoryLayout<OSColorComponent>.size,
            dataOffset: 0,
            dataStride: 0
        )
    }
}

public extension SCNGeometry {
    /// A closure that maps a Euclid material to a SceneKit material.
    /// - Parameter m: A Euclid material to convert, or `nil` for the default material.
    /// - Returns: An `SCNMaterial` used by SceneKit.
    typealias SCNMaterialProvider = (_ m: Polygon.Material?) -> SCNMaterial?

    /// Creates a geometry from a ``Mesh`` using the default tessellation method.
    /// - Parameters:
    ///   - mesh: The mesh to convert into a SceneKit geometry.
    ///   - materialLookup: A closure to map the polygon material to a SceneKit material.
    convenience init(_ mesh: Mesh, materialLookup: SCNMaterialProvider? = nil) {
        self.init(triangles: mesh, materialLookup: materialLookup)
    }

    /// Creates a geometry from a ``Mesh`` using triangles.
    /// - Parameters:
    ///   - mesh: The mesh to convert into a SceneKit geometry.
    ///   - materialLookup: A closure to map the polygon material to a SceneKit material.
    convenience init(triangles mesh: Mesh, materialLookup: SCNMaterialProvider? = nil) {
        var elementIndices = [[UInt32]]()
        var vertices = [SCNVector3]()
        var normals = [SCNVector3]()
        var texcoords = [CGPoint]()
        var colors = [SCNVector4]()
        var materials = [SCNMaterial]()
        var indicesByVertex = [Vertex: UInt32]()
        let hasTexcoords = mesh.hasTexcoords
        let hasVertexColors = mesh.hasVertexColors
        let materialLookup = materialLookup ?? defaultMaterialLookup
        let polygonsByMaterial = mesh.polygonsByMaterial
        for material in mesh.materials {
            let polygons = polygonsByMaterial[material] ?? []
            var indices = [UInt32]()
            func addVertex(_ vertex: Vertex) {
                if let index = indicesByVertex[vertex] {
                    indices.append(index)
                    return
                }
                let index = UInt32(indicesByVertex.count)
                indicesByVertex[vertex] = index
                indices.append(index)
                vertices.append(SCNVector3(vertex.position))
                normals.append(SCNVector3(vertex.normal))
                if hasTexcoords {
                    texcoords.append(CGPoint(vertex.texcoord))
                }
                if hasVertexColors {
                    colors.append(SCNVector4(vertex.color))
                }
            }
            materials.append(materialLookup(material) ?? SCNMaterial())
            for polygon in polygons {
                for triangle in polygon.triangulate() {
                    triangle.vertices.forEach(addVertex)
                }
            }
            elementIndices.append(indices)
        }
        var sources = [
            SCNGeometrySource(vertices: vertices),
            SCNGeometrySource(normals: normals),
        ]
        if hasTexcoords {
            sources.append(SCNGeometrySource(textureCoordinates: texcoords))
        }
        if hasVertexColors {
            sources.append(SCNGeometrySource(colors: colors))
        }
        self.init(
            sources: sources,
            elements: elementIndices.map { indices in
                SCNGeometryElement(indices: indices, primitiveType: .triangles)
            }
        )
        self.materials = materials
    }

    /// Creates a geometry from a ``Mesh`` using convex polygons.
    /// - Parameters:
    ///   - mesh: The mesh to convert into a SceneKit geometry.
    ///   - materialLookup: A closure to map the polygon material to a SceneKit material.
    @available(OSX 10.12, iOS 10.0, tvOS 10.0, *)
    convenience init(polygons mesh: Mesh, materialLookup: SCNMaterialProvider? = nil) {
        var elementData = [(Int, Data)]()
        var vertices = [SCNVector3]()
        var normals = [SCNVector3]()
        var texcoords = [CGPoint]()
        var colors = [SCNVector4]()
        var materials = [SCNMaterial]()
        var indicesByVertex = [Vertex: UInt32]()
        let hasTexcoords = mesh.hasTexcoords
        let hasVertexColors = mesh.hasVertexColors
        let materialLookup = materialLookup ?? defaultMaterialLookup
        let polygonsByMaterial = mesh.polygonsByMaterial
        for material in mesh.materials {
            var polygons = polygonsByMaterial[material] ?? []
            var indexData = Data()
            func addVertex(_ vertex: Vertex) {
                if let index = indicesByVertex[vertex] {
                    indexData.append(index)
                    return
                }
                let index = UInt32(indicesByVertex.count)
                indicesByVertex[vertex] = index
                indexData.append(index)
                vertices.append(SCNVector3(vertex.position))
                normals.append(SCNVector3(vertex.normal))
                if hasTexcoords {
                    texcoords.append(CGPoint(vertex.texcoord))
                }
                if hasVertexColors {
                    colors.append(SCNVector4(vertex.color))
                }
            }
            materials.append(materialLookup(material) ?? SCNMaterial())
            polygons = polygons.tessellate()
            for polygon in polygons {
                indexData.append(UInt32(polygon.vertices.count))
            }
            for polygon in polygons {
                polygon.vertices.forEach(addVertex)
            }
            elementData.append((polygons.count, indexData))
        }
        var sources = [
            SCNGeometrySource(vertices: vertices),
            SCNGeometrySource(normals: normals),
        ]
        if hasTexcoords {
            sources.append(SCNGeometrySource(textureCoordinates: texcoords))
        }
        if hasVertexColors {
            sources.append(SCNGeometrySource(colors: colors))
        }
        self.init(
            sources: sources,
            elements: elementData.map { count, indexData in
                SCNGeometryElement(
                    data: indexData,
                    primitiveType: .polygon,
                    primitiveCount: count,
                    bytesPerIndex: 4
                )
            }
        )
        self.materials = materials
    }

    /// Creates a wireframe geometry from a collection of line segments.
    /// - Parameter edges: The collection of ``LineSegment`` to convert.
    convenience init<T: Collection>(_ edges: T) where T.Element == LineSegment {
        var indices = [UInt32]()
        var vertices = [SCNVector3]()
        var indicesByVertex = [Vector: UInt32]()
        func addVertex(_ vertex: Vector) {
            if let index = indicesByVertex[vertex] {
                indices.append(index)
                return
            }
            let index = UInt32(indicesByVertex.count)
            indicesByVertex[vertex] = index
            indices.append(index)
            vertices.append(SCNVector3(vertex))
        }
        for edge in edges {
            addVertex(edge.start)
            addVertex(edge.end)
        }
        self.init(
            sources: [SCNGeometrySource(vertices: vertices)],
            elements: [
                SCNGeometryElement(indices: indices, primitiveType: .line),
            ]
        )
    }

    /// Creates a wireframe geometry from a mesh.
    /// - Parameter mesh: The ``Mesh`` to use for the wireframe geometry.
    convenience init(wireframe mesh: Mesh) {
        self.init(mesh.uniqueEdges)
    }

    /// Creates line-segment geometry representing the vertex normals of a mesh.
    /// - Parameters:
    ///   - mesh: The input ``Mesh``.
    ///   - scale: The line length of the normal indicators.
    convenience init(normals mesh: Mesh, scale: Double = 1) {
        self.init(Set(mesh.polygons.flatMap { $0.vertices.compactMap {
            LineSegment($0.position, $0.position + $0.normal * scale)
        }}))
    }

    /// Creates a wrieframe geometry from a path.
    /// - Parameter path: The ``Path`` to convert into a geometry.
    convenience init(_ path: Path) {
        var indices = [UInt32]()
        var vertices = [SCNVector3]()
        var colors = [SCNVector4]()
        var indicesByPoint = [Vector: UInt32]()
        let hasColors = path.hasColors
        for path in path.subpaths {
            for vertex in path.edgeVertices {
                let position = vertex.position
                if let index = indicesByPoint[position] {
                    indices.append(index)
                    continue
                }
                let index = UInt32(indicesByPoint.count)
                indicesByPoint[position] = index
                indices.append(index)
                vertices.append(SCNVector3(position))
                if hasColors {
                    colors.append(SCNVector4(vertex.color))
                }
            }
        }
        var sources = [SCNGeometrySource(vertices: vertices)]
        if hasColors {
            sources.append(SCNGeometrySource(colors: colors))
        }
        self.init(
            sources: sources,
            elements: [
                SCNGeometryElement(indices: indices, primitiveType: .line),
            ]
        )
    }

    /// Creates a wireframe geometry from a bounding box.
    /// - Parameter bounds: The ``Bounds`` to convert into a geometry.
    convenience init(_ bounds: Bounds) {
        let vertices = bounds.corners.map { SCNVector3($0) }
        let indices: [UInt32] = [
            // bottom
            0, 1, 1, 2, 2, 3, 3, 0,
            // top
            4, 5, 5, 6, 6, 7, 7, 4,
            // columns
            0, 4, 1, 5, 2, 6, 3, 7,
        ]
        self.init(
            sources: [SCNGeometrySource(vertices: vertices)],
            elements: [
                SCNGeometryElement(indices: indices, primitiveType: .line),
            ]
        )
    }

    @available(*, deprecated, message: "Use `init(_:)` instead")
    convenience init(bounds: Bounds) {
        self.init(bounds)
    }
}

// MARK: import

private extension Data {
    func index(at index: Int, bytes: Int) -> UInt32 {
        switch bytes {
        case 1: return UInt32(self[index])
        case 2: return UInt32(uint16(at: index * 2))
        case 4: return uint32(at: index * 4)
        default: preconditionFailure()
        }
    }

    func uint16(at index: Int) -> UInt16 {
        var int: UInt16 = 0
        withUnsafeMutablePointer(to: &int) { pointer in
            copyBytes(
                to: UnsafeMutableBufferPointer(start: pointer, count: 1),
                from: index ..< index + 2
            )
        }
        return int
    }

    func uint32(at index: Int) -> UInt32 {
        var int: UInt32 = 0
        withUnsafeMutablePointer(to: &int) { pointer in
            copyBytes(
                to: UnsafeMutableBufferPointer(start: pointer, count: 1),
                from: index ..< index + 4
            )
        }
        return int
    }

    func float(at index: Int) -> Double {
        var float: Float = 0
        withUnsafeMutablePointer(to: &float) { pointer in
            copyBytes(
                to: UnsafeMutableBufferPointer(start: pointer, count: 1),
                from: index ..< index + 4
            )
        }
        return Double(float)
    }

    func vector(at index: Int) -> Vector {
        Vector(
            float(at: index),
            float(at: index + 4),
            float(at: index + 8)
        )
    }
}

public extension Vector {
    /// Creates a new vector from a SceneKit vector.
    /// - Parameter v: The SceneKit `SCNVector3`.
    init(_ v: SCNVector3) {
        self.init(Double(v.x), Double(v.y), Double(v.z))
    }
}

public extension Rotation {
    /// Creates a rotation from a SceneKit quaternion.
    /// - Parameter quaternion: The `SCNQuaternion` to convert.
    init(_ quaternion: SCNQuaternion) {
        self.init(.init(quaternion))
    }
}

public extension Quaternion {
    /// Creates a Euclid `Quaternion` from a SceneKit quaternion.
    /// - Parameter q: The `SCNQuaternion` to convert.
    init(_ q: SCNQuaternion) {
        self.init(Double(q.x), Double(q.y), Double(q.z), Double(q.w))
    }
}

public extension Transform {
    /// Creates a transform from a SceneKit transform matrix.
    /// - Parameter scnMatrix: The `SCNMatrix4` from which to determine the transform.
    init(_ scnMatrix: SCNMatrix4) {
        let node = SCNNode()
        node.transform = scnMatrix
        self = .transform(from: node)
    }

    /// Creates a transform from the current position, scale and orientation of a SceneKit node.
    /// - Parameter scnNode: The `SCNNode` from which to determine the transform.
    static func transform(from scnNode: SCNNode) -> Transform {
        Transform(
            offset: Vector(scnNode.position),
            rotation: Rotation(scnNode.orientation),
            scale: Vector(scnNode.scale)
        )
    }
}

public extension Bounds {
    /// Creates a bounds from two SceneKit vectors.
    /// - Parameter scnBoundingBox: A tuple of two `SCNVector3` that
    ///   represent opposite corners of the bounding box volume.
    init(_ scnBoundingBox: (min: SCNVector3, max: SCNVector3)) {
        self.init(
            min: Vector(scnBoundingBox.min),
            max: Vector(scnBoundingBox.max)
        )
    }
}

public extension Mesh {
    /// A closure that maps a SceneKit material to a Euclid material.
    /// - Parameter m: An `SCNMaterial` material to convert.
    /// - Returns: A ``Material`` instance, or `nil` for the default material.
    typealias MaterialProvider = (_ m: SCNMaterial) -> Material?

    /// Loads a mesh from a file using any format supported by SceneKit,  with optional material mapping.
    /// - Parameters:
    ///   - url: The `URL` of the file to be loaded.
    ///   - ignoringTransforms: Should node transforms from the input file be ignored.
    ///   - materialLookup: An optional closure to map the SceneKit materials to Euclid materials.
    ///     If omitted, the `SCNMaterial` will be directly used as the mesh material.
    init(url: URL, ignoringTransforms: Bool, materialLookup: MaterialProvider? = nil) throws {
        var options: [SCNSceneSource.LoadingOption: Any] = [
            .checkConsistency: false,
            .flattenScene: true,
            .createNormalsIfAbsent: true,
            .convertToYUp: true,
        ]
        if #available(iOS 13, tvOS 13, macOS 10.12, *) {
            options[.preserveOriginalTopology] = true
        }
        if !FileManager.default.isReadableFile(atPath: url.path) {
            _ = try Data(contentsOf: url) // Will throw error if unreachable
        }
        let importedScene = try SCNScene(url: url, options: options)
        self.init(
            importedScene.rootNode,
            ignoringTransforms: ignoringTransforms,
            materialLookup: materialLookup
        )
    }

    /// Creates a mesh from a SceneKit node, with optional material mapping.
    /// - Parameters:
    ///   - scnNode: The `SCNNode` to convert into a mesh.
    ///   - ignoringTransforms: Should transforms from the input node and its children be ignored.
    ///   - materialLookup: An optional closure to map the SceneKit materials to Euclid materials.
    ///     If omitted, the `SCNMaterial` will be directly used as the mesh material.
    init(_ scnNode: SCNNode, ignoringTransforms: Bool, materialLookup: MaterialProvider? = nil) {
        var meshes = [Mesh]()
        if let mesh = scnNode.geometry.flatMap({
            Mesh($0, materialLookup: materialLookup)
        }) {
            meshes.append(mesh)
        }
        meshes += scnNode.childNodes.map {
            Mesh($0, ignoringTransforms: ignoringTransforms, materialLookup: materialLookup)
        }
        var mesh = Mesh.merge(meshes)
        if !ignoringTransforms {
            if !SCNMatrix4IsIdentity(scnNode.pivot) {
                mesh = mesh.transformed(by: Transform(SCNMatrix4Invert(scnNode.pivot)))
            }
            mesh = mesh.transformed(by: .transform(from: scnNode))
        }
        self = mesh
    }

    /// Creates a mesh from a SceneKit geometry, with optional material mapping.
    /// - Parameters:
    ///   - scnGeometry: The `SCNGeometry` to convert into a mesh.
    ///   - materialLookup: An optional closure to map SceneKit materials to Euclid materials.
    ///     If omitted, the `SCNMaterial` will be directly used as the mesh material.
    init?(_ scnGeometry: SCNGeometry, materialLookup: MaterialProvider? = nil) {
        // Force properties to update
        let scnGeometry = scnGeometry.copy() as! SCNGeometry

        var polygons = [Polygon]()
        var vertices = [Vertex]()
        for source in scnGeometry.sources {
            let count = source.vectorCount
            if vertices.isEmpty {
                vertices = Array(repeating: Vertex(.zero), count: count)
            } else if vertices.count != source.vectorCount {
                return nil
            }
            var offset = source.dataOffset
            let stride = source.dataStride
            let data = source.data
            switch source.semantic {
            case .vertex:
                for i in 0 ..< count {
                    vertices[i].position = data.vector(at: offset)
                    offset += stride
                }
            case .normal:
                for i in 0 ..< count {
                    vertices[i].normal = data.vector(at: offset)
                    offset += stride
                }
            case .texcoord:
                for i in 0 ..< count {
                    vertices[i].texcoord = Vector(
                        data.float(at: offset),
                        data.float(at: offset + 4)
                    )
                    offset += stride
                }
            default:
                continue
            }
        }
        let materialLookup = materialLookup ?? { $0 as Material }
        let materials = scnGeometry.materials.map(materialLookup)
        for (index, element) in scnGeometry.elements.enumerated() {
            let material = materials.isEmpty ? nil : materials[index % materials.count]
            let indexData = element.data
            let indexSize = element.bytesPerIndex
            func vertex(at i: Int) -> Vertex {
                let index = indexData.index(at: i, bytes: indexSize)
                return vertices[Int(index)]
            }
            switch element.primitiveType {
            case .triangles:
                for i in 0 ..< element.primitiveCount {
                    Polygon([
                        vertex(at: i * 3),
                        vertex(at: i * 3 + 1),
                        vertex(at: i * 3 + 2),
                    ], material: material).map {
                        polygons.append($0)
                    }
                }
            case .triangleStrip:
                for i in stride(from: 0, to: element.primitiveCount - 1, by: 2) {
                    Polygon([
                        vertex(at: i),
                        vertex(at: i + 1),
                        vertex(at: i + 2),
                    ], material: material).map {
                        polygons.append($0)
                    }
                    Polygon([
                        vertex(at: i + 3),
                        vertex(at: i + 2),
                        vertex(at: i + 1),
                    ], material: material).map {
                        polygons.append($0)
                    }
                }
            case let type where type.rawValue == 4: // polygon
                let polyCount = element.primitiveCount
                var index = polyCount
                for i in 0 ..< polyCount {
                    let vertexCount = indexData.index(at: i, bytes: indexSize)
                    var vertices = [Vertex]()
                    for _ in 0 ..< vertexCount {
                        vertices.append(vertex(at: index))
                        index += 1
                    }
                    if let polygon = Polygon(vertices, material: material) {
                        polygons.append(polygon)
                    } else {
                        for triangle in triangulateVertices(
                            vertices,
                            plane: nil,
                            isConvex: nil,
                            material: material,
                            id: 0
                        ) {
                            polygons.append(triangle)
                        }
                    }
                }
            default:
                // TODO: throw detailed error message instead
                print("Unsupported SCNGeometryPrimitiveType: \(element.primitiveType.rawValue)")
                return nil
            }
        }
        let isKnownConvex: Bool
        let isWatertight: Bool?
        let noSubmeshes: Bool
        switch scnGeometry {
        case is SCNPlane,
             is SCNBox,
             is SCNPyramid,
             is SCNSphere,
             is SCNCylinder,
             is SCNCone,
             is SCNCapsule:
            isKnownConvex = true
            isWatertight = true
            noSubmeshes = true
        case is SCNTube,
             is SCNTorus:
            isKnownConvex = false
            isWatertight = true
            noSubmeshes = true
        case is SCNText,
             is SCNShape:
            isKnownConvex = false
            isWatertight = true
            noSubmeshes = false
        default:
            isKnownConvex = false
            isWatertight = nil
            noSubmeshes = false
        }
        let holeEdges = polygons.holeEdges
        if !holeEdges.isEmpty {
            let holePoints = holeEdges.reduce(into: Set<Vector>()) {
                $0.insert($1.start)
                $0.insert($1.end)
            }
            let maxLength = holeEdges.map { $0.length }.min() ?? 0
            let distance = max(min(holeEdges.separationDistance, maxLength), epsilon)
            polygons = polygons.mergingVertices(holePoints, withPrecision: distance)
        }
        self.init(
            unchecked: polygons,
            bounds: Bounds(scnGeometry.boundingBox),
            isConvex: isKnownConvex,
            isWatertight: isWatertight,
            submeshes: noSubmeshes ? [] : nil
        )
    }

    /// Creates a mesh from a SceneKit geometry, with the material you provide.
    /// - Parameters:
    ///   - scnGeometry: The `SCNGeometry` to convert.
    ///   - material: A ``Material`` to apply to the geometry, replacing any existing materials.
    ///     Pass `nil` to use the default Euclid material.
    init?(_ scnGeometry: SCNGeometry, material: Material?) {
        self.init(scnGeometry) { _ in material }
    }

    @available(*, deprecated, message: "Use `init(_:material:)` instead")
    init?(scnGeometry: SCNGeometry, materialLookup: MaterialProvider? = nil) {
        self.init(scnGeometry, materialLookup: materialLookup)
    }
}

#endif
