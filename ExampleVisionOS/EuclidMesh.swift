//
//  EuclidMesh.swift
//  ExampleVisionOS
//
//  Created by Hal Mueller on 3/5/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import CoreGraphics
import Euclid

let euclidMesh: Mesh = {
    let start = CFAbsoluteTimeGetCurrent()

    // create some geometry using Euclid
    let cube = Mesh.cube(size: 0.8, material: Color.red)
    let sphere = Mesh.sphere(slices: 120, material: CGImage.checkerboard())
    let mesh = cube.subtracting(sphere).makeWatertight()

    print("Time:", CFAbsoluteTimeGetCurrent() - start)
    print("Polygons:", mesh.polygons.count)
    print("Triangles:", mesh.triangulate().polygons.count)
    print("Watertight:", mesh.isWatertight)

    return mesh
}()
