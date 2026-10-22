# MTag-SDM-Geotechnical-Monitoring

Overview

This repository provides selected experimental and numerical datasets supporting the study:

Towards Non-Contact Monitoring of Internal Deformation in Geotechnical Structures Using Magnetic Tag Localization

The shared materials support inspection and verification of the reported experimental findings and selected numerical analyses.

Repository Contents

experimental_data/

Experimental data comparing vision-based tracking (VT) and magnetic-tag localization (MT).

trajectory_tracking/: Uniaxial and incremental displacement trajectories.

cyclic_tracking/: Time-domain cyclic responses and corresponding frequency spectra under unreinforced and reinforced conditions.

static_positioning/: Three-dimensional static positioning series under air, unreinforced sand, and different reinforcement configurations.

numerical_data/

Selected numerical results from finite-element method (FEM) analyses.

fem_experiment_comparison/: Experimental and FEM magnetic-field data, sensor coordinates, comparison metrics, and supporting MATLAB post-processing code.

reinforcement_effects/: Selected numerical results examining reinforcement configurations and their effects on magnetic fields and localization.

numerical_sensitivity/: Selected mesh, computational-domain, and material-parameter sensitivity results.

slope_example/: Selected numerical results from the slope-scale forward analysis.

Numerical data are provided primarily in CSV format. Column names include units where applicable, and condition labels are standardized across datasets.

Reproducibility Scope

The released experimental datasets support inspection and quantitative analysis of the reported tracking results. The FEM–experiment magnetic-field comparison metrics can be recomputed from the released datasets using the provided MATLAB script.

Other numerical datasets are provided as selected result tables for inspection and comparison with the manuscript.

Usage and Citation

Please cite the associated manuscript when using these datasets.

Contact

For questions regarding the datasets, please contact the corresponding author using the contact information provided in the manuscript.
