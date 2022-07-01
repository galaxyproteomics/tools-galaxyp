#!/usr/bin/env Rscript

# This is the implementation for the
#   "MaxQuant Phosphopeptide Localization Probability Cutoff"
#   Galaxy tool (mqppep_lclztn_filter)
# It is adapted from the MaxQuant Processing Script written by Larry Cheng.

# libraries
library(optparse)
library(data.table)
library(stringr)
library(ggplot2)

# title: "MaxQuant Processing Script"
# author: "Larry Cheng"
# date: "February 19, 2018"
#
# # MaxQuant Processing Script
# Takes MaxQuant Phospho (STY)sites.txt file as input
# and performs the following (in order):
# 1) Runs the Proteomics Quality Control software
# 2) Remove contaminant and reverse sequence rows
# 3) Filters rows based on localization probability
# 4) Extract the quantitative data
# 5) Sequences phosphopeptides
# 6) Merges multiply phosphorylated peptides
# 7) Filters out phosphopeptides based on enrichment
# The output file contains the phosphopeptide (first column)
# and the quantitative values for each sample.
#
# ## Revision History
# Rev. 2022-02-10 :wrap for inclusion in Galaxy
# Rev. 2018-02-19 :break up analysis script into "MaxQuant Processing Script"
#                  and "Phosphopeptide Processing Script"
# Rev. 2017-12-12 :added PTXQC
#                  added additional plots and table outputs for quality control
#                  allowed for more than 2 samples to be grouped together
#                  (up to 26 (eg, 1A, 1B, 1C, etc))
#                  converted from .r to .rmd file to knit report
#                  for quality control
# Rev. 2016-09-11 :automated the FDR cutoffs; removed the option to data
#                  impute multiple times
# Rev. 2016-09-09 :added filter to eliminate contaminant & reverse sequence rows
# Rev. 2016-09-01 :moved the collapse step from after ANOVA filter to prior to
#                  preANOVA file output
# Rev. 2016-08-22 :use regexSampleNames <- "\\.(\\d + )[AB]$"
#                  so that it looks at the end of string
# Rev. 2016-08-05 :Removed vestigial line (ppeptides <- ....)
# Rev. 2016-07-03 :Removed row names from the write.table() output for
#                  ANOVA and PreANOVA
# Rev. 2016-06-25 :Set default Localization Probability cutoff to 0.75
# Rev. 2016-06-23 :fixed a bug in filtering for pY enrichment by resetting
#                  the row numbers afterwards
# Rev. 2016-06-21 :test18 + standardized the regexpression in protocol


### FUNCTION DECLARATIONS begin ----------------------------------------------

# Read first line of file at filePath
# adapted from: https://stackoverflow.com/a/35761217/15509512
read_first_line <- function(filepath) {
  con <- file(filepath, "r")
  line <- readLines(con, n = 1)
  close(con)
  return(line)
}

# Move columns to the end of dataframe
# - data: the dataframe
# - move: a vector of column names, each of which is an element of names(data)
movetolast <- function(data, move) {
  data[c(setdiff(names(data), move), move)]
}

