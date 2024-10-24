#! bin/bash
set -euo 

export PATH=/path/bin/samtools-1.10:$PATH
export PATH=/path/bin/bowtie2:$PATH
export PATH=/path/bin/HiCUP-0.8.3:$PATH

############################################################
#-- Draft shell workflow from fastq to .hic 

# test processing of all WT samples (n=3) mapping to all mm10
### 1.configure hicup with editConfig.py
### 2.run HiCUP + conversion to hic 

############################################################

HERE=$(realpath ..)
FASTQ=$HERE/_fastqL/processed

REFDIR=./_ref
OUTDIR=./_aln

READS="mpimg_L11359-1_L11678_Bl6_rep1 "
READS+="mpimg_S11359_BL6_S17 "
READS+="mpimg_L9627-1_C-HiC-Black6_S50"

ref_genome=mm10

## make separate dir for each sample
for sample in $READS; do
    if [ ! -d "$OUTDIR"/"$ref_genome"/"$sample"/results ] 
    then 
        mkdir -p "$OUTDIR"/"$ref_genome"/"$sample"/results 
    fi
done

## customize config file for each sample
echo $READS | tr ' ' '\n' | parallel -j 3 \
"python 00scripts/editConfig.py \
--bt2idx  '$REFDIR'/'$ref_genome'/'$ref_genome' \
--digest '$REFDIR'/'$ref_genome'/Digest_DpnII_mm10_DpnII_None_18-45-35_25-01-2023.txt \
--fastq '$FASTQ'/{} --outdir '$OUTDIR'/'$ref_genome'/{}/ "

# ## run HiCUP ##

# echo $READS | tr ' ' '\n' | parallel -j 3 \
# "hicup --config '$OUTDIR'/'$ref_genome'/{}/hicup_config.conf"