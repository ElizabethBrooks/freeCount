# developer: Elizabeth Brooks
# updated: 17 November 2025

#### Setup ####

# increase max uploadable file size to from the default 5MB to 30MB
options(shiny.maxRequestSize=30*1024^2)

# install any missing packages
packageList <- c("BiocManager", "shiny", "bslib", "shinyWidgets", "ggplot2", 
                 "rcartocolor", "dplyr", "statmod", "pheatmap", "ggplotify",
                 "rmarkdown")
biocList <- c("apeglm", "DESeq2")
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
  library(bslib)
  library(shinyWidgets)
  library(ggplot2)
  library(rcartocolor)
  library(edgeR)
  library(dplyr)
  library(pheatmap)
  library(ggplotify)
})

# color blind safe plotting palettes
plotColors <- carto_pal(12, "Safe")

# create a list of continuous colors
colors <- colorRampPalette( rev(brewer.pal(9, "Blues")) )(255)

# prepare styles for css
#font-family: Arial, sans-serif !important;
css_styles <- "
* {
  font-family: Arial, sans-serif;
  color: #5A5A5A;
}
#app-heading {
  background: linear-gradient(to right, #78c2ad, #f3969a);
  border-radius: 25px;
  border-color: #F5E7C9;
  border-width: 8px;
  border-style: solid;
}
.tabbable > .nav > li > a {
  background-color: #f3969a;  
  color: white; 
  border-color: white;
  border-width: 2px;
}
.nav-tabs .nav-link.active,.nav-tabs>li>a.active,.nav-tabs .nav-pills>li>a.active,.nav-tabs :where(ul.nav.navbar-nav > li)>a.active,.nav-tabs .nav-item.show .nav-link,.nav-tabs .nav-item.in .nav-link,.nav-tabs .nav-item.show .nav-tabs>li>a,.nav-tabs .nav-item.in .nav-tabs>li>a,.nav-tabs .nav-item.show .nav-pills>li>a,.nav-tabs .nav-item.in .nav-pills>li>a,.nav-tabs>li.show .nav-link,.nav-tabs>li.in .nav-link,.nav-tabs>li.show .nav-tabs>li>a,.nav-tabs>li.in .nav-tabs>li>a,.nav-tabs>li.show .nav-pills>li>a,.nav-tabs>li.in .nav-pills>li>a,.nav-tabs .nav-pills>li.show .nav-link,.nav-tabs .nav-pills>li.in .nav-link,.nav-tabs .nav-pills>li.show .nav-tabs>li>a,.nav-tabs .nav-pills>li.in .nav-tabs>li>a,.nav-tabs .nav-pills>li.show .nav-pills>li>a,.nav-tabs .nav-pills>li.in .nav-pills>li>a,.nav-tabs .nav-item.show :where(ul.nav.navbar-nav > li)>a,.nav-tabs .nav-item.in :where(ul.nav.navbar-nav > li)>a,.nav-tabs>li.show :where(ul.nav.navbar-nav > li)>a,.nav-tabs>li.in :where(ul.nav.navbar-nav > li)>a,.nav-tabs .nav-pills>li.show :where(ul.nav.navbar-nav > li)>a,.nav-tabs .nav-pills>li.in :where(ul.nav.navbar-nav > li)>a,.nav-tabs .show:where(ul.nav.navbar-nav > li):not(.dropdown) .nav-link,.nav-tabs .in:where(ul.nav.navbar-nav > li):not(.dropdown) .nav-link,.nav-tabs .show:where(ul.nav.navbar-nav > li):not(.dropdown) .nav-tabs>li>a,.nav-tabs .in:where(ul.nav.navbar-nav > li):not(.dropdown) .nav-tabs>li>a,.nav-tabs .show:where(ul.nav.navbar-nav > li):not(.dropdown) .nav-pills>li>a,.nav-tabs .in:where(ul.nav.navbar-nav > li):not(.dropdown) .nav-pills>li>a,.nav-tabs .show:where(ul.nav.navbar-nav > li):not(.dropdown) :where(ul.nav.navbar-nav > li)>a,.nav-tabs .in:where(ul.nav.navbar-nav > li):not(.dropdown) :where(ul.nav.navbar-nav > li)>a {
  color: white;
  background-color: #5A5A5A;
  border-color: #78c2ad;
  border-width: 2px;
}
.tab-pane.active {
  background-color: white;
  border-color: white;
  border-width: 10px;
  border-style: solid;
  border-top-right-radius: 25px;
  border-bottom-right-radius: 25px;
  border-bottom-left-radius: 25px;
}
"

