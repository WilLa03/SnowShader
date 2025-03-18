Shader "Custom/SnowShader"
{
    Properties
    {
    	//[ShowAsVector2] _NoiseScale ("NoiceScale", Vector) = (0, 0, 0, 0)
    	[Header(Main)]
    	_Noise ("Noise", 2D) = "gray" {}
    	_NoiseScale ("Noice Scale", Range(0,2)) = 0.1
    	_NoiseWeight ("Noice Weight", Range(0,2)) = 0.1
    	_ShadowSharpness ("Shadow Sharpness", Range(0.0001,0.05)) = 0.001
    	
    	[Space]
        _Tess ("Tessellation", Range(1, 64)) = 1
        _MaxTessDistance ("MaxTessDistance", Float) =20
        
    	[Space]
    	[Header(Snow)]
    	_SnowColor ("Color", Color) = (1,1,1,1)
    	_SnowHeight ("Snow Height", Range(-0.1,0.1)) = 0
    	_SnowTextureOpacity("(Not in use) Snow Texture Opacity ", Range(0,1)) = 0.3
    	
    	[Space]
        [Header(Path)]
	    _PathBlending("(Not in use) Path Color Blending", Range(0,3)) = 2
    	_SnowDepth ("Snow Depth", Range(0,10)) = 1
    	_SnowHeightMultiplier ("SnowBank Height", Range(0,10)) = 0.01
    	_RuggednessAmount ("Ruggedness Of SnowBanks", Range(0,10)) = 1
        [HDR]_TrailColor ("(Not in use) Trail Color", Color) = (1,0,0,1)
        
        [Space]
        [Header(Sparkles)]
        _SparkleScale("Sparkle Scale", Range(0,10)) = 10
    	_SparkleSpeed ("Sparkle Speed", Float) = 1.0
    	_BaseSparkleVisibility ("Base Sparkle Visibility", Range(0,1)) = 0.1
    	_PeakSparkleVisibility ("Peak Sparkle Visibility", Range(0,2)) = 0.5
    	_StandardSparkStrength ("Standard Strength of Spark", Range(0.1,3)) = 0.6
    	[Space]
    	_SparkleReflectionScale("Sparkle In Reflection Scale", Range(0,10)) = 10
    	_SparkCutoffInReflection("Sparkle Cutoff In Reflection", Range(0,10)) = 0.9
    	_AmountOfReflection("Amount Of Reflection", Range(0,10)) = 0.9
    	_StrengthOfReflectionEdge("Edge Reflection Strength", Range(0,1)) = 0.91
    	_StrengthOfReflectionCenter("Center Reflection Strength", Range(0,10)) = 3
    	[Space]
        _SparkleNoise("Sparkle Noise", 2D) = "gray" {}
    	_Gloss ("Gloss", Range(0,1)) = 1
    	[Space]
    	[Header(Shadow)]
    	_DisplacementScale ("Displacement Scale", Range(0,100)) = 1
        
        
    	
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma multi_compile_fwdbase
            #pragma vertex TessellationVertexProgram
            #pragma hull HullProgram
            #pragma domain DomainProgram
            #pragma fragment FragmentProgram
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma target 4.6

            #define TAU 6.283185307179586
            #define VERTEXLIGHT_ON

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            sampler2D _Noise;
            sampler2D _SparkleNoise;
            
            fixed4 _SnowColor;
            fixed4 _TrailColor;

            float _Tess;
            float _MaxTessDistance;
            float _NoiseScale;
            float _NoiseWeight;
            float _SnowHeight;
            float _SnowDepth;
            float _SparkleSpeed;
            float _SnowTextureOpacity;
            float _SparkleScale;
            float _Gloss;
            float _SparkCutoffInReflection;
            float _StrengthOfReflectionCenter;
            float _ShadowSharpness;
            float _SparkleReflectionScale;
            float _AmountOfReflection;
            float _StrengthOfReflectionEdge;
            float _StandardSparkStrength;
            float _SnowHeightMultiplier;
            float _RuggednessAmount;
            float _PathBlending;
            float _BaseSparkleVisibility;
            float _PeakSparkleVisibility;
            

            uniform float3 _PlayerPos;
            uniform sampler2D _GlobalEffectRT;
            uniform float _OrthographicCamSize;

            struct Meshdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD2;
            	float4 tangent : TANGENT;
            	float4 color : COLOR;
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
            	LIGHTING_COORDS(7,8)
            };

            struct ControlPoint
            {
                float4 vertex : INTERNALTESSPOS;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            	float4 tangent : TEXCOORD3;
            	float4 color : COLOR;
            	
            	
            };

            struct TessellationFactors
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

            float3 orthogonal(float3 v)
			{
				return normalize(abs(v.x) > abs(v.z) ? float3(-v.y, v.x, 0.0) : float3(0.0, -v.z, v.y));
			}

            float3 displace(float3 vertex)
			{
				float3 worldPos = mul(unity_ObjectToWorld, vertex).xyz;
                float2 uv = worldPos.xz - float2(-_OrthographicCamSize,-_OrthographicCamSize);
				uv /= (-_OrthographicCamSize * 2);
				uv +=1;
				float fade = 0.9f;
				
                float4 RTEffect = tex2Dlod(_GlobalEffectRT, float4(uv,0,0));
                RTEffect *= smoothstep(0.99, fade, uv.x) * smoothstep(0.99,fade,1-uv.x);
				RTEffect *= smoothstep(0.99, fade, uv.y) * smoothstep(0.99,fade,1-uv.y);
				
                float SnowNoice = tex2Dlod(_Noise, float4(worldPos.xz * _NoiseScale + 0.5, 0,0)).r;

				float downDisplacement = saturate(RTEffect.g * _SnowDepth);

				// Introduce ruggedness by modulating the upward displacement with noise
				float ruggedUpDisplacement = saturate(RTEffect.r * _SnowHeightMultiplier) * (1.0 - downDisplacement);
				float clampedNoise = clamp(SnowNoice, 0.14, 0.15); // Limits the variability of ranges for height in the snowhbank 
				ruggedUpDisplacement *= saturate( clampedNoise)* _RuggednessAmount; // _RuggednessAmount controls the intensity of ruggedness
				
				//float upDisplacement = saturate(RTEffect.r * _SnowHeightMultiplier) * (1.0 - downDisplacement); //Valiable for upwardsdisplacement if ruggedness isnt wanted
				
				return saturate(_SnowHeight + (SnowNoice * _NoiseWeight)) * (1.0 - downDisplacement + ruggedUpDisplacement);
			}
            
            float3 SetNormal (float3 vertex, float3 normal, float4 tangent)
			{
				
				float3 modifiedPos = vertex;
			    modifiedPos.y += displace(vertex);
			    
			    float3 posPlusTangent = vertex + tangent * _ShadowSharpness;
			    posPlusTangent.y += displace(posPlusTangent);

			    float3 bitangent = cross(normal, tangent);
			    float3 posPlusBitangent = vertex + bitangent * _ShadowSharpness;
			    posPlusBitangent.y += displace(posPlusBitangent);

			    float3 modifiedTangent = posPlusTangent - modifiedPos;
			    float3 modifiedBitangent = posPlusBitangent - modifiedPos;

				float3 modifiedNormal =  cross(modifiedTangent, modifiedBitangent);
				return modifiedNormal;
			}
            


            

            v2f VertexProgram (Meshdata v)
            {
                v2f o;

				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				
                o.viewDir = normalize(_WorldSpaceCameraPos - worldPos);

                v.vertex.y += displace(v.vertex);

                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.vlight = v.color;
				o.normal = SetNormal(v.vertex,v.normal, v.tangent);
                o.uv = v.uv;

				o.pos = UnityObjectToClipPos(v.vertex);

				o.lightDir = normalize(ObjSpaceLightDir(v.vertex));
				float3 worldNormal = normalize(mul((float3x3)unity_ObjectToWorld, v.normal));

				o.vlight = float3(1,1,1);
				#ifdef LIGHTMAP_OFF

						float3 shlight = ShadeSH9(float4(normalize(worldNormal) , 1.0));

						o.vlight = shlight;
						o.vlight += float3(0,0,0.05); // adds a slighty blue tint to the light

            		#ifdef VERTEXLIGHT_ON

            			o.vlight += Shade4PointLights (

            				unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,

            				unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,

            				unity_4LightAtten0, worldPos, worldNormal);

            		#endif // VERTEXLIGHT_ON

            	#endif // LIGHTMAP_OFF

            	TRANSFER_VERTEX_TO_FRAGMENT(o);
				
                return o;
            }

            float4 _LightColor0;

            ControlPoint TessellationVertexProgram(Meshdata v)
            {
                ControlPoint p;
                p.vertex = v.vertex;
                p.uv= v.uv;
                p.normal = v.normal;
                p.worldPos = v.worldPos;
            	p.color = v.color;
            	p.tangent = v.tangent;
                return p;
            }

            TessellationFactors PatchConstantFunction(InputPatch<ControlPoint, 3> patch)
            {
				float minDist = 5.0;
            	float maxDist = _MaxTessDistance;

            	TessellationFactors f;

            	float edge0 = CalcDistanceTessFactor(patch[0].vertex,minDist,maxDist,_Tess);
				float edge1 = CalcDistanceTessFactor(patch[1].vertex,minDist,maxDist,_Tess);
				float edge2 = CalcDistanceTessFactor(patch[2].vertex,minDist,maxDist,_Tess);

				f.edge[0] = (edge1+ edge2)/2;
				f.edge[1] = (edge2+ edge0)/2;
				f.edge[2] = (edge0+ edge1)/2;
				f.inside = (edge0+edge1+edge2)/3;
                
                return f;
            }

            
            

            float4 FragmentProgram (v2f i) : SV_Target
            {
            	
                i.lightDir = normalize(i.lightDir);
            	i.normal = normalize ( i.normal );
				float atten = LIGHT_ATTENUATION(i);
            	float3 color;

            	float NdotL = saturate( dot(i.normal.xyz, i.lightDir.xyz));
            	color = UNITY_LIGHTMODEL_AMBIENT.rgb * 2;
            	color += i.vlight;
            	color += _LightColor0.rgb * NdotL * ( atten * 2);
            	
				///
				/// Funktion to add a color in the bottom of the trail
				///
            	//float3 mainColors = lerp(_SnowColor,snowtexture * _SnowColor, _SnowTextureOpacity);
            	//lerp the colors using the RT effect path 
            	//float3 path = lerp(_TrailColor * effect.g,_TrailColor, saturate(effect.g * _PathBlending));
				//color += lerp(color,path, saturate(effect.g));


            	float3 N = normalize ( i.normal );
            	float3 L = _WorldSpaceLightPos0.xyz;
            	float3 lambert = saturate( dot(N,L));
            	float3 diffuseLight = lambert * _LightColor0.xyz;
            	float specularExponent = exp2(_Gloss *11 ) + 2;

            	float3 V  = normalize( _WorldSpaceCameraPos - i.worldPos);
            	float3 H = normalize(L+V);

            	float3 specularLight = saturate(dot(H,N))* (lambert >0);// Blinn-Phong
            	
            	 //Gör i vanligt script om optimera
            	specularLight = pow(specularLight, specularExponent) * _Gloss;
            	specularLight *= specularExponent;
            	specularLight *= _LightColor0.xyz;
				float3 reflectedLight = diffuseLight * _SnowColor + specularLight;

            	// Generate a pseudo-random seed for each world position
				float randomSeed = frac(sin(dot(i.worldPos.xz, float2(12.9898, 78.233))) * 43758.5453);

            	float sin1 = sin(_Time * _SparkleSpeed + randomSeed * 3.14);
            	float cos2 = cos(_Time * _SparkleSpeed + randomSeed * 2.71);
            	
				// Compute a time-based random offset
				float2 timeVaryingOffset = float2(sin1,cos2);
            	
				float2 sparklePosition = (i.worldPos.xz * _SparkleScale*0.01) + timeVaryingOffset * 0.5;
            	
            	float sparklesStatic = tex2D(_SparkleNoise, sparklePosition).r;

            	sparklesStatic = step(0.3,sparklesStatic);

            	float sparklesReflectionStatic = tex2D(_SparkleNoise, float4(i.worldPos.xz * _SparkleReflectionScale + 0.5, 0,0)).r;
            	
            	// Add subtle fluctuation to the static noise
				float sparkleFluctuation = abs(0.1 * sin(_Time * _SparkleSpeed+ randomSeed)); // Smooth fluctuation using sine
				sparklesStatic += sparkleFluctuation;
            	
				// Create a smoothed sparkle value with both fade-in and fade-out
				float sparkleFadeIn = smoothstep(_BaseSparkleVisibility, _PeakSparkleVisibility, sparklesStatic);
				float sparkleFadeOut = smoothstep(_PeakSparkleVisibility, _BaseSparkleVisibility, sparklesStatic); // Reverse smoothstep for fade-out
				float sparkleMoving = max(sparkleFadeIn - sparkleFadeOut, 0.0); // Ensure no negative values
            	
            	
            	
				float RemoveInShadow = pow(reflectedLight,_StandardSparkStrength);  //TODO add variable
            	float cutoffSparkles1 = sparkleMoving * RemoveInShadow;

            	
            	
            	float SR = step(reflectedLight, _AmountOfReflection);
            	SR= smoothstep(0.99,SR,_StrengthOfReflectionEdge)* pow(reflectedLight,_StrengthOfReflectionCenter) ;
            	float cutoffSparkles2 = step(_SparkCutoffInReflection,sparklesReflectionStatic*(saturate(SR.x)));
            	cutoffSparkles2 *= reflectedLight;
            	
            	float cutoffSparkles = cutoffSparkles1 +cutoffSparkles2;
            	cutoffSparkles *= SHADOW_ATTENUATION(i);
            	color +=cutoffSparkles;
            	color += diffuseLight * (reflectedLight* SHADOW_ATTENUATION(i));

            	return float4(color,1.0f);
            }


            [UNITY_domain("tri")]
            [UNITY_outputcontrolpoints(3)]
            [UNITY_outputtopology("triangle_cw")]
            [UNITY_partitioning("fractional_odd")]
            [UNITY_patchconstantfunc("PatchConstantFunction")]
            ControlPoint HullProgram(InputPatch<ControlPoint, 3> patch, uint id : SV_OutputControlPointID)
            {
                return patch[id];
            }

            [UNITY_domain("tri")]
            v2f DomainProgram(TessellationFactors factors,OutputPatch<ControlPoint, 3> patch,float3 barycentricCoordinates : SV_DomainLocation)
            {
                Meshdata data;

				#define DomainCalc(fieldName) data.fieldName = \
					patch[0].fieldName * barycentricCoordinates.x + \
		            patch[1].fieldName * barycentricCoordinates.y + \
		            patch[2].fieldName * barycentricCoordinates.z;

				
                DomainCalc(vertex)
            	DomainCalc(normal)
                DomainCalc(uv)
				DomainCalc(color)
            	DomainCalc(worldPos)
            	DomainCalc(tangent)
            	

				v2f output = VertexProgram(data);

				return output;
            }
            
            ENDCG
        }

		Pass
		{
		    Name "ShadowCaster"
		    Tags {"LightMode" = "ShadowCaster"}
		    CGPROGRAM
		    #pragma vertex ShadowCasterVertex
		    #pragma fragment ShadowCasterFragment
		    #include "UnityCG.cginc"

		    uniform sampler2D _GlobalEffectRT;
		    float _OrthographicCamSize;
		    sampler2D _Noise;
		    float _NoiseScale, _NoiseWeight;
		    float _SnowHeight, _SnowDepth, _ShadowSharpness;
		    float _DisplacementScale, _SnowHeightMultiplier, _RuggednessAmount;
		    

		    float3 displace(float3 worldPos)
		    {
                
                float2 uv = worldPos.xz - float2(-_OrthographicCamSize,-_OrthographicCamSize);
				uv /= (-_OrthographicCamSize * 2);
				uv +=1;
				float fade = 0.9f;
				
                float4 RTEffect = tex2Dlod(_GlobalEffectRT, float4(uv,0,0));
                RTEffect *= smoothstep(0.99, fade, uv.x) * smoothstep(0.99,fade,1-uv.x);
				RTEffect *= smoothstep(0.99, fade, uv.y) * smoothstep(0.99,fade,1-uv.y);
				
                float SnowNoice = tex2Dlod(_Noise, float4(worldPos.xz * _NoiseScale + 0.5, 0,0)).r;

				float downDisplacement = saturate(RTEffect.g * _SnowDepth);

				// Introduce ruggedness by modulating the upward displacement with noise
				float ruggedUpDisplacement = saturate(RTEffect.r * _SnowHeightMultiplier) * (1.0 - downDisplacement);
				float clampedNoise = clamp(SnowNoice, 0.14, 0.15); // Limits the variability of ranges for height in the snowhbank 
				ruggedUpDisplacement *= saturate( clampedNoise)* _RuggednessAmount; // _RuggednessAmount controls the intensity of ruggedness
				
				//float upDisplacement = saturate(RTEffect.r * _SnowHeightMultiplier) * (1.0 - downDisplacement); //Valiable for upwardsdisplacement if ruggedness isnt wanted
				
				return saturate(_SnowHeight + (SnowNoice * _NoiseWeight)) * (1.0 - downDisplacement + ruggedUpDisplacement);
		    }

		    void ShadowCasterVertex(appdata_full v, out float4 pos : SV_POSITION)
		    {
		    	float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
		        float displacement = displace(worldPos);
		        worldPos.y += displacement* _DisplacementScale;
		        pos = UnityObjectToClipPos(float4(worldPos, 1.0));
		    }
		    

		    float4 ShadowCasterFragment() : SV_Target
		    {
		        return 0;
		    }

		    ENDCG
		}
		
    }
	FallBack "Diffuse"
}
