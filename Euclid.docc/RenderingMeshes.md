# Rendering Meshes

Display the 3D shapes you created with meshes.

## Overview

After creating some 3D shapes, you probably want to actually *display* them.

Most of the Euclid library is completely self-contained, with no dependencies on any particular rendering technology or framework. However, when running on iOS or macOS you can take advantage of Euclid's built-in SceneKit and RealityKit integration. This is demonstrated in the Example app included with the project.

SceneKit is a high-level Apple 3D framework that can use either OpenGL or Metal for rendering on supported devices. Euclid provides extensions for creating an `SCNGeometry` from a ``Mesh``, as well as converting Euclid ``Vector`` and ``Rotation`` types to `SCNVector` and `SCNQuaternion` respectively.

The SceneKit integration makes it easy to display Euclid geometry on-screen, and to integrate with ARKit, etc. You can also use SceneKit to export Euclid-generated ``Mesh`` in standard 3D model formats such as DAE, STL or OBJ.

RealityKit is a newer Apple framework mainly intended for VR/AR purposes. It is slightly lower-level than SceneKit, and missing some high-level functionality such as camera control, but is equally-well supported by Euclid.

### Materials

Interesting geometry is one thing, but to really bring a shape to life it needs colors and textures.

Every ``Polygon`` has a ``Polygon/material-swift.property`` property that can be used to apply any kind of material you like on a per-polygon basis.

All primitives and builder methods accept a `material` parameter which will apply that material to every polygon in the resultant ``Mesh``. When you later combine meshes using CSG operations, the original materials from the `Mesh` that contributed to each part of the resultant shape are preserved.

Before a material can be used with SceneKit, you need to convert the Euclid material to an `SCNMaterial`. If the material is already an `SCNMaterial` instance it will be used directly.  If the material is a ``Color``, a `CG/UI/NSColor` or `CG/UI/NSImage` it will be converted to an `SCNMaterial` automatically.

For all other material types, you will need to do this conversion yourself. You can convert materials using the optional closure argument for Euclid's `SCNGeometry` constructor, which receives the Euclid material as an input and returns an `SCNMaterial`. An equivalent closure exists for Euclid's RealityKit `ModelEntity` constructor.

When serializing Euclid geometry using `Codable`, only specific material types can be supported. Currently, material serialization works for `String`s, `Int`s, `Color` and any class that conforms to `NSCoding` (which includes many UIKit, AppKit and SceneKit types, such as `UI/NSColor`, `UI/NSImage` and `SCNMaterial`).

### Colors

``Color`` stores **sRGB-encoded** components with **unpremultiplied alpha**. RGB and HSV initializers, named colors, serialized components, component-wise multiplication, and interpolation retain their sRGB convention. SceneKit and RealityKit adapters decode vertex RGB to linear light on export. SceneKit imports encode it back to sRGB. Alpha is never gamma-corrected.

`Color(cgColor)`, `Color(nsColor)`, and `Color(uiColor)` convert their input from its declared color space to sRGB. Conversely, `NSColor(color)` and `UIColor(color)` interpret Euclid components as sRGB. Use the `colorSpace:` overloads for another RGB space. Passing `nil` explicitly copies components without conversion on input and uses the platform's original RGB initializer on output.

Use `toLinear()` for linear-light calculations and `toSRGB()` to encode the results. These conversion functions leave alpha unchanged and preserve extended-range values. Source-over compositing and RealityKit material tint multiplication are calculated in linear light.

The `luminance` property does not perform sRGB-to-linear conversion. Use `color.toLinear().luminance` to calculate linear relative luminance. Compositing returns sRGB-encoded components. `*` and `lerp` are component-wise operations.

Raw OBJ/OFF/STL color components have no reliable color profile, so callers must convert according to their source's convention when known. Binary STL color extensions do not declare a color profile or conversion function. Euclid preserves their component values (subject to 5-bit facet quantization) without applying gamma conversion, and interprets imported colors using its sRGB convention. This is a compatibility policy, not a guarantee that every STL producer uses sRGB. Use the STL material/color lookup closures for conversions when a source or destination's convention is known.

ASCII PLY files can be loaded with `Mesh(plyString:)` or `Mesh(url:)`. The native reader preserves vertex RGB and alpha, normals and UV coordinates. Byte colors are normalized to 0...1 and interpreted using Euclid's sRGB convention; floating-point colors are preserved numerically. Binary PLY still requires a platform importer, whose supported attributes may differ. Use `try mesh.plyString()` or `mesh.write(to:)` to export ASCII PLY with sRGB vertex RGBA. A color lookup can supply material tint, which is multiplied with vertex RGB in linear light. Textures are not embedded.

