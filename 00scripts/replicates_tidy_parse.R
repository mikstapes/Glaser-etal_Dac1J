#! /usr/local/package/bin/R

pkgs <- c('dplyr', 'readr', 'tidyr', 'here', 'stringr')
invisible(suppressMessages(lapply(pkgs, library, character.only = TRUE)))

args <- commandArgs(trailingOnly = TRUE)
if length(args != 2) stop('./replicates_tidy_parse.R <input fastq dir> <outdir>')

# when calling R from snakemake an S4 object named snakemake allows access to input/output files/other parameters

fasqdir <- snakemake@input[[1]]
out <- snakemake@output[[1]]

file.ext <- '_R1_001.fastq.gz'
files <- str_remove(list.files(fasqdir, pattern = file.ext), pattern = file.ext)

df <- tibble(sample = paste0(files, '_R1_2_001.hicup.bam'), 
             tissue = ifelse(str_detect(sample, 'heart'), 'heart', 'FLHL'))

df <- df %>% 
    mutate(geno=str_extract(sample, pattern='Dac[:alnum:]{3}|LacZ')) %>% 
    mutate(geno = case_when(is.na(geno) ~ 'WT', 
                            geno == 'LacZ' ~ '5LTR', 
                            TRUE ~ geno), 
           merged = paste(tissue, geno, 'merged', sep = '_')) 

# manually annotate replicate
df$replicate <- c(rep('rep1', 3), 
                  'rep1', 'rep2', 'rep2', 'rep3', 'rep1', 
                  'rep3', rep('rep2', 3))

df <- df %>% 
    pivot_wider(names_from = replicate, values_from = sample) %>% 
    mutate(rep3 = ifelse(is.na(rep3), "", rep3)) %>% ## leaves blank if NA
    select(starts_with('rep'), merged)

write_tsv(df, file = out)