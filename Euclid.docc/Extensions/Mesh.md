# ``Euclid/Mesh``

## Topics

### Creating Meshes

- ``Mesh/empty``
- ``Mesh/init(_:)``
- ``Mesh/init(_:material:)``
- ``Mesh/init(_:materialLookup:)-7p5hd``
- ``Mesh/init(_:materialLookup:)-ilb2``
- ``Mesh/init(url:materialLookup:)``
- ``Mesh/Material``
- ``Mesh/MaterialProvider``
- ``Mesh/init(scnGeometry:materialLookup:)``

### Creating Meshes of Geometric Primitives

- ``Mesh/cone(radius:height:slices:poleDetail:addDetailAtBottomPole:faces:wrapMode:material:)``
- ``Mesh/cube(center:size:faces:material:)-7wdr2``
- ``Mesh/cube(center:size:faces:material:)-imdm``
- ``Mesh/cylinder(radius:height:slices:poleDetail:faces:wrapMode:material:)``
- ``Mesh/sphere(radius:slices:stacks:poleDetail:faces:wrapMode:material:)``

- ``Mesh/WrapMode``
- ``Mesh/Faces``

### Building with Constructive Solid Geometery

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
- ``Mesh/extrude(_:along:faces:material:)``
- ``Mesh/extrude(_:depth:faces:material:)``
- ``Mesh/fill(_:faces:material:)``
- ``Mesh/loft(_:faces:material:)``
- ``Mesh/stroke(_:width:detail:material:)-9mb5w``
- ``Mesh/stroke(_:width:detail:material:)-uzi1``
- ``Mesh/stroke(_:width:depth:faces:material:)``

### Creating Meshes from Text

- ``Mesh/text(_:font:width:depth:detail:material:)``
- ``Mesh/text(_:width:depth:detail:material:)``

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

### Comparing Meshes

- ``Mesh/!=(_:_:)``

### Encoding and Decoding Meshes

- ``Mesh/encode(to:)``
- ``Mesh/init(from:)``

