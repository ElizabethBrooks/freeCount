#!/bin/bash

# retrieve counts file
countsFile="/Users/bamflappy/Repos/freeCount/data/DEAnalysis/STAD_GTEX_counts.fmt.csv"

# retrieve pep to gene mappings file
mapFile="/Users/bamflappy/Repos/freeCount/data/tmp/Homo_sapiens.GRCh38_pepToGene.fmt.csv"

# output file for the reformatted counts file
outFile="/Users/bamflappy/Repos/freeCount/data/DEAnalysis/STAD_GTEX_counts.pep.csv"

# add counts file header to output
head -1 $countsFile > $outFile

# create tmp counts file without the header to loop over
tmpCounts="/Users/bamflappy/Repos/freeCount/data/tmp/tmp_STAD_GTEX_counts.csv"
tail -n+2 $countsFile > $tmpCounts

# loop over each gene Id in the counts file and swap it with the first protein ID
while read line; do
	# retrieve the counts gene ID from the current line
	countsID=$(echo $line | cut -d"," -f1)
	# retrieve the counts for the current line
	countsData=$(echo $line | cut -d"," -f2-)
	# reatrieve the first protein ID in the file for the current counts gene ID
	pepID=$(cat $mapFile | grep $countsID | head -1 | cut -d"," -f1)
	# replace the counts gene ID with the selected protein ID
	echo $pepID","$countsData > $outFile
done < $countsFile

# clean up
rm $tmpCounts
