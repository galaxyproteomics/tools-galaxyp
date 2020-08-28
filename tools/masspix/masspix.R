#' wl-02-11-2017, Thu: commence
#' wl-07-11-2017, Tue: debug using manual test
#' wl-10-11-2017, Fri: change 'steps' as float
#' wl-24-11-2017, Fri: Major changes
#' wl-25-11-2017, Sat: error handling
#' wl-07-11-2017, Thu: add debug codes
#' wl-25-01-2018, Thu: remove user's input for 'offset'
#' wl-30-01-2018, Tue: fix bugs in 'standards'
#' wl-12-02-2018, Mon: change output file as tabular (.tab) for galaxy only
#' wl-14-02-2018, Wed: save cluster intensity data
#' wl-28-03-2019, Thu: apply style_file() to reformat this script and use
#'  vim's folding as outline view. Without reformatng, the folding
#'  is messy.
#' wl-19-08-2020, Wed: review and drop WriteXLS. And find out PCA loadings
#'  will lead the failure of Galaxy planemo test. Round it and planemo test
#'  passes.
#' wl-20-08-2020, Thu: debug deisotope search mod
#' Usages:
#'  1.) For command line and galaxy, change `com_f` to TRUE.
#'  2.) For command line, change `home_dir` as appropriate
#'      For Windows, run: massPix.bat
#'      For Linux, run: ./massPix.sh
#'  3.) For interactive environment, change `com_f` to FALSE

## ==== General settings ====

rm(list = ls(all = T))
set.seed(123)

#' flag for command-line use or not. If false, only for debug interactively.
com_f <- T

#' galaxy will stop even if R has warning message
options(warn = -1) #' disable R warning. Turn back: options(warn=0)

#' Setup R error handling to go to stderr
#' options(show.error.messages = F, error = function() {
#'   cat(geterrmessage(), file = stderr())
#'   q("no", 1, F)
#' })

#' we need that to not crash galaxy with an UTF8 error on German LC settings.
loc <- Sys.setlocale("LC_MESSAGES", "en_US.UTF-8")

suppressPackageStartupMessages({
  library(optparse)
  library(calibrate)
  library(rJava)
})

## ==== Command line or interactive setting ====

