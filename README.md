# Glaser et al., 2024
Capture-HiC analysis for the manuscript: "Enhancer adoption by an LTR retrotransposon
generates viral-like particles causing developmental limb phenotypes" (Glaser et al., 2024) 
  See the preprint [here](https://www.biorxiv.org/content/10.1101/2024.09.13.612906v1.full.pdf)
  
---

## Overview
- Code to process & analyze cHiC data to characterize long-range interactions at the Fgf8 locus with/without insertion of Dac1J, a retrotransposon, and how that might relate to developmental limb malformations. 
- Data processing was done by combining the [HiCUP](https://www.bioinformatics.babraham.ac.uk/projects/hicup/read_the_docs/html/index.html) pipeline to handle chimeric fragments and [Juicer](https://github.com/aidenlab/juicer) for the generation of interaction matrices. This workflow is provided as a snakemake pipeline (see `Snakefile`), which is dependent on several helper scripts under `00scripts/`. 
- Data visualization of interaction matrices as heatmap was done using the plotting utlities provided by [FAN-C](https://vaquerizaslab.github.io/fanc/fanc.html). Analysis of changes in 3D interactions was done by matrice substraction between insertions - WT and visualized as a differential heatmap. 
- All visualization code is provided in the notebook `plotHic.ipynb`. 