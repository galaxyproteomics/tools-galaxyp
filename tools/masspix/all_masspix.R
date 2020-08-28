#' wl-22-08-2017, Tue: first touch
#' wl-23-08-2017, Wed: add some comments
#' wl-24-08-2017, Thu: debug three functions: imageSlice, imagePca and
#'  cluster.
#' wl-07-11-2017, Tue: Make some Changes
#'   - add 'lib_dir' for wrapper function 'massPix'
#'   - remove output in 'cluster' function
#'   - remove 'getwd' and use 'spectra_dir' in function 'subsetImage'
#' wl-27-11-2017, Mon: More trivia changes
#' wl-29-01-2018, Mon: modify and debug 'norm.median'
#' wl-30-01-2018, Tue: modify and debug 'norm.standard'.
#' wl-13-02-2018, Tue: modify and debug 'cluster'
#' wl-25-03-2019, Mon: apply styler to reformat R codes 

#' library(calibrate)  # for plot function 'textxy' only.
#' library(rJava)      # for execute Java
#' library(Biobase)    # for 'norm.median'

#' ========================================================================
#' make library of lipid masses
#'
#' @param ionisation_mode Choose "positive" or "negative", will determine
#' which lipid classes are in database
#' @param sel.class A vector defining classes of lipids to be included in
#'   the library
#' @param fixed Defines if one of the SN positions is fixed, default is F
#' @param fixed_FA Defines the name of the fixed FA eg 16, 18.1, 20.4.
#' @param lookup_lipid_class A data.frame defining lipid classes frm library
#' @param lookup_FA A dataframe defining FAs from library
#' @param lookup_element A data.frame defining elements from library
#' @return Dataframe of masses for all combinations of FAs with chosen head
#'   groups
#' @export
#'
#' wl-07-11-2017, Tue: should remove argument 'sel.class'
#'
makelibrary <- function(ionisation_mode, sel.class, fixed = F, fixed_FA,
                        lookup_lipid_class, lookup_FA, lookup_element) {
  cat("\nMaking library of lipid masses...\n")
  if (ionisation_mode == "positive") {
    sel.class <- c(
      T, # TG
      T, # DG
      T, # PC
      F, # PA
      T, # PE
      T, # PS
      F, # PG
      F, # PI
      F, # PIP
      F, # PIP2
      F, # PIP3
      T, # LysoPC
      T, # DG-H20
      T, # CE
      F, # FFA
      T, # SM
      T # Cer
    )
  }

  if (ionisation_mode == "negative") {
    sel.class <- c(
      F, # TG
      F, # DG
      T, # PC
      T, # PA
      T, # PE
      T, # PS
      T, # PG
      T, # PI
      T, # PIP
      T, # PIP2
      T, # PIP3
      F, # LysoPC
      F, # DG-H20
      F, # CE
      T, # FFA
      F, # SM
      T # Cer - ZLH changed this to true 20.03.18
    )
  }

  lookup_lipid_class <- cbind(lookup_lipid_class, sel.class)

  #' FAs to use in library
  FA_expt <- list(
    "10", "12", "14", "15", "16", "16.1", "17", "17.1", "18", "18.1",
    "18.2", "18.3", "20.3", "20.4", "20.5", "21", "22", "22.5",
    "22.6", "23", "24.1"
  )

  library <- numeric()
  for (i in 1:nrow(lookup_lipid_class)) {
    if (lookup_lipid_class[i, "sel.class"] == T) {
      #' key variables
      rounder <- 3 # number of decimals the rounded masses are rounded to.
      #' lipidclass = "TG"
      lipidclass <- row.names(lookup_lipid_class[i, ])


      #' determine how many FAs places to be used for combination and
      #' generate combination of FAs
      FA_number <- as.numeric(lookup_lipid_class[lipidclass, "FA_number"])
      if (fixed == TRUE) FAnum <- FA_number - 1 else FAnum <- FA_number
      s1 <- combn(FA_expt, FAnum)

      #' if one place is fixed add this FA to the matrix
      if (fixed == TRUE) {
        s1 <- rbind(s1, "fixed" = fixed_FA)
        FAnum <- FAnum + 1
      }

      #' if sn2 or sn3 does not have FA bind 'empty' FA channel.
      if (FAnum == 1) {
        s1 <- rbind(s1, sn2 <- vector(mode = "numeric", length = ncol(s1)), sn3 <- vector(mode = "numeric", length = ncol(s1)))
        FAnum <- FAnum + 2
      }
      if (FAnum == 2) {
        s1 <- rbind(s1, sn3 <- vector(mode = "numeric", length = ncol(s1)))
        FAnum <- FAnum + 1
      }


      #' label the matrix
      if (FAnum == 3) row.names(s1) <- c("FA1", "FA2", "FA3")

      #' add rows to matrix for massofFAs and formula
      massofFAs <- vector(mode = "numeric", length = ncol(s1))
      s1 <- rbind(s1, massofFAs)
      formula <- vector(mode = "numeric", length = ncol(s1))
      s1 <- rbind(s1, formula)
      #' row.names(s1) <-c("FA1", "FA2","FA3", "massofFAs")
      for (i in 1:ncol(s1)) {

        #' for 3 FAs
        if (FAnum == 3) {
          FA_1 <- as.character((s1[1, i]))
          FA_2 <- as.character((s1[2, i]))
          FA_3 <- as.character((s1[3, i]))
          s1["massofFAs", i] <- as.numeric((lookup_FA[FA_1, "FAmass"])) + as.numeric((lookup_FA[FA_2, "FAmass"])) + as.numeric((lookup_FA[FA_3, "FAmass"]))
          #' determine the formula
          temp_carbon <- as.numeric((lookup_FA[FA_1, "FAcarbon"])) + as.numeric((lookup_FA[FA_2, "FAcarbon"])) + as.numeric((lookup_FA[FA_3, "FAcarbon"]))
          temp_doublebond <- as.numeric((lookup_FA[FA_1, "FAdoublebond"])) + as.numeric((lookup_FA[FA_2, "FAdoublebond"])) + as.numeric((lookup_FA[FA_3, "FAdoublebond"]))
          s1["formula", i] <- paste(lipidclass, "(", temp_carbon, ":", temp_doublebond, ")", sep = "")
        }
      }

      #' calculate total mass
      totalmass <- vector(mode = "numeric", length = ncol(s1))
      s1 <- rbind(s1, totalmass)

      for (i in 1:ncol(s1)) {
        s1["totalmass", i] <- as.numeric(s1["massofFAs", i]) + as.numeric(as.character(lookup_lipid_class[lipidclass, "headgroup_mass"])) - (as.numeric(lookup_lipid_class[lipidclass, "FA_number"]) * as.numeric(lookup_element["H", "mass"]))
      }

      #' make rows for charged lipids masses
      protonated <- vector(mode = "numeric", length = ncol(s1))
      ammoniated <- vector(mode = "numeric", length = ncol(s1))
      sodiated <- vector(mode = "numeric", length = ncol(s1))
      potassiated <- vector(mode = "numeric", length = ncol(s1))
      deprotonated <- vector(mode = "numeric", length = ncol(s1))
      chlorinated <- vector(mode = "numeric", length = ncol(s1))
      acetate <- vector(mode = "numeric", length = ncol(s1))
      s1 <- rbind(s1, protonated, ammoniated, sodiated, potassiated, deprotonated, chlorinated, acetate)

      #' calculate charged lipids masses
      for (i in 1:ncol(s1)) {
        s1["protonated", i] <- round((as.numeric(s1["totalmass", i]) + as.numeric(lookup_element["H", "mass"])), digits = 4)
        s1["ammoniated", i] <- round((as.numeric(s1["totalmass", i]) + as.numeric(lookup_element["NH4", "mass"])), digits = 4)
        s1["sodiated", i] <- round((as.numeric(s1["totalmass", i]) + as.numeric(lookup_element["Na", "mass"])), digits = 4)
        s1["potassiated", i] <- round((as.numeric(s1["totalmass", i]) + as.numeric(lookup_element["K", "mass"])), digits = 4)
        s1["deprotonated", i] <- round((as.numeric(s1["totalmass", i]) - as.numeric(lookup_element["H", "mass"])), digits = 4)
        s1["chlorinated", i] <- round((as.numeric(s1["totalmass", i]) + as.numeric(lookup_element["Cl", "mass"])), digits = 4)
        s1["acetate", i] <- round((as.numeric(s1["totalmass", i]) + as.numeric(lookup_element["CH3COO", "mass"])), digits = 4)
      }

      #' make rows for rounded charged lipids masses
      round.protonated <- vector(mode = "numeric", length = ncol(s1))
      round.ammoniated <- vector(mode = "numeric", length = ncol(s1))
      round.sodiated <- vector(mode = "numeric", length = ncol(s1))
      round.potassiated <- vector(mode = "numeric", length = ncol(s1))
      round.deprotonated <- vector(mode = "numeric", length = ncol(s1))
      round.chlorinated <- vector(mode = "numeric", length = ncol(s1))
      round.acetate <- vector(mode = "numeric", length = ncol(s1))
      s1 <- rbind(s1, round.protonated, round.ammoniated, round.sodiated, round.potassiated, round.deprotonated, round.chlorinated, round.acetate)

      #' calculate rounded charged lipids masses
      for (i in 1:ncol(s1)) {
        s1["round.protonated", i] <- round(as.numeric(s1["protonated", i]), digits = rounder)
        s1["round.ammoniated", i] <- round(as.numeric(s1["ammoniated", i]), digits = rounder)
        s1["round.sodiated", i] <- round(as.numeric(s1["sodiated", i]), digits = rounder)
        s1["round.potassiated", i] <- round(as.numeric(s1["potassiated", i]), digits = rounder)
        s1["round.deprotonated", i] <- round(as.numeric(s1["deprotonated", i]), digits = rounder)
        s1["round.chlorinated", i] <- round(as.numeric(s1["chlorinated", i]), digits = rounder)
        s1["round.acetate", i] <- round(as.numeric(s1["acetate", i]), digits = rounder)
      }

      library <- cbind(library, s1)
    }
  }
  return(library)
}


