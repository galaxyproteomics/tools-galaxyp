#!/usr/bin/env Rscript

## begin warning handler
withCallingHandlers({

library(methods) # Because Rscript does not always do this

options('useFancyQuotes' = FALSE)

suppressPackageStartupMessages(library("optparse"))
suppressPackageStartupMessages(library("RGalaxy"))


option_list <- list()

option_list$exon_anno <- make_option('--exon_anno', type='character')
option_list$proteinseq <- make_option('--proteinseq', type='character')
option_list$procodingseq <- make_option('--procodingseq', type='character')
option_list$bam_file <- make_option('--bam', type='character')
option_list$idpDB_file <- make_option('--idpDB', type='character')
option_list$pepXmlTab_file <- make_option('--pepXmlTab', type='character')
option_list$peptideShakerPsmReport_file <- make_option('--peptideShakerPsmReport', type='character')
option_list$variantAnnotation_file <- make_option('--variantAnnotation', type='character')
option_list$searchEngineScore <- make_option('--searchEngineScore', type='character')


opt <- parse_args(OptionParser(option_list=option_list))


psm2sam <- function(
    exon_anno_file = GalaxyInputFile(required=TRUE),
    proteinseq_file = GalaxyInputFile(required=TRUE),
    procodingseq_file = GalaxyInputFile(required=TRUE),
    bam_file = GalaxyInputFile(required=TRUE),
    idpDB_file = GalaxyInputFile(required=FALSE),
    pepXmlTab_file = GalaxyInputFile(required=FALSE),
    peptideShakerPsmReport_file = GalaxyInputFile(required=FALSE),
    variantAnnotation_file = GalaxyInputFile(required=FALSE),
    searchEngineScore = GalaxyCharacterParam(required=FALSE)
    )
{
    options(stringsAsFactors = FALSE)

    if (length(bam_file) == 0)
    {
        stop("BAM file must be specified to provide sequence headers")
    }

    outputHeader = grep("^@(?!PG)", readLines(bam_file, n=500, warn=FALSE), value=TRUE, perl=TRUE)
    if (length(outputHeader) == 0)
    {
        stop("failed to read header lines from bam_file")
    }

    # load customProDB from GitHub (NOTE: downloading the zip is faster than cloning the repo with git2r or devtools::install_github)
    download.file("https://github.com/chambm/customProDB/archive/c57e5498392197bc598a18c26acb70d7530a921c.zip", "customProDB.zip", quiet=TRUE)
    unzip("customProDB.zip")
    devtools::load_all("customProDB-c57e5498392197bc598a18c26acb70d7530a921c")

    # load proBAMr from GitHub
    download.file("https://github.com/chambm/proBAMr/archive/a03edf68f51215be40717c5374f39ce67bd2e68b.zip", "proBAMr.zip", quiet=TRUE)
    unzip("proBAMr.zip")
    devtools::load_all("proBAMr-a03edf68f51215be40717c5374f39ce67bd2e68b")
    
    psmInputLength = length(idpDB_file)+length(pepXmlTab_file)+length(peptideShakerPsmReport_file)
    if (psmInputLength == 0)
    {
        stop("one of the input PSM file parameters must be specified")
    }
    else if (psmInputLength > 1)
    {
        stop("only one of the input PSM file parameters can be specified")
    }
    
    if (length(idpDB_file) > 0)
    {
        if (length(searchEngineScore) == 0)
            stop("searchEngineScore parameter must be specified when reading IDPicker PSMs, e.g. 'MyriMatch:MVH'")
        passedPSM = readIdpDB(idpDB_file, searchEngineScore)
    }
    else if (length(pepXmlTab_file) > 0)
    {
        if (length(searchEngineScore) == 0)
            stop("searchEngineScore parameter must be specified when reading pepXmlTab PSMs, e.g. 'mvh'")
        passedPSM = readPepXmlTab(pepXmlTab_file, searchEngineScore)
    }
    else if (length(peptideShakerPsmReport_file) > 0)
    {
        if (length(searchEngineScore) > 0)
            warning("searchEngineScore parameter is ignored when reading PeptideShaker PSM report")
        passedPSM = readPeptideShakerPsmReport(peptideShakerPsmReport_file)
    }

    load(exon_anno_file)
    load(proteinseq_file)
    load(procodingseq_file)

    if (length(variantAnnotation_file) > 0)
    {
        load(variantAnnotation_file) # variantAnnotation list, with members snvprocoding/snvproseq and indelprocoding/indelproseq

        varprocoding = unique(rbind(variantAnnotation$snvprocoding, variantAnnotation$indelprocoding))
        varproseq = unique(rbind(variantAnnotation$snvproseq, variantAnnotation$indelproseq))
    }
    else
    {
        varprocoding = NULL
        varproseq = NULL
    }

    # add proBAMr program key
    outputHeader = c(outputHeader, paste0("@PG\tID:proBAMr\tVN:", packageVersion("proBAMr")))

    # first write header lines to the output SAM
    writeLines(outputHeader, "output.sam")

    # then write the PSM "reads"
    PSMtab2SAM(passedPSM, exon,
               proteinseq, procodingseq,
               varproseq, varprocoding,
               outfile = "output.sam",
               show_progress = FALSE)

    invisible(NULL)
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
do.call(psm2sam, params)

## end warning handler
}, warning = function(w) {
    cat(paste("Warning:", conditionMessage(w), "\n"))
    invokeRestart("muffleWarning")
})
