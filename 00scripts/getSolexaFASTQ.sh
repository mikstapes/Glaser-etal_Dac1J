#! /bin/bash

##########
## take all given solexa paths in sample_info.tsv and make symlink for futher processing ##
#########

cut -f 7 ../samples_info.tsv | sed 1,1d | parallel "ln -s {}_R1_001.fastq.gz {}_R2_001.fastq.gz . "