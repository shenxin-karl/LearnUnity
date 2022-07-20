using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ScaleTransformation : Transformation {
    public Vector3 scale = Vector3.one;

    public override Matrix4x4 Matrix {
		get {
			return Matrix4x4.Scale(scale);
		}
	}

    public override Vector3 apply(Vector3 point) {
		point.x *= scale.x;
		point.y *= scale.y;
		point.z *= scale.z;
		return point;
	}
}
