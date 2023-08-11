# Change Log

## [0.6.16](https://github.com/nicklockwood/Euclid/releases/tag/0.6.16) (2023-08-11)

- Fixed `Mesh.stlString()` function

## [0.6.15](https://github.com/nicklockwood/Euclid/releases/tag/0.6.15) (2023-07-30)

- Fixed assertion failure in `Polygon.tessellate()` function
- Cone `poleDetail` now defaults to `3` instead of `sqrt(slices)`
- Improved `Mesh.makeWatertight()` reliability
- Improved `LineSegment` intersection detection
- Increased threshold for `Plane.containsPoint()`

## [0.6.14](https://github.com/nicklockwood/Euclid/releases/tag/0.6.14) (2023-06-10)

- Removed unreachable line flagged in Xcode 15 beta
- Fixed some comments

## [0.6.13](https://github.com/nicklockwood/Euclid/releases/tag/0.6.13) (2023-04-22)

- Added ASCII STL export function for Mesh
- Added `isZero` and `isOne` convenience properties
- Reduced cracking/holes for some meshes
- Fixed extrusion precision issue

## [0.6.12](https://github.com/nicklockwood/Euclid/releases/tag/0.6.12) (2023-04-04)

- Improved default `Path.arc()` segments heuristic
- Connecting open subpaths now behaves as expected
- Curved join between subpaths can now be overridden

## [0.6.11](https://github.com/nicklockwood/Euclid/releases/tag/0.6.11) (2023-03-02)

- Added `Path.arc()` function
- Add `Path.latheProfile` property

## [0.6.10](https://github.com/nicklockwood/Euclid/releases/tag/0.6.10) (2023-02-24)

- Fixed a precision problem that caused holes when creating a `Mesh` from `SCNGeometry`
- Fixed Linux and WASM builds (broken in 0.6.9)

## [0.6.9](https://github.com/nicklockwood/Euclid/releases/tag/0.6.9) (2023-02-09)

- Fixed bug when triangulating convex polygons with collinear points
- Fixed `Polygon.area` calculation for polygons not located on the XY plane
- Fixed `submeshes` property for meshes formed using a union operation

## [0.6.8](https://github.com/nicklockwood/Euclid/releases/tag/0.6.8) (2023-01-16)

- Fixed flipped front/back return values for `Mesh.split(along:)` function return value order
- Fixed `Mesh.stroke(_ shapes:)` multi-path stroke function when used with open paths
- Fixed `align` parameter in `Mesh.extrude(_:along:)` when the extruded shape has subpaths
- Fixed internal `rotationBetweenVectors()` function when vectors are parallel and opposite
- Fixed assertion failure in `Mesh.clip(to:)` when using `fill` argument
- Fixed assertion inverted fill plane in `Mesh.clip(to:)` when input is inverted Z plane
- Fixed bug where splitting planar mesh along its plane had no effect
- Added `Polygon.split(along:)` and `Polygon.clip(to:)` methods

## [0.6.7](https://github.com/nicklockwood/Euclid/releases/tag/0.6.7) (2023-01-01)

- Fixed use of duplicate cross-sections to create sharp junctions in `loft` shapes
- Fixed `Path(polygon:)` initializer to create closed path and preserve colors
- Added convenience initializers to convert between `Vertex` and `PathPoint`
- Added `Path.with(color:)` and `PathPoint.with(color:)` helpers
- Added `Mesh(submeshes:)` convenience initializer
- Added convenience initializers for `Transform`
- Removed obsolete backwards compatibility code

## [0.6.6](https://github.com/nicklockwood/Euclid/releases/tag/0.6.6) (2022-12-17)

- Reduced compilation time for some complex expressions to fix Linux build

## [0.6.5](https://github.com/nicklockwood/Euclid/releases/tag/0.6.5) (2022-12-08)

- Added `twist` and `sections` parameters for `Mesh.extrude()` methods
- Angle correction is now distributed evenly along extrusion length
- Added `Path.extrusionContours()` method
- Fixed crash when angle is infinite or NaN
- Fixed end caps for loft/extrusion shapes

## [0.6.4](https://github.com/nicklockwood/Euclid/releases/tag/0.6.4) (2022-11-21)

