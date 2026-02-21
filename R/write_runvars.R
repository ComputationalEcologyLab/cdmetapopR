#' Build RunVars File from Template
#'
#' This function loads a provided runVars template, allows the user to edit selected areas,
#' and saves the modified version as a new file.
#'
#' @param output_file The name of the output file. Defaults to 'my_new_runvars.csv'.
#' @return A Shiny app instance.
#' @import shiny
#' @import shinyBS
#' @export

write_runvars <- function(output_file = "my_new_runvars.csv") {
  
  # Provide the template
  template <- data.frame(
    Popvars           = NA,
    sizecontrol       = "Y",
    constMortans      = 2,
    mcruns            = 1,
    runtime           = 50,
    output_years      = 1,
    gridformat        = "cdpop",
    gridsampling      = "Sample",
    summaryOutput     = "N",
    cdclimgentime     = 0,
    startcomp         = 0,
    implementcomp     = "Back"
  )
  
  ############################################
  ################## UI ######################
  ############################################
  
  ui <- fluidPage(
    titlePanel("Build a RunVars.csv File"),
    
    helpText(
      "Welcome! This Shiny app helps you put together a RunVars.csv file for CDmetaPOP.",
      "Upload your PopVars file, adjust options if needed, and preview the final parameters."
    ),
    
    sidebarLayout(
      sidebarPanel(
        tags$style(HTML("
          .upload-block {
            margin-bottom: 20px;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 8px;
            background-color: #f9f9f9;
          }
          .upload-block h5 {
            margin-top: 0;
            font-weight: bold;
            color: #333;
          }
        ")),
        
        div(
          class = "upload-block",
          h5("Directory Help"),
          actionButton("directory_help", "Show Help")
        ),
        
        div(
          class = "upload-block",
          h5("PopVars Upload"),
          fileInput("popvars_file", "Upload the popvars.csv file", accept = ".csv"),
          actionButton("update_popvars", tagList(
            "Update ",
            em(span("Popvars", style = "color:#0072B2; font-weight: bold;"))
          ))
        )
      ),
      
      mainPanel(
        tabsetPanel(
         
          tabPanel(
            "Parameter Options",
            selectInput("sizecontrol", tagList(
              "Choose input to control size:",
              em(span("sizecontrol", style = "color:#0072B2;"))
            ),
            selected = "Y",
            choices = c("N", "Y")
            ),
            numericInput("constMortans", tagList(
              "select option",
              em(span("constMortans", style = "color:#0072B2;"))
            ), value = 2, min = 1, step = 1),
            numericInput("mcruns", tagList(
              "select number of MonteCarlo repetitions",
              em(span("mcruns", style = "color:#0072B2;"))
            ), value = 1, min = 1, step = 1),
            numericInput("runtime", tagList(
              "Plese select the number of time steps to run the simulation",
              em(span("runtime", style = "color:#0072B2;"))
            ), value = 50, min = 0, step = 1),
            numericInput("output_years", tagList(
              "Plese enter the specified simulation time steps [year/generation] to write to file, summarize year metrics, or to calculate genetic distance matrices",
              em(span("output_years", style = "color:#0072B2;"))
            ), value = 1, min = 1, step = 1),
            selectInput("gridformat", tagList(
              "Enter the desired gene output format: ",
              em(span("gridformat", style = "color:#0072B2;"))
            ), selected = "cdpop",
            choices = c("genepop", "genalex", "structure", "cdpop", "general")
            ),
            selectInput("gridsampling", tagList(
              "Select whether to output genotypes before the Immigration step or when they are away from their natal grounds: ",
              em(span("gridsampling", style = "color:#0072B2;"))
            ), selected = "Sample",
            choices = c("N", "Sample")
            ),
            selectInput("summaryOutput", tagList(
              "Option to output summary metrics for each patch at the given time intervals: ",
              em(span("summaryOutput", style = "color:#0072B2;"))
            ), selected = "N",
            choices = c("Y", "N")
            ),
            textInput("cdclimgentime", tagList(
              "To initiate the CDClimate module, this is the generation or year that the next variable or effective distance matrix will be switched e.g., 0.05|0|0: ",
              em(span("cdclimgentime", style = "color:#0072B2;"))
            ), value = 0, placeholder = "0"),
            
            numericInput("startcomp", tagList(
              "Year of the simulation at which Lotka-Volterra competition begins: ",
              em(span("startcomp", style = "color:#0072B2;"))
            ), value = 0, min = 0, step = 1),
            
            selectInput("implementcomp", tagList(
              "Option for when to implement Lotka-Volterra competition: ",
              em(span("implementcomp", style = "color:#0072B2;"))
            ), selected = "Back",
            choices = "Back"
            ),
            actionButton("update_parameters", "Update Parameters")
          ),
          tabPanel(
            "Preview Updated RunVars",
            tableOutput("preview_template"),
            downloadButton("download_runvars", "Download RunVars CSV")
          ),
        )
      )
    )
  )
  
  ##############################################
  ############### SERVER #######################
  ##############################################
  
  server <- function(input, output, session) {
    
    # Reactive template
    template_data <- reactiveVal(template)
    
    ##############################################
    # Directory Help Modal
    ##############################################
    # Side panel help button
    observeEvent(input$directory_help, {
      showModal(
        modalDialog(
          title = "How to Organize Your Data Directory",
          helpText(
            "Please organize your data in the following way:",
            "1. Create a main folder named ", strong("data"), ".",
            "2. Inside the data folder, place the ", code("runVars.csv"), "file.",
            "3. Also inside the data folder, create the following subdirectories:",
            br(), "   • ", code("popvars"), " — contains file ", code("popVars.csv"),
            br(), "   • ", code("patchvars"), " — contains file ", code("patchVars.csv"),
            br(), "   • ", code("classvars"), " — contains file ", code("classVars"),
            br(), "   • ", code("genes"), " — contains files ", code("allele frequency files (.csv)"),
            br(), "   • ", code("cdmats"), " — contains files for movement matrices",
            br(), "   • ", code("otherfiles"), " — contains other files, e.g. correlation matrices",
            br(), br(),
            "The correct structure should look like this:"
          ),
          tags$pre(
            "data/
│
├── runVars.csv
│
├── popvars/
│   └── popVars.csv
│
├── patchvars/
│   └── patchVars.csv
│
└── classvars/
│   └── classVars.csv
│
└── genes/
│   └── allelefrequencies.csv
│
└── cdmats/
|   ├── cdmat1.csv
│   ├── cdmat2.csv
│   └── cdmat3.csv
|
└── otherfiles/
│   ├── correlation_matrix1.csv
│   └── correlation_matrix2.csv"
            
          ),
          easyClose = TRUE,
          footer = modalButton("Close")
        )
      )
    })
    
    ##############################################
    # Add popmodel tooltip
    ##############################################
    observe({
      addTooltip(session, "popmodel",
                 "Population growth model:
N: exponential,
logistic: density-dependent,
packing: class-specific with competition,
packing_1: class-specific with adjacent competition,
anadromy: packing for anadromous species.",
                 placement = "right"
      )
    })
    
    ##############################################
    # UPDATE PARAMETER OPTIONS
    ##############################################
    observeEvent(input$update_parameters, {
      temp <- template_data()
      
      temp$sizecontrol <- input$sizecontrol
      temp$constMortans <- input$constMortans
      temp$mcruns <- input$mcruns
      temp$runtime <- input$runtime
      temp$output_years <- input$output_years
      temp$gridformat <- input$gridformat
      temp$gridsampling <- input$gridsampling
      temp$summaryOutput <- input$summaryOutput
      temp$cdclimgentime <- input$cdclimgentime
      temp$startcomp <- input$startcomp
      temp$implementcomp <- input$implementcomp
      
      # Update the reactive object
      template_data(temp)
    })
    ##############################################
    # Update Popvars
    ##############################################
    observeEvent(input$update_popvars, {
      req(input$popvars_file)
      popvars_name <- input$popvars_file$name
      temp <- template_data()
      temp$Popvars <- paste0("popvars/", popvars_name)
      template_data(temp)
    })
    
    ##############################################
    # Preview Template
    ##############################################
    output$preview_template <- renderTable({
      template_data()
    })
    
    ##############################################
    # Download Handler
    ##############################################
    output$download_runvars <- downloadHandler(
      
      filename = function() {
        "runVars.csv"
      },
      content = function(file) {
        write.csv(template_data(), file, row.names = FALSE)
      }
    )
    
  }
  
  ##############################################
  # Run the app
  ##############################################
  shinyApp(ui = ui, server = server)
  
}
