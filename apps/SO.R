# creator: Elizabeth Brooks
# updated: 12 April 2024

#### Setup ####

# install any missing packages
packageList <- c("BiocManager", "shiny", "shinythemes", "ggplot2", "rcartocolor", "ggVennDiagram", "gplots")
newPackages <- packageList[!(packageList %in% installed.packages()[,"Package"])]
if(length(newPackages)){
  install.packages(newPackages)
}

# load packages
suppressPackageStartupMessages({
  library(shiny)
  library(shinythemes)
  library(ggVennDiagram)
  library(ggplot2)
  library(rcartocolor)
  library(gplots)
})

# color blind safe plotting palettes
plotColors <- carto_pal(12, "Safe")

# TO-DO: make upload button appear after at least two sets are input
# TO-DO: check if headers are accounted for
# TO-DO: store data and results in reactiveVal and reactiveValues

#### UI ####

# Define UI 
ui <- fluidPage(
  # view available themes
  #shinythemes::themeSelector(),
  
  # use a theme
  theme = shinytheme("yeti"),
  #theme = shinytheme("superhero"),
  
  # add application title
  titlePanel("Set Operations"),
  
  # setup sidebar layout
  sidebarLayout(
    
    # setup sidebar panel
    sidebarPanel(
      
      # file uploads
      tags$p(
        "Enter set one name:"
      ),
      textInput(
        "setOne", 
        label = NULL,
        value = "Set One"
      ),
      ## TO-DO: consider allowing other file types to be uploaded
      tags$p(
        "Upload set one table (*.csv):"
      ),
      fileInput(
        "oneTable", 
        label = NULL,
        multiple = FALSE,
        accept = ".csv"
      ),
      tags$hr(),
      tags$p(
        "Enter set two name:"
      ),
      textInput(
        "setTwo", 
        label = NULL,
        value = "Set Two"
      ),
      tags$p(
        "Upload set two table (*.csv):"
      ),
      fileInput(
        "twoTable", 
        label = NULL,
        multiple = FALSE,
        accept = ".csv"
      ),
      conditionalPanel(
        condition = "output.twoDataUploaded",
        tags$hr(),
        tags$p(
          "Enter set three name:"
        ),
        textInput(
          "setThree", 
          label = NULL,
          value = "Set Three"
        ),
        tags$p(
          "Upload set three table (*.csv):"
        ),
        fileInput(
          "threeTable", 
          label = NULL,
          multiple = FALSE,
          accept = ".csv"
        ),
        conditionalPanel(
          condition = "output.threeDataUploaded",
          tags$hr(),
          tags$p(
            "Enter set four name:"
          ),
          textInput(
            "setFour", 
            label = NULL,
            value = "Set Four"
          ),
          tags$p(
            "Upload set four table (*.csv):"
          ),
          fileInput(
            "fourTable", 
            label = NULL,
            multiple = FALSE,
            accept = ".csv"
          )
        )
      )
    ),
    
    # Output: Show plots
    mainPanel(
      
      # getting started text
      conditionalPanel(
        condition = "!output.twoDataUploaded",
        tags$h1("Getting Started", align = "center"),
        tags$br(),
        # TO-DO: add input step numbers
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
          "Note that after uploading at least two files, it will be possible to view and download the venn diagrams along with the unique values belonging to each set and their intersections."
        ),
        tags$hr(),
        tags$p(
          align="center",
          HTML("<b>Helpful Tips</b>")
        ),
        tags$br(),
        tags$p(
          HTML("<b>Tip 1:</b> The first column of the <i>.csv</i> files are expected to contain the set values for comparison (e.g., gene IDs).")
        ),
        tags$p(
          HTML("<b>Tip 2:</b> It is possible to upload files that contain only a single column of values, since every column after the first is ignored.")
        ),
        tags$p(
          HTML("<b>Tip 3:</b> Two files must be uploaded for a minimum comparison between two sets of values.")
        ),
        tags$p(
          HTML("<b>Tip 4:</b> After uploading the first two files, it will be possible to compare up to four sets of values.")
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
            tags$br(),
            tags$p(
              align="center",
              HTML("<b>Helpful Tips</b>")
            ),
            tags$p(
              HTML("<b>Tip 1:</b> The results may take several moments to appear depending on the size of the input data tables.")
            ),
            tags$p(
              HTML("<b>Tip 2:</b> Navigate to the <i>Venn Diagrams</i> by clicking the tab at the top of the page.")
            ),
            tags$p(
              HTML("<b>Tip 3:</b> It is possible to change the sets of values for comparison by changing the uploaded files in the left-hand side bar.")
            ),
            tags$p(
              HTML("<b>Tip 4:</b> It is possible to compare up to four sets of values by uploading additional <i>.csv</i> files in the left-hand side bar.")
            ),
            tags$p(
              HTML("<b>Tip 5:</b> Enter or change the names of each set in the left-hand side bar.")
            )
          ),
          
          # Venn Diagrams tab
          tabPanel(
            "Venn Diagrams",
            tags$br(),
            tags$p(
              align="center",
              HTML("<b>Venn Diagrams</b>")
            ),
            tags$br(),
            tags$p(
              "Displayed below are venn diagrams for exploring the relationship between sets of discrete values. It is possible to download the diagrams along with the unique values belonging to each set and their intersections."
            ),
            tags$hr(),
            tags$p(
              align="center",
              HTML("<b>Two-Way Venn Diagram</b>")
            ),
            fluidRow(
              column(
                width = 6,
                plotOutput(outputId = "twoWayVenn"),
                downloadButton(outputId = "twoWayVennDownload", label = "Download Plot"),
                tags$p(
                  "The above two-way diagram shows the number and percentage of values that are contained in each of the input sets and their intersections."
                )
              ),
              column(
                width = 6,
                plotOutput(outputId = "twoWayVennSets"),
                downloadButton(outputId = "twoWayVennSetsDownload", label = "Download Plot"),
                tags$p(
                  "The above two-way diagram shows the names of the sets and intersections contained in each section of the diagram."
                )
              )
            ),
            tags$br(),
            fluidRow(
              column(
                width = 6,
                tags$p(
                  "Select a set or intersection:"
                ),
                selectInput(
                  inputId = "twoWayCompare",
                  label = NULL,
                  choices = c("")
                )
              ),
              column(
                width = 6,
                tags$p(
                  "Download set or intersection:"
                ),
                downloadButton(outputId = "twoWayIntersections", label = "Download Table")
              )
            ),
            # three-way venn
            conditionalPanel(
              condition = "output.threeDataUploaded",
              tags$hr(),
              tags$p(
                align="center",
                HTML("<b>Three-Way Venn Diagram</b>")
              ),
              fluidRow(
                column(
                  width = 6,
                  plotOutput(outputId = "threeWayVenn"),
                  downloadButton(outputId = "threeWayVennDownload", label = "Download Plot"),
                  tags$p(
                    "The above three-way diagram shows the number and percentage of values that are contained in each of the input sets and their intersections."
                  )
                ),
                column(
                  width = 6,
                  plotOutput(outputId = "threeWayVennSets"),
                  downloadButton(outputId = "threeWayVennSetsDownload", label = "Download Plot"),
                  tags$p(
                    "The above two-way diagram shows the names of the sets and intersections contained in each section of the diagram."
                  )
                )
              ),
              fluidRow(
                column(
                  width = 6,
                  tags$p(
                    "Select a set or intersection:"
                  ),
                  selectInput(
                    inputId = "threeWayCompare",
                    label = NULL,
                    choices = c("")
                  )
                ),
                column(
                  width = 6,
                  tags$p(
                    "Download set or intersection:"
                  ),
                  downloadButton(outputId = "threeWayIntersections", label = "Download Table")
                )
              )
            ),
            # four-way venn
            conditionalPanel(
              condition = "output.fourDataUploaded",
              tags$hr(),
              tags$p(
                align="center",
                HTML("<b>Four-Way Venn Diagram</b>")
              ),
              fluidRow(
                column(
                  width = 6,
                  plotOutput(outputId = "fourWayVenn"),
                  downloadButton(outputId = "fourWayVennDownload", label = "Download Plot"),   
                  tags$p(
                    "The above four-way diagram shows the number and percentage of values that are contained in each of the input sets and their intersections."
                  )
                ),
                column(
                  width = 6,
                  plotOutput(outputId = "fourWayVennSets"),
                  downloadButton(outputId = "fourWayVennSetsDownload", label = "Download Plot"),
                  tags$p(
                    "The above two-way diagram shows the names of the sets and intersections contained in each section of the diagram."
                  )
                )
              ),
              fluidRow(
                column(
                  width = 6,
                  tags$p(
                    "Select a set or intersection:"
                  ),
                  selectInput(
                    inputId = "fourWayCompare",
                    label = NULL,
                    choices = c("")
                  )
                ),
                column(
                  width = 6,
                  tags$p(
                    "Download set or intersection:"
                  ),
                  downloadButton(outputId = "fourWayIntersections", label = "Download Table")
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
            tags$p(
              "This application for creating venn diagrams to compare sets of values was created by",
              tags$a("Elizabeth Brooks",href = "https://www.linkedin.com/in/elizabethmbrooks/"),
              "."
            ),
            tags$p(
              "The latest version of this application may be downloaded from",
              tags$a("GitHub",href = "https://github.com/ElizabethBrooks/DGEAnalysis_ShinyApps"),
              "."
            ),
            tags$p(
              "Example sets of gene IDs are also provided on",
              tags$a("GitHub", href = "https://github.com/ElizabethBrooks/DGEAnalysis_ShinyApps/tree/main/data/ggVennDiagram"),
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
  # Data Setup
  ##
  
  # retrieve input data one
  inputOneTable <- reactive({
    # require input data
    req(input$oneTable)
    # check the input table is not null
    if(is.null(input$oneTable)){
      return(NULL)
    }
    # read the file
    dataTableInput <- read.csv(file = input$oneTable$datapath, row.names=1)
    # return data
    namesSet <- rownames(dataTableInput)
  })
  
  # retrieve input data two
  inputTwoTable <- reactive({
    # require input data
    req(input$twoTable)
    # check the input table is not null
    if(is.null(input$twoTable)){
      return(NULL)
    }
    # read the file
    dataTableInput <- read.csv(file = input$twoTable$datapath, row.names=1)
    # return data
    namesSet <- rownames(dataTableInput)
  })
  
  # retrieve input data three
  inputThreeTable <- reactive({
    # require input data
    req(input$threeTable)
    # check the input table is not null
    if(is.null(input$threeTable)){
      return(NULL)
    }
    # read the file
    dataTableInput <- read.csv(file = input$threeTable$datapath, row.names=1)
    # return data
    namesSet <- rownames(dataTableInput)
  })
  
  # retrieve input data four
  inputFourTable <- reactive({
    # require input data
    req(input$fourTable)
    # check the input table is not null
    if(is.null(input$fourTable)){
      return(NULL)
    }
    # read the file
    dataTableInput <- read.csv(file = input$fourTable$datapath, row.names=1)
    # return data
    namesSet <- rownames(dataTableInput)
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
  
  # check if three files have been uploaded
  output$threeDataUploaded <- function(){
    # check the input tables are not null
    if(is.null(inputOneTable())){
      return(FALSE)
    }else if(is.null(inputTwoTable())){
      return(FALSE)
    }else if(is.null(inputThreeTable())){
      return(FALSE)
    }
    return(TRUE)
  }
  outputOptions(output, 'threeDataUploaded', suspendWhenHidden=FALSE)
  
  # check if four files have been uploaded
  output$fourDataUploaded <- function(){
    # check the input tables are not null
    if(is.null(inputOneTable())){
      return(FALSE)
    }else if(is.null(inputTwoTable())){
      return(FALSE)
    }else if(is.null(inputThreeTable())){
      return(FALSE)
    }else if(is.null(inputFourTable())){
      return(FALSE)
    }
    return(TRUE)
  }
  outputOptions(output, 'fourDataUploaded', suspendWhenHidden=FALSE)
  
  # function to retrieve set intersections
  retrieveCompareList <- function(namesList){
    # create venn lists
    vennList <- venn(namesList, show.plot = FALSE)
    # retrieve intersections
    listaAtt <- attributes(vennList)$intersections
    # get list of set intersections
    compareList <- names(listaAtt)
  }
  
  # update inputs for two-way comparisons
  observe({
    # retrieve combined list of names
    namesList <- createTwoWayList()
    # get list of set intersections
    compareList <- retrieveCompareList(namesList)
    # update and set the two-way select items
    updateSelectInput(
      session, 
      inputId = "twoWayCompare",
      choices = compareList,
      selected = compareList[1]
    )
  })
  
  # update inputs for three-way comparisons
  observe({
    # retrieve combined list of names
    namesList <- createThreeWayList()
    # get list of set intersections
    compareList <- retrieveCompareList(namesList)
    # update and set the two-way select items
    updateSelectInput(
      session, 
      inputId = "threeWayCompare",
      choices = compareList,
      selected = compareList[1]
    )
  })
  
  # update inputs for four-way comparisons
  observe({
    # retrieve combined list of names
    namesList <- createFourWayList()
    # get list of set intersections
    compareList <- retrieveCompareList(namesList)
    # update and set the two-way select items
    updateSelectInput(
      session, 
      inputId = "fourWayCompare",
      choices = compareList,
      selected = compareList[1]
    )
  })
  
  
  ## 
  # Venn Diagrams
  ##
  
  # function to create two-way names list
  createTwoWayList <- function(){
    # retrieve set of row names
    namesSetOne <- inputOneTable()
    namesSetTwo <- inputTwoTable()
    # create combined list of names
    namesList <- list(setOne = namesSetOne, 
                      setTwo = namesSetTwo
    )
  }
  
  # function to create venn diagrams
  createVenn <- function(namesList, setList, colorList){
    # create venn diagram
    ggVennDiagram(namesList, label_alpha=0.25, category.names = setList) +
      scale_x_continuous(expand = expansion(mult = .2)) +
      scale_fill_gradientn(colors = colorList)
  }
  
  
  # TO-DO: stat_sf(): requires the missing aestehtic geometry (windows issue?)
  # https://stackoverflow.com/questions/76704893/r-stat-sf-requires-the-following-missing-aesthetics-geometry
  # function to create plot venn diagrams sets
  createVennSets <- function(dataList, labelList){
    # create venn diagram
    vennSets <- ggplot() +
      # change mapping of color filling
      geom_sf(data = venn_region(dataList), aes(fill = id), show.legend = FALSE) +  
      # adjust edge size and color
      geom_sf(color="grey", size = 3, data = venn_setedge(dataList), show.legend = FALSE) +  
      # show set label in bold
      geom_sf_text(aes(label = labelList), fontface = "bold", data = venn_setlabel(dataList)) +  
      # add a alternative region name
      geom_sf_label(aes(label = name), data = venn_region(dataList), alpha = 0.5) +  
      # expand the plotting area
      scale_x_continuous(expand = expansion(mult = .2)) +
      # void theme
      theme_void()
    #return plot
    vennSets
  }
  
  # function to retrieve intersections from the venn diagram
  retrieveVennSets <- function(namesList, compare){
    # create venn lists
    vennList <- venn(namesList, show.plot = FALSE)
    # retrieve intersections
    listaAtt <- attributes(vennList)$intersections
    # get sets of values
    listaAtt[names(listaAtt) == compare] 
  }
  
  # function to render two-way venn
  output$twoWayVenn <- renderPlot({
    # retrieve combined list of names
    namesList <- createTwoWayList()
    # setup set list
    setList <- c(input$setOne, input$setTwo)
    # setup colorList
    colorList <- c(plotColors[1], plotColors[2])
    # create plot
    createVenn(namesList, setList, colorList)
  })
  
  # download handler for two-way venn
  output$twoWayVennDownload <- downloadHandler(
    filename = function() {
      exportFile <- paste(input$setOne, input$setTwo, sep="_")
      exportFile <- paste(exportFile, "twoWayVenn.png", sep="_")
    },
    content = function(file) {
      # retrieve combined list of names
      namesList <- createTwoWayList()
      # setup set list
      setList <- c(input$setOne, input$setTwo)
      # setup colorList
      colorList <- c(plotColors[1], plotColors[2])
      # create plot
      outVenn <- createVenn(namesList, setList, colorList)
      # save plot
      ggsave(file, plot = outVenn, device = "png")
    }
  )
  
  # function to render two-way venn
  output$twoWayVennSets <- renderPlot({
    # retrieve combined list of names
    namesList <- createTwoWayList()
    vennList <- Venn(namesList)
    dataList <- process_data(vennList)
    # setup label list
    labelList <- c(input$setOne, input$setTwo)
    # create plot
    createVennSets(dataList, labelList)
  })
  
  # download handler for two-way venn
  output$twoWayVennSetsDownload <- downloadHandler(
    filename = function() {
      exportFile <- paste(input$setOne, input$setTwo, "twoWayVennSets.png", sep="_")
    },
    content = function(file) {
      # retrieve combined list of names
      namesList <- createTwoWayList()
      vennList <- Venn(namesList)
      dataList <- process_data(vennList)
      # setup label list
      labelList <- c(input$setOne, input$setTwo)
      # create plot
      outVenn <- createVennSets(dataList, labelList)
      # save the plot
      ggsave(file, plot = outVenn, device = "png")
    }
  )
  
  # download table with number of filtered genes
  output$twoWayIntersections <- downloadHandler(
    filename = function() {
      # setup output file name
      paste(input$twoWayCompare, "twoWayVenn.csv", sep = "_")
    },
    content = function(file) {
      # retrieve combined list of names
      namesList <- createTwoWayList()
      # retrieve selected sets
      compare <- input$twoWayCompare
      # retrieve intersections values
      resultsTbl <- retrieveVennSets(namesList, compare)
      # output table
      write.table(resultsTbl, file, sep=",", row.names=TRUE, quote=FALSE)
    }
  )
  
  
  # function to create three-way names list
  createThreeWayList <- function(){
    # retrieve set of row names
    namesSetOne <- inputOneTable()
    namesSetTwo <- inputTwoTable()
    namesSetThree <- inputThreeTable()
    # create combined list of names
    namesList <- list(setOne = namesSetOne, 
                      setTwo = namesSetTwo,
                      setThree = namesSetThree
    )
  }
  
  # function to render three-way venn
  output$threeWayVenn <- renderPlot({
    # retrieve combined list of names
    namesList <- createThreeWayList()
    # setup set list
    setList <- c(input$setOne, input$setTwo, input$setThree)
    # setup colorList
    colorList <- c(plotColors[1], plotColors[2])
    # create plot
    createVenn(namesList, setList, colorList)
  })
  
  # download handler for three-way venn
  output$threeWayVennDownload <- downloadHandler(
    filename = function() {
      exportFile <- paste(input$setOne, input$setTwo, input$setThree, "threeWayVenn.png", sep="_")
    },
    content = function(file) {
      # retrieve combined list of names
      namesList <- createThreeWayList()
      # setup set list
      setList <- c(input$setOne, input$setTwo, input$setThree)
      # setup colorList
      colorList <- c(plotColors[1], plotColors[2])
      # create plot
      outVenn <- createVenn(namesList, setList, colorList)
      # save plot
      ggsave(file, plot = outVenn, device = "png")
    }
  )
  
  # function to render three-way venn
  output$threeWayVennSets <- renderPlot({
    # retrieve combined list of names
    namesList <- createThreeWayList()
    vennList <- Venn(namesList)
    dataList <- process_data(vennList)
    # setup label list
    labelList <- c(input$setOne, input$setTwo, input$setThree)
    # create plot
    createVennSets(dataList, labelList)
  })
  
  # download handler for three-way venn
  output$threeWayVennSetsDownload <- downloadHandler(
    filename = function() {
      exportFile <- paste(input$setOne, input$setTwo, input$setThree, "threeWayVennSets.png", sep="_")
    },
    content = function(file) {
      # retrieve combined list of names
      namesList <- createThreeWayList()
      vennList <- Venn(namesList)
      dataList <- process_data(vennList)
      # setup label list
      labelList <- c(input$setOne, input$setTwo, input$setThree)
      # create plot
      outVenn <- createVennSets(dataList, labelList)
      # save the plot
      ggsave(file, plot = outVenn, device = "png")
    }
  )
  
  # download table with number of filtered genes
  output$threeWayIntersections <- downloadHandler(
    filename = function() {
      # setup output file name
      paste(input$threeWayCompare, "threeWayVenn.csv", sep = "_")
    },
    content = function(file) {
      # retrieve combined list of names
      namesList <- createThreeWayList()
      # retrieve selected sets
      compare <- input$threeWayCompare
      # retrieve intersections values
      resultsTbl <- retrieveVennSets(namesList, compare)
      # output table
      write.table(resultsTbl, file, sep=",", row.names=TRUE, quote=FALSE)
    }
  )
  
  
  # function to create four-way names list
  createFourWayList <- function(){
    # retrieve set of row names
    namesSetOne <- inputOneTable()
    namesSetTwo <- inputTwoTable()
    namesSetThree <- inputThreeTable()
    namesSetFour <- inputFourTable()
    # create combined list of names
    namesList <- list(setOne = namesSetOne, 
                      setTwo = namesSetTwo,
                      setThree = namesSetThree,
                      setFour = namesSetFour
                      )
  }
  
  # function to render four-way venn
  output$fourWayVenn <- renderPlot({
    # retrieve combined list of names
    namesList <- createFourWayList()
    # setup set list
    setList <- c(input$setOne, input$setTwo, input$setThree, input$setFour)
    # setup colorList
    colorList <- c(plotColors[1], plotColors[2])
    # create plot
    createVenn(namesList, setList, colorList)
  })
  
  # download handler for four-way venn
  output$fourWayVennDownload <- downloadHandler(
    filename = function() {
      exportFile <- paste(input$setOne, input$setTwo, input$setThree, input$setFour, "fourWayVenn.png", sep="_")
    },
    content = function(file) {
      # retrieve combined list of names
      namesList <- createFourWayList()
      # setup set list
      setList <- c(input$setOne, input$setTwo, input$setThree, input$setFour)
      # setup colorList
      colorList <- c(plotColors[1], plotColors[2])
      # create plot
      outVenn <- createVenn(namesList, setList, colorList)
      # save plot
      ggsave(file, plot = outVenn, device = "png")
    }
  )
  
  # function to render four-way venn
  output$fourWayVennSets <- renderPlot({
    # retrieve combined list of names
    namesList <- createFourWayList()
    vennList <- Venn(namesList)
    dataList <- process_data(vennList)
    # setup label list
    labelList <- c(input$setOne, input$setTwo, input$setThree, input$setFour)
    # create plot
    createVennSets(dataList, labelList)
  })
  
  # download handler for four-way venn
  output$fourWayVennSetsDownload <- downloadHandler(
    filename = function() {
      exportFile <- paste(input$setOne, input$setTwo, input$setThree, input$setFour, sep="_")
      exportFile <- paste(exportFile, "fourWayVennSets.png", sep="_")
    },
    content = function(file) {
      # retrieve combined list of names
      namesList <- createFourWayList()
      vennList <- Venn(namesList)
      dataList <- process_data(vennList)
      # setup label list
      labelList <- c(input$setOne, input$setTwo, input$setThree, input$setFour)
      # create plot
      outVenn <- createVennSets(dataList, labelList)
      # save the plot
      ggsave(file, plot = outVenn, device = "png")
    }
  )
  
  # download table with number of filtered genes
  output$fourWayIntersections <- downloadHandler(
    filename = function() {
      # setup output file name
      paste(input$fourWayCompare, "fourWayVenn.csv", sep = "_")
    },
    content = function(file) {
      # retrieve combined list of names
      namesList <- createFourWayList()
      # retrieve selected sets
      compare <- input$fourWayCompare
      # retrieve intersections values
      resultsTbl <- retrieveVennSets(namesList, compare)
      # output table
      write.table(resultsTbl, file, sep=",", row.names=TRUE, quote=FALSE)
    }
  )
  
}

#### App Object ####

# create the Shiny app object 
shinyApp(ui = ui, server = server)

