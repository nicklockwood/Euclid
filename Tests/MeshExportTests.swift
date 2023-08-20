//
//  MeshExportTests.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 22/08/2023.
//  Copyright © 2023 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

class MeshExportTests: XCTestCase {
    // MARK: STL export

    func testCubeSTL() {
        let cube = Mesh.cube().translated(by: [0.5, 0.5, 0.5])
        let stl = cube.stlString(options: .init(name: "Foo", indent: " "))
        XCTAssertEqual(stl, """
        solid Foo
        facet normal 1 0 0
         outer loop
          vertex 1 0 1
          vertex 1 0 0
          vertex 1 1 0
         endloop
        endfacet
        facet normal 1 0 0
         outer loop
          vertex 1 0 1
          vertex 1 1 0
          vertex 1 1 1
         endloop
        endfacet
        facet normal -1 0 0
         outer loop
          vertex 0 0 0
          vertex 0 0 1
          vertex 0 1 1
         endloop
        endfacet
        facet normal -1 0 0
         outer loop
          vertex 0 0 0
          vertex 0 1 1
          vertex 0 1 0
         endloop
        endfacet
        facet normal 0 1 0
         outer loop
          vertex 0 1 1
          vertex 1 1 1
          vertex 1 1 0
         endloop
        endfacet
        facet normal 0 1 0
         outer loop
          vertex 0 1 1
          vertex 1 1 0
          vertex 0 1 0
         endloop
        endfacet
        facet normal 0 -1 0
         outer loop
          vertex 0 0 0
          vertex 1 0 0
          vertex 1 0 1
         endloop
        endfacet
        facet normal 0 -1 0
         outer loop
          vertex 0 0 0
          vertex 1 0 1
          vertex 0 0 1
         endloop
        endfacet
        facet normal 0 0 1
         outer loop
          vertex 0 0 1
          vertex 1 0 1
          vertex 1 1 1
         endloop
        endfacet
        facet normal 0 0 1
         outer loop
          vertex 0 0 1
          vertex 1 1 1
          vertex 0 1 1
         endloop
        endfacet
        facet normal 0 0 -1
         outer loop
          vertex 1 0 0
          vertex 0 0 0
          vertex 0 1 0
         endloop
        endfacet
        facet normal 0 0 -1
         outer loop
          vertex 1 0 0
          vertex 0 1 0
          vertex 1 1 0
         endloop
        endfacet
        endsolid Foo
        """)
    }

    func testCubeSTLData() {
        let cube = Mesh.cube().translated(by: [0.5, 0.5, 0.5])
        let stlData = cube.stlData()
        XCTAssertEqual(stlData.count, 80 + 4 + 12 * 50)
        let hex = stlData.reduce(into: "") { $0 += String(format: "%02x", $1) }
        XCTAssertEqual(hex, """
        000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000\
        00000000000000000000000000000000000000000000000000c0000000000803f00000000000000000000803f000000000000803f000080\
        3f00000000000000000000803f0000803f0000000000000000803f00000000000000000000803f000000000000803f0000803f0000803f0\
        00000000000803f0000803f0000803f0000000080bf000000800000008000000000000000000000000000000000000000000000803f0000\
        00000000803f0000803f0000000080bf0000008000000080000000000000000000000000000000000000803f0000803f000000000000803\
        f000000000000000000000000803f00000000000000000000803f0000803f0000803f0000803f0000803f0000803f0000803f0000000000\
        00000000000000803f00000000000000000000803f0000803f0000803f0000803f00000000000000000000803f000000000000000000800\
        00080bf000000800000000000000000000000000000803f00000000000000000000803f000000000000803f000000000080000080bf0000\
        00800000000000000000000000000000803f000000000000803f00000000000000000000803f000000000000000000000000803f0000000\
        0000000000000803f0000803f000000000000803f0000803f0000803f0000803f000000000000000000000000803f000000000000000000\
        00803f0000803f0000803f0000803f000000000000803f0000803f00000000008000000080000080bf0000803f000000000000000000000\
        0000000000000000000000000000000803f0000000000000000008000000080000080bf0000803f0000000000000000000000000000803f\
        000000000000803f0000803f000000000000
        """)
    }

    func testRedCubeSTLData() {
        let cube = Mesh.cube(material: Color.red).translated(by: [0.5, 0.5, 0.5])
        let stlData = cube.stlData()
        XCTAssertEqual(stlData.count, 80 + 4 + 12 * 50)
        let hex = stlData.reduce(into: "") { $0 += String(format: "%02x", $1) }
        XCTAssertEqual(hex, """
        000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000\
        00000000000000000000000000000000000000000000000000c0000000000803f00000000000000000000803f000000000000803f000080\
        3f00000000000000000000803f0000803f0000000000fc0000803f00000000000000000000803f000000000000803f0000803f0000803f0\
        00000000000803f0000803f0000803f00fc000080bf000000800000008000000000000000000000000000000000000000000000803f0000\
        00000000803f0000803f00fc000080bf0000008000000080000000000000000000000000000000000000803f0000803f000000000000803\
        f0000000000fc000000000000803f00000000000000000000803f0000803f0000803f0000803f0000803f0000803f0000803f0000000000\
        fc000000000000803f00000000000000000000803f0000803f0000803f0000803f00000000000000000000803f0000000000fc000000800\
        00080bf000000800000000000000000000000000000803f00000000000000000000803f000000000000803f00fc00000080000080bf0000\
        00800000000000000000000000000000803f000000000000803f00000000000000000000803f00fc00000000000000000000803f0000000\
        0000000000000803f0000803f000000000000803f0000803f0000803f0000803f00fc00000000000000000000803f000000000000000000\
        00803f0000803f0000803f0000803f000000000000803f0000803f00fc0000008000000080000080bf0000803f000000000000000000000\
        0000000000000000000000000000000803f0000000000fc0000008000000080000080bf0000803f0000000000000000000000000000803f\
        000000000000803f0000803f0000000000fc
        """)
    }

