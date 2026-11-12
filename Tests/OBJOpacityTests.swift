//
//  OBJOpacityTests.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 11/11/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import Foundation
import XCTest
#if canImport(SceneKit)
import ImageIO
import ModelIO
import SceneKit
#endif

final class OBJOpacityTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("euclid-obj-opacity-\(UUID())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: directory)
    }

    func testMaterialLibrariesAndMapOptions() throws {
        let subdirectory = directory.appendingPathComponent("materials")
        try FileManager.default.createDirectory(at: subdirectory, withIntermediateDirectories: true)
        let obj = directory.appendingPathComponent("model.obj")
        try "mtllib \"materials/first library.mtl\" second.mtl # comment\n"
            .write(to: obj, atomically: true, encoding: .utf8)
        try """
        newmtl default paint
        map_d -o -1 0 -s 2 3 1 -clamp on "opacity map.png"
        newmtl alpha
        map_d -imfchan m alpha.png
        d 0.4
        newmtl selected
        map_d -imfchan r old.png
        """.write(to: subdirectory.appendingPathComponent("first library.mtl"), atomically: true, encoding: .utf8)
        try """
        newmtl selected
        Tr 0.25
        map_d -imfchan b -blendv off blue.png
        newmtl unsupported
        map_d -mm 0.2 0.8 remapped.png
        newmtl depth
        map_d -imfchan z depth.png
        newmtl incomplete
        map_d -imfchan
        """.write(to: directory.appendingPathComponent("second.mtl"), atomically: true, encoding: .utf8)
        let maps = OBJOpacityMap.read(from: obj)
        XCTAssertEqual(Set(maps.keys), ["default paint", "alpha", "selected"])
        XCTAssertEqual(maps["default paint"]?.channel, .luminance)
        XCTAssertEqual(maps["default paint"]?.url, subdirectory.appendingPathComponent("opacity map.png"))
        XCTAssertEqual(maps["alpha"]?.channel, .alpha)
        XCTAssertEqual(maps["alpha"]?.dissolve, 0.4)
        XCTAssertEqual(maps["selected"]?.dissolve, 0.75)
        XCTAssertEqual(maps["selected"]?.channel, .blue)
        XCTAssertEqual(maps["selected"]?.url, directory.appendingPathComponent("blue.png"))
    }

    func testMissingLibrariesAndUnrelatedMaterialProperties() throws {
        let obj = directory.appendingPathComponent("model.obj")
        try "mtllib missing.mtl input.mtl\n".write(to: obj, atomically: true, encoding: .utf8)
        try """
        newmtl paint
        map_Kd diffuse.png
        d 0.4
        newmtl replaced
        map_d opacity.png
        newmtl replaced
        Kd 1 1 1
        """.write(to: directory.appendingPathComponent("input.mtl"), atomically: true, encoding: .utf8)
        XCTAssertTrue(OBJOpacityMap.read(from: obj).isEmpty)
    }

    #if canImport(SceneKit)

    private func image(
        _ pixels: [UInt8], space: CGColorSpace, alpha: CGImageAlphaInfo = .last,
        order: CGBitmapInfo = [], width: Int = 1, height: Int = 1, bytesPerRow: Int? = nil
    ) throws -> CGImage {
        let components = space.numberOfComponents + (alpha == .none ? 0 : 1)
        return try XCTUnwrap(CGImage(
            width: width, height: height, bitsPerComponent: 8, bitsPerPixel: components * 8,
            bytesPerRow: bytesPerRow ?? width * components, space: space,
            bitmapInfo: CGBitmapInfo(rawValue: alpha.rawValue).union(order),
            provider: XCTUnwrap(CGDataProvider(data: Data(pixels) as CFData)),
            decode: nil, shouldInterpolate: false, intent: .defaultIntent
        ))
    }

    private func alphas(_ image: CGImage, channel: OBJOpacityMap.Channel) throws -> [UInt8] {
        let mask = try XCTUnwrap(image.objOpacityImage(for: channel))
        XCTAssertEqual(mask.width, image.width)
        XCTAssertEqual(mask.height, image.height)
        let data = try XCTUnwrap(mask.dataProvider?.data as Data?)
        return stride(from: 3, to: data.count, by: 4).map { data[$0] }
    }

    func testModelIOOpacityKeepsOrientationAndSamplerSettings() throws {
        let obj = directory.appendingPathComponent("model.obj")
        try ColorImportFixtures.obj.write(to: obj, atomically: true, encoding: .utf8)
        try "newmtl paint\nd 0.4\nmap_d -imfchan r opacity.png\n"
            .write(to: directory.appendingPathComponent("input.mtl"), atomically: true, encoding: .utf8)
        let pixels: [UInt8] = [32, 0, 0, 255, 64, 0, 0, 255, 128, 0, 0, 255, 192, 0, 0, 255]
        let source = try image(pixels, space: CGColorSpaceCreateDeviceRGB(), width: 2, height: 2)
        let destination = try XCTUnwrap(CGImageDestinationCreateWithURL(
            directory.appendingPathComponent("opacity.png") as CFURL, "public.png" as CFString, 1, nil
        ))
        CGImageDestinationAddImage(destination, source, nil)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        let asset = MDLAsset(url: obj)
        asset.loadTextures()
        let mesh = try XCTUnwrap(asset.childObjects(of: MDLMesh.self).first as? MDLMesh)
        let material = try XCTUnwrap((mesh.submeshes?.firstObject as? MDLSubmesh)?.material)
        let original = try XCTUnwrap(material.property(with: .opacity)?.textureSamplerValue)
        let originalTexture = original.texture
        let filter = MDLTextureFilter()
        filter.sWrapMode = .clamp
        filter.tWrapMode = .mirror
        filter.magFilter = .nearest
        original.hardwareFilter = filter
        let transform = MDLTransform()
        transform.translation = [0.2, 0.3, 0]
        original.transform = transform
        for _ in 0 ..< 2 {
            // Repeating normalization must not multiply the scalar twice.
            asset.restoreOBJOpacityMaps(from: obj)
            let sampler = try XCTUnwrap(material.property(with: .opacity)?.textureSamplerValue)
            XCTAssertTrue(sampler.hardwareFilter === filter)
            XCTAssertTrue(sampler.transform === transform)
            let texture = try XCTUnwrap(sampler.texture)
            XCTAssertEqual(texture.channelCount, 1)
            XCTAssertEqual(try XCTUnwrap(texture.texelDataWithTopLeftOrigin()), Data([13, 26, 51, 77]))
            let bridged = try XCTUnwrap(defaultMaterialLookup(material))
            let contents = try XCTUnwrap(bridged.transparent.contents)
            guard CFGetTypeID(contents as CFTypeRef) == CGImage.typeID else {
                return XCTFail("Expected an alpha mask for SceneKit")
            }
            // swiftformat:disable:next noForceUnwrapInTests
            let mask = contents as! CGImage
            XCTAssertEqual(try alphas(mask, channel: .alpha), [13, 26, 51, 77])
        }
        XCTAssertTrue(original.texture === originalTexture, "Normalization must not mutate a shared source sampler")
    }

    func testChannelsDoNotApplyColorSpaceConversion() throws {
        for profile in [CGColorSpace.sRGB, CGColorSpace.linearSRGB, CGColorSpace.displayP3] {
            let source = try image([32, 64, 192, 128], space: XCTUnwrap(CGColorSpace(name: profile)))
            XCTAssertEqual(try alphas(source, channel: .red), [32])
            XCTAssertEqual(try alphas(source, channel: .green), [64])
            XCTAssertEqual(try alphas(source, channel: .blue), [192])
            XCTAssertEqual(try alphas(source, channel: .alpha), [128])
            XCTAssertEqual(try alphas(source, channel: .luminance), [66])
        }
    }

    func testPremultipliedAndLittleEndianPixels() throws {
        for source in try [
            image([32, 16, 48, 128], space: CGColorSpaceCreateDeviceRGB(), alpha: .premultipliedLast),
            image(
                [48, 16, 32, 128],
                space: CGColorSpaceCreateDeviceRGB(),
                alpha: .premultipliedFirst,
                order: .byteOrder32Little
            ),
        ] {
            XCTAssertEqual(try alphas(source, channel: .red), [64])
            XCTAssertEqual(try alphas(source, channel: .green), [32])
            XCTAssertEqual(try alphas(source, channel: .blue), [96])
        }
    }

    func testGrayscaleAndRowPaddingPreserveOrientation() throws {
        let source = try image(
            [32, 64, 0, 128, 192, 0],
            space: CGColorSpaceCreateDeviceGray(),
            alpha: .none,
            width: 2,
            height: 2,
            bytesPerRow: 3
        )
        XCTAssertEqual(try alphas(source, channel: .luminance), [32, 64, 128, 192])
        XCTAssertEqual(try alphas(source, channel: .blue), [32, 64, 128, 192])
    }

    #endif
}
