using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TransformationGrid : MonoBehaviour
{
    public Transform prefab;
    public int gridResolution = 10;
    public bool useMatrix = true;
    Transform[] grid;
    List<Transformation> transformations;

    private void Awake() {
        transformations = new List<Transformation>();
        grid = new Transform[gridResolution * gridResolution * gridResolution];
        int index = 0; 
        for (int z = 0; z < gridResolution; ++z) {
            for (int y = 0; y < gridResolution; ++y) {
                for (int x = 0; x < gridResolution; ++x) {
                    grid[index] = CreateGridPoint(x, y, z);
                    ++index;
                }
            }
        }
    }

    private Transform CreateGridPoint(int x, int y, int z) {
        Transform point = Instantiate<Transform>(prefab);
        point.localPosition = GetCoordinates(x, y, z);
        point.GetComponent<MeshRenderer>().material.color = new Color(
            (float)x / gridResolution,
            (float)y / gridResolution,
            (float)z / gridResolution
        );
        return point;
    }

    private Vector3 GetCoordinates(int x, int y, int z) {
        return new Vector3(
               x - (gridResolution - 1) * 0.5f,
               y - (gridResolution - 1) * 0.5f,
               z - (gridResolution - 1) * 0.5f 
        );
    }

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update() {
        GetComponents<Transformation>(transformations);
        for (int i = 0, z = 0; z < gridResolution; z++) {
            for (int y = 0; y < gridResolution; y++) {
                for (int x = 0; x < gridResolution; x++, i++) {
                    if (useMatrix)
                        grid[i].localPosition = TransformPointByMatrix(x, y, z);
                    else
                        grid[i].localPosition = TransformPoint(x, y, z);
                }
            }
        }
    }

    private Vector3 TransformPoint(int x, int y, int z) {
        Vector3 coordinates = GetCoordinates(x, y, z);
        for (int i = 0; i < transformations.Count; i++)
            coordinates = transformations[i].apply(coordinates);
        return coordinates;
    }

    private Vector3 TransformPointByMatrix(int x, int y, int z) {
        Vector3 coordinates = GetCoordinates(x, y, z);
        Matrix4x4 trans = Matrix4x4.identity;
        for (int i = 0; i < transformations.Count; i++)
            trans = transformations[i].Matrix * trans;          // ... trans * coordinates
        return trans.MultiplyPoint(coordinates);

    }
}
