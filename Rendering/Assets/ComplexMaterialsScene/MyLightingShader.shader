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

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define FORWARD_BASE
            #include "MyShaderInclude.cginc"
            ENDCG
        }
        
        Pass 
        {
            Tags { "LightMode" = "ForwardAdd" }    
            Blend [_SrcBlend] One
            ZWrite Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd
            #include "MyShaderInclude.cginc"
            ENDCG
        }
        
        pass 
        {
            Tags { "LightMode" = "ShadowCaster" }    
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #pragma shader_feature _ _ALBEDO_MAP
			#pragma shader_feature _ _RENDERING_MODE_ALPHA_TEST _RENDERING_MODE_TRANSPARENT

            #pragma shader_feature _ _SMOOTHNESS_ALBEDO_SOURCE
			#include "UnityCG.cginc" 

            #if defined(_RENDERING_MODE_ALPHA_TEST) && defined(_ALBEDO_MAP) && !defined(_SMOOTHNESS_ALBEDO_SOURCE)
				#define SHADOW_NEED_UV 1
            #endif

            sampler2D _AlbedoTex;
            float  _AlphaCutoff;
            float4 _AlbedoTex_ST;
            float4 _DiffuseAlbedo;

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
            	#endif
            	
	            float depth = length(pin.lightVec) + unity_LightShadowBias.x;			// 这里计算 Bias
	            depth *= _LightPositionRange.w;
	            return UnityEncodeCubeShadowDepth(depth);								// 点光源的 ShadowMap 是立方体贴图, 所以这里会将 depth 解码到4个通道里面
            }
#else
            struct VertexIn {
				float3 vertex   : POSITION;
				float3 normal   : NORMAL;
            #if defined(SHADOW_NEED_UV)
				float2 texcoord : TEXCOORD;
            #endif
			};

            struct VertexOut {
	            float4 pos : SV_POSITION;
            #if defined(SHADOW_NEED_UV) 
            	float2 texcoord : TEXCOORD;
            #endif
            };

			VertexOut vert(VertexIn vin) : SV_POSITION {
				VertexOut vout;
				vout.pos = UnityApplyLinearShadowBias(UnityClipSpaceShadowCasterPos(vin.vertex, vin.normal));
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
            	#endif

				return float4(0.0, 0.0, 0.0, 1.0);
			}
#endif
            
            ENDCG
        }
        
    }
}
