//
//  ColorTests.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 31/07/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

final class ColorTests: XCTestCase {
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