- Improved default alignment heuristic when extruding along non-planar paths
- Added `Alignment` enum for controlling shape alignment when extruding along a path
- Fixed bug in face normal calculation for open paths
- Added scalar multiply/divide operators for `Rotation`

## [0.6.3](https://github.com/nicklockwood/Euclid/releases/tag/0.6.3) (2022-11-17)

- Fixed crash when extruding single-point path
- Fixed `Quaternion.axis` when angle is zero
- Disfavored `Angle.cos`/`sin`/`tan` overloads to improve ergonomics
- Added `Polygon.area` property

## [0.6.2](https://github.com/nicklockwood/Euclid/releases/tag/0.6.2) (2022-11-05)

- Added `Mesh.convexHull()` shape constructors
- Added `Polygon.orderedEdges` property
- Added `LineSegment.inverted()` method

## [0.6.1](https://github.com/nicklockwood/Euclid/releases/tag/0.6.1) (2022-11-02)

- Added `Transformable` protocol for all types that can be transformed
- Added initializer to create an `SCNMatrix4` from a `Transform`
- Transformable types (`Vector`, `Polygon`, `Mesh`, etc.) now support in-place transforms
- Swapped disfavored rotation method overloads from `Rotation` to `Quaternion`
- Added transform methods and `Transformable` conformance to `LineSegment`
- Normalized `Quaternion` at creation time (which fixes an assertion failure in `Plane`)
- Attempting to load a `Mesh` from an inaccessible URL now throws instead of failing silently
- Fixed assertion failure due to `sortedByPlane()` regression in 0.6.0
- Negative scale factors now behave as expected when applied to `Vertex`
- Topology is now preserved when loading a `Mesh` from a URL

## [0.6.0](https://github.com/nicklockwood/Euclid/releases/tag/0.6.0) (2022-10-22)

- Added support for rendering Euclid meshes using `RealityKit`
- CSG polygon clip operations now run concurrently (Note: `isCancelled` may now be called on any thread)
- Euclid `Rotation` now uses a quaternion representation internally rather than a 3x3 matrix
- Rotations are now serialized as a more compact 4-element axis/angle array when using `Codable`
- Added `axis` and `angle` property getters to `Rotation` and `Quaternion`
- Added `slerp()` (spherical linear interpolation) method to `Rotation`
- Added `Vector.unitX/Y/Z` constants
- The material order when generating `SCNGeometry` is now deterministic
- Euclid's `Quaternion` implementation now uses the SIMD framework if available
- The `tessellate()` methods now accept an optional `maxSides:` argument
- The `Angle` and `Vector` types now conform to the `AdditiveArithmetic` protocol
- Polygon materials of type `CGColor` or `CGImage` are now supported automatically in SceneKit
- Fixed some common assertion failures when running in debug mode
- Improved performance when applying transforms with null/identity values
- Removed previously deprecated methods and properties
- Raised minimum supported iOS version to 11

## [0.5.30](https://github.com/nicklockwood/Euclid/releases/tag/0.5.30) (2022-09-26)

- Fixed bug where applying negative scale to bounds made it empty

## [0.5.29](https://github.com/nicklockwood/Euclid/releases/tag/0.5.29) (2022-09-03)

- Fixed bug where transforming an empty bounds led to nan coordinates
- Fixed assertion failure when flattening non-horizontal paths
- Added `Mesh.containsPoint()` method
- Improved some deprecation messages

## [0.5.28](https://github.com/nicklockwood/Euclid/releases/tag/0.5.28) (2022-08-12)

- Fixed crash when bulk CSG methods were called with an empty array
- Fixed incorrect result from bulk `Mesh.intersection()` method when input meshes are non-intersecting 
- Removed legacy behavior in `Mesh.union()` where polygon order was flipped unnecessarily
- Bulk CSG methods now work with arbitrary `Collection`s of `Mesh`, not just an `Array`

## [0.5.27](https://github.com/nicklockwood/Euclid/releases/tag/0.5.27) (2022-08-06)
 
