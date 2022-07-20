using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RotateTransformation : Transformation {
    public Vector3 rotate;

    public override Matrix4x4 Matrix {
        get {
            return Matrix4x4.Rotate(Quaternion.Euler(rotate.x, rotate.y, rotate.z));   
        }
    }

    public override Vector3 apply(Vector3 point) {
        Quaternion q = Quaternion.Euler(rotate.x, rotate.y, rotate.z);
        point = q * point; 
        return point;
    }
}
