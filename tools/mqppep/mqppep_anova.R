#!/usr/bin/env Rscript
# libraries
library(optparse)
library(stringr)
library(tinytex)

# ref for parameterizing Rmd document: https://stackoverflow.com/a/37940285

# parse options
option_list <- list(

  # files
  make_option(
    c("-a", "--alphaFile"),
    action = "store",
    default = NA,
    type = "character",
    help = paste0("List of alpha cutoff values for significance testing;",
             " path to text file having one column and no header")
  ),
  make_option(
    c("-M", "--anova_ksea_metadata"),
    action = "store",
    default = "anova_ksea_metadata.tsv",
    type = "character",
    help = "Phosphopeptide metadata, ANOVA FDR, and KSEA enribhments"
  ),
  make_option(
    c("-o", "--imputedDataFile"),
    action = "store",
    default = "output_imputed.tsv",
    type = "character",
    help = "Imputed Phosphopeptide Intensities output file path"
  ),
  make_option(
    c("-n", "--imputedQNLTDataFile"),
    action = "store",
    default = "output_imp_qn_lt.tsv",
    type = "character",
    help =
      paste(
        "Imputed, Quantile-Normalized Log-Transformed Phosphopeptide",
        "Intensities output file path"
        )
  ),
  make_option(
    c("-i", "--inputFile"),
    action = "store",
    default = NA,
    type = "character",
    help = "Phosphopeptide Intensities sparse input file path"
  ),
  make_option(
    c("-K", "--ksea_sqlite"),
    action = "store",
    default = NA,
    type = "character",
    help = "Path to 'ksea_sqlite' output produced by this tool"
  ),
  make_option(
    c("-S", "--preproc_sqlite"),
    action = "store",
    default = NA,
    type = "character",
    help = "Path to 'preproc_sqlite' produced by `mqppep_mrgfltr.py`"
  ),
  make_option(
    c("-r", "--reportFile"),
    action = "store",
    default = "mqppep_anova.pdf",
    type = "character",
    help = "PDF report file path"
  ),

  # parameters
  make_option(
    c("-f", "--firstDataColumn"),
    action = "store",
    default = "^Intensity[^_]",
    type = "character",
    help = "First column of intensity values"
  ),
  make_option(
    c("-m", "--imputationMethod"),
    action = "store",
    default = "random",
    type = "character",
    help = paste0("Method for missing-value imputation,",
             " one of c('group-median','median','mean','random')")
  ),
  make_option(
    c("-C", "--intensityMinValuesPerClass"),
    action = "store",
    default = "0",
    type = "integer",
    help = "Minimum number of observed values per class"
  ),
  make_option(
    c("-k", "--ksea_cutoff_statistic"),
    action = "store",
    default = "FDR",
    type = "character",
    help = paste0("Method for missing-value imputation,",
      " one of c('FDR','p.value'), but don't expect 'p.value' to work well.")
  ),
  make_option(
    c("-t", "--ksea_cutoff_threshold"),
    action = "store",
    default = 0.05,
    type = "double",
    help = paste0(
      "Maximum score to be used to score a kinase enrichment as significant")
  ),
  make_option(
    c("-c", "--kseaMinSubstrateCount"),
    action = "store",
    default = "1",
    type = "integer",
    help = "Minimum number of substrates to consider any kinase for KSEA"
  ),
  make_option(
    c("--kseaUseAbsoluteLog2FC"),
    action = "store_true",
    default = "FALSE",
    type = "logical",
    help = paste0("Should abs(log2(fold-change)) be used for KSEA?",
                  " (TRUE may alter number of hits.)")
  ),
  make_option(
    c("-p", "--meanPercentile"),
    action = "store",
    default = 3,
    type = "integer",
    help = paste0("Mean percentile for randomly generated imputed values;",
              ", range [1,99]")
  ),
  make_option(
    c("--minQuality"),
    action = "store",
    default = 0,
    type = "integer",
    help = paste0("Minimum quality (higher value reduces number of substrates",
              " accepted; you may want to keep below 100), range [0,infinity]")
  ),
  make_option(
    c("--oneWayManyCategories"),
    action = "store",
    default = "aov",
    type = "character",
    help = "Name of R function for one-way tests among more than two categories"
  ),
  make_option(
    c("--oneWayTwoCategories"),
    action = "store",
    default = "two.way",
    type = "character",
    help = "Name of R function for one-way tests between two categories"
  ),
  make_option(
    c("-s", "--regexSampleNames"),
    action = "store",
    default = "\\.(\\d+)[A-Z]$",
    type = "character",
    help = "Regular expression extracting sample-names"
  ),
  make_option(
    c("-g", "--regexSampleGrouping"),
    action = "store",
    default = "(\\d+)",
    type = "character",
    help = paste0("Regular expression extracting sample-group",
             " from an extracted sample-name")
  ),
  make_option(
    c("-d", "--sdPercentile"),
    action = "store",
    default = 3,
    type = "double",
    help = paste0("Adjustment value for standard deviation of",
              " randomly generated imputed values; real")
  ),
  make_option(
    c("-F", "--sampleGroupFilter"),
    action = "store",
    default = "none",
    type = "character",
    help = paste0("Should no filter be applied to sample group names (none)",
             " or should the filter specify samples to include or exclude?")
  ),
  make_option(
    c("--sampleGroupFilterMode"),
    action = "store",
    default = "r",
    type = "character",
    help = paste0("First character ('f', 'p', or 'r') indicating regular",
      "expression matching mode ('fixed', 'perl', or 'grep'; ",
      "see https://rdrr.io/r/base/grep.html).  Second character may be 'i;",
      "to make search ignore case.")
  ),
  make_option(
    c("-G", "--sampleGroupFilterPatterns"),
    action = "store",
    default = ".*",
    type = "character",
    help = paste0("Regular expression extracting sample-group",
             " from an extracted sample-name")
  )
)

