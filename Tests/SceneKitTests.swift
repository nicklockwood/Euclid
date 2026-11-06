//
//  SceneKitTests.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 06/09/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

#if canImport(SceneKit)

@testable import Euclid
import Metal
import SceneKit
import XCTest

final class SceneKitTests: XCTestCase {
    func testVertexColorsDecodeSRGBWithoutGammaCorrectingAlpha() throws {
        let color = Color(red: 0.5, green: 0.25, blue: 0.75, alpha: 0.4)
        let mesh = Mesh.cube().mapVertexColors { _ in color }
        for geometry in [SCNGeometry(triangles: mesh), SCNGeometry(polygons: mesh)] {
            let source = try XCTUnwrap(geometry.sources(for: .color).first)
            let values = source.data.withUnsafeBytes { bytes in
                (0 ..< 4).map { index in
                    let offset = source.dataOffset + index * source.bytesPerComponent
                    return source.bytesPerComponent == 4 ?
                        Double(bytes.loadUnaligned(fromByteOffset: offset, as: Float.self)) :
                        bytes.loadUnaligned(fromByteOffset: offset, as: Double.self)
                }
            }
            XCTAssertEqual(values[0], color.toLinear().red, accuracy: 1e-6)
            XCTAssertEqual(values[3], color.alpha, accuracy: 1e-6)
            let imported = try XCTUnwrap(Mesh(geometry))
            XCTAssertEqual(try XCTUnwrap(imported.polygons.first?.vertices.first?.color), color, accuracy: 1e-6)
        }
    }

