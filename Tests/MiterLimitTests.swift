//
//  MiterLimitTests.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 31.07.26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/Euclid
//

@testable import Euclid
import XCTest

final class MiterLimitTests: XCTestCase {
    func testRatioInitializer() {
        let limit = MiterLimit(ratio: 2)

        XCTAssertEqual(limit.ratio, 2)
    }

    func testNumericLiteralUsesRatio() {
        let limit: MiterLimit = 1.5

        XCTAssertEqual(limit.ratio, 1.5)
    }

    func testAngleInitializer() {
        let limit = MiterLimit(angle: .degrees(90))

        XCTAssertEqual(limit.ratio, sqrt(2), accuracy: epsilon)
        XCTAssertEqual(limit.angle.degrees, 90, accuracy: epsilon)
    }

    func testInfiniteLimit() {
        XCTAssertFalse(MiterLimit.infinity.ratio.isFinite)
        XCTAssertEqual(MiterLimit.infinity.angle, .pi)
    }

    func testEncodingRatio() throws {
        let data = try JSONEncoder().encode(MiterLimit(ratio: 2))
        let ratio = try JSONDecoder().decode(Double.self, from: data)

        XCTAssertEqual(ratio, 2, accuracy: epsilon)
    }

    func testEncodingInfiniteLimit() throws {
        let data = try JSONEncoder().encode(MiterLimit.infinity)
        let string = String(data: data, encoding: .utf8)

        XCTAssertEqual(string, "{\"angle\":3.141592653589793}")
    }

    func testDecodingInfiniteLimit() throws {
        let data = #"{"angle":3.141592653589793}"#.data(using: .utf8)!
        let limit = try JSONDecoder().decode(MiterLimit.self, from: data)

        XCTAssertEqual(limit, .infinity)
    }
}
