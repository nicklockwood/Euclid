//
//  Mesh+Inset.swift
//  Euclid
//
//  Created by Nick Lockwood on 26/07/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

public extension Mesh {
    /// Applies a uniform inset to the faces of the mesh.
    /// - Parameters:
    ///   - distance: The distance by which to inset the polygon faces.
    ///   - isCancelled: Callback used to cancel the operation.
    /// - Returns: A copy of the mesh, inset by the specified distance.
    ///
    /// > Note: Passing a negative `distance` will expand the mesh instead of shrinking it.
    func inset(
        by distance: Double,
        isCancelled: CancellationHandler = { false }
    ) -> Mesh {
        guard !isCancelled() else { return .empty }
        if distance > 0, isPlanar, let plane = polygons.first?.plane, materials.count <= 1 {
            // If mesh is planar, inset edges only rather than making it vanish
            let facingPolygons = polygons.filter {
                $0.plane.normal.dot(plane.normal) > 0
            }
            let outlinePaths = facingPolygons.outlinePaths
            guard !outlinePaths.isEmpty else {
                return .empty
            }
            let hasOpposingFaces = polygons.contains {
                $0.plane.normal.dot(plane.normal) < 0
            }
            let path = Path(unchecked: .subpaths(outlinePaths), plane: plane)
                .inset(by: distance)
            let faces: Faces = hasOpposingFaces ? .frontAndBack : .front
            return Mesh.fill(path, faces: faces, material: materials.first ?? nil, isCancelled: isCancelled)
        }
        var mesh = Mesh(polygons.insetFaces(by: distance, isCancelled: isCancelled))
        let signedVolume = signedVolume
        guard !isCancelled(), distance > 0, signedVolume > epsilon, !mesh.isEmpty else {
            return mesh
        }
        // A positive inset of a solid should shrink toward zero volume, not flip it.
        guard signedVolume * mesh.signedVolume > 0 else {
            return .empty
        }
        if !isCancelled(), !mesh.polygons.holeEdges.isEmpty {
            mesh = mesh.makeWatertight(isCancelled: isCancelled)
            var precision = epsilon * 10
            while !isCancelled(), !mesh.polygons.holeEdges.isEmpty, precision <= distance * 0.25 {
                let holeEdges = mesh.polygons.holeEdges
                let holePoints = holeEdges.endPoints
                let polygons = mesh.polygons.mergingVertices(holePoints, withPrecision: precision)
                let merged = Mesh(polygons).makeWatertight(isCancelled: isCancelled)
                guard merged.polygons.holeEdges.count < holeEdges.count else {
                    precision *= 10
                    continue
                }
                mesh = Mesh(merged.polygons.mergingSmoothVertexNormals())
                precision *= 10
            }
        }
        return signedVolume * mesh.signedVolume > 0 ? mesh : .empty
    }
}
