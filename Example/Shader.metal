//
//  Shader.metal
//
//  Created by Zack Brown on 03/08/2021.
//

using namespace metal;

#include <metal_stdlib>
#include <SceneKit/scn_metal>

struct NodeTransforms {
    float4x4 modelViewProjectionTransform;
};

struct Vertex {
    float3 position [[attribute(SCNVertexSemanticPosition)]];
    float4 color [[attribute(SCNVertexSemanticColor)]];
};

struct Fragment {
    float4 fragmentPosition [[position]];
    float4 color;
};

vertex Fragment vertex_shader(
    Vertex v [[stage_in]],
    constant NodeTransforms& scn_node [[buffer(1)]]
) {
    return {
        .fragmentPosition = scn_node.modelViewProjectionTransform * float4(v.position, 1.f),
        .color = v.color
    };
}

fragment float4 fragment_shader(Fragment f [[stage_in]]) {
    return f.color;
}
