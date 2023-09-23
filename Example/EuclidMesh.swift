//
//  EuclidMesh.swift
//  Example
//
//  Created by Nick Lockwood on 20/09/2023.
//  Copyright © 2023 Nick Lockwood. All rights reserved.
//

import Euclid
import UIKit

let euclidMesh: Mesh = {
    let start = CFAbsoluteTimeGetCurrent()

    // create some geometry using Euclid
    let cube = Mesh.cube(size: 0.8, material: UIColor.red)
    let sphere = Mesh.sphere(slices: 120, material: CGImage.checkerboard())
    let mesh = cube.subtracting(sphere).makeWatertight()

    print("Time:", CFAbsoluteTimeGetCurrent() - start)
    print("Polygons:", mesh.polygons.count)
    print("Triangles:", mesh.triangulate().polygons.count)
    print("Watertight:", mesh.isWatertight)

    return mesh
}()
