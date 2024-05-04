#!/usr/bin/env Rscript

# creator: Elizabeth Brooks
# updated: 8 April 2024

# install any missing packages
packageList <- c("BiocManager", "shiny", "shinythemes", "ggplot2", "rcartocolor", "tidyr")
biocList <- c("topGO", "Rgraphviz")
newPackages <- packageList[!(packageList %in% installed.packages()[,"Package"])]
newBioc <- biocList[!(biocList %in% installed.packages()[,"Package"])]
if(length(newPackages)){
  install.packages(newPackages)
}
if(length(newBioc)){
  BiocManager::install(newBioc)
}

#Load the libraries
library(shiny)
library(shinythemes)
library(topGO)
library(ggplot2)
library(Rgraphviz)
library(tidyr)
library(rcartocolor)


# turn off scientific notation
options(scipen = 999)

# the following setting is important, do not omit.
options(stringsAsFactors = FALSE)

# set the statistic for gene scoring
statisticInput <- "FDR"
#statisticInput <- "number"
#statisticInput <- "color"

# set the expression for gene scoring
expressionInput <- "< 0.05" # example expression for edgeR FDR statistic
#expressionInput <- "== 1" # example expression for WGCNA number statistic
#expressionInput <- "== purple" # example expression for WGCNA color statistic

# retrieve input edgeR or WGCNA results tables
#DGE_results_table <- read.csv(file = "/Users/bamflappy/Repos/DGEAnalysis_ShinyApps/data/functionalAnalysis/example5_mycobacterium_topDEGs.csv", row.names=1)
#DGE_results_table <- read.csv(file = "/Users/bamflappy/Repos/DGEAnalysis_ShinyApps/data/functionalAnalysis/example6_daphnia_topDEGs.csv", row.names=1)
#DGE_results_table <- read.csv(file = "/Users/bamflappy/Repos/DGEAnalysis_ShinyApps/data/functionalAnalysis/example3_daphnia_topDEGs.csv", row.names=1)
#DGE_results_table <- read.csv(file = "/Users/bamflappy/Repos/DGEAnalysis_ShinyApps/data/functionalAnalysis/example4_daphnia_geneModules.csv", row.names=1)
DGE_results_table <- read.csv(file = "/Users/bamflappy/Repos/DGEAnalysis_ShinyApps/data/tmp/WildType2A_Scarlet2A_pairwiseDEGs.csv", row.names=1)

# retrieve mappings created by pannzer2
#GOmaps_pannzer <- read.delim(file = "/Users/bamflappy/Repos/DGEAnalysis_ShinyApps/data/functionalAnalysis/example5_mycobacterium_GO.out.txt", sep = "", row.names=NULL, colClasses = c(qpid = "character", goid = "character"))
#GOmaps_pannzer <- read.delim(file = "/Users/bamflappy/Repos/DGEAnalysis_ShinyApps/data/functionalAnalysis/example6_daphnia_GO.out.txt", sep = "", row.names=NULL, colClasses = c(qpid = "character", goid = "character"))
#GOmaps_pannzer <- read.delim(file = "/Users/bamflappy/Repos/DGEAnalysis_ShinyApps/data/functionalAnalysis/example4_daphnia_GO.out.txt", sep = "", row.names=NULL, colClasses = c(qpid = "character", goid = "character"))

# re-format mappings from pannzer2
#GOmaps_pannzer_fmt <- split(GOmaps_pannzer$goid,GOmaps_pannzer$qpid)

# create data frame with formtted mappings
#GOmaps_pannzer_out <- as.data.frame(unlist(lapply(names(GOmaps_pannzer_fmt), function(x){gsub(" ", "", toString(paste("GO:", GOmaps_pannzer_fmt[[x]], sep="")))})))
#rownames(GOmaps_pannzer_out) <- names(GOmaps_pannzer_fmt)
#colnames(GOmaps_pannzer_out) <- NULL

# output re-formatted mappings from pannzer2
#write.table(GOmaps_pannzer_out, file = "/Users/bamflappy/Repos/DGEAnalysis_ShinyApps/data/functionalAnalysis/example4_daphnia_GO.fmt.txt", sep = "\t", quote = FALSE)
#write.table(GOmaps_pannzer_out, file = "/Users/bamflappy/Repos/DGEAnalysis_ShinyApps/data/functionalAnalysis/example6_daphnia_GO.fmt.txt", sep = "\t", quote = FALSE)
#write.table(GOmaps_pannzer_out, file = "/Users/bamflappy/Repos/DGEAnalysis_ShinyApps/data/functionalAnalysis/example3_daphnia_GO.fmt.txt", sep = "\t", quote = FALSE)

