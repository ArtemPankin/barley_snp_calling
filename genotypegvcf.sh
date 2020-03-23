#!/bin/sh

	set -euo pipefail

raw_snps=`ls *dp2.snps.*vcf | awk 'BEGIN{RS=""}{gsub("\n"," --variant ",$0);print}'`
datapath="/path/to/"
for i in `seq 1 8`; do

	for b in `seq 1 2`; do

if [ ! -s dp8.HC.filt.nonvar.chr${i}_${b}.vcf ]; then #1

	java -Xmx50g -jar /biodata/dep_coupland/grp_korff/bin/GenomeAnalysisTK1.jar \
		-T GenotypeGVCFs \
		-R /biodata/dep_coupland/grp_korff/artem/mapping_new_artem/new_reference.chrom.fa \
		--variant $raw_snps \
		--includeNonVariantSites \
		-o /biodata/dep_coupland/grp_korff/artem/mapping_new_artem/dp2.HC.raw.var.nonvar.chr${i}_${b}.vcf \
		-L chr${i}H_${b}

	egrep "#|1\/1" dp2.HC.raw.var.nonvar.chr${i}_${b}.vcf > dp2.HC.raw.var.chr${i}_${b}.vcf

a=`tail -n 1 dp2.HC.raw.var.chr${i}_${b}.vcf | cut -f 1`

if [[ "${a}" == "#CHROM" || -z "${a}" ]]; then 

	exit 1

fi

	egrep -v "1\/1" dp2.HC.raw.var.nonvar.chr${i}_${b}.vcf > dp2.HC.raw.nonvar.chr${i}_${b}.vcf
																																														
a=`tail -n 1 dp2.HC.raw.nonvar.chr${i}_${b}.vcf | cut -f 1`

if [[ "${a}" == "#CHROM" || -z "${a}" ]]; then 

	exit 1

else

	rm dp2.HC.raw.var.nonvar.chr${i}_${b}.vcf 

fi

## filter raw DP2 non-variant genotypes for DP > 8

	java -Xmx50g -jar /biodata/dep_coupland/grp_korff/bin/GenomeAnalysisTK1.jar \
		-T VariantFiltration \
		-R /biodata/dep_coupland/grp_korff/artem/mapping_new_artem/new_reference.chrom.fa \
		--variant dp2.HC.raw.nonvar.chr${i}_${b}.vcf \
		--genotypeFilterExpression "DP < 8" \
		--genotypeFilterName "DP8" \
		--setFilteredGtToNocall | 
	sed "s/0\/1/.\/./g" | ## substitutes het SNPs w/o hom SNPs to missing data
	egrep "#|0\/0" > dp8.HC.filt.nonvar.chr${i}_${b}.vcf

a=`tail -n 1 dp8.HC.filt.nonvar.chr${i}_${b}.vcf | cut -f 1`

if [[ "${a}" == "#CHROM" || -z "${a}" ]]; then 

	exit 1

else

	rm dp2.HC.raw.nonvar.chr${i}_${b}.vcf
fi

rm *idx

fi #1 close

done

done

## continue with ug_hc_snpdiscovery.bsub