# Generate phosphopeptide and build list when applied
phosphopeptide_func <- function(df) {
  # generate peptide sequence and list of phosphopositions
  phosphoprobsequence <-
    strsplit(as.character(df["Phospho (STY) Score diffs"]), "")[[1]]
  output <- vector()
  phosphopeptide <- ""
  counter <- 0 # keep track of position in peptide
  phosphopositions <-
    vector() # keep track of phosphorylation positions in peptide
  score_diff <- ""
  for (chara in phosphoprobsequence) {
    # build peptide sequence
    if (!(
      chara == " " ||
      chara == "(" ||
      chara == ")" ||
      chara == "." ||
      chara == "-" ||
      chara == "0" ||
      chara == "1" ||
      chara == "2" ||
      chara == "3" ||
      chara == "4" ||
      chara == "5" ||
      chara == "6" ||
      chara == "7" ||
      chara == "8" ||
      chara == "9")
    ) {
      phosphopeptide <- paste(phosphopeptide, chara, sep = "")
      counter <- counter + 1
    }
    # generate score_diff
    if (chara == "-" ||
        chara == "." ||
        chara == "0" ||
        chara == "1" ||
        chara == "2" ||
        chara == "3" ||
        chara == "4" ||
        chara == "5" ||
        chara == "6" ||
        chara == "7" ||
        chara == "8" ||
        chara == "9"
    ) {
      score_diff <- paste(score_diff, chara, sep = "")
    }
    # evaluate score_diff
    if (chara == ")") {
      score_diff <- as.numeric(score_diff)
      # only consider a phosphoresidue if score_diff > 0
      if (score_diff > 0) {
        phosphopositions <- append(phosphopositions, counter)
      }
      score_diff <- ""
    }
  }

  # generate phosphopeptide sequence (ie, peptide sequence with "p"'s)
  counter <- 1
  phosphoposition_correction1 <-
    -1 # used to correct phosphosposition as "p"'s
       #  are inserted into the phosphopeptide string
  phosphoposition_correction2 <-
    0  # used to correct phosphosposition as "p"'s
       #   are inserted into the phosphopeptide string
  while (counter <= length(phosphopositions)) {
    phosphopeptide <-
      paste(
        substr(
          phosphopeptide,
          0,
          phosphopositions[counter] + phosphoposition_correction1
        ),
        "p",
        substr(
          phosphopeptide,
          phosphopositions[counter] + phosphoposition_correction2,
          nchar(phosphopeptide)
        ),
        sep = ""
      )
    counter <- counter + 1
    phosphoposition_correction1 <- phosphoposition_correction1 + 1
    phosphoposition_correction2 <- phosphoposition_correction2 + 1
  }
  # building phosphopeptide list
  output <- append(output, phosphopeptide)
  return(output)
}

### FUNCTION DECLARATIONS end ------------------------------------------------


### EXTRACT ARGUMENTS begin --------------------------------------------------

# parse options
option_list <- list(
  make_option(
    c("-i", "--input"),
    action = "store",
    type = "character",
    help = "A MaxQuant Phospho (STY)Sites.txt"
  )
  ,
  make_option(
    c("-o", "--output"),
    action = "store",
    type = "character",
    help = "path to output file"
  )
  ,
  make_option(
    c("-E", "--enrichGraph"),
    action = "store",
    type = "character",
    help = "path to enrichment graph PDF"
  )
  ,
  make_option(
    c("-F", "--enrichGraph_svg"),
    action = "store",
    type = "character",
    help = "path to enrichment graph SVG"
  )
  ,
  make_option(
    c("-L", "--locProbCutoffGraph"),
    action = "store",
    type = "character",
    help = "path to location-proability cutoff graph PDF"
  )
  ,
  make_option(
    c("-M", "--locProbCutoffGraph_svg"),
    action = "store",
    type = "character",
    help = "path to location-proability cutoff graph SVG"
  )
  ,
  make_option(
    c("-e", "--enriched"),
    action = "store",
    type = "character",
    help = "pY or pST enriched samples (ie, 'Y' or 'ST')"
  )
  # default = "^Number of Phospho [(]STY[)]$",
  ,
  make_option(
    c("-p", "--phosphoCol"),
    action = "store",
    type = "character",
    help = paste0("PERL-compatible regular expression matching",
             " header of column having number of 'Phospho (STY)'")
  )
  # default = "^Intensity[^_]",
  ,
  make_option(
    c("-s", "--startCol"),
    action = "store",
    type = "character",
    help = paste0("PERL-compatible regular expression matching",
             " header of column having first sample intensity")
  )
  # default = 1,
  ,
  make_option(
    c("-I", "--intervalCol"),
    action = "store",
    type = "integer",
    help = paste0("Column interval between the Intensities of samples",
             " (eg, 1 if subsequent column; 2 if every other column")
  )
  # default = 0.75,
  ,
  make_option(
    c("-l", "--localProbCutoff"),
    action = "store",
    type = "double",
    help = "Localization Probability Cutoff"
  )
  # default = "sum",
  ,
  make_option(
    c("-f", "--collapse_func"),
    action = "store",
    type = "character",
    help = paste0("merge identical phosphopeptides",
             " by ('sum' or 'average') the intensities")
  )
  # default = "filtered_data.txt",
  ,
  make_option(
    c("-r", "--filtered_data"),
    action = "store",
    type = "character",
    help = "filtered_data.txt"
  )
  # default = "quantData.txt",
  ,
  make_option(
    c("-q", "--quant_data"),
    action = "store",
    type = "character",
    help = "quantData.txt"
  )
)
args <- parse_args(OptionParser(option_list = option_list))
# Check parameter values

### EXTRACT ARGUMENTS end ----------------------------------------------------


