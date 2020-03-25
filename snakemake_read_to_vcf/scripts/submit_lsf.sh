1 #!/usr/bin/env bash
  2 CLUSTER_CMD=("bsub -q {cluster.queue} -n {cluster.nCPUs} -R {cluster.resourc    es} -M {cluster.memory} -o {cluster.output} -e {cluster.error} -J {cluster.n    ame}")
  3 #JOB_NAME="$1"
  4 
  5 #bsub -R "rusage[mem=1000]" \
  6 #  -M 1000 \
  7 #  -o logs/cluster_"$JOB_NAME".o \
  8 #  -e logs/cluster_"$JOB_NAME".e \
  9 #  -J "$JOB_NAME" \
 10   snakemake --cluster-config cluster.yaml \
 11     --latency-wait 2 \
 12     --jobs 10 \
 13     --cluster "${CLUSTER_CMD}"
 14 
 15 #exit 0
