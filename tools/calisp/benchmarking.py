import argparse
import os

import numpy as np
import pandas as pd

# Define the ArgumentParser
parser = argparse.ArgumentParser("List of natural abundances of the isotopes")

parser.add_argument(
    "--input", type=str, metavar="data", help="Input file/folder", required=True
)

parser.add_argument(
    "--isotope_abundance_matrix",
    type=str,
    metavar="data",
    help="Isotope abundance matrix",
    required=True,
)
parser.add_argument(
    "--isotope",
    type=str,
    metavar="ISOTOPE",
    help="Isotope",
    required=True,
)
parser.add_argument(
    "--out_summary",
    type=str,
    metavar="output",
    help="Peptide summary output",
    required=False,
)
parser.add_argument(
    "--out_filtered", type=str, metavar="output", help="Filtered output", required=False
)
parser.add_argument(
    "--nominal_values",
    type=str,
    metavar="nominal_values",
    help="Table giving nominal values",
    default=None,
    required=False,
)

# Indicate end of argument definitions and parse args
args = parser.parse_args()


def parse_nominal_values(filename):
    nominal_values = {}
    if not filename:
        return nominal_values
    with open(filename) as fh:
        for line in fh:
            line = line.strip()
            if len(line) == 0 or line[0] == "#":
                continue
            line = line.split()
            nominal_values[line[0]] = line[1]
    return nominal_values


# Benchmarking section
# the functions for optimising calis-p data


def load_calisp_data(filename, factor):
    # (1) load data
    file_count = 1
    if os.path.isdir(filename):
        file_data = []
        file_count = len(os.listdir(filename))
        for f in os.listdir(filename):
            f = os.path.join(filename, f)
            file_data.append(pd.read_feather(f))
            base, _ = os.path.splitext(f)
            file_data[-1].to_csv(f"{base}.tsv", sep="\t", index=False)
        data = pd.concat(file_data)
    else:
        data = pd.read_feather(filename)
        base, _ = os.path.splitext(filename)
        data.to_csv(f"{base}.tsv", sep="\t", index=False)

    file_success_count = len(data["ms_run"].unique())
    # (2) calculate deltas
    # ((1-f)/f) - 1 == 1/f -2
    data["delta_na"] = data["ratio_na"] / ((1 / factor) - 2) * 1000
    data["delta_fft"] = data["ratio_fft"] / ((1 / factor) - 2) * 1000
    print(
        f"Loaded {len(data.index)} isotopic patterns from {file_success_count}/{file_count} file(s)"
    )
    return data


def filter_calisp_data(data, target):
    if target.lower() == "na":
        subdata = data.loc[
            lambda df: (df["flag_peak_at_minus_one_pos"] == False)  # noqa: E712
            & (df["flag_pattern_is_wobbly"] == False)  # noqa: E712
            & (df["flag_psm_has_low_confidence"] == False)  # noqa: E712
            & (df["flag_psm_is_ambiguous"] == False)  # noqa: E712
            & (df["flag_pattern_is_contaminated"] == False)  # noqa: E712
            & (df["flag_peptide_assigned_to_multiple_bins"] == False),  # noqa: E712
            :,
        ]
    elif target.lower() == "fft":
        subdata = data.loc[
            lambda df: (df["error_fft"] < 0.001)
            & (df["flag_peptide_assigned_to_multiple_bins"] == False),  # noqa: E712
            :,
        ]
    elif target.lower() == "clumpy":
        subdata = data.loc[
            lambda df: (df["error_clumpy"] < 0.001)
            & (df["flag_peptide_assigned_to_multiple_bins"] == False),  # noqa: E712
            :,
        ]

    print(
        f"{len(subdata.index)} ({len(subdata.index)/len(data.index)*100:.1f}%) remaining after filters."
    )
    return subdata


def estimate_clumpiness(data):
    subdata = data.loc[lambda df: df["error_clumpy"] < 0.001, :]
    clumpiness = []
    for c in ["c1", "c2", "c3", "c4", "c5", "c6"]:
        try:
            count, division = np.histogram(subdata[c], bins=50)
            count = count[1:-1]
            opt = 0.02 * np.where(count == count.max())[0][0] / 0.96
            clumpiness.append(opt)
        except ValueError:
            pass
    return clumpiness / sum(clumpiness)


