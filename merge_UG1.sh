#!/bin/sh

set -euo pipefail

path="/netscarch/path/to/raw/uf_files/"
binpath="/path/to/gatk"

raw_snps=`ls ${path}*homoSNP.vcf | awk 'BEGIN{RS=""}{gsub("\n"," --variant ",$0);print}'`
	
	java -Xmx80g -jar ${binpath}/GenomeAnalysisTK1.jar \
		-R reference.fa \
		-T CombineVariants \
		--minimumN 1 \
		--out UG.dp8.minN1.homo.trainingforvsqr.vcf \
		--variant $raw_snps \
		--genotypemergeoption UNSORTED
