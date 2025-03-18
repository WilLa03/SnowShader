//This file is not actually needed for this shader, can be included in the shaderfile.

#ifndef PRECIPITATION_INCLUDED
#define PRECIPITATION_INCLUDED

#include "UnityCG.cginc"

sampler2D _MainTex;
sampler2D _NoiseTex;

float _GridSize;
float _Amount;
float2 _CameraRange;
float _FallSpeed;
float _MaxTravelDistance;

float2 _FlutterFrequency;
float2 _FlutterSpeed;
float2 _FlutterMagnitude;

float4 _Color;
float4 _ColorVariation;
float2 _SizeRange;

float4x4 _WindRotationMatrix;
float4 _PlayerPosition;
float _TurbulanceStrenght;
int _PlayerMoving;
float3 _PlayerMoveDirection;

struct MeshData{
    float4 vertex : POSITION;
    float4 uv : TEXCOORD0;
    uint instanceID : SV_InstanceID;
};

//vertex shader
MeshData vert(MeshData meshdata){
    return meshdata;
}

//Structure that goes from the geometry shader to the fragment shader
struct g2f{
    //UNITY_POSITION(pos);
    float4 pos : SV_POSITION;
    float4 uv : TEXCOORD0;
    //UNITY_VERTEX_OUTPUT_STEREO
};

void AddVertex (inout TriangleStream<g2f> stream, float3 vertex, float2 uv, 
    float colorVariation, float opacity){
        //Initialize the struct with information that will go from the vertex shader
        //to the fragment shader.

        g2f OUT;

        //Unity specific
        //UNITY_INITIALIZE_OUTPUT(g2f, OUT);
        //UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
        OUT.pos = UnityObjectToClipPos(vertex);
    
        //Transfer the uv coordinates
        OUT.uv.xy = uv;

        // we put `opacity` and `colorVariation` in the unused uv vector elements
        // this limits the amount of attributes we need going between the vertex
        // and fragment shaders, which is good for performance
        OUT.uv.z = opacity;
        OUT.uv.w = colorVariation;

        stream.Append(OUT);
};
void CreateQuad (inout TriangleStream<g2f> stream, float3 bottomMiddle, float3 topMiddle, float3 perpDir, float colorVariation, float opacity) {    
    AddVertex (stream, bottomMiddle - perpDir, float2(0, 0), colorVariation, opacity);
    AddVertex (stream, bottomMiddle + perpDir, float2(1, 0), colorVariation, opacity);
    AddVertex (stream, topMiddle - perpDir, float2(0, 1), colorVariation, opacity);
    AddVertex (stream, topMiddle + perpDir, float2(1, 1), colorVariation, opacity);
    stream.RestartStrip();
};


