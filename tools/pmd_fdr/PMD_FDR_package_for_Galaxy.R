###############################################################################
# PMD_FDR_package_for_Galaxy.R                                                #
#                                                                             #
# Project 021 - PMD-FDR for Galaxy-P                                          #
#                                                                             #
# Description: Computes iFDR and gFDR on PSMs as a script designed for Galaxy #
#              Note that plotting code has been left in that is not used      #
#              in this file; this is the code I used to create figures for    #
#              publication. I left it in for potential development of views.  #
#                                                                             #
#              This file was created by concatenating the following files:    #
#                                                                             #
#                   A - 005 - Parser - ArgParser.R                            #
#                   B - 019 - PMD-FDR - functions.R                           #
#                   C - 021 - PMD-FDR Wrapper - functions.R                   #
#                   D - 021 - PMD-FDR Main.R                                  #
#                                                                             #
# Required packages: argparser                                                #
#                    stringr                                                  #
#                    RUnit                                                    #
#                                                                             #
# Release date: 2019-10-05                                                    #
#      Version: 1.4                                                           #
#                                                                             #
###############################################################################
# Package currently supports the following parameters:
#
# --psm_report            full name and path to the PSM report
# --psm_report_1_percent  full name and path to the PSM report for 1% FDR
# --output_i_fdr          full name and path to the i-FDR output file 
# --output_g_fdr          full name and path to the g-FDR output file 
# --output_densities      full name and path to the densities output file 
#
###############################################################################
# A - 005 - Parser - ArgParser.R                                              #
#                                                                             #
# Description: Wrapper for argparser package, using RefClass                  #
#                                                                             #
###############################################################################

#install.packages("argparser")
library(argparser)

# Class definition

ArgParser <- setRefClass("ArgParser",
                         fields = c("parser"))
ArgParser$methods(
  initialize = function(...){
    parser <<- arg_parser(...)  
  },
  local_add_argument = function(...){
    parser <<- add_argument(parser, ...)
  },
  parse_arguments = function(...){
    result = parse_args(parser, ...)
    return(result) 
  }
)

###############################################################################
# B - 019 - PMD-FDR - functions.R                                             #
#                                                                             #
# Primary work-horse for PMD-FDR                                              #
#                                                                             #
###############################################################################
###############################################################################
####### Load libraries etc.
###############################################################################
library(stringr)
library(RUnit)

#############################################################
####### Global values (should be parameters to module but aren't yet)
#############################################################

MIN_GOOD_PEPTIDE_LENGTH          <- 11
MIN_ACCEPTABLE_POINTS_IN_DENSITY <- 10

#############################################################
####### General purpose functions
#############################################################
# Creates a more useful error report when file is not reasonable
safe_file_exists <- function(file_path){ # Still not particularly useful in cases where it is a valid directory
  tryCatch(
    return(file_test(op = "-f", x=file_path)),
    error=function(e) {simpleError(sprintf("file path is not valid: '%s'", file_path))}
  )
}
# My standard way of loading data into data.frames
load_standard_df <- function(file_path=NULL){
  clean_field_names = function(field_names){
    result <- field_names
    idx_blank <- which(result == "")
    result[idx_blank] <- sprintf("<Field %d>", idx_blank)
    return(result)
  }
  if (safe_file_exists(file_path)){
    field_names <- read_field_names(file_path, sep = "\t")
    field_names <- clean_field_names(field_names)
    
    if (length(field_names) == 0){
      return(data.frame())
    }
    data <- read.table(file = file_path, header = TRUE, sep = "\t", stringsAsFactors = FALSE, blank.lines.skip = TRUE)#, check.names = FALSE)
    colnames(data) = field_names
  } else {
    stop(sprintf("File path does not exist: '%s'", file_path))
  }
  return(data)
}
save_standard_df <- function(x=NULL, file_path=NULL){
  if (file_path != ""){
    write.table(x = x, file = file_path, quote = FALSE, sep = "\t", row.names = FALSE, col.names = TRUE)
  }
}
rename_column <- function(df=NULL, name_before=NULL, name_after=NULL, suppressWarnings=FALSE){
  if (is.null(df)){
    stop("Dataframe (df) does not exist - unable to rename column")
  }
  if (name_before %in% colnames(df)){
    df[,name_after]  <- df[,name_before]
    df[,name_before] <- NULL
  } else if (!suppressWarnings){
    warning(sprintf("'%s' is not a field in the data frame and so has not been renamed", name_before))
  }
  return(df)
}
rename_columns <- function(df=NULL, names_before=NULL, names_after=NULL){
  for (i in safe_iterator(length(names_before))){
    df <- rename_column(df, names_before[i], names_after[i])
  }
  return(df)
}
round_to_tolerance    <- function(x=NULL, tolerance=NULL, ...){ 
  return(function_to_tolerance(x=x, tolerance=tolerance, FUN=round, ...)) 
}
function_to_tolerance <- function(x=NULL, tolerance=NULL, FUN=NULL, ...){
  return(FUN(x/tolerance, ...) * tolerance) 
}
safe_median <- function(x) median(x, na.rm=TRUE)
normalize_density <- function(d){
  # Normalizes y-values in density function
  # so that the integral under the curve is 1
  # (uses rectangles to approximate area)
  delta_x               <- diff(range(d$x)) / length(d$x)
  unnormalized_integral <- delta_x * sum(d$y)
  new_d   <- d
  new_d$y <- with(new_d, y )
  
  return(new_d)
}
if_null <- function(cond=NULL, null_result=NULL, not_null_result=NULL){
  return(switch(1+is.null(cond), 
                not_null_result, 
                null_result))
}
rainbow_with_fixed_intensity <- function(n=NULL, goal_intensity_0_1=NULL, alpha=NULL){
  goal_intensity <- 255*goal_intensity_0_1
  hex_colors <- rainbow(n)
  rgb_colors <- col2rgb(hex_colors)
  df_colors <- data.frame(t(rgb_colors))
  df_colors$intensity <- with(df_colors, 0.2989*red + 0.5870*green + 0.1140*blue)
  
  df_colors$white_black <- with(df_colors, ifelse(intensity < goal_intensity, 255, 0))
  df_colors$mix_level   <- with(df_colors, (white_black - goal_intensity) / (white_black - intensity  ) )
  df_colors$new_red     <- with(df_colors, mix_level*red   + (1-mix_level)*white_black)
  df_colors$new_green   <- with(df_colors, mix_level*green + (1-mix_level)*white_black)
  df_colors$new_blue    <- with(df_colors, mix_level*blue  + (1-mix_level)*white_black)
  names_pref_new <- c("new_red", "new_green", "new_blue")
  names_no_pref  <- c("red", "green", "blue")
  df_colors <- df_colors[,names_pref_new]
  df_colors <- rename_columns(df_colors, names_before = names_pref_new, names_after = names_no_pref)
  rgb_colors <-as.matrix(df_colors/255 )
  
  return(rgb(rgb_colors, alpha=alpha))
}
safe_iterator <- function(n_steps = NULL){
  if (n_steps < 1){
    result = numeric(0)
  } else {
    result = 1:n_steps
  }
  return(result)
}
col2hex <- function(cols=NULL, col_alpha=255){
  if (all(col_alpha<=1)){
    col_alpha <- round(col_alpha*255)
  }
  col_matrix <- t(col2rgb(cols))
  results <- rgb(col_matrix, alpha=col_alpha, maxColorValue = 255)
  return(results)
}
credible_interval <- function(x=NULL, N=NULL, precision=0.001, alpha=0.05){
  # Approximates "highest posterior density interval"
  # Uses exact binomial but with a finite list of potential values (1/precision)
  
  p <- seq(from=0, to=1, by=precision)
  d <- dbinom(x = x, size = N, prob = p)
  d <- d / sum(d)
  df <- data.frame(p=p, d=d)
  df <- df[order(-df$d),]
  df$cumsum <- cumsum(df$d)
  max_idx <- sum(df$cumsum < (1-alpha)) + 1
  max_idx <- min(max_idx, nrow(df))
  
  lower <- min(df$p[1:max_idx])
  upper <- max(df$p[1:max_idx])
  
  return(c(lower,upper))
}
verified_element_of_list <- function(parent_list=NULL, element_name=NULL, object_name=NULL){
  if (is.null(parent_list[[element_name]])){
    if (is.null(object_name)){
      object_name = "the list"
    }
    stop(sprintf("Element '%s' does not yet exist in %s", element_name, object_name))
  }
  return(parent_list[[element_name]])
}
read_field_names = function(file_path=NULL, sep = "\t"){
  con = file(file_path,"r")
  fields = readLines(con, n=1)
  close(con)
  
  if (length(fields) == 0){
    return(c())
  }
  fields = strsplit(x = fields, split = sep)[[1]]
  return(fields)
}
check_field_name = function(input_df = NULL, name_of_input_df=NULL, field_name=NULL){
  test_succeeded <- field_name %in% colnames(input_df)
  current_columns <- paste0(colnames(input_df), collapse=", ")
  checkTrue(test_succeeded,
            msg = sprintf("Expected fieldname '%s' in %s (but did not find it among %s)", 
                          field_name, name_of_input_df, current_columns))
}

#############################################################
####### Classes for Data
#############################################################

###############################################################################
#            Class: Data_Object
###############################################################################
Data_Object <- setRefClass("Data_Object", 
                           fields =list(m_is_dirty = "logical",
                                        parents    = "list",
                                        children   = "list", 
                                        class_name = "character"))
Data_Object$methods(
  initialize = function(){
    m_is_dirty <<- TRUE
    class_name <<- "Data_Object <abstract class - class_name needs to be set in subclass>"
  },
  load_data = function(){
    #print(sprintf("Calling %s$load_data()", class_name)) # Useful for debugging
    ensure_parents()
    verify()
    m_load_data()
    set_dirty(new_value = FALSE)
  },
  ensure = function(){
    if (m_is_dirty){
      load_data()
    }
  },
  set_dirty = function(new_value){
    if (new_value != m_is_dirty){
      m_is_dirty <<- new_value
      set_children_dirty()
    }
  },
  verify = function(){
    stop(sprintf("verify() is an abstract method - define it in %s before calling load_data()", class_name))
  },
  m_load_data = function(){
    stop(sprintf("m_load_data() is an abstract method - define it in %s before calling load_data()", class_name))
  },
  append_parent = function(parent=NULL){
    parents <<- append(parents, parent)
  },
  append_child = function(child=NULL){
    children <<- append(children, child)
  },
  ensure_parents = function(){
    for (parent in parents){
      # print(sprintf("Calling %s$ensure()", parent$class_name)) # Useful for debugging
      parent$ensure()
    }
  },
  set_children_dirty = function(){
    for (child in children){
      child$set_dirty(TRUE)
    }
  }
)
###############################################################################
#            Class: Data_Object_Info
###############################################################################
Data_Object_Info <- setRefClass("Data_Object_Info", 
                                contains = "Data_Object",
                                fields =list(
                                  data_file_name_1_percent_FDR = "character",
                                  data_file_name  = "character",
                                  data_path_name  = "character",
                                  experiment_name = "character",
                                  designation     = "character",
                                  
                                  input_file_type = "character"
                                  
                                  #score_field_name = "character"
                                  #collection_name="character",
                                  #dir_results="character",
                                  #dir_dataset="character",
                                  #dataset_designation="character",
                                  #file_name_dataset="character",
                                  #file_name_dataset_1_percent="character",
                                  #experiment_name="character"
                                ) )
Data_Object_Info$methods(
  initialize = function(){
    callSuper()
    class_name <<- "Data_Object_Info - <Abstract class - class_name needs to be set in subclass>"
  },    
  verify = function(){
    checkFieldExists = function(field_name=NULL){
      field_value <- .self[[field_name]]
      checkTrue(length(field_value) > 0,
                sprintf("Field %s$%s has not been set (and should have been)", class_name, field_name))
      checkTrue(length(field_value) == 1,
                sprintf("Field %s$%s has been set to multiple values (and should be a single value)", class_name, field_name))
      checkTrue(field_value != "",
                sprintf("Field %s$%s has been set to an empty string (and should not have been)", class_name, field_name))
    }
    checkFieldExists("data_file_name")
    checkFieldExists("data_path_name")
    checkFieldExists("experiment_name")
    checkFieldExists("designation")
    checkFieldExists("input_file_type")
    #checkFieldExists("score_field_name")
  },
  m_load_data = function(){
    # Nothing to do - this is really a data class
  },
  file_path = function(){
    result <- file.path(data_path_name, data_file_name)
    if (length(result) == 0){
      stop("Unable to validate file path - one or both of path name and file name are missing")
    }
    return(result)
  },
  file_path_1_percent_FDR = function(){
    local_file_name <- get_data_file_name_1_percent_FDR()
    if (length(local_file_name) == 0){
      result <- ""
    } else {
      result <- file.path(data_path_name, local_file_name)
    }
    
    # Continue even if file name is missing - not all analyses have a 1 percent FDR file; this is managed downstream
    
    # if (length(result) == 0){
    #   stop("Unable to validate file path - one or both of path name and file name (of 1 percent FDR file) are missing")
    # }
    return(result)
  },
  get_data_file_name_1_percent_FDR = function(){
    return(data_file_name_1_percent_FDR)
  },
  collection_name = function(){
    result <- sprintf("%s_%s", experiment_name, designation)
    return(result)
  }
)
###############################################################################
#            Class: Data_Object_Info_737_two_step
###############################################################################
Data_Object_Info_737_two_step <- setRefClass("Data_Object_Info_737_two_step", 
                                             contains = "Data_Object_Info",
                                             fields =list())
Data_Object_Info_737_two_step$methods(
  initialize = function(){
    callSuper()
    class_name                   <<- "Data_Object_Info_737_two_step"
    #score_field_name             <<- "Confidence [%]"
    data_file_name_1_percent_FDR <<- "737_NS_Peptide_Shaker_PSM_Report_Multi_Stage_Two_Step.tabular"
    data_file_name               <<- "737_NS_Peptide_Shaker_Extended_PSM_Report_Multi_Stage_Two_Step.tabular.tabular"
    data_path_name               <<- file.path(".", "Data")
    experiment_name              <<- "Oral_737_NS"
    designation                  <<- "two_step"
    
    input_file_type              <<- "PSM_Report"
    
    #data_collection_oral_737_NS_combined$file_name_dataset_1_percent = "737_NS_Peptide_Shaker_PSM_Report_CombinedDB.tabular"
    #data_collection_oral_737_NS_two_step$file_name_dataset_1_percent = "737_NS_Peptide_Shaker_PSM_Report_Multi_Stage_Two_Step.tabular"
    
  }
)

###############################################################################
#            Class: Data_Object_Info_737_combined
###############################################################################
Data_Object_Info_737_combined <- setRefClass("Data_Object_Info_737_combined", 
                                             contains = "Data_Object_Info",
                                             fields =list())
Data_Object_Info_737_combined$methods(
  initialize = function(){
    callSuper()
    class_name                   <<- "Data_Object_Info_737_combined"
    #score_field_name             <<- "Confidence [%]"
    data_file_name_1_percent_FDR <<- "737_NS_Peptide_Shaker_PSM_Report_CombinedDB.tabular"
    data_file_name               <<- "737_NS_Peptide_Shaker_Extended_PSM_Report_CombinedDB.tabular"
    data_path_name               <<- file.path(".", "Data")
    experiment_name              <<- "Oral_737_NS"
    designation                  <<- "two_step"
    
    input_file_type              <<- "PSM_Report"
    
    #data_collection_oral_737_NS_combined$file_name_dataset_1_percent = "737_NS_Peptide_Shaker_PSM_Report_CombinedDB.tabular"
    #data_collection_oral_737_NS_two_step$file_name_dataset_1_percent = "737_NS_Peptide_Shaker_PSM_Report_Multi_Stage_Two_Step.tabular"
    
  }
)

###############################################################################
#            Class: Data_Object_Pyrococcus_tr
###############################################################################
Data_Object_Pyrococcus_tr <- setRefClass("Data_Object_Pyrococcus_tr", 
                                         contains = "Data_Object_Info",
                                         fields =list())
Data_Object_Pyrococcus_tr$methods(
  initialize = function(){
    callSuper()
    class_name                   <<- "Data_Object_Pyrococcus_tr"
    #score_field_name             <<- "Confidence [%]"
    data_file_name_1_percent_FDR <<- ""
    data_file_name               <<- "Pfu_traditional_Extended_PSM_Report.tabular"
    data_path_name               <<- file.path(".", "Data")
    experiment_name              <<- "Pyrococcus"
    designation                  <<- "tr"
    
    input_file_type              <<- "PSM_Report"
    
  }
)
###############################################################################
#            Class: Data_Object_Mouse_Mutations
###############################################################################
Data_Object_Mouse_Mutations <- setRefClass("Data_Object_Mouse_Mutations", 
                                           contains = "Data_Object_Info",
                                           fields =list())
