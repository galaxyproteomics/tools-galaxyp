#!/usr/bin/env python
# Search and memoize phosphopeptides in Swiss-Prot SQLite table UniProtKB

import argparse
import os.path
import re
import sqlite3
import sys  # import the sys module for exc_info
import time
import traceback  # import the traceback module for format_exception
from codecs import getreader as cx_getreader

# For Aho-Corasick search for fixed set of substrings
# - add_word
# - make_automaton
# - iter
import ahocorasick


# ref: https://stackoverflow.com/a/8915613/15509512
#   answers: "How to handle exceptions in a list comprehensions"
#   usage:
#       from math import log
#       eggs = [1,3,0,3,2]
#       print([x for x in [catch(log, egg) for egg in eggs] if x is not None])
#   producing:
#       for <built-in function log>
#         with args (0,)
#         exception: math domain error
#       [0.0, 1.0986122886681098, 1.0986122886681098, 0.6931471805599453]
def catch(func, *args, handle=lambda e: e, **kwargs):

    try:
        return func(*args, **kwargs)
    except Exception as e:
        print("For %s" % str(func))
        print("  with args %s" % str(args))
        print("  caught exception: %s" % str(e))
        (ty, va, tb) = sys.exc_info()
        print("  stack trace: " + str(traceback.format_exception(ty, va, tb)))
        # exit(-1)
        return None  # was handle(e)


