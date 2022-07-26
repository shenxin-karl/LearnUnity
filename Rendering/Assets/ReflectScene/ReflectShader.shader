Shader "Unlit/ReflectShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Metallic ("Metallic", Range(0, 1)) = 0.5
        _Smoothness ("Smoothness", Range(0, 1)) = 0.5
        _DiffuseAlbedo ("DiffuseAlbedo", Color) = (1, 1, 1, 1)
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
            #define FORWARD_BASE
            #pragma multi_compile _ VERTEXLIGHT_ON
            #pragma multi_compile _ SHADOWS_SCREEN
            #include "UnityCG.cginc"
            #include "../MultiLightScene/MY_LIGHTING_INCLUDE.cginc"
 
            ENDCG
        }
        pass 
        {
            Tags { "LightMode" = "ForwardAdd" }
            Blend One One
            ZWrite Off 

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd_fullshadows
            #include "../MultiLightScene/MY_LIGHTING_INCLUDE.cginc" 
            ENDCG
        }
        pass 
        {
            Tags { "LightMode" = "ShadowCaster" }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #include "../ShadowScene/MyShadowCaster.cginc" 
            ENDCG
        }
    }
    FallBack "Specular"
}
