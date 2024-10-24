#! /bin/bash
set -euo pipefail 
## take in replicates metadata in a df, parse reps and "merge" (without sorting)


if [ $# -ne 3 ]; then
    echo "Incorrect inputs. ./merge_bams.sh <metadata file> <build> <outdir> "
    exit 1
fi

df="$1"
build="$2"
outdir="$3"

if grep -q "Dac" <<< "$build"; then 
    prefix="Dac|WT"
elif grep -q "LTR" <<< "$build"; then
    prefix="LTR|WT"
else prefix="LTR|WT|Dac"
fi

echo $prefix

MERGE_REPS() {
	if [ "$#" -ne 6 ]; then
		echo "Error: wrong numbers of arguments"
		exit 1
	fi
    ## file path format : _aln/<build>/<lib>/results/<lib>_R1_2_001.hicup.bam
    local REP1=_aln/"$5"/"$1"/results/"$1"_R1_2_001.hicup.bam
    local REP2=_aln/"$5"/"$2"/results/"$2"_R1_2_001.hicup.bam
    local REP3=_aln/"$5"/"$3"/results/"$3"_R1_2_001.hicup.bam
    local OUT=$6
     # change to blank if file for rep3 doesn't exist
     
    if [ ! -f "$REP3" ]; then REP3=""; fi

    ## "merging" files 
    
    # CMD='samtools cat '"$REP1"' '"$REP2"' '"$REP3"' -o '"$OUT"'/'"$4"'_'"$5"'.bam'
    # echo $CMD
    samtools cat --threads 2 $REP1 $REP2 $REP3 -o $OUT/$4_$5.bam
    
}

export -f MERGE_REPS

if [ ! -f "$df" ]
then
    echo "Replicates metadata missing"
    exit 1
else
    awk  -F '\t' '$1 ~ /'"$prefix"'/ {print}' "$df" | \
    parallel --colsep '\t' -v -j 6 MERGE_REPS {3} {4} {5} {2} $build $outdir
fi

