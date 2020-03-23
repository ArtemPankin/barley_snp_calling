#!/bin/sh

set -euo pipefail

path="/netscarch/path/to/raw/uf_files/"

raw_snps=`find $path -name "_UG_raw.vcf" | awk 'BEGIN{RS=""}{gsub("\n"," --variant ",$0); print}'`

	java -Xmx50g -jar GenomeAnalysisTK.jar \
		-R reference.fa \
		-T CombineVariants \
		--minimumN 1 \
		--out rawcalls.478samples.mpipz.minN1.vcf \
		--variant $raw_snps \
		--genotypemergeoption UNSORTED
