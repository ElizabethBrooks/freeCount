# creator: Elizabeth Brooks
# updated: 12 April 2024

#### Setup ####

# install any missing packages
packageList <- c("BiocManager", "shiny", "shinythemes", "ggplot2", "rcartocolor", "tidyr", "eulerr")
biocList <- c("topGO", "Rgraphviz")
newPackages <- packageList[!(packageList %in% installed.packages()[,"Package"])]
newBioc <- biocList[!(biocList %in% installed.packages()[,"Package"])]
if(length(newPackages)){
  install.packages(newPackages)
}
if(length(newBioc)){
  BiocManager::install(newBioc)
}

# TO-DO: double check this increase on maximum upload size for servers
options(shiny.maxRequestSize=30*1024^2)

# load packages
suppressPackageStartupMessages({
  library(shiny)
  library(shinythemes)
  library(topGO)
  library(ggplot2)
  library(Rgraphviz)
  library(eulerr)
  library(tidyr)
  library(rcartocolor)
})

# plotting palette
plotColors <- carto_pal(12, "Safe")
dotPlotColors <- c(plotColors[5], plotColors[6])
eulerPlotColors <- c(plotColors[6], plotColors[7])

# setup defaults
defaultAlg <- "weight01"
defaultStat <- "fisher"
defaultP <- 0.05
defaultTermOne <- "GO:0008150"
defaultTermTwo <- "GO:0065007"

# TO-DO: fix download tables for other ontology levels
# TO-DO: change input expression to combo of text field and radio buttons
# TO-DO: add bar plot of gene LFC (if DE genes)
# TO-DO: output example tables as csv
# TO-DO: check mappings table output (error for two rows with duplicate names)

#### UI ####

