## BASH script

## This script performs Illumina read filtering, mapping and SNP calling and filtering

## The following SOFTWARE should be in the 'bin' path: 
	# samtools, 
	# bwa, 
	# GATK, 
	# cd-hit-dup, 
	# lighter, 
	# intersectBed, 
	# bamToFastq, 
	# AddOrReplaceReadGroups.jar, 
## The script requires two dependent BSUB scripts 'filt_map_snp.bsub', 'genotyping.bsub'. They should be placed in the same folder
## we recommend reserving memory for this script (~ 80 Gb in out case)

## The script should be started in with the eight compulsory arguments: 
## bash read_mapping_snp_calling.sh /
## $1 - reference_file (.fa) / 
## $2 - list_of_fastq files (one file name per line, no extra characters/FULL_PATH)
## $3 - number of cores for multicore processing /
## $4 - dataset type filtered/unfiltered ('filtered' - omits filtering steps; 'unfiltered' - proceeds with filtering) /
## $5 - coordinates of the cDNA reference in bed format (not used anymore!!!!) /
## $6 - first base to keep in bp, based on the FASTQC results / 
## $7 - last base to keep in bp, based on the FASTQC results /
## $8 - error correction by Lighter software (correction/nocorrection) (https://github.com/mourisl/Lighter) /
## $9 - skip_mapping/skip_genotyping(optional)
## $10 - russ/my
## Example command:
## bash read_mapping_snp_calling.sh reference_genome_23408contigs.fa read_files.list 8 unfiltered cDNA_coordinates.bed 5 90 correction

## The script is using BSUB LSF system for parallel computing

#!/bin/sh

set -euo pipefail

binpath="/biodata/dep_coupland/grp_korff/bin/"

# indexing reference if the index files do not exist, else skip

if [ ! -s ${1}.fai ]; then 

	samtools faidx $1

fi

if [ ! -s ${1}.bwt ]; then 
 
	bwa index $1 ## if reference > 2 Gb use '-a bwtsw' option!!!

fi

if [ ! -s ${1%%.fa}.dict ]; then

	java -jar ${binpath}CreateSequenceDictionary.jar R= $1 O= ${1%%fa}dict

fi

## modify and submit the bsub script for parallel processing of the samples

	grep -v "_2.fq" $2 > _list

	num=`awk '{sub("\r$","");print}' _list | wc -l`

	sed "s/1-.*]/1-$num]/" filtering_mapping_rawcalling.bsub | sed -r "s/BSUB -n .*$/BSUB -n $3/" | sed "s:\$1:$1:g" | sed "s:\$2:_list:g" | sed "s:\$3:$3:g" | sed "s:\$4:$4:g" | sed "s:\$6:$6:g" | sed "s:\$7:$7:g" | sed "s:\$8:$8:g" | awk '{sub("\r$","");print}' > filt_map_snp.temp.bsub
	
	bsub < filt_map_snp.temp.bsub > process_id