Data_Object_Mouse_Mutations$methods(
  initialize = function(){
    callSuper()
    class_name                   <<- "Data_Object_Mouse_Mutations"
    #score_field_name             <<- "Confidence [%]"
    data_file_name_1_percent_FDR <<- ""
    data_file_name               <<- "Combined_DB_Mouse_5PTM.tabular"
    data_path_name               <<- file.path(".", "Data")
    experiment_name              <<- "Mouse Mutations"
    designation                  <<- "combined_05"
    
    input_file_type              <<- "PSM_Report"
    
  }
)
###############################################################################
#            Class: Data_Object_Raw_Data
###############################################################################
Data_Object_Raw_Data <- setRefClass("Data_Object_Raw_Data", 
                                    contains = "Data_Object",
                                    fields =list(df = "data.frame"))
Data_Object_Raw_Data$methods(
  initialize = function(){
    callSuper()
    class_name <<- "Data_Object_Raw_Data"
  },
  verify = function(){
    # Check that file exists before using it
    file_path <- get_info()$file_path()
    if (! safe_file_exists(file_path)){
      stop(sprintf("Raw data file does not exist (%s)", file_path))
    }
    # BUGBUG: Needs to also check the following:
    #         - file is tab-delimited
    #         - first row is a list of column names
  },
  set_info = function(info){
    parents[["info"]] <<- info
  },
  get_info = function(){
    return(verified_element_of_list(parents, "info", "Data_Object_Raw_Data$parents"))
  },
  m_load_data = function(){
    info <- get_info()
    df <<- load_standard_df(info$file_path())
  }
)
###############################################################################
#            Class: Data_Object_Raw_1_Percent
###############################################################################
Data_Object_Raw_1_Percent <- setRefClass("Data_Object_Raw_1_Percent", 
                                         contains = "Data_Object",
                                         fields =list(df = "data.frame"))
Data_Object_Raw_1_Percent$methods(
  initialize = function(){
    callSuper()
    class_name <<- "Data_Object_Raw_1_Percent"
  },
  set_info = function(info){
    parents[["info"]] <<- info
  },
  verify = function(){
    # Do nothing - a missing file name is acceptable for this module and is dealt with in load()
  },
  get_info = function(){
    return(verified_element_of_list(parents, "info", "Data_Object_Raw_1_Percent$parents"))
  },
  m_load_data = function(){
    
    info <- get_info()
    file_path <- info$file_path_1_percent_FDR()
    if (exists()){
      df <<- load_standard_df(info$file_path_1_percent_FDR())
    } # Note that failing to load is a valid state for this file, leading to not is_dirty. BUGBUG: this could lead to problems if a good file appears later
  },
  exists = function(){
    
    info <- get_info()
    local_file_name <- info$get_data_file_name_1_percent_FDR() # Check file name not file path
    
    if (length(local_file_name) == 0 ){ # variable not set
      result = FALSE
    } else if (local_file_name == ""){  # variable set to empty string
      result = FALSE
    } else {
      result = safe_file_exists(info$file_path_1_percent_FDR())
    }
    
    return(result)
  }
)
###############################################################################
#            Class: Data_Converter
###############################################################################
Data_Converter <- setRefClass("Data_Converter", 
                              fields =list(class_name = "character",
                                           file_type  = "character"
                              ) )
Data_Converter$methods(
  initialize = function(){
    class_name <<- "Data_Converter <abstract class - class_name needs to be set in subclass>"
    file_type  <<- "file_type has not been set before being used <needs to be set in initialize() of subclass>"
  },
  check_raw_fields = function(info=NULL, raw_data=NULL){
    stop(sprintf("check_raw_fields() is an abstract method - define it in %s before calling Data_Object_Data_Converter$load_data()", class_name))
  },
  convert_data = function(){
    stop(sprintf("convert_data() is an abstract method - define it in %s before calling Data_Object_Data_Converter$load_data()", class_name))
  }
)
###############################################################################
#            Class: Data_Converter_PMD_FDR_input_file
###############################################################################
Data_Converter_PMD_FDR_input_file <- setRefClass("Data_Converter_PMD_FDR_input_file", 
                                                 contains = "Data_Converter",
                                                 fields =list(
                                                   
                                                 ) )
Data_Converter_PMD_FDR_input_file$methods(
  initialize = function(){
    callSuper()
    
    class_name <<- "Data_Converter_PMD_FDR_input_file"
    file_type  <<- "PMD_FDR_file_type"
  },
  check_raw_fields = function(info=NULL, raw_data=NULL){
    data_original <- raw_data$df
    check_field_name(data_original, "raw_data", "PMD_FDR_input_score")
    check_field_name(data_original, "raw_data", "PMD_FDR_pmd")
    check_field_name(data_original, "raw_data", "PMD_FDR_spectrum_file")
    check_field_name(data_original, "raw_data", "PMD_FDR_proteins")
    check_field_name(data_original, "raw_data", "PMD_FDR_spectrum_title")
    check_field_name(data_original, "raw_data", "PMD_FDR_sequence")
    check_field_name(data_original, "raw_data", "PMD_FDR_decoy")
  },
  convert_data = function(info=NULL, raw_data=NULL){
    data_new <- raw_data$df
    
    return(data_new) # Pass through - everything should be in order
  }
)
###############################################################################
#            Class: Data_Converter_PSM_Report
###############################################################################
Data_Converter_PSM_Report <- setRefClass("Data_Converter_PSM_Report", 
                                         contains = "Data_Converter",
                                         fields =list(
                                           
                                         ) )
Data_Converter_PSM_Report$methods(
  initialize = function(){
    callSuper()
    
    class_name <<- "Data_Converter_PSM_Report"
    file_type  <<- "PSM_Report"
  },
  check_raw_fields = function(info=NULL, raw_data=NULL){
    data_original <- raw_data$df
    check_field_name(data_original, "raw_data", "Confidence [%]") 
    check_field_name(data_original, "raw_data", "Precursor m/z Error [ppm]")
    check_field_name(data_original, "raw_data", "Spectrum File")
    check_field_name(data_original, "raw_data", "Protein(s)")
    check_field_name(data_original, "raw_data", "Spectrum Title")
    check_field_name(data_original, "raw_data", "Decoy")
    check_field_name(data_original, "raw_data", "Sequence")
    
  },
  convert_data = function(info=NULL, raw_data=NULL){
    data_new <- raw_data$df
    
    data_new$PMD_FDR_input_score    <- data_new[, "Confidence [%]"           ]
    data_new$PMD_FDR_pmd            <- data_new[, "Precursor m/z Error [ppm]"]
    data_new$PMD_FDR_spectrum_file  <- data_new[, "Spectrum File"            ]
    data_new$PMD_FDR_proteins       <- data_new[, "Protein(s)"               ]
    data_new$PMD_FDR_spectrum_title <- data_new[, "Spectrum Title"           ]
    data_new$PMD_FDR_sequence       <- data_new[, "Sequence"                 ]
    data_new$PMD_FDR_decoy          <- data_new[, "Decoy"                    ]
    
    return(data_new)
  }
)
###############################################################################
#            Class: Data_Converter_MaxQuant_Evidence
###############################################################################
Data_Converter_MaxQuant_Evidence <- setRefClass("Data_Converter_MaxQuant_Evidence", 
                                                contains = "Data_Converter",
                                                fields =list(
                                                  
                                                ) )
Data_Converter_MaxQuant_Evidence$methods(
  initialize = function(){
    callSuper()
    
    class_name <<- "Data_Converter_MaxQuant_Evidence"
    file_type  <<- "MaxQuant_Evidence"
  },
  check_raw_fields = function(info=NULL, raw_data=NULL){
    data_original <- raw_data$df
    
    check_field_name(data_original, "raw_data", "PEP")
    check_field_name(data_original, "raw_data", "Mass error [ppm]")
    check_field_name(data_original, "raw_data", "Proteins")
    check_field_name(data_original, "raw_data", "Retention time")
    check_field_name(data_original, "raw_data", "Sequence")
    check_field_name(data_original, "raw_data", "Reverse")
  },
  convert_data = function(info=NULL, raw_data=NULL){
    data_new <- raw_data$df
    
    data_new$PMD_FDR_input_score    <- 100 * (1 - data_new[, "PEP"             ])
    data_new$PMD_FDR_pmd            <-            data_new[, "Mass error [ppm]"]
    data_new$PMD_FDR_spectrum_file  <-            "<place_holder - assumes a single spectra file>"
    data_new$PMD_FDR_proteins       <-            data_new[, "Proteins"        ]
    data_new$PMD_FDR_spectrum_title <-            data_new[, "Retention time"  ] # Used for ordering peptides - not important in MaxQuant since PMD has already been normalized effectively
    data_new$PMD_FDR_sequence       <-            data_new[, "Sequence"        ]
    data_new$PMD_FDR_decoy          <- ifelse(    data_new[, "Reverse"         ] == "+", 1, 0)
    
    return(data_new)
  }
)

###############################################################################
#            Class: Data_Object_Data_Converter
###############################################################################
Data_Object_Data_Converter <- setRefClass("Data_Object_Data_Converter", 
                                          contains = "Data_Object",
                                          fields =list(df             = "data.frame",
                                                       data_converter = "Data_Converter"))
Data_Object_Data_Converter$methods(
  initialize = function(){
    callSuper()
    class_name <<- "Data_Object_Data_Converter"
  },
  currently_supported_file_types = function(){
    return(c("PSM_Report", "PMD_FDR_input_file"))
  },
  verify = function(){
    info     <- get_info()
    raw_data <- get_raw_data()
    file_type <- get_info()$input_file_type
    
    set_file_type(file_type)
    data_converter$check_raw_fields(info=info, raw_data=raw_data)
    
  },
  m_load_data = function(){
    
    info      <- get_info()
    raw_data  <- get_raw_data()
    file_type <- get_info()$input_file_type
    
    df <<- data_converter$convert_data(info=info, raw_data=raw_data)
    
  },
  set_file_type = function(file_type = NULL){
    if        (file_type == "PSM_Report"        ){
      data_converter <<- Data_Converter_PSM_Report        $new()
    } else if (file_type == "PMD_FDR_input_file"){
      data_converter <<- Data_Converter_PMD_FDR_input_file$new()
    } else if (file_type == "MaxQuant_Evidence"){
      data_converter <<- Data_Converter_MaxQuant_Evidence $new()
    } else {
      stop(sprintf("File type '%s' is not currently supported by PMD-FDR module", file_type))
    }
  },
  set_info = function(info){
    parents[["info"]] <<- info
  },
  get_info = function(){
    return(verified_element_of_list(parents, "info", "Data_Object_Data_Converter$parents"))
  },
  set_raw_data = function(raw_data){
    parents[["raw_data"]] <<- raw_data
  },
  get_raw_data = function(){
    return(verified_element_of_list(parents, "raw_data", "Data_Object_Data_Converter$parents"))
  }
)
###############################################################################
#            Class: Data_Object_Groupings
###############################################################################
Data_Object_Groupings <- setRefClass("Data_Object_Groupings", 
                                     contains = "Data_Object",
                                     fields =list(df = "data.frame"))
