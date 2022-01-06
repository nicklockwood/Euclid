# ``Euclid``

Euclid is a library for creating and manipulating 3D geometry using techniques such as extruding or "lathing" 2D paths to create solid 3D shapes, and CSG (Constructive Solid Geometry) to combine or subtract those shapes from one another.

## Overview

Euclid is the underlying implementation for the open source [ShapeScript scripting language](https://github.com/nicklockwood/ShapeScript) and [ShapeScript macOS app](https://itunes.apple.com/app/id1441135869). Anything you can build in ShapeScript can be replicated programmatically in Swift using this library.

If you would like to support the development of Euclid, please consider buying a copy of ShapeScript (the app itself is free, but there is an in-app purchase to unlock some features). You can also donate directly to the project via PayPal:

[![Donate via PayPal](https://www.paypalobjects.com/en_GB/i/btn/btn_donate_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=UJWT2RWPE7VA8&source=url)

**Note:** Euclid is a fairly complex piece of code, at a fairly early stage of development. You should expect some bugs and breaking changes over the first few releases, and the documentation is a little sparse. Please report any issues you encounter, and I will do my best to fix them.

## Topics

### Using Euclid

- <doc:ConstructingMeshes>
- <doc:RenderingMeshes>

### Types

- ``Vector``
- ``Color``
- ``Vertex``
- ``Polygon``
- ``Mesh``
- ``Bounds``
- ``Plane``
- ``Line``
- ``LineSegment``
- ``PathPoint``
- ``Path``
- ``Angle``
- ``Rotation``
- ``Quaternion``
- ``Rotation``
- ``Transform``

### Supporting Functions

- ``sin(_:)``
- ``cos(_:)``
- ``tan(_:)``
- ``min(_:_:)``
- ``max(_:_:)``
