// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Custom/SnowBlanketLit"
{
    Properties 
	{
		//_EdgeLength ("Edge length", Range(2,50)) = 5
		_Tess ("Tess amount", Range(2,50)) = 5
		_MainColor ("Main Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_Bump ("Bump", 2D) = "bump" {}
		_SnowLevel ("Level of Snow", Range(-1.0, 1.0)) = 0.25
		_SnowColor ("Color of Snow", Color) = (1.0, 1.0, 1.0, 1.0)
		_SnowDirection ("Direction of Snow", Vector) = (0, 1, 0, 0)
		_SnowDepth ("Depth of Snow", Range(0, 2)) = 0
		_SnowPuffiness ("Snow Puffiness", Range(-1, 1)) = 0.5
	}
	SubShader 
	{
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		#pragma surface surf BlinnPhong  tessellate:tessDistance vertex:vert nolightmap
		//#pragma surface surf BlinnPhong addshadow fullforwardshadows tessellate:tessEdge nolightmap
		#pragma target 4.6
		#include "Tessellation.cginc"

		sampler2D _MainTex;
		sampler2D _Bump;
		float _SnowLevel;
		float4 _SnowColor;
		float4 _MainColor;
		float4 _SnowDirection;
		float _SnowDepth;
		float _SnowPuffiness;

		struct Input 
		{
			float2 uv_MainTex;
			float2 uv_Bump;
			float3 worldNormal;
			INTERNAL_DATA
		};
		struct appdata {
            float4 vertex : POSITION;
            float4 tangent : TANGENT;
            float3 normal : NORMAL;
            float2 texcoord : TEXCOORD0;
        };
		float4 CalculatePos(appdata_full v)
		{
			float3 vertOffset = v.vertex.xyz;
			float3 vn = v.normal;
			// Convert the snow direction to object coordinates
			float3 sn = normalize(mul(unity_WorldToObject, float4(_SnowDirection.xyz, 0))).xyz;

			// snowAlignment is the amount that the vertex's normal aligns with the snow direction (-1 means opposite vector, +1 means identical vector)
			float snowAlignment = dot(vn, sn);
			

			if (snowAlignment >= -_SnowLevel)
			{
				float snowFactor = smoothstep(0, _SnowLevel, snowAlignment);

				snowFactor *= _SnowDepth;

				float3 vertOffset = vn * (_SnowPuffiness * snowFactor);
			}
			return float4( v.vertex.xyz + vertOffset, 1);
		}
		
		float _Tess;
		float4 tessDistance (appdata_full v0, appdata_full v1, appdata_full v2) {
                float minDist = 5.0;
                float maxDist = 50.0;
				float3 sn = normalize(mul(unity_WorldToObject, float4(_SnowDirection.xyz, 0))).xyz;
				float snowAlignment = dot(v0.normal, sn);
				if(snowAlignment <= 0) _Tess = 1;
                return UnityDistanceBasedTess(v0.vertex, v1.vertex, v2.vertex, minDist, maxDist, _Tess);
            }
		
		void vert (inout appdata_full v)
		{
			float3 vn = v.normal;
			// Convert the snow direction to object coordinates
			float3 sn = normalize(mul(unity_WorldToObject, float4(_SnowDirection.xyz, 0))).xyz;

			// snowAlignment is the amount that the vertex's normal aligns with the snow direction (-1 means opposite vector, +1 means identical vector)
			float snowAlignment = dot(vn, sn);
			

			if (snowAlignment >= -_SnowLevel && snowAlignment > 0.25)
			{
				float snowFactor = smoothstep(_SnowLevel, _SnowLevel + 0.1, snowAlignment);
				snowFactor *= _SnowDepth;

				float3 vertOffset = vn * (_SnowPuffiness * snowFactor);
				// vertex displacement calculation
				//float3 newPos = vertOffset * snowFactor;
				v.vertex.xyz += vertOffset;
			}
		}

		void surf (Input IN, inout SurfaceOutput o) 
		{
			half4 c = tex2D(_MainTex, IN.uv_MainTex);
			o.Normal = UnpackNormal(tex2D(_Bump, IN.uv_Bump));

			float3 snowDir = normalize(_SnowDirection.xyz);
			float snowAlignment = dot(WorldNormalVector(IN, o.Normal), snowDir);

			if (snowAlignment >= -_SnowLevel && snowAlignment > 0.25)
			{
				o.Albedo = _SnowColor.rgb;
			}
			else
			{
				o.Albedo = c.rgb * _MainColor;
			}

			o.Alpha = 1;
			
		}











		
		/*
		 float _EdgeLength;
		float3 CalculateNewPos(appdata v)
		{
			float3 pos = v.vertex.xyz;
			float3 snowDir = normalize(_SnowDirection.xyz);
            float snowAlignment = dot(v.normal, snowDir);

            if (snowAlignment >= _SnowLevel) {
                float snowFactor = pow(snowAlignment, 3) * _SnowDepth;
                float3 displacement = v.normal * lerp(0, snowFactor, (_SnowPuffiness + 1) / 2);
                pos += displacement;
            }
			return pos;
		}


		float4 tessEdge (appdata v0, appdata v1, appdata v2)
		{
            return UnityEdgeLengthBasedTess (v0.vertex, v1.vertex, v2.vertex, _EdgeLength);
		}
		void vert (inout appdata v)
		{
			
			
			// Convert the snow direction to object coordinates
			float3 sn = normalize(mul(unity_WorldToObject, float4(_SnowDirection.xyz, 0))).xyz;
			v.normal = dot(v.normal, sn);
			float3 vn = v.normal;

			// snowAlignment is the amount that the vertex's normal aligns with the snow direction (-1 means opposite vector, +1 means identical vector)
			float snowAlignment = dot(vn, sn);
			

			if (snowAlignment >= _SnowLevel)
			{
				// _SnowPuffiness determines how much the vertex is offset by its normal vs the snow fall direction
				//float3 vertOffset = sn + lerp(-vn, vn, (_SnowPuffiness+1)/2);
				
				//vertOffset = normalize(vertOffset);

				// snowFactor determines how much snow this vertex should receive
				//float snowFactor = lerp(0, _SnowDepth, snowAlignment * snowAlignment * snowAlignment);
				//snowFactor = min(snowFactor, 0.1);

				float snowFactor = smoothstep(_SnowLevel, _SnowLevel + 0.1, snowAlignment);
				snowFactor *= _SnowDepth;

				float3 vertOffset = vn * (_SnowPuffiness * snowFactor);
				// vertex displacement calculation
				//float3 newPos = vertOffset * snowFactor;
				v.vertex.xyz += vertOffset;
			}
		}
		
		//Här i ska alla tesselation beräkningar göras, inte i hullprogram osv
        float4 tessEdge (appdata v0, appdata v1, appdata v2)
            {
                return UnityEdgeLengthBasedTess (v0.vertex, v1.vertex, v2.vertex, _EdgeLength);
            }
		sampler2D _DispTex;
		float _Displacement;

		
		void vert (inout appdata v)
		{
			float3 vn = v.normal;
			// Convert the snow direction to object coordinates
			float3 sn = normalize(mul(unity_WorldToObject, float4(_SnowDirection.xyz, 0))).xyz;

			// snowAlignment is the amount that the vertex's normal aligns with the snow direction (-1 means opposite vector, +1 means identical vector)
			float snowAlignment = dot(vn, sn);
			

			if (snowAlignment >= _SnowLevel)
			{
				// _SnowPuffiness determines how much the vertex is offset by its normal vs the snow fall direction
				//float3 vertOffset = sn + lerp(-vn, vn, (_SnowPuffiness+1)/2);
				
				//vertOffset = normalize(vertOffset);

				// snowFactor determines how much snow this vertex should receive
				//float snowFactor = lerp(0, _SnowDepth, snowAlignment * snowAlignment * snowAlignment);
				//snowFactor = min(snowFactor, 0.1);

				float snowFactor = smoothstep(_SnowLevel, _SnowLevel + 0.1, snowAlignment);
				snowFactor *= _SnowDepth;

				float3 vertOffset = vn * (_SnowPuffiness * snowFactor);
				// vertex displacement calculation
				//float3 newPos = vertOffset * snowFactor;
				v.vertex.xyz += vertOffset;
			}
		}

		void surf (Input IN, inout SurfaceOutput o) 
		{
			half4 c = tex2D(_MainTex, IN.uv_MainTex);
			o.Normal = UnpackNormal(tex2D(_Bump, IN.uv_Bump));

			float3 snowDir = normalize(_SnowDirection.xyz);
			float snowAlignment = dot(WorldNormalVector(IN, o.Normal), snowDir);

			if (snowAlignment >= _SnowLevel)
			{
				o.Albedo = _SnowColor.rgb;
			}
			else
			{
				o.Albedo = c.rgb * _MainColor;
			}

			o.Alpha = 1;
			
		}*/
		ENDCG
    }
    FallBack "Diffuse"
}
