
using UnityEditor;
using UnityEngine;

public class MyLightingShaderGUI : ShaderGUI {
    Material target;
    MaterialEditor editor;
    MaterialProperty[] properties;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties) {
        this.target = materialEditor.target as Material;
        this.editor = materialEditor; 
        this.properties = properties;
        doMain();
        doSecondary();
    }

    void doNormal() {
        MaterialProperty normalTex = findProperty("_NormalTex");
        MaterialProperty bumpSacle = findProperty("_BumpScale");
        editor.TexturePropertySingleLine(
            makeLabel("Normal", "Albedo(RGB)"), 
            normalTex, 
            normalTex.textureValue ? bumpSacle : null
        );
    }

    void doMetallic() {
        MaterialProperty metallicTex = findProperty("_MetallicTex");
        MaterialProperty slider = findProperty("_Metallic");
        editor.TexturePropertySingleLine(
            makeLabel("Metallic", "Metallic(R)"),
            metallicTex,
            slider
        );
    }

    void doSmoothness() {
        MaterialProperty smoothnessTex = findProperty("_SmoothnessTex");
        MaterialProperty slider = findProperty("_Smoothness");
        editor.TexturePropertySingleLine(
            makeLabel("Smoothness", "Metallic(R)"),
            smoothnessTex,
            slider
        );
    }

    void doMain() {
        GUILayout.Label("Main Maps", EditorStyles.boldLabel);
        MaterialProperty albedoTex = findProperty("_AlbedoTex");
        MaterialProperty diffuseAlbedo = findProperty("_DiffuseAlbedo");
        editor.TexturePropertySingleLine(makeLabel("Albedo", "Albedo(RGB)"), albedoTex, diffuseAlbedo);
        doMetallic();
        doSmoothness();
        doNormal();
        EditorGUI.indentLevel += 2;
        editor.TextureScaleOffsetProperty(albedoTex);
        EditorGUI.indentLevel -= 2;
    }

    void doSecondaryNormal() {
        MaterialProperty detailNormalTex = findProperty("_DetailNormalTex");
        MaterialProperty detailNormalScale = findProperty("_DetailNormalScale");
        editor.TexturePropertySingleLine(
            makeLabel("DetailNormal"),
            detailNormalTex,
            detailNormalTex.textureValue ? detailNormalScale : null
        );
    }
    void doSecondary() {
        GUILayout.Label("Secondary Maps", EditorStyles.boldLabel);
        MaterialProperty detailAlbedoTex = findProperty("_DetailAlbedoTex");
        editor.TexturePropertySingleLine(makeLabel("DetailAlbedo", "Albedo(RGB) multiplied by 2"), detailAlbedoTex);
        doSecondaryNormal();
        EditorGUI.indentLevel += 2;
        editor.TextureScaleOffsetProperty(detailAlbedoTex);
        EditorGUI.indentLevel -= 2;
    }

    MaterialProperty findProperty(string name) {
        return FindProperty(name, properties);
    }

    void setKeyWord(string keyWord, bool state) {
        if (state)
            target.EnableKeyword(keyWord);
        else
            target.DisableKeyword(keyWord);
    }

    static GUIContent staticLabel = new GUIContent();

    static GUIContent makeLabel(string text, string tooltip = null) {
        staticLabel.text = text;
        staticLabel.tooltip = tooltip;
        return staticLabel;
    }
}