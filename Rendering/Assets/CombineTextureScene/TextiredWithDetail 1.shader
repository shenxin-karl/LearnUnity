Shader "Unlit/TextiredWithDetail"
{
    Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1)
        _MainTex ("MainTexture", 2D) = "white" {}
        _DetailTex ("_DetailTexture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _DetailTex;
            float4 _DetailTex_ST;

            struct VertexIn {
                float4 position       : POSITION;
                float2 texcoord       : TEXCOORD0;
                float2 detailTexcoord : TEXCOORD1;
            };

            struct VertexOut {
                float4 pos            : SV_POSITION;
                float3 position       : TEXCOORD0;
                float2 texcoord       : TEXCOORD1;
                float2 detailTexcoord : TEXCOORD2;
            };

            VertexOut vert(VertexIn vin) {
                VertexOut vout;
                float4 worldPosition = mul(unity_ObjectToWorld, vin.position);
                vout.pos = mul(UNITY_MATRIX_VP, worldPosition);
                vout.texcoord = TRANSFORM_TEX(vin.texcoord, _MainTex);
                vout.detailTexcoord = TRANSFORM_TEX(vin.detailTexcoord, _DetailTex);
                return vout;
            }

            fixed4 frag(VertexOut pin) : SV_TARGET {
                float4 texColor = tex2D(_MainTex, pin.texcoord);
                float4 detailColor = tex2D(_DetailTex, pin.detailTexcoord) * unity_ColorSpaceDouble;
                return _Color * texColor * detailColor;
            }
 
            ENDCG
        }
    }
}