# Define UI 
ui <- fluidPage(
  # view available themes
  #shinythemes::themeSelector(),
  
  # use a theme
  theme = shinytheme("yeti"),
  #theme = shinytheme("superhero"),
  
  # add application title
  titlePanel("Functional Analysis with topGO"),
  
  # setup sidebar layout
  sidebarLayout(
      
    # setup sidebar panel
    sidebarPanel(
      
      # TO-DO: fix scoreStat to allow or prohibit "color"
      # also, limit the input stat options
      # show panel depending on run analysis check
      conditionalPanel(
        condition = "!input.runAnalysis",
        # request inputs
        tags$p(
          "Enter Statistic for Gene Scoring:"
        ),
        textInput(
          inputId = "scoreStat",
          label = NULL,
          value = "FDR"
        ),
        tags$p(
          "Enter Expression for Gene Scoring:"
        ),
        textInput(
          inputId = "universeCut",
          label = NULL,
          value = "< 0.05"
        ),
        tags$p(
          "Upload Gene Score Table (*.csv):"
        ),
        fileInput(
          "analysisTable", 
          label = NULL,
          multiple = FALSE,
          accept = ".csv"
        ),
        tags$p(
          "Upload Mappings Table (*.txt):"
        ),
        fileInput(
          "mappings", 
          label = NULL,
          multiple = FALSE,
          accept = "text"
        )
      ),
      # show panel depending on input files check
      conditionalPanel(
        #condition = "output.dataUploaded && input.runUpload",
        condition = "output.dataUploaded && !input.runAnalysis",
        tags$hr(),
        tags$p(
          "Click to Run Analysis:"
        ),  
        actionButton("runAnalysis", "Run Analysis")
      ),
      # show panel depending on analysis run
      conditionalPanel(
        condition = "input.runAnalysis",
        tags$p(
          "Current Analysis Settings:"
        ), 
        tableOutput(outputId = "inputSettings")
      )
    ),
    
    # Output: Show plots
    mainPanel(
      
      # getting started text
      conditionalPanel(
        condition = "!input.runAnalysis",
        tags$h1(
          align = "center",
          "Getting Started"
        ),
        tags$br(),
        tags$p(
          HTML("<b>Hello!</b>"),
          HTML("Start in the left-hand sidebar by:")
        ),
        tags$p(
          HTML("<b>1.</b> entering the statistic for gene scoring, for example:")
        ),
        tags$p(
          HTML("<ul><li><i>FDR</i> from DE analysis results</li></ul>")
        ),
        tags$p(
          HTML("<ul><li>module <i>number</i> from WGCNA results</li></ul>")
        ),
        tags$p(
          HTML("<b>2.</b> entering the expression for gene scoring, for example:")
        ),
        tags$p(
          HTML("<ul><li><i>< 0.05</i> for specifying significant DE genes using a <i>FDR</i> cut off</li></ul>")
        ),
        tags$p(
          HTML("<ul><li><i>== 1</i> for specifying a specific module <i>number</i> from WGCNA</li></ul>")
        ),
        tags$p(
          HTML("<b>3.</b> uploading a gene score table <i>.csv</i> file with the <i>unfiltered</i> results table from DE analysis or WGCNA")
        ),
        tags$p(
          HTML("<b>4.</b> uploading a mappings table <i>.txt</i> file with the gene-to-GO term annotation mappings formatted as either:")
        ),
        tags$p(
          HTML("<ul><li>topGO expected gene-to-GO mappings</li></ul>")
        ),
        tags$p(
          HTML("<ul><li>PANNZER2 resulting <i>GO prediction details</i></li></ul>")
        ),
        #tags$p(
        #  HTML("<b>5.</b> clicking the <i>Upload</i> button to check that the inputs are valid, which appears after the format of the inputs are checked")
        #),
        tags$p(
          HTML("<b>5.</b> clicking the <i>Run Analysis</i> button, which appears after the format of the input files are checked and verified as valid for analysis")
        ),
        tags$br(),
        tags$p(
          "Note that the GO term analysis results and plots may take several moments to process depending on the size of the input tables."
        ),
        tags$hr(),
        tags$p(
          align="center",
          HTML("<b>Helpful Tips</b>")
        ),
        tags$br(),
        tags$p(
          HTML("<b>Tip 1:</b> The topGO package expects gene-to-GO mappings files to be specifically formatted where:")
        ),
        tags$p(
          HTML("<ul><li>the first column must contain gene IDs and the second column GO terms</li></ul>")
        ),
        tags$p(
          HTML("<ul><li>the second column of GO terms must be in a comma separated list format</li></ul>")
        ),
        tags$p(
          HTML("<ul><li>the first column must be tab or space separated from the second column</li></ul>")
        ),
        tags$p(
          HTML("<ul><li>the first column of gene IDs must match the gene IDs contained in the gene score table</li></ul>")
        ),
        tags$p(
          HTML("<b>Tip 2:</b> It is possible to create a gene-to-GO term annotations table with "),
          tags$a("PANNZER2",href = "http://ekhidna2.biocenter.helsinki.fi/sanspanz/"),
          " by:"
        ),
        tags$p(
          HTML("<ul><li><b>first,</b> navigating to the <i>Annotate</i> tab</li></ul>")
        ),
        tags$p(
          HTML("<ul><li><b>second,</b> uploading a list of protein sequences where the sequence names <i>must match</i> the gene names in the input gene score table</li></ul>")
        ),
        tags$p(
          HTML("<ul><li><b>third,</b> selecting <i>Batch queue</i> and entering your email</li></ul>")
        ),
        tags$p(
          HTML("<ul><li><b>fourth,</b> selecting the <i>GO prediction details</i> link after recieving the PANNZER2 results</li></ul>")
        ),
        tags$p(
          HTML("<ul><li><b>fifth,</b> right clicking and selecting <i>Save As...</i> to download the <i>GO.out.txt</i> annotations table</li></ul>")
        ),
        #tags$p(
        #  HTML("<b>Tip 3:</b> Valid statistic for gene scoring include <i>FDR</i> from DE analysis or module <i>number</i> from network analysis, and must be the same name as a column in the input gene score table.")
        #),
        #tags$p(
        #  HTML("<b>Tip 4:</b> Valid expressions for gene scoring include:")
        #),
        #tags$p(
        #  align = "center",
        #  HTML("<b>< 0.05</b> for specifying significant DE genes using a <i>FDR</i> cut off")
        #),
        #tags$p(
        #  align = "center",
        #  HTML("<b>== 1</b> for specifying a specific module <i>number</i> from WGCNA")
        #),
        tags$p(
          HTML("<b>Tip 3:</b> The input gene score table should <i>not</i> be filtered in advance."),
          "The functional analysis requires the complete gene universe, which includes all genes detected in the experiment regardless of signifigance in DE analysis or WGCNA."
        ),
        tags$p(
          HTML("<b>Tip 4:</b> The input gene score statistic <i>must match</i> the name of a column in the input gene score table.")
        ),
        tags$p(
          HTML("<b>Tip 5:</b> The first column of the gene score table is expected to contain gene IDs.")
        ),
        tags$p(
          HTML("<b>Tip 6:</b> The gene score tables are required to contain two columns with gene IDs and gene scores at <i>minimum</i>.")
        ),
        #tags$p(
        #HTML("<b>Tip 7:</b> Make sure to set the FDR cut off in your DE analysis <i>equal to 1</i> before downloading the results.")
        #),
        tags$hr(),
        tags$p(
          align="center",
          HTML("<b>Data Formatting</b>")
        ),
        tags$p(
          "Example gene score and gene-to-GO annotation mappings tables are displayed below."
        ),
        tags$br(),
        tags$p(
          align="center",
          HTML("<b>Example Gene Score Tables</b>")
        ),
        #tags$br(),
        fluidRow(
          column(
            width = 6,
            tags$p(
              HTML("Example <i>DE analysis</i> gene score table for five genes:"),
              tableOutput(outputId = "exampleDEScore")
            )
          ),
          column(
            width = 6,
            tags$p(
              HTML("Example <i>WGCNA</i> gene score table for five genes:"),
              tableOutput(outputId = "exampleWGCNAScore")
            )
          )
        ),
        tags$br(),
        fluidRow(
          column(
            width = 6,
            tags$p(
              HTML("Example <i>DE analysis</i> gene score table of three genes with the minimum expected columns:"),
              tableOutput(outputId = "exampleDEScoreSubset") 
            )
          ),
          column(
            width = 6,
            tags$p(
              HTML("Example <i>WGCNA</i> gene score table of three genes with the minimum expected columns:"),
              tableOutput(outputId = "exampleWGCNAScoreSubset") 
            )
          )
        ),
        tags$br(),
        tags$p(
          align="center",
          HTML("<b>Example Gene-to-GO Term Mapping Tables</b>")
        ),
        #tags$br(),
        tags$p(
          HTML("Example <i>topGO</i> gene-to-GO term mapping tables for four genes:"),
          tableOutput(outputId = "exampleTopGO") 
        ),
        tags$br(),
        tags$p(
          HTML("Example <i>two column CSV</i> with gene-to-GO term mapping tables for four genes:"),
          tableOutput(outputId = "exampleTwoCol") 
        ),
        tags$br(),
        tags$p(
          HTML("Example <i>PANNZER2</i> gene-to-GO annotations for two genes:"),
          tableOutput(outputId = "examplePannzer")
        )
      ),
      
      # processing text
      conditionalPanel(
        condition = "input.runAnalysis && !output.resultsCompleted",
        tags$h1(
          "Processing", 
          align="center"
        ),
        tags$br(),
        tags$p(
          "The GO term analysis results and plots may take several moments to process depending on the size of the input tables."
        )
      ),
      
      # results text and plots
      conditionalPanel(
        condition = "input.runAnalysis && output.resultsCompleted",
        # set of tab panels
        tabsetPanel(
          type = "tabs",
          tabPanel(
            "Tips",
            tags$br(),
            tags$p(
              align="center",
              HTML("<b>Helpful Tips</b>")
            ),
            tags$br(),
            tags$p(
              HTML("<b>Tip 1:</b> The plots and results may take several moments to appear depending on the size of the input data tables.")
            ),
            tags$p(
              HTML("<b>Tip 2:</b> Navigate to the <i>Analysis</i>, <i>Exploration</i>, or <i>Results</i> steps by clicking the tabs above.")
            ),
            tags$p(
              HTML("<b>Tip 3:</b> Further details about the available types of enrichment tests can be found in the "), 
              tags$a("topGO", href = "https://bioconductor.org/packages/devel/bioc/vignettes/topGO/inst/doc/topGO.pdf"),
              " manual (e.g., section 6)."
            ),
            tags$p(
              HTML("<b>Tip 4:</b> It is possible to use both the fisher's and KS tests since each gene has a score, which represents how it is diferentially expressed.")
            ),
            tags$p(
              HTML("<b>Tip 5:</b> Refer to the "),
              tags$a("topGO", href = "https://bioconductor.org/packages/devel/bioc/vignettes/topGO/inst/doc/topGO.pdf"),
              " manual for more information regarding the available algorithms and test statistics."
            )
          ),
          
          # Analysis tab
          tabPanel(
            "Analysis",
            tags$br(),
            tags$p(
              align = "center",
              HTML("<b>Functional Analysis</b>")
            ),
            tags$p(
              "Begin the functional enrichment or over-representation analysis by selecting a test statistic, algorithm, and p-value cut off."
            ),
            tags$br(),
            fluidRow(
              column(
                width = 6,
                tags$p(
                  "Select an Algorithm:"
                ),
                radioButtons(
                  inputId = "testAlg",
                  label = NULL,
                  choices = c("Default" = "weight01",
                              "Classic" = "classic",
                              "Elim" = "elim"),
                  selected = defaultAlg
                ),
                #tags$br(),
                tags$p(
                  HTML("<b>Available Algorithms:</b>")
                ),
                tags$p(
                  HTML("<b>1.</b> The <b>default</b> (a.k.a <i>weight01</i>) algorithm used by the topGO package is a mixture between the <i>elim</i> and <i>weight</i> algorithms")
                ),
                tags$p(
                  HTML("<b>2.</b> The <b>classic</b> algorithm performs functional analysis by testing the over-representation of GO terms within the group of diferentially expressed genes")
                ),
                tags$p(
                  HTML("<b>3.</b> The <b>elim</b> algorithm is more conservative then the classic method and you may expect the p-values returned by the former method to be lower bounded by the p-values returned by the later method")
                )
              ),
              column(
                width = 6,
                tags$p(
                  "Select a Test Statistic:"
                ),
                radioButtons(
                  inputId = "testStat",
                  label = NULL,
                  choices = c("Fisher" = "fisher",
                              "Kolmogorov-Smirnov" = "ks"),
                  selected = defaultStat
                ),
                tags$br(),
                tags$p(
                  HTML("<b>Available Test Statistics:</b>")
                ),
                tags$p(
                  HTML("<b>1.</b> The <b>fisher</b>'s exact test is based on gene counts and can be used to perform over representation analysis of GO terms")
                ),
                tags$p(
                  HTML("<b>2.</b> The <b>Kolmogorov-Smirnov</b> (<i>KS</i>) like test computes enrichment or rank based on gene scores and can be used to perform gene set enrichment analysis (GSEA)")
                )
              )
            ),
            tags$br(),
            fluidRow(
              column(
                width = 6,
                tags$p(
                  "Select P-Value Cut Off:"
                ),
                sliderInput(
                  "pValCut",
                  label = NULL,
                  min = 0, 
                  max = 0.1, 
                  value = defaultP 
                )
              ),
              column(
                width = 6,
                tags$p(
                  "Click to Update Analysis:"
                ),  
                actionButton("inputsUpdate", "Update Analysis")
              )
            ),
            tags$p(
              "Note that the computed p-values are unadjusted for multiple testing."
            ),
            tags$br(),
            tags$p(
              "Keep in mind that the plots and results may take several moments to update depending on the size of the input data tables."
            )
          ),
          
          # Exploration tab
          tabPanel(
            "Exploration",
            tags$br(),
            tags$p(
              align = "center",
              HTML("<b>Exploration</b>")
            ),
            tags$p(
              "Begin exploring the GO term data and functional analysis results by selecting a GO term category (e.g., ontology level) below."
            ),
            tags$br(),
            fluidRow(
              column(
                width = 6,
                tags$p(
                  "Select GO Term Category:"
                ),
                radioButtons(
                  inputId = "ontologyLevel",
                  label = NULL,
                  choices = c("Biological Process" = "BP",
                              "Molecular Function" = "MF",
                              "Cellular Component" = "CC"),
                  selected = "BP"
                )
              ),
              column(
                width = 6,
                tags$p(
                  "Click to Analyze:"
                ),  
                actionButton("levelUpdate", "Analyze")
              )
            ),
            tags$br(),
            tags$p(
              align = "center",
              HTML("<b>Helpful Tips</b>")
            ),
            tags$p(
              HTML("<b>Tip 1:</b> Only significant GO terms may be plotted.")
            ),
            tags$p(
              HTML("<b>Tip 2:</b> Make sure that the GO category is valid for the input GO term IDs.")
            ),
            # To-DO : make the current results load after completed
            # show results
            #conditionalPanel(
              #condition = "output.levelResultsCompleted",
              tags$hr(),
              tags$p(
                align = "center",
                HTML("<b>Range of GO Term P-Values</b>")
              ),
              tags$br(),
              plotOutput(outputId = "PHist"),
              downloadButton(outputId = "downloadPHist", label = "Download Plot"),
              tags$p(
                "The above histogram shows the range and frequency of p-values from the enrichment tests for the selected GO level (BP, MF, or CC)."
              ),
              tags$hr(),
              tags$p(
                align = "center",
                HTML("<b>Results for the Top Significant GO Terms:</b>")
              ),
              tableOutput(outputId = "topTerms"),
              tags$p(
                HTML("The above table shows the funcational analysis results for <i>up to the top 5</i> most significant (lowest p-value) GO terms for selected ontology level (BP, MF, or CC). The significance is determined by the input unadjusted p-value cut off.")
              ),
              tags$hr(),
              tags$p(
                align = "center",
                HTML("<b>Density Plots of GO Terms</b>")
              ),
              tags$br(),
              fluidRow(
                column(
                  width = 6,
                  tags$p(
                    "Enter GO Term ID:"
                  ),
                  textInput(
                    inputId = "ontologyTerm",
                    label = NULL,
                    value = "GO:0008150"
                  )
                ),
                column(
                  width = 6,
                  tags$p(
                    "Click to Analyze:"
                  ),  
                  actionButton("termUpdate", "Analyze")
                )
              ),
              #conditionalPanel(
                #condition = "output.densityResultsCompleted",
                tags$br(),
                tags$p(
                  align = "center",
                  HTML("<b>Density Plot</b>")
                ),
                # TO-DO: change to imageOutput
                plotOutput(outputId = "densityPlot"),
                downloadButton(outputId = "downloadDensity", label = "Download Plot"),
                tags$br(),
                tags$p(
                  "The above density plot shows the distribution of the gene's rank for the top GO term of each GO level (BP, MF, or CC). The gene's rank is compared with the null distribution."
                ),
              #),
              tags$br(),
              tags$p(
                HTML("<b>Table of Gene IDs</b>")
              ),
              downloadButton(outputId = "downloadSelected", label = "Download Table"),
              tags$p(
                "The table of gene IDs associated with the selected GO term may be downloaded above."
              ),
              tags$hr(),
              tags$p(
                align = "center",
                HTML("<b>Euler Diagrams of GO Terms</b>")
              ),
              tags$br(),
              fluidRow(
                column(
                  width = 4,
                  tags$p(
                    "Enter First GO Term ID:"
                  ),
                  textInput(
                    inputId = "ontologyTermOne",
                    label = NULL,
                    value = "GO:0008150"
                  )
                ),
                column(
                  width = 4,
                  tags$p(
                    "Enter Second GO Term ID:"
                  ),
                  textInput(
                    inputId = "ontologyTermTwo",
                    label = NULL,
                    value = "GO:0065007"
                  )
                ),
                column(
                  width = 4,
                  tags$p(
                    "Click to Analyze:"
                  ),  
                  actionButton("eulerUpdate", "Analyze")
                )
              ),
              plotOutput(outputId = "exampleEuler"),
              downloadButton(outputId = "downloadExampleEuler", label = "Download Plot"),
              tags$p(
                "The above euler diagram shows the relationship between the sets of genes associated with the selected GO terms."
              ),
              tags$br(),
              tags$p(
                HTML("<b>Tables of Gene IDs</b>")
              ),
              fluidRow(
                column(
                  width = 6,
                  tags$p(
                    "Gene IDs for First GO Term:"
                  ),
                  downloadButton(outputId = "downloadSelectedOne", label = "Download Table")
                ),
                column(
                  width = 6,
                  tags$p(
                    "Gene IDs for Second GO Term:"
                  ),
                  downloadButton(outputId = "downloadSelectedTwo", label = "Download Table")
                )
              ),
              tags$p(
                "The tables of gene IDs associated with each of the selected GO terms may be downloaded above."
              ),
              tags$hr(),
              # TO-DO: fix downloading of subgraphs
              tags$p(
                align = "center",
                HTML("<b>Subgraphs of Significant GO Terms</b>")
              ),
              tags$br(),
              fluidRow(
                column(
                  width = 6,
                  tags$p(
                    "Select the Number of Nodes:"
                  ),
                  sliderInput(
                    inputId = "sigNodes",
                    label = NULL,
                    min = 1,
                    max = 10,
                    value = 5,
                    step = 1
                  )
                ),
                column(
                  width = 6,
                  tags$p(
                    HTML("<b>Download Subgraphs:</b>")
                  ),
                  downloadButton(outputId = "downloadSubgraphs", label = "Download PDF")
                )
              ),
              tags$br(),
              tags$p(
                "The subgraph induced by the selected number of significant GO terms identifed by the selected algorithm for scoring GO terms for enrichment.",
                "Rectangles indicate the signifcant terms with colors representing the relative signifcance, which ranges from dark red (most signifcant) to bright yellow (least signifcant)."
              ),
              tags$p(
                HTML("For each <i>node</i>, some basic information is displayed."),
                "The frst two lines show the GO identifer and a trimmed GO name.",
                "In the third line the raw p-value is shown.",
                "The forth line is showing the number of signifcant genes and the total number of genes annotated to the respective GO term."
              )
            #)
          ),
          
          # results tab
          tabPanel(
            "Results",
            tags$br(),
            tags$p(
              align="center",
              HTML("<b>Functional Analysis Results</b>")
            ),
            tags$p(
              "Results from the GO term functional analysis may be viewed or downloaded below."
            ),
            tags$br(),
            tags$p(
              align = "center",
              HTML("<b>Dot Plot of Top 5 Significant GO Terms</b>")
            ),
            tags$br(),
            plotOutput(outputId = "dotPlot"),
            downloadButton(outputId = "downloadDotPlot", label = "Download Plot"),
            # TO-DO: make sure to note enriched or overrepresented for outputs
            tags$p(
              HTML("The above dot plot shows <i>up to the top 5</i> most significant (lowest p-value) GO terms for each ontology level (BP, MF, CC). The significance is determined by the input unadjusted p-value cut off. The size of the dots indicate the number of significant genes annotated to the GO term. The dots are colored by the enrichment test p-values.")
            ),
            tags$hr(),
            tags$p(
              align = "center",
              HTML("<b>Tables of All GO Term Results</b>")
            ),
            fluidRow(
              column(
                width = 4,
                tags$p(
                  "Results for BP GO Terms:"
                ),
                downloadButton(outputId = "resultsDownloadBP", label = "Download BP Table")
              ),
              column(
                width = 4,
                tags$p(
                  "Results for MF GO Terms:"
                ),
                downloadButton(outputId = "resultsDownloadMF", label = "Download MF Table")
              ),
              column(
                width = 4,
                tags$p(
                  "Results for CC GO Terms:"
                ),
                downloadButton(outputId = "resultsDownloadCC", label = "Download CC Table")
              )
            ),
            tags$p(
              "Above are the unfiltered tables of enriched GO terms for each of the ontology categories."
            ),
            tags$br(),
            tags$p(
              align = "center",
              HTML("<b>Tables of Significant GO Term Results</b>")
            ),
            fluidRow(
              column(
                width = 4,
                tags$p(
                  "Results for Significant BP GO Terms:"
                ),
                downloadButton(outputId = "sigDownloadBP", label = "Download BP Table")
              ),
              column(
                width = 4,
                tags$p(
                  "Results for Significant MF GO Terms:"
                ),
                downloadButton(outputId = "sigDownloadMF", label = "Download MF Table")
              ),
              column(
                width = 4,
                tags$p(
                  "Results for Significant CC GO Terms:"
                ),
                downloadButton(outputId = "sigDownloadCC", label = "Download CC Table")
              )
            ),
            tags$p(
              "Above are the tables of significantly enriched GO terms for each ontology category filtered by the input p-value cut off."
            ),
            tags$hr(),
            tags$p(
              align = "center",
              HTML("<b>Formatted Gene-to-GO Term Mapping Tables</b>")
            ),
            downloadButton(outputId = "mappingsDownload", label = "Download Table"),
            tags$p(
              "The above table of gene-to-GO term annotation mappings has been formatted for use with topGO."
            ),
            tags$br(),
            tags$p(
              align = "center",
              HTML("<b>Tables of Gene IDs for All GO Terms</b>")
            ),
            fluidRow(
              column(
                width = 4,
                tags$p(
                  "Gene IDs for BP GO Terms:"
                ),
                downloadButton(outputId = "downloadAllBP", label = "Download BP Table")
              ),
              column(
                width = 4,
                tags$p(
                  "Gene IDs for MF GO Terms:"
                ),
                downloadButton(outputId = "downloadAllMF", label = "Download MF Table")
              ),
              column(
                width = 4,
                tags$p(
                  "Gene IDs for CC GO Terms:"
                ),
                downloadButton(outputId = "downloadAllCC", label = "Download CC Table")
              )
            ),
            tags$p(
              "Above are the tables of significantly enriched GO terms for each ontology category filtered by the input p-value cut off."
            )
          ),
          
          # information tab
          tabPanel(
            "Information",
            tags$br(),
            tags$p(
              align="center",
              HTML("<b>Helpful Information</b>")
            ),
            tags$br(),
            tags$p(
              "This application for functional enrichment analysis was created by ",
              tags$a("Elizabeth Brooks",href = "https://www.linkedin.com/in/elizabethmbrooks/"),
              "."
            ),
            tags$p(
              "The latest version of this application may be downloaded from ",
              tags$a("GitHub",href = "https://github.com/ElizabethBrooks/DGEAnalysis_ShinyApps/tree/main/apps"),
              "."
            ),
            tags$p(
              "Example gene scores and mappings tables are also provided on ",
              tags$a("GitHub", href = "https://github.com/ElizabethBrooks/DGEAnalysis_ShinyApps/tree/main/data/topGO"),
              "."
            ),
            tags$p(
              "DE analysis gene score tables may be created from RNA-seq data as described in ", 
              tags$a("Bioinformatics Analysis of Omics Data with the Shell & R", href = "https://morphoscape.wordpress.com/2022/07/28/bioinformatics-analysis-of-omics-data-with-the-shell-r/"), 
              "."
            ),
            tags$p(
              "More information about the analysis performed in this application is provided in ", 
              tags$a("Gene set enrichment analysis with topGO", href = "https://bioconductor.org/packages/devel/bioc/vignettes/topGO/inst/doc/topGO.pdf"), 
              "."
            ),
            tags$p(
              "This project was funded by the National Science Foundation grant \"Collaborative Research: EDGE FGT: Genome-wide Knock-out mutant libraries for the microcrustacean Daphnia\" (2220695/2324639 to Sen Xu and 2220696 to Michael E. Pfrender)."
            )
          )
        )
      )
    )
  )
)


