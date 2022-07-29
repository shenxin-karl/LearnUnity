#ifndef _MY_SHADER_INCLUDE_
#define _MY_SHADER_INCLUDE_

/*
    _ALBEDO_MAP
    _NORMAL_MAP
    _METALLIC_MAP
    _SMOOTHNESS_MAP
    _DETAIL_ALBEDO_MAP
    _DETAIL_NORMAL_MAP
    VERTEXLIGHT_ON
    SHADOWS_SCREEN
    FORWARD_BASE
    UNITY_SPECCUBE_BLENDING
    UNITY_SPECCUBE_BOX_PROJECTION
*/

#include "UnityPBSLighting.cginc"
#include "UnityCG.cginc"
#include "UnityPBSLighting.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"
#pragma target 3.0

struct VertexIn {
    float4 vertex   : POSITION;
    float3 normal   : NORMAL;
    float2 texcoord : TEXCOORD;
#if defined(_NORMAL_MAP) || defined(_DETAIL_NORMAL_MAP)
    float4 tangent  : TANGENT;
#endif
};

struct VertexOut {
    float4 pos           : SV_POSITION;
    float3 worldPosition : TEXCOORD0;
    float3 worldNormal   : TEXCOORD1;
    float2 texcoord      : TEXCOORD2;
#if defined(_DETAIL_ALBEDO_MAP)
    float2 texcoord1     : TEXCOORD3;
#endif
#if defined(_NORMAL_MAP) || defined(_DETAIL_NORMAL_MAP)
    float3 worldTangent  : TEXCOORD4;
#endif
#if defined(VERTEXLIGHT_ON)
    float3 vertexLightColor : TEXCOORD5;
#endif
#if defined(SHADOWS_SCREEN)
    SHADOW_COORDS(6)
#endif
};

sampler2D _AlbedoTex;
float4 _AlbedoTex_ST;
float4 _DiffuseAlbedo;
float  _Metallic;
float  _Smoothness;

#if defined(_NORMAL_MAP)
    sampler2D _NormalTex;
    float _BumpScale;
#endif

#if defined(_METALLIC_MAP)
    sampler2D _MetallicTex;
#endif

#if defined(_SMOOTHNESS_MAP)
    sampler2D _SmoothnessTex;
#endif

#if defined(_DETAIL_ALBEDO_MAP)
    sampler2D _DetailAlbedoTex;
#endif
float4    _DetailAlbedoTex_ST; 

#if defined(_DETAIL_NORMAL_MAP)
    sampler2D _DetailNormalTex;
    float _DetailNormalScale;
#endif


VertexOut vert(VertexIn vin) {
    VertexOut vout;
    float4 worldPosition = mul(unity_ObjectToWorld, vin.vertex);
    vout.pos = mul(UNITY_MATRIX_VP, worldPosition);
    vout.worldPosition = worldPosition.xyz;
    vout.worldNormal = UnityObjectToWorldNormal(vin.normal);
    vout.texcoord = TRANSFORM_TEX(vin.texcoord, _AlbedoTex);

    #if defined(_DETAIL_ALBEDO_MAP) || defined(_DETAIL_NORMAL_MAP)
        vout.texcoord1 = TRANSFORM_TEX(vin.texcoord, _DetailAlbedoTex);
    #endif

    #if defined(_NORMAL_MAP) || defined(_DETAIL_NORMAL_MAP)
        vout.worldTangent = float4(UnityObjectToWorldDir(vin.tangent.xyz), vin.tangent.w);
    #endif

    #if defined(VERTEXLIGHT_ON)
        vout.vertexLightColor = Shade4PointLights(
            unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
            unity_LightColor[0], unity_LightColor[1], unity_LightColor[2], unity_LightColor[3],
            unity_4LightAtten0, vout.normal, vout.position
        );
    #endif

    #if defined(SHADOWS_SCREEN)
        TRANSFER_SHADOW(vout);	
    #endif
    return vout;
}

float3 getNormal(VertexOut pin) {
    #if defined(_NORMAL_MAP) 
        float3 N = normalize(pin.worldNormal);
        float3 T = normalize(pin.worldTangent.xyz);
        float3 B = cross(N, T) * pin.worldTangent.w;
        float3 mainNormal = UnpackScaleNormal(tex2D(_NormalMap, pin.texcoord.xy), _BumpScale);
        float3 tangentSpaceNormal = mainNormal;
        #if defined(_DETAIL_NORMAL_MAP)
            float3 detailNormal = UnpackScaleNormal(tex2D(_DetailNormalMap, pin.texcoord1), _DetailNormalScale);
            tangentSpaceNormal = BlendNormals(mainNormal, detailNormal);
        #endif
    #else
        
    #endif
}

float4 frag(VertexOut pin) : SV_Target {
    float3 N = getNormal(pin);
    float3 V = normalize(UnityWorldSpaceViewDir(pin.position));

}

#endif