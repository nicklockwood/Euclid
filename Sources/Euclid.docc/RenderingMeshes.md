# Rendering Meshes

Display the 3D shapes you created with meshes.

## Overview

After creating some 3D shapes, you probably want to actually *display* them.
Most of the Euclid library is completely self-contained, with no dependencies on any particular rendering technology or framework. 
However, when running on iOS or macOS you can take advantage of Euclid's built-in SceneKit integration. 
This is demonstrated in the Example app included with the project.

SceneKit is Apple's high-level 3D engine, which can use either OpenGL or Metal for rendering on supported devices. 
Euclid provides extensions for creating an `SCNGeometry` from a ``Mesh``, as well as converting Euclid ``Vector`` and ``Rotation`` types to `SCNVector` and `SCNQuaternion` respectively.

The SceneKit integration makes it easy to display Euclid geometry on-screen, and to integrate with ARKit, etc. 
You can also use SceneKit to export Euclid-generated ``Mesh`` in standard 3D model formats such as DAE, STL or OBJ.

### Materials

Interesting geometry is one thing, but to really bring a shape to life it needs colors and textures.

Every ``Polygon`` has a ``Polygon/material-swift.property`` property that can be used to apply any kind of material you like on a per-polygon basis.

All primitives and builder methods accept a `material` parameter which will apply that material to every polygon in the resultant ``Mesh``.
When you later combine meshes using CSG operations, the original materials from the `Mesh` that contributed to each part of the resultant shape are preserved.

Before a material can be used with SceneKit, you need to convert the Euclid material to an `SCNMaterial`. 
If the material is already an `SCNMaterial` instance it will be used directly. 
If the material is a ``Color``, a `UI/NSColor` or `UI/NSImage` it will be converted to an `SCNMaterial` automatically.

For all other material types, you will need to do this conversion yourself. 
You can convert materials using the optional closure argument for Euclid's `SCNGeometry` constructor, which receives the Euclid material as an input and returns an `SCNMaterial`.

When serializing Euclid geometry using `Codable`, only specific material types can be supported. 
Currently, material serialization works for `String`s, `Int`s, `Color` and any class that conforms to `NSCoding` (which includes many UIKit, AppKit and SceneKit types, such as `UI/NSColor`, `UI/NSImage` and `SCNMaterial`).


### Colors

Euclid currently has no support for setting colors on a per-vertex basis, but you can apply colors to a ``Mesh`` or ``Polygon`` using the material property.

The material property is of type `AnyHashable` which basically means it can be anything you want. 
You can set the `material` to an instance of Euclid's ``Color``, or you can use a `UIColor` or `NSColor` instead if you prefer.

This approach is demonstrated in the Example app included in the project.

### Textures

Euclid automatically adds 2D texture coordinates to the vertices of a ``Mesh`` created using primitives or builder methods. 
There is limited control over how those coordinates are specified at the moment, but they allow for simple spherical and cylindrical texture wrapping.

To apply a texture image to a ``Mesh``, store a `UIImage` or `NSImage` as the material property and it will be converted to an `SCNMaterial` automatically.

If you want to do something more complex, such as applying both a color *and* texture to the same ``Mesh``, or maybe including a normal map or some other material properties, you could create a custom material type to store all the properties you care about, or even assign an `SCNMaterial` directly as the material for your Euclid geometry.
