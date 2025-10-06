# Constructing Meshes

Define 3D objects by constructing meshes. 

## Overview

To create a 3D object, create a ``Mesh`` in Euclid.
You can manually create an array of ``Polygon`` instances, but that's pretty tedious. 
Euclid offers a number of helper methods to quickly create complex geometry.

### Primitive Geometry

The simplest way to create a ``Mesh`` is to start with an existing primitive, such as a cube or sphere. 
The following primitive types are available in Euclid, and are defined as static constructor methods on ``Mesh``:

- ``Mesh/cube(center:size:faces:wrapMode:material:)-8t5q8`` - A cubic ``Mesh`` (or cuboid, if you specify different values for the width, height and/or depth).
- ``Mesh/sphere(radius:slices:stacks:poleDetail:faces:wrapMode:material:)`` - A spherical `Mesh`.
- ``Mesh/cylinder(radius:height:slices:poleDetail:faces:wrapMode:material:)`` - A cylindrical `Mesh`.
- ``Mesh/cone(radius:height:slices:stacks:poleDetail:addDetailAtBottomPole:faces:wrapMode:material:)`` -  A conical ``Mesh``.

All `Mesh` instances are made of flat polygons. 
Since true curves cannot be represented using straight edges, the `sphere`, `cylinder` and `cone` primitives are approximations.
Control the quality of these approximations by using the `slices` and/or `stacks` parameters to configure the level of detail.

In addition to the 3D ``Mesh`` primitives listed, there are also 2D ``Path`` primitives. 
These are implemented as static constructor methods on the ``Path`` type instead of ``Mesh``:

