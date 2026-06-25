#' Build PatchVars File from Template
#'
#' This function loads a provided PatchVars template, allows the user to edit selected areas,
#' and saves the modified version as a new file.
#'
#' @param output_file The name of the output file. Defaults to 'my_new_patchvars.csv'.
#' @return A Shiny app instance.
#' @import shiny
#' @import shinyBS
#' @export
write_patchvars <- function(output_file = "my_new_patchvars.csv") {
  # Template
  template <- data.frame(
  PatchID = 0, X = NA, Y = NA,
  SubpatchNO = 0, K = 0, `K StDev` = 0, N0 = 0,
  `Natal Grounds` = 1, `Migration Out Grounds` = 0, 
  `Genes.Initialize` = NA, 
  `ClassVars` = NA,
  `Mortality Out` = 0, `Mortality Out StDev` = 0,
  `Mortality Back` = 0, `Mortality Back StDev` = 0,
  `Mortality Eggs` = 0, `Mortality Eggs StDev` = 0, 
  `Migration Out Prob` = 0, `Set Migration Out` = "N",
  `Migration Back Prob` = 1, `Straying Prob` = 0, 
  `Dispersal Prob` = 0, GrowthTemperatureOut = "N",
  GrowthTemperatureOutStDev = 0, GrowDaysOut = 155,
  GrowDaysOutStDev = 0, GrowthTemperatureBack = "N", 
  GrowthTemperatureBackStDev = 0, GrowDaysBack = 0,
  GrowDaysBackStDev = 0, `Capture Probability Out` = "N", 
  `Capture Probability Back` = "N", HabitatOut = 0, 
  HabitatBack = 0, Fitness_AA = 0, Fitness_Aa = 0,
  Fitness_aa = 0, Fitness_BB = 0, Fitness_Bb = 0,
  Fitness_bb = 0, Fitness_AABB = 0, Fitness_AaBB = 0,
  Fitness_aaBB = 0, Fitness_AABb = 0, Fitness_AaBb = 0, 
  Fitness_aaBb = 0, Fitness_AAbb = 0, Fitness_Aabb = 0,
  Fitness_aabb = 0, comp_coef = 0.5,  
  check.names = FALSE)
  ############################################
  ################## UI ######################
  ############################################
  ui <- fluidPage(
    titlePanel("Build a PatchVars.csv File"),
    p(
      "Welcome! This shiny app instance will help you put together a PatchVars.csv file to use as a CDmetaPOP input file.",
      "Select any of the tabs below and change the default parameters of the simulations in order to reflect those of the system you want to test. The parameter that will be changed according to your choices is indicated for each section as ",
      em(span("parameter", style = "color:#0072B2; font-weight: bold;")),
      "."
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
        div(class = "upload-block",
          h5("Coordinates File"),
            fileInput("coordinates_upload", "Upload the coordinates of your study system. It must be a csv file with two columns named X and Y", accept = ".csv"),
            actionButton(
              inputId = "update_coordinates",
              label = HTML('Update <em><span style="color:#0072B2; font-weight:bold;">X & Y</span></em>')
            )
        ),
        
        # Classvars
        div(
          class = "upload-block",
          h5("Classvars"),
          textInput("classvars_file", label = "Type the file name of your classvars.csv file: "),
          actionButton("update_classvars", tagList(
            "Update ",
            em(span("ClassVars", style = "color:#0072B2; font-weight: bold;"))  # Class.vars is the column name in the template
          ))
        ),
        
        # Genes 
        div(
          class = "upload-block",
          h5("Genes"),
          textInput("genes_file", label = "Type the name of your gene.csv file: "),
          actionButton("update_genes", tagList(
            "Update ",
            em(span("Genes Initialize", style = "color:#0072B2; font-weight: bold;"))  # Genes Initialize is the column name in the template
          ))
        ),
        downloadButton("download_patchvars", "Download PatchVars File")
      ),
      
      ############################################
      # MAIN PANEL
      ############################################    
      
      mainPanel(
        tabsetPanel(
          ########################################
          # Patches tab
          ########################################
          tabPanel("Patches",
                   helpText(
                     "Please indicate the path to the coordinates file on the left panel. Doing this will define the number of patches in your system.",
                     em(span("PatchesID", style = "color:#0072B2; font-weight: bold;")),
                     "."
                   ),
          tableOutput("patch_table"),
          
          numericInput("K", tagList("Enter the carrying capacity of your patches. A K value of 0 means individuals will not move into the patch. ", em(span("K", style = "color:#0072B2;"))), 
                       value = 0),
          numericInput("K_StDev", tagList("Enter the +/- annual variation for your patches ", em(span("K StDev", style = "color:#0072B2;"))), 
                       value = 0),
          numericInput("N0", tagList("Enter the population number of your patches.", em(span("N0", style = "color:#0072B2;"))), 
                       value = 0),
          selectInput("Natal_Grounds", tagList("Identify whether your patches are natal ground locations ", em(span("Natal Grounds", style = "color:#0072B2;"))),
                   selected = 1,
                   choices = c(0,1)
                   ),
          bsTooltip(
            "Natal_Grounds",
            "Warning - If patches at all Natal Ground = 0 simulation will not run",
            "right"
          ),
          actionButton("update_patches", "Apply changes")
          ),
          
          ########################################
          # Demography tab
          ########################################
          tabPanel("Demography",
                   helpText("Parameters entered here will define density-independent mortality applied to each patch and should range between 0 and 1 (0 = no mortality, 1 = 100% mortality)."),  
                   helpText("Warning! These parameters will interact with class specific values (ClassVars.csv) See user manual for how class and patch interact."),
                   
                                
          numericInput("mortality_out", tagList("Set the mortality rate for individuals during the rearing/overwintering/foraging stage ", em(span("Mortality Out", style = "color:#0072B2;"))), 
                      value = 0,
                      min = 0, max = 1, step = 0.05),
          numericInput("mortality_out_stdev", tagList("Set the standard deviation for the mortality rate during the rearing/overwintering/foraging stage ", em(span("Mortality Out StDev", style = "color:#0072B2;"))), 
                      value = 0,
                      min = 0, max = 1, step = 0.05),
          numericInput("mortality_back", tagList("Set the mortality rate for individuals during the spawning stage ", em(span("Mortality Back", style = "color:#0072B2;"))), 
                      value = 0,
                      min = 0, max = 1, step = 0.05),
          numericInput("mortality_back_stdev", tagList("Set the standard deviation for the mortality rate during the spawning stage ", em(span("Mortality Back StDev", style = "color:#0072B2;"))), 
                      value = 0,
                      min = 0, max = 1, step = 0.05),
          numericInput("mortality_eggs", tagList("Set the mortality rate for individuals during the egg/litter stage ", em(span("Mortality Eggs", style = "color:#0072B2;"))), 
                      value = 0,
                      min = 0, max = 1, step = 0.05),
          numericInput("mortality_eggs_stdev", tagList("Set the standard deviation for the mortality rate during the egg/litter stage ", em(span("Mortality Eggs StDev", style = "color:#0072B2;"))), 
                      value = 0,
                      min = 0, max = 1, step = 0.05),
          actionButton("update_demography", "Apply changes"),
          ),
          
          ########################################
          # Movement tab
          ########################################
          
          tabPanel("Movement",
          helpText("Parameters entered here will define movement, dispersal, and straying among patches."),
          helpText("Warning! These parameters will be multiplied by class specific values (ClassVars.csv) See user manual for how class and patch interact."),
          
          radioButtons("apply_movement", "Apply Movement Parameters?",
                       choices = c("No", "Yes"), 
                       selected = "No", 
                       inline = TRUE),
          
          # Show movement settings only if 'Yes' is selected
          conditionalPanel(
            condition = "input.apply_movement == 'Yes'",
            numericInput("migration_out_prob", tagList("Emigration probability [0-1] applied before moving to rearing/overwinter grounds. If just age/size class migration is wanted, then set these values to 1. ", em(span("Migration Out Prob", style = "color:#0072B2;"))), 
                         value = 0,
                         min = 0, max = 1, step = 0.05),
            radioButtons("set_migration_out", tagList("If an individual becomes a migrant, does it stay an annual migrant for life? ", em(span("Set Migration Out", style = "color:#0072B2;"))),
                         choices = c("Y", "N"), 
                         selected = "N", 
                         inline = TRUE),
            numericInput("migration_back_prob", tagList("Set return probability [0-1] (Default 1 means all migrants return) ", em(span("Migration Back Prob", style = "color:#0072B2;"))), 
                         value = 1, # 
                         min = 0, max = 1, step = 0.05),
            numericInput("straying_prob", tagList("Set straying probability [0-1] ", em(span("Straying Prob", style = "color:#0072B2;"))),
                         value = 0,
                         min = 0, max = 1, step = 0.05),
            numericInput("dispersal_prob", tagList("Set dispersal probability [0-1] ", em(span("Dispersal Prob", style = "color:#0072B2;"))), 
                         value = 0,
                         min = 0, max = 1, step = 0.05),
            actionButton("update_movement", "Apply changes")
          ),
        ),


        ########################################
        # Growth tab
        ########################################
          tabPanel("Growth",
                   helpText("Parameters entered here will define temperature-dependent growth at each patch."),
                   
                   radioButtons("apply_growth", "Do you want to turn on temperature-dependent growth?",
                                choices = c("No", "Yes"), 
                                selected = "No", 
                                inline = TRUE),
                   
                   # Show growth settings only if 'Yes' is selected
                   conditionalPanel(
                     condition = "input.apply_growth == 'Yes'",
                     numericInput("GrowthTemperatureOut", tagList("Define the temperature value that influences body size growth of individuals after migration out of natal grounds: ", em(span("GrowthTemperatureOut", style = "color:#0072B2;"))), 
                                  value = 0),
                     bsTooltip(
                       "GrowthTemperatureOutStDev",
                       "Standard deviations around each temperature value are applied annually to each patch. Enter 0 here and this field will be deterministic, using the 'Growth Temperature Out' value at each time step.",
                       placement = "right",
                       trigger = "hover"
                     ),
                     numericInput("GrowthTemperatureOutStDev", tagList("Define the standard deviation around the temperature value for growth out: ", em(span("GrowthTemperatureOutStDev", style = "color:#0072B2;"))), 
                                  value = 0),
                     bsTooltip(
                       "GrowDaysOut",
                       "Patch site growing days corresponding to the growth time 'out' for growth option 'temperature'. ",
                       placement = "right",
                       trigger = "hover"
                     ),
                     numericInput("GrowDaysOut", tagList("Define the number of growing days corresponding to the growth time out [0-365]: ", em(span("GrowDaysOut", style = "color:#0072B2;"))), 
                                  value = 155),
                     bsTooltip(
                       "GrowDaysOutStDev",
                       "Standard deviations around each grow days value are applied annually to each patch. Enter 0 here and this field will be deterministic, using the 'Growth Days Out' value at each time step.",
                       placement = "right",
                       trigger = "hover"
                     ),
                     numericInput("GrowDaysOutStDev", tagList("Define the standard deviation around the number of growing days for growth time out: ", em(span("GrowDaysOutStDev", style = "color:#0072B2;"))), 
                                  value = 0),
                     numericInput("GrowthTemperatureBack", tagList("Define the temperature value that influence body size growth of individuals after migration back to natal grounds: ", em(span("GrowthTemperatureBack", style = "color:#0072B2;"))), 
                                  value = 0),
                     bsTooltip(
                       "GrowthTemperatureBackStDev",
                       "Standard deviations around each temperature value are applied annually to each patch. Enter 0 here and this field will be deterministic, using the 'Growth Temperature Back' value at each time step.",
                       placement = "right",
                       trigger = "hover"
                     ),
                     numericInput("GrowthTemperatureBackStDev", tagList("Define the standard deviation around the temperature value for growth back: ", em(span("GrowthTemperatureBackStDev", style = "color:#0072B2;"))), 
                                  value = 0),
                     bsTooltip(
                       "GrowDaysBack",
                       "Patch site growing days corresponding to the growth time 'back' for growth option 'temperature'",
                       placement = "right",
                       trigger = "hover"
                     ),
                     numericInput("GrowDaysBack", tagList("Define the number of growing days corresponding to the growth time back [0-365]: ", em(span("GrowDaysBack", style = "color:#0072B2;"))), 
                                  value = 0),
                     bsTooltip(
                       "GrowDaysBackStDev",
                       "Standard deviations around each grow days value are applied annually to each patch. Enter 0 here and this field will be deterministic, using the 'Growth Days Back' value at each time step.",
                       placement = "right",
                       trigger = "hover"
                     ),
                     numericInput("GrowDaysBackStDev", tagList("Define the standard deviation around the number of growing days for growth back: ", em(span("GrowDaysBackStDev", style = "color:#0072B2;"))), 
                                  value = 0),
                            actionButton("update_growth", "Apply changes")
                   ),
          ),

        ########################################
        # Fitness tab
        ########################################
        
          tabPanel("Fitness",
        helpText("Warning: Selection parameters entered here are dependent on what is defined in the cdevolveans parameter of the PopVars.csv file."),
        
        radioButtons("apply_selection", "Do you want to apply selection?",
                     choices = c("No", "Basic 1-locus", "Basic 2-locus Epistatic", "Growth-dependent selection", "Maturation-dependent selection"), 
                     selected = "No", 
                     inline = TRUE),

        # Show differential settings only if 'No' is not selected
        conditionalPanel(
          condition = "input.apply_selection != 'No'",
           helpText("Warning: If you want to apply selection, make sure to also update the cdevolveans parameter in the PopVars.csv file to match the type of selection you want to apply. See user manual for more details."),
          uiOutput("implementSelectionUI"),
          actionButton("update_selection", "Apply changes")
        )
          ),
        
        ########################################
        # Miscellaneous tab
        ########################################
        
          tabPanel("Miscellaneous",
                   radioButtons("apply_capture", "Do you want to calculate capture probabilities?",
                                choices = c("No", "Yes"), 
                                selected = "No", 
                                inline = TRUE),
                   
                   # Show capture probability settings only if 'Yes' is selected
                   conditionalPanel(
                     condition = "input.apply_capture == 'Yes'",
                     numericInput("Capture_Probability_Out", tagList("Define the capture probability when individuals are out from natal grounds [0-1]: ", em(span("Capture Probability Out", style = "color:#0072B2;"))), 
                                  value = 0, 
                                  min = 0, step = 0.05, max = 1),
                     bsTooltip(
                       "Capture_Probability_Out",
                       "If '1' - capture probability will be controlled by ClassVars. **Warning**: If values for capture occur in both patchvars and classvars, these will be multiplied to achieve a final capture probability.",
                       placement = "right",
                       trigger = "hover"
                     ),
                     numericInput("Capture_Probability_Back", tagList("Define the capture probability when individuals are back at natal grounds [0-1]: ", em(span("Capture Probability Back", style = "color:#0072B2;"))), 
                                  value = 0,
                                  min = 0, max = 1, step = 0.05),
                     bsTooltip(
                       "Capture_Probability_Back",
                       "If '1' - Capture probability will be controlled by ClassVars. **Warning**: If values for capture occur in both patchvars and classvars, these will be multiplied to achieve a final capture probability. ", 
                       placement = "right",
                       trigger = "hover"
                     ),
                         actionButton("update_capture", "Apply changes"),
                   ),
                   
                 
                  
                   
                   radioButtons("apply_habitat", "Do you want to apply habitat quality values for use with the plasticity module?",
                                choices = c("No", "Yes"), 
                                selected = "No", 
                                inline = TRUE),
                   # Show habitat quality settings only if 'Yes' is selected
                   conditionalPanel(
                     condition = "input.apply_habitat == 'Yes'",
                     numericInput("HabitatOut", tagList("Define the habitat quality value for use during the outward migration [0-1]: ", em(span("HabitatOut", style = "color:#0072B2;"))), 
                                  value = 0,
                                  min = 0, step = 0.05, max = 1),
                     bsTooltip(
                       "HabitatOut",
                       "The HabitatOut parameter functions as a habitat-based modifier for plastic dispersal behaviors during emigration events. It only impacts the probability matrix if the first term of plasticgeneans in the RunVars.csv file is set as *Hab*",
                       placement = "right",
                       trigger = "hover"
                     ),
                     numericInput("HabitatBack", tagList("Define the habitat quality value for use during the returning migration [0-1]: ", em(span("HabitatBack", style = "color:#0072B2;"))), 
                                  value = 0,
                                  min = 0, step = 0.05, max = 1),
                     bsTooltip(
                       "HabitatBack",
                       "The HabitatBack parameter functions as a habitat-based modifier for plastic dispersal behaviors during immigration events. It only impacts the probability matrix if the first term of plasticgeneans in the RunVars.csv file is set as *Hab*",
                       placement = "right",
                       trigger = "hover"
                     ),
                    actionButton("update_habitat", "Apply changes")
                   ),
                   
                   radioButtons("apply_competition", "Do you want to include interspecific competition?",
                                choices = c("No", "Yes"), 
                                selected = "No", 
                                inline = TRUE),
                   # Show competition coefficient settings only if 'Yes' is selected
                   conditionalPanel(
                     condition = "input.apply_competition == 'Yes'",
                     numericInput("comp_coef", tagList("Define the value of he competitive impact : ", em(span("comp_coef", style = "color:#0072B2;"))), 
                                  value = 0,
                                  min = 0, step = 0.05),
                     bsTooltip(
                       "comp_coef",
                       "The competition coefficient represents the effect of one species on another. Higher values = greater competitive impact.",
                       placement = "right",
                       trigger = "hover"),                     
                    actionButton("update_competition", "Apply changes")
                   ),
          ),
        
        ########################################
        # Preview tab
        ########################################
          tabPanel("Preview Updated PatchVars",
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
|   |--correlation_matrix2.csv"
            
          ),
          easyClose = TRUE,
          footer = modalButton("Close")
        )
      )
    })
    
    ###################################
    # Classvars help button 
    ###################################
    observe({
      addTooltip(
        session,
        "classvars_file",
        HTML(
          "If you don't have a classvars file yet, you can skip this step for now and you may use the <code>write_classvars.R</code> function to build one. If your classvars is in a subdirectory, make sure to type it in here too. For example: <code>classvars/classVars.csv</code>."
        ),
        placement = "right",
        trigger = "hover"
      )
    })  
    
    ###################################################
    # SIDEPANEL UPDATE
    ###################################################
    
    # Update Classvars text
    observeEvent(input$update_classvars, {
      req(input$classvars_file)
      
      # Update only the 'Class.Vars' column with the subdir name
      temp <- template_data()
      temp$ClassVars <- input$classvars_file
      template_data(temp)
    })
    
    # Update Genes text
    observeEvent(input$update_genes, {
      req(input$genes_file)
      # Update only the 'Genes.Initialize' column with the subdir name
      temp <- template_data()
      temp$Genes.Initialize <- input$genes_file
      template_data(temp)
    })
    
    # Update template when coordinates file is uploaded
    observeEvent(input$update_coordinates, {
      req(input$coordinates_upload)
      uploaded <- read.csv(input$coordinates_upload$datapath)
      
      if (!all(c("X", "Y") %in% names(uploaded))) {
        showNotification("Uploaded file must contain columns named 'X' and 'Y'", type = "error")
        return(NULL)
      }
      
      n <- nrow(uploaded)
      new_template <- template[rep(1, n), ]
      new_template$PatchID <- 1:n
      new_template$X <- uploaded$X
      new_template$Y <- uploaded$Y
      
      template_data(new_template)
      showNotification("Template updated successfully!", type = "message")
    })
    
    ###################################################
    # MAIN PANEL UPDATE
    ###################################################
    
    ###################################################
    # update Patches tab
    ###################################################
    observeEvent(input$update_patches, {
      temp <- template_data()
      temp$K <- input$K
      temp$`K StDev` <- input$K_StDev
      temp$N0 <- input$N0
      temp$`Natal Grounds` <- input$Natal_Grounds
      template_data(temp)
    })
    
    ###################################################
    # update Demography tab
    ###################################################
    observeEvent(input$update_demography, {
      temp <- template_data()
      temp$`Mortality Out` <- input$mortality_out
      temp$`Mortality Out StDev` <- input$mortality_out_stdev
      temp$`Mortality Back` <- input$mortality_back
      temp$`Mortality Back StDev` <- input$mortality_back_stdev
      temp$`Mortality Eggs` <- input$mortality_eggs
      temp$`Mortality Eggs StDev` <- input$mortality_eggs_stdev
      template_data(temp)
    })
    
    ###################################################
    # update Movement tab
    ###################################################
    observeEvent(input$update_movement, {
      temp <- template_data()
      
      if (input$apply_movement == "Yes") {
        temp$`Migration Out Prob` <- input$migration_out_prob
        temp$`Set Migration Out` <- input$set_migration_out
        temp$`Migration Back Prob` <- input$migration_back_prob
        temp$`Straying Prob` <- input$straying_prob
        temp$`Dispersal Prob` <- input$dispersal_prob
      } else {
        temp$`Migration Out Prob` <- 0
        temp$`Set Migration Out` <- "N"
        temp$`Migration Back Prob` <- 0
        temp$`Straying Prob` <- 0
        temp$`Dispersal Prob` <- 0
      }
      
      template_data(temp)
    })
    ###################################################
    # update Growth tab
    ###################################################
    observeEvent(input$update_growth, {
      temp <- template_data()
      
      if (input$apply_growth == "Yes") {
        temp$GrowthTemperatureOut <- input$GrowthTemperatureOut
        temp$GrowthTemperatureOutStDev <- input$GrowthTemperatureOutStDev
        temp$GrowDaysOut <- input$GrowDaysOut
        temp$GrowDaysOutStDev <- input$GrowDaysOutStDev
        temp$GrowthTemperatureBack <- input$GrowthTemperatureBack
        temp$GrowthTemperatureBackStDev <- input$GrowthTemperatureBackStDev
        temp$GrowDaysBack <- input$GrowDaysBack
        temp$GrowDaysBackStDev <- input$GrowDaysBackStDev
      } else {
        temp$GrowthTemperatureOut <- "N"
        temp$GrowthTemperatureOutStDev <- 0
        temp$GrowDaysOut <- 155
        temp$GrowDaysOutStDev <- 0
        temp$GrowthTemperatureBack <- "N"
        temp$GrowthTemperatureBackStDev <- 0
        temp$GrowDaysBack <- 0
        temp$GrowDaysBackStDev <- 0
      }
      
      template_data(temp)
    })
    ###################################################
    # update Fitness tab
    ###################################################
    # Generate dynamic UI for selection parameters
    output$implementSelectionUI <- renderUI({
      if (input$apply_selection == "Basic 1-locus") {
        tagList(
          h4("Basic 1-locus Selection Parameters"),
          numericInput("Fitness_AA", tagList("Fitness value for AA genotype [0-1]: ", em(span("Fitness_AA", style = "color:#0072B2;"))), 
                       value = 0, min = 0, max = 1, step = 0.01),
          numericInput("Fitness_Aa", tagList("Fitness value for Aa genotype [0-1]: ", em(span("Fitness_Aa", style = "color:#0072B2;"))), 
                       value = 0, min = 0, max = 1, step = 0.01),
          numericInput("Fitness_aa", tagList("Fitness value for aa genotype [0-1]: ", em(span("Fitness_aa", style = "color:#0072B2;"))), 
                       value = 0, min = 0, max = 1, step = 0.01)
        )
      } else if (input$apply_selection == "Basic 2-locus Epistatic") {
        tagList(
          h4("Basic 2-locus Epistatic Selection Parameters"),
          fluidRow(
            column(6,
                   h5("Locus A genotypes (when BB)"),
                   numericInput("Fitness_AABB", tagList("AABB: ", em(span("Fitness_AABB", style = "color:#0072B2;"))), 
                                value = 0, min = 0, max = 1, step = 0.01),
                   numericInput("Fitness_AaBB", tagList("AaBB: ", em(span("Fitness_AaBB", style = "color:#0072B2;"))), 
                                value = 0, min = 0, max = 1, step = 0.01),
                   numericInput("Fitness_aaBB", tagList("aaBB: ", em(span("Fitness_aaBB", style = "color:#0072B2;"))), 
                                value = 0, min = 0, max = 1, step = 0.01)
            ),
            column(6,
                   h5("Locus A genotypes (when Bb)"),
                   numericInput("Fitness_AABb", tagList("AABb: ", em(span("Fitness_AABb", style = "color:#0072B2;"))), 
                                value = 0, min = 0, max = 1, step = 0.01),
                   numericInput("Fitness_AaBb", tagList("AaBb: ", em(span("Fitness_AaBb", style = "color:#0072B2;"))), 
                                value = 0, min = 0, max = 1, step = 0.01),
                   numericInput("Fitness_aaBb", tagList("aaBb: ", em(span("Fitness_aaBb", style = "color:#0072B2;"))), 
                                value = 0, min = 0, max = 1, step = 0.01)
            )
          ),
          h5("Locus A genotypes (when bb)"),
          fluidRow(
            column(4,
                   numericInput("Fitness_AAbb", tagList("AAbb: ", em(span("Fitness_AAbb", style = "color:#0072B2;"))), 
                                value = 0, min = 0, max = 1, step = 0.01)
            ),
            column(4,
                   numericInput("Fitness_Aabb", tagList("Aabb: ", em(span("Fitness_Aabb", style = "color:#0072B2;"))), 
                                value = 0, min = 0, max = 1, step = 0.01)
            ),
            column(4,
                   numericInput("Fitness_aabb", tagList("aabb: ", em(span("Fitness_aabb", style = "color:#0072B2;"))), 
                                value = 0, min = 0, max = 1, step = 0.01)
            )
          )
        )
      } else if (input$apply_selection == "Growth-dependent selection") {
        tagList(
          h4("Growth-dependent Selection Parameters"),
          helpText("These fitness values will be applied based on growth conditions."),
          numericInput("Growth_Fitness_AA", tagList("Fitness value for AA genotype under growth selection [0-1]: ", em(span("Fitness_AA", style = "color:#0072B2;"))), 
                       value = 0, min = 0, max = 1, step = 0.01),
          numericInput("Growth_Fitness_Aa", tagList("Fitness value for Aa genotype under growth selection [0-1]: ", em(span("Fitness_Aa", style = "color:#0072B2;"))), 
                       value = 0, min = 0, max = 1, step = 0.01),
          numericInput("Growth_Fitness_aa", tagList("Fitness value for aa genotype under growth selection [0-1]: ", em(span("Fitness_aa", style = "color:#0072B2;"))), 
                       value = 0, min = 0, max = 1, step = 0.01)
        )
      } else if (input$apply_selection == "Maturation-dependent selection") {
        tagList(
          h4("Maturation-dependent Selection Parameters"),
          helpText("These fitness values will be applied based on maturation conditions."),
          numericInput("Maturation_Fitness_AA", tagList("Fitness value for AA genotype under maturation selection [0-1]: ", em(span("Fitness_AA", style = "color:#0072B2;"))), 
                       value = 0, min = 0, max = 1, step = 0.01),
          numericInput("Maturation_Fitness_Aa", tagList("Fitness value for Aa genotype under maturation selection [0-1]: ", em(span("Fitness_Aa", style = "color:#0072B2;"))), 
                       value = 0, min = 0, max = 1, step = 0.01),
          numericInput("Maturation_Fitness_aa", tagList("Fitness value for aa genotype under maturation selection [0-1]: ", em(span("Fitness_aa", style = "color:#0072B2;"))), 
                       value = 0, min = 0, max = 1, step = 0.01)
        )
      } else {
        return(NULL)
      }
    })
    observeEvent(input$update_selection, {
      temp <- template_data()
      
      if (input$apply_selection == "Basic 1-locus") {
        temp$Fitness_AA <- input$Fitness_AA %||% 0
        temp$Fitness_Aa <- input$Fitness_Aa %||% 0
        temp$Fitness_aa <- input$Fitness_aa %||% 0
        # Reset other fitness values
        temp$Fitness_BB <- 0
        temp$Fitness_Bb <- 0
        temp$Fitness_bb <- 0
        temp$Fitness_AABB <- 0
        temp$Fitness_AaBB <- 0
        temp$Fitness_aaBB <- 0
        temp$Fitness_AABb <- 0
        temp$Fitness_AaBb <- 0
        temp$Fitness_aaBb <- 0
        temp$Fitness_AAbb <- 0
        temp$Fitness_Aabb <- 0
        temp$Fitness_aabb <- 0
        
      } else if (input$apply_selection == "Basic 2-locus Epistatic") {
        temp$Fitness_AABB <- input$Fitness_AABB %||% 0
        temp$Fitness_AaBB <- input$Fitness_AaBB %||% 0
        temp$Fitness_aaBB <- input$Fitness_aaBB %||% 0
        temp$Fitness_AABb <- input$Fitness_AABb %||% 0
        temp$Fitness_AaBb <- input$Fitness_AaBb %||% 0
        temp$Fitness_aaBb <- input$Fitness_aaBb %||% 0
        temp$Fitness_AAbb <- input$Fitness_AAbb %||% 0
        temp$Fitness_Aabb <- input$Fitness_Aabb %||% 0
        temp$Fitness_aabb <- input$Fitness_aabb %||% 0
        # Reset single locus fitness values
        temp$Fitness_AA <- 0
        temp$Fitness_Aa <- 0
        temp$Fitness_aa <- 0
        temp$Fitness_BB <- 0
        temp$Fitness_Bb <- 0
        temp$Fitness_bb <- 0
        
      } else if (input$apply_selection == "Growth-dependent selection") {
        temp$Fitness_AA <- input$Growth_Fitness_AA %||% 0
        temp$Fitness_Aa <- input$Growth_Fitness_Aa %||% 0
        temp$Fitness_aa <- input$Growth_Fitness_aa %||% 0
        # Reset all other fitness values
        temp$Fitness_BB <- 0
        temp$Fitness_Bb <- 0
        temp$Fitness_bb <- 0
        temp$Fitness_AABB <- 0
        temp$Fitness_AaBB <- 0
        temp$Fitness_aaBB <- 0
        temp$Fitness_AABb <- 0
        temp$Fitness_AaBb <- 0
        temp$Fitness_aaBb <- 0
        temp$Fitness_AAbb <- 0
        temp$Fitness_Aabb <- 0
        temp$Fitness_aabb <- 0
        
      } else if (input$apply_selection == "Maturation-dependent selection") {
        temp$Fitness_AA <- input$Maturation_Fitness_AA %||% 0
        temp$Fitness_Aa <- input$Maturation_Fitness_Aa %||% 0
        temp$Fitness_aa <- input$Maturation_Fitness_aa %||% 0
        # Reset all other fitness values
        temp$Fitness_BB <- 0
        temp$Fitness_Bb <- 0
        temp$Fitness_bb <- 0
        temp$Fitness_AABB <- 0
        temp$Fitness_AaBB <- 0
        temp$Fitness_aaBB <- 0
        temp$Fitness_AABb <- 0
        temp$Fitness_AaBb <- 0
        temp$Fitness_aaBb <- 0
        temp$Fitness_AAbb <- 0
        temp$Fitness_Aabb <- 0
        temp$Fitness_aabb <- 0
        
      } else {
        # If 'No' is selected, reset all fitness values to default
        temp$Fitness_AA <- 0
        temp$Fitness_Aa <- 0
        temp$Fitness_aa <- 0
        temp$Fitness_BB <- 0
        temp$Fitness_Bb <- 0
        temp$Fitness_bb <- 0
        temp$Fitness_AABB <- 0
        temp$Fitness_AaBB <- 0
        temp$Fitness_aaBB <- 0
        temp$Fitness_AABb <- 0
        temp$Fitness_AaBb <- 0
        temp$Fitness_aaBb <- 0
        temp$Fitness_AAbb <- 0
        temp$Fitness_Aabb <- 0
        temp$Fitness_aabb <- 0
      }
      
      template_data(temp)
      showNotification("Fitness parameters updated successfully!", type = "message")
    })
    ###################################################
    # update Miscellaneous tab
    ###################################################
    observeEvent(input$update_capture, {
      temp <- template_data()
      
      if (input$apply_capture == "Yes") {
        temp$`Capture Probability Out` <- input$Capture_Probability_Out
        temp$`Capture Probability Back` <- input$Capture_Probability_Back
      } else {
        temp$`Capture Probability Out` <- "N"
        temp$`Capture Probability Back` <- "N"
      }
      
      template_data(temp)
    })
    observeEvent(input$update_habitat, {
      temp <- template_data()
      
      if (input$apply_habitat == "Yes") {
        temp$HabitatOut <- input$HabitatOut
        temp$HabitatBack <- input$HabitatBack
      } else {
        temp$HabitatOut <- 0
        temp$HabitatBack <- 0
      }
      
      template_data(temp)
    })
    
    observeEvent(input$update_competition, {
      temp <- template_data()
      if (input$apply_competition == "Yes") {
        temp$comp_coef <- input$comp_coef
      } else {
        temp$comp_coef <- 0.5
      }
      template_data(temp)
    })
     
    
    ###################################################
    # update Preview tab
    ###################################################
    
    output$preview_template <- renderTable({
      template_data()
    })
    
    ##############################################
    # Download Handler
    ##############################################
    output$download_patchvars <- downloadHandler(
      filename = function() {
        "PatchVars.csv"
      },
      content = function(file) {
        write.csv(template_data(), file, row.names = FALSE)
      }
    )
    
  }
  
  shinyApp(ui = ui, server = server)
}

# Call the function to run the app
write_patchvars()