//Geom function builds the quad from each vertex in the mesh. Runs once for
//each snowflake.
[maxvertexcount(4)]
void geom(point MeshData IN[1], inout TriangleStream<g2f> stream){
    
    MeshData meshData = IN[0];

    UNITY_SETUP_INSTANCE_ID(meshData);
    
    //position of the snowflake
    float3 pos = meshData.vertex.xyz;
    
    pos.xz *= _GridSize;

    float2 noise = float2(frac(tex2Dlod(_NoiseTex, float4(meshData.uv.xy, 0, 0)).r + (pos.x + pos.z)),
        frac(tex2Dlod(_NoiseTex, float4(meshData.uv.yx * 2, 0, 0)).r + (pos.x * pos.z)));

    float vertexAmountThreshold = meshData.uv.z;
    vertexAmountThreshold *= noise.y;
    if(vertexAmountThreshold > _Amount)return;

    float3x3 windRotation = (float3x3)_WindRotationMatrix;

    float3 rotatedVertexOffset = mul(windRotation, pos) - pos;

    pos.y -= (_Time.y + 10000) * (_FallSpeed + (_FallSpeed * noise.y));

    float2 inside = pos.y * noise.yx * _FlutterFrequency + ((_FlutterSpeed + (_FlutterSpeed * noise)) * _Time.y);
    float2 flutter = float2(sin(inside.x), cos(inside.y)) * _FlutterMagnitude;
    pos.xz += flutter;

    pos.y = fmod(pos.y, -_MaxTravelDistance) + noise.x;

    pos = mul(windRotation, pos);

    pos -= rotatedVertexOffset;
    
    pos.y += _GridSize * .5;

    float2 quadSize = lerp(_SizeRange.x, _SizeRange.y, noise.x);

   
    float3 worldPos = mul(unity_ObjectToWorld, float4(pos.xyz, 1.0)).xyz;
    
    float maxEffectDistance = 1;

   
    _PlayerMoveDirection = normalize(_PlayerMoveDirection);
    
    float3 pointPosition = _PlayerPosition - (_PlayerMoveDirection * (maxEffectDistance / 2));
    float3 direction = worldPos - pointPosition;
    float distance = length(direction);
    if(distance < maxEffectDistance && _PlayerMoving == 1)
    {
        
        // Normalize direction to get a unit vector
        float3 normalizedDir = normalize(direction);

        // Calculate a perpendicular vector for swirling (rotation in the XZ plane)
        float3 swirlDir = float3(-normalizedDir.z, 0.0, normalizedDir.x);

        // Swirl offset based on time, strength, and distance
        float swirlMagnitude = 0.5 * exp(-distance * _TurbulanceStrenght);
        float3 swirlOffset = swirlDir * sin(_Time.y * 2.0) * swirlMagnitude;
        

        // Add outward drift based on distance
        float3 outwardDrift = normalizedDir * (0.9 * exp(-distance * _TurbulanceStrenght));

        // Apply the swirl and drift to the position
        pos += swirlOffset + outwardDrift;
        worldPos = mul(unity_ObjectToWorld, float4(pos.xyz, 1.0)).xyz;
    }

    float3 pos2Camera = worldPos - _WorldSpaceCameraPos;
    float distanceToCamera = length(pos2Camera);

    pos2Camera /= distanceToCamera;

    float3 camForwards = normalize(mul((float3x3)unity_CameraToWorld, float3(0,0,1)));

    if(dot(camForwards, pos2Camera) < 0.5)return;

    float opacity = 1.0;

    float camDistanceInterpolation = 1.0 - min(max(distanceToCamera - _CameraRange.x, 0) / (_CameraRange.y - _CameraRange.x), 1);
    opacity *= camDistanceInterpolation;

    #define VERTEX_THRESHOLD_LEVELS 4
    float vertexAmountThresholdFade = min((_Amount - vertexAmountThreshold) * VERTEX_THRESHOLD_LEVELS, 1);
    opacity *= vertexAmountThresholdFade;

    if(opacity <= 0)return;

    float colorVariation = (sin(noise.x * (pos.x + pos.y *noise.y + pos.z + _Time.y * 2)) * 0.5);
    //float colorVariation = float4(0,0,0,0);
    
    

    /*
    //FOR DEBUG REMOVE WHEN DONE
    if(distance < maxEffectDistance)
    {
         colorVariation = fixed4(1.0, 0.5, 0.2, 1.0);
         quadSize = float2(.3, .3);
    }*/
    
    float3 quadUpDirection = UNITY_MATRIX_IT_MV[1].xyz;
    float3 topMiddle = pos + quadUpDirection * quadSize.y;
    float3 rightDirection = UNITY_MATRIX_IT_MV[0].xyz * 0.5 * quadSize.x;

    CreateQuad (stream, pos, topMiddle, rightDirection, colorVariation, opacity);
};



float4 frag(g2f IN) : SV_TARGET
{

    float4 color = tex2D(_MainTex, IN.uv.xy) * _Color;

    float colorVariationAmoount = IN.uv.w;
    float3 shiftedColor = lerp(color.rgb, _ColorVariation.rgb, colorVariationAmoount);
    float maxBase = max(color.r, max(color.g, color.b));
    float newMaxBase = max(shiftedColor.r, max(shiftedColor.g, shiftedColor.b));
    color.rgb = saturate(shiftedColor * ((maxBase/newMaxBase) * 0.5 + 0.5));
    
    color.a *= IN.uv.z;
    return color;
};
#endif //PRECIPITATION_INCLUDED