#' ========================================================================
#' extract all m/zs from image data
#'
#' @param files spectra raw file (consisting of .imzML and .ibd file);
#' multiple files processing in devleopment, at the moment one file at a time
#' @param spectra_dir Defines the path to the spectral files
#' @param imzMLparse path to imzMLConverter
#' @param thres.int Defines if intensity threshold, above which ions are retained
#' @param thres.low Defines the minumum m/z threshold, above which ions will be retained
#' @param thres.high Defines the minumum m/z threshold, below which ions will be retained
#' @return List containing two elements. The first is a numeric vector
#' containing of all unique masses, the second a list of height, width and
#' height.width in pixels for each file.
#' @export
#' -----------------------------------------------------------------------
#' wl-24-11-2017, Fri: remove spectra_dir
#' -----------------------------------------------------------------------
mzextractor <- function(files, imzMLparse, thres.int = 10000,
                        thres.low = 200, thres.high = 1000) {
  cat("\nStarting mzextractor...\n")

  #' load parse and java
  .jinit()
  .jaddClassPath(path = imzMLparse)

  log <- vector()
  sizes <- list()
  all.mzs <- vector()
  for (a in 1:length(files)) {
    imzML <- J("imzMLConverter.ImzMLHandler")$parseimzML(files[a])
    #' imzML <- J("imzMLConverter.ImzMLHandler")$parseimzML(paste(spectra_dir,substr(files[a],2,100),sep=''))

    width <- J(imzML, "getWidth")
    height <- J(imzML, "getHeight")
    size <- height * width
    sizes[[a]] <- list(height, width, size)

    #' plot(mzs, counts, "l")
    #' determine list of image wide m/z values -> store in vectore s.mz (unique and sorted)
    marker <- 0
    for (i in 1:(height * 1)) {
      for (j in 1:(width * 1)) {
        #' i is width, j is height
        spectrum <- J(imzML, "getSpectrum", as.integer(j), as.integer(i))
        mzs <- J(spectrum, "getmzArray")
        counts <- J(spectrum, "getIntensityArray")
        scan <- cbind("r.mz" = round(mzs, digits = 4), counts)
        f.scan <- scan[scan[, 2] > thres.int, , drop = FALSE]
        all.mzs <- rbind(all.mzs, f.scan[, 1:2])
        #' all.mzs<-c(all.mzs, f.scan[,1])
      }
      #' progress report
      if ((i / height) * 100 > marker + 5) {
        marker <- marker + 5
        print(paste(marker, "% complete", sep = ""))
      }
    }
    print(paste("mzs from", size, "spectra in", files[a], "now read.", sep = " "))
  } #' end of reading in files

  final.size <- 0
  for (a in 1:length(sizes))
    final.size <- final.size + as.numeric(sizes[[a]][3])

  mz <- all.mzs[, 1]
  u.mz <- unique(mz)
  s.mz <- sort(u.mz)
  f.s.mz <- s.mz[s.mz > thres.low & s.mz < thres.high ]

  summary <- paste(length(f.s.mz), "unique ions retained within between",
    thres.low, "m/z and", thres.high, "m/z from", length(u.mz),
    "unique ions detected across all pixels.",
    sep = " "
  )

  print(summary)
  #' output <- list(f.s.mz, sizes)
  output <- list(f.s.mz = f.s.mz, sizes = sizes)
  return(output)
}


#' ========================================================================
#' bin all m/zs by ppm bucket
#'
#' @param extracted Product of mzextractor:list containing matrix of m/zs
#' and intensities in the first element.
#' @param bin.ppm Defines width of the ppm bin.
#' @return List containing two elements. The first is a matrix of extracted
#' m/z and binned m/z for each extracted m/z, the second is a vector of all
#' unique binned m/z values.
#' @export
peakpicker.bin <- function(extracted, bin.ppm = 12) {
  cat("\nStarting peakpicker.bin...\n")

  spectra <- cbind(round(extracted[[1]], digits = 4), "bin.med" = 0)
  marker <- 0
  i <- 1

  #' ptm <- proc.time()
  while (i <= nrow(spectra)) {
    #' group ions into common bin
    result <- spectra[ spectra[, 1] >= spectra[i, 1] & spectra[, 1] <= (spectra[i, 1] + (bin.ppm * spectra[i, 1]) / 1000000), ]

    if (class(result) == "matrix" & spectra[i, "bin.med"] == 0) {
      spectra[i:(i + nrow(result) - 1), 2] <- round(median(result[, 1]), digits = 4)
      i <- i + nrow(result)
    }
    #' if single ion in bin, label with it's m/z
    else {
      spectra[i, 2] <- spectra[i, 1]
      i <- i + 1
    }
    #' progress report
    if (i / nrow(spectra) * 100 > marker + 1) {
      marker <- marker + 1
      print(paste(marker, "% complete", sep = ""))
    }
  }
  #' print(proc.time() - ptm)

  bin.spectra <- spectra
  finalmz <- unique(spectra[, 2])
  summary <- paste(nrow(spectra), "ions across all pixels binned to",
    length(finalmz), "bins.",
    sep = " "
  )
  print(summary)
  #' log <- c(log,summary)

  #' peaks <- list(bin.spectra, finalmz)
  peaks <- list(bin.spectra = bin.spectra, finalmz = finalmz)

  return(peaks)
}