Data_Object_Groupings$methods(
  initialize = function(){
    callSuper()
    class_name <<- "Data_Object_Groupings"
  },
  simplify_field_name = function(x=NULL){
    result <- gsub(pattern = "PMD_FDR_", replacement = "", x = x)
    return(result)
  },
  verify = function(){
    data_original <- get_data_converter()$df
    
    check_field_name(data_original, "data_converter", "PMD_FDR_input_score")
    check_field_name(data_original, "data_converter", "PMD_FDR_pmd")
    check_field_name(data_original, "data_converter", "PMD_FDR_spectrum_file")
    check_field_name(data_original, "data_converter", "PMD_FDR_proteins")
    check_field_name(data_original, "data_converter", "PMD_FDR_spectrum_title")
    check_field_name(data_original, "data_converter", "PMD_FDR_sequence")
    check_field_name(data_original, "data_converter", "PMD_FDR_decoy")
    
  },
  m_load_data = function(){
    make_data_groups <- function(data_original=NULL){
      
      # Functions supporting make_data_groups()
      
      standardize_fields <- function(data=NULL){
        data_new <- data
        
        info <- get_info()
        info$ensure()
        #field_name_of_score <- info$get_field_name_of_score()
        
        # #data_new <- rename_column(data_new, "Variable Modifications"   , "ptm_list")
        # data_new <- rename_column(data_new, field_name_of_score        , "PMD_FDR_input_score")
        # data_new <- rename_column(data_new, "Precursor m/z Error [ppm]", "PMD_FDR_pmd")
        # #data_new <- rename_column(data_new, "Isotope Number"           , "isotope_number")
        # #data_new <- rename_column(data_new, "m/z"                      , "m_z")
        # #data_new <- rename_column(data_new, "Measured Charge"          , "charge")
        # data_new <- rename_column(data_new, "Spectrum File"            , "PMD_FDR_spectrum_file")
        # data_new <- rename_column(data_new, "Protein(s)"               , "PMD_FDR_proteins")
        # data_new <- rename_column(data_new, "Spectrum Title"           , "PMD_FDR_spectrum_title")
        # data_new <- manage_decoy_column(data_new)
        
        # Now managed in Data_Converter
        # data_new$PMD_FDR_input_score    <- data_new[,  field_name_of_score       ]
        # data_new$PMD_FDR_pmd            <- data_new[, "Precursor m/z Error [ppm]"]
        # data_new$PMD_FDR_spectrum_file  <- data_new[, "Spectrum File"            ]
        # data_new$PMD_FDR_proteins       <- data_new[, "Protein(s)"               ]
        # data_new$PMD_FDR_spectrum_title <- data_new[, "Spectrum Title"           ]
        
        data_new$value          <- data_new$PMD_FDR_pmd
        data_new$PMD_FDR_peptide_length <- str_length(data_new$PMD_FDR_sequence)
        #data_new$charge_value   <- with(data_new, as.numeric(substr(charge, start=1, stop=str_length(charge)-1)))
        #data_new$measured_mass  <- with(data_new, m_z*charge_value)
        data_new$PMD_FDR_spectrum_index <- NA
        data_new$PMD_FDR_spectrum_index[order(data_new$PMD_FDR_spectrum_title, na.last = TRUE)] <- 1:nrow(data_new)
        
        return(data_new)
      }
      add_grouped_variable <- function(data_groups = data_groups, field_name_to_group = NULL, vec.length.out = NULL, vec.tolerance = NULL, value_format = NULL){
        
        # Support functions for add_grouped_variable()
        find_interval_vec <- function(x=NULL, length.out = NULL, tolerance = NULL){
          q <- quantile(x = x, probs = seq(from=0, to=1, length.out = length.out), na.rm=TRUE)
          q <- round_to_tolerance(q, tolerance = tolerance)
          return(q)
        }
        get_group_data_frame <- function(vec=NULL, value_format = NULL){
          n <- length(vec)
          a <- vec[-n]
          b <- vec[-1]
          
          lower      <- ifelse(a == b           , "eq", NA)
          lower      <- ifelse(is.na(lower     ), "ge", lower)
          upper      <- ifelse(a == b           , "eq", NA)
          upper[n-1] <- ifelse(is.na(upper[n-1]), "le", "eq")
          upper      <- ifelse(is.na(upper     ), "lt", upper)
          group <- data.frame(list(idx=1:(n-1), a=a, b=b, lower=lower, upper=upper))
          
          name_format <- sprintf("%%%s_%%%s_%%s_%%s", value_format, value_format)
          group$new_var <- with(group, sprintf(name_format, a, b, lower, upper))
          
          return(group)
        }
        merge_group_with_data <- function(data_groups = NULL, group = NULL, vec = NULL, field_name_to_group = NULL){
          field_name_new <- sprintf("group_%s", simplify_field_name(field_name_to_group))
          group_idx      <- findInterval(x = data_groups[,field_name_to_group], 
                                         vec = vec, 
                                         all.inside=TRUE)
          data_groups$new_var <- group$new_var[group_idx]
          data_groups         <- rename_column(data_groups, "new_var", field_name_new)
        }
        # Body of add_grouped_variable()
        
        vec    <- find_interval_vec(x          = data_groups[[field_name_to_group]], 
                                    length.out = vec.length.out, 
                                    tolerance  = vec.tolerance )
        group  <- get_group_data_frame(vec          = vec, 
                                       value_format = value_format)
        df_new <- merge_group_with_data(data_groups         = data_groups, 
                                        group               = group, 
                                        vec                 = vec,
                                        field_name_to_group = field_name_to_group)
        df_new <- add_group_decoy(df_new, field_name_to_group)
        
        return(df_new)
      }
      add_already_grouped_variable <- function(field_name_to_group = NULL, data_groups = NULL ){
        old_name <- field_name_to_group
        new_name <- sprintf("group_%s", simplify_field_name(old_name))
        df_new <- data_groups
        df_new[[new_name]] <- data_groups[[old_name]]
        
        df_new <- add_group_decoy(data_groups = df_new, field_name_to_group = field_name_to_group)
        
        return(df_new)
      }
      add_value_norm <- function(data_groups = NULL){
        
        df_new            <- data_groups
        df_new$value_norm <- with(df_new, value - median_of_group_index)
        
        return(df_new)
      }
      add_protein_group <-function(data_groups = NULL){
        data_new <- data_groups
        df_group_def <- data.frame(stringsAsFactors = FALSE,
                                   list(pattern    = c(""     , "pfu_"      , "cRAP"),
                                        group_name = c("human", "pyrococcus", "contaminant")))
        for (i in 1:nrow(df_group_def)){
          idx <- grepl(pattern = df_group_def$pattern[i],
                       x       = data_new$PMD_FDR_proteins)
          data_new$group_proteins[idx] <- df_group_def$group_name[i]
        }
        
        data_new <- add_group_decoy(data_groups = data_new, field_name_to_group = "PMD_FDR_proteins")
        return(data_new)
      }
      add_group_decoy <- function(data_groups=NULL, field_name_to_group=NULL){
        simple_field_name <- simplify_field_name(field_name_to_group)
        field_name_decoy <- sprintf("group_decoy_%s", simple_field_name)
        field_name_group <- sprintf("group_%s",       simple_field_name)
        
        data_groups[[field_name_decoy]] <- with(data_groups, ifelse(PMD_FDR_decoy, "decoy", data_groups[[field_name_group]]))
        
        return(data_groups)
      }
      add_group_training_class <- function(data_groups = NULL){
        df_new <- data_groups
        
        lowest_confidence_group <- min(data_groups$group_input_score)
        
        is_long_enough   <- with(df_new, (PMD_FDR_peptide_length >= MIN_GOOD_PEPTIDE_LENGTH)    )
        is_good          <- with(df_new, (PMD_FDR_decoy == 0) & (PMD_FDR_input_score == 100) )
        is_bad           <- with(df_new, (PMD_FDR_decoy == 1) )
        #is_used_to_train <- with(df_new, used_to_find_middle) # BUGBUG: circular definition
        
        idx_good         <- which(is_good         ) # & is_long_enough)
        n_good           <- length(idx_good)
        idx_testing      <- idx_good[c(TRUE,FALSE)] # Selects every other item
        idx_training     <- setdiff(idx_good, idx_testing)
        
        #is_good_short    <- with(df_new,  is_good      & !is_long_enough                )
        #is_good_long     <- with(df_new,  is_good      &  is_long_enough                )
        is_bad_short     <- with(df_new,  is_bad       & !is_long_enough                )
        is_bad_long      <- with(df_new,  is_bad       &  is_long_enough                )
        #is_good_training <- with(df_new,  is_good_long & (used_to_find_middle == TRUE ) )
        #is_good_testing  <- with(df_new,  is_good_long & (used_to_find_middle == FALSE) )
        
        df_new$group_training_class                   <- "other_short"   # Default
        df_new$group_training_class[is_long_enough  ] <- "other_long"    # Default (if long enough)
        df_new$group_training_class[idx_training    ] <- "good_training" # Length does not matter (anymore)
        df_new$group_training_class[idx_testing     ] <- "good_testing"  # Ditto
        #df_new$group_training_class[is_good_short   ] <- "good_short"
        df_new$group_training_class[is_bad_long     ] <- "bad_long"      # ...except for "bad"
        df_new$group_training_class[is_bad_short    ] <- "bad_short"
        
        df_new <- add_used_to_find_middle( data_groups = df_new ) # Guarantees consistency between duplicated definitions
        
        return(df_new)
      }
      add_used_to_find_middle <- function(data_groups = NULL){
        df_new    <- data_groups
        idx_used  <- which(data_groups$group_training_class == "good_training")
        
        df_new$used_to_find_middle           <- FALSE
        df_new$used_to_find_middle[idx_used] <- TRUE
        
        return(df_new)
      }
      add_group_spectrum_index <- function(data_groups = NULL){
        
        # Supporting functions for add_group_spectrum_index()
        
        get_breaks_all <- function(df_new){
          # Supporting function(s) for get_breaks_all()
          
          get_cut_points <- function(data_subset){
            
            # Supporting function(s) for get_cut_points()
            
            cut_values <- function(data=NULL, minimum_segment_length=NULL){
              # using cpt.mean -- Appears to have a memory leak
              #results_cpt <- cpt.mean(data=data, method="PELT", minimum_segment_length=minimum_segment_length)
              #results <- results_cpt@cpts
              
              # Just look at the end
              #results <- c(length(data))
              
              # regularly spaced, slightly larger than minimum_segment_length
              n_points <- length(data)
              n_regions <- floor(n_points / minimum_segment_length)
              n_regions <- ifelse(n_regions == 0, 1, n_regions)
              results <- round(seq(1, n_points, length.out = n_regions + 1))
              results <- results[-1]
              return(results)
            }
            remove_last <- function(x){
              return(x[-length(x)] )
            }
            
            # Main code of for get_cut_points()
            max_idx = max(data_subset$PMD_FDR_spectrum_index)
            data_sub_sub <- subset(data_subset, group_training_class == "good_training") #(PMD_FDR_input_score==100) & (PMD_FDR_decoy==0))
            minimum_segment_length = 50
            
            values <- data_sub_sub$value
            n_values <- length(values)
            local_to_global_idx <- data_sub_sub$PMD_FDR_spectrum_index
            if (n_values <= minimum_segment_length){
              result <- c()
            } else {
              local_idx <- cut_values(data=values, minimum_segment_length=minimum_segment_length)
              result <- local_to_global_idx[local_idx]
              result <- remove_last(result)
            }
            result <- c(result, max_idx)
            return(result)
          }
          remove_last <- function(vec) {
            return(vec[-length(vec)])
          }
          
          # Main code of get_breaks_all()
          
          breaks <- 1
          
          files <- unique(df_new$PMD_FDR_spectrum_file)
          
          for (local_file in files){
            data_subset <- subset(df_new, (PMD_FDR_spectrum_file==local_file))
            if (nrow(data_subset) > 0){
              breaks <- c(breaks, get_cut_points(data_subset))
            }
          }
          breaks <- sort(unique(breaks))
          breaks <- remove_last(breaks)
          breaks <- c(breaks, max(df_new$PMD_FDR_spectrum_index + 1))
          
          return(breaks)
        }
        
        # Main code of add_group_spectrum_index()
        
        field_name_to_group <- "PMD_FDR_spectrum_index"
        
        df_new <- data_groups[order(data_groups[[field_name_to_group]]),]
        breaks <- get_breaks_all(df_new)
        
        df_new$group_spectrum_index <- cut(x = df_new[[field_name_to_group]], breaks = breaks, right = FALSE, dig.lab = 6)
        df_new <- add_group_decoy(data_groups = df_new, field_name_to_group = field_name_to_group)
        
        return(df_new)
      }
      add_median_of_group_index <-function(data_groups = NULL){
        field_median <- "median_of_group_index"
        data_good <- subset(data_groups, used_to_find_middle )
        med <- aggregate(value~group_spectrum_index, data=data_good, FUN=safe_median)
        med <- rename_column(med, "value", field_median)
        
        data_groups[[field_median]] <- NULL
        df_new <- merge(data_groups, med)
        
        return(df_new)
      }
      add_1_percent_to_data_groups <- function(data_groups=NULL){
        
        data_new <- data_groups
        
        if (get_raw_1_percent()$exists()){
          # Load 1 percent file
          df_1_percent <- get_raw_1_percent()$df
          
          # Get relevant fields
          df_1_percent$is_in_1percent <- TRUE
          df_1_percent                <- rename_column(df_1_percent, "Spectrum Title", "PMD_FDR_spectrum_title")
          df_1_percent                <- df_1_percent[,c("PMD_FDR_spectrum_title", "is_in_1percent")]
          
          # Merge with data_groups
          data_new <- merge(data_new, df_1_percent, all.x=TRUE)
          data_new$is_in_1percent[is.na(data_new$is_in_1percent)] <- FALSE
        }
        
        # Save results
        return(data_new)
        
      }
      
      
      # Main code of make_data_groups()
      data_groups <- standardize_fields(data_original)
      
      data_groups <- add_grouped_variable(field_name_to_group = "PMD_FDR_input_score", 
                                          data_groups         = data_groups, 
                                          vec.length.out      = 14, 
                                          vec.tolerance       = 1, 
                                          value_format        = "03d")
      
      data_groups <- add_grouped_variable(field_name_to_group = "PMD_FDR_pmd", 
                                          data_groups         = data_groups, 
                                          vec.length.out      = 21, 
                                          vec.tolerance       = 0.1, 
                                          value_format        = "+05.1f")
      
      data_groups <- add_grouped_variable(field_name_to_group = "PMD_FDR_peptide_length", 
                                          data_groups         = data_groups, 
                                          vec.length.out      = 11, 
                                          vec.tolerance       = 1, 
                                          value_format        = "02d")
      
      # data_groups <- add_grouped_variable(field_name_to_group = "m_z", 
      #                                     data_groups         = data_groups, 
      #                                     vec.length.out      = 11, 
      #                                     vec.tolerance       = 10, 
      #                                     value_format        = "04.0f")
      # 
      # data_groups <- add_grouped_variable(field_name_to_group = "measured_mass", 
      #                                     data_groups         = data_groups, 
      #                                     vec.length.out      = 11, 
      #                                     vec.tolerance       = 1, 
      #                                     value_format        = "04.0f")
      # 
      # data_groups <- add_already_grouped_variable(field_name_to_group = "isotope_number",
      #                                             data_groups         = data_groups )
      # 
      # data_groups <- add_already_grouped_variable(field_name_to_group = "charge",
      #                                             data_groups         = data_groups )
      # 
      data_groups <- add_already_grouped_variable(field_name_to_group = "PMD_FDR_spectrum_file",
                                                  data_groups         = data_groups )
      data_groups <- add_protein_group(data_groups = data_groups)
      data_groups <- add_group_training_class(  data_groups = data_groups)
      data_groups <- add_group_spectrum_index(  data_groups = data_groups)
      data_groups <- add_median_of_group_index( data_groups = data_groups)
      data_groups <- add_value_norm(            data_groups = data_groups)
      
      # fields_of_interest <- c("PMD_FDR_input_score", "PMD_FDR_pmd", "m_z", "PMD_FDR_peptide_length", "isotope_number", "charge", "PMD_FDR_spectrum_file", "measured_mass", "PMD_FDR_spectrum_index", "PMD_FDR_proteins")
      # fields_of_interest <- c("value", 
      #                         "PMD_FDR_decoy",
      #                         "PMD_FDR_spectrum_title",
      #                         "median_of_group_index",
      #                         "value_norm",
      #                         "used_to_find_middle",
      #                         "group_training_class",
      #                         fields_of_interest, 
      #                         sprintf("group_%s"      , fields_of_interest),
      #                         sprintf("group_decoy_%s", fields_of_interest))
      
      fields_of_interest <- c("PMD_FDR_input_score", "PMD_FDR_pmd", "PMD_FDR_peptide_length", "PMD_FDR_spectrum_file", "PMD_FDR_spectrum_index", "PMD_FDR_proteins")
      fields_of_interest <- c("value",
                              "PMD_FDR_decoy",
                              "PMD_FDR_spectrum_title",
                              "median_of_group_index",
                              "value_norm",
                              "used_to_find_middle",
                              "group_training_class",
                              fields_of_interest,
                              sprintf("group_%s"      , simplify_field_name(fields_of_interest)),
                              sprintf("group_decoy_%s", simplify_field_name(fields_of_interest)))
      
      data_groups <- data_groups[,fields_of_interest]
      data_groups <- add_1_percent_to_data_groups(data_groups)
      
      return(data_groups)
    }
    
    data_original <- get_data_converter()$df #parents[[INDEX_OF_ORIGINAL_DATA]]$df
    df <<- make_data_groups(data_original)
  },
  set_info = function(info){
    parents[["info"]] <<- info
  },
  get_info = function(){
    return(verified_element_of_list(parents, "info", "Data_Object_Groupings$parents"))
  },
  set_data_converter = function(data_converter){
    parents[["data_converter"]] <<- data_converter
  },
  get_data_converter = function(){
    return(verified_element_of_list(parents, "data_converter", "Data_Object_Groupings$parents"))
  },
  set_raw_1_percent = function(raw_1_percent){ ############## BUGBUG: the 1% file should be using the same file type format as the standard data (but isn't)
    parents[["raw_1_percent"]] <<- raw_1_percent
  },
  get_raw_1_percent = function(){
    return(verified_element_of_list(parents, "raw_1_percent", "Data_Object_Groupings$parents"))
  }
)
###############################################################################
#            Class: Data_Object_Individual_FDR
###############################################################################
Data_Object_Individual_FDR <- setRefClass("Data_Object_Individual_FDR", 
                                          contains = "Data_Object",
                                          fields =list(df = "data.frame"))
Data_Object_Individual_FDR$methods(
  initialize = function(){
    callSuper()
    class_name <<- "Data_Object_Individual_FDR"
  },
  verify = function(){
    data_groups = get_data_groups()$df
    densities   = get_densities()$df
    alpha       = get_alpha()$df
    
    check_field_name(data_groups, "data_groups", "value_norm")
    check_field_name(data_groups, "data_groups", "group_decoy_input_score")
    check_field_name(data_groups, "data_groups", "PMD_FDR_peptide_length")
    check_field_name(data_groups, "data_groups", "PMD_FDR_input_score")
    check_field_name(alpha, "alpha", "alpha") # BUGBUG: I'm missing a field here...
    check_field_name(densities, "densities", "x")
    check_field_name(densities, "densities", "t")
    check_field_name(densities, "densities", "f")
    
  },
  set_data_groups = function(parent){
    parents[["data_groups"]] <<- parent
  },
  get_data_groups = function(){
    return(verified_element_of_list(parents, "data_groups", "Data_Object_Individual_FDR$parents"))
  },
  set_densities = function(parent){
    parents[["densities"]] <<- parent
  },
  get_densities = function(){
    return(verified_element_of_list(parents, "densities", "Data_Object_Individual_FDR$parents"))
  },
  set_alpha = function(parent){
    parents[["alpha"]] <<- parent
  },
  get_alpha = function(){
    return(verified_element_of_list(parents, "alpha", "Data_Object_Individual_FDR$parents"))
  },
  m_load_data = function(){
    add_FDR_to_data_groups <- function(data_groups=NULL, densities=NULL, alpha=NULL, field_value=NULL, field_decoy_group=NULL, set_decoy_to_1=FALSE){
      # Support functions for add_FDR_to_data_groups()
      get_group_fdr <- function(group_stats = NULL, data_groups = NULL, densities=NULL){
        group_fdr <- apply(X = densities, MARGIN = 2, FUN = max)
        df_group_fdr <- data.frame(group_fdr)
        df_group_fdr <- rename_column(df_group_fdr, "group_fdr", "v")
        df_group_fdr$group_of_interest <- names(group_fdr)
        t <- df_group_fdr[df_group_fdr$group_of_interest == "t", "v"]
        f <- df_group_fdr[df_group_fdr$group_of_interest == "f", "v"]
        df_group_fdr <- subset(df_group_fdr, !(group_of_interest %in% c("x", "t", "f")))
        df_group_fdr$group_fdr <-(df_group_fdr$v - t) / (f - t)
        
        return(df_group_fdr)
      }
      
      get_mode <- function(x){
        d <- density(x)
        return(d$x[which.max(d$y)])
      }
      
      # Main code for add_FDR_to_data_groups()
      
      # Set up analysis
      data_new <- data_groups
      data_new$value_of_interest <- data_new[,field_value]
      data_new$group_of_interest <- data_new[,field_decoy_group]
      
      data_subset <- subset(data_new, PMD_FDR_peptide_length >= 11)
      
      # Identify mean PMD_FDR_input_score per group
      
      group_input_score <- aggregate(PMD_FDR_input_score~group_of_interest, data=data_subset, FUN=mean)
      group_input_score <- rename_column(group_input_score, "PMD_FDR_input_score", "group_input_score")
      
      #group_fdr   <- get_group_fdr(data_groups = data_subset, densities=densities)
      group_stats <- merge(alpha, group_input_score)
      group_stats <- subset(group_stats, group_of_interest != "PMD_FDR_decoy")
      
      x=c(0,group_stats$group_input_score)
      y=c(1,group_stats$alpha)
      FUN_interp <- approxfun(x=x,y=y)
      
      data_new$interpolated_groupwise_FDR <- FUN_interp(data_new$PMD_FDR_input_score)
      if (set_decoy_to_1){
        data_new$interpolated_groupwise_FDR[data_new$PMD_FDR_decoy == 1] <- 1
      }
      
      return(data_new)
    }
    
    data_groups = get_data_groups()$df
    densities   = get_densities()$df
    alpha       = get_alpha()$df
    
    d_true  <- densities[,c("x", "t")]
    d_false <- densities[,c("x", "f")]
    
    i_fdr <- add_FDR_to_data_groups(data_groups       = data_groups, 
                                    densities         = densities,
                                    alpha             = alpha,
                                    field_value       ="value_norm", 
                                    field_decoy_group = "group_decoy_input_score")
    # Derive local t
    interp_t <- splinefun(x=d_true$x,  y=d_true$t) #approxfun(x=d_true$x, y=d_true$y)
    
    # Derive local f
    interp_f <- splinefun(x=d_false$x, y=d_false$f) #approxfun(x=d_true$x, y=d_true$y)
    
    # Derive local FDR
    i_fdr$t     <- interp_t(i_fdr$value_of_interest)
    i_fdr$f     <- interp_f(i_fdr$value_of_interest)
    i_fdr$alpha <- i_fdr$interpolated_groupwise_FDR
    i_fdr$i_fdr <- with(i_fdr, (alpha*f) / (alpha*f + (1-alpha)*t)) 
    
    df <<- i_fdr
    
  }
)
###############################################################################
#            Class: Data_Object_Densities
###############################################################################
Data_Object_Densities <- setRefClass("Data_Object_Densities", 
                                     contains = "Data_Object",
                                     fields =list(df = "data.frame"))
