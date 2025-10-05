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

final class MeshImportTests: XCTestCase {
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

    func testCubeSTLStringData() throws {
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
        let cube = try Mesh(stlData: XCTUnwrap(data))
        let expected = Mesh.cube()
            .translated(by: [0.5, 0.5, 0.5])
            .withoutTexcoords()
            .triangulate()
        XCTAssertEqual(cube, expected)
    }

    // MARK: OBJ import

    func testCubeOBJ() throws {
        let objString = """
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
        """
        let cube = Mesh.cube().translated(by: [0.5, 0.5, 0.5])
        let mesh = try XCTUnwrap(Mesh(objString: objString))
        XCTAssertEqual(mesh, cube)
        XCTAssertTrue(mesh.isWatertight)
        XCTAssertTrue(mesh.isConvex())
    }

    func testCubeOBJWithWhitespaceAndComments() throws {
        let objString = """
         vT 0 1
        vt 1 1

        v 1 0 1
        v 1 0 0
        v 1 1 0 #foo
        V \t1 1 1

        v 0 0 0
        V 0   0 1
        v 0 1 1
        v 0 1 0

         \tf 1/1 2/2 3/3 4/4 

        VT \t 1 0
        Vt 0 \t0

          f 5/1 6/2 7/3 8/4
                F 7/1 4/2 3/3 8/4 #bar
          f 5/1 2/2 1/3 6/4
        f 6/1 1/2 4/3 7/4
           f 2/1 5/2    8/3 3/4
        """
        let cube = Mesh.cube().translated(by: [0.5, 0.5, 0.5])
        let mesh = try XCTUnwrap(Mesh(objString: objString))
        XCTAssertEqual(mesh, cube)
        XCTAssertTrue(mesh.isWatertight)
        XCTAssertTrue(mesh.isConvex())
    }

    func testMalformedOBJFiles() {
        let badOffs: [String] = [
            "", // Empty
            "v 1 0 1\nf -1 -1 -1", // Negative index
            "v 1 0 1\nf 1 2 1", // Index out of bounds
        ]
        for off in badOffs {
            let mesh = Mesh(offString: off) ?? .empty
            XCTAssertEqual(mesh, .empty)
        }
    }

    func testCylinderOBJ() throws {
        let objString = """
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
        """
        let cylinder = Mesh.cylinder(slices: 4)
        let mesh = try XCTUnwrap(Mesh(objString: objString))
        XCTAssertEqual(mesh, cylinder)
        XCTAssertTrue(mesh.isWatertight)
        XCTAssertTrue(mesh.isConvex())
    }

    func testGradientLatheOBJ() throws {
        let objString = """
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
        """
        let cylinder = Mesh.lathe(Path([
            .point(0, 1, color: .red),
            .point(1, 0, color: .green),
            .point(0, -1, color: .blue),
        ]), slices: 4)
        let mesh = try XCTUnwrap(Mesh(objString: objString))
        XCTAssertEqual(mesh, cylinder)
        XCTAssertTrue(mesh.isWatertight)
        XCTAssertTrue(mesh.isConvex())
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

    func testEmptyOFF() {
        let offString = """
        OFF
        0 0 0
        """
        let mesh = Mesh(offString: offString)
        XCTAssertEqual(mesh, .empty)
    }

    func testOFFWithoutTitle() {
        let offString = """
        0 0 0
        """
        let mesh = Mesh(offString: offString)
        XCTAssertEqual(mesh, .empty)
    }

    func testMalformedOFFFiles() {
        let badOffs: [String] = [
            "", // Empty
            "GOO\n0 0 0", // Bad header
            "OFF\n-1 0 0", // Negative vertex count
            "OFF\n0 -1 0", // Negative face count
            "OFF\n2 1 0\n1 0 0\n0 1 0\n3 0 1 2", // Index out of bounds
            "OFF\n2 1 0\n1 0 0\n0 1 0\n3 0 1", // Missing index
        ]
        for off in badOffs {
            let mesh = Mesh(offString: off) ?? .empty
            XCTAssertEqual(mesh, .empty)
        }
    }

    func testDodecahedronOFF() throws {
        // from https://people.sc.fsu.edu/~jburkardt/data/off/off.html
        let offString = """
        OFF
        #
        #  hdodec.off
        #
        20 12 30

         0.485869  0.081684 -0.682249
        -0.485869  0.0816845 -0.682249
        -0.786152 -0.185585 -0.236068
         0.786152  0.185584 0.236068
         0.0       0.249799 0.803619
        -0.485867  0.68225 0.0816817
         0.0       0.721938 0.432444
        -0.300283  0.618035 -0.485868
         0.300283  0.618035 -0.485867
         0.485866  0.68225 0.0816816
         0.48587  -0.682248 -0.0816834
         0.300283 -0.618035 0.485868
        -0.300282 -0.618035 0.485867
         0.0      -0.249798 -0.803619
         0.0      -0.721936 -0.432451
        -0.485869 -0.682249 -0.0816828
        -0.485868 -0.0816825 0.682249
        -0.786152  0.185586 0.236067
         0.786152 -0.185584 -0.236069
         0.485868 -0.0816818 0.682249

        5    3 9 6 4 19    0.800 0.098 0.098
        5    13 14 15 2 1    0.098 0.647 0.400
        5    3 18 0 8 9    0.098 0.098 0.800
        5    2 17 5 7 1    0.898 0.600 0.000
        5    11 12 15 14 10    0.000 0.600 0.800
        5    7 8 0 13 1    0.498 0.000 0.898
        5    5 6 9 8 7    0.498 0.000 0.898
        5    11 19 4 16 12    0.000 0.600 0.800
        5    17 2 15 12 16    0.898 0.600 0.000
        5    18 3 19 11 10    0.098 0.098 0.800
        5    14 13 0 18 10    0.098 0.647 0.400
        5    17 16 4 6 5    0.800 0.098 0.098
        """
        let mesh = try XCTUnwrap(Mesh(offString: offString))
        XCTAssertEqual(mesh.polygons.count, 36)
        XCTAssertTrue(mesh.polygons.allSatisfy { $0.vertices.count == 3 })
        XCTAssertTrue(mesh.isWatertight)
        XCTAssertFalse(mesh.isConvex())
    }
}
