#!/bin/bash

# Script adapted from https://github.com/galaxyproteomics/egglet to produce a minimal eggnog 5.0.2 database

sqlite3 $1 << "EOF"

CREATE TEMP TABLE og
AS SELECT * FROM og
WHERE description = 'Cytidylyltransferase'
AND level LIKE "651137"
LIMIT 1;

CREATE TEMP TABLE event
AS SELECT * FROM event
WHERE level=651137
AND og='41T2K'
LIMIT 20;

CREATE TEMP TABLE prots
AS SELECT * FROM prots
WHERE name = "436308.Nmar_0135";

CREATE TEMP TABLE version
AS SELECT * FROM version;


.backup temp eggnog_tiny.db
EOF
