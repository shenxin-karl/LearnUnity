using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShowNormalAndTangentScript : MonoBehaviour {
    public float offset = 0.01f;
    public float scale = 0.2f;
    public bool isShowNormal = true;
    public bool isShowTangent = true;
    public bool isShowBitangent = false;

    private void OnDrawGizmos() {
        MeshFilter meshFilter = GetComponent<MeshFilter>();
        if (meshFilter != null && meshFilter.sharedMesh)
            ShaowNormalAndTangent(meshFilter.sharedMesh);
    }

    private void ShaowNormalAndTangent(Mesh mesh) {
        if (!isShowNormal && !isShowTangent && !isShowBitangent)
            return;

        Vector3[] vertices = mesh.vertices;
        Vector3[] normals = mesh.normals;
        Vector4[] tangents = mesh.tangents;
        Transform transform = GetComponent<Transform>();
        for (int i = 0; i < vertices.Length; i++) {
            ShaowNormalAndTangent(
                transform.TransformPoint(vertices[i]),
                transform.TransformDirection(normals[i]), 
                transform.TransformVector(tangents[i]),
                tangents[i].w
            );
        }

    }

    private void ShaowNormalAndTangent(Vector3 position, Vector3 normal, Vector3 tangent, float tangentW) {
        normal = Vector3.Normalize(normal);
        tangent = Vector3.Normalize(tangent);
        position += (normal * offset);
        if (isShowTangent) {
            Gizmos.color = Color.red;
            Gizmos.DrawLine(position, position + (tangent * scale));
        }
        if (isShowNormal) {
            Gizmos.color = Color.green;
            Gizmos.DrawLine(position, position + (normal * scale));
        }
        if (isShowBitangent) {
            Vector3 bitangent = Vector3.Cross(normal, tangent) * tangentW;
            Gizmos.color = Color.blue;
            Gizmos.DrawLine(position, position + (bitangent * scale));
        }
    }
}
