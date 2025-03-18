using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;

/// <summary>
/// Creates the base of the mesh to render.
///     - Linnéa
/// </summary>
[ExecuteInEditMode]
public class PrecipitationManager : MonoBehaviour
{

    [System.Serializable]
    public class EnvironmentParticlesSettings
    {
        [Range(0, 1)] public float amount = 1.0f;
        public Color Color = Color.white;
        
        [Tooltip("Alpha = variation amount")] 
        public Color ColorVariation = Color.white;

        public float FallSpeed;
        public Vector2 CameraRange;
        public Vector2 FlutterFrequency;
        public Vector2 FlutterSpeed;
        public Vector2 FlutterMagnitude;
        public Vector2 SizeRange;

        public EnvironmentParticlesSettings(Color color, Color colorVariation, float fallSpeed, Vector2 cameraRange, Vector2 flutterFrequency,
            Vector2 flutterSpeed, Vector2 flutterMagnitude, Vector2 sizeRange)
        {
            Color = color;
            ColorVariation = colorVariation;
            FallSpeed = fallSpeed;
            CameraRange = cameraRange;
            FlutterFrequency = flutterFrequency;
            FlutterSpeed = flutterSpeed;
            FlutterMagnitude = flutterMagnitude;
            SizeRange = sizeRange;
        }
    }
    
    public Texture2D mainTexture;
    public Texture2D noiseTexture;

    [Range(0, 1)] public float WindStrenght;
    [Range(-180, 180)] public float WindYrotation;

    public Transform PlayerTransform;
    public float TurbulanceStrenght;
    
    [Tooltip("How mush to subdivide the mesh (65536 (256 x 256) vertices is the max per mesh).")]
    [Range(2, 256)] public int meshSubdivision = 200;

    public EnvironmentParticlesSettings snow = new EnvironmentParticlesSettings(Color.white, Color.white, 0.25f,
        new Vector2(0, 10), new Vector2(0.988f, 1.234f), new Vector2(1f, 0.5f), new Vector2(0.35f, 0.25f),
        new Vector2(0.05f, 0.025f));

    private GridHandler _gridHandler;
    private Mesh _meshToDraw;
    private Vector3 _playerLastPos;
    private bool _playerMoving;

    Matrix4x4[] renderMatrices = new Matrix4x4[3 *3 *3];

    Material snowMaterial;
    
    //automatic material creation
    static Material CreateMaterialIfNull(string shaderName, ref Material reference)
    {
        if (reference == null)
        {
            reference = new Material(Shader.Find(shaderName));
            reference.hideFlags = HideFlags.HideAndDontSave;
            reference.renderQueue = 3000;
            reference.enableInstancing = true;
        }
        return reference;
    }

    private void OnEnable()
    {
        _gridHandler = GetComponent<GridHandler>();
        _gridHandler.OnGridChange += OnGridHandlerGridChange;
    }
    private void OnDisable()
    {
        _gridHandler.OnGridChange -= OnGridHandlerGridChange;
    }
    void OnGridHandlerGridChange(Vector3Int playerGrid){ 
        int i = 0;

        for(int x = -1; x <= 1; x++)
        {
            for (int y = -1; y <= 1; y++)
            {
                for (int z = -1; z <= 1; z++)
                {
                    Vector3Int neighbourOffset = new Vector3Int(x,y,z);

                    renderMatrices[i++].SetTRS(
                        _gridHandler.GetGridCenter(playerGrid + neighbourOffset),
                        Quaternion.identity,
                        Vector3.one
                    );
                }
            }
        }
    }

    private void Update()
    {
        // update the mesh automatically if it doesn't exist
        if (_meshToDraw == null) RebuildPrecipitationMesh();

        float windStrenghtAngle = Mathf.Lerp(0, 45, WindStrenght);

        Vector3 windRotationEulerAngles = new Vector3(-windStrenghtAngle, WindYrotation, 0);

        Matrix4x4 windRotationMatrix =
            Matrix4x4.TRS(Vector3.zero, Quaternion.Euler(windRotationEulerAngles), Vector3.one);

        float maxTravelDistance = _gridHandler.GridSize / Mathf.Cos(windStrenghtAngle * Mathf.Deg2Rad);
        _playerMoving = !(_playerLastPos == PlayerTransform.position);

        RenderEnvironmentParticles(snow, CreateMaterialIfNull("Custom/Snow", ref snowMaterial), maxTravelDistance, windRotationMatrix);
        _playerLastPos = PlayerTransform.position;
    }

