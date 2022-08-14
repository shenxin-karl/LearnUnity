#include "UnityCG.cginc"
#include "UnityPBSLighting.cginc"

struct VertexIn {
    float4 vertex : POSITION0;
    float3 normal : NORMAL;
};

struct VertexOut {
    float4 pos       : SV_POSITION;
    float4 screenPos : TEXCOORD0;
    float3 ray       : TEXCOORD1;
};

UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
sampler2D _CameraGBufferTexture0;
sampler2D _CameraGBufferTexture1;
sampler2D _CameraGBufferTexture2;
sampler2D _LightTexture0;
sampler2D _LightTextureB0;

#if defined(DIRECTIONAL) || defined(DIRECTIONAL_COOKIE)
    sampler2D _ShadowMapTexture;
#endif

float4 _LightColor;
float4 _LightPos;
float4 _LightDir;
float4x4 unity_WorldToLight;
float _LightAsQuad;

VertexOut vert(VertexIn vin) {
    VertexOut vout;
    vout.pos = UnityObjectToClipPos(vin.vertex);
    vout.screenPos = ComputeScreenPos(vout.pos);
    float3 viewPos = UnityObjectToViewPos(vin.vertex) * float3(-1, -1, 1);
    vout.ray = lerp(viewPos, vin.normal, _LightAsQuad);
    return vout;
}

void getWorldPosAndViewZ(VertexOut pin, float2 texcoord, inout float3 worldPos, inout float viewZ) {
    float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, texcoord);
    depth = Linear01Depth(depth);
    float3 oneDepthRay = pin.ray / pin.ray.z;
    float3 viewPos = oneDepthRay * _ProjectionParams.z * depth;
    worldPos = mul(unity_CameraToWorld, float4(viewPos, 1.0));
    viewZ = viewPos.z;
}

UnityLight CreateLight(float2 texcoord, float3 worldPos, float viewZ) {
    float shadowAttenuation = 1.0;
    float lightAttenuation = 1.0;
    bool shadowed = false;
    UnityLight light;    
    
    #if defined(DIRECTIONAL) || defined(DIRECTIONAL_COOKIE)
        light.dir = -_LightDir.xyz;
        #if defined(DIRECTIONAL_COOKIE)		// 如果是 COOKIE
            float2 lightCookieTexcoord = mul(unity_WorldToLight, float4(worldPos, 1.0)).xy;
            lightAttenuation *= tex2Dbias(_LightTexture0, float4(lightCookieTexcoord, 0, -8)).w;
            // lightAttenuation *= tex2D(_LightTexture0, lightCookieTexcoord).w;
        #endif
        #if defined(SHADOWS_SCREEN)			// 如果开启了阴影就使用阴影衰减
            shadowed = true;
            shadowAttenuation = tex2D(_ShadowMapTexture, texcoord).r;
        #endif	
    // 如果是 点光源或者聚光灯
    #else	
        float3 lightVec = _LightPos.xyz - worldPos;
        light.dir = normalize(lightVec);
        // 计算距离衰减
        lightAttenuation *= tex2D(_LightTextureB0, (dot(lightVec, lightVec) * _LightPos.w).rr).UNITY_ATTEN_CHANNEL;

        #if defined(SPOT)
            // 计算圆锥衰减, 计算 Cookies 衰减
            float4 lightCookieTexcoord = mul(unity_WorldToLight, float4(worldPos, 1.0));
            lightCookieTexcoord.xy /= lightCookieTexcoord.w;
            lightAttenuation *= tex2D(_LightTexture0, lightCookieTexcoord.xy).w;
            lightAttenuation *= lightCookieTexcoord.w < 0;
            #if defined(SHADOWS_DEPTH)
                shadowed = true;
                shadowAttenuation = UnitySampleShadowmap(mul(unity_WorldToShadow[0], float4(worldPos, 1.0)));
            #endif
        #else 
            #if defined(SHADOWS_CUBE)
                shadowed = true;
                shadowAttenuation = UnitySampleShadowmap(-lightVec);
            #endif
        #endif
    #endif
    
    if (shadowed) {
        float shadowFadeDistance = UnityComputeShadowFadeDistance(worldPos, viewZ);
        float shadowFade = UnityComputeShadowFade(shadowFadeDistance);
        shadowAttenuation = saturate(shadowAttenuation + shadowFade);
    }

    light.color = _LightColor.rgb * (shadowAttenuation * lightAttenuation);
    return light;
}

float4 frag(VertexOut pin) : SV_Target {
    float2 texcoord = pin.screenPos.xy / pin.screenPos.w;

    float3 worldPos;
    float viewZ;
    getWorldPosAndViewZ(pin, texcoord, worldPos, viewZ);

    float3 albedo = tex2D(_CameraGBufferTexture0, texcoord).rgb;
    float3 fresnelR0 = tex2D(_CameraGBufferTexture1, texcoord).rgb;
    float smoothness = tex2D(_CameraGBufferTexture1, texcoord).a;
    float3 N = tex2D(_CameraGBufferTexture2, texcoord).rgb * 2.0 - 1.0;
    float oneMinusReflectivity = 1 - SpecularStrength(fresnelR0);
    
    float3 V = normalize(UnityWorldSpaceViewDir(worldPos));

    UnityLight light = CreateLight(texcoord, worldPos, viewZ);
    UnityIndirect indirectLight;
    indirectLight.diffuse = 0;
    indirectLight.specular = 0;

    float4 color = UNITY_BRDF_PBS(
        albedo,
        fresnelR0,
        oneMinusReflectivity,
        smoothness,
        N,
        V,
        light,
        indirectLight
    );

    #if !defined(UNITY_HDR_ON)
        color = exp2(-color);
    #endif
    return color;
}