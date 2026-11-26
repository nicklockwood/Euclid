# ``Euclid/Path``

A bezier path in three-dimensional space.

### Offsetting Paths

Use ``Path/inset(by:miterLimit:isCancelled:)`` to move a path's edges by a uniform distance. A positive distance shrinks the outer outline of a closed path, and a negative distance expands it.

The `miterLimit` sets the sharpest turn that can keep a mitered join at an expanding corner. On an outer outline, outsets can chamfer convex corners and insets can chamfer concave corners. Pass `1` to chamfer every expanding corner, or use ``MiterLimit/degrees(_:)`` to set a turn angle. The default, ``MiterLimit/infinity``, keeps mitered joins.

This example expands a square by one unit and chamfers all four corners.

```swift
let square = Path.square(size: 4)
let chamfered = square.inset(by: -1, miterLimit: 1)
```

## Topics

### Default Paths

- ``Path/empty``

### Creating Paths

- ``Path/init(_:)-(Collection<PathPoint>)``
- ``Path/init(_:)-(Polygon)``
- ``Path/init(subpaths:)``
- ``Path/init(_:windingRule:detail:color:)``
- ``Path/curve(_:detail:)``
- ``Path/line(_:_:color:)``
- ``Path/arc(angle:radius:segments:color:isCancelled:)``

### Creating Shape Paths

- ``Path/circle(radius:segments:color:)``
- ``Path/ellipse(width:height:segments:color:)``
- ``Path/rectangle(width:height:color:)``
- ``Path/roundedRectangle(width:height:radius:detail:color:)``
- ``Path/square(size:color:)``
- ``Path/polygon(radius:sides:color:)``

### Creating Text Paths

- ``Path/text(_:font:along:offset:rotation:width:detail:color:isCancelled:)``
- ``Path/text(_:along:offset:rotation:width:detail:isCancelled:)``

### Path Properties

- ``Path/points``
- ``Path/plane``
- ``Path/bounds``
- ``Path/length``
- ``Path/isClosed``
- ``Path/isPlanar``

### Transforming Paths

- ``Path/rotated(by:)``
- ``Path/scaled(by:)-19jpq``
- ``Path/scaled(by:)-84xdd``
- ``Path/translated(by:)``
- ``Path/transformed(by:)``
- ``Path/inset(by:miterLimit:isCancelled:)``
- ``Path/withColor(_:)``
- ``Path/withDetail(_:forTwist:)``
- ``Path/closed()``

### Interpolating Paths

- ``Path/interpolatedPoint(at:)``
- ``Path/interpolatedPoint(by:)``
- ``Path/interpolated(from:to:step:isCancelled:)``

### Clipping Paths

- ``Path/split(along:isCancelled:)``
- ``Path/clipped(to:isCancelled:)->Path``
- ``Path/clipped(to:isCancelled:)->Path?``
