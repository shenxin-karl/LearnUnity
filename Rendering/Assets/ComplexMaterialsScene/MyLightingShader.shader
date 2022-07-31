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
    }

	CustomEditor "MyLightingShaderGUI" 

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
            #define FORWARD_BASE
            #include "MyShaderInclude.cginc"
            ENDCG
        }
        
        Pass 
        {
            Tags { "LightMode" = "ForwardAdd" }    
            Blend One One
            ZWrite Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd
            #include "MyShaderInclude.cginc"
            ENDCG
        }
        
    }
    Fallback "Specular"
}