    private void RenderEnvironmentParticles(EnvironmentParticlesSettings settings, Material material, float maxTravelDistance, Matrix4x4 windRotationMatrix)
    {
        if(settings.amount == 0)return;
        
        material.SetTexture("_MainTex", mainTexture);
        material.SetTexture("_NoiseTex", noiseTexture);
        material.SetFloat("_GridSize", _gridHandler.GridSize);
        material.SetFloat("_Amount", settings.amount);
        material.SetColor("_Color", settings.Color);
        material.SetColor("_ColorVariation", settings.ColorVariation);
        material.SetFloat("_FallSpeed", settings.FallSpeed);
        material.SetVector("_FlutterFrequency", settings.FlutterFrequency);
        material.SetVector("_FlutterSpeed", settings.FlutterSpeed);
        material.SetVector("_FlutterMagnitude", settings.FlutterMagnitude);
        material.SetVector("_CameraRange", settings.CameraRange);
        material.SetVector("_SizeRange", settings.SizeRange);
        material.SetFloat("_MaxTravelDistance", maxTravelDistance);
        material.SetMatrix("_WindRotationMatrix", windRotationMatrix);
        material.SetVector("_PlayerPosition", PlayerTransform.position);
        material.SetFloat("_TurbulanceStrenght", TurbulanceStrenght);
        material.SetInteger("_PlayerMoving", _playerMoving ? 1 : 0);
        material.SetVector("_PlayerMoveDirection", PlayerTransform.forward);

        Graphics.DrawMeshInstanced(
            _meshToDraw, 0, material, renderMatrices, renderMatrices.Length, 
            null, ShadowCastingMode.Off, true, 0, null, LightProbeUsage.Off
        );
    }
    // the mesh created has a 
    // center at [0,0], 
    // min at [-.5, -.5] 
    // max at [.5, .5]
    public void RebuildPrecipitationMesh(){
        Mesh mesh = new Mesh();
        List<int> indices = new List<int>();
        List<Vector3> vertices = new List<Vector3>();
        List<Vector3> uvs = new List<Vector3>();

        // use 0 - 100 range instead of 0 to 1
        // to avoid precision errors when subdivisions
        // are to high

        float f = 100f / meshSubdivision;
        int i = 0;
        for(float x = 0.0f; x <= 100f; x += f)
        {
            for (float y = 0.0f; y <= 100f; y += f)
            {
                float x01 = x / 100.0f;
                float y01 = y / 100.0f;

                vertices.Add(new Vector3(x01 - 0.5f, 0, y01 - 0.5f));

                float vertexIntensityThreshold =
                    Mathf.Max((float)((x / f) % 4.0f) / 4.0f, (float)((y / f) % 4.0f) / 4.0f);

                uvs.Add(new Vector3(x01, y01, vertexIntensityThreshold));

                indices.Add(i++);
            }
        }

        mesh.SetVertices(vertices);
        mesh.SetUVs(0, uvs);
        mesh.SetIndices(indices.ToArray(), MeshTopology.Points, 0);

        // give a large bounds so it's always visible, we'll handle culling manually
        mesh.bounds = new Bounds(Vector3.zero, new Vector3(500, 500, 500));

        //don't save as an asset
        mesh.hideFlags = HideFlags.HideAndDontSave;

        _meshToDraw = mesh;
    }
}
#if UNITY_EDITOR
//create a custom editor with a button to trigger rebuilding of the mesh
[CustomEditor(typeof(PrecipitationManager))]
public class PrecipitationManagerEditor : Editor{
    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();
        if(GUILayout.Button("Rebuild Precipitation Mesh")){
            (target as PrecipitationManager).RebuildPrecipitationMesh();
            //Set dirty to make sure the editor updates
            EditorUtility.SetDirty(target);
        }
    }
}
#endif