    // MARK: OBJ export

    func testCubeOBJ() {
        let cube = Mesh.cube().translated(by: [0.5, 0.5, 0.5])
        let obj = cube.objString()
        XCTAssertEqual(obj, """
        v 1 0 1
        v 1 0 0
        v 1 1 0
        v 1 1 1
        v 0 0 0
        v 0 0 1
        v 0 1 1
        v 0 1 0

        vt 0 1
        vt 1 1
        vt 1 0
        vt 0 0

        f 1/1 2/2 3/3 4/4
        f 5/1 6/2 7/3 8/4
        f 7/1 4/2 3/3 8/4
        f 5/1 2/2 1/3 6/4
        f 6/1 1/2 4/3 7/4
        f 2/1 5/2 8/3 3/4
        """)
    }

    func testCylinderOBJ() {
        let cylinder = Mesh.cylinder(slices: 4)
        let obj = cylinder.objString()
        XCTAssertEqual(obj, """
        v 0 0.5 0
        v -0.5 0.5 0
        v 0 0.5 0.5
        v -0.5 -0.5 0
        v 0 -0.5 0.5
        v 0 -0.5 0
        v 0.5 0.5 0
        v 0.5 -0.5 0
        v 0 0.5 -0.5
        v 0 -0.5 -0.5

        vt 0.125 0
        vt 0 0
        vt 0.25 0
        vt 0 1
        vt 0.25 1
        vt 0.125 1
        vt 0.375 0
        vt 0.5 0
        vt 0.5 1
        vt 0.375 1
        vt 0.625 0
        vt 0.75 0
        vt 0.75 1
        vt 0.625 1
        vt 0.875 0
        vt 1 0
        vt 1 1
        vt 0.875 1

        vn 0 1 0
        vn -6.12323e-17 0 1
        vn -1 0 0
        vn 0 -1 0
        vn 1 0 1.22465e-16
        vn 1.83697e-16 0 -1
        vn -1 0 -2.44929e-16

        f 1/1/1 2/2/1 3/3/1
        f 3/3/2 2/2/3 4/4/3 5/5/2
        f 5/5/4 4/4/4 6/6/4
        f 1/7/1 3/3/1 7/8/1
        f 7/8/5 3/3/2 5/5/2 8/9/5
        f 8/9/4 5/5/4 6/10/4
        f 1/11/1 7/8/1 9/12/1
        f 9/12/6 7/8/5 8/9/5 10/13/6
        f 10/13/4 8/9/4 6/14/4
        f 1/15/1 9/12/1 2/16/1
        f 2/16/7 9/12/6 10/13/6 4/17/7
        f 4/17/4 10/13/4 6/18/4
        """)
    }

    func testGradientLatheOBJ() {
        let cylinder = Mesh.lathe(Path([
            .point(0, 1, color: .red),
            .point(1, 0, color: .green),
            .point(0, -1, color: .blue),
        ]), slices: 4)
        let obj = cylinder.objString()
        XCTAssertEqual(obj, """
        v 0 1 0 1 0 0
        v -1 0 0 0 1 0
        v 0 0 1 0 1 0
        v 0 -1 0 0 0 1
        v 1 0 0 0 1 0
        v 0 0 -1 0 1 0

        vt 0.125 0
        vt 0 0.5
        vt 0.25 0.5
        vt 0.125 1
        vt 0.375 0
        vt 0.5 0.5
        vt 0.375 1
        vt 0.625 0
        vt 0.75 0.5
        vt 0.625 1
        vt 0.875 0
        vt 1 0.5
        vt 0.875 1

        vn -0.707107 0.707107 0
        vn -4.32978e-17 0.707107 0.707107
        vn -4.32978e-17 -0.707107 0.707107
        vn -0.707107 -0.707107 0
        vn 0.707107 0.707107 8.65956e-17
        vn 0.707107 -0.707107 8.65956e-17
        vn 1.29893e-16 0.707107 -0.707107
        vn 1.29893e-16 -0.707107 -0.707107
        vn -0.707107 0.707107 -1.73191e-16
        vn -0.707107 -0.707107 -1.73191e-16

        f 1/1/1 2/2/1 3/3/2
        f 3/3/3 2/2/4 4/4/4
        f 1/5/2 3/3/2 5/6/5
        f 5/6/6 3/3/3 4/7/3
        f 1/8/5 5/6/5 6/9/7
        f 6/9/8 5/6/6 4/10/6
        f 1/11/7 6/9/7 2/12/9
        f 2/12/10 6/9/8 4/13/8
        """)
    }
}
