# MT2MQ: prepares metatranscriptomic outputs from ASaiM (HUMAnN2 and metaphlan) for metaquantome

# Load libraries
suppressPackageStartupMessages(library(tidyverse))
#default_locale()

# Set parameters from arguments
args = commandArgs(trailingOnly = TRUE)
data <- args[1]
  # data: full path to file or directory:
  #   - if in functional or f-t mode, should be a tsv file of HUMAnN2 gene families, after regrouping and renaming to GO, joining samples, and renormalizing to CPM.
  #   - if in taxonomic mode, should be a directory of tsv files of metaphlan genus-level results
mode <- args[2]
  # mode:
  #   -"f": function
  #   -"t": taxonomy
  #   -"ft": function-taxonomy
ontology <- unlist(strsplit(args[3], split = ","))
  # ontology: only for function or f-t mode. A string of the GO namespace(s) to include, separated by commas.
  #   ex: to include all: "molecular_function,biological_process,cellular_component"
outfile <- args[4]
  # outfile: full path with pathname and extension for output

# Functional mode
if (mode == "f"){
  out <- read.delim(file=data, header=TRUE, sep='\t') %>% 
    filter(!grepl(".+g__.+",X..Gene.Family)) %>% 
    separate(col=X..Gene.Family, into=c("id", "Extra"), sep=": ", fill="left") %>% 
    separate(col=Extra, into = c("namespace", "name"), sep = " ", fill="left", extra="merge") %>% 
    mutate(namespace = if_else(namespace == "[MF]", true = "molecular_function", false = if_else(namespace == "[BP]", true = "biological_process", false = "cellular_component"))) %>% 
    filter(namespace %in% ontology) %>% 
    select(id, name, namespace, 4:ncol(.))
}

# Taxonomic mode
if (mode == "t"){
  files <- dir(path = data)
  out <- tibble(filename = files) %>% 
    mutate(file_contents= map(filename, ~read.delim(file=file.path(data, .), header=TRUE, sep = "\t"))) %>% 
    unnest(cols = c(file_contents)) %>% 
    rename(sample = filename) %>% 
    separate(col = sample, into = c("sample",NA), sep=".tsv") %>% 
    pivot_wider(names_from = sample, values_from = abundance) %>% 
    mutate(rank = "genus") %>% 
    rename(name = genus) %>% 
    mutate(id = row_number(name)) %>% # filler for taxon id but should eventually find a way to get id from ncbi database
    select(id, name, rank, 2:ncol(.))
}

# Function-taxonomy mode
if (mode == "ft"){
  out <- read.delim(file=data, header=TRUE, sep='\t') %>% 
    filter(grepl(".+g__.+",X..Gene.Family)) %>% 
    separate(col=X..Gene.Family, into=c("id", "Extra"), sep=": ", fill="left") %>% 
    separate(col=Extra, into = c("namespace", "name"), sep = " ", fill="left", extra="merge") %>% 
    separate(col = name, into = c("name", "taxa"), sep="\\|", extra = "merge") %>%
    separate(col = taxa, into = c("Extra", "genus", "species"), sep = "__") %>% select(-"Extra") %>%
    mutate_if(is.character, str_replace_all, pattern = "\\.s", replacement = "") %>% 
    mutate_at(c("species"), str_replace_all, pattern = "_", replacement = " ") %>% 
    mutate(namespace = if_else(namespace == "[MF]", true = "molecular_function", false = if_else(namespace == "[BP]", true = "biological_process", false = "cellular_component"))) %>% 
    filter(namespace %in% ontology) %>% 
    select(id, name, namespace, 4:ncol(.))
}

# Write file
write.table(x = out, file = outfile, quote = FALSE, sep = "\t");