    @MainActor
    func testRenderedAlphaMatchesCompositedColor() throws {
        try XCTSkipIf(MTLCreateSystemDefaultDevice() == nil, "SceneKit requires a Metal device")
        let device = try XCTUnwrap(MTLCreateSystemDefaultDevice())
        let queue = try XCTUnwrap(device.makeCommandQueue())
        let renderer = SCNRenderer(device: device, options: nil)
        let scene = SCNScene()
        let node = SCNNode()
        scene.rootNode.addChildNode(node)
        let foregroundNode = SCNNode()
        foregroundNode.position.z = 0.1
        scene.rootNode.addChildNode(foregroundNode)
        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.position = SCNVector3(0, 0, 3)
        scene.rootNode.addChildNode(camera)
        renderer.scene = scene
        renderer.pointOfView = camera
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm_srgb, width: 32, height: 32, mipmapped: false
        )
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .shared
        let texture = try XCTUnwrap(device.makeTexture(descriptor: descriptor))
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = texture
        pass.colorAttachments[0].loadAction = .clear
        pass.colorAttachments[0].storeAction = .store
        let depthDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .depth32Float_stencil8, width: 32, height: 32, mipmapped: false
        )
        depthDescriptor.usage = .renderTarget
        depthDescriptor.storageMode = .private
        let depth = try XCTUnwrap(device.makeTexture(descriptor: depthDescriptor))
        pass.depthAttachment.texture = depth
        pass.depthAttachment.loadAction = .clear
        pass.depthAttachment.clearDepth = 1
        pass.stencilAttachment.texture = depth
        pass.stencilAttachment.loadAction = .clear
        func renderPixel(_ geometry: SCNGeometry) throws -> [UInt8] {
            node.geometry = geometry
            SCNTransaction.flush()
            let buffer = try XCTUnwrap(queue.makeCommandBuffer())
            renderer.render(
                atTime: 0, viewport: CGRect(x: 0, y: 0, width: 32, height: 32),
                commandBuffer: buffer, passDescriptor: pass
            )
            buffer.commit()
            buffer.waitUntilCompleted()
            XCTAssertNil(buffer.error)
            var pixel = [UInt8](repeating: 0, count: 4)
            texture.getBytes(&pixel, bytesPerRow: 4, from: MTLRegionMake2D(16, 16, 1, 1), mipmapLevel: 0)
            return pixel
        }
        func geometry(_ color: Color) -> SCNGeometry {
            let geometry = SCNGeometry(Mesh.fill(
                .square(size: 2),
                faces: .front,
                material: color.withAlphaComponent(1)
            ))
            geometry.firstMaterial?.lightingModel = .constant
            // Keep the diffuse color opaque to isolate material opacity.
            geometry.firstMaterial?.transparency = CGFloat(color.alpha)
            return geometry
        }
        // Compare translucent layers with an opaque, precomposited color so that
        // both results pass through the same renderer color management.
        for (foreground, background) in [
            (Color(white: 1, alpha: 0.5), Color.black),
            (Color(red: 1, green: 0, blue: 0, alpha: 0.5), Color.blue),
            (Color(red: 0.5, green: 0.25, blue: 0.75, alpha: 0.3), Color(white: 0.4)),
        ] {
            foregroundNode.isHidden = false
            foregroundNode.geometry = geometry(foreground)
            let actual = try renderPixel(geometry(background))
            foregroundNode.isHidden = true
            let expected = try renderPixel(geometry(foreground.composited(over: background)))
            for channel in 0 ..< 4 {
                XCTAssertEqual(Double(actual[channel]), Double(expected[channel]), accuracy: 2)
            }
        }
    }

    @MainActor
    func testRenderedVertexColorsMatchMaterialColors() throws {
        try XCTSkipIf(MTLCreateSystemDefaultDevice() == nil, "SceneKit requires a Metal device")
        let device = try XCTUnwrap(MTLCreateSystemDefaultDevice())
        let queue = try XCTUnwrap(device.makeCommandQueue())
        let renderer = SCNRenderer(device: device, options: nil)
        let scene = SCNScene()
        let node = SCNNode()
        scene.rootNode.addChildNode(node)
        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.position = SCNVector3(0, 0, 3)
        scene.rootNode.addChildNode(camera)
        renderer.scene = scene
        renderer.pointOfView = camera
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm_srgb, width: 32, height: 32, mipmapped: false
        )
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .shared
        let texture = try XCTUnwrap(device.makeTexture(descriptor: descriptor))
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = texture
        pass.colorAttachments[0].loadAction = .clear
        pass.colorAttachments[0].storeAction = .store
        let depthDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .depth32Float_stencil8, width: 32, height: 32, mipmapped: false
        )
        depthDescriptor.usage = .renderTarget
        depthDescriptor.storageMode = .private
        let depth = try XCTUnwrap(device.makeTexture(descriptor: depthDescriptor))
        pass.depthAttachment.texture = depth
        pass.depthAttachment.loadAction = .clear
        pass.depthAttachment.clearDepth = 1
        pass.stencilAttachment.texture = depth
        pass.stencilAttachment.loadAction = .clear
        func renderPixel(_ geometry: SCNGeometry) throws -> [UInt8] {
            node.geometry = geometry
            SCNTransaction.flush()
            let buffer = try XCTUnwrap(queue.makeCommandBuffer())
            renderer.render(
                atTime: 0, viewport: CGRect(x: 0, y: 0, width: 32, height: 32),
                commandBuffer: buffer, passDescriptor: pass
            )
            buffer.commit()
            buffer.waitUntilCompleted()
            XCTAssertNil(buffer.error)
            var pixel = [UInt8](repeating: 0, count: 4)
            texture.getBytes(&pixel, bytesPerRow: 4, from: MTLRegionMake2D(16, 16, 1, 1), mipmapLevel: 0)
            return pixel
        }
        for color in [Color(white: 0.5), Color(red: 0.5, green: 0.25, blue: 0.75)] {
            let vertexGeometry = SCNGeometry(Mesh.cube().mapVertexColors { _ in color })
            vertexGeometry.firstMaterial?.lightingModel = .constant
            let actual = try renderPixel(vertexGeometry)
            let materialGeometry = SCNGeometry(Mesh.cube(material: color))
            materialGeometry.firstMaterial?.lightingModel = .constant
            let expected = try renderPixel(materialGeometry)
            XCTAssertGreaterThan(expected[0], 0)
            for channel in 0 ..< 4 {
                XCTAssertEqual(Double(actual[channel]), Double(expected[channel]), accuracy: 2)
            }
        }
    }

    // MARK: Import

    func testGeometryImportedWithCorrectDetail() {
        let sphere = SCNSphere(radius: 0.5)
        sphere.segmentCount = 3
        let mesh = Mesh(sphere)
        XCTAssertEqual(mesh?.polygons.count ?? 0, 12)
    }

    func testExportImportTriangles() throws {
        let cube = Mesh.cube().triangulate()
        let geometry = try XCTUnwrap(SCNGeometry(triangles: cube))
        let result = try XCTUnwrap(Mesh(geometry))
        XCTAssertTrue(result.isWatertight)
        XCTAssertTrue(result.isActuallyConvex)
        XCTAssertEqual(result.polygons.count, 12)
    }

    func testExportImportPolygons() throws {
        let cube = Mesh.cube()
        let geometry = try XCTUnwrap(SCNGeometry(polygons: cube))
        let result = try XCTUnwrap(Mesh(geometry))
        XCTAssertTrue(result.isWatertight)
        XCTAssertTrue(result.isActuallyConvex)
        XCTAssertEqual(result.polygons.count, 6)
    }

    func testExportImportTransformedPolygons() throws {
        var transforms = [Transform]()
        for _ in 0 ..< 10 {
            transforms.append(.random())
        }

        for transform in transforms {
            let cube = Mesh.cube(size: .random(in: 0.00001 ... 100000)).transformed(by: transform)
            let geometry = SCNGeometry(polygons: cube)
            let result = try XCTUnwrap(Mesh(geometry))
            XCTAssertTrue(result.isWatertight)
            let quads = result.polygons.filter { $0.vertices.count == 4 }.count
            let triangles = result.polygons.filter { $0.vertices.count == 3 }.count
            XCTAssertEqual(quads + triangles, result.polygons.count)
            XCTAssertEqual(quads * 2 + triangles, 12)
        }
    }

    @available(macOS 13.0, iOS 16.0, tvOS 16.0, *)
    func testImportGeometrySourceChannels() throws {
        let positions = SCNGeometrySource(vertices: [
            SCNVector3(0, 0, 0),
            SCNVector3(1, 0, 0),
            SCNVector3(0, 1, 0),
        ])
        let texcoords = SCNGeometrySource(textureCoordinates: [
            CGPoint(x: 9, y: 9),
            CGPoint(x: 0, y: 0),
            CGPoint(x: 1, y: 0),
            CGPoint(x: 0, y: 1),
        ])
        func check(
            _ indices: [UInt16],
            primitiveType: SCNGeometryPrimitiveType,
            interleaved: Bool
        ) throws {
            let data = indices.withUnsafeBytes { Data($0) }
            let element = SCNGeometryElement(
                data: data,
                primitiveType: primitiveType,
                primitiveCount: 1,
                indicesChannelCount: 2,
                interleavedIndicesChannels: interleaved,
                bytesPerIndex: MemoryLayout<UInt16>.size
            )
            let geometry = SCNGeometry(
                sources: [positions, texcoords],
                elements: [element],
                sourceChannels: [0, 1]
            )
            let polygon = try XCTUnwrap(Mesh(geometry)?.polygons.first)
            XCTAssertEqual(polygon.vertices.map(\.position), [
                [0, 0, 0], [1, 0, 0], [0, 1, 0],
            ])
            XCTAssertEqual(polygon.vertices.map(\.texcoord), [
                [0, 1, 0], [1, 0, 0], [0, 0, 0],
            ])
        }
        try check([0, 3, 1, 2, 2, 1], primitiveType: .triangles, interleaved: true)
        try check([0, 1, 2, 3, 2, 1], primitiveType: .triangles, interleaved: false)
        try check([3, 0, 3, 1, 2, 2, 1], primitiveType: .polygon, interleaved: true)
        try check([3, 0, 1, 2, 3, 2, 1], primitiveType: .polygon, interleaved: false)
    }

    func testSCNBoxIsWatertight() throws {
        for s in [0.01, 0.1, 0.2, 0.8, 1, 10] as [CGFloat] {
            let cube = SCNBox(width: s, height: s, length: s, chamferRadius: 0)
            let mesh = try XCTUnwrap(Mesh(cube))
            XCTAssert(mesh.isWatertight)
            XCTAssert(mesh.polygons.areWatertight)
        }
    }

    func testSCNCylinderIsWatertight() throws {
        for s in [0.2, 0.8, 3, 5, 10] as [CGFloat] {
            for r in [0.1, 0.2, 0.8, 3, 5, 10] as [CGFloat] {
                let cylinder = SCNCylinder(radius: r, height: s)
                let mesh = try XCTUnwrap(Mesh(cylinder))
                XCTAssert(mesh.isWatertight)
                XCTAssert(mesh.polygons.areWatertight)
            }
        }
    }

    func testSCNTubeIsWatertight() throws {
        for r in [0.1, 0.2, 0.8, 3, 5, 10] as [CGFloat] {
            for r2 in [0.001, 0.01, 0.1, 0.2] as [CGFloat] {
                let cylinder = SCNTube(innerRadius: r, outerRadius: r + r2, height: 1)
                let mesh = try XCTUnwrap(Mesh(cylinder))
                XCTAssert(mesh.isWatertight)
                XCTAssert(mesh.polygons.areWatertight)
            }
        }
    }

    func testSCNSphereIsWatertight() throws {
        for r in [0.01, 0.1, 0.2, 0.8, 3, 5, 10] as [CGFloat] {
            let sphere = SCNSphere(radius: r)
            let mesh = try XCTUnwrap(Mesh(sphere))
            XCTAssert(mesh.isWatertight)
            XCTAssert(mesh.polygons.areWatertight)
        }
    }

    func testSCNTextIsWatertight() throws {
        let text = SCNText(string: "Hello", extrusionDepth: 0.2)
        let mesh = try XCTUnwrap(Mesh(text))
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
    }

    func testSCNBoxSubtractedFromSCNBoxCanBeMadeWatertight() throws {
        let box1 = SCNBox(width: 0.2, height: 0.2, length: 0.2, chamferRadius: 0)
        let box2 = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        let mesh = try XCTUnwrap(Mesh(box1)?.translated(by: [0, 0, -0.4])
            .subtracting(XCTUnwrap(Mesh(box2)?.translated(by: [0, 0.12, -0.3])))
            .makeWatertight())
        XCTAssert(mesh.isWatertight)
        XCTAssert(mesh.polygons.areWatertight)
    }

    // MARK: Export

    func testExportCube() {
        let cube = Mesh.cube()
        let geometry = SCNGeometry(polygons: cube)
        XCTAssertEqual(geometry.sources.count, 3)
        XCTAssertEqual(geometry.sources.first?.vectorCount, 24)
    }

    func testExportCubeWithoutTexcoords() {
        let cube = Mesh.cube().withoutTexcoords()
        let geometry = SCNGeometry(polygons: cube)
        XCTAssertEqual(geometry.sources.count, 2)
        XCTAssertEqual(geometry.sources.first?.vectorCount, 24)
    }

    func testExportSphere() {
        let sphere = Mesh.sphere()
        let geometry = SCNGeometry(polygons: sphere)
        XCTAssertEqual(geometry.sources.count, 3)
        XCTAssertEqual(geometry.sources.first?.vectorCount, 151)
    }

    func testExportSphereWithoutTexcoords() {
        let sphere = Mesh.sphere().withoutTexcoords()
        let geometry = SCNGeometry(polygons: sphere)
        XCTAssertEqual(geometry.sources.count, 2)
        XCTAssertEqual(geometry.sources.first?.vectorCount, 151)
    }

    func testExportMeshWithColors() throws {
        let mesh = Mesh.lathe(.curve([
            .point(.unitY, color: .red),
            .curve(-.unitX, color: .green),
            .point(-.unitY, color: .blue),
        ]))
        let geometry = SCNGeometry(polygons: mesh)
        let result = try XCTUnwrap(Mesh(geometry))
        XCTAssert(result.hasVertexColors)
        XCTAssertEqual(result.polygons.first?.vertices.first?.color, .red)
    }

    // MARK: Transforms

    func testIdentityTransformToFromMatrix() {
        let transform = Transform.identity
        let matrix = SCNMatrix4(transform)
        XCTAssert(SCNMatrix4EqualToMatrix4(matrix, SCNMatrix4Identity))
        XCTAssertEqual(transform, Transform(matrix))
    }

    func testScaleTransformToFromMatrix() {
        let transform = Transform(scale: .init(size: [1.5]))
        let matrix = SCNMatrix4(transform)
        let expected = SCNMatrix4MakeScale(1.5, 1.5, 1.5)
        XCTAssert(SCNMatrix4EqualToMatrix4(matrix, expected))
        XCTAssertEqual(transform, Transform(matrix))
    }

    func testOffsetTransformToFromMatrix() {
        let transform = Transform(translation: .init(1, 2, 3))
        let matrix = SCNMatrix4(transform)
        let expected = SCNMatrix4MakeTranslation(1, 2, 3)
        XCTAssert(SCNMatrix4EqualToMatrix4(matrix, expected))
        XCTAssertEqual(transform, Transform(matrix))
    }

    func testRotationTransformToFromMatrix() {
        let transform = Transform(rotation: .init(.yaw(-.pi)))
        let matrix = SCNMatrix4(transform)
        XCTAssertEqual(transform.scale, .one)
        XCTAssertEqual(transform.translation, .zero)
        XCTAssertEqual(transform.rotation, Transform(matrix).rotation)
    }
}

#endif
