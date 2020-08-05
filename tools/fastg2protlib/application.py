import argparse
import os
import sys

import fastg2protlib.fastg2protlib as fg

expasy_rules = [
    "arg-c",
    "asp-n",
    "bnps-skatole",
    "caspase 1",
    "caspase 2",
    "caspase 3",
    "caspase 4",
    "caspase 5",
    "caspase 6",
    "caspase 7",
    "caspase 8",
    "caspase 9",
    "caspase 10",
    "chymotrypsin high specificity",
    "chymotrypsin low specificity",
    "clostripain",
    "cnbr",
    "enterokinase",
    "factor xa",
    "formic acid",
    "glutamyl endopeptidase",
    "granzyme b",
    "hydroxylamine",
    "iodosobenzoic acid",
    "lysc",
    "ntcb",
    "pepsin ph1.3",
    "pepsin ph2.0",
    "proline endopeptidase",
    "proteinase k",
    "staphylococcal peptidase i",
    "thermolysin",
    "thrombin",
    "trypsin",
    "trypsin_exception",
]


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run peptides for fastg")
    parser.add_argument("fastg", help="Path to Spades formatted FASTG.")
    parser.add_argument(
        "-d",
        "--dbname",
        default="results.db",
        help="Name for the results database. Defaults to results.db",
    )
    parser.add_argument(
        "-c",
        "--cleavage",
        default="trypsin",
        help="Cleavage rule from ExPASy cleavage rules. Defaults to trypsin.",
    )
    parser.add_argument(
        "-p",
        "--min_protein_length",
        default=55,
        type=int,
        help="Minimum protein length in number of amino acids. Defaults to 55.",
    )
    parser.add_argument(
        "-m",
        "--min_peptide_length",
        default=8,
        type=int,
        help="Minimum peptide length in amino acids. Defaults to eight.",
    )
    parser.add_argument(
        "-l", "--plots", default=True, type=bool, help="Generate diagnostic plots.",
    )

    args = parser.parse_args()

    print(args)

    fg.peptides_for_fastg(
        fastg_filename=args.fastg,
        db_name=args.dbname,
        cleavage=args.cleavage,
        min_protein_length=(args.min_protein_length * 3),
        min_peptide_length=args.min_peptide_length,
        create_plots=args.plots,
    )
