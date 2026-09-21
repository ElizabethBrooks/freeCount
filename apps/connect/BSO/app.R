# developer: Elizabeth Brooks
# updated: 21 April 2026

#### Setup ####

# increase max uploadable file size to from the default 5MB to 30MB
options(shiny.maxRequestSize=30*1024^2)

# install any missing packages
packageList <- c("shiny", "bslib", "reactable", "shinyWidgets")
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
})

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
#setOne, #setTwo, #setThree, #setFour {
  border-color: #f3969a;
  border-width: 2px;
  border-style: solid;
}
"

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
           "freeCount BSO",
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
         "Batch Set Operations", 
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
      # file uploads
      tags$p(
        "Upload the target set (*.txt or *.csv):"
      ),
      fileInput(
        "oneTable", 
        label = NULL,
        multiple = FALSE,
        accept = "text"
      ),
      tags$hr(),
      tags$p(
        "Upload the batch of query sets (*.txt or *.csv):"
      ),
      fileInput(
        "twoTable", 
        "Select File(s)", 
        multiple = TRUE, 
        accept = c(".csv", ".txt")
      )
      # add button to enable dark mode style
      #tags$p(
      #  "Select Color Mode:"
      #),
      #input_dark_mode()
    ),
    
    # setup the main panel
    mainPanel(
      # getting started text
      conditionalPanel(
        condition = "!output.twoDataUploaded",
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
          HTML("<b>1.</b> entering the names of the sets for comparison")
        ),
        tags$p(
          HTML("<b>2.</b> uploading two <i>.csv</i> files with discrete values")
        ),
        tags$br(),
        tags$p(
          "After uploading at least two files, it will be possible to view and download the venn diagrams along with the unique values belonging to each set and their intersections."
        ),
        tags$hr(),
        tags$p(
          align="center",
          HTML("<b>Helpful Tips</b>")
        ),
        tags$p(
          HTML("<b>Tip 1:</b> The first column of the <i>.csv</i> files are expected to contain the set values for comparison (e.g., gene IDs).")
        ),
        tags$p(
          HTML("<b>Tip 2:</b> It is possible to upload files that contain multiple columns of values, since every column after the first is ignored.")
        ),
      ),
      
      # results text and plots
      conditionalPanel(
        condition = "output.twoDataUploaded",
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
              HTML("<b>Tip 1:</b> The results may take several moments to appear depending on the size and number of input data tables.")
            ),
            tags$p(
              HTML("<b>Tip 2:</b> Navigate to the <i>Results</i> by clicking the tab at the top of the page.")
            ),
            tags$p(
              HTML("<b>Tip 3:</b> It is possible to change the sets of values for comparison by changing the uploaded files in the left-hand side bar.")
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
              "Displayed below is a table for exploring the intersections between a target set and a batch of query sets."
            ),
            tags$hr(),
            tags$p(
              align="center",
              HTML("<b>Target Set File Name</b>")
            ),
            verbatimTextOutput("printID"),
            tags$p(
              align="center",
              HTML("<b>Table of Intersections</b>")
            ),
            #reactableOutput("resultsTable"), 
            DT::DTOutput("resultsTable"), 
            tags$p(
              "The above table shows the number of matches and values that are contained in each target and query set intersection. Click the button below to download the above table of intersections."
            ),
            downloadButton(outputId = "intersections", label = "Download Table")
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
  
  # retrieve input data one
  inputOneTable <- reactive({
    # target list for comparison
    #target_list <- read.csv("/Users/bamflappy/PfrenderLab/melanica_UV_exposure/old_new_merged/data/GO_terms/repair_BP_GO_terms_AmiGO_IDs.txt")
    # require input data
    req(input$oneTable)
    # check the input table is not null
    if(is.null(input$oneTable)){
      return(NULL)
    }
    # read the file
    dataTableInput <- read.csv(file = input$oneTable$datapath)
    # return the first column of data
    dataTableInput[,1]
  })
  
  # retrieve input data two
  inputTwoTable <- reactive({
    # inputs path to set of lists
    #input_files <- list.files(path = "/Users/bamflappy/PfrenderLab/melanica_UV_exposure/old_new_merged/DA/edgeR_LFC0.01_FDR0.05_normalized/genotype_noE2/NA/FA", pattern = "\\BP_GO_terms_0.05_IDs.csv", recursive = TRUE, full.names = TRUE)
    # require input data
    req(input$twoTable)
    # check the input table is not null
    if(is.null(input$twoTable)){
      return(NULL)
    }
    # read the file
    #dataTableInput <- list.files(path = input$twoTable$datapath, recursive = TRUE, full.names = TRUE)
    dataTableInput <- input$twoTable$datapath
  })
  
  # check if two files have been uploaded
  output$twoDataUploaded <- function(){
    # check the input tables are not null
    if(is.null(inputOneTable())){
      return(FALSE)
    }else if(is.null(inputTwoTable())){
      return(FALSE)
    }
    return(TRUE)
  }
  outputOptions(output, 'twoDataUploaded', suspendWhenHidden=FALSE)
  
  ##
  # Analysis
  ##
  
  # output the target file ID
  output$printID <- renderText({
    input$oneTable$name
  })
  
  # function to create the intersection table
  createTable <- function(){
    # retrieve the input data
    target_list <- inputOneTable()
    input_files <- inputTwoTable()
    # initialize the data lists
    iteration_num <- 0
    name_list <- NULL
    num_data <- NULL
    intersect_data <- NULL
    # loop over each input list
    for (file_path in input_files) {
      # counter
      iteration_num <- iteration_num + 1
      # retrieve input list
      input_data <- read.csv(file_path)
      #i retrieve the first colmn of data
      input_list <- input_data[,1]
      # compare the target and current list
      intersect_list <- list(intersect(target_list, input_list))
      # count the number of matches
      num_matching <- nrow(data.frame(inter = intersect_list))
      # check how many matches there are
      if (num_matching == 0) {
        intersect_list <- "None"
      }
      # add the file path to the list
      name_list <- c(name_list, input$twoTable$name[iteration_num])
      # add the number of matches to the list
      num_data <- c(num_data, num_matching)
      # add the intersect list to the list
      intersect_data <- c(intersect_data, intersect_list)
    }
    # combine the lists into a single data frame
    intersect_data <- data.frame(Name = name_list, Matches = num_data, Intersection = I(intersect_data))
    # remove NAs
    #na.omit(intersect_data)
    # re-number rows
    row.names(intersect_data) <- seq(from = 1, to = nrow(intersect_data))
    # return table
    intersect_data
  }
  
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
    #reactable(
      #createTable(),
      #rowNames = FALSE,
      #bordered = TRUE,
      #resizable = TRUE,
      #columns = list(
      #  Name = colDef(minWidth = 100),
      #  Matches = colDef(minWidth = 50),
      #  Intersection = colDef(minWidth = 100))
  }) 
  
  # download table of results
  output$intersections <- downloadHandler(
    filename = function() {
      # retrieve the target file name without extension
      no_ext <- tools::file_path_sans_ext(input$oneTable$name)
      # setup output file name
      out_file <- paste("intersections_", no_ext, ".csv", sep = "")
    },
    content = function(file) {
      # retrieve combined list of names
      resultsTbl <- createTable()
      # output table
      write.table(resultsTbl, file, sep=",", row.names = FALSE, quote=FALSE)
    }
  )
}

#### App Object ####

# create the Shiny app object 
shinyApp(ui = ui, server = server)
