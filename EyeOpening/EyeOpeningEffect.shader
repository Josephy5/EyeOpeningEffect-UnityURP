Shader "Hidden/EyeOpeningEffect"
{
    Properties
    {
        //Main Setting
        _MainTex ("Source Texture", 2D) = "white" {}
        _EyeOpenness ("Eye Openness", Range(0, 1)) = 1
        _EyeWidth ("Eye Width", Range(1, 3)) = 1.5

        //Screen Colors
        _TransitionScreenColor ("Transition Screen Color", Color) = (0, 0, 0, 1)
        _ColorTransitionThreshold ("Color Transition Threshold", Range(0.01, 0.5)) = 0.3
        _ColorTransitionSmoothness ("Color Transition Smoothness", Range(0.01, 0.5)) = 0.1

        //Subsurface Scattering Simulation
        _FleshColor ("Flesh Color", Color) = (0.8, 0.4, 0.3, 1)
        _FleshIntensity ("Flesh Light Intensity", Range(0, 2)) = 0.3
        _ScatteringWidth ("Scattering Width", Range(0.01, 0.5)) = 0.1
        _ScatteringOffset ("Scattering Y Offset", Range(0.7, 1.3)) = 1.0

        //Blur Setting
        _BlurIntensity ("Blur Intensity", Range(0, 3)) = 0.5
        _BlurQuality ("Blur Quality", Range(1, 3)) = 1

        //Transition Setting
        _TransitionThreshold ("Full Vision Transition Threshold", Range(0.7, 0.95)) = 0.85
        _TransitionSmoothness ("Transition Smoothness", Range(0.01, 0.2)) = 0.1
    }

    SubShader
    {
        Tags { 
            "RenderType"="Opaque" 
            "RenderPipeline" = "UniversalPipeline"
            "IgnoreProjector" = "True"
        }
        LOD 0
        ZTest Always
        ZWrite Off
        Cull Off

        Pass
        {
            Name "EyeOpening"

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag

            #pragma multi_compile _ STEREO_INSTANCING_ON
            #pragma multi_compile _ UNITY_SINGLE_PASS_STEREO
            #pragma multi_compile _ STEREO_MULTIVIEW_ON
            #pragma multi_compile _ STEREO_CUBEMAP_RENDER_ON
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            
            // Core parameters
            float _EyeOpenness;
            float _EyeWidth;
            
            // Screen colors
            float4 _ScreenColor;
            float4 _TransitionScreenColor;
            float _ColorTransitionThreshold;
            float _ColorTransitionSmoothness;
            
            // Flesh light parameters
            float4 _FleshColor;
            float _FleshIntensity;
            float _ScatteringWidth;
            float _ScatteringOffset;
            
            // Blur parameters
            float _BlurIntensity;
            float _BlurQuality;
            
            // Transition parameters
            float _TransitionThreshold;
            float _TransitionSmoothness;

            float4 _MainTex_TexelSize;

            Varyings Vert(Attributes input)
            {
                Varyings output;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = input.uv;
                return output;
            }

            float4 SampleBox(float2 uv, float2 texelSize, float offset)
            {
                float4 color = 0;
                float totalWeight = 0;
                
                [unroll]
                for(int x = -1; x <= 1; x++)
                {
                    [unroll]
                    for(int y = -1; y <= 1; y++)
                    {
                        float2 offsetUV = uv + float2(x, y) * texelSize * offset;
                        float weight = 1.0;
                        
                        color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, offsetUV) * weight;
                        totalWeight += weight;
                    }
                }
                
                return color / totalWeight;
            }

            float4 BoxBlur(float2 uv, float intensity)
            {
                float2 texelSize = _MainTex_TexelSize.xy * intensity * 2;
                float4 color = 0;
                
                // Adjust samples based on blur quality
                int samples = ceil(_BlurQuality);
                float stepSize = 1.0 / samples;
                
                [unroll(3)]
                for(int i = 0; i < samples; i++)
                {
                    color += SampleBox(uv, texelSize, (i + 1) * stepSize);
                }
                
                return color / samples;
            }

            float4 GetCurrentScreenColor()
            {
                // Calculate smooth transition between screen colors
                float colorTransition = smoothstep(_ColorTransitionThreshold, 
                                                _ColorTransitionThreshold + _ColorTransitionSmoothness, 
                                                _EyeOpenness);
                return lerp(_ScreenColor, _TransitionScreenColor, colorTransition);
            }

            float GetTransitionFactor(float baseOpenness)
            {
                // Calculate transition factor with power curve for smoother fade
                float transitionProgress = smoothstep(_TransitionThreshold, 
                                                    _TransitionThreshold + _TransitionSmoothness, 
                                                    baseOpenness);
                
                // Apply subtle power curve for more natural transition
                return pow(transitionProgress, 1.2);
            }

            void GetEyelidMasks(float2 uv, out float baseMask, out float scatterMask)
            {
                // Center and scale UV
                float2 adjustedUV = (uv - 0.5) * 2;
                
                // Apply eye width scaling
                adjustedUV.x /= _EyeWidth;
                
                // Get transition factor for smooth fade
                float transitionFactor = GetTransitionFactor(_EyeOpenness);

                // Calculate dynamic height based on eye openness
                float heightScale = lerp(0.0, 1.4, _EyeOpenness);
                adjustedUV.y /= heightScale;               

                // Create elliptical mask
                float mask = length(adjustedUV);
                baseMask = smoothstep(1.0009999, 1.001, mask);
                
                // Apply offset to scattering UV
                float2 scatteringUV = adjustedUV;
                float scatteringMask = length(scatteringUV);

                float clipAdjust = adjustedUV.y > 0 ? _ScatteringOffset : 1.0;
                float scatterStart = (0.95 - _ScatteringWidth) * clipAdjust - 0.25;
                scatterMask = smoothstep(scatterStart, 1.0, scatteringMask);
                
                // Apply smoother transition fade to masks
                float fadeStrength = 1.0 - transitionFactor;
                baseMask *= fadeStrength;
                scatterMask *= fadeStrength;

                // Ensure scattering fades slightly before the base mask
                scatterMask *= smoothstep(1.0, 0.0, transitionFactor * 1.2);

                // old code, ignore below, left here for referall
                // Calculate transition to full vision
                //float fullVisionTransition = smoothstep(_TransitionThreshold, _TransitionThreshold + _TransitionSmoothness, _EyeOpenness);
                
                // Apply full vision transition to both masks
                //baseMask = lerp(baseMask, 0.0, fullVisionTransition);
                //scatterMask = lerp(scatterMask, 0.0, fullVisionTransition);
            }

            float4 Frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);                

                float2 uv = input.uv;
                
                // Get transition factor for effects
                float transitionFactor = GetTransitionFactor(_EyeOpenness);

                // Calculate base scene color with blur based on eye openness
                float blurAmount = (1 - _EyeOpenness) * _BlurIntensity * (1.0 - transitionFactor * 0.7);
                // old code, ignore it, left here for referall
                //float blurAmount = (1 - _EyeOpenness) * _BlurIntensity;
                float4 sceneColor = BoxBlur(uv, blurAmount);
                
                // Get both eyelid masks
                float eyelidMask, scatteringMask;
                GetEyelidMasks(uv, eyelidMask, scatteringMask);

                // Get current screen color based on eye openness
                float4 currentScreenColor = GetCurrentScreenColor();

                // Calculate improved scattering effect with softer transitions
                float scatteringGradient = smoothstep(0, 1.0, (scatteringMask - eyelidMask) / _ScatteringWidth);
                scatteringGradient *= (1.0 - (transitionFactor * 1.1)); // originally, its transitionFactor * 1.0, but slightly increased for faster Fade scattering
                float4 scatteringColor = lerp(currentScreenColor, _FleshColor, scatteringGradient * _FleshIntensity);
                
                // Apply additional blur to the Scattering areas 
                float scatterBlur = BoxBlur(uv, blurAmount * 0.5).rgb;
                scatteringColor.rgb = lerp(scatteringColor.rgb, scatterBlur, 0.3 * (1.0 - transitionFactor));
                // old code, ignore it, left here for referall
                //scatteringColor.rgb = lerp(scatteringColor.rgb, scatterBlur, 0.3);
                
                // Blend scene with scattering and eyelid colors
                float4 finalColor = sceneColor;
                finalColor = lerp(finalColor, scatteringColor, saturate(scatteringMask - eyelidMask));
                finalColor = lerp(finalColor, currentScreenColor, eyelidMask);
                
                return finalColor;
            }
            ENDHLSL
        }
    }
}