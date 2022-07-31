#ifndef _MY_SHADER_INCLUDE_
#define _MY_SHADER_INCLUDE_


/*
 
Properties
    {
        _AlbedoTex ("AlbedoTexture", 2D) = "white" {}
        _DiffuseAlbedo ("DiffuseAlbedo", Color) = (1, 1, 1, 1)
        [NoScaleOffset] _NormalTex ("NormalTexture", 2D) = "bump" {}
        [NoScaleOffset] _MetallicTex ("MetallicTexture", 2D) = "white" {}
        [NoScaleOffset] _SmoothnessTex ("SmoothnessTexture", 2D) = "white" {}
        [NoScaleOffset] _OcclusionTex ("OcclusionTexture", 2D) = "white" {}
        [NoScaleOffset] _EmissionTex ("EmissionTexture", 2D) = "block" {}
        _EmissionColor ("EmissionColor", Color) = (0, 0, 0, 0) 
        _BumpScale ("BumpScale", float) = 1.0
        _OcclusionStrength ("OcclusionStrength", Range(0, 1)) = 1.0
        _AlphaCutoff ("AlphaCutoff", Range(0, 1)) = 0.5
        [gamma] _Metallic ("Metallic", Range(0, 1)) = 0.5
        _Smoothness ("Smoothness", Range(0, 1)) = 0.5
        _DetailAlbedoTex ("DetailAlbedoTex", 2D) = "white" {}
        [NoScaleOffset] _DetailNormalTex ("DetailNormalTex", 2D) = "bump" {}
        [NoScaleOffset] _DetailMaskTex ("DetailMaskTexture", 2D) = "white" {}
        _DetailNormalScale ("DetailNormalScale", float) = 1.0 
    }
    CustomEditor "MyLightingShaderGUI"
    
*/

#include "UnityPBSLighting.cginc"
#include "UnityCG.cginc"
#include "UnityPBSLighting.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"

#pragma shader_feature _ _ALBEDO_MAP
#pragma shader_feature _ _MATERIAL_MAP
#pragma shader_feature _ _NORMAL_MAP
#pragma shader_feature _ _METALLIC_MAP
#pragma shader_feature _ _SMOOTHNESS_MAP 
#pragma shader_feature _ _DETAIL_ALBEDO_MAP
#pragma shader_feature _ _DETAIL_NORMAL_MAP
#pragma shader_feature _ _SMOOTHNESS_SOURCE _SMOOTHNESS_ALBEDO_SOURCE _SMOOTHNESS_METALLIC_SOURCE
#pragma shader_feature _ _EMISSION_MAP
#pragma shader_feature _ _OCCLUSION_MAP
#pragma shader_feature _ _OCCLUSTION_SOURCE _OCCLUSTION_METALLIC_SOURCE
#pragma shader_feature _ _DETAIL_MASK_MAP
#pragma shader_feature _ _RENDERING_MODE_ALPHA_TEST

#pragma shader_feature _ VERTEXLIGHT_ON
#pragma shader_feature _ SHADOWS_SCREEN

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
#if defined(_DETAIL_ALBEDO_MAP) || defined(_DETAIL_NORMAL_MAP)
    float2 texcoord1     : TEXCOORD3;
#endif
#if defined(_NORMAL_MAP) || defined(_DETAIL_NORMAL_MAP)
    float4 worldTangent  : TEXCOORD4;
#endif
#if defined(VERTEXLIGHT_ON)
    float3 vertexLightColor : TEXCOORD5;
#endif
#if defined(SHADOWS_SCREEN)
    SHADOW_COORDS(6)
#endif
};

sampler2D _AlbedoTex;
sampler2D _NormalTex;
sampler2D _MetallicTex;
sampler2D _SmoothnessTex;
sampler2D _DetailAlbedoTex;
sampler2D _DetailNormalTex;
sampler2D _EmissionTex;
sampler2D _OcclusionTex;
sampler2D _DetailMaskTex;
float4    _DetailAlbedoTex_ST; 
float4    _AlbedoTex_ST;
float4    _DiffuseAlbedo;
float4    _EmissionColor;
float     _Metallic;
float     _Smoothness;
float     _BumpScale;
float     _DetailNormalScale;
float     _OcclusionStrength;
float     _AlphaCutoff;

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
            unity_4LightAtten0, vout.worldNormal, vout.worldPosition
        );
    #endif

    #if defined(SHADOWS_SCREEN)
        TRANSFER_SHADOW(vout);	
    #endif
    return vout;
}