#### Server ####

# Define server 
server <- function(input, output, session) {
  ##
  # Example Data Setup
  ##
  
  # render example gene score table
  output$exampleDEScore <- renderTable({
    # create example score table
    exScoreTable <- data.frame(
      Gene = c("gene-1", "gene-2", "gene-3", "gene-4", "gene-5"),
      logFC = c(2.61034881060096,-2.77567627557932,0.776975043760105,-1.34029691872383,2.00219952581652),
      logCPM = c(8.45787942136883,9.3923802734891,7.77358110628366,7.9912560914574,8.28149397708451),
      PValue = c(0.0002731254813,0.451205836761818,0.451205836761818,0.451205836761818,0.451205836761818),
      FDR = c(0.435362017290981,0.451205836761818,0.451205836761818,0.451205836761818,0.451205836761818)
    )
  })
  
  # render example gene score table subset
  output$exampleDEScoreSubset <- renderTable({
    # create example score table
    exScoreTable <- data.frame(
      Gene = c("gene-1", "gene-2", "gene-3"),
      FDR = c(0.435362017290981,0.451205836761818,0.451205836761818)
    )
  })
  
  # render example gene score table
  output$exampleWGCNAScore <- renderTable({
    # create example score table
    exScoreTable <- data.frame(
      gene = c("geneA", "geneB", "geneC", "geneD", "geneE"),
      color = c("brown","brown","brown", "grey", "grey"),
      number = c("1","1","1","0","0")
    )
  })
  
  # render example gene score table subset
  output$exampleWGCNAScoreSubset <- renderTable({
    # create example score table
    exScoreTable <- data.frame(
      gene = c("geneA", "geneB", "geneC"),
      number = c("1","1","1")
    )
  })
  
  # render example topGO mappings table
  output$exampleTopGO <- renderTable({
    # create example mappings table
    exMappingsTable <- data.frame(
      Gene = c("geneA", "geneB", "geneC", "geneD"),
      Terms = c("GO:0005730,GO:0030490", "GO:0006890,GO:0030173,GO:0005783,GO:0006621", "GO:0006355", "GO:0005739,GO:0008203,GO:0006744,GO:0015039")
    )
  })
  
  # render example two column csv mappings table
  output$exampleTwoCol <- renderTable({
    # create example mappings table
    exMappingsTable <- data.frame(
      Gene = c("geneA", "geneA", "geneB", "geneB", "geneB", "geneB", "geneC", "geneD", "geneD", "geneD", "geneD"),
      Terms = c("GO:0005730" ,"GO:0030490", "GO:0006890", "GO:0030173", "GO:0005783", "GO:0006621", "GO:0006355", "GO:0005739", "GO:0008203", "GO:0006744", "GO:0015039")
    )
  })
  
  # render example PANNZER2 mappings table
  output$examplePannzer <- renderTable({
    # create example mappings table
    exMappingsTable <- data.frame(
      qpid = c("geneA", "geneA", "geneA", "geneB", "geneB"),
      goid = c("0009360", "0008408", "0071897", "0003887", "0006260"),
      ontology = c("CC", "MF", "BP", "MF", "BP"),
      desc = c("DNA polymerase III complex", "3'-5' exonuclease activity", "DNA biosynthetic process", "DNA-directed DNA polymerase activity", "DNA replication"),
      ARGOT_RSscore = c("9.351550793", "8.193028339", "6.425739587", "7.915962904", "5.993446976"),
      ARGOT_RSPPV = c("0.748726035", "0.720312733", "0.672768098", "0.713224862", "0.660171634"),
      ARGOT_RSrank = c("1", "1", "1", "2", "2"),
      goclasscount = c("100", "100", "100", "100", "100")
    )
  })
  
  
  ##
  # Data Setup
  ##
  
  # retrieve input data
  inputAnalysisTable <- reactive({
    # require input data
    req(input$analysisTable)
    # check the input table is not null
    if(is.null(input$analysisTable)){
      return(NULL)
    }
    # TO-DO: add note about first column is expected to contain gene names
    # read the file
    dataTableInput <- read.csv(file = input$analysisTable$datapath, row.names=1)
    # check if the input table contains the selected gene score
    if(!(input$scoreStat %in% colnames(dataTableInput))){
      return(NULL)
    }
    # return data
    dataTableInput
  })
  
  # retrieve input data
  inputMappings <- reactive({
    # require input data
    req(input$mappings)
    # check the input table is not null
    if(is.null(input$mappings)){
      return(NULL)
    }
    # read in the file
    GOmaps_input <- suppressWarnings(read.delim(file = input$mappings$datapath, sep = "", row.names=NULL, colClasses = c(goid = "character")))
    # check what format mappings file was input
    if(ncol(GOmaps_input) == 2){ # two columns
      # check if mappings are in topGO format
      if( "\t" %in% strsplit(readLines(input$mappings$datapath, n=1)[1], split="")[[1]] ) { # topGO formatted
        # read the mappings file
        GOmaps <- readMappings(file = input$mappings$datapath)
      }else{ # two column csv
        # re-format mappings from two column csv
        GOmaps_csv_format <- aggregate(GOmaps_input[2], GOmaps_input[1], FUN = toString)
        GOmaps_csv_out <- GOmaps_csv_format
        GOmaps_csv_out$Terms <- gsub(" ", "", GOmaps_input[2])
        # output re-formatted mappings from two column csv
        write.table(GOmaps_csv_out, file = "mappings_GO.fmt.txt", sep = "\t", quote = FALSE, row.names=FALSE)
        # read the mappings file
        GOmaps <- readMappings(file = "mappings_GO.fmt.txt")
        # clean up
        file.remove("mappings_GO.fmt.txt") 
      }
    }else if(ncol(GOmaps_input) == 8){ # 8 columns
      # double check if input mappings are from PANNZER2
      if("qpid" %in% colnames(GOmaps_input) && "goid" %in% colnames(GOmaps_input)){
        # re-format mappings from PANNZER2
        GOmaps_fmt <- split(GOmaps_input$goid,GOmaps_input$qpid)
        # create data frame with formtted mappings
        GOmaps_out <- as.data.frame(unlist(lapply(names(GOmaps_fmt), function(x){gsub(" ", "", toString(paste("GO:", GOmaps_fmt[[x]], sep="")))})))
        rownames(GOmaps_out) <- names(GOmaps_fmt)
        colnames(GOmaps_out) <- NULL
        # TO-DO: double check location for storing this necessary output file
        # output re-formatted mappings from PANNZER2
        write.table(GOmaps_out, file = "PANNZER2_GO.fmt.txt", sep = "\t", quote = FALSE)
        # read the mappings file
        GOmaps <- readMappings(file = "PANNZER2_GO.fmt.txt")
        # clean up
        file.remove("PANNZER2_GO.fmt.txt")
      }
    }else{
      GOmaps <- NULL
    }
    # return data
    GOmaps
  })
  
  # check if file has been uploaded
  output$dataUploaded <- function(){
    # check the input tables are not null
    if(is.null(inputAnalysisTable())){
      return(FALSE)
    }
    if(is.null(inputMappings())){
      return(FALSE)
    }
    return(TRUE)
  }
  outputOptions(output, 'dataUploaded', suspendWhenHidden=FALSE)
  
  ## 
  # Functional Analysis Setup
  ##
  
  # setup reactive values for settings
  algVal <- reactiveVal(defaultAlg)
  statVal <- reactiveVal(defaultStat)
  pVal <- reactiveVal(defaultP)
  
  # function to create gene universe
  observeEvent(input$inputsUpdate, {
    # require input data
    req(input$testAlg, input$testStat, input$pValCut)
    # update settings
    algVal(input$testAlg)
    statVal(input$testStat)
    pVal(input$pValCut)
  })
  
  # render table with input settings
  output$inputSettings <- renderTable({
    # create table with factor levels
    settings <- data.frame(
      Setting = c("Algorithm", "Statistic", "PValue"),
      Value = c(algVal(), statVal(), pVal())
    )
    # return the settings data frame
    settings
  })
  
  # setup reactive gene universe values
  geneUniverse <- reactiveValues(list_data = NULL)
    
  # function to create gene universe
  observeEvent(input$runAnalysis, {
  #geneUniverse <- reactive({
    # require input
    req(input$scoreStat)
    # check for valid inputs
    if(is.null(inputAnalysisTable())){
      return(NULL)
    }
    if(is.null(inputMappings())){
      return(NULL)
    }
    # retrieve results for analysis
    resultsTable <- inputAnalysisTable()
    # retrieve go mappings
    GO_maps <- inputMappings()
    # retrieve selected gene score statistic column
    list_genes <- as.numeric(resultsTable[[input$scoreStat]])
    # create named list of all genes (gene universe) and values
    # the gene universe is set to be the list of all genes contained in the gene2GO list of annotated genes
    list_genes <- setNames(list_genes, rownames(resultsTable))
    list_genes_filtered <- list_genes[names(list_genes) %in% names(GO_maps)]
    # update list
    geneUniverse$list_data <- list_genes_filtered
  }, ignoreInit = TRUE)
  
  # check if results are complete
  output$resultsCompleted <- function(){
    if(is.null(geneUniverse$list_data)){
      return(FALSE)
    }
    return(TRUE)
  }
  outputOptions(output, 'resultsCompleted', suspendWhenHidden=FALSE, priority=0)
  
  # TO-DO: fix evaluation of strings (e.g., == brown)
  # TO-DO: test the validity of the input expression for error handling
  # function to retrieve interesting genes
  retrieveInteresting <- function(){
    # function that returns list of interesting DE genes (0 == not significant, 1 == significant)
    get_interesting_DE_genes <- function(geneUniverse){
      interesting_DE_genes <- rep(0, length(geneUniverse))
      for(i in 1:length(geneUniverse)){
        if(eval(parse(text = paste(geneUniverse[i], input$universeCut, sep=" ")))){
          interesting_DE_genes[i] = 1
        }
      }
      interesting_DE_genes <- setNames(interesting_DE_genes, names(geneUniverse))
      return(interesting_DE_genes)
    }
  }
  
  # function to create and save BP, MF, or CC topGOdata objects
  createGO <- function(termsLevel){
    # retrieve gene universe
    list_genes_filtered <- geneUniverse$list_data
    # retrieve go mappings
    GO_maps <- inputMappings()
    # create topGOdata objects for enrichment analysis (1 for each ontology)
    GO_data <- new('topGOdata', ontology = termsLevel, allGenes = list_genes_filtered, 
                   geneSel = retrieveInteresting(), nodeSize = 10, annot = annFUN.gene2GO, 
                   gene2GO = GO_maps)
  }
  
  # TO-DO: double check the selection of interesting genes
  # The user needs to provide the gene universe, GO annotations and either a
  # criteria for selecting interesting genes (e.g. dierentially expressed genes) from the gene universe or a score
  # associated with each gene.
  # function to perform BP, MF, or CC GO analysis 
  performGO <- function(dataOntology){
    # retrieve topGOdata object
    GO_data <- dataOntology
    # perform GO enrichment using the topGOdata objects
    GO_results <- runTest(GO_data, algorithm = algVal(), statistic = statVal())
  }
  
  # setup reactive ontology values
  dataGO <- reactiveValues(topGO_data = NULL)
  dataGO_BP <- reactiveValues(topGO_data = NULL)
  dataGO_MF <- reactiveValues(topGO_data = NULL)
  dataGO_CC <- reactiveValues(topGO_data = NULL)
  
  # setup reactive GO results values
  resultsGO <- reactiveValues(results_data = NULL)
  resultsGO_BP <- reactiveValues(results_data = NULL)
  resultsGO_MF <- reactiveValues(results_data = NULL)
  resultsGO_CC <- reactiveValues(results_data = NULL)
  
  # event to update GO analysis results 
  observeEvent(input$levelUpdate, {
    # re-set the data and results
    #dataGO$topGO_data <- NULL
    #resultsGO$results_data <- NULL
    # update the data and results
    dataGO$topGO_data <- createGO(input$ontologyLevel)
    resultsGO$results_data <- performGO(dataGO$topGO_data)
  }, ignoreInit = TRUE)
  
  # event to update GO analysis results 
  observeEvent(list(input$runAnalysis, input$inputsUpdate), {
    # update the data
    dataGO_BP$topGO_data <- createGO("BP")
    dataGO_MF$topGO_data <- createGO("MF")
    dataGO_CC$topGO_data <- createGO("CC")
    # update the results
    resultsGO_BP$results_data <- performGO(dataGO_BP$topGO_data)
    resultsGO_MF$results_data <- performGO(dataGO_MF$topGO_data)
    resultsGO_CC$results_data <- performGO(dataGO_CC$topGO_data)
    # update the current ontology level data and results
    dataGO$topGO_data <- dataGO_BP$topGO_data
    resultsGO$results_data <- resultsGO_BP$results_data
    # re-set the current ontology level
    updateRadioButtons(
      session, 
      "ontologyLevel",
      selected = "BP",
    )
  }, ignoreInit = TRUE)
  
  # check if results are complete
  #output$levelResultsCompleted <- function(){
    #if(is.null(resultsGO$results_data)){
      #return(FALSE)
    #}
    #return(TRUE)
  #}
  #outputOptions(output, 'levelResultsCompleted', suspendWhenHidden=FALSE, priority=0)
  
  # setup reactive ontology term values
  selectedTerm <- reactiveVal(defaultTermOne)
  selectedTermOne <- reactiveVal(defaultTermOne)
  selectedTermTwo <- reactiveVal(defaultTermTwo)
  
  # get most significant terms
  observeEvent(list(input$runAnalysis, input$inputsUpdate, input$levelUpdate), {
    # retrieve top terms
    termOne <- getSigTermOne()
    termTwo <- getSigTermTwo()
    # set top terms
    selectedTerm(termOne)
    selectedTermOne(termOne)
    selectedTermTwo(termTwo)
    # update inputs
    updateTextInput(
      session,
      inputId = "ontologyTerm",
      value = selectedTerm()
    )
    updateTextInput(
      session,
      inputId = "ontologyTermOne",
      value = selectedTermOne()
    )
    updateTextInput(
      session,
      inputId = "ontologyTermTwo",
      value = selectedTermTwo()
    )
  }, ignoreInit = TRUE)
  
  # update input ontology term
  observeEvent(input$termUpdate, {
    # retrieve input term
    selectedTerm(input$ontologyTerm)
  }, ignoreInit = TRUE)
  
  # update input ontology terms
  observeEvent(input$eulerUpdate, {
    # retrieve input terms
    selectedTermOne(input$ontologyTermOne)
    selectedTermTwo(input$ontologyTermTwo)
  }, ignoreInit = TRUE)
  
  ## 
  # Functional Analysis Exploration
  ##
  
  # function to retrieve gene IDs for the selected GO term for the input ontology level
  retrieveSelected <- function(term){
    # create GO data
    GO_data <- dataGO$topGO_data
    # retrieve gene IDs for all GO terms
    allGO <- genesInTerm(GO_data)
    # retrieve selected GO term gene IDs
    selectGO <- allGO[term]
  }
  
  # download handler to export gene IDs for the selected GO term
  output$downloadSelected <- downloadHandler(
    filename = function() {
      outTerm <- gsub(":", "_", selectedTerm())
      outFile <- paste(outTerm, "gene_IDs.csv", sep = "_")
    },
    content = function(outFile) {
      # retrieve gene IDs for the selected term
      selectGO <- retrieveSelected(selectedTerm())
      # write out all GO term gene IDs
      write.table(unlist(selectGO), file = outFile, sep = ",", quote = FALSE, row.names=FALSE, col.names = FALSE)
    }
  )
  
  # download handler to export gene IDs for the first selected GO term
  output$downloadSelectedOne <- downloadHandler(
    filename = function() {
      outTerm <- gsub(":", "_", selectedTermOne())
      outFile <- paste(outTerm, "gene_IDs.csv", sep = "_")
    },
    content = function(outFile) {
      # retrieve gene IDs for the selected term
      selectGO <- retrieveSelected(selectedTermOne())
      # write out all GO term gene IDs
      write.table(unlist(selectGO), file = outFile, sep = ",", quote = FALSE, row.names=FALSE, col.names = FALSE)
    }
  )
  
  # download handler to export gene IDs for the second selected GO term
  output$downloadSelectedTwo <- downloadHandler(
    filename = function() {
      outTerm <- gsub(":", "_", selectedTermTwo())
      outFile <- paste(outTerm, "gene_IDs.csv", sep = "_")
    },
    content = function(outFile) {
      # retrieve gene IDs for the selected term
      selectGO <- retrieveSelected(selectedTermTwo())
      # write out all GO term gene IDs
      write.table(unlist(selectGO), file = outFile, sep = ",", quote = FALSE, row.names=FALSE, col.names = FALSE)
    }
  )
  
  # function to create example euler diagram for two selected GO terms
  createExampleEuler <- function(selectedOne, selectedTwo){
    # retrieve gene IDs for the two selected terms
    selectGO_one <- unlist(retrieveSelected(selectedOne))
    selectGO_two <- unlist(retrieveSelected(selectedTwo))
    # euler diagram with significant stress GO terms
    glm_list_venn_GO <-list(First = selectGO_one,
                            Second = selectGO_two)
    euler_plot_GO <- euler(glm_list_venn_GO)#, shape = "ellipse")
    plot(euler_plot_GO, quantities = list(type = c("counts")), fills = eulerPlotColors)
  }
  
  # display euler diagram of selected GO terms
  output$exampleEuler <- renderPlot({
    # create the plot
    createExampleEuler(selectedTermOne(), selectedTermTwo())
  })
  
  # download handler for the euler diagram of selected GO terms
  output$downloadExampleEuler <- downloadHandler(
    filename = function() {
      # create the file name
      outTermOne <- gsub(":", "_", selectedTermOne())
      outTermTwo <- gsub(":", "_", selectedTermTwo())
      exportFile <- paste(outTermOne, outTermTwo, sep = "_")
      exportFile <- paste(exportFile, "eulerPlot.png", sep = "_")
    },
    content = function(file) {
      # save the plot
      png(file)
      createExampleEuler(selectedTermOne(), selectedTermTwo())
      dev.off()
    }
  )
  
  # function to create BP, MF, or CC p-value histogram
  createPHist <- function(){
    # require inputs
    #req(input$ontologyLevel)
    # retrieve results
    GO_results <- resultsGO$results_data
    # store p-values as named list...
    pvalGO <- score(GO_results)
    # create title
    titleName <- paste("Range of", input$ontologyLevel, "P-Values", sep=" ")
    # plot histogram to see range of p-values
    hist(pvalGO, 35, xlab = "p-values", main = titleName)
  }
  
  # render BP p-value histogram
  output$PHist <- renderPlot({
    # create the plot
    createPHist()
  })
  
  # download handler for the BP histogram
  output$downloadPHist <- downloadHandler(
    filename = function() {
      paste(input$ontologyLevel, "pValueRanges.png", sep = "_")
    },
    content = function(file) {
      # save the plot
      png(file, width = 12, height = 9, units="in", res=150)
      createPHist()
      dev.off()
    }
  )
  
  # function to plot BP, MF, or CC subgraphs
  createSubgraphs <- function(){
    # require inputs
    req(input$ontologyLevel, input$sigNodes)
    # retrieve topGOdata object
    GO_data <- dataGO$topGO_data
    # retrieve results
    GO_results <- resultsGO$results_data
    # plot subgraphs induced by the significant GO terms
    printGraph(GO_data, GO_results, firstSigNodes = input$sigNodes, 
               fn.prefix = paste(input$ontologyLevel, "sigGO_subgraphs", sep="_"), useInfo = "all", pdfSW = TRUE)
  }
  
  # TO-DO: fix, currently saves to working directory
  # download button for PDFs of subgraphs
  output$downloadSubgraphs <- downloadHandler(
    filename = function() {
      paste(input$ontologyLevel, "sigGO_subgraphs.pdf", sep = "_")
    },
    content = function(file) {
      # create subgraph PDFs
      createSubgraphs()
    }
  )
  
  # TO-DO: fix extra column in output table
  # function to get statistics on BP, MF, or CC GO terms
  getResults <- function(GO_data, GO_Results){
    # check for valid inputs
    if(is.null(dataGO$topGO_data)){
      return(NULL)
    }
    # retrieve statistics
    list_GO_terms <- usedGO(GO_data)
    # retrieve results table
    GO_Results_table <- GenTable(GO_data, weightFisher = GO_Results, orderBy = 'weightFisher', 
                                 topNodes = length(list_GO_terms))
  }
  
  # function to get significant BP, MF, or CC GO terms
  getSigResults <- function(GO_data, GO_Results){
    # retrieve stats
    GO_Results_table <- getResults(GO_data, GO_Results)
    # create table of significant GO terms
    sigGO_Results_table <- GO_Results_table[GO_Results_table$weightFisher <= pVal(), ]
  }
  
  # TO-DO: double check the updated term returned on button press
  # function to get the first significant results for selected the top BP, MF, or CC GO terms
  getSigTermOne <- function(){
    # require processed data
    req(dataGO$topGO_data, resultsGO$results_data)
    # retrieve stats
    GO_results_table <- getResults(dataGO$topGO_data, resultsGO$results_data)
    # retrieve results for selected GO term
    topSigID <- GO_results_table[1, 'GO.ID']
  }
  
  # function to get the second significant results for selected the top BP, MF, or CC GO terms
  getSigTermTwo <- function(){
    # require processed data
    req(dataGO$topGO_data, resultsGO$results_data)
    # retrieve stats
    GO_results_table <- getResults(dataGO$topGO_data, resultsGO$results_data)
    # retrieve results for selected GO term
    topSigID <- GO_results_table[2, 'GO.ID']
  }
  
  # function to get results for selected BP, MF, or CC GO terms
  getTerm <- function(){
    # require processed data
    req(dataGO$topGO_data, resultsGO$results_data)
    # retrieve stats
    GO_results_table <- getResults(dataGO$topGO_data, resultsGO$results_data)
    # retrieve results for selected GO term
    topSigID <- GO_results_table[GO_results_table$GO.ID == selectedTerm(),1]
  }
  
  # render table of top 5 GO terms for the selected ontology level
  output$topTerms <- renderTable({
    # create BP, MF, and CC GO data
    GO_data <- dataGO$topGO_data
    # perform BP, MF, and CC GO analysis
    GO_Results <- resultsGO$results_data
    # retrieve ontology result tables
    resultsTable <- getSigResults(GO_data, GO_Results)
    # subset the table
    resultsTableSubset <- resultsTable[1:5, ]
  })
  
  # function to create BP, MF, or CC density plots
  # default is most sig GO term
  createDensity <- function(){
    # retrieve topGOdata object
    GO_data <- dataGO$topGO_data
    # retrieve term results
    termResults <- getTerm()
    # create density plot
    showGroupDensity(GO_data, whichGO = termResults, ranks = TRUE)
  }
  
  # TO-DO: this causes additional function calls
  # check if results have completed
  #output$densityResultsCompleted <- function(){
    #if(is.null(createDensity())){
      #return(FALSE)
    #}
    #return(TRUE)
  #}
  #outputOptions(output, 'densityResultsCompleted', suspendWhenHidden=FALSE, priority=0)
  
  # render density plot
  output$densityPlot <- renderPlot({
    # create plot
    createDensity()
  })
  
  # TO-DO: fix
  # download handler for the density plot
  output$downloadDensity <- downloadHandler(
    filename = function() {
      paste(input$ontologyLevel, "density.png", sep = "_")
    },
    content = function(file) {
      # save the plot
      png(file, width = 12, height = 9, units="in", res=150)
      createDensity()
      dev.off()
    }
  )
  
  ## 
  # Functional Analysis Results
  ##
  
  # function to format data for use with dot plots
  dotPlotSigData <- function(){
    # create BP, MF, and CC GO data
    GO_data_BP <- dataGO_BP$topGO_data
    GO_data_MF <- dataGO_MF$topGO_data
    GO_data_CC <- dataGO_CC$topGO_data
    # perform BP, MF, and CC GO analysis
    GO_Results_BP <- resultsGO_BP$results_data
    GO_Results_MF <- resultsGO_MF$results_data
    GO_Results_CC <- resultsGO_CC$results_data
    # retrieve ontology result tables
    BPTable <- getSigResults(GO_data_BP, GO_Results_BP)
    MFTable <- getSigResults(GO_data_MF, GO_Results_MF)
    CCTable <- getSigResults(GO_data_CC, GO_Results_CC)
    # subset the tables
    BPTable <- BPTable[1:5, ]
    MFTable <- MFTable[1:5, ]
    CCTable <- CCTable[1:5, ]
    # add column with ontology ID
    BPPlotTable <- cbind('ID' = 'BP', BPTable)
    MFPlotTable <- cbind('ID' = 'MF', MFTable)
    CCPlotTable <- cbind('ID' = 'CC', CCTable)
    # combine all tables
    allPlotTable <- rbind(BPPlotTable, MFPlotTable, CCPlotTable)
    # remove NAs
    plotTable <- na.omit(allPlotTable)
  }
  
  # function to create dot plots
  createDotPlot <- function(){
    # retrieve formatted data
    plotTable <- dotPlotSigData()
    # create faceting by ontology
    facet <- factor(plotTable$ID, levels = c('BP', 'CC', 'MF'))
    # create dot plot
    dotplot <- ggplot(data = plotTable, aes(x = "Enrichment", y = GO.ID, size = Significant, color = as.numeric(weightFisher))) + 
      facet_grid(rows = facet, space = 'free_y', scales = 'free') +
      geom_point() +
      #scale_color_gradientn(colors = heat.colors(10), limits=c(0, 0.05)) + 
      scale_color_gradientn(colors = dotPlotColors) +
      #scale_x_discrete(guide = guide_axis(angle = 90)) +
      theme_bw() +
      xlab('Score') +
      ylab('Term') + 
      #scale_x_discrete(labels=c("Interaction"=expression(italic("Interaction")), parse=TRUE)) +
      labs(color = 'P-Value', size = 'Significant')
    # view plot
    dotplot
  }
  
  # render dot plot
  output$dotPlot <- renderPlot({
    # create plot
    createDotPlot()
  })
  
  # TO-DO: update file names based on data subset
  # download handler for the dot plot
  output$downloadDotPlot <- downloadHandler(
    filename = function() {
      "dotPlot.png"
    },
    content = function(file) {
      # create plot
      dotPlotResults <- createDotPlot()
      # save plot
      ggsave(file, plot = dotPlotResults, device = "png")
    }
  )
  
  # function to download table of results
  output$resultsDownloadBP <- downloadHandler(
    # retrieve file name
    filename = function() {
      # setup output file name
      paste(input$ontologyLevel, "GO_terms.csv", sep = "_")
    },
    # read in data
    content = function(file) {
      # create BP GO data
      GO_data <- dataGO_BP$topGO_data
      # perform BP GO analysis
      GO_Results <- performGO(GO_data)
      # retrieve results
      GO_results_table <- getResults(GO_data, GO_Results)
      # write table of GO terms to a CSV file
      write.table(GO_results_table, file, sep=",", row.names=FALSE, quote=FALSE)
    }
  )
  
  # function to download table of results
  output$resultsDownloadMF <- downloadHandler(
    # retrieve file name
    filename = function() {
      # setup output file name
      paste(input$ontologyLevel, "GO_terms.csv", sep = "_")
    },
    # read in data
    content = function(file) {
      # create MF GO data
      GO_data <- dataGO_MF$topGO_data
      # perform MF GO analysis
      GO_Results <- performGO(GO_data)
      # retrieve results
      GO_results_table <- getResults(GO_data, GO_Results)
      # write table of GO terms to a CSV file
      write.table(GO_results_table, file, sep=",", row.names=FALSE, quote=FALSE)
    }
  )
  
  # function to download table of results
  output$resultsDownloadCC <- downloadHandler(
    # retrieve file name
    filename = function() {
      # setup output file name
      paste(input$ontologyLevel, "GO_terms.csv", sep = "_")
    },
    # read in data
    content = function(file) {
      # create CC GO data
      GO_data <- dataGO_CC$topGO_data
      # perform CC GO analysis
      GO_Results <- performGO(GO_data)
      # retrieve results
      GO_results_table <- getResults(GO_data, GO_Results)
      # write table of GO terms to a CSV file
      write.table(GO_results_table, file, sep=",", row.names=FALSE, quote=FALSE)
    }
  )
  
  # function to download table of significant results
  output$sigDownloadBP <- downloadHandler(
    # retrieve file name
    filename = function() {
      # setup output file name
      paste(input$ontologyLevel, pVal(), "sigGO_terms.csv", sep = "_")
    },
    # read in data
    content = function(file) {
      # create BP GO data
      GO_data <- dataGO_BP$topGO_data
      # perform BP GO analysis
      GO_Results <- performGO(GO_data)
      # retrieve significant results
      sigGO_results_table <- getSigResults(GO_data, GO_Results)
      # write table of significant GO terms to a CSV file
      write.table(sigGO_results_table, file, sep=",", row.names=FALSE, quote=FALSE)
    }
  )
  
  # function to download table of significant results
  output$sigDownloadMF <- downloadHandler(
    # retrieve file name
    filename = function() {
      # setup output file name
      paste(input$ontologyLevel, pVal(), "sigGO_terms.csv", sep = "_")
    },
    # read in data
    content = function(file) {
      # create MF GO data
      GO_data <- dataGO_MF$topGO_data
      # perform MF GO analysis
      GO_Results <- performGO(GO_data)
      # retrieve significant results
      sigGO_results_table <- getSigResults(GO_data, GO_Results)
      # write table of significant GO terms to a CSV file
      write.table(sigGO_results_table, file, sep=",", row.names=FALSE, quote=FALSE)
    }
  )
  
  # function to download table of significant results
  output$sigDownloadCC <- downloadHandler(
    # retrieve file name
    filename = function() {
      # setup output file name
      paste(input$ontologyLevel, pVal(), "sigGO_terms.csv", sep = "_")
    },
    # read in data
    content = function(file) {
      # create CC GO data
      GO_data <- dataGO_CC$topGO_data
      # perform CC GO analysis
      GO_Results <- performGO(GO_data)
      # retrieve significant results
      sigGO_results_table <- getSigResults(GO_data, GO_Results)
      # write table of significant GO terms to a CSV file
      write.table(sigGO_results_table, file, sep=",", row.names=FALSE, quote=FALSE)
    }
  )
  
  # function to retrieve gene IDs for all GO terms for the input ontology level
  retrieveAll <- function(termLevel){
    # create GO data
    GO_data <- createGO(termLevel)
    # retrieve geneIDs associated with all GO terms
    # https://support.bioconductor.org/p/29775/
    allGO_BP = genesInTerm(GO_data)
  }
  
  # download handler for all BP GO terms gene IDs
  output$downloadAllBP <- downloadHandler(
    filename = function() {
      "BP_GO_gene_IDs.txt"
    },
    content = function(file) {
      # retrieve gene IDs
      allGO <- retrieveAll("BP")
      # write out all GO term gene IDs
      sink(file)
      allGO
      sink()
    }
  )
  
  # download handler for all MF GO terms gene IDs
  output$downloadAllMF <- downloadHandler(
    filename = function() {
      "MF_GO_gene_IDs.txt"
    },
    content = function(file) {
      # retrieve gene IDs
      allGO <- retrieveAll("MF")
      # write out all GO term gene IDs
      sink(file)
      allGO
      sink()
    }
  )
  
  # download handler for all CC GO terms gene IDs
  output$downloadAllCC <- downloadHandler(
    filename = function() {
      "CC_GO_gene_IDs.txt"
    },
    content = function(file) {
      # retrieve gene IDs
      allGO <- retrieveAll("CC")
      # write out all GO term gene IDs
      sink(file)
      allGO
      sink()
    }
  )
  
  # function to download table of GO term mappings
  output$mappingsDownload <- downloadHandler(
    # retrieve file name
    filename = function() {
      # setup output file name
      "gene_to_GO_map.fmt.txt"
    },
    # read in data
    content = function(file) {
      # retrieve go mappings
      GO_maps <- inputMappings()
      # create data frame with formtted mappings
      GOmaps_out <- as.data.frame(unlist(lapply(names(GO_maps), function(x){gsub(" ", "", toString(paste("GO:", GO_maps[[x]], sep="")))})))
      rownames(GOmaps_out) <- names(GO_maps)
      colnames(GOmaps_out) <- NULL
      # write table of GO terms mappings to a CSV file
      write.table(GOmaps_out, file, sep = "\t", quote = FALSE)
    }
  )
  
}

#### App Object ####

# create the Shiny app object 
shinyApp(ui = ui, server = server)

