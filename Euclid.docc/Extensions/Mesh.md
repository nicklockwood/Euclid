# ``Euclid/Mesh``

## Topics

### Default Meshes

- ``Mesh/empty``

### Geometric Primitives

- ``Mesh/cone(radius:height:slices:poleDetail:addDetailAtBottomPole:faces:wrapMode:material:)``
- ``Mesh/cube(center:size:faces:material:)-7wdr2``
- ``Mesh/cube(center:size:faces:material:)-imdm``
- ``Mesh/cylinder(radius:height:slices:poleDetail:faces:wrapMode:material:)``
- ``Mesh/sphere(radius:slices:stacks:poleDetail:faces:wrapMode:material:)``

- ``Mesh/WrapMode``
- ``Mesh/Faces``

### Creating Meshes from Other Meshes

- ``Mesh/convexHull(of:)-6c896``
- ``Mesh/union(_:isCancelled:)-swift.method``
- ``Mesh/union(_:isCancelled:)-swift.type.method``
- ``Mesh/intersect(_:isCancelled:)``
- ``Mesh/intersection(_:isCancelled:)``
- ``Mesh/subtract(_:isCancelled:)``
- ``Mesh/difference(_:isCancelled:)``
- ``Mesh/xor(_:isCancelled:)-swift.method``
- ``Mesh/xor(_:isCancelled:)-swift.type.method``
- ``Mesh/stencil(_:isCancelled:)-swift.method``
- ``Mesh/stencil(_:isCancelled:)-swift.type.method``

- ``Mesh/CancellationHandler``

### Creating Meshes from Polygons

- ``Mesh/init(_:)``
- ``Mesh/convexHull(of:)-8x4al``

### Creating Meshes from Paths

- ``Mesh/convexHull(of:material:)-4hvi3``
- ``Mesh/lathe(_:slices:poleDetail:addDetailForFlatPoles:faces:wrapMode:material:)``
- ``Mesh/extrude(_:along:faces:material:isCancelled:)``
- ``Mesh/extrude(_:depth:faces:material:)``
- ``Mesh/extrude(_:depth:faces:material:isCancelled:)``
- ``Mesh/fill(_:faces:material:)``
- ``Mesh/fill(_:faces:material:)``
- ``Mesh/loft(_:faces:material:)``
- ``Mesh/stroke(_:width:detail:material:)``
- ``Mesh/stroke(_:width:detail:material:isCancelled:)-85o14``
- ``Mesh/stroke(_:width:detail:material:isCancelled:)-9mn9o``

### Creating Meshes from Vertices, Points or LineSegments

- ``Mesh/convexHull(of:material:)-6176``
- ``Mesh/convexHull(of:material:)-75on2``
- ``Mesh/convexHull(of:material:)-91swk``
- ``Mesh/convexHull(of:material:)-5ztum``

### Creating Meshes from Text

- ``Mesh/text(_:font:width:depth:detail:material:)``
- ``Mesh/text(_:width:depth:detail:material:)``

### Creating Meshes from SceneKit Models

- ``Mesh/init(_:material:)``
- ``Mesh/init(_:ignoringTransforms:materialLookup:)``
- ``Mesh/init(url:ignoringTransforms:materialLookup:)``

- ``Mesh/Material``
- ``Mesh/MaterialProvider``

### Mesh Properties

- ``Mesh/polygons``
- ``Mesh/materials``
- ``Mesh/bounds``
- ``Mesh/hasTexcoords``
- ``Mesh/hasVertexColors``
- ``Mesh/isWatertight``
- ``Mesh/polygonsByMaterial``
- ``Mesh/uniqueEdges``

### Comparing Meshes

- ``Mesh/containsPoint(_:)``

### Transforming Meshes

- ``Mesh/rotated(by:)``
- ``Mesh/scaled(by:)-90bab``
- ``Mesh/scaled(by:)-94kks``
- ``Mesh/translated(by:)``
- ``Mesh/transformed(by:)``
- ``Mesh/inverted()``

### Updating Mesh Materials

- ``Mesh/replacing(_:with:)``

### Merging Meshes

- ``Mesh/merge(_:)-swift.method``
- ``Mesh/merge(_:)-swift.type.method``

### Splitting Meshes

- ``Mesh/clip(to:fill:)``
- ``Mesh/split(along:)``
- ``Mesh/edges(intersecting:)``
- ``Mesh/submeshes``

### Adjusting Mesh Topology

- ``Mesh/tessellate(maxSides:)``
- ``Mesh/triangulate()``
- ``Mesh/detessellate()``
- ``Mesh/detriangulate()``
- ``Mesh/makeWatertight()``
- ``Mesh/smoothNormals(_:)``