Data_Object_Densities$methods(
  initialize = function(){
    callSuper()
    class_name <<- "Data_Object_Densities"
  },
  verify = function(){
    df_data_groups <- get_data_groups()$df
    
    checkTrue(nrow(df_data_groups) > 0,
              msg = "data_groups data frame was empty (and should not have been)")
    
    check_field_name(df_data_groups, "data_groups", "value_norm")
    check_field_name(df_data_groups, "data_groups", "group_decoy_input_score")
    check_field_name(df_data_groups, "data_groups", "group_training_class")
  },
  set_data_groups = function(parent=NULL){
    parents[["data_groups"]] <<- parent
  },
  get_data_groups = function(){
    return(verified_element_of_list(parent_list = parents, element_name = "data_groups", object_name = "Data_Object_Densities$parents"))
  },
  m_load_data = function(){
    
    # Support functions for make_densities()
    set_values_of_interest <- function(df_data_groups=NULL, field_group = NULL){
      field_value       = "value_norm"
      
      new_data_groups <- get_data_groups()$df
      new_data_groups$value_of_interest <- new_data_groups[,field_value]
      new_data_groups$group_of_interest <- new_data_groups[,field_group]
      #groups <- sort(unique(new_data_groups$group_of_interest))
      
      return(new_data_groups)
    }
    get_ylim <- function(data_groups=NULL){
      ylim <- range(data_groups$value_of_interest, na.rm = TRUE)
      return(ylim)
    }
    make_hit_density <- function(data_subset=NULL, descr_of_df=NULL, ylim=NULL){
      #stop("Data_Object_Densities$make_hit_density() is untested beyond here")
      verify_density = function(data_subset=NULL, value_field=NULL, descr_of_df=NULL, ylim=NULL){
        values <- data_subset[value_field]
        values <- values[! is.na(values)]
        if (length(values) < MIN_ACCEPTABLE_POINTS_IN_DENSITY){
          stop (sprintf("There are too few valid %s (%d < %d) in %s to be used for calculating a density function",
                        value_field, 
                        length(values),
                        MIN_ACCEPTABLE_POINTS_IN_DENSITY,
                        descr_of_df))
        }
        d <- density(values, from = ylim[1], to = ylim[2])
        
        return(d)
      }
      uniformalize_density <- function(d){
        # Reorganizes y-values of density function so that 
        # function is monotone increasing to mode
        # and monotone decreasing afterwards
        idx_mode   <- which.max(d$y)
        idx_lower <- 1:(idx_mode-1)
        idx_upper <- idx_mode:length(d$y)
        
        values_lower <- d$y[idx_lower]
        values_upper <- d$y[idx_upper]
        
        new_d   <- d
        new_d$y <- c(sort(values_lower, decreasing = FALSE), 
                     sort(values_upper, decreasing = TRUE))
        
        return(new_d)
      }
      
      local_df <- subset(data_subset,
                         (PMD_FDR_peptide_length >= MIN_GOOD_PEPTIDE_LENGTH) &
                           (used_to_find_middle == FALSE))
      d <- verify_density      (data_subset=local_df, value_field = "value_of_interest", descr_of_df = descr_of_df, ylim=ylim)
      d <- normalize_density   (d)
      d <- uniformalize_density(d)
      
      return(d)
    }
    make_true_hit_density  <- function(data_groups=NULL){
      d_true  <- make_hit_density(data_subset = subset(data_groups, (group_training_class == "good_testing") ),
                                  descr_of_df = "Good-testing dataset",
                                  ylim        = get_ylim(data_groups))
      return(d_true)
    }
    make_false_hit_density <- function(data_groups=NULL){
      d_false <- make_hit_density(data_subset = subset(data_groups, (group_training_class == "bad_long") ),
                                  descr_of_df = "Bad-long dataset",
                                  ylim        = get_ylim(data_groups))
      
      return(d_false)
    }
    add_v_densities <- function(data_groups=NULL, densities=NULL, field_group = NULL){
      groups <- sort(unique(data_groups$group_of_interest))
      
      new_densities <- densities
      
      for (local_group in groups){
        d_v <- make_hit_density(data_subset = subset(data_groups, (group_of_interest == local_group)),
                                descr_of_df = sprintf("subset of data (where %s is '%s')", 
                                                      field_group,
                                                      local_group),
                                ylim        = get_ylim(data_groups))
        new_densities[local_group] <- d_v$y
      }
      
      return(new_densities)
    }
    
    # Main section of make_densities()
    df_data_groups <- get_data_groups()$df
    new_data_groups <- set_values_of_interest(df_data_groups,  field_group = "group_decoy_input_score")
    d_true  <- make_true_hit_density( new_data_groups)
    d_false <- make_false_hit_density(new_data_groups)
    
    densities <- data.frame(x=d_true$x, 
                            t=d_true$y, 
                            f=d_false$y)
    densities <- add_v_densities(data_groups=new_data_groups, densities=densities,  field_group = "group_decoy_input_score")
    df <<- densities
  }
)
###############################################################################
#            Class: Data_Object_Alpha
###############################################################################
Data_Object_Alpha <- setRefClass("Data_Object_Alpha", 
                                 contains = "Data_Object",
                                 fields =list(df = "data.frame"))
Data_Object_Alpha$methods(
  initialize = function(){
    callSuper()
    class_name <<- "Data_Object_Alpha"
  },
  verify = function(){
    densities <- get_densities()$df
    
    checkTrue(nrow(densities) > 0,
              msg = "Densities data.frame was empty (and should not have been)")
  },
  set_densities = function(parent=NULL){
    parents[["densities"]] <<- parent
  },
  get_densities = function(){
    return(verified_element_of_list(parent_list = parents, element_name = "densities", object_name = "Data_Object_Alpha"))
  },
  m_load_data = function(){
    
    densities <- get_densities()$df
    
    max_of_density = apply(X = densities, MARGIN = 2, FUN = max)
    df_alpha <- data.frame(stringsAsFactors = FALSE,
                           list(v = max_of_density,
                                group_of_interest = names(max_of_density)))
    df_alpha <- subset(df_alpha, group_of_interest != "x")
    t <- with(subset(df_alpha, group_of_interest=="t"), v)
    f <- with(subset(df_alpha, group_of_interest=="f"), v)
    df_alpha$alpha <- with(df_alpha, (t-v)/(t-f))
    
    alpha <- df_alpha[,c("group_of_interest", "alpha")]
    alpha <- subset(alpha, (group_of_interest != "t") & (group_of_interest != "f"))
    
    df <<- alpha
  }
)
###############################################################################
#            Class: Data_Processor
###############################################################################
Data_Processor <- setRefClass("Data_Processor", 
                              fields =list(info           = "Data_Object_Info",
                                           raw_data       = "Data_Object_Raw_Data",
                                           raw_1_percent  = "Data_Object_Raw_1_Percent",
                                           data_converter = "Data_Object_Data_Converter",
                                           data_groups    = "Data_Object_Groupings",
                                           densities      = "Data_Object_Densities",
                                           alpha          = "Data_Object_Alpha",
                                           i_fdr          = "Data_Object_Individual_FDR"))
Data_Processor$methods(
  initialize = function(p_info=NULL){
    if (! is.null(p_info)){
      set_info(p_info)
    }
  },
  set_info = function(p_info=NULL){
    # This initialization defines all of the dependencies between the various components
    
    info <<- p_info
    
    # raw_data
    raw_data$set_info(info)
    info$append_child(raw_data)
    
    # raw_1_percent
    raw_1_percent$set_info(info)
    info$append_child(raw_1_percent)
    
    # data_converter
    data_converter$set_info    (info)
    data_converter$set_raw_data(raw_data)
    info         $append_child (data_converter)
    raw_data     $append_child (data_converter)
    
    # data_groups
    data_groups$set_info          (info)
    data_groups$set_data_converter(data_converter)
    data_groups$set_raw_1_percent (raw_1_percent)
    info          $append_child   (data_groups)
    data_converter$append_child   (data_groups)
    raw_1_percent $append_child   (data_groups)
    
    # densities
    densities  $set_data_groups(data_groups)
    data_groups$append_child   (densities)
    
    # alpha
    alpha    $set_densities(densities)
    densities$append_child (alpha)
    
    # i_fdr
    i_fdr$set_data_groups(data_groups)
    i_fdr$set_densities  (densities)
    i_fdr$set_alpha      (alpha)
    data_groups  $append_child(i_fdr)
    densities    $append_child(i_fdr)
    alpha        $append_child(i_fdr)
  }
)


#############################################################
####### Classes for Plotting
#############################################################

###############################################################################
#            Class: Plot_Image
###############################################################################
Plot_Image = setRefClass("Plot_Image",
                         fields = list(data_processors    = "list",
                                       plot_title         = "character",
                                       include_text       = "logical",
                                       include_main       = "logical", 
                                       x.intersp          = "numeric",
                                       y.intersp          = "numeric",
                                       scale              = "numeric",
                                       main               = "character",
                                       is_image_container = "logical"))
Plot_Image$methods(
  initialize = function(p_data_processors = list(), 
                        p_include_main = TRUE, 
                        p_include_text = TRUE,
                        p_is_image_container = FALSE){
    include_main    <<- p_include_main
    include_text    <<- p_include_text
    data_processors <<- p_data_processors
    is_image_container <<- p_is_image_container
  },
  plot_image = function(){
    plot(main="Define plot_image() for subclass") # Abstract function
  },
  get_n = function(){
    stop("Need to define function get_n() for subclass") #Abstract function
  },
  create_standard_main = function(){
    needs_main <- function(){
      return(include_text & include_main & !is_image_container)
    }
    if (needs_main()){
      collection_name <- data_processors[[1]]$info$collection_name()
      main <<- sprintf("%s\n(Dataset: %s; n=%s)", plot_title, collection_name,  format(get_n(), big.mark = ","))
    }
  },
  plot_image_in_window = function(p_scale=NULL, window_height=NULL, window_width=NULL){
    scale <<- p_scale
    SIZE_AXIS      <- 2.5 * scale # in the units used by mar
    SIZE_MAIN      <- 2.5 * scale
    SIZE_NO_MARGIN <- 0.1 * scale
    FONT_SIZE      <- 8   * scale
    WINDOW_WIDTH   <- window_width  * scale
    WINDOW_HEIGHT  <- window_height * scale
    X_INTERSP      <- 0.5 * scale + 0.4 # manages legend text spacing
    Y_INTERSP      <- 0.5 * scale + 0.4 # manages
    
    if (include_main){
      mar = c(SIZE_AXIS, SIZE_AXIS, SIZE_MAIN     , SIZE_NO_MARGIN)
    } else {
      mar = c(SIZE_AXIS, SIZE_AXIS, SIZE_NO_MARGIN, SIZE_NO_MARGIN)
    }
    mgp = c(SIZE_AXIS/2, SIZE_AXIS/4, 0) # Margin line (mex units) for axis title, axis labels, axis lines
    ps  = FONT_SIZE
    x.intersp <<- X_INTERSP
    y.intersp <<- Y_INTERSP
    
    windows(width = WINDOW_WIDTH, height=WINDOW_HEIGHT)
    
    old_par  <- par(mar=mar, ps=ps, mgp=mgp)
    create_standard_main()
    
    plot_image()
    if (!is_image_container){
      axis(side=1, labels=include_text, tcl=-0.5, lwd=scale)
      axis(side=2, labels=include_text, tcl=-0.5, lwd=scale)
      box(lwd=scale)
    }
    par(old_par)
  },
  plot_image_in_small_window = function(p_scale=1){
    plot_image_in_window(p_scale=p_scale, window_height=2, window_width=3.25)
  },
  plot_image_in_large_window = function(p_scale=1, window_height=NULL){
    plot_image_in_window(p_scale=p_scale, window_height=window_height, window_width=7)
  }
)
###############################################################################
#            Class: Legend_Object
###############################################################################
Legend_Object = setRefClass("Legend_Object",
                            contains = "Plot_Image",
                            fields = list(user_params = "list",
                                          scale       = "numeric"))
Legend_Object$methods(
  initialize = function(p_user_params = NULL, p_scale = NULL){
    if (is.null(p_user_params)){
      user_params <<- list()
    } else {
      user_params <<- p_user_params
    }
    if (is.null(p_scale)){
      stop("Legend_Object must have a valid scale")
    } else {
      scale <<- p_scale
    }
    user_params$x         <<- if_null(user_params$x        , "topleft", user_params$x)
    user_params$y         <<- if_null(user_params$y        ,      NULL, user_params$y)
    user_params$bty       <<- if_null(user_params$bty      ,       "o", user_params$bty)
    user_params$lwd       <<- if_null(user_params$lwd      ,      NULL, user_params$lwd        * scale) # Because we allow NULL, scale must be inside parens
    user_params$seg.len   <<- if_null(user_params$seg.len  ,         3, user_params$seg.len  ) * scale
    user_params$box.lwd   <<- if_null(user_params$box.lwd  ,         1, user_params$box.lwd  ) * scale
    user_params$x.intersp <<- if_null(user_params$x.intersp,       0.6, user_params$x.intersp) * scale
    user_params$y.intersp <<- if_null(user_params$y.intersp,       0.4, user_params$y.intersp) * scale + 0.2
  },
  show = function(){
    first_legend = legend(x         = user_params$x,
                          y         = user_params$y,
                          title     = "", 
                          legend    = user_params$leg, 
                          col       = user_params$col, 
                          bty       = user_params$bty,
                          lty       = user_params$lty, 
                          lwd       = user_params$lwd, 
                          seg.len   = user_params$seg.len, 
                          box.lwd   = user_params$box.lwd, 
                          x.intersp = user_params$x.intersp, 
                          y.intersp = user_params$y.intersp)
    new_x = first_legend$rect$left 
    new_y = first_legend$rect$top + first_legend$rect$h * ifelse(scale==1, 0.07, 0.03 - (scale * 0.02)) #switch(scale, 0.01, -0.01, -0.03, -0.05)# (0.07 - 0.09 * ((scale-1)^2))#(0.15 - 0.08*scale)#.07 * (2 - scale)
    legend(x=new_x, y=new_y, title = user_params$title, legend = "", cex=1.15, bty="n")
    
  }
)
###############################################################################
#            Class: Plot_Multiple_Images
###############################################################################
Plot_Multiple_Images = setRefClass("Plot_Multiple_Images",
                                   contains = "Plot_Image",
                                   fields = list(n_images_wide = "numeric",
                                                 n_images_tall = "numeric",
                                                 image_list    = "list"))
Plot_Multiple_Images$methods(
  initialize = function(p_n_images_wide=1, p_n_images_tall=2, p_image_list=NULL, ...){
    n_images_wide  <<- p_n_images_wide
    n_images_tall  <<- p_n_images_tall
    image_list     <<- p_image_list
    #plot_title      <<- "True Hit and False Hit Distributions"
    
    callSuper(p_is_image_container=TRUE, ...)
  },
  plot_image = function(){
    # Support functions
    apply_mtext <- function(letter=NULL){
      line=1.3*scale
      mtext(letter, side=1, line=line, adj=0)
    }
    # main code
    old_par <- par(mfrow=c(n_images_tall, n_images_wide))
    i=0
    n_images <- length(image_list)
    
    for (i in 1:n_images){
      image <- image_list[[i]]
      image$create_standard_main()
      image$scale <- scale
      image$plot_image()
      axis(side=1, labels=include_text, tcl=-0.5, lwd=scale)
      axis(side=2, labels=include_text, tcl=-0.5, lwd=scale)
      box(lwd=scale)
      apply_mtext(letter=sprintf("(%s)", letters[i]))
      
    }
    par(old_par)
    
  }
)
###############################################################################
#            Class: Plot_Compare_PMD_and_Norm_Density
###############################################################################
Plot_Compare_PMD_and_Norm_Density = setRefClass("Plot_Compare_PMD_and_Norm_Density",
                                                contains = "Plot_Image",
                                                fields = list(show_norm      = "logical",
                                                              display_n_psms = "logical"))
