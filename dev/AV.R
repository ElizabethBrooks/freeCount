# developer: Elizabeth Brooks
# updated: 22 April 2026

#### Setup ####

# increase max uploadable file size to from the default 5MB to 30MB
options(shiny.maxRequestSize=30*1024^2)

# install any missing packages
packageList <- c("shiny", "bslib", "reactable", "shinyWidgets", 
                 "ggpubr", "multcomp", "rcartocolor","DT")
newPackages <- packageList[!(packageList %in% installed.packages()[,"Package"])]
if(length(newPackages)){
  install.packages(newPackages)
}

# load packages 
suppressPackageStartupMessages({
  library(shiny)
  library(bslib)
  library(reactable)
  library(shinyWidgets)
  library(ggpubr)
  library(multcomp)
  library(rcartocolor)
  library(DT)
})

# TO-DO: double check
# color blind safe plotting palettes
defaultColors <- palette.colors(palette = "Okabe-Ito")
blindColors <- c("#000000", "#999999", "#E69F00", "#56B4E9", "#009E73", 
                       "#F0E442", "#0072B2", "#D55E00", "#CC79A7")
safeColors <- carto_pal(12, "Safe")
plotColors <- c(safeColors, blindColors, defaultColors)

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
defaultPVal <- 0.05
defaultExp <- "NA"
inputExpression <- "NA"
defaultDfTable <- data.frame()
defaultSumSqTable <- data.frame()
defaultMeanSqTable <- data.frame()
defaultFValTable <- data.frame()
defaultPrTable <- data.frame()

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
           "freeCount AV",
           tags$i(
             class = "fa fa-square-root-variable",
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
         "Analysis of Variance", 
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
        actionButton("runAnalysis", "Run Analysis")
      ),
      # show panel depending on input files
      conditionalPanel(
        condition = "input.runAnalysis && output.inputCheck",
        h4("Current Settings", align = "center"),
        tags$hr(),
        tags$b(
          "Contrast:"
        ), 
        tableOutput(outputId = "inputContrast"),
        tags$hr(),
        tags$b(
          "P-Value:"
        ), 
        tableOutput(outputId = "inputPVal")
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
          "Note that the analysis results and plots may take several moments to process depending on the size of the input counts table."
        ),
        tags$hr(),
        tags$p(
          align = "center",
          HTML("<b>Helpful Tips</b>")
        ),
        tags$br(),
        tags$p(
          HTML("<b>Tip 1:</b> The input raw gene counts table is expected to contain <i>numeric</i> values."),
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
        )
      ),
      
      # processing text
      conditionalPanel(
        condition = "output.inputCheck && !output.prepCompleted",
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
        "The analysis results and plots may take several moments to process depending on the size of the input counts and experimental design tables."
      ),
      
      # results text and plots
      conditionalPanel(
        condition = "(input.runAnalysis && output.inputCheck) && output.prepCompleted",
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
              HTML("<b>Tip 1:</b> The plots and results may take several moments to appear depending on the size of the input counts table.")
            ),
            tags$p(
              HTML("<b>Tip 2:</b> Navigate to the <i>Analysis</i>, <i>Data Normalization</i>, <i>Data Exploration</i>, or <i>Results</i> steps by clicking the tabs above.")
            )
          ),
          
          # Analysis tab
          tabPanel(
            "Analysis",
            tags$h1(
              align="center",
              "Analysis of Variance",
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
              "Begin the analysis of variance by entering an expression that specifies the sample to analyze."
            ),
            fluidRow(
              column(
                width = 6,
                tags$p(
                  HTML("<b>Select P-Value Cut Off:</b>")
                ),
                sliderInput(
                  "cutPVal",
                  label=NULL,
                  min = 0, 
                  max = 0.1, 
                  value=defaultPVal 
                )
              ),
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
            tags$p(
              HTML("<b>Click to Analyze:</b>")
            ),  
            actionButton("analysisUpdate", "Analyze"),
            tags$hr(),
            tags$p(
            "Design Factors:"
            ),
            fluidRow(
            align = "center",
            # display input design table
            tableOutput(outputId = "designTable")
            )
          ),
          
          # analysis & results tab
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
                border-radius: 25px;
              "
            ),
            tags$p(
              HTML("Begin the analysis of variance on the <i>Analysis</i> tab by selecting input values and clicking the <i>Analyze</i> button.")
            ),
            tags$p(
              HTML("The inputs may also be adjusted on the <i>Analysis</i> tab and updated by clicking the <i>Analyze</i> button.")
            ),
            # show pairwise results
            conditionalPanel(
              condition = "input.analysisUpdate",
              tags$h1(
                align="center",
                "Analysis of Variance",
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
                condition = "!output.resultsCompleted",
                tags$p(
                  HTML("<b>Note</b> that results will not appear if there are invalid input values (e.g., dispersions).")
                )
              ),
              # show pairwise results
              conditionalPanel(
                condition = "output.resultsCompleted",
                tags$p(
                  align="center",
                  HTML("<b>Pr Summary</b>")
                ),
                DT::DTOutput("prTable"),
                downloadButton(outputId = "prTableDownload", label = "Download Table"),
                tags$hr(),
                tags$p(
                  align="center",
                  HTML("<b>Df Summary</b>")
                ),
                DT::DTOutput("dfTable"),
                downloadButton(outputId = "dfTableDownload", label = "Download Table"),
                tags$hr(),
                tags$p(
                  align="center",
                  HTML("<b>Sum Sq Summary</b>")
                ),
                DT::DTOutput("sumSqTable"),
                downloadButton(outputId = "sumSqTableDownload", label = "Download Table"),
                tags$hr(),
                tags$p(
                  align="center",
                  HTML("<b>Mean Sq Summary</b>")
                ),
                DT::DTOutput("meanSqTable"),
                downloadButton(outputId = "meanSqTableDownload", label = "Download Table"),
                tags$hr(),
                tags$p(
                  align="center",
                  HTML("<b>F Value Summary</b>")
                ),
                DT::DTOutput("fValTable"),
                downloadButton(outputId = "fValTableDownload", label = "Download Table"),
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
              "The latest version of this application may be downloaded from the freeCount ",
              tags$a("GitHub",href = "https://github.com/ElizabethBrooks/freeCount"),
              "."
            ),
            tags$p(
              "Example counts and experimental design tables are also provided on ",
              tags$a("GitHub", href = "https://github.com/ElizabethBrooks/freeCount/tree/main/data/AV"),
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
  })
  
  # function to transpose the input counts
  tranposeCounts <- function(){
    # retrieve input counts
    geneCounts <- inputGeneCounts()
    # transpose expression data
    inputTable <- as.data.frame(t(geneCounts))
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
  
  # get the design factors
  designFactors <- reactive({
    # require input data
    req(input$expDesignTable)
    # retrieve input design
    targets <- inputDesign()
    # check data type of the sample names
    if(!is.character(rownames(targets))){
      return(NULL)
    }
    # retrieve factors
    colnames(targets)
  })
  
  # compare input design and counts samples
  compareSamples <- function(){
    # check the inputs
    if(is.null(inputGeneCounts())) {
      return(NULL)
    }else if(is.null(inputDesign())) {
      return(NULL)
    } 
    # retrieve input design samples
    targets <- inputDesign()
    designSamples <- data.frame(ID1 = rownames(targets))
    # TO-DO: check if counts need to be transposed
    # retrieve input gene counts samples
    geneCounts <- tranposeCounts() 
    countsSamples <- data.frame(ID2 = rownames(geneCounts))
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
    #if(is.null(compareSamples())) {
    #  return(FALSE)
    #}
    return(TRUE)
  }
  outputOptions(output, 'inputCheck', suspendWhenHidden=FALSE)
  
  # render experimental design table
  output$designTable <- renderTable({
    # retrieve input design table
    group <- designFactors()
  }, colnames = FALSE)

  # setup reactive values
  valueExp <- reactiveVal(defaultExp)
  valuePVal <- reactiveVal(defaultPVal)
  savedDfTable <- reactiveVal(defaultDfTable)
  savedSumSqTable <- reactiveVal(defaultSumSqTable)
  savedMeanSqTable <- reactiveVal(defaultMeanSqTable)
  savedFValTable <- reactiveVal(defaultFValTable)
  savedPrTable <- reactiveVal(defaultPrTable)
  
  # update input comparison
  observeEvent(input$runAnalysis, {
    # retrieve input design table
    group <- designFactors()
    # create temporary GLM expression
    tmpExpression <- paste(tail(group, 1), head(group, 1), sep = " - ")
    # update and set the glm comparison expression
    updateTextInput(
      session,
      "compareExpression",
      value = tmpExpression
    )
    # update reactive expression value with a temporary pairwise expression
    #valueExp(tmpExpression)
  })
  
  # update reactive values
  observeEvent(input$analysisUpdate, {
    valueExp(input$compareExpression)
    valuePVal(input$cutPVal)
  })
  
  # render text with input contrast
  output$inputContrast <- renderText({
    valueExp()
  })
  
  # render text with input contrast
  output$inputPVal <- renderText({
    valuePVal()
  })
  
  ##
  # Analysis
  ##
  
  # function to prepare the data for analysis
  prepData <- function(){
    # retrieve input counts, design, and factors
    geneCounts <- tranposeCounts() 
    targets <- inputDesign()
    targets_cols <- designFactors()
    # setup data frame
    expData <- merge(targets, geneCounts, by = 'row.names') 
    # set row names
    rownames(expData) <- expData$Row.names
    # remove the Row.names column
    expData <- expData[,-1]
    # loop over each factor column
    for (col in 1:length(targets_cols)) {
      expData[,targets_cols[col]] <- factor(expData[,targets_cols[col]])
    }
    # return the data
    expData
  }
  
  # check if results have completed
  output$prepCompleted <- function(){
    if(is.null(prepData())){
      return(FALSE)
    }
    return(TRUE)
  }
  outputOptions(output, 'prepCompleted', suspendWhenHidden=FALSE, priority=0)
  
  # reactive function to perform the anova
  performAOV <- eventReactive(input$analysisUpdate, {
    # retrieve the expression data and factors
    expData <- prepData()
    targets_cols <- designFactors()
    # set the input expression as global
    inputExpression <- valueExp()
    # initialize data
    start <- length(targets_cols)+1
    stop <- length(expData)-1
    aov_exp <- NA
    # loop over each sample
    for (col in start:stop) {
      # get sample name
      samp <- colnames(expData)[col]
      # setup expression
      aov_exp <- paste(samp, "~", inputExpression, sep=" ")
      # compute anova
      affy.aov <- aov(as.formula(aov_exp), data = expData)
      # retrieve summary stats
      stats <- summary(affy.aov)
      # separate summary stats
      df <- stats[[1]][1]
      sum_sq <- stats[[1]][2]
      mean_sq <- stats[[1]][3]
      f_val <- stats[[1]][4]
      pr <- data.frame(Pr = stats[[1]][5][1:nrow(df)-1,])
      # add sample name to columns
      colnames(df) <- samp
      colnames(sum_sq) <- samp
      colnames(mean_sq) <- samp
      colnames(f_val) <- samp
      colnames(pr) <- samp
      # fix row names
      rownames(pr) <- rownames(df)[1-nrow(df)-1]
      # initialize data frames
      if (col == start) {
        df_table <- data.frame(Df = df)
        sum_sq_table <- data.frame(SumSq = sum_sq)
        mean_sq_table <- data.frame(MeanSq = mean_sq)
        f_val_table <- data.frame(FValue = f_val)
        pr_table <- data.frame(Pr = pr)
      } else {
        # add current sample data to each results table
        df_table <- cbind(df_table, df)
        sum_sq_table <- cbind(sum_sq_table, sum_sq)
        mean_sq_table <- cbind(mean_sq_table, mean_sq)
        f_val_table <- cbind(f_val_table, f_val)
        pr_table <- cbind(pr_table, pr)
      }
    }
    # set the results tables
    savedDfTable(df_table)
    savedSumSqTable(sum_sq_table)
    savedMeanSqTable(mean_sq_table)
    savedFValTable(f_val_table)
    savedPrTable(pr_table)
  })
  
  # check if results have completed
  output$resultsCompleted <- function(){
    if(is.null(performAOV())){
      return(FALSE)
    }
    return(TRUE)
  }
  outputOptions(output, 'resultsCompleted', suspendWhenHidden=FALSE, priority=0)

  # output the Df table
  output$dfTable <- DT::renderDataTable({
    DT::datatable(
      savedDfTable(),
      options = list(
        deferRender = TRUE,
        scrollY = TRUE,
        scrollX = TRUE,
        scroller = TRUE,
        autoWidth = TRUE
      )
    )
  }) 
  
  # download table of Df results
  output$dfTableDownload <- downloadHandler(
    filename = function() {
      # setup output file name
      "dfTable.csv"
    },
    content = function(file) {
      # retrieve combined list of names
      resultsTbl <- df_results
      # output table
      write.table(resultsTbl, file, sep=",", quote=FALSE)
    }
  )
  
  # output the Df table
  output$sumSqTable <- DT::renderDataTable({
    DT::datatable(
      savedSumSqTable(),
      options = list(
        deferRender = TRUE,
        scrollY = TRUE,
        scrollX = TRUE,
        scroller = TRUE,
        autoWidth = TRUE
      )
    )
  }) 
  
  # download table of sum sq results
  output$sumSqTableDownload <- downloadHandler(
    filename = function() {
      # setup output file name
      "sumSqTable.csv"
    },
    content = function(file) {
      # retrieve combined list of names
      resultsTbl <- sum_sq_results
      # output table
      write.table(resultsTbl, file, sep=",", quote=FALSE)
    }
  )
  
  # output the Df table
  output$meanSqTable <- DT::renderDataTable({
    DT::datatable(
      savedMeanSqTable(),
      options = list(
        deferRender = TRUE,
        scrollY = TRUE,
        scrollX = TRUE,
        scroller = TRUE,
        autoWidth = TRUE
      )
    )
  }) 
  
  # download table of mean sq results
  output$meanSqTableDownload <- downloadHandler(
    filename = function() {
      # setup output file name
      "meanSqTable.csv"
    },
    content = function(file) {
      # retrieve combined list of names
      resultsTbl <- mean_sq_results
      # output table
      write.table(resultsTbl, file, sep=",", quote=FALSE)
    }
  )
  
  # output the Df table
  output$fValTable <- DT::renderDataTable({
    DT::datatable(
      savedFValTable(),
      options = list(
        deferRender = TRUE,
        scrollY = TRUE,
        scrollX = TRUE,
        scroller = TRUE,
        autoWidth = TRUE
      )
    )
  }) 
  
  # download table of F Value results
  output$fValTableDownload <- downloadHandler(
    filename = function() {
      # setup output file name
      "fValTable.csv"
    },
    content = function(file) {
      # retrieve combined list of names
      resultsTbl <- f_val_results
      # output table
      write.table(resultsTbl, file, sep=",", quote=FALSE)
    }
  )
  
  # output the Df table
  output$prTable <- DT::renderDataTable({
    DT::datatable(
      savedPrTable(),
      options = list(
        deferRender = TRUE,
        scrollY = TRUE,
        scrollX = TRUE,
        scroller = TRUE,
        autoWidth = TRUE
      )
    ) %>% 
      formatStyle(
        colnames(pr_results),
        backgroundColor = styleInterval(valuePVal(), c('red', 'white')),
        color = styleInterval(valuePVal(), c('white', 'black'))
      )
  }) 
  
  # download table of Pr results
  output$prTableDownload <- downloadHandler(
    filename = function() {
      # setup output file name
      "prTable.csv"
    },
    content = function(file) {
      # retrieve combined list of names
      resultsTbl <- pr_results
      # output table
      write.table(resultsTbl, file, sep=",", quote=FALSE)
    }
  )
}

#### App Object ####

# create the Shiny app object 
shinyApp(ui = ui, server = server)
