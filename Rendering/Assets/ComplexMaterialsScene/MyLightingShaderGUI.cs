
using System;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using Object = UnityEngine.Object;

public class MyLightingShaderGUI : ShaderGUI {
    enum SmoothnessSource {
        None                      = 0,
        AlbedoTextureSource_A     = 1,
        MetallicTextureSource_A   = 2,
        SmoothnessTextureSource_R = 3,
    };
    enum OcclusionSource {
        OcclusionTextureSource_R = 0,
        MetallicTextureSource_G  = 1,
    };

    enum RenderingMode {
        Opaque      = 0,
        AlphaTest   = 1,
        Transparent = 2,
    };

    struct RenderingSettings {
        public RenderQueue queue;
        public string renderType;

        public static RenderingSettings[] modes = {
            new RenderingSettings() {
                queue = RenderQueue.Geometry,
                renderType = "",
            },
            new RenderingSettings() {
                queue = RenderQueue.AlphaTest,
                renderType = "TransparentCutout",
            },
            new RenderingSettings() {
                queue = RenderQueue.Transparent,
                renderType = "Transparent",
            }
        };
    };
    
    Object[] _targets;
    MaterialEditor _editor;
    MaterialProperty[] _properties;
    bool _shouldShowAlphaCutoff = false;
    
    private static readonly string AlbedoMapKeyword = "_ALBEDO_MAP";
    private static readonly string NormalMapKeyword = "_NORMAL_MAP";
    private static readonly string MetallicMapKeyword = "_METALLIC_MAP";
    private static readonly string SmoothnessMapKeyword = "_SMOOTHNESS_MAP";
    private static readonly string DetailAlbedoMapKeyWord = "_DETAIL_ALBEDO_MAP";
    private static readonly string DetailNormalMapKeyWord = "_DETAIL_NORMAL_MAP";
    private static readonly string DetailMaskMapKeyWord = "_DETAIL_MASK_MAP";
    private static readonly string EmissionMapKeyWord = "_EMISSION_MAP";
    private static readonly string OcclusionMapKeyWord = "_OCCLUSION_MAP";
    private static readonly string RenderingModeAlphaTestKeyWord = "_RENDERING_MODE_ALPHA_TEST";
    private static readonly string RenderingModeTransparentKeyWord = "_RENDERING_MODE_TRANSPARENT";
    
    private static readonly string SmoothnessSourceKeyWord = "_SMOOTHNESS_SOURCE";
    private static readonly string SmoothnessAlbedoSourceKeyWord = "_SMOOTHNESS_ALBEDO_SOURCE";
    private static readonly string SmoothnessMetallicSourceKeyWord = "_SMOOTHNESS_METALLIC_SOURCE";
    
    private static readonly string OcclusionSourceKeyWord = "_OCCLUSTION_SOURCE";
    private static readonly string OcclusionMetallicSourceKeyWord = "_OCCLUSTION_METALLIC_SOURCE";
    
