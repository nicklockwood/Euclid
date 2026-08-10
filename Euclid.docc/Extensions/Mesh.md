# ``Euclid/Mesh``

A three-dimensional surface made from polygons.

## Topics

### Default Meshes

- ``Mesh/empty``

### Geometric Primitives

- ``Mesh/cone(radius:height:slices:stacks:poleDetail:addDetailAtBottomPole:faces:wrapMode:material:isCancelled:)``
- ``Mesh/cube(center:size:faces:wrapMode:material:)-8t5q8``
- ``Mesh/cube(center:size:faces:wrapMode:material:)-eado``
- ``Mesh/cylinder(radius:height:slices:poleDetail:faces:wrapMode:material:isCancelled:)``
- ``Mesh/sphere(radius:slices:stacks:poleDetail:faces:wrapMode:material:isCancelled:)``
- ``Mesh/icosahedron(radius:faces:wrapMode:material:)``

- ``Mesh/WrapMode``
- ``Mesh/Faces``

### Creating Meshes from Other Meshes

- ``Mesh/init(submeshes:)``
- ``Mesh/convexHull(of:isCancelled:)-(Collection<Mesh>,_)``
- ``Mesh/minkowskiSum(of:isCancelled:)``
- ``Mesh/union(_:isCancelled:)-swift.method``
- ``Mesh/union(_:isCancelled:)-swift.type.method``
- ``Mesh/intersection(_:isCancelled:)-swift.method``
- ``Mesh/intersection(_:isCancelled:)-swift.type.method``
- ``Mesh/subtracting(_:isCancelled:)``
- ``Mesh/difference(_:isCancelled:)``
- ``Mesh/symmetricDifference(_:isCancelled:)-swift.method``
- ``Mesh/symmetricDifference(_:isCancelled:)-swift.type.method``
- ``Mesh/stencil(_:isCancelled:)-swift.method``
- ``Mesh/stencil(_:isCancelled:)-swift.type.method``

- ``Mesh/CancellationHandler``

### Creating Meshes from Polygons

- ``Mesh/init(_:)``
- ``Mesh/convexHull(of:isCancelled:)-(Collection<Polygon>,_)``

### Creating Meshes from Paths

- ``Mesh/convexHull(of:material:isCancelled:)-(Collection<Path>,_,_)``
- ``Mesh/lathe(_:slices:poleDetail:addDetailForFlatPoles:faces:wrapMode:material:isCancelled:)``
- ``Mesh/extrude(_:along:twist:align:miterLimit:faces:material:isCancelled:)-6crez``
- ``Mesh/extrude(_:along:twist:align:miterLimit:faces:material:isCancelled:)-646jk``
- ``Mesh/extrude(_:depth:twist:sections:faces:material:isCancelled:)-(Path,_,_,_,_,_,_)``
- ``Mesh/extrude(_:depth:twist:sections:faces:material:isCancelled:)-(Collection<Path>,_,_,_,_,_,_)``
- ``Mesh/fill(_:faces:material:isCancelled:)-(Path,_,_,_)``
- ``Mesh/fill(_:faces:material:isCancelled:)-(Collection<Path>,_,_,_)``
- ``Mesh/loft(_:faces:material:isCancelled:)``
- ``Mesh/stroke(_:width:miterLimit:detail:material:isCancelled:)-9uirg``
- ``Mesh/stroke(_:width:miterLimit:detail:material:isCancelled:)-3t1zn``
- ``Mesh/stroke(_:width:detail:material:isCancelled:)``

### Creating Meshes from Vertices, Points or LineSegments

- ``Mesh/convexHull(of:material:isCancelled:)-(Collection<Vector>,_,_)``
- ``Mesh/convexHull(of:material:isCancelled:)-(Collection<Vertex>,_,_)``
- ``Mesh/convexHull(of:material:isCancelled:)-(Collection<PathPoint>,_,_)``
- ``Mesh/convexHull(of:material:isCancelled:)-(Collection<LineSegment>,_,_)``

### Creating Meshes from Text

- ``Mesh/text(_:font:width:depth:detail:material:)``
- ``Mesh/text(_:width:depth:detail:material:)``

### Creating Meshes from SceneKit Models

- ``Mesh/init(_:material:)``
- ``Mesh/init(_:ignoringTransforms:materialLookup:)``

### Importing Meshes

- ``Mesh/ImportOptions``
- ``Mesh/init(objString:options:)``
- ``Mesh/init(offString:options:)``
- ``Mesh/init(stlString:options:)``
- ``Mesh/init(stlData:options:materialLookup:)``
- ``Mesh/init(url:options:materialLookup:)``
- ``Mesh/init(_:ignoringTransforms:materialLookup:)``

### Exporting Meshes

- ``Mesh/objString()``
- ``Mesh/stlString(name:)``
- ``Mesh/stlData(colorLookup:)``
- ``Mesh/write(to:materialLookup:)``

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

- ``Mesh/intersects(_:)-3rdg``
- ``Mesh/intersects(_:)-(Plane)``
- ``Mesh/intersects(_:)-1nvd3``
- ``Mesh/edges(intersecting:)``

### Transforming Meshes

- ``Mesh/rotated(by:)``
- ``Mesh/scaled(by:)-90bab``
- ``Mesh/scaled(by:)-94kks``
- ``Mesh/translated(by:)``
- ``Mesh/transformed(by:)``
- ``Mesh/inverted()``

### Updating Materials and Texture Coordinates

- ``Mesh/replacing(_:with:)``
- ``Mesh/withMaterial(_:)``
- ``Mesh/withoutTexcoords()``
- ``Mesh/withTextureTransform(_:)``
- ``Mesh/sphereMapped()``
- ``Mesh/cylinderMapped()``
- ``Mesh/cubeMapped()``

### Merging Meshes

- ``Mesh/merge(_:)-swift.method``
- ``Mesh/merge(_:)-swift.type.method``

### Splitting Meshes

- ``Mesh/clipped(to:fill:)``
- ``Mesh/split(along:)``
- ``Mesh/submeshes``

### Adjusting Mesh Topology

- ``Mesh/tessellate(maxSides:)``
- ``Mesh/triangulate()``
- ``Mesh/detessellate(isCancelled:)``
- ``Mesh/detriangulate()``
- ``Mesh/makeWatertight(isCancelled:)``
- ``Mesh/withConsistentWinding(isCancelled:)``
- ``Mesh/smoothingNormals(forAnglesGreaterThan:)``
