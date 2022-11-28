//
//  Euclid+CoreGraphics.swift
//  Euclid
//
//  Created by Nick Lockwood on 09/03/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
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

#if canImport(CoreGraphics)

import CoreGraphics

extension CGPoint: XYZRepresentable {
    public var xyzComponents: (x: Double, y: Double, z: Double) {
        (Double(x), Double(y), 0)
    }

    public init(x: Double, y: Double, z _: Double) {
        self.init(x: x, y: y)
    }
}

extension CGSize: XYZRepresentable {
    public var xyzComponents: (x: Double, y: Double, z: Double) {
        (Double(width), Double(height), 0)
    }

    public init(x: Double, y: Double, z _: Double) {
        self.init(width: x, height: y)
    }
}

extension CGColor: RGBAConvertible {
    public var rgbaComponents: (r: Double, g: Double, b: Double, a: Double) {
        let c = components?.map(Double.init) ?? [1]
        switch c.count {
        case 1: return (c[0], c[0], c[0], 1)
        case 2: return (c[0], c[0], c[0], c[1])
        case 3: return (c[0], c[1], c[2], 1)
        default: return (c[0], c[1], c[2], 1)
        }
    }
}

public extension CGImage {
    /// Creates a checkerboard pattern image.
    /// - Parameter size: The dimensions of the checkerboard.
    static func checkerboard(size: CGSize = .init(width: 8, height: 8)) -> CGImage {
        let alphaInfo = CGImageAlphaInfo.premultipliedLast
        let width = Int(size.width), height = Int(size.height)
        let bytesPerRow = width * 4
        var data = [UInt8](repeating: 255, count: width * height * 4)
        for y in 0 ..< height {
            for x in 0 ..< width {
                let index = y * bytesPerRow + x * 4
                let value: UInt8 = (x + y) % 2 == 0 ? 0 : 255
                data[index] = value
                data[index + 1] = value
                data[index + 2] = value
            }
        }
        let context = CGContext(
            data: &data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: alphaInfo.rawValue
        )
        return context!.makeImage()!
    }
}

public extension CGPoint {
    /// Creates a `CGPoint` from the ``Vector/x`` and ``Vector/y`` components of a vector.
    /// - Parameter vector: The vector to convert into a point.
    init(_ vector: Vector) {
        self.init(x: vector.x, y: vector.y)
    }
}

public extension CGSize {
    /// Creates a `CGSize` from the X and Y components of a vector.
    /// - Parameter vector: The vector to convert into a point.
    init(_ vector: Vector) {
        self.init(width: vector.x, height: vector.y)
    }
}

public extension Path {
    /// Creates a Path from a `CGPath`. The returned path may contain nested subpaths.
    /// - Parameters:
    ///   - cgPath: The CoreGraphics path to convert.
    ///   - detail: The number of line segments used to approximate cubic or quadratic bezier curves.
    ///   - color: An optional ``Color`` to apply to the path vertices.
    init(_ cgPath: CGPath, detail: Int = 4, color: Color? = nil) {
        self.init(subpaths: cgPath.paths(detail: detail, color: color))
    }

    @available(*, deprecated, renamed: "init(_:detail:color:)")
    init(cgPath: CGPath, detail: Int = 4, color: Color? = nil) {
        self.init(subpaths: cgPath.paths(detail: detail, color: color))
    }
}

