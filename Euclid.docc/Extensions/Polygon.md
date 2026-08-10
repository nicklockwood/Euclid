# ``Euclid/Polygon``

A flat polygonal face in a mesh.

## Topics

### Creating Polygons

- ``Polygon/init(_:material:)-([Vertex],_)``
- ``Polygon/init(_:material:)-(Collection<Vector>,_)``

### Polygon Properties

- ``Polygon/vertices``
- ``Polygon/plane``
- ``Polygon/bounds``
- ``Polygon/centroid``
- ``Polygon/material-swift.property``
- ``Polygon/isConvex``
- ``Polygon/hasTexcoords``
- ``Polygon/hasVertexColors``
- ``Polygon/orderedEdges``
- ``Polygon/undirectedEdges``
- ``Polygon/area``

### Comparing Polygons

- ``Polygon/intersects(_:)-4f51y``
- ``Polygon/intersects(_:)-(Plane)``
- ``Polygon/intersects(_:)-87xk8``
- ``Polygon/edges(intersecting:)``

### Transforming Polygons

- ``Polygon/rotated(by:)``
- ``Polygon/scaled(by:)-69m6m``
- ``Polygon/scaled(by:)-8sjrv``
- ``Polygon/translated(by:)``
- ``Polygon/transformed(by:)``
- ``Polygon/merge(_:ensureConvex:)``
- ``Polygon/inverted()``
- ``Polygon/withMaterial(_:)``

### Splitting Polygons

- ``Polygon/clipped(to:)``
- ``Polygon/split(along:)``
- ``Polygon/tessellate(maxSides:)``
- ``Polygon/triangulate()``
