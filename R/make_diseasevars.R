#' Build DiseaseVars File from Template
#'
#' This function loads a provided DiseaseVars template, allows the user to edit selected areas,
#' and saves the modified version as a new file.
#'
#' @param output_file The name of the output file. Defaults to 'my_new_diseasevars.csv'.
#' @return A Shiny app instance.
#' @import shiny
#' @import shinyBS
#' @export
make_diseasevars <- function(output_file = "my_new_diseasevars.csv") {
  # Template
  template <- data.frame(
    `Number of States` = 3,
    `Initial Conditions` = "0.9;0.1;0.0",
    `Transition Rate` = NA,
    `Susceptible States` = 0,
    `Infection States` = 1,
    `Death States` = "N",
    `Initial Conditions Offspring` = "Susceptible",
    `Start Disease` = 0,
    `Transmission Mode` = "Direct",
    `Disease Resistant` = "N",
    `Disease Tolerant` = "N",
    check.names = FALSE)
  
############################################
################## UI ######################
############################################
  ui <- fluidPage(
    tags$head(
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
    input[type=number]::-webkit-inner-spin-button,
    input[type=number]::-webkit-outer-spin-button {
      -webkit-appearance: none;
      margin: 0;
    }
    input[type=number] {
      -moz-appearance: textfield;
    }
  "))
    ),
    titlePanel("Build a DiseaseVars.csv File"),
    p(
      "Welcome! This shiny app instance will help you put together a DiseaseVars.csv file to use as a CDmetaPOP input file.",
      "Select any of the tabs below and change the default parameters of the simulations in order to reflect those of the system you want to test. The parameter that will be changed according to your choices is indicated for each section as ",
      em(span("parameter", style = "color:#0072B2; font-weight: bold;")),
      "."
    ),
    ###################################
    ####       SIDE PANEL          ####
    ###################################
    sidebarLayout(
      sidebarPanel(
        # How to best organize your directories
        div(
          class = "upload-block",
          h5("How to best organize your directories"),
          # The Help button
          actionButton("directory_help", "Show help")
        ),
        div(class = "upload-block",
            h5("Transition Rates Matrix"),
            textInput("Transition_Rates_file", "Type the file name of your TransitionMatrix.csv file: "),
            actionButton("update_TransitionMatrix", tagList(
                "Update ",
                em(span("Transition Matrix", style = "color:#0072B2; font-weight: bold;"))
              )),
            actionButton("help_transition_matrix", "?", class = "btn-info")
            ),
      downloadButton("download_diseasevars", "Download DiseaseVars File")
      ), #sidebar panel
      
        ############################################
        ####            MAIN PANEL              ####
        ############################################    
        
        mainPanel(
          tabsetPanel(
            id = "main_tabs",
            
        ############################################
        ####           DISEASE VARS             ####
        ############################################
            
            tabPanel("Disease",
              
              numericInput("Number_of_States", tagList("Define the number of states", em(span("Number of States", style = "color:#0072B2;"))), 
                           value = 0,
                           min = 0, step = 1),
              bsTooltip(
                "Number_of_States",
                "E.g. an SIRD model with states susceptible, infected, recovered and dead states should set Number of States = 4.",
                placement = "right",
                trigger = "hover"), 
              
              
              textInput("Initial_Conditions", tagList("Define the proportion of individuals to be initialized in each state, separated by semicolons", em(span("Initial Conditions", style = "color:#0072B2;")))
                        ),
              bsTooltip(
                "Initial_Conditions",
                "Define the proportion of individuals to be initialized in each state, separated by semicolons. Must sum to 1. E.g. 0.8;0.1;0.1;0",
                placement = "right",
                trigger = "hover"), 
            
              
              textInput("Susceptible_States",
                        tagList("Define the state considered succeptible", em(span("Susceptible States", style = "color:#0072B2;")))),
              bsTooltip(
                "Susceptible_States",
                "Define the state considered succeptible. Typically this is state 0.",
                placement = "right",
                trigger = "hover"), 
              
              
              textInput("Infection_States",
                        tagList("Define the state considered infected", em(span("Infection States", style = "color:#0072B2;")))
                        ),
              bsTooltip(
                "Infection_States",
                "Define the state considered infected, using numbering starting at 0. E.g. for an SIRD model, the infection state = 1.",
                placement = "right",
                trigger = "hover"), 
              
              
              radioButtons("Include_Death_States", "Do you want to include a death state?",
                           choices = c("No", "Yes"), 
                           selected = "No", 
                           inline = TRUE),
              conditionalPanel(
                condition = "input.Include_Death_States == 'Yes'",
              textInput("Death_States", 
                        tagList("Define the state used for mortality", em(span("Death States", style = "color:#0072B2;")))),
              bsTooltip(
                "Death_States",
                "Define the state used for mortality, using numbering starting at 0. E.g. for an SIRD model, the death state 3. If there is no death state, use 'N'.",
                placement = "right",
                trigger = "hover")
              ), 
              
              wellPanel(
              h4("Initialize offspring states"),
              helpText("Susceptible: All are born in state 0 (Default)."),
              helpText("Random: Drawn from initial conditions."),
              helpText("Vertical_X:Y: Vertical transmission from infected mothers with mean rate X and standard deviation Y."),
              radioButtons("Initial_Conditions_Offspring", 
                           tagList("Define how to initialize offspring states", em(span("Initial Conditions Offspring", style = "color:#0072B2;"))),
                           choices = c("Susceptible", "Random", "Vertical_X:Y"), 
                           selected = "Susceptible", 
                           inline = TRUE)
              ),
              
              
              numericInput("Start_Disease", tagList("Define the time step to initiate disease spread.", em(span("Start Disease", style = "color:#0072B2;"))), 
                           value = 0,
                           min = 0, step = 1),
              bsTooltip(
                "Start_Disease",
                "Enter an integer for the time step to initiate disease spread.",
                placement = "right",
                trigger = "hover"),          
              
              
              radioButtons("Transmission_Mode", "Define transmission mode",
                           choices = c("Direct", "Indirect"), 
                           selected = "Direct", 
                           inline = TRUE),
              bsTooltip(
                "Transmission_Mode",
                "Direct: Transmission from individual to individual
                Indirect: Transmission from patch environmental contaminants to individuals. 
                Note 'Direct' is also included here but can be excluded via the Transition Matrix file.",
                placement = "right",
                trigger = "hover"), 
              
              
              radioButtons("Apply_Disease_Resistant", "Do you want to include a disease resistance genotype?",
                           choices = c("No", "Yes"), 
                           selected = "No", 
                           inline = TRUE),
              
              conditionalPanel(
                condition = "input.Apply_Disease_Resistant == 'Yes'",
                textInput("Disease_Resistant", "Define the transition rate(s) modified by the resistance genotype.")),
              bsTooltip(
                "Disease_Resistant",
                "Define the transition rate(s) modified by genotype 'RR'. E.g. '0_1;3_1' indicates that the transition rate from state 0 to state 1 will be affected as well as the transition rate from state three to state 1.",
                placement = "right",
                trigger = "hover"), 
              
              
              radioButtons("Apply_Disease_Tolerant", "Do you want to include a disease tolerance genotype?",
                           choices = c("No", "Yes"), 
                           selected = "No", 
                           inline = TRUE),
              conditionalPanel(
                condition = "input.Apply_Disease_Tolerant == 'Yes'",
                textInput("Disease_Tolerant", "Define the transition rate(s) modified by the tolerance genotype."),
                bsTooltip(
                  "Disease_Tolerant",
                  "Define the transition rate(s) modified by genotype 'TT. E.g. '0_1;3_1' indicates that the transition rate from state 0 to state 1 will be affected as well as the transition rate from state three to state 1.",
                  placement = "right",
                  trigger = "hover")
              ),
              actionButton("update_disease_vars_file", "Update Disease Vars File"),
              
        ), #Disease tab panel
        
        ########################################
        ####         Preview tab            ####
        ########################################
        
        tabPanel("Preview Updated DiseaseVars",
                 tableOutput("preview_template")
        ) 
      ) # tabset panel
    ) # main panel
  ) # sidebar layout
  ) # fluidpage
  
  ############################################
  ################ SERVER ####################
  ############################################
  
  server <- function(input, output, session) {
    
    template_data <- reactiveVal(template)
    
    # Track whether the startup reminder has already been shown
    startup_warning_shown <- reactiveVal(FALSE)
    
    # Helper function to show apply changes reminder 
    show_tab_apply_changes <- function(tab_name) {
      showModal(
        modalDialog(
          title = "If you change parameters on any tab, remember to click on 'Apply changes' buttons",
          p("The 'Apply changes' buttons are necessary to update the values of the final input file."),
          easyClose = TRUE,
          footer = modalButton("Got it!")
        )
      )
    }
    
    observeEvent(input$main_tabs, {
      if (startup_warning_shown()) {
        return()
      }
      
      if (!is.null(input$main_tabs) && input$main_tabs == "Patches") {
        startup_warning_shown(TRUE)
        show_tab_apply_changes("Patches")
      }
    }, ignoreInit = FALSE)
    ###################################
    ####    Directory Help button  ####
    ###################################
    observeEvent(input$directory_help, {
      showModal(
        modalDialog(
          title = "How to Organize Your Data Directory",
          helpText(
            "Please organize your data in the following way:",
            "1. Create a main folder named ", strong("data"), ".",
            "2. Inside the data folder, place the ", code("runVars.csv"), "file.",
            "3. Also inside the data folder, create the following subdirectories:",
            br(), "   * ", code("popvars"), " - contains file ", code("popVars.csv"),
            br(), "   * ", code("patchvars"), " - contains file ", code("patchVars.csv"),
            br(), "   * ", code("classvars"), " - contains file ", code("classVars"),
            br(), "   * ", code("genes"), " - contains files ", code("allele frequency files (.csv)"),
            br(), "   * ", code("cdmats"), " - contains files for movement matrices",
            br(), "   * ", code("otherfiles"), " - contains other files, e.g. correlation matrices",
            br(), br(),
            "The correct structure should look like this:"
          ),
          tags$pre(
            "data/
|
|-- runVars.csv
|
|-- popvars/
|   |--popVars.csv
|
|-- patchvars/
|   |--patchVars.csv
|
|--classvars/
|   |--classVars.csv
|
|--genes/
|   |--allelefrequencies.csv
|
|--cdmats/
|   |-- cdmat1.csv
|   |-- cdmat2.csv
|   |--cdmat3.csv
|
|--otherfiles/
|   |-- correlation_matrix1.csv
|   |--correlation_matrix2.csv
|   |--Disease/
|   |   |--DiseaseVars.csv
|   |   |--TransitionMatrix.csv"
            
          ),
          easyClose = TRUE,
          footer = modalButton("Close")
        )
      )
    })
    
    
    ###################################################
    ####              SIDEPANEL UPDATE             ####
    ###################################################
    
    transition_matrix_help_text <- modalDialog(
      title = "Instructions for Transition Matrix",
      p("The disease matrix requires an additional Transition Matrix to define the mean probabilistic rates of moving from one state to another"),
      p("The matrix must be square (Number of states x Number of states)."),
      p("For a simple SIR model where individuals move from Susceptible (S, state 0) to Infected (I, state 1) at rate beta, and from Infected (I, state 1) to Recovered (R, state 2) at rate gamma, the file would look like this:"),
      p("# TO (rows) FROM (cols)"),
      p("# S, I, R"),
      p("0.0, 0.0, 0.0"),
      p("0.5, 0.0, 0.0  # This is beta, the S -> I transition rate"),
      p("0.0, 0.2, 0.0  # This is gamma, the I -> R transition rate"),
      p("Note: The S -> I transition rate (beta) is treated as the transmission rate and is multiplied by the proportion of infected individuals (I/N) in the patch to determine the final probability of infection for a susceptible individual."),
      p("See CDmetaPOP user manual for more detailed information about the disease module"),
      easyClose = TRUE,
      footer = modalButton("Close")
    )
    
    # Update Transition Matrix text
    observeEvent(input$help_transition_matrix, { showModal(transition_matrix_help_text) })
    
    observeEvent(input$update_TransitionMatrix, {
      req(input$Transition_Rates_file)
      
      # Update only the 'Transition Rates' column with the subdir name
      temp <- template_data()
      temp$Transition_Rates <- input$Transition_Rates_file
      template_data(temp)
    })
    

    ###################################################
    ####             MAIN PANEL UPDATE             ####
    ###################################################

    ###################################################
    ####            Update DiseaseVars             ####
    ###################################################
    observeEvent(input$update_disease_vars_file, {
      temp <- template_data()
      
      if (input$update_disease_vars_file == "Yes") {
        temp$`Number of States` <- as.integer(input$Number_of_States)
        temp$`Initial Conditions` <- input$Initial_Conditions
        temp$`Transition Rates` <- input$Transition_Rates
        temp$`Susceptible States` <- input$Susceptible_States
        temp$`Infection States` <- input$Infection_States
        temp$`Death States` <- input$Death_States
        temp$`Initial Conditions Offspring` <- input$Initial_Conditions_Offspring
        temp$`Start Disease` <- input$Start_Disease
        temp$`Transmission Mode` <- input$Transmission_Mode
        temp$`Disease Resistant` <- input$Disease_Resistant
        temp$`Disease Tolerant` <- input$Disease_Tolerant
        
      } else {
        temp$`Number of States` <- as.integer(input$Number_of_States)
        temp$`Initial Conditions` <- input$Initial_Conditions
        temp$`Transition Rates` <- input$Transition_Rates
        temp$`Susceptible States` <- input$Susceptible_States
        temp$`Infection States` <- input$Infection_States
        temp$`Death States` <- input$Death_States
        temp$`Initial Conditions Offspring` <- input$Initial_Conditions_Offspring
        temp$`Start Disease` <- input$Start_Disease
        temp$`Transmission Mode` <- input$Transmission_Mode
        temp$`Disease Resistant` <- input$Disease_Resistant
        temp$`Disease Tolerant` <- input$Disease_Tolerant
      }
      
      template_data(temp)
    })
    
    ###################################################
    ####             Update Preview tab            ####
    ###################################################
    
    output$preview_template <- renderTable({
      template_data()
    })
    
    
    ##############################################
    ####             Download Handler         ####
    ##############################################
    output$download_diseasevars <- downloadHandler(
      filename = function() {
        "DiseaseVars.csv"
      },
      content = function(file) {
        write.csv(template_data(), file, row.names = FALSE, quote = FALSE)
      }
    )
    
  }
  
  shinyApp(ui = ui, server = server)
}      
      