### EXTRACT PARAMETERS from arguments begin ----------------------------------

if (!file.exists(args$input)) {
  stop((paste("File", args$input, "does not exist")))
}

phospho_col_pattern <- "^Number of Phospho [(][STY][STY]*[)]$"
start_col_pattern <- "^Intensity[^_]"
phospho_col_pattern <- read_first_line(args$phosphoCol)
start_col_pattern <- read_first_line(args$startCol)

sink(getConnection(2))

input_file_name <- args$input
filtered_filename <- args$filtered_data
quant_file_name <- args$quant_data
interval_col <- as.integer(args$intervalCol)

first_line <- read_first_line(input_file_name)
col_headers <-
  unlist(strsplit(
    x = first_line,
    split = c("\t"),
    fixed = TRUE
  ))
sink(getConnection(2))
sink()


intensity_header_cols <-
  grep(pattern = start_col_pattern, x = col_headers, perl = TRUE)
if (length(intensity_header_cols) == 0) {
  err_msg <-
    paste("Found no intensity columns matching pattern:",
          start_col_pattern)
  # Divert output to stderr
  sink(getConnection(2))
  print(err_msg)
  sink()
  stop(err_msg)
}


phospho_col <-
  grep(pattern = phospho_col_pattern, x = col_headers, perl = TRUE)[1]
if (is.na(phospho_col)) {
  err_msg <-
    paste("Found no 'number of phospho sites' columns matching pattern:",
          phospho_col_pattern)
  # Divert output to stderr
  sink(getConnection(2))
  print(err_msg)
  sink()
  stop(err_msg)
}


i_count <- 0
this_column <- 1
last_value <- intensity_header_cols[1]
intensity_cols <- c(last_value)

while (length(intensity_header_cols) >= interval_col * i_count) {
  i_count <- 1 + i_count
  this_column <- interval_col + this_column
  if (last_value + interval_col != intensity_header_cols[this_column])
    break
  last_value <- intensity_header_cols[this_column]
  if (length(intensity_header_cols) < interval_col * i_count)
    break
  intensity_cols <-
    c(intensity_cols, intensity_header_cols[this_column])
}

start_col <- intensity_cols[1]
num_samples <- i_count

output_filename <- args$output
enrich_graph_filename <- args$enrichGraph
loc_prob_cutoff_graph_filename <- args$locProbCutoffGraph
enrich_graph_filename_svg <- args$enrichGraph_svg
loc_prob_cutoff_graph_fn_svg <- args$locProbCutoffGraph_svg

local_prob_cutoff <- args$localProbCutoff
enriched <- args$enriched
collapse_fn <- args$collapse_func

### EXTRACT PARAMETERS from arguments end ------------------------------------


# Proteomics Quality Control for MaxQuant Results
#  (Bielow C et al. J Proteome Res. 2016 PMID: 26653327)
# is run by the Galaxy MaxQuant wrapper and need not be invoked here.


# Read & filter out contaminants, reverse sequences, & localization probability
# ---
full_data <-
  read.table(
    file = input_file_name,
    sep = "\t",
    header = TRUE,
    quote = ""
  )

# Filter out contaminant rows and reverse rows
filtered_data <- subset(full_data, !grepl("CON__", Proteins))
filtered_data <-
  subset(filtered_data, !grepl("_MYCOPLASMA", Proteins))
filtered_data <-
  subset(filtered_data, !grepl("CONTAMINANT_", Proteins))
filtered_data <-
  subset(filtered_data, !grepl("REV__", Protein)
         ) # since REV__ rows are blank in the first column (Proteins)
write.table(
  filtered_data,
  file = filtered_filename,
  sep = "\t",
  quote = FALSE,
  col.names = TRUE,
  row.names = FALSE
)
# ...


# Filter out data with localization probability below localProbCutoff
# ---
# Data filtered by localization probability
loc_prob_filtered_data <-
  filtered_data[
    filtered_data$Localization.prob >= local_prob_cutoff,
    ]
# ...


# Localization probability -- visualize locprob cutoff
# ---
loc_prob_graph_data <-
  data.frame(
    group = c(paste(">", toString(local_prob_cutoff), sep = ""),
              paste("<", toString(local_prob_cutoff), sep = "")),
    value = c(
      nrow(loc_prob_filtered_data) / nrow(filtered_data) * 100,
      (nrow(filtered_data) - nrow(loc_prob_filtered_data))
        / nrow(filtered_data) * 100
    )
  )
