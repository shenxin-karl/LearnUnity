// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

#ifndef MY_SHADOW_CASTER
#define MY_SHADOW_CASTER
#include "UnityCG.cginc"

struct VertexIn {
	float3 vertex : POSITION;
	float3 normal : NORMAL;
};

float4 vert(VertexIn vin) : SV_POSITION {
	float4 clipPos = UnityClipSpaceShadowCasterPos(vin.vertex, vin.normal);
	return UnityApplyLinearShadowBias(clipPos);
}

float4 frag() : SV_Target {
	return float4(0.0, 0.0, 0.0, 1.0);
}


#endif