public extension CGPath {
    /// Creates an array of paths from a CoreGraphics path. Returned paths will not contain nested subpaths.
    /// - Parameters
    ///   - detail: The number of line segments used to approximate cubic or quadratic bezier curves.
    ///   - color: An optional color to apply to the path vertices.
    func paths(detail: Int = 4, color: Color? = nil) -> [Path] {
        typealias SafeElement = (type: CGPathElementType, points: [CGPoint])
        var paths = [Path]()
        var points = [PathPoint]()
        var startingPoint = Vector.zero
        var firstElement: SafeElement?
        var lastElement: SafeElement?
        func endPath() {
            if points.count > 1 {
                if points.count > 2, points.first == points.last,
                   let firstElement = firstElement
                {
                    updateLastPoint(nextElement: firstElement)
                }
                let points = sanitizePoints(points)
                let plane = flattenedPointsAreClockwise(points.map { $0.position }) ? Plane.xy.inverted() : .xy
                paths.append(Path(unchecked: points, plane: plane, subpathIndices: []))
            }
            points.removeAll()
            firstElement = nil
        }
        func updateLastPoint(nextElement: SafeElement) {
            if points.isEmpty {
                points.append(.point(startingPoint, color: color))
                return
            }
            guard let lastElement = lastElement else {
                return
            }
            let p0, p1, p2: CGPoint, isCurved: Bool
            switch nextElement.type {
            case .moveToPoint:
                points[points.count - 1].isCurved = false
                return
            case .closeSubpath:
                if let firstElement = firstElement {
                    updateLastPoint(nextElement: firstElement)
                }
                return
            case .addLineToPoint:
                p2 = nextElement.points[0]
                isCurved = false
            case .addQuadCurveToPoint, .addCurveToPoint:
                p2 = nextElement.points[0]
                isCurved = true
            @unknown default:
                return
            }
            switch lastElement.type {
            case .moveToPoint, .closeSubpath:
                return
            case .addLineToPoint:
                guard points.count > 1, isCurved else {
                    return
                }
                p0 = CGPoint(points[points.count - 2].position)
                p1 = lastElement.points[0]
            case .addQuadCurveToPoint:
                p0 = lastElement.points[0]
                p1 = lastElement.points[1]
            case .addCurveToPoint:
                p0 = lastElement.points[1]
                p1 = lastElement.points[2]
            @unknown default:
                return
            }
            let d0 = Vector(Double(p1.x - p0.x), Double(p1.y - p0.y)).normalized()
            let d1 = Vector(Double(p2.x - p1.x), Double(p2.y - p1.y)).normalized()
            let isTangent = abs(d0.dot(d1)) > 0.99
            points[points.count - 1].isCurved = isTangent
        }
        applyWithBlock {
            var element: SafeElement = ($0.pointee.type, [])
            switch element.type {
            case .moveToPoint:
                endPath()
                element.points = [$0.pointee.points[0]]
                startingPoint = Vector(element.points[0])
            case .closeSubpath:
                if points.last?.position != points.first?.position {
                    points.append(points[0])
                }
                startingPoint = points.first?.position ?? .zero
                endPath()
            case .addLineToPoint:
                let origin = $0.pointee.points[0]
                element.points = [origin]
                updateLastPoint(nextElement: element)
                points.append(.point(Vector(origin), color: color))
            case .addQuadCurveToPoint:
                let p1 = $0.pointee.points[0], p2 = $0.pointee.points[1]
                element.points = [p1, p2]
                updateLastPoint(nextElement: element)
                guard detail > 0 else {
                    points.append(.curve(Vector(p1), color: color))
                    points.append(.point(Vector(p2), color: color))
                    break
                }
                let detail = max(detail, 2)
                var t = 0.0
                let step = 1 / Double(detail)
                let p0 = points.last ?? .point(startingPoint, color: color)
                for _ in 1 ..< detail {
                    t += step
                    points.append(.curve(
                        quadraticBezier(p0.position.x, Double(p1.x), Double(p2.x), t),
                        quadraticBezier(p0.position.y, Double(p1.y), Double(p2.y), t),
                        color: color
                    ))
                }
                points.append(.point(Vector(p2), color: color))
            case .addCurveToPoint:
                let p1 = $0.pointee.points[0],
                    p2 = $0.pointee.points[1],
                    p3 = $0.pointee.points[2]
                element.points = [p1, p2, p3]
                updateLastPoint(nextElement: element)
                guard detail > 0 else {
                    points.append(.curve(Vector(p1), color: color))
                    points.append(.curve(Vector(p2), color: color))
                    points.append(.point(Vector(p3), color: color))
                    break
                }
                let detail = max(detail * 2, 3)
                var t = 0.0
                let step = 1 / Double(detail)
                let p0 = points.last ?? .point(startingPoint, color: color)
                for _ in 1 ..< detail {
                    t += step
                    points.append(.curve(
                        cubicBezier(p0.position.x, Double(p1.x), Double(p2.x), Double(p3.x), t),
                        cubicBezier(p0.position.y, Double(p1.y), Double(p2.y), Double(p3.y), t)
                    ))
                }
                points.append(.point(Vector(p3), color: color))
            @unknown default:
                return
            }
            if firstElement == nil, element.type != .moveToPoint {
                firstElement = element
            }
            lastElement = element
        }
        endPath()
        return paths
    }
}

#endif
