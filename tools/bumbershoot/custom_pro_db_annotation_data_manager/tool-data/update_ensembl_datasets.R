##
## Run this script to update the table of Ensembl assemblies available in the customProDB annotation data manager (ensembl_datasets.loc)
##

library(RMySQL)
library(httr)
library(biomaRt)
library(stringdist)

con = dbConnect(MySQL(), host="ensembldb.ensembl.org", user="anonymous")
archives = dbGetQuery(con, "SHOW DATABASES LIKE 'ensembl_archive_%'")
dbDisconnect(con)

latestArchive = tail(archives[,1], 1)
con = dbConnect(MySQL(), host="ensembldb.ensembl.org", user="anonymous", dbname=latestArchive)
assemblies = dbGetQuery(con, "SELECT s.name, s.common_name, rs.assembly_name, MAX(rs.release_id) AS latest_release, r.date
                              FROM species as s, release_species as rs, ens_release as r
                              WHERE s.species_id = rs.species_id AND r.release_id = rs.release_id AND r.online = 'Y'
                              AND r.release_id < 10000 -- ignore 10075 (the special GRCh37 site)
                              GROUP BY rs.assembly_name
                              ORDER BY s.common_name, rs.release_id")
allReleases = assemblies$latest_release
uniqueReleases = unique(allReleases)

# Get the <MMMYYYY> style archive link for each Ensembl release
urlRedirectMap = sapply(paste0("e", uniqueReleases, ".ensembl.org"), function(url){XML::parseURI(HEAD(url)$url)$server})

## NOTE ## Make sure the following line is updated to the latest Ensembl mirror
assemblies$url = sub("www.", "may2017.archive.", urlRedirectMap[paste0("e", allReleases, ".ensembl.org")], fixed=TRUE)

# Get all datasets from the archives
datasets = c()
for (archive in unique(assemblies$url)) {
    datasets = unique(c(datasets, listDatasets(useMart("ensembl", host=archive))$dataset))
}
datasets = sub("_gene_ensembl", "", datasets, fixed=TRUE)

# Match the assembly species names to the datasets (using amatch() because of cases like Mustela_putorius_furo -> mfuro)
assemblies$dataset_id = datasets[amatch(tolower(assemblies$name), datasets, maxDist=3, method="osa", weight=c(0.1, 1, 1, 1))]

# Remove mouse strains (would need to add these from ENSEMBL_MOUSE_MART)
assemblies = assemblies[-grep("Mus_musculus_\\S+", assemblies$name, perl=TRUE),]

# Remove unmatched assemblies (e.g. Mus spretus)
assemblies = assemblies[-which(is.na(assemblies$dataset_id)),]

# Replace underscores in scientific name
assemblies$name = gsub("_", " ", assemblies$name, fixed=TRUE)

# Sort assemblies first by scientific name, then descending by latest release for that assembly
assemblies = assemblies[order(assemblies$name, -assemblies$latest_release),]

# Write dataset table (3 columns: dataset_id, host, description)
dataset_id = paste0(assemblies$dataset_id, "_gene_ensembl")
host = paste0(assemblies$url)
description = paste0(assemblies$common_name, " genes (Ensembl ", assemblies$latest_release, " ", assemblies$dataset_id,
                     ") (", assemblies$assembly_name, ")")
write.csv(paste(dataset_id, host, description, sep="\t"), file="ensembl_datasets.loc.sample")
