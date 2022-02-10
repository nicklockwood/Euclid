//
//  Euclid+CoreText.swift
//  Euclid
//
//  Created by Nick Lockwood on 10/03/2019.
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

#if canImport(CoreText)

import CoreText
import Foundation

public extension Path {
    /// Creates an array of glyph contours from a string and font you provide.
    /// - Parameters:
    ///   - text: The text to convert.
    ///   - font: The font to use for the text.
    ///   - width: The optional width at which to line-wrap the text.
    ///   - detail: The number line segments used to approximate glyph curves.
    static func text(
        _ text: String,
        font: CTFont? = nil,
        width: Double? = nil,
        detail: Int = 2
    ) -> [Path] {
        let attributedString = NSAttributedString(string: text, font: font)
        return self.text(attributedString, width: width, detail: detail)
    }

    /// Creates an array of glyph contours from an attributed string.
    /// - Parameters:
    ///   - text: The text to convert.
    ///   - width: The optional width at which to line-wrap the text.
    ///   - detail: The number line segments used to approximate glyph curves.
    static func text(
        _ text: NSAttributedString,
        width: Double? = nil,
        detail: Int = 2
    ) -> [Path] {
        text.cgPaths(width: width).map {
            let cgPath = CGMutablePath()
            let transform = CGAffineTransform(translationX: $1.x, y: $1.y)
            cgPath.addPath($0, transform: transform)
            return Path(cgPath, detail: detail, color: $2)
        }
    }
}

public extension Mesh {
    /// Creates an extruded text model from a string.
    /// - Parameters:
    ///   - text: The text to convert into a model
    ///   - font: The font to use for the text glyphs.
    ///   - width: The optional width at which to line-wrap the text.
    ///   - depth: The depth of the extruded text.
    ///   - detail: The number line segments used to approximate glyph curves.
    ///   - material: An optional material to apply to the mesh.
    static func text(
        _ text: String,
        font: CTFont? = nil,
        width: Double? = nil,
        depth: Double = 1,
        detail: Int = 2,
        material: Material? = nil
    ) -> Mesh {
        .text(
            NSAttributedString(string: text, font: font),
            width: width,
            depth: depth,
            detail: detail,
            material: material
        )
    }

    /// Create an extruded text model from an attributed string
    /// - Parameters:
    ///   - text: The text to convert into a model
    ///   - width: The optional width at which to line-wrap the text.
    ///   - depth: The depth of the extruded text.
    ///   - detail: The number line segments used to approximate glyph curves.
    ///   - material: Optional material to apply to the mesh.
    static func text(
        _ text: NSAttributedString,
        width: Double? = nil,
        depth: Double = 1,
        detail: Int = 2,
        material: Material? = nil
    ) -> Mesh {
        var meshes = [Mesh]()
        var cache = [CGPath: Mesh]()
        for (cgPath, cgPoint, color) in text.cgPaths(width: width) {
            let offset = Vector(cgPoint)
            guard let mesh = cache[cgPath] else {
                let path = Path(cgPath, detail: detail, color: color)
                let mesh = Mesh.extrude(path, depth: depth, material: material)
                cache[cgPath] = mesh
                meshes.append(mesh.translated(by: offset))
                continue
            }
            meshes.append(mesh.translated(by: offset))
        }
        return .union(meshes)
    }

    @available(*, deprecated, message: "Use Mesh.text() instead")
    init(
        text: String,
        font: CTFont? = nil,
        width: Double? = nil,
        depth: Double = 1,
        detail: Int = 2,
        material: Material? = nil
    ) {
        self = .text(
            text,
            font: font,
            width: width,
            depth: depth,
            detail: detail,
            material: material
        )
    }

    @available(*, deprecated, message: "Use Mesh.text() instead")
    init(
        text: NSAttributedString,
        width: Double? = nil,
        depth: Double = 1,
        detail: Int = 2,
        material: Material? = nil
    ) {
        self = .text(
            text,
            width: width,
            depth: depth,
            detail: detail,
            material: material
        )
    }
}

#if os(watchOS)
// Workaround for missing constants on watchOS
extension NSAttributedString.Key {
    static let font = NSAttributedString.Key(rawValue: "NSFont")
}
#endif

#if canImport(UIKit)
import UIKit
private typealias OSColor = UIColor
#elseif canImport(AppKit)
import AppKit
private typealias OSColor = NSColor
#endif

private extension NSAttributedString {
    // Creates a new attributed string using text in the font you provide.
    convenience init(string: String, font: CTFont?) {
        let font = font ?? CTFontCreateWithName("Helvetica" as CFString, 1, nil)
        let attributes = [NSAttributedString.Key.font: font]
        self.init(string: string, attributes: attributes)
    }

    // Returns an array of (path, position, color) tuples
    // for the glyphs in an attributed string
    func cgPaths(width: Double?) -> [(glyph: CGPath, offset: CGPoint, color: Color?)] {
        let framesetter = CTFramesetterCreateWithAttributedString(self as CFAttributedString)

        let range = CFRangeMake(0, 0)
        let maxSize = CGSize(width: width ?? .greatestFiniteMagnitude, height: .greatestFiniteMagnitude)
        let size = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, range, nil, maxSize, nil)
        let rectPath = CGPath(rect: CGRect(origin: .zero, size: size), transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, range, rectPath, nil)
        let lines = CTFrameGetLines(frame) as! [CTLine]

        var origins = Array(repeating: CGPoint.zero, count: lines.count)
        CTFrameGetLineOrigins(frame, range, &origins)

        var paths = [(CGPath, CGPoint, Color?)]()
        for (line, origin) in zip(lines, origins) {
            let runs = CTLineGetGlyphRuns(line) as! [CTRun]
            for run in runs {
                let attributes = CTRunGetAttributes(run) as! [NSAttributedString.Key: Any]
                let font = attributes[.font] as! CTFont
                let color = attributes[.foregroundColor] as? OSColor

                var glyph = CGGlyph()
                for index in 0 ..< CTRunGetGlyphCount(run) {
                    let range = CFRangeMake(index, 1)
                    CTRunGetGlyphs(run, range, &glyph)
                    guard let letter = CTFontCreatePathForGlyph(font, glyph, nil) else {
                        continue
                    }

                    var position = CGPoint.zero
                    CTRunGetPositions(run, range, &position)
                    position.x += origin.x
                    position.y += origin.y - origins[0].y
                    paths.append((letter, position, color.map(Color.init)))
                }
            }
        }
        return paths
    }
}

#endif
