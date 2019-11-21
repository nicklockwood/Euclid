//
//  VectorTests.swift
//  GeometryScriptTests
//
//  Created by Nick Lockwood on 20/11/2019.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

class VectorTests: XCTestCase {
    // MARK: Vector length
    
    func testAxisAlignedLength() {
        let vector = Vector(1, 0, 0)
        XCTAssertEqual(vector.length, 1)
    }
    
    func testAngledLength() {
        let vector = Vector(2, 5, 3)
        let length = (2.0 * 2.0 + 5.0 * 5.0 + 3.0 * 3.0).squareRoot()
        XCTAssertEqual(vector.length, length)
    }
    
    // MARK: Angle with vector
    
    func testRightAngle() {
        let vector1 = Vector(1, 0, 0)
        let vector2 = Vector(0, 1, 0)
        XCTAssertEqual(vector1.angleWith(vector2), Double.pi / 2.0)
    }
    
    func testNonNormalizedAngle() {
        let vector1 = Vector(10, 0, 0)
        let vector2 = Vector(-10, 0, 0)
        XCTAssertEqual(vector1.angleWith(vector2), Double.pi)            
    }
    
    // MARK: Angle with plane
    
    func testRightAngleWithPlane() {
        let vector1 = Vector(1, 0, 0)
        let plane = Plane(normal: vector1, pointOnPlane: Vector.zero)
        XCTAssertEqual(vector1.angleWith(plane: plane!), Double.pi / 2.0)
    }
    
    func testNonNormalizedAngleWithPlane() {
        let vector1 = Vector(7, 0, 0)
        let plane = Plane(normal: vector1, pointOnPlane: Vector.zero)
        XCTAssertEqual(vector1.angleWith(plane: plane!), Double.pi / 2.0)
    }
}

