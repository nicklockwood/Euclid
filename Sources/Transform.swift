//
//  Transform.swift
//  Euclid
//
//  Created by Nick Lockwood on 21/04/2025.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

/// A combined rotation, position, and scale that can be applied to a 3D object.
///
/// Working with intermediate transform objects instead of directly updating the vertex positions of a mesh
/// is more efficient and avoids a buildup of rounding errors.
public struct Transform: Hashable {
    /// The translation or position component of the transform.
    public var offset: Vector
    /// The rotation or orientation component of the transform.
    public var rotation: Rotation
    /// The size or scale component of the transform.
    public var scale: Vector {
        didSet { scale = scale.clamped() }
    }

    /// Creates a new transform.
    /// - Parameters:
    ///   - offset: The translation or position component of the transform. Defaults to zero (no offset).
    ///   - rotation: The translation or position component of the transform. Defaults to identity (no rotation).
    ///   - scale: The scaling component of the transform. Defaults to one (no scale adjustment).
    public init(offset: Vector? = nil, rotation: Rotation? = nil, scale: Vector? = nil) {
        self.offset = offset ?? .zero
        self.rotation = rotation ?? .identity
        self.scale = scale?.clamped() ?? .one
    }
}

extension Transform: Codable {
    private enum CodingKeys: CodingKey {
        case offset, rotation, scale
    }

    /// Creates a new transform by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let offset = try container.decodeIfPresent(Vector.self, forKey: .offset)
        let rotation = try container.decodeIfPresent(Rotation.self, forKey: .rotation)
        let scale = try container.decodeIfPresent(Vector.self, forKey: .scale)
        self.init(offset: offset, rotation: rotation, scale: scale)
    }

    /// Encodes this transform into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try offset.isZero ? () : container.encode(offset, forKey: .offset)
        try rotation.isIdentity ? () : container.encode(rotation, forKey: .rotation)
        try scale.isOne ? () : container.encode(scale, forKey: .scale)
    }
}

public extension Transform {
    /// The identity transform (i.e. no transform).
    static let identity = Transform()

    /// Creates a offset transform.
    /// - Parameter offset: An offset distance.
    static func offset(_ offset: Vector) -> Transform {
        .init(offset: offset)
    }

    /// Creates a rotation transform.
    /// - Parameter rotation: A rotation to apply.
    static func rotation(_ rotation: Rotation) -> Transform {
        .init(rotation: rotation)
    }

    /// Creates a scale transform.
    /// - Parameter scale: A vector scale factor to apply.
    static func scale(_ scale: Vector) -> Transform {
        .init(scale: scale)
    }

    /// Creates a uniform scale transform.
    /// - Parameter factor: A uniform scale factor to apply.
    static func scale(_ factor: Double) -> Transform {
        .init(scale: Vector(size: factor))
    }

    /// Transform has no effect.
    var isIdentity: Bool {
        rotation.isIdentity && offset.isZero && scale.isOne
    }

    /// Does the transform apply a mirror operation (negative scale)?
    var isFlipped: Bool {
        isFlippedScale(scale)
    }
}
