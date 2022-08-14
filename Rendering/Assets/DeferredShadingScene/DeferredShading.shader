Shader "Unlit/DeferredShading"
{
    Properties
    {
    }
    
    SubShader 
    {
        Pass
        {
        	Name "DeferredShading Pass1"
            Cull Off
//            ZTest Always
//            ZWrite Off
        	Blend [_SrcBlend] [_DstBlend]
        	
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma exclude_renderers nomrt
			#pragma multi_compile_lightpass			
			#pragma multi_compile _ _ UNITY_HDR_ON
							
			#include "MyDeferredShading.cginc"
            ENDCG
        }    
        
		Pass {
			Cull Off
			ZTest Always
			ZWrite Off

			Stencil {
				Ref [_StencilNonBackground]
				ReadMask [_StencilNonBackground]
				CompBack Equal
				CompFront Equal
			}

			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#pragma exclude_renderers nomrt
			#include "UnityCG.cginc"

			struct VertexIn { 
				float4 vertex   : POSITION;
				float2 texcoord : TEXCOORD0;
			};
			struct VertexOut {
				float4 pos      : SV_POSITION;
				float2 texcoord : TEXCOORD0;
			};

			VertexOut vert (VertexIn vin) {
				VertexOut vout;
				vout.pos = UnityObjectToClipPos(vin.vertex);
				vout.texcoord = vin.texcoord;
				return vout;
			}
			
			sampler2D _LightBuffer;
			float4 frag (VertexOut pin) : SV_Target {
				return -log2(tex2D(_LightBuffer, pin.texcoord));
			}
			ENDCG
		}
    }
}
