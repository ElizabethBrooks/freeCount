#!/usr/bin/env Rscript

# creator: Elizabeth Brooks
# updated: 2 April 2024

# install any missing packages
packageList <- c("BiocManager", "shiny", "shinythemes", "dplyr", "matrixStats", "Hmisc", "splines", "foreach", "doParallel", "fastcluster", "dynamicTreeCut", "survival")
biocList <- c("WGCNA", "GO.db", "impute", "preprocessCore")
newPackages <- packageList[!(packageList %in% installed.packages()[,"Package"])]
newBioc <- biocList[!(biocList %in% installed.packages()[,"Package"])]
if(length(newPackages)){
  install.packages(newPackages)
}
if(length(newBioc)){
  BiocManager::install(newBioc)
}

# load libraries
library(shiny)
library(shinythemes)
library(WGCNA)
library(dplyr)

#The following setting is important, do not omit.
options(stringsAsFactors = FALSE)

# Allow multi-threading within WGCNA. At present this call is necessary.
# Any error here may be ignored but you may want to update WGCNA if you see one.
# Caution: skip this line if you run RStudio or other third-party R environments.
# See note above.
#enableWGCNAThreads()


##
# Data Input
##

#Import normalized gene count data
inputTable_subset <- read.csv(file = "/Users/bamflappy/Repos/DGEAnalysis_ShinyApps/data/WGCNA/example3_daphnia_normalizedCounts.csv", row.names=1)

# load in the trait data
allTraits <- read.csv("/Users/bamflappy/Repos/DGEAnalysis_ShinyApps/data/WGCNA/example3_daphnia_design_WGCNA.csv", row.names=1)

dim(allTraits)
names(allTraits)


##
# Data Prep
##

# transpose each subset
datExpr0 = data = as.data.frame(t(inputTable_subset))
names(datExpr0) = rownames(inputTable_subset)
rownames(datExpr0) = names(inputTable_subset)

#Check the genes across all samples
gsg = goodSamplesGenes(datExpr0, verbose = 3)
gsg$allOK

# remove the offending genes and samples from the data
if (!gsg$allOK){
  # Optionally, print the gene and sample names that were removed:
  if (sum(!gsg$goodGenes)>0)
    printFlush(paste("Removing genes:", paste(names(datExpr0)[!gsg$goodGenes], collapse = ", ")));
  if (sum(!gsg$goodSamples)>0)
    printFlush(paste("Removing samples:", paste(rownames(datExpr0)[!gsg$goodSamples], collapse = ", ")));
  # Remove the offending genes and samples from the data:
  datExpr0 = datExpr0[gsg$goodSamples, gsg$goodGenes]
}

# cluster the samples to see if there are any obvious outliers
sampleTree = hclust(dist(datExpr0), method = "average")
# Plot the sample tree: Open a graphic output window of size 12 by 9 inches
# The user should change the dimensions if the window is too large or too small.
#exportFile <- paste(tag, "sampleClustering.png", sep="_")
#png(file = exportFile, width = 12, height = 9, units="in", res=150)
sizeGrWindow(12,9)
par(cex = 0.6)
par(mar = c(0,4,2,0))
plot(sampleTree, main = "Sample clustering to detect outliers", sub="", xlab="", cex.lab = 1.5,
     cex.axis = 1.5, cex.main = 2)
# Plot a line to show the cut
abline(h = sampleTree$height[1], col = "red")
dev.off()

# Determine cluster under the line
clust = cutreeStatic(sampleTree, cutHeight = sampleTree$height[1], minSize = 1)
table(clust)
# clust 1 contains the samples we want to keep.
keepSamples = (clust==1)

# filter out samples
datExpr <- datExpr0
#datExpr = datExpr0[keepSamples, ]
nGenes = ncol(datExpr)
nSamples = nrow(datExpr)

# Form a data frame analogous to expression data that will hold the clinical traits
samples = rownames(datExpr)
traitRows = match(samples, rownames(allTraits))
datTraits = allTraits[traitRows,]
collectGarbage()

# Re-cluster samples
#exportFile <- paste(tag, "sampleDendrogram_traitHeatmap.png", sep="_")
#png(file = exportFile, width = 10, height = 7, units="in", res=150)
sizeGrWindow(10,7)
sampleTree2 = hclust(dist(datExpr), method = "average")
# Convert traits to a color representation: white means low, red means high, grey means missing entry
traitColors = numbers2colors(datTraits, signed = FALSE)
# Plot the sample dendrogram and the colors underneath.
plotDendroAndColors(sampleTree2, traitColors,
                    groupLabels = names(datTraits),
                    main = "Sample dendrogram and trait heatmap")
dev.off()

# save the relevant expression and trait data for use in the next steps
#exportFile <- paste(tag, "dataInput.RData", sep="-")
#save(datExpr, datTraits, file = exportFile)


##
# Pick Soft Thresholding Powers
##

# Choose a set of soft-thresholding powers
powers = c(c(1:10), seq(from = 12, to=36, by=2))
# Call the network topology analysis function
sft = pickSoftThreshold(datExpr, powerVector = powers, verbose = 5)
# Plot the results
cex1 = 0.9
#exportFile <- paste(genotype, "SoftPowers.png", sep="_")
#png(file = exportFile, wi = 9, he = 5, units="in", res=150)
sizeGrWindow(9, 5)
par(mfrow = c(1,2))
# Scale-free topology fit index as a function of the soft-thresholding power
plot(sft$fitIndices[,1], -sign(sft$fitIndices[,3])*sft$fitIndices[,2],
     xlab="Soft Threshold (power)",ylab="Scale Free Topology Model Fit,signed R^2",type="n",
     main = paste("Scale independence"));
