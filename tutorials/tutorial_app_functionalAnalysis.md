## Functional Analysis

Functional analysis is a typical approach to interpreting gene expression data and identify potential biological mechanisms. After determining sets significantly of DE genes or genes associated with different network modules, it is possible to perform enrichment or over-representation analysis. 

### Objectives

<i>After completing this tutorial</i> you will know how to:
* learn how to download gene-to-GO annotations from PANNZER2 for input to topGO, <i>if necessary</i>
* perform enrichment and over-representation analysis
* use different types of plots to explore the data and results
* retrieve tables of significant biological process, molecular function, and cellular component GO terms

### Background



## topGO



## Installation

> [!TIP]
> The edgeR app can be run on a computer locally using Posit. To run the app locally we need to download the edgeR R Shiny app script. The script is in a GitHub repository and can be downloaded [HERE](https://github.com/ElizabethBrooks/DGEAnalysis_ShinyApps/tree/main).

<b>First,</b> download the GitHub repository using the git clone command in the terminal, for example:

```
git clone https://github.com/ElizabethBrooks/DGEAnalysis_ShinyApps.git
```

<b>Next,</b> if running the app locally, we will need to install or update [R and Posit](https://posit.co/download/rstudio-desktop/) (formerly RStudio).

<b>Lastly,</b> we need to install all of the necessary R packages with the software needed to run edgeR and create plots with the results:

```
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
```

The above code can also be found at the top of the R script for the edgeR app, which is located in the <i>apps</i> directory of the GitHub repository that we downloaded.

## Data Format

Before running the topGO functional analysis app, make sure to have ready the two tables with the <b>gene scores</b> and <b>mappings</b>. Example data for the topGO app can be found in the <i>data/functionalAnalysis</i> directory of the GitHub repository.

### Gene Scores Table

#### DE Analysis Results

The following is a small example gene scores table resulting from DE analysis:

```
Gene,logFC,logCPM,PValue,FDR
gene-1,2.61,8.46,0.00,0.44
gene-2,-2.78,9.39,0.45,0.45
gene-3,0.78,7.77,0.45,0.45
gene-4,-1.34,7.99,0.45,0.45
gene-5,2.00,8.28,0.45,0.45
```

#### Network Analysis Results

The following is a small example gene scores table resulting from network analysis:

```
gene,color,number
geneA,brown,1
geneB,brown,1
geneC,brown,1
geneD,grey,0
geneE,grey,0
```

### Mappings Table

#### topGO

The following is a small example table of topGO gene-to-GO term mappings:

```
Gene  Terms
geneA GO:0005730,GO:0030490
geneB GO:0006890,GO:0030173,GO:0005783,GO:0006621
geneC GO:0006355
geneD GO:0005739,GO:0008203,GO:0006744,GO:0015039
```

#### PANNZER2

The following is a small example table of pannzer2 gene-to-GO annotations:

```
qpid  goid  ontology  desc  ARGOT_RSscore ARGOT_RSPPV ARGOT_RSrank  goclasscount
geneA 0009360 CC  DNA polymerase III complex  9.351550793 0.748726035 1 100
geneA 0008408 MF  3'-5' exonuclease activity  8.193028339 0.720312733 1 100
geneA 0071897 BP  DNA biosynthetic process  6.425739587 0.672768098 1 100
geneB 0003887 MF  DNA-directed DNA polymerase activity  7.915962904 0.713224862 2 100
geneB 0006260 BP  DNA replication 5.993446976 0.660171634 2 100
```

## Analysis Workflow

To run the functional analysis app, open the R <b>script app_shiny_functionalAnalysis.R</b> in Posit and press the <i>Run App</i> button in the upper right corner of the [source pane](https://docs.posit.co/ide/user/ide/guide/ui/ui-panes.html).

After the app is launched you will see the following pages:
1. <i>Getting Started</i> page with information for uploading data to start the analysis
2. <i>Processing</i> page that indicates the analysis has begun running
3. a page with separate tabs for each step in the analysis workflow, including:
* Tips 
* Analysis
* Results
* Information

### Part One: Getting Started

Start in the left-hand sidebar by:
1. entering the statistic for gene scoring, for example:
* <i>FDR</i> from DGE results
* module <i>number</i> from WGCNA results
2. entering the expression for gene scoring, for example:
* <b>< 0.05</b> for specifying significant DEGs using a <b>FDR</b> cut off
* <b>== 1</b> for specifying a specific module <b>number</b> from WGCNA
3. uploading a gene score table <i>.csv</i> file with the <i>unfiltered</i> results table from DGE or WGCNA
4. uploading a mappings table <i>.txt</i> file with the gene-to-GO term annotation mappings formatted as either:
* topGO expected gene-to-GO mappings
* pannzer2 resulting GO prediction details
5. clicking the <i>Upload</i> button to check that the inputs are valid, which appears after the format of the inputs are checked
6. clicking the <i>Run Analysis</i> button, which appears after the input files are verified as valid for analysis

> [!NOTE]
> Note that module <i>color</i> is currently not supported as an input statistic.

#### Helpful Tips
The following are some helpful tips for uploading appropriatly formatted data for functional analysis.
1. The topGO package expects gene-to-GO mappings files to be specifically formatted where:
* the first column must contain gene IDs and the second column GO terms
* the second column of GO terms must be in a comma separated list format
* the first column must be tab or space separated from the second column
* the first column of gene IDs must match the gene IDs contained in the gene score table
2. It is possible to create a gene-to-GO term annotations table with [PANNZER2](http://ekhidna2.biocenter.helsinki.fi/sanspanz/) by:
* <b>first,</b> navigating to the <i>Annotate</i> tab
* <b>second,</b> uploading a list of protein sequences where the sequence names <i>must match</i> the gene names in the input gene score table
* <b>third,</b> selecting <i>Batch queue</i> and entering your email
* <b>fourth,</b> selecting the <i>GO prediction details</i> link after recieving the pannzer2 results
* <b>fifth,</b> right clicking and selecting <i>Save As...</i> to download the GO.out.txt annotations table
3. The input gene score table should <i>not</i> be filtered in advance. The functional analysis requires the complete gene universe, which includes all genes detected in the experiment regardless of signifigance in DGE or WGCNA.
4. The input gene score statistic <i>must match</i> the name of a column in the input gene score table.
5. The first column of the gene score table is expected to contain gene IDs.
6. The gene score tables are required to contain two columns with gene IDs and gene scores at <i>minimum</i>.

### Part Two: Analysis

#### Functional Analysis

Begin the functional enrichment or over-representation analysis by selecting a test statistic and algorithm.

> [!NOTE]
> Further details about the available types of enrichment tests can be found in the [topGO documentation](https://bioconductor.org/packages/devel/bioc/vignettes/topGO/inst/doc/topGO.pdf) (e.g., section 6).
> Also, refer to the topGO manual for more information regarding the available algorithms and test statistics.

##### Available Algorithms
1. Default algorithm used by the topGO package is a mixture between the <i>elim</i> and <i>weight</i> algorithms
2. Classic algorithm performs functional analysis by testing the over-representation of GO terms within the group of diferentially expressed genes
3. Elim algorithm is more conservative then the classic method and you may expect the p-values returned by the former method to be lower bounded by the p-values returned by the later method

##### Available Test Statistics
1. Fisher's exact test is based on gene counts and can be used to perform over representation analysis of GO terms
2. Kolmogorov-Smirnov (KS) like test computes enrichment or rank based on gene scores and can be used to perform gene set enrichment analysis (GSEA)

> [!TIP]
> It is possible to use both the fisher's and KS tests for DE analysis results since each gene in the results table has a score, which represents how it is diferentially expressed.

#### Range of GO Term P-Values

The histograms shows the range and frequency of p-values from the enrichment tests for each GO level (BP, MF, or CC).

#### Density Plots of GO Terms

To draw the density plot for a particular GO term, select a GO term category and enter a GO term ID.

> [!WARNING]
> Only significant GO terms may be plotted.

The density plot shows the distribution of the gene's rank for the top GO term of each GO level (BP, MF, or CC). The gene's rank is compared with the null distribution.

> [!CAUTION]
> Make sure that the GO category is valid for the input GO term ID.

#### Dot Plot of Most Significant GO Terms

The dot plot of most significant GO terms requires the selection of a p-value cut off.

> [!NOTE]
> Note that the computed p-values are unadjusted for multiple testing.

The dot plot shows <i>up to the top 5</i> most enriched or overrepresented GO terms for each level (BP, MF, CC). The size of the dots indicate the number of significant genes annotated to the GO term. The dots are colored by the enrichment test p-values.

#### Subgraphs of Most Significant GO Terms

To draw the subgraphs of most significant GO terms, select a GO term category and the number of nodes.

The subgraph induced by the selected number of top (most significant) GO terms identifed by the selected algorithm for scoring GO terms for enrichment. Rectangles indicate the most signifcant terms with colors representing the relative signifcance, which ranges from dark red (most signifcant) to bright yellow (least signifcant).

For each <i>node</i>, some basic information is displayed. The frst two lines show the GO identifer and a trimmed GO name. In the third line the raw p-value is shown. The forth line is showing the number of signifcant genes and the total number of genes annotated to the respective GO term.

> [!IMPORTANT]
> The subgraphs must be downloaded to be viewed.

### Part Three: Results

#### Functional Analysis Results

Results from the GO term enrichment analysis may be downloaded by selecting a GO term category and p-value cut off.

It is also possible to download the table of gene-to-GO term annotation mappings for each gene, which has been formatted for use with topGO.

> [!NOTE]
> Note that the computed p-values are unadjusted for multiple testing.

## Example Script

An example R script named <b>script_EXAMPLE.R</b> with code for performing the same analysis as in the edgeR R Shiny app can be found in the <i>scripts</i> directory of the GitHub repository. 

> [!IMPORTANT]
> The script is hard coded to work for an example data set and will need to be customized for use with other data sets.
