#!/usr/bin/env Rscript

initial.options <- commandArgs(trailingOnly = FALSE)
script_parent_dir <- dirname(sub("--file=", "", initial.options[grep("--file=", initial.options)]))

## begin warning handler
withCallingHandlers({

library(methods) # Because Rscript does not always do this

options('useFancyQuotes' = FALSE)

suppressPackageStartupMessages(library("optparse"))
suppressPackageStartupMessages(library("RGalaxy"))


option_list <- list()

option_list$bam <- make_option('--bam', type='character')
option_list$bai <- make_option('--bai', type='character')
option_list$vcf <- make_option('--vcf', type='character')
option_list$exon_anno <- make_option('--exon_anno', type='character')
option_list$proteinseq <- make_option('--proteinseq', type='character')
option_list$procodingseq <- make_option('--procodingseq', type='character')
option_list$ids <- make_option('--ids', type='character')
option_list$dbsnpinCoding <- make_option('--dbsnpinCoding', type='character')
option_list$cosmic <- make_option('--cosmic', type='character')
option_list$annotationFromHistory <- make_option('--annotationFromHistory', type='logical', action="store_true", default=FALSE)
option_list$rpkmCutoff <- make_option('--rpkmCutoff', type='character')
#option_list$outputIndels <- make_option('--outputIndels', type='logical', action="store_true", default=FALSE)
#option_list$outputNovelJunctions <- make_option('--outputNovelJunctions', type='logical', action="store_true", default=FALSE)
option_list$outputFile <- make_option('--outputFile', type='character')


opt <- parse_args(OptionParser(option_list=option_list))


customProDB <- function(
	bam_file = GalaxyInputFile(required=TRUE), 
	bai_file = GalaxyInputFile(required=TRUE), 
	vcf_file = GalaxyInputFile(required=TRUE), 
	exon_anno_file = GalaxyInputFile(required=TRUE),
	proteinseq_file = GalaxyInputFile(required=TRUE),
	procodingseq_file = GalaxyInputFile(required=TRUE),
	ids_file = GalaxyInputFile(required=TRUE),
	dbsnpinCoding_file = GalaxyInputFile(required=FALSE),
	cosmic_file = GalaxyInputFile(required=FALSE),
	annotationFromHistory = GalaxyLogicalParam(required=FALSE),
	rpkmCutoff = GalaxyNumericParam(required=TRUE),
	#outputIndels = GalaxyLogicalParam(required=FALSE),
	#outputNovelJunctions = GalaxyLogicalParam(required=FALSE),
	outputFile = GalaxyOutput("FASTA","fasta"))
{
    file.symlink(exon_anno_file, paste(getwd(), "exon_anno.RData", sep="/"))
    file.symlink(proteinseq_file, paste(getwd(), "proseq.RData", sep="/"))
    file.symlink(procodingseq_file, paste(getwd(), "procodingseq.RData", sep="/"))
    file.symlink(ids_file, paste(getwd(), "ids.RData", sep="/"))

    if (length(dbsnpinCoding_file) > 0)
    {
        file.symlink(dbsnpinCoding_file, paste(getwd(), "dbsnpinCoding.RData", sep="/"))
        labelrsid = T
    }
    else
    {
        labelrsid = F
    }

    if (length(cosmic_file) > 0)
    {
        file.symlink(cosmic_file, paste(getwd(), "cosmic.RData", sep="/"))
        cosmic = T
    }
    else
    {
        cosmic = F
    }

    bamLink = "input.bam"
    file.symlink(bam_file, bamLink)
    file.symlink(bai_file, paste(bamLink, ".bai", sep=""))

    suppressPackageStartupMessages(library(customProDB))

    easyRun(bamFile=bamLink, vcfFile=vcf_file, annotation_path=getwd(),
            rpkm_cutoff=rpkmCutoff, outfile_path=".", outfile_name="output",
            nov_junction=F, INDEL=T, lablersid=labelrsid, COSMIC=cosmic)
}


params <- list()
for(param in names(opt))
{
    if (!param == "help")
        params[param] <- opt[param]
}

setClass("GalaxyRemoteError", contains="character")
wrappedFunction <- function(f)
{
    tryCatch(do.call(f, params),
        error=function(e) new("GalaxyRemoteError", conditionMessage(e)))
}


suppressPackageStartupMessages(library(RGalaxy))
do.call(customProDB, params)

## end warning handler
}, warning = function(w) {
    cat(paste("Warning:", conditionMessage(w), "\n"))
    invokeRestart("muffleWarning")
})
