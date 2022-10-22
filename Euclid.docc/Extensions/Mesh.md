# ``Euclid/Mesh``

## Topics

### Creating Meshes

- ``Mesh/init(_:)``
- ``Mesh/init(_:material:)``
- ``Mesh/init(_:materialLookup:)-7p5hd``
- ``Mesh/init(_:ignoringTransforms:materialLookup:)``
- ``Mesh/init(url:ignoringTransforms:materialLookup:)``

- ``Mesh/Material``
- ``Mesh/MaterialProvider``

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

### Constructive Solid Geometry

- ``Mesh/union(_:isCancelled:)-swift.method``
- ``Mesh/union(_:isCancelled:)-swift.type.method``
- ``Mesh/intersect(_:isCancelled:)``
- ``Mesh/intersection(_:isCancelled:)``
- ``Mesh/subtract(_:isCancelled:)``
- ``Mesh/difference(_:isCancelled:)``
- ``Mesh/clip(to:fill:)``
- ``Mesh/xor(_:isCancelled:)-swift.method``
- ``Mesh/xor(_:isCancelled:)-swift.type.method``
- ``Mesh/stencil(_:isCancelled:)-swift.method``
- ``Mesh/stencil(_:isCancelled:)-swift.type.method``

- ``Mesh/CancellationHandler``

### Creating Meshes from Paths

- ``Mesh/lathe(_:slices:poleDetail:addDetailForFlatPoles:faces:wrapMode:material:)``
- ``Mesh/extrude(_:along:faces:material:isCancelled:)``
- ``Mesh/extrude(_:depth:faces:material:)``
- ``Mesh/extrude(_:depth:faces:material:isCancelled:)``
- ``Mesh/fill(_:faces:material:)``
- ``Mesh/fill(_:faces:material:)``
- ``Mesh/loft(_:faces:material:isCancelled:)``
- ``Mesh/stroke(_:width:detail:material:)``
- ``Mesh/stroke(_:width:detail:material:isCancelled:)-85o14``
- ``Mesh/stroke(_:width:detail:material:isCancelled:)-9mn9o``

### Creating Meshes from Text

- ``Mesh/text(_:font:width:depth:detail:material:)``
- ``Mesh/text(_:width:depth:detail:material:)``

### Comparing Meshes

- ``Mesh/bounds``
- ``Mesh/containsPoint(_:)``
- ``Mesh/hasTexcoords``
- ``Mesh/hasVertexColors``
- ``Mesh/isWatertight``
- ``Mesh/materials``
- ``Mesh/polygons``
- ``Mesh/polygonsByMaterial``
- ``Mesh/uniqueEdges``

### Transforming Meshes

- ``Mesh/translated(by:)``
- ``Mesh/rotated(by:)-266e9``
- ``Mesh/rotated(by:)-38lip``
- ``Mesh/scaled(by:)-90bab``
- ``Mesh/scaled(by:)-94kks``
- ``Mesh/transformed(by:)``

### Updating Mesh Materials

- ``Mesh/replacing(_:with:)``

### Merging Meshes

- ``Mesh/merge(_:)-swift.method``
- ``Mesh/merge(_:)-swift.type.method``

### Splitting Meshes

- ``Mesh/split(along:)``
- ``Mesh/edges(intersecting:)``
- ``Mesh/submeshes``

### Adjusting Mesh Topology

- ``Mesh/inverted()``
- ``Mesh/tessellate(maxSides:)``
- ``Mesh/triangulate()``
- ``Mesh/detessellate()``
- ``Mesh/detriangulate()``
- ``Mesh/makeWatertight()``
- ``Mesh/smoothNormals(_:)``
