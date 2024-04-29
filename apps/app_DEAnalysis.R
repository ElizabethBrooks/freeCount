# creator: Elizabeth Brooks
# updated: 12 April 2024

#### Setup ####

# install any missing packages
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

# load packages 
suppressPackageStartupMessages({
  library(shiny)
  library(shinythemes)
  library(ggplot2)
  library(rcartocolor)
  library(edgeR)
  library(dplyr)
  library(pheatmap)
  library(ggplotify)
})

# color blind safe plotting palettes
plotColors <- carto_pal(12, "Safe")

# set default values
defaultLFC <- 1.2
defaultFDR <- 0.05

# TO-DO: fix output table header, which is missing the "gene" column?
# TO-DO: store data and results in reactiveVal and reactiveValues
# TO-DO: add bar plots of gene counts and LFC
# TO-DO: output example tables as csv
# TO-DO: consider separating analysis and results into different tabs

#### UI ####

# Define UI 
ui <- fluidPage(
  # view available themes
  #shinythemes::themeSelector(),
  
  # use a theme
  theme = shinytheme("yeti"),
  
  # add application title
  titlePanel("Differential Expression (DE) Analysis with edgeR"),
  
  # setup sidebar layout
  sidebarLayout(
    
    # setup sidebar panel
    sidebarPanel(
      
      # show panel depending on run button
      conditionalPanel(
        condition = "!input.runAnalysis",
        # header for file uploads
        tags$p(
          "Upload table of gene counts (*.csv):"
        ),
        # select a file
        fileInput(
          "geneCountsTable", 
          label = NULL,
          multiple = FALSE,
          accept = ".csv"
        ),
        # header for comparison selection
        tags$p(
          "Upload table with the experimental design (*.csv):"),
        # select a file
        fileInput(
          "expDesignTable", 
          label = NULL,
          multiple = FALSE,
          accept = ".csv"
        )
      ),
      # show panel depending on inputs check
      conditionalPanel(
        condition = "(output.inputsUploaded && output.inputCheck) && !input.runAnalysis",
        tags$p(
          "Click to Run Analysis:"
        ),  
        actionButton("runAnalysis", "Run Analysis"),
      ),
      # show panel depending on input files
      conditionalPanel(
        condition = "input.runAnalysis && output.normalizeResultsCompleted",
        tags$p(
          "Select Analysis Type:"
        ),
        selectInput(
          inputId = "analysisType",
          label = NULL,
          choices = list("pairwise", "GLM")
        ),
        tags$hr(),
        tags$p(
          "Set Cut Offs:"
        ),
        # glmTreat vs exactTest
        sliderInput(
          "cutLFC", 
          tags$p("LFC Cut Off"), 
          min=0, 
          max=10, 
          step=0.1,
          value=defaultLFC
        ),
        sliderInput(
          "cutFDR",
          tags$p("FDR Cut Off"),
          min = 0, 
          max = 0.1, 
          value=defaultFDR 
        ),
        tags$br(),
        tags$p(
          "Click to Update Analysis:"
        ),  
        actionButton("inputsUpdate", "Update Analysis"),
        tags$hr(),
        tags$p(
          "Design Table:"
        ),
        fluidRow(
          align = "center",
          # display input design table
          tableOutput(outputId = "designTable")
        )
      )
    ),
    
    # Output: Show plots
    mainPanel(
      
      # getting started text
      conditionalPanel(
        condition = "!input.runAnalysis",
        tags$h1("Getting Started", align = "center"),
        tags$br(),
        tags$p(
          HTML("<b>Hello!</b>"),
          HTML("Start in the left-hand sidebar by:")
        ),
        tags$p(
          HTML("<b>1.</b> browsing for a <i>.csv</i> file with the gene counts")
        ),
        tags$p(
          HTML("<b>2.</b> browsing for a <i>.csv</i> file with the experimental design")
        ),
        tags$p(
          HTML("<b>3.</b> clicking the <i>Run Analysis</i> button, which appears after the input files are verified as valid for analysis (see tips below)")
        ),
        tags$br(),
        tags$p(
          "Note that the DE analysis results and plots may take several moments to process depending on the size of the input gene counts table."
        ),
        tags$hr(),
        tags$p(
          align = "center",
          HTML("<b>Helpful Tips</b>")
        ),
        tags$br(),
        tags$p(
          HTML("<b>Tip 1:</b> The input raw gene counts table is expected to contain <i>numeric</i> integer values."),
        ),
        tags$p(
          HTML("<b>Tip 2:</b> Gene names in the first column of the input gene counts table are expected to be <i>character</i> values."),
        ),
        tags$p(
          HTML("<b>Tip 3:</b> Sample names in the first line of the gene counts table <i>must match</i> the sample names contained in the first column of the experimental design table.")
        ),
        tags$p(
          HTML("<b>Tip 4:</b> Sample names contained in the gene counts and experimental design tables are expected to be <i>character</i> values.")
        ),
        tags$p(
          HTML("<b>Tip 5:</b> The input gene counts and experimental design tables must end in the <i>.csv</i> file extension.")
        ),
        tags$hr(),
        tags$p(
          align="center",
          HTML("<b>Data Formatting</b>")
        ),
        tags$p(
          "Example gene counts and experimental design tables are displayed below."
        ),
        tags$br(),
        tags$p(
          align="center",
          HTML("<b>Example Gene Counts Tables</b>")
        ),
        HTML("Example gene counts table of six samples and five genes:"),
        tableOutput(outputId = "exampleCountsOne"),
        HTML("Example gene counts table of twelve samples and three genes:"),
        tableOutput(outputId = "exampleCountsTwo"),
        tags$br(),
        tags$p(
          align="center",
          HTML("<b>Example Experimental Design Tables</b>")
        ),
        fluidRow(
          column(
            width = 6,
            HTML("Example experimental design table of six samples and one factor with two levels:"),
            tableOutput(outputId = "exampleDesignOne"), 
          ),
          column(
            width = 6,
            HTML("Example experimental design table of twelve samples and two factors each with two levels:"),
            tableOutput(outputId = "exampleDesignTwo") 
          ),
        )
      ),
      
      # warning text
      #conditionalPanel(
      #condition = "output.inputsUploaded && !output.inputCheck",
      #tags$h1(
      #"Warning", 
      #align="center"
      #),
      #tags$br(),
      #tags$p(
      #"The data in the uploaded file(s) are not of the correct type or the sample names do not match.",
      #),
      #tags$br(),
      #tags$p(
      #"Please check that each of the input files were uploaded correctly in the left-hand side bar."
      #),
      #tags$p(
      #HTML("Please <b>allow a moment for processing</b> after uploading new input file(s).")
      #),
      #tags$hr(),
      #tags$p(
      #align = "center",
      #HTML("<b>Helpful Tips</b>")
      #),
      #tags$p(
      #HTML("<b>Tip 1:</b> The input gene counts table is expected to contain <i>numeric</i> integer values."),
      #),
      #tags$p(
      #HTML("<b>Tip 2:</b> Sample names contained in the first column of the gene counts and experimental design tables are expected to be <i>character</i> values.")
      #),
      #tags$p(
      #HTML("<b>Tip 3:</b> Sample names in the first line of the gene counts table <i>must match</i> the sample names contained in the first column of the experimental design table.")
      #),
      #tags$p(
      #HTML("<b>Tip 4:</b> The input gene counts and experimental design tables must end in the <i>.csv</i> file extension.")
      #)
      #),
      
      # processing text
      conditionalPanel(
        condition = "output.inputCheck && !output.normalizeResultsCompleted",
        tags$h1(
          "Processing", 
          align="center"
        ),
        tags$br(),
        "The DE analysis results and plots may take several moments to process depending on the size of the input gene counts or experimental design tables."
      ),
      
      # results text and plots
      conditionalPanel(
        condition = "(input.runAnalysis && output.inputCheck) && output.normalizeResultsCompleted",
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
              HTML("<b>Tip 1:</b> The plots and results may take several moments to appear depending on the size of the input gene counts table.")
            ),
            tags$p(
              HTML("<b>Tip 2:</b> Navigate to the <i>Data Normalization</i>, <i>Data Exploration</i>, or <i>Analysis & Results</i> steps by clicking the tabs above.")
            ),
            tags$p(
              HTML("<b>Tip 3:</b> It is possible to change the type of analysis (pairwise or GLM) in the left-hand sidebar.")
            ),
            tags$p(
              HTML("<b>Tip 4:</b> It is possible to change the LFC and FDR cut offs for both the pairwise or GLM analysis in the left-hand sidebar")
            ),
            tags$p(
              HTML("<b>Tip 6:</b> If the normalizaion plot or other results look strange, make sure that the input table contains raw gene counts that have not been normalized.")
            )
          ),
          
          # data normalization tab
          tabPanel(
            "Data Normalization",
            tags$br(),
            tags$p(
              align="center",
              HTML("<b>Data Normalization</b>")
            ),
            imageOutput(outputId = "librarySizes", height="100%", width="100%"),
            downloadButton(outputId = "downloadLibrarySizes", label = "Download Plot"),
            tags$p(
              "The plot of library sizes shows the sequencing library size for each sample before Trimmed Mean of M-values (TMM) normalization.",
              "Libraries are the collection of RNA-seq reads associated with each sample."
            ),
            tags$br(),
            tags$p(
              HTML("<b>Number of Genes with Sufficiently Large Counts:</b>")
            ),
            tableOutput(outputId = "numNorm"),
            tags$p(
              "Filtering is performed to remove genes that were identified as not sufficiently expressed under the experimental conditions."
            ),
            tags$br(),
            tags$p(
              HTML("<b>Normalized Gene Counts Table:</b>")
            ),
            downloadButton(outputId = "cpmNorm", label = "Download Table"),
            tags$p(
              "Normalized values were calcuated in counts per million (CPM) using the normalized library sizes.",
              "The normalization method used with edgeR was the Trimmed Mean of M-values (TMM).",
              "Note that TMM normalization factors do not take into account library sizes."
            )
          ),
          
          # data exploration tab
          tabPanel(
            "Data Exploration",
            tags$br(),
            tags$p(
              align="center",
              HTML("<b>Data Exploration</b>")
            ),
            imageOutput(outputId = "PCA", height="100%", width="100%"),
            downloadButton(outputId = "downloadPCA", label = "Download Plot"),
            tags$p(
              "The above principal component analysis (PCA) plot shows the distances between samples by the approximate the expression differences.",
              "The expression differences were calculated as the the average of the largest absolute LFCs between each pair of samples and the same genes were selected for all comparisons.",
              "Note that the points are replaced by the sample name and colored by the associated factor level."
            ),
            tags$p(
              "PCAs are commonly used to visualize the signal to noise relationship within a data set. For example, the patterns of variation between and within groups."
            ),
            tags$br(),
            imageOutput(outputId = "MDS", height="100%", width="100%"),
            downloadButton(outputId = "downloadMDS", label = "Download Plot"),
            tags$p(
              "The above multidimensional scaling (MDS) plot shows the distances between samples by the approximate the expression differences.",
              "The expression differences were calculated as the the average of the largest absolute LFCs between each pair of samples and the top genes were selected separately for each pairwise comparison.",
              "Note that the points are replaced by the sample name and colored by the associated factor level."
            ),
            tags$br(),
            #imageOutput(outputId = "heatmap", height="100%", width="100%"),
            #downloadButton(outputId = "downloadHeatmap", label = "Download Plot"),
            imageOutput(outputId = "pheatmap", height="100%", width="100%"),
            downloadButton(outputId = "downloadPheatmap", label = "Download Plot"),
            tags$p(
              "The heatmap shows the hierarchical clustering of individual samples by the log2 CPM expression values.",
              "Furthermore, the log2 CPM that has undefined values avoided and poorly defined LFC for low counts shrunk towards zero"
            ),
            tags$br(),
            imageOutput(outputId = "BCV", height="100%", width="100%"),
            downloadButton(outputId = "downloadBCV", label = "Download Plot"),
            tags$p(
              "The biological coefficient of variation (BCV) plot is the square root of the dispersion parameter under the negative binomial model and is equivalent to estimating the dispersions of the negative binomial model."
            ),
            tags$p(
              "The negative binomial distribution is used to identify genes with sufficiently large counts to be considered a real signal and measures what it expects to be missing data, or a measure of dispersion.",
              "For example, a BCV^2 of 0.4 indicates a 20% difference between samples."
            ),
            tags$p(
              "The negative binomial distribution models biological noise rather than sequencing noise (e.g., library size normalization)."
            )
          ),
          
          # analysis & results tab
          tabPanel(
            "Analysis & Results", 
            # show pairwise results
            conditionalPanel(
              condition = "input.analysisType == 'pairwise'",
              tags$br(),
              tags$p(
                align="center",
                HTML("<b>Pairwise Comparison</b>")
              ),
              span(
                textOutput(outputId = "pairwiseComparison"), 
                align="center"
              ),
              tags$br(),
              tags$p(
                "Exact tests are performed to identify differences in the means between two groups of negative-binomially distributed counts.",
                "A comparison or contrast is a linear combination of means for groups of samples."
              ),
              tags$br(),
              fluidRow(
                column(
                  width = 6,
                  tags$p(
                    HTML("<b>Choose Factor Levels for Comparison:</b>")
                  ),
                  # select variable for the first level
                  selectInput(
                    inputId = "levelOne",
                    label = "First Level",
                    choices = c("")
                  ),
                  # select variable for the second level
                  selectInput(
                    inputId = "levelTwo",
                    label = "Second Level",
                    choices = c("")
                  )
                ),
                column(
                  width = 6,
                  tags$p(
                    HTML("<b>Click to Analyze:</b>")
                  ),  
                  actionButton("pairwiseUpdate", "Analyze")
                )
              ),
              # show pairwise results
              conditionalPanel(
                condition = "output.pairwiseResultsCompleted",
                tags$hr(),
                tags$p(
                  align="center",
                  HTML("<b>Pairwise Results</b>")
                ),
                tags$br(),
                fluidRow(
                  column(
                    width = 6,
                    imageOutput(outputId = "pairwiseMD", height="100%", width="100%"),
                    downloadButton(outputId = "downloadPairwiseMD", label = "Download Plot")
                  ),
                  column(
                    width = 6,
                    tags$p(
                      HTML("<b>Number of Significantly DE Genes:</b>")
                    ),
                    tableOutput(outputId = "pairwiseSummary"),
                    tags$p(
                      "The above table shows the number of significantly DE genes that were up- or down-expressed in the input comparison. Signifigance was determined by the input LFC and FDR cut offs."
                    )
                  )
                ),
                tags$p(
                  "The mean-difference (MD) plot shows the log2 fold changes (LFCs) in expression differences versus average log2 CPM values.",
                  "Red points are significantly up-expressed genes and the blue points are significantly down-expressed, where signifigance was determined by the input FDR cut off.",
                  "The blue lines indicate the input LFC cut off, which will be used to further filter the set of significantly DE genes."
                ),
                tags$br(),
                fluidRow(
                  column(
                    width = 6,
                    tags$p(
                      HTML("<b>DE Analysis Results Table:</b>")
                    ),
                    downloadButton(outputId = "pairwiseResults", label = "Download Table"),
                    tags$p(
                      "A table of pairwise DE analysis results sorted by increasing FDR adjusted p-values may be downloaded by clicking the above button."
                    ),
                    tags$br(),
                    tags$p(
                      HTML("<b>DE Analysis Significant Results Table:</b>")
                    ),
                    downloadButton(outputId = "pairwiseSigResults", label = "Download Table"),
                    tags$p(
                      "A table of pairwise DE analysis significant results sorted by increasing FDR adjusted p-values may be downloaded by clicking the above button.",
                      "Signifigance was determined by the input LFC and FDR cut offs."
                    )
                  ),
                  column(
                    width = 6,
                    tags$p(
                      HTML("<b>DE Genes IDs:</b>")
                    ),
                    downloadButton(outputId = "pairwiseResultsIDs", label = "Download Table"),
                    tags$p(
                      "A list of the DE gene IDs from the pairwise analysis may be downloaded by clicking the above button."
                    ),
                    tags$br(),
                    tags$p(
                      HTML("<b>Significantly DE Genes IDs:</b>")
                    ),
                    downloadButton(outputId = "pairwiseSigResultsIDs", label = "Download Table"),
                    tags$p(
                      "A list of the significantly DE gene IDs from the pairwise analysis may be downloaded by clicking the above button.",
                      "Signifigance was determined by the input LFC and FDR cut offs."
                    )
                  )
                ),
                tags$hr(),
                tags$p(
                  align="center",
                  HTML("<b>Results Exploration</b>")
                ),
                tags$br(),
                imageOutput(outputId = "pheatmapPairwise", height="100%", width="100%"),
                downloadButton(outputId = "downloadPheatmapPairwise", label = "Download Plot"),
                tags$p(
                  "The heatmap displays the hierarchical clustering of individual samples by the log2 CPM expression values of significantly DE genes from the pairwise analysis.",
                  "Signifigance was determined by the input FDR and LFC cut offs."
                ),
                tags$p(
                  HTML("<b>Note</b> that the heatmap function requires at least 2 significantly DE genes to create the plot.")
                ),
                tags$br(),
                plotOutput(outputId = "pairwiseVolcano"),
                #click = "pairwiseVolcano_click",
                #dblclick = "pairwiseVolcano_dblclick",
                #hover = "pairwiseVolcano_hover",
                #brush = "pairwiseVolcano_brush"),
                #verbatimTextOutput(outputId = "pairwiseVolcanoInfo")
                downloadButton(outputId = "downloadPairwiseVolcano", label = "Download Plot"),
                tags$p(
                  "The above volcano plot displays the association between statistical significance (e.g., p-value) and magnitude of gene expression (fold change).",
                  "Signifigance and magnitude were determined by the input FDR and LFC cut offs."
                )
              )
            ),
            # show GLM comparison
            conditionalPanel(
              condition = "input.analysisType == 'GLM'",
              tags$br(),
              tags$p(
                align="center",
                HTML("<b>GLM Comparison</b>")
              ),
              span(
                textOutput(outputId = "glmComparison"), 
                align="center"
              ),
              tags$br(),
              tags$p(
                "The GLM is used to perform an ANOVA-like analysis to identify any significant main effect associated with an explanatory variable.",
                "An explanatory variable may be a categorical factor with two or more levels, such as treat and cntrl."
              ),
              tags$br(),
              tags$p(
                "Additionally, genes above the input log2 fold change (LFC) threshold are identified as significantly DE using t-tests relative to a threshold (TREAT) with the glmTreat function of edgeR.",
                "If the input LFC cut off is set to 0, then the glmQLFTest function is used instead."
              ),
              tags$br(),
              fluidRow(
                column(
                  width = 6,
                  tags$p(
                    HTML("<b>Enter Expression for Comparison:</b>")
                  ),
                  textInput("compareExpression", "Expression")
                ),
                column(
                  width = 6,
                  tags$p(
                    HTML("<b>Click to Analyze:</b>")
                  ),  
                  actionButton("glmUpdate", "Analyze")
                )
              ),
              tags$br(),
              tags$p(
                HTML("<b>Tip!</b> Make sure that the factors used in the expression are spelled the same as in the experimental design file and shown in the left-hand sidebar.")
              ),
              tags$br(),
              tags$p(
                "Valid expressions must consist of the factors contained in the input experimental design file, which is displayed in the left-hand sidebar."
              ),
              tags$p(
                "Examples of designing model expressions for ANOVA-like tests are availble in the",
                tags$a("edgeR manual", href = "https://www.bioconductor.org/packages/release/bioc/vignettes/edgeR/inst/doc/edgeRUsersGuide.pdf"),
                " (e.g., sections 3.2.6 & 4.4.9)."
              ),
              tags$p(
                HTML("A detailed description of designing model expressions is provided in the paper \"A guide to creating design matrices for gene expression experiments\" <i>doi: 10.12688/f1000research.27893.1</i> (e.g., studies with multiple factors).")
              ),
              # show glm results
              conditionalPanel(
                condition = "output.glmResultsCompleted",
                tags$hr(),
                tags$p(
                  align="center",
                  HTML("<b>GLM Results</b>")
                ),
                tags$br(),
                fluidRow(
                  column(
                    width = 6,
                    imageOutput(outputId = "glmMD", height="100%", width="100%"),
                    downloadButton(outputId = "downloadGLMMD", label = "Download Plot")
                  ),
                  column(
                    width = 6,
                    tags$p(
                      HTML("<b>Number of Significantly DE Genes:</b>")
                    ),
                    tableOutput(outputId = "glmSummary"),
                    tags$p(
                      "The above table shows the number of significantly DE genes that were up- or down-expressed in the input comparison.",
                      "Signifigance was determined by the input LFC and FDR cut offs."
                    )
                  )
                ),
                tags$p(
                  "The mean-difference (MD) plot shows the LFCs in expression differences versus average log2 CPM values.",
                  "Red points are significantly up-expressed genes and the blue points are significantly down-expressed, where signifigance was determined by the input FDR and LFC cut offs.",
                  "The blue lines indicate the input LFC cut off, which was used by the glmTreat function to determine significantly DE genes relative to the LFC threshold."
                ),
                tags$br(),
                fluidRow(
                  column(
                    width = 6,
                    tags$p(
                      HTML("<b>DE Analysis Results Table:</b>")
                    ),
                    downloadButton(outputId = "glmResults", label = "Download Table"),
                    tags$p(
                      "A table of GLM DE analysis results sorted by increasing FDR adjusted p-values may be downloaded by clicking the above button."
                    ),
                    tags$br(),
                    tags$p(
                      HTML("<b>DE Analysis Significant Results Table:</b>")
                    ),
                    downloadButton(outputId = "glmSigResults", label = "Download Table"),
                    tags$p(
                      "A table of GLM DE analysis significant results sorted by increasing FDR adjusted p-values may be downloaded by clicking the above button.",
                      "Signifigance was determined by the input LFC and FDR cut offs."
                    )
                  ),
                  column(
                    width = 6,
                    tags$p(
                      HTML("<b>DE Gene IDs:</b>")
                    ),
                    downloadButton(outputId = "glmResultsIDs", label = "Download Table"),
                    tags$p(
                      "A list of the DE gene IDs from the ANOVA-like analysis may be downloaded by clicking the above button."
                    ),
                    tags$br(),
                    tags$p(
                      HTML("<b>Significantly DE Gene IDs:</b>")
                    ),
                    downloadButton(outputId = "glmSigResultsIDs", label = "Download Table"),
                    tags$p(
                      "A list of the significantly DE gene IDs from the ANOVA-like analysis may be downloaded by clicking the above button.",
                      "Signifigance was determined by the input LFC and FDR cut offs."
                    )
                  )
                ),
                tags$hr(),
                tags$p(
                  align="center",
                  HTML("<b>Model Exploration</b>")
                ),
                tags$br(),
                imageOutput(outputId = "glmDispersions", height="100%", width="100%"),
                downloadButton(outputId = "downloadGLMDispersions", label = "Download Plot"),
                tags$p(
                  "Above is a plot of the genewise quasi-likelihood (QL) dispersion against the log2 CPM gene expression levels.",
                  "Dispersion estimates are obtained after fitting negative binomial models and calculating dispersion estimates."
                ),
                tags$hr(),
                tags$p(
                  align="center",
                  HTML("<b>Results Exploration</b>")
                ),
                tags$br(),
                imageOutput(outputId = "pheatmapGLM", height="100%", width="100%"),
                downloadButton(outputId = "downloadPheatmapGLM", label = "Download Plot"),
                tags$p(
                  "The heatmap displays the hierarchical clustering of individual samples by the log2 CPM expression values of significantly DE genes from the GLM analysis.",
                  "Signifigance was determined by the input FDR and LFC cut offs."
                ),
                tags$p(
                  HTML("<b>Note</b> that the heatmap requires at least 2 significantly DE genes to create the plot.")
                ),
                tags$br(),
                plotOutput(outputId = "glmVolcano"),
                downloadButton(outputId = "downloadGLMVolcano", label = "Download Plot"),
                tags$p(
                  "The above volcano plot displays the association between statistical significance (e.g., p-value) and magnitude of gene expression (fold change).",
                  "Signifigance and magnitude were determined by the input FDR and LFC cut offs."
                )
              )
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
              "This application for DE analysis was created by ",
              tags$a("Elizabeth Brooks",href = "https://www.linkedin.com/in/elizabethmbrooks/"),
              "."
            ),
            tags$p(
              "The latest version of this application may be downloaded from ",
              tags$a("GitHub",href = "https://github.com/ElizabethBrooks/DGEAnalysis_ShinyApps"),
              "."
            ),
            tags$p(
              "Example gene counts and experimental design tables are also provided on ",
              tags$a("GitHub", href = "https://github.com/ElizabethBrooks/DGEAnalysis_ShinyApps/tree/main/data/edgeR"),
              "."
            ),
            tags$p(
              "Gene tables may be created from RNA-seq data as described in ", 
              tags$a("Bioinformatics Analysis of Omics Data with the Shell & R", href = "https://morphoscape.wordpress.com/2022/07/28/bioinformatics-analysis-of-omics-data-with-the-shell-r/"), 
              "."
            ),
            tags$p(
              "A tutorial of the biostatistical analysis performed in this application is provided in ", 
              tags$a("Downstream Bioinformatics Analysis of Omics Data with edgeR", href = "https://morphoscape.wordpress.com/2022/08/09/downstream-bioinformatics-analysis-of-omics-data-with-edger/"), 
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
  
  # render example gene counts table
  output$exampleCountsOne <- renderTable({
    # create example counts table
    exCountsTable <- data.frame(
      Gene = c("gene-1", "gene-2", "gene-3", "gene-4", "gene-5"),
      SampleOne = c("0", "0", "0", "0", "0"),
      SampleTwo = c("10", "20", "30", "40", "50"),
      SampleThree = c("111", "222", "333", "444", "555"),
      SampleFour = c("1", "2", "3", "4", "5"),
      SampleFive = c("0", "0", "0", "0", "0"),
      SampleSix = c("1000", "2000", "3000", "4000", "5000"),
      SampleSeven = c("11", "12", "13", "14", "15"),
      SampleEight = c("0", "0", "0", "0", "0")
    )
  })
  
  # render example gene counts table
  output$exampleCountsTwo <- renderTable({
    # create example counts table
    exCountsTable <- data.frame(
      Gene = c("geneA", "geneB", "geneC"),
      sample_1 = c("0", "0", "0"),
      sample_2 = c("10", "20", "30"),
      sample_3 = c("111", "222", "333"),
      sample_4 = c("1", "2", "3"),
      sample_5 = c("3", "3", "3"),
      sample_6 = c("1000", "2000", "3000"),
      sample_7 = c("11", "12", "13"),
      sample_8 = c("1", "1", "1"),
      sample_9 = c("123", "12", "1"),
      sample_10 = c("3", "32", "321"),
      sample_11 = c("33", "333", "33"),
      sample_12 = c("2", "2", "2")
    )
  })
  
  # render first example gene counts table
  output$exampleDesignOne <- renderTable({
    # create example counts table
    exDesignTable <- data.frame(
      Sample = c("SampleOne", "SampleTwo", "SampleThree", "SampleFour", "SampleFive", "SampleSix"),
      Group = c("cntrl", "cntrl", "cntrl", "treat", "treat", "treat")
    )
  })
  
  # render second example gene counts table
  output$exampleDesignTwo <- renderTable({
    # create example counts table
    exDesignTable <- data.frame(
      Individual = c("sample_1", "sample_2", "sample_3", "sample_4", "sample_5", "sample_6", "sample_7", "sample_8", "sample_9", "sample_10", "sample_11", "sample_12"),
      Factors = c("cntrl.high", "cntrl.high", "cntrl.high", "cntrl.low", "cntrl.low", "cntrl.low", "treat.high", "treat.high", "treat.high", "treat.low", "treat.low", "treat.low")
    )
  })
  
  ##
  # Data Setup
  ##
  
  # reactive function to retrieve input data
  inputGeneCounts <- reactive({
    # require input data
    req(input$geneCountsTable)
    # check the input table is not null
    if(is.null(input$geneCountsTable)){
      return(NULL)
    }
    # read the file
    geneCounts <- read.csv(file = input$geneCountsTable$datapath, row.names=1)
    # trim the data table to remove lines with counting statistics (htseq)
    removeList <- c("__no_feature", "__ambiguous", "__too_low_aQual", "__not_aligned", "__alignment_not_unique")
    geneCounts[!row.names(geneCounts) %in% removeList,]
  })
  
  # check input counts type
  countsType <- function(){
    # retrieve input gene counts
    geneCounts <- inputGeneCounts()    
    # loop over each data frame column
    for(i in 1:ncol(geneCounts)) { 
      # check data type
      if(!is.integer(geneCounts[,i])){
        return(NULL)
      }
    }
    # return the counts table
    geneCounts
  }
  
  # reactive function to retrieve input data
  inputDesign <- reactive({
    # require input data
    req(input$expDesignTable)
    # check the input table is not null
    if(is.null(input$expDesignTable)){
      return(NULL)
    }
    # import grouping factor
    targets <- read.csv(input$expDesignTable$datapath, row.names=1)
  })
  
  # check if input files have been uploaded
  output$inputsUploaded <- function(){
    # check if the input files are valid
    if(is.null(inputGeneCounts())) {
      return(FALSE)
    }else if(is.null(inputDesign())) {
      return(FALSE)
    }
    return(TRUE)
  }
  outputOptions(output, 'inputsUploaded', suspendWhenHidden=FALSE)
  
  # check input design type
  designFactors <- reactive({
    # require input data
    req(input$expDesignTable)
    # retrieve input design
    targets <- inputDesign()
    # check data type of the sample names
    if(!is.character(rownames(targets))){
      return(NULL)
    }
    # setup a design matrix
    factor(targets[,1])
  })
  
  # compare input design and counts samples
  compareSamples <- function(){
    # check the inputs
    if(is.null(countsType())) {
      return(NULL)
    }else if(is.null(inputDesign())) {
      return(NULL)
    } 
    # retrieve input design samples
    targets <- inputDesign()
    designSamples <- data.frame(ID1 = targets[,1])
    # retrieve input gene counts samples
    geneCounts <- countsType() 
    countsSamples <- data.frame(ID2 = colnames(geneCounts))
    # first simply check if the number of samples matches
    if(nrow(designSamples) != nrow(countsSamples)) return(NULL)
    # find samples in counts, but not in design
    mismatch_counts <- designSamples %>% 
      filter(!designSamples$ID1 %in% countsSamples$ID2)
    # find samples in design, but not in counts
    mismatch_design <- countsSamples %>% 
      filter(!countsSamples$ID2 %in% designSamples$ID1)
    # check total non matches
    totalMismatches <- nrow(mismatch_counts) + nrow(mismatch_design)
    # check if all matched
    if(totalMismatches != 0){
      # all matched
      return(TRUE)
    }
    # there were mismatches
    return(NULL)
  }
  
  # check if inputs are good
  output$inputCheck <- function(){
    if(is.null(compareSamples())) {
      return(FALSE)
    }
    return(TRUE)
  }
  outputOptions(output, 'inputCheck', suspendWhenHidden=FALSE)
  
  # update inputs for comparisons
  observeEvent(input$runAnalysis, {
    # retrieve input design table
    group <- levels(designFactors())
    # update and set the first select items
    updateSelectInput(
      session, 
      "levelOne",
      choices = group,
    )
    # update and set the second select items
    updateSelectInput(
      session, 
      "levelTwo",
      choices = group,
      selected = tail(group, 1)
    )
    # create temporary expression
    tmpExpression <- paste(head(group, 1), tail(group, 1), sep = "-")
    # update and set the glm comparison expression
    updateTextInput(
      session,
      "compareExpression",
      value = tmpExpression
    )
  })
  
  # setup reactive LFC value
  valueLFC <- reactiveVal(defaultLFC)
  
  # update LFC value
  observeEvent(input$inputsUpdate, {
    valueLFC(input$cutLFC)
  })
  
  # setup reactive FDR value
  valueFDR <- reactiveVal(defaultFDR)
  
  # update FDR value
  observeEvent(input$inputsUpdate, {
    valueFDR(input$cutFDR)
  })
  
  # render experimental design table
  output$designTable <- renderTable({
    # retrieve input design table
    group <- designFactors()
    # retrieve input gene counts table
    geneCounts <- countsType()
    # retrieve column names
    sampleNames <- colnames(geneCounts)
    # create data frame
    design <- data.frame(
      Sample = sampleNames,
      Factors = group
    )
  })
  
  ##
  # Data Normalization & Exploration
  ##
  
  # function for data normalization
  normalizeData <- function(){
    # retrieve input design table
    group <- designFactors()
    # begin to construct the DGE list object
    geneCounts <- countsType()
    list <- DGEList(counts=geneCounts,group=group)
  }
  
  # check if results have completed
  output$normalizeResultsCompleted <- function(){
    if(is.null(normalizeData())){
      return(FALSE)
    }
    return(TRUE)
  }
  outputOptions(output, 'normalizeResultsCompleted', suspendWhenHidden=FALSE, priority=0)
  
  # function for normalized data filtering
  filterNorm <- function(){
    # begin to construct the DGE list object
    list <- normalizeData()
    # filter the list of gene counts based on expression levels
    keep <- filterByExpr(list)
    # remove genes that are not expressed in either experimental condition
    list <- list[keep, , keep.lib.sizes=FALSE]
    # calculate scaling factors
    list <- calcNormFactors(list)
  }
  
  # download table with number of filtered genes
  output$cpmNorm <- downloadHandler(
    # retrieve file name
    filename = function() {
      # setup output file name
      paste("normalizedCounts", "csv", sep = ".")
    },
    # read in data
    content = function(file) {
      # begin to construct the DGE list object
      list <- normalizeData()
      # compute counts per million (CPM) using normalized library sizes
      normList <- cpm(list, normalized.lib.sizes=TRUE)
      # add gene row name tag
      normList <- as_tibble(normList, rownames = "gene")
      # output table
      write.table(normList, file, sep=",", row.names=FALSE, quote=FALSE)
    }
  )
  
  # plot of library sizes before normalization
  createLibrarySizes <- function(){
    # begin to construct the DGE list object
    list <- normalizeData()
    # retrieve the number of samples
    numSamples <- ncol(list)
    # create barplot of library sizes before normalization
    barplot(list$samples$lib.size*1e-6, names=1:numSamples, ylab="Library Size (millions)", main = "Library Sizes Before Normalization")
  }
  
  # render plot of library sizes before normalization
  output$librarySizes <- renderImage({
    # save the plot
    exportFile <- "librarySizesPlot.png"
    png(exportFile)
    createLibrarySizes()
    dev.off()
    # Return a list
    list(src = exportFile, alt = "Invalid Results")
  }, deleteFile = TRUE)
  
  # download handler for the bar plot
  output$downloadLibrarySizes <- downloadHandler(
    filename = function() {
      "librarySizesPlot.png"
    },
    content = function(file) {
      # save the plot
      png(file)
      createLibrarySizes()
      dev.off()
    }
  )
  
  # render table with number of filtered genes
  output$numNorm <- renderTable({
    # begin to construct the DGE list object
    list <- normalizeData()
    # filter the list of gene counts based on expression levels
    keep <- filterByExpr(list)
    # view the number of filtered genes
    table(keep)[2]
  }, colnames = FALSE)
  
  # PCA plot
  createPCA <- function(){
    # retrieve input design table
    group <- designFactors()
    # calculate scaling factors
    list <- filterNorm()
    ## TO-DO: consider allowing users to input shapes and colors or other features
    # retrieve the number of grouping levels
    stringLevels <- gsub("\\..*","", (levels(group)))
    # setup colors and points
    colors <- plotColors[1:length(stringLevels)]
    #points <- c(0:length(unique(stringLevels)))
    # add extra space to right of plot area and change clipping to figure
    par(mar=c(6.5, 5.5, 5.5, 9.5), xpd=TRUE)
    # PCA plot with distances approximating log2 fold changes
    #plotMDS(list, col=colors[group], pch=points[group], gene.selection="common", main = "Principal Component Analysis")
    plotMDS(list, col=colors[group], gene.selection="common", main = "Principal Component Analysis")
    # place the legend outside the right side of the plot
    #legend("topright", inset=c(-0.5,0), legend=levels(group), pch=points, col=colors)
    legend("topright", inset=c(-0.5,0), legend=levels(group), fill=colors)
  }
  
  # render PCA plot
  output$PCA <- renderImage({
    # save the plot
    exportFile <- "PCAPlot.png"
    png(exportFile)
    createPCA()
    dev.off()
    # Return a list
    list(src = exportFile, alt = "Invalid Results")
  }, deleteFile = TRUE)
  
  # download handler for the PCA plot
  output$downloadPCA <- downloadHandler(
    filename = function() {
      "PCAPlot.png"
    },
    content = function(file) {
      # save the plot
      png(file)
      createPCA()
      dev.off()
    }
  )
  
  # MDS plot
  createMDS <- function(){
    # retrieve input design table
    group <- designFactors()
    # calculate scaling factors
    list <- filterNorm()
    ## TO-DO: consider allowing users to input shapes and colors or other features
    # retrieve the number of grouping levels
    stringLevels <- gsub("\\..*","", (levels(group)))
    # setup colors and points
    colors <- plotColors[1:length(stringLevels)]
    #points <- c(0:length(unique(stringLevels)))
    # add extra space to right of plot area and change clipping to figure
    par(mar=c(6.5, 5.5, 5.5, 9.5), xpd=TRUE)
    # PCA plot with distances approximating log2 fold changes
    #plotMDS(list, col=colors[group], pch=points[group], main = "Multi-Dimensional Scaling (MDS) Plot")
    plotMDS(list, col=colors[group], main = "Multi-Dimensional Scaling")
    # place the legend outside the right side of the plot
    #legend("topright", inset=c(-0.5,0), legend=levels(group), pch=points, col=colors)
    legend("topright", inset=c(-0.5,0), legend=levels(group), fill=colors)
  }
  
  # render MDS plot
  output$MDS <- renderImage({
    # save the plot
    exportFile <- "MDSPlot.png"
    png(exportFile)
    createMDS()
    dev.off()
    # Return a list
    list(src = exportFile, alt = "Invalid Results")
  }, deleteFile = TRUE)
  
  # download handler for the MDS plot
  output$downloadMDS <- downloadHandler(
    filename = function() {
      "MDSPlot.png"
    },
    content = function(file) {
      # save the plot
      png(file)
      createMDS()
      dev.off()
    }
  )
  
  # pheatmap of individual samples using moderated log2 CPM
  createPheatmap <- function(){
    # retrieve input design
    targets <- inputDesign()
    # calculate scaling factors
    list <- filterNorm()
    # calculate the log2 CPM of the gene count data
    logcpm <- cpm(list, log=TRUE)
    #Create data frame with the experimental design layout
    exp_factor <- data.frame(Sample = unlist(targets, use.names = FALSE))
    rownames(exp_factor) <- colnames(logcpm)
    # TO-DO: use color blind safe pallette for sample dendrogram
    # create heatmap of individual samples using moderated log2 CPM
    as.ggplot(
      pheatmap(logcpm, scale="row", annotation_col = exp_factor, 
               main="Heatmap of Samples", show_rownames = FALSE,
               color = colorRampPalette(c(plotColors[5], "white", plotColors[6]))(100))
    )
  }
  
  # render pheatmap of individual samples using moderated log2 CPM
  output$pheatmap <- renderImage({
    # save image
    exportFile <- "pheatmapPlotSamples.png"
    # create the plot
    pheatmapPlot <- createPheatmap()
    # save the plot
    ggsave(exportFile, plot = pheatmapPlot, bg = "white", device = "png")
    # Return a list
    list(src = exportFile, alt = "Invalid Results", height = "500px")
  }, deleteFile = TRUE)
  
  # download handler for the pheatmap plot
  output$downloadPheatmap <- downloadHandler(
    filename = function() {
      "pheatmapPlotSamples.png"
    },
    content = function(file) {
      # create the plot
      pheatmapPlot <- createPheatmap()
      # save the plot
      ggsave(file, plot = pheatmapPlot, bg = "white", device = "png")
    }
  )
  
  # plot of dispersion estimates and biological coefficient of variation
  createBCV <- function(){
    # calculate scaling factors
    list <- filterNorm()
    # estimate common dispersion and tagwise dispersions to produce a matrix of pseudo-counts
    list <- estimateDisp(list)
    # create BCV plot
    plotBCV(list, main = "Biological Coefficient of Variation")
  }
  
  # render plot of dispersion estimates and biological coefficient of variation
  output$BCV <- renderImage({
    # save the plot
    exportFile <- "BCVPlot.png"
    png(exportFile)
    createBCV()
    dev.off()
    # Return a list
    list(src = exportFile, alt = "Invalid Results")
  }, deleteFile = TRUE)
  
  # download handler for the BCV plot
  output$downloadBCV <- downloadHandler(
    filename = function() {
      "BCVPlot.png"
    },
    content = function(file) {
      # save the plot
      png(file)
      createBCV()
      dev.off()
    }
  )
  
  ##
  # Pairwise Comparisons (Contrasts)
  ##
  
  # render text with pairwise comparison
  output$pairwiseComparison <- renderText({
    # require input data
    req(input$levelOne, input$levelTwo)
    # create string with factor levels
    paste(input$levelTwo, input$levelOne, sep = " vs ")
  })
  
  # function to calculate table of DE genes
  pairwiseTest <- eventReactive(list(input$inputsUpdate, input$pairwiseUpdate), {
    # require valid inputs
    if(is.null(compareSamples())){
      return(NULL)
    }
    # require input data
    req(input$levelOne, input$levelTwo)
    # calculate scaling factors
    list <- filterNorm()
    # estimate common dispersion and tagwise dispersions to produce a matrix of pseudo-counts
    list <- estimateDisp(list)
    # perform exact test
    exactTest(list, pair=c(input$levelOne, input$levelTwo))
  })
  
  # check if results have completed
  output$pairwiseResultsCompleted <- function(){
    if(is.null(pairwiseTest())){
      return(FALSE)
    }
    return(TRUE)
  }
  outputOptions(output, 'pairwiseResultsCompleted', suspendWhenHidden=FALSE, priority=0)
  
  # render results summary
  output$pairwiseSummary <- renderTable({
    # perform exact test
    tested <- pairwiseTest()
    # view the total number of differentially expressed genes at a FDR and LFC cut off
    DGEgenes = decideTests(tested,p.value=valueFDR(), lfc=valueLFC())
    resultsSummary <- summary(DGEgenes)
    # create the results summary
    resultsTable <- data.frame(
      Direction = c("Down", "NotSig", "Up"),
      Number = resultsSummary[,1]
    )
    # return the formatted results summary
    resultsTable
  })
  
  # pheatmap of pairwise DGE 
  createPairwisePheatmapDGE <- function(){
    # perform exact test
    tested <- pairwiseTest()
    # retrieve input design
    targets <- inputDesign()
    # calculate scaling factors
    list <- filterNorm()
    # create a results table of DE genes by FDR and LFC
    resultsTbl <- topTags(tested, n=nrow(tested$table), adjust.method="fdr", p.value=valueFDR())$table
    # identify significantly DE genes
    DGESubset <- resultsTbl[resultsTbl$logFC > valueLFC() | resultsTbl$logFC < (-1*valueLFC()),]
    # calculate the log2 CPM of the gene count data
    logcpm <- cpm(list, log=TRUE)
    # subset the log2 CPM by the DGE set
    #logcpmSubset <- subset(logcpm,
    #                       grepl(
    #                         paste0(rownames(DGESubset), collapse = "|"),
    #                         rownames(logcpm),
    #                         ignore.case = TRUE
    #                       )
    #)
    DGESubset.keep <- rownames(logcpm) %in% rownames(DGESubset)
    logcpmSubset <- logcpm[DGESubset.keep, ]
    # combine all columns into one period separated
    exp_factor <- data.frame(Sample = unlist(targets, use.names = FALSE))
    rownames(exp_factor) <- colnames(logcpmSubset)
    # TO-DO: use color blind safe pallette for sample dendrogram
    #Create heatmap for DGE
    as.ggplot(
      pheatmap(logcpmSubset, scale="row", annotation_col = exp_factor, 
               main="Heatmap of Pairwise DE Genes", show_rownames = FALSE,
               color = colorRampPalette(c(plotColors[5], "white", plotColors[6]))(100))
    )
  }
  
  # render pheatmap of pairwise DGE
  output$pheatmapPairwise <- renderImage({
    # save image
    exportFile <- "pheatmapPlotPairwise.png"
    # create the plot
    pheatmapPlot <- createPairwisePheatmapDGE()
    # save the plot
    ggsave(exportFile, plot = pheatmapPlot, bg = "white", device = "png")
    # Return a list
    list(src = exportFile, alt = "Invalid Results", height = "500px")
  }, deleteFile = TRUE)
  
  # download handler for the pairwise heatmap plot
  output$downloadPheatmapPairwise <- downloadHandler(
    filename = function() {
      "pheatmapPlotPairwise.png"
    },
    content = function(file) {
      # create the plot
      pheatmapPlot <- createPairwisePheatmapDGE()
      # save the plot
      ggsave(file, plot = pheatmapPlot, bg = "white", device = "png")
    }
  )
  
  # plot of log2-fold change against log2-counts per million with DE genes highlighted
  createPairwiseMD <- function(){
    # perform exact test
    tested <- pairwiseTest()
    # return MD plot
    plotMD(tested, main = "Mean-Differences of Pairwise DE Genes", adjust.method="fdr", p.value=valueFDR())
    # add blue lines to indicate 2-fold changes
    abline(h=c((-1*valueLFC()), valueLFC()), col="blue") 
  }
  
  # render plot of log2-fold change against log2-counts per million with DE genes highlighted
  output$pairwiseMD <- renderImage({
    # save the plot
    exportFile <- "pairwiseMDPlot.png"
    png(exportFile)
    createPairwiseMD()
    dev.off()
    # Return a list
    list(src = exportFile, alt = "Invalid Results")
  }, deleteFile = TRUE)
  
  
  # download handler for the MD plot
  output$downloadPairwiseMD <- downloadHandler(
    filename = function() {
      "pairwiseMDPlot.png"
    },
    content = function(file) {
      # save the plot
      png(file)
      createPairwiseMD()
      dev.off()
    }
  )
  
  # create volcano plot
  plotPairwiseVolcano <- function(){
    # perform exact test
    tested <- pairwiseTest()
    # create a results table of DE genes
    resultsTbl <- topTags(tested, n=nrow(tested$table), adjust.method="fdr")$table
    # add column for identifying direction of DE gene expression
    resultsTbl$colorDE <- plotColors[5]
    resultsTbl$alphaDE <- 0.75
    # identify significantly up DE genes
    resultsTbl$colorDE[resultsTbl$logFC > valueLFC() & resultsTbl$FDR < valueFDR()] <- plotColors[4]
    resultsTbl$alphaDE[resultsTbl$logFC > valueLFC() & resultsTbl$FDR < valueFDR()] <- 1
    #resultsTbl$colorDE[sign(resultsTbl$logFC) == 1 & resultsTbl$FDR < valueFDR()] <- "Up"
    # identify significantly down DE genes
    resultsTbl$colorDE[resultsTbl$logFC < (-1*valueLFC()) & resultsTbl$FDR < valueFDR()] <- plotColors[6]
    resultsTbl$alphaDE[resultsTbl$logFC < (-1*valueLFC()) & resultsTbl$FDR < valueFDR()] <- 1
    #resultsTbl$colorDE[sign(resultsTbl$logFC) == -1 & resultsTbl$FDR < valueFDR()] <- "Down"
    # add column with -log10(FDR) values
    resultsTbl$negLog10FDR <- -log10(resultsTbl$FDR)
    # create volcano plot
    ggplot(data=resultsTbl, aes(x=logFC, y=negLog10FDR, color = colorDE, alpha = alphaDE)) + 
      geom_point() +
      theme_minimal() +
      scale_color_identity() +
      scale_alpha(guide = 'none') +
      ggtitle("Volcano Plot of Pairwise DE Genes") +
      theme(plot.title = element_text(hjust = 0.5)) +
      theme(plot.title = element_text(face="bold")) +
      xlab("LFC")
  }
  
  # render volcano plot
  output$pairwiseVolcano <- renderPlot({
    # create plot
    plotPairwiseVolcano()
  })
  
  
  # download handler for the volcano plot
  output$downloadPairwiseVolcano <- downloadHandler(
    filename = function() {
      "pairwiseVolcanoPlot.png"
    },
    content = function(file) {
      # create plot
      volcanoPlotPairwise <- plotPairwiseVolcano()
      # save plot
      ggsave(file, plot = volcanoPlotPairwise, device = "png")
    }
  )
  
  ## TO-DO: allow users to select plot points
  # render text from brushed plot points
  #output$volcanoInfo <- renderText({
  # perform exact test
  #tested <- pairwiseTest()
  # create a results table of DE genes
  #resultsTbl <- topTags(tested, n=nrow(tested$table), adjust.method="fdr", p.value=valueFDR())$table
  # add column with -log10(FDR) values
  #resultsTbl$negLog10FDR <- -log10(resultsTbl$FDR)
  # With base graphics, need to tell it what the x and y variables are.
  #brushedPoints(resultsTbl, input$volcano_brush, xvar = "logFC", yvar = "negLog10FDR")
  #})
  
  # download table with number of DE genes
  output$pairwiseResults <- downloadHandler(
    filename = function() {
      # setup output file name
      paste(input$levelTwo, input$levelOne, "pairwiseDE_genes.csv", sep = "_")
    },
    content = function(file) {
      # perform exact test
      tested <- pairwiseTest()
      # view results table of top 10 DE genes
      resultsTbl <- topTags(tested, n=nrow(tested$table), adjust.method="fdr")$table
      # add gene row name tag
      resultsTbl <- as_tibble(resultsTbl, rownames = "gene")
      # output table
      write.table(resultsTbl, file, sep=",", row.names=FALSE, quote=FALSE)
    }
  )
  
  # TO-DO: note LFC cut off filter
  # https://www.ncbi.nlm.nih.gov/pmc/articles/PMC2654802/#:~:text=Results%3A%20We%20present%20a%20method,given%20(biologically%20meaningful)%20threshold.
  # download table with number of filtered DE genes
  output$pairwiseSigResults <- downloadHandler(
    filename = function() {
      # setup output file name
      paste(input$levelTwo, input$levelOne, "pairwiseSigDE_genes.csv", sep = "_")
    },
    content = function(file) {
      # perform exact test
      tested <- pairwiseTest()
      # create a results table of DE genes by FDR
      resultsTbl <- topTags(tested, n=nrow(tested$table), adjust.method="fdr", p.value=valueFDR())$table
      # identify significantly DE genes by LFC cut offs
      DGESubset <- resultsTbl[resultsTbl$logFC > valueLFC() | resultsTbl$logFC < (-1*valueLFC()),]
      # add gene row name tag
      resultsTbl.out <- as_tibble(DGESubset, rownames = "gene")
      # output table
      write.table(resultsTbl.out, file, sep=",", row.names=FALSE, quote=FALSE)
    }
  )
  
  # function to retrieve gene IDs from results tables
  retrievePairwiseGeneIDs <- function(){
    # perform exact test
    tested <- pairwiseTest()
    # view results table of top 10 DE genes
    resultsTbl <- topTags(tested, n=nrow(tested$table), adjust.method="fdr")$table
    # retrieve gene IDS
    resultsTblNames <- rownames(resultsTbl)
    # add commas
    resultsTblNames <- paste(resultsTblNames, ",", sep="")
    # retrieve last entry
    lastEntry <- resultsTblNames[length(resultsTblNames)]
    # remove extra trailing comma
    resultsTblNames[length(resultsTblNames)] <- gsub(",", "\n", lastEntry)
    # return list of gene IDs
    resultsTblNames
  }
  
  # function to retrieve gene IDs from results tables
  retrievePairwiseSigGeneIDs <- function(){
    # perform exact test
    tested <- pairwiseTest()
    # create a results table of DE genes by FDR
    resultsTbl <- topTags(tested, n=nrow(tested$table), adjust.method="fdr", p.value=valueFDR())$table
    # identify significantly DE genes by LFC cut offs
    DGESubset <- resultsTbl[resultsTbl$logFC > valueLFC() | resultsTbl$logFC < (-1*valueLFC()),]
    # retrieve gene IDS
    resultsTblNames <- rownames(DGESubset)
    # add commas
    resultsTblNames <- paste(resultsTblNames, ",", sep="")
    # retrieve last entry
    lastEntry <- resultsTblNames[length(resultsTblNames)]
    # remove extra trailing comma
    resultsTblNames[length(resultsTblNames)] <- gsub(",", "\n", lastEntry)
    # return list of gene IDs
    resultsTblNames
  }
  
  # download table with number of DE genes IDs
  output$pairwiseResultsIDs <- downloadHandler(
    filename = function() {
      # setup output file name
      paste(input$levelTwo, input$levelOne, "pairwiseDE_geneIDs.csv", sep = "_")
    },
    content = function(file) {
      # add commas
      resultsTblNames <- retrievePairwiseGeneIDs()
      # output table
      writeLines(resultsTblNames, con = file, sep = "")
    }
  )
  
  # download table with number of filtered DE genes IDs
  output$pairwiseSigResultsIDs <- downloadHandler(
    filename = function() {
      # setup output file name
      paste(input$levelTwo, input$levelOne, "pairwiseSigDE_geneIDs.csv", sep = "_")
    },
    content = function(file) {
      # add commas
      resultsTblNames <- retrievePairwiseSigGeneIDs()
      # output table
      writeLines(resultsTblNames, con = file, sep = "")
    }
  )
  
  ##
  # GLM Fitting
  ##
  
  # function to create the glm design
  glmDesign <- function(){
    # require valid inputs
    if(is.null(compareSamples())){
      return(NULL)
    }
    # retrieve input design table
    group <- designFactors()
    # parametrize the experimental design with a one-way layout 
    design <- model.matrix(~ 0 + group)
    # add group names
    colnames(design) <- levels(group)
    # return design layout
    design
  }
  
  # function for fitting the glm
  glmFitting <- function(){
    # calculate scaling factors
    list <- filterNorm()
    # retrieve the experimental design 
    design <- glmDesign()
    # estimate common dispersion and tagwise dispersions to produce a matrix of pseudo-counts
    list <- estimateDisp(list, design, robust=TRUE)
    # estimate the QL dispersions
    glmQLFit(list, design, robust=TRUE)
  }
  
  # plot of QL dispersions
  createGLMDispersions <- function(){
    # retrieve the fitted glm
    fit <- glmFitting()
    # return the plot
    plotQLDisp(fit)
  }
  
  # render plot of QL dispersions
  output$glmDispersions <- renderImage({
    # save the plot
    exportFile <- "glmDispersionsPlot.png"
    png(exportFile)
    createGLMDispersions()
    dev.off()
    # Return a list
    list(src = exportFile, alt = "Invalid Results")
  }, deleteFile = TRUE)
  
  # download handler for the GLM dispersions plot
  output$downloadGLMDispersions <- downloadHandler(
    filename = function() {
      "glmDispersionsPlot.png"
    },
    content = function(file) {
      # save the plot
      png(file)
      createGLMDispersions()
      dev.off()
    }
  )
  
  ##
  # GLM Contrasts
  ##
  
  # render text with glm comparison
  output$glmComparison <- renderText({
    # require the expression
    req(input$compareExpression)
    # return the expression
    input$compareExpression
  })
  
  # function to perform glm contrasts
  glmContrast <- eventReactive(list(input$inputsUpdate, input$glmUpdate), {
    # require the expression
    req(input$compareExpression)
    # set the input expression as global
    inputExpression <<- input$compareExpression
    # retrieve the fitted glm
    fit <- glmFitting()
    # retrieve the experimental design 
    design <- glmDesign()
    # examine the overall effect of treatment
    glmContrast <- makeContrasts(glmSet = inputExpression,
                                 levels=design)
    # look at genes with significant expression across all UV groups
    glmTreat(fit, contrast=glmContrast, lfc=valueLFC())
  })
  
  # check if results have completed
  output$glmResultsCompleted <- function(){
    if(is.null(glmContrast())){
      return(FALSE)
    }
    return(TRUE)
  }
  outputOptions(output, 'glmResultsCompleted', suspendWhenHidden=FALSE, priority=0)
  
  # render table with the summary of results
  output$glmSummary <- renderTable({
    # perform glm test
    tested <- glmContrast()
    # view the total number of differentially expressed genes at a FDR and LFC cut off
    DGEgenes = decideTests(tested,p.value=valueFDR(), lfc=valueLFC())
    resultsSummary <- summary(DGEgenes)
    # create the results summary
    resultsTable <- data.frame(
      Direction = c("Down", "NotSig", "Up"),
      Number = resultsSummary[,1]
    )
    # return the formatted results summary
    resultsTable
  })
  
  # pheatmap of glm DGE 
  createGLMPheatmapDGE <- function(){
    # perform exact test
    tested <- glmContrast()
    # retrieve input design
    targets <- inputDesign()
    # calculate scaling factors
    list <- filterNorm()
    # create a results table of DE genes by FDR and LFC
    resultsTbl <- topTags(tested, n=nrow(tested$table), adjust.method="fdr", p.value=valueFDR())$table
    # calculate the log2 CPM of the gene count data
    logcpm <- cpm(list, log=TRUE)
    # subset the log2 CPM by the DGE set
    #logcpmSubset <- subset(logcpm,
    #                       grepl(
    #                         paste0(rownames(DGESubset), collapse = "|"),
    #                         rownames(logcpm),
    #                         ignore.case = TRUE
    #                       )
    #)
    DGESubset.keep <- rownames(logcpm) %in% rownames(DGESubset)
    logcpmSubset <- logcpm[DGESubset.keep, ]
    # combine all columns into one period separated
    exp_factor <- data.frame(Sample = unlist(targets, use.names = FALSE))
    rownames(exp_factor) <- colnames(logcpmSubset)
    # TO-DO: use color blind safe pallette for sample dendrogram
    #Create heatmap for DGE
    as.ggplot(
      pheatmap(logcpmSubset, scale="row", annotation_col = exp_factor, 
               main="Heatmap of GLM DE Genes", show_rownames = FALSE,
               color = colorRampPalette(c(plotColors[5], "white", plotColors[6]))(100))
    )
  }
  
  # render pheatmap of GLM DGE
  output$pheatmapGLM <- renderImage({
    # save image
    exportFile <- "heatmapPlotGLM.png"
    # create the plot
    pheatmapPlot <- createGLMPheatmapDGE()
    # save the plot
    ggsave(exportFile, plot = pheatmapPlot, bg = "white", device = "png")
    # Return a list
    list(src = exportFile, alt = "Invalid Results", height = "500px")
  }, deleteFile = TRUE)
  
  # download handler for the GLM heatmap plot
  output$downloadPheatmapGLM <- downloadHandler(
    filename = function() {
      "heatmapPlotGLM.png"
    },
    content = function(file) {
      # create the plot
      pheatmapPlot <- createGLMPheatmapDGE()
      # save the plot
      ggsave(file, plot = pheatmapPlot, bg = "white", device = "png")
    }
  )
  
  # plot of log2-fold change against log2-counts per million with DE genes highlighted
  createGLMMD <- function(){
    # perform exact test
    tested <- glmContrast()
    # return MD plot
    plotMD(tested, main = "Mean-Differences of GLM DE Genes", adjust.method="fdr", p.value=valueFDR())
    # add blue lines to indicate 2-fold changes
    abline(h=c((-1*valueLFC()), valueLFC()), col="blue") 
  }
  
  # render plot of log2-fold change against log2-counts per million with DE genes highlighted
  output$glmMD <- renderImage({
    # save the plot
    exportFile <- "glmMDPlot.png"
    png(exportFile)
    createGLMMD()
    dev.off()
    # Return a list
    list(src = exportFile, alt = "Invalid Results")
  }, deleteFile = TRUE)
  
  # download handler for the GLM MD plot
  output$downloadGLMMD <- downloadHandler(
    filename = function() {
      "glmMDPlot.png"
    },
    content = function(file) {
      # save the plot
      png(file)
      createGLMMD()
      dev.off()
    }
  )
  
  # create volcano plot
  plotGLMVolcano <- function(){
    # perform exact test
    tested <- glmContrast()
    # create a results table of DE genes
    resultsTbl <- topTags(tested, n=nrow(tested$table), adjust.method="fdr")$table
    # add column for identifying direction of DE gene expression
    resultsTbl$colorDE <- plotColors[5]
    resultsTbl$alphaDE <- 0.75
    # identify significantly up DE genes
    resultsTbl$colorDE[resultsTbl$logFC > valueLFC() & resultsTbl$FDR < valueFDR()] <- plotColors[4]
    resultsTbl$alphaDE[resultsTbl$logFC > valueLFC() & resultsTbl$FDR < valueFDR()] <- 1
    #resultsTbl$colorDE[sign(resultsTbl$logFC) == 1 & resultsTbl$FDR < valueFDR()] <- "Up"
    # identify significantly down DE genes
    resultsTbl$colorDE[resultsTbl$logFC < (-1*valueLFC()) & resultsTbl$FDR < valueFDR()] <- plotColors[6]
    resultsTbl$alphaDE[resultsTbl$logFC < (-1*valueLFC()) & resultsTbl$FDR < valueFDR()] <- 1
    #resultsTbl$colorDE[sign(resultsTbl$logFC) == -1 & resultsTbl$FDR < valueFDR()] <- "Down"
    # add column with -log10(FDR) values
    resultsTbl$negLog10FDR <- -log10(resultsTbl$FDR)
    # create volcano plot
    ggplot(data=resultsTbl, aes(x=logFC, y=negLog10FDR, color = colorDE, alpha = alphaDE)) + 
      geom_point() +
      theme_minimal() +
      scale_color_identity() +
      scale_alpha(guide = 'none') +
      ggtitle("Volcano Plot of GLM DE Genes") +
      theme(plot.title = element_text(hjust = 0.5)) +
      theme(plot.title = element_text(face="bold")) +
      xlab("LFC")
  }
  
  # render GLM volcano plot
  output$glmVolcano <- renderPlot({
    # create plot
    plotGLMVolcano()
  })
  
  # download handler for the volcano plot
  output$downloadGLMVolcano <- downloadHandler(
    filename = function() {
      "glmVolcanoPlot.png"
    },
    content = function(file) {
      # create plot
      volcanoPlotGLM <- plotGLMVolcano()
      # save plot
      ggsave(file, plot = volcanoPlotGLM, device = "png")
    }
  )
  
  # download table with number of filtered genes
  output$glmResults <- downloadHandler(
    filename = function() {
      # setup output file name
      paste(input$compareExpression, "glmDE_genes.csv", sep = "_")
    },
    content = function(file) {
      # perform glm test
      tested <- glmContrast()
      # view results table of DE genes
      resultsTbl <- topTags(tested, n=nrow(tested$table), adjust.method="fdr")$table
      # add gene row name tag
      resultsTbl <- as_tibble(resultsTbl, rownames = "gene")
      # output table
      write.table(resultsTbl, file, sep=",", row.names=FALSE, quote=FALSE)
    }
  )
  
  # download table with number of filtered genes
  output$glmSigResults <- downloadHandler(
    filename = function() {
      # setup output file name
      paste(input$compareExpression, "glmSigDE_genes.csv", sep = "_")
    },
    content = function(file) {
      # perform glm test
      tested <- glmContrast()
      # create a results table of DE genes by FDR and LFC
      resultsTbl <- topTags(tested, n=nrow(tested$table), adjust.method="fdr", p.value=valueFDR())$table
      # add gene row name tag
      resultsTbl.out <- as_tibble(resultsTbl, rownames = "gene")
      # output table
      write.table(resultsTbl.out, file, sep=",", row.names=FALSE, quote=FALSE)
    }
  )
  
  # function to retrieve gene IDs from results tables
  retrieveGLMGeneIDs <- function(){
    # perform exact test
    tested <- glmContrast()
    # view results table of top 10 DE genes
    resultsTbl <- topTags(tested, n=nrow(tested$table), adjust.method="fdr")$table
    # retrieve gene IDS
    resultsTblNames <- rownames(resultsTbl)
    # add commas
    resultsTblNames <- paste(resultsTblNames, ",", sep="")
    # retrieve last entry
    lastEntry <- resultsTblNames[length(resultsTblNames)]
    # remove extra trailing comma
    resultsTblNames[length(resultsTblNames)] <- gsub(",", "\n", lastEntry)
    # return list of gene IDs
    resultsTblNames
  }
  
  # function to retrieve gene IDs from results tables
  retrieveGLMSigGeneIDs <- function(){
    # perform exact test
    tested <- glmContrast()
    # create a results table of DE genes by FDR and LFC
    resultsTbl <- topTags(tested, n=nrow(tested$table), adjust.method="fdr", p.value=valueFDR())$table
    # retrieve gene IDS
    resultsTblNames <- rownames(DGESubset)
    # add commas
    resultsTblNames <- paste(resultsTblNames, ",", sep="")
    # retrieve last entry
    lastEntry <- resultsTblNames[length(resultsTblNames)]
    # remove extra trailing comma
    resultsTblNames[length(resultsTblNames)] <- gsub(",", "\n", lastEntry)
    # return list of gene IDs
    resultsTblNames
  }
  
  # download table with number of DE genes IDs
  output$glmResultsIDs <- downloadHandler(
    filename = function() {
      # setup output file name
      paste(input$compareExpression, "glmcolorGs_geneIDs.csv", sep = "_")
    },
    content = function(file) {
      # retrieve gene IDS
      resultsTblNames <- retrieveGLMGeneIDs()
      # output table
      writeLines(resultsTblNames, con = file, sep = "")
    }
  )
  
  # download table with number of filtered DE genes IDs
  output$glmSigResultsIDs <- downloadHandler(
    filename = function() {
      # setup output file name
      paste(input$compareExpression, "glmSigDE_geneIDs.csv", sep = "_")
    },
    content = function(file) {
      # retrieve gene IDS
      resultsTblNames <- retrieveGLMSigGeneIDs()
      # output table
      writeLines(resultsTblNames, con = file, sep = "")
    }
  )
}

#### App Object ####

# create the Shiny app object 
shinyApp(ui = ui, server = server)