#' ========================================================================
#' Generate subset of first image file to improve speed of deisotoping.
#'
#' @param extracted Product of mzextractor:list containing matrix of m/zs
#' and intensities in the first element.
#' @param peaks Product of peakpicker.bin:list containing a vector of all
#' unique binned m/z values in the 2nd element.
#' @param percentage.deiso Defines the proportion of total pixels to select,
#'   at random from the first file to produce a subset of the image
#' @param thres.int Defines if intensity threshold, above which ions are
#'   retained
#' @param thres.low Defines the minumum m/z threshold, above which ions will
#'   be retained
#' @param thres.high Defines the minumum m/z threshold, below which ions
#'   will be retained
#' @param files a vector of file names
#' @param spectra_dir Defines the path to the spectral files
#' @param imzMLparse path to imzMLConverter
#' @return matrix of subset of first image file. variables are binned
#' peak m/z, observations are pixels (n = percentage.deiso x size)
#' chosen at random from the first image file.
#' @export
#'
#' -----------------------------------------------------------------------
#' wl-24-11-2017, Fri: remove spectra_dir
#' -----------------------------------------------------------------------
subsetImage <- function(extracted, peaks, percentage.deiso = 3, thres.int = 10000,
                        thres.low = 200, thres.high = 2000, files, imzMLparse) {
  cat("\nMaking image subset...\n")

  #' R parser
  .jinit()
  .jaddClassPath(path = imzMLparse)

  sizes <- extracted[[2]]
  bin.spectra <- peaks[[1]]
  finalmz <- peaks[[2]]
  file <- sample(1:length(sizes), 1, replace = F, prob = NULL)

  #' wl-07-11-2017, Tue: change
  #' imzML <- J("imzMLConverter.ImzMLHandler")$parseimzML(paste(getwd(),substr(files[file],2,100),sep=''))
  #' imzML <- J("imzMLConverter.ImzMLHandler")$parseimzML(paste(spectra_dir,substr(files[file],2,100),sep=''))
  #' wl-24-11-2017, Fri: change again
  imzML <- J("imzMLConverter.ImzMLHandler")$parseimzML(files[file])

  subset <- sample(1:as.numeric(sizes[[file]][3]),
    as.numeric(sizes[[file]][3]) * (percentage.deiso / 100),
    replace = FALSE, prob = NULL
  )

  temp.image <- cbind(as.numeric(finalmz), matrix(0,
    nrow = length(finalmz),
    ncol = length(subset)
  ))
  marker <- 0
  for (n in 1:length(subset)) {
    remainder <- subset[n]
    rows <- floor(remainder / as.numeric(sizes[[file]][2]))
    cols <- remainder - (rows * as.numeric(sizes[[file]][2]))
    if (cols == 0) {
      remainder <- remainder - 1
      rows <- floor(remainder / as.numeric(sizes[[file]][2]))
      cols <- remainder - (rows * as.numeric(sizes[[file]][2]))
    }

    #' i is height, j is width
    spectrum <- J(imzML, "getSpectrum", as.integer(cols), as.integer(rows + 1))
    mzs <- J(spectrum, "getmzArray")
    counts <- J(spectrum, "getIntensityArray")

    scan <- cbind("r.mz" = round(mzs, digits = 4), counts)
    f.scan <- scan[scan[, 2] > thres.int & scan[, 1] > thres.low & scan[, 1] < thres.high, , drop = FALSE]

    if (length(f.scan) > 0) {
      for (k in 1:nrow(f.scan)) {
        bin.group <- bin.spectra[which(f.scan[k, 1] == bin.spectra[, 1], arr.ind = T), 2]
        if (length(bin.group) > 0) {
          temp.image[which(temp.image[, 1] == bin.group), n + 1] <- as.numeric(f.scan[k, "counts"])
        }
      }
    }
    if ((n / length(subset) * 100) > marker + 5) {
      marker <- marker + 5
      print(paste(marker, "% done", sep = ""))
    }
  }

  colnames(temp.image) <- c("mzbin", subset)

  return(temp.image)
}


#' ========================================================================
#' Filter to a matrix subset that includes variables above a threshold of
#' missing values
#'
#' @param imagedata.in dataframe containing spectral informaion
#' @param thres.filter Defines threshold for proportion of missing values
#'   (this is the step number, not the actual proportion)
#' @param offset Defines the number of columns that preceed intensitiy values
#' @param steps Sequence of values between 0 and 1 that define the
#'   thresholds of missing values to test
#' @return Matrix of image data containing only variables with a missing
#'   value proporiton below thres.filter.
#' @export
filter <- function(imagedata.in, steps = seq(0, 1, 0.05), thres.filter = 11,
                   offset = 4) {
  cat("\nStarting filter\n")
  zeros <- zeroperrow(steps, as.matrix(imagedata.in[, (offset + 1):ncol(imagedata.in)]))
  image.filtered <- imagedata.in[zeros[[thres.filter]], ]
  return(image.filtered)
}


#' ========================================================================
#' Generate subset of first image file to improve speed of deisotoping.
#'
#' @param ppm Tolerance (ppm) within which mass of isotope must be within
#' @param no_isotopes Number of isotopes to consider (1 or 2)
#' @param prop.1 Proportion of monoisotope intensity the 1st isotope
#'   intensity must not exceed
#' @param prop.2 Proportion of monoisotope intensity the 2nd isotope
#'   intensity must not exceed
#' @param peaks Product of peakpicker.bin:list containing a vector of all
#'   unique binned m/z values in the 2nd element.
#' @param image.sub Product of subset.image: matrix containing intensity
#'   values to average for each binned m/z
#' @param search.mod Search modifications T/F.
#' @param mod modifications to search eg. c(NL=T, label=F, oxidised=T,desat=T)
#' @param lookup_mod A dataframe defining modifications
#'
#' @return List of elements. Each element contains a dataframe with columns
#' for m/z, mean intensity, deisotope annotation, modification annotation.
#' Element 1, 2 and 3 have dataframes contain rows for all peaks, deisotoped
#' and isotopes only.
#' @export
deisotope <- function(ppm = 3, no_isotopes = 2, prop.1 = 0.9, prop.2 = 0.5, peaks,
                      image.sub, search.mod = F,
                      mod = c(NL = T, label = F, oxidised = T, desat = T),
                      lookup_mod) {
  cat("\nStarting deisotoping and difference scanning...\n")

  counts <- round(rowMeans(image.sub[, 2:ncol(image.sub)]), digits = 0)
  spectra <- cbind(peaks[[2]], counts, "", "")
  colnames(spectra) <- c("mz.obs", "intensity", "isotope", "modification")

  C13_1 <- 1.003355
  C13_2 <- C13_1 * 2

  #' set pmm window

  #' make column to store isotope annotation

  #' isotope counter
  k <- 0
  m <- 0

  #' run loop to find isotopes for each ion.
  for (i in (1:nrow(spectra) - 1)) {
    #' values of search
    mass <- as.numeric(spectra[i, 1])
    intensity <- as.numeric(spectra[i, 2])
    #' calculated values
    offset <- (ppm * mass) / 1000000


    #' find isotope with ppm filter on isotpe
    search <- round((mass + C13_1), digits = 3)
    top <- search + offset
    bottom <- search - offset
    result <- spectra[as.numeric(spectra[, "intensity"]) <= (intensity * prop.1) & spectra[, 1] >= bottom & spectra[, 1] <= top & spectra[, "isotope"] == "", ]
    result <- rbind(result, blank1 = "", blank2 = "")

    if (no_isotopes == 2) {
      #' find isotope with ppm filter on isotpe
      search <- round((mass + C13_2), digits = 3)
      top <- search + offset
      bottom <- search - offset
      result_2 <- spectra[as.numeric(spectra[, "intensity"]) <= (intensity * prop.2) & spectra[, 1] >= bottom & spectra[, 1] <= top & spectra[, "isotope"] == "", ]
      result_2 <- rbind(result_2, blank1 = "", blank2 = "")
    }

    result_3 <- vector()
    if (search.mod != F) {
      for (j in 1:nrow(lookup_mod)) {
        if (mod[which(lookup_mod[j, "type"] == rownames(as.data.frame(mod)))] == T) {
          #' find isotope with ppm filter on isotpe
          search <- round(mass + lookup_mod[j, "mass"], digits = 3)
          top <- search + offset
          bottom <- search - offset
          if (0 != length(spectra[ spectra[, 1] >= bottom & spectra[, 1] <= top, ])) {
            temp.hits <- rbind(spectra[ spectra[, 1] >= bottom & spectra[, 1] <= top, ])
            for (l in 1:nrow(temp.hits)) {
              res_3_temp <- c(temp.hits[l, 1], paste(as.vector(lookup_mod[j, "class"]), "(", row.names(lookup_mod[j, ]), ")", sep = ""))
              result_3 <- rbind(result_3, res_3_temp)
            }

            #' res_3_temp <- c(spectra[spectra[,1] >= bottom & spectra[,1] <= top,], paste(as.vector(lookup_mod[j,"class"]), "(", row.names(lookup_mod[j,]),")", sep=""))
          }
        }
      }
    }
    result_3 <- rbind(result_3, blank1 = "", blank2 = "")


    #' result<- as.matrix(result)
    #' add intensity filter
    #' iso_intensity <- (((mass-380)/8.8)/100)*intensity

    if (nrow(result) > 2) {
      k <- k + 1
      spectra[i, "isotope"] <- paste(spectra[i, "isotope"], " ", "[", k, "]", "[M]", sep = "")
      for (j in 1:(nrow(result) - 2)) {
        indices <- which(spectra == result[j, 1], arr.ind = TRUE)
        spectra[indices[, "row"], "isotope"] <- paste(spectra[indices[, "row"], "isotope"], " ", "[", k, "]", "[M+1]", sep = "")
      }
      if (no_isotopes == 2 && nrow(result_2) > 2) {
        for (j in 1:(nrow(result_2) - 2)) {
          indices <- which(spectra == result_2[j, 1], arr.ind = TRUE)
          spectra[indices[, "row"], "isotope"] <- paste(spectra[indices[, "row"], "isotope"], " ", "[", k, "]", "[M+2]", sep = "")
        }
      }
    }
    if (nrow(result_3) > 2) {
      m <- m + 1
      spectra[i, "modification"] <- paste(spectra[i, "modification"], " ", "Precursor[", m, "]", sep = "")
      for (j in 1:(nrow(result_3) - 2)) {
        indices <- which(spectra == result_3[j, 1], arr.ind = TRUE)
        spectra[indices[, "row"], "modification"] <- paste(spectra[indices[, "row"], "modification"], " ", "Fragment[", m, "] ", result_3[j, ncol(result_3)], sep = "")
      }
    }
  }
  allpeaks <- as.data.frame(spectra)
  deisotoped <- allpeaks[(grep("\\[M\\+", allpeaks$isotope, invert = T)), ]
  isotopes <- allpeaks[(grep("\\[M\\+", allpeaks$isotope, invert = F)), ]

  results <- list(allpeaks = allpeaks, deisotoped = deisotoped, isotopes = isotopes)

  summary <- paste(length(as.vector(deisotoped$mz.obs)),
    "monoisotopic peaks retained and",
    length(as.vector(isotopes$mz.obs)),
    "C13 isotopes discarded from",
    length(as.vector(allpeaks$mz.obs)),
    "detected ions",
    sep = " "
  )
  print(summary)
  return(results)
}


