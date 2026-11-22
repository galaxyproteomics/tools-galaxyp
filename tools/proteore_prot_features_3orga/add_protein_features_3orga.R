options(warn = -1)  #TURN OFF WARNINGS !!!!!!

# Read file and return file content as data.frame
order_columns <- function(df, ncol, file) {
  if (ncol == 1) { #already at the right position
    return(df)
  } else {
    df <- df[, c(2:ncol, 1, (ncol + 1):dim.data.frame(df)[2])]
  }
  return(df)
}

get_list_from_cp <- function(list) {
  list <- gsub(";", "\t", list)
  list <- strsplit(list, "[ \t\n]+")[[1]]
  list <- gsub("NA", "", list)
  list <- list[list != ""]    #remove empty entry
  list <- gsub("-.+", "", list)  #Remove isoform accession number (e.g. "-2")
  return(list)
}

check_ids <- function(vector, type) {
  uniprot_pattern <- "^([OPQ][0-9][A-Z0-9]{3}[0-9]
  |[A-NR-Z][0-9]([A-Z][A-Z0-9]{2}[0-9]) {1,2})$"
  entrez_id <- "^([0-9]+|[A-Z]{1,2}_[0-9]+|[A-Z]{1,2}_[A-Z]{1,4}[0-9]+)$"
  if (type == "entrez")
    return(grepl(entrez_id, vector))
  else if (type == "uniprot") {
    return(grepl(uniprot_pattern, vector))
  }
}

get_args <- function() {

  ## Collect arguments
  args <- commandArgs(TRUE)

  ## Default setting when no arguments passed
  if (length(args) < 1) {
    args <- c("--help")
  }

  ## Help section
  if ("--help" %in% args) {
    cat("Selection and Annotation HPA
        Arguments:
        --inputtype: type of input (list of id or filename)
        --input: input
        --uniprot_file: path to uniprot reference file
        --column: the column number which you would like to apply...
        --header: true/false if your file contains a header
        --pc_features: IsoPoint,SeqLength,MW
        --output: text output filename \n")

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
  }else{
    return(NULL)
  }
}

#take data frame, return  data frame
split_ids_per_line <- function(line, ncol) {

  #print (line)
  header <- colnames(line)
  line[ncol] <- gsub("[[:blank:]]|\u00A0", "", line[ncol])

  if (length(unlist(strsplit(as.character(line[ncol]), ";"))) > 1) {
    if (length(line) == 1) {
      lines <- as.data.frame(unlist(strsplit(as.character(line[ncol]), ";")),
                            stringsAsFactors = F)
    } else {
      if (ncol == 1) {                                #first column
        lines <- suppressWarnings(cbind(unlist(
          strsplit(as.character(line[ncol]), ";")), line[2:length(line)]))
      } else if (ncol == length(line)) {                 #last column
        lines <- suppressWarnings(cbind(line[1:ncol - 1],
                  unlist(strsplit(as.character(line[ncol]), ";"))))
      } else {
        lines <- suppressWarnings(cbind(line[1:ncol - 1], unlist(
          strsplit(as.character(line[ncol]), ";"), use.names = F),
          line[(ncol + 1):length(line)]))
      }
    }
    colnames(lines) <- header
    return(lines)
  } else {
    return(line)
  }
}

#create new lines if there's more than one id per cell in the columns
# in order to have only one id per line
one_id_one_line <- function(tab, ncol) {

  if (ncol(tab) > 1) {

    tab[, ncol] <- sapply(tab[, ncol], function(x) gsub("[[:blank:]]", "", x))
    header <- colnames(tab)
    res <- as.data.frame(matrix(ncol = ncol(tab), nrow = 0))
    for (i in seq_len(nrow(tab))) {
      lines <- split_ids_per_line(tab[i, ], ncol)
      res <- rbind(res, lines)
    }
  }else {
    res <- unlist(sapply(tab[, 1], function(x) strsplit(x, ";")), use.names = F)
    res <- data.frame(res[which(!is.na(res[res != ""]))], stringsAsFactors = F)
    colnames(res) <- colnames(tab)
  }
  return(res)
}

# Get information from neXtProt
get_uniprot_info <- function(ids, pc_features, uniprot_file) {

  cols <- c("Entry", pc_features)
  cols <- cols[cols != "None"]
  info <- uniprot_file[match(ids, uniprot_file$Entry), cols]
  colnames(info)[1] <- "UniProt-AC"

  return(info)
}

main <- function() {

  args <- get_args()
  #save(args,file="/home/dchristiany/proteore_project/ProteoRE/tools
  #/add_protein_features_mouse/args.rda")
  #load("/home/dchristiany/proteore_project/ProteoRE/tools
  #/add_protein_features_mouse/args.rda")

  #setting variables
  inputtype <- args$inputtype
  if (inputtype == "copy_paste") {
    ids <- get_list_from_cp(args$input)

    #Check for UniProt-AC ids
    if (all(!check_ids(ids, "uniprot"))) {
      stop("No UniProt-AC found in ids.")
    } else if (any(!check_ids(ids, "uniprot"))) {
      print("Some ids in ids are not uniprot-AC:")
      print(ids[which(!check_ids(ids, "uniprot"))])
    }
    file <- data.frame(ids, stringsAsFactors = F)
    ncol <- 1

    } else if (inputtype == "file") {
    filename <- args$input
    ncol <- args$column
    # Check ncol
    if (! as.numeric(gsub("c", "", ncol)) %% 1 == 0) {
      stop("Please enter an integer for level")
    } else {
      ncol <- as.numeric(gsub("c", "", ncol))
    }

    header <- str2bool(args$header)
    file <- read.table(filename, header = header, sep = "\t", fill = TRUE,
                       stringsAsFactors = FALSE, quote = "", check.names = F,
                       comment.char = "")
    # Get file content
    if (any(grep(";", file[, ncol]))) {
      file <- one_id_one_line(file, ncol)
      }
    ids <- file[, ncol]
  }


  org <- args$org

  # Read reference file
  if (org == "Mouse") {
    uniprot_file <- read.table(args$uniprot_file_mouse, header = TRUE,
                               sep = "\t", fill = TRUE,
                               stringsAsFactors = FALSE, quote = "",
                               check.names = F, comment.char = "")
  } else if (org == "Human") {
    uniprot_file <- read.table(args$uniprot_file_human, header = TRUE,
                               sep = "\t", fill = TRUE,
                               stringsAsFactors = FALSE, quote = "",
                               check.names = F, comment.char = "")
  } else if (org == "Rat") {
    uniprot_file <- read.table(args$uniprot_file_rat, header = TRUE,
                               sep = "\t", fill = TRUE,
                               stringsAsFactors = FALSE, quote = "",
                               check.names = F, comment.char = "")
  }

  # Parse arguments
  pc_features <- gsub("__ob__", "[", gsub("__cb__", "]",
                                        strsplit(args$pc_features, ",")[[1]]))
  output <- args$output

  #output file
  res <- get_uniprot_info(ids, pc_features, uniprot_file)
  res <- res[!duplicated(res$`UniProt-AC`), ]
  output_content <- merge(file, res, by.x = ncol, by.y = "UniProt-AC",
                          incomparables = NA, all.x = T)
  output_content <- order_columns(output_content, ncol, file)
  output_content <- as.data.frame(apply(output_content, c(1, 2),
                                        function(x) gsub("^$|^ $", NA, x)))
  #convert "" et " " to NA
  write.table(output_content, output, row.names = FALSE, sep = "\t",
              quote = FALSE)
}

if (!interactive()) {
  main()
}
