#!/bin/sh

	set -euo pipefail

binpath="/path/to/bin/gatk"


## RECALIBRATING & FILTERING HAPLOTYPE CALLER SNPs

## split variable sites into SNPs and INDELS

	grep -v "#" dp2.HC.raw.var.chr* | awk '$5 !~ "," && length($4) == 1 && length($5) == 1' > dp2.HC.raw.SNP.biall.vcf

	grep -v "#" dp2.HC.raw.var.chr* | awk '$5 !~ "," && (length($4) != 1 || length($5) != 1)' > dp2.HC.raw.INDEL.biall.vcf

## extract concordant genotypes between HC and UG callers for VSQR

	java -Xmx4g -jar $binpath/GenomeAnalysisTK.jar \
		-T SelectVariants \
		-R reference.fa \
		--variant dp2.HC.raw.SNP.biall.vcf \
		--concordance UG.dp8.minN1.homo.trainingforvsqr.vcf.gz \
		-o dp2.HC.concord.SNP.biall.vcf

## extract concordant SNP QUAL and QD values - to create VSQR training dataset

	grep -v "#" dp2.HC.concord.SNP.biall.vcf | cut -f1,2,6 > concordance.temp

	awk 'BEGIN{FS=";QD=|;SO|;Rea"}{print $2}' dp2.HC.concord.SNP.biall.vcf | paste concordance.temp - > concordance.snp.ids.for.plotting

	rm -f concordance.temp

	sort -k4,4nr concordance.snp.ids.for.plotting | awk '$4 > 20' > concordance.snp.ids.for.plotting.sorted

## extract > 0.5 quantile of QD values

	a=`awk 'END{print int(NR/2)}' concordance.snp.ids.for.plotting.sorted`; sed -n 1,${a}p concordance.snp.ids.for.plotting.sorted > concordance.snp.ids.for.plotting.sorted.0.5quant

	awk 'NR==FNR{a[$1"_"$2]=$0;next}{if ($1"_"$2 in a || $1 ~ "#")print}' concordance.snp.ids.for.plotting.sorted.0.5quant dp2.HC.concord.SNP.biall.vcf > 0.5quant.training.dp2.HC.concord.SNP.biall.vcf

	rm -f concordance.snp.ids.for.plotting.sorted.0.5quant concordance.snp.ids.for.plotting.sorted concordance.snp.ids.for.plotting

## applying HARD filters to the raw snp dataset - to create truth/training set

java -Xmx10g -jar $binpath/GenomeAnalysisTK.jar -T VariantFiltration \
	-R /biodata/dep_coupland/grp_korff/artem/mapping_new_artem/reference.fa \
	--variant dp2.HC.raw.SNP.biall.vcf \
	--filterExpression "QD < 2.0 || FS > 60.0 || MQ < 20.0" \
	--filterName "snp_filter" \
	--genotypeFilterName "GQ20_DP8" \
	--genotypeFilterExpression "DP < 8 || GQ < 20" \
	--setFilteredGtToNocall | 
egrep "#|PASS" | 
egrep "#|1\/1" > dp2.HC.filtered_hard.SNP.biall.vcf

## extracting common SNPs between concordance & hard_filtered VCFs

	awk 'NR==FNR{a[$1"_"$2]=$1;next}{if ($1"_"$2 in a || $1 ~ "#")print}' concordance.snp.ids.for.plotting.sorted dp2.HC.filtered_hard.SNP.biall.vcf | cat header.dp2.HC.raw.var.nonvar.chr1H_1.vcf - > truth.concordance.dp2.HC.filtered_hard.SNP.biall.vcf

## running VQSLR

	java -Xmx10g -jar $binpath/GenomeAnalysisTK.jar \
		-T VariantRecalibrator \
		-R reference.fa \
		-input dp2.HC.raw.SNP.biall.vcf \ 
		-resource:0.75,known=false,training=true,truth=true,prior=12.0 truth.concordance.dp2.HC.filtered_hard.SNP.biall.vcf \ 
		-resource:0.5,known=false,training=true,truth=false,prior=10.0 0.5quant.training.dp2.HC.concord.SNP.biall.vcf \
		-an QD -an MQ -an MQRankSum -an ReadPosRankSum -an SOR \
		-mode SNP \
		-recalFile newtruth.wo_fs.recal \
		-tranchesFile newtruth.wo_fs.tranches \
		-rscriptFile newtruth.wo_fs.R \
		--TStranche 80.0 --TStranche 85.0 --TStranche 90.0  --TStranche 99.0 --TStranche 99.5 --TStranche 99.9 --TStranche 100.0

