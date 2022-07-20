Shader "Unlit/TextureSplatting"
{
    Properties
    {
        _SplatTex ("SplatMap", 2D) = "white" {}
        [NoScaleOffset] _Texture1 ("Texture1", 2D) = "white" {}
        [NoScaleOffset] _Texture2 ("Texture2", 2D) = "white" {}
        [NoScaleOffset] _Texture3 ("Texture3", 2D) = "white" {}
        [NoScaleOffset] _Texture4 ("Texture4", 2D) = "white" {}
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

            sampler2D _SplatTex;
            sampler2D _Texture1;
            sampler2D _Texture2;
            sampler2D _Texture3;
            sampler2D _Texture4;
            float4 _SplatTex_ST;

            struct VertexIn {
                float4 position       : POSITION;
                float2 texcoord       : TEXCOORD0;
                float2 splatTexcoord  : TEXCOORD1;
            };

            struct VertexOut {
                float4 pos            : SV_POSITION;
                float3 position       : TEXCOORD0;
                float2 texcoord       : TEXCOORD1;
                float2 splatTexcoord  : TEXCOORD2;
            };

            VertexOut vert(VertexIn vin) {
                VertexOut vout;
                float4 worldPosition = mul(unity_ObjectToWorld, vin.position);
                vout.pos = mul(UNITY_MATRIX_VP, worldPosition);
                vout.texcoord = TRANSFORM_TEX(vin.texcoord, _SplatTex);
                vout.splatTexcoord = vin.texcoord;
                return vout;
            }

            fixed4 frag(VertexOut pin) : SV_TARGET {
                float4 splat = tex2D(_SplatTex ,pin.splatTexcoord);
                return tex2D(_Texture1, pin.texcoord) * splat.r +
                       tex2D(_Texture2, pin.texcoord) * splat.g +
                       tex2D(_Texture3, pin.texcoord) * splat.b +
                       tex2D(_Texture4, pin.texcoord) * (1.0 - splat.r -  splat.g - splat.b);
            }
 
            ENDCG
        }
    }
}