Plot_Compare_PMD_and_Norm_Density$methods(
  initialize = function(p_show_norm=TRUE, p_display_n_psms=TRUE, ...){
    show_norm       <<- p_show_norm
    display_n_psms  <<- p_display_n_psms
    plot_title      <<- "True Hit and False Hit Distributions"
    
    callSuper(...)
  },
  plot_image = function(){
    # Support functions for plot_compare_PMD_and_norm_density()
    
    get_densities <- function(data_subset = NULL, var_value = NULL){
      data_subset$value_of_interest <- data_subset[,var_value]
      from <- min(data_subset$value_of_interest, na.rm = TRUE)
      to   <- max(data_subset$value_of_interest, na.rm = TRUE)
      xlim = range(data_subset$value_of_interest)
      data_true  <- subset(data_subset, (PMD_FDR_decoy==0) & (PMD_FDR_input_score==100))
      data_false <- subset(data_subset, (PMD_FDR_decoy==1))    
      
      d_true  <- with(data_true , density(value_of_interest, from = from, to = to, na.rm = TRUE))
      d_false <- with(data_false, density(value_of_interest, from = from, to = to, na.rm = TRUE))
      d_true  <- normalize_density(d_true)
      d_false <- normalize_density(d_false)
      
      densities <- list(d_true=d_true, d_false=d_false, var_value = var_value, n_true = nrow(data_true), n_false = nrow(data_false))
      
      return(densities)
    }
    get_xlim <- function(densities_a = NULL, densities_b = NULL, show_norm=NULL){
      xlim   <- range(c(      densities_a$d_true$x, densities_a$d_false$y))
      if (show_norm){
        xlim <- range(c(xlim, densities_b$d_true$x, densities_b$d_false$y))
      }
      return(xlim)
    }
    get_ylim <- function(densities_a = NULL, densities_b = NULL, show_norm=NULL){
      ylim   <- range(c(      densities_a$d_true$y, densities_a$d_false$y))
      if (show_norm){
        ylim <- range(c(ylim, densities_b$d_true$y, densities_b$d_false$y))
      }
      return(ylim)
    }
    plot_distributions <- function(densities = NULL, var_value= NULL, dataset_name = NULL, ...){
      leg = list()
      leg$leg = c("Good", "Bad")
      if (display_n_psms){
        leg$leg = sprintf("%s (%d PSMs)", 
                          leg$leg,
                          c(densities$n_true, densities$n_false))
        
      }
      leg$col = c("black", "red")
      leg$lwd = c(3      ,     3)
      leg$lty = c(1      ,     2)
      leg$title = "Hit Category"
      xlab = ifelse(var_value == "value",
                    "PMD (ppm)",
                    "PMD - normalized (ppm)")
      ylab = "Density"
      if (!include_text){
        xlab = ""
        ylab = ""
      }
      plot( densities$d_true , col=leg$col[1], lwd=leg$lwd[1] * scale, lty=leg$lty[1], xaxt = "n", yaxt = "n", main=main, xlab = xlab, ylab=ylab, ...)
      lines(densities$d_false, col=leg$col[2], lwd=leg$lwd[2] * scale, lty=leg$lty[2])
      abline(v=0, h=0, col="gray", lwd=1*scale)
      if (include_text){
        legend_object <- Legend_Object$new(leg, scale)
        legend_object$show()
        #legend("topleft", legend=leg.leg, col=leg.col, lwd=leg.lwd, lty=leg.lty, x.intersp = x.intersp, y.intersp = y.intersp)
      }
    }
    
    # Main code block for plot_compare_PMD_and_norm_density
    data_processor <- data_processors[[1]]
    data_processor$data_groups$ensure()
    data_groups <- data_processor$data_groups$df
    
    data_subset_a <- subset(data_groups  , used_to_find_middle == FALSE)
    data_subset_b <- subset(data_subset_a, PMD_FDR_peptide_length > 11)
    
    densities_a <- get_densities(data_subset = data_subset_a, var_value = "value")
    densities_b <- get_densities(data_subset = data_subset_b, var_value = "value_norm")
    
    xlim=get_xlim(densities_a, densities_b, show_norm = show_norm)
    ylim=get_ylim(densities_a, densities_b, show_norm = show_norm)
    
    dataset_name <- data_processor$info$collection_name
    plot_distributions(  densities=densities_a, var_value = "value"     , dataset_name = dataset_name, xlim=xlim, ylim=ylim)
    if (show_norm){
      plot_distributions(densities=densities_b, var_value = "value_norm", dataset_name = dataset_name, xlim=xlim, ylim=ylim)
    }
  },
  get_n = function(){
    data_processor <- data_processors[[1]]
    data_processor$data_groups$ensure()
    data_subset_a <- subset(data_processor$data_groups$df  , used_to_find_middle == FALSE)
    data_subset_b <- subset(data_subset_a, PMD_FDR_peptide_length > 11)
    
    if (show_norm){
      data_subset <- data_subset_a
    } else {
      data_subset <- data_subset_b
    }
    
    data_true  <- subset(data_subset, (PMD_FDR_decoy==0) & (PMD_FDR_input_score==100))
    data_false <- subset(data_subset, (PMD_FDR_decoy==1))       
    
    return(nrow(data_true) + nrow(data_false))
  }
)

###############################################################################
#            Class: Plot_Time_Invariance_Alt
###############################################################################
Plot_Time_Invariance_Alt = setRefClass("Plot_Time_Invariance_Alt",
                                       contains = "Plot_Image",
                                       fields = list(show_norm      = "logical",
                                                     display_n_psms = "logical",
                                                     training_class = "character",
                                                     ylim           = "numeric",
                                                     field_of_interest = "character"))
Plot_Time_Invariance_Alt$methods(
  initialize = function(p_ylim=NULL, p_training_class=NULL, p_field_of_interest="value_norm", ...){
    get_subset_title <- function(training_class=NULL){
      if        (training_class == "bad_long"){
        subset_title="bad only"
      } else if (training_class == "good_testing"){
        subset_title="good-testing only"
      } else if (training_class == "good_training"){
        subset_title="good-training only"
      } else if (training_class == "other"){
        subset_title="other only"
      } else {
        stop("Unexpected training_class in plot_time_invariance")
      }
      return(subset_title)
    }
    
    ylim <<- p_ylim
    training_class <<- p_training_class
    field_of_interest <<- p_field_of_interest
    subset_title <- get_subset_title(training_class=training_class)
    backup_title <- sprintf("Middle 25%% PMD for spectra sorted by index%s", 
                            ifelse(is.null(subset_title),
                                   "",
                                   sprintf(" - %s", subset_title)))
    #plot_title <<- get_main(main_title=main, backup_title=backup_title, data_collection = data_collection)
    plot_title <<- backup_title
    
    callSuper(...)
  },
  plot_image = function(){
    # Support functions for plot_time_invariance()
    
    # Main code of plot_time_invariance()
    data_subset = get_data_subset()
    plot_group_spectrum_index_from_subset_boxes(data_subset = data_subset)
    abline(h=0, col="blue", lwd=scale)
  },
  get_data_subset = function(){
    data_processor <- data_processors[[1]]
    data_processor$data_groups$ensure()
    return(subset(data_processor$data_groups$df, (group_training_class==training_class)))
  },
  get_n = function(){
    return(nrow(get_data_subset()))
  },
  plot_group_spectrum_index_from_subset_boxes = function(data_subset = NULL){
    n_plot_groups <- 100
    
    field_name_text <- ifelse(field_of_interest=="value", "PMD", "Translated PMD")
    new_subset                   <- data_subset
    new_subset$value_of_interest <- new_subset[,field_of_interest]
    new_subset                   <- new_subset[order(new_subset$PMD_FDR_spectrum_index),]
    
    idxs <- round_to_tolerance(seq(from=1, to=nrow(new_subset), length.out = n_plot_groups+1), 1)
    idxs_left  <- idxs[-(n_plot_groups+1)]
    idxs_right <- idxs[-1] - 1
    idxs_right[n_plot_groups] <- idxs_right[n_plot_groups] + 1
    
    new_subset$plot_group <- NA
    for (i in 1:n_plot_groups){
      new_subset$plot_group[idxs_left[i]:idxs_right[i]] <- i 
    }
    xleft   <- aggregate(PMD_FDR_spectrum_index   ~plot_group, data=new_subset, FUN=min)
    xright  <- aggregate(PMD_FDR_spectrum_index   ~plot_group, data=new_subset, FUN=max)
    ybottom <- aggregate(value_of_interest~plot_group, data=new_subset, FUN=function(x){quantile(x, probs = 0.5 - (0.25/2))})
    ytop    <- aggregate(value_of_interest~plot_group, data=new_subset, FUN=function(x){quantile(x, probs = 0.5 + (0.25/2))})
    boxes <- merge(            rename_column(xleft  , "PMD_FDR_spectrum_index"   , "xleft"),
                               merge(      rename_column(xright , "PMD_FDR_spectrum_index"   , "xright"),
                                           merge(rename_column(ybottom, "value_of_interest", "ybottom"),
                                                 rename_column(ytop   , "value_of_interest", "ytop"))))
    
    xlab <- "Spectrum Index"
    ylab <- sprintf("%s (ppm)", field_name_text )
    if (is.null(ylim)){
      ylim <<- range(new_subset$value_of_interest)
    }
    if (!include_text){
      xlab=""
      ylab=""
    }
    plot(value_of_interest~PMD_FDR_spectrum_index, data=new_subset, type="n", ylim=ylim, xlab = xlab, ylab=ylab, main=main, xaxt="n", yaxt="n")
    with(boxes, rect(xleft = xleft, ybottom = ybottom, xright = xright, ytop = ytop, lwd=scale))
    #points(median_of_group_index~PMD_FDR_spectrum_index, data=data_subset, cex=.5, pch=15)
    axis(1, labels=include_text, lwd=scale)
    axis(2, labels=include_text, lwd=scale)
    box(lwd=scale) #box around plot area
  }
  
)
###############################################################################
#            Class: Plot_Time_Invariance_Alt_Before_and_After
###############################################################################
Plot_Time_Invariance_Alt_Before_and_After = setRefClass("Plot_Time_Invariance_Alt_Before_and_After",
                                                        contains = "Plot_Multiple_Images",
                                                        fields = list())
Plot_Time_Invariance_Alt_Before_and_After$methods(
  initialize = function(p_data_processors = NULL, 
                        p_include_text=TRUE, 
                        p_include_main=FALSE,
                        p_ylim = c(-4,4), ...){
    plot_object1 <- Plot_Time_Invariance_Alt$new(p_data_processors = p_data_processors, 
                                                 p_include_text=p_include_text, 
                                                 p_include_main=p_include_main,
                                                 p_training_class = "good_testing",
                                                 p_field_of_interest = "value",
                                                 p_ylim = p_ylim)
    
    plot_object2 <- Plot_Time_Invariance_Alt$new(p_data_processors = p_data_processors, 
                                                 p_include_text=p_include_text, 
                                                 p_include_main=p_include_main,
                                                 p_training_class = "good_testing",
                                                 p_field_of_interest = "value_norm",
                                                 p_ylim = p_ylim)
    
    callSuper(p_n_images_wide=1, 
              p_n_images_tall=2, 
              p_include_text=p_include_text,
              p_include_main=p_include_main,
              p_image_list = list(plot_object1, plot_object2), ...)
  }
)

###############################################################################
#            Class: Plot_Density_PMD_and_Norm_Decoy_by_AA_Length
###############################################################################
Plot_Density_PMD_and_Norm_Decoy_by_AA_Length = setRefClass("Plot_Density_PMD_and_Norm_Decoy_by_AA_Length",
                                                           contains = "Plot_Image",
                                                           fields = list(show_norm = "logical"))
Plot_Density_PMD_and_Norm_Decoy_by_AA_Length$methods(
  initialize = function(p_show_norm=FALSE, ...){
    plot_title <<- "The Decoy Bump: PMD Distribution of Decoy matches by peptide length"
    show_norm  <<- p_show_norm
    callSuper(...)
  },
  get_n = function(){
    data_processor <- data_processors[[1]]
    data_processor$data_groups$ensure()
    data_subset <- subset(data_processor$data_groups$df, (PMD_FDR_decoy == 1))
    return(nrow(data_subset))
  },
  plot_image = function(){
    
    # Support functions for plot_density_PMD_and_norm_decoy_by_aa_length()
    
    add_group_peptide_length_special <- function(){
      data_processor <- data_processors[[1]]
      data_processor$data_groups$ensure()
      data_groups <- data_processor$data_groups$df # the name data_groups is a data.frame instead of a Data_Object
      data_groups <- subset(data_groups, used_to_find_middle == FALSE)
      
      df_group_definition <- data.frame(stringsAsFactors = FALSE,
                                        list(group_peptide_length_special = c("06-08", "09-10", "11-12", "13-15", "16-20", "21-50"),
                                             min                          = c(  6    ,   9    ,  11    ,  13    ,  16    ,  21    ),
                                             max                          = c(     8 ,     10 ,     12 ,     15 ,     20 ,     50 ) ))
      group_peptide_length_special     <- data.frame(list(PMD_FDR_peptide_length = 6:50))
      group_peptide_length_special$min <- with(group_peptide_length_special, sapply(PMD_FDR_peptide_length, FUN = function(i) max(df_group_definition$min[df_group_definition$min <= i])))
      group_peptide_length_special     <- merge(group_peptide_length_special, df_group_definition)
      
      data_groups$group_peptide_length_special <- NULL
      new_data_groups <- (merge(data_groups, 
                                group_peptide_length_special[,c("PMD_FDR_peptide_length", 
                                                                "group_peptide_length_special")]))
      return(new_data_groups)
    }
    get_densities <- function(data_subset = NULL, field_value = NULL, field_group=NULL){
      get_density_from_subset <- function(data_subset=NULL, xlim=NULL){
        
        d_group            <- with(data_subset , density(value_of_interest, from = xlim[1], to = xlim[2], na.rm=TRUE))
        d_group            <- normalize_density(d_group)
        
        return(d_group)
      }
      
      data_temp                   <- data_subset
      data_temp$value_of_interest <- data_temp[[field_value]]
      data_temp$group_of_interest <- data_temp[[field_group]]
      
      xlim = range(data_temp$value_of_interest, na.rm=TRUE)
      
      groups      <- sort(unique(data_temp$group_of_interest))
      n_groups    <- length(groups)
      
      d_group <- get_density_from_subset( data_subset=data_temp, xlim = xlim )
      densities <- list("All decoys" = d_group)
      for (i in 1:n_groups){
        group <- groups[i]
        
        d_group <- get_density_from_subset( data_subset=subset(data_temp, (group_of_interest == group)), 
                                            xlim = xlim )
        densities[[group]] <- d_group
      }
      
      return(densities)
    }
    get_limits <- function(densities_a = NULL, densities_b = NULL){
      xlim = c()
      ylim = c(0)
      for (single_density in densities_a){
        xlim=range(c(xlim, single_density$x))
        ylim=range(c(ylim, single_density$y))
      }
      for (single_density in densities_b){
        xlim=range(c(xlim, single_density$x))
        ylim=range(c(ylim, single_density$y))
      }
      
      return(list(xlim=xlim, ylim=ylim))
    }
    plot_distributions <- function(data_groups = NULL, xlim=NULL, ylim=NULL, densities = NULL, field_group= NULL, field_value = "value", xlab_modifier = "", var_value= NULL, include_peak_dots=TRUE, dataset_name = NULL, ...){
      data_groups$group_of_interest <- data_groups[[field_group]]
      data_groups$value_of_interest <- data_groups[[field_value]]
      
      # Main body of plot_decoy_distribution_by_field_of_interest()
      FIXED_LWD=3
      
      groups <- sort(unique(data_groups$group_of_interest))
      n      <- length(groups)
      
      df_leg <- data.frame(stringsAsFactors = FALSE,
                           list(leg = groups,
                                col = rainbow_with_fixed_intensity(n = n, goal_intensity_0_1 = 0.4),
                                lty = rep(1:6, length.out=n),
                                lwd = rep(FIXED_LWD , n)) )
      
      d <- densities[["All decoys"]]
      
      xlab = sprintf("Precursor Mass Discrepancy%s (ppm)", xlab_modifier)
      ylab = "Density"
      
      if (!include_text){
        xlab=""
        ylab=""
      }
      plot(d, lwd=FIXED_LWD * scale, main=main, xlab=xlab, ylab=ylab, xlim=xlim, ylim=ylim, xaxt="n", yaxt="n")
      
      ave_peak <- max(d$y)
      max_peak <- 0
      
      for (local_group in groups){
        data_subset <- subset(data_groups, group_of_interest == local_group)
        data_info   <- subset(df_leg     , leg               == local_group)
        col <- data_info$col[1]
        lty <- data_info$lty[1]
        lwd <- data_info$lwd[1]
        if (nrow(data_subset) > 100){
          d <- densities[[local_group]]  #density(data_subset[[field_value]])
          lines(d, col=col, lty=lty, lwd=lwd * scale)
          peak <- max(d$y)
          max_peak <- max(max_peak, peak)
        }
      }
      abline(v=0, h=0, lwd=scale)
      leg <- list(title = "Peptide length (aa)", 
                  leg = c("All decoys"     , df_leg$leg),
                  col = c(col2hex("black") , df_leg$col),
                  lty = c(1                , df_leg$lty),
                  lwd = c(FIXED_LWD        , df_leg$lwd)
      )
      if (include_text){
        legend_object = Legend_Object$new(leg, scale)
        legend_object$show()
        #first_legend = legend(x="topleft", title = "", legend = leg$leg, col = leg$col, lty = leg$lty, lwd = leg$lwd, seg.len=leg$seg.len, box.lwd=leg$box.lwd, x.intersp = leg$x.intersp, y.intersp = leg$y.intersp)
        #new_x = first_legend$rect$left 
        #new_y = first_legend$rect$top + first_legend$rect$h * .07 * (2 - scale)
        #legend(x=new_x, y=new_y, title = leg$title, legend = "", cex=1.15, bty="n")
      }
      
      box(lwd=scale) #box around plot area
      
    }
    
    # Main body for plot_density_PMD_and_norm_decoy_by_aa_length()
    
    data_mod <- add_group_peptide_length_special()
    data_mod <- subset(data_mod, PMD_FDR_decoy==1)
    
    densities_a <- get_densities(data_subset = data_mod, field_value = "value"     , field_group = "group_peptide_length_special")
    densities_b <- get_densities(data_subset = data_mod, field_value = "value_norm", field_group = "group_peptide_length_special")
    
    data_processor <- data_processors[[1]]
    dataset_name <- data_processor$info$collection_name()
    
    limits <- get_limits(densities_a, densities_b)
    xlim   <- limits$xlim
    ylim   <- limits$ylim
    
    if (show_norm){
      plot_distributions(data_groups = data_mod, densities=densities_b, field_value = "value_norm", xlab_modifier = " - normalized", field_group = "group_peptide_length_special", dataset_name=dataset_name, xlim=xlim, ylim=ylim)
    } else {
      plot_distributions(data_groups = data_mod, densities=densities_a, field_value = "value"     , xlab_modifier = ""             , field_group = "group_peptide_length_special", dataset_name=dataset_name, xlim=xlim, ylim=ylim)
    }
  }
  
)