tryCatch(
  args <- parse_args(
    OptionParser(
      option_list = option_list,
      add_help_option = TRUE
    ),
    print_help_and_exit = TRUE
  ),
  error = function(e) {
    parse_args(
      OptionParser(
        option_list = option_list,
        add_help_option = TRUE
      ),
      print_help_and_exit = TRUE
    )
    stop(as.character(e))
  }
)
print("args is:")
cat(str(args))

# Check parameter values

if (! file.exists(args$inputFile)) {
  stop((paste("Input file", args$inputFile, "does not exist")))
}

# files
alpha_file                     <- args$alphaFile
anova_ksea_metadata_file       <- args$anova_ksea_metadata
imp_qn_lt_data_file            <- args$imputedQNLTDataFile
imputed_data_file              <- args$imputedDataFile
input_file                     <- args$inputFile
ksea_sqlite_file               <- args$ksea_sqlite
preproc_sqlite_file            <- args$preproc_sqlite
report_file_name               <- args$reportFile

# parameters
# firstDataColumn - see below
group_filter                   <- args$sampleGroupFilter
group_filter_mode              <- args$sampleGroupFilterMode
# imputationMethod - see below
intensity_min_values_per_class <- args$intensityMinValuesPerClass
ksea_cutoff_statistic          <- args$ksea_cutoff_statistic
ksea_cutoff_threshold          <- args$ksea_cutoff_threshold
ksea_min_substrate_count       <- args$kseaMinSubstrateCount
ksea_use_absolute_log2_fc      <- args$kseaUseAbsoluteLog2FC
# mean_percentile - see below
min_quality                    <- args$minQuality
# regexSampleNames - see below
# regexSampleGrouping - see below
# sampleGroupFilterPatterns - see below (becomes group_filter_patterns)
# sd_percentile - see below

if (
  sum(
    grepl(
      pattern = ksea_cutoff_statistic,
      x = c("FDR", "p.value")
      )
    ) < 1
  ) {
    print(sprintf(
      "bad ksea_cutoff_statistic argument: %s", ksea_cutoff_statistic))
    return(-1)
    }

imputation_method <- args$imputationMethod
if (
  sum(
    grepl(
      pattern = imputation_method,
      x = c("group-median", "median", "mean", "random")
      )
    ) < 1
  ) {
    print(sprintf("bad imputationMethod argument: %s", imputation_method))
    return(-1)
    }

# read with default values, when applicable
mean_percentile <- args$meanPercentile
sd_percentile   <- args$sdPercentile
# in the case of 'random" these values are ignored by the client script
if (imputation_method == "random") {
  print("mean_percentile is:")
  cat(str(mean_percentile))

  print("sd_percentile is:")
  cat(str(mean_percentile))
}

# convert string parameters that are passed in via config files:
#  - firstDataColumn
#  - regexSampleNames
#  - regexSampleGrouping
read_config_file_string <- function(fname, limit) {
  cat(sprintf("read_config_file_string: fname = '%s'\n", fname))
  cat(sprintf("length(fname) = '%s'\n", length(fname)))
  result <-
    if (file.exists(fname)) {
      cat(sprintf("reading '%s' ...\n", fname))
      readChar(fname, limit)
    } else {
      cat(sprintf("not a file: '%s'\n", fname))
      fname
    }
  # eliminate any leading whitespace
  result <- gsub("^[ \t\n]*", "",   result)
  # eliminate any trailing whitespace
  result <- gsub("[ \t\n]*$", "",   result)
  # substitute characters escaped by Galaxy sanitizer
  result <- gsub("__lt__",    "<",  result)
  result <- gsub("__le__",    "<=", result)
  result <- gsub("__eq__",    "==", result)
  result <- gsub("__ne__",    "!=", result)
  result <- gsub("__gt__",    ">",  result)
  result <- gsub("__ge__",    ">=", result)
  result <- gsub("__sq__",    "'",  result)
  result <- gsub("__dq__",    '"',  result)
  result <- gsub("__ob__",    "[",  result)
  result <- gsub("__cb__",    "]",  result)
}
nc <- 1000