float getDetailMask(VertexOut pin) {
    #if defined(_DETAIL_MASK_MAP)
        return tex2D(_DetailMaskTex, pin.texcoord).a;
    #endif
    return 1.0;
}

float3 getNormal(VertexOut pin) {
    #if defined(_NORMAL_MAP) || defined(_DETAIL_NORMAL_MAP)
        float3 N = normalize(pin.worldNormal);
        float3 T = normalize(pin.worldTangent.xyz);
        float3 B = cross(N, T) * pin.worldTangent.w;
    #endif
    
    #if defined(_NORMAL_MAP) 
        float3 mainNormal = UnpackScaleNormal(tex2D(_NormalTex, pin.texcoord.xy), _BumpScale);
        float3 tangentSpaceNormal = mainNormal;
        #if defined(_DETAIL_NORMAL_MAP)
            float3 detailNormal = UnpackScaleNormal(tex2D(_DetailNormalTex, pin.texcoord1), _DetailNormalScale);
            #if defined(_DETAIL_MASK_MAP)
                detailNormal = lerp(float3(0, 0, 1), detailNormal, getDetailMask(pin));                    
            #endif
            tangentSpaceNormal = BlendNormals(mainNormal, detailNormal);
        #endif
        return normalize(T * tangentSpaceNormal.x + B * tangentSpaceNormal.y + N * tangentSpaceNormal.z);
    #elif defined(_DETAIL_NORMAL_MAP)
        float3 detailNormal = UnpackScaleNormal(tex2D(_DetailNormalTex, pin.texcoord1.xy), _DetailNormalScale);
        return normalize(T * detailNormal.x + B * detailNormal.y + N * detailNormal.z);
    #endif
    return normalize(pin.worldNormal);
}

float getOcclusion(VertexOut pin) {
    #if defined(_OCCLUSTION_SOURCE) && defined(_OCCLUSION_MAP)
        return lerp(1.0, tex2D(_OcclusionTex, pin.texcoord.xy).r, _OcclusionStrength);
    #elif defined(_OCCLUSTION_METALLIC_SOURCE) && defined(_METALLIC_MAP)
        return lerp(1.0, tex2D(_MetallicTex, pin.texcoord).g, _OcclusionStrength);
    #endif
    return 1.0;
}

UnityLight CreateLight(VertexOut pin, float3 N) {
    UnityLight light;
    float3 L = normalize(UnityWorldSpaceLightDir(pin.worldPosition));
    #if defined(SHADOWS_SCREEN)
        UNITY_LIGHT_ATTENUATION(attenuation, pin, pin.worldPosition);
    #else
        UNITY_LIGHT_ATTENUATION(attenuation, 0, pin.worldPosition);
    #endif
    
    light.color = _LightColor0.rgb * attenuation * getOcclusion(pin);
    light.dir = L;
    light.ndotl = saturate(dot(N, L));
    return light;
}

float3 BoxProjection(float3 direction, float3 position, float4 cubemapPosition, float3 boxMin, float3 boxMax) {
    #if UNITY_SPECCUBE_BOX_PROJECTION
    UNITY_BRANCH
    if (cubemapPosition.w > 0.0) {
        float3 factors = ((direction > 0 ? boxMax : boxMin) - position) / direction;
        float scalar = min(min(factors.x, factors.y), factors.z);
        direction = direction * scalar + (position - cubemapPosition); 
    }
    #endif
    return direction;
}

