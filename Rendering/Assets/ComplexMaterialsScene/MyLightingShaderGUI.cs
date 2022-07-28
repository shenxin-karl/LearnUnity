
using UnityEditor;
using UnityEngine;

public class MyLightingShaderGUI : ShaderGUI {
    MaterialEditor editor;
    MaterialProperty[] properties;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties) {
        this.editor = materialEditor; 
        this.properties = properties;
        doMain();
    }

    void doNormal() {
        MaterialProperty normalTex = findProperty("_NormalTex");
        MaterialProperty bumpSacle = findProperty("_BumpScale");
        editor.TexturePropertySingleLine(
            makeLabel(normalTex.displayName, "Albedo(RGB)"), 
            normalTex, 
            normalTex.textureValue ? bumpSacle : null
        );
    }

    void doMetallic() {
        MaterialProperty slider = findProperty("_Metallic");
        EditorGUI.indentLevel += 2;
        editor.ShaderProperty(slider, makeLabel(slider.displayName));
        EditorGUI.indentLevel -= 2;
    }

    void doSmoothness() {
        MaterialProperty slider = findProperty("_Smoothness");
        EditorGUI.indentLevel += 2;
        editor.ShaderProperty(slider, makeLabel(slider.displayName));
        EditorGUI.indentLevel -= 2;
    }


    void doMain() {
        GUILayout.Label("Main Maps", EditorStyles.boldLabel);
        MaterialProperty albedoTex = findProperty("_AlbedoTex");
        MaterialProperty diffuseAlbedo = findProperty("_DiffuseAlbedo");
        editor.TexturePropertySingleLine(makeLabel(albedoTex.displayName, "Albedo(RGB)"), albedoTex, diffuseAlbedo);
        doMetallic();
        doSmoothness();
        doNormal();
        editor.TextureScaleOffsetProperty(albedoTex);
    }

    MaterialProperty findProperty(string name) {
        return FindProperty(name, properties);
    }

    static GUIContent staticLabel = new GUIContent();

    static GUIContent makeLabel(string text, string tooltip = null) {
        staticLabel.text = text;
        staticLabel.tooltip = tooltip;
        return staticLabel;
    }
}