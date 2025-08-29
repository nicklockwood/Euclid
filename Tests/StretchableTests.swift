//
//  StretchableTests.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 21/11/2022.
//  Copyright © 2022 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

private extension Stretchable {
    func stretched(by scaleFactor: Double, along: Vector) -> Self {
        assert(along.isNormalized)
        return stretched(by: scaleFactor, along: Line(
            unchecked: .zero,
            direction: along.normalized()
        ))
    }
}

class StretchableTests: XCTestCase {
    // MARK: Points

    func testStretchPoint() {
        let p = Vector(1, 1)
        let q = p.stretched(by: 1.5, along: .unitY)
        XCTAssertEqual(q, [1, 1.5])
        let r = p.stretched(by: 1.5, along: -.unitY)
        XCTAssertEqual(r, [1, 1.5])
        let s = p.stretched(by: 1.5, along: .unitX)
        XCTAssertEqual(s, [1.5, 1])
        let t = p.stretched(by: 1.5, along: -.unitX)
        XCTAssertEqual(t, [1.5, 1])
    }

    // MARK: Paths

    func testStretchPath() {
        let p = Path.circle()
        let q = p.stretched(by: 1.5, along: .unitY)
        XCTAssert(q.isEqual(to: p.scaled(by: [1, 1.5, 1])))
        let r = p.stretched(by: 1.5, along: .unitX)
        XCTAssert(r.isEqual(to: p.scaled(by: [1.5, 1, 1])))
    }
}
