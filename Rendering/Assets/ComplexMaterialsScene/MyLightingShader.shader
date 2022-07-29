Shader "Unlit/MyLightingShader"
{
    Properties
    {
        _AlbedoTex ("AlbedoTexture", 2D) = "white" {}
        _DiffuseAlbedo ("DiffuseAlbedo", Color) = (1, 1, 1, 1)
        [NoScaleOffset] _NormalTex ("NormalTexture", 2D) = "bump" {}
        [NoScaleOffset] _MetallicTex ("MetallicTexture", 2D) = "white" {}
        [NoScaleOffset] _SmoothnessTex ("SmoothnessTexture", 2D) = "white" {}
        _BumpScale ("BumpScale", float) = 1.0
        [gamma] _Metallic ("Metallic", Range(0, 1)) = 0.5
        _Smoothness ("Smoothness", Range(0, 1)) = 0.5
        _DetailAlbedoTex ("DetailAlbedoTex", 2D) = "white" {}
        [NoScaleOffset] _DetailNormalTex ("DetailNormalTex", 2D) = "bump" {}
        _DetailNormalScale ("DetailNormalScale", float) = 1.0 
    }

	CustomEditor "MyLightingShaderGUI"

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma shader_feature _ _MATERIAL_MAP
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _AlbedoTex;
            float4 _AlbedoTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _AlbedoTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_AlbedoTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