###############################################################################
#            Class: Plot_Bad_CI
###############################################################################
Plot_Bad_CI = setRefClass("Plot_Bad_CI",
                          contains = "Plot_Image",
                          fields = list(breaks = "numeric",
                                        ylim   = "numeric"))
Plot_Bad_CI$methods(
  initialize = function(p_breaks=20, p_ylim=NULL, ...){
    if (is.null(p_ylim)){
      ylim <<- numeric(0)
    } else {
      ylim <<- p_ylim
    }
    breaks <<- p_breaks
    plot_title <<- "Credible Intervals for proportion within range - bad"
    callSuper(...)
  },
  data_processor = function(){
    return(data_processors[[1]])
  },
  get_n = function(){
    data_processor()$data_groups$ensure()
    return(nrow(subset(data_processor()$data_groups$df, (PMD_FDR_decoy == 1))))
  },
  plot_image = function(){
    data_processor()$data_groups$ensure()
    data_groups <- data_processor()$data_groups$df
    data_decoy <- subset(data_groups, data_groups$group_training_class == "bad_long")
    data_decoy$region <- cut(x = data_decoy$value, breaks = breaks)
    table(data_decoy$region)
    regions <- unique(data_decoy$region)
    
    N = nrow(data_decoy)
    find_lower_ci_bound <- function(x){
      ci <- credible_interval(length(x), N, precision = 0.001, alpha=0.05)
      return(ci[1])
    }
    find_upper_ci_bound <- function(x){
      ci <- credible_interval(length(x), N, precision = 0.001, alpha=0.05)
      return(ci[2])
    }
    xleft   <- aggregate(value~region, data=data_decoy, FUN=min)
    xright  <- aggregate(value~region, data=data_decoy, FUN=max)
    ytop    <- aggregate(value~region, data=data_decoy, FUN=find_upper_ci_bound)
    ybottom <- aggregate(value~region, data=data_decoy, FUN=find_lower_ci_bound)
    
    xleft   <- rename_column(xleft  , "value", "xleft"  )
    xright  <- rename_column(xright , "value", "xright" )
    ytop    <- rename_column(ytop   , "value", "ytop"   )
    ybottom <- rename_column(ybottom, "value", "ybottom")
    
    boxes <- merge(merge(xleft, xright), merge(ytop, ybottom))
    
    
    xlab <- "Precursor Mass Discrepancy (ppm)"
    ylab <- "Proportion of PSMs\nin subgroup"
    xlim=range(data_decoy$value, na.rm = TRUE)
    get_ylim(boxes=boxes)
    if (!include_text){
      xlab=""
      ylab=""
    }
    
    plot(x=c(-10,10), y=c(0,1), type="n", ylim=ylim, xlim=xlim, xlab=xlab, ylab=ylab, main=main, xaxt="n", yaxt="n")
    
    with(boxes, rect(xleft=xleft, xright=xright, ytop=ytop, ybottom=ybottom, lwd=scale))
    
    abline(h=1/breaks, col="blue", lwd=scale)
  },
  get_ylim = function(boxes=NULL){
    is_valid_range <- function(r=NULL){
      return(length(r) == 2)
    }
    if (! is_valid_range(ylim)){
      ylim <<- range(c(0,boxes$ytop, boxes$ybottom))
    }
  }
  
)
###############################################################################
#            Class: Plot_Selective_Loss
###############################################################################
Plot_Selective_Loss = setRefClass("Plot_Selective_Loss",
                                  contains = "Plot_Image",
                                  fields = list())
Plot_Selective_Loss$methods(
  initialize = function( ...){
    plot_title <<- "PMD-FDR Selectively removes Bad Hits"
    callSuper(...)
  },
  data_processor = function(){
    return(data_processors[[1]])
  },
  get_n = function(){
    data_processor()$i_fdr$ensure()
    data_subset <- data_processor()$i_fdr$df
    return(nrow(data_subset))
  },
  plot_image = function(){
    # Support functions for plot_selective_loss()
    
    samples_lost_by_threshold <- function(updated_i_fdr=NULL, score_threshold=NULL){
      data_subset <- subset(updated_i_fdr, PMD_FDR_input_score >= score_threshold)
      tbl <- with(updated_i_fdr, 
                  table(PMD_FDR_input_score >= score_threshold, 
                        new_confidence < score_threshold, 
                        group_decoy_proteins))
      df <- data.frame(tbl)
      df_n <- aggregate(Freq~group_decoy_proteins+Var1, data=df, FUN=sum)
      df_n <- rename_column(df_n, name_before = "Freq", "n")
      df <- merge(df, df_n)
      df$rate_of_loss <- with(df, Freq/n)
      df <- subset(df, (Var1==TRUE) & (Var2==TRUE))
      df <- df[,c("group_decoy_proteins", "rate_of_loss", "n", "Freq")]
      if (nrow(df) > 0){
        df$score_threshold <- score_threshold
      }
      return(df)
    }
    get_loss_record <- function(updated_i_fdr=NULL, score_thresholds=NULL){
      df=data.frame()
      for (score_threshold in score_thresholds){
        df_new_loss <- samples_lost_by_threshold(updated_i_fdr, score_threshold)
        df <- rbind(df, df_new_loss)
      }
      return(df)
    }
    
    # Main code for plot_selective_loss()
    
    updated_i_fdr                <- data_processor()$i_fdr$df
    updated_i_fdr$new_confidence <- with(updated_i_fdr, 100 * (1-i_fdr)) #ifelse((1-i_fdr) < (PMD_FDR_input_score / 100), (1-i_fdr), (PMD_FDR_input_score/100)))
    loss_record <- get_loss_record(updated_i_fdr=updated_i_fdr, score_thresholds = 1:100)
    xlim <- with(loss_record, range(score_threshold))
    ylim <- c(0,1)
    xlab <- "Fixed Confidence threshold (PeptideShaker score)"
    ylab <- "Rate of PSM disqualification from PMD-FDR"
    lwd  <- 4
    plot(x=xlim, y=ylim, type="n", main=main, xlab=xlab, ylab=ylab)
    
    groups <- sort(unique(loss_record$group_decoy_proteins))
    n_g    <- length(groups)
    
    cols <- rainbow_with_fixed_intensity(n=n_g, goal_intensity_0_1 = 0.5, alpha = 1)
    ltys <- rep(1:6, length.out=n_g)
    
    leg     <- list(leg=groups, col=cols, lty=ltys, lwd=lwd, title="Species/Category")
    
    for (i in 1:n_g){
      lines(rate_of_loss~score_threshold, data=subset(loss_record, group_decoy_proteins==leg$leg[i]), col=leg$col[i], lwd=leg$lwd * scale, lty=leg$lty[i])
    }
    abline(h=0, v=100, lwd=scale)
    abline(h=c(0.1, 0.8), col="gray", lwd=scale)
    
    #leg = list(leg=group, col=col, lty=lty, lwd=lwd)
    #with(leg, legend(x = "topleft", legend = group, col = col, lty = lty, lwd = lwd, seg.len = seg.len))
    legend_object <- Legend_Object$new(leg, scale)
    legend_object$show()
  }
  
)
###############################################################################
#            Class: Plot_Selective_Loss_for_TOC
###############################################################################
Plot_Selective_Loss_for_TOC = setRefClass("Plot_Selective_Loss_for_TOC",
                                          contains = "Plot_Image",
                                          fields = list(xlab="character",
                                                        ylab="character",
                                                        title_x="numeric",
                                                        title_y="numeric",
                                                        legend_border="logical",
                                                        legend_x = "numeric",
                                                        legend_y = "numeric",
                                                        legend_title="character",
                                                        legend_location = "character",
                                                        name_contaminant = "character",
                                                        name_decoy = "character",
                                                        name_human = "character",
                                                        name_pyro = "character"))
Plot_Selective_Loss_for_TOC$methods(
  initialize = function( ...){
    plot_title <<- "PMD-FDR selectively removes bad hits"
    callSuper(...)
    xlab <<- "Confidence threshold (PeptideShaker)"
    ylab <<- "PMD Disqualifiction Rate"
    legend_border    <<- FALSE
    #legend_title     <<-  "Species/Category"
    title_x          <<- 50
    title_y          <<- 0.9
    legend_x         <<- 10         
    legend_y         <<- 0.75
    name_contaminant <<- "signal - contaminant"
    name_decoy       <<- "decoy - reversed"
    name_human       <<- "decoy - human"
    name_pyro        <<- "signal - pyrococcus"
  },
  data_processor = function(){
    return(data_processors[[1]])
  },
  get_n = function(){
    data_processor()$i_fdr$ensure()
    data_subset <- data_processor()$i_fdr$df
    return(nrow(data_subset))
  },
  plot_image = function(){
    # Support functions for plot_selective_loss()
    
    samples_lost_by_threshold <- function(updated_i_fdr=NULL, score_threshold=NULL){
      data_subset <- subset(updated_i_fdr, PMD_FDR_input_score >= score_threshold)
      tbl <- with(updated_i_fdr, 
                  table(PMD_FDR_input_score >= score_threshold, 
                        new_confidence < score_threshold, 
                        group_decoy_proteins))
      df <- data.frame(tbl)
      df_n <- aggregate(Freq~group_decoy_proteins+Var1, data=df, FUN=sum)
      df_n <- rename_column(df_n, name_before = "Freq", "n")
      df <- merge(df, df_n)
      df$rate_of_loss <- with(df, Freq/n)
      df <- subset(df, (Var1==TRUE) & (Var2==TRUE))
      df <- df[,c("group_decoy_proteins", "rate_of_loss", "n", "Freq")]
      if (nrow(df) > 0){
        df$score_threshold <- score_threshold
      }
      return(df)
    }
    get_loss_record <- function(updated_i_fdr=NULL, score_thresholds=NULL){
      df=data.frame()
      for (score_threshold in score_thresholds){
        df_new_loss <- samples_lost_by_threshold(updated_i_fdr, score_threshold)
        df <- rbind(df, df_new_loss)
      }
      return(df)
    }
    convert_groups <- function(groups=NULL){
      new_groups <- groups
      new_groups <- gsub(pattern = "contaminant", replacement = name_contaminant, x = new_groups)
      new_groups <- gsub(pattern = "decoy"      , replacement = name_decoy      , x = new_groups)
      new_groups <- gsub(pattern = "human"      , replacement = name_human      , x = new_groups)
      new_groups <- gsub(pattern = "pyrococcus" , replacement = name_pyro       , x = new_groups)
      
      return(new_groups)
    }
    
    # Main code for plot_selective_loss()
    
    updated_i_fdr                <- data_processor()$i_fdr$df
    updated_i_fdr$new_confidence <- with(updated_i_fdr, 100 * (1-i_fdr)) #ifelse((1-i_fdr) < (PMD_FDR_input_score / 100), (1-i_fdr), (PMD_FDR_input_score/100)))
    loss_record <- get_loss_record(updated_i_fdr=updated_i_fdr, score_thresholds = 1:100)
    xlim <- with(loss_record, range(score_threshold))
    ylim <- c(0,1)
    #xlab <- "Fixed Confidence threshold (PeptideShaker score)"
    #ylab <- "Rate of PSM disqualification from PMD-FDR"
    lwd  <- 4
    plot(x=xlim, y=ylim, type="n", main=main, xlab=xlab, ylab=ylab)
    
    groups <- sort(unique(loss_record$group_decoy_proteins))
    n_g    <- length(groups)
    
    cols <- rainbow_with_fixed_intensity(n=n_g, goal_intensity_0_1 = 0.5, alpha = 1)
    ltys <- rep(1:6, length.out=n_g)
    bty  <- ifelse(legend_border, "o", "n")
    
    leg     <- list(leg=convert_groups(groups), var_name=groups, col=cols, lty=ltys, lwd=lwd, bty=bty, x=legend_x, y=legend_y)
    #leg     <- list(leg=groups, col=cols, lty=ltys, lwd=lwd, bty=bty, x=legend_x, y=legend_y)
    
    for (i in 1:n_g){
      lines(rate_of_loss~score_threshold, data=subset(loss_record, group_decoy_proteins==leg$var_name[i]), col=leg$col[i], lwd=leg$lwd * scale, lty=leg$lty[i])
    }
    abline(h=0, v=100, lwd=scale)
    abline(h=c(0.1, 0.8), col="gray", lwd=scale)
    
    #leg = list(leg=group, col=col, lty=lty, lwd=lwd)
    #with(leg, legend(x = "topleft", legend = group, col = col, lty = lty, lwd = lwd, seg.len = seg.len))
    legend_object <- Legend_Object$new(leg, scale)
    legend_object$show()
    text(x=title_x, y=title_y, labels = plot_title)
  }
  
)
###############################################################################
#            Class: Plot_Compare_iFDR_Confidence_1_Percent_TD_FDR
###############################################################################
Plot_Compare_iFDR_Confidence_1_Percent_TD_FDR = setRefClass("Plot_Compare_iFDR_Confidence_1_Percent_TD_FDR",
                                                            contains = "Plot_Image",
                                                            fields = list())
