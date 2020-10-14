import argparse

import psmfragmentation.psmfragmentation as pf


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run PSM Validator")
    parser.add_argument(
        "-d",
        "--dbname",
        help="Path to mzsqlite db",
    )
    parser.add_argument(
        "-p",
        "--peptides",
        help="Path to peptide sequence file",
    )
    parser.add_argument(
        "-n",
        "--neutral",
        action="store_true",
        default=False,
        help="Calculate netutral loss",
    )
    parser.add_argument(
        "-i",
        "--internal",
        action="store_true",
        default=False,
        help="Calculate internals",
    )
    parser.add_argument(
        "-e", "--epsilon", type=float
    )
    parser.add_argument(
        "-b",
        "--b_run",
        type=int,
        default=2,
        help="Number of consecutive b-ions"
    )
    parser.add_argument(
        "-y",
        "--y_run",
        type=int,
        default=2,
        help="Number of consecutive y-ions"
        )

    parser.add_argument(
        "-t",
        "--test",
        action="store_true",
        default=False
    )

    args = parser.parse_args()

    itypes = ['b', 'y']
    if args.neutral:
        itypes.extend(['b-H2O', 'b-NH3', 'y-H2O', 'y-NH3'])

    if args.internal:
        itypes.append('M')

    pf.score_psms(args.dbname, args.peptides, ion_types=itypes, epsilon=args.epsilon, maxcharge=1, b_run=args.b_run, y_run=args.y_run, a_test=args.test)