# the function for benchmarking
def benchmark_sip_mock_community_data(data, factor, nominal_values):
    background_isotope = 1 - factor
    background_unlabelled = factor

    # For false positive discovery rates we set the threshold at the isotope/unlabelled associated with 1/4 of a generation
    # of labeling. The E. coli values (1.7, 4.2 and 7.1) are for 1 generation at 1, 5 and 10% label,
    # and we take the background (1.07) into account as well.
    thresholds = {
        1: 1.07 + (1.7 - 1.07) / 4,
        5: 1.07 + (4.2 - 1.07) / 4,
        10: 1.07 + (7.1 - 1.07) / 4,
    }

    filenames = data["ms_run"].unique()
    for fname in filenames:
        print(f"Using nominal value {nominal_values.get(fname, 0)} for {fname}")

    bin_names = data["bins"].unique()
    peptide_sequences = data["peptide"].unique()
    benchmarking = pd.DataFrame(
        columns=[
            "file",
            "bins",
            "% label",
            "ratio",
            "peptide",
            "psm_mz",
            "n(patterns)",
            "mean intensity",
            "ratio_NA median",
            "N mean",
            "ratio_NA SEM",
            "ratio_FFT median",
            "ratio_FFT SEM",
            "False Positive",
        ]
    )
    false_positives = 0
    for p in peptide_sequences:
        pep_data = data.loc[lambda df: df["peptide"] == p, :]
        for b in bin_names:
            # bindata = data.loc[lambda df: df["bins"] == b, :]
            for f in filenames:
                nominal_value = nominal_values.get(fname, 0)
                unlabeled_fraction = 1 - nominal_value / 100
                U = unlabeled_fraction * background_unlabelled
                I = nominal_value / 100 + unlabeled_fraction * background_isotope
                ratio = I / U * 100
                pepfiledata = pep_data.loc[lambda df: df["ms_run"] == f, :]
                is_false_positive = 0
                try:
                    if (
                        b != "K12"
                        and pepfiledata["ratio_na"].median() > thresholds[nominal_value]
                    ):
                        is_false_positive = 1
                        false_positives += 1
                except KeyError:
                    pass
                benchmarking.loc[len(benchmarking)] = [
                    f,
                    b,
                    nominal_value,
                    ratio,
                    p,
                    pepfiledata["psm_mz"].median(),
                    len(pepfiledata.index),
                    pepfiledata["pattern_total_intensity"].mean(),
                    pepfiledata["ratio_na"].median(),
                    pepfiledata["psm_neutrons"].mean(),
                    pepfiledata["ratio_na"].sem(),
                    pepfiledata["ratio_fft"].median(),
                    pepfiledata["ratio_fft"].sem(),
                    is_false_positive,
                ]

    benchmarking = benchmarking.sort_values(["bins", "peptide"])
    benchmarking = benchmarking.reset_index(drop=True)
    return benchmarking


rowcol = {
    "13C": (0, 1),
    "14C": (0, 2),
    "15N": (1, 1),
    "17O": (2, 1),
    "18O": (2, 2),
    "2H": (3, 1),
    "3H": (3, 2),
    "33S": (4, 1),
    "34S": (4, 2),
    "36S": (4, 3),
}
with open(args.isotope_abundance_matrix) as iamf:
    matrix = []
    for line in iamf:
        line = line.strip()
        line = line.split("#")[0]
        if line == "":
            continue
        matrix.append([float(x) for x in line.split()])
factor = matrix[rowcol[args.isotope][0]][rowcol[args.isotope][1]]
print(f"Using factor {factor}")


# cleaning and filtering data
data = load_calisp_data(args.input, factor)

if args.out_filtered:
    data = filter_calisp_data(data, "na")
    data["peptide_clean"] = data["peptide"]
    data["peptide_clean"] = data["peptide_clean"].replace("'Oxidation'", "", regex=True)
    data["peptide_clean"] = data["peptide_clean"].replace(
        "'Carbamidomethyl'", "", regex=True
    )
    data["peptide_clean"] = data["peptide_clean"].replace(r"\s*\[.*\]", "", regex=True)

    data["ratio_na"] = data["ratio_na"] * 100
    data["ratio_fft"] = data["ratio_fft"] * 100
    data.to_csv(args.out_filtered, sep="\t", index=False)

    # The column "% label" indicates the amount of label applied (percentage of label in the glucose). The amount of
    # labeled E. coli cells added corresponded to 1 generation of labeling (50% of E. coli cells were labeled in
    # all experiments except controls)

if args.out_summary:
    nominal_values = parse_nominal_values(args.nominal_values)
    benchmarks = benchmark_sip_mock_community_data(data, factor, nominal_values)
    benchmarks.to_csv(args.out_summary, sep="\t", index=False)
