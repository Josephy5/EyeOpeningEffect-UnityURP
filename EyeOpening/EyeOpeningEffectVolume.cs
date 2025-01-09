using System.Collections;
using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[Serializable, VolumeComponentMenu("Eye Opening Effect")]
public class EyeOpeningEffectVolume : VolumeComponent, IPostProcessComponent
{
    [Header("Main Settings")]
    public FloatParameter _EyeOpenness = new ClampedFloatParameter(1f, 0f, 1f, true);
    public FloatParameter _EyeWidth = new ClampedFloatParameter(1.45f, 1f, 3f, true);

    [Header("Screen & Scattering Transition Setting")]
    public ColorParameter _ScreenColor = new ColorParameter(Color.black, true);
    public ColorParameter _ScatteringTransitionScreenColor = new ColorParameter(new Color(0.094f, 0.0156f, 0.0156f), true);
    public FloatParameter _ScatteringTransitionThreshold = new ClampedFloatParameter(0.15f, 0.01f, 0.5f, true);
    public FloatParameter _ScatteringTransitionSmoothness = new ClampedFloatParameter(0.42f, 0.01f, 0.5f, true);

    [Header("Subsurface Scattering Settings")]
    public ColorParameter _ScatteringColor = new ColorParameter(new Color(0.8f, 0.4f, 0.3f), true);
    public FloatParameter _ScatteringIntensity = new ClampedFloatParameter(0.011f, 0f, 2f, true);
    public FloatParameter _ScatteringWidth = new ClampedFloatParameter(0.15f, 0.01f, 0.5f, true);
    public FloatParameter _ScatteringOffset = new ClampedFloatParameter(1f, 0.7f, 1.3f, true);

    [Header("Blur Settings")]
    public FloatParameter _BlurIntensity = new ClampedFloatParameter(2f, 0f, 5f, true);
    public ClampedIntParameter _BlurQuality = new ClampedIntParameter(1, 1, 3, true);

    [Header("Fade Out Transition Settings")]
    public FloatParameter _FadeOutTransitionThreshold = new ClampedFloatParameter(0.9f, 0.7f, 0.95f, true);
    public FloatParameter _FadeOutTransitionSmoothness = new ClampedFloatParameter(0.1f, 0.01f, 0.2f, true);

    //set the parameters for the render pass's material
    public void load(Material material)
    {
        // Core parameters
        material.SetFloat("_EyeOpenness", _EyeOpenness.value);
        material.SetFloat("_EyeWidth", _EyeWidth.value);

        // Screen colors
        material.SetColor("_ScreenColor", _ScreenColor.value);
        material.SetColor("_TransitionScreenColor", _ScatteringTransitionScreenColor.value);
        material.SetFloat("_ColorTransitionThreshold", _ScatteringTransitionThreshold.value);
        material.SetFloat("_ColorTransitionSmoothness", _ScatteringTransitionSmoothness.value);

        // Flesh light parameters
        material.SetColor("_FleshColor", _ScatteringColor.value);
        material.SetFloat("_FleshIntensity", _ScatteringIntensity.value);
        material.SetFloat("_ScatteringWidth", _ScatteringWidth.value);
        material.SetFloat("_ScatteringOffset", _ScatteringOffset.value);

        // Blur parameters
        material.SetFloat("_BlurIntensity", _BlurIntensity.value);
        material.SetFloat("_BlurQuality", _BlurQuality.value);

        // Transition parameters
        material.SetFloat("_TransitionThreshold", _FadeOutTransitionThreshold.value);
        material.SetFloat("_TransitionSmoothness", _FadeOutTransitionSmoothness.value);
    }

    public bool IsActive() => true;
    public bool IsTileCompatible() => false;
}