#' ========================================================================
#' Performs identification of lipids and adducts
#'
#' @param ionisation_mode "positive" or "negative" determines which adducts
#'   to search for
#' @param deisotoped Product of function 'deisotope': list with dataframe in
#'   the second element containing image data for deisotoped data
#' @param adducts vector of adducts to be searched in the library of lipid
#'   masses
#' @param ppm.annotate Defines if ppm threshold for which |observed m/z -
#'   theotical m/z| must be less than for annotation to be retained
#' @param dbase The product of library - dataframe containing lipid massess.
#' @return Character vector containing annotations
#' @export
#'
#' wl-07-11-2017, Tue: should remove adducts in function arguments
#'
annotate <- function(ionisation_mode, deisotoped,
                     #' adducts=c(H = T, NH4 = F, Na = T, K = T, dH = F, Cl = F, OAc = F),
                     ppm.annotate = 10, dbase) {
  cat("\nStarting annotation\n")

  d.finalmz <- as.vector(deisotoped[[2]]$mz.obs) #' deisotoped
  s1 <- dbase
  spectra <- cbind(round(as.numeric(d.finalmz), digits = 3), d.finalmz)
  combined <- vector()
  sel.adducts <- vector()
  index <- 13 # offset to search only rounded masses in library

  if (ionisation_mode == "positive") {
    adducts <- c(H = T, NH4 = F, Na = T, K = T, dH = F, Cl = F, OAc = F)
  }
  if (ionisation_mode == "negative") {
    adducts <- c(H = F, NH4 = F, Na = F, K = F, dH = T, Cl = T, OAc = F)
  }
  for (a in 1:length(adducts)) {
    if (adducts[a] == T) sel.adducts <- c(sel.adducts, index + a)
  }
  for (i in 1:nrow(spectra)) {
    search <- as.numeric(spectra[i, 1])
    offset <- (ppm.annotate * search) / 1000000
    top <- search + offset
    bottom <- search - offset
    result <- which(s1[sel.adducts, ] >= bottom & s1[sel.adducts, ] <= top, arr.ind = TRUE)
    if (nrow(result) > 0) {
      for (j in 1:nrow(result))
      {
        col <- result[j, "col"]
        row <- result[j, "row"]
        row <- sel.adducts[row]
        #' determine the adduct that was matched, summarising match information from library for matched mass (as 'data')
        #' determine which adduct
        if (row == "14") {
          adduct <- "protonated"
          name.adduct <- "H"
        }
        if (row == "15") {
          adduct <- "ammoniated"
          name.adduct <- "NH4"
        }
        if (row == "16") {
          adduct <- "sodiated"
          name.adduct <- "Na"
        }
        if (row == "17") {
          adduct <- "potassiated"
          name.adduct <- "K"
        }
        if (row == "18") {
          adduct <- "deprotonated"
          name.adduct <- "-H"
        }
        if (row == "19") {
          adduct <- "chlorinated"
          name.adduct <- "Cl"
        }
        if (row == "20") {
          adduct <- "acetate"
          name.adduct <- "OAc"
        }

        a.ppm <- round(abs(((as.numeric(spectra[i, 2]) - as.numeric(s1[adduct, col])) / as.numeric(spectra[i, 2])) * 1000000), digits = 1)

        #' make vector with summary of match and paired match
        data <- c(
          s1[row, col], s1[adduct, col], spectra[i, 2], a.ppm,
          s1["formula", col], name.adduct, s1["protonated", col],
          s1["FA1", col], s1["FA2", col], s1["FA3", col]
        )

        #' make matrix of search results
        combined <- rbind(combined, unlist(data, use.names = F))
      }
    }
  }
  if (length(combined) > 0) {
    colnames(combined) <- c(
      "mz.matched", "mz.matched.lib", "mz.observed",
      "ppm", "formula", "adduct", "mz.lib.protonated",
      "FA1", "FA2", "FA3"
    )

    ids <- unique.matrix(combined[, c(3, 5, 6)])
    annotations <- cbind(d.finalmz, "")
    for (i in 1:nrow(annotations)) {
      result <- which(ids[, 1] == annotations[i, 1], arr.ind = T)
      if (length(result) > 0) {
        for (j in 1:length(result)) {
          annotations[i, 2] <- paste(annotations[i, 2], "[", ids[result[j], "formula"], "+", ids[result[j], "adduct"], "]", sep = "")
        }
      }
    }

    #' image.roi<-cbind(image.roi[,2:ncol(image.roi)])
    #' vresults<-cbind(annotations[,2], image.roi[,1],image.roi[,2:ncol(image.roi)])
    #' colnames(image)<-c("annoation","modification","bin.mz", files)

    summary <- paste(length(annotations[annotations[, 2] != "", 2]),
      "from", length(as.vector(deisotoped[[2]]$mz.obs)),
      "monoisotopic peaks were annoated (using accuract mass) with a",
      ppm.annotate, "ppm tollerance",
      sep = " "
    )
    print(summary)

    return(annotations[, 2])
  }
  if (length(combined) == 0) {
    print("No annotations were made")
  }
}


