Shader "Unlit/SnowLight"
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
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #define VERTEXLIGHT_ON

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            struct appdata
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

            sampler2D _MainTex;
            float4 _MainTex_ST;
			sampler2D _Bump;
			float _SnowLevel;
			float4 _SnowColor;
			float4 _MainColor;
			float4 _SnowDirection;
			float _SnowDepth;
			float _SnowPuffiness;
            
            v2f vert (appdata v)
            {
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
					// vertex displacement calculation
					//float3 newPos = vertOffset * snowFactor;
					v.vertex.xyz += vertOffset;
				}
                v2f o;
            	float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.pos = UnityObjectToClipPos(v.vertex);
            	o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.vlight = v.color;
				
                o.uv = v.uv;
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
            sampler2D _SparkleNoise;
            float4 _LightColor0;

            float _NoiseScale;
            float _NoiseWeight;
            float _SnowHeight;
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
            float4 frag (v2f i) : SV_Target
            {
                i.lightDir = normalize(i.lightDir);
            	i.normal = normalize ( i.normal );
				float atten = LIGHT_ATTENUATION(i);
            	float3 color;

            	
            	float NdotL = saturate( dot(i.normal.xyz, i.lightDir.xyz));
            	color = UNITY_LIGHTMODEL_AMBIENT.rgb * 2;
            	
            	float3 snowDir = normalize(_SnowDirection.xyz);
				float snowAlignment = dot(i.normal, snowDir);

				if (snowAlignment >= -_SnowLevel)
				{
					color += _SnowColor.rgb;
				}
				else
				{
					color +=  _MainColor;
				}
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
            ENDCG
        }
    }
}