- ``Path/line(_:color:)`` - A straight line.
- ``Path/ellipse(width:height:segments:color:)``- A closed, elliptical ``Path``.
- ``Path/circle(radius:segments:color:)``  - A closed, circular ``Path``.
- ``Path/rectangle(width:height:color:)`` - A closed, rectangular ``Path``.
- ``Path/roundedRectangle(width:height:radius:detail:color:)`` - A closed, rectangular ``Path`` with rounded corners.
- ``Path/square(size:color:)`` - Same as ``Path/rectangle(width:height:color:)``, but with equal width and height.
- ``Path/polygon(radius:sides:color:)`` - A regular polygon shape (not to be confused with Euclid's ``Polygon`` type).

### Builders

Geometric primitives are all very well, but there is a limit to what you can create by combining spheres, cubes, etc. 
As an intermediate step between the extremes of using predefined primitives or individually positioning polygons, you can use *builders*.

Builders create a ``Mesh`` from a (typically) 2D ``Path``.
The following builders are defined as static constructor functions on the ``Mesh`` type:

- ``Mesh/fill(_:faces:material:isCancelled:)-(Path,_,_,_)`` - This builder fills a single `Path` to create a pair of `Polygon`s (front and back faces).
- ``Mesh/stroke(_:width:detail:material:isCancelled:)-85o14`` - This builder strokes a single `Path` to create a strip or tube. A second variant (``Mesh/stroke(_:width:detail:material:isCancelled:)-(Collection<LineSegment>,_,_,_,_)``) of the function accepts an collection of ``LineSegment``, which is convenient for creating a wireframe geometry from the `uniqueEdges` of a ``Mesh``.
- ``Mesh/lathe(_:slices:poleDetail:addDetailForFlatPoles:faces:wrapMode:material:isCancelled:)`` - This builder takes a 2D ``Path`` and rotates it around the Y-axis to create a rotationally symmetrical ``Mesh``. This is an easy way to create complex shapes like candlesticks, chess pieces, rocket ships, etc.
- ``Mesh/extrude(_:along:twist:align:faces:material:isCancelled:)`` - This builder fills a ``Path`` and extrudes it along its axis, or another path. This can turn a circular path into a tube, or a square into a cube etc.
- ``Mesh/loft(_:faces:material:isCancelled:)`` - This builder is similar to ``Mesh/extrude(_:along:twist:align:faces:material:isCancelled:)``, but takes multiple ``Path`` instances and joins them. The sequence of ``Path`` instances do not need to be the same shape, but must all have the same number of points and subpaths. To work correctly, each ``Path`` must be pre-positioned in 3D space so they do not all lie on the same plane.
- ``Mesh/convexHull(of:material:isCancelled:)-(Collection<Vector>,_,_)`` - Similar the the ``Mesh/loft(_:faces:material:isCancelled:)`` builder, this method can form a Mesh by wrapping a skin around one or more ``Path`` instances. But unlike the other builders, in addition to paths you can also form a convex hull around a collection of meshes, polygons, vertices or points.

### Curves

Builders are a powerful tool for creating interesting ``Mesh`` instances from one or more ``Path`` instances, but what about creating an interesting ``Path`` in the first place?

Creating a polygonal ``Path`` by specifying points individually is straightforward, but creating *curves* that way is tedious.
That's where *Bezier* curves come in. Beziers allow you to specify complex curves using just a few control points. 
Euclid exposes this feature via the ``Path/curve(_:detail:)`` constructor method.

The ``Path/curve(_:detail:)`` method takes an array of ``PathPoint`` and a `detail` argument. 
Normally, the ``PathPoint/isCurved`` property is used to calculate surface normals (for lighting purposes), but with the ``Path/curve(_:detail:)`` method it actually affects the shape of the ``Path``.

A sequence of regular (non-curved) ``PathPoint``s create sharp corners in the ``Path`` as normal, but curved ones are treated as off-curve Bezier control points. 
The `detail` argument of the ``Path/curve(_:detail:)`` method controls how many line segments are used to approximate the curve.

The ``Path/curve(_:detail:)`` method uses second-order (quadratic) Bezier curves, where each curve has two on-curve end points and a single off-curve control point. 
If two curved ``PathPoint`` are used in sequence then an on-curve point is interpolated between them. 
It is therefore  possible to create curves entirely out of curved (off-curve) control points.

This approach to curve generation is based on the popular [TrueType (TTF) font system](https://developer.apple.com/fonts/TrueType-Reference-Manual/RM01/Chap1.html), and provides a good balance between simplicity and flexibility.

For more complex curves, on macOS and iOS you can create Euclid ``Path`` from a Core Graphics `CGPath` by using the `CGPath.paths()` extension method. 
`CGPath` supports cubic bezier curves as well as quadratic.

### Constructive Solid Geometry (CSG)

CSG is another powerful tool for creating intricate geometry. 
CSG allows you to perform boolean operations (logical AND, OR, etc.) on solid shapes. 
The following CSG operations are defined as methods on the ``Mesh`` type:

- ``Mesh/subtracting(_:isCancelled:)`` - Subtracts the volume of one `Mesh` from another.
- ``Mesh/symmetricDifference(_:isCancelled:)-swift.type.method`` - Produces a shape representing the non-overlapping parts of the input `Mesh`es (this is useful for rendering text glyphs).
- ``Mesh/union(_:isCancelled:)-swift.method`` - Combines two intersecting `Mesh`es, removing internal faces and leaving only the outer shell around both shapes (logical OR).
- ``Mesh/intersection(_:isCancelled:)-swift.method`` - Returns a single ``Mesh`` representing the common volume of two intersecting ``Mesh``es (logical AND).
- ``Mesh/stencil(_:isCancelled:)-swift.method`` - This effectively "paints" part of one ``Mesh`` with the material from another.
- ``Mesh/convexHull(with:isCancelled:)-swift.method`` - This creates a convex hull around one or more meshes.
- ``Mesh/minkowskiSum(with:isCancelled:)-(Mesh,_)`` - This traces the edges of one mesh with another.

Most CSG operations require ``Mesh``es that are "watertight", that is they have no holes in their surface. 
Using a CSG operation on a mesh that isn't sealed may result in unexpected results.

### Text

On macOS and iOS you can make use of Euclid's Core Text integration to create 2D or 3D extruded text.

The ``Path/text(_:width:detail:)`` method produces an array of 2D ``Path`` that represent the contours of each glyph in an `AttributedString`. You can use these paths with either ``Mesh/fill(_:faces:material:isCancelled:)-([Path],_,_,_)`` or ``Mesh/extrude(_:depth:twist:sections:faces:material:isCancelled:)-(Collection<Path>,_,_,_,_,_,_)`` builder methods to create solid text.

Alternatively, the ``Mesh/text(_:font:width:depth:detail:material:)`` constructor directly produces an extruded 3D text model from a `String` or `AttributedString`.

Each glyph in the input string maps to a single ``Path`` in the result, but these ``Path``s may contain nested subpaths. 
Glyphs formed from multiple subpaths will be filled using the even-odd rule (equivalent to using `symmetricDifference` with the individually filled or extruded subpaths).