# retrieve gene to GO map in two column csv format
#GOmaps_csv <- read.delim(file = "/Users/bamflappy/Repos/DGEAnalysis_ShinyApps/data/tmp/All.annot.csv")
GOmaps_csv <- suppressWarnings(read.delim(file = "/Users/bamflappy/Repos/DGEAnalysis_ShinyApps/data/tmp/All.annot.csv", sep = "", row.names=NULL, colClasses = c(goid = "character")))

# re-format mappings from two column csv
GOmaps_csv_format <- aggregate(GOmaps_csv[2], GOmaps_csv[1], FUN = toString)
GOmaps_csv_out <- GOmaps_csv_format
GOmaps_csv_out$Terms <- gsub(" ", "", GOmaps_csv_out$Terms)

# output re-formatted mappings from two column csv
write.table(GOmaps_csv_out, file = "/Users/bamflappy/Repos/DGEAnalysis_ShinyApps/data/tmp/All.annot.fmt.txt", sep = "\t", quote = FALSE, row.names=FALSE)

# retrieve gene to GO map
#GOmaps <- readMappings(file = "/Users/bamflappy/Repos/DGEAnalysis_ShinyApps/data/functionalAnalysis/example4_daphnia_GO.fmt.txt")
#GOmaps <- readMappings(file = "/Users/bamflappy/Repos/DGEAnalysis_ShinyApps/data/functionalAnalysis/example6_daphnia_GO.fmt.txt")
#GOmaps <- readMappings(file = "/Users/bamflappy/Repos/DGEAnalysis_ShinyApps/data/functionalAnalysis/example3_daphnia_GO.fmt.txt")
GOmaps <- readMappings(file = "/Users/bamflappy/Repos/DGEAnalysis_ShinyApps/data/tmp/All.annot.fmt.txt")


## GO enrichment
# create named list of all genes (gene universe) and p-values
# the gene universe is set to be the list of all genes contained in the gene2GO list of annotated genes
list_genes <- as.numeric(DGE_results_table[,statisticInput])
list_genes <- setNames(list_genes, rownames(DGE_results_table))
list_genes_filtered <- list_genes[names(list_genes) %in% names(GOmaps)]


# create function to return list of interesting DE genes (0 == not significant, 1 == significant)
get_interesting_DE_genes <- function(geneUniverse){
  interesting_DE_genes <- rep(0, length(geneUniverse))
  for(i in 1:length(geneUniverse)){
    if(eval(parse(text = paste(geneUniverse[i], expressionInput, sep=" ")))){
      interesting_DE_genes[i] = 1
    }
  }
  interesting_DE_genes <- setNames(interesting_DE_genes, names(geneUniverse))
  return(interesting_DE_genes)
}

# create topGOdata objects for enrichment analysis (1 for each ontology)
BP_GO_data <- new('topGOdata', ontology = 'BP', allGenes = list_genes_filtered, 
                  geneSel = get_interesting_DE_genes, nodeSize = 10, annot = annFUN.gene2GO, 
                  gene2GO = GOmaps)
#MF_GO_data <- new('topGOdata', ontology = 'MF', allGenes = list_genes_filtered, 
#                  geneSel = get_interesting_DE_genes, nodeSize = 10, annot = annFUN.gene2GO, 
#                  gene2GO = GOmaps)
#CC_GO_data <- new('topGOdata', ontology = 'CC', allGenes = list_genes_filtered, 
#                  geneSel = get_interesting_DE_genes, nodeSize = 10, annot = annFUN.gene2GO, 
#                  gene2GO = GOmaps)

# save the topGOdata as an R data object
#outFile <- paste("test", "topGOdata.rds", sep="_")
#saveRDS(BP_GO_data, outFile)

# retrieve topGOdata objects for enrichment analysis (1 for each ontology)
#inFile <- paste("test", "topGOdata.rds", sep="_")
#BP_GO_data_test <- readRDS(inFile)

# retrieve geneIDs associated with all GO terms
# https://support.bioconductor.org/p/29775/
allGO_BP = genesInTerm(BP_GO_data)

# write out all GO term gene IDs
sink("/Users/bamflappy/Repos/DGEAnalysis_ShinyApps/data/tmp/all_GO_gene_IDs.txt")
allGO_BP
sink()

# retrieve selected GO term gene IDs
selectedTermOne <- "GO:0031397"
selectGO_one <- allGO_BP[selectedTermOne]

# write out selected GO term gene IDs
outTermOne <- gsub(":", "_", selectedTermOne)
outFile <- paste(outTerm, "gene_IDs.csv", sep = "_")
outFile <- paste("/Users/bamflappy/Repos/DGEAnalysis_ShinyApps/data/tmp", outFile, sep = "/")
write.table(unlist(selectGO_one), file = outFile, sep = ",", quote = FALSE, row.names=FALSE, col.names = FALSE)

