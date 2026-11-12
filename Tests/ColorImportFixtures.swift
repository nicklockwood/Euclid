//
//  ColorImportFixtures.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 11/11/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

/// Hand-authored input, independent of Euclid and platform exporters.
/// USD shader connections follow https://openusd.org/release/spec_usdpreviewsurface.html.
/// Collada uses the common-profile A_ONE transparency convention.
enum ColorImportFixtures {
    static let obj = """
    mtllib input.mtl
    v -1 -1 0
    v 1 -1 0
    v 1 1 0
    v -1 1 0
    vt 0 0
    vt 1 0
    vt 1 1
    vt 0 1
    vn 0 0 1
    usemtl paint
    f 1/1/1 2/2/1 3/3/1
    f 1/1/1 3/3/1 4/4/1

    """

    static let texturedMTL = """
    newmtl paint
    Kd 1 1 1
    Ka 0 0 0
    Ks 0 0 0
    illum 2
    d 1
    map_Kd color.png
    map_d opacity.png

    """

    static func usd(textured: Bool) -> String {
        let surface = textured ? """
        color3f inputs:diffuseColor.connect = </Fixture/Paint/Color.outputs:rgb>
        float inputs:opacity.connect = </Fixture/Paint/Opacity.outputs:r>
        """ : """
        color3f inputs:diffuseColor = (0.2140411405, 0.0508760882, 0.5225215540)
        float inputs:opacity = 0.4
        """
        let textures = textured ? """
        def Shader "UV" {
            uniform token info:id = "UsdPrimvarReader_float2"
            token inputs:varname = "st"
            float2 outputs:result
        }
        def Shader "Color" {
            uniform token info:id = "UsdUVTexture"
            asset inputs:file = @color.png@
            token inputs:sourceColorSpace = "sRGB"
            float2 inputs:st.connect = </Fixture/Paint/UV.outputs:result>
            float3 outputs:rgb
        }
        def Shader "Opacity" {
            uniform token info:id = "UsdUVTexture"
            asset inputs:file = @opacity.png@
            token inputs:sourceColorSpace = "raw"
            float2 inputs:st.connect = </Fixture/Paint/UV.outputs:result>
            float outputs:r
        }
        """ : ""
        return """
        #usda 1.0
        (
            defaultPrim = "Fixture"
            upAxis = "Y"
            metersPerUnit = 1
        )
        def Xform "Fixture" {
            def Mesh "Surface" (prepend apiSchemas = ["MaterialBindingAPI"]) {
                uniform token subdivisionScheme = "none"
                bool doubleSided = true
                point3f[] points = [(-1, -1, 0), (1, -1, 0), (1, 1, 0), (-1, 1, 0)]
                int[] faceVertexCounts = [3, 3]
                int[] faceVertexIndices = [0, 1, 2, 0, 2, 3]
                normal3f[] normals = [(0, 0, 1), (0, 0, 1), (0, 0, 1), (0, 0, 1)] (
                    interpolation = "vertex"
                )
                texCoord2f[] primvars:st = [(0, 0), (1, 0), (1, 1), (0, 1)] (
                    interpolation = "vertex"
                )
                rel material:binding = </Fixture/Paint>
            }
            def Material "Paint" {
                token outputs:surface.connect = </Fixture/Paint/Surface.outputs:surface>
                def Shader "Surface" {
                    uniform token info:id = "UsdPreviewSurface"
                    \(surface)
                    float inputs:metallic = 0
                    float inputs:roughness = 1
                    token outputs:surface
                }
                \(textures)
            }
        }
        """
    }

    static func collada(textured: Bool) -> String {
        let image = textured ? """
        <library_images><image id="image"><init_from>color.png</init_from></image></library_images>
        """ : ""
        let sampler = textured ? """
        <newparam sid="surface"><surface type="2D"><init_from>image</init_from></surface></newparam>
        <newparam sid="sampler"><sampler2D><source>surface</source></sampler2D></newparam>
        """ : ""
        let diffuse = textured ? "<texture texture=\"sampler\" texcoord=\"UV\"/>" :
            "<color>0.5 0.25 0.75 1</color>"
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <COLLADA xmlns="http://www.collada.org/2005/11/COLLADASchema" version="1.4.1">
          <asset><created>2026-11-11T00:00:00Z</created><modified>2026-11-11T00:00:00Z</modified>
            <unit meter="1"/><up_axis>Y_UP</up_axis></asset>
          \(image)
          <library_effects><effect id="effect"><profile_COMMON>
            \(sampler)
            <technique sid="common"><lambert>
              <diffuse>\(diffuse)</diffuse>
              <transparent opaque="A_ONE"><color>1 1 1 0.4</color></transparent>
              <transparency><float>1</float></transparency>
            </lambert></technique>
          </profile_COMMON></effect></library_effects>
          <library_materials><material id="paint"><instance_effect url="#effect"/></material></library_materials>
          <library_geometries><geometry id="geometry"><mesh>
            <source id="positions"><float_array id="positions-array" count="12">-1 -1 0 1 -1 0 1 1 0 -1 1 0</float_array>
              <technique_common><accessor source="#positions-array" count="4" stride="3">
                <param name="X" type="float"/><param name="Y" type="float"/><param name="Z" type="float"/>
              </accessor></technique_common></source>
            <source id="uv"><float_array id="uv-array" count="8">0 0 1 0 1 1 0 1</float_array>
              <technique_common><accessor source="#uv-array" count="4" stride="2">
                <param name="S" type="float"/><param name="T" type="float"/>
              </accessor></technique_common></source>
            <vertices id="vertices"><input semantic="POSITION" source="#positions"/></vertices>
            <triangles count="2" material="paint-symbol">
              <input semantic="VERTEX" source="#vertices" offset="0"/>
              <input semantic="TEXCOORD" source="#uv" offset="0" set="0"/>
              <p>0 1 2 0 2 3</p>
            </triangles>
          </mesh></geometry></library_geometries>
          <library_visual_scenes><visual_scene id="scene"><node id="node"><instance_geometry url="#geometry">
            <bind_material><technique_common><instance_material symbol="paint-symbol" target="#paint">
              <bind_vertex_input semantic="UV" input_semantic="TEXCOORD" input_set="0"/>
            </instance_material></technique_common></bind_material>
          </instance_geometry></node></visual_scene></library_visual_scenes>
          <scene><instance_visual_scene url="#scene"/></scene>
        </COLLADA>
        """
    }
}