# set default values
defaultLFC <- 1.2
defaultFDR <- 0.05
defaultDes <- "NA"
defaultExp <- "NA"

#### UI ####

# Define UI 
ui <- fluidPage(
  # set background color
  setBackgroundColor("#FFF4DD"),
  
  # use a theme
  theme = bs_theme(bootswatch = "minty"),
  
  # apply css styles
  tags$style(
    HTML(css_styles)
  ),
  
  # add application title
  h1(id="app-heading", 
     tags$p(
       "freeCount DA",
       style = "
          margin-top: 14px;
          margin-left: 25px; 
          font-family: Georgia, Arial, sans-serif;
          color: white
        "
     )
  ),
  
  # setup sidebar layout
  sidebarLayout(
    
    # setup sidebar panel
    sidebarPanel(
      # setup the style
      style = "
          background-color: white;
          border-color: #F5E7C9; 
          border-width: 10px; 
          border-style: solid;
          border-radius: 25px
      ",
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
          "Current Analysis Settings:"
        ), 
        tableOutput(outputId = "inputSettings"),
        tags$hr(),
        tags$p(
          "Click to Download Analysis Report:"
        ),
        downloadButton("report", "Download Report")
      )
    ),
    
    # Output: Show plots
    mainPanel(
      
      # getting started text
      conditionalPanel(
        condition = "!input.runAnalysis",
        # set the background style
        style = "
          background-color: white; 
          border-color: white; 
          border-width: 10px; 
          border-style: solid;
          border-radius: 25px
        ",
        # header
        tags$h1(
          "Getting Started", 
          align = "center",
          style = "
            color: white; 
            background: #78c2ad;
            font-size: xx-large;
            font-family: Georgia, Arial, sans-serif;
            border-color: #78c2ad;
            border-width: 4px;
            border-style: solid;
            border-radius: 25px
          "
        ),
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
        tags$p(
          HTML("<b>Tip 6:</b> Lines containing HTSeq stats (no_feature, ambiguous, too_low_aQual, not_aligned, alignment_not_unique) are automatically removed from the input counts table.")
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
        # set the background style
        style = "
          background-color: white; 
          border-color: white; 
          border-width: 10px; 
          border-style: solid;
          border-radius: 25px
        ",
        # header
        tags$h1(
          "Processing", 
          align = "center",
          style = "
            color: white; 
            background: #78c2ad;
            font-size: xx-large;
            font-family: Georgia, Arial, sans-serif;
            border-color: #78c2ad;
            border-width: 4px;
            border-style: solid;
            border-radius: 25px
          "
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
            tags$h1(
              align="center",
              "Helpful Tips",
              style = "
                color: white; 
                background: #78c2ad;
                font-size: x-large;
                font-family: Georgia, Arial, sans-serif;
                border-color: #78c2ad;
                border-width: 4px;
                border-style: solid;
                border-radius: 25px;
              "
            ),
            tags$br(),
            tags$p(
              HTML("<b>Tip 1:</b> The plots and results may take several moments to appear depending on the size of the input gene counts table.")
            ),
            tags$p(
              HTML("<b>Tip 2:</b> Navigate to the <i>Analysis</i>, <i>Data Normalization</i>, <i>Data Exploration</i>, or <i>Results</i> steps by clicking the tabs above.")
            ),
            tags$p(
              HTML("<b>Tip 3:</b> Further information about choosing dispersion values and methods for obtaining dispersions may be found in the "),
              tags$a("edgeR manual", href = "https://www.bioconductor.org/packages/release/bioc/vignettes/edgeR/inst/doc/edgeRUsersGuide.pdf"),
              " (e.g., section 2.12)."
            ),
            tags$p(
              HTML("<b>Tip 4:</b> Examples of designing model expressions for ANOVA-like tests are availble in the"),
              tags$a("edgeR manual", href = "https://www.bioconductor.org/packages/release/bioc/vignettes/edgeR/inst/doc/edgeRUsersGuide.pdf"),
              " (e.g., sections 3.2.6 & 4.4.9)."
            ),
            tags$p(
              HTML("<b>Tip 5:</b> If the normalizaion plot or other results look strange, make sure that the input table contains raw gene counts that have not been normalized.")
            )
          ),
          
          # Analysis tab
          tabPanel(
            "Analysis",
            tags$h1(
              align="center",
              "DE Analysis",
              style = "
                color: white; 
                background: #78c2ad;
                font-size: x-large;
                font-family: Georgia, Arial, sans-serif;
                border-color: #78c2ad;
                border-width: 4px;
                border-style: solid;
                border-radius: 25px;
              "
            ),
            tags$p(
              "Begin the differential expression (DE) analysis by selecting an analysis type, log2-fold change (LFC) cut off, and false discovery rate (FDR) adjusted p-value cut off."
            ),
            tags$br(),
            fluidRow(
              column(
                width = 6,
                tags$p(
                  HTML("<b>Select LFC Cut Off:</b>")
                ),
                sliderInput(
                  "cutLFC", 
                  label=NULL,
                  min=0, 
                  max=10, 
                  step=0.1,
                  value=defaultLFC
                ),
                tags$p(
                  HTML("<b>Select FDR Adjusted p-Value Cut Off:</b>")
                ),
                sliderInput(
                  "cutFDR",
                  label=NULL,
                  min = 0, 
                  max = 0.1, 
                  value=defaultFDR 
                )
              ),
              column(
                width = 6,
                tags$p(
                  HTML("<b>Select Analysis Type:</b>")
                ),
                selectInput(
                  inputId = "analysisType",
                  label = NULL,
                  choices = list("pairwise", "GLM")
                )
              )
            ),
            tags$br(),
            # show pairwise analysis inputs
            conditionalPanel(
              condition = "input.analysisType == 'pairwise'",
              tags$h1(
                align="center",
                "Pairwise Comparison",
                style = "
                color: white; 
                background: #78c2ad;
                font-size: x-large;
                font-family: Georgia, Arial, sans-serif;
                border-color: #78c2ad;
                border-width: 4px;
                border-style: solid;
                border-radius: 25px;
              "
              ),
              tags$h4(
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
                    HTML("<b>Enter Dispersion Value:</b>")
                  ),
                  textInput(
                    inputId = "inputPairwiseDisp", 
                    label = NULL,
                    value = defaultPairwiseDisp
                  )
                )
              ),
              tags$p(
                "The dispersion value may be either a character string or a numeric value.",
                "The character string is used to indicate that dispersions should be taken from the data.",
                #"The dispersion value may be either a character string indicating that dispersions should be taken from the data or a numeric vector of dispersions.",
                HTML("Allowable character values are <i>common</i>, <i>trended</i>, <i>tagwise</i> or <i>auto</i>."),
                "If the input is numeric, then it can be a common value for all genes."
                #"If the input is numeric, then it can be either of length one or of length equal to the number of genes."
              ),
              tags$p(
                HTML("<b>Note</b> that the default dispersion value is <i>auto</i>, which uses the most complex dispersions found in the data."),
              )
            ),
            # show GLM analysis inputs
            conditionalPanel(
              condition = "input.analysisType == 'GLM'",
              tags$h1(
                align="center",
                "GLM Comparison",
                style = "
                color: white; 
                background: #78c2ad;
                font-size: x-large;
                font-family: Georgia, Arial, sans-serif;
                border-color: #78c2ad;
                border-width: 4px;
                border-style: solid;
                border-radius: 25px;
              "
              ),
              tags$h4(
                textOutput(outputId = "deComparison"), 
                align="center"
              ),
              tags$br(),
              tags$p(
                "The GLM is used to perform an ANOVA-like analysis to identify any significant main effect associated with an explanatory variable.",
                "An explanatory variable may be a categorical factor with two or more levels, such as treat and cntrl."
              ),
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
                  # To-Do: make text input area larger
                  textInput(
                    "compareExpression", 
                    label = NULL
                  )
                )
              ),
              tags$br(),
              tags$p(
                HTML("<b>Tip!</b> Make sure that the factors used in the expression are spelled the same as in the experimental design file (shown below)")
              ),
              #tags$p(
              #  "Valid expressions must consist of the factors contained in the input experimental design file, which is displayed below"
              #),
              tags$p(
                "Examples of designing model expressions for ANOVA-like tests are availble in the",
                tags$a("edgeR manual", href = "https://www.bioconductor.org/packages/release/bioc/vignettes/edgeR/inst/doc/edgeRUsersGuide.pdf"),
                " (e.g., sections 3.2.6 & 4.4.9).",
                HTML("A detailed description of designing model expressions is also provided in the paper \"A guide to creating design matrices for gene expression experiments\" <i>doi: 10.12688/f1000research.27893.1</i> (e.g., studies with multiple factors).")
              ),
              tags$p(
                "The dispersion value may be either a NULL or numeric scalar.", 
                #"The dispersion value may be either a NULL, numeric scalar, vector or matrix of negative binomial dispersions.", 
                "If the input is NULL, then the dispersions will be extracted from the data.",
                "The order of precedence is genewise dispersion, trended dispersions, common dispersion.",
                "If the input is numeric, then the dispersion value can be a common value for all genes."
                #"If the input is numeric, then the dispersion value can be a common value for all genes, a vector of dispersion values with one for each gene, or a matrix of dispersion values with one for each observation."
              ),
              tags$p(
                HTML("<b>Note</b> that the default dispersion value is <i>NULL</i>.")
              )
            ),
            tags$p(
              "Examples of typical dispersion values and methods for obtaining dispersions may be found in the ",
              tags$a("edgeR manual", href = "https://www.bioconductor.org/packages/release/bioc/vignettes/edgeR/inst/doc/edgeRUsersGuide.pdf"),
              " (e.g., section 2.12).",
              "For example, the common BCV (square-root dispersion) values typically are 0.4 for human data, 0.1 for data on genetically identical model organisms or 0.01 for technical replicates.",
              "Furthermore, the dispersion may be estimated from the data given a sizeable number of control transcripts that should not be DE."
            ),
            tags$p(
              HTML("<b>Click to Analyze:</b>")
            ),  
            actionButton("analysisUpdate", "Analyze"),
            tags$hr(),
            tags$p(
            "Design Table:"
            ),
            fluidRow(
            align = "center",
            # display input design table
            tableOutput(outputId = "designTable")
            )
          ),
          
          # data normalization tab
          tabPanel(
            "Data Normalization",
            tags$h1(
              align="center",
              "Data Normalization",
              style = "
                color: white; 
                background: #78c2ad;
                font-size: x-large;
                font-family: Georgia, Arial, sans-serif;
                border-color: #78c2ad;
                border-width: 4px;
                border-style: solid;
                border-radius: 25px;
              "
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
            tags$h1(
              align="center",
              "Data Exploration",
              style = "
                color: white; 
                background: #78c2ad;
                font-size: x-large;
                font-family: Georgia, Arial, sans-serif;
                border-color: #78c2ad;
                border-width: 4px;
                border-style: solid;
                border-radius: 25px;
              "
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
            "Results", 
            tags$h1(
              align="center",
              "DE Analysis Results",
              style = "
                color: white; 
                background: #78c2ad;
                font-size: x-large;
                font-family: Georgia, Arial, sans-serif;
                border-color: #78c2ad;
                border-width: 4px;
                border-style: solid;
                border-radius: 25px;
              "
            ),
            tags$p(
              HTML("Begin the differential expression (DE) analysis on the <i>Analysis</i> tab by selecting input values and clicking the <i>Analyze</i> button.")
            ),
            tags$p(
              HTML("The inputs may also be adjusted on the <i>Analysis</i> tab and updated by clicking the <i>Analyze</i> button.")
            ),
            # show pairwise results
            conditionalPanel(
              condition = "input.analysisType == 'pairwise' && input.analysisUpdate",
              tags$h1(
                align="center",
                "Pairwise Comparison",
                style = "
                color: white; 
                background: #78c2ad;
                font-size: x-large;
                font-family: Georgia, Arial, sans-serif;
                border-color: #78c2ad;
                border-width: 4px;
                border-style: solid;
                border-radius: 25px;
              "
              ),
              # show error message
              conditionalPanel(
                condition = "!output.pairwiseResultsCompleted",
                tags$p(
                  HTML("<b>Note</b> that results will not appear if there are invalid input values (e.g., dispersions).")
                )
              ),
              # show pairwise results
              conditionalPanel(
                condition = "output.pairwiseResultsCompleted",
                tags$p(
                  align="center",
                  HTML("<b>Pairwise Results</b>")
                ),
                tags$br(),
                imageOutput(outputId = "pairwiseMD", height="100%", width="100%"),
                downloadButton(outputId = "downloadPairwiseMD", label = "Download Plot"),
                tags$p(
                  "The mean-difference (MD) plot shows the log2 fold changes (LFCs) in expression differences versus average log2 CPM values.",
                  "Red points are significantly up-expressed genes and the blue points are significantly down-expressed, where signifigance was determined by the input FDR cut off.",
                  "The blue lines indicate the input LFC cut off, which will be used to further filter the set of significantly DE genes."
                ),
                tags$p(
                  HTML("<b>Number of Significantly DE Genes:</b>")
                ),
                tableOutput(outputId = "pairwiseSummary"),
                tags$p(
                  "The above table shows the number of significantly DE genes that were up- or down-expressed in the input comparison. Signifigance was determined by the input LFC and FDR cut offs."
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
                      HTML("<b>Significant DE Analysis Results Table:</b>")
                    ),
                    downloadButton(outputId = "pairwiseSigResults", label = "Download Table"),
                    tags$p(
                      "A table of significant pairwise DE analysis results sorted by increasing FDR adjusted p-values may be downloaded by clicking the above button.",
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
              condition = "input.analysisType == 'GLM' && input.analysisUpdate",
              tags$h1(
                align="center",
                "GLM Comparison",
                style = "
                color: white; 
                background: #78c2ad;
                font-size: x-large;
                font-family: Georgia, Arial, sans-serif;
                border-color: #78c2ad;
                border-width: 4px;
                border-style: solid;
                border-radius: 25px;
              "
              ),
              # show error message
              conditionalPanel(
                condition = "!output.glmResultsCompleted",
                tags$p(
                  HTML("<b>Note</b> that results will not appear if there are invalid input values (e.g., dispersions).")
                )
              ),
              # show glm results
              conditionalPanel(
                condition = "output.glmResultsCompleted",
                tags$p(
                  align="center",
                  HTML("<b>GLM Results</b>")
                ),
                tags$br(),
                imageOutput(outputId = "glmMD", height="100%", width="100%"),
                downloadButton(outputId = "downloadGLMMD", label = "Download Plot"),
                tags$p(
                  "The mean-difference (MD) plot shows the log2 fold changes (LFCs) in expression differences versus average log2 CPM values.",
                  "Red points are significantly up-expressed genes and the blue points are significantly down-expressed, where signifigance was determined by the input FDR cut off.",
                  "The blue lines indicate the input LFC cut off, which will be used to further filter the set of significantly DE genes."
                ),
                tags$p(
                  HTML("<b>Number of Significantly DE Genes:</b>")
                ),
                tableOutput(outputId = "glmSummary"),
                tags$p(
                  "The above table shows the number of significantly DE genes that were up- or down-expressed in the input comparison. Signifigance was determined by the input LFC and FDR cut offs."
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
                      HTML("<b>Significant DE Analysis Results Table:</b>")
                    ),
                    downloadButton(outputId = "glmSigResults", label = "Download Table"),
                    tags$p(
                      "A table of significant GLM DE analysis results sorted by increasing FDR adjusted p-values may be downloaded by clicking the above button.",
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
            tags$h1(
              align="center",
              "Helpful Information",
              style = "
                color: white; 
                background: #78c2ad;
                font-size: x-large;
                font-family: Georgia, Arial, sans-serif;
                border-color: #78c2ad;
                border-width: 4px;
                border-style: solid;
                border-radius: 25px;
              "
            ),
            tags$p(
              "A tutorial for this application can be found ",
              tags$a("here",href = "https://github.com/ElizabethBrooks/DGEAnalysis_ShinyApps/blob/main/tutorials/tutorial_app_DEAnalysis.md"),
              " in the scripts directory of the freeCount GitHub."
            ),
            tags$p(
              "The latest version of this application may be downloaded from the freeCount ",
              tags$a("GitHub",href = "https://github.com/ElizabethBrooks/freeCount"),
              "."
            ),
            tags$p(
              "Example gene counts and experimental design tables are also provided on ",
              tags$a("GitHub", href = "https://github.com/ElizabethBrooks/freeCount/tree/main/data/edgeR"),
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
            tags$h1(
              align="center",
              "Cite",
              style = "
                color: white; 
                background: #78c2ad;
                font-size: x-large;
                font-family: Georgia, Arial, sans-serif;
                border-color: #78c2ad;
                border-width: 4px;
                border-style: solid;
                border-radius: 25px;
              "
            ),
            tags$p("Elizabeth Mae Brooks, Sheri A Sanders, and Michael E Pfrender. 2024. FreeCount: A Coding Free Framework for Guided Count Data Visualization and Analysis. 
                   In Practice and Experience in Advanced Research Computing 2024: Human Powered Computing (PEARC '24). 
                   Association for Computing Machinery, New York, NY, USA, Article 37, 1–4. https://doi.org/10.1145/3626203.3670605")
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
    design <- read.csv(input$expDesignTable$datapath, row.names=1)
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
    # convert the grouping data into factors
    colData <- as.data.frame(lapply(targets, as.factor))
    rownames(colData) <- rownames(targets)
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
  
  # setup reactive LFC value
  valueLFC <- reactiveVal(defaultLFC)
  
  # update LFC value
  observeEvent(input$analysisUpdate, {
    valueLFC(input$cutLFC)
  })
  
  # setup reactive FDR value
  valueFDR <- reactiveVal(defaultFDR)
  
  # update FDR value
  observeEvent(input$analysisUpdate, {
    valueFDR(input$cutFDR)
  })
  
  # setup reactive design value
  valueDes <- reactiveVal(defaultDes)
  
  # setup reactive expression value
  valueExp <- reactiveVal(defaultExp)
  
  # update expression and design values
  observeEvent(input$analysisUpdate, {
    valueDes(input$designExpression)
    valueExp(input$compareExpression)
  })
  
  # update inputs for comparisons
  observeEvent(input$runAnalysis, {
    # retrieve input design table
    group <- levels(designFactors())
    # update reactive expression value with a temporary pairwise expression
    valueExp(colnames(group)[1])
    # create temporary GLM expression
    tmpExpression <- paste(colnames(group)[1])
    # update and set the glm comparison expression
    updateTextInput(
      session,
      "compareExpression",
      value = tmpExpression
    )
  })
  
  # render table with input settings
  output$inputSettings <- renderTable({
    # create table with factor levels
    settings <- data.frame(
      Setting = c("Analysis", "LFC", "FDR", "Comparison"),
      Value = c(valueAnalysis(), valueLFC(), valueFDR(), valueExp())
    )
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
  
  # function to create the DE list object
  dataSetFromMatrix <- function(){
    # retrieve input counts, design, and expression
    geneCounts <- countsType()
    targetFactors <- designFactors()
    listExp <- valueExp()
    # create DESeqDataSet list object
    dds <- DESeqDataSetFromMatrix(countData = geneCounts,
                                  colData = targetFactors,
                                  design = listExp)
  }
  
  # TP-DO: allow user input of reference levels for each factor
  # specify the reference level
  #dds$treatment <- relevel(dds$treatment, ref = "VIS")
  #dds$genotype <- relevel(dds$genotype, ref = "PA")
  
  ##
  # Data Exploration
  ##
  
  # function for finding the genes with sufficient expression
  findMin <- function(){
    # retrieve input design
    targets <- inputDesign()
    # get the minimum group size
    sampleCounts <- table(targets)
    sampleCounts[sampleCounts == 0] <- NA
    smallestGroupSize <- min(sampleCounts, na.rm = TRUE)
    # TO-DO: allow user inputs of minimum counts threshold
    # keep only rows that have a count of at least 10 for a minimal number of samples
    keep <- rowSums(counts(dds) >= 10) >= smallestGroupSize
  }
  
  # render table with number of filtered genes
  output$numFilt <- renderTable({
    # filter the genes based on expression levels
    keep <- findMin()
    # view the number of filtered genes
    table(keep)[2]
  }, colnames = FALSE)
  
  # function for pre-filtering the data
  preFilter <- function(){
    # filter the genes based on expression levels
    keep <- findMin()
    # filter the list object
    dds <- dds[keep,]
  }
  
  # check if results have completed
  output$preFilterCompleted <- function(){
    if(is.null(preFilter())){
      return(FALSE)
    }
    return(TRUE)
  }
  outputOptions(output, 'preFilterCompleted', suspendWhenHidden=FALSE, priority=0)
  
  # function for vst of the data
  vstData <- function(){
    # retrieve filtered counts
    dds <- preFilter()
    # vst the data
    vsd <- vst(dds, blind=FALSE)
  }
  
  # PCA plot
  createPCA <- function(){
    # retrieve the vst data
    vsd <- vstData()
    # save the PCA
    pcaData <- plotPCA(vsd, intgroup=colnames(colData)[-1], returnData=FALSE)
    # store the PCA plot
    sample_pca <- ggplot(pcaData@data, aes(PC1, PC2, color=pcaData@data[,5], shape=pcaData@data[,6])) +
      geom_point(size=3) + 
      scale_colour_manual(values = c(plotColors[seq(1, length(levels(pcaData@data[,5])))])) +
      scale_shape_manual(values = seq(0, length(levels(pcaData@data[,6]))-1)) +
      xlab(pcaData@labels$x) +
      ylab(pcaData@labels$y) + 
      coord_fixed()
  }
  
  # render PCA plot
  output$PCA <- renderImage({
    # save image
    exportFile <- "PCAPlot.png"
    # create the plot
    pcaPlot <- createPCA()
    # save the PCA plot
    ggsave(exportFile, plot = pcaPlot, device = "png", units = "in")
    # Return a list
    list(src = exportFile, alt = "Invalid Results", height = "500px")
  }, deleteFile = TRUE)
  
  # download handler for the PCA plot
  output$downloadPCA <- downloadHandler(
    filename = function() {
      "PCAPlot.png"
    },
    content = function(file) {
      # create the plot
      pcaPlot <- createPCA()
      # save the PCA plot
      ggsave(file, plot = pcaPlot, device = "png", units = "in")
    }
  )
  
  # function to determine the sample distances
  determineDistances <- function(){
    # retrieve the vst data
    vsd <- vstData()
    # transpose of the transformed count matrix to get sample-to-sample distances
    sampleDists <- dist(t(assay(vsd)))
  }
   
  # function to prepare the distance matrix
  prepareDistMatrix <- function(){ 
    # retrieve sample distances
    sampleDists <- determineDistances()
    # convert the distances to a matrix
    sampleDistMatrix <- as.matrix(sampleDists)
    # update the column names
    colnames(sampleDistMatrix) <- NULL
  }
  
  # pheatmap of the individual samples
  createPheatmap <- function(){
    # retrieve sample distances
    sampleDists <- determineDistances()
    # retrieve the distance matrix
    sampleDistMatrix <- prepareDistMatrix()
    # TO-DO: use color blind safe pallette
    # store the clustering plot as a ggplot object
    as.ggplot(pheatmap(sampleDistMatrix,
                       clustering_distance_rows=sampleDists,
                       clustering_distance_cols=sampleDists,
                       col=colors))
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
  
  ##
  # DE Analysis Contrasts
  ##
  
  # render text with glm comparison
  output$deComparison <- renderText({
    # require the expression
    #req(input$compareExpression)
    # return the expression
    valueExp()
  })
  
  # function to perform DE analysis
  deAnalysis <- function(){
    # retrieve filtered counts
    dds <- preFilter()
    # standard differential expression analysis steps are wrapped into a single function
    dds <- DESeq(dds)
  }
  
  # function to perform glm contrasts
  glmContrast <- eventReactive(list(input$analysisUpdate), {
    # retrieve input design
    colData <- designFactors()
    # perform DE analysis
    dds <- deAnalysis()
    # TO-DO: allow user to input contrast
    # directly specify the comparison
    res <- results(dds, contrast=c(colnames(colData)[2],rev(levels(colData[,2]))))
    # order our results table by the smallest p value
    resOrdered <- res[order(res$pvalue),]
  })
  
  # check if results have completed
  output$glmResultsCompleted <- function(){
    if(is.null(glmContrast())){
      return(FALSE)
    }
    return(TRUE)
  }
  outputOptions(output, 'glmResultsCompleted', suspendWhenHidden=FALSE, priority=0)
  
  # function to filter results
  filterResults <- function(){
    # perform DE analysis
    dds <- deAnalysis()
    # TO-DO: allow users to input cut offs
    # set the adjusted p-value cut off to 0.05 and LFC to 1.2
    res05 <- results(dds, contrast=c(colnames(targets)[2],levels(targets[,2])), alpha=0.05, lfcThreshold=1.2)
    # order our results table by the smallest p value
    resOrdered <- res05[order(res05$pvalue),]
  }
  
  # render table with the summary of results
  output$glmSummary <- renderTable({
    # retrieve filtered DE results
    tested <- filterResults()
    # summarize results
    testSummary <- summary(resOrdered)
    # number of up expressed
    numUp <- gsub(",", "", strsplit(capture.output(testSummary)[4], " ")[[1]][9])
    # number of down expressed
    numDown <- gsub(",", "", strsplit(capture.output(testSummary)[5], " ")[[1]][6])
    # create the results summary
    resultsTable <- data.frame(
      Direction = c("Down", "Up"),
      Number = c(numDown, numUp)
    )
    # return the formatted results summary
    resultsTable
  })
  
  # pheatmap of glm DGE 
  createGLMPheatmapDGE <- function(){
    # retrieve filtered DE results
    tested <- filterResults()
    # retrieve input design
    targets <- inputDesign()
    
    ## TO-DO: continue to update
    
    # calculate scaling factors
    list <- filterNorm()
    # create a results table of DE genes by FDR and LFC
    resultsTbl <- topTags(tested, n=nrow(tested$table), adjust.method="fdr", p.value=valueFDR())$table
    # TO-DO: change to >= or <=
    # identify significantly DE genes
    DGESubset <- resultsTbl[resultsTbl$logFC > valueLFC() | resultsTbl$logFC < (-1*valueLFC()),]
    # calculate the log2 CPM of the gene count data
    logcpm <- cpm(list, log=TRUE)
    # subset the log2 CPM by the DGE set
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
      paste(valueExp(), "glmDE_genes.csv", sep = "_")
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
      paste(valueExp(), "glmSigDE_genes.csv", sep = "_")
    },
    content = function(file) {
      # perform glm test
      tested <- glmContrast()
      # create a results table of DE genes by FDR and LFC
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
  output$glmResultsIDs <- downloadHandler(
    filename = function() {
      # setup output file name
      paste(valueExp(), "glmcolorGs_geneIDs.csv", sep = "_")
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
      paste(valueExp(), "glmSigDE_geneIDs.csv", sep = "_")
    },
    content = function(file) {
      # retrieve gene IDS
      resultsTblNames <- retrieveGLMSigGeneIDs()
      # output table
      writeLines(resultsTblNames, con = file, sep = "")
    }
  )
  
  # download Rmd HTML report with the current inputs
  # https://shiny.posit.co/r/articles/build/generating-reports/
  #output$report <- downloadHandler(
    # For PDF output, change this to "report.pdf"
    #filename = "DA_report.html",
    #content = function(file) {
      # Copy the report file to a temporary directory before processing it, in
      # case we don't have write permissions to the current working dir
      #tempReport <- file.path(tempdir(), "DA_report.Rmd")
      #file.copy("../markdown/DA_report.Rmd", tempReport, overwrite = TRUE)
      # Set up parameters to pass to Rmd document
      #params <- list(
        #inputDataIn = input$geneCountsTable$datapath,
        #targetsIn = input$expDesignTable$datapath,
        #cutLFCIn = valueLFC(),
        #cutFDRIn = valueFDR(),
        #designIn = valueDes(),
        #comparisonIn = valueExp()
      #)
      # Knit the document, passing in the `params` list, and eval it in a
      # child of the global environment
      #rmarkdown::render(tempReport, output_file = file,
                        #params = params#,
                        ##envir = new.env(parent = globalenv())
      #)
    #}
  #)
}

#### App Object ####

# create the Shiny app object 
shinyApp(ui = ui, server = server)

# TO-DO: improve detail of output error messages (using console?)
## https://stackoverflow.com/questions/34422342/show-warning-to-user-in-shiny-in-r
# TO-DO: consider adding data summary tab
# TO-DO: add software version print out on information tab
# TO-DO: add scree plot
# TO-DO: double check pheatmap display
# TO-DO: fix check of design file length (requires new line to match counts header length)
# TO-DO: fix output table header, which is missing the "gene" column?
# TO-DO: add bar plots of gene counts and LFC
# TO-DO: output example tables as csv
# TO-DO: add legend to volcano plots
# TO-DO: allow input lists and tables of dispersion values
# TO-DO: hide pheatmap when not enough DGE
# TO-DO: note that the sample names need to be carefully formatted, for example:
### don't include mathematical symbols like - that can confuse the GLM contrasts
### don't have the same names between samples and groups
# TO-DO: add note that plotMDS can't show if only 2 columns of data: need at least 3
# TO-DO: plotBCV and plotQLDisp are only appropriate with replicates
# TO-DO: note that LFC cut is only auto taken into consideration using GLMs with replicates
# TO-DO: specifically set up-expressed genes as pink and down as blue, not-sig as green
# TO-DO: check if sample and group names need to be different
# TO-DO: add/fix white background for getting started text
# TO-DO: add results table with sig and not-sig DEGs flagged for FA (based on both FDR and LFC)
# TO-DO: update "Data Exploration" tab to "Exploration"
