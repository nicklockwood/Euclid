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
            submeshes: submeshesIfEmpty
        )
    }

    /// Return a copy of the mesh with spherically-mapped texture coordinates.
    func sphereMapped() -> Mesh {
        mapPolygonTexcoords { p in
            let c = p.center
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
                    if !angleBetweenNormalizedVectors(n, chn).radians.isEqual(to: abs(a2), withPrecision: .pi) {
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
                    if !angleBetweenNormalizedVectors(n, cvn).radians.isEqual(to: abs(a2), withPrecision: .pi) {
                        va = a2 > 0 ? a - .twoPi : a + .twoPi
                    } else {
                        va = a
                    }
                }
                let x = ha.radians / -Angle.twoPi.radians + 0.5
                let y = va.radians / -.pi + 0.5
                return $0.withTexcoord([x, y])
            }
        }
    }

    /// Return a copy of the mesh with cylindrically-mapped texture coordinates.
    func cylinderMapped() -> Mesh {
        mapPolygonTexcoords { p in
            let c = p.center, cd = Vector(c.x, c.z)
            let cn = cd.normalized()
            let ca = Angle.atan2(y: cn.y, x: cn.x)
            return p.vertices.map {
                let p = $0.position, d = Vector(p.x, p.z)
                let ha: Angle
                // TODO: can we find a less arbitrary value for this?
                let epsilon = 0.1
                if d.length < epsilon, d.length < cd.length {
                    ha = ca
                } else {
                    let n = d.normalized()
                    let a = Angle.atan2(y: n.y, x: n.x)
                    let a2 = (a - ca).radians
                    if !angleBetweenNormalizedVectors(n, cn).radians.isEqual(to: abs(a2), withPrecision: .pi) {
                        ha = a2 > 0 ? a - .twoPi : a + .twoPi
                    } else {
                        ha = a
                    }
                }
                let x = ha.radians / -Angle.twoPi.radians + 0.5
                let y = (p.y - bounds.min.y) / -bounds.size.y
                return $0.withTexcoord([x, y])
            }
        }
    }

    /// Return a copy of the mesh with cube-mapped texture coordinates.
    func cubeMapped() -> Mesh {
        mapPolygonTexcoords { p in
            let n = p.plane.normal, f = FlatteningPlane(normal: n)
            func coords(for v: Vector) -> (h: Vector, v: Vector) {
                switch f {
                case .xy:
                    let sign = n.z < 0 ? -1.0 : 1.0
                    return ([v.x, v.z], [v.z, sign * v.y])
                case .xz:
                    let sign = n.y < 0 ? -1.0 : 1.0
                    return ([sign * v.x, v.y], [v.z, v.y])
                case .yz:
                    let sign = n.x > 0 ? -1.0 : 1.0
                    return ([v.x, v.z], [sign * v.y, v.x])
                }
            }

            let (ch, cv) = coords(for: p.center)
            let chn = ch.normalized(), cvn = cv.normalized()
            let cha = Angle.atan2(y: chn.y, x: chn.x)
            let cva = Angle.atan2(y: cvn.y, x: cvn.x)
            return p.vertices.map {
                let (h, v) = coords(for: $0.position)
                let ha, va: Angle
                // TODO: can we find a less arbitrary value for this?
                let epsilon = 0.1
                if h.length < epsilon, h.length < ch.length {
                    ha = cha
                } else {
                    let n = h.normalized()
                    let a = Angle.atan2(y: n.y, x: n.x)
                    let a2 = (a - cha).radians
                    if !angleBetweenNormalizedVectors(n, chn).radians.isEqual(to: abs(a2), withPrecision: .pi) {
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
                    if !angleBetweenNormalizedVectors(n, cvn).radians.isEqual(to: abs(a2), withPrecision: .pi) {
                        va = a2 > 0 ? a - .twoPi : a + .twoPi
                    } else {
                        va = a
                    }
                }
                let scale = -Double.pi / 2
                let x = ha.radians / scale + 0.5
                let y = va.radians / scale + 0.5
                return $0.withTexcoord([x, y])
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
            submeshes: submeshesIfEmpty
        )
    }
}
