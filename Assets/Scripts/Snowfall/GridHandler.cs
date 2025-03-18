using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor.EditorTools;
using UnityEngine;

/// <summary>
/// A script that creates a grid over the world. This is then used to know where
/// render the snowfall. We don't want to render the snow following the camera,
/// since that makes it so the player can never reach the snowflake, and that
/// makes for a very not realistic experience.
///     - Linnéa
/// </summary>

[ExecuteInEditMode]
public class GridHandler : MonoBehaviour
{
    [Tooltip("How large (in meters) one grid-block side is.")]
    public float GridSize = 10f;

    [Tooltip("This is the object that's being tracked, preferably the players transform.")]
    public Transform TrackedTransform;

    //Is called when the grid changes.
    public event Action<Vector3Int> OnGridChange;

    private Vector3Int _lastTrackedGridPos = new Vector3Int(-99999, -99999, -99999);

    // Update is called once per frame
    void Update()
    {
        if(TrackedTransform == null){
            Debug.LogWarning("Grid handler has no transform to track.");
            return;
        }
        //Calculate the grid-coordinate for where the tracked transform is at.
        Vector3 trackedPos = TrackedTransform.position;
        Vector3Int trackedGridPos = new Vector3Int(
            Mathf.FloorToInt(trackedPos.x / GridSize),
            Mathf.FloorToInt(trackedPos.y / GridSize),
            Mathf.FloorToInt(trackedPos.z / GridSize)
        );
        //check if the transform is still in the same gridspace as last update
        if(trackedGridPos != _lastTrackedGridPos){
            OnGridChange?.Invoke(trackedGridPos);
            _lastTrackedGridPos = trackedGridPos;
        }

        
    }
    //calculate the center position of a certain grid coordinate.
    public Vector3 GetGridCenter(Vector3Int grid){
        float halfGrid = GridSize * 0.5f;
        return new Vector3(
            grid.x * GridSize + halfGrid,
            grid.y * GridSize + halfGrid,
            grid.z * GridSize + halfGrid
        );
    }
    private void OnDrawGizmos()
    {
        for(int x = -1; x <= 1; x++)
        {
            for (int y = -1; y <= 1; y++)
            {
                for (int z = -1; z <= 1; z++)
                {
                    bool isCenter = x == 0 && y == 0 && z == 0;
                    Vector3 gridCenter = GetGridCenter(_lastTrackedGridPos + new Vector3Int(x,y,z));

                    Gizmos.color = isCenter ? Color.green : Color.red;
                    Gizmos.DrawWireCube(gridCenter, Vector3.one * (GridSize * (isCenter ? 0.95f : 1.0f)));
                }
            }
        }
    }
}