- Added efficient methods for filling, extruding and stroking multiple paths
- Imported meshes that contain non-planar polygons are now tessellated instead of having holes
- Improved logic for removing hairline cracks in imported meshes
- Fixed bug where material could be lost when triangulating/tessellating polygons
- Fixed bug where `Mesh.submeshes` returned too many submeshes
- Fixed retain cycle in `Mesh.submeshes`
- Submeshes are now cached for faster access
- All cancellation callbacks are now non-escaping

## [0.5.26](https://github.com/nicklockwood/Euclid/releases/tag/0.5.26) (2022-07-24)

- SceneKit meshes are now more reliably sealed at import time
- Improved triangulation/tessellation of complex convex polygons
- Fixed case where `loft` could produce a mesh with redundant back-face polygons
- You can now create `Path`s with a single point (useful when lofting)
- Fixed crash when lofting zero-scale path
- Fixed assertion failure when scaling path by zero vector
- Reduced false negatives when comparing `Plane` equality
- Improved performance of uniform `Plane` scaling
- Added `Sendable` conformance to all applicable types when building with Xcode 14
- Converted unintended static `var` values to `let`
- Fixed warnings in Xcode 14 beta

## [0.5.25](https://github.com/nicklockwood/Euclid/releases/tag/0.5.25) (2022-07-03)

- Added `Mesh.submeshes` property
- Loft now supports path sections with differing point counts
- Fixed normals at joints between multipart loft or extrusion shapes
- Fixed crash when lofting empty paths

## [0.5.24](https://github.com/nicklockwood/Euclid/releases/tag/0.5.24) (2022-06-26)

- Fixed crash when extruding along collinear points
- Fixed bug when lofting intermediate open paths
- Improved `makeWatertight()` implementation
- Improved vertex merging logic to only merge vertices that cause holes
- Fixed bugs in triangulation logic that could introduce holes
- Fixed case where mesh was incorrectly assumed to be watertight
- Vector equality is now exact again, instead of using quantization internally
- Fixed spurious assertion when using compound paths

## [0.5.23](https://github.com/nicklockwood/Euclid/releases/tag/0.5.23) (2022-06-09)

- Fixed crash in `mergingSimilarVertices()` function
- Used heuristic for `mergingSimilarVertices()` instead of hard-coded epsilon
- Increased epsilon precision again to fix cracking issues (and added tests)

## [0.5.22](https://github.com/nicklockwood/Euclid/releases/tag/0.5.22) (2022-06-02)

- Reduced epsilon precision to fix assertion when creating `Mesh` from `SCNGeometry`
- Added WASM (Web Assembly) compatibility tests

## [0.5.21](https://github.com/nicklockwood/Euclid/releases/tag/0.5.21) (2022-05-28)

- Fixed a glitch with how stroke or extrude-along was applied to paths with sharp corners
- Fixed a bug where PathPoint colors were incorrectly applied for non-closed paths
- The `pivot` property is now taken into account when creating `Mesh` from an `SCNNode`
- Added ability to create a `Transform` from an `SCNMatrix4`
- Fixed warnings in Xcode 13.4

## [0.5.20](https://github.com/nicklockwood/Euclid/releases/tag/0.5.20) (2022-04-12)

- Added input sanitization to `Angle.acos()` and `Angle.asin()` (fixes `Mesh.smoothNormals()`)
- Changed `Mesh.smoothNormals()` threshold check from `<=` to `<`
- Improved `Mesh.smoothNormals()` performance

## [0.5.19](https://github.com/nicklockwood/Euclid/releases/tag/0.5.19) (2022-04-11)

- Improved `Mesh.makeWatertight()` reliability
- Meshes created from SceneKit primitives are now watertight
- Increased `LineSegment.containsPoint()` tolerance 
- Added `Mesh.detriangulate()` method
- Added `Mesh.smoothNormals()` function

## [0.5.18](https://github.com/nicklockwood/Euclid/releases/tag/0.5.18) (2022-04-08)

- Added `Mesh.empty` constant
- Added `Path.roundedRectangle()` method
- Fixed assertion failure due to incorrect `isWatertight` assumption
- Fixed precision issue with `LineSegment.containsPoint()` method
- The `Polygon(_: [Vector])` constructor now takes any `Vector` sequence
- Added `Vector` -> `CGize` conversion functions
- Renamed `Path(cgPath:)` to `Path(_:)` for consistency
- Renamed `Mesh(text:)` constructor to `Mesh.text()`
- Replaced broken `SCNNode`/`URL` Mesh initializers
- Deprecated `Vector.quantized()` method
- Fixed warnings in Xcode 13.3

