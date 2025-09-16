//
//  MeshImportTests.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 17/12/2023.
//  Copyright © 2023 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

private extension Data {
    init(hexString: String) {
        var bytes = [UInt8]()
        var index = hexString.startIndex
        while let next = hexString.index(index, offsetBy: 2, limitedBy: hexString.endIndex) {
            UInt8(hexString[index ..< next], radix: 16).map { bytes.append($0) }
            index = next
        }
        self.init(bytes)
    }
}

class MeshImportTests: XCTestCase {
    // MARK: STL import

    func testCubeSTL() {
        let cube = Mesh(stlString: """
        solid Foo
        facet normal 1 0 0
        \touter loop
        \t\tvertex 1 0 1
        \t\tvertex 1 0 0
        \t\tvertex 1 1 0
        \tendloop
        endfacet
        facet normal 1 0 0
        \touter loop
        \t\tvertex 1 0 1
        \t\tvertex 1 1 0
        \t\tvertex 1 1 1
        \tendloop
        endfacet
        facet normal -1 0 0
        \touter loop
        \t\tvertex 0 0 0
        \t\tvertex 0 0 1
        \t\tvertex 0 1 1
        \tendloop
        endfacet
        facet normal -1 0 0
        \touter loop
        \t\tvertex 0 0 0
        \t\tvertex 0 1 1
        \t\tvertex 0 1 0
        \tendloop
        endfacet
        facet normal 0 1 0
        \touter loop
        \t\tvertex 0 1 1
        \t\tvertex 1 1 1
        \t\tvertex 1 1 0
        \tendloop
        endfacet
        facet normal 0 1 0
        \touter loop
        \t\tvertex 0 1 1
        \t\tvertex 1 1 0
        \t\tvertex 0 1 0
        \tendloop
        endfacet
        facet normal 0 -1 0
        \touter loop
        \t\tvertex 0 0 0
        \t\tvertex 1 0 0
        \t\tvertex 1 0 1
        \tendloop
        endfacet
        facet normal 0 -1 0
        \touter loop
        \t\tvertex 0 0 0
        \t\tvertex 1 0 1
        \t\tvertex 0 0 1
        \tendloop
        endfacet
        facet normal 0 0 1
        \touter loop
        \t\tvertex 0 0 1
        \t\tvertex 1 0 1
        \t\tvertex 1 1 1
        \tendloop
        endfacet
        facet normal 0 0 1
        \touter loop
        \t\tvertex 0 0 1
        \t\tvertex 1 1 1
        \t\tvertex 0 1 1
        \tendloop
        endfacet
        facet normal 0 0 -1
        \touter loop
        \t\tvertex 1 0 0
        \t\tvertex 0 0 0
        \t\tvertex 0 1 0
        \tendloop
        endfacet
        facet normal 0 0 -1
        \touter loop
        \t\tvertex 1 0 0
        \t\tvertex 0 1 0
        \t\tvertex 1 1 0
        \tendloop
        endfacet
        endsolid Foo
        """)
        let expected = Mesh.cube()
            .translated(by: [0.5, 0.5, 0.5])
            .withoutTexcoords()
            .triangulate()
        XCTAssertEqual(cube, expected)
    }

    func testUppercaseCubeSTL() {
        let cube = Mesh(stlString: """
        SOLID FOO
        FACET NORMAL 1 0 0
        \tOUTER LOOP
        \t\tVERTEX 1 0 1
        \t\tVERTEX 1 0 0
        \t\tVERTEX 1 1 0
        \tENDLOOP
        ENDFACET
        FACET NORMAL 1 0 0
        \tOUTER LOOP
        \t\tVERTEX 1 0 1
        \t\tVERTEX 1 1 0
        \t\tVERTEX 1 1 1
        \tENDLOOP
        ENDFACET
        FACET NORMAL -1 0 0
        \tOUTER LOOP
        \t\tVERTEX 0 0 0
        \t\tVERTEX 0 0 1
        \t\tVERTEX 0 1 1
        \tENDLOOP
        ENDFACET
        FACET NORMAL -1 0 0
        \tOUTER LOOP
        \t\tVERTEX 0 0 0
        \t\tVERTEX 0 1 1
        \t\tVERTEX 0 1 0
        \tENDLOOP
        ENDFACET
        FACET NORMAL 0 1 0
        \tOUTER LOOP
        \t\tVERTEX 0 1 1
        \t\tVERTEX 1 1 1
        \t\tVERTEX 1 1 0
        \tENDLOOP
        ENDFACET
        FACET NORMAL 0 1 0
        \tOUTER LOOP
        \t\tVERTEX 0 1 1
        \t\tVERTEX 1 1 0
        \t\tVERTEX 0 1 0
        \tENDLOOP
        ENDFACET
        FACET NORMAL 0 -1 0
        \tOUTER LOOP
        \t\tVERTEX 0 0 0
        \t\tVERTEX 1 0 0
        \t\tVERTEX 1 0 1
        \tENDLOOP
        ENDFACET
        FACET NORMAL 0 -1 0
        \tOUTER LOOP
        \t\tVERTEX 0 0 0
        \t\tVERTEX 1 0 1
        \t\tVERTEX 0 0 1
        \tENDLOOP
        ENDFACET
        FACET NORMAL 0 0 1
        \tOUTER LOOP
        \t\tVERTEX 0 0 1
        \t\tVERTEX 1 0 1
        \t\tVERTEX 1 1 1
        \tENDLOOP
        ENDFACET
        FACET NORMAL 0 0 1
        \tOUTER LOOP
        \t\tVERTEX 0 0 1
        \t\tVERTEX 1 1 1
        \t\tVERTEX 0 1 1
        \tENDLOOP
        ENDFACET
        FACET NORMAL 0 0 -1
        \tOUTER LOOP
        \t\tVERTEX 1 0 0
        \t\tVERTEX 0 0 0
        \t\tVERTEX 0 1 0
        \tENDLOOP
        ENDFACET
        FACET NORMAL 0 0 -1
        \tOUTER LOOP
        \t\tVERTEX 1 0 0
        \t\tVERTEX 0 1 0
        \t\tVERTEX 1 1 0
        \tENDLOOP
        ENDFACET
        ENDSOLID FOO
        """)
        let expected = Mesh.cube()
            .translated(by: [0.5, 0.5, 0.5])
            .withoutTexcoords()
            .triangulate()
        XCTAssertEqual(cube, expected)
    }