## applying VQSLR to VCF - 99.9 tranche

	java -Xmx10g -jar $binpath/GenomeAnalysisTK.jar \
		-T ApplyRecalibration \
		-R /biodata/dep_coupland/grp_korff/artem/mapping_new_artem/reference.fa \
		-input dp2.HC.raw.SNP.biall.vcf \
		--ts_filter_level 99.9 \
		-tranchesFile newtruth.wo_fs.tranches \
		-recalFile newtruth.wo_fs.recal \
		-mode SNP \
		-o dp2.HC.recal99.9.newtruth.wo_fs.SNP.biall.vcf


## filtering re-calibrated VCFs for overall SNP quality and individual genotypes

	java -Xmx10g -jar $binpath/GenomeAnalysisTK.jar \
		-T VariantFiltration \
		-R /biodata/dep_coupland/grp_korff/artem/mapping_new_artem/reference.fa \
		--variant dp2.HC.recal99.9.newtruth.wo_fs.SNP.biall.vcf \
		--genotypeFilterName "GQ20_DP8" \
		--genotypeFilterExpression "DP < 8 || GQ < 20" \
		--setFilteredGtToNocall | 
	egrep "#|1\/1" | 
	awk '$7 ~ "PASS"' > dp8_gq20.HC.recal99.9.newtruth.wo_fs.SNP.biall.var_nonvar1.vcf

######################################

## FILTERING INDELS

	java -Xmx10g -jar $binpath/GenomeAnalysisTK.jar \
		-T VariantFiltration \
		-R /biodata/dep_coupland/grp_korff/artem/mapping_new_artem/reference.fa \
		--variant dp2.HC.raw.INDEL.biall.vcf \
		--filterExpression "QD < 2.0 || FS > 200.0" \
		--filterName "indel_filter" \
		--genotypeFilterName "GQ20_DP8" \
		--genotypeFilterExpression "GQ < 20 || DP < 8" \
		--setFilteredGtToNocall | 
	egrep "#|1\/1" | 
	awk '{if ($1 ~ "#")print$0; else if ($7 ~ "PASS")print $0}'  > dp8_gq20.HC.filtered.INDEL.biall.var_nonvar1.vcf

#########################################

## FILTERING AND MERGING non-variant VCFs

## step1: filter by DP and GQ vsqr-rejected SNPs and convert 0/1 and 1/1 to ./.; part of a non-variant dataset

java -Xmx10g -jar $binpath/GenomeAnalysisTK.jar \
		-T VariantFiltration \
		-R reference.fa \
		--variant dp2.HC.recal99.9.newtruth.wo_fs.SNP.biall.vcf \
		--genotypeFilterName "GQ20_DP8" \
		--genotypeFilterExpression "DP < 8 || GQ < 20" \
		--setFilteredGtToNocall |
		awk '$7 !~ "PASS"' | ## did not pass vsqr
		sed -e "s:0\/1:.\/.:g" -e "s:1\/1:.\/.:g" |
		grep "0\/0" > temp.vsqrdiscarded_snp_converted_to_nonvar.vcf


## step2: merge non-variant VCFs per chromosome + vsqr-rejected SNPs converted to non-variant in a FINAL single non-variant VCF

raw_snps=`ls *nonvar.chr*_*.vcf | awk 'BEGIN{RS=""}{gsub("\n"," --variant ",$0);print}'`	

java -Xmx10g -jar $binpath/GenomeAnalysisTK.jar \
	-R /biodata/dep_coupland/grp_korff/artem/mapping_new_artem/reference.fa \
	-T CombineVariants \
	--genotypemergeoption UNSORTED \
	--minimumN 1 \
	--variant temp.vsqrdiscarded_snp_converted_to_nonvar.vcf \
	--variant ${raw_snps} |
	egrep "#|0\/0"	> dp8.HC.filt.nonvar.all.vcf ## final VCF with all non-variant sites

########################################

## STRAIGHTEN the CHROMOSOME COORDINATES and CONVERT chr[1:8]H format to [1:8]

for file in \
	dp8.HC.filt.nonvar.all.vcf \
	dp8_gq20.HC.filtered.INDEL.biall.var_nonvar1.vcf \
	dp8_gq20.HC.recal99.9.newtruth.wo_fs.SNP.biall.var_nonvar1.vcf; do

rm -f header

mkfifo header
  
grep "#" ${file} > header &

grep -v "#" ${file} |
awk 'BEGIN{FS="_|\t"}{if($2 == 2)print $1"\t"($3+400000000)"\t"$0; else print $1"\t"$3"\t"$0}' |
cut -f1,2,5- |
sed -e "s/^chr//" -e "s/H\t/\t/" |
cat header - > ${file%%vcf}chr.vcf 

rm -f header

done

