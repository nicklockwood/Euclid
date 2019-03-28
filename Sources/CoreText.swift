//
//  CoreText.swift
//  Euclid
//
//  Created by Nick Lockwood on 10/03/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

#if canImport(CoreText)

import CoreText
import Foundation

#if os(watchOS)

// Workaround for missing constants on watchOS
extension NSAttributedString.Key {
    static let font = NSAttributedString.Key(rawValue: "NSFont")
}

#endif

public extension Path {
    /// Create an array of glyph contours from an attributed string
    static func text(
        _ attributedString: NSAttributedString,
        width: Double? = nil,
        detail: Int = 2
    ) -> [Path] {
        let framesetter = CTFramesetterCreateWithAttributedString(attributedString as CFAttributedString)

        let range = CFRangeMake(0, 0)
        let maxSize = CGSize(width: width ?? .greatestFiniteMagnitude, height: .greatestFiniteMagnitude)
        let size = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, range, nil, maxSize, nil)
        let rectPath = CGPath(rect: CGRect(origin: .zero, size: size), transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, range, rectPath, nil)
        let lines = CTFrameGetLines(frame) as! [CTLine]

        var origins = Array(repeating: CGPoint.zero, count: lines.count)
        CTFrameGetLineOrigins(frame, range, &origins)

        var paths = [Path]()
        for (line, origin) in zip(lines, origins) {
            let runs = CTLineGetGlyphRuns(line) as! [CTRun]
            for run in runs {
                let attributes = CTRunGetAttributes(run) as! [NSAttributedString.Key: Any]
                let font = attributes[.font] as! CTFont

                for index in 0 ..< CTRunGetGlyphCount(run) {
                    var glyph = CGGlyph()
                    let range = CFRangeMake(index, 1)
                    CTRunGetGlyphs(run, range, &glyph)
                    var position = CGPoint.zero
                    CTRunGetPositions(run, range, &position)
                    position.x += origin.x
                    position.y += origin.y - origins[0].y

                    let letter = CTFontCreatePathForGlyph(font, glyph, nil)
                    letter.map {
                        let cgPath = CGMutablePath()
                        let transform = CGAffineTransform(translationX: position.x, y: position.y)
                        cgPath.addPath($0, transform: transform)
                        paths.append(Path(cgPath: cgPath, detail: detail))
                    }
                }
            }
        }
        return paths
    }
}

public extension Mesh {
    /// Create an extruded text model from a String
    init(text: String,
         font: CTFont? = nil,
         width: Double? = nil,
         depth: Double = 1,
         detail: Int = 2,
         material: Polygon.Material = nil
    ) {
        let font = font ?? CTFontCreateWithName("Helvetica" as CFString, 1, nil)
        let attributes = [NSAttributedString.Key.font: font]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        self.init(text: attributedString, width: width, depth: depth, detail: detail, material: material)
    }

    /// Create an extruded text model from an NSAttributedString
    init(text: NSAttributedString,
         width: Double? = nil,
         depth: Double = 1,
         detail: Int = 2,
         material: Polygon.Material = nil
    ) {
        let paths = Path.text(text, width: width, detail: detail)
        let meshes = paths.map { Mesh.extrude($0, depth: depth, material: material) }
        self.init(Mesh.union(meshes).polygons)
    }
}

#endif