    func testCubeSTLData() {
        let data = Data(hexString: """
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
        let cube = Mesh(stlData: data)
        let expected = Mesh.cube()
            .translated(by: [0.5, 0.5, 0.5])
            .withoutTexcoords()
            .triangulate()
        XCTAssertEqual(cube, expected)
    }

    func testRedCubeSTLData() {
        let data = Data(hexString: """
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
        let cube = Mesh(stlData: data)
        let expected = Mesh.cube(material: Color.red)
            .translated(by: [0.5, 0.5, 0.5])
            .withoutTexcoords()
            .triangulate()
        XCTAssertEqual(cube, expected)
    }

    func testCubeSTLStringData() {
        let data = """
        solid Foo
        facet normal 1 0 0
        \touter loop
        \t\tvertex 1 0 1
        \t\tvertex 1 0 0
        \t\tvertex 1 1 0
        \tendloop
        endfacet
        facet normal 1 0 0
        \touter loop
        \t\tvertex 1 0 1
        \t\tvertex 1 1 0
        \t\tvertex 1 1 1
        \tendloop
        endfacet
        facet normal -1 0 0
        \touter loop
        \t\tvertex 0 0 0
        \t\tvertex 0 0 1
        \t\tvertex 0 1 1
        \tendloop
        endfacet
        facet normal -1 0 0
        \touter loop
        \t\tvertex 0 0 0
        \t\tvertex 0 1 1
        \t\tvertex 0 1 0
        \tendloop
        endfacet
        facet normal 0 1 0
        \touter loop
        \t\tvertex 0 1 1
        \t\tvertex 1 1 1
        \t\tvertex 1 1 0
        \tendloop
        endfacet
        facet normal 0 1 0
        \touter loop
        \t\tvertex 0 1 1
        \t\tvertex 1 1 0
        \t\tvertex 0 1 0
        \tendloop
        endfacet
        facet normal 0 -1 0
        \touter loop
        \t\tvertex 0 0 0
        \t\tvertex 1 0 0
        \t\tvertex 1 0 1
        \tendloop
        endfacet
        facet normal 0 -1 0
        \touter loop
        \t\tvertex 0 0 0
        \t\tvertex 1 0 1
        \t\tvertex 0 0 1
        \tendloop
        endfacet
        facet normal 0 0 1
        \touter loop
        \t\tvertex 0 0 1
        \t\tvertex 1 0 1
        \t\tvertex 1 1 1
        \tendloop
        endfacet
        facet normal 0 0 1
        \touter loop
        \t\tvertex 0 0 1
        \t\tvertex 1 1 1
        \t\tvertex 0 1 1
        \tendloop
        endfacet
        facet normal 0 0 -1
        \touter loop
        \t\tvertex 1 0 0
        \t\tvertex 0 0 0
        \t\tvertex 0 1 0
        \tendloop
        endfacet
        facet normal 0 0 -1
        \touter loop
        \t\tvertex 1 0 0
        \t\tvertex 0 1 0
        \t\tvertex 1 1 0
        \tendloop
        endfacet
        endsolid Foo
        """.data(using: .utf8)
        let cube = Mesh(stlData: data!)
        let expected = Mesh.cube()
            .translated(by: [0.5, 0.5, 0.5])
            .withoutTexcoords()
            .triangulate()
        XCTAssertEqual(cube, expected)
    }

    // MARK: OFF import

    func testCubeOFF() {
        let offString = """
        OFF
        8 6 0
        1 0 1
        1 0 0
        1 1 0
        1 1 1
        0 0 0
        0 0 1
        0 1 1
        0 1 0
        4 0 1 2 3
        4 4 5 6 7
        4 6 3 2 7
        4 4 1 0 5
        4 5 0 3 6
        4 1 4 7 2
        """
        let cube = Mesh.cube().translated(by: [0.5, 0.5, 0.5])
        let mesh = Mesh(offString: offString)
        XCTAssertEqual(mesh, cube.withoutTexcoords())
    }

    func testCubeOFFWithWhitespaceAndComments() {
        let offString = """
        OFF
        # cube
          8 6 0
        1 0   1
         1 0 0
        1 \t1 0
        1 1 1
        # hello
        0 0 0
         0 0 1 #foo
        0 1 1

        0 1 0
        # indices
        4 0 1 2 3
        \t 4 4 5 6 7 #bar
        4 6  3 2 7

        4  4 1 0 5
         4 5 0 3 6\r
        4 1 4 7 2
        """
        let cube = Mesh.cube().translated(by: [0.5, 0.5, 0.5])
        let mesh = Mesh(offString: offString)
        XCTAssertEqual(mesh, cube.withoutTexcoords())
    }
}