#' ========================================================================
#' construct dataframe of image data
#'
#' @param extracted Product of mzextractor: list containing a list of the
#'   image diminsions in the 2nd element.
#' @param deisotoped Product of deisotope
#' @pgqaram peaks Product of peakpicker.bin:list containing a matrix of all
#'   peaks and the corresponding m/z bin in the first element.
#' @param imzMLparse path to imzMLConverter
#' @param spectra_dir Defines the path to the spectral files
#' @param thres.int Defines if intensity threshold, above which ions are
#'   retained
#' @param thres.low Defines the minumum m/z threshold, above which ions will
#'   be retained
#' @param thres.high Defines the minumum m/z threshold, below which ions
#'   will be retained
#' @param files a vector of file names
#' @return Dataframe of image data. Variables are deisotoped binned m/z,
#' observations are pixels. For image of width w and height h, the number of
#' columns is w x h. The first w columns are from the first row (from left
#' to right), the next w columns are the next row, from left to right and so
#' on. List, first element is has column containing m/z values preceeding
#' image data, second element has 4 columns preceeding image data which
#' include m/z, annotation, isotope status, modification status.
#' @export
#' -----------------------------------------------------------------------
#' wl-24-11-2017, Fri: remove spectra_dir
#' -----------------------------------------------------------------------
contructImage <- function(extracted, deisotoped, peaks, imzMLparse,
                          thres.int = 10000, thres.low = 200,
                          thres.high = 1000, files) {
  cat("\nStarting 'constructImage'...\n")

  .jinit()
  .jaddClassPath(path = imzMLparse)

  sizes <- extracted[[2]]
  final.size <- 0
  for (a in 1:length(sizes))
    final.size <- final.size + as.numeric(sizes[[a]][3])

  bin.spectra <- peaks[[1]]
  d.finalmz <- as.vector(deisotoped[[2]]$mz.obs)

  image <- cbind(
    as.numeric(d.finalmz),
    matrix(0, nrow = length(d.finalmz), ncol = final.size)
  )

  for (a in 1:length(files)) {
    height <- as.numeric(sizes[[a]][1])
    width <- as.numeric(sizes[[a]][2])

    #' wl-24-11-2017, Fri: remove spectra_dir here
    #' imzML <- J("imzMLConverter.ImzMLHandler")$parseimzML(paste(spectra_dir,substr(files[a],2,100),sep=''))
    imzML <- J("imzMLConverter.ImzMLHandler")$parseimzML(files[a])

    marker <- 0
    for (i in 1:height) {
      for (j in 1:width) {
        spectrum <- J(imzML, "getSpectrum", as.integer(j), as.integer(i))
        mzs <- J(spectrum, "getmzArray")
        counts <- J(spectrum, "getIntensityArray")

        scan <- cbind("r.mz" = round(mzs, digits = 4), counts)
        f.scan <- scan[scan[, 2] > thres.int & scan[, 1] > thres.low & scan[, 1] < thres.high, , drop = FALSE]

        if (length(f.scan) > 0) {
          for (k in 1:nrow(f.scan)) {
            bin.group <- bin.spectra[which(f.scan[k, 1] == bin.spectra[, 1], arr.ind = T), 2]
            if (length(bin.group) > 0) {
              image[which(image[, 1] == bin.group), ((i - 1) * width) + (j + 1)] <- as.numeric(f.scan[k, "counts"])
            }
            #' if(length(result)>0) image[result,((i-1)*width)+(j+1)]<- agg.mzs[k,"counts"]
          }
        }
      }
      #' progress report

      if ((i / height) * 100 > marker + 1) {
        marker <- marker + 1
        print(paste(marker, "% done", sep = ""))
      }
    }
  }

  cat("\nimzMLcube constructed!\n")

  return(image)
}


#' ========================================================================
#' Normalise image data
#'
#' @param imagedata.in Product of 'constructImage' function.
#' @param norm.type Mode of normalisation. Valid argument: "standards",
#' "TIC", "median", "none".
#' @param standards vector of row indices corresponding to variables that
#'   are standards.
#' @param offset number of columns that preceed image data
#' @return Normalised dataframe containing image data.
#' @export
normalise <- function(imagedata.in = image.ann, norm.type = "TIC",
                      standards = NULL, offset = 4) {
  if (norm.type == "standards") {
    #' from standards
    images.f.n <- norm.standards(imagedata.in, offset, standards)
    imagedata.in <- images.f.n
  }
  if (norm.type == "TIC") {
    #' from TIC
    images.f.n <- norm.TIC(imagedata.in, offset)
    image
    imagedata.in <- images.f.n
  }
  if (norm.type == "median") {
    #' from median
    images.f.n <- norm.median(imagedata.in, offset)
    imagedata.in <- images.f.n
  }
  if (norm.type == "none") {
    #' no normalisation
    imagedata.in <- imagedata.in
  }
  return(imagedata.in)
}


#' ========================================================================
#' Normalise data to the median ion current
#'
#' @param imagedata.in Product of 'constructImage' function.
#' @param offset number of columns that preceed image data
#' @export
#' -----------------------------------------------------------------------
#' wl-08-11-2017, Wed: rowMedians can be replaced by median. Example of
#' rowMedians in `Biobase`:
#' -----------------------------------------------------------------------
#'   set.seed(1)
#'   x <- rnorm(n=234*543)
#'   x[sample(1:length(x), size=0.1*length(x))] <- NA
#'   dim(x) <- c(234,543)
#'   y1 <- rowMedians(x, na.rm=TRUE)
#'   y2 <- apply(x, MARGIN=1, FUN=median, na.rm=TRUE)
#'   stopifnot(all.equal(y1, y2))
#'   x <- cbind(x1=3, x2=c(4:1, 2:5))
#'   stopifnot(all.equal(rowMeans(x), rowMedians(x)))
norm.median <- function(imagedata.in, offset) {
  if (F) {
    library(Biobase)
    medians.1 <- as.vector(rowMedians(t(as.matrix(imagedata.in[, (offset + 1):ncol(imagedata.in)], na.rm = T))))
    #' wl-29-01-2018, Mon: The parentheses for `na.rm = T` is wrong.
  } else {
    #' wl-29-01-2018, Mon: Do not use `rowMedians` in `Biobase`.
    tmp <- t(as.matrix(imagedata.in[, (offset + 1):ncol(imagedata.in)]))
    medians <- apply(tmp, MARGIN = 1, FUN = median, na.rm = TRUE)
    medians <- as.vector(medians)
  }

  factor <- medians / mean(medians)
  image.norm <- cbind(imagedata.in[, 1:offset], t(t(imagedata.in[, (offset + 1):ncol(imagedata.in)]) / factor))
  empty.spectra <- which(factor == 0, arr.ind = TRUE)
  if (length(empty.spectra) > 1) {
    for (i in 1:length(empty.spectra)) {
      for (j in 1:nrow(image.norm)) image.norm[j, empty.spectra[i] + offset] <- 0
    }
  }
  image.norm <- cbind(imagedata.in[, 1:offset], image.norm[, (offset + 1):ncol(image.norm)])
  #' hist(factor, breaks=100)
  image.norm
}


#' ========================================================================
#' Normalise data to standards
#' @param imagedata.in Product of 'constructImage' function.
#' @param offset number of columns that preceed image data
#' @param standards vector of row indices corresponding to variables that are standards.
#' @export
#' wl-30-01-2018, Tue: modify and debug
norm.standards <- function(imagedata.in, offset, standards = NULL) {
  #' norm.standards <- function(imagedata.in, offset, standards){

  #' wl-30-01-2018, Tue: do not plot too many boxplots
  if (F) {
    for (i in 1:length(standards))
      boxplot(as.vector(t(imagedata.in[standards[i], (offset + 1):length(imagedata.in)])),
        main = paste("distribution of standard",
          imagedata.in[standards[i], 1], ".",
          sep = " "
        )
      )
  }

  #' wl-30-01-2018, Tue: added.
  if (is.null(standards)) {
    standards <- 1:nrow(imagedata.in)
  }

  av <- mean(colMeans(imagedata.in[standards, (offset + 1):length(imagedata.in)]))
  norm <- t(imagedata.in[, (offset + 1):ncol(imagedata.in)]) / colMeans(imagedata.in[standards, (offset + 1):length(imagedata.in)])

  norm <- norm * av
  norm.rep <- replace(norm, norm == "NaN", 0)
  norm.rep <- replace(norm.rep, norm == "Inf", 0)
  image.norm <- cbind(imagedata.in[, 1:offset], t(norm.rep))
  image.norm
}


#' ========================================================================
#' Normalise data to the TIC
#' @param imagedata.in Product of 'constructImage' function.
#' @param offset number of columns that preceed image data
#' @export
norm.TIC <- function(imagedata.in, offset) {
  sums <- as.vector(colSums(imagedata.in[, (offset + 1):ncol(imagedata.in)],
    na.rm = T
  ))
  factor <- sums / mean(sums)
  image.norm <- cbind(
    imagedata.in[, 1:offset],
    t(t(imagedata.in[, 5:ncol(imagedata.in)]) / factor)
  )

  empty.spectra <- which(factor == 0, arr.ind = TRUE)
  if (length(empty.spectra) > 0) {
    for (i in 1:length(empty.spectra)) {
      for (j in 1:nrow(image.norm)) image.norm[j, empty.spectra[i] + offset] <- 0
    }
  }
  image.norm <- cbind(
    imagedata.in[, 1:offset],
    image.norm[, (offset + 1):ncol(image.norm)]
  )

  #'  hist(factor, breaks=100)
  return(image.norm)
}

