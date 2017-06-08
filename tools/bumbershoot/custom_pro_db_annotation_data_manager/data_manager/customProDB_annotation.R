#!/usr/bin/env Rscript

initial.options <- commandArgs(trailingOnly = FALSE)
script_parent_dir <- dirname(sub("--file=", "", initial.options[grep("--file=", initial.options)]))

## begin warning handler
withCallingHandlers({

library(methods) # Because Rscript does not always do this

options('useFancyQuotes' = FALSE)

suppressPackageStartupMessages(library("optparse"))
suppressPackageStartupMessages(library("RGalaxy"))
suppressPackageStartupMessages(library("GetoptLong"))


option_list <- list()
option_list$dbkey <- make_option('--dbkey', type='character')
option_list$ensembl_host <- make_option('--ensembl_host', type='character')
option_list$ensembl_dataset <- make_option('--ensembl_dataset', type='character')
option_list$dbsnp <- make_option('--dbsnp', type='character')
option_list$cosmic <- make_option('--cosmic', type='logical')
option_list$outputFile <- make_option('--outputFile', type='character')
option_list$dbkey_description <- make_option('--dbkey_description', type='character')

opt <- parse_args(OptionParser(option_list=option_list))


customProDB_annotation <- function(
	dbkey = GalaxyCharacterParam(required=FALSE), 
	ensembl_host = GalaxyCharacterParam(required=FALSE), 
	ensembl_dataset = GalaxyCharacterParam(required=FALSE), 
	dbsnp_str = GalaxyCharacterParam(required=FALSE), 
	cosmic = GalaxyLogicalParam(required=FALSE), 
	dbkey_description = GalaxyCharacterParam(required=FALSE), 
	outputFile = GalaxyOutput("output","json"))
{
    options(stringsAsFactors = FALSE, gsubfn.engine = "R")

    if (!file.exists(outputFile))
    {
        gstop("json params file does not exist")
    }

    if (length(dbkey)+length(ensembl_dataset)+length(ensembl_host) == 0)
    {
        gstop("one of the genome annotation sources must be specified; either dbkey or host and dataset")
    }
    else if (length(dbkey) > 0 &&
             (length(ensembl_dataset) > 0 || length(ensembl_host) > 0))
    {
        gstop("only one genome annotation source can be specified; either dbkey or host and dataset")
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
        if (length(dbkey) > 0 && grepl("^hg", dbkey) ||
            length(ensembl_dataset) > 0 && grepl("^hsapiens", ensembl_dataset))
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

    # load customProDB from GitHub (NOTE: downloading the zip is faster than cloning the repo with git2r or devtools::install_github)
    download.file("https://github.com/chambm/customProDB/archive/c57e5498392197bc598a18c26acb70d7530a921cc57e5498.zip", "customProDB.zip", quiet=TRUE)
    unzip("customProDB.zip")
    devtools::load_all("customProDB-c57e5498392197bc598a18c26acb70d7530a921c")

    #suppressPackageStartupMessages(library(customProDB))
    options(timeout=3600)

    # download protein and coding sequences for UCSC annotation
    if (length(dbkey) > 0)
    {
        proteinFastaFilepath = paste(dbkey, ".protein.fa", sep="")

        cat(paste("Downloading protein FASTA from:", getProteinFastaUrlFromUCSC(dbkey), "\n"))
        download.file(getProteinFastaUrlFromUCSC(dbkey), proteinFastaFilepath, quiet=T, mode='wb')

        local_cache_path = paste0("customProDB_annotation_", dbkey, "-", tools::md5sum(proteinFastaFilepath)[[1]])
        codingFastaFilepath = paste0(local_cache_path, "/", dbkey, ".cds.fa")
        dir.create(local_cache_path, showWarnings=FALSE)

        if (!file.exists(codingFastaFilepath)) {
            cat(paste("Downloading coding FASTA from:", getCodingFastaUrlFromUCSC(dbkey), "\n"))
            download.file(getCodingFastaUrlFromUCSC(dbkey), codingFastaFilepath, quiet=T, mode='wb')
        }

        cat(paste("Preparing Refseq annotation files\n"))
        PrepareAnnotationRefseq(genome=dbkey, CDSfasta=codingFastaFilepath, pepfasta=proteinFastaFilepath, annotation_path=target_directory, dbsnp=dbsnp, COSMIC=use_cosmic, local_cache_path=local_cache_path)

        if (length(dbkey_description) < 1)
        {
            dbkey_description = dbkey
        }
    }
    else
    {
        local_cache_path = paste0("customProDB_annotation_", ensembl_dataset, "_", ensembl_host)

        suppressPackageStartupMessages(library(biomaRt))
        cat(paste("Preparing Ensembl annotation files\n"))
        ensembl_mart = useMart("ENSEMBL_MART_ENSEMBL", dataset=ensembl_dataset, host=ensembl_host)
        PrepareAnnotationEnsembl(mart=ensembl_mart, annotation_path=target_directory, dbsnp=dbsnp, COSMIC=use_cosmic, local_cache_path=local_cache_path)

        metadata = sqldf::sqldf("SELECT value FROM metadata WHERE name='BioMart database version' OR name='BioMart dataset description' OR name='BioMart dataset version'",
                                dbname=file.path(target_directory, "txdb.sqlite"))
        version = metadata$value[1] # Ensembl Genes 87
        assembly = metadata$value[3]
        dbkey = paste0(ensembl_dataset, "_", sub(".*?(\\d+)", "\\1", version, perl=TRUE))

        # convert Ensembl chromosome names to UCSC for Galaxy compatibility
        chromosomeMappingsBaseUrl = "https://raw.githubusercontent.com/dpryan79/ChromosomeMappings/master"
        assemblyNoGrcPatch = sub("(\\S+?)(\\.p\\S+)?$", "\\1", assembly, perl=TRUE)
        chromosomeMappingsUrl = qq("@{chromosomeMappingsBaseUrl}/@{assemblyNoGrcPatch}_ensembl2UCSC.txt")
        if (RCurl::url.exists(chromosomeMappingsUrl))
        {
            cat(qq("Converting Ensembl chromosome names from: @{chromosomeMappingsUrl}\n"))
            e2u = read.delim(chromosomeMappingsUrl, header=FALSE, col.names=c("ensembl", "ucsc"))
            e2u = setNames(as.list(e2u$ucsc), e2u$ensembl)
            load(file.path(target_directory, "exon_anno.RData"))
            exon$chromosome_name = sapply(exon$chromosome_name, function(x) e2u[[as.character(x)]])
            exon = exon[nzchar(exon$chromosome_name), ] # omit genome patches with no mapping
            save(exon, file=file.path(target_directory, "exon_anno.RData"))
        }
        else
        {
            gwarning(qq("unable to convert Ensembl chromosome names to UCSC; mapping file @{assemblyNoGrcPatch}_ensembl2UCSC.txt does not exist"))
        }

        if (length(dbkey_description) < 1)
        {
            dbkey_description = qq("@{ensembl_dataset} (@{version}) (@{assembly})")
        }
    }

    qualified_dbkey = dbkey

    if (length(dbsnp_str) > 0 && nzchar(dbsnp_str))
    {
        qualified_dbkey = qq("@{qualified_dbkey}_db@{dbsnp_str}")
        dbkey_description = qq("@{dbkey_description} (db@{dbsnp_str})")
    }

    if (length(cosmic) > 0)
    {
        qualified_dbkey = qq("@{qualified_dbkey}_cosmic")
        dbkey_description = qq("@{dbkey_description} (COSMIC)")
    }

    outputPath = paste0(qualified_dbkey, "/customProDB")
    output = list(data_tables = list())
    output[["data_tables"]][["customProDB"]]=c(path=outputPath, name=dbkey_description, dbkey=qualified_dbkey, value=qualified_dbkey)
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