if (com_f) {

  #' Setup home directory
  #' wl-24-11-2017, Fri: A dummy function for the base directory. The reason
  #' to write such a function is to keep the returned values by
  #' 'commandArgs' with 'trailingOnly = FALSE' in a local environment
  #' otherwise 'parse_args' will use the results of
  #' 'commandArgs(trailingOnly = FALSE)' even with 'args =
  #' commandArgs(trailingOnly = TRUE)' in its argument area.
  func <- function() {
    argv <- commandArgs(trailingOnly = FALSE)
    path <- sub("--file=", "", argv[grep("--file=", argv)])
  }
  #' prog_name <- basename(func())
  home_dir <- paste0(dirname(func()), "/")

  #' Specify our desired options in a list by default OptionParser will add
  #' an help option equivalent to make_option(c("-h", "--help"),
  #' action="store_true", default=FALSE, help="Show this help message and
  #' exit")
  option_list <- list(
    make_option(c("-v", "--verbose"),
      action = "store_true", default = TRUE,
      help = "Print extra output [default]"
    ),
    make_option(c("-q", "--quietly"),
      action = "store_false",
      dest = "verbose", help = "Print little output"
    ),

    #' input files
    make_option("--imzML_file",
      type = "character",
      help = "Mass spectrometry imaging data to be processed.
              Currently imzML format is supported."
    ),
    make_option("--image_file",
      type = "character",
      help = "Processed imaging data to be further analysis."
    ),

    #' image processing
    make_option("--process", type = "logical", default = TRUE),

    #' make library
    make_option("--ionisation_mode", type = "character", default = "positive"),
    make_option("--fixed", type = "logical", default = FALSE),
    make_option("--fixed_FA", type = "double", default = 16),

    #' mz_extractor
    make_option("--thres_int", type = "integer", default = 100000),
    make_option("--thres_low", type = "integer", default = 200),
    make_option("--thres_high", type = "integer", default = 1000),

    #' peak_bin
    make_option("--bin_ppm", type = "integer", default = 10),

    #' subset_image
    make_option("--percentage_deiso", type = "integer", default = 3),

    #' filter
    make_option("--steps", type = "double", default = 0.05),
    make_option("--thres_filter", type = "integer", default = 11),

    #' deisotope
    make_option("--ppm", type = "integer", default = 3),
    make_option("--no_isotopes", type = "integer", default = 2),
    make_option("--prop_1", type = "double", default = 0.9),
    make_option("--prop_2", type = "double", default = 0.5),
    make_option("--search_mod", type = "logical", default = TRUE),
    make_option("--mod",
      type = "character",
      default = "c(NL = T, label = F, oxidised = F, desat = F)"
    ),

    #' annotate
    make_option("--ppm_annotate", type = "integer", default = 10),

    #' normalise
    make_option("--norm_type", type = "character", default = "TIC"),
    make_option("--standards", type = "character", default = "NULL"),

    #' output parameters and files
    make_option("--image_out",
      type = "character", default = "image.tsv",
      help = "Processed imaging data visualisation"
    ),

    make_option("--rdata", type = "logical", default = TRUE),
    make_option("--rdata_out",
      type = "character", default = "r_running.rdata",
      help = "All the running results in RData for inspection."
    ),

    #' plot parameters
    make_option("--scale", type = "integer", default = 100),
    make_option("--nlevels", type = "integer", default = 50),
    make_option("--res_spatial", type = "integer", default = 50),
    make_option("--rem_outliers", type = "logical", default = TRUE),
    make_option("--summary", type = "logical", default = FALSE),
    make_option("--title", type = "logical", default = TRUE),

    #' pca plot
    make_option("--pca", type = "logical", default = TRUE),
    make_option("--pca_out", type = "character", default = "pca.pdf"),
    make_option("--scale_type", type = "character", default = "cs"),
    make_option("--transform", type = "logical", default = FALSE),
    make_option("--PCnum", type = "integer", default = 5),
    make_option("--loading", type = "logical", default = TRUE),
    make_option("--loading_out", type = "character", default = "loading.tsv"),

    #' slice plot
    make_option("--slice", type = "logical", default = TRUE),
    make_option("--row", type = "integer", default = 12),
    make_option("--slice_out", type = "character", default = "slice.pdf"),

    #' cluster plot
    make_option("--clus", type = "logical", default = TRUE),
    make_option("--clus_out", type = "character", default = "clus.pdf"),
    make_option("--cluster_type", type = "character", default = "kmeans"),
    make_option("--clusters", type = "integer", default = 5),
    make_option("--intensity", type = "logical", default = TRUE),
    make_option("--intensity_out", type = "character", default = "intensity.tsv")
  )

  opt <- parse_args(
    object = OptionParser(option_list = option_list),
    args = commandArgs(trailingOnly = TRUE)
  )
} else {
  #' home_dir <- "C:/R_lwc/massPix/"         #' for windows
  home_dir <- "/home/wl/R_lwc/r_data/cam1/massPix/"
  ## home_dir <- "/home/wl/my_galaxy/massPix/"
  opt <- list(
    #' -------------------------------------------------------------------
    #' input files. Note that using full path here.
    imzML_file = paste0(home_dir, "test-data/cut_masspix.imzML"),
    ## imzML_file = paste0(home_dir, "test-data/test_pos.imzML"),
    image_file = paste0(home_dir, "test-data/image_norm.tsv"),

    #' image data processing parameters
    process = T,

    #' make library
    ionisation_mode = "positive",
    fixed = FALSE,
    fixed_FA = 16,
    #' mz_extractor
    thres_int = 100000,
    thres_low = 200,
    thres_high = 1000,
    #' peak_bin
    bin_ppm = 10,
    #' subset_image
    percentage_deiso = 3,
    #' filter
    steps = 0.05,
    thres_filter = 11,
    #' deisotope
    ppm = 3,
    no_isotopes = 2,
    prop_1 = 0.9,
    prop_2 = 0.5,
    search_mod = TRUE,
    mod = "c(NL = T, label = F, oxidised = F, desat = F)",
    #' annotate
    ppm_annotate = 10,
    #' normalise
    norm_type = "TIC",
    standards = "NULL",

    #' output parameters and files
    image_out = paste0(home_dir, "test-data/res/image.tsv"),

    rdata = TRUE,
    rdata_out = paste0(home_dir, "test-data/res/r_running.rdata"),

    #' plot parameters
    scale = 100,
    nlevels = 50,
    res_spatial = 50,
    rem_outliers = TRUE,
    summary = FALSE,
    title = TRUE,

    #' pca plot
    pca = TRUE,
    pca_out = paste0(home_dir, "test-data/res/pca.pdf"),
    scale_type = "cs",
    transform = FALSE,
    PCnum = 5,
    loading = TRUE,
    loading_out = paste0(home_dir, "test-data/res/loading.tsv"),

    #' slice plot
    slice = TRUE,
    slice_out = paste0(home_dir, "test-data/res/slice.pdf"),
    row = 12,

    #' cluster plot
    clus = TRUE,
    clus_out = paste0(home_dir, "test-data/res/clus.pdf"),
    cluster_type = "kmeans",
    clusters = 5,
    intensity = TRUE,
    intensity_out = paste0(home_dir, "test-data/res/intensity.tsv")
  )
}
#' print(opt)

suppressPackageStartupMessages({
  source(paste0(home_dir, "all_masspix.R"))
})

