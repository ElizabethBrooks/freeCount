# creator: Elizabeth Brooks
# updated: 12 April 2024

#### Setup ####

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

# load packages 
suppressPackageStartupMessages({
  library(shiny)
  library(shinythemes)
  library(WGCNA)
  library(dplyr)
})

# the following setting is important, do not omit.
options(stringsAsFactors = FALSE)

# Allow multi-threading within WGCNA. At present this call is necessary.
# Any error here may be ignored but you may want to update WGCNA if you see one.
# Caution: skip this line if you run RStudio or other third-party R environments.
# See note above.
#enableWGCNAThreads()

# TO-DO: store data and results in reactiveVal and reactiveValues
# TO-DO: output example tables as csv
# TO-DO: hide plots for invalid inputs
# TO-DO: fix Windows OS images not showing
# https://stackoverflow.com/questions/38011285/image-not-showing-in-shiny-app-r

#### UI ####

# Define UI 
ui <- fluidPage(
  # view available themes
  #shinythemes::themeSelector(),
  
  # use a theme
  theme = shinytheme("yeti"),
  #theme = shinytheme("superhero"),
  
  # add application title
  titlePanel("Weighted Gene Co-Expression Network Analysis with WGCNA"),
  
  # setup sidebar layout
  sidebarLayout(
    
    # setup sidebar panel
    sidebarPanel(
      
      # show panel depending on run button
      conditionalPanel(
        condition = "!input.runUpload",
        # header for file uploads
        tags$p(
          "Upload table of gene counts (*.csv):"
        ),
        # select a file
        fileInput(
          "dataTableInput", 
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
      # show panel depending on input files check
      conditionalPanel(
        #condition = "output.inputsUploaded && !input.runAnalysis",
        condition = "output.inputsUploaded && !input.runUpload",
        tags$hr(),
        tags$p(
          "Click to Upload Data:"
        ),  
        # TO-DO: remove
        actionButton("runUpload", "Upload")
      ),
      # show panel depending on input files check
      conditionalPanel(
        condition = "input.runUpload && output.inputCheck && !input.runAnalysis",
        tags$p(
          "Click to Run Analysis:"
        ),  
        actionButton("runAnalysis", "Run Analysis"),
        tags$hr()
      ),
      # show panel depending on input files check
      conditionalPanel(
        condition = "input.runUpload && output.inputCheck",
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
        #condition = "!output.inputsUploaded", 
        condition = "!input.runAnalysis",
        tags$h1("Getting Started", align = "center"),
        tags$br(),
        tags$p(
          HTML("<b>Hello!</b>"),
          HTML("Start in the left-hand sidebar by:")
        ),
        tags$p(
          HTML("<b>1.</b> uploading <i>.csv</i> files with the normalized gene counts and experimental design")
        ),
        tags$p(
          HTML("<b>2.</b> clicking the <i>Upload</i> button to check that the inputs are valid, which appears after the format of the inputs are checked")
        ),
        tags$p(
          HTML("<b>3.</b> clicking the <i>Run Analysis</i> button, which appears after the input files are verified as valid for analysis")
        ),
        tags$br(),
        tags$p(
          "Note that the WGCNA analysis results and plots may take several moments to process depending on the size of the input noramlized gene counts table and experimental design."
        ),
        tags$hr(),
        tags$p(
          align = "center",
          HTML("<b>Helpful Tips</b>")
        ),
        tags$br(),
        tags$p(
          HTML("<b>Tip 1:</b> In the input experimental design table the first column with sample names must contain <i>characters</i> and the remaining columns of factors are expected to contain whole <i>numbers</i>.")
        ),
        tags$p(
          HTML("<b>Tip 2:</b> The input gene counts should be <i>TMM</i> normalized gene counts (e.g., using edgeR).")
        ),
        tags$hr(),
        tags$p(
          align="center",
          HTML("<b>Data Formatting</b>")
        ),
        tags$p(
          "Example experimental design and gene counts tables are displayed below."
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
          )
        )
      ),
      
      # warning text
      conditionalPanel(
        condition = "output.inputsUploaded && !output.inputCheck",
        #condition = "output.inputsUploaded && !output.inputCheck && !output.resultsCompleted",
        tags$h1(
          "Warning", 
          align="center"
        ),
        tags$br(),
        tags$p(
          "The data in the uploaded file(s) are not of the correct type or the sample names do not match.",
        ),
        tags$br(),
        tags$p(
          "Please check that each of the input files were uploaded correctly in the left-hand side bar."
        ),
        tags$p(
          HTML("Please <b>allow a moment for processing</b> after uploading new input file(s).")
        ),
        tags$hr(),
        tags$p(
          align = "center",
          HTML("<b>Helpful Tips</b>")
        ),
        tags$p(
          HTML("<b>Tip 1:</b> The input normalized gene counts table is expected to contain <i>numeric</i> values."),
        ),
        tags$p(
          HTML("<b>Tip 2:</b> Sample names contained in the first line of the normalized gene counts table and first column of the experimental design table are expected to contain <i>characters</i>.")
        ),
        tags$p(
          HTML("<b>Tip 3:</b> Each column after the first in the experimental design table is expected to contain whole <i>numeric</i> values (integers)."),
        ),
        tags$p(
          HTML("<b>Tip 4:</b> Sample names in the first line of the normalized gene counts table <i>must match</i> the sample names contained in the first column of the experimental design table.")
        ),
        tags$p(
          HTML("<b>Tip 5:</b> The input normalized gene counts and experimental design tables must end in the <i>.csv</i> file extension.")
        )
      ),
      
      # processing text
      conditionalPanel(
        condition = "input.runAnalysis && output.inputCheck && !output.resultsCompleted",
        tags$h1(
          "Processing", 
          align="center"
        ),
        tags$br(),
        tags$p(
          "The network analysis results and plots may take several moments to process depending on the size of the input normalized gene counts or experimental design tables."
        )
        #tags$br(),
        #tags$p(
        #align="center",
        #HTML("<b>Warning!</b>")
        #),
        #tags$p(
        #HTML("The application will stop working if errors have been produced from a too high <i>Minimum Branch Cluster Size</i> or too low <i>Branch Cut Height</i>.")
        #)
      ),
      
      # results text and plots
      conditionalPanel(
        condition = "input.runAnalysis && output.inputCheck && output.resultsCompleted",
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
              HTML("<b>Tip 1:</b> The plots and results may take several moments to appear depending on the size of the input normalized gene counts table.")
            ),
            tags$p(
              HTML("<b>Tip 2:</b> Navigate to the <i>Data Cleaning</i> or <i>Network Construction</i> steps by clicking the tabs above.")
            ),
            tags$p(
              HTML("<b>Tip 3:</b> Navigate to the <i>Results</i> by clicking the tabs above.")
            ),
            tags$p(
              HTML("<b>Tip 4:</b> Make sure to read the additional <i>Helpful Tips</i> and information that can be found throughout the analysis steps.")
            ),
            #tags$p(
            #HTML("<b>Tip 5:</b> Changing the input normalized gene counts or experimental design tables in the left-hand sidebar may produce <i>temporary</i> errors.")
            #),
            tags$p(
              HTML("<b>Tip 5:</b> Tables of gene counts with missing data may produce an error.")
            )
            #tags$p(
            #HTML("<b>Tip 7:</b> Repeatedly changing the inputs may cause the application to stop working.")
            #)
          ),
          
          # data cleaning tab
          tabPanel(
            "Data Cleaning",
            tags$br(),
            tags$p(
              align="center",
              HTML("<b>Data Input and Cleaning</b>")
            ),
            tags$br(),
            fluidRow(
              column(
                width = 4,
                sliderInput(
                  "setMinSize", 
                  tags$p("Minimum Branch Cluster Size"), 
                  value=1,
                  min=1, 
                  max=2, 
                  step=1
                ),
                tags$p(
                  "Select a minimum branch cluster size for the detection of outlier samples."
                ),
              ),
              column(
                width = 4,
                sliderInput(
                  "setCutHeight", 
                  tags$p("Branch Cut Height"), 
                  value=99,
                  min=99, 
                  max=100, 
                  step=1
                ),
                tags$p(
                  "Select a cut height to remove outlier samples."
                )
              ),
              column(
                width = 4,
                tags$p(
                  HTML("<b>Sample Cluster Sizes:</b>")
                ),
                tableOutput(outputId = "clusterData")
              )
            ),
            tags$p(
              HTML("<b>Tip:</b> Errors can result from a high <i>Minimum Branch Cluster Size</i> or low <i>Branch Cut Height</i>.")
            ),
            tags$br(),
            imageOutput(outputId = "samplesOutliers", height="100%", width="100%"),
            downloadButton(outputId = "downloadSamplesOutliers", label = "Download Plot"),
            tags$p(
              "The above dendrogram clusters samples based on their Euclidean distance, which facilitates the detection of outliers."
            ),
            tags$hr(),
            tags$p(
              align="center",
              HTML("<b>Filtered Data</b>")
            ),
            tags$br(),
            imageOutput(outputId = "clusterSamples", height="100%", width="100%"),
            downloadButton(outputId = "downloadClusterSamples", label = "Download Plot"),
            tags$p(
              "Factors associated with samples are displayed below each sample in the cluster plot. The factors are shown as colors that range from white to red, where white indicates low values and red high. Missing entries are shown as grey."
            ),
            tags$hr(),
            tags$p(
              align="center",
              HTML("<b>Cleaned Data</b>")
            ),
            tags$br(),
            tags$p(
              "Genes or samples with too many missing values have been removed from the data and lists of these genes or samples may be downloaded below."
            ),
            tags$br(),
            tags$p(
              HTML("<b>Sample Data Check:</b>")
            ),
            downloadButton(outputId = "testSamples", label = "Download Data"),
            tags$p(
              "Any samples with too many missing values are listed."
            ),
            tags$br(),
            tags$p(
              HTML("<b>Gene Data Check:</b>")
            ),
            downloadButton(outputId = "testGenes", label = "Download Data"),
            tags$p(
              "Any genes with too many missing values are listed."
            )
          ),
          
          # network construction tab
          tabPanel(
            "Network Construction",
            tags$br(),
            tags$p(
              align="center",
              HTML("<b>Network Construction and Module Detection</b>")
            ),
            tags$br(),
            sliderInput(
              "setPowersRange", 
              tags$p("Soft Thresholding Power Range"), 
              value=20,
              min=1, 
              max=50, 
              step=1
            ),
            tags$p(
              "Select an upper value for the range of candidate soft thresholding powers."
            ),
            tags$br(),
            imageOutput(outputId = "plotThreshold", height="100%", width="100%"),
            downloadButton(outputId = "downloadPlotThreshold", label = "Download Plot"),
            tags$p(
              "The above plot shows the analysis of network topology for the input range of soft thresholding powers. The left panel shows the scale-free fit index (y-axis) as a function of the soft-thresholding power (x-axis). The right panel displays the mean connectivity (degree, y-axis) as a function of the soft-thresholding power (x-axis)."
            ),
            tags$hr(),
            tags$p(
              align="center",
              HTML("<b>Module Construction</b>")
            ),
            tags$br(),
            fluidRow(
              column(
                width = 6,
                sliderInput(
                  "setPowers", 
                  tags$p("Soft Thresholding Power"), 
                  value=6,
                  min=1, 
                  max=20, 
                  step=1
                ),
                tags$p(
                  "Choose a soft thresholding power to which co-expression similarity is raised to calculate adjacency."
                )
              ),
              column(
                width = 6,
                sliderInput(
                  "setSize", 
                  tags$p("Minimum Module Size"), 
                  value=30,
                  min=1, 
                  max=100, 
                  step=1
                ),
                tags$p(
                  "Choose a minimum module size for the gene clusters."
                )
              )
            ),
            tags$br(),
            tags$p(
              HTML("<b>Tip 2:</b> Errors can result from a combination of high <i>Soft Thresholding Power</i> or <i>Minimum Module Size</i> values.")
            ),
            tags$br(),
            fluidRow(
              column(
                width = 6,
                tags$p(
                  HTML("<b>Module Number Labels and Sizes:</b>")
                ),
                tableOutput(outputId = "moduleTable")
              ),
              column(
                width = 6,
                tags$p(
                  HTML("<b>Module Color Labels and Sizes:</b>")
                ),
                tableOutput(outputId = "colorsTable")
              )
            ),
            tags$br(),
            tags$p(
              align="center",
              HTML("<b>Helpful Tips</b>")
            ),
            tags$p(
              HTML("<b>Tip 1:</b> The <i>Soft Thresholding Power</i> and <i>Minimum Module Size</i> should be selected where the scale free topology model fit is above 0.8 and mean connectivity under the hundreds.")
            ),
            tags$p(
              HTML("<b>Tip 2:</b> Note that the 0 number label is reserved for unassigned genes.")
            ),
            tags$p(
              HTML("<b>Tip 3:</b> Note that the grey color label is reserved for unassigned genes.")
            ),
            #tags$p(
            #HTML("<b>Tip 4:</b> The thresholding procedure is describe in "),
            #tags$a("\"WGCNA: an R package for weighted correlation network analysis\"", href = "https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7873980/"),
            #"(e.g., Category 1: Functions for network construction)."
            #),
            tags$hr(),
            tags$p(
              align="center",
              HTML("<b>Network Construction</b>")
            ),
            tags$br(),
            sliderInput(
              "setMEDissThres", 
              tags$p("Module Eigengene Cut Height"), 
              value=0.25,
              min=0, 
              max=1, 
              step=0.01
            ),
            tags$p(
              "Select a cut height to merge close modules, which is measured by the correlation of the module eigengenes."
            ),
            tags$p(
              "Eigengenes can be thought of as a weighted average expression profile."
            ),
            tags$p(
              "Modules are clustered by their calculated eigengene correlations to determine the co-expression similarity of modules."
            ),
            tags$br(),
            tags$p(
              HTML("<b>Tip</b> It is recommended to select a cut height of 0.25, which corresponds to a 0.75 correlation.")
            ),
            tags$br(),
            imageOutput(outputId = "plotEigengenes", height="100%", width="100%"),
            downloadButton(outputId = "downloadPlotEigengenes", label = "Download Plot"),
            tags$p(
              "Above is a dendrogram that displays the clustering of module eigengenes (ME), which have been labeled with their associated module color."
            ),
            tags$hr(),
            tags$p(
              align="center",
              HTML("<b>Network Data</b>")
            ),
            tags$br(),
            imageOutput(outputId = "plotTrimmedDendro", height="100%", width="100%"),
            downloadButton(outputId = "downloadPlotTrimmedDendro", label = "Download Plot"),
            tags$p(
              "The above clustering dendrogram of genes shows dissimilarity based on topological overlap, together with assigned merged module colors and the original module colors."
            )
            #imageOutput(outputId = "plotColorDendro", height="100%", width="100%"),
            #downloadButton(outputId = "downloadPlotColorDendro", label = "Download Plot"),
            #imageOutput(outputId = "hclustPlot", height="100%", width="100%"),
            #downloadButton(outputId = "downloadHclustPlot", label = "Download Plot")
          ),
          
          # results tab
          tabPanel(
            "Results",
            tags$br(),
            tags$p(
              align="center",
              HTML("<b>Network Analysis Results</b>")
            ),
            tags$br(),
            tags$p(
              "Results from the co-expression network analysis may be downloaded below."
            ),
            tags$br(),
            tags$p(
              HTML("<b>Gene Module Data</b>")
            ),
            downloadButton(outputId = "geneDownload", label = "Download Table"),
            tags$br(),
            tags$p(
              "The genes and their associated module colors and numbers."
            ),
            tags$br(),
            tags$p(
              HTML("<b>Eigengene Expression Data</b>")
            ),
            downloadButton(outputId = "eigengeneDownload", label = "Download Table"),
            tags$br(),
            tags$p(
              "The calculated ME expression values for each module."
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
              "This application for expression network analysis was created by ",
              tags$a("Elizabeth Brooks",href = "https://www.linkedin.com/in/elizabethmbrooks/"),
              "."
            ),
            tags$p(
              "The latest version of this application may be downloaded from ",
              tags$a("GitHub",href = "https://github.com/ElizabethBrooks/DGEAnalysis_ShinyApps/tree/main/apps"),
              "."
            ),
            tags$p(
              "Example normalized gene counts and experimental design tables are also provided on ",
              tags$a("GitHub", href = "https://github.com/ElizabethBrooks/DGEAnalysis_ShinyApps/tree/main/data/WGCNA"),
              "."
            ),
            tags$p(
              "Normalized gene tables may be created from RNA-seq data as described in ", 
              tags$a("Downstream Bioinformatics Analysis of Omics Data with edgeR", href = "https://morphoscape.wordpress.com/2022/08/09/downstream-bioinformatics-analysis-of-omics-data-with-edger/"), 
              "."
            ),
            tags$p(
              "A tutorial of the network analysis performed in this application can be found in the URL entry for ", 
              tags$a("WGCNA: Weighted Correlation Network Analysis", href = "https://CRAN.R-project.org/package=WGCNA"), 
              "."
            ),
            #tags$p(
            #"Frequently asked questions are available at ", 
            #tags$a("WGCNA package FAQ", href = "https://horvath.genetics.ucla.edu/html/CoexpressionNetwork/Rpackages/WGCNA/faq.html"), 
            #"."
            #),
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

# TO-DO: consider using validate functions to handle some errors
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
      SampleOne = c(55.4739214515074,55.4922106735603,50.8277794324053,49.0577237706748,35.0116413707558),
      SampleTwo = c(1.29009119654668,3.14106852869209,1.78343085727738,1.66722101765504,0.89916090304527),
      SampleThree = c(60.6342862376941,58.6332792022524,66.8786571479017,55.1899392420091,47.5157990031686),
      SampleFour = c(41.2829182894939,77.4796903744049,73.1206651483725,52.7370530534754,59.1863461267538),
      SampleFive = c(169.001946747616,187.417088878628,135.540745153081,199.9102243655,132.544070903575),
      SampleSix = c(21.9315503412936,24.0815253866394,33.8851862882702,34.3404066394723,26.6755362824806)
    )
  })
  
  # render example gene counts table
  output$exampleCountsTwo <- renderTable({
    # create example counts table
    exCountsTable <- data.frame(
      Gene = c("geneA", "geneB", "geneC"),
      sample_1 = c(25.4739214515074,25.4922106735603,20.8277794324053),
      sample_2 = c(30.6342862376941,28.6332792022524,36.8786571479017),
      sample_3 = c(11.2829182894939,37.4796903744049,33.1206651483725),
      sample_4 = c(133.001946747616,145.417088878628,121.540745153081),
      sample_5 = c(21.9315503412936,24.0815253866394,33.8851862882702),
      sample_6 = c(32.2522799136671,42.9279365587919,60.6366491474309),
      sample_7 = c(1.29009119654668,3.14106852869209,1.78343085727738),
      sample_8 = c(60.6342862376941,58.6332792022524,66.8786571479017),
      sample_9 = c(41.2829182894939,77.4796903744049,73.1206651483725),
      sample_10 = c(6.6342862376941,5.6332792022524,6.8786571479017),
      sample_11 = c(169.001946747616,187.417088878628,135.540745153081),
      sample_12 = c(55.4739214515074,55.4922106735603,50.8277794324053)
    )
  })
  
  # render first example gene counts table
  output$exampleDesignOne <- renderTable({
    # create example counts table
    exDesignTable <- data.frame(
      Sample = c("SampleOne", "SampleTwo", "SampleThree", "SampleFour", "SampleFive", "SampleSix"),
      Group = c("1", "1", "1", "2", "2", "2")
    )
  })
  
  # render second example gene counts table
  output$exampleDesignTwo <- renderTable({
    # create example counts table
    exDesignTable <- data.frame(
      Individual = c("sample_1", "sample_2", "sample_3", "sample_4", "sample_5", "sample_6", "sample_7", "sample_8", "sample_9", "sample_10", "sample_11", "sample_12"),
      Treatment = c("1", "1", "1", "1", "1", "1", "2", "2", "2", "2", "2", "2"),
      Genotype = c("1", "1", "1", "2", "2", "2", "1", "1", "1", "2", "2", "2")
    )
  })
  
  
  ##
  # Data Setup
  ##
  
  # retrieve input data
  inputDataTable <- reactive({
    # require input data
    req(input$dataTableInput)
    # check the input table is not null
    if(is.null(input$dataTableInput)){
      return(NULL)
    }
    # read the file
    dataInput <- read.csv(file = input$dataTableInput$datapath, row.names=1)
    # check data type of the sample names
    if(!is.character(colnames(dataInput))){
      return(NULL)
    }
    # loop over each data frame column
    for(i in 1:ncol(dataInput)) { 
      # check data type
      if(!is.numeric(dataInput[,i])){
        return(NULL)
      }
    }
    # make sure there are at least three columns
    #if(ncol(dataInput) < 3) { 
    #return(NULL)
    #}
    # return gene counts
    dataInput
  })
  
  # retrieve input data
  inputDesign <- reactive({
    # require input data
    req(input$expDesignTable)
    # check the input table is not null
    if(is.null(input$expDesignTable)){
      return(NULL)
    }
    # import grouping factor
    targets <- read.csv(input$expDesignTable$datapath, row.names=1)
    # check data type of the sample names
    if(!is.character(rownames(targets))){
      return(NULL)
    }
    # loop over each data frame column
    for(i in 1:ncol(targets)) { 
      # check data type
      if(!is.integer(targets[,i])){
        return(NULL)
      }
    }
    # return the design
    targets
  })
  
  # check if input files have been uploaded
  output$inputsUploaded <- function(){
    # check if the input files are valid
    if(is.null(inputDataTable())) {
      return(FALSE)
    }else if(is.null(inputDesign())) {
      return(FALSE)
    }
    return(TRUE)
  }
  outputOptions(output, 'inputsUploaded', suspendWhenHidden=FALSE)
  
  # compare input design and counts samples
  compareSamples <- function(){
    # check if the input files are valid
    if(is.null(inputDesign())) {
      return(NULL)
    }else if(is.null(inputDataTable())) {
      return(NULL)
    }
    # retrieve input design samples
    targets <- inputDesign()
    designSamples <- data.frame(ID1 = targets[,1])
    # retrieve input gene counts samples
    dataInput <- inputDataTable() 
    countsSamples <- data.frame(ID2 = colnames(dataInput))
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
  
  # render experimental design table
  output$designTable <- renderTable({
    # retrieve input gene counts table
    dataInput <- inputDataTable()
    # retrieve column names
    sampleNames <- colnames(dataInput)
    # retrieve input design table
    allTraits <- inputDesign()
    # create data frame
    design <- data.frame(
      Sample = sampleNames,
      Factors = allTraits
    )
  })
  
  
  ##
  # Data Input and Cleaning
  ##
  
  # function to setup the data
  setupData <- function(){
    # check if the input files are valid
    if(is.null(inputDataTable())) {
      return(NULL)
    }
    # begin to construct the counts object
    dataInput <- inputDataTable()
    # transpose each subset
    datExpr0 = data = as.data.frame(t(dataInput))
    names(datExpr0) = rownames(dataInput)
    rownames(datExpr0) = names(dataInput)
    # return the expression data
    datExpr0
  }
  
  ## TO-DO: fix issue with additional goodSamplesGenes function runs
  # https://stackoverflow.com/questions/55650524/avoid-multiple-function-calls-in-server-shiny
  # function to test data
  testCheckData <- function(){
    # require valid inputs
    if(is.null(setupData())){
      return(NULL)
    }
    # retrieve setup data
    datExpr0 <- setupData()
    # check valid input
    testCheck <- try(
      goodSamplesGenes(datExpr0, verbose = 3),
      silent = TRUE
    )
    if(class(testCheck) == "try-error"){
      return(NULL)
    }
    return(TRUE)
  }
  
  # function to check the data
  checkData <- function(){
    # require valid inputs
    if(is.null(testCheckData())){
      return(NULL)
    }
    # retrieve setup data
    datExpr0 <- setupData()
    #Check the genes across all samples
    gsg = goodSamplesGenes(datExpr0, verbose = 3)
  }
  
  # download table with gene data
  output$testGenes <- downloadHandler(
    # retrieve file name
    filename = function() {
      "geneQualityCheck.txt"
    },
    # read in data
    content = function(file) {
      # retrieve check results
      gsg <- checkData()
      # retrieve the expression data
      datExpr0 <- setupData()
      # remove the offending genes and samples from the data
      if (!gsg$allOK){
        # Optionally, print the gene and sample names that were removed:
        if (sum(!gsg$goodGenes)>0){
          geneList <- c(paste("Removing genes:", paste(names(datExpr0)[!gsg$goodGenes], collapse = ", ")))
        }else{
          geneList <- c("Input normalized counts for the genes are good.")
        }
      }else{
        geneList <- c("Input normalized counts for the genes are good.")
      }
      # write the results to a file
      writeLines(geneList, file)
    }
  )
  
  #  download table with sample data
  output$testSamples <- downloadHandler(
    # retrieve file name
    filename = function() {
      "sampleQualityCheck.txt"
    },
    # read in data
    content = function(file) {
      # retrieve prepared data
      datExpr0 <- prepareData()
      # retrieve checked data results
      gsg <- checkData()
      # remove the offending genes and samples from the data
      if (!gsg$allOK){
        if (sum(!gsg$goodSamples)>0){
          sampleList <- c(paste("Removing samples:", paste(rownames(datExpr0)[!gsg$goodSamples], collapse = ", ")))
        }else{
          sampleList <- c("Input normalized counts for the samples are good.")
        }
      }else{
        sampleList <- c("Input normalized counts for the samples are good.")
      }
      # write the results to a file
      writeLines(sampleList, file)
    }
  )
  
  # function to prepare the data
  prepareData <- function(){
    # check valid input
    if(is.null(setupData())){
      return(NULL)
    }else if(is.null(checkData())){
      return(NULL)
    }
    # retrieve checked data
    datExpr0 <- setupData()
    # retrieve checked data results
    gsg <- checkData()
    # remove the offending genes and samples from the data
    if (!gsg$allOK){
      # Remove the offending genes and samples from the data:
      datExpr0 = datExpr0[gsg$goodSamples, gsg$goodGenes]
    }
    # return the expression data
    datExpr0
  }
  
  # function to cluster samples
  createSampleTree <- function(){
    # check valid input
    if(is.null(prepareData())){
      return(NULL)
    }
    # retrieve prepared data
    datExpr0 <- prepareData()
    # cluster the samples to see if there are any obvious outliers
    sampleTree = hclust(dist(datExpr0), method = "average")
  }
  
  # update cut height inputs
  observeEvent(input$runUpload, {
    # retrieve cluster of samples
    sampleTree <- createSampleTree()
    # setup test height value
    testHeightMin <- as.integer(mean(sampleTree$height))
    testHeightMax <- as.integer(max(sampleTree$height))+1
    testHeightValue <- testHeightMax
    # update sample cut height slider
    updateSliderInput(
      session,
      "setCutHeight", 
      value=testHeightValue,
      min=testHeightMin, 
      max=testHeightMax,
      step=1
    )
  })
  
  # update minimum size inputs
  observeEvent(input$runUpload, {
    # retrieve cluster of samples
    sampleTree <- createSampleTree()
    # setup test maximum cut height
    numSamples <- length(sampleTree$height)+1
    testCutHeight <- (numSamples)/4
    # update cluster size slider
    updateSliderInput(
      session,
      "setMinSize", 
      value=1,
      min=1, 
      max=testCutHeight,
      step=1
    )
  })
  
  # update power inputs
  observeEvent(input$runUpload, {
    # retrieve input powers
    inputPower <- input$setPowersRange
    # setup test power value
    testPower <- inputPower/2
    # update powers slider
    updateSliderInput(
      session,
      "setPowers",
      value=testPower,
      min=1, 
      max=inputPower,
      step=1
    )
  })
  
  # update size inputs
  observeEvent(input$runUpload, {
    # retrieve prepared data
    datExpr <- filterData()
    nGenes = ncol(datExpr)
    nSamples = nrow(datExpr)
    # setup test size and max minimum module size
    testSizeValue <- as.integer(nGenes/nSamples)
    testSizeMax <- testSizeValue*2
    # update module size slider
    updateSliderInput(
      session,
      "setSize",
      value=testSizeValue,
      min=1, 
      max=testSizeMax,
      step=1
    )
  })
  
  # function to create clustering plot
  createSamplesOutliers <- function(){
    # require input data
    req(input$setCutHeight)
    # check inputs
    if(is.null(prepareData())) {
      return(NULL)
    }else if(is.null(createSampleTree())) {
      return(NULL)
    }
    # retrieve prepared data
    datExpr0 <- prepareData()
    # retrieve cluster of samples
    sampleTree <- createSampleTree()
    # Plot the sample tree: Open a graphic output window of size 12 by 9 inches
    # The user should change the dimensions if the window is too large or too small.
    sizeGrWindow(12,9)
    par(cex = 0.6)
    par(mar = c(0,4,2,0))
    plot(sampleTree, main = "Sample clustering to detect outliers", sub="", xlab="", cex.lab = 1.5,
         cex.axis = 1.5, cex.main = 2)
    # Plot a line to show the cut
    abline(h = input$setCutHeight, col = "red")
  }
  
  # function to render clustering plot
  output$samplesOutliers <- renderImage({
    # save file
    exportFile <- "sampleClustering.png"
    png(file = exportFile, width = 12, height = 9, units="in", res=150)
    createSamplesOutliers()
    dev.off()
    # Return a list
    list(src = exportFile, alt = "Invalid Results", height = "500px")
  }, deleteFile = TRUE)
  
  # download handler for the samples plot
  output$downloadSamplesOutliers <- downloadHandler(
    filename = function() {
      "sampleClustering.png"
    },
    content = function(file) {
      # save the plot
      png(file, width = 12, height = 9, units="in", res=150)
      createSamplesOutliers()
      dev.off()
    }
  )
  
  # reactive function to filter expression data
  setupClusterData <- eventReactive(input$runAnalysis, {
    # require input data
    req(input$setCutHeight, input$setMinSize)
    # require valid inputs
    if(is.null(prepareData())){
      return(NULL)
    }
    # retrieve prepared data
    datExpr0 <- prepareData()
    # retrieve cluster of samples
    sampleTree <- createSampleTree()
    # Determine cluster under the line
    clust = cutreeStatic(sampleTree, cutHeight = input$setCutHeight, minSize = input$setMinSize)
  })
  
  # render table of clusters
  output$clusterData <- renderTable({
    # retrieve clusters
    clust <- setupClusterData()
    # retrieve table of results
    resultsTable <- table(clust)
    # create data frame
    infoTable <- data.frame(
      Cluster = rownames(resultsTable),
      Size = resultsTable
    )
    # remove extra column
    infoTable <- infoTable[,-2]
    # update column names
    colnames(infoTable) <- c("Cluster", "Size")
    # return table
    infoTable
  })
  
  # function to filter expression data
  filterData <- function(){
    # check if the inputs are valid
    if(is.null(setupClusterData())) {
      return(NULL)
    }else if(is.null(prepareData())) {
      return(NULL)
    }
    # retrieve clusters
    clust <- setupClusterData()
    # retrieve prepared data
    datExpr0 <- prepareData()
    # clust 1 contains the samples we want to keep.
    keepSamples = (clust==1)
    # filter out samples
    datExpr <- datExpr0
    datExpr = datExpr0[keepSamples, ]
  }
  
  # function to prepare trait data
  traitData <- function(){
    # check if the inputs are valid
    if(is.null(inputDesign())) {
      return(NULL)
    }else if(is.null(filterData())) {
      return(NULL)
    }
    # retrieve input design table
    allTraits <- inputDesign()
    # retrieve prepared data
    datExpr <- filterData()
    nGenes = ncol(datExpr)
    nSamples = nrow(datExpr)
    # Form a data frame analogous to expression data that will hold the traits
    samples = rownames(datExpr)
    traitRows = match(samples, rownames(allTraits))
    datTraits = allTraits[traitRows,]
    # clean up memory
    collectGarbage()
    # return the trait data
    datTraits
  }
  
  # function to create updated clustering plot
  createClusterSamples <- function(){
    # check inputs
    if(is.null(filterData())) {
      return(NULL)
    }else if(is.null(traitData())) {
      return(NULL)
    }
    # retrieve prepared data
    datExpr <- filterData()
    # retrieve the trait data
    datTraits <- traitData()
    # Re-cluster samples
    sizeGrWindow(10,7)
    sampleTree2 = hclust(dist(datExpr), method = "average")
    # Convert traits to a color representation: white means low, red means high, grey means missing entry
    traitColors = numbers2colors(datTraits, signed = FALSE)
    # check valid inputs
    testCheck <- try(
      plotDendroAndColors(sampleTree2, traitColors),
      silent = TRUE
    )
    if(class(testCheck) == "try-error"){
      return(NULL)
    }
    # Plot the sample dendrogram and the colors underneath.
    plotDendroAndColors(sampleTree2, traitColors,
                        groupLabels = names(datTraits),
                        main = "Sample dendrogram and trait heatmap")
  }
  
  # function to render updated clustering plot
  output$clusterSamples <- renderImage({
    # save image
    exportFile <- "sampleDendrogram_traitHeatmap.png"
    png(file = exportFile, width = 10, height = 7, units="in", res=150)
    createClusterSamples()
    dev.off()
    # Return a list
    list(src = exportFile, alt = "Invalid Results", height = "500px")
  }, deleteFile = TRUE)
  
  # download handler for the clustering plot
  output$downloadClusterSamples <- downloadHandler(
    filename = function() {
      "sampleDendrogram_traitHeatmap.png"
    },
    content = function(file) {
      # save the plot
      png(file, width = 10, height = 7, units="in", res=150)
      createClusterSamples()
      dev.off()
    }
  )
  
  
  ##
  # Network Construction and Module Detection
  ##
  
  # reactive function to pick powers
  pickPowers <- eventReactive(input$runAnalysis, {
    # require input data
    req(input$setPowersRange)
    # require valid inputs
    if(is.null(compareSamples())){
      return(NULL)
    }
    # retrieve prepared data
    datExpr <- filterData()
    # retrieve selected powers
    powers <- c(seq(from = 1, to = input$setPowersRange, by = 2))
    # Call the network topology analysis function
    sft = pickSoftThreshold(datExpr, powerVector = powers, verbose = 5)
  })
  
  # TO-DO: this suspendWhenHidden=FALSE appears to cause additional function calls
  # check if file has been uploaded
  output$resultsCompleted <- function(){
    if(!is.null(pickPowers())){
      return(TRUE)
    }
    return(FALSE)
  }
  outputOptions(output, 'resultsCompleted', suspendWhenHidden=FALSE, priority=0)
  
  # create plot with scale independence and mean connectivity
  createPlotThreshold <- function(){
    # require input data
    req(input$setPowersRange)
    # check inputs
    if(is.null(pickPowers())) {
      return(NULL)
    }
    # retrieve soft thresholding powers
    sft <- pickPowers()
    # retrieve selected powers
    powers <- c(seq(from = 1, to = input$setPowersRange, by = 2))
    # Plot the results
    cex1 = 0.9
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
  }
  
  # render plot with scale independence and mean connectivity
  output$plotThreshold <- renderImage({
    # save image
    exportFile <- "SoftPowers.png"
    png(file = exportFile, wi = 9, he = 5, units="in", res=150)
    createPlotThreshold()
    dev.off()
    # Return a list
    list(src = exportFile, alt = "Invalid Results", height = "500px")
  }, deleteFile = TRUE)
  
  # download handler for the powers plot
  output$downloadPlotThreshold <- downloadHandler(
    filename = function() {
      "SoftPowers.png"
    },
    content = function(file) {
      # save the plot
      png(file, wi = 9, he = 5, units="in", res=150)
      createPlotThreshold()
      dev.off()
    }
  )
  
  # reactive function to create TOMs
  createTOM <- eventReactive(input$runAnalysis, {
    # require input data
    req(input$setPowers)
    # require valid inputs
    if(is.null(compareSamples())){
      return(NULL)
    }
    # retrieve prepared data
    datExpr <- filterData()
    # retrieve input soft power
    softPower <- input$setPowers
    # determine adjacency
    adjacency = adjacency(datExpr, power = softPower)
    # Turn adjacency into topological overlap
    TOM = TOMsimilarity(adjacency)
    dissTOM = 1-TOM
  })
  
  # function to create the gene tree
  createGeneTree <- function(){
    # check if the inputs are valid
    if(is.null(createTOM())) {
      return(NULL)
    }
    # retrieve TOM
    dissTOM <- createTOM()
    # Call the hierarchical clustering function
    geneTree = hclust(as.dist(dissTOM), method = "average")
  }
  
  # function to create hierarchical clustering plot
  createHclustPlot <- function(){
    # check inputs
    if(is.null(createGeneTree())) {
      return(NULL)
    }
    # retrieve gene tree
    geneTree <- createGeneTree()
    # Plot the resulting clustering tree (dendrogram)
    sizeGrWindow(12,9)
    plot(geneTree, xlab="", sub="", main = "Gene clustering on TOM-based dissimilarity",
         labels = FALSE, hang = 0.04)
  }
  
  # function to render hierarchical clustering plot
  output$hclustPlot <- renderImage({
    # save image
    exportFile <- "geneClustering.png"
    png(file = exportFile, wi = 12, he = 9, units="in", res=150)
    createHclustPlot()
    dev.off()
    # Return a list
    list(src = exportFile, alt = "Invalid Results", height = "500px")
  }, deleteFile = TRUE)
  
  # download handler for the clustering plot
  output$downloadHclustPlot <- downloadHandler(
    filename = function() {
      "geneClustering.png"
    },
    content = function(file) {
      # save the plot
      png(file, wi = 12, he = 9, units="in", res=150)
      createHclustPlot()
      dev.off()
    }
  )
  
  # reactive function to identify modules
  findModules <- eventReactive(input$runAnalysis, {
    # require input data
    req(input$setSize)
    # require valid inputs
    if(is.null(createGeneTree())){
      return(NULL)
    }else if(is.null(createTOM())){
      return(NULL)
    }
    # retrieve gene tree
    geneTree <- createGeneTree()
    # retrieve TOM
    dissTOM <- createTOM()
    # retrieve module size
    minModuleSize <- input$setSize
    # Module identification using dynamic tree cut:
    dynamicMods = cutreeDynamic(dendro = geneTree, distM = dissTOM,
                                deepSplit = 2, pamRespectsDendro = FALSE,
                                minClusterSize = minModuleSize)
  })
  
  # function to render table of modules
  output$moduleTable <- renderTable({
    # retrieve modules
    dynamicMods <- findModules()
    # get table of results
    resultsTable <- table(dynamicMods)
    # create data frame
    infoTable <- data.frame(
      Module = rownames(resultsTable),
      Size = resultsTable
    )
    # remove extra column
    infoTable <- infoTable[,-2]
    # update column names
    colnames(infoTable) <- c("Module", "Size")
    # return table
    infoTable
  })
  
  # function to convert module labels
  convertLabels <- function(){
    # require valid inputs
    if(is.null(findModules())){
      return(NULL)
    }
    # retrieve modules
    dynamicMods <- findModules()
    # Convert numeric lables into colors
    dynamicColors = labels2colors(dynamicMods)
  }
  
  # function to render table of colors
  output$colorsTable <- renderTable({
    # retrieve modules
    dynamicColors <- convertLabels()
    # get table of results
    resultsTable <- table(dynamicColors)
    # create data frame
    infoTable <- data.frame(
      Module = rownames(resultsTable),
      Size = resultsTable
    )
    # remove extra column
    infoTable <- infoTable[,-2]
    # update column names
    colnames(infoTable) <- c("Module", "Size")
    # return table
    infoTable
  })
  
  # function to create plot of dendorgram with colors
  createPlotColorDendro <- function(){
    # check inputs
    if(is.null(createGeneTree())) {
      return(NULL)
    }else if(is.null(convertLabels())) {
      return(NULL)
    }
    # retrieve gene tree
    geneTree <- createGeneTree()
    # retrieve modules
    dynamicColors <- convertLabels()
    # Plot the dendrogram and colors underneath
    sizeGrWindow(8,6)
    plotDendroAndColors(geneTree, dynamicColors, "Dynamic Tree Cut",
                        dendroLabels = FALSE, hang = 0.03,
                        addGuide = TRUE, guideHang = 0.05,
                        main = "Gene dendrogram and module colors")
  }
  
  # function to render plot of dendorgram with colors
  output$plotColorDendro <- renderImage({
    # save file
    exportFile <- "dynamicTreeCut.png"
    png(file = exportFile, wi = 8, he = 6, units="in", res=150)
    createPlotColorDendro()
    dev.off()
    # Return a list
    list(src = exportFile, alt = "Invalid Results", height = "700px")
  }, deleteFile = TRUE)
  
  # download handler for the dendrogram plot
  output$downloadPlotColorDendro <- downloadHandler(
    filename = function() {
      "dynamicTreeCut.png"
    },
    content = function(file) {
      # save the plot
      png(file, wi = 8, he = 6, units="in", res=150)
      createPlotColorDendro()
      dev.off()
    }
  )
  
  # function to calculate eigengenes
  calcEigengenes <- function(){
    # require valid inputs
    if(is.null(filterData())){
      return(NULL)
    }else if(is.null(convertLabels())){
      return(NULL)
    }
    # retrieve prepared data
    datExpr <- filterData()
    # retrieve modules
    dynamicColors <- convertLabels()
    testCheck <- try(
      moduleEigengenes(datExpr, colors = dynamicColors),
      silent = TRUE
    )
    if(class(testCheck) == "try-error"){
      return(NULL)
    }
    # Calculate eigengenes
    MEList = moduleEigengenes(datExpr, colors = dynamicColors)
    MEs = MEList$eigengenes
    # Calculate dissimilarity of module eigengenes
    MEDiss = 1-cor(MEs, use = 'pairwise.complete.obs')
    #MEDiss = 1-cor(MEs)
    # check valid inputs
    testCheck <- try(
      hclust(as.dist(MEDiss), method = "average"),
      silent = TRUE
    )
    if(class(testCheck) == "try-error"){
      return(NULL)
    }
    # Cluster module eigengenes
    METree = hclust(as.dist(MEDiss), method = "average")
  }
  
  # function to create plot of the clustering of eigengenes
  createPlotEigengenes <- function(){
    # require input data
    req(input$setMEDissThres)
    # check the inputs
    if(is.null(calcEigengenes())) {
      return(NULL)
    }
    # retrieve eigengenes
    METree <- calcEigengenes()
    # retrieve eigengene threshold
    MEDissThres <- input$setMEDissThres
    # Plot the result
    sizeGrWindow(7, 6)
    plot(METree, main = "Clustering of module eigengenes",
         xlab = "", sub = "")
    # Plot the cut line into the dendrogram
    abline(h=MEDissThres, col = "red")
  }
  
  # function to plot the clustering of eigengenes
  output$plotEigengenes <- renderImage({
    # save file
    exportFile <- "clusteringME.png"
    png(file = exportFile, wi = 7, he = 6, units="in", res=150)
    createPlotEigengenes()
    dev.off()
    # Return a list
    list(src = exportFile, alt = "Invalid Results", height = "500px")
  }, deleteFile = TRUE)
  
  # download handler for the eigengenes plot
  output$downloadPlotEigengenes <- downloadHandler(
    filename = function() {
      "clusteringME.png"
    },
    content = function(file) {
      # save the plot
      png(file, wi = 7, he = 6, units="in", res=150)
      createPlotEigengenes()
      dev.off()
    }
  )
  
  # reactive function to merge module colors
  mergeColors <- eventReactive(input$runAnalysis, {
    # require input data
    req(input$setMEDissThres)
    # require valid inputs
    if(is.null(compareSamples())){
      return(NULL)
    }
    # retrieve prepared data
    datExpr <- filterData()
    # retrieve modules
    dynamicColors <- convertLabels()
    # retrieve eigengene threshold
    MEDissThres <- input$setMEDissThres
    # check valid input
    testCheck <- try(
      mergeCloseModules(datExpr, dynamicColors, cutHeight = MEDissThres),
      silent = TRUE
    )
    if(class(testCheck) == "try-error"){
      return(NULL)
    }
    # Call an automatic merging function
    merge = mergeCloseModules(datExpr, dynamicColors, cutHeight = MEDissThres, verbose = 3)
    # The merged module colors
    mergedColors = merge$colors
  })
  
  # reactive function to merge module eigengenes
  mergeEigengenes <- eventReactive(input$runAnalysis, {
    # require input data
    req(input$setMEDissThres)
    # require valid inputs
    if(is.null(compareSamples())){
      return(NULL)
    }
    # retrieve prepared data
    datExpr <- filterData()
    # retrieve modules
    dynamicColors <- convertLabels()
    # retrieve eigengene threshold
    MEDissThres <- input$setMEDissThres
    # check valid input
    testCheck <- try(
      mergeCloseModules(datExpr, dynamicColors, cutHeight = MEDissThres),
      silent = TRUE
    )
    if(class(testCheck) == "try-error"){
      return(NULL)
    }
    # Call an automatic merging function
    merge = mergeCloseModules(datExpr, dynamicColors, cutHeight = MEDissThres, verbose = 3)
    # Eigengenes of the new merged modules:
    mergedMEs = merge$newMEs
  })
  
  # function to create plot of the trimmed dendrogram
  createPlotTrimmedDendro <- function(){
    # check the inputs
    if(is.null(createGeneTree())) {
      return(NULL)
    }else if(is.null(convertLabels())){
      return(NULL)
    }else if(is.null(mergeColors())){
      return(NULL)
    }
    # retrieve gene tree
    geneTree <- createGeneTree()
    # retrieve modules
    dynamicColors <- convertLabels()
    # retrieve merged colors
    mergedColors <- mergeColors()
    # plot the gene dendrogram again, with the 
    # original and merged module colors underneath
    sizeGrWindow(12, 9)
    plotDendroAndColors(geneTree, cbind(dynamicColors, mergedColors),
                        c("Dynamic Tree Cut", "Merged dynamic"),
                        dendroLabels = FALSE, hang = 0.03,
                        addGuide = TRUE, guideHang = 0.05)
  }
  
  # function to plot the trimmed dendrogram
  output$plotTrimmedDendro <- renderImage({
    # save file
    exportFile <- "geneDendro-3.png"
    png(file = exportFile, wi = 12, he = 9, units="in", res=150)
    createPlotTrimmedDendro()
    dev.off()
    # Return a list
    list(src = exportFile, alt = "Invalid Results", height = "700px")
  }, deleteFile = TRUE)
  
  # download handler for the dendrogram plot
  output$downloadPlotTrimmedDendro <- downloadHandler(
    filename = function() {
      "geneDendro-3.png"
    },
    content = function(file) {
      # save the plot
      png(file, wi = 12, he = 9, units="in", res=150)
      createPlotTrimmedDendro()
      dev.off()
    }
  )
  
  # function to retrieve eigengenes
  retrieveEigengenes <- function(){
    # require valid inputs
    if(is.null(mergeColors())){
      return(NULL)
    }else if(is.null(mergeEigengenes())){
      return(NULL)
    }
    # retrieve merged colors
    mergedColors <- mergeColors()
    # retrieve merged eigengenes
    mergedMEs <- mergeEigengenes()
    # Rename to moduleColors
    moduleColors = mergedColors
    # Construct numerical labels corresponding to the colors
    colorOrder = c("grey", standardColors(50));
    moduleLabels = match(moduleColors, colorOrder)-1;
    MEs = mergedMEs;
  }
  
  # function to retrieve eigengene expression values
  eigengeneExpression <- eventReactive(input$runAnalysis, {
    # retrieve prepared data
    datExpr0 <- filterData()
    # retrieve module eigengenes
    MEs <- retrieveEigengenes()
    # transpose each subset
    datExpr0 = data = as.data.frame(t(MEs))
    names(datExpr0) = rownames(MEs)
    rownames(datExpr0) = names(MEs)
    # add a column for the row names
    datExpr0 <- cbind(gene = rownames(datExpr0), datExpr0)
    rownames(datExpr0) <- NULL
    # return expression data
    datExpr0
  })
  
  
  ##
  # Analysis Results
  ##
  
  # function to map genes with module information
  mapResults <- function(){
    # require valid inputs
    if(is.null(filterData())){
      return(NULL)
    }else if(is.null(mergeColors())){
      return(NULL)
    }
    # retrieve prepared data
    datExpr <- filterData()
    # retrieve merged colors
    mergedColors <- mergeColors()
    # Rename to moduleColors
    moduleColors = mergedColors
    # Construct numerical labels corresponding to the colors
    colorOrder = c("grey", standardColors(50));
    moduleLabels = match(moduleColors, colorOrder)-1;
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
    # return results
    resultsTable
  }
  
  # download table with eigengene expression data
  output$geneDownload <- downloadHandler(
    # retrieve file name
    filename = function() {
      # setup output file name
      paste("geneModules", "csv", sep = ".")
    },
    # read in data
    content = function(file) {
      # retrieve eigengene expression data
      resultsTable <- mapResults()
      # output table
      write.table(resultsTable, file, sep=",", row.names=FALSE, quote=FALSE)
    }
  )
  
  # download table with eigengene expression data
  output$eigengeneDownload <- downloadHandler(
    # retrieve file name
    filename = function() {
      # setup output file name
      paste("eigengeneExpression", "csv", sep = ".")
    },
    # read in data
    content = function(file) {
      # retrieve eigengene expression data
      datExpr0 <- eigengeneExpression()
      # output table
      write.table(datExpr0, file, sep=",", row.names=FALSE, quote=FALSE)
    }
  )
  
}

#### App Object ####

# create the Shiny app object 
shinyApp(ui = ui, server = server)
