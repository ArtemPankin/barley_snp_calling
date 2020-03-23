# Pipelines for generating high-quality VSQR filtered SNP and INDEL calls

### bash pileine + snakemake pipeline

## BASH pipeline (requires LSF/bsub job management system)

### step 1 - run launch_filtering_mapping.sh - runs the initial checks and launches filtering_mapping_rawcalling.bsub (requires LSF system)
### step 2 - after all the bsub jobs are finished, run merge_UG.sh and genotypegvcf.sh
### step 3 - run ug_genotyping.bsub (requires LSF system)
### step 4 - after all bsub jobs are finished, run merge_UG1.sh
### step 5 - run filtering_vsqr.sh
