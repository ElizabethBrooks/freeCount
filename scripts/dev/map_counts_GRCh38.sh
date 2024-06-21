#!/bin/bash

# BASH script to map gene IDs to protein IDs for downstream functional analysis

# usage: bash map_counts_GRCh38.sh

# output formatted counts file
#fmtFile="/Users/bamflappy/Repos/freeCount/data/dev/Cancer_RNAseq_STAD_GTEx_counts.fmt.csv"
fmtFile="/Users/bamflappy/Repos/freeCount/data/dev/scRNAseq_STAD_GTEx_counts.fmt.csv"

# tmp file for mapping IDs
tmpCounts="/Users/bamflappy/Repos/freeCount/data/dev/tmp_scRNAseq_STAD_GTEx_counts.csv"

# retrieve pep to gene mappings file
mapFile="/Users/bamflappy/Repos/freeCount/data/dev/Homo_sapiens.GRCh38_pepToGene.fmt.csv"

# output file for the re-formatted counts file
#outFile="/Users/bamflappy/Repos/freeCount/data/DA_DEAnalysis/Cancer_RNAseq_STAD_GTEx_counts.pep.csv"
outFile="/Users/bamflappy/Repos/freeCount/data/DA_DEAnalysis/scRNAseq_STAD_GTEx_counts.pep.csv"

# tmp output re-formatted counts file
#tmpOut="/Users/bamflappy/Repos/freeCount/data/dev/tmp_Cancer_RNAseq_STAD_GTEx_counts.pep.csv"
tmpOut="/Users/bamflappy/Repos/freeCount/data/dev/tmp_scRNAseq_STAD_GTEx_counts.pep.csv"

# add counts file header to output
head -1 $fmtFile > $tmpOut

# create tmp counts file without the header to loop over
tail -n+2 $fmtFile > $tmpCounts

# output status message
echo "Beginning counts re-formatting..."

# loop over each gene Id in the counts file
# and swap it with the first protein ID that is found (not typically recommended)
while read line; do
	# retrieve the counts gene ID from the current line
	countsID=$(echo $line | cut -d"," -f1)
	# output status message
	echo "Processing $countsID ..."
	# retrieve the counts for the current line
	countsData=$(echo $line | cut -d"," -f2-)
	# reatrieve the first protein ID in the file for the current counts gene ID
	pepID=$(cat $mapFile | grep $countsID | head -1 | cut -d"," -f1)
	# replace the counts gene ID with the selected protein ID
	echo $pepID","$countsData >> $tmpOut
done < $tmpCounts

# remove rowns with duplicate protein IDs (not typically recommended)
awk -F',' '!seen[$1]++' $tmpOut > $outFile

# output status message
echo "Counts re-formatting completed!"

# clean up
rm $tmpCounts
rm $tmpOut
