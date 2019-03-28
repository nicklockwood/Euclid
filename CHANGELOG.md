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
