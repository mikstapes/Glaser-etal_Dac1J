import os
import re
import pandas as pd
from glob import glob

HICUP='/project/4c_gene_reg/mikie/bin/HiCUP-0.8.3/hicup'

here = os.path.realpath(".")
fastq_dir = f"{here}/_fastqL/processed"

## get list of all libs
READS=[f for f in os.listdir(fastq_dir) if "R1" in f]

build=config['ref_genome']
MapQ=30 # hard-coding default MAPQ

def read_tsv (f):
    if os.path.exists(f):
        tsv = pd.read_csv(f, sep = '\t')
        return tsv
    
reps_df = read_tsv("_aln/reps_metadata.tsv")

if build == 'Dac_mm10':
    SAMPLES = [s.replace('_R1_001.fastq.gz', '') for s in READS if not re.search(r'LacZ', s)]
    reps_df = reps_df[~reps_df['geno'].str.contains('LTR')]
elif build == '5LTRLacZ_mm10':
    SAMPLES = [s.replace('_R1_001.fastq.gz', '') for s in READS if not re.search(r'Dac', s)]
    reps_df = reps_df[~reps_df['geno'].str.contains('Dac')]
else: 
    SAMPLES = [s.replace('_R1_001.fastq.gz', '') for s in READS]



# Define the output files
merged_bams = expand("_aln/%s/_merged/{merged}_{build}.bam" %build, merged=reps_df.merged, build=build)
prejuicer = expand("_aln/%s/_merged/{merged}_%s.bam.prejuicer" %(build,build), merged=reps_df.merged)
enriched_pre = expand("_MAPS/%s/_pre/{merged}_%s_enriched.prejuicer" %(build,build), merged=reps_df.merged)
hic = expand("_MAPS/%s/_hic/{merged}_%s_enriched_MAPQ%s.hic" %(build,build,MapQ), merged=reps_df.merged)


rule all:
    input:
        expand("_aln/%s/{sample}/hicup_config.conf" %build, sample=SAMPLES),
        expand("_aln/%s/{sample}/results/{sample}_R1_2_001.hicup.bam" %build, sample=SAMPLES),
        merged_bams,
        prejuicer, 
        enriched_pre, 
        hic

rule parse_reps_df:
    """
    From pre-processed fastq (merged tech reps or trimmed), 
    generate new df with sample metadata
    """
    input:
        "_fastqL/processed"
    output:
        "_aln/reps_metadata.tsv"
    script:
        '00scripts/replicates_tidy_parse.R'

rule edit_config:
    """
    Customize config file for each sample/ref builds
    """
    input:
        '_fastqL/processed/{sample}_R1_001.fastq.gz'
    output:
        "_aln/{build}/{sample}/hicup_config.conf",
    params: 
        fastq='_fastqL/processed/{sample}',
        bt2_index=config['bt2_index'],
        DpnII_digest=config['DpnII_digest']
        
    shell:
        """
        python 00scripts/editConfig.py \
            --bt2idx  {params.bt2_index} \
            --digest {params.DpnII_digest} \
            --fastq {params.fastq} --outdir _aln/{build}/{wildcards.sample}/
        """

rule hicup:
    """
    Run HiCUP with specified config
    """
    input:
        ancient("_aln/{build}/{sample}/hicup_config.conf")
    output:
        "_aln/{build}/{sample}/results/{sample}_R1_2_001.hicup.bam"
    threads: min(workflow.cores, 15)
    shell:
        """
        {HICUP} --config {input}
        """

bam_dir = "_aln/%s/_merged" %build

rule merge_bams:
    """
    Run samtools merge of all replicates, rename merged file
    """
    input: 
        rules.parse_reps_df.output
    output: 
        merged_bams
    shell:
        """
        00scripts/merge_replicate_bams.sh {input} {build} {bam_dir}
        """

rule make_hic:
    """
    Convert bam files to Juicer's .hic for only enriched regions
    ./bam2hic.sh <bam> <target.bed> <chrom.sizes> <MAPQ> <outdir>
    """
    input: [bam for bam in rules.merge_bams.output]
    output: prejuicer, enriched_pre, hic
    params:
        target = config['target_bed'],
        chrom_sizes = config['chrom_sizes'],
        outdir = "_MAPS/%s" %build
    shell:
        """
        parallel -j 4 -v \
        00scripts/bam2hic.sh {{}} {params.target} {params.chrom_sizes} {MapQ} {params.outdir} \
        ::: {input}
        """
