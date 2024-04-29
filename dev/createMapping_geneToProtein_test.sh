#!/bin/bash


# BASH code to create gene to protein mapping files and updated protein sequences
# currently this code can be run as a script, but works for a specific use cases only


##
# EXAMPLE 1: single line code (D pulex)
##
# update protein sequences with gene names
#while read -r line; do firstChar=$(printf %.1s "$line"); if test $firstChar = ">"; then proteinName=$(echo $line | cut -d" " -f1 | sed 's/>//g'); geneName=$(cat genomic.gff | grep "Name=$proteinName" | cut -d";" -f2 | sed 's/gene=//g'); echo ">gene-"$geneName; else echo $line; fi; done < protein.faa > protein_geneNames.faa


##
# EXAMPLE 2: single line code (Mavium)
##
# create mapping file of gene to protein names
while read -r line; do firstChar=$(printf %.1s "$line"); if test $firstChar = ">"; then proteinName=$(echo $line | cut -d" " -f1 | sed 's/>//g'); geneName=$(cat genomic.gff | grep "Name=$proteinName" | cut -d";" -f2 | sed 's/Parent=//g' | sed 's/gene-//g' | sed 's/_/_RS/g'); echo "$proteinName $geneName"; fi; done < protein.faa > proteinToGene.txt

# update protein sequences with gene names
while read -r line; do firstChar=$(printf %.1s "$line"); if test $firstChar = ">"; then proteinName=$(echo $line | cut -d" " -f1 | sed 's/>//g'); geneName=$(cat genomic.gff | grep "Name=$proteinName" | cut -d";" -f2 | sed 's/Parent=//g' | sed 's/gene-//g' | sed 's/_/_RS/g'); echo ">"$geneName; else echo $line; fi; done < protein.faa > protein_geneNames.faa


##
# EXAMPLE 3: multi line code (Mavium)
##
# remove a pre-exsisting mapping file
rm proteinToGene.txt
# loop over each line of the protein seqeunce file 
# and create a mapping file of gene to protein names
while read -r line; do 
	# retrieve first character of the current line
	firstChar=$(printf %.1s "$line")
	# check if the first character is > that denotes the start of a new sequence header
	if test $firstChar = ">"; then 
		# retrieve the current protein name
		proteinName=$(echo $line | cut -d" " -f1 | sed 's/>//g')
		# retrieve the corresponding gene name
		geneName=$(cat genomic.gff | grep "Name=$proteinName" | cut -d";" -f2 | sed 's/Parent=//g' | sed 's/gene-//g' | sed 's/_/_RS/g')
		# print out the screen the protein name followed by the gene name
		# and append the results to the mapping file
		echo "$proteinName $geneName" >> proteinToGene.txt
	fi
done < protein.faa

# remove a pre-exsisting updated protein sequences file
rm protein_geneNames.txt
# loop over each line of the protein seqeunce file 
# and update the protein sequences with gene names
while read -r line; do 
	# retrieve first character of the current line
	firstChar=$(printf %.1s "$line")
	# check if the first character is > that denotes the start of a new sequence header
	if test $firstChar = ">"; then 
		# retrieve the current protein name
		proteinName=$(echo $line | cut -d" " -f1 | sed 's/>//g')
		# retrieve the corresponding gene name
		geneName=$(cat genomic.gff | grep "Name=$proteinName" | cut -d";" -f2 | sed 's/Parent=//g' | sed 's/gene-//g' | sed 's/_/_RS/g')
		# print out the screen the gene name
		# and append the results to the update the protein sequences file
		echo ">"$geneName >> protein_geneNames.txt
	else 
		# print out the screen the protein sequence
		# and append the results to the update the protein sequences file
		echo $line >> protein_geneNames.txt
	fi
done < protein.faa
