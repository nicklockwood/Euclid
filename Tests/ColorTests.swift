//
//  ColorTests.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 31/07/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

final class ColorTests: XCTestCase {
    func testSRGBTransferFunctionsPreserveAlphaAndExtendedRange() {
        let encoded = Color(red: 0.5, green: 0.02, blue: 1.25, alpha: 0.5)
        let linear = encoded.toLinear()
        XCTAssertEqual(linear.red, 0.21404114048223255, accuracy: 1e-12)
        XCTAssertEqual(linear.green, 0.02 / 12.92, accuracy: 1e-12)
        XCTAssertEqual(linear.alpha, 0.5)
        XCTAssertEqual(linear.toSRGB(), encoded, accuracy: 1e-12)
        XCTAssertEqual(Color(white: -0.5).toLinear().red, -linear.red, accuracy: 1e-12)
        XCTAssertEqual(Color(white: 0.002).toSRGB().red, 0.02584, accuracy: 1e-12)
    }

    #if canImport(UIKit) || canImport(AppKit)
    func testPlatformColorConversionsUseSRGBByDefault() throws {
        let color = Color(red: 0.5, green: 0.25, blue: 0.75, alpha: 0.4)
        let srgb = try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB))
        let linear = try XCTUnwrap(CGColorSpace(name: CGColorSpace.extendedLinearSRGB))
        let input = OSColor(red: 0.5, green: 0.25, blue: 0.75, alpha: 0.4)
        XCTAssertEqual(Color(input), color, accuracy: 1e-6)
        XCTAssertEqual(Color(OSColor(color), colorSpace: srgb), color, accuracy: 1e-6)
        XCTAssertEqual(Color(OSColor(color), colorSpace: linear), color.toLinear(), accuracy: 1e-6)
        XCTAssertEqual(Color(OSColor(color.toLinear(), colorSpace: linear)), color, accuracy: 1e-6)
        XCTAssertEqual(Color(input, colorSpace: nil), color, accuracy: 1e-6)
        XCTAssertEqual(Color(CGColor(gray: 0.5, alpha: 0.4)).alpha, 0.4, accuracy: 1e-6)
    }

    func testPlatformColorImportConvertsDisplayP3() throws {
        let space = try XCTUnwrap(CGColorSpace(name: CGColorSpace.displayP3))
        let srgb = try XCTUnwrap(CGColorSpace(name: CGColorSpace.extendedSRGB))
        let input = try XCTUnwrap(CGColor(colorSpace: space, components: [0.7, 0.3, 0.2, 0.4]))
        let expected = try XCTUnwrap(input.converted(to: srgb, intent: .defaultIntent, options: nil))
        XCTAssertEqual(Color(input), Color(expected, colorSpace: nil), accuracy: 1e-6)
        XCTAssertEqual(Color(OSColor(Color(input))), Color(input), accuracy: 1e-6)
    }

    func testComponentMultiplicationMatchesPlatformColorConversion() {
        let color = Color(red: 0.5, green: 0.25, blue: 0.75, alpha: 0.4)
        let product = Color(OSColor(color)) * Color(OSColor(color))
        XCTAssertEqual(product, Color(red: 0.25, green: 0.0625, blue: 0.5625, alpha: 0.16), accuracy: 1e-6)
    }
    #endif

    func testCompositedOpaqueForeground() {
        XCTAssertEqual(Color.red.composited(over: .blue.withAlphaComponent(0.5)), .red)
    }

    func testCompositedTransparentForeground() {
        let background = Color.blue.withAlphaComponent(0.5)
        XCTAssertEqual(Color.red.withAlphaComponent(0).composited(over: background), background)
    }

    func testCompositedTransparentBackground() {
        let foreground = Color.red.withAlphaComponent(0.5)
        XCTAssertEqual(foreground.composited(over: .blue.withAlphaComponent(0)), foreground)
    }

    func testCompositedTransparentColors() {
        XCTAssertEqual(
            Color.red.withAlphaComponent(0).composited(over: .blue.withAlphaComponent(0)),
            .clear
        )
    }

    func testCompositedOntoOpaqueBackground() {
        XCTAssertEqual(
            Color.red.withAlphaComponent(0.5).composited(over: .blue),
            Color(red: 0.5, green: 0, blue: 0.5),
            accuracy: epsilon
        )
    }

    func testCompositedTranslucentColors() {
        XCTAssertEqual(
            Color.red.withAlphaComponent(0.5).composited(over: .blue.withAlphaComponent(0.5)),
            Color(red: 2.0 / 3, green: 0, blue: 1.0 / 3, alpha: 0.75),
            accuracy: epsilon
        )
    }

    func testCollectionLerp() {
        let colors: [Color] = [.red, .green, .blue]
        XCTAssertEqual(colors.lerp(-1), .red)
        XCTAssertEqual(colors.lerp(0.25), Color(red: 0.5, green: 0.5, blue: 0))
        XCTAssertEqual(colors.lerp(0.5), .green)
        XCTAssertEqual(colors.lerp(0.75), Color(red: 0, green: 0.5, blue: 0.5))
        XCTAssertEqual(colors.lerp(2), .blue)
        XCTAssertEqual([Color]().lerp(0.5), .clear)
        XCTAssertEqual([Color.red].lerp(0.5), .red)
        XCTAssertEqual(colors[1...].lerp(0.5), Color(red: 0, green: 0.5, blue: 0.5))
    }

    func testHSBInitializer() {
        XCTAssertEqual(Color(hue: 0, saturation: 1, brightness: 1), .red, accuracy: epsilon)
        XCTAssertEqual(Color(hue: 1.0 / 6, saturation: 1, brightness: 1), .yellow, accuracy: epsilon)
        XCTAssertEqual(Color(hue: 2.0 / 6, saturation: 1, brightness: 1), .green, accuracy: epsilon)
        XCTAssertEqual(Color(hue: 3.0 / 6, saturation: 1, brightness: 1), .cyan, accuracy: epsilon)
        XCTAssertEqual(Color(hue: 4.0 / 6, saturation: 1, brightness: 1), .blue, accuracy: epsilon)
        XCTAssertEqual(Color(hue: 5.0 / 6, saturation: 1, brightness: 1), .magenta, accuracy: epsilon)
    }

    func testHSBInitializerWithAlpha() {
        XCTAssertEqual(
            Color(hue: 0, saturation: 1, brightness: 1, alpha: 0.5),
            Color.red.withAlphaComponent(0.5),
            accuracy: epsilon
        )
    }

    func testHSBInitializerWrapsHue() {
        XCTAssertEqual(
            Color(hue: 1, saturation: 1, brightness: 1),
            .red,
            accuracy: epsilon
        )
        XCTAssertEqual(
            Color(hue: -1.0 / 6, saturation: 1, brightness: 1),
            .magenta,
            accuracy: epsilon
        )
    }

    func testHSBInitializerWithZeroSaturation() {
        XCTAssertEqual(
            Color(hue: 0.5, saturation: 0, brightness: 0.5),
            .gray,
            accuracy: epsilon
        )
    }

    func testHSBComponents() {
        let color = Color(hue: 0.2, saturation: 0.75, brightness: 0.8, alpha: 0.5)
        let hsb = color.hsbComponents
        XCTAssertEqual(hsb.hue, 0.2, accuracy: epsilon)
        XCTAssertEqual(hsb.saturation, 0.75, accuracy: epsilon)
        XCTAssertEqual(hsb.brightness, 0.8, accuracy: epsilon)
        XCTAssertEqual(hsb.alpha, 0.5, accuracy: epsilon)
    }

    func testHSBComponentsForGray() {
        XCTAssertEqual(Color.gray.hue, 0, accuracy: epsilon)
        XCTAssertEqual(Color.gray.saturation, 0, accuracy: epsilon)
        XCTAssertEqual(Color.gray.brightness, 0.5, accuracy: epsilon)
    }
}