gigi <-
  ggplot(loc_prob_graph_data, aes(x = "", y = value, fill = group)) +
  geom_bar(width = 0.5,
           stat = "identity",
           color = "black") +
  labs(x = NULL,
    y = "percent",
    title = "Phosphopeptides partitioned by localization-probability cutoff"
  ) +
  scale_fill_discrete(name = "phosphopeptide\nlocalization-\nprobability") +
  theme_minimal() +
  theme(
    legend.position = "right",
    legend.title = element_text(),
    plot.title = element_text(hjust = 0.5),
    plot.subtitle = element_text(hjust = 0.5),
    plot.title.position = "plot"
  )
pdf(loc_prob_cutoff_graph_filename)
print(gigi)
dev.off()
svg(loc_prob_cutoff_graph_fn_svg)
print(gigi)
dev.off()
# ...


# Extract quantitative values from filtered data
# ---
quant_data <-
  loc_prob_filtered_data[, seq(from = start_col,
                               by = interval_col,
                               length.out = num_samples)]
# ...


# Generate Phosphopeptide Sequence
#   for latest version of MaxQuant (Version 1.5.3.30)
# ---
metadata_df <-
  data.frame(
    loc_prob_filtered_data[, 1:8],
    loc_prob_filtered_data[, phospho_col],
    loc_prob_filtered_data[, phospho_col + 1],
    loc_prob_filtered_data[, phospho_col + 2],
    loc_prob_filtered_data[, phospho_col + 3],
    loc_prob_filtered_data[, phospho_col + 4],
    loc_prob_filtered_data[, phospho_col + 5],
    loc_prob_filtered_data[, phospho_col + 6],
    loc_prob_filtered_data[, phospho_col + 7],
    quant_data
  )
colnames(metadata_df) <-
  c(
    "Proteins",
    "Positions within proteins",
    "Leading proteins",
    "Protein",
    "Protein names",
    "Gene names",
    "Fasta headers",
    "Localization prob",
    "Number of Phospho (STY)",
    "Amino Acid",
    "Sequence window",
    "Modification window",
    "Peptide window coverage",
    "Phospho (STY) Probabilities",
    "Phospho (STY) Score diffs",
    "Position in peptide",
    colnames(quant_data)
  )
# 'phosphopeptide_func' generates a phosphopeptide sequence
#   for each row of data.
# for the 'apply' function: MARGIN 1 == rows, 2 == columns, c(1, 2) = both
metadata_df$phosphopeptide <-
  apply(X = metadata_df, MARGIN = 1, FUN = phosphopeptide_func)
colnames(metadata_df)[1] <- "Phosphopeptide"
# Move the quant data columns to the right end of the data.frame
metadata_df <- movetolast(metadata_df, c(colnames(quant_data)))
# ...


# Write quantitative values for debugging purposes
# ---
quant_write <- cbind(metadata_df[, "Sequence window"], quant_data)
colnames(quant_write)[1] <- "Sequence.Window"
write.table(
  quant_write,
  file = quant_file_name,
  sep = "\t",
  quote = FALSE,
  col.names = TRUE,
  row.names = FALSE
)
# ...


# Make new data frame containing only Phosphopeptides
#   that are to be mapped to quant data (merge_df)
# ---
metadata_df <-
  setDT(metadata_df, keep.rownames = TRUE) # row name will be used to map
merge_df <-
  data.frame(
    as.integer(metadata_df$rn),
    metadata_df$phosphopeptide # row index to merge data frames
    )
colnames(merge_df) <- c("rn", "Phosphopeptide")
# ...


# Add Phosphopeptide column to quant columns for quality control checking
# ---
quant_data_qc <- as.data.frame(quant_data)
setDT(quant_data_qc, keep.rownames = TRUE) # will use to match rowname to data
quant_data_qc$rn <- as.integer(quant_data_qc$rn)
quant_data_qc <- merge(merge_df, quant_data_qc, by = "rn")
quant_data_qc$rn <- NULL # remove rn column
# ...


# Collapse multiphosphorylated peptides
# ---
quant_data_qc_collapsed <-
  data.table(quant_data_qc, key = "Phosphopeptide")
quant_data_qc_collapsed <-
  aggregate(. ~ Phosphopeptide, quant_data_qc, FUN = collapse_fn)
# ...
print("quant_data_qc_collapsed")
head(quant_data_qc_collapsed)

