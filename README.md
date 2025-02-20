# Analysis of Calcium Imaging Output for Fear Learning Paradigm
All functions needed for Fear Learning analysis of Calcium Imaging Data

*Before Starting with the Analysis you have to deconvolute all the videos*

**Pipeline of the Analysis**
1. GraphTraces: to check the quality of your deconvoluted videos and eventually remove wrongly identified neurons;
2. DataPreparation: to compute the variable Experiment, which will be used for the rest of the steps;
3. FluorescenceAnalysis: to analyze the fluorescent traces of all your neurons;
4. Tunning: to analyze the responsiveness of the neurons to the different stimuli (ex. tones or shocks).

The pipeline needs to be performed for every session of your experiment (ex. FA, FE1, ...).