#' ========================================================================
#' Remove outliers for image analysis
#'
#' @param x image data in
#' @param na.rm remove missing values
#' @param replace.1.min initial value to replace minimum values with
#' @param replace.1.max initial value to replace maximum values with
#' @return matrix of image data with outliers removed
#' @export
remove_outliers <- function(x, na.rm = TRUE, replace.1.min, replace.1.max) {
  qnt <- quantile(x, probs = c(.25, .75), na.rm = na.rm)
  H <- 1.5 * IQR(x, na.rm = na.rm)
  y <- x
  y[x < (qnt[1] - H)] <- replace.1.min
  y[x > (qnt[2] + H)] <- replace.1.max

  y[x < (qnt[1] - H)] <- min(y)
  y[x > (qnt[2] + H)] <- max(y)
  y
}

#' ========================================================================
#' Rescale image values
#'
#' @param x image date in
#' @param scale range of scaled data
#' @return matrix of scaled data
#' @export
rescale <- function(x, scale) {
  ((x - min(x)) / (max(x) - min(x))) * scale
}

#' ========================================================================
#' Normalise image data
#'
#' @param imagedata.in Product of 'constructImage' function.
#' @param scale.type Mode of scaling Valid argument: "c", "cs", "none" for
#'   centre and center + pareto scaling, respectively .
#' @param transform log transform data T/F
#' @param offset number of columns that precede image data
#' @return Centred, scaled, transformed dataframe containing image data.
#' @export
centreScale <- function(imagedata.in = image.ann, scale.type = "cs", transform = F,
                        offset = 4) {
  #' matrix of non-transformed data
  if (transform == F) {
    matr <- as.matrix(imagedata.in[, (offset + 1):ncol(imagedata.in)])
  }
  #' log transform data to remove heteroscedasticity
  if (transform == T) {
    matr <- as.matrix(log(imagedata.in[, (offset + 1):ncol(imagedata.in)] + 1))
    #' log of 0 causes -inf values so +1..zeros (missing values) become 0
  }

  matr[matr == 0] <- NA # replace zeros for NA so they are ommited from center and scaling


  if (scale.type == "c") {
    matr <- as.matrix(log(imagedata.in[, (offset + 1):ncol(imagedata.in)] + 1))
    #' log of 0 causes -inf values so +1..zeros (missing values) become 0     }
  }
  if (scale.type == "cs") {
    matr <- t(scale(t(matr), center = TRUE, scale = apply(t(matr), 2, function(x) sqrt(sd(x, na.rm = TRUE)))))
    #' mean center and pareto scale
  }
  if (scale.type == "pareto") {
    matr <- t(scale(t(matr), center = FALSE, scale = apply(t(matr), 2, function(x) sqrt(sd(x, na.rm = TRUE)))))
    #' pareto scale only for slicing=T
  }
  if (scale.type == "none") {
    matr <- matr # no scaling
  }
  #' replace NA with value (in this case 0)
  matr[which(is.na(matr))] <- 0

  imagedata.in <- cbind(imagedata.in[, 1:offset], matr)
  return(imagedata.in)
}


#' ========================================================================
#' determine the number of zeros per row in a matrix
#' @param steps Sequence of values between 0 and 1 that define the
#'   thresholds of missing values to test
#' @param matrix Matrix of image data
#' @return List of row indices corresponing to variables that were retained
#'   at each thres.filter step.
#' @export
#' -----------------------------------------------------------------------
#' wl-25-11-2017, Sat: add plot.f
zeroperrow <- function(steps, matrix, plot.f = FALSE) {
  #' filter summary for MVA
  indices <- list()
  results <- vector()
  counter <- 1
  for (threshold in steps) {
    filter <- vector()
    for (i in 1:nrow(matrix)) {
      if ((length(which(matrix[i, ] < 1)) / ncol(matrix)) <= threshold) filter <- c(filter, i)
    }
    print(paste("Step ", counter, ": ", length(filter), " records at ", threshold, " threshold.", sep = ""))
    #' record the retained indices at each threshold
    indices[counter] <- list(filter)
    results <- c(results, length(matrix[filter, 1]))
    counter <- counter + 1
  }

  if (plot.f) {
    plot(steps, results[1:(length(results))],
      ylab = "Number of ions",
      xlab = "% missing values",
      main = "Coverage of ions across selected pixels", type = "s"
    )
  }
  #' results
  return(indices)
}


#' ========================================================================
#' Create heat map for PCA image
#'
#' Generate heat map based on spectral information.
#'
#' @param imagedata.in Dataframe containing image data.
#' @param offset number of columns preceeding image data
#' @param PCnum number of PCs to consider
#' @param scale range of scale that intensity values will be scaled to.
#' @param x.cood width of image.
#' @param y.cood height of image.
#' @param nlevels Graduations of colour scale.
#' @param res.spatial spatial resolution of image
#' @param rem.outliers Remove intensities that are outliers, valid arguments: "only", "true".
#' @param summary T/F
#' @param title show titles, T/F".
#' @return heatmap image
#' @export
imagePca <- function(imagedata.in, offset, PCnum, scale, x.cood, y.cood, nlevels,
                     res.spatial, summary, title = T, rem.outliers = TRUE) {
  #' res.spatial,summary, title=T, rem.outliers="only"){

  pca <- princomp(t(imagedata.in[, (offset + 1):ncol(imagedata.in)]),
    cor = FALSE, scores = TRUE, covmat = NULL
  )

  for (i in 1:PCnum) {
    imageSlice(
      row = i, imagedata.in = t(pca$scores), scale, x.cood, y.cood,
      nlevels, name = paste("PC", i, sep = ""), subname = "", offset = 0,
      res.spatial, rem.outliers, summary, title
    )

    labs.all <- as.numeric(as.vector(imagedata.in[, 1]))
    perc <- 5 # percent of data to label
    y <- cut(pca$loadings[, i],
      breaks = c(
        -Inf, quantile(pca$loadings[, i], p = c(perc / 100)),
        quantile(pca$loadings[, i], p = c(1 - (perc / 100))),
        Inf
      ),
      labels = c("low", "mid", "long")
    )

    labs <- labs.all
    labs[which(y == "mid")] <- ""

    plot(
      x = as.numeric(as.vector(imagedata.in[, 1])), y = pca$loadings[, i],
      type = "n", main = paste("PC", i, " loadings", sep = ""), xlab = "m/z",
      ylab = "p[4]"
    )
    lines(
      x = as.numeric(as.vector(imagedata.in[, 1])), y = pca$loadings[, i],
      type = "h"
    )
    textxy(
      X = as.numeric(as.vector(imagedata.in[, 1])), Y = pca$loadings[, i],
      labs = labs, cx = 0.5, dcol = "black", m = c(0, 0)
    )
    #' wl-23-08-2017, Wed: 'textxy' (from 'calibrate') places labels in a plot
  }
}

#' ========================================================================
#' Generate heat map based on spectral information.
#'
#' @param row indices of row which corresponds to spectral data to plot;
#' use image.norm_short.csv to hel identify row number of interest
#' @param imagedata.in Dataframe containing image data
#' @param scale range of scale that intensity values will be scaled to
#' @param x.cood width of image
#' @param y.cood height of image
#' @param nlevels Graduations of colour scale
#' @param name main name of image
#' @param subname sub name of image
#' @param res.spatial spatial resolution of image
#' @param offset number of columns preceding image data
#' @param rem.outliers Remove intensities that are outliers, valid arguments:
#' "only" (without outliers only) or T (with and without outliers0)
#' @param summary T/F
#' @param title show titles, T/F
#' @return heatmap image
#' @export
#'
#' ------------------------------------------------------------------------
#' wl-23-08-2017, Wed: 'filled.contour' {graphics}: This function produces a
#' contour plot with the areas between the contours filled in solid color
#' (Cleveland calls this a level plot). A key showing how the colors map to
#' z values is shown to the right of the plot.
#' ------------------------------------------------------------------------
#' wl-19-11-2017, Sun:
#'  1.) @param rem.outliers Remove outliers or not
#'  2.) change 'summary' condition. Default is FALSE
#' ------------------------------------------------------------------------