# Compute (as string) % of phosphopeptides that are multiphosphorylated
#   (for use in next step)
# ---
pct_multiphos <-
  (
    nrow(quant_data_qc) - nrow(quant_data_qc_collapsed)
  ) / (2 * nrow(quant_data_qc))
pct_multiphos <- sprintf("%0.1f%s", 100 * pct_multiphos, "%")
# ...


# Compute and visualize breakdown of pY, pS, and pT before enrichment filter
# ---
py_data <-
  quant_data_qc_collapsed[
    str_detect(quant_data_qc_collapsed$Phosphopeptide, "pY"),
    ]
ps_data <-
  quant_data_qc_collapsed[
    str_detect(quant_data_qc_collapsed$Phosphopeptide, "pS"),
    ]
pt_data <-
  quant_data_qc_collapsed[
     str_detect(quant_data_qc_collapsed$Phosphopeptide, "pT"),
     ]

py_num <- nrow(py_data)
ps_num <- nrow(ps_data)
pt_num <- nrow(pt_data)

# Visualize enrichment
enrich_graph_data <- data.frame(group = c("pY", "pS", "pT"),
                                value = c(py_num, ps_num, pt_num))

enrich_graph_data <-
  enrich_graph_data[
    enrich_graph_data$value > 0,
    ]

# Plot pie chart with legend
# start: https://stackoverflow.com/a/62522478/15509512
# refine: https://www.statology.org/ggplot-pie-chart/
# colors: https://colorbrewer2.org/#type=diverging&scheme=BrBG&n=8
slices <- enrich_graph_data$value
phosphoresidue <- enrich_graph_data$group
pct    <- round(100 * slices / sum(slices))
lbls   <-
  paste(enrich_graph_data$group, "\n", pct, "%\n(", slices, ")", sep = "")
slc_ctr <- c()
run_tot <- 0
for (p in pct) {
  slc_ctr <- c(slc_ctr, run_tot + p / 2.0)
  run_tot <- run_tot + p
}
lbl_y  <- 100 - slc_ctr
df     <-
  data.frame(slices,
             pct,
             lbls,
             phosphoresidue = factor(phosphoresidue, levels = phosphoresidue))
gigi <- ggplot(df
               , aes(x = 1, y = pct, fill = phosphoresidue)) +
  geom_col(position = "stack", orientation = "x") +
  geom_text(aes(x = 1, y = lbl_y, label = lbls), col = "black") +
  coord_polar(theta = "y", direction = -1) +
  labs(
    x = NULL
    ,
    y = NULL
    ,
    title = "Percentages (and counts) of phosphosites, by type of residue"
    ,
    caption = sprintf(
      "Roughly %s of peptides have multiple phosphosites.",
      pct_multiphos
    )
  ) +
  labs(x = NULL, y = NULL, fill = NULL) +
  theme_classic() +
  theme(
    legend.position = "right"
    ,
    axis.line = element_blank()
    ,
    axis.text = element_blank()
    ,
    axis.ticks = element_blank()
    ,
    plot.title = element_text(hjust = 0.5)
    ,
    plot.subtitle = element_text(hjust = 0.5)
    ,
    plot.caption = element_text(hjust = 0.5)
    ,
    plot.title.position = "plot"
  ) +
  scale_fill_manual(breaks = phosphoresidue,
                    values = c("#c7eae5", "#f6e8c3", "#dfc27d"))

pdf(enrich_graph_filename)
print(gigi)
dev.off()
svg(enrich_graph_filename_svg)
print(gigi)
dev.off()
# ...


# Filter phosphopeptides by enrichment
# --
if (enriched == "Y") {
  quant_data_qc_enrichment <- quant_data_qc_collapsed[
    str_detect(quant_data_qc_collapsed$Phosphopeptide, "pY"),
    ]
} else if (enriched == "ST") {
  quant_data_qc_enrichment <- quant_data_qc_collapsed[
    str_detect(quant_data_qc_collapsed$Phosphopeptide, "pS") |
    str_detect(quant_data_qc_collapsed$Phosphopeptide, "pT"),
    ]
} else {
  print("Error in enriched variable. Set to either 'Y' or 'ST'")
}
# ...

print("quant_data_qc_enrichment")
head(quant_data_qc_enrichment)

# Write phosphopeptides filtered by enrichment
# --
write.table(
  quant_data_qc_enrichment,
  file = output_filename,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE
)
# ...
