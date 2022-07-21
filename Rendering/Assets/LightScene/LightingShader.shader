Shader "Unlit/LightingShader"
{
    Properties
    {
        _MainTex ("AlbedoTexture", 2D) = "white" {}
        _Roughness ("Roughness", Range(0, 1)) = 0.5
        _Metallic ("Metallic", Range(0, 1)) = 0.5
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
            fixed _Roughness;
            fixed _Metallic;
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

            struct MaterialData {
                float4 diffuseAlbedo;
                float  roughness;
                float  metallic;
            };

            float3 SchlickFresnel(float3 F0, float cosIncidenceAngle) {
                float cosTh = 1.0 - cosIncidenceAngle;
                return F0 + (1.f - F0) * (cosTh * cosTh * cosTh * cosTh * cosTh);
            }

            float3 BlinnPhong(float3 lightStrength, float3 L, float N, float3 V, MaterialData mat) {
                float m = max((1.0 - mat.roughness) * 256.f, 1.f);
                fixed3 H = normalize(V + L);

                float3 F0 = lerp(float3(0.04, 0.04, 0.04), mat.diffuseAlbedo.rgb, mat.metallic);

                float NdotH = max(dot(N, H), 0.0);
                float roughnessFactor = (m + 2.0) / 8.0 * pow(NdotH, m);
                float3 freshnelFactor = SchlickFresnel(F0, saturate(dot(H, L)));
                float3 specAlbedo = roughnessFactor * freshnelFactor;

                float3 diffAlbedo = mat.diffuseAlbedo.rgb * (1.f - mat.metallic);
                specAlbedo = specAlbedo / (specAlbedo + 1.f);
                return (diffAlbedo + specAlbedo) * lightStrength;
                
            }

            float4 frag(VertexOut pin) : SV_TARGET {
                float3 textureAlbedo = tex2D(_MainTex, pin.texcoord);
                MaterialData mat = {
                    float4(textureAlbedo, 1.0),
                    _Roughness,
                    _Metallic,
                };

                float3 N = normalize(pin.normal);
                float3 L = normalize(UnityWorldSpaceLightDir(pin.position));
                float3 V = normalize(UnityWorldSpaceViewDir(pin.position));
                float3 lightStrength = _LightColor0.rgb * saturate(dot(N, L));

                float m = max((1.0 - mat.roughness) * 256.f, 1.f);
                fixed3 H = normalize(V + L);

                float3 F0 = lerp(float3(0.04, 0.04, 0.04), mat.diffuseAlbedo.rgb, mat.metallic);

                float NdotH = max(dot(N, H), 0.0);
                float roughnessFactor = (m + 2.0) / 8.0 * pow(NdotH, m);
                float3 freshnelFactor = SchlickFresnel(F0, saturate(dot(H, L)));
                float3 specAlbedo = roughnessFactor * freshnelFactor;

                float3 diffAlbedo = mat.diffuseAlbedo.rgb * (1.f - mat.metallic);
                specAlbedo = specAlbedo / (specAlbedo + 1.f);
                float3 result = (diffAlbedo + specAlbedo) * lightStrength;
                return float4(result, 1.0);
            }

            ENDCG
        }
    }
}