    private static readonly ColorPickerHDRConfig emissionConfig =  new ColorPickerHDRConfig(0f, 99f, 1f / 99f, 3f);
    
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties) {
        this._targets = materialEditor.targets;
        this._editor = materialEditor; 
        this._properties = properties;
        doRenderingMode();
        doMain();
        doSecondary();
    }

    private void doRenderingMode() {
        RenderingMode mode = RenderingMode.Opaque;
        if (isKeyWordEnable(RenderingModeAlphaTestKeyWord))
            mode = RenderingMode.AlphaTest;
        else if (isKeyWordEnable(RenderingModeTransparentKeyWord))
            mode = RenderingMode.Transparent;
        
        EditorGUI.BeginChangeCheck();
        mode = (RenderingMode)EditorGUILayout.EnumPopup(makeLabel("Rendering Mode"), mode);
        _shouldShowAlphaCutoff = (mode == RenderingMode.AlphaTest);
        if (EditorGUI.EndChangeCheck()) {   
            recordAction("Rendering Mode");
            setKeyWord(RenderingModeAlphaTestKeyWord, mode == RenderingMode.AlphaTest);
            setKeyWord(RenderingModeTransparentKeyWord, mode == RenderingMode.Transparent);
            RenderingSettings settings = RenderingSettings.modes[(int)mode];
            foreach (Object o in _targets) {
                Material m = (Material)o;
                m.renderQueue = (int)settings.queue;
                m.SetOverrideTag("RenderType", settings.renderType);
            }
        } 
    }

    void doNormal() {
        MaterialProperty normalTex = findProperty("_NormalTex");
        MaterialProperty bumpScale = findProperty("_BumpScale");
        EditorGUI.BeginChangeCheck();
        {
            _editor.TexturePropertySingleLine(
                makeLabel("Normal", "Albedo(RGB)"), 
                normalTex, 
                normalTex.textureValue ? bumpScale : null
            );
        }
        if (EditorGUI.EndChangeCheck())
            setKeyWord(NormalMapKeyword, normalTex.textureValue);
    }

    void doMetallic() {
        MaterialProperty metallicTex = findProperty("_MetallicTex");
        MaterialProperty slider = findProperty("_Metallic");
        EditorGUI.BeginChangeCheck();
        {
            _editor.TexturePropertySingleLine(
                makeLabel("Metallic", "Metallic(R)"),
                metallicTex,
                slider
            );
        }
        if (EditorGUI.EndChangeCheck())
            setKeyWord(MetallicMapKeyword, metallicTex.textureValue);
    }

    void doSmoothness() {
        MaterialProperty smoothnessTex = findProperty("_SmoothnessTex");
        MaterialProperty slider = findProperty("_Smoothness");
        EditorGUI.BeginChangeCheck();
        {
            _editor.TexturePropertySingleLine(
                makeLabel("Smoothness", "Smoothness(R)"),
                smoothnessTex,
                slider
            );
        }
        if (EditorGUI.EndChangeCheck())
            setKeyWord(SmoothnessMapKeyword, smoothnessTex.textureValue);

        SmoothnessSource source = SmoothnessSource.None;
        if (isKeyWordEnable(SmoothnessAlbedoSourceKeyWord))
            source = SmoothnessSource.AlbedoTextureSource_A;
        else if (isKeyWordEnable(SmoothnessMetallicSourceKeyWord))
            source = SmoothnessSource.MetallicTextureSource_A;
        else if (isKeyWordEnable(SmoothnessSourceKeyWord))
            source = SmoothnessSource.SmoothnessTextureSource_R;
        
        EditorGUI.BeginChangeCheck();
        EditorGUI.indentLevel += 3;
        source = (SmoothnessSource)EditorGUILayout.EnumPopup(makeLabel("Source"), source);
        EditorGUI.indentLevel -= 3;
        if (EditorGUI.EndChangeCheck()) {
            recordAction("SmoothnessSource");
            setKeyWord(SmoothnessAlbedoSourceKeyWord, source == SmoothnessSource.AlbedoTextureSource_A);
            setKeyWord(SmoothnessMetallicSourceKeyWord, source == SmoothnessSource.MetallicTextureSource_A);
            setKeyWord(SmoothnessSourceKeyWord, source == SmoothnessSource.SmoothnessTextureSource_R);
        }
    }
    
    void doEmission() {
        MaterialProperty emissionTex = findProperty("_EmissionTex");
        MaterialProperty emissionColor = findProperty("_EmissionColor");
        EditorGUI.BeginChangeCheck();
        {
            _editor.TexturePropertyWithHDRColor(
                makeLabel("Emission", "Emission(RGB)"),
                emissionTex,
                emissionColor,
                emissionConfig,
                false
            );
        }
        if (EditorGUI.EndChangeCheck())
            setKeyWord(EmissionMapKeyWord, (bool)emissionTex.textureValue);
    }
    
    private void doOcclusion() {
        MaterialProperty occlusionTex = findProperty("_OcclusionTex");
        MaterialProperty occlusionStrength = findProperty("_OcclusionStrength");
        EditorGUI.BeginChangeCheck();
        _editor.TexturePropertySingleLine(
            makeLabel("Occlusion", "Occlusion(G)"), 
            occlusionTex,
            occlusionTex.textureValue ? occlusionStrength : null
        );
        if (EditorGUI.EndChangeCheck())
            setKeyWord(OcclusionMapKeyWord, occlusionTex.textureValue);


        OcclusionSource source = isKeyWordEnable(OcclusionMetallicSourceKeyWord)
            ? OcclusionSource.MetallicTextureSource_G
            : OcclusionSource.OcclusionTextureSource_R;
        EditorGUI.indentLevel += 3;
        source = (OcclusionSource)EditorGUILayout.EnumPopup(makeLabel("Source"), source);
        EditorGUI.indentLevel -= 3;
        
        setKeyWord(OcclusionSourceKeyWord, false);
        setKeyWord(OcclusionMetallicSourceKeyWord, false);
        if (source == OcclusionSource.OcclusionTextureSource_R) 
            setKeyWord(OcclusionSourceKeyWord, true);
        else 
            setKeyWord(OcclusionMetallicSourceKeyWord, true);
    }

    void doMain() {
        GUILayout.Label("Main Maps", EditorStyles.boldLabel);
        MaterialProperty albedoTex = findProperty("_AlbedoTex");
        MaterialProperty diffuseAlbedo = findProperty("_DiffuseAlbedo");
        EditorGUI.BeginChangeCheck();
        {
            _editor.TexturePropertySingleLine(makeLabel("Albedo", "Albedo(RGB)"), albedoTex, diffuseAlbedo);
        }
        if (EditorGUI.EndChangeCheck())
            setKeyWord(AlbedoMapKeyword, albedoTex.textureValue);
        doAlphaCutoff();
        doMetallic();
        doSmoothness();
        doNormal();
        doOcclusion();
        doEmission();
        EditorGUI.indentLevel += 2;
        _editor.TextureScaleOffsetProperty(albedoTex);
        EditorGUI.indentLevel -= 2;
    }

    private void doAlphaCutoff() {
        if (!_shouldShowAlphaCutoff)
            return;
        MaterialProperty alphaCutoffSlider = findProperty("_AlphaCutoff");
        EditorGUI.indentLevel += 2;
        _editor.ShaderProperty(alphaCutoffSlider, makeLabel("AlphaCutoff"));
        EditorGUI.indentLevel -= 2;

    }

    void doSecondaryNormal() {
        MaterialProperty detailNormalTex = findProperty("_DetailNormalTex");
        MaterialProperty detailNormalScale = findProperty("_DetailNormalScale");
        EditorGUI.BeginChangeCheck();
        {
            _editor.TexturePropertySingleLine(
                makeLabel("DetailNormal"),
                detailNormalTex,
                detailNormalTex.textureValue ? detailNormalScale : null
            );
        }
        if (EditorGUI.EndChangeCheck())
            setKeyWord(DetailNormalMapKeyWord, detailNormalTex.textureValue);
    }
    
    private void doSecondaryDetailMask() {
        MaterialProperty detailMaskTex = findProperty("_DetailMaskTex");
        EditorGUI.BeginChangeCheck();
        {
            _editor.TexturePropertySingleLine(
                makeLabel("DetailMask", "Mask(A)"),
                detailMaskTex
            );
        }
        if (EditorGUI.EndChangeCheck())
            setKeyWord(DetailMaskMapKeyWord, detailMaskTex.textureValue);
    }
    
    void doSecondary() {
        GUILayout.Label("Secondary Maps", EditorStyles.boldLabel);
        MaterialProperty detailAlbedoTex = findProperty("_DetailAlbedoTex");
        EditorGUI.BeginChangeCheck();
        {
            _editor.TexturePropertySingleLine(makeLabel("DetailAlbedo", "Albedo(RGB) multiplied by 2"), detailAlbedoTex);
        }
        if (EditorGUI.EndChangeCheck())
            setKeyWord(DetailAlbedoMapKeyWord, detailAlbedoTex.textureValue);
        doSecondaryNormal();
        doSecondaryDetailMask();
        EditorGUI.indentLevel += 2;
        _editor.TextureScaleOffsetProperty(detailAlbedoTex);
        EditorGUI.indentLevel -= 2;
    }
    
    MaterialProperty findProperty(string name) {
        return FindProperty(name, _properties);
    }

    void setKeyWord(string keyWord, bool state) {
        if (state) {
            foreach (Material m in _targets)
                m.EnableKeyword(keyWord);    
        } else {
            foreach (Material m in _targets)
                m.DisableKeyword(keyWord);
        }
    }
    
    bool isKeyWordEnable(string keyword) {
        if (_targets.Length == 0)
            return false;
        
        Material m = _targets[0] as Material;
        return m.IsKeywordEnabled(keyword);
    }

    void recordAction(string label) {
        _editor.RegisterPropertyChangeUndo(label);
    }
    
    static readonly GUIContent staticLabel = new GUIContent();

    static GUIContent makeLabel(string text, string tooltip = null) {
        staticLabel.text = text;
        staticLabel.tooltip = tooltip;
        return staticLabel;
    }
}