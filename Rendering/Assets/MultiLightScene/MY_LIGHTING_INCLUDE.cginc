#ifndef MY_LIGHTING_INCLUDE
#define MY_LIGHTING_INCLUDE
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
};

struct VertexOut {
    float4 pos      : SV_POSITION;
    float3 position : TEXCOORD0;
    float3 normal   : TEXCOORD1;
    float2 texcoord : TEXCOORD2;
#if defined(VERTEXLIGHT_ON)
	float3 vertexLightColor : TEXCOORD3;
#endif

#if defined(SHADOWS_SCREEN)
	SHADOW_COORDS(4)
#endif
};

sampler2D _MainTex;
float4 _MainTex_ST;
fixed _Metallic;
fixed _Smoothness;
float4 _DiffuseAlbedo;

VertexOut vert(VertexIn vin) {
    VertexOut vout;
    float4 worldPosition = mul(unity_ObjectToWorld, vin.vertex);
    vout.pos = mul(UNITY_MATRIX_VP, worldPosition);
    vout.position = worldPosition.xyz;
    vout.normal = UnityObjectToWorldNormal(vin.normal);
    vout.texcoord = TRANSFORM_TEX(vin.texcoord, _MainTex);

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

UnityLight CreateLight(VertexOut pin, float3 N) {
    UnityLight light;
    float3 L = normalize(UnityWorldSpaceLightDir(pin.position));
#if defined(SHADOWS_SCREEN)
    UNITY_LIGHT_ATTENUATION(attenuation, pin, pin.position);
#else
    UNITY_LIGHT_ATTENUATION(attenuation, 0, pin.position);
#endif
    light.color = _LightColor0.rgb * attenuation;
    light.dir = L;
    light.ndotl = saturate(dot(N, L));
    return light;
}

float3 BoxProjection(float3 direction, float3 position, float4 cubemapPosition, float3 boxMin, float3 boxMax) {
    UNITY_BRANCH
    if (cubemapPosition.w > 0.0) {
	  	boxMin -= position;
		boxMax -= position;
		float3 factors = ((direction > 0 ? boxMax : boxMin) - position) / direction;
		float scalar = min(min(factors.x, factors.y), factors.z);
		return direction * scalar + (position - cubemapPosition);  
    }
    return direction;
}

UnityIndirect CreateUnityIndirectLight(VertexOut pin, float3 albedo, float3 V) {
	UnityIndirect indirectLight;
    indirectLight.diffuse = 0;
    indirectLight.specular = 0;

#ifdef FORWARD_BASE
	indirectLight.diffuse = max(0, ShadeSH9(float4(pin.normal, 1.0)));

    Unity_GlossyEnvironmentData envData;
	envData.roughness = 1 - _Smoothness;
    float3 R = normalize(reflect(-V, pin.normal));
	envData.reflUVW = BoxProjection(
			R, pin.position,
			unity_SpecCube0_ProbePosition,
			unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax
		);
    indirectLight.specular = Unity_GlossyEnvironment(
		UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData
	);
#endif

#if defined(VERTEXLIGHT_ON)
	indirectLight.diffuse += pin.vertexLightColor;
#endif
    return indirectLight;
}

float4 frag(VertexOut pin) : SV_TARGET {
    float3 V = normalize(UnityWorldSpaceViewDir(pin.position));
    float3 N = normalize(pin.normal);
    
    float3 albedo = tex2D(_MainTex, pin.texcoord).rgb * _DiffuseAlbedo.rgb;

    float3 fresnelR0;
    float oneMinusReflectivity;
    albedo = DiffuseAndSpecularFromMetallic( 
        albedo,
        _Metallic,
        fresnelR0,
        oneMinusReflectivity
    );

    UnityLight light = CreateLight(pin, N);
    UnityIndirect indirectLight = CreateUnityIndirectLight(pin, albedo, V);

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