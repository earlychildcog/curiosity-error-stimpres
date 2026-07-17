
## about

Codebase for the experimental task "curiosity: error-monitoring" in the preprint "Foundations of human self-reflection: Error-monitoring developmentally predicts the emergence of self-representation" [0]  
It runs a realtime gaze-controlled match-to-sample task for infants (12m-24m) with concurrent eyetracking and EEG acquisition. The participant flips cards by looking at them, and the task is to remember and choose which one of two cards matches a third one.  
Task structure (from the preprint; please refer to the preprint’s methods for more details):  

<img width="1123" height="1123" alt="image" src="https://github.com/user-attachments/assets/31d4bcad-d472-4431-b4bf-ccd2ffade43a" />

## technical details

The script is written in MATLAB and uses Psychtoolbox ([https://psychtoolbox.org/](https://psychtoolbox.org/)) for stimuli presentation and synchronisation of data acquisition [1]. The host computer ran on Linux (Ubuntu 22.04 LTS).  
Equipment used for data acquisition:  

- Eyetracker: Eyelink 1000 plus eyetracker at 500Hz sampling rate, binocular (or monocular)
- EEG system: EGI system at 1000Hz sampling rate, with 128 channel HydroCel Geodesic Net

The script will require modifications to work on different equipment setups. However, we have reused part of the code to run tasks on Windows with a different eyetracker, and we have run part of our troubleshooting on MacOS, so using different OSes should be possible with minimal effort. Otherwise, to start with it, run this in your computer’s terminal:  

```
git clone --recurse-submodules git@github.com:earlychildcog/curiosity-error-stimpres.git  
```

The `--recurse-submodules` flag is needed because the repository requires a second repository [2] in `src/base` which contains generic classes (used across experiments in the lab) from which we derive the task-specific classes.  
To run the experiment, in the MATLAB command line simply run `curiosityE_start` and follow the instructions in the command line. You can use the flag `2` by running `curiosityE_start(2)` to trial run with no eyetracking/eeg and control the experiment with the keyboard.  
Of course, you need MATLAB and Psychtoolbox installed first.  
Note: Requires modification of the Eyelink integration scripts (part of Psychtoolbox) due to legacy/broken audio implementation used. This may have been fixed in newer versions of the toolbox. Refer to `src/base/helperFunctions/eyelink-scripts` for instructions how to make Eyelink toolbox work properly. It may need to be done again when Psychtoolbox is updated, and it may be required even if Eyelink toolbox is upstream fixed if the new version is incompatible.  
We would love for anyone to inspire their own research from our script — you are welcome to adapt it, and we are happy to be contacted for help if you encounter any bugs or issues with it. You can either create a new github issue [here](https://github.com/earlychildcog/curiosity-error-stimpres/issues/new/choose) or look for our contact information (links to github). We will do our best to respond but please be mindful of our time as this project ended and we will be helping you in our free time.  

## authors & contributors

Codebase developed by D. Askitis and C. Gal, implementing the task in [0]. All three coauthors (C. Gal., D. Askitis, & K. Begus) contributed to the iterative refinement and validation of the experimental implementation.  
  
## license & crediting

The software is provided as-is, and is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).  
If you use this software in academic work, please credit our work by citing it [0].  
  
---

[0] Gal, C., Askitis, D., & Begus, K. (2026). Foundations of human self-reflection: Error-monitoring developmentally predicts the emergence of self-representation. bioRxiv 2026.02.01.702903; [https://doi.org/10.64898/2026.02.01.702903](https://doi.org/10.64898/2026.02.01.702903)  
[1] Software versions will be added here soon  
[2] [https://github.com/earlychildcog/yapwrap](https://github.com/earlychildcog/yapwrap)
