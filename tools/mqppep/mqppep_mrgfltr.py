#!/usr/bin/env python

# Import the packages needed
import argparse
import operator  # for operator.itemgetter
import os.path
import re
import shutil  # for shutil.copyfile(src, dest)
import sqlite3 as sql
import sys  # import the sys module for exc_info
import time
import traceback  # for formatting stack-trace
from codecs import getreader as cx_getreader

import numpy as np
import pandas

# global constants
N_A = "N/A"


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
        exit(-1)
        return None


def whine(func, *args, handle=lambda e: e, **kwargs):

    try:
        return func(*args, **kwargs)
    except Exception as e:
        print("Warning: For %s" % str(func))
        print("  with args %s" % str(args))
        print("  caught exception: %s" % str(e))
        (ty, va, tb) = sys.exc_info()
        print("  stack trace: " + str(traceback.format_exception(ty, va, tb)))
        return None


def ppep_join(x):
    x = [i for i in x if N_A != i]
    result = "%s" % " | ".join(x)
    if result != "":
        return result
    else:
        return N_A


def melt_join(x):
    tmp = {key.lower(): key for key in x}
    result = "%s" % " | ".join([tmp[key] for key in tmp])
    return result


def __main__():
    # Parse Command Line
    parser = argparse.ArgumentParser(
        description="Phopsphoproteomic Enrichment Pipeline Merge and Filter."
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
        help="Phosphopeptide data for experimental results, including the intensities and the mapping to kinase domains, in tabular format",
    )
    #   UniProtKB/SwissProt DB input, SQLite
    parser.add_argument(
        "--ppep_mapping_db",
        "-d",
        nargs=1,
        required=True,
        dest="ppep_mapping_db",
        help="UniProtKB/SwissProt SQLite Database",
    )
    #   species to limit records chosed from PhosPhositesPlus
    parser.add_argument(
        "--species",
        "-x",
        nargs=1,
        required=False,
        default=[],
        dest="species",
        help="limit PhosphoSitePlus records to indicated species (field may be empty)",
    )

    # outputs:
    #   tabular output
    parser.add_argument(
        "--mrgfltr_tab",
        "-o",
        nargs=1,
        required=True,
        dest="mrgfltr_tab",
        help="Tabular output file for results",
    )
    #   CSV output
    parser.add_argument(
        "--mrgfltr_csv",
        "-c",
        nargs=1,
        required=True,
        dest="mrgfltr_csv",
        help="CSV output file for results",
    )
    #   SQLite output
    parser.add_argument(
        "--mrgfltr_sqlite",
        "-S",
        nargs=1,
        required=True,
        dest="mrgfltr_sqlite",
        help="SQLite output file for results",
    )

    # "Make it so!" (parse the arguments)
    options = parser.parse_args()
    print("options: " + str(options))

    # determine phosphopeptide ("upstream map") input tabular file access
    if options.phosphopeptides is None:
        exit('Argument "phosphopeptides" is required but not supplied')
    try:
        upstream_map_filename_tab = os.path.abspath(options.phosphopeptides[0])
        input_file = open(upstream_map_filename_tab, "r")
        input_file.close()
    except Exception as e:
        exit("Error parsing phosphopeptides argument: %s" % str(e))

    # determine input SQLite access
    if options.ppep_mapping_db is None:
        exit('Argument "ppep_mapping_db" is required but not supplied')
    try:
        uniprot_sqlite = os.path.abspath(options.ppep_mapping_db[0])
        input_file = open(uniprot_sqlite, "rb")
        input_file.close()
    except Exception as e:
        exit("Error parsing ppep_mapping_db argument: %s" % str(e))

    # copy input SQLite dataset to output SQLite dataset
    if options.mrgfltr_sqlite is None:
        exit('Argument "mrgfltr_sqlite" is required but not supplied')
    try:
        output_sqlite = os.path.abspath(options.mrgfltr_sqlite[0])
        shutil.copyfile(uniprot_sqlite, output_sqlite)
    except Exception as e:
        exit("Error copying ppep_mapping_db to mrgfltr_sqlite: %s" % str(e))

    # determine species to limit records from PSP_Regulatory_Sites
    if options.species is None:
        exit(
            'Argument "species" is required (and may be empty) but not supplied'
        )
    try:
        if len(options.species) > 0:
            species = options.species[0]
        else:
            species = ""
    except Exception as e:
        exit("Error parsing species argument: %s" % str(e))

    # determine tabular output destination
    if options.mrgfltr_tab is None:
        exit('Argument "mrgfltr_tab" is required but not supplied')
    try:
        output_filename_tab = os.path.abspath(options.mrgfltr_tab[0])
        output_file = open(output_filename_tab, "w")
        output_file.close()
    except Exception as e:
        exit("Error parsing mrgfltr_tab argument: %s" % str(e))

    # determine CSV output destination
    if options.mrgfltr_csv is None:
        exit('Argument "mrgfltr_csv" is required but not supplied')
    try:
        output_filename_csv = os.path.abspath(options.mrgfltr_csv[0])
        output_file = open(output_filename_csv, "w")
        output_file.close()
    except Exception as e:
        exit("Error parsing mrgfltr_csv argument: %s" % str(e))

    def mqpep_getswissprot():

        #
        # copied from Excel Output Script.ipynb BEGIN #
        #

        #  String Constants  #################
        DEPHOSPHOPEP = "DephosphoPep"
        DESCRIPTION = "Description"
        FUNCTION_PHOSPHORESIDUE = (
            "Function Phosphoresidue(PSP=PhosphoSitePlus.org)"
        )
        GENE_NAME = "Gene_Name"  # Gene Name from UniProtKB
        ON_FUNCTION = (
            "ON_FUNCTION"  # ON_FUNCTION column from PSP_Regulatory_Sites
        )
        ON_NOTES = "NOTES"  # NOTES column from PSP_Regulatory_Sites
        ON_OTHER_INTERACT = "ON_OTHER_INTERACT"  # ON_OTHER_INTERACT column from PSP_Regulatory_Sites
        ON_PROCESS = (
            "ON_PROCESS"  # ON_PROCESS column from PSP_Regulatory_Sites
        )
        ON_PROT_INTERACT = "ON_PROT_INTERACT"  # ON_PROT_INTERACT column from PSP_Regulatory_Sites
        PHOSPHOPEPTIDE = "Phosphopeptide"
        PHOSPHOPEPTIDE_MATCH = "Phosphopeptide_match"
        PHOSPHORESIDUE = "Phosphoresidue"
        PUTATIVE_UPSTREAM_DOMAINS = "Putative Upstream Kinases(PSP=PhosphoSitePlus.org)/Phosphatases/Binding Domains"
        SEQUENCE = "Sequence"
        SEQUENCE10 = "Sequence10"
        SEQUENCE7 = "Sequence7"
        SITE_PLUSMINUS_7AA_SQL = "SITE_PLUSMINUS_7AA"
        UNIPROT_ID = "UniProt_ID"
        UNIPROT_SEQ_AND_META_SQL = """
            select    Uniprot_ID, Description, Gene_Name, Sequence,
                      Organism_Name, Organism_ID, PE, SV
                 from UniProtKB
             order by Sequence, UniProt_ID
        """
        UNIPROT_UNIQUE_SEQ_SQL = """
            select distinct Sequence
                       from UniProtKB
                   group by Sequence
        """
        PPEP_PEP_UNIPROTSEQ_SQL = """
            select distinct phosphopeptide, peptide, sequence
                       from uniprotkb_pep_ppep_view
                   order by sequence
        """
        PPEP_MELT_SQL = """
            SELECT DISTINCT
                phospho_peptide AS 'p_peptide',
                kinase_map AS 'characterization',
                'X' AS 'X'
            FROM ppep_gene_site_view
        """
        # CREATE TABLE PSP_Regulatory_site (
        #   site_plusminus_7AA TEXT PRIMARY KEY ON CONFLICT IGNORE,
        #   domain             TEXT,
        #   ON_FUNCTION        TEXT,
        #   ON_PROCESS         TEXT,
        #   ON_PROT_INTERACT   TEXT,
        #   ON_OTHER_INTERACT  TEXT,
        #   notes              TEXT,
        #   organism           TEXT
        # );
        PSP_REGSITE_SQL = """
            SELECT DISTINCT
              SITE_PLUSMINUS_7AA ,
              DOMAIN             ,
              ON_FUNCTION        ,
              ON_PROCESS         ,
              ON_PROT_INTERACT   ,
              ON_OTHER_INTERACT  ,
              NOTES              ,
              ORGANISM
            FROM PSP_Regulatory_site
        """
        PPEP_ID_SQL = """
            SELECT
                id AS 'ppep_id',
                seq AS 'ppep_seq'
            FROM ppep
        """
        MRGFLTR_DDL = """
        DROP VIEW  IF EXISTS mrgfltr_metadata_view;
        DROP TABLE IF EXISTS mrgfltr_metadata;
        CREATE TABLE mrgfltr_metadata
          ( ppep_id                 INTEGER REFERENCES ppep(id)
          , Sequence10              TEXT
          , Sequence7               TEXT
          , GeneName                TEXT
          , Phosphoresidue          TEXT
          , UniProtID               TEXT
          , Description             TEXT
          , FunctionPhosphoresidue  TEXT
          , PutativeUpstreamDomains TEXT
          , PRIMARY KEY (ppep_id)            ON CONFLICT IGNORE
          )
          ;
        CREATE VIEW mrgfltr_metadata_view AS
          SELECT DISTINCT
              ppep.seq             AS phospho_peptide
            , Sequence10
            , Sequence7
            , GeneName
            , Phosphoresidue
            , UniProtID
            , Description
            , FunctionPhosphoresidue
            , PutativeUpstreamDomains
          FROM
            ppep, mrgfltr_metadata
          WHERE
              mrgfltr_metadata.ppep_id = ppep.id
          ORDER BY
            ppep.seq
            ;
        """

        CITATION_INSERT_STMT = """
          INSERT INTO Citation (
            ObjectName,
            CitationData
          ) VALUES (?,?)
          """
        CITATION_INSERT_PSP = 'PhosphoSitePlus(R) (PSP) was created by Cell Signaling Technology Inc. It is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License. When using PSP data or analyses in printed publications or in online resources, the following acknowledgements must be included: (a) the words "PhosphoSitePlus(R), www.phosphosite.org" must be included at appropriate places in the text or webpage, and (b) the following citation must be included in the bibliography: "Hornbeck PV, Zhang B, Murray B, Kornhauser JM, Latham V, Skrzypek E PhosphoSitePlus, 2014: mutations, PTMs and recalibrations. Nucleic Acids Res. 2015 43:D512-20. PMID: 25514926."'
        CITATION_INSERT_PSP_REF = 'Hornbeck, 2014, "PhosphoSitePlus, 2014: mutations, PTMs and recalibrations.", https://pubmed.ncbi.nlm.nih.gov/22135298, https://doi.org/10.1093/nar/gkr1122'

        MRGFLTR_METADATA_COLUMNS = [
            "ppep_id",
            "Sequence10",
            "Sequence7",
            "GeneName",
            "Phosphoresidue",
            "UniProtID",
            "Description",
            "FunctionPhosphoresidue",
            "PutativeUpstreamDomains",
        ]

        #  String Constants (end) ############

        class Error(Exception):
            """Base class for exceptions in this module."""

            pass

        class PreconditionError(Error):
            """Exception raised for errors in the input.

            Attributes:
                expression -- input expression in which the error occurred
                message -- explanation of the error
            """

            def __init__(self, expression, message):
                self.expression = expression
                self.message = message

        # start_time = time.clock() #timer
        start_time = time.process_time()  # timer

        # get keys from upstream tabular file using readline()
        # ref: https://stackoverflow.com/a/16713581/15509512
        #      answer to "Use codecs to read file with correct encoding"
        file1_encoded = open(upstream_map_filename_tab, "rb")
        file1 = cx_getreader("latin-1")(file1_encoded)

        count = 0
        upstream_map_p_peptide_list = []
        re_tab = re.compile("^[^\t]*")
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
                upstream_map_p_peptide_list.append(m[0])
        file1.close()
        file1_encoded.close()

        # Get the list of phosphopeptides with the p's that represent the phosphorylation sites removed
        re_phos = re.compile("p")

        end_time = time.process_time()  # timer
        print(
            "%0.6f pre-read-SwissProt [0.1]" % (end_time - start_time,),
            file=sys.stderr,
        )

        # ----------- Get SwissProt data from SQLite database (start) -----------
        # build UniProt sequence LUT and list of unique SwissProt sequences

        # Open SwissProt SQLite database
        conn = sql.connect(uniprot_sqlite)
        cur = conn.cursor()

        # Set up structures to hold SwissProt data

        uniprot_Sequence_List = []
        UniProtSeqLUT = {}

        # Execute query for unique seqs without fetching the results yet
        uniprot_unique_seq_cur = cur.execute(UNIPROT_UNIQUE_SEQ_SQL)

        while 1:
            batch = uniprot_unique_seq_cur.fetchmany(size=50)
            if not batch:
                # handle case where no records are returned
                break
            for row in batch:
                Sequence = row[0]
                UniProtSeqLUT[(Sequence, DESCRIPTION)] = []
                UniProtSeqLUT[(Sequence, GENE_NAME)] = []
                UniProtSeqLUT[(Sequence, UNIPROT_ID)] = []
                UniProtSeqLUT[Sequence] = []

        # Execute query for seqs and metadata without fetching the results yet
        uniprot_seq_and_meta = cur.execute(UNIPROT_SEQ_AND_META_SQL)

        while 1:
            batch = uniprot_seq_and_meta.fetchmany(size=50)
            if not batch:
                # handle case where no records are returned
                break
            for (
                UniProt_ID,
                Description,
                Gene_Name,
                Sequence,
                OS,
                OX,
                PE,
                SV,
            ) in batch:
                uniprot_Sequence_List.append(Sequence)
                UniProtSeqLUT[Sequence] = Sequence
                UniProtSeqLUT[(Sequence, UNIPROT_ID)].append(UniProt_ID)
                UniProtSeqLUT[(Sequence, GENE_NAME)].append(Gene_Name)
                if OS != N_A:
                    Description += " OS=" + OS
                if OX != -1:
                    Description += " OX=" + str(OX)
                if Gene_Name != N_A:
                    Description += " GN=" + Gene_Name
                if PE != N_A:
                    Description += " PE=" + PE
                if SV != N_A:
                    Description += " SV=" + SV
                UniProtSeqLUT[(Sequence, DESCRIPTION)].append(Description)

        # Close SwissProt SQLite database; clean up local variables
        conn.close()
        Sequence = ""
        UniProt_ID = ""
        Description = ""
        Gene_Name = ""

        # ----------- Get SwissProt data from SQLite database (finish) -----------

        end_time = time.process_time()  # timer
        print(
            "%0.6f post-read-SwissProt [0.2]" % (end_time - start_time,),
            file=sys.stderr,
        )

        # ----------- Get SwissProt data from SQLite database (start) -----------
        # Open SwissProt SQLite database
        conn = sql.connect(uniprot_sqlite)
        cur = conn.cursor()

        # Set up dictionary to aggregate results for phosphopeptides correspounding to dephosphoeptide
        DephosphoPep_UniProtSeq_LUT = {}

        # Set up dictionary to accumulate results
        PhosphoPep_UniProtSeq_LUT = {}

        # Execute query for tuples without fetching the results yet
        ppep_pep_uniprotseq_cur = cur.execute(PPEP_PEP_UNIPROTSEQ_SQL)

        while 1:
            batch = ppep_pep_uniprotseq_cur.fetchmany(size=50)
            if not batch:
                # handle case where no records are returned
                break
            for (phospho_pep, dephospho_pep, sequence) in batch:
                # do interesting stuff here...
                PhosphoPep_UniProtSeq_LUT[phospho_pep] = phospho_pep
                PhosphoPep_UniProtSeq_LUT[
                    (phospho_pep, DEPHOSPHOPEP)
                ] = dephospho_pep
                if dephospho_pep not in DephosphoPep_UniProtSeq_LUT:
                    DephosphoPep_UniProtSeq_LUT[dephospho_pep] = set()
                    DephosphoPep_UniProtSeq_LUT[
                        (dephospho_pep, DESCRIPTION)
                    ] = []
                    DephosphoPep_UniProtSeq_LUT[
                        (dephospho_pep, GENE_NAME)
                    ] = []
                    DephosphoPep_UniProtSeq_LUT[
                        (dephospho_pep, UNIPROT_ID)
                    ] = []
                    DephosphoPep_UniProtSeq_LUT[(dephospho_pep, SEQUENCE)] = []
                DephosphoPep_UniProtSeq_LUT[dephospho_pep].add(phospho_pep)

                if (
                    sequence
                    not in DephosphoPep_UniProtSeq_LUT[
                        (dephospho_pep, SEQUENCE)
                    ]
                ):
                    DephosphoPep_UniProtSeq_LUT[
                        (dephospho_pep, SEQUENCE)
                    ].append(sequence)
                for phospho_pep in DephosphoPep_UniProtSeq_LUT[dephospho_pep]:
                    if phospho_pep != phospho_pep:
                        print(
                            "phospho_pep:'%s' phospho_pep:'%s'"
                            % (phospho_pep, phospho_pep)
                        )
                    if phospho_pep not in PhosphoPep_UniProtSeq_LUT:
                        PhosphoPep_UniProtSeq_LUT[phospho_pep] = phospho_pep
                        PhosphoPep_UniProtSeq_LUT[
                            (phospho_pep, DEPHOSPHOPEP)
                        ] = dephospho_pep
                    r = list(
                        zip(
                            [s for s in UniProtSeqLUT[(sequence, UNIPROT_ID)]],
                            [s for s in UniProtSeqLUT[(sequence, GENE_NAME)]],
                            [
                                s
                                for s in UniProtSeqLUT[(sequence, DESCRIPTION)]
                            ],
                        )
                    )
                    # Sort by `UniProt_ID`
                    #   ref: https://stackoverflow.com/a/4174955/15509512
                    r = sorted(r, key=operator.itemgetter(0))
                    # Get one tuple for each `phospho_pep`
                    #   in DephosphoPep_UniProtSeq_LUT[dephospho_pep]
                    for (upid, gn, desc) in r:
                        # Append pseudo-tuple per UniProt_ID but only when it is not present
                        if (
                            upid
                            not in DephosphoPep_UniProtSeq_LUT[
                                (dephospho_pep, UNIPROT_ID)
                            ]
                        ):
                            DephosphoPep_UniProtSeq_LUT[
                                (dephospho_pep, UNIPROT_ID)
                            ].append(upid)
                            DephosphoPep_UniProtSeq_LUT[
                                (dephospho_pep, DESCRIPTION)
                            ].append(desc)
                            DephosphoPep_UniProtSeq_LUT[
                                (dephospho_pep, GENE_NAME)
                            ].append(gn)

        # Close SwissProt SQLite database; clean up local variables
        conn.close()
        # wipe local variables
        phospho_pep = dephospho_pep = sequence = 0
        upid = gn = desc = r = ""

        # ----------- Get SwissProt data from SQLite database (finish) -----------

        end_time = time.process_time()  # timer
        print(
            "%0.6f finished reading and decoding '%s' [0.4]"
            % (end_time - start_time, upstream_map_filename_tab),
            file=sys.stderr,
        )

        print(
            "{:>10} unique upstream phosphopeptides tested".format(
                str(len(upstream_map_p_peptide_list))
            )
        )

        # Read in Upstream tabular file
        # We are discarding the intensity data; so read it as text
        upstream_data = pandas.read_table(
            upstream_map_filename_tab, dtype="str", index_col=0
        )

        end_time = time.process_time()  # timer
        print(
            "%0.6f read Upstream Map from file [1g_1]"
            % (end_time - start_time,),
            file=sys.stderr,
        )  # timer

        upstream_data.index = upstream_map_p_peptide_list

        end_time = time.process_time()  # timer
        print(
            "%0.6f added index to Upstream Map [1g_2]"
            % (end_time - start_time,),
            file=sys.stderr,
        )  # timer

        # trim upstream_data to include only the upstream map columns
        old_cols = upstream_data.columns.tolist()
        i = 0
        first_intensity = -1
        last_intensity = -1
        intensity_re = re.compile("Intensity.*")
        for col_name in old_cols:
            m = intensity_re.match(col_name)
            if m:
                last_intensity = i
                if first_intensity == -1:
                    first_intensity = i
            i += 1
        # print('last intensity = %d' % last_intensity)
        col_PKCalpha = last_intensity + 2

        data_in_cols = [old_cols[0]] + old_cols[
            first_intensity: last_intensity + 1
        ]

        if upstream_data.empty:
            print("upstream_data is empty")
            exit(0)

        data_in = upstream_data.copy(deep=True)[data_in_cols]

        # Convert floating-point integers to int64 integers
        #   ref: https://stackoverflow.com/a/68497603/15509512
        data_in[list(data_in.columns[1:])] = (
            data_in[list(data_in.columns[1:])]
            .astype("float64")
            .apply(np.int64)
        )

        # create another phosphopeptide column that will be used to join later;
        #  MAY need to change depending on Phosphopeptide column position
        # data_in[PHOSPHOPEPTIDE_MATCH] = data_in[data_in.columns.tolist()[0]]
        data_in[PHOSPHOPEPTIDE_MATCH] = data_in.index

        end_time = time.process_time()  # timer
        print(
            "%0.6f set data_in[PHOSPHOPEPTIDE_MATCH] [A]"
            % (end_time - start_time,),
            file=sys.stderr,
        )  # timer

        # Produce a dictionary of metadata for a single phosphopeptide.
        #   This is a replacement of `UniProtInfo_subdict` in the original code.
        def pseq_to_subdict(phospho_pep):
            # Strip "p" from phosphopeptide sequence
            dephospho_pep = re_phos.sub("", phospho_pep)

            # Determine number of phosphoresidues in phosphopeptide
            numps = len(phospho_pep) - len(dephospho_pep)

            # Determine location(s) of phosphoresidue(s) in phosphopeptide
            #   (used later for Phosphoresidue, Sequence7, and Sequence10)
            ploc = []  # list of p locations
            i = 0
            p = phospho_pep
            while i < numps:
                ploc.append(p.find("p"))
                p = p[: p.find("p")] + p[p.find("p") + 1:]
                i += 1

            # Establish nested dictionary
            result = {}
            result[SEQUENCE] = []
            result[UNIPROT_ID] = []
            result[DESCRIPTION] = []
            result[GENE_NAME] = []
            result[PHOSPHORESIDUE] = []
            result[SEQUENCE7] = []
            result[SEQUENCE10] = []

            # Add stripped sequence to dictionary
            result[SEQUENCE].append(dephospho_pep)

            # Locate phospho_pep in PhosphoPep_UniProtSeq_LUT
            # Caller may elect to:
            # try:
            #     ...
            # except PreconditionError as pe:
            #     print("'{expression}': {message}".format(
            #             expression = pe.expression,
            #             message = pe.message))
            #             )
            #         )
            if phospho_pep not in PhosphoPep_UniProtSeq_LUT:
                raise PreconditionError(
                    phospho_pep,
                    "no matching phosphopeptide found in PhosphoPep_UniProtSeq_LUT",
                )
            if dephospho_pep not in DephosphoPep_UniProtSeq_LUT:
                raise PreconditionError(
                    dephospho_pep,
                    "dephosphorylated phosphopeptide not found in DephosphoPep_UniProtSeq_LUT",
                )
            if (
                dephospho_pep != PhosphoPep_UniProtSeq_LUT[(phospho_pep, DEPHOSPHOPEP)]
            ):
                my_err_msg = "dephosphorylated phosphopeptide does not match "
                my_err_msg += "PhosphoPep_UniProtSeq_LUT[(phospho_pep,DEPHOSPHOPEP)] = "
                my_err_msg += PhosphoPep_UniProtSeq_LUT[(phospho_pep, DEPHOSPHOPEP)]
                raise PreconditionError(dephospho_pep, my_err_msg)

            result[SEQUENCE] = [dephospho_pep]
            result[UNIPROT_ID] = DephosphoPep_UniProtSeq_LUT[
                (dephospho_pep, UNIPROT_ID)
            ]
            result[DESCRIPTION] = DephosphoPep_UniProtSeq_LUT[
                (dephospho_pep, DESCRIPTION)
            ]
            result[GENE_NAME] = DephosphoPep_UniProtSeq_LUT[
                (dephospho_pep, GENE_NAME)
            ]
            if (dephospho_pep, SEQUENCE) not in DephosphoPep_UniProtSeq_LUT:
                raise PreconditionError(
                    dephospho_pep,
                    "no matching phosphopeptide found in DephosphoPep_UniProtSeq_LUT",
                )
            UniProtSeqList = DephosphoPep_UniProtSeq_LUT[
                (dephospho_pep, SEQUENCE)
            ]
            if len(UniProtSeqList) < 1:
                print(
                    "Skipping DephosphoPep_UniProtSeq_LUT[('%s',SEQUENCE)] because value has zero length"
                    % dephospho_pep
                )
                # raise PreconditionError(
                #     "DephosphoPep_UniProtSeq_LUT[('" + dephospho_pep + ",SEQUENCE)",
                #      'value has zero length'
                #      )
            for UniProtSeq in UniProtSeqList:
                i = 0
                phosphoresidues = []
                seq7s_set = set()
                seq7s = []
                seq10s_set = set()
                seq10s = []
                while i < len(ploc):
                    start = UniProtSeq.find(dephospho_pep)
                    # handle case where no sequence was found for dep-pep
                    if start < 0:
                        i += 1
                        continue
                    psite = (
                        start + ploc[i]
                    )  # location of phosphoresidue on protein sequence

                    # add Phosphoresidue
                    phosphosite = "p" + str(UniProtSeq)[psite] + str(psite + 1)
                    phosphoresidues.append(phosphosite)

                    # Add Sequence7
                    if psite < 7:  # phospho_pep at N terminus
                        seq7 = str(UniProtSeq)[: psite + 8]
                        if seq7[psite] == "S":  # if phosphosresidue is serine
                            pres = "s"
                        elif (
                            seq7[psite] == "T"
                        ):  # if phosphosresidue is threonine
                            pres = "t"
                        elif (
                            seq7[psite] == "Y"
                        ):  # if phosphoresidue is tyrosine
                            pres = "y"
                        else:  # if not pSTY
                            pres = "?"
                        seq7 = (
                            seq7[:psite] + pres + seq7[psite + 1: psite + 8]
                        )
                        while (
                            len(seq7) < 15
                        ):  # add appropriate number of "_" to the front
                            seq7 = "_" + seq7
                    elif (
                        len(UniProtSeq) - psite < 8
                    ):  # phospho_pep at C terminus
                        seq7 = str(UniProtSeq)[psite - 7:]
                        if seq7[7] == "S":
                            pres = "s"
                        elif seq7[7] == "T":
                            pres = "t"
                        elif seq7[7] == "Y":
                            pres = "y"
                        else:
                            pres = "?"
                        seq7 = seq7[:7] + pres + seq7[8:]
                        while (
                            len(seq7) < 15
                        ):  # add appropriate number of "_" to the back
                            seq7 = seq7 + "_"
                    else:
                        seq7 = str(UniProtSeq)[psite - 7: psite + 8]
                        pres = ""  # phosphoresidue
                        if seq7[7] == "S":  # if phosphosresidue is serine
                            pres = "s"
                        elif seq7[7] == "T":  # if phosphosresidue is threonine
                            pres = "t"
                        elif seq7[7] == "Y":  # if phosphoresidue is tyrosine
                            pres = "y"
                        else:  # if not pSTY
                            pres = "?"
                        seq7 = seq7[:7] + pres + seq7[8:]
                    if seq7 not in seq7s_set:
                        seq7s.append(seq7)
                        seq7s_set.add(seq7)

                    # add Sequence10
                    if psite < 10:  # phospho_pep at N terminus
                        seq10 = (
                            str(UniProtSeq)[:psite] + "p" + str(UniProtSeq)[psite: psite + 11]
                        )
                    elif (
                        len(UniProtSeq) - psite < 11
                    ):  # phospho_pep at C terminus
                        seq10 = (
                            str(UniProtSeq)[psite - 10: psite] + "p" + str(UniProtSeq)[psite:]
                        )
                    else:
                        seq10 = str(UniProtSeq)[psite - 10: psite + 11]
                        seq10 = seq10[:10] + "p" + seq10[10:]
                    if seq10 not in seq10s_set:
                        seq10s.append(seq10)
                        seq10s_set.add(seq10)

                    i += 1

                result[PHOSPHORESIDUE].append(phosphoresidues)
                result[SEQUENCE7].append(seq7s)
                # result[SEQUENCE10] is a list of lists of strings
                result[SEQUENCE10].append(seq10s)

            r = list(
                zip(
                    result[UNIPROT_ID],
                    result[GENE_NAME],
                    result[DESCRIPTION],
                    result[PHOSPHORESIDUE],
                )
            )
            # Sort by `UniProt_ID`
            #   ref: https://stackoverflow.com//4174955/15509512
            s = sorted(r, key=operator.itemgetter(0))

            result[UNIPROT_ID] = []
            result[GENE_NAME] = []
            result[DESCRIPTION] = []
            result[PHOSPHORESIDUE] = []

            for r in s:
                result[UNIPROT_ID].append(r[0])
                result[GENE_NAME].append(r[1])
                result[DESCRIPTION].append(r[2])
                result[PHOSPHORESIDUE].append(r[3])

            # convert lists to strings in the dictionary
            for key, value in result.items():
                if key not in [PHOSPHORESIDUE, SEQUENCE7, SEQUENCE10]:
                    result[key] = "; ".join(map(str, value))
                elif key in [SEQUENCE10]:
                    # result[SEQUENCE10] is a list of lists of strings
                    joined_value = ""
                    joined_set = set()
                    sep = ""
                    for valL in value:
                        # valL is a list of strings
                        for val in valL:
                            # val is a string
                            if val not in joined_set:
                                joined_set.add(val)
                                joined_value += sep + val
                                sep = "; "
                    # joined_value is a string
                    result[key] = joined_value

            newstring = "; ".join(
                [", ".join(prez) for prez in result[PHOSPHORESIDUE]]
            )
            # #separate the isoforms in PHOSPHORESIDUE column with ";"
            # oldstring = result[PHOSPHORESIDUE]
            # oldlist = list(oldstring)
            # newstring = ""
            # i = 0
            # for e in oldlist:
            #     if e == ";":
            #         if numps > 1:
            #             if i%numps:
            #                 newstring = newstring + ";"
            #             else:
            #                 newstring = newstring + ","
            #         else:
            #             newstring = newstring + ";"
            #         i +=1
            #     else:
            #         newstring = newstring + e
            result[PHOSPHORESIDUE] = newstring

            # separate sequence7's by |
            oldstring = result[SEQUENCE7]
            oldlist = oldstring
            newstring = ""
            for ol in oldlist:
                for e in ol:
                    if e == ";":
                        newstring = newstring + " |"
                    elif len(newstring) > 0 and 1 > newstring.count(e):
                        newstring = newstring + " | " + e
                    elif 1 > newstring.count(e):
                        newstring = newstring + e
            result[SEQUENCE7] = newstring

            return [phospho_pep, result]

        # Construct list of [string, dictionary] lists
        #   where the dictionary provides the SwissProt metadata
        #   for a phosphopeptide
        result_list = [
            whine(pseq_to_subdict, psequence)
            for psequence in data_in[PHOSPHOPEPTIDE_MATCH]
        ]

        end_time = time.process_time()  # timer
        print(
            "%0.6f added SwissProt annotations to phosphopeptides [B]"
            % (end_time - start_time,),
            file=sys.stderr,
        )  # timer

        # Construct dictionary from list of lists
        #   ref: https://www.8bitavenue.com/how-to-convert-list-of-lists-to-dictionary-in-python/
        UniProt_Info = {
            result[0]: result[1]
            for result in result_list
            if result is not None
        }

        end_time = time.process_time()  # timer
        print(
            "%0.6f create dictionary mapping phosphopeptide to metadata dictionary [C]"
            % (end_time - start_time,),
            file=sys.stderr,
        )  # timer

        # cosmetic: add N_A to phosphopeptide rows with no hits
        p_peptide_list = []
        for key in UniProt_Info:
            p_peptide_list.append(key)
            for nestedKey in UniProt_Info[key]:
                if UniProt_Info[key][nestedKey] == "":
                    UniProt_Info[key][nestedKey] = N_A

        end_time = time.process_time()  # timer
        print(
            "%0.6f performed cosmetic clean-up [D]" % (end_time - start_time,),
            file=sys.stderr,
        )  # timer

        # convert UniProt_Info dictionary to dataframe
        uniprot_df = pandas.DataFrame.transpose(
            pandas.DataFrame.from_dict(UniProt_Info)
        )

        # reorder columns to match expected output file
        uniprot_df[
            PHOSPHOPEPTIDE
        ] = uniprot_df.index  # make index a column too

        cols = uniprot_df.columns.tolist()
        # cols = [cols[-1]]+cols[4:6]+[cols[1]]+[cols[2]]+[cols[6]]+[cols[0]]
        # uniprot_df = uniprot_df[cols]
        uniprot_df = uniprot_df[
            [
                PHOSPHOPEPTIDE,
                SEQUENCE10,
                SEQUENCE7,
                GENE_NAME,
                PHOSPHORESIDUE,
                UNIPROT_ID,
                DESCRIPTION,
            ]
        ]

        end_time = time.process_time()  # timer
        print(
            "%0.6f reordered columns to match expected output file [1]"
            % (end_time - start_time,),
            file=sys.stderr,
        )  # timer

        # concat to split then groupby to collapse
        seq7_df = pandas.concat(
            [
                pandas.Series(row[PHOSPHOPEPTIDE], row[SEQUENCE7].split(" | "))
                for _, row in uniprot_df.iterrows()
            ]
        ).reset_index()
        seq7_df.columns = [SEQUENCE7, PHOSPHOPEPTIDE]

        # --- -------------- begin read PSP_Regulatory_sites ---------------------------------
        # read in PhosphoSitePlus Regulatory Sites dataset
        # ----------- Get PhosphoSitePlus Regulatory Sites data from SQLite database (start) -----------
        conn = sql.connect(uniprot_sqlite)
        regsites_df = pandas.read_sql_query(PSP_REGSITE_SQL, conn)
        # Close SwissProt SQLite database
        conn.close()
        # ... -------------- end read PSP_Regulatory_sites ------------------------------------

        # keep only the human entries in dataframe
        if len(species) > 0:
            print(
                'Limit PhosphoSitesPlus records to species "' + species + '"'
            )
            regsites_df = regsites_df[regsites_df.ORGANISM == species]

        # merge the seq7 df with the regsites df based off of the sequence7
        merge_df = seq7_df.merge(
            regsites_df,
            left_on=SEQUENCE7,
            right_on=SITE_PLUSMINUS_7AA_SQL,
            how="left",
        )

        # after merging df, select only the columns of interest;
        #   note that PROTEIN is absent here
        merge_df = merge_df[
            [
                PHOSPHOPEPTIDE,
                SEQUENCE7,
                ON_FUNCTION,
                ON_PROCESS,
                ON_PROT_INTERACT,
                ON_OTHER_INTERACT,
                ON_NOTES,
            ]
        ]
        # combine column values of interest
        #   into one FUNCTION_PHOSPHORESIDUE column"
        merge_df[FUNCTION_PHOSPHORESIDUE] = merge_df[ON_FUNCTION].str.cat(
            merge_df[ON_PROCESS], sep="; ", na_rep=""
        )
        merge_df[FUNCTION_PHOSPHORESIDUE] = merge_df[
            FUNCTION_PHOSPHORESIDUE
        ].str.cat(merge_df[ON_PROT_INTERACT], sep="; ", na_rep="")
        merge_df[FUNCTION_PHOSPHORESIDUE] = merge_df[
            FUNCTION_PHOSPHORESIDUE
        ].str.cat(merge_df[ON_OTHER_INTERACT], sep="; ", na_rep="")
        merge_df[FUNCTION_PHOSPHORESIDUE] = merge_df[
            FUNCTION_PHOSPHORESIDUE
        ].str.cat(merge_df[ON_NOTES], sep="; ", na_rep="")

        # remove the columns that were combined
        merge_df = merge_df[
            [PHOSPHOPEPTIDE, SEQUENCE7, FUNCTION_PHOSPHORESIDUE]
        ]

        end_time = time.process_time()  # timer
        print(
            "%0.6f merge regsite metadata [1a]" % (end_time - start_time,),
            file=sys.stderr,
        )  # timer

        # cosmetic changes to Function Phosphoresidue column
        fp_series = pandas.Series(merge_df[FUNCTION_PHOSPHORESIDUE])

        end_time = time.process_time()  # timer
        print(
            "%0.6f more cosmetic changes [1b]" % (end_time - start_time,),
            file=sys.stderr,
        )  # timer

        i = 0
        while i < len(fp_series):
            # remove the extra ";" so that it looks more professional
            if fp_series[i] == "; ; ; ; ":  # remove ; from empty hits
                fp_series[i] = ""
            while fp_series[i].endswith("; "):  # remove ; from the ends
                fp_series[i] = fp_series[i][:-2]
            while fp_series[i].startswith("; "):  # remove ; from the beginning
                fp_series[i] = fp_series[i][2:]
            fp_series[i] = fp_series[i].replace("; ; ; ; ", "; ")
            fp_series[i] = fp_series[i].replace("; ; ; ", "; ")
            fp_series[i] = fp_series[i].replace("; ; ", "; ")

            # turn blanks into N_A to signify the info was searched for but cannot be found
            if fp_series[i] == "":
                fp_series[i] = N_A

            i += 1
        merge_df[FUNCTION_PHOSPHORESIDUE] = fp_series

        end_time = time.process_time()  # timer
        print(
            "%0.6f cleaned up semicolons [1c]" % (end_time - start_time,),
            file=sys.stderr,
        )  # timer

        # merge uniprot df with merge df
        uniprot_regsites_merged_df = uniprot_df.merge(
            merge_df,
            left_on=PHOSPHOPEPTIDE,
            right_on=PHOSPHOPEPTIDE,
            how="left",
        )

        # collapse the merged df
        uniprot_regsites_collapsed_df = pandas.DataFrame(
            uniprot_regsites_merged_df.groupby(PHOSPHOPEPTIDE)[
                FUNCTION_PHOSPHORESIDUE
            ].apply(lambda x: ppep_join(x))
        )
        # .apply(lambda x: "%s" % ' | '.join(x)))

        end_time = time.process_time()  # timer
        print(
            "%0.6f collapsed pandas dataframe [1d]" % (end_time - start_time,),
            file=sys.stderr,
        )  # timer

        uniprot_regsites_collapsed_df[
            PHOSPHOPEPTIDE
        ] = (
            uniprot_regsites_collapsed_df.index
        )  # add df index as its own column

        # rename columns
        uniprot_regsites_collapsed_df.columns = [
            FUNCTION_PHOSPHORESIDUE,
            "ppp",
        ]

        end_time = time.process_time()  # timer
        print(
            "%0.6f selected columns to be merged to uniprot_df [1e]"
            % (end_time - start_time,),
            file=sys.stderr,
        )  # timer

        # add columns based on Sequence7 matching site_+/-7_AA
        uniprot_regsite_df = pandas.merge(
            left=uniprot_df,
            right=uniprot_regsites_collapsed_df,
            how="left",
            left_on=PHOSPHOPEPTIDE,
            right_on="ppp",
        )

        end_time = time.process_time()  # timer
        print(
            "%0.6f added columns based on Sequence7 matching site_+/-7_AA [1f]"
            % (end_time - start_time,),
            file=sys.stderr,
        )  # timer

        data_in.rename(
            {"Protein description": PHOSPHOPEPTIDE},
            axis="columns",
            inplace=True,
        )

        # data_in.sort_values(PHOSPHOPEPTIDE_MATCH, inplace=True, kind='mergesort')
        res2 = sorted(
            data_in[PHOSPHOPEPTIDE_MATCH].tolist(), key=lambda s: s.casefold()
        )
        data_in = data_in.loc[res2]

        end_time = time.process_time()  # timer
        print(
            "%0.6f sorting time [1f]" % (end_time - start_time,),
            file=sys.stderr,
        )  # timer

        cols = [old_cols[0]] + old_cols[col_PKCalpha - 1:]
        upstream_data = upstream_data[cols]

        end_time = time.process_time()  # timer
        print(
            "%0.6f refactored columns for Upstream Map [1g]"
            % (end_time - start_time,),
            file=sys.stderr,
        )  # timer

        # #rename upstream columns in new list
        # new_cols = []
        # for name in cols:
        #     if "_NetworKIN" in name:
        #         name = name.split("_")[0]
        #     if " motif" in name:
        #         name = name.split(" motif")[0]
        #     if " sequence " in name:
        #         name = name.split(" sequence")[0]
        #     if "_Phosida" in name:
        #         name = name.split("_")[0]
        #     if "_PhosphoSite" in name:
        #         name = name.split("_")[0]
        #     new_cols.append(name)

        # rename upstream columns in new list
        def col_rename(name):
            if "_NetworKIN" in name:
                name = name.split("_")[0]
            if " motif" in name:
                name = name.split(" motif")[0]
            if " sequence " in name:
                name = name.split(" sequence")[0]
            if "_Phosida" in name:
                name = name.split("_")[0]
            if "_PhosphoSite" in name:
                name = name.split("_")[0]
            return name

        new_cols = [col_rename(col) for col in cols]
        upstream_data.columns = new_cols

        end_time = time.process_time()  # timer
        print(
            "%0.6f renamed columns for Upstream Map [1h_1]"
            % (end_time - start_time,),
            file=sys.stderr,
        )  # timer

        # Create upstream_data_cast as a copy of upstream_data
        #   but with first column substituted by the phosphopeptide sequence
        upstream_data_cast = upstream_data.copy()
        new_cols_cast = new_cols
        new_cols_cast[0] = "p_peptide"
        upstream_data_cast.columns = new_cols_cast
        upstream_data_cast["p_peptide"] = upstream_data.index

        # --- -------------- begin read upstream_data_melt ------------------------------------
        # ----------- Get melted kinase mapping data from SQLite database (start) -----------
        conn = sql.connect(uniprot_sqlite)
        upstream_data_melt_df = pandas.read_sql_query(PPEP_MELT_SQL, conn)
        # Close SwissProt SQLite database
        conn.close()
        upstream_data_melt = upstream_data_melt_df.copy()
        upstream_data_melt.columns = ["p_peptide", "characterization", "X"]
        upstream_data_melt["characterization"] = [
            col_rename(s) for s in upstream_data_melt["characterization"]
        ]

        print(
            "%0.6f upstream_data_melt_df initially has %d rows"
            % (end_time - start_time, len(upstream_data_melt.axes[0])),
            file=sys.stderr,
        )
        # ref: https://stackoverflow.com/a/27360130/15509512
        #      e.g. df.drop(df[df.score < 50].index, inplace=True)
        upstream_data_melt.drop(
            upstream_data_melt[upstream_data_melt.X != "X"].index, inplace=True
        )
        print(
            "%0.6f upstream_data_melt_df pre-dedup has %d rows"
            % (end_time - start_time, len(upstream_data_melt.axes[0])),
            file=sys.stderr,
        )
        # ----------- Get melted kinase mapping data from SQLite database (finish) -----------
        # ... -------------- end read upstream_data_melt --------------------------------------

        end_time = time.process_time()  # timer
        print(
            "%0.6f melted and minimized Upstream Map dataframe [1h_2]"
            % (end_time - start_time,),
            file=sys.stderr,
        )  # timer
        # ... end read upstream_data_melt

        end_time = time.process_time()  # timer
        print(
            "%0.6f indexed melted Upstream Map [1h_2a]"
            % (end_time - start_time,),
            file=sys.stderr,
        )  # timer

        upstream_delta_melt_LoL = upstream_data_melt.values.tolist()

        melt_dict = {}
        for key in upstream_map_p_peptide_list:
            melt_dict[key] = []

        for el in upstream_delta_melt_LoL:
            (p_peptide, characterization, X) = tuple(el)
            if p_peptide in melt_dict:
                melt_dict[p_peptide].append(characterization)
            else:
                exit(
                    'Phosphopeptide %s not found in ppep_mapping_db: "phopsphopeptides" and "ppep_mapping_db" must both originate from the same run of mqppep_kinase_mapping'
                    % (p_peptide)
                )

        end_time = time.process_time()  # timer
        print(
            "%0.6f appended peptide characterizations [1h_2b]"
            % (end_time - start_time,),
            file=sys.stderr,
        )  # timer

        # for key in upstream_map_p_peptide_list:
        #     melt_dict[key] = ' | '.join(melt_dict[key])

        for key in upstream_map_p_peptide_list:
            melt_dict[key] = melt_join(melt_dict[key])

        end_time = time.process_time()  # timer
        print(
            "%0.6f concatenated multiple characterizations [1h_2c]"
            % (end_time - start_time,),
            file=sys.stderr,
        )  # timer

        # map_dict is a dictionary of dictionaries
        map_dict = {}
        for key in upstream_map_p_peptide_list:
            map_dict[key] = {}
            map_dict[key][PUTATIVE_UPSTREAM_DOMAINS] = melt_dict[key]

        end_time = time.process_time()  # timer
        print(
            "%0.6f instantiated map dictionary [2]" % (end_time - start_time,),
            file=sys.stderr,
        )  # timer

        # convert map_dict to dataframe
        map_df = pandas.DataFrame.transpose(
            pandas.DataFrame.from_dict(map_dict)
        )
        map_df["p-peptide"] = map_df.index  # make index a column too
        cols_map_df = map_df.columns.tolist()
        cols_map_df = [cols_map_df[1]] + [cols_map_df[0]]
        map_df = map_df[cols_map_df]

        # join map_df to uniprot_regsite_df
        output_df = uniprot_regsite_df.merge(
            map_df, how="left", left_on=PHOSPHOPEPTIDE, right_on="p-peptide"
        )

        output_df = output_df[
            [
                PHOSPHOPEPTIDE,
                SEQUENCE10,
                SEQUENCE7,
                GENE_NAME,
                PHOSPHORESIDUE,
                UNIPROT_ID,
                DESCRIPTION,
                FUNCTION_PHOSPHORESIDUE,
                PUTATIVE_UPSTREAM_DOMAINS,
            ]
        ]

        # cols_output_prelim = output_df.columns.tolist()
        #
        # print("cols_output_prelim")
        # print(cols_output_prelim)
        #
        # cols_output = cols_output_prelim[:8]+[cols_output_prelim[9]]+[cols_output_prelim[10]]
        #
        # print("cols_output with p-peptide")
        # print(cols_output)
        #
        # cols_output = [col for col in cols_output if not col == "p-peptide"]
        #
        # print("cols_output")
        # print(cols_output)
        #
        # output_df = output_df[cols_output]

        # join output_df back to quantitative columns in data_in df
        quant_cols = data_in.columns.tolist()
        quant_cols = quant_cols[1:]
        quant_data = data_in[quant_cols]

        # ----------- Write merge/filter metadata to SQLite database (start) -----------
        # Open SwissProt SQLite database
        conn = sql.connect(output_sqlite)
        cur = conn.cursor()

        cur.executescript(MRGFLTR_DDL)

        cur.execute(
            CITATION_INSERT_STMT,
            ("mrgfltr_metadata_view", CITATION_INSERT_PSP),
        )
        cur.execute(
            CITATION_INSERT_STMT, ("mrgfltr_metadata", CITATION_INSERT_PSP)
        )
        cur.execute(
            CITATION_INSERT_STMT,
            ("mrgfltr_metadata_view", CITATION_INSERT_PSP_REF),
        )
        cur.execute(
            CITATION_INSERT_STMT, ("mrgfltr_metadata", CITATION_INSERT_PSP_REF)
        )

        # Read ppep-to-sequence LUT
        ppep_lut_df = pandas.read_sql_query(PPEP_ID_SQL, conn)
        # write only metadata for merged/filtered records to SQLite
        mrgfltr_metadata_df = output_df.copy()
        # replace phosphopeptide seq with ppep.id
        mrgfltr_metadata_df = ppep_lut_df.merge(
            mrgfltr_metadata_df,
            left_on="ppep_seq",
            right_on=PHOSPHOPEPTIDE,
            how="inner",
        )
        mrgfltr_metadata_df.drop(
            columns=[PHOSPHOPEPTIDE, "ppep_seq"], inplace=True
        )
        # rename columns
        mrgfltr_metadata_df.columns = MRGFLTR_METADATA_COLUMNS
        mrgfltr_metadata_df.to_sql(
            "mrgfltr_metadata",
            con=conn,
            if_exists="append",
            index=False,
            method="multi",
        )

        # Close SwissProt SQLite database
        conn.close()
        # ----------- Write merge/filter metadata to SQLite database (finish) -----------

        output_df = output_df.merge(
            quant_data,
            how="right",
            left_on=PHOSPHOPEPTIDE,
            right_on=PHOSPHOPEPTIDE_MATCH,
        )
        output_cols = output_df.columns.tolist()
        output_cols = output_cols[:-1]
        output_df = output_df[output_cols]

        # cosmetic changes to Upstream column
        output_df[PUTATIVE_UPSTREAM_DOMAINS] = output_df[
            PUTATIVE_UPSTREAM_DOMAINS
        ].fillna(
            ""
        )  # fill the NaN with "" for those Phosphopeptides that got a "WARNING: Failed match for " in the upstream mapping
        us_series = pandas.Series(output_df[PUTATIVE_UPSTREAM_DOMAINS])
        i = 0
        while i < len(us_series):
            # turn blanks into N_A to signify the info was searched for but cannot be found
            if us_series[i] == "":
                us_series[i] = N_A
            i += 1
        output_df[PUTATIVE_UPSTREAM_DOMAINS] = us_series

        end_time = time.process_time()  # timer
        print(
            "%0.6f establisheed output [3]" % (end_time - start_time,),
            file=sys.stderr,
        )  # timer

        (output_rows, output_cols) = output_df.shape

        output_df = output_df.convert_dtypes(convert_integer=True)

        # Output onto Final CSV file
        output_df.to_csv(output_filename_csv, index=False)
        output_df.to_csv(
            output_filename_tab, quoting=None, sep="\t", index=False
        )

        end_time = time.process_time()  # timer
        print(
            "%0.6f wrote output [4]" % (end_time - start_time,),
            file=sys.stderr,
        )  # timer

        print(
            "{:>10} phosphopeptides written to output".format(str(output_rows))
        )

        end_time = time.process_time()  # timer
        print(
            "%0.6f seconds of non-system CPU time were consumed"
            % (end_time - start_time,),
            file=sys.stderr,
        )  # timer

        # Rev. 7/1/2016
        # Rev. 7/3/2016 : fill NaN in Upstream column to replace to N/A's
        # Rev. 7/3/2016:  renamed Upstream column to PUTATIVE_UPSTREAM_DOMAINS
        # Rev. 12/2/2021: Converted to Python from ipynb; use fast Aho-Corasick searching; \
        #                read from SwissProt SQLite database
        # Rev. 12/9/2021: Transfer code to Galaxy tool wrapper

        #
        # copied from Excel Output Script.ipynb END #
        #

    try:
        catch(
            mqpep_getswissprot,
        )
        exit(0)
    except Exception as e:
        exit("Internal error running mqpep_getswissprot(): %s" % (e))


if __name__ == "__main__":
    __main__()
