Shader "Unlit/LightingShader"
{
    Properties
    {
        _MainTex ("AlbedoTexture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "UnityStandardBRDF.cginc"

            struct VertexIn {
                float4 position       : POSITION;
                float3 normal         : NORMAL;
                float2 texcoord       : TEXCOORD;
            };

            struct VertexOut {
                float4 pos            : SV_POSITION;
                float3 position       : TEXCOORD0;
                float3 normal         : TEXCOORD1;
                float2 texcoord       : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            VertexOut vert(VertexIn vin) {
                VertexOut vout;
                float4 worldPosition = mul(unity_ObjectToWorld, vin.position);
                vout.pos = mul(UNITY_MATRIX_VP, worldPosition);
                vout.position = worldPosition.xyz;
                vout.normal = UnityObjectToWorldNormal(vin.normal);
                vout.texcoord = TRANSFORM_TEX(vin.texcoord, _MainTex);
                return vout;
            }

            float4 frag(VertexOut pin) : SV_TARGET {
                float3 albedo = tex2D(_MainTex, pin.texcoord);
                fixed3 L = normalize(UnityWorldSpaceLightDir(pin.position));
                fixed3 N = normalize(pin.normal);
                float3 finalColor = albedo * _LightColor0.rgb * saturate(dot(N, L));
                return float4(finalColor, 1.0);
            }

            ENDCG
        }
    }
}
