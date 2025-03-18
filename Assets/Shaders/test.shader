Shader "AE/Deformer"
{
   
    Properties {
        _Color ("Color", Color) = (1, 1, 1, 1)
        _PhaseOffset ("PhaseOffset", Range(0,1)) = 0
        _Speed ("Speed", Range(0.1,10)) = 1
        _Depth ("Depth", Range(0.01,1)) = 0.2
        _Scale ("Scale", Range(0.1,20)) = 10
    }
   
   
    SubShader
    {
       
        Tags
        {
            "Queue" = "Geometry"
            "RenderType" = "Opaque"
            "IgnoreProjector" = "True"
        }
       
        CGPROGRAM
        //#pragma surface surf Lambert finalcolor:showNormals vertex:vert noforwardadd
        #pragma surface surf Lambert vertex:vert
       
       
       
        half3 _Color;
        float _PhaseOffset;
        float _Speed;
        float _Depth;
        float _Scale;
       
       
       
        struct Input
        {
            half3 debugColor;
        };
       
       
       
        void vert( inout appdata_full v, out Input o )
        {

            // Obtain tangent space rotation matrix
            float3 binormal = cross( v.normal, v.tangent.xyz ) * v.tangent.w;
            float3x3 rotation = transpose( float3x3( v.tangent.xyz, binormal, v.normal ) );
           
            // Create two sample vectors (small +x/+y deflections from +z), put them in tangent space, normalize them, and halve the result.
            // This is equivalent to sampling neighboring vertex data since we're on a unit sphere.
            float3 v1 = normalize( mul( rotation, float3(0.1, 0, 1) ) ) * 0.5;
            float3 v2 = normalize( mul( rotation, float3(0, 0.1, 1) ) ) * 0.5;
           
            // Some animation values
            float phase = _PhaseOffset * 3.14 * 2;
            float speed = _Time.y * _Speed;
           
            // Modify the real vertex and two theoretical samples by the distortion algorithm (here a simple sine wave on XZ)
            v.vertex.x += sin( phase + speed + (v.vertex.z * _Scale) ) * _Depth;
            v1.x += sin( phase + speed + (v1.z * _Scale) ) * _Depth;
            v2.x += sin( phase + speed + (v2.z * _Scale) ) * _Depth;
           
            // Take the cross product of the sample-original positions, resulting in a dynamic normal
            float3 vn = cross( v2-v.vertex.xyz, v1-v.vertex.xyz );
           
            // Normalize
            v.normal = normalize( vn );
           
            // OPTIONAL pass this out to a custom value.  Uncomment the showNormals finalcolor profile option above to see the result
            o.debugColor = ( v.normal.xyz * 0.5 ) + 0.5;
        }
       
       
       
        // Optional normal debug function, unccoment profile option to invoke
        void showNormals( Input IN, SurfaceOutput o, inout fixed4 color )
        {
            //color.rgb = IN.debugColor.rgb;
            //color.a = 1;
        }
       
       
       
        // Regular old surface shader
        void surf (Input IN, inout SurfaceOutput o)
        {
            o.Albedo = o.Normal;
        }
       
        ENDCG
       
    }
       
}