# retrieve selected GO term gene IDs
selectedTermTwo <- "GO:0000041"
selectGO_two <- allGO_BP[selectedTermTwo]

# euler diagram with significant stress GO terms
glm_list_venn_GO <-list(First = unlist(selectGO_one),
                        Second = unlist(selectGO_two))
euler_plot_GO <- euler(glm_list_venn_GO)#, shape = "ellipse")
plot(euler_plot_GO, quantities = list(type = c("counts")))#, fills = plotColors[1:6])

# save the plot
outTermTwo <- gsub(":", "_", selectedTermTwo)
exportFile <- paste(outTermOne, outTermTwo, sep = "_")
exportFile <- paste(exportFile, "eulerPlot.png", sep = "_")
exportFile <- paste("/Users/bamflappy/Repos/DGEAnalysis_ShinyApps/data/tmp", exportFile, sep = "/")
png(exportFile)
plot(euler_plot_GO, quantities = list(type = c("counts")))#, fills = plotColors[1:6])
dev.off()

#Summary functions
#numGenes(BP_GO_data)
#length(sigGenes(BP_GO_data))
#numGenes(MF_GO_data)
#length(sigGenes(MF_GO_data))
#numGenes(CC_GO_data)
#length(sigGenes(CC_GO_data))

# perform GO enrichment using the topGOdata objects
BP_GO_results <- runTest(BP_GO_data, statistic = 'ks')
#BP_GO_results <- runTest(BP_GO_data, statistic = 'fisher')
#MF_GO_results <- runTest(MF_GO_data, statistic = 'Fisher')
#CC_GO_results <- runTest(CC_GO_data, statistic = 'Fisher')

# save the topGOdata as an R data object
#outFile <- paste("test", "topGOdata_results.rds", sep="_")
#saveRDS(BP_GO_results, outFile)

# retrieve topGOdata objects for enrichment analysis (1 for each ontology)
#inFile <- paste("test", "topGOdata_results.rds", sep="_")
#BP_GO_results_test <- readRDS(inFile)

# check the names of GO terms
#head(names(BP_GO_results@score))
#geneData(BP_GO_results)

# store p-values as named list... ('score(x)' or 'x@score' returns named list of p-val's 
# where names are the GO terms)
pval_BP_GO <- score(BP_GO_results)
#pval_MF_GO <- score(MF_GO_results)
#pval_CC_GO <- score(CC_GO_results)

# plot histogram to see range of p-values
#exportFile <- paste(set, "pValueRanges.pdf", sep="_")
#pdf(file=exportFile)
#par(mfrow=c(3, 1),mar=c(1,1,1,1))
hist(pval_BP_GO, 35, xlab = "p-values", main = "Range of BP GO term p-values")
#hist(pval_MF_GO, 35, xlab = "p-values", main = "Range of MF GO term p-values")
#hist(pval_CC_GO, 35, xlab = "p-values", main = "Range of CC GO term p-values")
#dev.off()

# get statistics on GO terms
list_BP_GO_terms <- usedGO(BP_GO_data)
#list_MF_GO_terms <- usedGO(MF_GO_data)
#list_CC_GO_terms <- usedGO(CC_GO_data)

BP_GO_results_table <- GenTable(BP_GO_data, weightFisher = BP_GO_results, orderBy = 'weightFisher', 
                                topNodes = length(list_BP_GO_terms))
#MF_GO_results_table <- GenTable(MF_GO_data, weightFisher = MF_GO_results, orderBy = 'weightFisher', 
#                                topNodes = length(list_MF_GO_terms))
#CC_GO_results_table <- GenTable(CC_GO_data, weightFisher = CC_GO_results, orderBy = 'weightFisher', 
#                                topNodes = length(list_CC_GO_terms))

# write table of GO terms to a CSV file
#write.table(BP_GO_results_table, file=paste(set, "BP_GO_terms.csv", sep="_"), sep=",", row.names=FALSE, quote=FALSE)
#write.table(MF_GO_results_table, file=paste(set, "MF_GO_terms.csv", sep="_"), sep=",", row.names=FALSE, quote=FALSE)
#write.table(CC_GO_results_table, file=paste(set, "CC_GO_terms.csv", sep="_"), sep=",", row.names=FALSE, quote=FALSE)

# create table of significant GO terms
BP_sigGO_results_table <- BP_GO_results_table[BP_GO_results_table$weightFisher <= 0.05, ]
#MF_sigGO_results_table <- MF_GO_results_table[MF_GO_results_table$weightFisher <= 0.05, ]
#CC_sigGO_results_table <- CC_GO_results_table[CC_GO_results_table$weightFisher <= 0.05, ]

