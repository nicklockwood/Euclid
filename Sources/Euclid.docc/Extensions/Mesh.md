# ``Euclid/Mesh``

## Topics

### Creating Meshes

- ``Mesh/init(_:)``
- ``Mesh/init(_:material:)``
- ``Mesh/init(_:materialLookup:)-7p5hd``
- ``Mesh/init(_:materialLookup:)-ilb2``
- ``Mesh/init(url:materialLookup:)``
- ``Mesh/init(scnGeometry:materialLookup:)``

- ``Mesh/Material``
- ``Mesh/MaterialProvider``

### Creating Meshes of Geometric Primitives

- ``Mesh/cone(radius:height:slices:poleDetail:addDetailAtBottomPole:faces:wrapMode:material:)``
- ``Mesh/cube(center:size:faces:material:)-7wdr2``
- ``Mesh/cube(center:size:faces:material:)-imdm``
- ``Mesh/cylinder(radius:height:slices:poleDetail:faces:wrapMode:material:)``
- ``Mesh/sphere(radius:slices:stacks:poleDetail:faces:wrapMode:material:)``

- ``Mesh/WrapMode``
- ``Mesh/Faces``

### Creating Meshes from Paths

- ``Mesh/lathe(_:slices:poleDetail:addDetailForFlatPoles:faces:wrapMode:material:)``
- ``Mesh/extrude(_:along:faces:material:)``
- ``Mesh/extrude(_:depth:faces:material:)``
- ``Mesh/fill(_:faces:material:)``
- ``Mesh/loft(_:faces:material:)``

### Creating Text Meshes

- ``Mesh/init(text:font:width:depth:detail:material:)``
- ``Mesh/init(text:width:depth:detail:material:)``

### Inspecting Meshes

- ``Mesh/materials``
- ``Mesh/polygons``
- ``Mesh/bounds``
- ``Mesh/polygonsByMaterial``
- ``Mesh/uniqueEdges``
- ``Mesh/isWatertight``

### Moving Meshes

- ``Mesh/translated(by:)``
- ``Mesh/rotated(by:)-266e9``
- ``Mesh/rotated(by:)-38lip``
- ``Mesh/scaled(by:)-90bab``
- ``Mesh/scaled(by:)-94kks``
- ``Mesh/transformed(by:)``
- ``Mesh/scaleCorrected(for:)``

### Updating the Mesh Materials

- ``Mesh/replacing(_:with:)``

### Combining Meshes

- ``Mesh/merge(_:)-swift.method``
- ``Mesh/merge(_:)-swift.type.method``

### Splitting Meshes

- ``Mesh/split(along:)``
- ``Mesh/edges(intersecting:)``

### Adjusting Polygons within Meshes

- ``Mesh/inverted()``
- ``Mesh/tessellate()``
- ``Mesh/triangulate()``
- ``Mesh/detessellate()``
- ``Mesh/makeWatertight()``

### Encoding and Decoding Meshes

- ``Mesh/encode(to:)``
- ``Mesh/init(from:)``

### Comparing Meshes

- ``Mesh/!=(_:_:)``

### All The Stuff

- ``Mesh/CancellationHandler``
- ``Mesh/clip(to:fill:)``
- ``Mesh/difference(_:isCancelled:)``
- ``Mesh/intersect(_:isCancelled:)``
- ``Mesh/intersection(_:isCancelled:)``
- ``Mesh/stencil(_:isCancelled:)-swift.method``
- ``Mesh/stencil(_:isCancelled:)-swift.type.method``
- ``Mesh/stroke(_:width:depth:faces:material:)``
- ``Mesh/stroke(_:width:detail:material:)-9mb5w``
- ``Mesh/stroke(_:width:detail:material:)-uzi1``
- ``Mesh/subtract(_:isCancelled:)``
- ``Mesh/union(_:isCancelled:)-swift.method``
- ``Mesh/union(_:isCancelled:)-swift.type.method``
- ``Mesh/xor(_:isCancelled:)-swift.method``
- ``Mesh/xor(_:isCancelled:)-swift.type.method``
