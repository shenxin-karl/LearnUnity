// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

#ifndef MY_SHADOW_CASTER
#define MY_SHADOW_CASTER
#include "UnityCG.cginc"

struct VertexIn {
	float4 position : POSITION;
};

float4 vert(VertexIn vin) : SV_POSITION {
	return UnityObjectToClipPos(vin.position);
}

float4 frag() : SV_Target {
	return float4(0.0, 0.0, 0.0, 1.0);
}


#endif