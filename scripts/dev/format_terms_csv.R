# turn off scientific notation
library(topGO)
library(dplyr)
library(stringr)

options(scipen = 999)

algVal <- "weight01"
statVal <- "fisher"

resultsTable <- read.csv(file="/Users/bamflappy/MackLab/metabolic_adaptation/Biostatistics/DEAnalysis_14Sep2026/single_means_random_domesticus/genotype_M_Ad_dge_results.csv", row.names=1)

sigTable <<- read.csv(file="/Users/bamflappy/MackLab/metabolic_adaptation/Biostatistics/DEAnalysis_14Sep2026/single_means_random_domesticus/genotype_M_Ad_dge_sig_FDR_0.05_LFC_0.263034405833794.csv", row.names=1)

if (length(setdiff(rownames(sigTable), rownames(resultsTable))) == 0) {
  print("TRUE")
}

GO_file <- "/Users/bamflappy/MackLab/metabolic_adaptation/annotations/go_terms_coding_biomaRt.csv"
#GOmaps_input <- read.delim(file = GO_file, sep = "\t", row.names=NULL, colClasses = c(goid = "character"))
#if (length(colnames(GOmaps_input)) == 1) {
#  print("TRUE")
  # NOTE: the column with GO terms is assumed to be the second column and gene IDs the first column
  GOmaps_input <- read.delim(file = GO_file, sep = ",", row.names=NULL, colClasses = c("character", "character"))
#}
if (length(colnames(GOmaps_input)) == 1) {
  print("TRUE")
}

object.size(GOmaps_input)

#GOmaps_csv_out <- aggregate(GOmaps_input[2], GOmaps_input[1], FUN = toString)
#GOmaps_csv_out$Terms <- gsub(" ", "", GOmaps_input[2])

GOmaps_csv_out <- GOmaps_input %>%
  group_by(get(colnames(GOmaps_input[1]))) %>%
  summarise(terms = str_c(get(colnames(GOmaps_input[2])), collapse = ","))


#GOmaps_csv_out[2] <- str_remove_all(GOmaps_csv_out[2], " ")

write.table(GOmaps_csv_out, file = "/Users/bamflappy/Downloads/mappings_GO.fmt.txt", sep = "\t", quote = FALSE, row.names=FALSE)

GOmaps <- readMappings(file = "/Users/bamflappy/Downloads/mappings_GO.fmt.txt")

#head(as.numeric(resultsTable[["adj.P.Val"]]))
#head(as.numeric(resultsTable[[1]]))

sigCheck <- "filter"
universeCut <- "< 0.05"
list_genes <- as.numeric(resultsTable[["adj.P.Val"]])

#sigCheck <- "table"
#list_genes <- as.numeric(resultsTable[[1]])

# setup the lists
list_genes <- setNames(list_genes, rownames(resultsTable))
list_genes_filtered <- list_genes[names(list_genes) %in% names(GOmaps)]

# initialize list data
list_genes_sig <- rep(0, length(list_genes_filtered))
# check input significant data source
if (sigCheck == "table") {
  list_genes_sig <- setNames(list_genes_sig, names(list_genes_filtered))
  # set the significant genes
  list_genes_sig[names(list_genes_sig) %in% rownames(sigTable)] <- 1
} else if (sigCheck == "filter") {
  # loop over the gene universe
  for(i in 1:length(list_genes_filtered)){
    # check if significant
    if(eval(parse(text = paste(list_genes_filtered[i], universeCut, sep=" ")))){
      list_genes_sig[i] = 1
    }
  }
  # set the list names
  list_genes_sig <- setNames(list_genes_sig, names(list_genes_filtered))
}

length(list_genes_sig)
length(list_genes_sig[list_genes_sig == 1])
length(list_genes_sig[list_genes_sig == 0])

# function that returns list of interesting DE genes (0 == not significant, 1 == significant)
get_interesting_genes <- function(geneUniverseInput){
  interesting_DE_genes <- rep(0, length(geneUniverseInput))
  # loop over the gene universe
  for(i in 1:length(geneUniverseInput)){
    # check if significant
    if (is.na(geneUniverseInput[i])) {
      interesting_DE_genes[i] = 0
    }else if(geneUniverseInput[i] == 1){
      interesting_DE_genes[i] = 1
    }
  }
  interesting_DE_genes <- setNames(interesting_DE_genes, names(geneUniverseInput))
  return(interesting_DE_genes)
}

# create topGOdata objects for enrichment analysis (1 for each ontology)
GO_data <- new('topGOdata', ontology = "BP", allGenes = list_genes_sig, 
               geneSel = get_interesting_genes, nodeSize = 10, annot = annFUN.gene2GO, 
               gene2GO = GOmaps)

# perform GO enrichment using the topGOdata objects
GO_results <- runTest(GO_data, algorithm = algVal, statistic = statVal)