imageSlice <- function(row, imagedata.in, scale, x.cood, y.cood, nlevels, name,
                       subname, offset, res.spatial, rem.outliers, summary,
                       title = T) {
  slice <- as.numeric(as.vector(as.matrix(imagedata.in[row, (1 + offset):ncol(imagedata.in)])))
  #' wl-24-08-2017: take intensity for one m/z. (1+offset):ncol(imagedata.in)
  #' is for only numeric values.

  #' -----------------------------------------------------------------------
  #' if(rem.outliers != "only"){
  if (!rem.outliers) { #' wl-19-11-2017, Sun: changed
    #' if(summary==F){
    if (summary) { #' wl-19-11-2017, Sun: changed. Should be TRUE
      boxplot(slice,
        main = (paste("distribution with 'outliers' for", imagedata.in[row, 1], ".", sep = " ")),
        cex.main = 1
      )

      hist(slice,
        breaks <- seq(min(slice), max(slice), (max(slice) - min(slice)) / 100),
        prob = T,
        main = paste("distribution with 'outliers' for", imagedata.in[row, 1], ".", sep = " "),
        cex.main = 1
      )

      lines(density(slice), col = "red", lwd = 2)
    }

    rescaled <- rescale(slice, scale)
    section <- t(matrix(rescaled, nrow = y.cood, ncol = x.cood, byrow = T))

    filled.contour(
      x = seq(from = 1, to = x.cood, length = x.cood) * res.spatial,
      y = seq(from = 1, to = y.cood, length = y.cood) * res.spatial,
      z = section,
      nlevels = 50,
      axes = TRUE,
      asp = 1,
      plot.title = title(xlab = "x (micrometers)", ylab = "y (micrometers)", cex.axis = 0.5),
      color.palette = topo.colors
    )
    if (title == T) {
      title(main = paste("with outliers", name, sep = " "), cex.main = 1)
    }
    title(sub = subname, cex.sub = 1 / 2)
  }

  #' -----------------------------------------------------------------------
  #' if(rem.outliers == T || rem.outliers == "only"){
  if (rem.outliers) { #' wl-19-11-2017, Sun: changed
    slice <- remove_outliers(x = slice, na.rm = TRUE, replace.1.min = 0, replace.1.max = 0)

    #' if(summary==F){
    if (summary) { #' wl-19-11-2017, Sun: changed. Should be TRUE
      boxplot(slice, main = (paste("distribution without 'outliers' for", imagedata.in[row, 1], ".", sep = " ")), cex.main = 1)
      hist(slice, breaks <- seq(min(slice), max(slice), (max(slice) - min(slice)) / 100),
        prob = T, main = paste("distribution without 'outliers' for", imagedata.in[row, 1], ".", sep = " "), cex.main = 1
      )
      lines(density(slice), col = "red", lwd = 2)
    }

    rescaled <- rescale(slice, scale)
    section <- t(matrix(rescaled, nrow = y.cood, ncol = x.cood, byrow = T))

    filled.contour(
      x = seq(from = 1, to = x.cood, length = x.cood) * res.spatial,
      y = seq(from = 1, to = y.cood, length = y.cood) * res.spatial,
      z = section,
      nlevels = 50,
      axes = TRUE,
      asp = 1,
      plot.title = title(xlab = "x (micrometers)", ylab = "y (micrometers)", cex.axis = 0.5),
      color.palette = topo.colors
    )
    if (title == T) {
      title(main = paste("without outliers", name, sep = " "), cex.main = 1)
    }
    title(sub = subname, cex.sub = 1 / 2)
  }
}

#' ========================================================================
#' k-means clustering for imaging processing
#' @param cluster.type Currently only "kmeans" suported
#' @param imagedata.in Dataframe containing image data
#' @param offset columns preceding data
#' @param res.spatial spatial resolution of the image
#' @param width width of image; x.cood
#' @param height height of image; y.cood
#' @param clusters number of desired clusters
#' @return clustered images and cluster centers; writes csv files for
#'   cluster centers
#' @export
#'
#' ------------------------------------------------------------
#' wl-13-02-2018, Tue: return intensity for saving option

cluster <- function(cluster.type = cluster.type, imagedata.in = imagedata.in,
                    offset = offset, res.spatial = res.spatial, width = x.cood,
                    height = y.cood, clusters = clusters) {

  #' to do k-means clustering based on spectral similarity of pixels
  if (cluster.type == "kmeans") {
    k <- kmeans(t(imagedata.in[, (offset + 1):ncol(imagedata.in)]), clusters)

    #' rearrange your matrix to fit in image space, where nrow=y and ncol=x
    #' transpose for the heatmap

    k.matrix <- data.frame()
    k.matrix <- matrix(k$cluster, nrow = height, ncol = width, byrow = T)
    t.k.matrix <- t(k.matrix)

    #' plot the heatmap, choose colour scheme and colour according to cluster class
    filled.contour(
      x = seq(1, width, length = width) * res.spatial,
      y = seq(1, height, length = height) * res.spatial,
      z = t.k.matrix,
      col = grey(seq(0, 1, length = 10)),
      #' color.palette=topo.colors,
      axes = TRUE,
      nlevels = 12,
      #' col=rainbow(10, alpha=0.5),
      asp = 1,
      plot.title = title(xlab = "x (micrometers)", ylab = "y (micrometers)", cex.axis = 0.5),
      key.title = title("Cluster")
    )
    title(main = paste("k-means clustering -", clusters, "clusters", sep = " "), cex.main = 1)

    #' ------------------------------------------------------------
    #' wl-13-02-2018, Tue: get intensity matrix
    colnames(k$centers) <- imagedata.in[, 1]
    mz <- as.numeric(colnames(k$centers))
    Intensity <- k$centers
    rownames(Intensity) <- paste0("Cluster", 1:nrow(Intensity))

    for (i in 1:clusters) { #' i = 2
      #' wl-13-02-2018, Tue: move out this loop
      #' colnames(k$centers) <- imagedata.in[,1]
      #' mz <- as.numeric(colnames(k$centers))
      #' Intensity <- k$centers[i,]
      #' plot(mz, Intensity, "h")

      plot(mz, Intensity[i, ], "h")
      abline(0, 0)
      title(main = paste("Cluster", i, sep = " "))

      #' wl-24-08-2017: plot only this cluster and disable others using level
      #' plot.

      one.cluster <- t.k.matrix
      one.cluster[one.cluster[, ] != i] <- 0 #' wl-24-08-2017: remove other clusters.

      filled.contour(
        x = seq(1, width, length = width) * res.spatial,
        y = seq(1, height, length = height) * res.spatial,
        z = one.cluster,
        #' col=grey(seq(0,1,length=2)),
        col = c("black", sample(rainbow(10), 1)),
        #' col=c("black", "purple"),
        axes = TRUE,
        nlevels = 2,
        asp = 1,
        plot.title = title(xlab = "x (micrometers)", ylab = "y (micrometers)", cex.axis = 0.5),
      )
      title(main = paste("k-means clustering -", "Cluster", i, sep = " "), cex.main = 1)

      #' wl-07-11-2017, Tue: any output should be outside function
      #' write.csv(Intensity, paste("Cluster_",i,".csv"))
    }
    Intensity #' wl-13-02-2018, Tue: return Intensity
  }
}

