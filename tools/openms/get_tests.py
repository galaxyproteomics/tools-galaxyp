#!/usr/bin/env python

import argparse
import json
import os
import os.path
import re
import shlex
import sys
import tempfile
from typing import (
    Dict,
    List,
    Optional,
    Set,
    TextIO,
    Tuple,
)

from ctdconverter.common.utils import (
    ParameterHardcoder,
    parse_hardcoded_parameters,
    parse_input_ctds,
)
from ctdconverter.galaxy.converter import convert_models
from CTDopts.CTDopts import (
    CTDModel,
    ModelTypeError,
    Parameters,
)

SKIP_LIST = [
    r"_prepare\"",
    r"_convert",
    r"WRITEINI",
    r"WRITECTD",
    r"INVALIDVALUE",
    r"\.flat\.json",
    r"\.ini\.json",
    r"TOPP_FileConverter_29_back",  # -out FileConverter_29.back.tmp.mzML: no DIFF compares it, so there is no fixture to compare the wrapper output with
    r"OpenSwathMzMLFileCacher .*-convert_back",  # - OpenSwathMzMLFileCacher with -convert_back argument https://github.com/OpenMS/OpenMS/issues/4399
    r"MaRaClusterAdapter.*-consensus_out",  # - MaRaCluster with -consensus_out (parameter blacklister: https://github.com/OpenMS/OpenMS/issues/4456)
    r"FileMerger_1_input1.dta2d.*FileMerger_1_input2.dta ",  # - FileMerger with mixed dta dta2d input (ftype can not be specified in the test, dta can not be sniffed)
    r'^(TOPP_OpenSwathAnalyzer_test_3|TOPP_OpenSwathAnalyzer_test_4)$',  # no  suppert for cached mzML
    r'TOPP_SiriusAdapter_[0-9]+$',  # Do not test SiriusAdapter https://github.com/OpenMS/OpenMS/issues/7000 .. will be removed anyway
    r'TOPP_AssayGeneratorMetabo_(7|8|9|10|11|12|13|14|15|16|17|18)$'  # Skip AssayGeneratorMetabo tests using Sirius  https://github.com/OpenMS/OpenMS/issues/7150 (will be replaced by two tools)
]


def get_failing_tests(cmake: List[str]) -> List[str]:
    failing_tests = []
    re_fail = re.compile(r"set_tests_properties\(\"([^\"]+)\" PROPERTIES WILL_FAIL 1\)")

    for path in cmake:
        with open(path) as cmake_fh:
            for line in cmake_fh:
                match = re_fail.search(line)
                if match:
                    failing_tests.append(match.group(1))
    return failing_tests


def get_message_tests(cmake: List[str]) -> List[str]:
    """Tests which only assert a message, i.e. expect the tool to refuse to run.

    Upstream writes e.g.

        add_test("TOPP_EICExtractor_1" ${TOPP_BIN_PATH}/EICExtractor -rt_collect -1)
        set_tests_properties("TOPP_EICExtractor_1" PROPERTIES PASS_REGULAR_EXPRESSION "rt_collect")

    There is no input file and no output to compare, so there is nothing Galaxy
    could check; the non-zero exit code is the point of the test.
    """
    message_tests = []
    re_msg = re.compile(r"set_tests_properties\(\"([^\"]+)\" PROPERTIES [^)]*PASS_REGULAR_EXPRESSION")
    for path in cmake:
        with open(path) as cmake_fh:
            for line in cmake_fh:
                match = re_msg.search(line)
                if match:
                    message_tests.append(match.group(1))
    return message_tests


def fix_tmp_files(line: str, diff_pairs: Dict[str, str]) -> str:
    """
    OpenMS tests output to tmp files and compare with FuzzyDiff to the expected file.
    problem: the extension of the tmp files is unusable for test generation.
    unfortunately the extensions used in the DIFF lines are not always usable for the CLI
    (e.g. for prepare_test_data, e.g. CLI expects csv but test file is txt)
    this function replaces the tmp file by the expected file.
    """
    cmd = shlex.split(line)
    for i, e in enumerate(cmd):
        if e in diff_pairs:
            dst = os.path.join("test-data", diff_pairs[e])
            if os.path.exists(dst):
                os.unlink(dst)
            sys.stderr.write(f"symlink {e} {dst}\n")
            try:
                os.symlink(e, dst)
            except FileExistsError:
                # a re-run over a test-data/ which test-data.sh did not clean
                pass
            cmd[i] = diff_pairs[e]
    return shlex.join(cmd)


