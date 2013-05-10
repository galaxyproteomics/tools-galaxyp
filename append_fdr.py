#!/usr/bin/env python
import optparse
import sys

try:
    # Ubuntu deps: gfortan libblas-dev liblapack-dev
    # pip deps: numpy scipy
    from math import sqrt
    from scipy.optimize import root
    from numpy import arange, exp, concatenate, sum, log, array, seterr
except ImportError:
    # Allow this script to be used for global FDR even
    # if these dependencies are not present.
    pass


SEPARATORS = {"TAB": "\t",
              "SPACE": " ",
              "COMMA": ","
             }


def __main__():
    run_script()


def append_fdr(input_file, output, settings):
    sorted_scores, accum_hits, accum_decoys = _accum_decoys(input_file, settings)
    fdr_array = compute_fdr(sorted_scores, accum_hits, accum_decoys, settings)
    index = 0
    for line in __read_lines(input_file):
        if not line or line.startswith('#'):
            continue
        entry = Entry(line, settings, index)
        this_fdr = fdr_array[entry.score]
        new_line = "%s%s%f" % (line, settings["separator"], this_fdr)
        print >> output, new_line
        index += 1


def compute_fdr(sorted_scores, accum_hits, accum_decoys, settings):
    fdr_type = settings["fdr_type"]
    compute_functions = {"global_conservative": _compute_fdr_global_conservative,
                         "global_permissive": _compute_fdr_global_permissive,
                         #"pspep": _compute_pspep
                        }
    return compute_functions[fdr_type](sorted_scores, accum_hits, accum_decoys, settings)
    #return compute_functions[fdr_type](all_hits_array, decoy_hits_array, settings)


def _compute_pspep(all_hits, decoy_hits, settings):
    scaling = _get_scaling(settings)
    seterr(all="ignore")
    sigma = array([sqrt(x) if x > 0 else 0.2 for x in decoy_hits])
    if isinstance(all_hits, list):
        all_hits = array(all_hits)
    if isinstance(decoy_hits, list):
        decoy_hits = array(decoy_hits)
    searchSeg = concatenate((exp(arange(-8, 9, 2)), -1 * exp(arange(-8, 9, 2))))
    bestResids = sys.float_info.max
    bestResidsComb = [0.0, 0.0, 0.0]
    for aEst in searchSeg:
        for bEst in searchSeg:
            for cEst in searchSeg:
                try:
                    sol = _non_linear_fit(aEst, bEst, cEst, all_hits, decoy_hits, sigma)
                    if sol[3] and sol[3] < bestResids:
                        bestResids = sol[3]
                        bestResidsComb = sol[0:3]
                except:
                    pass
    (a, b, c) = bestResidsComb[0:3]
    fdr_local = scaling * (exp(b * (all_hits - a)) / (exp(b * (all_hits - a)) + 1)) * c
    return fdr_local


def _get_scaling(settings):
    scaling = float(settings.get("scaling", "2.0"))
    return scaling


def _non_linear_fit(aEst, bEst, cEst, all_hits, decoy_hits, sigma, scaling=2):
    guess = [aEst, bEst, cEst]

    def f(a, b, c):
        return c * (log(exp(b * (all_hits - a)) + 1) - log(exp(-b * a) + 1)) / b

    def fcn(p):
        a = p[0]
        b = p[1]
        c = p[2]
        return (decoy_hits - f(a, b, c)) / sigma

    solution = root(fcn, guess, method='lm')
    a = solution.x[0]
    b = solution.x[1]
    c = solution.x[2]
    resids = sum((decoy_hits - f(a, b, c)) ** 2) / len(all_hits)
    return (a, b, c, resids)


def _compute_fdr_global_conservative(sorted_scores, accum_hits, accum_decoys, settings):
    raw_fdrs = build_raw_fdr_dict(sorted_scores, accum_hits, accum_decoys, settings)
    fdrs = {}
    max_fdr = -1
    for score in sorted_scores:
        raw_fdr = raw_fdrs[score]
        if raw_fdr > max_fdr:
            max_fdr = raw_fdr
        fdrs[score] = max_fdr
    return fdrs


