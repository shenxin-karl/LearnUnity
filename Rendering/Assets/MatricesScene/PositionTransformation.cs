using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PositionTransformation : Transformation {
    public Vector3 offset;

    public override Matrix4x4 Matrix {
        get {
            return Matrix4x4.Translate(offset);
        }
    }

    public override Vector3 apply(Vector3 point) {
        return offset + point;
    }
}