def pin_mz_name(line: str) -> str:
    """Make a `-mz_file` test independent of the name Galaxy gives the copy.

    ID converters look up the run in a pepXML by the *file name* of the spectra
    file ("Found no experiment with name 'PepXMLFile_test_mzML.mzML'. It has to
    match the end of a run's 'base_name' ... (IDFileConverter: 'mz_name')"),
    and Galaxy stages the upload as <dataset name>.<ext>, i.e.
    `<tool>_<element_identifier>.mzML`.  Pin `-mz_name` to the stem of the
    fixture the way upstream names the file.
    """
    cmd = shlex.split(line)
    if "-mz_file" not in cmd or "-mz_name" in cmd:
        return line
    mz_file = cmd[cmd.index("-mz_file") + 1]
    cmd += ["-mz_name", os.path.basename(mz_file).rsplit(".", 1)[0]]
    return shlex.join(cmd)


def chained_inputs(line: str) -> List[str]:
    """Intermediates ("*.tmp.*") which are passed as inputs."""
    tokens = line.split()
    return [
        val
        for opt, val in zip(tokens, tokens[1:])
        if opt.startswith("-in") and ".tmp." in val
    ]


# test-data.sh records the fixtures it copied from the OpenMS source tree before
# prepare_test_data.sh adds the intermediates of the tests themselves.  A test
# which consumes an intermediate (FLU_parquet_in1.featureparquet is written by
# the FileConverter prep tests, MSGFPlusAdapter_1_out.mzid by the MSGF+ test)
# cannot be expressed in Galaxy: it would upload a directory or a file which
# does not exist.  Without the list (get_tests.py run by hand) fall back to
# checking that the file exists at all.
_UPSTREAM_LIST = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".upstream-fixtures.txt")


def _upstream_fixtures() -> Optional[Set[str]]:
    try:
        with open(_UPSTREAM_LIST) as handle:
            return {line.strip() for line in handle if line.strip()}
    except FileNotFoundError:
        return None


UPSTREAM_FIXTURES = _upstream_fixtures()


def is_fixture(token: str) -> bool:
    if UPSTREAM_FIXTURES is not None:
        return token in UPSTREAM_FIXTURES or os.path.basename(token) in UPSTREAM_FIXTURES
    path = os.path.join("test-data", token)
    return os.path.isfile(path)


def missing_inputs(line: str) -> List[str]:
    """Input files which are not available in test-data/.

    Those are either intermediates of a previous test of the same tool or
    fixtures which are not part of the source tree (e.g. generated at build
    time).  Galaxy cannot produce them, so tests using them are skipped.
    """
    tokens = shlex.split(line)
    missing = []
    for i, tok in enumerate(tokens):
        # a file name: an alphabetic extension, and not a number like "0.05"
        # (the value of an unrelated option, which looks deceptively similar)
        looks_like_file = re.search(r"\.[A-Za-z][A-Za-z0-9]{1,9}$", tok) is not None
        is_input_value = i > 0 and re.fullmatch(r"-in[0-9]*", tokens[i - 1]) is not None
        if tok.startswith("-") or not (looks_like_file or is_input_value):
            continue
        if i > 0 and tokens[i - 1].startswith("-out"):
            continue
        if not is_fixture(tok):
            missing.append(tok)
    return missing


# OpenMS 3.6 moved the parquet format into the (blacklisted) Parquet* tools and
# the remaining readers cannot open the files the 3.6 tests ship, so tests
# feeding them can only fail (FeatureLinkerUnlabeled: "ZIP archive contains 5
# file entries; expected exactly 1").
UNREADABLE_SUFFIXES = (".parquet", ".featureparquet", ".idparquet", ".consensusparquet")


HARDCODER = parse_hardcoded_parameters(
    os.path.join(os.path.dirname(os.path.abspath(__file__)), "aux", "hardcoded_params.json")
)


def only_blacklisted_outputs(line: str, tool_id: str) -> List[str]:
    """Outputs of a test which are all blacklisted, i.e. the test is pointless.

    MapAlignerIdentification_6 only writes -trafo_out, and -trafo_out is
    blacklisted for the MapAligners (see aux/hardcoded_params.json), so the
    generated test has no output at all and the tool stops with "Data output or
    transformation output files have to be provided".
    """
    outputs = re.findall(r"-(\w*out\w*)\b", line)
    if outputs and all(HARDCODER.get_blacklist(o, tool_id) for o in outputs):
        return outputs
    return []


PARQUET_FORMATS = tuple(s.lstrip(".") for s in UNREADABLE_SUFFIXES)


