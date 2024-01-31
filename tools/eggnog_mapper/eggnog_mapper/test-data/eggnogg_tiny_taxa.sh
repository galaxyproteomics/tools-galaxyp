#!/bin/bash

# Script adapted from https://github.com/galaxyproteomics/egglet to produce a minimal eggnog 5.0.2 database

sqlite3 $1 << "EOF"

CREATE TEMP TABLE species
AS SELECT * FROM species
WHERE taxid in (1131266, 436308);

CREATE TEMP TABLE synonym
AS SELECT * FROM synonym
WHERE taxid in (1131266, 436308);

CREATE TEMP TABLE merged
AS SELECT * FROM merged
WHERE taxid_old in (1131266, 436308);

CREATE TEMP TABLE stats
AS SELECT * FROM stats;

.backup temp eggnog_tiny_taxa.db
EOF
