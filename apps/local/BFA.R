# developer: Elizabeth Brooks
# updated: 24 April 2026

#### Setup ####

# increase max uploadable file size to from the default 5MB to 30MB
options(shiny.maxRequestSize=30*1024^2)

# install any missing packages
packageList <- c("BiocManager", "shiny", "bslib", "shinyWidgets", "ggplot2", 
                 "rcartocolor", "tidyr", "eulerr")
biocList <- c("topGO", "Rgraphviz")
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
#scoreStat, #universeCut {
  border-color: #f3969a;
  border-width: 2px;
  border-style: solid;
}
"

# setup defaults
defaultAlg <- "weight01"
defaultStat <- "fisher"
defaultP <- 0.05
defaultFile <- NA
defaultTable <- data.frame()
defaultTermOne <- "GO:0008150"

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
     fluidRow(
       column(
         width = 6,
         tags$p(
           HTML("&emsp;"),
           "freeCount BFA",
           tags$i(
             class = "fa fa-layer-group",
             style = "color: white"
           ),
           tags$i(
             class = "fa fa-plus",
             style = "color: white"
           ),
           style = "
            font-family: Georgia, Arial, sans-serif;
            color: white
            "
         )
       ),
       column(
         width = 6, 
         align = "right",
         "Batch Functional Analysis", 
         HTML("&emsp;"),
         style = "
          font-family: Georgia, Arial, sans-serif;
          color: white
        "
       ),
       style = "
          margin-top: 14px;
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
          border-width: 8px; 
          border-style: solid;
          border-radius: 25px
      ",
      # inputs
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
        "Upload the Batch of Gene Score Tables (*.csv):"
      ),
      fileInput(
        "fileList", 
        "Select File(s)", 
        multiple = TRUE,
        accept = ".csv"
      ),
      tags$p(
        "Upload Mappings Table (*.txt or *.csv):"
      ),
      fileInput(
        "mappings", 
        label = NULL,
        multiple = FALSE,
        accept = "text"
      ),
      tags$hr(),
      tags$p(
        "Click to Run Analysis:"
      ),  
      actionButton("runAnalysis", "Run Analysis"),
      # show panel depending on analysis run
      conditionalPanel(
        condition = "input.runAnalysis",
        tags$p(
          "Current Analysis Settings:"
        ), 
        tableOutput(outputId = "inputSettings")
      )
    ),
    
    # setup the main panel
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
          HTML("<b>1.</b> entering the statistic for gene scoring:")
        ),
        tags$p(
          HTML("<ul><li><i>FDR</i> (edgeR) or <i>padj</i> (DESeq2) for DE analysis results</li></ul>")
        ),
        tags$p(
          HTML("<ul><li><i>number</i> of the module for WGCNA results</li></ul>")
        ),
        tags$p(
          HTML("<b>2.</b> entering the expression for gene scoring:")
        ),
        tags$p(
          HTML("<ul><li><i><0.05</i> for specifying significantly DE genes using a <i>FDR</i> or <i>padj</i> cut off</li></ul>")
        ),
        tags$p(
          HTML("<ul><li><i>== 1</i> for specifying one module <i>number</i> from the WGCNA</li></ul>")
        ),
        tags$p(
          HTML("<b>3.</b> uploading a batch of gene score tables <i>.csv</i> with the <i>unfiltered</i> results table from DE analysis or WGCNA")
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
        tags$p(
          HTML("<b>5.</b> clicking the <i>Run Analysis</i> button")
        ),
        tags$br(),
        tags$p(
          "Note that the functional analysis results and plots may take several moments to process depending on the size of the input data tables."
        ),
        tags$hr(),
        tags$p(
          align="center",
          HTML("<b>Helpful Tips</b>")
        ),
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
        )
      ),
      
      #  processing text
      conditionalPanel(
        condition = "input.runAnalysis && !output.resultsCompleted",
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
        tags$p(
          "The functional analysis results and plots may take several moments to process depending on the size of the input tables."
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
            tags$h1(
              align="center",
              "Functional Analysis",
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
              "Begin the functional enrichment or over-representation analysis by selecting a file, test statistic, algorithm, and p-value cut off."
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
                  "Click to Run Analysis:"
                ),  
                actionButton("inputsUpdate", "Analyze")
              )
            ),
            tags$p(
              "Note that the computed p-values are unadjusted for multiple testing."
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
            tags$hr(),
            tags$p(
              "Keep in mind that the plots and results may take several moments to update depending on the size of the input data tables."
            )
          ),
          
          # Results tab
          tabPanel(
            "Results",
            tags$h1(
              align="center",
              "Results",
              style = "
                color: white; 
                background: #78c2ad;
                font-size: x-large;
                font-family: Georgia, Arial, sans-serif;
                border-color: #78c2ad;
                border-width: 4px;
                border-style: solid;
                border-radius: 25px
              "
            ),
            tags$p(
              align="center",
              HTML("<b>Select File for Analysis</b>")
            ),
            fluidRow(
              column(
                width = 6,
                tags$p(
                  "Select a File:"
                ),
                selectInput(inputId = "analysisTable", 
                            label = "Select a File:", 
                            choices = defaultFile
                )
              ),
              column(
                width = 6,
                tags$p(
                  "Click to Run Analysis:"
                ),  
                actionButton("fileUpdate", "Analyze")
              )
            ),
            tags$hr(),
            tags$p(
              align="center",
              HTML("<b>Table of Top 5 BP Results</b>")
            ),
            DT::DTOutput("topTermsBP")
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
                border-radius: 25px
              "
            ),
            tags$p(
              "The latest version of this application may be downloaded from the freeCount ",
              tags$a("GitHub",href = "https://github.com/ElizabethBrooks/freeCount"),
              "."
            ),
            tags$p(
              "Example sets of gene IDs are also provided on",
              tags$a("GitHub", href = "https://github.com/ElizabethBrooks/freeCount/tree/main/data/BI"),
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
  # view and adjust themes
  #bs_themer()
  
  ##
  # Data Setup
  ##
  
  # setup reactive values for settings
  algVal <- reactiveVal(defaultAlg)
  statVal <- reactiveVal(defaultStat)
  pVal <- reactiveVal(defaultP)
  fileVal <- reactiveVal(defaultFile)
  fileTable <- reactiveVal(defaultTable)
  inputAnalysisTable <- reactiveVal(defaultTable)
  inputMappings <- reactiveVal(defaultTable)
  
  # function to set the input file name
  observeEvent(input$fileList, {
    # require input data
    req(input$fileList)
    # create file table
    inputFiles <- data.frame(
      name = input$fileList$name,
      path = input$fileList$datapath
    )
    # update file table
    fileTable(inputFiles)
    # read data
    fileVal(inputFiles$name[1])
  })
  
  # function to read the input files
  observeEvent(input$runAnalysis, {
    # read data
    inputAnalysisTable(retrieveAnalysisTable())
    inputMappings(retrieveMappings())
  })
  
  # function to create gene universe
  observeEvent(input$inputsUpdate, {
    # require input data
    req(input$analysisTable, input$testAlg, input$testStat, input$pValCut)
    # update settings
    fileVal(input$analysisTable)
    algVal(input$testAlg)
    statVal(input$testStat)
    pVal(input$pValCut)
  })
  
  # function to update gene universe
  observeEvent(input$fileUpdate, {
    # require input data
    req(input$analysisTable)
    # update file
    fileVal(input$analysisTable)
  })
  
  # function to retrieve input data two
  retrieveAnalysisTable <- function(){
    # retrieve the input files
    inputFiles <- fileTable()
    # TO-DO: add note about first column is expected to contain gene names
    selectedFile <- inputFiles[inputFiles$name == fileVal(), "path"]
    # read the file
    #dataTableInput <- read.csv(file = paste(filePath(), fileVal(), sep="/"), row.names = 1)
    dataTableInput <- read.csv(file = selectedFile, row.names = 1)
    # check if the input table contains the selected gene score
    if(!(input$scoreStat %in% colnames(dataTableInput))){
      return(NULL)
    }
    # return data
    dataTableInput
  }
  
  # function to retrieve input data one
  retrieveMappings <- function(){
    # require input data
    req(input$mappings)
    # check the input table is not null
    if(is.null(input$mappings)){
      return(NULL)
    }
    # TO-DO: double check reading in tab delimited pannzer2 outputs
    # Error in read.table: "more columns than column names" with sep = "", but not with sep = "\t"
    # No enrichment can pe performed - there are no feasible GO terms!
    # read in the file
    GOmaps_input <- suppressWarnings(read.delim(file = input$mappings$datapath, sep = "\t", row.names=NULL, colClasses = c(goid = "character")))
    #GOmaps_input <- suppressWarnings(read.delim(file = input$mappings$datapath, sep = "", row.names=NULL, colClasses = c(goid = "character")))
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
      # TO-DO: double check outputting of GO:GO: instead of GO:
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
  }
  
  # render table with input settings
  output$inputSettings <- renderTable({
    # create table with factor levels
    settings <- data.frame(
      Setting = c("File", "Algorithm", "Statistic", "PValue"),
      Value = c(fileVal(), algVal(), statVal(), pVal())
    )
    # return the settings data frame
    settings
  })
  
  ## 
  # Analysis Setup
  ##
  
  # setup reactive gene universe values
  geneUniverse <- reactiveValues(list_data = NULL)
  
  # function to initialize data
  observeEvent(input$runAnalysis, {
    # require input
    req(input$scoreStat)
    req(input$fileList)
    # retrieve the input files
    inputFiles <- fileTable()
    # update file list
    updateSelectInput(
      session, 
      "analysisTable",
      choices = inputFiles$name,
      selected = inputFiles$name[1],
    )
    # read data
    inputAnalysisTable(retrieveAnalysisTable())
    inputMappings(retrieveMappings())
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
        if (is.na(geneUniverse[i])) {
          interesting_DE_genes[i] = 0
        }else if(eval(parse(text = paste(geneUniverse[i], input$universeCut, sep=" ")))){
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
  observeEvent(list(input$runAnalysis, input$inputsUpdate), {
    # update the data
    dataGO_BP$topGO_data <- createGO("BP")
    dataGO_MF$topGO_data <- createGO("MF")
    dataGO_CC$topGO_data <- createGO("CC")
    # update the results
    resultsGO_BP$results_data <- performGO(dataGO_BP$topGO_data)
    resultsGO_MF$results_data <- performGO(dataGO_MF$topGO_data)
    resultsGO_CC$results_data <- performGO(dataGO_CC$topGO_data)
    # update the current file data and results
    dataGO$topGO_data <- dataGO_BP$topGO_data
    resultsGO$results_data <- resultsGO_BP$results_data
  }, ignoreInit = TRUE)
  
  ##
  # Outputs
  ##

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
  
  # render table of top 5 BP GO terms for the selected file
  output$topTermsBP <- DT::renderDataTable({
    # create BP, MF, and CC GO data
    GO_data <- dataGO$topGO_data
    # perform BP, MF, and CC GO analysis
    GO_Results <- resultsGO$results_data
    # retrieve ontology result tables
    resultsTable <- getSigResults(GO_data, GO_Results)
    # subset the table
    resultsTableSubset <- resultsTable[1:5, ]
    # add QuickGO link outs
    resultsTableSubset[,1] <- paste0("<a href='", paste("https://www.ebi.ac.uk/QuickGO/term", resultsTableSubset[,1], sep ="/"), "' target='_blank'>", resultsTableSubset[,1], "</a>")
    # return the table
    DT::datatable(resultsTableSubset, escape=FALSE)
  })
  
  # output the table
  #output$resultsTable <- renderReactable({
  output$resultsTable <- DT::renderDataTable({
    DT::datatable(
      createTable(),
      options = list(
        deferRender = TRUE,
        scrollY = TRUE,
        scrollX = TRUE,
        scroller = TRUE,
        autoWidth = TRUE,
        columnDefs = list(list(width = '10%', targets = c(1,3))
        )))
  }) 
  
}

#### App Object ####

# create the Shiny app object 
shinyApp(ui = ui, server = server)