def unsupported_inputs(line: str) -> List[str]:
    """Files in the parquet family, on either side of the command line.

    3.6 moved the parquet readers into the (blacklisted) Parquet* tools, so a
    test reading `X.featureparquet` fails with "ZIP archive contains 5 file
    entries; expected exactly 1", and `FileConverter -out X.tmp.featureparquet`
    fails earlier still: the format is gone from the tool's `-out`, so the
    wrapper does not even offer `out_type=featureparquet`.
    """
    tokens = shlex.split(line)
    unsupported = []
    for i, tok in enumerate(tokens):
        if tok.endswith(UNREADABLE_SUFFIXES) or tok in PARQUET_FORMATS:
            unsupported.append(tok)
        elif i > 0 and tokens[i - 1] == "-out_type" and tok in PARQUET_FORMATS:
            unsupported.append(tok)
    return unsupported


def get_ini(line: str, tool_id: str) -> Tuple[str, str]:
    """
    if there is an ini file then we use this to generate the test
    otherwise the ctd file is used
    other command line parameters are inserted later into this xml
    """
    cmd = shlex.split(line)
    ini = None
    for i, e in enumerate(cmd):
        if e == "-ini":
            ini = cmd[i + 1]
            cmd = cmd[:i] + cmd[i + 2:]
    if ini:
        return os.path.join("test-data", ini), shlex.join(cmd)
    else:
        return os.path.join("ctd", f"{tool_id}.ctd"), line


def unique_files(line: str):
    """
    some tests use the same file twice which does not work in planemo tests
    hence we create symlinks for each file used twice
    """
    cmd = shlex.split(line)
    # print(f"{cmd}")
    files = {}
    # determine the list of indexes where each file argument (anything appearing in test-data/) appears
    for idx, e in enumerate(cmd):
        p = os.path.join("test-data", e)
        if not os.path.exists(p) and not os.path.islink(p):
            continue
        try:
            files[e].append(idx)
        except KeyError:
            files[e] = [idx]
    # print(f"{files=}")
    for f in files:
        if len(files[f]) < 2:
            continue
        for i, idx in enumerate(files[f]):
            f_parts = f.split(".")
            f_parts[0] = f"{f_parts[0]}_{i}"
            new_f = ".".join(f_parts)
            # if os.path.exists(os.path.join("test-data", new_f)):
            #     os.unlink(os.path.join("test-data", new_f))
            sys.stderr.write(
                f'\tsymlink {os.path.join("test-data", new_f)} {f}\n'
            )
            try:
                os.symlink(f, os.path.join("test-data", new_f))
            except FileExistsError:
                pass
            cmd[idx] = new_f
    return shlex.join(cmd)


def fill_ctd_clargs(ini: str, line: str, ctd_tmp: TextIO) -> None:
    cmd = shlex.split(line)

    # load CTDModel
    ini_model = None
    try:
        ini_model = CTDModel(from_file=ini)
    except ModelTypeError:
        pass
    try:
        ini_model = Parameters(from_file=ini)
    except ModelTypeError:
        pass
    assert ini_model is not None, "Could not parse %s, seems to be no CTD/PARAMS" % (
        args.ini_file
    )

    # get a dictionary of the ctd arguments where the values of the parameters
    # given on the command line are overwritten
    ini_values = ini_model.parse_cl_args(cl_args=cmd, ignore_required=True)
    ini_model.write_ctd(ctd_tmp, ini_values)


