//
//  EuclidMesh.swift
//  Example
//
//  Created by Nick Lockwood on 20/09/2023.
//  Copyright © 2023 Nick Lockwood. All rights reserved.
//

import Euclid
import UIKit

func framingCameraDistance(for bounds: Bounds, fov: Angle) -> Double {
    let radius = bounds.size.length / 2
    return max(radius / sin(fov / 2) * 1.1, 2)
}

let euclidMesh: Mesh = {
    let start = CFAbsoluteTimeGetCurrent()

    // create some geometry using Euclid
    let cube = Mesh.cube(size: 0.8, material: UIColor.red)
    let sphere = Mesh.sphere(slices: 120, material: CGImage.checkerboard())
    // let mesh = cube.subtracting(sphere).makeWatertight()

    let mesh = Mesh.extrude(.text("e").scaled(by: 0.05), along: .text("w")[0], miterLimit: 1)

    print("Time:", CFAbsoluteTimeGetCurrent() - start)
    print("Polygons:", mesh.polygons.count)
    print("Triangles:", mesh.triangulate().polygons.count)
    print("Watertight:", mesh.isWatertight)

    return mesh
}()
