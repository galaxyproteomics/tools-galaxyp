options(warn = -1)  #TURN OFF WARNINGS !!!!!!

suppressMessages(library(KEGGREST))

get_args <- function() {

  ## Collect arguments
  args <- commandArgs(TRUE)

  ## Default setting when no arguments passed
  if (length(args) < 1) {
    args <- c("--help")
  }

  ## Help section
  if ("--help" %in% args) {
    cat("Pathview R script
    Arguments:
      --help                  Print this test
      --input                 tab file
      --id_list               id list ',' separated
      --id_type               type of input ids (kegg-id, uniprot_AC,geneID)
      --id_column             number og column containg ids of interest
      --nb_pathways           number of pathways to return
      --header                boolean
      --output                output path
      --species               species used to get specific pathways(hsa,mmu,rno)

      Example:
      Rscript keggrest.R --input='P31946,P62258' --id_type='uniprot'
        --id_column 'c1' --header TRUE \n\n")

    q(save = "no")
  }

  parseargs <- function(x) strsplit(sub("^--", "", x), "=")
  argsdf <- as.data.frame(do.call("rbind", parseargs(args)))
  args <- as.list(as.character(argsdf$V2))
  names(args) <- argsdf$V1

  return(args)
}

str2bool <- function(x) {
  if (any(is.element(c("t", "true"), tolower(x)))) {
    return(TRUE)
  }else if (any(is.element(c("f", "false"), tolower(x)))) {
    return(FALSE)
  }else {
    return(NULL)
  }
}

read_file <- function(path, header) {
  file <- try(read.csv(path, header = header, sep = "\t",
       stringsAsFactors = FALSE, quote = "\"", check.names = F), silent = TRUE)
  if (inherits(file, "try-error")) {
    stop("File not found !")
  }else {
    return(file)
  }
}

get_pathways_list <- function(species) {
  ##all available pathways for the species
  pathways <- keggLink("pathway", species)
  tot_path <- unique(pathways)

  ##formating the dat into a list object
  ##key= pathway ID, value = genes of the pathway in the kegg format
  pathways_list <- sapply(tot_path, function(pathway)
          names(which(pathways == pathway)))
  return(pathways_list)
}

get_list_from_cp <- function(list) {
  list <- strsplit(list, "[ \t\n]+")[[1]]
  list <- gsub("[[:blank:]]|\u00A0|NA", "", list)
  list <- list[which(!is.na(list[list != ""]))]    #remove empty entry
  list <- unique(gsub("-.+", "", list))
  #Remove isoform accession number (e.g. "-2")
  return(list)
}

geneid_to_kegg <- function(vector, species) {
  vector <- sapply(vector, function(x) paste(species, x, sep = ":"),
                   USE.NAMES = F)
  return(vector)
}

to_keggid <- function(id_list, id_type) {
  if (id_type == "ncbi-geneid") {
    id_list <-  unique(geneid_to_kegg(id_list, args$species))
  }else if (id_type == "uniprot") {
    id_list <- unique(sapply(id_list, function(x)
      paste(id_type, ":", x, sep = ""), USE.NAMES = F))
    if (length(id_list) > 250) {
      id_list <- split(id_list, ceiling(seq_along(id_list) / 250))
      id_list <- sapply(id_list, function(x) keggConv("genes", x))
      id_list <- unique(unlist(id_list))
    } else {
      id_list <- unique(keggConv("genes", id_list))
    }
  } else if (id_type == "kegg-id") {
    id_list <- unique(id_list)
  }
  return(id_list)
}

#take data frame, return  data frame
split_ids_per_line <- function(line, ncol) {

  #print (line)
  header <- colnames(line)
  line[ncol] <- gsub("[[:blank:]]|\u00A0", "", line[ncol])

  if (length(unlist(strsplit(as.character(line[ncol]), ";"))) > 1) {
    if (length(line) == 1) {
      lines <- as.data.frame(unlist(strsplit(
        as.character(line[ncol]), ";")), stringsAsFactors = F)
    } else {
      if (ncol == 1) {        #first column
        lines <- suppressWarnings(cbind(unlist(strsplit(
          as.character(line[ncol]), ";")), line[2:length(line)]))
      } else if (ncol == length(line)) {         #last column
        lines <- suppressWarnings(cbind(line[1:ncol - 1],
                          unlist(strsplit(as.character(line[ncol]), ";"))))
      } else {
        lines <- suppressWarnings(cbind(line[1:ncol - 1],
          unlist(strsplit(as.character(line[ncol]), ";"), use.names = F),
          line[(ncol + 1):length(line)]))
      }
    }
    colnames(lines) <- header
    return(lines)
  } else {
    return(line)
  }
}

#create new lines if there's more than one id per cell in the columns in order
#to have only one id per line
one_id_one_line <- function(tab, ncol) {

  if (ncol(tab) > 1) {

    tab[, ncol] <- sapply(tab[, ncol], function(x) gsub("[[:blank:]]", "", x))
    header <- colnames(tab)
    res <- as.data.frame(matrix(ncol = ncol(tab), nrow = 0))
    for (i in seq_len(nrow(tab))) {
      lines <- split_ids_per_line(tab[i, ], ncol)
      res <- rbind(res, lines)
    }
  } else {
    res <- unlist(sapply(tab[, 1], function(x) strsplit(x, ";")), use.names = F)
    res <- data.frame(res[which(!is.na(res[res != ""]))], stringsAsFactors = F)
    colnames(res) <- colnames(tab)
  }
  return(res)
}

kegg_mapping <- function(kegg_id_list, id_type, ref_ids) {

    #mapping
    map <- lapply(ref_ids, is.element, unique(kegg_id_list))
    names(map) <- sapply(names(map), function(x) gsub("path:", "", x),
                         USE.NAMES = FALSE)    #remove the prefix "path:"

    in_path <- sapply(map, function(x) length(which(x == TRUE)))
    tot_path <- sapply(map, length)

    ratio <- (as.numeric(in_path[which(in_path != 0)])) /
      (as.numeric(tot_path[which(in_path != 0)]))
    ratio <- as.numeric(format(round(ratio * 100, 2), nsmall = 2))

    ##useful but LONG
    ## to do before : in step 1
    path_names <- names(in_path[which(in_path != 0)])
    name <- sapply(path_names, function(x) keggGet(x)[[1]]$NAME,
                   USE.NAMES = FALSE)

    res <- data.frame(I(names(in_path[which(in_path != 0)])), I(name), ratio,
              as.numeric(in_path[which(in_path != 0)]),
              as.numeric(tot_path[which(in_path != 0)]))
    res <- res[order(as.numeric(res[, 3]), decreasing = TRUE), ]
    colnames(res) <- c("pathway_ID", "Description",
                       "Ratio IDs mapped / total IDs (%)",
                       "nb KEGG genes IDs mapped in the pathway",
                       "nb total of KEGG genes IDs present in the pathway")

    return(res)

}

#get args from command line
args <- get_args()

###setting variables
header <- str2bool(args$header)
if (!is.null(args$id_list)) {
  id_list <- get_list_from_cp(args$id_list)
  }     #get ids from copy/paste input
if (!is.null(args$input)) { #get ids from input file
  csv <- read_file(args$input, header)
  ncol <- as.numeric(gsub("c", "", args$id_column))
  csv <- one_id_one_line(csv, ncol)
  id_list <- as.vector(csv[, ncol])
  id_list <- unique(id_list[which(!is.na(id_list[id_list != ""]))])
}

#convert to keggID if needed
id_list <- to_keggid(id_list, args$id_type)

#get pathways of species with associated KEGG ID genes
pathways_list <- get_pathways_list(args$species)

#mapping on pathways
res <- kegg_mapping(id_list, args$id_type, pathways_list)
if (nrow(res) > as.numeric(args$nb_pathways)) {
  res <- res[1:args$nb_pathways, ]
  }

write.table(res, file = args$output, quote = FALSE, sep = "\t",
            row.names = FALSE, col.names = TRUE)
