#' Build ClassVars File from Template
#'
#' This function loads a provided ClassVars template, allows the user to edit selected areas,
#' and saves the modified version as a new file.
#'
#' @param output_file The name of the output file. Defaults to 'my_new_classvars.csv'.
#' @return A Shiny app instance.
#' @import shiny
#' @import shinyBS
#' @export
#' 
make_classvars <- function(output_file = "my_new_classvars.csv") {

  # Template 
  template <- data.frame(
    `Age class` = 0, `Body Size Mean (mm)` = NA, `Body Size Std (mm)` = NA,
    Distribution = 0, 
    `Sex Ratio` = "0.5~0.5", 
    `Age Mortality Out %` = "N", `Age Mortality Out StDev` = 0, 
    `Age Mortality Back %` = "N", `Age Mortality Back StDev` = 0,
    `Size Mortality Out %` = "N", `Size Mortality Out StDev` = 0,
    `Size Mortality Back %` = "0.1~0.1", `Size Mortaltiy Back StDev` = 0,
    `Migration Out Prob` = 0, `Migration Back Prob` = 0, 
    `Straying Prob` = 0, `Dispersal Prob` = 0,
    Maturation = "0", `Fecundity Ind` = 0, `Fecundity Ind StDev` = 0,
    `Fecundity Leslie` = 0, `Fecundity Leslie StDev` = 0, 
    `Capture Out Probability` = "N", `Capture Back Probability` = "N", 
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
    titlePanel("Build a ClassVars.csv File"),
    p(
      "Welcome! This shiny app instance will help you put together a ClassVars.csv file to use as a CDmetaPOP input file.",
      "Select parameters below to reflect your system."
    ),
    
    ###################################
    # SIDE PANEL 
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
        downloadButton("download_classvars", "Download ClassVars File")
      ),
      
      ############################################
      # MAIN PANEL
      ############################################    
      
      mainPanel(
        tabsetPanel(
          id = "main_tabs",
          ########################################
          # Age & Size tab
          ########################################
          tabPanel("Age & Size",
                   helpText(
                     "Please define the number of possible age classes allowed in your system, if it is more than one, please enter the average size and standard deviation for size initialization at each age class stage.",
                     "."
                   ),
                   numericInput(
                     inputId = "age_max",
                     label = tagList(
                       "Define the number of possible age classes allowed in your system: ",
                       em(span("Age class", style = "color:#0072B2;"))
                     ),
                     value = 0, min = 0, step = 1
                   ),
                   
                   uiOutput("body_size_inputs"),
                   
                   actionButton("update_ages", "Apply changes"),
          ),
          ########################################
          # Distribution tab
          ########################################
          tabPanel("Distribution",
                   helpText("This parameter specifies the age class distribution at initialization. Depending on how many age classes you defined in the Age & Size tab, you can specify the distribution of individuals across those age classes at initialization. The values should sum to 1. For example, if you have 3 age classes and want an even distribution, you would enter 0.33 for each class."),
                   uiOutput("distribution_inputs"),
                   actionButton("update_distribution", "Apply changes"),
          ),
          
          
          ########################################
          # Sex ratio tab
          ########################################
          tabPanel("Sex Ratio",
                   helpText("Initializes the sex of the population which can give a ratio of females to males per age class. Up to 4 values may be specified here: e.g., 0.5~0.5~0, for females~males~trojan YY males. The values must equal 1, be separated with a tilda (~), and the number of values provided must be equal to the value given for the sex_chromo variable in the PopVars file.   
                            *A special case for Wright Fisher assumption can be specified here by entering ‘WrightFisher’ and only should be used when considering a panmictic population (see CDMetaPOP manual on Special Cases for more details). 
                            "), 
                   textInput("sex_ratio", tagList("Enter the sex ratio at initialization (e.g. 0.5~0.5 for 50% males & 50% females): ", em(span("Sex Ratio", style = "color:#0072B2;"))), 
                             value = "0.5~0.5"),
                   actionButton("update_sex_ratio", "Apply changes"),
          ),
          ########################################
          # Mortality tab
          ########################################
          tabPanel("Mortality",
                   helpText("Parameters entered here will be compounded with patch and size level mortalities and should range between 0 and 1 (0 = no mortality, 1 = 100% mortality)."),  
                   helpText("Warning! These parameters will interact with patch specific values (PatchVars.csv) See user manual for how class and patch interact."),
                   radioButtons("apply_mortality", "Apply Mortality Parameters?",
                                choices = c("No", "Yes"), 
                                selected = "No", 
                                inline = TRUE),
                   
                   # Show mortality settings only if 'Yes' is selected
                   conditionalPanel(
                     condition = "input.apply_mortality == 'Yes'",
                     textInput("age_mortality_out", tagList("Define age specific mortality out from natal grounds [0-1] or 'N' for no mortality: ", em(span("Age Mortality Out %", style = "color:#0072B2;"))), 
                               value = "N"),
                     numericInput("age_mortality_out_sd", tagList("Define standard deviation for age specific mortality out from natal grounds: ", em(span("Age Mortality Out StDev", style = "color:#0072B2;"))), 
                                  value = 0, min = 0, step = 0.01),
                     textInput("age_mortality_back", tagList("Define age specific mortality back at natal grounds [0-1] or 'N' for no mortality: ", em(span("Age Mortality Back %", style = "color:#0072B2;"))), 
                               value = "N"),
                     numericInput("age_mortality_back_sd", tagList("Define standard deviation for age specific mortality back at natal grounds: ", em(span("Age Mortality Back StDev", style = "color:#0072B2;"))), 
                                  value = 0, min = 0, step = 0.01),
                     textInput("size_mortality_out", tagList("Define size specific mortality out from natal grounds [0-1] or 'N' for no mortality: ", em(span("Size Mortality Out %", style = "color:#0072B2;"))), 
                               value = "N"),
                     numericInput("size_mortality_out_sd", tagList("Define standard deviation for size specific mortality out from natal grounds: ", em(span("Size Mortality Out StDev", style = "color:#0072B2;"))), 
                                  value = 0, min = 0, step = 0.01),
                     textInput("size_mortality_back", tagList("Define size specific mortality back at natal grounds [0-1] or 'N' for no mortality: ", em(span("Size Mortality Back %", style = "color:#0072B2;"))), 
                               value = "0.1~0.1"),
                     numericInput("size_mortality_back_sd", tagList("Define standard deviation for size specific mortality back at natal grounds: ", em(span("Size Mortality Back StDev", style = "color:#0072B2;"))), 
                                  value = 0, min = 0, step = 0.01),
                     actionButton("update_mortality", "Apply changes")
                   ),
          ),
          
          ########################################
          # Movement tab
          ########################################
          
          tabPanel("Movement",
                   helpText("Parameters entered here will define movement, dispersal, and straying."),
                   helpText("Warning! These parameters will be multiplied by patch specific values from the PatchVars.csv. See user manual for how class and patch interact."),
                   
                   radioButtons("apply_movement", "Apply Movement Parameters?",
                                choices = c("No", "Yes"), 
                                selected = "No", 
                                inline = TRUE),
                   
                   # Show movement settings only if 'Yes' is selected
                   conditionalPanel(
                     condition = "input.apply_movement == 'Yes'",
                     numericInput("migration_out_prob", tagList("Enter the emigration probability [0-1] applied before moving to rearing/overwinter grounds. ", em(span("Migration Out Prob", style = "color:#0072B2;"))), 
                                  value = 0,
                                  min = 0, max = 1, step = 0.05),
                     numericInput("migration_back_prob", tagList("Set return probability [0-1] (Set these values to 1 for patch level control on migration) ", em(span("Migration Back Prob", style = "color:#0072B2;"))), 
                                  value = 1, # 
                                  min = 0, max = 1, step = 0.05),
                     numericInput("straying_prob", tagList("Set straying probability [0-1] of a migrant straying to a patch other than their natal patch ", em(span("Straying Prob", style = "color:#0072B2;"))),
                                  value = 0,
                                  min = 0, max = 1, step = 0.05),
                     numericInput("dispersal_prob", tagList("Set dispersal probability [0-1] of an individual undergoing annual dispersal from their natal/spawning patch", em(span("Dispersal Prob", style = "color:#0072B2;"))), 
                                  value = 0,
                                  min = 0, max = 1, step = 0.05),
                     actionButton("update_movement", "Apply changes")
                   ),
          ),
          
          
          ########################################
          # Reproduction tab
          ########################################
          tabPanel("Reproduction",
                   helpText("Define the probability of being a reproductively mature individual and stay this way."), 
                   
                   uiOutput("Maturation_inputs"),
                   helpText("If size option is specified (sizecontrol in RunVars), then these values are not used and population fit parameters based on size/length relationships are used instead. 3 sex class values can be used here, as well, separated by ‘~’."),
                   
                   actionButton("update_Maturation", "Apply changes"),
                   
                   radioButtons("apply_reproduction", "Do you want to change specific reproduction options?",
                                choices = c("No", "Yes"), 
                                selected = "No", 
                                inline = TRUE),
                   
                   helpText("These parameters can be changed manually for each class. The choices offered below will change reproduction options for all classes."),
                   
                   # Show reproduction settings only if 'Yes' is selected
                   conditionalPanel(
                     condition = "input.apply_reproduction == 'Yes'",
                     
                     numericInput("Fecundity_Ind", tagList("Define litter size or egg number: ", em(span("Fecundity Ind", style = "color:#0072B2;"))), 
                                  value = 0),
                     numericInput("Fecundity_Ind_StDev", tagList("Define litter size or egg number standard deviation: ", em(span("Fecundity Ind StDev", style = "color:#0072B2;"))), 
                                  value = 0),
                     numericInput("Fecundity_Leslie", tagList("Define fecundity values specific to the Leslie matrix model: ", em(span("Fecundity Leslie", style = "color:#0072B2;"))), 
                                  value = 0),
                     numericInput("Fecundity_Leslie_StDev", tagList("Define standard deviation fecundity values specific to the Leslie matrix model: ", em(span("Fecundity Leslie StDev", style = "color:#0072B2;"))),
                                  value = 0),
                     
                     actionButton("update_reproduction", "Apply changes")
                   ),
          ),
          
          ########################################
          # Capture Probabilities tab
          ########################################
          
          tabPanel("Capture Probabilities",
                   helpText("Parameters entered here will define capture probabilities for individuals based on their location (in natal grounds vs out from natal grounds)."),
                   
                   radioButtons("apply_capture_prob", "Do you want to apply class specific capture probabilities?",
                                choices = c("No", "Yes"), 
                                selected = "No", 
                                inline = TRUE),
                   
                   # Show capture probability settings only if 'Yes' is selected
                   conditionalPanel(
                     condition = "input.apply_capture_prob == 'Yes'",
                     
                     numericInput("Capture_Out_Probability", tagList("Define the capture probability when individuals are out from natal grounds [0-1]: ", em(span("Capture Out Probability", style = "color:#0072B2;"))), 
                                  value = 0, 
                                  min = 0, step = 0.05, max = 1),
                     
                     numericInput("Capture_Back_Probability", tagList("Define the capture probability when individuals are back at natal grounds [0-1]: ", em(span("Capture Back Probability", style = "color:#0072B2;"))), 
                                  value = 0,
                                  min = 0, max = 1, step = 0.05),
                     
                     actionButton("update_capture_prob", "Apply changes")
                   ),
          ),
          
          
          ########################################
          # Preview tab
          ########################################
          tabPanel("Preview Updated ClassVars",
                   tableOutput("preview_template")
          )
        )
      )
    )
  )
  
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
      
      if (!is.null(input$main_tabs) && input$main_tabs == "Age & Size") {
        startup_warning_shown(TRUE)
        show_tab_apply_changes("Age & Size")
      }
    }, ignoreInit = FALSE)
    
    #####################################################
    # SIDE PANEL HELP
    #####################################################
    
    
    ###################################
    # Directory Help button
    ###################################
    observeEvent(input$directory_help, {
      showModal(
        modalDialog(
          title = "How to Organize Your Data Directory",
          helpText(
            "Directories and input files can have any name. The following is an example method for structuring your input files.",
            "1. Create a main folder named ", strong("data"), ".",
            "2. Inside the data folder, place the ", code("runVars.csv"), "file.",
            "3. Also inside the data folder, you may want to create the following subdirectories:",
            br(), "   • ", code("popvars"), " — contains file ", code("popVars.csv"),
            br(), "   • ", code("patchvars"), " — contains file ", code("patchVars.csv"),
            br(), "   • ", code("classvars"), " — contains file ", code("classVars"),
            br(), "   • ", code("genes"), " — contains files ", code("allele frequency files (.csv)"),
            br(), "   • ", code("cdmats"), " — contains files for movement matrices",
            br(), "   • ", code("otherfiles"), " — contains other files, e.g. correlation matrices",
            br(), br(),
            "The file structure should look something like this:"
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
    
    
    ###################################################
    # MAIN PANEL UPDATE
    ###################################################
    
    ###################################################
    # update Ages & Size tab
    ###################################################
    observeEvent(input$update_ages, {
      req(input$age_max >= 0) # Allow age_max to be 0
      
      temp <- template_data()
      
      # Get number of rows needed (current row or age_max, whichever is larger)
      current_rows <- nrow(temp)
      needed_rows <- max(current_rows, input$age_max + 1) # add 1 for the zeroth age class
      
      # Expand template if needed
      if (needed_rows > current_rows) {
        additional_rows <- needed_rows - current_rows
        new_rows <- temp[1, ]
        new_rows[] <- NA  # Set all values to NA
        temp <- rbind(temp, new_rows[rep(1, additional_rows), ])
      }
      
      # Update age class column
      temp$`Age class` <- 0:input$age_max
      
      # Update body size columns
      for (age in 0:input$age_max) {
        if (age <= nrow(temp)) {
          temp$`Body Size Mean (mm)`[age + 1] <- input[[paste0("Body_Size_Mean_", age)]]
          temp$`Body Size Std (mm)`[age + 1] <- input[[paste0("Body_Size_Std_", age)]]
        }
      }
      
      template_data(temp)
      
    })
    
    # Generate dynamic body size inputs based on age_max
    output$body_size_inputs <- renderUI({
      req(input$age_max >= 0) # Allow age_max to be 0
      
      age_classes <- 0:input$age_max
      
      tagList(
        h5("Please enter the body size parameters for initialization at each age class stage:", em(span("Body Size Mean (mm) & Body Size Mean Std (mm)", style = "color:#0072B2;"))),
        lapply(age_classes, function(age) {
          fluidRow(
            column(6,
                   numericInput(
                     inputId = paste0("Body_Size_Mean_", age),
                     label = tagList("Age ", age, " - Mean (mm): ", 
                     ),
                     value = 0,  # default values
                     min = 0,
                     step = 0.1
                   )
            ),
            column(6,
                   numericInput(
                     inputId = paste0("Body_Size_Std_", age),
                     label = tagList("Age ", age, " - Std (mm): ", 
                     ),
                     value = 0,  # default values
                     min = 0,
                     step = 0.1
                   )
            )
          )
        })
      )
    })
    
    # Smart auto-fill using existing template values
    observeEvent(input$age_max, {
      req(input$age_max >= 0)
      
      temp <- template_data()
      current_rows <- nrow(temp)
      needed_rows <- max(current_rows, input$age_max + 1)
      
      # Expand template if needed
      if (needed_rows > current_rows) {
        additional_rows <- needed_rows - current_rows
        new_rows <- temp[1, ]
        new_rows[] <- NA
        temp <- rbind(temp, new_rows[rep(1, additional_rows), ])
      }
      
      # Update age class column
      temp$`Age class` <- 0:input$age_max
      
      # Auto-fill all columns with existing template values
      # This preserves any values already entered
      for (col in names(temp)) {
        if (col != "Age class" && !is.na(temp[[col]][1])) {
          # Fill all rows with the value from first row
          temp[[col]] <- temp[[col]][1]
        }
      }
      
      template_data(temp)
    })
    ###################################################
    # update Distribution tab
    ###################################################
    observeEvent(input$update_distribution, {
      req(input$age_max >= 0)
      
      temp <- template_data()
      current_rows <- nrow(temp)
      needed_rows <- max(current_rows, input$age_max + 1)
      
      if (needed_rows > current_rows) {
        additional_rows <- needed_rows - current_rows
        new_rows <- temp[1, ]
        new_rows[] <- NA
        temp <- rbind(temp, new_rows[rep(1, additional_rows), ])
      }
      
      # Get distribution values from inputs
      distribution_values <- numeric(0)
      for (age in 0:input$age_max) {
        if (age <= nrow(temp)) {
          distribution_values <- c(distribution_values, input[[paste0("Distribution_", age)]])
        }
      }
      
      # Check if distribution values sum to 1
      total_distribution <- sum(distribution_values, na.rm = TRUE)
      
      if (!is.na(total_distribution) && abs(total_distribution - 1) > 0.001) {
        showNotification(paste("Distribution values must sum to 1. Current sum:", round(total_distribution, 3)), 
                         type = "error", duration = 5)
        return()  # Stop execution
      }
      
      # Update distribution column
      for (age in 0:input$age_max) {
        if (age <= nrow(temp)) {
          temp$`Distribution`[age + 1] <- input[[paste0("Distribution_", age)]]
        }
      }
      
      template_data(temp)
      showNotification("Distribution parameters updated successfully!", type = "message")
    })
    
    # Generate dynamic distribution inputs based on age_max
    output$distribution_inputs <- renderUI({
      req(input$age_max >= 0) # Allow age_max to be 0
      
      age_classes <- 0:input$age_max
      
      tagList(
        h5("Please enter the distribution parameters for initialization at each age class stage:", em(span("Distribution", style = "color:#0072B2;"))),
        lapply(age_classes, function(age) {
          fluidRow(
            column(6,
                   numericInput(
                     inputId = paste0("Distribution_", age),
                     label = tagList("Age ", age, " - Distribution: "),
                     value = 0,  # default values
                     min = 0,
                     step = 0.1
                   )
            )
          )
        })
      )
    })
    ###################################################
    # update Sex Ratio tab
    ###################################################
    
    observeEvent(input$update_sex_ratio, {
      req(input$age_max >= 0)
      
      temp <- template_data()
      current_rows <- nrow(temp)
      needed_rows <- max(current_rows, input$age_max + 1)
      
      # Expand template if needed
      if (needed_rows > current_rows) {
        additional_rows <- needed_rows - current_rows
        new_rows <- temp[1, ]
        new_rows[] <- NA
        temp <- rbind(temp, new_rows[rep(1, additional_rows), ])
      }
      
      # Update Sex Ratio for ALL rows (automatic fill)
      temp$`Sex Ratio` <- input$sex_ratio
      
      template_data(temp)
      showNotification("Sex ratio parameters updated successfully!", type = "message")
    })
    
    ###################################################
    # update Mortality tab
    ###################################################
    observeEvent(input$update_mortality, {
      temp <- template_data()
      
      if (input$apply_mortality == "Yes") {
        temp$`Age Mortality Out %` <- input$age_mortality_out
        temp$`Age Mortality Out StDev` <- input$age_mortality_out_sd
        temp$`Age Mortality Back %` <- input$age_mortality_back
        temp$`Age Mortality Back StDev` <- input$age_mortality_back_sd
        temp$`Size Mortality Out %` <- input$size_mortality_out
        temp$`Size Mortality Out StDev` <- input$size_mortality_out_sd
        temp$`Size Mortality Back %` <- input$size_mortality_back
        temp$`Size Mortaltiy Back StDev` <- input$size_mortality_back_sd
      } else {
        temp$`Age Mortality Out %` <- "N"
        temp$`Age Mortality Out StDev` <- 0
        temp$`Age Mortality Back %` <- "N"
        temp$`Age Mortality Back StDev` <- 0
        temp$`Size Mortality Out %` <- "N"
        temp$`Size Mortality Out StDev` <- 0
        temp$`Size Mortality Back %` <- "0.1~0.1"
        temp$`Size Mortaltiy Back StDev` <- 0
      }
      
      template_data(temp)
    })
    
    ###################################################
    # update Movement tab
    ###################################################
    observeEvent(input$update_movement, {
      temp <- template_data()
      
      if (input$apply_movement == "Yes") {
        temp$`Migration Out Prob` <- input$migration_out_prob
        temp$`Migration Back Prob` <- input$migration_back_prob
        temp$`Straying Prob` <- input$straying_prob
        temp$`Dispersal Prob` <- input$dispersal_prob
      } else {
        temp$`Migration Out Prob` <- 0
        temp$`Migration Back Prob` <- 0
        temp$`Straying Prob` <- 0
        temp$`Dispersal Prob` <- 0
      }
      template_data(temp)
    })
    ###################################################
    # update Reproduction tab
    ###################################################
    observeEvent(input$update_Maturation, {
      req(input$age_max >= 0)
      
      temp <- template_data()
      current_rows <- nrow(temp)
      needed_rows <- max(current_rows, input$age_max + 1)
      
      if (needed_rows > current_rows) {
        additional_rows <- needed_rows - current_rows
        new_rows <- temp[1, ]
        new_rows[] <- NA
        temp <- rbind(temp, new_rows[rep(1, additional_rows), ])
      }
      
      # Get Maturation values from inputs
      maturation_values <- numeric(0)
      for (age in 0:input$age_max) {
        if (age <= nrow(temp)) {
          maturation_values <- c(maturation_values, input[[paste0("Maturation_", age)]])
        }
      }
      
      
      # Update maturation column
      for (age in 0:input$age_max) {
        if (age <= nrow(temp)) {
          temp$`Maturation`[age + 1] <- input[[paste0("Maturation_", age)]]
        }
      }
      
      template_data(temp)
      
    })
    
    # Generate dynamic maturation inputs based on age_max
    output$Maturation_inputs <- renderUI({
      req(input$age_max >= 0) # Allow age_max to be 0
      
      age_classes <- 0:input$age_max
      
      tagList(
        h5("Please enter the maturation parameters for initialization at each age class stage:", em(span("Maturation", style = "color:#0072B2;"))),
        lapply(age_classes, function(age) {
          fluidRow(
            column(6,
                   textInput(
                     inputId = paste0("Maturation_", age),
                     label = tagList("Age ", age, " - Maturation (e.g., 4~3~2): "),
                     value = "0",  # default as string
                     placeholder = "e.g., 4~3~2 for 3 sex classes"
                   )
            )
          )
        })
      )
    })
    ############
    
    observeEvent(input$update_reproduction, {
      temp <- template_data()
      
      if (input$apply_reproduction == "Yes") {
        temp$`Fecundity Ind` <- input$Fecundity_Ind
        temp$`Fecundity Ind StDev` <- input$Fecundity_Ind_StDev
        temp$`Fecundity Leslie` <- input$Fecundity_Leslie
        temp$`Fecundity Leslie StDev` <- input$Fecundity_Leslie_StDev
      } else {
        temp$`Fecundity Ind` <- 0
        temp$`Fecundity Ind StDev` <- 0
        temp$`Fecundity Leslie` <- 0
        temp$`Fecundity Leslie StDev` <- 0
      }
      
      template_data(temp)
    })
    
    ###################################################
    # update Capture Probabilities tab
    ###################################################
    observeEvent(input$update_capture_prob, { ##### FIX THIS  BECAUSE IT IS NOT UPDATING PROPERLY
      temp <- template_data()
      
      if (input$apply_capture_prob == "Yes") {
        temp$`Capture Out Probability` <- input$Capture_Out_Probability
        temp$`Capture Back Probability` <- input$Capture_Back_Probability
      } else {
        temp$`Capture Out Probability` <- "N"
        temp$`Capture Back Probability` <- "N"
      }
      
      template_data(temp)
    })
    
    ###################################################
    # update Preview tab
    ###################################################
    
    output$preview_template <- renderTable({
      template_data()
    })
    
    # Download updated template
    output$download_classvars <- downloadHandler(
      filename = function() {
        "ClassVars.csv"
      },
      content = function(file) {
        write.csv(template_data(), file, row.names = FALSE)
      }
    )
    
    
    
  }
  
  shinyApp(ui = ui, server = server)
}

