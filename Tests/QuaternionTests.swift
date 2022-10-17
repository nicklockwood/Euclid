//
//  QuaternionTests.swift
//  Euclid
//
//  Created by Nick Lockwood on 17/10/2022.
//  Copyright © 2022 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

class QuaternionTests: XCTestCase {
    func testNormalizeZeroQuaternion() {
        let q = Quaternion.zero
        XCTAssertEqual(q.normalized(), .zero)
    }
}