Plot_Compare_iFDR_Confidence_1_Percent_TD_FDR$methods(
  initialize = function( ...){
    plot_title <<- "Precursor Mass Discrepance i-FDR for 1% Target-Decoy FDR PSMs"
    callSuper(...)
  },
  data_processor = function(){
    return(data_processors[[1]])
  },
  get_n = function(){
    data_processor()$i_fdr$ensure()
    if (one_percent_calculation_exists()){
      i_fdr <- data_processor()$i_fdr$df
      data_subset <- subset(i_fdr, is_in_1percent==TRUE)
      n <- nrow(data_subset)
    } else {
      n <- 0
    }
    
    return (n)
  },
  plot_image = function(){
    if (one_percent_calculation_exists()){
      i_fdr        <- get_modified_fdr()
      report_good_discrepancies(i_fdr)
      data_TD_good <- get_data_TD_good(i_fdr)
      mean_results <- get_mean_results(data_TD_good)
      boxes        <- mean_results
      boxes        <- rename_columns(df = boxes, 
                                     names_before = c("min_conf", "max_conf", "lower"  , "upper"),
                                     names_after  = c("xleft"   , "xright"  , "ybottom", "ytop" ))
      xlim <- range(boxes[,c("xleft", "xright")])
      ylim <- range(boxes[,c("ybottom", "ytop")])
      
      #head(mean_results)
      
      xlab = "Confidence Score (Peptide Shaker)"
      ylab = "Mean PMD i-FDR"
      
      if (!include_text){
        xlab=""
        ylab=""
      }
      
      plot(mean_i_fdr~mean_conf, data=mean_results, xlim=xlim, ylim=ylim, xlab=xlab, ylab=ylab, main=main, xaxt="n", yaxt="n", cex=scale, lwd=scale)
      with(boxes, rect(xleft = xleft, ybottom = ybottom, xright = xright, ytop = ytop, lwd=scale))
      abline(b=-1, a=100, lwd=4*scale, col="dark gray")
      abline(h=0, v=100, lwd=1*scale)
      
    } else {
      stop(sprintf("Dataset '%s' does not include 1%% FDR data", data_processor()$info$collection_name()))
    }
  },
  get_mean_results = function(data_TD_good = NULL){
    mean_i_fdr <- aggregate(i_fdr~conf_group, data=data_TD_good, FUN=mean)
    mean_i_fdr <- rename_column(mean_i_fdr, "i_fdr", "mean_i_fdr")
    sd_i_fdr <- aggregate(i_fdr~conf_group, data=data_TD_good, FUN=sd)
    sd_i_fdr <- rename_column(sd_i_fdr, "i_fdr", "sd_i_fdr")
    n_i_fdr <- aggregate(i_fdr~conf_group, data=data_TD_good, FUN=length)
    n_i_fdr <- rename_column(n_i_fdr, "i_fdr", "n")
    mean_conf <- aggregate(PMD_FDR_input_score~conf_group, data=data_TD_good, FUN=mean)
    mean_conf <- rename_column(mean_conf, "PMD_FDR_input_score", "mean_conf")
    min_conf <- aggregate(PMD_FDR_input_score~conf_group, data=data_TD_good, FUN=min)
    min_conf <- rename_column(min_conf, "PMD_FDR_input_score", "min_conf")
    max_conf <- aggregate(PMD_FDR_input_score~conf_group, data=data_TD_good, FUN=max)
    max_conf <- rename_column(max_conf, "PMD_FDR_input_score", "max_conf")
    
    mean_results <-                     mean_i_fdr
    mean_results <- merge(mean_results, sd_i_fdr)
    mean_results <- merge(mean_results, n_i_fdr)
    mean_results <- merge(mean_results, mean_conf)
    mean_results <- merge(mean_results, min_conf)
    mean_results <- merge(mean_results, max_conf)
    
    mean_results$se    <- with(mean_results, sd_i_fdr / sqrt(n - 1))
    mean_results$lower <- with(mean_results, mean_i_fdr - 2*se)
    mean_results$upper <- with(mean_results, mean_i_fdr + 2*se)
    return(mean_results)
  },
  get_data_TD_good = function(i_fdr=NULL){
    data_TD_good <- subset(i_fdr, TD_good==TRUE)
    data_TD_good <- data_TD_good[order(data_TD_good$PMD_FDR_input_score),]
    n <- nrow(data_TD_good)
    data_TD_good$conf_group <- cut(1:n, breaks=floor(n/100))
    data_TD_good$i_fdr <- 100 * data_TD_good$i_fdr
    return(data_TD_good)
  },
  get_modified_fdr = function(){
    i_fdr <- data_processor()$i_fdr$df
    i_fdr$PMD_good  <- i_fdr$i_fdr < 0.01
    i_fdr$TD_good   <- i_fdr$is_in_1percent == TRUE
    i_fdr$conf_good <- i_fdr$PMD_FDR_input_score == 100
    return(i_fdr)
  },
  one_percent_calculation_exists = function(){
    data_processor()$raw_1_percent$ensure()
    return(data_processor()$raw_1_percent$exists())# "is_in_1percent" %in% colnames(data_processor()$i_fdr))
  },
  report_good_discrepancies = function(i_fdr=NULL){
    with(subset(i_fdr,                                        (PMD_FDR_decoy == 0)), print(table(TD_good, PMD_good)))
    with(subset(i_fdr, (PMD_FDR_input_score==100)                    & (PMD_FDR_decoy == 0)), print(table(TD_good, PMD_good)))
    with(subset(i_fdr, (PMD_FDR_input_score>= 99) & (PMD_FDR_input_score<100) & (PMD_FDR_decoy == 0)), print(table(TD_good, PMD_good)))
    with(subset(i_fdr, (PMD_FDR_input_score>= 99) & (PMD_FDR_input_score<100) & (PMD_FDR_decoy == 0)), print(table(TD_good, PMD_good)))
    with(subset(i_fdr, (PMD_FDR_input_score>= 90) & (PMD_FDR_input_score< 99) & (PMD_FDR_decoy == 0)), print(table(TD_good, PMD_good)))
  }
  
)

###############################################################################
#            Class: Plot_Density_PMD_by_Score
###############################################################################
Plot_Density_PMD_by_Score = setRefClass("Plot_Density_PMD_by_Score",
                                        contains = "Plot_Image",
                                        fields = list(show_norm = "logical"))
Plot_Density_PMD_by_Score$methods(
  initialize = function(p_show_norm=FALSE, ...){
    show_norm <<- p_show_norm
    plot_title <<- "PMD distribution, by Confidence ranges"
    callSuper(...)
    
  },
  data_processor = function(){
    return(data_processors[[1]])
  },
  get_n = function(){
    return(nrow(data_processor()$data_groups$df))
    #data_subset <- data_collection$i_fdr
    #return(nrow(data_subset))
  },
  get_modified_data_groups = function(var_value = NULL){
    # Note: Filters out used_to_find_middle
    # Note: Creates "value_of_interest" field
    # Note: Remakes "group_decoy_input_score" field
    data_new                   <- data_processor()$data_groups$df
    data_new                   <- subset(data_new, !used_to_find_middle )
    data_new$value_of_interest <- data_new[, var_value]
    
    cutoff_points <- c(100, 100, 95, 80, 50, 0, 0)
    n <- length(cutoff_points)
    uppers <- cutoff_points[-n]
    lowers <- cutoff_points[-1]
    
    for (i in 1:(n-1)){
      upper <- uppers[i]
      lower <- lowers[i]
      
      
      if (lower==upper){
        idx <- with(data_new, which(                        (PMD_FDR_input_score == upper) & (PMD_FDR_decoy == 0)))
        cat_name <- sprintf("%d", upper)
      } else {
        idx <- with(data_new, which((PMD_FDR_input_score >= lower) & (PMD_FDR_input_score <  upper) & (PMD_FDR_decoy == 0)))
        cat_name <- sprintf("%02d - %2d", lower, upper)
      }
      data_new$group_decoy_input_score[idx] <- cat_name
    }
    
    return(data_new)
  },
  plot_image = function(){
    
    # Support functions for plot_density_PMD_by_score()
    
    get_densities <- function(data_subset = NULL, var_value = NULL){
      
      # Support functions for get_densities()
      
      # New version
      
      # Main body of get_densities()
      
      data_subset <- get_modified_data_groups(var_value=var_value)
      #data_subset$value_of_interest <- data_subset[,var_value]
      from <- min(data_subset$value_of_interest, na.rm=TRUE)
      to   <- max(data_subset$value_of_interest, na.rm=TRUE)
      xlim = range(data_subset$value_of_interest, na.rm=TRUE)     
      
      groups   <- sort(unique(data_subset$group_decoy_input_score), decreasing = TRUE)
      n_groups <- length(groups)
      
      densities <- list(var_value = var_value, groups=groups)
      
      for (i in 1:n_groups){
        group <- groups[i]
        
        data_group_single  <- subset(data_subset, (group_decoy_input_score == group))
        d_group            <- with(data_group_single , density(value_of_interest, from = from, to = to, na.rm = TRUE))
        d_group            <- normalize_density(d_group)
        
        densities[[group]] <- d_group
      }
      
      return(densities)
      
    }
    get_xlim <- function(densities_a = NULL, densities_b = NULL){
      groups <- densities_a$groups
      
      xlim <- 0
      for (group in groups){
        xlim <- range(xlim, densities_a[[group]]$x, densities_b[[group]]$x)
      }
      
      return(xlim)
      
    }
    get_ylim <- function(densities_a = NULL, densities_b = NULL){
      groups <- densities_a$groups
      
      ylim <- 0
      for (group in groups){
        ylim <- range(ylim, densities_a[[group]]$y, densities_b[[group]]$y)
      }
      
      return(ylim)
      
    }
    plot_distributions <- function(densities = NULL, var_value= NULL,include_peak_dots=TRUE, xlab_modifier="", xlim=NULL, ylim=NULL, ...){
      data_groups <- get_modified_data_groups(var_value=var_value)
      groups      <- sort(unique(data_groups$group_decoy_input_score))
      n_groups    <- length(groups)
      
      groups_std   <- setdiff(groups, c("100", "decoy", "0") )
      groups_std   <- sort(groups_std, decreasing = TRUE)
      groups_std   <- c(groups_std, "0")
      n_std        <- length(groups_std)
      cols <- rainbow_with_fixed_intensity(n = n_std, goal_intensity_0_1 = 0.5, alpha=0.5)
      
      leg <- list(group = c("100"             , groups_std   , "decoy"                           ),
                  leg   = c("100"             , groups_std   , "All Decoys"                      ),
                  col   = c(col2hex("black")  , cols         , col2hex("purple", col_alpha = 0.5)), 
                  lwd   = c(4                 , rep(2, n_std), 4                                 ), 
                  title = "Confidence Score")
      
      xlab = sprintf("Precursor Mass Discrepancy%s (ppm)",
                     xlab_modifier)
      ylab = "Density"
      if (!include_text){
        xlab=""
        ylab=""
      }
      
      
      plot( x=xlim, y=ylim, col=leg$col[1], lwd=leg$lwd[1] * scale, main=main, xlab=xlab, ylab=ylab, xaxt="n", yaxt="n", cex=scale, type="n")#, lty=leg.lty[1], ...)
      
      include_peak_dots = FALSE # BUGBUG: Disabling this for now.  Need to move this to class parameter
      
      for (i in 1:length(leg$group)){
        group <- leg$group[i]
        d     <- densities[[group]]
        lines(d, col=leg$col[i], lwd=leg$lwd[i] * scale)
        if (include_peak_dots){
          x=d$x[which.max(d$y)]
          y=max(d$y)
          points(x=c(x,x), y=c(0,y), pch=19, col=leg$col[i], cex=scale)
        }
      }
      
      abline(v=0, lwd=scale)
      
      if (include_text){
        legend_object = Legend_Object$new(leg, scale)
        legend_object$show()
      }
      
    }
    
    # Main body for plot_density_PMD_by_score()
    
    data_groups <- data_processor()$data_groups$df
    
    data_subset_a <- subset(data_groups  , used_to_find_middle == FALSE)
    data_subset_b <- subset(data_subset_a, PMD_FDR_peptide_length > 11)
    
    densities_a <- get_densities(data_subset = data_subset_a, var_value = "value")        
    densities_b <- get_densities(data_subset = data_subset_b, var_value = "value_norm")
    
    xlim=get_xlim(densities_a, densities_b)
    ylim=get_ylim(densities_a, densities_b)
    
    dataset_name <- data_processor()$info$collection_name()
    if (show_norm){
      plot_distributions(densities=densities_b, var_value = "value_norm", xlab_modifier = " - normalized", xlim=xlim, ylim=ylim)
    } else {
      plot_distributions(densities=densities_a, var_value = "value"     , xlab_modifier = ""             , xlim=xlim, ylim=ylim)
    }
  }
)
###############################################################################
#            Class: Plot_Dataset_Description
###############################################################################
Plot_Dataset_Description = setRefClass("Plot_Dataset_Description",
                                       contains = "Plot_Multiple_Images",
                                       fields = list(ylim_time_invariance = "numeric"))
Plot_Dataset_Description$methods(
  initialize = function(p_data_processors = NULL, 
                        p_include_text=TRUE, 
                        p_include_main=FALSE,
                        p_ylim_time_invariance = c(-4,4), ...){
    plot_object_r1_c1 <- Plot_Time_Invariance_Alt$new(p_data_processors=p_data_processors, 
                                                      p_include_text=p_include_text, 
                                                      p_include_main=p_include_main,
                                                      p_training_class = "good_testing",
                                                      p_field_of_interest = "value",
                                                      p_ylim = p_ylim_time_invariance)
    
    plot_object_r1_c2 <- Plot_Time_Invariance_Alt$new(p_data_processors=p_data_processors, 
                                                      p_include_text=p_include_text, 
                                                      p_include_main=p_include_main,
                                                      p_training_class = "good_testing",
                                                      p_field_of_interest = "value_norm",
                                                      p_ylim = p_ylim_time_invariance)
    plot_object_r2_c1 <- Plot_Density_PMD_by_Score$new(p_data_processors=p_data_processors, 
                                                       p_show_norm=FALSE, 
                                                       p_include_text=p_include_text, 
                                                       p_include_main=p_include_main)
    
    plot_object_r2_c2 <- Plot_Density_PMD_and_Norm_Decoy_by_AA_Length$new(p_data_processors=p_data_processors, 
                                                                          p_show_norm=FALSE,
                                                                          p_include_text=p_include_text, 
                                                                          p_include_main=p_include_main)
    
    plot_object_r3_c1 <- Plot_Density_PMD_by_Score$new(p_data_processors=p_data_processors, 
                                                       p_show_norm=TRUE, 
                                                       p_include_text=p_include_text, 
                                                       p_include_main=p_include_main)
    plot_object_r3_c2 <- Plot_Density_PMD_and_Norm_Decoy_by_AA_Length$new(p_data_processors=p_data_processors, 
                                                                          p_show_norm=TRUE,
                                                                          p_include_text=p_include_text, 
                                                                          p_include_main=p_include_main)
    callSuper(p_n_images_wide=2, 
              p_n_images_tall=3, 
              p_include_text=p_include_text,
              p_include_main=p_include_main,
              p_image_list = list(plot_object_r1_c1, plot_object_r1_c2,
                                  plot_object_r2_c1, plot_object_r2_c2,
                                  plot_object_r3_c1, plot_object_r3_c2), ...)
    
  }
)
###############################################################################
#            Class: Plots_for_Paper
###############################################################################
Plots_for_Paper <- setRefClass("Plots_for_Paper", fields =list(data_processor_a = "Data_Processor",
                                                               data_processor_b = "Data_Processor",
                                                               data_processor_c = "Data_Processor",
                                                               data_processor_d = "Data_Processor",
                                                               include_text      = "logical",
                                                               include_main      = "logical", 
                                                               mai               = "numeric"))
