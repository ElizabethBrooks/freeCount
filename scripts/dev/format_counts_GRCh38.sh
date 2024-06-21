#!/bin/bash

# BASH script to re-format gene IDs in a GRCh38 Human reference genome bulk or scRNA seq counts file 
# by removing the decimal values in the gene IDs (not typically recommended) 

# usage: bash format_counts_GRCh38.sh

# retrieve counts file
#countsFile="/Users/bamflappy/Repos/freeCount/data/dev/Cancer_RNAseq_STAD_GTEx_counts.csv"
countsFile="/Users/bamflappy/Repos/freeCount/data/dev/scRNAseq_STAD_GTEx_counts.csv"

# output formatted counts file
#fmtFile="/Users/bamflappy/Repos/freeCount/data/dev/Cancer_RNAseq_STAD_GTEx_counts.fmt.csv"
fmtFile="/Users/bamflappy/Repos/freeCount/data/dev/scRNAseq_STAD_GTEx_counts.fmt.csv"

# tmp files for formatting IDs
#tmpIDs="/Users/bamflappy/Repos/freeCount/data/dev/tmp_Cancer_RNAseq_STAD_GTEx_IDs.csv"
tmpIDs="/Users/bamflappy/Repos/freeCount/data/dev/tmp_scRNAseq_STAD_GTEx_IDs.csv"
#tmpCounts="/Users/bamflappy/Repos/freeCount/data/dev/tmp_Cancer_RNAseq_STAD_GTEx_counts.csv"
tmpCounts="/Users/bamflappy/Repos/freeCount/data/dev/tmp_scRNAseq_STAD_GTEx_counts.csv"

# output status message
echo "Beginning counts re-formatting..."

# retreive gene IDs and remove the decimal values
cat $countsFile | cut -d"," -f1 | cut -d"." -f1 > $tmpIDs

# retrieve the count data
cat $countsFile | cut -d"," -f2- > $tmpCounts

# create the re-formatted counts file
paste -d"," $tmpIDs $tmpCounts > $fmtFile

# output status message
echo "Counts re-formatting completed!"

# clean up
rm $tmpIDs
rm $tmpCounts
