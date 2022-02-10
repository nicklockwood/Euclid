# ``Euclid/PathPoint``

## Topics 

### Creating Path Points

- ``PathPoint/init(_:texcoord:color:isCurved:)``
- ``PathPoint/init(_:texcoord:isCurved:)``
- ``PathPoint/point(_:_:_:texcoord:color:)``
- ``PathPoint/point(_:texcoord:color:)``
- ``PathPoint/curve(_:_:_:texcoord:color:)``
- ``PathPoint/curve(_:texcoord:color:)``

### Interpolating between Path Points

- ``PathPoint/lerp(_:_:)``

### Inspecting Path Points

- ``PathPoint/position``
- ``PathPoint/texcoord``
- ``PathPoint/isCurved``

### Transforming Path Points

- ``PathPoint/rotated(by:)-8zjfc``
- ``PathPoint/rotated(by:)-9koyv``
- ``PathPoint/scaled(by:)-4wtbg``
- ``PathPoint/scaled(by:)-7e3o7``
- ``PathPoint/transformed(by:)``
- ``PathPoint/translated(by:)``

### Comparing Path Points

- ``PathPoint/!=(_:_:)``

### Encoding and Decoding Path Points

- ``PathPoint/encode(to:)``
- ``PathPoint/init(from:)``