def __main__():

    DROP_TABLES_SQL = """
        DROP VIEW  IF EXISTS ppep_gene_site_view;
        DROP VIEW  IF EXISTS uniprot_view;
        DROP VIEW  IF EXISTS uniprotkb_pep_ppep_view;
        DROP VIEW  IF EXISTS ppep_intensity_view;
        DROP VIEW  IF EXISTS ppep_metadata_view;

        DROP TABLE IF EXISTS sample;
        DROP TABLE IF EXISTS ppep;
        DROP TABLE IF EXISTS site_type;
        DROP TABLE IF EXISTS deppep_UniProtKB;
        DROP TABLE IF EXISTS deppep;
        DROP TABLE IF EXISTS ppep_gene_site;
        DROP TABLE IF EXISTS ppep_metadata;
        DROP TABLE IF EXISTS ppep_intensity;
    """

    CREATE_TABLES_SQL = """
        CREATE TABLE deppep
          ( id INTEGER PRIMARY KEY
          , seq TEXT UNIQUE                            ON CONFLICT IGNORE
          )
          ;
        CREATE TABLE deppep_UniProtKB
          ( deppep_id    INTEGER REFERENCES deppep(id) ON DELETE CASCADE
          , UniProtKB_id TEXT REFERENCES UniProtKB(id) ON DELETE CASCADE
          , pos_start    INTEGER
          , pos_end      INTEGER
          , PRIMARY KEY (deppep_id, UniProtKB_id, pos_start, pos_end)
                                                       ON CONFLICT IGNORE
          )
          ;
        CREATE TABLE ppep
          ( id        INTEGER PRIMARY KEY
          , deppep_id INTEGER REFERENCES deppep(id)    ON DELETE CASCADE
          , seq       TEXT UNIQUE                      ON CONFLICT IGNORE
          , scrubbed  TEXT
          );
        CREATE TABLE site_type
          ( id        INTEGER PRIMARY KEY
          , type_name TEXT UNIQUE                      ON CONFLICT IGNORE
          );
        CREATE INDEX idx_ppep_scrubbed on ppep(scrubbed)
          ;
        CREATE TABLE sample
          ( id        INTEGER PRIMARY KEY
          , name      TEXT UNIQUE                      ON CONFLICT IGNORE
          )
          ;
        CREATE VIEW uniprot_view AS
          SELECT DISTINCT
              Uniprot_ID
            , Description
            , Organism_Name
            , Organism_ID
            , Gene_Name
            , PE
            , SV
            , Sequence
            , Description ||
                CASE WHEN Organism_Name = 'N/A'
                     THEN ''
                     ELSE ' OS='|| Organism_Name
                     END ||
                CASE WHEN Organism_ID = -1
                     THEN ''
                     ELSE ' OX='|| Organism_ID
                     END ||
                CASE WHEN Gene_Name = 'N/A'
                     THEN ''
                     ELSE ' GN='|| Gene_Name
                     END ||
                CASE WHEN PE = 'N/A'
                     THEN ''
                     ELSE ' PE='|| PE
                     END ||
                CASE WHEN SV = 'N/A'
                     THEN ''
                     ELSE ' SV='|| SV
                     END AS long_description
            , Database
          FROM UniProtKB
          ;
        CREATE VIEW uniprotkb_pep_ppep_view AS
          SELECT   deppep_UniProtKB.UniprotKB_ID       AS accession
                 , deppep_UniProtKB.pos_start          AS pos_start
                 , deppep_UniProtKB.pos_end            AS pos_end
                 , deppep.seq                          AS peptide
                 , ppep.seq                            AS phosphopeptide
                 , ppep.scrubbed                       AS scrubbed
                 , uniprot_view.Sequence               AS sequence
                 , uniprot_view.Description            AS description
                 , uniprot_view.long_description       AS long_description
                 , ppep.id                             AS ppep_id
          FROM     ppep, deppep, deppep_UniProtKB, uniprot_view
          WHERE    deppep.id = ppep.deppep_id
          AND      deppep.id = deppep_UniProtKB.deppep_id
          AND      deppep_UniProtKB.UniprotKB_ID = uniprot_view.Uniprot_ID
          ORDER BY UniprotKB_ID, deppep.seq, ppep.seq
          ;
        CREATE TABLE ppep_gene_site
          ( ppep_id         INTEGER REFERENCES ppep(id)
          , gene_names      TEXT
          , site_type_id    INTEGER REFERENCES site_type(id)
          , kinase_map      TEXT
          , PRIMARY KEY (ppep_id, kinase_map)          ON CONFLICT IGNORE
          )
          ;
        CREATE VIEW ppep_gene_site_view AS
          SELECT DISTINCT
            ppep.seq   AS phospho_peptide
          , ppep_id
          , gene_names
          , type_name
          , kinase_map
          FROM
            ppep, ppep_gene_site, site_type
          WHERE
              ppep_gene_site.ppep_id = ppep.id
            AND
              ppep_gene_site.site_type_id = site_type.id
          ORDER BY
            ppep.seq
            ;
        CREATE TABLE ppep_metadata
          ( ppep_id             INTEGER REFERENCES ppep(id)
          , protein_description TEXT
          , gene_name           TEXT
          , FASTA_name          TEXT
          , phospho_sites       TEXT
          , motifs_unique       TEXT
          , accessions          TEXT
          , motifs_all_members  TEXT
          , domain              TEXT
          , ON_FUNCTION         TEXT
          , ON_PROCESS          TEXT
          , ON_PROT_INTERACT    TEXT
          , ON_OTHER_INTERACT   TEXT
          , notes               TEXT
          , PRIMARY KEY (ppep_id)                      ON CONFLICT IGNORE
          )
          ;
        CREATE VIEW ppep_metadata_view AS
          SELECT DISTINCT
              ppep.seq             AS phospho_peptide
            , protein_description
            , gene_name
            , FASTA_name
            , phospho_sites
            , motifs_unique
            , accessions
            , motifs_all_members
            , domain
            , ON_FUNCTION
            , ON_PROCESS
            , ON_PROT_INTERACT
            , ON_OTHER_INTERACT
            , notes
          FROM
            ppep, ppep_metadata
          WHERE
              ppep_metadata.ppep_id = ppep.id
          ORDER BY
            ppep.seq
            ;
        CREATE TABLE ppep_intensity
          ( ppep_id    INTEGER REFERENCES ppep(id)
          , sample_id  INTEGER
          , intensity  INTEGER
          , PRIMARY KEY (ppep_id, sample_id)           ON CONFLICT IGNORE
          )
          ;
        CREATE VIEW ppep_intensity_view AS
          SELECT DISTINCT
              ppep.seq             AS phospho_peptide
            , sample.name          AS sample
            , intensity
          FROM
            ppep, sample, ppep_intensity
          WHERE
              ppep_intensity.sample_id = sample.id
            AND
              ppep_intensity.ppep_id = ppep.id
          ;
    """

    UNIPROT_SEQ_AND_ID_SQL = """
        select    Sequence, Uniprot_ID
             from UniProtKB
    """

    # Parse Command Line
    parser = argparse.ArgumentParser(
        description=" ".join([
            "Phopsphoproteomic Enrichment",
            "phosphopeptide SwissProt search (in place in SQLite DB)."
        ])
    )

    # inputs:
    #   Phosphopeptide data for experimental results, including the intensities
    #   and the mapping to kinase domains, in tabular format.
    parser.add_argument(
        "--phosphopeptides",
        "-p",
        nargs=1,
        required=True,
        dest="phosphopeptides",
        help=" ".join([
            "Phosphopeptide data for experimental results,",
            "generated by the Phopsphoproteomic Enrichment Localization",
            "Filter tool"
        ]),
    )
    parser.add_argument(
        "--uniprotkb",
        "-u",
        nargs=1,
        required=True,
        dest="uniprotkb",
        help=" ".join([
            "UniProtKB/Swiss-Prot data, converted from FASTA format by the",
            "Phopsphoproteomic Enrichment Kinase Mapping tool"
        ]),
    )
    parser.add_argument(
        "--schema",
        action="store_true",
        dest="db_schema",
        help="show updated database schema",
    )
    parser.add_argument(
        "--warn-duplicates",
        action="store_true",
        dest="warn_duplicates",
        help="show warnings for duplicated sequences",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        dest="verbose",
        help="show somewhat verbose program tracing",
    )
    # "Make it so!" (parse the arguments)
    options = parser.parse_args()
    if options.verbose:
        print("options: " + str(options) + "\n")

    # path to phosphopeptide (e.g., "outputfile_STEP2.txt") input tabular file
    if options.phosphopeptides is None:
        exit('Argument "phosphopeptides" is required but not supplied')
    try:
        f_name = os.path.abspath(options.phosphopeptides[0])
    except Exception as e:
        exit("Error parsing phosphopeptides argument: %s" % (e))

    # path to SQLite input/output tabular file
    if options.uniprotkb is None:
        exit('Argument "uniprotkb" is required but not supplied')
    try:
        db_name = os.path.abspath(options.uniprotkb[0])
    except Exception as e:
        exit("Error parsing uniprotkb argument: %s" % (e))

    # print("options.schema is %d" % options.db_schema)

    # db_name = "demo/test.sqlite"
    # f_name  = "demo/test_input.txt"

    con = sqlite3.connect(db_name)
    cur = con.cursor()
    ker = con.cursor()

    cur.executescript(DROP_TABLES_SQL)

    # if options.db_schema:
    #     print("\nAfter dropping tables/views that are to be created,"
    #         + schema is:")
    #     cur.execute("SELECT * FROM sqlite_schema")
    #     for row in cur.fetchall():
    #         if row[4] is not None:
    #             print("%s;" % row[4])

    cur.executescript(CREATE_TABLES_SQL)

    if options.db_schema:
        print(
            "\nAfter creating tables/views that are to be created, schema is:"
        )
        cur.execute("SELECT * FROM sqlite_schema")
        for row in cur.fetchall():
            if row[4] is not None:
                print("%s;" % row[4])

    def generate_ppep(f):
        # get keys from upstream tabular file using readline()
        # ref: https://stackoverflow.com/a/16713581/15509512
        #      answer to "Use codecs to read file with correct encoding"
        file1_encoded = open(f, "rb")
        file1 = cx_getreader("latin-1")(file1_encoded)

        count = 0
        re_tab = re.compile("^[^\t]*")
        re_quote = re.compile('"')
        while True:
            count += 1
            # Get next line from file
            line = file1.readline()
            # if line is empty
            # end of file is reached
            if not line:
                break
            if count > 1:
                m = re_tab.match(line)
                m = re_quote.sub("", m[0])
                yield m
        file1.close()
        file1_encoded.close()

    # Build an Aho-Corasick automaton from a trie
    # - ref:
    #   - https://pypi.org/project/pyahocorasick/
    #   - https://en.wikipedia.org/wiki/Aho%E2%80%93Corasick_algorithm
    #   - https://en.wikipedia.org/wiki/Trie
    auto = ahocorasick.Automaton()
    re_phos = re.compile("p")
    # scrub out unsearchable characters per section
    #   "Match the p_peptides to the @sequences array:"
    # of the original
    #   PhosphoPeptide Upstream Kinase Mapping.pl
    # which originally read
    #   $tmp_p_peptide =~ s/#//g;
    #   $tmp_p_peptide =~ s/\d//g;
    #   $tmp_p_peptide =~ s/\_//g;
    #   $tmp_p_peptide =~ s/\.//g;
    #
    re_scrub = re.compile("0-9_.#")
    ppep_count = 0
    for ppep in generate_ppep(f_name):
        ppep_count += 1
        add_to_trie = False
        # print(ppep)
        scrubbed = re_scrub.sub("", ppep)
        deppep = re_phos.sub("", scrubbed)
        if options.verbose:
            print("deppep: %s; scrubbed: %s" % (deppep, scrubbed))
        # print(deppep)
        cur.execute("SELECT id FROM deppep WHERE seq = (?)", (deppep,))
        if cur.fetchone() is None:
            add_to_trie = True
        cur.execute("INSERT INTO deppep(seq) VALUES (?)", (deppep,))
        cur.execute("SELECT id FROM deppep WHERE seq = (?)", (deppep,))
        deppep_id = cur.fetchone()[0]
        if add_to_trie:
            # print((deppep_id, deppep))
            # Build the trie
            auto.add_word(deppep, (deppep_id, deppep))
        cur.execute(
            "INSERT INTO ppep(seq, scrubbed, deppep_id) VALUES (?,?,?)",
            (ppep, scrubbed, deppep_id),
        )
    # def generate_deppep():
    #     cur.execute("SELECT seq FROM deppep")
    #     for row in cur.fetchall():
    #         yield row[0]
    cur.execute("SELECT count(*) FROM (SELECT seq FROM deppep GROUP BY seq)")
    for row in cur.fetchall():
        deppep_count = row[0]

    cur.execute(
        """
        SELECT count(*) FROM (
          SELECT Sequence FROM UniProtKB GROUP BY Sequence
          )
        """
    )
    for row in cur.fetchall():
        sequence_count = row[0]

    print("%d phosphopeptides were read from input" % ppep_count)
    print(
        "%d corresponding dephosphopeptides are represented in input"
        % deppep_count
    )
    # Look for cases where both Gene_Name and Sequence are identical
    cur.execute(
        """
      SELECT Uniprot_ID, Gene_Name, Sequence
      FROM   UniProtKB
      WHERE  Sequence IN (
        SELECT   Sequence
        FROM     UniProtKB
        GROUP BY Sequence, Gene_Name
        HAVING   count(*) > 1
        )
      ORDER BY Sequence
      """
    )
    duplicate_count = 0
    old_seq = ""
    for row in cur.fetchall():
        if duplicate_count == 0:
            print(" ".join([
                "\nEach of the following sequences is associated with several",
                "accession IDs (which are listed in the first column) but",
                "the same gene ID (which is listed in the second column)."
            ]))
        if row[2] != old_seq:
            old_seq = row[2]
            duplicate_count += 1
            if options.warn_duplicates:
                print("\n%s\t%s\t%s" % row)
        else:
            if options.warn_duplicates:
                print("%s\t%s" % (row[0], row[1]))
    if duplicate_count > 0:
        print(
            "\n%d sequences have duplicated accession IDs\n" % duplicate_count
        )

    print("%s accession sequences will be searched\n" % sequence_count)

    # print(auto.dump())

    # Convert the trie to an automaton (a finite-state machine)
    auto.make_automaton()

    # Execute query for seqs and metadata without fetching the results yet
    uniprot_seq_and_id = cur.execute(UNIPROT_SEQ_AND_ID_SQL)
    while 1:
        batch = uniprot_seq_and_id.fetchmany(size=50)
        if not batch:
            break
        for Sequence, UniProtKB_id in batch:
            if Sequence is not None:
                for end_index, (insert_order, original_value) in auto.iter(
                    Sequence
                ):
                    ker.execute(
                        """
                      INSERT INTO deppep_UniProtKB
                        (deppep_id,UniProtKB_id,pos_start,pos_end)
                      VALUES (?,?,?,?)
                      """,
                        (
                            insert_order,
                            UniProtKB_id,
                            1 + end_index - len(original_value),
                            end_index,
                        ),
                    )
            else:
                raise ValueError(
                    "UniProtKB_id %s, but Sequence is None: %s %s"
                    % (
                        UniProtKB_id,
                        "Check whether SwissProt file is missing",
                        "the sequence for this ID")
                )
    ker.execute(
        """
        SELECT
          count(*) ||
            ' accession-peptide-phosphopeptide combinations were found'
        FROM
          uniprotkb_pep_ppep_view
        """
    )
    for row in ker.fetchall():
        print(row[0])

    ker.execute(
        """
      SELECT
        count(*) || ' accession matches were found',
        count(*) AS accession_count
      FROM     (
        SELECT   accession
        FROM     uniprotkb_pep_ppep_view
        GROUP BY accession
        )
      """
    )
    for row in ker.fetchall():
        print(row[0])

    ker.execute(
        """
      SELECT   count(*) || ' peptide matches were found'
      FROM     (
        SELECT   peptide
        FROM     uniprotkb_pep_ppep_view
        GROUP BY peptide
        )
      """
    )
    for row in ker.fetchall():
        print(row[0])

    ker.execute(
        """
      SELECT
        count(*) || ' phosphopeptide matches were found',
        count(*) AS phosphopeptide_count
      FROM     (
        SELECT   phosphopeptide
        FROM     uniprotkb_pep_ppep_view
        GROUP BY phosphopeptide
        )
      """
    )
    for row in ker.fetchall():
        print(row[0])

    # link peptides not found in sequence database to a dummy sequence-record
    ker.execute(
        """
        INSERT INTO deppep_UniProtKB(deppep_id,UniProtKB_id,pos_start,pos_end)
          SELECT id, 'No Uniprot_ID', 0, 0
          FROM   deppep
          WHERE  id NOT IN (SELECT deppep_id FROM deppep_UniProtKB)
        """
    )

    con.commit()
    ker.execute("vacuum")
    con.close()


if __name__ == "__main__":
    wrap_start_time = time.perf_counter()
    __main__()
    wrap_stop_time = time.perf_counter()
    # print(wrap_start_time)
    # print(wrap_stop_time)
    print(
        "\nThe matching process took %d milliseconds to run.\n"
        % ((wrap_stop_time - wrap_start_time) * 1000),
    )

# vim: sw=4 ts=4 et ai :
