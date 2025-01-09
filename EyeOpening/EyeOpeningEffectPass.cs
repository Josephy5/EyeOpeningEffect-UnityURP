using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

//render pass code for the transition effect
public class EyeOpeningEffectPass : ScriptableRenderPass
{
    static readonly string renderPassTag = "Eye Opening Effect";

    private static EyeOpeningEffectVolume eyeOpeningEffectVolume;
    //material containing the shader
    private static Material eyeOpeningEffectMaterial;

    private static ProfilingSampler ProfilingSampler;

    //If user wants the fog to be viewable in scene view
    bool showInSceneView = false;

    //initializes our variables
    public EyeOpeningEffectPass(RenderPassEvent evt, Shader shader, bool val)
    {
        renderPassEvent = evt;
        if (shader == null)
        {
            Debug.LogError("No Shader");
            return;
        }
        //to make profiling easier
        ProfilingSampler = new ProfilingSampler(renderPassTag);
        eyeOpeningEffectMaterial = CoreUtils.CreateEngineMaterial(shader);
        showInSceneView = val;
    }
    //where our rendering of the effect starts
    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        if (eyeOpeningEffectMaterial == null)
        {
            Debug.LogError("No Eye Opening Effect Material");
            return;
        }
        //in case if the camera doesn't have the post process option enabled and if the camera is not the game's camera
        if (renderingData.cameraData.cameraType != CameraType.Game && (showInSceneView == false && renderingData.cameraData.cameraType == CameraType.SceneView))
        {
            return;
        }

        VolumeStack stack = VolumeManager.instance.stack;
        eyeOpeningEffectVolume = stack.GetComponent<EyeOpeningEffectVolume>();

        var cmd = CommandBufferPool.Get(renderPassTag);
        Render(cmd, ref renderingData);

        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();

        CommandBufferPool.Release(cmd);
    }

    //helper method to contain all of our rendering code for the Execute() method
    void Render(CommandBuffer cmd, ref RenderingData renderingData)
    {
        //we handle the setting the shader's material's parameters/variables in the transition volume script instead of here
        if (eyeOpeningEffectVolume.IsActive() == false) return;
        eyeOpeningEffectVolume.load(eyeOpeningEffectMaterial);

        //for profiling
        using (new ProfilingScope(cmd, ProfilingSampler))
        {
            var src = renderingData.cameraData.renderer.cameraColorTargetHandle;

            int width = renderingData.cameraData.cameraTargetDescriptor.width;
            int height = renderingData.cameraData.cameraTargetDescriptor.height;

            var tempColorTexture = RenderTexture.GetTemporary(width, height, 0, RenderTextureFormat.ARGB32);

            //actual rendering code
            cmd.Blit(src, tempColorTexture, eyeOpeningEffectMaterial, 0);
            cmd.Blit(tempColorTexture, src);

            RenderTexture.ReleaseTemporary(tempColorTexture);
        }
    }
}