# write table of significant GO terms to a CSV file
#write.table(BP_sigGO_results_table, file=paste(set, "BP_sigGO_terms.csv", sep="_"), sep=",", row.names=FALSE, quote=FALSE)
#write.table(MF_sigGO_results_table, file=paste(set, "MF_sigGO_terms.csv", sep="_"), sep=",", row.names=FALSE, quote=FALSE)
#write.table(CC_sigGO_results_table, file=paste(set, "CC_sigGO_terms.csv", sep="_"), sep=",", row.names=FALSE, quote=FALSE)

# retrieve most significant GO term
BP_topSigGO_ID <- BP_GO_results_table[1, 'GO.ID']
#MF_topSigGO_ID <- MF_GO_results_table[1, 'GO.ID']
#CC_topSigGO_ID <- CC_GO_results_table[1, 'GO.ID']

# create density plots
#pdf(file = "/Users/bamflappy/Repos/DGEAnalysis_ShinyApps/data/tmp/example3_daphnia_topSigGO_Density.pdf")
showGroupDensity(BP_GO_data, whichGO = BP_topSigGO_ID, ranks = TRUE)
#showGroupDensity(MF_GO_data, whichGO = MF_topSigGO_ID, ranks = TRUE)
#showGroupDensity(CC_GO_data, whichGO = CC_topSigGO_ID, ranks = TRUE)
#dev.off()

# plot subgraphs induced by the most significant GO terms and save to a PDF file
#printGraph(BP_GO_data, BP_GO_results, firstSigNodes = 5, 
#           fn.prefix = "BP_sigGO_subgraphs", useInfo = "all", pdfSW = TRUE)
#printGraph(MF_GO_data, MF_GO_results, firstSigNodes = 5, 
#           fn.prefix ="MF_sigGO_subgraphs", useInfo = "all", pdfSW = TRUE)
#printGraph(CC_GO_data, CC_GO_results, firstSigNodes = 5, 
#           fn.prefix = "CC_sigGO_subgraphs", useInfo = "all", pdfSW = TRUE)


## 
# testing
##

# testing functions for evaluating input expressions for get_interesting_DE_genes
testInput <- "== 1"
testExp <- strsplit(testInput, split = " ")[[1]][1]
testComp <- strsplit(testInput, split = " ")[[1]][2]

testCheck <- try(
  if(eval(parse(text = paste(which(colors() == "1"), testExp, which(colors() == testComp), sep=" ")))){
    print("yes")
  },
  silent = TRUE
)
if(class(testCheck) == "try-error"){
  if(eval(parse(text = paste("1", testExp, testComp, sep=" ")))){
    print("yes")
  }
}

if(eval(parse(text = paste(which(colors() == "purple3"), "==", which(colors() == "purple3"), sep=" ")))){
  print("yes")
}

if(eval(parse(text = paste(which(colors() == "purple3"), "==", which(colors() == "green"), sep=" ")))){
  print("yes")
}

#showSigOfNodes(BP_GO_data, score(BP_GO_results), firstSigNodes = 5, useInfo = 'all')

#im.convert("BP_sigGO_subgraphs_weight01_5_all.pdf", output = "BP_sigGO_subgraphs_weight01_5_all.png", extra.opts="-density 150")

# function to retrieve interesting genes
retrieveInteresting <- function(){
  # split the input expression string
  inputExp <- strsplit(input$universeCut, split = " ")[[1]][1]
  inputStr <- strsplit(input$universeCut, split = " ")[[1]][2]
  # retrieve color list
  colorList <- colors()
  # function that returns list of interesting DE genes (0 == not significant, 1 == significant)
  get_interesting_DE_genes <- function(geneUniverse){
    interesting_DE_genes <- rep(0, length(geneUniverse))
    # check for color string inputs
    testCheck <- try(
      if(eval(parse(text = paste(which(colorList == geneUniverse[1]), inputExp, which(colorList == inputStr), sep=" ")))){
        print("yes")
      },
      silent = TRUE
    )
    if(class(testCheck) == "try-error"){
      for(i in 1:length(geneUniverse)){
        if(eval(parse(text = paste(geneUniverse[1], inputExp, inputStr, sep=" ")))){
          interesting_DE_genes[i] = 1
        }
      }
    }else{
      for(i in 1:length(geneUniverse)){
        if(eval(parse(text = paste(which(colorList == geneUniverse[1]), inputExp, which(colorList == inputStr), sep=" ")))){
          interesting_DE_genes[i] = 1
        }
      }
    }
    interesting_DE_genes <- setNames(interesting_DE_genes, names(geneUniverse))
    return(interesting_DE_genes)
  }
}
