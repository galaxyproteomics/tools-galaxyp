#!/usr/bin/env python

import argparse
import os.path
import re
import shlex
import sys
import tempfile
from typing import (
    Dict,
    List,
    Optional,
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
    r"\.ini\.json",
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

    for cmake in args.cmake:
        with open(cmake) as cmake_fh:
            for line in cmake_fh:
                match = re_fail.search(line)
                if match:
                    failing_tests.append(match.group(1))
    return failing_tests


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
            os.symlink(e, dst)
            cmd[i] = diff_pairs[e]
    return shlex.join(cmd)


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
    line = line.replace("THIRDPARTY/", "")
    line = line.replace("${DATA_DIR_SHARE}/", "")
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

    line = fix_tmp_files(line, diff_pairs)
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
            tool_version="3.1",
            test_only=True,
            test_unsniffable=[
                "csv",
                "tsv",
                "txt",
                "dta",
                "dta2d",
                "edta",
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
args = parser.parse_args()
sys.stderr.write(f"generate tests for {args.id}\n")

re_comment = re.compile("#.*")
re_empty_prefix = re.compile(r"^\s*")
re_empty_suffix = re.compile(r"\s*$")
re_add_test = re.compile(r"add_test\(\"(TOPP|UTILS)_.*/" + args.id)
re_diff = re.compile(r"\$\{DIFF\}.* -in1 ([^ ]+) -in2 ([^ ]+)")
failing_tests = get_failing_tests(args.cmake)
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

            # join test statements that are split over multiple lines
            if line.endswith(")"):
                jline += " " + line[:-1]
            else:
                jline = line
                continue
            line, jline = jline.strip(), ""
            match = re_diff.search(line)
            if match:
                in1 = match.group(1).split("/")[-1]
                in2 = match.group(2).split("/")[-1]
                if in1 != in2:
                    diff_pairs[in1] = in2
            elif re_add_test.match(line):
                test_lines.append(line)

for line in test_lines:
    test = process_test_line(args.id, line, failing_tests, SKIP_LIST, diff_pairs)
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
