//
//  Path+Shapes.swift
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
    /// Creates a linear path from a start and end point.
    /// - Parameters:
    ///   - start: The starting point of the line.
    ///   - end: The ending point of the line.
    ///   - color: An optional ``Color`` to apply to the path's points.
    static func line(_ start: Vector, _ end: Vector, color: Color? = nil) -> Path {
        Path([.point(start, color: color), .point(end, color: color)])
    }

    /// Creates a circular arc.
    /// - Parameters:
    ///   - angle: The angular span of the arc, measured clockwise from vertical. Defaults to `pi` (180 degrees).
    ///   - radius: The distance from the center of the arc to each point used to approximate its shape.
    ///   - segments: The number of line segments used to approximate the circle.
    ///   - color: An optional ``Color`` to apply to the path's points.
    ///   - isCancelled: Callback used to cancel the operation.
    ///
    /// > Note: Because the arc is approximated using line segments, its radius is not uniform. The radius
    /// specified is the *outer* radius, i.e. the radius at the end points.
    static func arc(
        angle: Angle = .pi,
        radius: Double = 0.5,
        segments: Int? = nil,
        color: Color? = nil,
        isCancelled: CancellationHandler = { false }
    ) -> Path {
        var points = [PathPoint]()
        let angle = max(-.twoPi, min(.twoPi, angle))
        let span = angle / .twoPi
        let segments = segments.map {
            switch abs(span) {
            case 0 ... 0.25:
                max(1, $0)
            case 0.25 ... 0.5:
                max(2, $0)
            default:
                max(3, $0)
            }
        } ?? Int(ceil(abs(span) * 16))
        let radius = max(abs(radius), scaleLimit / 2)
        for i in 0 ... segments {
            if i.isMultiple(of: cancellationCheckInterval), isCancelled() {
                return .empty
            }
            let a = Double(i) / Double(segments) * angle
            points.append(.curve(sin(a) * radius, cos(a) * radius, color: color))
        }
        let plane = angle > .zero ? Plane.xy.inverted() : .xy
        return Path(unchecked: points, plane: plane)
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
        radius: Double = 0.5,
        segments: Int = 16,
        color: Color? = nil
    ) -> Path {
        let d = radius * 2
        return ellipse(width: d, height: d, segments: segments, color: color)
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
        let w = max(abs(width / 2), scaleLimit / 2)
        let h = max(abs(height / 2), scaleLimit / 2)
        return Path(unchecked: stride(from: 0, through: to, by: step).map {
            .curve(w * -sin($0), h * cos($0), color: color)
        }, plane: .xy)
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
        let circle = circle(radius: radius, segments: sides)
        return Path(unchecked: circle.points.map {
            .point($0.position, color: color)
        }, plane: .xy)
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
        let w = abs(width / 2), h = abs(height / 2)
        if abs(height) < scaleLimit {
            if abs(width) < scaleLimit {
                return Path([.point(.zero)])
            }
            return Path.line([-w, 0], [w, 0]).closed()
        } else if abs(width) < scaleLimit {
            return Path.line([0, -h], [0, h]).closed()
        }
        return Path(unchecked: [
            .point(-w, h, color: color), .point(-w, -h, color: color),
            .point(w, -h, color: color), .point(w, h, color: color),
            .point(-w, h, color: color),
        ], plane: .xy)
    }

    /// Creates a rounded rectangle path.
    /// - Parameters:
    ///   - width: The width of the rectangle.
    ///   - height: The height of the rectangle.
    ///   - radius: The corner radius,
    ///   - detail: The number of line segments used to approximate each corner curve.
    ///   - color: An optional ``Color`` to apply to the path's points.
    static func roundedRectangle(
        width: Double,
        height: Double,
        radius: Double,
        detail: Int = 4,
        color: Color? = nil
    ) -> Path {
        guard radius > scaleLimit / 2,
              width > scaleLimit,
              height > scaleLimit
        else {
            return .rectangle(width: width, height: height, color: color)
        }
        let w = abs(width / 2), h = abs(height / 2)
        guard detail > 0 else {
            return Path(unchecked: [
                .curve(-w, h, color: color), .curve(-w, -h, color: color),
                .curve(w, -h, color: color), .curve(w, h, color: color),
                .curve(-w, h, color: color),
            ], plane: .xy)
        }
        let r = min(radius, w, h)
        var points = [PathPoint]()
        let step = Double.pi / Double(detail * 2)
        let toX = Double.pi / 2 + (r < w ? epsilon : -epsilon)
        let toY = Double.pi / 2 + (r < h ? epsilon : -epsilon)
        var x = r - w, y = r - h
        for a in stride(from: 0, through: toX, by: step) {
            points.append(.curve(x - r * cos(a), y - r * sin(a), color: color))
        }
        x = w - r
        for a in stride(from: 0, through: toY, by: step) {
            points.append(.curve(x + r * sin(a), y - r * cos(a), color: color))
        }
        y = h - r
        for a in stride(from: 0, through: toX, by: step) {
            points.append(.curve(x + r * cos(a), y + r * sin(a), color: color))
        }
        x = r - w
        for a in stride(from: 0, through: toY, by: step) {
            points.append(.curve(x - r * sin(a), y + r * cos(a), color: color))
        }
        points.append(points[0])
        return Path(unchecked: points, plane: .xy)
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
    ///   - detail: The number of line segments used to approximate curved sections.
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
                    texcoord = [
                        quadraticBezier(t0.x, t1.x, t2.x, $0),
                        quadraticBezier(t0.y, t1.y, t2.y, $0),
                        quadraticBezier(t0.z, t1.z, t2.z, $0),
                    ]
                }
                var color: Color?
                if p0.color != nil || p1.color != nil || p2.color != nil {
                    color = [
                        p0.color ?? .white,
                        p1.color ?? .white,
                        p2.color ?? .white,
                    ].lerp($0)
                }
                return .curve(
                    quadraticBezier(p0.position.x, p1.position.x, p2.position.x, $0),
                    quadraticBezier(p0.position.y, p1.position.y, p2.position.y, $0),
                    quadraticBezier(p0.position.z, p1.position.z, p2.position.z, $0),
                    texcoord: texcoord,
                    color: color
                )
            }
        }

        let points = sanitizePoints(points)
        guard detail > 0, points.count > 2 else {
            return Path(unchecked: points, plane: nil)
        }
        var result = [PathPoint]()
        let count = points.count
        let isClosed = pointsAreClosed(unchecked: points)
        let start = isClosed ? 0 : 1, end = count - 1
        var (p0, p1) = isClosed ? (points[count - 2], points[0]) : (points[0], points[1])
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
        let path = Path(result)
        assert(path.isClosed == isClosed)
        return path
    }

    /// Alignment mode to use when extruding along a path.
    enum Alignment: Hashable, Codable, Sendable {
        /// Use default alignment heuristic for the given path.
        case `default`
        /// Align extruded cross-sections to the tangent of the path curve.
        case tangent
        /// Align extruded cross-sections with the X, Y or Z axis
        /// (whichever is most perpendicular to the extrusion path).
        case axis
    }

    /// Cropped and flattened version of path suitable for lathing around the Y axis.
    var latheProfile: Path {
        guard subpaths.count == 1 else {
            return Path(subpaths: subpaths.map(\.latheProfile))
        }
        let profile = flattened().clippedToYAxis()
        if profile.faceNormal.z < 0 {
            return Path(
                unchecked: profile.points.reversed(),
                plane: profile.plane?.inverted()
            )
        }
        return profile
    }

    /// Creates an array of contours by extruding one path along another path.
    /// - Parameters:
    ///   - along: The path along which to extrude the shape.
    ///   - twist: Angular twist to apply along the extrusion.
    ///   - align: The alignment mode to use for the extruded shape.
    ///   - miterLimit: The miter threshold beyond which a corner is beveled.
    func extrusionContours(
        along: Path,
        twist: Angle = .zero,
        align: Alignment = .default,
        miterLimit: MiterLimit = .infinity
    ) -> [Path] {
        let points = along.points
        switch points.count {
        case 0:
            return []
        case 1:
            return [translated(by: points[0].position)]
        default:
            break
        }

        // Get initial shape orientation
        var shape = self
        var shapeNormal: Vector
        let pathPlane = along.flatteningPlane
        switch (shape.flatteningPlane, pathPlane) {
        case (.xy, .xy):
            shape.rotate(by: .pitch(.halfPi))
            shapeNormal = .unitY
        case (.yz, .yz):
            shape.rotate(by: .roll(.halfPi))
            shapeNormal = -.unitY
        case (.xz, .xz):
            shape.rotate(by: .roll(.halfPi))
            shapeNormal = .unitX
        case (.xy, _):
            shapeNormal = .unitZ
        case (.yz, _):
            shapeNormal = .unitX
        case (.xz, _):
            shapeNormal = .unitY
        }

        // Get alignment mode
        let axisAligned: Bool
        switch align {
        case .axis:
            axisAligned = true
        case .tangent:
            axisAligned = false
        case .default:
            var aligned = true
            var p0 = points[0]
            for p1 in points.dropFirst() {
                let v = p1.position - p0.position
                let l = v.projected(onto: pathPlane.rawValue).length
                if l < v.length * 0.9 {
                    aligned = false
                    break
                }
                p0 = p1
            }
            axisAligned = aligned
        }

        func rotateShape(by rotation: Rotation) {
            shape.rotate(by: rotation)
            shapeNormal.rotate(by: rotation)
        }

        func lengthAndDirection(from a: PathPoint, to b: PathPoint) -> (length: Double, direction: Vector?) {
            var ab = b.position - a.position
            let length = ab.length
            if axisAligned {
                let projected = ab.projected(onto: pathPlane.rawValue)
                if !projected.isZero {
                    ab = projected
                }
            }
            return (length, ab.direction)
        }

        func transformedShape(
            for p: PathPoint,
            _ scale: (distance: Double, along: Vector)?,
            snappingTo snapPoint: Vector? = nil
        ) -> Path {
            var shape = shape
            if let color = p.color {
                shape = shape.mapColors { ($0 ?? .white) * color }
            }
            if let (distance, along) = scale, let line = Line(origin: .zero, direction: along) {
                shape.stretch(by: distance, along: line)
            }
            shape.translate(by: p.position)
            if let snapPoint {
                shape = shape.mapPoints {
                    $0.position.isApproximatelyEqual(to: snapPoint) ? $0.withPosition(snapPoint) : $0
                }
            }
            return shape
        }

        func projectionRange(of shape: Path, along axis: Vector) -> (min: Double, max: Double) {
            var result = (min: Double.infinity, max: -Double.infinity)
            for p in shape.points {
                let projection = p.position.dot(axis)
                result.min = min(result.min, projection)
                result.max = max(result.max, projection)
            }
            if result.min == .infinity {
                return (0, 0)
            }
            return result
        }

        func snapCoincidentPoints(in shapes: [Path]) -> [Path] {
            var points = [Vector]()
            func snap(_ position: Vector) -> Vector {
                if let match = points.first(where: { $0.isApproximatelyEqual(to: position) }) {
                    return match
                }
                points.append(position)
                return position
            }
            return shapes.map { shape in
                shape.mapPoints { $0.withPosition(snap($0.position)) }
            }
        }

        func twistShape(_ distance: Double) {
            let angle = twist * (distance / length)
            rotateShape(by: Rotation(unchecked: shapeNormal, angle: angle))
        }

        func transformedShapes(for index: Int, firstOnly: Bool = false) -> [Path] {
            assert(index > 0)
            let p0 = points[index > 1 ? index - 2 : points.count - 2]
            let p1 = points[index - 1]
            let p2 = points[index]
            let (incomingLength, n1) = lengthAndDirection(from: p0, to: p1)
            let (outgoingLength, n2) = lengthAndDirection(from: p1, to: p2)
            twistShape(incomingLength)
            guard let n1, let n2 else {
                shapeToPointIndex.append(index - 1)
                return [transformedShape(for: p1, nil)]
            }
            var (axis, angle) = axisAndAngleBetweenNormalizedVectors(n1, n2)
            func miteredShape() -> [Path] {
                angle /= 2
                let r = Rotation(unchecked: axis, angle: angle)
                rotateShape(by: r)
                let stretchDistance = 1 / cos(angle)
                let stretchAxis = n1.rotated(by: Rotation(unchecked: axis, angle: angle - .halfPi))
                let results = [transformedShape(for: p1, (stretchDistance, stretchAxis))]
                shapeToPointIndex.append(index - 1)
                rotateShape(by: r)
                return results
            }
            if angle > miterLimit.angle {
                let bevelAngle = angle / 3
                let stretchDistance = 1 / cos(bevelAngle)
                let shouldSeparateInnerCorner = angle < .halfPi - .radians(epsilon)
                let maximumInnerCornerGap = shouldSeparateInnerCorner ?
                    max(shape.bounds.size.length * 1e-5, scaleLimit * 2) : 0
                let incomingSideAxis = n1.rotated(by: Rotation(unchecked: axis, angle: -.halfPi))
                let incomingSideRange = projectionRange(of: shape, along: incomingSideAxis)
                let outgoingSideAxis = n1.rotated(by: Rotation(unchecked: axis, angle: angle - .halfPi))
                let outgoingShape = shape.rotated(by: Rotation(unchecked: axis, angle: angle))
                let outgoingSideRange = projectionRange(of: outgoingShape, along: outgoingSideAxis)
                let innerCorner = Line(
                    origin: p1.position + incomingSideAxis * incomingSideRange.min,
                    direction: n1
                ).flatMap { incomingLine in
                    Line(
                        origin: p1.position + outgoingSideAxis * outgoingSideRange.min,
                        direction: n2
                    ).flatMap { incomingLine.intersection(with: $0) }
                }
                let bevelRotation = Rotation(unchecked: axis, angle: bevelAngle)
                rotateShape(by: bevelRotation)
                let incomingAxis = n1.rotated(by: Rotation(unchecked: axis, angle: bevelAngle - .halfPi))
                let incomingRange = projectionRange(of: shape, along: incomingAxis)
                let incomingAdvanceToCorner: Double? = innerCorner.flatMap {
                    let denominator = n1.dot(incomingAxis)
                    guard abs(denominator) > epsilon else {
                        return nil
                    }
                    let incomingSupport = incomingRange.min * stretchDistance
                    let advance = (
                        p1.position.dot(incomingAxis) + incomingSupport - $0.dot(incomingAxis)
                    ) / denominator
                    return advance.isFinite ? advance : nil
                }
                let rawIncomingAdvance = incomingAdvanceToCorner ??
                    incomingRange.max * tan(angle / 2)
                let incomingGap = min(max(rawIncomingAdvance / 2, 0), maximumInnerCornerGap)
                let incomingLimit = incomingLength / 2
                let incomingAdvance = min(
                    max(rawIncomingAdvance - incomingGap, 0),
                    incomingLimit
                )
                rotateShape(by: bevelRotation)
                let outgoingAxis = n1.rotated(by: Rotation(unchecked: axis, angle: bevelAngle * 2 - .halfPi))
                let outgoingRange = projectionRange(of: shape, along: outgoingAxis)
                let outgoingAdvanceToCorner: Double? = innerCorner.flatMap {
                    let denominator = n2.dot(outgoingAxis)
                    guard abs(denominator) > epsilon else {
                        return nil
                    }
                    let outgoingSupport = outgoingRange.min * stretchDistance
                    let advance = (
                        $0.dot(outgoingAxis) - p1.position.dot(outgoingAxis) - outgoingSupport
                    ) / denominator
                    return advance.isFinite ? advance : nil
                }
                let rawOutgoingAdvance = outgoingAdvanceToCorner ??
                    outgoingRange.max * tan(angle / 2)
                let outgoingGap = min(max(rawOutgoingAdvance / 2, 0), maximumInnerCornerGap)
                let outgoingLimit = outgoingLength / 2
                let outgoingAdvance = min(
                    max(rawOutgoingAdvance - outgoingGap, 0),
                    outgoingLimit
                )
                let advance = min(incomingAdvance, outgoingAdvance)
                let outgoing = firstOnly ? nil : transformedShape(
                    for: p1.withPosition(p1.position + n2 * advance),
                    (stretchDistance, outgoingAxis),
                    snappingTo: shouldSeparateInnerCorner || outgoingAdvanceToCorner == nil ? nil : innerCorner
                )
                rotateShape(by: -bevelRotation)
                let incoming = transformedShape(
                    for: p1.withPosition(p1.position - n1 * advance),
                    (stretchDistance, incomingAxis),
                    snappingTo: shouldSeparateInnerCorner || incomingAdvanceToCorner == nil ? nil : innerCorner
                )
                rotateShape(by: bevelRotation)
                guard let outgoing else {
                    shapeToPointIndex.append(index - 1)
                    rotateShape(by: bevelRotation)
                    return [incoming]
                }
                shapeToPointIndex.append(index - 1)
                shapeToPointIndex.append(index - 1)
                rotateShape(by: bevelRotation)
                return [incoming, outgoing]
            }
            return miteredShape()
        }

        // Prepare initial shape
        let length = along.length
        var shapes = [Path]()
        var shapeToPointIndex: [Int] = []
        do {
            var p0p1 = (points[1].position - points[0].position)
            if align == .axis {
                let projected = p0p1.projected(onto: pathPlane.rawValue)
                if !projected.isZero {
                    p0p1 = projected
                }
            }
            if let p0p1 = p0p1.direction {
                rotateShape(by: rotationBetweenNormalizedVectors(shapeNormal, p0p1))
            }
        }
        let initialShape = shape

        if along.isClosed {
            for i in 2 ..< points.count {
                shapes += transformedShapes(for: i)
            }
            shapes += transformedShapes(for: 1)
            shapes += transformedShapes(for: 2, firstOnly: true)
        } else {
            shapes.append(transformedShape(for: points[0], nil))
            shapeToPointIndex.append(points.count - 0)
            for i in 2 ..< points.count {
                shapes += transformedShapes(for: i)
            }
            let last2 = points.suffix(2).map(\.position)
            twistShape((last2[1] - last2[0]).length)
            shapes.append(transformedShape(for: points.last!, nil))
            shapeToPointIndex.append(points.count - 1)
        }

        if along.isClosed {
            // Compute final shape
            shape = initialShape
            shapeNormal = shape.faceNormal
            twistShape(length)
            let expected = transformedShapes(for: 2, firstOnly: true)[0]

            func rotationBetween(_ a: Path?, _ b: Path, checkSign: Bool = true) -> Rotation {
                guard let a else { return .identity }
                let b = b.rotated(by: rotationBetweenNormalizedVectors(a.faceNormal, b.faceNormal))
                let points0 = a.points, points1 = b.points
                let delta = (points0[1].position - points0[0].position)
                    .angle(with: points1[1].position - points1[0].position)
                let rotation = Rotation(unchecked: b.faceNormal, angle: delta)
                if checkSign, rotationBetween(
                    a,
                    b.rotated(by: rotation),
                    checkSign: false
                ).angle > delta {
                    // TODO: this is pretty weird - find better solution
                    return Rotation(unchecked: b.faceNormal, angle: -delta)
                }
                return rotation
            }

            // Fix up angles
            let last = shapes.last!
            shapes[shapes.count - 1] = expected
            if !last.isApproximatelyEqual(to: expected) {
                let r = rotationBetween(expected, last)
                let delta = r.axis.dot(shapeNormal) > 0 ? r.angle : -r.angle
                var distance = 0.0
                var prev = points[0].position
                for i in 0 ..< shapes.count - 1 {
                    let position = points[shapeToPointIndex[i]].position
                    distance += position.distance(from: prev)
                    prev = position
                    var shape = shapes[i]
                    let offset = shape.bounds.center
                    shape.translate(by: -offset)
                    let angle = delta * (distance / length)
                    shape.rotate(by: .init(unchecked: shapeNormal, angle: angle))
                    shape.translate(by: offset)
                    shapes[i] = shape
                }
            }
        }

        // Double up shapes at sharp corners
        let startIndex = along.isClosed ? 0 : 1
        let shouldDoubleClosingShape = along.isClosed && !points[shapeToPointIndex[shapes.count - 1]].isCurved
        for i in (startIndex ..< shapes.count - 1).reversed() where !points[shapeToPointIndex[i]].isCurved {
            shapes.insert(shapes[i], at: i)
        }
        if shouldDoubleClosingShape {
            shapes.append(shapes[shapes.count - 1])
        }
        return along.isClosed ? snapCoincidentPoints(in: shapes) : shapes
    }
}
