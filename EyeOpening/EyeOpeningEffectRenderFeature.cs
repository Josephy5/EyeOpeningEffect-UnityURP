using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class EyeOpeningEffectRenderFeature : ScriptableRendererFeature
{
    //initialzing the render feature settings
    [System.Serializable]
    public class Settings
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing;
        //the transition shader, will automatically be assigned
        public Shader shader;
        //having the effect on for scene view can be annoying, so by default its off, you can turn it on if you want it on
        public bool showInSceneView = false;
    }
    public Settings settings = new Settings();

    EyeOpeningEffectPass m_EyeOpeningEffectPass;

    //When render feature object is enabled, set the shader
    private void OnEnable()
    {
        settings.shader = Shader.Find("Hidden/EyeOpeningEffect");
    }
    //sets the hatching's render pass up
    public override void Create()
    {
        this.name = "Eye Opening Effect Pass";
        if (settings.shader == null)
        {
            Debug.LogWarning("No EyeOpeningEffect Shader");
            return;
        }
        m_EyeOpeningEffectPass = new EyeOpeningEffectPass(settings.renderPassEvent, settings.shader, settings.showInSceneView);
    }

    //call and adds the hatching render pass to the scriptable renderer's queue
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_EyeOpeningEffectPass);
    }
}