## [0.5.17](https://github.com/nicklockwood/Euclid/releases/tag/0.5.17) (2022-02-23)

- Euclid now includes full DocC documentation (big thanks to Joseph Heck for making this happen)
- Fixed unused vertex color parameter in `Path.line()` constructor
- Added missing `w` component to `Quaternion.components` property
- Fixed unused detail argument in `Mesh(text:)` constructor
- Fixed a bug in the `faceNormalForPolygonPoints()` utility function
- Fixed bug in `Plane.intersection(with: Plane)` calculation

## [0.5.16](https://github.com/nicklockwood/Euclid/releases/tag/0.5.16) (2022-01-04)

- Added `Vertex.color` property
- Added `PathPoint.color` property
- Added `color` parameters for `Path` constructors
- Added `lerp()` functions for `Color` collections
- Added check to skip all-zero texture coordinates when exporting to SceneKit

## [0.5.15](https://github.com/nicklockwood/Euclid/releases/tag/0.5.15) (2021-12-22)

- Added `Mesh.makeWatertight()` method, for removing hairline cracks in meshes
- Vector `==` operator now returns approximate equality, solving some issues with quantization
- The `Mesh.isWatertight` getter is now a stored property, so cheaper to access
- Added unordered min/max point initializer for `Bounds`
- Added convenience initializer for uniform-sized Vectors
- Fixed assertion failure when creating a polygon with < 3 points
- Improved performance for `Mesh.polygonsByMaterial` getter
- Added `Mesh.edges(intersecting:)` method
- Added `Bounds.inset()` methods

## [0.5.14](https://github.com/nicklockwood/Euclid/releases/tag/0.5.14) (2021-11-01)

- Added support for `triangleStrip` and `polygon` primitives when creating a `Mesh` from `SCNGeometry`
- Creating a `Mesh` from an `SCNGeometry` now returns nil if the mesh can't be loaded

## [0.5.13](https://github.com/nicklockwood/Euclid/releases/tag/0.5.13) (2021-10-15)

- Fixed support for Mac Catalyst

## [0.5.12](https://github.com/nicklockwood/Euclid/releases/tag/0.5.12) (2021-09-12)

- Added `Quaternion` type as an alternative representation for rotations
- The `Rotation.pitch`/`yaw`/`roll` properties should now return correct values
- Fixed bug when defining a zero-width rectangle path
- Fixed bug when encoding vertices with zeroed normals

## [0.5.11](https://github.com/nicklockwood/Euclid/releases/tag/0.5.11) (2021-09-03)

- Added `Mesh.stroke()` function variant for generating wireframes
- Added `Mesh.loft()` optimization for common cases
- Added optimized `Mesh.merge()` function for merging multiple meshes at once
- Added `Bounds.formUnion()` and `Bounds.formIntersection()` functions
- Added fast-path optimization for `Polygon.triangulate()`
- Improved compilation time for the CSG `Mesh.union()` function
- Deprecated `Mesh.scaleCorrected()` and `Polygon.scaleCorrected()`
- Tweaked `Bounds.isEmpty` logic so that zero volume counts as empty

## [0.5.10](https://github.com/nicklockwood/Euclid/releases/tag/0.5.10) (2021-08-30)

- Added `Color` type for convenient cross-platform color materials
- Fixed bug when calculating face normal for very small paths
- Texture coordinates are now preserved when using the `Path.curve()` constructor
- Fixed bug where `Angle.atan()` was actually calling `tan()` instead
- Added `Path.line()` constructor for creating straight lines
- Added `Path.polygon()` constructor for creating regular polygons
- Added `Path.text(_:font:)` convenience constructor
- Improved `Mesh.stroke()` constructor to allow for variable detail

## [0.5.9](https://github.com/nicklockwood/Euclid/releases/tag/0.5.9) (2021-08-19)

- Fixed relative orientation when extruding along a path
- Fixed missing face polygons when extruding along a complex shape such as text
- Fixed back-face duplication when lofting a line shape
- Fixed assertion in `Path(points:)` when creating a simple line shape
- Fixed assertion when lofting complex shapes like text

