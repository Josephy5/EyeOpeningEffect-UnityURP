![repaiocelohc1](https://github.com/user-attachments/assets/a0ae9d54-8009-4471-8f0c-5b6f11c8b7fe)

# Eye Opening Effect Post Processing
![Unity Version](https://img.shields.io/badge/Unity-6000.0.27%27LTS%2B-blueviolet?logo=unity)
![Unity Pipeline Support (Built-In)](https://img.shields.io/badge/BiRP_❌-darkgreen?logo=unity)
![Unity Pipeline Support (URP)](https://img.shields.io/badge/URP_✔️-blue?logo=unity)
![Unity Pipeline Support (HDRP)](https://img.shields.io/badge/HDRP_❌-darkred?logo=unity)
 
A post processing effect that simulates the look of eyes opening and closing to the camera screen. It was created for Serious Point Games as part of my studies in shader development.
It is designed to run on the Unity URP pipeline and Unity 6 (6000.0.32f1), but theoretically, it could run on Unity 2022 but it is untested. 

You can refer to the effect's documentation for more info (should be in the repo and its release as a PDF file).

## Features
- Cinematic like eye openning in combination with a red tint to simulate light penerating through the skin of the eye lids (aka Subsurface scattering)
- Fully adjustable parameters via volume component
- Support for Unity 6
  
## Example[s]
![repaiocelohc1](https://github.com/user-attachments/assets/a0ae9d54-8009-4471-8f0c-5b6f11c8b7fe)
The eye opening effect in action
<br>

## Installation
1. Clone repo or download the folder and load it into an unity project.
2. Ensure that under the project settings > graphics > Render Graph, you enable Compatibility Mode on (meaning you have Render Graph Disabled).
3. Add the render feature of the effect to the Universal Renderer Data you are using.
4. Create a volume game object and load the effect's volume component in the volume profile to adjust values
5. If needed, you can change the effect's render pass event in its render feature under settings.

## Known Issue
On some surfaces like lightly coloured walls, the blur blending between the player’s view and the eye shape mask may become less apparent or in some cases, not apparent at all.
This is due to the way the effect is coded to be able to blend with the subsurface scattering like simulation, eye mask, and the player’s view effectively. This may not be an issue if the
eye opening effect is used for a very short period of time and to be more of a subtle effect. Other than that, the blending effect is still rendered there but it is just not so apparent.

## Credits/Assets used
No credits yet
