# created by: 
# date: 


#### Setup ####

# load packages
suppressPackageStartupMessages({
  library(shiny)
  library(shinythemes)
})


#### UI ####

# Define UI 
ui <- fluidPage(
  # view available themes
  #shinythemes::themeSelector(),
  
  # use a theme that displays tables in a compact format
  theme = shinytheme("yeti"),
  #theme = shinytheme("superhero"),
  
  # add application title
  titlePanel("... Shiny App Title ..."),
  
  # setup sidebar layout
  sidebarLayout(
    
    # setup sidebar panel
    sidebarPanel(
      
      # request inputs
      tags$p(
        "Upload Table (*.csv):"
      ),
      fileInput(
        "analysisTable", 
        label = NULL,
        multiple = FALSE,
        accept = ".csv"
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
          HTML("<b>1.</b> upload a table, for example:")
        ),
        tags$p(
          HTML("<ul><li> example <i>one</i></li></ul>")
        ),
        tags$p(
          HTML("<ul><li> example <i>two</i></li></ul>")
        ),
        tags$br(),
        tags$p(
          "Note that the analysis results and plots may take several moments to process depending on the size of the input table."
        ),
        tags$hr(),
        tags$p(
          align="center",
          HTML("<b>Helpful Tips</b>")
        ),
        tags$p(
          HTML("<b>Tip 1:</b> example tip one."),
        ),
        tags$p(
          HTML("<b>Tip 2:</b> example tip two."),
        ),
        tags$hr(),
        tags$p(
          align="center",
          HTML("<b>Data Formatting</b>")
        ),
        tags$p(
          "Example tables are displayed below."
        ),
        tags$br(),
        tags$p(
          HTML("<b>Example</b> table one:")
        ),
        tableOutput(outputId = "exampleTableOne"),
        tags$p(
          HTML("<b>Example</b> table two:")
        ),
        tableOutput(outputId = "exampleTableTwo"),
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
          "The analysis results and plots may take several moments to process depending on the size of the input tables."
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
              HTML("<b>Tip 1:</b> example tip one.")
            ),
            tags$p(
              HTML("<b>Tip 2:</b> example tip two.")
            )
          ),
          
          # analysis tab
          tabPanel(
            "Analysis",
            tags$br(),
            tags$p(
              align = "center",
              HTML("<b>... Analysis</b>")
            ),
            tags$br(),
            tags$p(
              "Begin the analysis by..."
            )
          ),
            
          # results tab
          tabPanel(
            "Results",
            tags$br(),
            tags$p(
              align="center",
              HTML("<b>... Results</b>")
            ),
            tags$br(),
            tableOutput(outputId = "tableRowNames")
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
              tags$a("...",href = "..."),
              "."
            ),
            tags$p(
              "The latest version of this application may be downloaded from ",
              tags$a("GitHub",href = "..."),
              "."
            ),
            tags$p(
              "Example data tables are also provided on ",
              tags$a("GitHub", href = "..."),
              "."
            ),
            tags$p(
              "More information about the analysis performed in this application is provided in ", 
              tags$a("...", href = "..."), 
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
  
  # output example table one
  output$exampleTableOne <- renderTable({
    # create example score table
    exScoreTable <- data.frame(
      Gene = c("gene-1", "gene-2", "gene-3", "gene-4", "gene-5"),
      logFC = c(2.61034881060096,-2.77567627557932,0.776975043760105,-1.34029691872383,2.00219952581652),
      logCPM = c(8.45787942136883,9.3923802734891,7.77358110628366,7.9912560914574,8.28149397708451),
      PValue = c(0.0002731254813,0.451205836761818,0.451205836761818,0.451205836761818,0.451205836761818),
      FDR = c(0.435362017290981,0.451205836761818,0.451205836761818,0.451205836761818,0.451205836761818)
    )
  })
  
  # output example table two
  output$exampleTableTwo <- renderTable({
    # create example score table
    exScoreTable <- data.frame(
      Gene = c("gene-1", "gene-2", "gene-3", "gene-4", "gene-5"),
      FDR = c(0.435362017290981,0.451205836761818,0.451205836761818,0.451205836761818,0.451205836761818)
    )
  })
  
  
  ##
  # Data Setup
  ##
  
  # retrieve input data table
  inputAnalysisTable <- reactive({
    # require input data
    req(input$analysisTable)
    # check the input table is not null
    if(is.null(input$analysisTable)){
      return(NULL)
    }
    # read the file
    dataTableInput <- read.csv(file = input$analysisTable$datapath, row.names=1)
  })
  
  # check if file has been uploaded
  output$dataUploaded <- function(){
    # check the input tables are not null
    if(is.null(inputAnalysisTable())){
      return(FALSE)
    }
    return(TRUE)
  }
  outputOptions(output, 'dataUploaded', suspendWhenHidden=FALSE)
  
  
  ## 
  # Analysis
  ##
  
  # function to return the table row names
  getRowNames <- function(){
    # retrieve input table
    inputTable <- inputAnalysisTable()
    # return the row names
    rownames(inputTable)
  }
  
  # check if results are complete
  output$resultsCompleted <- function(){
    if(is.null(getRowNames())){
      return(FALSE)
    }
    return(TRUE)
  }
  outputOptions(output, 'resultsCompleted', suspendWhenHidden=FALSE, priority=0)
  
  # output table row names
  output$tableRowNames <- renderTable({
    # retrieve and return the row names
    getRowNames()
  })
  
}


#### App Object ####

# create the Shiny app object 
shinyApp(ui = ui, server = server)
          
          