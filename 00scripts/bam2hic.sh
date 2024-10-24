#! /bin/bash
set -eou pipefail

export PATH=/path/bin/samtools-1.10:$PATH
export PATH=/path/bin/HiCUP-0.8.3/Conversion:$PATH

JUICER_JAR="java -jar /path/bin/hic/scripts/common/juicer_tools.jar"

if [ "$#" -ne 5 ]; then
    echo "Incorrect inputs: ./bam2hic.sh <bam> <target.bed> <chrom.sizes> <MAPQ> <outdir> "
    exit 1
fi

BAM=$1
BAMDIR=$(dirname $BAM)
PREFIX=$(basename $BAM ".bam")
BED=$2
GENOME=$3
MAPQ=$4
OUT=$5


# Convert bam files to Juicer's friendly contacts file

if [ ! -f $BAMDIR/$PREFIX.bam.prejuicer ]; then hicup2juicer $BAM; fi

# Extract only enriched region

if [ -f $BAMDIR/$PREFIX.bam.prejuicer ]; then
    while IFS=$'\t' read -r CHR START END; do
        # edit custom chr19 names back to chr19 
        sed 's/chr19\S*/chr19/g' $BAMDIR/$PREFIX.bam.prejuicer | \
        awk -v chrom=$CHR -v start=$START -v end=$END '{
		if (NF != 11) {
		    print "Wrong input format, line:", NR
		    exit 1
		}
        # extract targeted regions 
		if($3==chrom && $7==chrom && 
		   $4 >= start && $4 < end && 
		   $8 >= start && $8 < end) {
			print $0
			}
	}' > $OUT/_pre/"$PREFIX"_enriched.prejuicer
    done < $BED
fi

# Convert to .hic with Juicer's Pre & custom chrom sizes file

if [ ! -f $OUT/_hic/"$PREFIX"_enriched_MAPQ"$MAPQ".hic ]; then
    $JUICER_JAR pre -q $MAPQ \
    $OUT/_pre/"$PREFIX"_enriched.prejuicer \
    $OUT/_hic/"$PREFIX"_enriched_MAPQ"$MAPQ".hic \
    $GENOME
fi