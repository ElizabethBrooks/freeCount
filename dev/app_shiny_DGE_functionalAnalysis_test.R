# created by: Elizabeth Brooks
# last update: 24 October 2023

#### Setup ####

# load packages
library(shiny)
library(shinythemes)
library(topGO)
library(ggplot2)
library(Rgraphviz)
library(tidyr)
library(rcartocolor)

# the following setting is important, do not omit.
options(stringsAsFactors = FALSE)

# plotting palette
plotColors <- carto_pal(12, "Safe")
plotColorSubset <- c(plotColors[5], plotColors[6])

#### UI ####

# Define UI 
ui <- fluidPage(
  # view available themes
  #shinythemes::themeSelector(),
  
  # use a theme
  theme = shinytheme("yeti"),
  #theme = shinytheme("superhero"),
  
  # add application title
  titlePanel("Gene Ontology (GO) Term Enrichment Analysis with topGO"),
  
  # setup sidebar layout
  sidebarLayout(
    
    # setup sidebar panel
    sidebarPanel(
      
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
      ),
      # show panel depending on input files check
      conditionalPanel(
        condition = "output.dataUploaded && !input.runUpload",
        tags$hr(),
        tags$p(
          "Click to Upload Data:"
        ),  
        actionButton("runUpload", "Upload")
      ),
      # show panel depending on input files check
      conditionalPanel(
        condition = "output.dataUploaded && input.runUpload",
        tags$hr(),
        tags$p(
          "Click to Run Analysis:"
        ),  
        actionButton("runAnalysis", "Run Analysis")
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
          HTML("<ul><li><i>FDR</i> from DGE</li></ul>")
        ),
        tags$p(
          HTML("<ul><li>module <i>number</i> from WGCNA</li></ul>")
        ),
        tags$p(
          HTML("<b>2.</b> entering the expression for gene scoring, for example:")
        ),
        tags$p(
          HTML("<ul><li><i>< 0.05</i> for specifying significant DEGs using a <i>FDR</i> cut off</li></ul>")
        ),
        tags$p(
          HTML("<ul><li><i>== 1</i> for specifying a specific module <i>number</i> from WGCNA</li></ul>")
        ),
        tags$p(
          HTML("<b>3.</b> uploading a gene score table <i>.csv</i> file with the <i>unfiltered</i> results table from DGE or WGCNA")
        ),
        tags$p(
          HTML("<b>4.</b> uploading a mappings table <i>.txt</i> file with the gene-to-GO term mappings, in which:")
        ),
        tags$p(
          HTML("<ul><li>the first column is expected to contain gene IDs and the second column GO terms</li></ul>")
        ),
        tags$p(
          HTML("<ul><li>the second column of GO terms is expected to be in a comma separated list format</li></ul>")
        ),
        tags$p(
          HTML("<ul><li>the first column is expected to be tab separated from the second column</li></ul>")
        ),
        tags$p(
          HTML("<b>5.</b> clicking the <i>Upload</i> button to check that the inputs are valid")
        ),
        tags$p(
          HTML("<b>6.</b> clicking the <i>Run Analysis</i> button")
        ),
        tags$br(),
        tags$p(
          "Note that the GO term enrichment analysis results and plots may take several moments to process depending on the size of the input tables."
        ),
        tags$hr(),
        tags$p(
          align="center",
          HTML("<b>Helpful Tips</b>")
        ),
        tags$p(
          HTML("<b>Tip 1:</b> It is possible to create a gene-to-GO term mapping file by uploading a list of protein sequences in the <i>Annotate</i> tab of "),
          tags$a("PANNZER",href = "http://ekhidna2.biocenter.helsinki.fi/sanspanz/"),
          "."
        ),
        tags$p(
          HTML("<b>Tip 2:</b> The input gene score table should <i>not</i> be filtered in advance."),
          "The enrichment analysis requires the complete gene universe, which includes all genes detected in the experiment regardless of signifigance in DGE or WGCNA."
        ),
        tags$p(
          HTML("<b>Tip 3:</b> The input gene score statistic <i>must match</i> the name of a column in the input gene score table.")
        ),
        tags$p(
          HTML("<b>Tip 4:</b> The first column of the gene score table is expected to contain gene IDs.")
        ),
        tags$p(
          HTML("<b>Tip 5:</b> The gene score tables are required to contain two columns with gene IDs and gene scores at <i>minimum</i>.")
        ),
        #tags$p(
          #HTML("<b>Tip 6:</b> Make sure to set the FDR cut off in your DGE analysis <i>equal to 1</i> before downloading the results.")
        #),
        tags$hr(),
        tags$p(
          align="center",
          HTML("<b>Data Formatting</b>")
        ),
        tags$p(
          "Example gene score and mappings tables are displayed below."
        ),
        tags$br(),
        tags$p(
          HTML("<b>Example</b> gene to GO term mappings for four genes:"),
          tableOutput(outputId = "exampleMappings") 
        ),
        tags$br(),
        fluidRow(
          column(
            width = 6,
            tags$p(
              HTML("<b>Example</b> gene score table for five genes scored by DGE analysis:"),
              tableOutput(outputId = "exampleDGEScore")
            )
          ),
          column(
            width = 6,
            tags$p(
              HTML("<b>Example</b> gene score table for three genes scored by WGCNA:"),
              tableOutput(outputId = "exampleWGCNAScore")
            )
          )
        ),
        tags$br(),
        fluidRow(
          column(
            width = 6,
            tags$p(
              HTML("<b>Example</b> gene score table with minimum expected columns for five genes scored by DGE analysis:"),
              tableOutput(outputId = "exampleDGEScoreSubset") 
            )
          ),
          column(
            width = 6,
            tags$p(
              HTML("<b>Example</b> gene score table with minimum expected columns for three genes scored by WGCNA:"),
              tableOutput(outputId = "exampleWGCNAScoreSubset") 
            )
          )
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
          "The GO term enrichment analysis results and plots may take several moments to process depending on the size of the input normalized gene tables."
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
              HTML("<b>Tip 1:</b> The results may take several moments to appear depending on the size of the input data tables.")
            ),
            tags$p(
              HTML("<b>Tip 2:</b> Valid statistic for gene scoring include <i>FDR</i> from DGE or module <i>number</i> from WGCNA, and must be the same name as a column in the input gene score table.")
            ),
            tags$p(
              HTML("<b>Tip 3:</b> Valid expressions for gene scoring include:")
            ),
            tags$p(
              align = "center",
              HTML("<b>< 0.05</b> for specifying significant DEGs using a <i>FDR</i> cut off")
            ),
            tags$p(
              align = "center",
              HTML("<b>== 1</b> for specifying a specific module <i>number</i> from WGCNA")
            )
          ),
          
          # Enrichment tab
          tabPanel(
            "Enrichment",
            tags$br(),
            tags$p(
              align = "center",
              HTML("<b>GO Term Enrichment</b>")
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
                  selected = "weight01"
                ),
                #tags$br(),
                tags$p(
                  HTML("<b>Available Algorithms:</b>")
                ),
                tags$p(
                  HTML("<b>1.</b> Default algorithm used by the topGO package is a mixture between the <i>elim</i> and <i>weight</i> algorithms.")
                ),
                tags$p(
                  HTML("<b>2.</b> Classic algorithm performs enrichment analysis by testing the over-representation of GO terms within the group of diferentially expressed genes.")
                ),
                tags$p(
                  HTML("<b>3.</b> Elim algorithm is more conservative then the classic method and you may expect the p-values returned by the former method to be lower bounded by the p-values returned by the later method.")
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
                  selected = "fisher"
                ),
                tags$br(),
                tags$p(
                  HTML("<b>Available Test Statistics:</b>")
                ),
                tags$p(
                  HTML("<b>1.</b> Fisher's exact test is based on gene counts")
                ),
                tags$p(
                  HTML("<b>2.</b> Kolmogorov-Smirnov like test computes enrichment based on gene scores")
                ),
                tags$p(
                  "It is possible to use both the above tests since each gene has a score, which represents how it is diferentially expressed."
                )
              )
            ),
            tags$br(),
            tags$p(
              HTML("<b>Tip:</b> refer to the "),
              tags$a("topGO", href = "https://bioconductor.org/packages/devel/bioc/vignettes/topGO/inst/doc/topGO.pdf"),
              " manual for a description of the algorithms and test statistics."
            ),
            # TO-DO: output table of top GO term IDs
            tags$hr(),
            tags$p(
              align = "center",
              HTML("<b>Range of GO Term P-Values</b>")
            ),
            tags$br(),
            fluidRow(
              column(
                width = 4,
                plotOutput(outputId = "BPHist"),
                downloadButton(outputId = "downloadBPHist", label = "Download Plot")
              ),
              column(
                width = 4,
                plotOutput(outputId = "MFHist"),
                downloadButton(outputId = "downloadMFHist", label = "Download Plot")
              ),
              column(
                width = 4,
                plotOutput(outputId = "CCHist"),
                downloadButton(outputId = "downloadCCHist", label = "Download Plot")
              )
            ),
            tags$p(
              "The above histograms show the range and frequency of p-values from the enrichment tests for each GO level (BP, MF, or CC)."
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
                  "Select GO Term Category:"
                ),
                radioButtons(
                  inputId = "ontologyCategory",
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
                  "Enter GO Term ID:"
                ),
                textInput(
                  inputId = "ontologyTerm",
                  label = NULL,
                  value = "GO:0008150"
                )
              )
            ),
            tags$br(),
            tags$p(
              align = "center",
              HTML("<b>Helpful Tips</b>")
            ),
            tags$p(
              HTML("<b>Tip 1:</b> only significant GO terms may be plotted.")
            ),
            tags$p(
              HTML("<b>Tip 2:</b> make sure that the GO category is valid for the input GO term ID.")
            ),
            tags$br(),
            conditionalPanel(
              condition = "output.densityResultsCompleted",
              tags$br(),
              tags$p(
                align = "center",
                HTML("<b>Density Plot</b>")
              ),
              plotOutput(outputId = "densityPlot"),
              downloadButton(outputId = "downloadDensity", label = "Download Plot"),
              tags$br(),
              tags$p(
                "The above density plot shows the distribution of the gene's rank for the top GO term of each GO level (BP, MF, or CC). The gene's rank is compared with the null distribution."
              )
            ),
            tags$hr(),
            tags$p(
              align = "center",
              HTML("<b>Dot Plot of Most Significant GO Terms</b>")
            ),
            tags$br(),
            tags$p(
              "Select P-Value Cut Off:"
            ),
            sliderInput(
              "fisherCut",
              label = NULL,
              min = 0, 
              max = 0.1, 
              value=0.05 
            ),
            tags$p(
              "Note that the computed p-values are unadjusted for multiple testing."
            ),
            tags$br(),
            plotOutput(outputId = "dotPlot"),
            downloadButton(outputId = "downloadDotPlot", label = "Download Plot"),
            tags$p(
              HTML("The above dot plot shows the <i>up to the top 5</i> most enriched GO terms for each level (BP, MF, CC). The dots are colored by the enrichment test p-values.")
            ),
            tags$hr(),
            tags$p(
              align = "center",
              HTML("<b>Subgraphs of Most Significant GO Terms</b>")
            ),
            tags$br(),
            fluidRow(
              column(
                width = 6,
                tags$p(
                  "Select GO Term Category:"
                ),
                radioButtons(
                  inputId = "subCategory",
                  label = NULL,
                  choices = c("BP" = "BP",
                              "MF" = "MF",
                              "CC" = "CC"),
                  selected = "BP"
                )
              ),
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
              )
            ),
            tags$br(),
            tags$p(
              HTML("<b>Download Subgraphs:</b>")
            ),
            downloadButton(outputId = "downloadSubgraphs", label = "Download PDF"),
            tags$br(),
            tags$p(
              "The subgraph induced by the selected number of top (most significant) GO terms identifed by the selected algorithm for scoring GO terms for enrichment.",
              "Rectangles indicate the most signifcant terms with colors representing the relative signifcance, which ranges from dark red (most signifcant) to bright yellow (least signifcant).",
            ),
            tags$p(
              HTML("For each <i>node</i>, some basic information is displayed."),
              "The frst two lines show the GO identifer and a trimmed GO name.",
              "In the third line the raw p-value is shown.",
              "The forth line is showing the number of signifcant genes and the total number of genes annotated to the respective GO term."
            )
          ),
            
          # results tab
          tabPanel(
            "Results",
            tags$br(),
            tags$p(
              align="center",
              HTML("<b>Enrichment Results</b>")
            ),
            tags$br(),
            fluidRow(
              column(
                width = 6,
                tags$p(
                  "Select GO Term Category:"
                ),
                radioButtons(
                  inputId = "resultsCategory",
                  label = NULL,
                  choices = c("BP" = "BP",
                              "MF" = "MF",
                              "CC" = "CC"),
                  selected = "BP"
                )
              ),
              column(
                width = 6,
                tags$p(
                  "Select P-Value Cut Off:"
                ),
                sliderInput(
                  "sigCut",
                  label = NULL,
                  min = 0, 
                  max = 0.1, 
                  value=0.05 
                ),
                tags$p(
                  "Note that the computed p-values are unadjusted for multiple testing."
                )
              )
            ),
            tags$br(),
            tags$p(
              "Results from the GO term enrichment analysis may be downloaded below."
            ),
            tags$p(
              HTML("<b>Table of Enriched GO Terms</b>")
            ),
            downloadButton(outputId = "resultsDownload", label = "Download Table"),
            tags$br(),
            tags$p(
              "The unfiltered list of enriched GO terms for the selected ontology category."
            ),
            tags$br(),
            tags$p(
              HTML("<b>Table of Significantly Enriched GO Terms</b>")
            ),
            downloadButton(outputId = "sigDownload", label = "Download Table"),
            tags$br(),
            tags$p(
              "The list of significantly enriched GO terms filtered by the input p-value cut off and for the selected ontology category."
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
              "This application for GO term enrichment analysis was created by ",
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
              "DGE gene scores (e.g., FDR) may be created from RNA-seq data as described in ", 
              tags$a("Bioinformatics Analysis of Omics Data with the Shell & R", href = "https://morphoscape.wordpress.com/2022/07/28/bioinformatics-analysis-of-omics-data-with-the-shell-r/"), 
              "."
            ),
            tags$p(
              "More information about the analysis performed in this application is provided in ", 
              tags$a("Gene set enrichment analysis with topGO", href = "https://bioconductor.org/packages/devel/bioc/vignettes/topGO/inst/doc/topGO.pdf"), 
              "."
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
  output$exampleDGEScore <- renderTable({
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
  output$exampleDGEScoreSubset <- renderTable({
    # create example score table
    exScoreTable <- data.frame(
      Gene = c("gene-1", "gene-2", "gene-3", "gene-4", "gene-5"),
      FDR = c(0.435362017290981,0.451205836761818,0.451205836761818,0.451205836761818,0.451205836761818)
    )
  })
  
  # render example gene score table
  output$exampleWGCNAScore <- renderTable({
    # create example score table
    exScoreTable <- data.frame(
      gene = c("geneA", "geneB", "geneC"),
      color = c("brown","brown","brown"),
      number = c(1,1,1)
    )
  })
  
  # render example gene score table subset
  output$exampleWGCNAScoreSubset <- renderTable({
    # create example score table
    exScoreTable <- data.frame(
      gene = c("geneA", "geneB", "geneC"),
      number = c(1,1,1)
    )
  })
  
  # render first example mappings table
  output$exampleMappings <- renderTable({
    # create example mappings table
    exMappingsTable <- data.frame(
      Gene = c("geneA", "geneB", "geneC", "geneD"),
      Terms = c("GO:0005730,GO:0030490", "GO:0006890,GO:0030173,GO:0005783,GO:0006621", "GO:0006355", "GO:0005739,GO:0008203,GO:0006744,GO:0015039")
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
    # read the file
    GOmaps <- readMappings(file = input$mappings$datapath)
    # return data
    GOmaps
  })
  
  # check if file has been uploaded
  output$dataUploaded <- function(){
    # check the input tables are not null
    if(is.null(inputAnalysisTable())){
      return(FALSE)
    }else if(is.null(inputMappings())){
      return(FALSE)
    }
    return(TRUE)
  }
  outputOptions(output, 'dataUploaded', suspendWhenHidden=FALSE)
  
  # update input ontology term
  observeEvent(input$runAnalysis, {
    # retrieve top BP term
    tmpTerm <- getSigTerm("BP")
    # update input
    updateTextInput(
      session,
      inputId = "ontologyTerm",
      value = tmpTerm
    )
  })
  
  
  ## 
  # GO Enrichment
  ##
  
  # function to create gene universe
  createUniverse <- eventReactive(input$runAnalysis, {
    # require input
    req(input$scoreStat)
    # check for inputs
    if(is.null(inputAnalysisTable())){
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
    # return list
    list_genes_filtered
  })
  
  # TO-DO: fix evaluation of strings (e.g., == brown)
  # TO-DO: test the validity of the input expression for error handling
  # function to retrieve interesting genes
  retrieveInteresting <- function(){
    # function that returns list of interesting DE genes (0 == not significant, 1 == significant)
    get_interesting_DE_genes <- function(geneUniverse){
      interesting_DE_genes <- rep(0, length(geneUniverse))
      for(i in 1:length(geneUniverse)){
        if(eval(parse(text = paste(geneUniverse[1], input$universeCut, sep=" ")))){
          interesting_DE_genes[i] = 1
        }
      }
      interesting_DE_genes <- setNames(interesting_DE_genes, names(geneUniverse))
      return(interesting_DE_genes)
    }
  }
  
  # function to create BP, MF, or CC topGOdata objects
  createOntology <- function(ontologyID){
    # TO-DO: this causes additional function calls
    # require valid input
    if(is.null(createUniverse())){
      return(NULL)
    }
    # retrieve gene universe
    list_genes_filtered <- createUniverse()
    # retrieve go mappings
    GO_maps <- inputMappings()
    # create topGOdata objects for enrichment analysis (1 for each ontology)
    GO_data <- new('topGOdata', ontology = ontologyID, allGenes = list_genes_filtered, 
                    geneSel = retrieveInteresting(), nodeSize = 10, annot = annFUN.gene2GO, 
                    gene2GO = GO_maps)
  }
  
  # TO-DO: this causes additional function calls
  # check if results are complete
  output$resultsCompleted <- function(){
    if(is.null(createOntology("BP"))){
      return(FALSE)
    }
    return(TRUE)
  }
  outputOptions(output, 'resultsCompleted', suspendWhenHidden=FALSE, priority=0)
  
  # function to perform BP, MF, or CC GO enrichment 
  performGO <- function(ontologyID){
    # require inputs
    req(input$testAlg, input$testStat)
    # retrieve topGOdata object
    GO_data <- createOntology(ontologyID)
    # perform GO enrichment using the topGOdata objects
    GOResults <- runTest(GO_data, algorithm = input$testAlg, statistic = input$testStat)
  }
  
  # function to create BP, MF, or CC p-value histogram
  createPHist <- function(ontologyID){
    # retrieve results
    GOResults <- performGO(ontologyID)
    # store p-values as named list...
    pvalGO <- score(GOResults)
    # create title
    titleName <- paste("Range of", ontologyID, "P-Values", sep=" ")
    # plot histogram to see range of p-values
    hist(pvalGO, 35, xlab = "p-values", main = titleName)
  }
  
  # render BP p-value histogram
  output$BPHist <- renderPlot({
    # create the plot
    createPHist("BP")
  })
  
  # download handler for the BP histogram
  output$downloadBPHist <- downloadHandler(
    filename = function() {
      "pValueRanges_BP.png"
    },
    content = function(file) {
      # save the plot
      png(file, width = 12, height = 9, units="in", res=150)
      createPHist("BP")
      dev.off()
    }
  )
  
  # render MF p-value histogram
  output$MFHist <- renderPlot({
    # create the plot
    createPHist("MF")
  })
  
  # download handler for the MF histogram
  output$downloadMFHist <- downloadHandler(
    filename = function() {
      "pValueRanges_MF.png"
    },
    content = function(file) {
      # save the plot
      png(file, width = 12, height = 9, units="in", res=150)
      createPHist("MF")
      dev.off()
    }
  )
  
  # render CC p-value histogram
  output$CCHist <- renderPlot({
    # create the plot
    createPHist("CC")
  })
  
  # download handler for the CC histogram
  output$downloadCCHist <- downloadHandler(
    filename = function() {
      "pValueRanges_CC.png"
    },
    content = function(file) {
      # save the plot
      png(file, width = 12, height = 9, units="in", res=150)
      createPHist("CC")
      dev.off()
    }
  )
  
  # function to plot BP, MF, or CC subgraphs
  createSubgraphs <- function(ontologyID, ontologyNodes){
    # retrieve topGOdata object
    GO_data <- createOntology(ontologyID)
    # retrieve results
    GOResults <- performGO(ontologyID)
    # plot subgraphs induced by the most significant GO terms
    printGraph(GO_data, GOResults, firstSigNodes = ontologyNodes, 
               fn.prefix = paste(ontologyID, "sigGO_subgraphs", sep="_"), useInfo = "all", pdfSW = TRUE)
  }
  
  # download button for PDFs of subgraphs
  output$downloadSubgraphs <- downloadHandler(
    filename = function() {
      "sigGO_subgraphs_BP_weight01_5_all.pdf"
    },
    content = function(file) {
      # require inputs
      req(input$subCategory, input$sigNodes)
      # create subgraph PDFs
      createSubgraphs(input$subCategory, input$sigNodes)
    }
  )
  
  # function to get statistics on BP, MF, or CC GO terms
  getResults <- function(ontologyID){
    # retrieve topGOdata object
    GO_data <- createOntology(ontologyID)
    # retrieve results
    GO_Results <- performGO(ontologyID)
    # retrieve statistics
    list_GO_terms <- usedGO(GO_data)
    # retrieve results table
    GO_Results_table <- GenTable(GO_data, weightFisher = GO_Results, orderBy = 'weightFisher', 
                                    topNodes = length(list_GO_terms))
  }
  
  # function to get significant BP, MF, or CC GO terms
  getSigResults <- function(ontologyID, sigCutOff){
    # retrieve stats
    GO_Results_table <- getResults(ontologyID)
    # create table of significant GO terms
    sigGO_Results_table <- GO_Results_table[GO_Results_table$weightFisher <= sigCutOff, ]
  }
  
  # function to get results for selected the top BP, MF, or CC GO terms
  getSigTerm <- function(ontologyID){
    # retrieve stats
    GO_results_table <- getResults(ontologyID)
    # retrieve results for selected GO term
    topSigID <- GO_results_table[1, 'GO.ID']
  }
  
  # function to get results for selected BP, MF, or CC GO terms
  getTerm <- function(ontologyID, termID){
    # retrieve stats
    GO_results_table <- getResults(ontologyID)
    # retrieve results for selected GO term
    topSigID <- GO_results_table[GO_results_table$GO.ID == termID,1]
  }
  
  # function to create BP, MF, or CC density plots
  # default is most sig GO term
  createDensity <- function(ontologyID, termID){
    # retrieve topGOdata object
    GO_data <- createOntology(ontologyID)
    # retrieve term results
    termResults <- getTerm(ontologyID, termID)
    # create density plot
    showGroupDensity(GO_data, whichGO = termResults, ranks = TRUE)
  }
  
  # TO-DO: this causes additional function calls
  # check if results have completed
  output$densityResultsCompleted <- function(){
    if(is.null(createDensity(input$ontologyCategory, input$ontologyTerm))){
      return(FALSE)
    }
    return(TRUE)
  }
  outputOptions(output, 'densityResultsCompleted', suspendWhenHidden=FALSE, priority=0)
  
  # render density plot
  output$densityPlot <- renderPlot({
    # require inputs
    req(input$ontologyCategory, input$ontologyTerm)
    # create plot
    createDensity(input$ontologyCategory, input$ontologyTerm)
  })
  
  # download handler for the density plot
  output$downloadDensity <- downloadHandler(
    filename = function() {
      paste(input$ontologyCategory, input$ontologyTerm, "density.png", sep = "_")
    },
    content = function(file) {
      # require inputs
      req(input$ontologyCategory, input$ontologyTerm)
      # save the plot
      png(file, width = 12, height = 9, units="in", res=150)
      createDensity(input$ontologyCategory, input$ontologyTerm)
      dev.off()
    }
  )
  
  # function to format data for use with dot plots
  # default it top 5 most significant GO terms
  dotPlotSigData <- eventReactive(input$runAnalysis, {
    # require inputs
    req(input$fisherCut)
    # retrieve ontology result tables
    BPTable <- getSigResults("BP", input$fisherCut)
    MFTable <- getSigResults("MF", input$fisherCut)
    CCTable <- getSigResults("CC", input$fisherCut)
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
  })
  
  # function to create dot plots
  createDotPlot <- function(){
    # retrieve formatted data
    plotTable <- dotPlotSigData()
    # create faceting by ontology
    facet <- factor(plotTable$ID, levels = c('BP', 'CC', 'MF'))
    # create dot plot
    dotplot <- ggplot(data = plotTable, aes(x = "Enrichment", y = Term, size = Significant, color = as.numeric(weightFisher))) + 
      facet_grid(rows = facet, space = 'free_y', scales = 'free') +
      geom_point() +
      #scale_color_gradientn(colors = heat.colors(10), limits=c(0, 0.05)) + 
      scale_color_gradientn(colors = plotColorSubset) +
      #scale_x_discrete(guide = guide_axis(angle = 90)) +
      theme_bw() +
      xlab('Score') +
      ylab('GO Term') + 
      #scale_x_discrete(labels=c("Interaction"=expression(italic("Interaction")), parse=TRUE)) +
      labs(color = 'P-Value', size = 'Gene Rank')
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
  output$resultsDownload <- downloadHandler(
    # retrieve file name
    filename = function() {
      # setup output file name
      paste(input$resultsCategory, "GO_terms.csv", sep = "_")
    },
    # read in data
    content = function(file) {
      # require input
      req(input$resultsCategory)
      # retrieve results
      GO_results_table <- getResults(input$resultsCategory)
      # write table of GO terms to a CSV file
      write.table(GO_results_table, file, sep=",", row.names=FALSE, quote=FALSE)
    }
  )
  
  # function to download table of significant results
  output$sigDownload <- downloadHandler(
    # retrieve file name
    filename = function() {
      # setup output file name
      paste(input$resultsCategory, input$sigCut, "sigGO_terms.csv", sep = "_")
    },
    # read in data
    content = function(file) {
      # require input
      req(input$resultsCategory, input$sigCut)
      # retrieve significant results
      sigGO_results_table <- getSigResults(input$resultsCategory, input$sigCut)
      # write table of significant GO terms to a CSV file
      write.table(sigGO_results_table, file, sep=",", row.names=FALSE, quote=FALSE)
    }
  )
  
}

#### App Object ####

# create the Shiny app object 
shinyApp(ui = ui, server = server)
          
          