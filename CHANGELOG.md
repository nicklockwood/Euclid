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
