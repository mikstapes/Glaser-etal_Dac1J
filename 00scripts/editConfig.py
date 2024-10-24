import argparse


# Set up command line argument parser
parser = argparse.ArgumentParser(description='Edit HiCUP config file')
parser.add_argument('--config', help='Path to the config file', 
                   default='/project/4c_gene_reg/mikie/hicup_config.conf')
parser.add_argument('--bowtie2', help='Bowtie2 path', 
                    default='/usr/local/package/bin/bowtie2')
parser.add_argument('--bt2idx', help='Bowtie2 index path')
parser.add_argument('--digest', help='DpnII digest path produced by hicup_digester')
parser.add_argument('--fastq', help='Path to fastq, include only basename')
parser.add_argument('--outdir', help='New output directory/')


args = parser.parse_args()

## Read in the input file and edit as needed

with open(args.config, 'r') as f:
    lines = f.readlines()
    for i in range(len(lines)):
        if lines[i].startswith('Bowtie2:'):
            lines[i] = 'Bowtie2:' + args.bowtie2 + '\n'
        elif lines[i].startswith('Outdir:'):
            lines[i] = 'Outdir:' + args.outdir + 'results'
        elif lines[i].startswith('Index:'):
            lines[i] = 'Index:' + args.bt2idx + '\n'
        elif lines[i].startswith('Digest:'):
            lines[i] = 'Digest:' + args.digest + '\n'
        elif lines[i].startswith('R1'):
            lines[i] = args.fastq + '_R1_001.fastq.gz' + '\n'
        elif lines[i].startswith('R2'):
            lines[i] = args.fastq + '_R2_001.fastq.gz'
            
## Write the edits to a new file

with open(args.outdir + 'hicup_config.conf', 'w') as f:
    f.writelines(lines)