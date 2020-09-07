#' wl-07-09-2020, Mon: remove comments

## ==== General settings ====

set.seed(123)
options(warn = -1)
loc <- Sys.setlocale("LC_MESSAGES", "en_US.UTF-8")

suppressPackageStartupMessages({
  library(optparse)
  library(calibrate)
  library(rJava)
})

## ==== Command line ====

func <- function() {
  argv <- commandArgs(trailingOnly = FALSE)
  path <- sub("--file=", "", argv[grep("--file=", argv)])
  return(path)
}
home_dir <- paste0(dirname(func()), "/")

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
  make_option("--imzml_file",
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
  make_option("--fixed_fa", type = "double", default = 16),

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
    type = "character", default = "image_tsv",
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
  make_option("--pc_num", type = "integer", default = 5),
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
  make_option("--intensity_out", type = "character",
              default = "intensity.tsv")
)

opt <- parse_args(
  object = OptionParser(option_list = option_list),
  args = commandArgs(trailingOnly = TRUE)
)

print(opt)

suppressPackageStartupMessages({
  source(paste0(home_dir, "tool-data/all_masspix"))
})

## ==== Pre-processing ====

#' imzML converter
lib_dir <- paste0(home_dir, "tool-data/")
imzml_parse <- paste0(home_dir, "tool-data/imzMLConverter.jar")

options(java.parameters = "-Xmx4g")

if (is.null(opt$imzml_file)) {
  cat("'imzml_file' is required\n")
  q(status = 1)
}

if (!opt$process) {
  if (is.null(opt$image_file)) {
    cat("'image_file' is required\n")
    q(status = 1)
  }
}

#' read in library files
read <- read.csv(paste(lib_dir, "lib_FA.csv", sep = "/"), sep = ",",
                 header = T)
lookup_fa <- read[, 2:4]
row.names(lookup_fa) <- read[, 1]

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
rJava::.jinit()
rJava::.jaddClassPath(path = imzml_parse)

imzml <- rJava::J("imzMLConverter.ImzMLHandler")$parseimzML(opt$imzml_file)
x_cood <- rJava::J(imzml, "getWidth")
y_cood <- rJava::J(imzml, "getHeight")

## ==== Main Process ====

if (opt$process) {
  #' make library
  dbase <- makelibrary(
    ionisation_mode = opt$ionisation_mode,
    sel_class = NULL, fixed = opt$fixed,
    fixed_fa = opt$fixed_fa,
    lookup_lipid_class = lookup_lipid_class,
    lookup_fa = lookup_fa,
    lookup_element = lookup_element
  )

  #' Extract m/z and pick peaks
  extracted <- mzextractor(
    files = opt$imzml_file,
    imzml_parse = imzml_parse,
    thres_int = opt$thres_int,
    thres_low = opt$thres_low,
    thres_high = opt$thres_high
  )

  #' Bin all m/zs by ppm bucket
  peaks <- peakpicker_bin(extracted = extracted, bin_ppm = opt$bin_ppm)

  #' Generate subset of first image file to improve speed of deisotoping
  temp_image <- subset_image(
    extracted = extracted, peaks = peaks,
    percentage_deiso = opt$percentage_deiso,
    thres_int = opt$thres_int,
    thres_low = opt$thres_low,
    thres_high = opt$thres_high,
    files = opt$imzml_file,
    imzml_parse = imzml_parse
  )

  #' Filter to a matrix subset that includes variables above a threshold of
  #' missing values
  temp_image_filtered <- filter(
    imagedata_in = temp_image,
    steps = seq(0, 1, opt$steps),
    thres_filter = opt$thres_filter,
    offset = 1
  )

  #' Perform deisotoping on a subset of the image
  deisotoped <- deisotope(
    ppm = opt$ppm, no_isotopes = opt$no_isotopes,
    prop_1 = opt$prop_1, prop_2 = opt$prop_2,
    peaks = list("", temp_image_filtered[, 1]),
    image_sub = temp_image_filtered,
    search.mod = opt$search_mod,
    mod = eval(parse(text = opt$mod)),
    lookup_mod = lookup_mod
  )

  #' Perform annotation of lipids using library
  annotated <- annotate(
    ionisation_mode = opt$ionisation_mode,
    deisotoped = deisotoped,
    ppm_annotate = opt$ppm_annotate,
    dbase = dbase
  )

  #' make full image and add lipid ids
  final_image <- contruct_image(
    extracted = extracted,
    deisotoped = deisotoped,
    peaks = peaks, imzml_parse = imzml_parse,
    thres_int = opt$thres_int,
    thres_low = opt$thres_low,
    thres_high = opt$thres_high,
    files = opt$imzml_file
  )

  ids <- cbind(deisotoped[[2]][, 1], annotated, deisotoped[[2]][, 3:4])

  #' Create annotated image
  image_ann <- cbind(ids, final_image[, 2:ncol(final_image)])

  #' Normalise image
  image_norm <- normalise(
    imagedata_in = image_ann,
    norm_type = opt$norm_type,
    standards = eval(parse(text = opt$standards)),
    offset = 4
  )
  colnames(image_norm)[1] <- "peak"
  write.table(image_norm, file = opt$image_out, sep = "\t", row.names = FALSE)

  #' save to rda for debug
  if (opt$rdata) {
    save(image_norm, image_ann, final_image, annotated, deisotoped,
      temp_image_filtered, temp_image, peaks, extracted, dbase,
      file = opt$rdata_out
    )
  }
} else {
  image_norm <- read.table(opt$image_file,
    sep = "\t", header = TRUE,
    na.strings = "", stringsAsFactors = T
  )
}


