//
//  SceneKitTests.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 06/09/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

#if canImport(SceneKit)
import SceneKit
#endif

@testable import Euclid
import XCTest

class SceneKitTests: XCTestCase {
    func testGeometryImportedWithCorrectDetail() {
        #if canImport(SceneKit)
        let sphere = SCNSphere(radius: 0.5)
        sphere.segmentCount = 3
        let mesh = Mesh(sphere)
        XCTAssertEqual(mesh?.polygons.count ?? 0, 12)
        #endif
    }
}
