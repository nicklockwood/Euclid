//
//  Shapes.swift
//  Euclid
//
//  Created by Nick Lockwood on 03/01/2022.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/Euclid
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

public extension Path {
    /// Creates a linear path from a line segment.
    /// - Parameters:
    ///   - line: The ``LineSegment`` defining the path.
    ///   - color: An optional ``Color`` to apply to the path's points.
    static func line(_ line: LineSegment, color: Color? = nil) -> Path {
        .line(line.start, line.end, color: color)
    }

    /// Create a linear path from a start and end point.
    /// - Parameters:
    ///   - start: The starting point of the line.
    ///   - end: The ending point of the line.
    ///   - color: An optional ``Color`` to apply to the path's points.
    static func line(_ start: Vector, _ end: Vector, color _: Color? = nil) -> Path {
        Path([.point(start), .point(end)])
    }

    /// Creates a closed circular path.
    /// - Parameters:
    ///   - radius: The distance from the center of the circle to each point used to approximate its shape.
    ///   - segments: The number of line segments used to approximate the circle.
    ///   - color: An optional ``Color`` to apply to the path's points.
    ///
    /// > Note: Because the circle is approximated using line segments, its radius is not uniform. The radius
    /// specified is the *outer* radius, i.e. the radius at the corners of the polygon.
    static func circle(
        radius r: Double = 0.5,
        segments: Int = 16,
        color: Color? = nil
    ) -> Path {
        ellipse(width: r * 2, height: r * 2, segments: segments, color: color)
    }

    /// Creates a closed elliptical path.
    /// - Parameters:
    ///   - width: The horizontal diameter of the ellipse.
    ///   - height: The vertical diameter of the ellipse.
    ///   - segments: The number of line segments used to approximate the ellipse.
    ///   - color: An optional ``Color`` to apply to the path's points.
    static func ellipse(
        width: Double,
        height: Double,
        segments: Int = 16,
        color: Color? = nil
    ) -> Path {
        let segments = max(3, segments)
        let step = 2 / Double(segments) * .pi
        let to = 2 * .pi + epsilon
        let w = max(abs(width / 2), epsilon)
        let h = max(abs(height / 2), epsilon)
        return Path(unchecked: stride(from: 0, through: to, by: step).map {
            PathPoint.curve(w * -sin($0), h * cos($0), color: color)
        }, plane: .xy, subpathIndices: [])
    }

    /// Creates a closed regular polygon.
    /// - Parameters:
    ///   - radius: The distance from the center of the polygon to each point.
    ///   - sides: The number of sides on the polygon.
    ///   - color: An optional ``Color`` to apply to the path's points.
    static func polygon(
        radius: Double = 0.5,
        sides: Int,
        color: Color? = nil
    ) -> Path {
        let circle = self.circle(radius: radius, segments: sides)
        return Path(unchecked: circle.points.map {
            .point($0.position, color: color)
        }, plane: .xy, subpathIndices: [])
    }

    /// Creates a closed square path.
    /// - Parameters:
    ///   - size: The width and height of the square.
    ///   - color: An optional ``Color`` to apply to the path's points.
    static func square(size: Double = 1, color: Color? = nil) -> Path {
        rectangle(width: size, height: size, color: color)
    }

    /// Creates a closed rectangular path.
    /// - Parameters:
    ///   - width: The width of the rectangle.
    ///   - height: The height of the rectangle.
    ///   - color: An optional ``Color`` to apply to the path's points.
    static func rectangle(
        width: Double,
        height: Double,
        color: Color? = nil
    ) -> Path {
        let w = width / 2, h = height / 2
        if height < epsilon {
            return .line(Vector(-w, 0), Vector(w, 0))
        } else if width < epsilon {
            return .line(Vector(0, -h), Vector(0, h))
        }
        return Path(unchecked: [
            .point(-w, h, color: color), .point(-w, -h, color: color),
            .point(w, -h, color: color), .point(w, h, color: color),
            .point(-w, h, color: color),
        ], plane: .xy, subpathIndices: [])
    }

