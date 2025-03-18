Shader "Custom/SnowCover"
{
    Properties
    {
        _MainColor ("Main Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_Bump ("Bump", 2D) = "bump" {}
		_SnowLevel ("Level of Snow", Range(-1.0, 1.0)) = 0.25
		_SnowColor ("Color of Snow", Color) = (1.0, 1.0, 1.0, 1.0)
		_SnowDirection ("Direction of Snow", Vector) = (0, 1, 0, 0)
		_SnowDepth ("Depth of Snow", Range(0, 2)) = 0
		_SnowPuffiness ("Snow Puffiness", Range(-1, 1)) = 0.5
    	_TessellationEdgeLength ("Tessellation Edge Length", Range(5, 100)) = 50
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        Pass
        {
            CGPROGRAM
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma vertex TessellationVertexProgram
            #pragma hull HullProgram
            #pragma domain DomainProgram
            #pragma fragment FragmentProgram
            //#pragma surface surf Standard fullforwardshadows
            #pragma target 4.0

            sampler2D _MainTex;
			sampler2D _Bump;
			float _SnowLevel;
			float4 _SnowColor;
			float4 _MainColor;
			float4 _SnowDirection;
			float _SnowDepth;
			float _SnowPuffiness;
            float _TessellationUniform;
            float _TessellationEdgeLength;
            
            struct MeshData
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            	float2 uv1 : TEXCOORD1;
				float2 uv2 : TEXCOORD2;
            	float4 tangent : TANGENT;
            	float4 color : COLOR;
            	float2 uv_MainTex : TEXCOORD3;
				float2 uv_Bump: TEXCOORD4;
				float3 worldNormal: TEXCOORD5;
            };
            struct Input 
		{
			float2 uv_MainTex;
			float2 uv_Bump;
			float3 worldNormal;
		};
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 normal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            	float3 vlight : COLOR;
            	float3 lightDir : TEXCOORD3;
            	float3 viewDir : TEXCOORD4;
            	float4 tangent : TEXCOORD5;
            	float4 bitangen : TEXCOORD6;
            	//float4 color : COLOR;
            	
            };
            struct TessellationControlPoint {
				float4 vertex : INTERNALTESSPOS;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float2 uv : TEXCOORD0;
				float2 uv1 : TEXCOORD1;
				float2 uv2 : TEXCOORD2;
			};

            struct TesselationFactors
            {
                float edge[3] : SV_TessFactor;
                float inside : SV_InsideTessFactor;
            };

            float CalcDistanceTessFactor(float4 vertex, float minDist, float maxDist, float tess)
            {
	            float3 worldPos = mul(unity_ObjectToWorld, vertex).xyz;
            	float dist = distance(worldPos, _WorldSpaceCameraPos);
            	float f = clamp(1.0 - (dist - minDist) / (maxDist-minDist),0.01, 1.0);
            	return f * tess;
            }
            
            //vertex shader
            v2f VertexProgram (MeshData v)
            {
                v2f o;

				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
            	
            	float3 vn = v.normal;
            	float3 sn = normalize(mul(unity_WorldToObject, float4(_SnowDirection.xyz, 0))).xyz;
				
                o.viewDir = normalize(_WorldSpaceCameraPos - worldPos);

                

                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.vlight = v.color;
				
                //o.normal = GetNormal(v.vertex,v.normal, v.tangent);
                o.uv = v.uv;

				o.pos = UnityObjectToClipPos(v.vertex);

            	float snowAlignment = dot(vn, sn);

			if (snowAlignment >= _SnowLevel)
			{
				// _SnowPuffiness determines how much the vertex is offset by its normal vs the snow fall direction
				float3 vertOffset = sn + lerp(-vn, vn, (_SnowPuffiness+1)/2);
				vertOffset = normalize(vertOffset);

				// snowFactor determines how much snow this vertex should receive
				float snowFactor = lerp(0, _SnowDepth, snowAlignment * snowAlignment * snowAlignment);

				// vertex displacement calculation
				v.vertex.xyz += vertOffset * snowFactor;
			}
				
                return o;
            }

            TessellationControlPoint TessellationVertexProgram(MeshData v)
            {
                TessellationControlPoint p;
				p.vertex = v.vertex;
				p.normal = v.normal;
				p.tangent = v.tangent;
				p.uv = v.uv;
				p.uv1 = v.uv1;
				p.uv2 = v.uv2;
				return p;
            }

            float TessellationEdgeFactor (
				float3 p0, float3 p1
			) {
				float edgeLength = distance(p0, p1);

				float3 edgeCenter = (p0 + p1) * 0.5;
				float viewDistance = distance(edgeCenter, _WorldSpaceCameraPos);

				return edgeLength * _ScreenParams.y / (_TessellationEdgeLength * viewDistance);
				
			}
            TesselationFactors PatchConstantFunction (InputPatch<TessellationControlPoint, 3> patch)
            {
            	float3 p0 = mul(unity_ObjectToWorld, patch[0].vertex).xyz;
				float3 p1 = mul(unity_ObjectToWorld, patch[1].vertex).xyz;
				float3 p2 = mul(unity_ObjectToWorld, patch[2].vertex).xyz;
                TesselationFactors f;
			    f.edge[0] = TessellationEdgeFactor(p1, p2);
			    f.edge[1] = TessellationEdgeFactor(p2, p0);
			    f.edge[2] = TessellationEdgeFactor(p0, p1);
				f.inside =
					(TessellationEdgeFactor(p1, p2) +
					TessellationEdgeFactor(p2, p0) +
					TessellationEdgeFactor(p0, p1)) * (1 / 3.0);
				return f;
            }
			
			float4 FragmentProgram (v2f i) : SV_Target
            {
            	return float4(1,1,1,1.0f);
            }
            
            [UNITY_domain("tri")]
            [UNITY_outputcontrolpoints(3)]
            [UNITY_outputtopology("triangle_cw")]
            [UNITY_partitioning("fractional_odd")]
            [UNITY_patchconstantfunc("PatchConstantFunction")]
            TessellationControlPoint HullProgram(InputPatch<TessellationControlPoint, 3> patch, uint id : SV_OutputControlPointID)
            {
                return patch[id];
            }
            [UNITY_domain("tri")]
            v2f DomainProgram(TesselationFactors factors, OutputPatch<TessellationControlPoint, 3> patch, float3 barycentricCoordinates : SV_DomainLocation)
            {
                MeshData data;
                #define MY_DOMAIN_PROGRAM_INTERPOLATE(fieldName) data.fieldName = \
		            patch[0].fieldName * barycentricCoordinates.x + \
		            patch[1].fieldName * barycentricCoordinates.y + \
		            patch[2].fieldName * barycentricCoordinates.z;

	            MY_DOMAIN_PROGRAM_INTERPOLATE(vertex)
                MY_DOMAIN_PROGRAM_INTERPOLATE(normal)
	            MY_DOMAIN_PROGRAM_INTERPOLATE(tangent)
	            MY_DOMAIN_PROGRAM_INTERPOLATE(uv)

            	v2f output = VertexProgram(data);
            	return output;
            }
            
            ENDCG
        }
        
    }
    FallBack "Diffuse"
}