## [0.5.8](https://github.com/nicklockwood/Euclid/releases/tag/0.5.8) (2021-08-15)

- Fixed several bugs in `Polygon` validation that could lead to cracks in generated meshes
- Fixed spurious assertion in `Path(points:)` initializer

## [0.5.7](https://github.com/nicklockwood/Euclid/releases/tag/0.5.7) (2021-08-13)

- Fixed a regression in `SCNGeometry(_ path:)` introduced in version 0.3.6

## [0.5.6](https://github.com/nicklockwood/Euclid/releases/tag/0.5.6) (2021-08-10)

- Fixed axis alignment bug when extruding complex shapes along a custom path
- Increased epsilon precision to fix mesh corruption issues in extruded text paths

## [0.5.5](https://github.com/nicklockwood/Euclid/releases/tag/0.5.5) (2021-08-09)

- Vertices with zero normals are automatically corrected to use the face normal
- Vertex normals are now optional
- Polygons can now be created from an array of vector positions (normals are set automatically)
- Imported models are now converted to use Y-up automatically, matching SceneKit convention

## [0.5.4](https://github.com/nicklockwood/Euclid/releases/tag/0.5.4) (2021-08-04)

- Fixed a regression in `Mesh.fill()` introduced in 0.5.0 that affected nested paths (e.g. text)
- Fixed a bug in the calculation of vertex normals for non-planar paths
- Fixed a bug where extruding non-planar paths could result in an inside-out mesh  
- Lengthy CSG operations can now be interrupted by using the optional `isCancelled` callback
- Improved `Mesh.xor()` and `Mesh.stencil()` performance by merging CSG steps
- Self-intersecting paths can now be lathed
- Added `Path.stroke()` method

## [0.5.3](https://github.com/nicklockwood/Euclid/releases/tag/0.5.3) (2021-07-30)

- Slightly improved the performance of bounds checking during CSG operations
- The `Polygon.bounds` is no longer a stored property, which should reduce memory footprint
- Coincident `Line`s will now always be equal, even if initialized with a different `origin`
- Fixed a bug where Z component was ignored when testing for `LineSegment` intersection
- Fixed a performance regression in `Vector.distance(from: Plane)`, introduced in version 0.5.0
- Added `min()`/`max()` functions for component-wise comparison of `Vector`s
- Added `Line.intersection(with: Plane)` method

## [0.5.2](https://github.com/nicklockwood/Euclid/releases/tag/0.5.2) (2021-07-28)

- Fixed some bugs when serializing texture coordinates with a non-zero Z component
- Fixed assertion in `shortestLineBetween()` utility function
- Fixed spurious assertion in `LineSegment` initializer
- The identity `Rotation` is now encoded more compactly when serializing
- Added a more compact serialized encoding for `Line` and `LineSegment`
- Added `Vector(size:)` initializer with better defaults for size/scale vectors

## [0.5.1](https://github.com/nicklockwood/Euclid/releases/tag/0.5.1) (2021-07-25)

- Added `LineSegment.containsPoint()` method
- Added `Mesh.isWatertight` property to determine if a mesh contains holes
- Reduced BSP construction time when performing CSG operations on convex meshes
- Fixed edge case where `Mesh.detessellate()` function would fail to merge adjacent polygons
- Fixed bug where CSG operations would sometimes unnecessarily tesselate polygons
- Improved back-face insertion logic for lofted paths

## [0.5.0](https://github.com/nicklockwood/Euclid/releases/tag/0.5.0) (2021-07-12)

- Added `Mesh.detessellate()` method and `Mesh.uniqueEdges` property
- `Mesh` initializer no longer tessellates non-convex polygons automatically
- Added methods for computing intersections and distances between points, planes and lines
- `Line` and `LineSegment` intersection methods now correctly work for lines in different planes 
- `Polygon` initializer now rejects vertices that would form self-intersecting edges
- Fixed crash when attempting to create fill or lathe meshes from self-intersecting paths
- Fixed certain cases where `Path.edgeVertices` would produce inverted normals
- Added method to easily create a `Path` from a `Polygon`
- Texture coordinates with a non-zero Z component are now serialized correctly
- Added optional `texcoord` property to `PathPoint`s
- The `Mesh.fill()`, `Mesh.extrude()` and `Mesh.loft()` methods now work with non-planar paths
- The `Path.faceVertices` property now works correctly for non-planar paths
- Added `Path.facePolygons()` method for filling non-planar paths

