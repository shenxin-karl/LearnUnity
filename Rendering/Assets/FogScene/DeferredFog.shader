Shader "Unlit/DeferredFog"
{
    Properties
    {
        _MainTex ("Source", 2D) = "white" {}
    }
    SubShader
    {
        Cull Off
        ZTest Always
        ZWrite Off
        Pass 
        {
            CGPROGRAM
            // switch:
            #define FOG_DISTANCE
            #define FOG_SKYBOX 
            
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #include "UnityCG.cginc"

            struct VertexIn {
                float4 vertex   : POSITION0;
                float2 texcoord : TEXCOORD0;
            };

            struct VertexOut {
                float4 pos      : SV_POSITION;
                float2 texcoord : TEXCOORD0;
            #if defined(FOG_DISTANCE)
                float3 ray      : TEXCOORD1;
            #endif
            };

            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;
            float4 _FrustumCorners[4];
            
            VertexOut vert(VertexIn vin) {
                VertexOut vout;
                vout.pos = UnityObjectToClipPos(vin.vertex);
                vout.texcoord = vin.texcoord;
                #if defined(FOG_DISTANCE)
                    vout.ray = _FrustumCorners[vin.texcoord.x + (2 * vin.texcoord.y)];
                #endif
                return vout;
            }
            
            float4 frag(VertexOut pin) : SV_Target {
                float3 sourceColor = tex2D(_MainTex, pin.texcoord).rgb;
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, pin.texcoord);
                depth = Linear01Depth(depth);
                float viewDistance = depth * _ProjectionParams.z - _ProjectionParams.y;
                #if defined(FOG_DISTANCE)
                    viewDistance = length(depth * pin.ray);
                #endif
                UNITY_CALC_FOG_FACTOR_RAW(viewDistance);

                #if !defined(FOG_SKYBOX)
                    if (depth > 0.999)
                        unityFogFactor = 1.0;
                #endif

                #if !defined(FOG_LINEAR) && !defined(FOG_EXP) && !defined(FOG_EXP2)
                    unityFogFactor = 1.0;
                #endif
                
                float3 floggedColor = lerp(unity_FogColor.rgb, sourceColor, saturate(unityFogFactor));
                return float4(floggedColor, 1.0);
            }
            ENDCG
        }
    }
}
