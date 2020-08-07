import argparse

import fastg2protlib.fastg2protlib as fg


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run peptides for fastg")
    parser.add_argument("msgf", help="Path MSGF+ tabular results.")
    parser.add_argument(
        "-d",
        "--dbname",
        default="results.db",
        help="Name for the results database. Defaults to results.db",
    )
    parser.add_argument(
        "-f",
        "--fdr",
        default=0.10,
        type=float,
        help="FDR cutoff for accepting PSM validation.",
    )
    parser.add_argument(
        "-x",
        "--decoy_header",
        default="XXX_",
        help="String used for marking decoy proteins.",
    )

    args = parser.parse_args()
    fg.verified_proteins(
        args.msgf, fdr_level=0.10, decoy_header="XXX_", db_name=args.dbname
    )
