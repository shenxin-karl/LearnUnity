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
            #define FORWARD_BASE
            #include "MyShaderInclude.cginc"
            ENDCG
        }
        
        // forward additive
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

                        #define _NORMAL_MAP
            struct VertexIn {
                float4 vertex : POSITION;
                float3 normal   : NORMAL;
                float2 texcoord : TEXCOORD;
            #if defined(_NORMAL_MAP) || defined(_DETAIL_NORMAL_MAP)
                float4 tangent  : TANGENT;
            #endif
            };

            #define _DETAIL_ALBEDO_MAP
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
            };

            VertexOut vert(VertexIn vin) {
                VertexOut vout;
                float4 worldPosition = mul(unity_ObjectToWorld, vin.vertex);
                vout.pos = mul(UNITY_MATRIX_VP, worldPosition);
                vout.worldPosition = worldPosition;
                vout.worldNormal = UnityObjectToWorldNormal(vin.normal);
                vout.texcoord = TRANSFORM_TEX(vin.texcoord, _AlbedoTex);
                #if defined(_DETAIL_ALBEDO_MAP) || defined(_DETAIL_NORMAL_MAP)
                    vout.texcoord1 = TRANSFORM_TEX(vin.texcoord, _DetailAlbedoTex);
                #endif
                #if defined(_NORMAL_MAP) || defined(_DETAIL_NORMAL_MAP)
                    vout.worldTangent = float4(UnityObjectToWorldDir(vin.tangent.xyz), vin.tangent.w);
                #endif
                return vout;
            }

            float getDetailMask(VertexOut pin) {
                #if defined(_DETAIL_MASK_MAP)
                    return tex2D(_DetailMaskTex, pin.texcoord).a;
                #endif
                return 1.0;
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

            float getOcclusion(VertexOut pin) {
                #if defined(_OCCLUSTION_SOURCE) && defined(_OCCLUSION_MAP)
                    return lerp(1.0, tex2D(_OcclusionTex, pin.texcoord.xy).r, _OcclusionStrength);
                #elif defined(_OCCLUSTION_METALLIC_SOURCE) && defined(_METALLIC_MAP)
                    return lerp(1.0, tex2D(_MetallicTex, pin.texcoord).g, _OcclusionStrength);
                #endif
                return 1.0;
            }
            
            struct PixelOut {
                float4 gBuffer0 : SV_Target0;
                float4 gBuffer1 : SV_Target1;
                float4 gBuffer2 : SV_Target2;
                float4 gBuffer3 : SV_Target3;
            };

            PixelOut frag(VertexOut pin) {
                PixelOut pout;
                float3 albedo = getAlbedo(pin);
                pout.gBuffer0.rgb = getAlbedo(pin);
                pout.gBuffer0.a = getOcclusion(pin);
                pout.gBuffer1.rgb = albedo;
            }
            
            ENDCG
        }
    }
}
