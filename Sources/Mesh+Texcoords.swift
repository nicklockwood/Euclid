//
//  Mesh+Texcoords.swift
//  Euclid
//
//  Created by Nick Lockwood on 10/09/2023.
//  Copyright © 2023 Nick Lockwood. All rights reserved.
//

public extension Mesh {
    /// Return a copy of the mesh without texture coordinates.
    func withoutTexcoords() -> Mesh {
        Mesh(
            unchecked: polygons.mapTexcoords { _ in .zero },
            bounds: boundsIfSet,
            bsp: nil, // TODO: Can we update this directly?
            isConvex: isKnownConvex,
            isWatertight: watertightIfSet,
            isPlanar: planarIfSet,
            submeshes: submeshesIfEmpty
        )
    }

    /// Return a copy of the mesh with transformed texture coordinates.
    /// - Parameter transform: The transform to apply to the texture coordinates.
    func withTextureTransform(_ transform: Transform) -> Mesh {
        Mesh(
            unchecked: polygons.mapTexcoords { $0.transformed(by: transform) },
            bounds: boundsIfSet,
            bsp: nil, // TODO: Can we update this directly?
            isConvex: isKnownConvex,
            isWatertight: watertightIfSet,
            isPlanar: planarIfSet,
            submeshes: submeshesIfEmpty
        )
    }

    /// Return a copy of the mesh with spherically-mapped texture coordinates.
    func sphereMapped() -> Mesh {
        mapPolygonTexcoords { p in
            let c = p.centroid
            let ch = Vector(c.x, c.z), cv = Vector(ch.length, c.y)
            let chn = ch.normalized(), cvn = cv.normalized()
            let cha = Angle.atan2(y: chn.y, x: chn.x)
            let cva = Angle.atan2(y: cvn.y, x: cvn.x)
            return p.vertices.map {
                let p = $0.position
                let h = Vector(p.x, p.z), v = Vector(h.length, p.y)
                let ha, va: Angle
                // TODO: can we find a less arbitrary value for this?
                let epsilon = 0.1
                if h.length < epsilon, h.length < ch.length {
                    ha = cha
                } else {
                    let n = h.normalized()
                    let a = Angle.atan2(y: n.y, x: n.x)
                    let a2 = (a - cha).radians
                    if !angleBetweenNormalizedVectors(n, chn).radians.isApproximatelyEqual(
                        to: abs(a2),
                        absoluteTolerance: .pi
                    ) {
                        ha = a2 > 0 ? a - .twoPi : a + .twoPi
                    } else {
                        ha = a
                    }
                }
                if v.length < epsilon, v.length < cv.length {
                    va = cva
                } else {
                    let n = v.normalized()
                    let a = Angle.atan2(y: n.y, x: n.x)
                    let a2 = (a - cva).radians
                    if !angleBetweenNormalizedVectors(n, cvn).radians.isApproximatelyEqual(
                        to: abs(a2),
                        absoluteTolerance: .pi
                    ) {
                        va = a2 > 0 ? a - .twoPi : a + .twoPi
                    } else {
                        va = a
                    }
                }
                let x = ha / -.twoPi + 0.5
                let y = va / -.pi + 0.5
                return $0.withTexcoord([x, y])
            }
        }
    }

    /// Return a copy of the mesh with cylindrically-mapped texture coordinates.
    func cylinderMapped() -> Mesh {
        let height = bounds.size.y
        return mapPolygonTexcoords { p in
            let c = p.centroid, cd = Vector(c.x, c.z)
            let cn = cd.normalized()
            let ca = Angle.atan2(y: cn.y, x: cn.x)
            return p.vertices.map {
                let p = $0.position, d = Vector(p.x, p.z)
                let ha: Angle
                // TODO: can we find a less arbitrary value for this?
                let epsilon = 0.1
                if cd.length < epsilon {
                    ha = d.length < epsilon ? ca : Angle.atan2(y: d.y, x: d.x)
                } else if d.length < epsilon, d.length < cd.length {
                    ha = ca
                } else {
                    let n = d.normalized()
                    let a = Angle.atan2(y: n.y, x: n.x)
                    let a2 = (a - ca).radians
                    if !angleBetweenNormalizedVectors(n, cn).radians.isApproximatelyEqual(
                        to: abs(a2),
                        absoluteTolerance: .pi
                    ) {
                        ha = a2 > 0 ? a - .twoPi : a + .twoPi
                    } else {
                        ha = a
                    }
                }
                let x = ha / -.twoPi + 0.5
                let y = height > epsilon ? (bounds.max.y - p.y) / height : 0
                return $0.withTexcoord([x, y])
            }
        }
    }

    /// Return a copy of the mesh with cube-mapped texture coordinates.
    func cubeMapped() -> Mesh {
        func normalized(_ value: Double, _ min: Double, _ size: Double) -> Double {
            size > epsilon ? (value - min) / size : 0
        }

        return mapPolygonTexcoords { p in
            let n = p.plane.normal
            return p.vertices.map {
                let v = $0.position
                let texcoord: Vector
                switch n.mostParallelAxis {
                case .unitX:
                    let x = n.x > 0 ?
                        normalized(bounds.max.z - v.z, 0, bounds.size.z) :
                        normalized(v.z - bounds.min.z, 0, bounds.size.z)
                    let y = normalized(bounds.max.y - v.y, 0, bounds.size.y)
                    texcoord = [x, y]
                case .unitY:
                    let x = normalized(v.x - bounds.min.x, 0, bounds.size.x)
                    let y = n.y > 0 ?
                        normalized(v.z - bounds.min.z, 0, bounds.size.z) :
                        normalized(bounds.max.z - v.z, 0, bounds.size.z)
                    texcoord = [x, y]
                default:
                    let x = n.z > 0 ?
                        normalized(v.x - bounds.min.x, 0, bounds.size.x) :
                        normalized(bounds.max.x - v.x, 0, bounds.size.x)
                    let y = normalized(bounds.max.y - v.y, 0, bounds.size.y)
                    texcoord = [x, y]
                }
                return $0.withTexcoord(texcoord)
            }
        }
    }
}

private extension Mesh {
    func mapPolygonTexcoords(_ fn: (Polygon) -> [Vertex]) -> Mesh {
        Mesh(
            unchecked: polygons.map {
                Polygon(
                    unchecked: fn($0),
                    plane: $0.plane,
                    isConvex: $0.isConvex,
                    sanitizeNormals: false,
                    material: $0.material
                )
            },
            bounds: boundsIfSet,
            bsp: nil, // TODO: Can we update this directly?
            isConvex: isKnownConvex,
            isWatertight: watertightIfSet,
            isPlanar: planarIfSet,
            submeshes: submeshesIfEmpty
        )
    }
}