#' ========================================================================
#' wrapper to process image data
#'
#' @param process T to process data from imzML, F to skip processing
#' @param pca T to conduct PCA image analysis
#' @param slice T to generate two dimensional image of one ion defined in row
#' @param cluster.k T to perform clustering
#' @param ionisation_mode Choose "positive" or "negative"; determines which lipid classes to use when building database
#' @param thres.int Defines if intensity threshold, above which ions are retained
#' @param thres.low Defines the minumum m/z threshold, above which ions will be retained
#' @param thres.high Defines the minumum m/z threshold, below which ions will be retained
#' @param bin.ppm Mass accuracy for binning between spectra
#' @param thres.filter Defines threshold for proportion of missing values (this is the step number, not the actual proportion)
#' @param ppm.annotate Defines if ppm threshold for which |observed m/z - theotical m/z| must be less than for annotation to be retained
#' @param res.spatial spatial resolution of image
#' @param PCnum number of PCs to calculate
#' @param row indices of row which corresponds to spectral data to plot in image slice - use image.norm_short.csv to find row number
#' @param cluster.type At the moment only supports "kmeans"
#' @param clusters Number of clusters to use for clustering
#' @param ppm Tolerance (ppm) within which mass of isotope must be within .
#' @param no_isotopes Number of isotopes to consider (1 or 2)
#' @param prop.1 Proportion of monoisotope intensity the 1st isotope intensity must not exceed
#' @param prop.2 Proportion of monoisotope intensity the 2nd isotope intensity must not exceed
#' @param search.mod Search modifications T/F.
#' @param mod modifications to search eg. c(NL=T, label=F, oxidised=T,desat=T)
#' @param lookup_mod A dataframe defining modifications
#' @param adducts vector of adducts to be searched in the library of lipid masses
#' @param sel.class A vector defining classes of lipids to be included in the library
#' @param fixed Defines if one of the SN positions is fixed, default is F.
#' @param fixed_FA Defines the name of the fixed FA is fixed is T, e.g. 16, 16.1, 18.2.
#' @param lookup_lipid_class A data.frame defining lipid classes
#' @param lookup_FA A dataframe defining FAs
#' @param lookup_element A dataframe defining elements
#' @param files a vector of file names; currently only supports processing one file at a time
#' @param spectra_dir Defines the path to the spectral files,
#' @param imzMLparse path to imzMLConverter
#' @param percentage.deiso Defines the proportion of total pixels to select, at random from the first file to produce a subset of the image
#' @param steps Sequence of values between 0 and 1 that define the thresholds of missing values to test
#' @param imagedata.in Dataframe containing image
#' @param norm.type "TIC" or "median" or "standards" or "none", recommend "TIC"
#' @param standards default is NULL, vector of row indices corresponding to variables that are standards
#' @param scale.type options are "cs" center and pareto scale, "c" center only, "pareto" pareto only and "none"
#' @param scale range of scale that intensity values will be scaled to
#' @param transform T/F to perform log transform
#' @param x.cood width of image
#' @param y.cood height of image
#' @param nlevels Graduations of colour scale.
#' @param name main name of image.
#' @param subname sub name of image
#' @param rem.outliers Choose "only" to show only images after removing outliers, T for both with and without outliers
#' @param summary T/F to show extra information
#' @param title show titles, T/F
#' @param offset number of columns of text preceding data
#'
#' @return Dataframe of annotated image data. Variables are deisotoped
#' binned m/z, observations are pixels. For image of width w and height h,
#' the number of columns is w x h. The first w columns are from the first
#' row (from left to right), the next w columns are the next row, from left
#' to right and so on.
#' @export
massPix <- function(
                    process = T,
                    pca = T,
                    slice = T,
                    cluster.k = T,
                    ionisation_mode = "positive",
                    thres.int = 500000,
                    thres.low = 200,
                    thres.high = 1000,
                    bin.ppm = 12,
                    thres.filter = 11,
                    ppm.annotate = 12,
                    res.spatial = 50,
                    PCnum = 5,
                    row = 50,
                    cluster.type = "kmeans",
                    clusters = 6,
                    ppm = 3,
                    no_isotopes = 2,
                    prop.1 = 0.9,
                    prop.2 = 0.5,
                    search.mod = T,
                    mod = c(NL = T, label = F, oxidised = T, desat = T),
                    lookup_mod,
                    adducts,
                    sel.class,
                    fixed = F,
                    fixed_FA,
                    lookup_lipid_class,
                    lookup_FA,
                    lookup_element,
                    files,
                    #' spectra_dir,
                    lib_dir, #' wl-07-11-2017, Tue: added
                    imzMLparse,
                    percentage.deiso = 3,
                    steps = seq(0, 1, 0.05),
                    imagedata.in = imagedata.in,
                    norm.type = "TIC",
                    standards = NULL,
                    scale.type = "cs",
                    transform = F,
                    scale = 100,
                    x.cood = x.cood,
                    y.cood = y.cood,
                    nlevels = 50,
                    #' name = "",
                    #' subname = "",
                    rem.outliers = "only",
                    summary = T,
                    title = T,
                    offset = 4) {

  #' setting up, reading library files
  #' to read and process very large files
  options(java.parameters = "Xmx4g")

  #' read in library files
  setwd(lib_dir)
  read <- read.csv("lib_FA.csv", sep = ",", header = T)
  lookup_FA <- read[, 2:4]
  row.names(lookup_FA) <- read[, 1]

  read <- read.csv("lib_class.csv", sep = ",", header = T)
  lookup_lipid_class <- read[, 2:3]
  row.names(lookup_lipid_class) <- read[, 1]

  read <- read.csv("lib_element.csv", sep = ",", header = T)
  lookup_element <- read[, 2:3]
  row.names(lookup_element) <- read[, 1]

  read <- read.csv("lib_modification.csv", sep = ",", header = T)
  lookup_mod <- read[, 2:ncol(read)]
  row.names(lookup_mod) <- read[, 1]

  #' parsing the data and getting x and y dimensions
  imzMLparse <- paste(home_dir, "imzMLConverter/imzMLConverter.jar", sep = "") # spectra files

  setwd(spectra_dir)
  files <- list.files(, recursive = TRUE, full.names = TRUE, pattern = ".imzML")

  setwd(spectra_dir)
  .jinit()
  .jaddClassPath(path = imzMLparse)
  imzML <- J("imzMLConverter.ImzMLHandler")$parseimzML(paste(getwd(), substr(files, 2, 100), sep = ""))
  x.cood <- J(imzML, "getWidth")
  y.cood <- J(imzML, "getHeight")

  #' make library
  if (process == T) {
    dbase <- makelibrary(ionisation_mode, sel.class, fixed, fixed_FA, lookup_lipid_class, lookup_FA, lookup_element)
    print(paste("library containing", ncol(dbase), "entries was made", sep = " "))

    #' extract m/z and pick peaks
    setwd(spectra_dir)
    extracted <- mzextractor(files, spectra_dir, imzMLparse, thres.int, thres.low, thres.high)
    peaks <- peakpicker.bin(extracted, bin.ppm) # pick peaks

    #' perform deisotoping on a subset of the image
    temp.image <- subsetImage(
      extracted, peaks, percentage.deiso,
      thres.int, thres.low, thres.high, files,
      spectra_dir, imzMLparse
    )
    temp.image.filtered <- filter(
      imagedata.in = temp.image, steps,
      thres.filter, offset = 1
    )
    deisotoped <- deisotope(ppm, no_isotopes, prop.1, prop.2,
      peaks = list("", temp.image.filtered[, 1]),
      image.sub = temp.image.filtered, search.mod, mod,
      lookup_mod
    )

    #' perform annotation of lipids using library
    annotated <- annotate(
      ionisation_mode, deisotoped, adducts, ppm.annotate,
      dbase
    )

    #' make full image and add lipid ids
    final.image <- contructImage(
      extracted, deisotoped, peaks, imzMLparse,
      spectra_dir, thres.int, thres.low,
      thres.high, files
    )
    ids <- cbind(deisotoped[[2]][, 1], annotated, deisotoped[[2]][, 3:4])
    #' create annotated image
    image.ann <- cbind(ids, final.image[, 2:ncol(final.image)])

    #' normalise image
    image.norm <- normalise(
      imagedata.in = image.ann, norm.type,
      standards, offset = 4
    )

    #' wl-23-08-2017: save results for 'make library'
    write.csv(image.norm[, ], "image.norm.csv")
    write.csv(image.norm[, 1:3], "image.norm_short.csv")

    image.process <- image.norm
  } else {
    image.process <- read.csv("image.norm.csv")
    image.process <- image.process[, 2:ncol(image.process)]
  }

  #' perform PCA if requested
  if (pca == T) {
    image.scale <- centreScale(
      imagedata.in = image.process, scale.type,
      transform, offset = 4
    )

    imagedata.in <- image.scale

    imagePca(
      imagedata.in = image.scale, offset = 4, PCnum, scale, x.cood,
      y.cood, nlevels, res.spatial, summary, title, rem.outliers
    )

    pca <- princomp(t(imagedata.in[, (offset + 1):ncol(imagedata.in)]),
      cor = FALSE, scores = TRUE, covmat = NULL
    )

    labs.all <- as.numeric(as.vector(imagedata.in[, 1]))
    for (i in 1:PCnum) {
      loadings <- pca$loadings[, i]
      loadings <- cbind(loadings, labs.all)
      write.csv(loadings, paste("loadings_PC", i, ".csv"))
    }
  }

  #' make ion slice if requested
  if (slice == T) {
    imageSlice(row,
      imagedata.in = image.process, scale, x.cood, y.cood,
      nlevels, name = image.process[row, 1],
      subname = image.process[row, 2], offset = 4, res.spatial,
      rem.outliers, summary, title
    )
  }

  #' perform clustering if requested
  if (cluster.k == T) {
    cluster(cluster.type,
      imagedata.in = image.process, offset, width = x.cood,
      res.spatial, height = y.cood, clusters
    )
  }

  #' returns normalised data file, also printed as a csv
  if (process == T) {
    return(image.norm)
  }
}