## [0.4.7](https://github.com/nicklockwood/Euclid/releases/tag/0.4.7) (2021-07-09)

- Fixed tessellation bug affecting anti-clockwise polygons
- Fixed bug where `Mesh(url:materialLookup:)` initializer ignored `materialLookup:` parameter
- Made `SCNGeometry(polygons:)` `materialLookup:` callback return value optional for consistency

## [0.4.6](https://github.com/nicklockwood/Euclid/releases/tag/0.4.6) (2021-07-04)

- Fixed bug in Path plane calculation that could result in corrupted extrusion shapes
- Fixed edge case in logic for detecting degenerate polygons
- Added +=, -=, *= and /= Vector operators
- Added `Vector.translated(by:)` function

## [0.4.5](https://github.com/nicklockwood/Euclid/releases/tag/0.4.5) (2021-06-26)

- Rewrote CSG operations to use iteration rather than recursion, so they no longer overflow stack 
- Add methods to create a Mesh from an SCNNode or file url (in any ModelIO-supported format)
- Removed spurious assertion failure when creating paths with multiple subpaths

## [0.4.4](https://github.com/nicklockwood/Euclid/releases/tag/0.4.4) (2021-04-27)

- Fixed glitch in CSG operations on multiple meshes
- Improved performance for CSG functions on non-convex meshes

## [0.4.3](https://github.com/nicklockwood/Euclid/releases/tag/0.4.3) (2021-04-24)

- Added up, right, forward vectors to Rotation
- Removed unused file

## [0.4.2](https://github.com/nicklockwood/Euclid/releases/tag/0.4.2) (2021-04-16)

- Reduced size of serialized mesh data by ~50%
- Materials are now deduplicated when encoding/decoding
- Fixed bug when decoding serialized rotation values

## [0.4.1](https://github.com/nicklockwood/Euclid/releases/tag/0.4.1) (2021-04-14)

- Fixed bug with encoding texture coordinates
- Material property is no longer encoded for polygons if nil

## [0.4.0](https://github.com/nicklockwood/Euclid/releases/tag/0.4.0) (2021-04-04)

- Added type-safe Angle API replacing raw Doubles
- Added plane intersection and direction utility functions
- Upgraded project to Swift 5.1

## [0.3.6](https://github.com/nicklockwood/Euclid/releases/tag/0.3.6) (2020-11-22)

- Euclid types now conform to Codable for easy serialization
- Added default implementation for SCNMaterial mapping
- Fixed bug where SCNGeometry detail argument was ignored
- Added missing Embed Frameworks phase to example app

## [0.3.5](https://github.com/nicklockwood/Euclid/releases/tag/0.3.5) (2020-09-03)

- Fixed bug with loft function when two edges are not parallel, resulting in a non-planar polygon

## [0.3.4](https://github.com/nicklockwood/Euclid/releases/tag/0.3.4) (2020-05-23)

- Fixed issue where shapes extruded a long a path were sometimes tilted (not perpendicular to path)
- Fixed internal random number generator (broken by a change introduced in Swift 5.2)
- Simplified path to SCNGeometry conversion

## [0.3.3](https://github.com/nicklockwood/Euclid/releases/tag/0.3.3) (2020-04-13)

- Fixed a precision issue when forming unions between meshes with coinciding surfaces

## [0.3.2](https://github.com/nicklockwood/Euclid/releases/tag/0.3.2) (2020-04-12)

- Added ability to extrude a shape along a path

## [0.3.1](https://github.com/nicklockwood/Euclid/releases/tag/0.3.1) (2020-03-22)

- Fixed a bug where cubic bezier components of `CGPath`s were not handled correctly
- Fixed some bugs in the plane clipping algorithm
- Slightly reduced compilation time

## [0.3.0](https://github.com/nicklockwood/Euclid/releases/tag/0.3.0) (2020-01-22)

