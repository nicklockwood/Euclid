//
//  Transform.swift
//  Euclid
//
//  Created by Nick Lockwood on 03/07/2018.
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

/// A combined rotation, position, and scale that can be applied to a 3D object.
///
/// Working with intermediate transform objects instead of directly updating the vertex positions of a mesh
/// is more efficient and avoids a buildup of rounding errors.
public struct Transform: Hashable {
    /// The size or scale component of the transform.
    public var scale: Vector {
        didSet { scale = scale.clampedToScaleLimit() }
    }

    /// The rotation or orientation component of the transform.
    public var rotation: Rotation

    /// The translation or position component of the transform.
    public var translation: Vector

    /// Creates a new transform.
    /// - Parameters:
    ///   - scale: The scaling component of the transform. Defaults to one (no scale adjustment).
    ///   - rotation: The translation or position component of the transform. Defaults to identity (no rotation).
    ///   - translation: The translation or position component of the transform. Defaults to zero (no translation).
    public init(
        scale: Vector? = nil,
        rotation: Rotation? = nil,
        translation: Vector? = nil
    ) {
        self.scale = scale?.clampedToScaleLimit() ?? .one
        self.rotation = rotation ?? .identity
        self.translation = translation ?? .zero
    }
}

extension Transform: CustomDebugStringConvertible {
    public var debugDescription: String {
        guard self != .identity else {
            return "Transform.identity"
        }
        let components: [String] = [
            scale == .one ? nil : "scale: \(scale.components)",
            rotation == .identity ? nil : "rotation: \(rotation)",
            translation == .zero ? nil : "translation: \(translation.components)",
        ].compactMap { $0 }
        let joined = components.joined(separator: ", ")
        if components.count > 1, joined.count > 80 {
            return "Transform(\n\t\(components.joined(separator: ",\n\t"))\n)"
        }
        return "Transform(\(joined))"
    }
}

extension Transform: Codable {
    private enum CodingKeys: CodingKey {
        case scale, rotation, translation
        case offset // legacy
    }

    /// Creates a new transform by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let scale = try container.decodeIfPresent(Vector.self, forKey: .scale)
        let rotation = try container.decodeIfPresent(Rotation.self, forKey: .rotation)
        let translation = try container.decodeIfPresent(Vector.self, forKey: .translation)
            ?? container.decodeIfPresent(Vector.self, forKey: .offset)
        self.init(scale: scale, rotation: rotation, translation: translation)
    }

    /// Encodes this transform into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try scale.isOne ? () : container.encode(scale, forKey: .scale)
        try rotation.isIdentity ? () : container.encode(rotation, forKey: .rotation)
        try translation.isZero ? () : container.encode(translation, forKey: .offset)
    }
}

public extension Transform {
    /// The identity transform (i.e. no transform).
    static let identity = Transform()

    /// Creates a translation or position transform.
    /// - Parameter translation: An offset distance.
    static func translation(_ translation: Vector) -> Transform {
        .init(translation: translation)
    }

    /// Deprecated.
    @available(*, deprecated, renamed: "translation(_:)")
    static func offset(_ offset: Vector) -> Transform {
        .init(translation: offset)
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

    /// Creates a rotation transform.
    /// - Parameter rotation: A rotation to apply.
    static func rotation(_ rotation: Rotation) -> Transform {
        .init(rotation: rotation)
    }

    /// Creates a new transform with a uniform scale factor
    /// - Parameters:
    ///   - scale: The scaling factor of the transform. Defaults to `1.0` (no scale adjustment).
    ///   - rotation: The translation or position component of the transform. Defaults to identity (no rotation).
    ///   - translation: The translation or position component of the transform. Defaults to zero (no translation).
    init(
        scale: Double,
        rotation: Rotation? = nil,
        translation: Vector? = nil
    ) {
        self.scale = .init(size: scale.clampedToScaleLimit())
        self.rotation = rotation ?? .identity
        self.translation = translation ?? .zero
    }

    /// Deprecated
    @available(*, deprecated, renamed: "translation")
    var offset: Vector {
        set { translation = newValue }
        get { translation }
    }

    /// Deprecated
    @available(*, deprecated, renamed: "init(scale:rotation:translation:)")
    init(
        offset: Vector?,
        rotation: Rotation? = nil,
        scale: Vector? = nil
    ) {
        self.init(scale: scale, rotation: rotation, translation: offset)
    }

    /// Transform has no effect.
    var isIdentity: Bool {
        rotation.isIdentity && translation.isZero && scale.isOne
    }

    /// Does the transform apply a mirror operation (negative scale)?
    var isFlipped: Bool {
        isFlippedScale(scale)
    }
}
