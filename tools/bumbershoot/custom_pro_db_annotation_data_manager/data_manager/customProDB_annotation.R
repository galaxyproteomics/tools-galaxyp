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
option_list$dbkey <- make_option('--dbkey', type='character')
option_list$dbsnp <- make_option('--dbsnp', type='character')
option_list$cosmic <- make_option('--cosmic', type='logical')
option_list$outputFile <- make_option('--outputFile', type='character')
option_list$dbkey_description <- make_option('--dbkey_description', type='character')

opt <- parse_args(OptionParser(option_list=option_list))


customProDB_annotation <- function(
	dbkey = GalaxyCharacterParam(required=TRUE), 
	dbsnp_str = GalaxyCharacterParam(required=FALSE), 
	cosmic = GalaxyLogicalParam(required=FALSE), 
	dbkey_description = GalaxyCharacterParam(required=FALSE), 
	outputFile = GalaxyOutput("output","json"))
{
    if (!file.exists(outputFile))
    {
        gstop("json params file does not exist")
    }

    if (length(dbkey_description) < 1)
    {
        dbkey_description = dbkey
    }

    if (length(dbsnp_str) > 0)
    {
        dbsnp = dbsnp_str
    }
    else
    {
        dbsnp = NULL
    }

    use_cosmic = FALSE
    if (length(cosmic) > 0)
    {
        if (grepl("^hg", dbkey))
        {
            use_cosmic = TRUE
        }
        else
        {
            gstop("COSMIC annotation requested but dbkey does not indicate a human genome (e.g. hg19)")
        }
    }

    suppressPackageStartupMessages(library(rjson))
    params = fromJSON(file=outputFile)
    target_directory = params$output_data[[1]]$extra_files_path
    dir.create(target_directory)

    tryCatch(
    {
        file.remove(outputFile)
    }, error=function(err)
    {
        gstop("failed to remove json params file after reading")
    })

    ucscTableCodingFastaURL = paste("http://genome.ucsc.edu/cgi-bin/hgTables?db=", dbkey, "&hgSeq.cdsExon=on&hgSeq.granularity=gene&hgSeq.casing=exon&hgSeq.repMasking=lower&hgta_doGenomicDna=get+sequence&hgta_group=genes&hgta_track=refGene&hgta_table=refGene&hgta_regionType=genome", sep="")
    ucscTableProteinFastaURL = paste("http://genome.ucsc.edu/cgi-bin/hgTables?db=", dbkey, "&hgta_geneSeqType=protein&hgta_doGenePredSequence=submit&hgta_track=refGene&hgta_table=refGene", sep="")
    codingFastaFilepath = paste(target_directory, "/", dbkey, ".cds.fa", sep="")
    proteinFastaFilepath = paste(target_directory, "/", dbkey, ".protein.fa", sep="")

    suppressPackageStartupMessages(library(customProDB))
    options(timeout=3600)

    cat(paste("Downloading coding FASTA from:", ucscTableCodingFastaURL, "\n"))
    download.file(ucscTableCodingFastaURL, codingFastaFilepath, quiet=T, mode='wb')

    cat(paste("Downloading protein FASTA from:", ucscTableProteinFastaURL, "\n"))
    download.file(ucscTableProteinFastaURL, proteinFastaFilepath, quiet=T, mode='wb')

    cat(paste("Preparing Refseq annotation files\n"))
    customProDB::PrepareAnnotationRefseq(genome=dbkey, CDSfasta=codingFastaFilepath, pepfasta=proteinFastaFilepath, annotation_path=target_directory, dbsnp=dbsnp, COSMIC=use_cosmic)
    
    outputPath = paste(dbkey, "/customProDB", sep="")
    output = list(data_tables = list())
    output[["data_tables"]][["customProDB"]]=c(path=outputPath, name=dbkey_description, dbkey=dbkey, value=dbkey)
    write(toJSON(output), file=outputFile)
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
do.call(customProDB_annotation, params)

## end warning handler
}, warning = function(w) {
    cat(paste("Warning:", conditionMessage(w), "\n"))
    invokeRestart("muffleWarning")
})
