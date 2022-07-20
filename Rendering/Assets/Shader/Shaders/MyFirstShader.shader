// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/MyFirstShader"
{
    Properties {
        _Color("Color", Color) = (1, 1, 1, 1)
        _MainTex("MainTex", 2D) = "white" {}
    }

    SubShader {
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            float4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;

            struct VertexIn {
                float4 position : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct VertexOut {
                float4 pos      : SV_POSITION;
                float3 position : POSITION1;
                float2 texcoord : TEXCOORD0;
            };

            VertexOut vert(VertexIn vin) {
                VertexOut vout;
                float4 worldPosition = mul(unity_ObjectToWorld, vin.position);
                vout.pos = mul(UNITY_MATRIX_VP, worldPosition);
                vout.position = worldPosition.xyz;
                vout.texcoord = TRANSFORM_TEX(vin.texcoord, _MainTex);
                return vout;
            }

            float4 frag(VertexOut pin) : SV_TARGET {
                float4 albedo = tex2D(_MainTex, pin.texcoord);
                return _Color * albedo;
            }

            ENDCG
        }
    }
}