## ==== Perform PCA if requested ====

if (opt$pca) {
  image_scale <- centre_scale(
    imagedata_in = image_norm,
    scale_type = opt$scale_type,
    transform = opt$transform,
    offset = 4
  )

  pdf(file = opt$pca_out, onefile = T)
  image_pca(
    imagedata_in = image_scale, offset = 4,
    pc_num = opt$pc_num, scale = opt$scale,
    x_cood = x_cood, y_cood = y_cood,
    nlevels = opt$nlevels, res_spatial = opt$res_spatial,
    rem_outliers = opt$rem_outliers,
    summary = opt$summary, title = opt$title
  )
  dev.off()

  if (opt$loading) {
    pca <- princomp(t(image_scale[, (4 + 1):ncol(image_scale)]),
      cor = FALSE,
      scores = TRUE, covmat = NULL
    )
    labs_all <- as.numeric(as.vector(image_scale[, 1]))

    ld <- lapply(1:opt$pc_num, function(x) {
      loadings <- round(pca$loadings[, x], digits = 4)
      loadings <- cbind(loadings, labs_all)
      loadings <- as.data.frame(loadings)
    })
    names(ld) <- paste0("PC", 1:opt$pc_num)

    tmp <- lapply(names(ld), function(x) {
      res <- cbind(PC = x, ld[[x]])
    })
    tmp <- do.call("rbind", tmp)
    write.table(tmp, file = opt$loading_out, sep = "\t", row.name = FALSE)
  }
}

## ==== Make ion slice if requested ====

if (opt$slice) {
  pdf(file = opt$slice_out, onefile = T)
  image_slice(
    row = opt$row, imagedata_in = image_norm, scale = opt$scale,
    x_cood = x_cood, y_cood = y_cood,
    nlevels = opt$nlevels,
    name = image_norm[opt$row, 1],
    subname = image_norm[opt$row, 2],
    offset = 4, res_spatial = opt$res_spatial,
    rem_outliers = opt$rem_outliers, summary = opt$summary,
    title = opt$title
  )
  dev.off()
}

## ==== Perform clustering if requested ====

if (opt$clus) {
  pdf(file = opt$clus_out, onefile = T)
  intensity <- cluster(
    cluster_type = opt$cluster_type,
    imagedata_in = image_norm,
    offset = 4, res_spatial = opt$res_spatial,
    width = x_cood, height = y_cood,
    clusters = opt$clusters
  )
  dev.off()

  if (opt$intensity) {
    tmp <- cbind(Clusters = rownames(intensity), intensity)
    write.table(tmp, file = opt$intensity_out, sep = "\t", row.name = FALSE)
  }
}
