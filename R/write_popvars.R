#' Build PopVars File from Template
#'
#' This function loads a provided PopVars template, allows the user to edit selected areas,
#' and saves the modified version as a new file.
#'
#' @param output_file The name of the output file. Defaults to 'my_new_popvars.csv'.
#' @return A Shiny app instance.
#' @import shiny
#' @import shinyBS
#' @export

write_popvars <- function(output_file = "my_new_popvars.csv") {
  # Provide the template
  template <- data.frame(
    xyfilename           = NA,
    mate_cdmat           = NA,
    matemoveno           = 6,
    matemoveparA         = 0,
    matemoveparB         = 0,
    matemoveparC         = 0,
    matemovethresh       = 0,
    migrateout_cdmat     = NA,
    migratemoveOutno     = 4,
    migratemoveOutparA   = 0,
    migratemoveOutparB   = 0,
    migratemoveOutparC   = 0,
    migratemoveOutthresh = "max~max",
    migrateback_cdmat    = NA,
    migratemoveBackno    = 4,
    migratemoveBackparA  = 0,
    migratemoveBackparB  = 0,
    migratemoveBackparC  = 0,
    migratemoveBackthresh= "max~max",
    stray_cdmat          = NA,
    StrayBackno          = 4,
    StrayBackparA        = 0,
    StrayBackparB        = 0,
    StrayBackparC        = 0,
    StrayBackthresh      = "max",
    disperseLocal_cdmat  = NA,
    disperseLocalno      = 4,
    disperseLocalparA    = 0,
    disperseLocalparB    = 0,
    disperseLocalparC     = 0,
    disperseLocalthresh   = "max",
    HomeAttempt           = "mortality",
    sex_chromo            = 2,
    sexans                = "Y",
    selfans               = "N",
    Freplace              = "Y",
    Mreplace              = "Y",
    AssortativeMate_Model = 1,
    AssortativeMate_Factor= 1,
    mature_default        = "age3",
    mature_eqn_slope      = "0.0539",
    mature_eqn_int        = "-6.313",
    offno                 = 2,
    offans_InheritClassVars = "random",
    equalClutchSize       = "Y",
    Egg_Freq_Mean         = 1,
    Egg_Freq_StDev        = 0,
    Egg_Mean_ans          = "linear",
    Egg_Mean_par1         = 126,
    Egg_Mean_par2         = 0.0061,
    Egg_Mortality         = 0.62,
    Egg_Mortality_StDev   = 0,
    Egg_FemaleProb        = 0.5,
    startGenes            = 0,
    loci                  = 2,
    alleles               = 2,
    muterate              = 0,
    mutationtype          = "random",
    mtdna                 = "N",
    cdevolveans           = "N",
    startSelection        = 0,
    implementSelection    = "Out",
    betaFile_selection    = "N",
    plasticgeneans        = "N",
    plasticSignalResponse = 0,
    plasticBehavioralResponse = 0,
    startPlasticgene      = 0,
    implementPlasticgene  = "Back",
    #cdinfect             = "N",# not in next version
    #transmissionprob     = 1.5, # not in next version
    growth_option         = "N",
    growth_Loo            = 250,
    growth_R0             = 0.57,
    growth_temp_max       = 12,
    growth_temp_CV        = 0.25,
    growth_temp_t0        = -0.075,
    popmodel              = "packing",
    popmodel_par1         = -0.682,
    correlation_matrix    = "N",
    subpopmort_file       = "N",
    egg_delay             = 0,
    egg_add               = "mating",
    implement_disease     = "N" # don't know the options yet... Ask Erin... Which tab???? 
  )
  ############################################
  ################## UI ######################
  ############################################
  
  ui <- fluidPage(
    tags$head(
      tags$style(HTML("
    /* Hide arrows in numericInput for Chrome, Safari, Edge */
    input[type=number]::-webkit-inner-spin-button, 
    input[type=number]::-webkit-outer-spin-button {
      -webkit-appearance: none;
      margin: 0;
    }
    /* Hide arrows for Firefox */
    input[type=number] {
      -moz-appearance: textfield;
    }
  "))
    ),
    titlePanel("Build a PopVars.csv File"),
    helpText(
      "Welcome! This shiny app instance will help you put together a PopVars.csv file to use as a CDmetaPOP input file.",
      "Please indicate the paths to the patchvars and cost distance matrices on the left panel.",
      "Also, if needed, select any of the tabs below and change the default parameters of the simulations in order to better reflect those of the system you want to test. The parameter that will be changed according to your choices is indicated for each section as ",
      em(span("parameter", style = "color:#0072B2; font-weight: bold;")),
      "."
    )
    ,
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
        # How to best organize your directories
        div(
          class = "upload-block",
          h5("How to best organize your directories"),
          # The Help button
          actionButton("directory_help", "Show help")
        ),
        
        # Patchvars
        div(
          class = "upload-block",
          h5("Patchvars"),
          textInput("patchvars_file", label = "Type the file name of your patchvars.csv file: "),
          actionButton("update_patchvars", tagList(
            "Apply changes ",
            em(span("xyfilename", style = "color:#0072B2; font-weight: bold;"))  # xyfilename is the column name in the template
          ))
        ),
        
        # mating cost-distance matrix
        div(
          class = "upload-block",
          h5("Mating Movement"),
          textInput("mate_cdmat_file", "Type the file name of the distance matrix for mating movement"),
          actionButton("update_cdmat", tagList(
            "Apply changes ",
            em(span("mate_cdmat", style = "color:#0072B2; font-weight: bold;"))
          ))
        ),
        
        # Correlation matrix
        div(
          class = "upload-block",
          h5("Dispersal Movement"),
          radioButtons(
            "cor_matrix_source",
            tagList(
              "Do you want to use a correlation matrix?:",
              em(span("correlation_matrix", style = "color:#0072B2;"))
            ),
            choices = c("Yes" = "file", "Do not use a Correlation Matrix" = "N"),
            selected = "N"
          ),
          conditionalPanel(
            condition = "input.cor_matrix_source == 'file'",
            tagList(
              textInput("Patch_r", "Type the file name of the Correlation Matrix File"),
              actionButton("update_corrmatrix", tagList(
                "Apply changes ",
                em(span("correlation_matrix", style = "color:#0072B2; font-weight: bold;"))
              ))
            )
          )
        ),
        
        # Subpopmort
        div(
          class = "upload-block",
          h5("Mortality Matrix"),
          radioButtons(
            "subpopmort_source",
            tagList(
              "Subpopulation mortality matrix source:",
              em(span("subpopmort_file", style = "color:#0072B2; font-weight: bold;"))
            ),
            choices  = c("Yes" = "file", "Do not use a subpopulation mortality matrix" = "N"),
            selected = "N"
          ),
          conditionalPanel(
            condition = "input.subpopmort_source == 'file'",
            tagList(
              textInput("Subpopmort_file", "Write name of Percent Mortality Matrix"),
              actionButton("update_subpopmort", tagList(
                "Apply changes ",
                em(span("subpopmort_file", style = "color:#0072B2; font-weight: bold;"))
              ))
            )
          )
        ),
        
        # Download button
        downloadButton("download_popvars", "Download PopVars File")
      ),
      
      ###################################
      # MAIN PANEL 
      ###################################
      mainPanel(
        tabsetPanel(
          #################
          # Population Growth Tab #
          #################
          tabPanel(
            "Population Growth",
            selectInput("popmodel", tagList("Enter choice for population growth ", em(span("popmodel", style = "color:#0072B2;"))),
                        selected = "packing",
                        choices = c("N", "logistic", "packing", "anadromy")
            ),                        
            actionButton("update_population_growth", "Apply changes")
          ),
          #################
          # Growth Tab #
          #################
          tabPanel(
            "Growth",
            HTML("<b style='color:red;'>⚠ Warning: If in RunVars.csv, the value for cdevolveans points to fitness-based growth, CDMetaPOP will use the growth parameters from the PatchVars.csv. Therefore, the growth parameters from the PopVars.csv will be ignored.</b>"),
            selectInput("growth_option", tagList("Enter choice for Growth Pattern ", em(span("growth_option", style = "color:#0072B2;"))),
                        selected = "temperature",
                        choices = c("N", "known", "vonB", "temperature", "temperature_hindex", "bioenergetics")
            ),
            conditionalPanel(
              condition = "!['N', 'known'].includes(input.growth_option)",
              textInput("growth_Loo", tagList("Enter the value(s) for the von Bertalanffy asymptotic length value (L∞) ", em(span("growth_Loo", style = "color:#0072B2;"))), value = 250),
              numericInput("growth_R0", tagList("Enter the value for the von Bertalanffy Growth Rate value (R0) ", em(span("growth_R0", style = "color:#0072B2;"))), value = 0.57, min = 0),
              numericInput("growth_temp_max", tagList("Maximum Temperature ", em(span("growth_temp_max", style = "color:#0072B2;"))), value = 12),
              numericInput("growth_temp_CV", tagList("Enter a value between 0-1 for the temperature coefficient of variation ", em(span("growth_temp_CV", style = "color:#0072B2;"))), value = 0.25, min = 0, max = 1),
              numericInput("growth_temp_t0", tagList("Theoretical Age at Length 0 (t0) ", em(span("growth_temp_t0", style = "color:#0072B2;"))), value = -0.075)
            ),
            actionButton("update_growth", "Apply changes")
          ),
          ####################################
          # Reproduction Tab
          ####################################
          tabPanel(
            "Reproduction",
            selectInput("sex_chromo", tagList("Enter the number of sex chromosome combinations ", em(span("sex_chromo", style = "color:#0072B2;"))),
                        selected = 2,
                        choices = 2:4
            ),
            selectInput("sexans", tagList("This option determines heterosexual or asexual reproduction. Enter Y for sexual reproduction, N for asexual, and H for hermaphroditic ", em(span("sexans", style = "color:#0072B2;"))),
                        selected = "Y",
                        choices = c("Y", "N", "H")
            ),
            uiOutput("selfans_input"), # This will render either selectInput or numericInput
            
            selectInput("Freplace", tagList("Enter whether females mate with replacement 'Y' or not 'N' ", em(span("Freplace", style = "color:#0072B2;"))),
                        selected = "Y",
                        choices = c("Y", "N")
            ),
            selectInput("Mreplace", tagList("Enter whether males mate with replacement 'Y' or not 'N' ", em(span("Mreplace", style = "color:#0072B2;"))),
                        selected = "Y",
                        choices = c("Y", "N")
            ),
            selectInput("AssortativeMate_Model", tagList("Enter choice for mating model ", em(span("AssortativeMate_Model", style = "color:#0072B2;"))),
                        selected = "1",
                        choices = c("1", "2", "3a", "3b", "4", "5")
            ),
            uiOutput("AssortativeMate_Factor"), # rendering determined by choice given in AssortativeMate_Model
            selectInput("mature_default", tagList("Do you want to force individuals to become mature at a given size or age?", em(span("mature_default", style = "color:#0072B2;"))),
                        choices = c("N", "age", "size"),
                        selected = "age3"
            ),
            uiOutput("mature_input"), # This will render either selectInput or numericInput
            numericInput("egg_delay", tagList("Enter an integer ≥ 0 for the number of years (time-steps) between mating and gestation/emergence. Please note that 0 is the most common option here.", em(span("egg_delay", style = "color:#0072B2;"))), value = 0, step = 0.1, min = 0),
            #uiOutput("mature_eqn_slope"), # This will render either selectInput or numericInput
            #uiOutput("mature_eqn_int"), # This will render either selectInput or numericInput
            numericInput("mature_eqn_slope", tagList("Enter the value for the slope of the maturity equation ", em(span("mature_eqn_slope", style = "color:#0072B2;"))), value = 0.0539),
            numericInput("mature_eqn_int", tagList("Enter the value for the intercept of the maturity equation ", em(span("mature_eqn_int", style = "color:#0072B2;"))), value = -6.313),
            actionButton("update_reproduction", "Apply changes")
          ),
          
          ####################################
          # Offspring Tab
          ####################################
          tabPanel(
            "Offspring",
            uiOutput("offno"),
            bsTooltip(
              "offno",
              "‘1’ – random draw between 0 and mean fecundity value. ‘2’ - Poisson draw of mean fecundity value.‘3’ - constant number of offspring of mean fecundity value.‘4’ - normal draw with mean fecundity and standard deviation.",
              "right"
            ),
            selectInput("offans_InheritClassVars", tagList("Select how offsprings will inherit their parent's classvars file ", em(span("offans_InheritClassVars", style = "color:#0072B2;"))),
                        choices = c("random", "Hindex", "mother"),
                        selected = "random"
            ),
            selectInput("equalClutchSize", tagList("Select whether each mate pair will have an equal clutch size.", em(span("equalClutchSize", style = "color:#0072B2;"))),
                        choices = c("Y", "N"),
                        selected = "N"
            ),
            numericInput("Egg_Freq_Mean", tagList("Indicate a value for the frequency of egg laying events each year ", em(span("Egg_Freq_Mean", style = "color:#0072B2;"))),
                         value = 1,
                         min = 0
            ),
            bsTooltip(
              "Egg_Freq_Mean",
              "e.g. 0.5 means a mature female lays eggs every other year",
              "right"
            ),
            numericInput("Egg_Freq_StDev", tagList("Indicate a standard deviation value for the egg laying events frequency ", em(span("Egg_Freq_StDev", style = "color:#0072B2;"))),
                         value = 0,
                         min = 0
            ),
            bsTooltip(
              "Egg_Freq_StDev", "If nonzero, then stochastic variability will occur at every time step",
              "right"
            ),
            
            selectInput("Egg_Mean_ans",
                        tagList("Select the size-based fecundity function ",
                                em(span("Egg_Mean_ans", style = "color:#0072B2;"))),
                        choices = c("exp", "linear", "pow"),
                        selected = "linear"
            ),
            bsTooltip(
              "Egg_Mean_ans",
              "If size control is specified in sizecontrol column in RunVars, then this choice is used to produce the number of offspring a female will have.",
              placement = "right",
              trigger = "hover"
            ),
            #uiOutput("Egg_Mean_ans"),
            numericInput("Egg_Mean_par1",
                         tagList("Enter the parameters values used to fit size-based fecundity function above", em(span("Egg_Mean_par1", style = "color:#0072B2;"))),
                         value = 126
            ),
            bsTooltip(
              "Egg_Mean_par1",
              "Enter specific value if size control is specified in sizecontrol column in RunVars.",
              "right"
            ),
            numericInput("Egg_Mean_par2",
                         tagList("Enter the parameters values used to fit size-based fecundity function above ", em(span("Egg_Mean_par2", style = "color:#0072B2;"))),
                         value = 0.0061
            ),
            bsTooltip(
              "Egg_Mean_par2",
              "Enter specific value if size control is specified in sizecontrol column in RunVars.",
              "right"
            ),
            numericInput("Egg_Mortality",
                         tagList("Indicate a value between 0-1 for the egg mortality ", em(span("Egg_Mortality", style = "color:#0072B2;"))),
                         value = 0.62, min = 0, max = 1
            ),
            numericInput("Egg_Mortality_StDev",
                         tagList("Indicate a value for egg mortality standard deviation ", em(span("Egg_Mortality_StDev", style = "color:#0072B2;"))),
                         value = 0,
                         min = 0
            ),
            bsTooltip(
              "Egg_Mortality_StDev",
              "If a nonzero value is placed here, then stochastic variability will occur at every time step.",
              "right"
            ),
            radioButtons("Egg_FemaleProbChoice",
                         tagList("Select sex ratio type ", em(span("Egg_FemaleProb", style = "color:#0072B2;"))),
                         choices = c("Numeric (0-1)" = "numeric", "WrightFisher" = "WrightFisher"),
                         selected = "numeric"
            ),
            uiOutput("Egg_FemaleProbInput"),
            actionButton("update_offspring", "Apply changes")
          ),
          
          
          ####################################
          # Genetics Tab 
          ####################################
          tabPanel(
            "Genetics",
            numericInput("startGenes", tagList("When will genetic exchange start? Input Year/Generation ", em(span("startGenes", style = "color:#0072B2;"))), value = 0, min = 0),
            bsTooltip(
              "startGenes",
              "The year/generation at which genetic exchange will begin. For example, use a later year to begin swapping genes while population dynamics stabilize",
              "right"
            ),
            numericInput("loci", tagList("Number of Loci ", em(span("loci", style = "color:#0072B2;"))), value = 2, min = 2),
            bsTooltip(
              "loci",
              "‘2’ – max number dependent on computer resources - The number of loci (microsatellites/snps). Recommended maximum number of loci dependent on computer resources and recommend test runs for tradeoffs in performance. If a file is specified in the ClassVars.csv input file, then the number of loci entered here must match this file", "right"
            ),
            numericInput("alleles", tagList("Starting Alleles per Locus ", em(span("alleles", style = "color:#0072B2;"))), value = 2, min = 2),
            bsTooltip(
              "alleles",
              "The number of starting alleles per locus. If a file is specified in the PatchVars.csv input file (Genes Initialize column), then the number of alleles entered here must match this file. Polymorphism or varying number of alleles can be used by specifying the maximum number of alleles here and filling in allele frequency values of 0 for ‘filler’ alleles in other loci locations", "right"
            ),
            
            wellPanel(
              radioButtons("apply_mutation", "Apply Mutation?",
                           choices = c("No", "Yes"), 
                           selected = "No", 
                           inline = TRUE),
              # Show mutation settings only if 'Yes' is selected
              conditionalPanel(
                condition = "input.apply_mutation == 'Yes'",
                numericInput("muterate", tagList("Allele Mutation Rate ", em(span("muterate", style = "color:#0072B2;"))), value = 0, min = 0, max = 1, step = 0.01),
                bsTooltip(
                  "muterate",
                  "Mutation rate ranges between a value of 0 - 1",
                  "left"
                ),
                selectInput("mutationtype", tagList("Enter the Mutation Model you want to implement ", em(span("mutationtype", style = "color:#0072B2;"))),
                            choices = c("random", "forward", "backward", "forwardbackward", "forwardAbackwardBrandomN"),
                            selected = "random"
                ),
              )
            ),
            
            selectInput("mtdna", tagList("Track maternal genes ", em(span("mtdna", style = "color:#0072B2;"))),
                        choices = c("Y", "N"),
                        selected = "N"
            ),
            actionButton("update_genetics", "Apply changes")
          ),
          
          
          ######################################
          # Selection Tab  
          ######################################
          tabPanel(
            "Selection",
            wellPanel(
              radioButtons("apply_selection", "Apply Selection?",
                           choices = c("No", "Yes"), 
                           selected = "No", 
                           inline = TRUE),
              
              # Show selection settings only if 'Yes' is selected
              conditionalPanel(
                condition = "input.apply_selection == 'Yes'",
                radioButtons(
                  "cdevolveansChoice",
                  HTML(
                    paste0(
                      "Select Selection Type (only the first 2 alleles of each locus are used), ",
                      "<i><span style='color:#0072B2;'>cdevolveans</span></i>:"
                    )
                  ),
                  choices = c(
                    
                    "Selection with 1 locus A" = "1",
                    "Selection with 2 loci (A and B)" = "2",
                    "M" = "M",
                    "G" = "G",
                    "MG_ind" = "MG_ind",
                    "MG_link" = "MG_link",
                    "1_mat" = "1_mat",
                    "2_mat" = "2_mat",
                    "stray" = "stray",
                    "1_G_ind" = "1_G_ind",
                    "1_G_link" = "1_G_link",
                    "Multiple loci/alleles" = "multi",
                    "Hindex Gauss" = "hindex_gauss",
                    "Hindex Para" = "hindex_para",
                    "Hindex Step" = "hindex_step",
                    "Hindex Linear" = "hindex_linear",
                    "F Linear" = "F_linear",
                    "F Logistic" = "F_logistic"
                  ),
                  selected = "N"
                ),
                conditionalPanel(
                  condition = "['multi', 'hindex_gauss', 'hindex_para', 'hindex_step', 'hindex_linear', 'F_linear', 'F_logistic'].includes(input.cdevolveansChoice)",
                  tagList(
                    div(
                      style = "color: red; font-weight: bold; margin-bottom: 10px;",
                      "⚠️ Advanced Users Only - see CDmetaPOP manual for additional details")
                  ),
                  textAreaInput(
                    "multiSelectionText",
                    HTML("Enter desired selection model details: "),
                    placeholder = "e.g. M_X{n}_L{l}_A{a}_Model{XY}",
                    rows = 1
                  )
                ),
                numericInput(
                  "startSelection",
                  HTML(
                    "When will selection start? Input Year/Generation (<i><span style='color:#0072B2;'>startSelection</span></i>):"
                  ),
                  value = 0,
                  min = 0
                ),
                
                checkboxGroupInput(
                  "implementSelectionChoice",
                  HTML(
                    paste0(
                      "Indicate the option to apply selection at specific timing events. ",
                      "You can select multiple options ",
                      "(<i><span style='color:#0072B2;'>implementSelectionChoice</span></i>):"
                    )
                  ),
                  choices = c(
                    "Out" = "Out",
                    "Back" = "Back",
                    "Eggs" = "Eggs",
                    "packing" = "packing",
                    "Out_age" = "Out_age",
                    "Back_age" = "Back_age"
                  )
                ), 
                uiOutput("warning")
                ,
                uiOutput("implementSelectionUI"),
                radioButtons(
                  "betaFileSelectionChoice",
                  HTML(
                    paste0(
                      "Beta File Selection Option ",
                      "(<i><span style='color:#0072B2;'>betaFileSelectionChoice</span></i>):"
                    )
                  ),
                  choices = c(
                    "No" = "N",
                    "write path to CSV or excel" = "path"
                  ),
                  selected = "N"
                )
                ,
                uiOutput("betaFileSelectionUI"),
                actionButton("update_selection", "Apply changes")
                
              )
            ),
          ),
          
          
          # ####################################
          # # Movement Tab 
          # ####################################
          tabPanel(
            "Movement",
            # MATE section
            wellPanel(
              h4("Mate Movement"),
              numericInput("matemoveno", tagList("Probability of Mate Movement ", em(span("matemoveno", style = "color:#0072B2;"))), value = 6, min = 1, max = 11, step = 1),
              uiOutput("mate_extra_ui"),
              radioButtons("apply_max_threshold", "Do you want to define a maximum mating movement threshold?",
                           choices = c("No", "Yes"),
                           selected = "No",
                           inline = TRUE),
              conditionalPanel(
                condition =  "input.apply_max_threshold == 'Yes'",
                numericInput("matemovethresh", tagList("Select a threshold option in effective distance units for how far an individual can search for a mate  ",
                                                       em(span("matemovethresh", style = "color:#0072B2;"))), value = 0, min = 0),
                bsTooltip(
                  "matemovethresh",
                  "If you want to set your own maximum threshold for mate movement, enter a value greater than 0. Otherwise, leave No and the maximum movement value will be the maximum value entered in the uploaded cost distance matrix.",
                  "left")
              ),
              
              actionButton("update_mate", "Apply changes"),
              actionButton("help_mate", "?", class = "btn-info")
            ),
            
            # MIGRATION Section
            wellPanel(
              radioButtons("apply_migration", "Apply Migration?",
                           choices = c("No", "Yes"),
                           selected = "No",
                           inline = TRUE),
              
              # Show migration settings only if 'Yes' is selected
              conditionalPanel(
                condition = "input.apply_migration == 'Yes'",
                
                # MIGRATE OUT Section
                wellPanel(
                  h4("Migrate Out Movement"),
                  textInput("migrateout_cdmat_file", "Type the file name of the distance matrix for migrating out movement"),
                  actionButton("update_migrateout_cdmat",
                               tagList("Apply changes ", em(span("migrateout_cdmat", style = "color:#0072B2; font-weight: bold;")))),
                  numericInput("migrateoutno",
                               tagList("Migrate Out Movement Option Number",
                                       em(span("migratemoveOutno", style = "color:#0072B2;"))),
                               value = 4, min = 1, max = 11, step = 1),
                  uiOutput("migrateout_extra_ui"),
                  textInput( "migratemoveOutthresh",
                             tagList(
                               "Input a threshold option in effective distance units for how far an individual can migrate out:",
                               em(span("migratemoveOutthresh", style = "color:#0072B2;")))),
                  actionButton("update_migrateout", "Apply changes"),
                  actionButton("help_migrateout", "?", class = "btn-info"),
                ),
                
                # MIGRATE BACK Section
                wellPanel(
                  h4("Migrate Back Movement"),
                  textInput("migrateback_cdmat_file", "Type the file name of the distance matrix for migrating back movement"),
                  
                  actionButton("update_migrateback_cdmat",
                               tagList("Apply changes ", em(span("migrateback_cdmat", style = "color:#0072B2; font-weight: bold;")))),
                  
                  numericInput("migratebackno",
                               tagList("Probability of Migrate Back",
                                       em(span("migratemoveBackno", style = "color:#0072B2;"))),
                               value = 4, min = 1, max = 11, step = 1),
                  
                  uiOutput("migrateback_extra_ui"),
                  
                  textInput("migratemoveBackthresh",
                            tagList("Input a threshold option in effective distance units for how far an individual can migrate back: ",
                                    em(span("migratemoveBackthresh", style = "color:#0072B2;")))),
                  
                  selectInput(
                    "HomeAttempt",
                    HTML("There is a possibility that a migrant that did not become a strayer attempts to immigrate back to its original natal patch but cannot. Select the case (<i><span style='color:#0072B2;'>HomeAttempt</span></i>):"),
                    selected = "mortality",
                    choices = c("mortality", "stray_emiPop", "stray_natalPop")
                  ),
                  actionButton("update_migrateback", "Apply changes"),
                  actionButton("help_migrateback", "?", class = "btn-info"),
                )
              )
            ),
            # STRAY section
            wellPanel(
              radioButtons("apply_stray", "Apply Stray?",
                           choices = c("No", "Yes"),
                           selected = "No",
                           inline = TRUE),
              # Show stray settings only if 'Yes' is selected
              conditionalPanel(
                condition = "input.apply_stray == 'Yes'",
                
                h4("Stray Movement"),
                textInput("stray_cdmat_file", "Type the file name of the distance matrix for stray movement"),
                actionButton("update_stray_cdmat",
                             tagList("Apply changes ", em(span("stray_cdmat", style = "color:#0072B2; font-weight: bold;")))),
                
                numericInput("strayno",
                             tagList("Probability of Stray ", em(span("StrayBackno", style = "color:#0072B2;"))),
                             value = 4, min = 1, max = 11, step = 1),
                uiOutput("stray_extra_ui"),
                textInput(
                  "StrayBackthresh",
                  tagList("Input a threshold option in effective distance units for how far an individual can stray: ",
                          em(span("StrayBackthresh", style="color:#0072B2;")))),
                
                actionButton("update_stray", "Apply changes"),
                actionButton("help_stray", "?", class = "btn-info"),
              )
            ),
            
            # DISPERSE section
            wellPanel(
              radioButtons("apply_dispersal", "Apply Dispersal?",
                           choices = c("No", "Yes"),
                           selected = "No",
                           inline = TRUE),
              
              # Show dispersal settings only if 'Yes' is selected
              conditionalPanel(
                condition = "input.apply_dispersal == 'Yes'",
                h4("Dispersal Movement"),
                textInput("disperse_cdmat_file", "Type the file name of the distance matrix for dispersal movement"),
                actionButton("update_disperse_cdmat",
                             tagList("Apply changes ", em(span("disperse_cdmat", style = "color:#0072B2; font-weight: bold;")))),
                
                numericInput("disperseLocalno", tagList("Probability of Dispersal ", em(span("disperseLocalno", style = "color:#0072B2;"))), value = 4, min = 1, max = 11, step = 1),
                uiOutput("disperseLocal_extra_ui"),
                textInput(
                  "disperseLocalthresh",
                  tagList("Input a threshold option in effective distance units for how far an individual can disperse ",
                          em(span("disperseLocalthresh", style="color:#0072B2;")))),
                
                actionButton("update_disperseLocal", "Apply changes"),
                actionButton("help_disperse", "?", class = "btn-info"),
              )
            ),
          ),
          ####################################
          # Plasticity tab
          ####################################
          tabPanel(
            "Plasticity",
            wellPanel(
              h4("Behavioral Plasticity"),
              # Yes/No choice
              radioButtons(
                "apply_behavioral_plasticity",
                HTML(
                  "Apply behavioral plasticity? (<i><span style='color:#0072B2;'>plasticgeneans</span></i>)"
                ),
                choices = c("Yes", "No"),
                selected = "No"
              ),
              
              # UI that appears only if Yes
              conditionalPanel(
                condition = "input.apply_behavioral_plasticity == 'Yes'",
                
                selectInput(
                  "plastic_signal_type",
                  HTML(
                    "Select the signal type (<i><span style='color:#0072B2;'>plasticgeneans</span></i>):"
                  ),
                  choices = c("Temp", "Hab")
                ),
                
                selectInput(
                  "plastic_allele_response",
                  HTML(
                    "Select allele response type (<i><span style='color:#0072B2;'>plasticgeneans</span></i>):"
                  ),
                  choices = c("dom", "rec", "codom")
                ),
                
                sliderInput(
                  "plastic_signal_threshold",
                  HTML(
                    "Signal threshold (<i><span style='color:#0072B2;'>plasticgeneans</span></i>):"
                  ),
                  min = 0, max = 100, value = 0, step = 0.1
                ),
                
                sliderInput(
                  "plastic_behavior_response",
                  HTML(
                    "Behavioral response (<i><span style='color:#0072B2;'>plasticsignalResponse</span></i>):"
                  ),
                  min = 0, max = 1, value = 0, step = 0.01
                ),
                
                sliderInput(
                  "plastic_response_reduction",
                  HTML(
                    "Response reduction (0–1) (<i><span style='color:#0072B2;'>plasticBehavioralResponse</span></i>):"
                  ),
                  min = 0, max = 1, value = 0, step = 0.01
                ),
                
                numericInput(
                  "startPlasticgene",
                  HTML(
                    "This is the time unit that the plastic process will begin operating on the plastic locus region (<i><span style='color:#0072B2;'>startPlasticgene</span></i>):"
                  ),
                  value = 0
                ),
                selectInput(
                  "implementPlasticgene",
                  HTML(
                    "Apply plasticity at specific times (<i><span style='color:#0072B2;'>plasticgeneans</span></i>):"
                  ),
                  choices = c("Out", "Back", "Out:Back")
                ),
              ),
              
              actionButton("update_plasticity", "Apply changes")
            )
          ),
          
          ####################################
          # Preview Tab
          #####################################
          tabPanel(
            "Preview Updated PopVars",
            tableOutput("preview_template")
          )
        )
      )
    )
  )
  
  ######################################################
  # SERVER 
  #######################################################
  
  server <- function(input, output, session) {
    # Reactive to store template
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
    
    
    ###################################
    # Patchvars help button 
    ###################################
    observe({
      addTooltip(
        session,
        "patchvars_file",
        HTML(
          "If you don't have a patchvars file yet, you can skip this step for now and you may use the <code>write_patchvars.R</code> function to build one. If your patchvars is in a subdirectory, make sure to type it in here too. For example: <code>patchvars/patchVars.csv</code>."
        ),
        placement = "right",
        trigger = "hover"
      )
    })
    
    
    #####################################################
    # MAIN PANEL HELP 
    #####################################################
    
    ###################################
    # Help Population growth parameters #
    ###################################
    
    observe({
      addTooltip(session, "popmodel",
                 "Select the population growth model: 'N' - exponential growth; 'logistic' - density-dependent age-structured Leslie matrix model modified for logistic growth; 'packing' - density-dependent class specific population model, competition simulated among all classes simultaneously; 'anadromy' - density-dependent packing model for individuals that have not yet migrated to the ocean",
                 placement = "right",
                 trigger = "hover"
      )
    })
    
    ###################################
    # Help growth parameters #
    ###################################
    observe({
      addTooltip(session, "growth_option",
                 "'Select the growth function option for your model: These functions can work for either size or age control (as specified in RunVars.csv). 'N' - turn off growth and the rest of the growth parameters are ignored.'known' - assign each individual's size by a known amount each year. 'vonB' - von Bertalanffy equation for growth. Newsize = size_Loo * (1 - exp( -size_R0 * ('adjusted' age + 1))). 'temperature' - the von Bertalanffy function is modified by parameters that are fit to temperature. 'temperature_hindex' - the above temperature growth model is used with the individual's HIndex which adjusts the Loo parameter. 'bioenergetics' - ...",
                 placement = "right",
                 trigger = "hover"
      )
    })
    ###################################
    # Help reproduction parameters #
    ###################################
    
    # This inserts tooltip for sex_chromo
    observe({
      addTooltip(session, "sex_chromo",
                 "Enter '2' if your sims include XX females and XY males only; Enter '3' for XX, XY, and YY males; Enter '4' for XX, XY, YY males and YY females",
                 placement = "right",
                 trigger = "hover"
      )
    })
    
    # This insert tooltip for assortative mating model
    observe({
      addTooltip(session, "AssortativeMate_Model",
                 "‘1’ – Random mating; ‘2’ – Strict self-preference mating; ‘3’ – Self-preference; ‘4’ – Dominance-preference; ‘5’ – Linear-preference",
                 placement = "right",
                 trigger = "hover"
      )
    })
    
    
    ###################################
    # Help offspring parameters #
    ###################################
    
    # This inserts tooltip for offans_InheritClassVars
    
    observe({
      addTooltip(
        session, 
        "offans_InheritClassVars",
        HTML("
      <div style='text-align: left; white-space: normal;'>
        <strong>'Random'</strong> – equal probability of receiving mother’s or father’s ClassVars file and associated parameters;<br>
        <strong>'Hindex'</strong> – weighted probability of receiving ClassVars files associated with Hindex values;<br>
        <strong>'Mother'</strong> – all offspring inherit the mother’s ClassVars
      </div>
    "),
        placement = "right",
        trigger = "hover"
      )
    })
    
    # This inserts tooltip for  equalClutchSize
    
    observe({
      addTooltip(
        session, 
        "equalClutchSize",
        HTML("<div style='text-align: left;'>Careful! Y is the most common choice. This parameter interacts with <em><span style='color:#0072B2;'>Freplace</span></em>, see user manual for more details"),
        placement = "right",
        trigger = "hover"
      )
    })
    
    ###################################
    # Help genetics parameters #
    ###################################
    
    # This inserts tooltip for startGenes
    observe({
      addTooltip(session, "startGenes",
                 "The year/generation at which genetic exchange will begin. For example, use a later year to begin swapping genes while population dynamics stabilize",
                 placement = "right",
                 trigger = "hover"
      )
    })
    
    # This inserts tooltip for loci
    observe({
      addTooltip(session, "loci",
                 "‘2’ to max.  Max number is dependent on computer resources",
                 placement = "right",
                 trigger = "hover"
      )
    })
    
    # This inserts tooltip for mutationtype
    observe({addTooltip(
      session = session,
      id = "mutationtype",
      title = HTML(
        "<div style='text-align: left; white-space: normal;'>
        <strong>‘random’</strong> – kth-allele mutation model.<br>
        <strong>‘forward’</strong> – step-wise mutation in which an allele can mutate forwards only.<br>
        <strong>‘backward’</strong> – step-wise mutation in which an allele can mutate backwards only.<br>
        <strong>‘forwardbackward’</strong> – step-wise mutation in which an allele can mutate forward or backwards only.<br>
        <strong>‘forwardAbackwardBrandomN’</strong> – special case for the 2-locus selection model
      </div>"
      ),
      placement = "left",
      trigger = "hover"
    )
    })
    
    
    # This inserts tooltip for mtdna
    observe({
      addTooltip(
        session = session,
        id = "mtdna",
        title = HTML(
          "<div style='text-align: left; white-space: normal;'>
        Tracking maternal genes:<br>
        <strong>‘Y’</strong> - the last locus becomes the maternal marker (mtDNA) and every offspring inherits this locus from its mother only.<br>
        <strong>‘N’</strong> - regular Mendel inheritance occurs for the last locus.
      </div>"
        ),
        placement = "right",
        trigger = "hover"
      )
    })
    
    ###################################
    # Help selection parameters 
    ###################################
    
    ###################################
    # Help movement parameters #
    ###################################
    
    ###################################
    # Help plasticity parameters #
    ###################################
    
    
    #####################################################
    # MAIN PANEL UPDATE
    #####################################################
    
    ###################################
    # Update Population Growth 
    ###################################
    # UI rendering for popmodel parameter
    
    output$Popmodel_par1 <- renderUI({
      if (input$popmodel %in% "packing") {
        numericInput(
          "popmodel_param",
          HTML(
            paste0(
              "Define the packing parameter that shapes the ideal class distribution: ",
              "<i><span style='color:#0072B2;'>Popmodel_par1</span></i>"
            )
          ),
          value = -0.6821
        )
      }
    })
    observeEvent(input$update_population_growth, {
      temp <- template_data()
      temp$popmodel <- input$popmodel
      
      if (input$popmodel %in% "packing") {
        temp$popmodel_par1 <- input$popmodel_param
      }
      
      template_data(temp)
    })
    ###################################
    # Update Growth
    ###################################
    observeEvent(input$update_growth, {
      temp <- template_data()
      temp$growth_option <- input$growth_option
      
      if (!input$growth_option %in% c("N", "known")) {
        loo_values <- as.numeric(unlist(strsplit(input$growth_Loo, ";")))
        if (any(is.na(loo_values))) {
          showNotification("growth_Loo must be numeric values separated by semicolons, e.g. 250;300", type = "error")
          return()
        }
        temp$growth_Loo       <- loo_values
        temp$growth_R0        <- input$growth_R0
        temp$growth_temp_max  <- input$growth_temp_max
        temp$growth_temp_CV   <- input$growth_temp_CV
        temp$growth_temp_t0   <- input$growth_temp_t0
      }
      template_data(temp)
    })
    ####################################
    # Update Offspring/litter/egg/sex ratio options
    ####################################
    
    # Dinamically display numeric input only if 'numeric' is selected
    output$Egg_FemaleProbInput <- renderUI({
      if (input$Egg_FemaleProbChoice == "numeric") {
        numericInput(
          "Egg_FemaleProbValue",
          tagList(
            "Define sex ratio probability at birth (0-1): ",
            em(span("Egg_FemaleProb", style = "color:#0072B2;"))
          ),
          value = 0.5,
          min = 0,
          max = 1,
          step = 0.01
        )
      }
    })
    observeEvent(input$update_offspring, {
      temp <- template_data()
      temp$offno <- input$offno
      temp$offans_InheritClassVars <- input$offans_InheritClassVars
      temp$equalClutchSize <- input$equalClutchSize
      temp$Egg_Freq_Mean <- input$Egg_Freq_Mean
      temp$Egg_Freq_StDev <- input$Egg_Freq_StDev
      temp$Egg_Mean_ans <- input$Egg_Mean_ans
      temp$Egg_Mean_par1 <- input$Egg_Mean_par1
      temp$Egg_Mean_par2 <- input$Egg_Mean_par2
      temp$Egg_Mortality <- input$Egg_Mortality
      temp$Egg_Mortality_StDev <- input$Egg_Mortality_StDev
      if (input$Egg_FemaleProbChoice == "numeric") {
        temp$Egg_FemaleProb <- input$Egg_FemaleProbValue
      } else {
        temp$Egg_FemaleProb <- "WrightFisher"
      }
      temp$egg_delay <- input$egg_delay
      template_data(temp)
    })
    
    ####################################
    # Update Genetics 
    ####################################
    observeEvent(input$update_genetics, {
      temp <- template_data()
      temp$startGenes <- input$startGenes
      temp$loci <- input$loci
      temp$alleles <- input$alleles
      temp$muterate <- input$muterate
      temp$mutationtype <- input$mutationtype
      template_data(temp)
    })
    
    
    ####################################
    # Update Selection options
    ####################################
    
    
    #dinamically update startSelection choice
    output$startSelection <- renderUI({
      if(input$cdevolveansChoice != "N") {
        numericInput("startSelection", "Enter the time/generation at which selection should start:", value = 0, min = 0)
      }
    })
    
    #dinamically update implementSelection choice
    output$implementSelectionUI <- renderUI({
      req(input$implementSelectionChoice)
      
      inputs <- lapply(input$implementSelectionChoice, function(choice) {
        if (choice == "Out_age") {
          numericInput("Out_age_input", "Enter Start Selection Age for Out:", value = 0, min = 0)
        } else if (choice == "Back_age") {
          numericInput("Back_age_input", "Enter Start Selection Age for Back:", value = 0, min = 0)
        } else {
          # Return NULL for other choices, but we don't need to filter them here
          NULL
        }
      })
      
      
      if (any(c("Out_age", "Back_age") %in% input$implementSelectionChoice)) { # Only add if Out or Back are selected
        do.call(tagList, inputs)
      } else {
        return(NULL)
      }
    })
    
    # Add a warning if forbidden combos are selected
    output$warning <- renderUI({
      sel <- input$implementSelectionChoice
      
      if (all(c("Out", "Out_age") %in% sel)) {
        HTML("<b style='color:red;'>⚠️ Warning: You selected both 'Out' and 'Out_age' (not allowed together).</b>")
      } else if (all(c("Back", "Back_age") %in% sel)) {
        HTML("<b style='color:red;'>⚠️ Warning: You selected both 'Back' and 'Back_age' (not allowed together).</b>")
      } else {
        NULL
      }
    })
    
    # Add beta file selection UI output
    output$betaFileSelectionUI <- renderUI({
      if (input$betaFileSelectionChoice == "path") {
        fileInput("betaFile", "Choose Beta File",
                  accept = c(".csv", ".xlsx", ".xls")
        )
      }
    })
    
    observeEvent(input$update_selection, {
      temp <- template_data()
      
      # Check if selection is enabled first
      if (is.null(input$apply_selection) || input$apply_selection == "No") {
        # Set default values when selection is not applied
        temp$cdevolveans <- "N"
        temp$startSelection <- 0
        temp$implementSelection <- "Out"
        temp$betaFile_selection <- "N"
        template_data(temp)
        return()
      }
      
      # Guard: user enabled selection but didn't actually configure it
      if (is.null(input$cdevolveansChoice) || input$cdevolveansChoice == "N") {
        showModal(modalDialog(
          title = "Warning: No Selection Applied",
          HTML("You selected <strong>Apply Selection = Yes</strong> but did not choose a selection type.<br><br>
            No selection parameters have been saved. Please choose a selection model from the dropdown before updating."),
          easyClose = TRUE,
          footer = modalButton("OK")
        ))
        return()
      }
      
      # List of selection types that should use user-provided text
      use_text_input <- c("multi", "hindex_gauss", "hindex_para", "hindex_step", "hindex_linear", "F_linear", "F_logistic")
      
      if (input$cdevolveansChoice %in% use_text_input) {
        temp$cdevolveans <- input$multiSelectionText
        
      } else {
        temp$cdevolveans <- input$cdevolveansChoice
      }
      
      # Validation check for startSelection with proper null checks
      if (!is.null(input$startSelection) && !is.null(input$startGenes)) {
        if (as.numeric(input$startSelection) < as.numeric(input$startGenes)) {
          showModal(
            modalDialog(
              title = "Input Error",
              "'startSelection' should be larger or equal to 'startGenes'. Check the genetic tab to change the input value at which genetic exchange should start.",
              easyClose = TRUE,
              footer = NULL
            )
          )
        } else {
          temp$startSelection <- input$startSelection
        }
      }
      
      # Handle implementSelection choices
      if (!is.null(input$implementSelectionChoice) && length(input$implementSelectionChoice) > 0) {
        selection_values <- sapply(input$implementSelectionChoice, function(choice) {
          if (choice == "Out_age" && !is.null(input$Out_age_input)) {
            paste0("Out_", input$Out_age_input)
          } else if (choice == "Back_age" && !is.null(input$Back_age_input)) {
            paste0("Back_", input$Back_age_input)
          } else {
            choice
          }
        })
        temp$implementSelection <- paste(selection_values, collapse = ":")
      } else {
        temp$implementSelection <- ""
      }
      
      # Handle beta file selection
      if (!is.null(input$betaFileSelectionChoice)) {
        if (input$betaFileSelectionChoice == "path" && !is.null(input$betaFile)) {
          # Construct the full file path
          beta_path <- file.path(getwd(), input$betaFile$name)
          temp$betaFile_selection <- beta_path
        } else {
          temp$betaFile_selection <- "N"
        }
      }
      
      template_data(temp)
    })
    
    
    ####################################
    # Update Movement
    ####################################
    
    movement_help_text <- modalDialog(
      title = "Instructions for Movement",
      p("This feature allows you to control the probability of movement of individuals and effective distance distribution by transforming the cost distance matrix using different functions. All probabilities are scaled between 0 and 1. Some of the functions listed below are naturally between 0-1, while others use the minimum, maximum, and threshold values of the effective distance matrix to rescale. If a cost value exceeds the threshold provided by the user, then probability will be 0."),
      p("•	‘1’ = Linear: probability = (1 – (1/Threshold) * Effective Distance)"),
      p("•	‘2’ = Inverse Square: probability = (1 / (Effective Distance^2))"),
      p("•	‘3’ = Nearest Neighbor"),
      p("•	‘4’ = Random Mixing"),
      p("•	‘5’ = Negative Exponential: probability =  (A * 10^(-B * Effective Distance))"),
      p("•	‘6’ = Random Within Patch"),
      p("•	‘7’ = Gaussian function: probability = A * exp ( - (Cost Distance – B)^2 / (2 * C^2))"),
      p("•	‘8’ = Use the cost distance matrix"),
      p("•	‘9’ = Provide a probability matrix rather than a cost distance matrix in the cdmat column: no function is applied to values and the straight probability matrix is used."),
      p("•	‘10’ = Pareto function: For divide by zero issue, Cost distance = cost distance + b and probability =(a*(b^a))/(cost distance^(a+1))"),
      p("•	‘11’ = FIDIMO distribution function"),
      p("See CDmetaPOP user manual for more detailed information about each function"),
      easyClose = TRUE,
      footer = modalButton("Close")
    )
    # MATING MOVEMENT 
    output$mate_extra_ui <- renderUI({
      if (input$matemoveno %in% c(5, 7, 10, 11)) {
        inputs <- list(
          textInput(
            "mate_extra_A",
            HTML(
              "This is the A parameter used for function answers ‘5’, ‘7’, ‘10’, and ‘11’. If the CDClimate module was initiated with multiple years in the RunVars field ‘cdclimgentime’, then the same number of surfaces may be given here separated by a ‘|’ (<i><span style='color:#0072B2;'>matemoveparA</span></i>):"
            ),
            value = "0"
          ),
          textInput(
            "mate_extra_B",
            HTML(
              "This is the B parameter used for function answers ‘5’, ‘7’, ‘10’, and ‘11’. Specify same number of values here if CDClimate is initiated, e.g., 0.05|0|0 (<i><span style='color:#0072B2;'>matemoveparB</span></i>):"
            ),
            value = "0"
          )
        )
        
        if (input$matemoveno %in% c(7, 11)) {
          inputs <- c(
            inputs,
            textInput(
              "mate_extra_C",
              HTML(
                "This is the C parameter used for the function answer ‘7’ and ‘11’. Specify same number of values here if CDClimate is initiated, e.g., 0.05|0|0 (<i><span style='color:#0072B2;'>matemoveparC</span></i>):"
              ),
              value = "0"
            )
          )
        }
        
        tagList(inputs)
      } else {
        NULL  # Nothing to show if not needed
      }
    })
    
    observeEvent(input$update_mate, {
      temp <- template_data()
      temp$matemoveno <- input$matemoveno
      
      if (input$matemoveno %in% c(5, 7, 10, 11)) {
        temp$matemoveparA <- input$mate_extra_A   # store whole string
        temp$matemoveparB <- input$mate_extra_B   # store whole string
        if (input$matemoveno %in% c(7, 11)) {
          temp$matemoveparC <- input$mate_extra_C
        }
      }
      
      template_data(temp)
    })
    
    observeEvent(input$help_mate, { showModal(movement_help_text) })
    observeEvent(input$update_mate, {
      temp <- template_data()
      thresh_value <- input$matemovethresh
      temp$matemovethresh <- thresh_value
      template_data(temp)
    })
    
    # MIGRATE OUT
    output$migrateout_extra_ui <- renderUI({
      if (input$migrateoutno %in% c(5, 7, 10, 11)) {
        inputs <- list(
          textInput(
            "migrateout_extra_A",
            HTML(
              "This is the A parameter used for function answers ‘5’, ‘7’, ‘10’, and ‘11’. If the CDClimate module was initiated with multiple years in the RunVars field ‘cdclimgentime’, then the same number of surfaces may be given here separated by a ‘|’ (<i><span style='color:#0072B2;'>migratemoveOutparA</span></i>):"
            ),
            value = "0"
          ),
          textInput(
            "migrateout_extra_B",
            HTML(
              "This is the B parameter used for function answers ‘5’, ‘7’, ‘10’, and ‘11’. Specify same number of values here if CDClimate is initiated, e.g., 0.05|0|0 (<i><span style='color:#0072B2;'>migratemoveOutparB</span></i>):"
            ),
            value = "0"
          )
        )
        
        if (input$migrateoutno %in% c(7, 11)) {
          inputs <- c(
            inputs,
            textInput(
              "migrateout_extra_C",
              HTML(
                "This is the C parameter used for the function answer ‘7’ and ‘11’. Specify same number of values here if CDClimate is initiated, e.g., 0.05|0|0 (<i><span style='color:#0072B2;'>migratemoveOutparC</span></i>):"
              ),
              value = "0"
            )
          )
        }
        
        tagList(inputs)
      } else {
        NULL  # Nothing to show if not needed
      }
    })
    
    observeEvent(input$update_migrateout, {
      temp <- template_data()
      temp$migrateoutno <- input$migrateoutno
      if (input$migrateoutno %in% c(5, 7, 10, 11)) {
        temp$migrateoutparA <- input$migrateout_extra_A   # store whole string
        temp$migrateoutparB <- input$migrateout_extra_B   # store whole string
        if (input$migrateoutno %in% c(7, 11)) {
          temp$migrateoutparC <- input$migrateout_extra_C
        }
      }
      template_data(temp)
    })
    
    observeEvent(input$update_migrateout, {
      temp <- template_data()
      thresh_value <- input$migratemoveOutthresh
      temp$migratemoveOutthresh <- thresh_value
      template_data(temp)
    })
    
    # MIGRATE BACK
    output$migrateback_extra_ui <- renderUI({
      if (input$migratebackno %in% c(5, 7, 10, 11)) {
        inputs <- list(
          textInput(
            "migrateback_extra_A",
            HTML(
              "This is the A parameter used for function answers ‘5’, ‘7’, ‘10’, and ‘11’. If the CDClimate module was initiated with multiple years in the RunVars field ‘cdclimgentime’, then the same number of surfaces may be given here separated by a ‘|’ (<i><span style='color:#0072B2;'>migratemoveBackparA</span></i>):"
            ),
            value = "0"
          ),
          textInput(
            "migrateback_extra_B",
            HTML(
              "This is the B parameter used for function answers ‘5’, ‘7’, ‘10’, and ‘11’. Specify same number of values here if CDClimate is initiated, e.g., 0.05|0|0 (<i><span style='color:#0072B2;'>migratemoveBackparB</span></i>):"
            ),
            value = "0"
          )
        )
        
        if (input$migratebackno %in% c(7, 11)) {
          inputs <- c(
            inputs,
            textInput(
              "migrateback_extra_C",
              HTML(
                "This is the C parameter used for the function answer ‘7’ and ‘11’. Specify same number of values here if CDClimate is initiated, e.g., 0.05|0|0 (<i><span style='color:#0072B2;'>migratemoveBackparC</span></i>):"
              ),
              value = "0"
            )
          )
        }
        
        tagList(inputs)
      } else {
        NULL  # Nothing to show if not needed
      }
    })
    observeEvent(input$update_migrateback, {
      # Get current template data
      temp <- template_data()
      
      # Update migrate back parameters
      temp$migratebackno <- input$migratebackno
      temp$migratebackparA <- NA
      temp$migratebackparB <- NA
      temp$migratebackparC <- NA
      
      # Only set parameters if specific migrate back options are selected
      if (input$migratebackno %in% c(5, 7, 10, 11)) {
        temp$migratebackparA <- input$migrateback_extra_A
        temp$migratebackparB <- input$migrateback_extra_B
        if (input$migratebackno %in% c(7, 11)) {
          temp$migratebackparC <- input$migrateback_extra_C
        }
      }
      
      # Update HomeAttempt
      temp$HomeAttempt <- input$HomeAttempt
      
      template_data(temp)
    })
    
    observeEvent(input$update_migrateback, {
      temp <- template_data()
      thresh_value <- input$migratemoveBackthresh
      temp$migrateBackthresh <- thresh_value
      template_data(temp)
    })
    
    observeEvent(input$help_migrateback, { showModal(movement_help_text) })
    
    # STRAY
    output$stray_extra_ui <- renderUI({
      if (input$strayno %in% c(5, 7, 10, 11)) {
        inputs <- list(
          textInput(
            "stray_extra_A",
            HTML(
              "This is the A parameter used for function answers ‘5’, ‘7’, ‘10’, and ‘11’. If the CDClimate module was initiated with multiple years in the RunVars field ‘cdclimgentime’, then the same number of surfaces may be given here separated by a ‘|’ (<i><span style='color:#0072B2;'>StrayBackparA</span></i>):"
            ),
            value = "0"
          ),
          textInput(
            "stray_extra_B",
            HTML(
              "This is the B parameter used for function answers ‘5’, ‘7’, ‘10’, and ‘11’. Specify same number of values here if CDClimate is initiated, e.g., 0.05|0|0 (<i><span style='color:#0072B2;'>StrayBackparB</span></i>):"
            ),
            value = "0"
          )
        )
        if (input$strayno %in% c(7, 11)) {
          inputs <- c(
            inputs,
            textInput(
              "stray_extra_C",
              HTML(
                "This is the C parameter used for the function answer ‘7’ and ‘11’. Specify same number of values here if CDClimate is initiated, e.g., 0.05|0|0 (<i><span style='color:#0072B2;'>StrayBackparC</span></i>):"
              ),
              value = "0"
            )
          )
        }
        tagList(inputs)
      } else {
        NULL
      }
    })
    
    observeEvent(input$update_stray, {
      temp <- template_data()
      temp$strayno <- input$strayno
      temp$StrayBackparA <- NA
      temp$StrayBackparB <- NA
      temp$StrayBackparC <- NA
      if (input$strayno %in% c(5, 7, 10, 11)) {
        temp$StrayBackparA <- input$stray_extra_A
        temp$StrayBackparB <- input$stray_extra_B
        if (input$strayno %in% c(7, 11)) {
          temp$StrayBackparC <- input$stray_extra_C
        }
      }
      template_data(temp)
    })
    
    # output$StrayBackthreshinput <- renderUI({
    #   if (input$StrayBackthresh == "%max") {
    #     numericInput(
    #       "StrayBackthresh_pct",
    #       "Specify the % of max distance (1–100):",
    #       value = 50,
    #       min = 1,
    #       max = 100,
    #       step = 1
    #     )
    #   } else {
    #     NULL
    #   }
    # })
    # 
    # observeEvent(input$update_stray, {
    #   temp <- template_data()
    #   thresh_value <- input$StrayBackthresh
    #   if (thresh_value == "%max") {
    #     thresh_value <- paste0(input$StrayBackthresh_pct, "%max")
    #   }
    #   temp$StrayBackthresh <- thresh_value
    #   template_data(temp)
    # })
    
    observeEvent(input$update_stray, {
      temp <- template_data()
      thresh_value <- input$strayBackthresh
      temp$strayBackthresh <- thresh_value
      template_data(temp)
    })
    
    
    observeEvent(input$help_stray, { showModal(movement_help_text) })
    
    # DISPERSE
    
    output$disperse_extra_ui <- renderUI({
      if (input$disperseno %in% c(5, 7, 10, 11)) {
        inputs <- list(
          textInput(
            "disperse_extra_A",
            HTML(
              "This is the A parameter used for function answers ‘5’, ‘7’, ‘10’, and ‘11’. If the CDClimate module was initiated with multiple years in the RunVars field ‘cdclimgentime’, then the same number of surfaces may be given here separated by a ‘|’ (<i><span style='color:#0072B2;'>disperseLocalparA</span></i>):"
            ),
            value = "0"
          ),
          textInput(
            "disperse_extra_B",
            HTML(
              "This is the B parameter used for function answers ‘5’, ‘7’, ‘10’, and ‘11’. Specify same number of values here if CDClimate is initiated, e.g., 0.05|0|0 (<i><span style='color:#0072B2;'>disperseLocalparB</span></i>):"
            ),
            value = "0"
          )
        )
        if (input$disperseno %in% c(7, 11)) {
          inputs <- c(
            inputs,
            textInput(
              "disperse_extra_C",
              HTML(
                "This is the C parameter used for the function answer ‘7’ and ‘11’. Specify same number of values here if CDClimate is initiated, e.g., 0.05|0|0 (<i><span style='color:#0072B2;'>disperseLocalparC</span></i>):"
              ),
              value = "0"
            )
          )
        }
        tagList(inputs)
      } else {
        NULL
      }
    })
    
    output$disperseLocal_extra_ui <- renderUI({
      if (input$disperseLocalno %in% c(5, 7, 10, 11)) {
        inputs <- list(
          textInput(
            "disperseLocal_extra_A",
            HTML(
              "This is the A parameter used for function answers ‘5’, ‘7’, ‘10’, and ‘11’. If the CDClimate module was initiated with multiple years in the RunVars field ‘cdclimgentime’, then the same number of surfaces may be given here separated by a ‘|’ (<i><span style='color:#0072B2;'>disperseLocalparA</span></i>):"
            ),
            value = "0"
          ),
          textInput(
            "disperseLocal_extra_B",
            HTML(
              "This is the B parameter used for function answers ‘5’, ‘7’, ‘10’, and ‘11’. Specify same number of values here if CDClimate is initiated, e.g., 0.05|0|0 (<i><span style='color:#0072B2;'>disperseLocalparB</span></i>):"
            ),
            value = "0"
          )
        )
        if (input$disperseLocalno %in% c(7, 11)) {
          inputs <- c(
            inputs,
            textInput(
              "disperseLocal_extra_C",
              HTML(
                "This is the C parameter used for the function answer ‘7’ and ‘11’. Specify same number of values here if CDClimate is initiated, e.g., 0.05|0|0 (<i><span style='color:#0072B2;'>disperseLocalparC</span></i>):"
              ),
              value = "0"
            )
          )
        }
        tagList(inputs)
      } else {
        NULL
      }
    })
    
    observeEvent(input$update_disperse, {
      temp <- template_data()
      temp$disperseno <- input$disperseno
      temp$disperseLocalparA <- NA
      temp$disperseLocalparB <- NA
      temp$disperseLocalparC <- NA
      if (input$disperseno %in% c(5, 7, 10, 11)) {
        temp$disperseLocalparA <- input$disperse_extra_A
        temp$disperseLocalparB <- input$disperse_extra_B
        if (input$disperseno %in% c(7, 11)) {
          temp$disperseLocalparC <- input$disperse_extra_C
        }
      }
      template_data(temp)
    })
    
    observeEvent(input$update_disperseLocal, {
      temp <- template_data()
      temp$disperseLocalno <- input$disperseLocalno
      temp$disperseLocalparA <- NA
      temp$disperseLocalparB <- NA
      temp$disperseLocalparC <- NA
      if (input$disperseLocalno %in% c(5, 7, 10, 11)) {
        temp$disperseLocalparA <- input$disperseLocal_extra_A
        temp$disperseLocalparB <- input$disperseLocal_extra_B
        if (input$disperseLocalno %in% c(7, 11)) {
          temp$disperseLocalparC <- input$disperseLocal_extra_C
        }
      }
      template_data(temp)
    })
    
    observeEvent(input$update_disperseLocal, {
      temp <- template_data()
      thresh_value <- input$disperseLocalthresh
      temp$disperseLocalthresh <- thresh_value
      template_data(temp)
    })
    
    observeEvent(input$help_disperse, { showModal(movement_help_text) })
    
    ####################################
    # Update Behavioral Plasticity
    ####################################
    observeEvent(input$update_plasticity, {
      temp <- template_data()
      if (input$apply_behavioral_plasticity == "No") {
        temp$plasticgeneans <- "N"
        temp$plasticSignalResponse <- 0
        temp$plasticBehavioralResponse <- 0
      } else {
        # Combine the 3 values
        combined <- paste(
          input$plastic_signal_type,
          input$plastic_allele_response,
          input$plastic_response_reduction,
          sep = "_"
        )
        temp$plasticgeneans <- combined
        temp$plasticSignalResponse <- input$plastic_signal_threshold
        temp$plasticBehavioralResponse <- input$plastic_behavior_response
        temp$startPlasticgene <- input$startPlasticgene
        temp$implementPlasticgene <- input$implementPlasticgene
      }
      template_data(temp)
    })
    
    
    ####################################
    # Update Reproduction
    ####################################
    observeEvent(input$update_reproduction, {
      temp <- template_data()
      temp$sex_chromo <- input$sex_chromo
      temp$sexans <- input$sexans
      temp$selfans <- input$selfans
      temp$Freplace <- input$Freplace
      temp$Mreplace <- input$Mreplace
      temp$AssortativeMate_Model <- input$AssortativeMate_Model
      temp$AssortativeMate_Factor <- input$AssortativeMate_Factor
      temp$mature_default <- if (input$mature_default %in% c("age", "size")) {
        paste(input$mature_default, input$mature_value, sep = "")
      } else {
        input$mature_default # If "N", just store "N"
      }
      temp$mature_eqn_slope <- input$mature_eqn_slope
      temp$mature_eqn_int <- input$mature_eqn_int
      template_data(temp)
    })
    
    # This gives the flexibility to handle both categorical and numerical inputs for the selfans category appropriately
    output$selfans_input <- renderUI({
      if (input$sexans == "H") {
        numericInput(
          "selfans",
          HTML(
            "Indicate the probability (0–1) that hermaphroditic individuals will self-fertilize (<i><span style='color:#0072B2;'>selfans</span></i>):"
          ),
          value = 0.5,
          min = 0,
          max = 1,
          step = 0.01
        )
      } else {
        selectInput(
          "selfans",
          HTML(
            "Select whether individuals can self-fertilize (Y = Yes, N = No) (<i><span style='color:#0072B2;'>selfans</span></i>):"
          ),
          choices = c("Y", "N"),
          selected = "N"
        )
      }
    })
    
    # This gives different choice option according the assortative mating model chosen
    output$AssortativeMate_Factor <- renderUI({
      if (input$AssortativeMate_Model %in% c("3a", "3b", 4, 5)) {
        numericInput("AssortativeMate_Factor",
                     "Indicate the extent of assortative mating (1 = random mating, higher values increase self-preference):",
                     value = 1, min = 1, max = 1000000
        )
      }
    })
    
    # Dinamically asks for a number if age or size are selected at mature_default
    output$mature_input <- renderUI({
      if (input$mature_default %in% c("age", "size")) {
        numericInput("mature_value",
                     paste0("Indicate the ", input$mature_default, " at which individuals mature:"),
                     value = 1, min = 1
        )
      } else {
        return(NULL)
      }
    })
    
    # Dinamically asks for number of offspring  if age is selected at mature_default option
    output$offno <- renderUI({
      if (input$mature_default == "age") {
        numericInput(
          "offno",
          label = HTML('Indicate the number of offspring to draw (<i><span style="color:#0072B2;">offno</span></i>):'),
          value = 2,
          min = 1,
          max = 4
        )
      } else {
        return(NULL)
      }
    })
    
    
    ###################################################
    # SIDEPANEL UPDATE
    ###################################################
    
    # Update Patchvars text
    observeEvent(input$update_patchvars, {
      req(input$patchvars_file)
      
      # Update only the 'xyfilename' column with the subdir name
      temp <- template_data()
      temp$xyfilename <- trimws(input$patchvars_file)
      template_data(temp)
    })
    
    # Update CDMAT text
    observeEvent(input$update_cdmat, {
      req(input$mate_cdmat_file)
      # Update the cdmat column with the dir and subdir name
      temp <- template_data()
      temp$mate_cdmat <- trimws(input$mate_cdmat_file)
      template_data(temp)
    })
    
    # Update MigrationOut CDMat from entered text
    observeEvent(input$update_migrateout_cdmat, {
      req(input$migrateout_cdmat_file)
      
      # Get the original filename
      migrate_cdmats_name <- input$migrateout_cdmat_file
      
      # Update the 'migrate_cdmat' column with the subdir name
      temp <- template_data()
      temp$migrateout_cdmat <- trimws(migrate_cdmats_name)
      template_data(temp)
    })
    
    # Update migrateback_cdmat from Uploaded File
    
    observeEvent(input$update_migrateback_cdmat, {
      req(input$migrateback_cdmat_file)
      
      # Get the original filename
      migrateback_cdmats_name <- input$migrateback_cdmat_file
      
      # Update the 'migratemoveback_cdmat' column 
      temp <- template_data()
      temp$migrateback_cdmat <- trimws(migrateback_cdmats_name)
      template_data(temp)
    })
    
    # Update Stray CDMat from text
    
    observeEvent(input$update_stray_cdmat, {
      req(input$stray_cdmat_file)
      
      # Get the original filename
      stray_cdmats_name <- input$stray_cdmat_file
      
      # Update  the 'stray_cdmat' column 
      temp <- template_data()
      temp$stray_cdmat <- stray_cdmats_name
      template_data(temp)
    })
    
    # Updated Dispersal CDMat from text
    observeEvent(input$update_dispersal_cdmat, {
      req(input$dispersal_cdmat_file)
      
      # Get the original filename
      dispersal_cdmats_name <- input$dispersal_cdmat_file
      
      # Update  the 'dispersal_cdmat' column 
      temp <- template_data()
      temp$dispersal_cdmat <- dispersal_cdmats_name
      template_data(temp)
    })
    
    ###########################################################   
    # Update Correlation matrix from text or "N" selection
    ##########################################################
    observeEvent(input$update_corrmatrix, {
      temp <- template_data()
      
      if (input$cor_matrix_source == "N") {
        temp$correlation_matrix <- "N"
      } else if (!is.null(input$Patch_r)) {
        # Use uploaded filename
        corr_name <- trimws(input$Patch_r)
        #corr_path <- file.path(getwd(), corr_name)
        temp$correlation_matrix <- corr_name
      }
      
      template_data(temp)
    })
    ###################################################### 
    # Update Mortality matrix from text or "N" selection
    ##########################################################
    observeEvent(input$update_subpopmort, {
      temp <- template_data()
      
      if (input$subpopmort_source == "N") {
        temp$subpopmort_file <- "N"
      } else if (!is.null(input$Subpopmort_file)) {
        #mort_name <- input$Subpopmort_file$name
        #mort_path <- file.path(getwd(), mort_name)
        temp$subpopmort_file <- trimws(input$Subpopmort_file)
      }
      
      template_data(temp)
    })
    
    ###################################################### 
    # Preview Template
    ##########################################################
    
    output$preview_template <- renderTable({
      template_data()
    })
    
    # Download updated template
    output$download_popvars <- downloadHandler(
      filename = function() {
        paste0(output_file) # Ensure correct file naming
      },
      content = function(file) {
        write.csv(template_data(), file, row.names = FALSE)
      }
    )
  }
  # Run the application
  shinyApp(ui = ui, server = server)
}

