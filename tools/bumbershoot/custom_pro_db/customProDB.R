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
option_list$outputIndels <- make_option('--outputIndels', type='logical', action="store_true", default=FALSE)
#option_list$outputNovelJunctions <- make_option('--outputNovelJunctions', type='logical', action="store_true", default=FALSE)
#option_list$bedFile <- make_option('--bedFile', type='character')
#option_list$bsGenome <- make_option('--bsGenome', type='character')


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
    outputIndels = GalaxyLogicalParam(required=FALSE)
    #,outputNovelJunctions = GalaxyLogicalParam(required=FALSE)
    #,bedFile = GalaxyInputFile(required=FALSE)
    #,bsGenome = GalaxyCharacterParam(required=FALSE)
    )
{
    old <- options(stringsAsFactors = FALSE, gsubfn.engine = "R")
    on.exit(options(old), add = TRUE)

    file.symlink(exon_anno_file, paste(getwd(), "exon_anno.RData", sep="/"))
    file.symlink(proteinseq_file, paste(getwd(), "proseq.RData", sep="/"))
    file.symlink(procodingseq_file, paste(getwd(), "procodingseq.RData", sep="/"))
    file.symlink(ids_file, paste(getwd(), "ids.RData", sep="/"))

    load(exon_anno_file)
    load(proteinseq_file)
    load(procodingseq_file)
    load(ids_file)

    if (length(dbsnpinCoding_file) > 0)
    {
        file.symlink(dbsnpinCoding_file, paste(getwd(), "dbsnpinCoding.RData", sep="/"))
        labelrsid = TRUE
        load(dbsnpinCoding_file)
    }
    else
    {
        dbsnpinCoding = NULL
        labelrsid = FALSE
    }

    if (length(cosmic_file) > 0)
    {
        file.symlink(cosmic_file, paste(getwd(), "cosmic.RData", sep="/"))
        use_cosmic = TRUE
        load(cosmic_file)
    }
    else
    {
        cosmic = NULL
        use_cosmic = FALSE
    }

    bamLink = "input.bam"
    file.symlink(bam_file, bamLink)
    file.symlink(bai_file, paste(bamLink, ".bai", sep=""))

    # load from GitHub until conda package is available
    download.file("https://github.com/ggrothendieck/sqldf/archive/master.zip", "sqldf.zip", quiet=TRUE)
    unzip("sqldf.zip")
    devtools::load_all("sqldf-master")

    # load customProDB from GitHub (NOTE: downloading the zip is faster than cloning the repo with git2r or devtools::install_github)
    download.file("https://github.com/chambm/customProDB/archive/master.zip", "customProDB.zip", quiet=TRUE)
    unzip("customProDB.zip")
    devtools::load_all("customProDB-master")

    easyRun(bamFile=bamLink, vcfFile=vcf_file, annotation_path=getwd(),
            rpkm_cutoff=rpkmCutoff, outfile_path=".", outfile_name="output",
            nov_junction=FALSE, INDEL=outputIndels,
            lablersid=labelrsid, COSMIC=use_cosmic)

    # save variant annotations to an RData file (needed by proBAMr)
    variantAnnotation = getVariantAnnotation(vcf_file, ids, exon, proteinseq, procodingseq, dbsnpinCoding, cosmic)
    save(variantAnnotation, file="output.rdata")

    # save genomic mapping to a SQLite file (needed by Galaxy-P viewer MVP)
    dbWriteTable(dbConnect(RSQLite::SQLite(), "output_genomic_mapping.sqlite"),
                 "genomic_mapping",
                 sqldf::sqldf("SELECT gene_name, tx_name, pro_name, strand,
                                      chromosome_name || ':' || group_concat(exon_chrom_start || '-' || exon_chrom_end) AS coding_ranges
                               FROM exon
                               WHERE length(pro_name) > 0
                               GROUP BY tx_name"))

    # create protein-centric variant annotation table (needed by Galaxy-P viewer MVP)
    varproseq = unique(rbind(variantAnnotation$snvproseq, variantAnnotation$indelproseq))
    ref_vs_var_seq = sqldf::sqldf("SELECT reference.pro_name, variant.pro_name AS var_pro_name, reference.peptide AS ref_seq, variant.peptide AS var_seq
                                   FROM proteinseq reference, varproseq variant
                                   WHERE reference.tx_name=variant.tx_name
                                   GROUP BY variant.pro_name")
    getCigarishString = function(ref, var)
    {
        a = Biostrings::pairwiseAlignment(ref, var)
        d = gsub("[A-Z]", "=", Biostrings::compareStrings(a@pattern, a@subject))
        r = rle(strsplit(d, "")[[1]])
        gsub("-", "D", gsub("\\+", "I", gsub("\\?", "X", paste0(r$lengths, r$values, collapse=""))))
    }
    ref_vs_var_seq$cigar =  mapply(FUN=getCigarishString, ref_vs_var_seq$ref_seq, ref_vs_var_seq$var_seq, USE.NAMES=FALSE)
    ref_vs_var_seq$annotation = substring(ref_vs_var_seq$var_pro_name, stringr::str_length(ref_vs_var_seq$pro_name)+2)

    dbWriteTable(dbConnect(RSQLite::SQLite(), "output_variant_annotation.sqlite"),
                 "variant_annotation",
                 sqldf::sqldf("SELECT var_pro_name, pro_name, cigar, annotation FROM ref_vs_var_seq"))

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
do.call(customProDB, params)

## end warning handler
}, warning = function(w) {
    cat(paste("Warning:", conditionMessage(w), "\n"))
    invokeRestart("muffleWarning")
})
