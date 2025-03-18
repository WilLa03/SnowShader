using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PresenceManager : MonoBehaviour
{
    [SerializeField] private RenderTexture renderTexture;
    [SerializeField] private Transform Player;
    [SerializeField] private Transform SnowPlatform;
    void Awake()
    {
        Camera _camera = GetComponent<Camera>();
        if (Math.Abs(SnowPlatform.lossyScale.x / SnowPlatform.lossyScale.z - 1) < 0.001)
        {
            _camera.orthographicSize = SnowPlatform.lossyScale.x *0.5f;
        }
        else
        {
            _camera.orthographicSize = GetSmallest(SnowPlatform.lossyScale.x ,SnowPlatform.lossyScale.z) *0.5f;
            float scale = GetLargest(SnowPlatform.lossyScale.x, SnowPlatform.lossyScale.z) /
                          GetSmallest(SnowPlatform.lossyScale.x, SnowPlatform.lossyScale.z);

            if (SnowPlatform.lossyScale.x > SnowPlatform.lossyScale.z)
            {
                _camera.rect = new Rect(_camera.rect.x, _camera.rect.y, _camera.rect.width,
                    _camera.rect.height / scale);
            }
                
            else
            {
                _camera.rect = new Rect(_camera.rect.x,_camera.rect.y, _camera.rect.width/ scale,_camera.rect.height);
            }

            
                
        }
        
        Shader.SetGlobalTexture("_GlobalEffectRT", renderTexture);
        Shader.SetGlobalFloat("_OrthographicCamSize", _camera.orthographicSize);
    }

    // Update is called once per frame
    void Update()
    {
        //transform.position = new Vector3(Player.transform.position.x, transform.position.y, Player.transform.position.z);
        Shader.SetGlobalVector("_PlayerPos", Player.position);
        
        /*
         transform.position = new Vector3(target.transform.position.x, transform.position.y, target.transform.position.z);
        Shader.SetGlobalVector("_Position", transform.position);
         */
    }

    float GetSmallest(float x, float z)
    {
        if (x <= z)
            return x;
        return z;
    }
    float GetLargest(float x, float z)
    {
        if (x > z)
            return x;
        return z;
    }
}
