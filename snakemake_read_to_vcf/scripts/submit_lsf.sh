#!/usr/bin/env bash
CLUSTER_CMD=("bsub -q {cluster.queue} -n {cluster.nCPUs} -R {cluster.resourc    es} -M {cluster.memory} -o {cluster.output} -e {cluster.error} -J {cluster.n    ame}")
 #JOB_NAME="$1"
 
 #bsub -R "rusage[mem=1000]" \
 #  -M 1000 \
 #  -o logs/cluster_"$JOB_NAME".o \
 #  -e logs/cluster_"$JOB_NAME".e \
 #  -J "$JOB_NAME" \
snakemake --cluster-config cluster.yaml \
     --latency-wait 2 \
     --jobs 10 \
     --cluster "${CLUSTER_CMD}"
 
#exit 0