- Significantly improved performance for CSG functions, especially for convex meshes
- Fixed bug where `Path.circle` and `Path.ellipse` could produce unclosed polygon
- `Mesh.polygons` is now read-only. Use initializer or `merge` functions to modify mesh
- Added mesh tessellation/inversion methods

## [0.2.3](https://github.com/nicklockwood/Euclid/releases/tag/0.2.3) (2020-01-14)

- Improved CSG performance by another 2X by converting Polygon to a reference type internally
- Improved `polygonsByMaterial` getter for Mesh, which also speeds up conversion to SceneKit Geometry

## [0.2.2](https://github.com/nicklockwood/Euclid/releases/tag/0.2.2) (2020-01-11)

- Fixed infinite loop when constructing BSP for CSG operations
- Clip to plane function now fills correctly if plane does not pass through the origin
- LineSegment initializer is now public

## [0.2.1](https://github.com/nicklockwood/Euclid/releases/tag/0.2.1) (2020-01-11)

- Improved CSG performance by 2X on average
- Added methods for clipping or splitting a Mesh along a Plane
- Added computed components property to Vector
- Added methods to compute distance and projection between a point and Plane
- Fixed some bugs relating to coplanar polygon clipping

## [0.2.0](https://github.com/nicklockwood/Euclid/releases/tag/0.2.0) (2020-01-04)

- Added Swift 5 compatibility fixes
- Added Line and LineSegment types
- Unified iOS and macOS framework targets

## [0.1.9](https://github.com/nicklockwood/Euclid/releases/tag/0.1.9) (2019-04-03)

- Fixed polygon triangulation edge case
- Improved automatic sanitization of paths with degenerate vertices  
- Paths with subpaths now display correctly when rendered with SceneKit
- Further improved text rendering performance
- Added methods for transforming planes

## [0.1.8](https://github.com/nicklockwood/Euclid/releases/tag/0.1.8) (2019-03-28)

- Added support for multiple subpaths within a single Path instance
- CGPaths can now be converted to a single Path instead of an array of subpaths
- Added methods for performing bulk CSG operations on arrays of meshes
- Improved text rendering performance

## [0.1.7](https://github.com/nicklockwood/Euclid/releases/tag/0.1.7) (2019-03-11)

- Added support for creating Euclid Paths from a Core Graphics CGPath
- Added support for rendering 2D or extruded 3D text using Core Text
- Fixed some bugs in triangulation that occasionally caused concave polygons not to render
- Fixed a bug where material was not set correctly for extrusions with a depth of zero
- Added XOR CSG function (useful for rendering text)
- Added ellipse constructor for Path

## [0.1.6](https://github.com/nicklockwood/Euclid/releases/tag/0.1.6) (2019-02-27)

- Improved CSG operations on coplanar polygons
- Default radius for circle Path is now 0.5 instead of 1.0
- Added Linux test suite

## [0.1.5](https://github.com/nicklockwood/Euclid/releases/tag/0.1.5) (2019-01-21)

- Reduced epsilon value in order to avoid precision-related bugs
- Fixed an occasional assertion failure in triangulation logic
- Polygon initializer now checks that points are planar
- Mesh and Polygon now conform to Hashable
- Added ability to convert SceneKit geometry back to a Mesh

## [0.1.4](https://github.com/nicklockwood/Euclid/releases/tag/0.1.4) (2019-01-09)

- Fixed bug with Vector transform application order (also affected Bounds calculation)

## [0.1.3](https://github.com/nicklockwood/Euclid/releases/tag/0.1.3) (2018-12-19)

- Fixed bug in Plane calculation for closed Paths

## [0.1.2](https://github.com/nicklockwood/Euclid/releases/tag/0.1.2) (2018-12-14)

- Polygon constructor now accepts concave vertices
- Added missing transform methods
- Improved polygon merging performance
- Improved tessellation algorithm

## [0.1.1](https://github.com/nicklockwood/Euclid/releases/tag/0.1.1) (2018-12-12)

- Fixed some bugs in the order of application of Transforms
- Fixed mixed up pitch, yaw and roll logic

## [0.1.0](https://github.com/nicklockwood/Euclid/releases/tag/0.1.0) (2018-12-11)

- First release
