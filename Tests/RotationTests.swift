//
//  RotationTests.swift
//  EuclidTests
//
//  Created by Zack Brown on 20/04/2021.
//  Copyright © 2021 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

class RotationTests: XCTestCase {
    
    // MARK: Rotation axis
    func testRotationIdentityAxis() {
        let r = Rotation.identity
        
        XCTAssertEqual(r.right, Vector(1, 0, 0))
        XCTAssertEqual(r.up, Vector(0, 1, 0))
        XCTAssertEqual(r.forward, Vector(0, 0, 1))
    }
}
