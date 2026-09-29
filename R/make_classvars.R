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
                            *A special case for Wright Fisher assumption can be specified here by entering 'WrightFisher' and only should be used when considering a panmictic population (see CDMetaPOP manual on Special Cases for more details). 
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
                     textInput("age_mortality_out", tagList("Define age specific mortality out from natal grounds [0-1] or 'N' for no mortality (comma-separated values for each age class): ", em(span("Age Mortality Out %", style = "color:#0072B2;"))), 
                               value = "N"),
                     bsTooltip(
                       "age_mortality_out",
                       "Enter values with sexes separated by ~ and ages within each sex separated by ,. Example: if Age class = 2 with 3 sexes, enter '0,0.1,0.2~0,0.1,0.2~1,0.3,0.5' (sex1: ages 0,1,2; sex2: ages 0,1,2; sex3: ages 0,1,2). For equal mortality across all ages, enter single value per sex: '0.6~0.3' (replicates across all ages). Values must be between 0 and 1. Enter 'N' for no mortality.",
                       placement = "right",
                       trigger = "hover"),
                     textInput("age_mortality_out_sd", tagList("Define standard deviation for age specific mortality out from natal grounds (comma-separated values for each age class): ", em(span("Age Mortality Out StDev", style = "color:#0072B2;"))), 
                               value = "0"),
                     bsTooltip(
                       "age_mortality_out_sd",
                       "Enter values with sexes separated by ~ and ages within each sex separated by ,. Example: if Age class = 2 with 3 sexes, enter '0,0.01,0.02~0,0.01,0.02~0.01,0.03,0.05' (sex1: ages 0,1,2; sex2: ages 0,1,2; sex3: ages 0,1,2).",
                       placement = "right",
                       trigger = "hover"),
                     textInput("age_mortality_back", tagList("Define age specific mortality back at natal grounds [0-1] or 'N' for no mortality (comma-separated values for each age class): ", em(span("Age Mortality Back %", style = "color:#0072B2;"))), 
                               value = "N"),
                     bsTooltip(
                       "age_mortality_back",
                       "Enter values with sexes separated by ~ and ages within each sex separated by ,. Example: if Age class = 2 with 3 sexes, enter '0,0.1,0.2~0,0.1,0.2~1,0.3,0.5' (sex1: ages 0,1,2; sex2: ages 0,1,2; sex3: ages 0,1,2). For equal mortality across all ages, enter single value per sex: '0.6~0.3' (replicates across all ages). Values must be between 0 and 1. Enter 'N' for no mortality.",
                       placement = "right",
                       trigger = "hover"),
                     textInput("age_mortality_back_sd", tagList("Define standard deviation for age specific mortality back at natal grounds (comma-separated values for each age class): ", em(span("Age Mortality Back StDev", style = "color:#0072B2;"))), 
                               value = "0"),
                     bsTooltip(
                       "age_mortality_back_sd",
                       "Enter values with sexes separated by ~ and ages within each sex separated by ,. Example: if Age class = 2 with 3 sexes, enter '0,0.01,0.02~0,0.01,0.02~0.01,0.03,0.05' (sex1: ages 0,1,2; sex2: ages 0,1,2; sex3: ages 0,1,2).",
                       placement = "right",
                       trigger = "hover"),
                     textInput("size_mortality_out", tagList("Define size specific mortality out from natal grounds [0-1] or 'N' for no mortality (comma-separated values for each age class): ", em(span("Size Mortality Out %", style = "color:#0072B2;"))), 
                               value = "N"),
                     textInput("size_mortality_out_sd", tagList("Define standard deviation for size specific mortality out from natal grounds (comma-separated values for each age class): ", em(span("Size Mortality Out StDev", style = "color:#0072B2;"))), 
                               value = "0"),
                     textInput("size_mortality_back", tagList("Define size specific mortality back at natal grounds [0-1] or 'N' for no mortality (comma-separated values for each age class): ", em(span("Size Mortality Back %", style = "color:#0072B2;"))), 
                               value = "0.1~0.1"),
                     textInput("size_mortality_back_sd", tagList("Define standard deviation for size specific mortality back at natal grounds (comma-separated values for each age class): ", em(span("Size Mortality Back StDev", style = "color:#0072B2;"))), 
                               value = "0"),
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
                     textInput("migration_out_prob", tagList("Enter the emigration probability [0-1] applied before moving to rearing/overwinter grounds (comma-separated values for each age class): ", em(span("Migration Out Prob", style = "color:#0072B2;"))), 
                               value = "0"),
                     bsTooltip(
                       "migration_out_prob",
                       "Enter values with sexes separated by ~ and ages within each sex separated by ,. Example: if Age class = 2 with 3 sexes, enter '0,0.1,0.2~0,0.1,0.2~1,0.3,0.5' (sex1: ages 0,1,2; sex2: ages 0,1,2; sex3: ages 0,1,2). For equal probability across all ages, enter single value per sex: '0.6~0.3' (replicates across all ages). Values must be between 0 and 1.",
                       placement = "right",
                       trigger = "hover"),
                     textInput("migration_back_prob", tagList("Set return probability [0-1] (comma-separated values for each age class): ", em(span("Migration Back Prob", style = "color:#0072B2;"))), 
                               value = "1"),
                     bsTooltip(
                       "migration_back_prob",
                       "Enter values with sexes separated by ~ and ages within each sex separated by ,. Example: if Age class = 2 with 3 sexes, enter '0,0.1,0.2~0,0.1,0.2~1,0.3,0.5' (sex1: ages 0,1,2; sex2: ages 0,1,2; sex3: ages 0,1,2). For equal probability across all ages, enter single value per sex: '0.6~0.3' (replicates across all ages). Values must be between 0 and 1.",
                       placement = "right",
                       trigger = "hover"),
                     textInput("straying_prob", tagList("Set straying probability [0-1] of a migrant straying to a patch other than their natal patch (comma-separated values for each age class): ", em(span("Straying Prob", style = "color:#0072B2;"))),
                               value = "0"),
                     bsTooltip(
                       "straying_prob",
                       "Enter values with sexes separated by ~ and ages within each sex separated by ,. Example: if Age class = 2 with 3 sexes, enter '0,0.1,0.2~0,0.1,0.2~1,0.3,0.5' (sex1: ages 0,1,2; sex2: ages 0,1,2; sex3: ages 0,1,2). For equal probability across all ages, enter single value per sex: '0.6~0.3' (replicates across all ages). Values must be between 0 and 1.",
                       placement = "right",
                       trigger = "hover"),
                     textInput("dispersal_prob", tagList("Set dispersal probability [0-1] of an individual undergoing annual dispersal from their natal/spawning patch (comma-separated values for each age class): ", em(span("Dispersal Prob", style = "color:#0072B2;"))), 
                               value = "0"),
                     bsTooltip(
                       "dispersal_prob",
                       "Enter values with sexes separated by ~ and ages within each sex separated by ,. Example: if Age class = 2 with 3 sexes, enter '0,0.1,0.2~0,0.1,0.2~1,0.3,0.5' (sex1: ages 0,1,2; sex2: ages 0,1,2; sex3: ages 0,1,2). For equal probability across all ages, enter single value per sex: '0.6~0.3' (replicates across all ages). Values must be between 0 and 1.",
                       placement = "right",
                       trigger = "hover"),
                     actionButton("update_movement", "Apply changes")
                   ),
          ),
          
          
          ########################################
          # Reproduction tab
          ########################################
          tabPanel("Reproduction",
                   helpText("Define the probability of being a reproductively mature individual and stay this way."), 
                   
                   textInput("maturation", tagList("Define maturation parameters for each age class (comma-separated values, sex-specific values separated by ~): ", em(span("Maturation", style = "color:#0072B2;"))), 
                            value = "0"),
                   bsTooltip(
                     "maturation",
                     "Enter values with sexes separated by ~ and ages within each sex separated by ,. Example: if Age class = 2 with 3 sexes, enter '0.4,0.5,0.6~0.3,0.4,0.5~0.2,0.3,0.4' (sex1: ages 0,1,2; sex2: ages 0,1,2; sex3: ages 0,1,2). For equal maturation across all ages, enter single value per sex: '0.4~0.3' (replicates across all ages).",
                     placement = "right",
                     trigger = "hover"),
                   helpText("If size option is specified (sizecontrol in RunVars), then these values are not used and population fit parameters based on size/length relationships are used instead. Sex-specific values can be separated by '~' within each age class."),
                   
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
                     
                     textInput("Capture_Out_Probability", tagList("Define the capture probability when individuals are out from natal grounds [0-1] (comma-separated values for each age class): ", em(span("Capture Out Probability", style = "color:#0072B2;"))), 
                               value = "0"),
                     bsTooltip(
                       "Capture_Out_Probability",
                       "Enter values with sexes separated by ~ and ages within each sex separated by ,. Example: if Age class = 2 with 3 sexes, enter '0,0.1,0.2~0,0.1,0.2~1,0.3,0.5' (sex1: ages 0,1,2; sex2: ages 0,1,2; sex3: ages 0,1,2). For equal probability across all ages, enter single value per sex: '0.6~0.3' (replicates across all ages). Values must be between 0 and 1. Enter 'N' for no capture.",
                       placement = "right",
                       trigger = "hover"),
                     
                     textInput("Capture_Back_Probability", tagList("Define the capture probability when individuals are back at natal grounds [0-1] (comma-separated values for each age class): ", em(span("Capture Back Probability", style = "color:#0072B2;"))), 
                               value = "0"),
                     bsTooltip(
                       "Capture_Back_Probability",
                       "Enter values with sexes separated by ~ and ages within each sex separated by ,. Example: if Age class = 2 with 3 sexes, enter '0,0.1,0.2~0,0.1,0.2~1,0.3,0.5' (sex1: ages 0,1,2; sex2: ages 0,1,2; sex3: ages 0,1,2). For equal probability across all ages, enter single value per sex: '0.6~0.3' (replicates across all ages). Values must be between 0 and 1. Enter 'N' for no capture.",
                       placement = "right",
                       trigger = "hover"),
                     
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
            br(), "   * ", code("popvars"), " -- contains file ", code("popVars.csv"),
            br(), "   * ", code("patchvars"), " -- contains file ", code("patchVars.csv"),
            br(), "   * ", code("classvars"), " -- contains file ", code("classVars"),
            br(), "   * ", code("genes"), " -- contains files ", code("allele frequency files (.csv)"),
            br(), "   * ", code("cdmats"), " -- contains files for movement matrices",
            br(), "   * ", code("otherfiles"), " -- contains other files, e.g. correlation matrices",
            br(), br(),
            "The file structure should look something like this:"
          ),
          tags$pre(
            "data/
|
+-- runVars.csv
|
+-- popvars/
|   +-- popVars.csv
|
+-- patchvars/
|   +-- patchVars.csv
|
+-- classvars/
|   +-- classVars.csv
|
+-- genes/
|   +-- allelefrequencies.csv
|
+-- cdmats/
|   +-- cdmat1.csv
|   +-- cdmat2.csv
|   +-- cdmat3.csv
|
+-- otherfiles/
|   +-- correlation_matrix1.csv
|   +-- correlation_matrix2.csv"
            
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
      
      # Parse comma-separated values for body size
      parse_comma_values <- function(input_val, age_max) {
        values <- strsplit(as.character(input_val), ",")[[1]]
        values <- trimws(values)
        if (length(values) == 1) {
          return(rep(as.numeric(values), age_max + 1))
        }
        return(as.numeric(values))
      }
      
      # Validate and parse body size mean
      body_size_mean <- parse_comma_values(input$body_size_mean, input$age_max)
      if (length(body_size_mean) != input$age_max + 1) {
        showNotification(paste("Body Size Mean: Expected", input$age_max + 1, "values, got", length(body_size_mean)), type = "error")
        return()
      }
      
      # Validate and parse body size std
      body_size_std <- parse_comma_values(input$body_size_std, input$age_max)
      if (length(body_size_std) != input$age_max + 1) {
        showNotification(paste("Body Size Std: Expected", input$age_max + 1, "values, got", length(body_size_std)), type = "error")
        return()
      }
      
      # Update body size columns with parsed values
      for (age in 0:input$age_max) {
        if (age + 1 <= nrow(temp)) {
          temp$`Body Size Mean (mm)`[age + 1] <- body_size_mean[age + 1]
          temp$`Body Size Std (mm)`[age + 1] <- body_size_std[age + 1]
        }
      }
      
      template_data(temp)
      showNotification("Age & Size parameters updated successfully!", type = "message")
      
    })
    
    # Generate body size inputs for comma-separated values
    output$body_size_inputs <- renderUI({
      req(input$age_max >= 0)
      
      tagList(
        textInput("body_size_mean", tagList("Define body size mean for each age class (comma-separated values in mm): ", em(span("Body Size Mean (mm)", style = "color:#0072B2;"))), 
                  value = "0"),
        bsTooltip(
          "body_size_mean",
          "Enter comma-separated values for each age class. Example: if Age class = 2, enter '10,15,20' for ages 0, 1, 2. If only one value is provided, it will be replicated across all age classes.",
          placement = "right",
          trigger = "hover"),
        textInput("body_size_std", tagList("Define body size standard deviation for each age class (comma-separated values in mm): ", em(span("Body Size Mean Std (mm)", style = "color:#0072B2;"))), 
                  value = "0"),
        bsTooltip(
          "body_size_std",
          "Enter comma-separated values for each age class. Example: if Age class = 2, enter '1,2,3' for ages 0, 1, 2. If only one value is provided, it will be replicated across all age classes.",
          placement = "right",
          trigger = "hover")
      )
    })
    
    # Smart auto-fill using existing template values
    observeEvent(input$age_max, {
      req(input$age_max >= 0)
      
      temp <- template_data()
      current_rows <- nrow(temp)
      needed_rows <- input$age_max + 1
      
      # Shrink template if needed (when age_max is reduced)
      if (needed_rows < current_rows) {
        temp <- temp[1:needed_rows, ]
      }
      
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
      req(input$age_max >= 0)
      
      # Ensure template has enough rows for all age classes
      current_rows <- nrow(temp)
      needed_rows <- max(current_rows, input$age_max + 1)
      
      if (needed_rows > current_rows) {
        additional_rows <- needed_rows - current_rows
        new_rows <- temp[1, ]
        new_rows[] <- NA
        temp <- rbind(temp, new_rows[rep(1, additional_rows), ])
      }
      
      if (input$apply_mortality == "Yes") {
        # Parse comma-separated values for age-specific mortality with optional sex-specific values
        parse_comma_values <- function(input_val, age_max) {
          if (is.null(input_val) || input_val == "N") {
            return(rep("N", age_max + 1))
          }
          values <- strsplit(as.character(input_val), ",")[[1]]
          values <- trimws(values)
          if (length(values) == 1) {
            return(rep(values, age_max + 1))
          }
          return(values)
        }
        
        # Parse values with sex (tilde) and age (comma) separators
        # Format: sex1_age0,sex1_age1,sex1_age2~sex2_age0,sex2_age1,sex2_age2~...
        # Or: sex1_value~sex2_value (single value per sex replicates across all ages)
        parse_age_sex_values <- function(input_val, age_max) {
          if (is.null(input_val) || input_val == "N") {
            return(rep("N", age_max + 1))
          }
          # Split by ~ to get sex groups
          sex_groups <- strsplit(as.character(input_val), "~")[[1]]
          sex_groups <- trimws(sex_groups)
          
          # If only one sex group without ~, treat as single sex
          if (length(sex_groups) == 1 && !grepl("~", input_val)) {
            age_values <- strsplit(sex_groups[1], ",")[[1]]
            age_values <- trimws(age_values)
            if (length(age_values) == 1) {
              return(rep(age_values, age_max + 1))
            }
            return(age_values)
          }
          
          # For each sex group, split by comma to get age values
          sex_age_values <- lapply(sex_groups, function(sg) {
            age_vals <- strsplit(sg, ",")[[1]]
            trimws(age_vals)
          })
          
          # Validate that all sex groups have the same number of age values
          age_counts <- sapply(sex_age_values, length)
          if (length(unique(age_counts)) > 1) {
            return(NULL)  # Will trigger validation error
          }
          
          # If each sex group has only 1 value, replicate it across all ages
          if (age_counts[1] == 1) {
            sex_age_values <- lapply(sex_age_values, function(sav) {
              rep(sav[1], age_max + 1)
            })
          } else {
            # Check if number of age values matches age_max + 1
            if (age_counts[1] != age_max + 1) {
              return(NULL)  # Will trigger validation error
            }
          }
          
          # Transpose: create age-specific values with sex values separated by ~
          age_specific_values <- character(age_max + 1)
          for (age in 0:age_max) {
            sex_values_for_age <- sapply(sex_age_values, function(sav) {
              if (age + 1 <= length(sav)) sav[age + 1] else "N"
            })
            age_specific_values[age + 1] <- paste(sex_values_for_age, collapse = "~")
          }
          
          return(age_specific_values)
        }
        
        # Validate that the parsed values are valid
        validate_parsed_values <- function(values, age_max) {
          if (is.null(values)) return(FALSE)
          if (length(values) != age_max + 1) return(FALSE)
          return(TRUE)
        }
        
        # Validate and parse age mortality out
        age_mort_out <- parse_age_sex_values(input$age_mortality_out, input$age_max)
        if (!validate_parsed_values(age_mort_out, input$age_max)) {
          showNotification(paste("Age Mortality Out %: Invalid format. Expected format: sex1_age0,sex1_age1,...~sex2_age0,sex2_age1,... For age=2 with 3 sexes: '0,0.1,0.2~0,0.1,0.2~1,0.3,0.5'"), type = "error")
          return()
        }
        # Validate 0-1 bounds for age mortality out
        for (val in age_mort_out) {
          if (val != "N") {
            sex_vals <- strsplit(as.character(val), "~")[[1]]
            for (sv in sex_vals) {
              num_val <- as.numeric(trimws(sv))
              if (is.na(num_val) || num_val < 0 || num_val > 1) {
                showNotification(paste("Age Mortality Out %: Values must be between 0 and 1, or 'N'. Invalid value:", sv), type = "error")
                return()
              }
            }
          }
        }
        
        # Validate and parse age mortality out SD
        age_mort_out_sd <- parse_age_sex_values(as.character(input$age_mortality_out_sd), input$age_max)
        if (!validate_parsed_values(age_mort_out_sd, input$age_max)) {
          showNotification(paste("Age Mortality Out StDev: Invalid format. Expected format: sex1_age0,sex1_age1,...~sex2_age0,sex2_age1,... For age=2 with 3 sexes: '0,0.1,0.2~0,0.1,0.2~1,0.3,0.5'"), type = "error")
          return()
        }
        
        # Validate and parse age mortality back
        age_mort_back <- parse_age_sex_values(input$age_mortality_back, input$age_max)
        if (!validate_parsed_values(age_mort_back, input$age_max)) {
          showNotification(paste("Age Mortality Back %: Invalid format. Expected format: sex1_age0,sex1_age1,...~sex2_age0,sex2_age1,... For age=2 with 3 sexes: '0,0.1,0.2~0,0.1,0.2~1,0.3,0.5'"), type = "error")
          return()
        }
        # Validate 0-1 bounds for age mortality back
        for (val in age_mort_back) {
          if (val != "N") {
            sex_vals <- strsplit(as.character(val), "~")[[1]]
            for (sv in sex_vals) {
              num_val <- as.numeric(trimws(sv))
              if (is.na(num_val) || num_val < 0 || num_val > 1) {
                showNotification(paste("Age Mortality Back %: Values must be between 0 and 1, or 'N'. Invalid value:", sv), type = "error")
                return()
              }
            }
          }
        }
        
        # Validate and parse age mortality back SD
        age_mort_back_sd <- parse_age_sex_values(as.character(input$age_mortality_back_sd), input$age_max)
        if (!validate_parsed_values(age_mort_back_sd, input$age_max)) {
          showNotification(paste("Age Mortality Back StDev: Invalid format. Expected format: sex1_age0,sex1_age1,...~sex2_age0,sex2_age1,... For age=2 with 3 sexes: '0,0.1,0.2~0,0.1,0.2~1,0.3,0.5'"), type = "error")
          return()
        }
        
        # Update age-specific mortality values for each age class
        for (age in 0:input$age_max) {
          if (age + 1 <= nrow(temp)) {
            temp$`Age Mortality Out %`[age + 1] <- age_mort_out[age + 1]
            temp$`Age Mortality Out StDev`[age + 1] <- as.numeric(age_mort_out_sd[age + 1])
            temp$`Age Mortality Back %`[age + 1] <- age_mort_back[age + 1]
            temp$`Age Mortality Back StDev`[age + 1] <- as.numeric(age_mort_back_sd[age + 1])
          }
        }
        
        # Validate and parse size mortality out
        size_mort_out <- parse_age_sex_values(input$size_mortality_out, input$age_max)
        if (!validate_parsed_values(size_mort_out, input$age_max)) {
          showNotification(paste("Size Mortality Out %: Invalid format. Expected format: sex1_age0,sex1_age1,...~sex2_age0,sex2_age1,... For age=2 with 3 sexes: '0,0.1,0.2~0,0.1,0.2~1,0.3,0.5'"), type = "error")
          return()
        }
        # Validate 0-1 bounds for size mortality out
        for (val in size_mort_out) {
          if (val != "N") {
            sex_vals <- strsplit(as.character(val), "~")[[1]]
            for (sv in sex_vals) {
              num_val <- as.numeric(trimws(sv))
              if (is.na(num_val) || num_val < 0 || num_val > 1) {
                showNotification(paste("Size Mortality Out %: Values must be between 0 and 1, or 'N'. Invalid value:", sv), type = "error")
                return()
              }
            }
          }
        }
        
        # Validate and parse size mortality out SD
        size_mort_out_sd <- parse_age_sex_values(as.character(input$size_mortality_out_sd), input$age_max)
        if (!validate_parsed_values(size_mort_out_sd, input$age_max)) {
          showNotification(paste("Size Mortality Out StDev: Invalid format. Expected format: sex1_age0,sex1_age1,...~sex2_age0,sex2_age1,... For age=2 with 3 sexes: '0,0.1,0.2~0,0.1,0.2~1,0.3,0.5'"), type = "error")
          return()
        }
        
        # Validate and parse size mortality back
        size_mort_back <- parse_age_sex_values(input$size_mortality_back, input$age_max)
        if (!validate_parsed_values(size_mort_back, input$age_max)) {
          showNotification(paste("Size Mortality Back %: Invalid format. Expected format: sex1_age0,sex1_age1,...~sex2_age0,sex2_age1,... For age=2 with 3 sexes: '0,0.1,0.2~0,0.1,0.2~1,0.3,0.5'"), type = "error")
          return()
        }
        # Validate 0-1 bounds for size mortality back
        for (val in size_mort_back) {
          if (val != "N") {
            sex_vals <- strsplit(as.character(val), "~")[[1]]
            for (sv in sex_vals) {
              num_val <- as.numeric(trimws(sv))
              if (is.na(num_val) || num_val < 0 || num_val > 1) {
                showNotification(paste("Size Mortality Back %: Values must be between 0 and 1, or 'N'. Invalid value:", sv), type = "error")
                return()
              }
            }
          }
        }
        
        # Validate and parse size mortality back SD
        size_mort_back_sd <- parse_age_sex_values(as.character(input$size_mortality_back_sd), input$age_max)
        if (!validate_parsed_values(size_mort_back_sd, input$age_max)) {
          showNotification(paste("Size Mortality Back StDev: Invalid format. Expected format: sex1_age0,sex1_age1,...~sex2_age0,sex2_age1,... For age=2 with 3 sexes: '0,0.1,0.2~0,0.1,0.2~1,0.3,0.5'"), type = "error")
          return()
        }
        
        # Update size-specific mortality values for each age class
        for (age in 0:input$age_max) {
          if (age + 1 <= nrow(temp)) {
            temp$`Size Mortality Out %`[age + 1] <- size_mort_out[age + 1]
            temp$`Size Mortality Out StDev`[age + 1] <- size_mort_out_sd[age + 1]
            temp$`Size Mortality Back %`[age + 1] <- size_mort_back[age + 1]
            temp$`Size Mortaltiy Back StDev`[age + 1] <- size_mort_back_sd[age + 1]
          }
        }
      } else {
        # Reset age-specific mortality values to defaults
        for (age in 0:input$age_max) {
          if (age + 1 <= nrow(temp)) {
            temp$`Age Mortality Out %`[age + 1] <- "N"
            temp$`Age Mortality Out StDev`[age + 1] <- 0
            temp$`Age Mortality Back %`[age + 1] <- "N"
            temp$`Age Mortality Back StDev`[age + 1] <- 0
          }
        }
        temp$`Size Mortality Out %` <- "N"
        temp$`Size Mortality Out StDev` <- 0
        temp$`Size Mortality Back %` <- "0.1~0.1"
        temp$`Size Mortaltiy Back StDev` <- 0
      }
      
      template_data(temp)
      showNotification("Mortality parameters updated successfully!", type = "message")
    })
    
    ###################################################
    # update Movement tab
    ###################################################
    observeEvent(input$update_movement, {
      temp <- template_data()
      req(input$age_max >= 0)
      
      # Ensure template has enough rows for all age classes
      current_rows <- nrow(temp)
      needed_rows <- max(current_rows, input$age_max + 1)
      
      if (needed_rows > current_rows) {
        additional_rows <- needed_rows - current_rows
        new_rows <- temp[1, ]
        new_rows[] <- NA
        temp <- rbind(temp, new_rows[rep(1, additional_rows), ])
      }
      
      if (input$apply_movement == "Yes") {
        # Parse values with sex (tilde) and age (comma) separators
        # Format: sex1_age0,sex1_age1,sex1_age2~sex2_age0,sex2_age1,sex2_age2~...
        # Or: sex1_value~sex2_value (single value per sex replicates across all ages)
        parse_age_sex_values <- function(input_val, age_max) {
          if (is.null(input_val) || input_val == "N") {
            return(rep("N", age_max + 1))
          }
          # Split by ~ to get sex groups
          sex_groups <- strsplit(as.character(input_val), "~")[[1]]
          sex_groups <- trimws(sex_groups)
          
          # If only one sex group without ~, treat as single sex
          if (length(sex_groups) == 1 && !grepl("~", input_val)) {
            age_values <- strsplit(sex_groups[1], ",")[[1]]
            age_values <- trimws(age_values)
            if (length(age_values) == 1) {
              return(rep(age_values, age_max + 1))
            }
            return(age_values)
          }
          
          # For each sex group, split by comma to get age values
          sex_age_values <- lapply(sex_groups, function(sg) {
            age_vals <- strsplit(sg, ",")[[1]]
            trimws(age_vals)
          })
          
          # Validate that all sex groups have the same number of age values
          age_counts <- sapply(sex_age_values, length)
          if (length(unique(age_counts)) > 1) {
            return(NULL)  # Will trigger validation error
          }
          
          # If each sex group has only 1 value, replicate it across all ages
          if (age_counts[1] == 1) {
            sex_age_values <- lapply(sex_age_values, function(sav) {
              rep(sav[1], age_max + 1)
            })
          } else {
            # Check if number of age values matches age_max + 1
            if (age_counts[1] != age_max + 1) {
              return(NULL)  # Will trigger validation error
            }
          }
          
          # Transpose: create age-specific values with sex values separated by ~
          age_specific_values <- character(age_max + 1)
          for (age in 0:age_max) {
            sex_values_for_age <- sapply(sex_age_values, function(sav) {
              if (age + 1 <= length(sav)) sav[age + 1] else "N"
            })
            age_specific_values[age + 1] <- paste(sex_values_for_age, collapse = "~")
          }
          
          return(age_specific_values)
        }
        
        # Validate that the parsed values are valid
        validate_parsed_values <- function(values, age_max) {
          if (is.null(values)) return(FALSE)
          if (length(values) != age_max + 1) return(FALSE)
          return(TRUE)
        }
        
        # Validate and parse migration out prob
        mig_out <- parse_age_sex_values(input$migration_out_prob, input$age_max)
        if (!validate_parsed_values(mig_out, input$age_max)) {
          showNotification(paste("Migration Out Prob: Invalid format. Expected format: sex1_age0,sex1_age1,...~sex2_age0,sex2_age1,... For age=2 with 3 sexes: '0,0.1,0.2~0,0.1,0.2~1,0.3,0.5'"), type = "error")
          return()
        }
        # Validate 0-1 bounds
        for (val in mig_out) {
          sex_vals <- strsplit(as.character(val), "~")[[1]]
          for (sv in sex_vals) {
            num_val <- as.numeric(trimws(sv))
            if (is.na(num_val) || num_val < 0 || num_val > 1) {
              showNotification(paste("Migration Out Prob: Values must be between 0 and 1. Invalid value:", sv), type = "error")
              return()
            }
          }
        }
        
        # Validate and parse migration back prob
        mig_back <- parse_age_sex_values(input$migration_back_prob, input$age_max)
        if (!validate_parsed_values(mig_back, input$age_max)) {
          showNotification(paste("Migration Back Prob: Invalid format. Expected format: sex1_age0,sex1_age1,...~sex2_age0,sex2_age1,... For age=2 with 3 sexes: '0,0.1,0.2~0,0.1,0.2~1,0.3,0.5'"), type = "error")
          return()
        }
        for (val in mig_back) {
          sex_vals <- strsplit(as.character(val), "~")[[1]]
          for (sv in sex_vals) {
            num_val <- as.numeric(trimws(sv))
            if (is.na(num_val) || num_val < 0 || num_val > 1) {
              showNotification(paste("Migration Back Prob: Values must be between 0 and 1. Invalid value:", sv), type = "error")
              return()
            }
          }
        }
        
        # Validate and parse straying prob
        stray_prob <- parse_age_sex_values(input$straying_prob, input$age_max)
        if (!validate_parsed_values(stray_prob, input$age_max)) {
          showNotification(paste("Straying Prob: Invalid format. Expected format: sex1_age0,sex1_age1,...~sex2_age0,sex2_age1,... For age=2 with 3 sexes: '0,0.1,0.2~0,0.1,0.2~1,0.3,0.5'"), type = "error")
          return()
        }
        for (val in stray_prob) {
          sex_vals <- strsplit(as.character(val), "~")[[1]]
          for (sv in sex_vals) {
            num_val <- as.numeric(trimws(sv))
            if (is.na(num_val) || num_val < 0 || num_val > 1) {
              showNotification(paste("Straying Prob: Values must be between 0 and 1. Invalid value:", sv), type = "error")
              return()
            }
          }
        }
        
        # Validate and parse dispersal prob
        disp_prob <- parse_age_sex_values(input$dispersal_prob, input$age_max)
        if (!validate_parsed_values(disp_prob, input$age_max)) {
          showNotification(paste("Dispersal Prob: Invalid format. Expected format: sex1_age0,sex1_age1,...~sex2_age0,sex2_age1,... For age=2 with 3 sexes: '0,0.1,0.2~0,0.1,0.2~1,0.3,0.5'"), type = "error")
          return()
        }
        for (val in disp_prob) {
          sex_vals <- strsplit(as.character(val), "~")[[1]]
          for (sv in sex_vals) {
            num_val <- as.numeric(trimws(sv))
            if (is.na(num_val) || num_val < 0 || num_val > 1) {
              showNotification(paste("Dispersal Prob: Values must be between 0 and 1. Invalid value:", sv), type = "error")
              return()
            }
          }
        }
        
        # Update movement values for each age class
        for (age in 0:input$age_max) {
          if (age + 1 <= nrow(temp)) {
            temp$`Migration Out Prob`[age + 1] <- mig_out[age + 1]
            temp$`Migration Back Prob`[age + 1] <- mig_back[age + 1]
            temp$`Straying Prob`[age + 1] <- stray_prob[age + 1]
            temp$`Dispersal Prob`[age + 1] <- disp_prob[age + 1]
          }
        }
      } else {
        # Reset movement values to defaults
        for (age in 0:input$age_max) {
          if (age + 1 <= nrow(temp)) {
            temp$`Migration Out Prob`[age + 1] <- 0
            temp$`Migration Back Prob`[age + 1] <- 0
            temp$`Straying Prob`[age + 1] <- 0
            temp$`Dispersal Prob`[age + 1] <- 0
          }
        }
      }
      template_data(temp)
      showNotification("Movement parameters updated successfully!", type = "message")
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
      
      # Parse values with sex (tilde) and age (comma) separators
      # Format: sex1_age0,sex1_age1,sex1_age2~sex2_age0,sex2_age1,sex2_age2~...
      # Or: sex1_value~sex2_value (single value per sex replicates across all ages)
      parse_age_sex_values <- function(input_val, age_max) {
        if (is.null(input_val) || input_val == "N") {
          return(rep("N", age_max + 1))
        }
        # Split by ~ to get sex groups
        sex_groups <- strsplit(as.character(input_val), "~")[[1]]
        sex_groups <- trimws(sex_groups)
        
        # If only one sex group without ~, treat as single sex
        if (length(sex_groups) == 1 && !grepl("~", input_val)) {
          age_values <- strsplit(sex_groups[1], ",")[[1]]
          age_values <- trimws(age_values)
          if (length(age_values) == 1) {
            return(rep(age_values, age_max + 1))
          }
          return(age_values)
        }
        
        # For each sex group, split by comma to get age values
        sex_age_values <- lapply(sex_groups, function(sg) {
          age_vals <- strsplit(sg, ",")[[1]]
          trimws(age_vals)
        })
        
        # Validate that all sex groups have the same number of age values
        age_counts <- sapply(sex_age_values, length)
        if (length(unique(age_counts)) > 1) {
          return(NULL)  # Will trigger validation error
        }
        
        # If each sex group has only 1 value, replicate it across all ages
        if (age_counts[1] == 1) {
          sex_age_values <- lapply(sex_age_values, function(sav) {
            rep(sav[1], age_max + 1)
          })
        } else {
          # Check if number of age values matches age_max + 1
          if (age_counts[1] != age_max + 1) {
            return(NULL)  # Will trigger validation error
          }
        }
        
        # Transpose: create age-specific values with sex values separated by ~
        age_specific_values <- character(age_max + 1)
        for (age in 0:age_max) {
          sex_values_for_age <- sapply(sex_age_values, function(sav) {
            if (age + 1 <= length(sav)) sav[age + 1] else "N"
          })
          age_specific_values[age + 1] <- paste(sex_values_for_age, collapse = "~")
        }
        
        return(age_specific_values)
      }
      
      # Validate that the parsed values are valid
      validate_parsed_values <- function(values, age_max) {
        if (is.null(values)) return(FALSE)
        if (length(values) != age_max + 1) return(FALSE)
        return(TRUE)
      }
      
      # Validate and parse maturation
      maturation_vals <- parse_age_sex_values(input$maturation, input$age_max)
      if (!validate_parsed_values(maturation_vals, input$age_max)) {
        showNotification(paste("Maturation: Invalid format. Expected format: sex1_age0,sex1_age1,...~sex2_age0,sex2_age1,... For age=2 with 3 sexes: '4,5,6~3,4,5~2,3,4'"), type = "error")
        return()
      }
      
      # Update maturation column
      for (age in 0:input$age_max) {
        if (age + 1 <= nrow(temp)) {
          temp$`Maturation`[age + 1] <- maturation_vals[age + 1]
        }
      }
      
      template_data(temp)
      showNotification("Maturation parameters updated successfully!", type = "message")
      
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
    observeEvent(input$update_capture_prob, {
      temp <- template_data()
      req(input$age_max >= 0)
      
      # Ensure template has enough rows for all age classes
      current_rows <- nrow(temp)
      needed_rows <- max(current_rows, input$age_max + 1)
      
      if (needed_rows > current_rows) {
        additional_rows <- needed_rows - current_rows
        new_rows <- temp[1, ]
        new_rows[] <- NA
        temp <- rbind(temp, new_rows[rep(1, additional_rows), ])
      }
      
      if (input$apply_capture_prob == "Yes") {
        # Parse values with sex (tilde) and age (comma) separators
        # Format: sex1_age0,sex1_age1,sex1_age2~sex2_age0,sex2_age1,sex2_age2~...
        # Or: sex1_value~sex2_value (single value per sex replicates across all ages)
        parse_age_sex_values <- function(input_val, age_max) {
          if (is.null(input_val) || input_val == "N") {
            return(rep("N", age_max + 1))
          }
          # Split by ~ to get sex groups
          sex_groups <- strsplit(as.character(input_val), "~")[[1]]
          sex_groups <- trimws(sex_groups)
          
          # If only one sex group without ~, treat as single sex
          if (length(sex_groups) == 1 && !grepl("~", input_val)) {
            age_values <- strsplit(sex_groups[1], ",")[[1]]
            age_values <- trimws(age_values)
            if (length(age_values) == 1) {
              return(rep(age_values, age_max + 1))
            }
            return(age_values)
          }
          
          # For each sex group, split by comma to get age values
          sex_age_values <- lapply(sex_groups, function(sg) {
            age_vals <- strsplit(sg, ",")[[1]]
            trimws(age_vals)
          })
          
          # Validate that all sex groups have the same number of age values
          age_counts <- sapply(sex_age_values, length)
          if (length(unique(age_counts)) > 1) {
            return(NULL)  # Will trigger validation error
          }
          
          # If each sex group has only 1 value, replicate it across all ages
          if (age_counts[1] == 1) {
            sex_age_values <- lapply(sex_age_values, function(sav) {
              rep(sav[1], age_max + 1)
            })
          } else {
            # Check if number of age values matches age_max + 1
            if (age_counts[1] != age_max + 1) {
              return(NULL)  # Will trigger validation error
            }
          }
          
          # Transpose: create age-specific values with sex values separated by ~
          age_specific_values <- character(age_max + 1)
          for (age in 0:age_max) {
            sex_values_for_age <- sapply(sex_age_values, function(sav) {
              if (age + 1 <= length(sav)) sav[age + 1] else "N"
            })
            age_specific_values[age + 1] <- paste(sex_values_for_age, collapse = "~")
          }
          
          return(age_specific_values)
        }
        
        # Validate that the parsed values are valid
        validate_parsed_values <- function(values, age_max) {
          if (is.null(values)) return(FALSE)
          if (length(values) != age_max + 1) return(FALSE)
          return(TRUE)
        }
        
        # Validate and parse capture out probability
        capture_out <- parse_age_sex_values(input$Capture_Out_Probability, input$age_max)
        if (!validate_parsed_values(capture_out, input$age_max)) {
          showNotification(paste("Capture Out Probability: Invalid format. Expected format: sex1_age0,sex1_age1,...~sex2_age0,sex2_age1,... For age=2 with 3 sexes: '0,0.1,0.2~0,0.1,0.2~1,0.3,0.5'"), type = "error")
          return()
        }
        # Validate 0-1 bounds
        for (val in capture_out) {
          if (val != "N") {
            sex_vals <- strsplit(as.character(val), "~")[[1]]
            for (sv in sex_vals) {
              num_val <- as.numeric(trimws(sv))
              if (is.na(num_val) || num_val < 0 || num_val > 1) {
                showNotification(paste("Capture Out Probability: Values must be between 0 and 1, or 'N'. Invalid value:", sv), type = "error")
                return()
              }
            }
          }
        }
        
        # Validate and parse capture back probability
        capture_back <- parse_age_sex_values(input$Capture_Back_Probability, input$age_max)
        if (!validate_parsed_values(capture_back, input$age_max)) {
          showNotification(paste("Capture Back Probability: Invalid format. Expected format: sex1_age0,sex1_age1,...~sex2_age0,sex2_age1,... For age=2 with 3 sexes: '0,0.1,0.2~0,0.1,0.2~1,0.3,0.5'"), type = "error")
          return()
        }
        for (val in capture_back) {
          if (val != "N") {
            sex_vals <- strsplit(as.character(val), "~")[[1]]
            for (sv in sex_vals) {
              num_val <- as.numeric(trimws(sv))
              if (is.na(num_val) || num_val < 0 || num_val > 1) {
                showNotification(paste("Capture Back Probability: Values must be between 0 and 1, or 'N'. Invalid value:", sv), type = "error")
                return()
              }
            }
          }
        }
        
        # Update capture probability values for each age class
        for (age in 0:input$age_max) {
          if (age + 1 <= nrow(temp)) {
            temp$`Capture Out Probability`[age + 1] <- capture_out[age + 1]
            temp$`Capture Back Probability`[age + 1] <- capture_back[age + 1]
          }
        }
      } else {
        # Reset capture probability values to defaults
        for (age in 0:input$age_max) {
          if (age + 1 <= nrow(temp)) {
            temp$`Capture Out Probability`[age + 1] <- "N"
            temp$`Capture Back Probability`[age + 1] <- "N"
          }
        }
      }
      
      template_data(temp)
      showNotification("Capture probability parameters updated successfully!", type = "message")
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
        write.csv(template_data(), file, row.names = FALSE, quote = FALSE)
      }
    )
    
    
    
  }
  
  shinyApp(ui = ui, server = server)
}