    /// Creates a quadratic bezier spline.
    ///
    /// The method takes an array of ``PathPoint`` and a `detail` argument.
    /// Normally, the ``PathPoint/isCurved`` property is used to calculate surface normals
    /// (for lighting purposes), but with the ``Path/curve(_:detail:)`` method it actually affects
    /// the shape of the ``Path``.
    ///
    /// A sequence of regular (non-curved) ``PathPoint``s creates sharp corners in the ``Path`` as
    /// normal, but curved points are treated as off-curve Bezier control points.
    ///
    /// The method uses second-order (quadratic) Bezier curves, where each curve has two on-curve end
    /// points and a single off-curve control point. If two curved ``PathPoint`` are used in sequence
    /// then an on-curve point is interpolated between them. It is therefore  possible to create curves
    /// entirely out of curved (off-curve) control points.
    ///
    /// This approach to curve generation is based on the popular [TrueType (TTF) font system](
    /// https://developer.apple.com/fonts/TrueType-Reference-Manual/RM01/Chap1.html
    /// ), and provides a good balance between simplicity and flexibility.
    ///
    /// For more complex curves, on macOS and iOS you can create Euclid ``Path`` from a `CGPath`
    /// by using the `CGPath.paths()` extension method. `CGPath` supports cubic bezier curves as
    /// well as quadratic, and has convenience constructors for rounded rectangles and other shapes.
    ///
    /// - Parameters:
    ///   - points: The control points for the curve.
    ///   - detail: The number line segments used to approximate curved sections.
    static func curve(_ points: [PathPoint], detail: Int = 4) -> Path {
        enum ArcRange {
            case lhs, rhs, all
        }

        func arc(
            _ p0: PathPoint,
            _ p1: PathPoint,
            _ p2: PathPoint,
            _ detail: Int,
            _ range: ArcRange = .all
        ) -> [PathPoint] {
            let detail = detail + 1
            assert(detail >= 2)
            let steps: [Double]
            switch range {
            case .all:
                // excludes start and end points
                steps = (1 ..< detail).map { Double($0) / Double(detail) }
            case .lhs:
                // includes start and end point
                let range = 0 ..< Int(ceil(Double(detail) / 2))
                steps = range.map { Double($0) / Double(detail) } + [0.5]
            case .rhs:
                // excludes end point
                let range = detail / 2 + 1 ..< detail
                steps = [0.5] + range.map { Double($0) / Double(detail) }
            }

            return steps.map {
                var texcoord: Vector?
                if let t0 = p0.texcoord, let t1 = p1.texcoord, let t2 = p2.texcoord {
                    texcoord = Vector(
                        quadraticBezier(t0.x, t1.x, t2.x, $0),
                        quadraticBezier(t0.y, t1.y, t2.y, $0),
                        quadraticBezier(t0.z, t1.z, t2.z, $0)
                    )
                }
                var color: Color?
                if p0.color != nil || p1.color != nil || p2.color != nil {
                    color = [
                        p0.color ?? .white,
                        p1.color ?? .white,
                        p2.color ?? .white,
                    ].lerp($0)
                }
                return .curve(Vector(
                    quadraticBezier(p0.position.x, p1.position.x, p2.position.x, $0),
                    quadraticBezier(p0.position.y, p1.position.y, p2.position.y, $0),
                    quadraticBezier(p0.position.z, p1.position.z, p2.position.z, $0)
                ), texcoord: texcoord, color: color)
            }
        }

        let points = sanitizePoints(points)
        guard detail > 0, !points.isEmpty else {
            return Path(unchecked: points, plane: nil, subpathIndices: nil)
        }
        var result = [PathPoint]()
        let isClosed = pointsAreClosed(unchecked: points)
        let count = points.count
        let start = isClosed ? 0 : 1
        let end = count - 1
        var p0 = isClosed ? points[count - 2] : points[0]
        var p1 = isClosed ? points[0] : points[1]
        if !isClosed {
            if p0.isCurved, count >= 3 {
                let pe = extrapolate(points[2], p1, p0)
                if p1.isCurved {
                    result += arc(pe.lerp(p0, 0.5), p0, p0.lerp(p1, 0.5), detail, .rhs)
                } else {
                    result += arc(pe, p0, p1, detail, .rhs)
                }
            } else {
                result.append(p0)
            }
        }
        for i in start ..< end {
            let p2 = points[(i + 1) % count]
            switch (p0.isCurved, p1.isCurved, p2.isCurved) {
            case (false, true, false):
                result += arc(p0, p1, p2, detail + 1)
            case (true, true, true):
                let p0p1 = p0.lerp(p1, 0.5)
                result.append(p0p1)
                result += arc(p0p1, p1, p1.lerp(p2, 0.5), detail)
            case (true, true, false):
                let p0p1 = p0.lerp(p1, 0.5)
                result.append(p0p1)
                result += arc(p0p1, p1, p2, detail)
            case (false, true, true):
                result += arc(p0, p1, p1.lerp(p2, 0.5), detail)
            case (_, false, _):
                result.append(p1)
            }
            p0 = p1
            p1 = p2
        }
        if !isClosed {
            let p2 = points.last!
            if p2.isCurved, count >= 3 {
                p1 = p0
                let pe = extrapolate(points[count - 3], p1, p2)
                if p1.isCurved {
                    result += arc(p1.lerp(p2, 0.5), p2, p2.lerp(pe, 0.5), detail, .lhs)
                } else {
                    result += arc(p1, p2, pe, detail, .lhs).dropFirst()
                }
            } else {
                result.append(p2)
            }
        } else {
            result.append(result[0])
        }
        let path = Path(unchecked: result, plane: nil, subpathIndices: nil)
        assert(path.isClosed == isClosed)
        return path
    }
}