## ==== Pre-processing ====

#' imzML converter
lib_dir <- paste0(home_dir, "tool-data/")
imzMLparse <- paste0(home_dir, "tool-data/imzMLConverter.jar")

options(java.parameters = "-Xmx2g")

#' enforce the following required arguments
if (is.null(opt$imzML_file)) {
  cat("'imzML_file' is required\n")
  q(status = 1)
}
#' wl-07-02-2018, Wed: 'imzML_file' must be provided no matter what
#' 'process' is. For 'process' is FALSE, it gives 'x.cood' and 'y.cood' for
#' visualisation.

if (!opt$process) {
  if (is.null(opt$image_file)) {
    cat("'image_file' is required\n")
    q(status = 1)
  }
}

#' read in library files
read <- read.csv(paste(lib_dir, "lib_FA.csv", sep = "/"), sep = ",", 
                 header = T)
lookup_FA <- read[, 2:4]
row.names(lookup_FA) <- read[, 1]

read <- read.csv(paste(lib_dir, "lib_class.csv", sep = "/"), sep = ",", 
                 header = T)
lookup_lipid_class <- read[, 2:3]
row.names(lookup_lipid_class) <- read[, 1]

read <- read.csv(paste(lib_dir, "lib_element.csv", sep = "/"), sep = ",", 
                 header = T)
lookup_element <- read[, 2:3]
row.names(lookup_element) <- read[, 1]

read <- read.csv(paste(lib_dir, "lib_modification.csv", sep = "/"), 
                 sep = ",", header = T)
lookup_mod <- read[, 2:ncol(read)]
row.names(lookup_mod) <- read[, 1]

#' parsing the data and getting x and y dimensions
.jinit()
.jaddClassPath(path = imzMLparse)

imzML <- J("imzMLConverter.ImzMLHandler")$parseimzML(opt$imzML_file)
#' wl-07-11-2017, Tue: Location opt$ibd_file is also written into imzML.
#' Note that opt$imzML_file and opt$ibd_file must have the same file name
#' and extention names imzML and ibd, respectively. You can see this from
#' CPP file: (https://goo.gl/WTkFkn)
#'
#'  // Remove ".imzML" from the end of the file
#' 	this->ibdLocation = imzMLFilename.substr(0, imzMLFilename.size()-6) + ".ibd";
#'
#' Otherwise this function: J(spectrum, 'getIntensityArray') does not work.
#' Three functions mzextractor, subsetImage and contructImage call this
#' function.
#' wl-25-11-2017, Sat: imzML and ibd file must be uploaded and located in
#' the same directory. If so, no need to pass ibd file into R code since
#' imzMLConverter will get ibd file implicitely based on the directory and
#' name of imzML file.

x.cood <- J(imzML, "getWidth")
y.cood <- J(imzML, "getHeight")

## ==== Main Process ====

if (opt$process) {
  #' make library
  dbase <- makelibrary(
    ionisation_mode = opt$ionisation_mode,
    sel.class = NULL, fixed = opt$fixed,
    fixed_FA = opt$fixed_FA,
    lookup_lipid_class = lookup_lipid_class,
    lookup_FA = lookup_FA,
    lookup_element = lookup_element
  )

  #' Extract m/z and pick peaks
  extracted <- mzextractor(
    files = opt$imzML,
    imzMLparse = imzMLparse,
    thres.int = opt$thres_int,
    thres.low = opt$thres_low,
    thres.high = opt$thres_high
  )

  #' Bin all m/zs by ppm bucket
  peaks <- peakpicker.bin(extracted = extracted, bin.ppm = opt$bin_ppm)

  #' Generate subset of first image file to improve speed of deisotoping
  temp.image <- subsetImage(
    extracted = extracted, peaks = peaks,
    percentage.deiso = opt$percentage_deiso,
    thres.int = opt$thres_int,
    thres.low = opt$thres_low,
    thres.high = opt$thres_high,
    files = opt$imzML,
    imzMLparse = imzMLparse
  )

  #' Filter to a matrix subset that includes variables above a threshold of
  #' missing values
  temp.image.filtered <- filter(
    imagedata.in = temp.image,
    steps = seq(0, 1, opt$steps),
    thres.filter = opt$thres_filter,
    offset = 1
  )

  #' Perform deisotoping on a subset of the image
  deisotoped <- deisotope(
    ppm = opt$ppm, no_isotopes = opt$no_isotopes,
    prop.1 = opt$prop_1, prop.2 = opt$prop_2,
    peaks = list("", temp.image.filtered[, 1]),
    image.sub = temp.image.filtered,
    search.mod = opt$search_mod,
    mod = eval(parse(text = opt$mod)),
    lookup_mod = lookup_mod
  )

  #' Perform annotation of lipids using library
  annotated <- annotate(
    ionisation_mode = opt$ionisation_mode,
    deisotoped = deisotoped,
    ppm.annotate = opt$ppm_annotate,
    dbase = dbase
  )

  #' make full image and add lipid ids
  #' wl-23-08-2017: it takes **LONG TIME**.
  final.image <- contructImage(
    extracted = extracted,
    deisotoped = deisotoped,
    peaks = peaks, imzMLparse = imzMLparse,
    thres.int = opt$thres_int,
    thres.low = opt$thres_low,
    thres.high = opt$thres_high,
    files = opt$imzML
  )

  ids <- cbind(deisotoped[[2]][, 1], annotated, deisotoped[[2]][, 3:4])

  #' Create annotated image
  image.ann <- cbind(ids, final.image[, 2:ncol(final.image)])

  #' Normalise image
  image.norm <- normalise(
    imagedata.in = image.ann,
    norm.type = opt$norm_type,
    standards = eval(parse(text = opt$standards)),
    offset = 4
  )

  #' wl-12-02-2018, Mon: change the first column name
  colnames(image.norm)[1] <- "peak"

  #' save processed results
  #' write.csv(image.norm, file=opt$image_out, row.names = FALSE)
  write.table(image.norm, file = opt$image_out, sep = "\t", row.names = FALSE)

  #' save to rda for debug
  if (opt$rdata) {
    save(image.norm, image.ann, final.image, annotated, deisotoped,
      temp.image.filtered, temp.image, peaks, extracted, dbase,
      file = opt$rdata_out
    )
  }
} else {
  image.norm <- read.table(opt$image_file,
    sep = "\t", header = TRUE,
    na.strings = "", stringsAsFactors = T
  )
}
## ==== Perform PCA if requested ====

