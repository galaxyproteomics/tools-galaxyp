###############################################################################
#                                                                             #
# TestScript.R                                                                #
#                                                                             #
# I am using this to test the scripting language and passing parameters       #
#                                                                             #
# Created: 2017-04-12                                                         #
#                                                                             #
###############################################################################

args <- commandArgs(TRUE) # Saves the parameters (command code)
eval(parse(text=args))    # Runs the parameters
# NOTE: This is extremely unsafe programming - any valid R code can run here

#sprintf("z_cutoff is %s and ppm_tolerance is %s", z_cutoff, ppm_tolerance)
#sprintf("Finally, the PSM report file is %s", psm_report)
#sprintf("Oh, and the output file name is %s", output_psm_report)

##### Support functions
calc_z <- function(v=NULL, mu=NULL, sigma=NULL) {
  return( (v-mu) / sigma )
}

##### Load Data
data <- read.table(psm_report, 
                   header = TRUE, 
                   blank.lines.skip = TRUE, 
                   fill = TRUE, 
                   sep = "\t")
#sprintf("data loaded")

##### Local "confidence"
values <- data$Precursor.m.z.Error..ppm.
#sprintf("Number of values: %d", length(values))
mu = mean(values)
#sprintf("mean is %f", mu)
sigma = sd(values)
#sprintf("sigma is %f", sigma)
precursor_z      <- calc_z(v=values, mu=mu, sigma=sigma)
data$precursor_z <- precursor_z
#sprintf("made the z list")
write.table(data, file=output_psm_report, quote=FALSE, sep="\t", row.names=FALSE)
#sprintf("file written")

##### Global "confidence"
ppm_min <- -ppm_tolerance
ppm_max <- +ppm_tolerance
zmin    <- calc_z(v=ppm_min, mu=mu, sigma=sigma)
zmax    <- calc_z(v=ppm_max, mu=mu, sigma=sigma)
area    <- (-z_cutoff - zmin) + (zmax - z_cutoff)
nFalseHit <- sum(abs(precursor_z) > z_cutoff)
n         <- length(values)
propArea  <- area / (zmax - zmin)
global_precursor_conf <- nFalseHit / (n * propArea)

global_precursor_conf