Plots_for_Paper$methods(
  initialize = function(){
    data_processor_a <<- Data_Processor$new(p_info = Data_Object_Info_737_two_step$new())
    data_processor_b <<- Data_Processor$new(p_info = Data_Object_Info_737_combined$new())
    data_processor_c <<- Data_Processor$new(p_info = Data_Object_Pyrococcus_tr    $new())
    data_processor_d <<- Data_Processor$new(p_info = Data_Object_Mouse_Mutations  $new())
  },
  create_plots_for_paper = function(include_main=TRUE, finalize=TRUE){
    print_table_4_data()
    print_figure_2_data()
    plot_figure_D(p_scale=ifelse(finalize, 2, 1), p_include_main = include_main)
    plot_figure_C(p_scale=ifelse(finalize, 2, 1), p_include_main = include_main)
    plot_figure_B(p_scale=ifelse(finalize, 2, 1), p_include_main = include_main)
    plot_figure_A(p_scale=ifelse(finalize, 2, 1), p_include_main = include_main)
    plot_figure_8(p_scale=ifelse(finalize, 2, 1), p_include_main = include_main)
    plot_figure_7(p_scale=ifelse(finalize, 2, 1), p_include_main = include_main)
    plot_figure_6(p_scale=ifelse(finalize, 4, 1), p_include_main = include_main)
    plot_figure_5(p_scale=ifelse(finalize, 2, 1), p_include_main = include_main)
    plot_figure_4(p_scale=ifelse(finalize, 2, 1), p_include_main = include_main)
    plot_figure_3(p_scale=ifelse(finalize, 4, 1), p_include_main = include_main)
  },
  print_figure_2_data = function(){
    print(create_stats_for_grouping_figure(list(data_processor_a)))
  },
  print_table_4_data = function(){
    report_ranges_of_comparisons(processors = list(data_processor_a))
    report_ranges_of_comparisons(processors = list(data_processor_c))
  },
  plot_figure_3 = function(p_scale=NULL, p_include_main=NULL){
    plot_object <- Plot_Compare_PMD_and_Norm_Density$new(p_data_processor  = list(data_processor_a),
                                                         p_show_norm       = FALSE,
                                                         p_include_text    = TRUE,
                                                         p_include_main    = p_include_main,
                                                         p_display_n_psms  = FALSE)
    plot_object$plot_image_in_small_window(p_scale=p_scale)
  },
  plot_figure_4 = function(p_scale=NULL, p_include_main=NULL){
    plot_object <- Plot_Time_Invariance_Alt_Before_and_After$new(p_data_processors = list(data_processor_a), 
                                                                 p_include_text=TRUE, 
                                                                 p_include_main=p_include_main,
                                                                 p_ylim = c(-4,4))
    plot_object$plot_image_in_large_window(window_height=4, p_scale=p_scale)
    
  },
  plot_figure_5 = function(p_scale=NULL, p_include_main=NULL){
    plot_object <- Plot_Density_PMD_and_Norm_Decoy_by_AA_Length$new(p_data_processors = list(data_processor_a), 
                                                                    p_include_text=TRUE, 
                                                                    p_include_main=p_include_main)
    plot_object$plot_image_in_large_window(window_height=4, p_scale=p_scale)
  },
  plot_figure_6 = function(p_scale=NULL, p_include_main=NULL){
    plot_object <- Plot_Bad_CI$new(p_data_processors = list(data_processor_a), 
                                   p_include_text=TRUE, 
                                   p_include_main=p_include_main)
    plot_object$plot_image_in_small_window(p_scale=p_scale)
  },
  plot_figure_7 = function(p_scale=NULL, p_include_main=NULL){
    plot_object <- Plot_Compare_iFDR_Confidence_1_Percent_TD_FDR$new(p_data_processors = list(data_processor_a), 
                                                                     p_include_text=TRUE, 
                                                                     p_include_main=p_include_main)
    plot_object$plot_image_in_large_window(window_height=4, p_scale=p_scale)
  },
  plot_figure_8 = function(p_scale=NULL, p_include_main=NULL){
    plot_object <- Plot_Selective_Loss$new(p_data_processors = list(data_processor_c), 
                                           p_include_text=TRUE, 
                                           p_include_main=p_include_main)
    plot_object$plot_image_in_large_window(window_height=4, p_scale=p_scale)
  },
  plot_figure_A = function(p_scale=NULL, p_include_main=NULL){
    plot_object <- Plot_Dataset_Description$new(p_data_processors=list(data_processor_a), 
                                                p_include_text=TRUE,
                                                p_include_main=p_include_main,
                                                p_ylim_time_invariance=c(-4,4) )
    plot_object$plot_image_in_large_window(window_height=4, p_scale=p_scale)
  },
  plot_figure_B = function(p_scale=NULL, p_include_main=NULL){
    plot_object <- Plot_Dataset_Description$new(p_data_processors=list(data_processor_b), 
                                                p_include_text=TRUE,
                                                p_include_main=p_include_main,
                                                p_ylim_time_invariance=c(-4,4) )
    plot_object$plot_image_in_large_window(window_height=4, p_scale=p_scale)
  },
  plot_figure_C = function(p_scale=NULL, p_include_main=NULL){
    plot_object <- Plot_Dataset_Description$new(p_data_processors=list(data_processor_c), 
                                                p_include_text=TRUE,
                                                p_include_main=p_include_main,
                                                p_ylim_time_invariance=c(-4,4) )
    plot_object$plot_image_in_large_window(window_height=4, p_scale=p_scale)
  },
  plot_figure_D = function(p_scale=NULL, p_include_main=NULL){
    plot_object <- Plot_Dataset_Description$new(p_data_processors=list(data_processor_d), 
                                                p_include_text=TRUE,
                                                p_include_main=p_include_main,
                                                p_ylim_time_invariance=c(-4,4) )
    plot_object$plot_image_in_large_window(window_height=4, p_scale=p_scale)
  },
  create_stats_for_grouping_figure = function(processors=NULL){
    processor <- processors[[1]]
    processor$i_fdr$ensure()
    aug_i_fdr                      <- processor$i_fdr$df
    aug_i_fdr$group_good_bad_other <- gsub("_.*", "", aug_i_fdr$group_training_class) 
    aug_i_fdr$group_null           <- "all"
    table(aug_i_fdr$group_training_class)
    table(aug_i_fdr$group_good_bad_other)
    table(aug_i_fdr$group_null)
    
    create_agg_fdr_stats <- function(i_fdr=NULL, grouping_var_name = NULL){
      formula_fdr <- as.formula(sprintf("%s~%s", "i_fdr", grouping_var_name))
      formula_len <- as.formula(sprintf("%s~%s", "PMD_FDR_peptide_length", grouping_var_name))
      agg_fdr <- aggregate(formula=formula_fdr, data=i_fdr, FUN=mean)
      agg_n   <- aggregate(formula=formula_fdr, data=i_fdr, FUN=length)
      agg_len <- aggregate(formula=formula_len, data=i_fdr, FUN=mean)
      agg_fdr <- rename_columns(df = agg_fdr, 
                                names_before = c(grouping_var_name, "i_fdr"), 
                                names_after  = c("group"          , "fdr"))
      agg_n   <- rename_columns(df = agg_n, 
                                names_before = c(grouping_var_name, "i_fdr"), 
                                names_after  = c("group"          , "n"))
      agg_len <- rename_columns(df = agg_len, 
                                names_before = c(grouping_var_name), 
                                names_after  = c("group"          ))
      agg <- merge(agg_fdr, agg_n)
      agg <- merge(agg    , agg_len)
      
      return(agg)
    }
    
    agg_detail  <- create_agg_fdr_stats(i_fdr = aug_i_fdr, grouping_var_name = "group_training_class")
    agg_grouped <- create_agg_fdr_stats(i_fdr = aug_i_fdr, grouping_var_name = "group_good_bad_other")
    agg_all     <- create_agg_fdr_stats(i_fdr = aug_i_fdr, grouping_var_name = "group_null")
    
    agg <- rbind(agg_detail, agg_grouped)
    agg <- rbind(agg, agg_all)
    
    agg$fdr <- ifelse(agg$fdr < 1, agg$fdr, 1)
    
    linear_combo <- function(x=NULL, a0=NULL, a1=NULL){
      result <- (a0 * (1-x) + a1 * x)
      return(result)
    }
    
    agg$r <- linear_combo(agg$fdr, a0=197, a1= 47)
    agg$g <- linear_combo(agg$fdr, a0= 90, a1= 85)
    agg$b <- linear_combo(agg$fdr, a0= 17, a1=151)
    
    return(agg)
  },
  report_ranges_of_comparisons = function(processors=NULL){
    report_comparison_of_Confidence_and_PMD = function (i_fdr = NULL, min_conf=NULL, max_conf=NULL, include_max=FALSE){
      report_PMD_confidence_comparison_from_subset = function(data_subset=NULL, group_name=NULL){
        print(group_name)
        print(sprintf("    Number of PSMs: %d", nrow(data_subset)))
        mean_confidence <- mean(data_subset$PMD_FDR_input_score)
        print(sprintf("    Mean Confidence Score: %3.1f", mean_confidence))
        print(sprintf("    PeptideShaker g-FDR: %3.1f", 100-mean_confidence))
        mean_PMD_FDR = mean(data_subset$i_fdr)
        print(sprintf("    PMD g-FDR: %3.1f", 100*mean_PMD_FDR))
        #col <- col2hex("black", 0.2)
        #plot(data_subset$i_fdr, pch=".", cex=2, col=col)
        #abline(h=0)
      }
      
      if (is.null(max_conf)) {
        data_subset <- subset(i_fdr, PMD_FDR_input_score == min_conf)
        group_name <- sprintf("Group %d", min_conf)
      } else if (include_max){
        data_subset <- subset(i_fdr, (PMD_FDR_input_score >= min_conf) & (PMD_FDR_input_score <= max_conf))
        group_name <- sprintf("Group %d through %d", min_conf, max_conf)
      } else {
        data_subset <- subset(i_fdr, (PMD_FDR_input_score >= min_conf) & (PMD_FDR_input_score < max_conf))
        group_name <- sprintf("Group %d to %d", min_conf, max_conf)
      }
      
      report_PMD_confidence_comparison_from_subset(data_subset=data_subset, group_name=group_name)
    }
    
    processor <- processors[[1]]
    processor$i_fdr$ensure()
    i_fdr <- processor$i_fdr$df
    info  <- processor$info
    print(sprintf("PMD and Confidence comparison for -- %s",  info$collection_name()))
    report_comparison_of_Confidence_and_PMD(i_fdr = i_fdr, min_conf=100, max_conf=NULL, include_max=TRUE)
    report_comparison_of_Confidence_and_PMD(i_fdr = i_fdr, min_conf= 99, max_conf=100 , include_max=FALSE)
    report_comparison_of_Confidence_and_PMD(i_fdr = i_fdr, min_conf= 90, max_conf= 99 , include_max=FALSE)
    report_comparison_of_Confidence_and_PMD(i_fdr = i_fdr, min_conf=  0, max_conf=100 , include_max=TRUE)
  }
)
###############################################################################
# C - 021 - PMD-FDR Wrapper - functions.R                                     #
#                                                                             #
# Creates the necessary structure to convert the PMD-FDR code into one that   #
# can run as a batch file                                                     #
#                                                                             #
###############################################################################
###############################################################################
#            Class: ModuleArgParser_PMD_FDR
###############################################################################
ModuleArgParser_PMD_FDR <- setRefClass("ModuleArgParser_PMD_FDR", 
                                       contains = c("ArgParser"),
                                       fields =list(args = "character") )
ModuleArgParser_PMD_FDR$methods(
  initialize = function(description = "Computes individual and global FDR using Precursor Mass Discrepancy (PMD-FDR)", ...){
    callSuper(description=description, ...)
    local_add_argument("--psm_report"          ,                                 help="full name and path to the PSM report")
    local_add_argument("--psm_report_1_percent", default = ""                  , help="full name and path to the PSM report for 1% FDR")
    local_add_argument("--output_i_fdr"        , default = ""                  , help="full name and path to the i-FDR output file ")
    local_add_argument("--output_g_fdr"        , default = ""                  , help="full name and path to the g-FDR output file ")
    local_add_argument("--output_densities"    , default = ""                  , help="full name and path to the densities output file ")
    #local_add_argument("--score_field_name"    , default = ""                  , help="name of score field (in R format)")
    local_add_argument("--input_file_type"     , default = "PMD_FDR_input_file", help="type of input file (currently supports: PMD_FDR_file_type, PSM_Report, MaxQuant_Evidence)")
  }
)###############################################################################
#            Class: Data_Object_Parser
###############################################################################
Data_Object_Parser <- setRefClass("Data_Object_Parser", 
                                  contains = c("Data_Object"),
                                  fields =list(parser = "ModuleArgParser_PMD_FDR",
                                               args = "character",
                                               parsing_results = "list") )
Data_Object_Parser$methods(
  initialize = function(){
    callSuper()
    class_name <<- "Data_Object_Parser"
  },
  verify = function(){
    # Nothing to do here - parser handles verification during load
  },
  m_load_data = function(){
    if (length(args) == 0){
      parsing_results <<- parser$parse_arguments(NULL)
    } else {
      parsing_results <<- parser$parse_arguments(args)
    }
    
  },
  set_args = function(p_args=NULL){ 
    # This is primarily used for testing.  In operation arguments will be passed automatically (through use of commandArgs)
    args <<- p_args
    set_dirty(TRUE)
  }
)
###############################################################################
#            Class: Data_Object_Info_Parser
###############################################################################
Data_Object_Info_Parser <- setRefClass("Data_Object_Info_Parser", 
                                       contains = c("Data_Object_Info"),
                                       fields =list(
                                         output_i_fdr = "character",
                                         output_g_fdr = "character",
                                         output_densities = "character"
                                       ) )
Data_Object_Info_Parser$methods(
  initialize = function(){
    callSuper()
    class_name <<- "Data_Object_Info_Parser"
  },
  verify = function(){
    check_field_exists = function(field_name=NULL, check_empty = TRUE){
      field_value <- get_parser()$parsing_results[field_name]
      checkTrue(! is.null(field_value),
                msg = sprintf("Parameter %s was not passed to PMD_FDR", field_value))
      if (check_empty){
        checkTrue(! is.null(field_value),
                  msg = sprintf("Parameter %s was not passed to PMD_FDR", field_value))
      }
    }
    # Check parameters passed in
    check_field_exists("junk")
    check_field_exists("psm_report")
    check_field_exists("psm_report_1_percent", check_empty = FALSE)
    check_field_exists("output_i_fdr"        , check_empty = FALSE)
    check_field_exists("output_g_fdr"        , check_empty = FALSE)
    check_field_exists("output_densities"    , check_empty = FALSE)
    #check_field_exists("score_field_name")
    check_field_exists("input_file_type")
  },
  m_load_data = function(){
    parsing_results <- get_parser()$parsing_results
    
    data_file_name               <<- as.character(parsing_results["psm_report"])
    data_file_name_1_percent_FDR <<- as.character(parsing_results["psm_report_1_percent"])
    data_path_name               <<- as.character(parsing_results[""])
    #experiment_name              <<- data_file_name
    #designation                  <<- ""
    output_i_fdr                 <<- as.character(parsing_results["output_i_fdr"])
    output_g_fdr                 <<- as.character(parsing_results["output_g_fdr"])
    output_densities             <<- as.character(parsing_results["output_densities"])
    
    input_file_type              <<- as.character(parsing_results["input_file_type"])
    #score_field_name             <<- as.character(parsing_results["score_field_name"])
  },
  set_parser = function(parser){
    parents[["parser"]] <<- parser
  },
  get_parser = function(){
    return(verified_element_of_list(parents, "parser", "Data_Object_Info_Parser$parents"))
  },
  file_path = function(){
    result <- data_file_name # Now assumes that full path is provided
    if (length(result) == 0){
      stop("Unable to validate file path - file name is missing")
    }
    return(result)
  },
  file_path_1_percent_FDR = function(){
    local_file_name <- get_data_file_name_1_percent_FDR()
    if (length(local_file_name) == 0){
      result <- ""
    } else {
      result <- local_file_name # path name is no longer relevant
    }
    
    # Continue even if file name is missing - not all analyses have a 1 percent FDR file; this is managed downstream
    
    # if (length(result) == 0){
    #   stop("Unable to validate file path - one or both of path name and file name (of 1 percent FDR file) are missing")
    # }
    return(result)
  },
  get_data_file_name_1_percent_FDR = function(){
    return(data_file_name_1_percent_FDR)
  },
  collection_name = function(){
    result <- ""
    return(result)
  }
  
)
###############################################################################
#            Class: Processor_PMD_FDR_for_Galaxy
# Purpose: Wrapper on tools from Project 019 to enable a Galaxy-based interface
###############################################################################
Processor_PMD_FDR_for_Galaxy <- setRefClass("Processor_PMD_FDR_for_Galaxy", 
                                            fields = list(
                                              parser         = "Data_Object_Parser",
                                              info           = "Data_Object_Info_Parser",
                                              raw_data       = "Data_Object_Raw_Data",
                                              raw_1_percent  = "Data_Object_Raw_1_Percent",
                                              data_converter = "Data_Object_Data_Converter",
                                              data_groups    = "Data_Object_Groupings",
                                              densities      = "Data_Object_Densities",
                                              alpha          = "Data_Object_Alpha",
                                              i_fdr          = "Data_Object_Individual_FDR"
                                            ))
Processor_PMD_FDR_for_Galaxy$methods(
  initialize = function(){
    # This initialization defines all of the dependencies between the various components
    # (Unfortunately, inheriting from Data_Processor leads to issues - I had to reimplement it here with a change to "info")
    
    # info
    info$set_parser(parser)
    parser$append_child(info)
    
    # raw_data
    raw_data$set_info(info)
    info$append_child(raw_data)
    
    # raw_1_percent
    raw_1_percent$set_info(info)
    info$append_child(raw_1_percent)
    
    # data_converter
    data_converter$set_info    (info)
    data_converter$set_raw_data(raw_data)
    info         $append_child (data_converter)
    raw_data     $append_child (data_converter)
    
    # data_groups
    data_groups$set_info          (info)
    data_groups$set_data_converter(data_converter)
    data_groups$set_raw_1_percent (raw_1_percent)
    info          $append_child   (data_groups)
    data_converter$append_child   (data_groups)
    raw_1_percent $append_child   (data_groups)
    
    # densities
    densities  $set_data_groups(data_groups)
    data_groups$append_child   (densities)
    
    # alpha
    alpha    $set_densities(densities)
    densities$append_child (alpha)
    
    # i_fdr
    i_fdr$set_data_groups(data_groups)
    i_fdr$set_densities  (densities)
    i_fdr$set_alpha      (alpha)
    data_groups  $append_child(i_fdr)
    densities    $append_child(i_fdr)
    alpha        $append_child(i_fdr)
    
  },
  compute = function(){
    #i_fdr is currently the lowest level object - it ultimately depends on everything else.
    i_fdr$ensure() # All pieces on which i_fdr depends are automatically verified and computed (through their verify() and ensure())
    
    save_standard_df(x = densities$df, file_path = info$output_densities)
    save_standard_df(x =     alpha$df, file_path = info$output_g_fdr)
    save_standard_df(x =     i_fdr$df, file_path = info$output_i_fdr)
  }
)
###############################################################################
# D - 021 - PMD-FDR Main.R                                                    #
#                                                                             #
# File Description: Contains the base code that interprets the parameters     #
#                   and computes i-FDR and g-FDR for a mass spec project      #
#                                                                             #
###############################################################################
argv <- commandArgs(TRUE) # Saves the parameters (command code)

processor <- Processor_PMD_FDR_for_Galaxy$new()
processor$parser$set_args(argv)
processor$compute()