Euclid supports applying colors to a ``Mesh`` or ``Polygon`` using the material property, but you can also set colors individually for each vertex, which will be interpolated to create smooth gradients.

The material property is of type `AnyHashable` which basically means it can be anything you want. You can set the `material` to an instance of Euclid's ``Color``, or you can use a `CGColor`, `UIColor` or `NSColor` instead if you prefer.

This approach is demonstrated in the Example app included in the project.

### Textures

Euclid automatically adds 2D texture coordinates to the vertices of a ``Mesh`` created using primitives or builder methods. 
There is limited control over how those coordinates are specified at the moment, but they allow for simple cylindrical or spherical texture wrapping.

You can also scale, rotate or translate the texture coordinates for a ``Mesh`` by using - ``Mesh/withTextureTransform(_:)``, or remap the texture coordinates completely by using the ``Mesh/sphereMapped()``, ``Mesh/cylinderMapped()`` and ``Mesh/cubeMapped()`` methods. This can be useful for wrapping composite objects that you've created using CSG functions, where the texture coordinates may end up scrambled.

To apply a texture image to a ``Mesh``, store a `UIImage` or `NSImage` as the material property and it will be converted to an `SCNMaterial` automatically.

If you want to do something more complex, such as applying both a color *and* texture to the same ``Mesh``, or maybe including a normal map or some other material properties, you could create a custom material type to store all the properties you care about, or even assign an `SCNMaterial` or RealityKit `Material` directly.

### RealityKit vertex colors

On macOS 15, iOS 18, tvOS 26, and visionOS 2 or later, Euclid's default and `triangles:` `ModelEntity` initializers preserve vertex colors using `LowLevelMesh`. The `polygons:` and `quads:` initializers retain their requested tessellation using `MeshDescriptor` and do not preserve vertex-color attributes. Older platforms continue to use `MeshDescriptor`, which does not preserve vertex colors.

You can also construct a `LowLevelMesh` directly with `LowLevelMesh(mesh)`, or use `MeshResource.generate(triangles: mesh)` (synchronously or asynchronously) to select the appropriate conversion automatically. Normals, texture coordinates, vertex alpha, and polygon material assignments are preserved.

For static collision shapes, create a separate resource using `MeshResource.generate(from: [MeshDescriptor(triangles: mesh)])` and pass it to `ShapeResource.generateStaticMesh(from:)`. Generating a static collision shape directly from a `LowLevelMesh` resource can throw `staticMeshGenerationFailed`; this was reproduced on macOS 15.8.2, iOS 18.5/18.6 Simulator, and visionOS 2.3/2.5 Simulator. The collision resource does not need vertex colors; keep the original resource for rendering.

Euclid applies uniform vertex colors to RealityKit's built-in materials automatically, multiplying color and opacity per material. This fallback works on older platforms and with the polygon and quad initializers too. Custom materials are left unchanged to avoid applying vertex colors twice.

RealityKit's built-in materials do not support vertex-color gradients. On supported platforms, `try await ModelEntity(mesh)` and the async `triangles:` initializer automatically select ``RealityKitVertexColorMaterial`` for materials with varying vertex colors. Default color tints, textures, and alpha are preserved. Uniform vertex colors retain the built-in-material fallback. Explicit RealityKit materials and custom material lookup closures are not replaced.

Shader loading is asynchronous, so synchronous initializers do not select this shader automatically. For customized shading, supply a `ShaderGraphMaterial` via the material lookup closure, or create one with ``RealityKitVertexColorMaterial``:

```swift
let material = try await RealityKitVertexColorMaterial.make(
    color: Color(white: 0.8),
    roughness: 0.6
)
let entity = try await ModelEntity(mesh) { _ in material }
```

The `RealityKitVertexColorMaterial.make()` function accepts a base tint (including opacity), emission, and scalar roughness, metallic, and specular values. It supports textures for base color, normals, opacity, emission, roughness, and metallicity. Vertex, tint, and base-texture RGB are multiplied in linear light; alpha and the opacity texture are multiplied without gamma conversion.

Load base-color and emission textures with `.color` semantics. Load opacity, roughness, and metallic textures with `.scalar` semantics; their red channels multiply the corresponding scalar values. Use a scalar value of `1` for an unscaled texture, and an emission color of `.white` for an untinted emission texture. Normal maps use OpenGL-style tangent-space normals and must be loaded with `.normal` semantics. Unlit materials use base color, opacity, and emission, and ignore the lighting-related inputs.

The returned `ShaderGraphMaterial` can be customized, for example to change face culling behavior. Shader templates are cached, while each returned material has independent parameter values.
