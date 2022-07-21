#ifndef MY_LIGHTING_INCLUDE
#define MY_LIGHTING_INCLUDE
#include "UnityPBSLighting.cginc"

#include "UnityCG.cginc"
#include "UnityPBSLighting.cginc"
#pragma target 3.0

struct VertexIn {
    float4 position : POSITION;
    float3 normal   : NORMAL;
    float2 texcoord : TEXCOORD;
};

struct VertexOut {
    float4 pos      : SV_POSITION;
    float3 position : TEXCOORD0;
    float3 normal   : TEXCOORD1;
    float2 texcoord : TEXCOORD2;
};

sampler2D _MainTex;
float4 _MainTex_ST;
fixed _Metallic;
fixed _Smoothness;
float4 _DiffuseAlbedo;

VertexOut vert(VertexIn vin) {
    VertexOut vout;
    float4 worldPosition = mul(unity_ObjectToWorld, vin.position);
    vout.pos = mul(UNITY_MATRIX_VP, worldPosition);
    vout.position = worldPosition.xyz;
    vout.normal = UnityObjectToWorldNormal(vin.normal);
    vout.texcoord = TRANSFORM_TEX(vin.texcoord, _MainTex);
    return vout;
}

UnityLight CreateLight(VertexOut pin, float3 N) {
    UnityLight light;
    float3 L = normalize(UnityWorldSpaceLightDir(pin.position));
    light.color = _LightColor0.rgb;
    light.dir = L;
    light.ndotl = saturate(dot(N, L));
    return light;
}

float4 frag(VertexOut pin) : SV_TARGET {
    float3 V = normalize(UnityWorldSpaceViewDir(pin.position));
    float3 N = normalize(pin.normal);
    
    float3 albedo = tex2D(_MainTex, pin.texcoord).rgb * _DiffuseAlbedo.rgb;
    float3 ambient = _LightColor0.rgb * albedo;

    float3 fresnelR0;
    float oneMinusReflectivity;
    albedo = DiffuseAndSpecularFromMetallic( 
        albedo,
        _Metallic,
        fresnelR0,
        oneMinusReflectivity
    );

    UnityLight light = CreateLight(pin, N);

    UnityIndirect indirectLight;
    indirectLight.diffuse = ambient;
    indirectLight.specular = 0;

    return UNITY_BRDF_PBS(
        albedo,
        fresnelR0,
        oneMinusReflectivity,
        _Smoothness,
        N,
        V,
        light,
        indirectLight
    );
}

#endif