def process_test_line(
    id: str,
    line: str,
    failing_tests: List[str],
    skip_list: List[str],
    diff_pairs: Dict[str, str],
    version: str
) -> Optional[str]:

    re_test_id = re.compile(r"add_test\(\"([^\"]+)\" ([^ ]+) (.*)")
    re_id_out_test = re.compile(r"_out_?[0-9]?")

    # TODO auto extract from  set(OLD_OSW_PARAM ... lin
    line = line.replace(
        "${OLD_OSW_PARAM}",
        " -test -mz_extraction_window 0.05 -mz_extraction_window_unit Th -ms1_isotopes 0 -Scoring:TransitionGroupPicker:compute_peak_quality -Scoring:Scores:use_ms1_mi false -Scoring:Scores:use_mi_score false",
    )

    line = line.replace("${TOPP_BIN_PATH}/", "")
    line = line.replace("${DATA_DIR_TOPP}/", "")
    # since 3.6 the tests write their intermediate output to ${TESTS_TEMP_DIR}
    # (src/tests/topp/CMakeLists.txt: set(TESTS_TEMP_DIR "${PROJECT_BINARY_DIR}/tmp_path"))
    # and FuzzyDiff compares it to the reference in ${DATA_DIR_TOPP}. Strip the
    # prefix like the other path variables: diff_pairs is keyed by basename, so
    # without this fix_tmp_files() cannot map X.tmp.ext to the reference X.ext
    line = line.replace("${TESTS_TEMP_DIR}/", "")
    line = line.replace("THIRDPARTY/", "")
    line = line.replace("${DATA_DIR_SHARE}/", "")
    line = line.replace("${DATA_DIR_CLASS_TESTS}/", "")
    # a few tests name the build directory directly instead of ${TESTS_TEMP_DIR}
    line = re.sub(r"(?<![\w/])tmp_path/", "", line)
    # IDRipper PATH gets empty causing problems. TODO But overall the option needs to be handled differently
    line = line.replace("${TMP_RIP_PATH}/", "")
    # some input files are originally in a subdir (degenerated cases/), but not in test-data
    line = line.replace("degenerate_cases/", "")
    # determine the test and tool ids and remove the 1) add_test("TESTID" 2) trailing )
    match = re_test_id.match(line)
    if not match:
        sys.exit(f"Ill formated test line {line}\n")
    test_id = match.group(1)
    tool_id = match.group(2)

    line = f"{match.group(2)} {match.group(3)}"

    if test_id in failing_tests:
        # WILL_FAIL or PASS_REGULAR_EXPRESSION: the test asserts that the tool
        # refuses the input, there is no output Galaxy could compare
        sys.stderr.write(f"    skip failing {test_id} {line}\n")
        return

    if id != tool_id:
        sys.stderr.write(f"    skip {test_id} ({id} != {tool_id}) {line}\n")
        return

    if re_id_out_test.search(test_id):
        sys.stderr.write(f"    skip {test_id} {line}\n")
        return

    for skip in skip_list:
        if re.search(skip, line):
            return
        if re.search(skip, test_id):
            return
    # CMake loops (e.g. `foreach(format mzML mzXML)` around
    # add_test("TOPP_ConsensusID_no_ids_${format}" ...)) are expanded at
    # configure time; this plain parser only sees the template, so the
    # reference file ConsensusID_no_ids_input_0.${format} does not exist.
    unresolved = sorted(set(re.findall(r"\$\{[A-Za-z_][A-Za-z0-9_]*\}", line)))
    if unresolved:
        sys.stderr.write(
            f"    skip {test_id} (unresolved variable(s): {', '.join(unresolved)})\n"
        )
        return
    line = fix_tmp_files(line, diff_pairs)  # may create the reference symlinks
    # Remaining .tmp. files on the *input* side are intermediates produced by
    # another test of the same tool (upstream chains them with
    # set_tests_properties(... DEPENDS ...), see e.g. TOPP_IDMerger_idparquet_convert
    # which consumes the output of TOPP_IDMerger_idparquet). Galaxy tests cannot
    # express such a dependency and the intermediate is never uploaded, so skip
    # these tests instead of emitting tests which can only fail.
    chained = chained_inputs(line)
    if chained:
        sys.stderr.write(
            f"    skip chained {test_id} (input is the output of another test: {', '.join(sorted(chained))})\n"
        )
        return
    blacklisted_outputs = only_blacklisted_outputs(line, tool_id)
    if blacklisted_outputs:
        sys.stderr.write(
            f"    skip {test_id} (only blacklisted outputs: {', '.join(sorted(set(blacklisted_outputs)))})\n"
        )
        return
    line = pin_mz_name(line)
    unsupported = unsupported_inputs(line)
    if unsupported:
        sys.stderr.write(
            f"    skip {test_id} (format not readable in 3.6: {', '.join(sorted(set(unsupported)))})\n"
        )
        return
    missing = missing_inputs(line)
    if missing:
        sys.stderr.write(
            f"    skip {test_id} (input not in test-data: {', '.join(sorted(set(missing)))})\n"
        )
        return
    # print(f"fix {line=}")
    line = unique_files(line)
    # print(f"unq {line=}")
    ini, line = get_ini(line, tool_id)

    from dataclasses import dataclass, field

    @dataclass
    class CTDConverterArgs:
        input_files: list
        output_destination: str
        default_executable_path: Optional[str] = None
        hardcoded_parameters: Optional[str] = None
        parameter_hardcoder: Optional[ParameterHardcoder] = None
        xsd_location: Optional[str] = None
        formats_file: Optional[str] = None
        add_to_command_line: str = ""
        required_tools_file: Optional[str] = None
        skip_tools_file: Optional[str] = None
        macros_files: Optional[List[str]] = field(default_factory=list)
        test_macros_files: Optional[List[str]] = field(default_factory=list)
        test_macros_prefix: Optional[List[str]] = field(default_factory=list)
        test_test: bool = False
        test_only: bool = False
        test_unsniffable: Optional[List[str]] = field(default_factory=list)
        test_condition: Optional[List[str]] = ("compare=sim_size", "delta_frac=0.05")
        tool_version: str = None
        tool_profile: str = None
        bump_file: str = None

    # create an ini/ctd file where the values are equal to the arguments from the command line
    # and transform it to xml
    test = [f"<!-- {test_id} -->\n"]
    with tempfile.NamedTemporaryFile(
        mode="w+", delete_on_close=False
    ) as ctd_tmp, tempfile.NamedTemporaryFile(
        mode="w+", delete_on_close=False
    ) as xml_tmp:
        fill_ctd_clargs(ini, line, ctd_tmp)
        ctd_tmp.close()
        xml_tmp.close()
        parsed_ctd = parse_input_ctds(None, [ctd_tmp.name], xml_tmp.name, "xml")
        ctd_args = CTDConverterArgs(
            input_files=[ctd_tmp.name],
            output_destination=xml_tmp.name,
            macros_files=["macros.xml"],
            skip_tools_file="aux/tools_blacklist.txt",
            formats_file="aux/filetypes.txt",
            # tool_conf_destination = "tool.conf",
            hardcoded_parameters="aux/hardcoded_params.json",
            tool_version=version,
            test_only=True,
            test_unsniffable=[
                "csv",
                "tsv",
                "txt",
                "dta",
                "dta2d",
                "edta",
                "psms",
                "msp",
                "mrm",
                "splib",
            ],
            test_condition=["compare=sim_size", "delta_frac=0.7"],
        )
        ctd_args.parameter_hardcoder = parse_hardcoded_parameters(
            ctd_args.hardcoded_parameters
        )
        convert_models(ctd_args, parsed_ctd)
        xml_tmp = open(xml_tmp.name, "r")
        for l in xml_tmp:
            test.append(l)

    return "".join(test)


