Shader "Unlit/MyLightingShader"
{
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
        [HideInInspector] _SrcBlend ("SrcBlend", Float) = 1
        [HideInInspector] _DstBlend ("DstBlend", Float) = 0  
        [HideInInspector] _ZWrite ("ZWrite", Float) = 1
    }

	CustomEditor "MyLightingShaderGUI" 

    SubShader
    {
        LOD 100

        // forward base
        Pass
        {
            Tags { "LightMode" = "ForwardBase" }
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define FORWARD_BASE_PASS
            #pragma shader_feature _ _RENDERING_MODE_ALPHA_TEST _RENDERING_MODE_TRANSPARENT
            #include "MyShaderInclude.cginc"
            ENDCG
        }
        
        // forward additive
        Pass 
        {
            Tags { "LightMode" = "ForwardAdd" }    
            Blend [_SrcBlend] One
            ZTest On
            ZWrite Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd
            #pragma shader_feature _ _RENDERING_MODE_ALPHA_TEST _RENDERING_MODE_TRANSPARENT
            #include "MyShaderInclude.cginc"
            ENDCG
        }
    	
        // shadow caster
        Pass 
        {
            Tags { "LightMode" = "ShadowCaster" }
            Blend Off
            ZWrite True 
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _ _ALBEDO_MAP
            #pragma shader_feature _ _SMOOTHNESS_ALBEDO_SOURCE
            #pragma shader_feature _ _RENDERING_MODE_ALPHA_TEST
            #pragma shader_feature _ _TRANSPARENT_SHADOW_CAST
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"
            
            sampler2D _AlbedoTex;
            sampler3D _DitherMaskLOD;
            float4    _AlbedoTex_ST;
            float4    _DiffuseAlbedo;
            float     _AlphaCutoff;

            #define _TRANSPARENT_SHADOW_CAST
            #if (defined(_TRANSPARENT_SHADOW_CAST) || defined(_RENDERING_MODE_ALPHA_TEST)) && defined(_ALBEDO_MAP) && !(_SMOOTHNESS_ALBEDO_SOURCE)
                #define SHADOW_NEED_UV 1
            #endif

            
#if defined(SHADOWS_CUBE)
            struct VertexIn {
		        float3 vertex   : POSITION;
            #if defined(SHADOW_NEED_UV)
            	float2 texcoord : TEXCOORD0;
            #endif
	        };

	        struct VertexOut {
		        float4 position : SV_POSITION;
		        float3 lightVec : TEXCOORD0;
	        #if defined(SHADOW_NEED_UV)
	            float2 texcoord : TEXCOORD1;
	        #endif
	        };

	        VertexOut vert(VertexIn vin) {
		        VertexOut vout;
		        vout.position = UnityObjectToClipPos(vin.vertex);
		        vout.lightVec = _LightPositionRange.xyz - mul(unity_ObjectToWorld, vin.vertex).xyz;
	            #if defined(SHADOW_NEED_UV)
	                vout.texcoord = TRANSFORM_TEX(vin.texcoord, _AlbedoTex);
	            #endif
		        return vout;
	        }

	        float4 frag(VertexOut pin) : SV_Target {
                float alpha = _DiffuseAlbedo.a;
                #if defined(SHADOW_NEED_UV)
                    alpha *= tex2D(_AlbedoTex, pin.texcoord).a;
                #endif
                
                #if defined(_RENDERING_MODE_ALPHA_TEST)
                    clip(alpha - _AlphaCutoff);
                #elif defined(_TRANSPARENT_SHADOW_CAST)
                    float3 vpos = float3(pin.position.xy * 0.25, alpha * 15.0 / 16.0);
                    float dither = tex3D(_DitherMaskLOD, vpos).a;
                    clip(dither - 0.01);
                #endif
	            
		        float depth = length(pin.lightVec) + unity_LightShadowBias.x;
		        depth *= _LightPositionRange.w;
		        return UnityEncodeCubeShadowDepth(depth);
	        }
#else
            struct VertexIn {
                float4 vertex   : POSITION0;
                float3 normal   : NORMAL0;
            #if defined(SHADOW_NEED_UV)
                float2 texcoord : TEXCOORD0;
            #endif
            };

            struct VertexOut {
                float4 pos      : SV_POSITION;
            #if defined(SHADOW_NEED_UV)
                float2 texcoord : TEXCOORD0;
            #endif
            };

            VertexOut vert(VertexIn vin) { 
                VertexOut vout;
                float4 clipPos = UnityClipSpaceShadowCasterPos(vin.vertex, vin.normal);
                vout.pos = UnityApplyLinearShadowBias(clipPos);
                #if defined(SHADOW_NEED_UV)
                    vout.texcoord = TRANSFORM_TEX(vin.texcoord, _AlbedoTex);
                #endif
                return vout;
            }

            float4 frag(VertexOut pin) : SV_Target {
                float alpha = _DiffuseAlbedo.a;
                #if defined(SHADOW_NEED_UV)
                    alpha *= tex2D(_AlbedoTex, pin.texcoord).a;
                #endif
                
                #if defined(_RENDERING_MODE_ALPHA_TEST)
                    clip(alpha - _AlphaCutoff);
                #elif defined(_TRANSPARENT_SHADOW_CAST)
                    float3 vpos = float3(pin.pos.xy * 0.25, alpha * 15.0 / 16.0);
                    float dither = tex3D(_DitherMaskLOD, vpos).a;
                    clip(dither - 0.01);
                #endif
                
                return float4(0.0, 0.0, 0.0, 1.0);
            }
#endif
            ENDCG
        }
        
        // deferred 
        Pass 
        {
            Tags { "LightMode" = "Deferred" }   
            CGPROGRAM
            #pragma target 3.0
            #pragma exclude_renderers nomrt
            #define DEFERRED_PASS
            #pragma vertex vert
            #pragma fragment frag
            #include "MyShaderInclude.cginc"
            ENDCG
        }
    }
}
