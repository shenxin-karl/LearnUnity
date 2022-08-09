using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor.Experimental.GraphView;
using UnityEngine;

[ExecuteInEditMode]
public class DeferredFogEffect : MonoBehaviour {
    public Shader deferredFog;

    [NonSerialized] private Material _fogMaterial;
    [NonSerialized] private Camera _deferredCamera;
    [NonSerialized] private Vector3[] _frustumCorners;
    [NonSerialized] private Vector4[] _vectorArray;
    
    [ImageEffectOpaque]         
    private void OnRenderImage(RenderTexture src, RenderTexture dest) {
        if (_fogMaterial == null) {
            _deferredCamera = GetComponent<Camera>();
            _fogMaterial = new Material(deferredFog);
            _frustumCorners = new Vector3[4];
            _vectorArray = new Vector4[4];
        }
        
        // 这里获取到的 _frustumCorners 为: 左下, 左上, 右上, 右下
        _deferredCamera.CalculateFrustumCorners(
            new Rect(0, 0, 1, 1),
            _deferredCamera.farClipPlane,
            _deferredCamera.stereoActiveEye,
            _frustumCorners
        );

        // 渲染的四边形为: 左下，右下，左上，右上
        _vectorArray[0] = _frustumCorners[0];
        _vectorArray[1] = _frustumCorners[3];
        _vectorArray[2] = _frustumCorners[1];
        _vectorArray[3] = _frustumCorners[2];
        _fogMaterial.SetVectorArray("_FrustumCorners", _vectorArray);
        Graphics.Blit(src, dest, _fogMaterial);
    }
}
