## Differential Expression (DE) Analysis

A common task when working with transcriptomic data is the identification of differentially expressed (DE) genes or tags between groups. In this tutorial users will learn how to perform biostatistical analysis with the edgeR shiny app, including pairwise and analysis of variance (ANOVA) like comparisons to identify significantly DE genes.

### Objectives

<i>After completing this tutorial</i> you will know how to:
* analyze quantified transcriptomic data
* make comparisons using the experimental design
* perform pairwise and ANOVA-like comparisons
* use different types of plots to explore the data and results
* filter tables of DE genes by statistical and biological significance 
* retrieve tables of DE genes

#### Background



## edgeR

In this tutorial we will be performing differential expression (DE) analysis using [edgeR](https://bioconductor.org/packages/release/bioc/html/edgeR.html) R package. 



> [!NOTE]
> Note that the DESeq2 and edgeR packages perform similarly and have the same underlying hypothesis that most genes are not DE, but use different normalization methods that may change the number of detected DE genes.

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
packageList <- c("BiocManager", "shiny", "shinythemes", "ggplot2", "rcartocolor", "dplyr", "statmod", "pheatmap", "ggplotify")

biocList <- c("edgeR")

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

Before running the edgeR DE analysis app, make sure to have ready the two .csv files with the <b>gene counts</b> and <b>experimental design</b>. Example data for the edgeR app can be found in the <i>data/DEAnalysis</i> directory of the GitHub repository.

### Gene Counts Table

The following is a small example gene counts table:

```
Gene,SampleOne,SampleTwo,SampleThree,SampleFour,SampleFive,SampleSix
gene-1,0,10,111,1,0,1000,11,0
gene-2,0,20,222,2,0,2000,12,0
gene-3,0,30,333,3,0,3000,13,0
gene-4,0,40,444,4,0,4000,14,0
gene-5,0,50,555,5,0,5000,15,0
```

### Experimental Design Table

The experimental design file must also be in the format required by edgeR, for example: 

```
Sample,Group
SampleOne,cntrl
SampleTwo,cntrl
SampleThree,cntrl
SampleFour,treat
SampleFive,treat
SampleSix,treat
```

## Analysis Workflow

To run the edgeR app, open the R <b>script app_DEAnalysis.R</b> in Posit and press the <i>Run App</i> button in the upper right corner of the [source pane](https://docs.posit.co/ide/user/ide/guide/ui/ui-panes.html).

After the app is launched you will see the following pages:
1. <i>Getting Started</i> page with information for uploading data to start the analysis
2. <i>Processing</i> page that indicates the analysis has begun running
3. a page with separate tabs for each step in the analysis workflow, including:
* Tips 
* Data Normalization
* Data Exploration
* Analysis & Results
* Information

### Part One: Getting Started

Start in the left-hand sidebar by:
1. browsing for a <i>.csv</i> file with the gene counts
2. browsing for a <i>.csv</i> file with the experimental design
3. clicking the <i>Run Analysis</i> button, which appears after the input files are verified as valid for analysis

#### Helpful Tips
The following are some helpful tips for uploading appropriatly formatted data for DE analysis.
* The input raw gene counts table is expected to contain <i>numeric integer</i> values.
* Gene names in the first column of the input gene counts table are expected to be <i>character</i> values.
* Sample names in the first line of the gene counts table <i>must match</i> the sample names contained in the first column of the experimental design table.
* Sample names contained in the gene counts and experimental design tables are expected to be <i>character</i> values.
* The input gene counts and experimental design tables must end in the <i>.csv</i> file extension.

### Part Two: Data Normalization

After uploading the gene counts and experimental design, the sample libraries are normalized using Trimmed Mean of M-values (TMM) normalization. Normalized values are calcuated in counts per million (CPM) using the normalized library sizes. Note, however, that TMM normalization factors do not take into account library sizes.

> [!NOTE]
> A library is the collection of RNA-seq reads associated with a sample.

#### Data Normalization

##### Library Sizes Before Normalization

The plot of library sizes shows the sequencing library size for each sample before Trimmed Mean of M-values (TMM) normalization. 

##### Number of Genes with Sufficiently Large Counts

Here filtering is also performed to remove genes that were identified as not sufficiently expressed under the experimental conditions. The negative binomial distribution is used to identify genes with sufficiently large counts to be considered a real signal.

##### Normalized Gene Counts Table

It is possible to download the normalized gene counts table here, which can be used in the downstream network analysis.

### Part Three: Data Exploration

#### Data Exploration

#### Principal Component Analysis

Principal component analysis (PCA) is commonly used to visualize the signal to noise relationship within a data set. For example, the patterns of variation between and within groups.

In a PCA plot the distances between samples approximate the expression differences. The expression differences were calculated as the the average of the largest absolute LFCs between each pair of samples and the same genes were selected for all comparisons. 

> [!NOTE]
> Note that the points are replaced by the sample name and colored by the associated factor level.

#### Multid-Densional Scaling

In a multi-dimensional scaling (MDS) plot the distances between samples approximate the expression differences. The expression differences were calculated as the the average of the largest absolute LFCs between each pair of samples and the top genes were selected separately for each pairwise comparison. 

Note that the points are replaced by the sample name and colored by the associated factor level.

#### Heatmap of Samples

The heatmap shows the hierarchical clustering of individual samples by the log2 CPM expression values. Furthermore, the log2 CPM that has undefined values avoided and poorly defined LFC for low counts shrunk towards zero

#### Biological Coefficient of Variation

The biological coefficient of variation (BCV) plot shows the square root of the dispersion parameter under the negative binomial model, which is equivalent to estimating the dispersions of the negative binomial model.

The negative binomial distribution is used to identify genes with sufficiently large counts to be considered a real signal and measures what it expects to be missing data, or a measure of dispersion. For example, a BCV^2 of 0.4 indicates a 20% difference between samples.

The negative binomial distribution models biological noise rather than sequencing noise (e.g., library size normalization).

### Part Four: Analysis & Results

#### Pairwise Comparison

Exact tests are performed to identify differences in the means between two groups of negative-binomially distributed counts. A comparison or contrast is a linear combination of means for groups of samples.

<b>Start</b> by choosing the factor levels for comparison, then click the <i>Analyze</i> button.

##### Pairwise Results

###### Mean-Differences of Pairwise DE Genes

The mean-difference (MD) plot shows the log2 fold changes (LFCs) in expression differences versus average log2 CPM values. Red points are significantly up-expressed genes and the blue points are significantly down-expressed, where signifigance was determined by the input FDR cut off. The blue lines indicate the input LFC cut off, which will be used to further filter the set of significantly DE genes.

###### Number of Significantly DE Genes

The output table shows the number of significantly DE genes that were up- or down-expressed in the input comparison. Signifigance was determined by the input LFC and FDR cut offs.

###### DE Analysis Results Tables and Lists

A table with the pairwise DGE analysis results sorted by increasing FDR adjusted p-values may be downloaded. Also, a list of the DE gene IDs from the pairwise analysis may be downloaded.

A table with the pairwise DGE analysis significant results sorted by increasing FDR adjusted p-values may be downloaded. Also, a list of the significantly DE gene IDs from the pairwise analysis may be downloaded by clicking the above button. 

> [!NOTE]
> Signifigance was determined by the input LFC and FDR cut offs.

##### Results Exploration

###### Heatmap of Pairwise DE Genes

The heatmap displays the hierarchical clustering of individual samples by the log2 CPM expression values of significantly DE genes from the pairwise analysis. Signifigance was determined by the input FDR and LFC cut offs.

> [!WARNING]
> The heatmap function requires at least 2 significantly DE genes to create the plot.

###### Volcano Plot of Pairwise DE Genes

The volcano plot displays the association between statistical significance (e.g., p-value) and magnitude of gene expression (fold change). Signifigance and magnitude were determined by the input FDR and LFC cut offs.

#### GLM Comparison

The GLM is used to perform an ANOVA-like analysis to identify any significant main effect associated with an explanatory variable. An explanatory variable may be a categorical factor with two or more levels, such as treat and cntrl.

Additionally, genes above the input log2 fold change (LFC) threshold are identified as significantly DE using t-tests relative to a threshold (TREAT) with the glmTreat function of edgeR. If the input LFC cut off is set to 0 in the app then the glmQLFTest function is used instead.

<b>Start</b> by entering an expression for comparison, then click the <i>Analyze</i> button.

> [!CAUTION]
> Make sure that the factors used in the expression are spelled the same as in the experimental design file and shown in the left-hand sidebar.

Valid expressions must consist of the factors contained in the input experimental design file, which is displayed in the left-hand sidebar.

> [!TIP]
> Examples of designing model expressions for ANOVA-like tests are availble in the [edgeR user guide](https://www.bioconductor.org/packages/devel/bioc/vignettes/edgeR/inst/doc/edgeRUsersGuide.pdf) (e.g., sections 3.2.6 & 4.4.9).
> Also, a detailed description of designing model expressions is provided in the paper "A guide to creating design matrices for gene expression experiments" <i>doi: 10.12688/f1000research.27893.1</i> (e.g., studies with multiple factors).

##### GLM Results

###### Mean-Differences of GLM DE Genes

The mean-difference (MD) plot shows the LFCs in expression differences versus average log2 CPM values. Red points are significantly up-expressed genes and the blue points are significantly down-expressed, where signifigance was determined by the input FDR and LFC cut offs. The blue lines indicate the input LFC cut off, which was used by the glmTreat function to determine significantly DE genes relative to the LFC threshold.

###### Number of Significantly DE Genes

The output table shows the number of significantly DE genes that were up- or down-expressed in the input comparison. Signifigance was determined by the input LFC and FDR cut offs.

###### DE Analysis Results Tables and Lists

A table with the GLM DGE analysis results sorted by increasing FDR adjusted p-values may be downloaded. Also, a list of the DE gene IDs from the GLM analysis may be downloaded.

A table with the GLM DGE analysis significant results sorted by increasing FDR adjusted p-values may be downloaded. Also, a list of the significantly DE gene IDs from the GLM analysis may be downloaded by clicking the above button. 

> [!NOTE]
> Signifigance was determined by the input LFC and FDR cut offs.

##### Model Exploration

Output is a plot of the genewise quasi-likelihood (QL) dispersion against the log2 CPM gene expression levels. Dispersion estimates are obtained after fitting negative binomial models and calculating dispersion estimates.

##### Results Exploration

###### Heatmap of GLM DE Genes

The heatmap displays the hierarchical clustering of individual samples by the log2 CPM expression values of significantly DE genes from the GLM analysis. Signifigance was determined by the input FDR and LFC cut offs.

> [!WARNING]
> The heatmap function requires at least 2 significantly DE genes to create the plot.

###### Volcano Plot of GLM DE Genes

The above volcano plot displays the association between statistical significance (e.g., p-value) and magnitude of gene expression (fold change). Signifigance and magnitude were determined by the input FDR and LFC cut offs.

## Example Script

An example R script named <b>script_DEAnalysis.R</b> with code for performing the same analysis as in the edgeR R Shiny app can be found in the <i>scripts</i> directory of the GitHub repository. 

> [!IMPORTANT]
> The script is hard coded to work for an example data set and will need to be customized for use with other data sets.