parser = argparse.ArgumentParser(description="Create Galaxy tests for a OpenMS tools")
parser.add_argument("--id", dest="id", help="tool id")
parser.add_argument("--cmake", nargs="+", help="OpenMS test CMake files")
parser.add_argument("--version", dest="version", help="OpenMS Version")
args = parser.parse_args()
sys.stderr.write(f"generate tests for {args.id}\n")

re_comment = re.compile("#.*")
re_empty_prefix = re.compile(r"^\s*")
re_empty_suffix = re.compile(r"\s*$")
re_add_test = re.compile(r"add_test\(\"(TOPP|UTILS)_.*/" + args.id)
re_diff = re.compile(r"\$\{DIFF\}.* -in1 ([^ ]+) -in2 ([^ ]+)")
failing_tests = get_failing_tests(args.cmake) + get_message_tests(args.cmake)
tests = []

# process the given CMake files and compile lists of
# - test lines .. essentially add_test(...)
# - and pairs of files that are diffed
jline = ""
test_lines = []
diff_pairs = {}
for cmake in args.cmake:
    with open(cmake) as cmake_fh:
        for line in cmake_fh:
            # remove comments, empty prefixes and suffixes
            line = re_comment.sub("", line)
            line = re_empty_prefix.sub("", line)
            line = re_empty_suffix.sub("", line)
            # skip empty lines
            if line == "":
                continue

            # join test statements that are split over multiple lines.  3.6
            # reformatted many of them as
            #   add_test("TOPP_ProSE_1" ${TOPP_BIN_PATH}/ProSE -test
            #   -ini ${DATA_DIR_TOPP}/ProSE_1.ini -in
            #   ${DATA_DIR_TOPP}/SimpleSearchEngine_1.mzML -out_idxml ...
            #   )
            # (the closing parenthesis on a line of its own), so keep
            # accumulating until a line closes the statement instead of
            # resetting the buffer with every continuation line.
            jline = f"{jline} {line}".strip()
            if line != ")" and not line.endswith(")"):
                continue
            # drop the closing parenthesis of the add_test(...) call
            line = jline[:-1].strip() if jline.endswith(")") else jline.strip()
            jline = ""
            match = re_diff.search(line)
            if match:
                in1 = match.group(1).split("/")[-1]
                in2 = match.group(2).split("/")[-1]
                if in1 != in2:
                    diff_pairs[in1] = in2
            elif re_add_test.match(line):
                test_lines.append(line)

for line in test_lines:
    test = process_test_line(args.id, line, failing_tests, SKIP_LIST, diff_pairs, args.version)
    if test:
        tests.append(test)

tests = "\n".join(tests)
print(
    f"""
<xml name="autotest_{args.id}">
{tests}
</xml>
"""
)
