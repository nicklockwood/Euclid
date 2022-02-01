# ``Euclid/Path``

## Topics 

### Creating Paths

- ``Path/init(_:)``
- ``Path/init(subpaths:)``
- ``Path/init(polygon:)``
- ``Path/init(cgPath:detail:)``

### Creating Paths of Lines and Curves

- ``Path/curve(_:detail:)``
- ``Path/line(_:_:)``
- ``Path/line(_:)``

### Creating Shape Paths

- ``Path/circle(radius:segments:)``
- ``Path/ellipse(width:height:segments:)``
- ``Path/rectangle(width:height:)``
- ``Path/square(size:)``
- ``Path/polygon(radius:sides:)``

### Creating Text Paths

- ``Path/text(_:font:width:detail:)``
- ``Path/text(_:width:detail:)``

### Inspecting Paths

- ``Path/points``
- ``Path/isClosed``
- ``Path/plane``

- ``Path/isPlanar``
- ``Path/bounds``
- ``Path/faceNormal``
- ``Path/subpaths``

- ``Path/facePolygons(material:)``
- ``Path/faceVertices``
- ``Path/edgeVertices``
- ``Path/edgeVertices(for:)``

### Updating Paths

- ``Path/closed()``

### Transforming Paths

- ``Path/rotated(by:)-3qnnh``
- ``Path/rotated(by:)-4iaqb``
- ``Path/scaled(by:)-19jpq``
- ``Path/scaled(by:)-84xdd``
- ``Path/transformed(by:)``
- ``Path/translated(by:)``

### Comparing Paths

- ``Path/!=(_:_:)``

### Encoding and Decoding Paths

- ``Path/encode(to:)``
- ``Path/init(from:)``