if (opt$pca) {
  image.scale <- centreScale(
    imagedata.in = image.norm,
    scale.type = opt$scale_type,
    transform = opt$transform,
    offset = 4
  )

  pdf(file = opt$pca_out, onefile = T)
  imagePca(
    imagedata.in = image.scale, offset = 4,
    PCnum = opt$PCnum, scale = opt$scale,
    x.cood = x.cood, y.cood = y.cood,
    nlevels = opt$nlevels, res.spatial = opt$res_spatial,
    rem.outliers = opt$rem_outliers,
    summary = opt$summary, title = opt$title
  )
  dev.off()

  if (opt$loading) {
    pca <- princomp(t(image.scale[, (4 + 1):ncol(image.scale)]),
      cor = FALSE,
      scores = TRUE, covmat = NULL
    )
    labs.all <- as.numeric(as.vector(image.scale[, 1]))

    #' wl-05-02-2018, Mon: save as one excel file
    #' wl-19-08-2020, Wed: drop R package WriteXLS and round loadings.
    #' without it, galaxy's 'planemo test' will definitely fail.
    ld <- lapply(1:opt$PCnum, function(x) {
      loadings <- round(pca$loadings[, x], digits = 4)
      loadings <- cbind(loadings, labs.all)
      loadings <- as.data.frame(loadings)
    })
    names(ld) <- paste0("PC", 1:opt$PCnum)
    ## WriteXLS::WriteXLS(ld, ExcelFileName = opt$loading_out, row.names = F,
    ##                    FreezeRow = 1)

    tmp <- lapply(names(ld), function(x){
      res <- cbind(PC=x, ld[[x]])
    })
    tmp <- do.call("rbind", tmp)
    write.table(tmp, file = opt$loading_out, sep = "\t", row.name = FALSE)
  }
}

## ==== Make ion slice if requested ====

if (opt$slice) {
  pdf(file = opt$slice_out, onefile = T)
  imageSlice(
    row = opt$row, imagedata.in = image.norm, scale = opt$scale,
    x.cood = x.cood, y.cood = y.cood,
    nlevels = opt$nlevels,
    name = image.norm[opt$row, 1],
    subname = image.norm[opt$row, 2],
    offset = 4, res.spatial = opt$res_spatial,
    rem.outliers = opt$rem_outliers, summary = opt$summary,
    title = opt$title
  )
  dev.off()
}

## ==== Perform clustering if requested ====

if (opt$clus) {
  pdf(file = opt$clus_out, onefile = T)
  intensity <- cluster(
    cluster.type = opt$cluster_type,
    imagedata.in = image.norm,
    offset = 4, res.spatial = opt$res_spatial,
    width = x.cood, height = y.cood,
    clusters = opt$clusters
  )
  dev.off()

  if (opt$intensity) {
    #' write.table(intensity,file=opt$intensity_out,sep="\t")
    #' wl-14-02-2018, Wed: more need to be done for "\t"
    tmp <- cbind(Clusters = rownames(intensity), intensity)
    write.table(tmp, file = opt$intensity_out, sep = "\t", row.name = FALSE)
  }
}