def _compute_fdr_global_permissive(sorted_scores, accum_hits, accum_decoys, settings):
    raw_fdrs = build_raw_fdr_dict(sorted_scores, accum_hits, accum_decoys, settings)
    fdrs = {}
    index = len(sorted_scores) - 1
    min_fdr = 1
    while index >= 0:
        score = sorted_scores[index]
        raw_fdr = raw_fdrs[score]
        if raw_fdr < min_fdr:
            min_fdr = raw_fdr
        fdrs[score] = min_fdr
        index -= 1
    return fdrs


def build_raw_fdr_dict(sorted_scores, accum_hits, accum_decoys, settings):
    scaling = _get_scaling(settings)
    fdrs = {}
    for score in sorted_scores:
        fdrs[score] = (scaling * accum_decoys[score]) / accum_hits[score]
    return fdrs


def __read_lines(input_file):
    with open(input_file, 'r') as input:
        for i, line in enumerate(input):
            line = line.rstrip('\r\n')
            yield line


def __read_entries(input_file, settings):
    total_hits = 0
    for line in __read_lines(input_file):
        if not line or line.startswith('#'):
            continue
        entry = Entry(line, settings, total_hits)
        total_hits = total_hits + 1
        yield entry


class Entry(object):

    def __init__(self, line, settings, index):
        self.settings = settings
        line_parts = line.split(settings["separator"])
        self.identifier = line_parts[settings["identifiers_index"]]
        if settings["score_column"]:
            self.score = float(line_parts[settings["score_column"]])
        else:
            self.score = index

    @property
    def is_decoy(self):
        return self.identifier.startswith(self.settings["decoy_prefix"])


def _accum_decoys(input_file, settings):
    hits_at_score = {}
    decoys_at_score = {}
    for entry in __read_entries(input_file, settings):
        score = entry.score
        score_total = hits_at_score.get(score, 0) + 1
        score_decoys = decoys_at_score.get(score, 0) + (1 if entry.is_decoy else 0)
        hits_at_score[score] = score_total
        decoys_at_score[score] = score_decoys
    sorted_scores = sorted(hits_at_score, reverse=not settings["invert_score"])
    accum_hits = {}
    accum_decoys = {}
    accum_hit_count = 0
    accum_decoy_count = 0
    for score in sorted_scores:
        accum_decoy_count += decoys_at_score[score]
        accum_hit_count += hits_at_score[score]
        accum_hits[score] = accum_hit_count
        accum_decoys[score] = accum_decoy_count
    return (sorted_scores, accum_hits, accum_decoys)


def _build_arrays(input_file, settings, sorted_scores, accum_hits, accum_decoys):
    all_hits = []
    decoy_hits = []
    for entry in __read_entries(input_file, settings):
        score = entry.score
        all_hits.append(accum_hits[score])
        decoy_hits.append(accum_decoys[score])

    return (all_hits, decoy_hits)


def run_script():
    parser = optparse.OptionParser()
    parser.add_option("--input")
    parser.add_option("--output")
    parser.add_option("--decoy_prefix")
    parser.add_option("--identifiers_column")
    parser.add_option("--separator", default="TAB")
    parser.add_option("--fdr_type", default="global_conservative")
    parser.add_option("--scaling")
    parser.add_option("--score_column", default=None)
    # By default higher score is better.
    parser.add_option("--invert_score", default=False, action="store_true")

    (options, args) = parser.parse_args()
    decoy_prefix = options.decoy_prefix
    identifiers_column = options.identifiers_column
    score_column = options.score_column
    separator = SEPARATORS[options.separator]
    settings = {"decoy_prefix": decoy_prefix,
                "identifiers_index": int(identifiers_column) - 1,
                "fdr_type": options.fdr_type,
                "separator": separator,
                "scaling": options.scaling,
                "invert_score": options.invert_score
               }
    if score_column:
        settings["score_column"] = int(score_column) - 1
    else:
        settings["score_column"] = None
        # Assume data is descending, use index as score and invert.
        settings["invert_score"] = True
    with open(options.output, 'w') as output:
        append_fdr(options.input, output, settings)


if __name__ == '__main__':
    __main__()