text(sft$fitIndices[,1], -sign(sft$fitIndices[,3])*sft$fitIndices[,2],
     labels=powers,cex=cex1,col="red");

# this line corresponds to using an R^2 cut-off of h
abline(h=0.80,col="red")
abline(h=0.90,col="blue")
# Mean connectivity as a function of the soft-thresholding power
plot(sft$fitIndices[,1], sft$fitIndices[,5],
     xlab="Soft Threshold (power)",ylab="Mean Connectivity", type="n",
     main = paste("Mean connectivity"))
text(sft$fitIndices[,1], sft$fitIndices[,5], labels=powers, cex=cex1,col="red")
dev.off()


##
# Network Construction
##

# set the soft thresholding power
softPower = 9

# We like large modules, so we set the minimum module size relatively high:
minModuleSize = 60

# determine adjacency
adjacency = adjacency(datExpr, power = softPower)

# Turn adjacency into topological overlap
TOM = TOMsimilarity(adjacency)
dissTOM = 1-TOM

# Call the hierarchical clustering function
geneTree = hclust(as.dist(dissTOM), method = "average")
# Plot the resulting clustering tree (dendrogram)
#exportFile <- paste(genotype, minModuleSize, sep="_")
#exportFile <- paste(exportFile, "geneClustering.png", sep="_")
#png(file = exportFile, wi = 12, he = 9, units="in", res=150)
sizeGrWindow(12,9)
plot(geneTree, xlab="", sub="", main = "Gene clustering on TOM-based dissimilarity",
     labels = FALSE, hang = 0.04)
dev.off()

# Module identification using dynamic tree cut:
dynamicMods = cutreeDynamic(dendro = geneTree, distM = dissTOM,
                            deepSplit = 2, pamRespectsDendro = FALSE,
                            minClusterSize = minModuleSize)
table(dynamicMods)

# Convert numeric lables into colors
dynamicColors = labels2colors(dynamicMods)
table(dynamicColors)
# Plot the dendrogram and colors underneath
#exportFile <- paste(genotype, minModuleSize, sep="_")
#exportFile <- paste(exportFile, "dynamicTreeCut.png", sep="_")
#png(file = exportFile, wi = 8, he = 6, units="in", res=150)
sizeGrWindow(8,6)
plotDendroAndColors(geneTree, dynamicColors, "Dynamic Tree Cut",
                    dendroLabels = FALSE, hang = 0.03,
                    addGuide = TRUE, guideHang = 0.05,
                    main = "Gene dendrogram and module colors")
dev.off()

# Calculate eigengenes
MEList = moduleEigengenes(datExpr, colors = dynamicColors)
MEs = MEList$eigengenes
# Calculate dissimilarity of module eigengenes
MEDiss = 1-cor(MEs);
# Cluster module eigengenes
METree = hclust(as.dist(MEDiss), method = "average");
# Plot the result
#exportFile <- paste(genotype, minModuleSize, sep="_")
#exportFile <- paste(exportFile, "clusteringME.png", sep="_")
#png(file = exportFile, wi = 7, he = 6, units="in", res=150)
sizeGrWindow(7, 6)
plot(METree, main = "Clustering of module eigengenes",
     xlab = "", sub = "")
# choose a height cut of 0.25, corresponding to correlation of 0.75, to merge
MEDissThres = 0.25
# Plot the cut line into the dendrogram
abline(h=MEDissThres, col = "red")
dev.off()

# Call an automatic merging function
merge = mergeCloseModules(datExpr, dynamicColors, cutHeight = MEDissThres, verbose = 3)
# The merged module colors
mergedColors = merge$colors;
# Eigengenes of the new merged modules:
mergedMEs = merge$newMEs

# plot the gene dendrogram again, with the 
# original and merged module colors underneath
#exportFile <- paste(genotype, minModuleSize, sep="_")
#exportFile <- paste(exportFile, "geneDendro-3.png", sep="_")
#png(file = exportFile, wi = 12, he = 9, units="in", res=150)
sizeGrWindow(12, 9)
plotDendroAndColors(geneTree, cbind(dynamicColors, mergedColors),
                    c("Dynamic Tree Cut", "Merged dynamic"),
                    dendroLabels = FALSE, hang = 0.03,
                    addGuide = TRUE, guideHang = 0.05)
dev.off()

# Rename to moduleColors
moduleColors = mergedColors
# Construct numerical labels corresponding to the colors
colorOrder = c("grey", standardColors(50));
moduleLabels = match(moduleColors, colorOrder)-1;
MEs = mergedMEs;

# create list of module colors mapped to numbers
numMods <- length(unique(moduleColors))
colorTable <- data.frame(
  color = unique(moduleColors),
  number = seq(from = 1, to = numMods, by = 1)
)

# initialize module data frame
resultsTable <- data.frame(
  gene = character(),
  color = character(),
  number = numeric()
)

# match gene IDs with module colors
for(i in 1:numMods){
  gene <- names(datExpr)[moduleColors==colorTable[i,1]]
  color <- rep(colorTable[i,1], length(gene))
  number <- rep(colorTable[i,2], length(gene))
  moduleData <- cbind(gene, color, number)
  resultsTable <- rbind(resultsTable, moduleData)
}

# Save module colors and labels for use in subsequent parts
#exportFile <- paste(genotype, minModuleSize, sep="_")
#exportFile <- paste(exportFile, "networkConstruction-stepByStep.RData", sep="-")
#save(MEs, moduleLabels, moduleColors, geneTree, file = exportFile)

