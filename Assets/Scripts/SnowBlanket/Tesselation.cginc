#if !defined(TESSELLATION_INCLUDED)
#define TESSELLATION_INCLUDED

struct TesselationFactors
{
    float edge[3] : SV_TessFactor;
    float inside : SV_InsideTessFactor;
};
TesselationFactors MyPatchConstantFunction (InputPatch<Ver, 3> patch)
{
    TesselationFactors f;
    f.edge[0] = 1;
    f.edge[1] = 1;
    f.edge[2] = 1;
    f.inside = 1;
    return f;
}
[UNITY_domain("tri")]
[UNITY_outputcontrolpoints(3)]
[UNITY_outputtopology("triangle_cw")]
[UNITY_partitioning("integer")]
[UNITY_patchconstantfunc("MyPatchConstantFunction")]
Input MyHullProgram(InputPatch<Input, 3> patch, uint id : SV_OutputControlPointID)
{
    return patch[id];
}
#include "UnityCG.cginc"

#endif

