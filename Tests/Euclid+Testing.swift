//
//  Euclid+Testing.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 13/06/2022.
//  Copyright © 2022 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

func XCTAssertEqual(
    _ v1: @autoclosure () throws -> Vector,
    _ v2: @autoclosure () throws -> Vector,
    accuracy: Double = epsilon,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
) {
    do {
        let v1 = try v1(), v2 = try v2()
        if !v1.isEqual(to: v2, withPrecision: accuracy) {
            var m = message()
            if m.isEmpty {
                m = "\(v1) is not equal to \(v2) +/1 \(accuracy)"
            }
            XCTFail(m, file: file, line: line)
        }
    } catch {
        XCTFail(error.localizedDescription)
    }
}