sink(stderr())

cat(paste0("first_data_column file: ", args$firstDataColumn, "\n"))
first_data_column <- read_config_file_string(args$firstDataColumn,  nc)
cat(paste0("first_data_column: ",     first_data_column,     "\n"))

cat(paste0("regex_sample_grouping file: ", args$regexSampleGrouping, "\n"))
regex_sample_grouping <- read_config_file_string(args$regexSampleGrouping, nc)
cat(paste0("regex_sample_grouping: ", regex_sample_grouping, "\n"))

cat(paste0("regex_sample_names file: ", args$regexSampleNames, "\n"))
regex_sample_names <- read_config_file_string(args$regexSampleNames, nc)
cat(paste0("regex_sample_names: ",    regex_sample_names,    "\n"))

if (group_filter != "none") {
  cat(paste0("group_filter_patterns file: '",
             args$sampleGroupFilterPatterns, "'\n"))
  group_filter_patterns <-
    read_config_file_string(args$sampleGroupFilterPatterns, nc)
} else {
  group_filter_patterns <- ".*"
}
cat(paste0("group_filter_patterns: ", group_filter_patterns, "\n"))

sink()


# from: https://github.com/molgenis/molgenis-pipelines/wiki/
#   How-to-source-another_file.R-from-within-your-R-script
# Function location_of_this_script returns the location of this .R script
#   (may be needed to source other files in same dir)
location_of_this_script <- function() {
    this_file <- NULL
    # This file may be 'sourced'
    for (i in - (1:sys.nframe())) {
        if (identical(sys.function(i), base::source)) {
            this_file <- (normalizePath(sys.frame(i)$ofile))
        }
    }

    if (!is.null(this_file)) return(dirname(this_file))

    # But it may also be called from the command line
    cmd_args <- commandArgs(trailingOnly = FALSE)
    cmd_args_trailing <- commandArgs(trailingOnly = TRUE)
    cmd_args <- cmd_args[
      seq.int(
        from = 1,
        length.out = length(cmd_args) - length(cmd_args_trailing)
        )
      ]
    res <- gsub("^(?:--file=(.*)|.*)$", "\\1", cmd_args)

    # If multiple --file arguments are given, R uses the last one
    res <- tail(res[res != ""], 1)
    if (0 < length(res)) return(dirname(res))

    # Both are not the case. Maybe we are in an R GUI?
    return(NULL)
}

# validation of input parameters is complete; it is now justifiable to
#   install LaTeX tools to render markdown as PDF; this involves a big
#   download from GitHub
if (!tinytex::is_tinytex()) tinytex::install_tinytex()

rmarkdown_params <- list(

    # files
    alphaFile = alpha_file
  , anovaKseaMetadata = anova_ksea_metadata_file
  , imputedDataFilename = imputed_data_file
  , imputedQNLTDataFile = imp_qn_lt_data_file
  , inputFile = input_file
  , kseaAppPrepDb = ksea_sqlite_file
  , preprocDb = preproc_sqlite_file

    # parameters
  , firstDataColumn = first_data_column
  , groupFilter = group_filter
  , groupFilterMode = group_filter_mode         # arg sampleGroupFilterMode
  , groupFilterPatterns = group_filter_patterns # arg sampleGroupFilterPatterns
  , imputationMethod = imputation_method
  , intensityMinValuesPerGroup = intensity_min_values_per_class
  , kseaCutoffStatistic = ksea_cutoff_statistic
  , kseaCutoffThreshold = ksea_cutoff_threshold
  , kseaMinSubstrateCount = ksea_min_substrate_count
  , kseaUseAbsoluteLog2FC = ksea_use_absolute_log2_fc # add
  , meanPercentile = mean_percentile
  , minQuality = min_quality                          # add
  , regexSampleGrouping = regex_sample_grouping
  , regexSampleNames = regex_sample_names
  , sdPercentile = sd_percentile
  )

print("rmarkdown_params")
print(rmarkdown_params)
print(
  lapply(
    X = rmarkdown_params,
    FUN = function(x) {
      paste0(
        nchar(as.character(x)),
        ": '",
        as.character(x),
        "'"
      )
    }
  )
)


# freeze the random number generator so the same results will be produced
#  from run to run
set.seed(28571)

script_dir <-  location_of_this_script()

rmarkdown::render(
  input = paste(script_dir, "mqppep_anova_script.Rmd", sep = "/")
, output_file = report_file_name
, params = rmarkdown_params
, output_format = rmarkdown::pdf_document(
    includes = rmarkdown::includes(in_header = "mqppep_anova_preamble.tex")
  , dev = "pdf"
  , toc = TRUE
  , toc_depth = 2
  , number_sections = FALSE
  )
)
