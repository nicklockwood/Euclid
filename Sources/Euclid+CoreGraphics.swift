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

public extension Vector {
    init(_ cgPoint: CGPoint) {
        self.init(Double(cgPoint.x), Double(cgPoint.y))
    }
}

public extension Position {
    init(_ cgPoint: CGPoint) {
        self.init(Double(cgPoint.x), Double(cgPoint.y))
    }
}

public extension Distance {
    init(_ cgPoint: CGPoint) {
        self.init(Double(cgPoint.x), Double(cgPoint.y))
    }
}

public extension Color {
    init(_ cgColor: CGColor) {
        let components = cgColor.components ?? [1]
        self.init(unchecked: components.map(Double.init))
    }
}

public extension CGPoint {
    init(_ vector: Vector) {
        self.init(x: vector.x, y: vector.y)
    }

    init(_ position: Position) {
        self.init(x: position.x, y: position.y)
    }

    init(_ distance: Distance) {
        self.init(x: distance.x, y: distance.y)
    }
}

public extension Path {
    /// Create a Path from a CGPath. The returned path may contain nested subpaths
    init(cgPath: CGPath, detail: Int = 4) {
        self.init(subpaths: cgPath.paths(detail: detail))
    }
}

public extension CGPath {
    private func enumerateElements(_ block: @convention(block) (CGPathElement) -> Void) {
        if #available(iOS 11.0, tvOS 11.0, OSX 10.13, *) {
            applyWithBlock { block($0.pointee) }
            return
        }

        // Fallback for earlier OSes
        typealias Block = @convention(block) (CGPathElement) -> Void
        let callback: @convention(c) (
            UnsafeMutableRawPointer,
            UnsafePointer<CGPathElement>
        ) -> Void = { info, element in
            unsafeBitCast(info, to: Block.self)(element.pointee)
        }
        withoutActuallyEscaping(block) { block in
            let block = unsafeBitCast(block, to: UnsafeMutableRawPointer.self)
            self.apply(info: block, function: unsafeBitCast(callback, to: CGPathApplierFunction.self))
        }
    }

    /// Create a flat array of Paths from a CGPath. Returned paths are
    /// guaranteed not to contain nested subpaths
    func paths(detail: Int = 4) -> [Path] {
        typealias SafeElement = (type: CGPathElementType, points: [CGPoint])
        var paths = [Path]()
        var points = [PathPoint]()
        var startingPoint = Position.origin
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
                points.append(.point(startingPoint))
                return
            }
            guard let lastElement = lastElement else {
                return
            }
            let p0: CGPoint, p1: CGPoint, p2: CGPoint, isCurved: Bool
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
        enumerateElements {
            var element: SafeElement = ($0.type, [])
            switch element.type {
            case .moveToPoint:
                endPath()
                element.points = [$0.points[0]]
                startingPoint = Position(element.points[0])
            case .closeSubpath:
                if points.last?.position != points.first?.position {
                    points.append(points[0])
                }
                startingPoint = points.first?.position ?? .origin
                endPath()
            case .addLineToPoint:
                let origin = $0.points[0]
                element.points = [origin]
                updateLastPoint(nextElement: element)
                points.append(.point(Position(origin)))
            case .addQuadCurveToPoint:
                let p1 = $0.points[0], p2 = $0.points[1]
                element.points = [p1, p2]
                updateLastPoint(nextElement: element)
                guard detail > 0 else {
                    points.append(.curve(Position(p1)))
                    points.append(.point(Position(p2)))
                    break
                }
                let detail = max(detail, 2)
                var t = 0.0
                let step = 1 / Double(detail)
                let p0 = points.last ?? .point(startingPoint)
                for _ in 1 ..< detail {
                    t += step
                    points.append(.curve(
                        quadraticBezier(p0.position.x, Double(p1.x), Double(p2.x), t),
                        quadraticBezier(p0.position.y, Double(p1.y), Double(p2.y), t)
                    ))
                }
                points.append(.point(Position(p2)))
            case .addCurveToPoint:
                let p1 = $0.points[0], p2 = $0.points[1], p3 = $0.points[2]
                element.points = [p1, p2, p3]
                updateLastPoint(nextElement: element)
                guard detail > 0 else {
                    points.append(.curve(Position(p1)))
                    points.append(.curve(Position(p2)))
                    points.append(.point(Position(p3)))
                    break
                }
                let detail = max(detail * 2, 3)
                var t = 0.0
                let step = 1 / Double(detail)
                let p0 = points.last ?? .point(startingPoint)
                for _ in 1 ..< detail {
                    t += step
                    points.append(.curve(
                        cubicBezier(p0.position.x, Double(p1.x), Double(p2.x), Double(p3.x), t),
                        cubicBezier(p0.position.y, Double(p1.y), Double(p2.y), Double(p3.y), t)
                    ))
                }
                points.append(.point(Position(p3)))
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
