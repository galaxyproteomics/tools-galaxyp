# MzToSQLite

## Description

Parses MzIdentML, FASTA and MGF scan files into a SQLite3 database. The schema is used by MVPApplication in visualizing the parsed data.

## General Requirements

MzToSQLite is threaded during the read stages of processing. It is single threaded during SQL writes. It will perform best when given one core per MGF file. But it runs well with between two and four cores.

Reading the MGF files is memory intensive, set the _JAVA_OPTIONS to the minimum recommended below.

**Example Recommended Settings**

    One core, minimum memory:
        _JAVA_OPTIONS: -Xms20G -Xmx20G

    Four core, slightly faster performance (performance determined by size of each MGF file):
        _JAVA_OPTIONS: -Xms40G -Xmx40G