UnityIndirect CreateUnityIndirectLight(VertexOut pin, float3 albedo, float3 V) {
    UnityIndirect indirectLight;
    indirectLight.diffuse = 0;
    indirectLight.specular = 0;

    #ifdef FORWARD_BASE
        indirectLight.diffuse = max(0, ShadeSH9(float4(pin.worldNormal, 1.0)));
        Unity_GlossyEnvironmentData envData;
        envData.roughness = 1 - _Smoothness;
        float3 R = reflect(-V, pin.worldNormal);
        envData.reflUVW = BoxProjection(
                R, pin.worldPosition,
                unity_SpecCube0_ProbePosition,
                unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax
            );
        float3 probe0 = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData);

        #if UNITY_SPECCUBE_BLENDING
            envData.reflUVW = BoxProjection(
                R, pin.worldPosition,
                unity_SpecCube1_ProbePosition,
                unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax
            );
            float3 probe1 = Unity_GlossyEnvironment(
                UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1, unity_SpecCube0), unity_SpecCube0_HDR, envData
            );
            indirectLight.specular = lerp(probe1, probe0, unity_SpecCube0_BoxMin.w);
        #else
            indirectLight.specular = probe0;
        #endif
    
        float occlusionStrength = getOcclusion(pin);
        indirectLight.diffuse *= occlusionStrength;
        indirectLight.specular *= occlusionStrength;
    #endif

    #if defined(VERTEXLIGHT_ON)
        indirectLight.diffuse += pin.vertexLightColor;
    #endif
    return indirectLight;
}

float3 getAlbedo(VertexOut pin) {
    float3 albedo = _DiffuseAlbedo.rgb;
    #if defined(_ALBEDO_MAP)
        albedo *= tex2D(_AlbedoTex, pin.texcoord).rgb;
    #endif
    #if defined(_DETAIL_ALBEDO_MAP)
        float3 detailAlbedo = tex2D(_DetailAlbedoTex, pin.texcoord1).rgb * unity_ColorSpaceDouble;
        albedo = lerp(albedo, albedo * detailAlbedo, getDetailMask(pin));
    #endif
    return albedo;
}

float getMetallic(VertexOut pin) {
    float metallic = _Metallic;
    #if defined(_METALLIC_MAP)
        metallic *= tex2D(_MetallicTex, pin.texcoord).r;
    #endif
    return metallic;
}

float getSmoothness(VertexOut pin) {
    float smoothness = _Smoothness;
    #if defined(_SMOOTHNESS_SOURCE) && defined(_SMOOTHNESS_MAP) 
        smoothness *= tex2D(_SmoothnessTex, pin.texcoord).r;
    #elif defined(_SMOOTHNESS_ALBEDO_SOURCE) && defined(_ALBEDO_MAP)
        smoothness *= tex2D(_AlbedoTex, pin.texcoord).a;
    #elif defined(_SMOOTHNESS_METALLIC_SOURCE) && defined(_METALLIC_MAP)
        smoothness *= tex2D(_MetallicTex, pin.texcoord).a;
    #endif
    return smoothness;
}

float3 getEmission(VertexOut pin) {
    #if defined(FORWARD_BASE)
        #if defined(_EMISSION_MAP)
            return tex2D(_EmissionTex, pin.texcoord).rgb * _EmissionColor.rgb;
        #else
            return _EmissionColor.rgb;
        #endif
    #endif
    return 0;
}

float getAlpha(VertexOut pin) {
    float alpha = _DiffuseAlbedo.a;
    #if !defined(_SMOOTHNESS_ALBEDO_SOURCE)
        alpha *= tex2D(_AlbedoTex, pin.texcoord).a;
    #endif
    return alpha;
}

float4 frag(VertexOut pin) : SV_Target {
    #if defined(_RENDERING_MODE_ALPHA_TEST)
        clip(getAlpha(pin) - _AlphaCutoff);    
    #endif
    float3 N = getNormal(pin);
    float3 V = normalize(UnityWorldSpaceViewDir(pin.worldPosition));
    
    float3 fresnelR0;
    float oneMinusReflectivity;
    float3 albedo = DiffuseAndSpecularFromMetallic( 
        getAlbedo(pin),
        getMetallic(pin),
        fresnelR0,
        oneMinusReflectivity
    );

    UnityLight light = CreateLight(pin, N);
    UnityIndirect indirectLight = CreateUnityIndirectLight(pin, albedo, V);
    float4 finalColor = UNITY_BRDF_PBS(
        albedo,
        fresnelR0,
        oneMinusReflectivity,
        getSmoothness(pin),
        N,
        V,
        light,
        indirectLight
    );
    finalColor.xyz += getEmission(pin);
    return finalColor;
}

#endif