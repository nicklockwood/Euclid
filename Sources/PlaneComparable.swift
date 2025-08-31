//
//  PlaneComparable.swift
//  Euclid
//
//  Created by Nick Lockwood on 08/04/2025.
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

/// The relationship between a point or shape and a plane.
public enum PlaneComparison: Int {
    /// All points in the shape lie on the plane.
    case coplanar = 0
    /// All points in the shape lie in front of the plane.
    case front = 1
    /// All points in the shape lie behind the plane.
    case back = 2
    /// The shape spans the plane (some points are in front, some behind).
    case spanning = 3
}

/// Protocol for plane-comparable types.
public protocol PlaneComparable {
    /// Returns the signed distance between the receiver and the specified plane.
    /// - Parameter plane: The plane to compare with.
    /// - Returns: The distance between the receiver and the plane. The value is positive if the receiver lies
    ///   in front of the plane, negative if it lies behind it, or zero if it lies exactly on the plane, or crosses it.
    func signedDistance(from plane: Plane) -> Double

    /// The relationship between the receiver and the specified plane.
    /// - Parameter plane: The plane to compare with.
    /// - Returns: The `PlaneComparison` between the receiver and the plane.
    func compare(with plane: Plane) -> PlaneComparison
}

public extension PlaneComparable {
    /// Returns the absolute distance between the receiver and the specified plane.
    /// - Parameter plane: The plane to compare with.
    /// - Returns: The absolute distance between the receiver and the plane. The value will be
    ///   positive if the receiver lies in front or behind the plane, or zero if they intersect.
    func distance(from plane: Plane) -> Double {
        abs(signedDistance(from: plane))
    }

    /// Determines if the receiver intersects the specified plane.
    /// - Parameter plane: The plane to compare with.
    /// - Returns: `true` if the receiver intersects the plane, and `false` otherwise.
    func intersects(_ plane: Plane) -> Bool {
        [.spanning, .coplanar].contains(compare(with: plane))
    }
}

extension Bounds: PlaneComparable {
    public func signedDistance(from plane: Plane) -> Double {
        corners.signedDistance(from: plane)
    }

    public func compare(with plane: Plane) -> PlaneComparison {
        corners.compare(with: plane)
    }
}

extension Vector: PlaneComparable {
    public func signedDistance(from plane: Plane) -> Double {
        plane.normal.dot(self) - plane.w
    }

    public func compare(with plane: Plane) -> PlaneComparison {
        .init(signedDistance: signedDistance(from: plane))
    }
}

extension Vertex: PlaneComparable {
    public func signedDistance(from plane: Plane) -> Double {
        position.signedDistance(from: plane)
    }

    public func compare(with plane: Plane) -> PlaneComparison {
        position.compare(with: plane)
    }
}

extension PathPoint: PlaneComparable {
    public func signedDistance(from plane: Plane) -> Double {
        position.signedDistance(from: plane)
    }

    public func compare(with plane: Plane) -> PlaneComparison {
        position.compare(with: plane)
    }
}

extension Line: PlaneComparable {
    public func signedDistance(from plane: Plane) -> Double {
        signedPerpendicularDistance(from: plane) ?? 0
    }

    public func compare(with plane: Plane) -> PlaneComparison {
        signedPerpendicularDistance(from: plane).map(PlaneComparison.init) ?? .spanning
    }
}

extension LineSegment: PlaneComparable {
    public func signedDistance(from plane: Plane) -> Double {
        [start, end].signedDistance(from: plane)
    }

    public func compare(with plane: Plane) -> PlaneComparison {
        [start, end].compare(with: plane)
    }
}

extension Plane: PlaneComparable {
    public func signedDistance(from plane: Plane) -> Double {
        signedPerpendicularDistance(from: plane) ?? 0
    }

    public func compare(with plane: Plane) -> PlaneComparison {
        signedPerpendicularDistance(from: plane).map(PlaneComparison.init) ?? .spanning
    }
}

extension Path: PlaneComparable {
    public func signedDistance(from plane: Plane) -> Double {
        if let distance = self.plane?.signedPerpendicularDistance(from: plane) {
            return distance
        }
        return points.signedDistance(from: plane)
    }

    public func compare(with plane: Plane) -> PlaneComparison {
        // Note: will return `coplanar` for empty path
        if let distance = self.plane?.signedPerpendicularDistance(from: plane) {
            return .init(signedDistance: distance)
        }
        return points.compare(with: plane)
    }
}

extension Polygon: PlaneComparable {
    public func signedDistance(from plane: Plane) -> Double {
        if let distance = self.plane.signedPerpendicularDistance(from: plane) {
            return distance
        }
        return vertices.signedDistance(from: plane)
    }

    public func compare(with plane: Plane) -> PlaneComparison {
        vertices.compare(with: plane)
    }
}

extension Mesh: PlaneComparable {
    public func signedDistance(from plane: Plane) -> Double {
        // Note: will return zero for empty mesh
        polygons.signedDistance(from: plane)
    }

    public func compare(with plane: Plane) -> PlaneComparison {
        // Note: will return `coplanar` for empty mesh
        switch bounds.compare(with: plane) {
        case .front:
            return .front
        case .back:
            return .back
        case .coplanar, .spanning:
            // TODO: can we optimize this using BSP?
            return polygons.compare(with: plane)
        }
    }
}

extension PlaneComparison {
    /// Create a `PlaneComparison` from a distance
    /// - Parameter distance: The distance between an object and plane.
    init(signedDistance: Double) {
        switch signedDistance {
        case ..<(-planeEpsilon): self = .back
        case ...planeEpsilon: self = .coplanar
        default: self = .front
        }
    }

    /// A cumulative comparison.
    /// - Parameter other: A comparison to combine with the receiver.
    func union(_ other: PlaneComparison) -> PlaneComparison {
        PlaneComparison(rawValue: rawValue | other.rawValue)!
    }
}

/// Cumulative `PlaneComparable` operations.
/// These are a bit quirky in terms of handling of empty collections or when objects span the plane
/// but don't actually touch it, so we'll keep it private for now
private extension Collection where Element: PlaneComparable {
    func signedDistance(from plane: Plane) -> Double {
        guard var distance = first?.signedDistance(from: plane) else {
            return .infinity
        }
        // Note: this duplication is inelegant, but allows for early exit
        if distance < 0 {
            for element in dropFirst() where distance < 0 {
                distance = element.signedDistance(from: plane).clamped(to: distance ... 0)
            }
        } else {
            for element in dropFirst() where distance > 0 {
                distance = element.signedDistance(from: plane).clamped(to: 0 ... distance)
            }
        }
        return distance
    }

    func compare(with plane: Plane) -> PlaneComparison {
        var comparison = PlaneComparison.coplanar
        for element in self {
            comparison = comparison.union(element.compare(with: plane))
            if comparison == .spanning {
                break
            }
        }
        return comparison
    }
}
