//
//  PlaneTests.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 19/12/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

class PlaneTests: XCTestCase {
    func testLinuxTestSuiteIncludesAllTests() {
        #if os(macOS)
        let thisClass = type(of: self)
        let linuxCount = thisClass.__allTests.count
        let darwinCount = thisClass.defaultTestSuite.testCaseCount
        XCTAssertEqual(linuxCount, darwinCount, "run swift test --generate-linuxmain")
        #endif
    }

    func testConcavePolygonClockwiseWinding() {
        var transform = Transform.identity
        var points = [Vector]()
        let sides = 5
        for _ in 0 ..< sides {
            points.append(Vector(0, -0.5).transformed(by: transform))
            transform.rotate(by: .roll(.pi / Double(sides)))
            points.append(Vector(0, -1).transformed(by: transform))
            transform.rotate(by: .roll(.pi / Double(sides)))
        }
        let plane = Plane(points: points)
        XCTAssertEqual(plane?.normal, Vector(0, 0, -1))
    }
    
    func testIntersectionWithParallelPlane() {
        let plane1 = Plane(normal: Vector(0, 1, 0), pointOnPlane: Vector(0, 0, 0))
        let plane2 = Plane(normal: Vector(0, 1, 0), pointOnPlane: Vector(0, 1, 0))
        
        XCTAssertNil(plane1!.intersectionWith(plane2!))
    }
    
    func testIntersectionWithPerpendicularPlane() {
        let plane1 = Plane(normal: Vector(0, 1, 0), pointOnPlane: Vector(0, 0, 0))
        let plane2 = Plane(normal: Vector(1, 0, 0), pointOnPlane: Vector(0, 0, 0))
        
        let intersection = plane1!.intersectionWith(plane2!)
        XCTAssertNotNil(intersection)
        if (intersection != nil) {
            XCTAssert(plane1!.containsPoint(intersection!.point))
            XCTAssert(plane2!.containsPoint(intersection!.point))
            
            XCTAssert(plane1!.containsPoint(intersection!.point + intersection!.direction))
            XCTAssert(plane2!.containsPoint(intersection!.point + intersection!.direction))
        }
    }
    
    func testIntersectionWithRandomPlane() {
        let plane1 = Plane(normal: Vector(1.2, 0.4, 5.7), w: 6)
        let plane2 = Plane(normal: Vector(0.5, 0.7, 0.1), w: 8)
        
        let intersection = plane1!.intersectionWith(plane2!)
        XCTAssertNotNil(intersection)
        if (intersection != nil) {
            XCTAssertEqual(plane1!.normal.dot(intersection!.point), plane1!.w);
            XCTAssertEqual(plane2!.normal.dot(intersection!.point), plane2!.w);
            
            XCTAssert(plane1!.containsPoint(intersection!.point))
            XCTAssert(plane2!.containsPoint(intersection!.point))
            
            XCTAssert(plane1!.containsPoint(intersection!.point + intersection!.direction))
            XCTAssert(plane2!.containsPoint(intersection!.point + intersection!.direction))
        }
    }
}
