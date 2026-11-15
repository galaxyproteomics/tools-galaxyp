#!/usr/bin/env python

import argparse
import json
import os
import os.path
import re
import shlex
import sys
import tempfile
import xml.etree.ElementTree as ET
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
    r"^TOPP_DatabaseSuitability_[0-9]+$",  # calls Comet through ExternalProcess::run() (PATH lookup, comet.exe default); upstream guards these behind find_program(COMET_BINARY)
    r"OpenSwathMzMLFileCacher .*-convert_back",  # - OpenSwathMzMLFileCacher with -convert_back argument https://github.com/OpenMS/OpenMS/issues/4399
    r"MaRaClusterAdapter.*-consensus_out",  # - MaRaCluster with -consensus_out (parameter blacklister: https://github.com/OpenMS/OpenMS/issues/4456)
    r"FileMerger_1_input1.dta2d.*FileMerger_1_input2.dta ",  # - FileMerger with mixed dta dta2d input (ftype can not be specified in the test, dta can not be sniffed)
    r'^(TOPP_OpenSwathAnalyzer_test_3|TOPP_OpenSwathAnalyzer_test_4)$',  # no  suppert for cached mzML
    r'TOPP_SiriusAdapter_[0-9]+$',  # Do not test SiriusAdapter https://github.com/OpenMS/OpenMS/issues/7000 .. will be removed anyway
    r'TOPP_AssayGeneratorMetabo_(7|8|9|10|11|12|13|14|15|16|17|18)$',  # Skip AssayGeneratorMetabo tests using Sirius  https://github.com/OpenMS/OpenMS/issues/7150 (will be replaced by two tools)
    # OpenMS' own FileDiff compares XML attributes as *numbers* when both sides
    # look numeric, Galaxy's compare="diff" is a plain text diff: 3.6 writes
    # significance_threshold="0.0" where the reference fixture (and 3.2) has
    # "0", which OpenMS accepts and Galaxy can not express.  IDRipper_1 and
    # IDRipper_3 cover the same code path.
    r'^TOPP_IDRipper_2(_out[0-9]+|a|a_out[0-9]+)?$',
    # UniPEFF needs its input staged as *.xml and writes *.peff, but Galaxy has
    # no datatype for either name: macros.xml gxy2omsext() maps the Galaxy *xml*
    # dataset to *.bioml (what the BioML readers need) and the Galaxy *peff*
    # dataset to *.fasta (what the other tools need), so the tool gets
    # 'in/UniPEFF_1_input_xml.bioml' ("Could not determine format of input
    # file") and is asked to write 'out/output.fasta' ("Invalid output file
    # extension").  Which extension a *.xml/*.peff dataset needs is a property
    # of the *tool*, and filetypes.txt is a global first-wins map, so this
    # needs a per-tool extension override in the generator (see the ledger).
    r'^TOPP_UniPEFF_',
    # -exp_design names its spectra files by *file name* (the wrapper stages a
    # data set as '<sanitized element identifier>.<openms extension>' in a
    # directory of its own), so OpenMS reports
    #   Spectra file does not exist: 'TMTTenPlexMethod_test.mzML' in:
    #   exp_design/IsobaricWorkflow_1_design_tsv.tsv
    # The design file would have to be rewritten per test to point at the staged
    # name, which Galaxy cannot do.  Applies to IsobaricWorkflow (_1,
    # strictly_unique) and Epifany.
    r"-exp_design",
    # the percolator shipped in openms-thirdparty=3.6.0 aborts inside the
    # external binary ("Setting an empty value for primary MS runs paths",
    # exit 9) on the in-process tests as well, so there is nothing Galaxy or the
    # wrapper can assert on
    r'^TOPP_PercolatorAdapter_1_inproc',
    # AssayGeneratorMetaboSirius reads a *directory* (a SIRIUS project:
    # formula_identifications.tsv, canopus_formula_summary.tsv, report.mztab and
    # one subdirectory per compound).  Its CTD calls the parameter input-file,
    # which is why the wrapper offers a single data set, but passing one file
    # makes the tool answer "SIRIUS project directory is empty." (verified with
    # 3.6.0), and Galaxy can only stage single files.  The fixture is not in the
    # test-data repository either - it lives in the OpenMS source tree - so the
    # three tests cannot be expressed (see D12 in the ledger).
    r'^TOPP_AssayGeneratorMetaboSirius_',
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


def disabled_tests(cmake: List[str]) -> List[str]:
    """Tests inside `if (WITH_FOO)`, where `option(WITH_FOO ... OFF)`.

    Upstream switches whole test families off by default and expects them to be
    enabled by hand, e.g.

        option(WITH_MASCOT_TEST "Runs the Mascot Online test (do not turn this
        on unless you know what you are doing)" OFF)
        if (WITH_MASCOT_TEST)
          add_test("TOPP_MascotAdapterOnline_1" ...)

    Those tests need a server or a licensed vendor library, so a generated
    Galaxy test can only fail.  The option default is taken from the same CMake
    file (no hardcoded option names), and `else()` branches are honoured.
    """
    re_option = re.compile(r"option\(\s*(\w+)\s+\"[^\"]*\"\s+(ON|OFF)\s*\)")
    re_if = re.compile(r"^\s*if\s*\(([^)]*)\)")
    re_else = re.compile(r"^\s*else\s*\(")
    re_endif = re.compile(r"^\s*endif\s*\(")
    re_add_test = re.compile(r"add_test\(\"([^\"]+)\"")
    disabled = []
    for path in cmake:
        with open(path) as cmake_fh:
            lines = cmake_fh.readlines()
        off = {
            match.group(1)
            for line in lines
            if (match := re_option.search(line)) and match.group(2) == "OFF"
        }
        if not off:
            continue
        # one frame per open if(): is the region disabled, and is the branch
        # enabled (flipped by `else`)
        stack: List[bool] = []
        own_stack: List[bool] = []
        for line in lines:
            match_if = re_if.match(line)
            if match_if:
                parent = stack[-1] if stack else False
                own = match_if.group(1).strip() in off
                stack.append(parent or own)
                own_stack.append(own)
                continue
            if re_else.match(line):
                if own_stack:
                    # the else branch of `if (WITH_FOO)` is enabled
                    own_stack[-1] = not own_stack[-1]
                    stack[-1] = (
                        stack[-2] if len(stack) > 1 else False
                    ) or own_stack[-1]
                continue
            if re_endif.match(line):
                if stack:
                    stack.pop()
                    own_stack.pop()
                continue
            if stack and stack[-1]:
                match_test = re_add_test.search(line)
                if match_test:
                    disabled.append(match_test.group(1))
    return disabled


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
        # never rewrite an input: X.tmp.ext as an input means "chained test",
        # not "compare with the reference"
        if i > 0 and cmd[i - 1].startswith("-in"):
            continue
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


def map_output_references(xml: str, diff_pairs: Dict[str, str]) -> str:
    """Point an <output value=...> at the reference file it is compared with.

    Tests which pass an -ini file get their parameters (and therefore their
    output file names) from that ini, which fix_tmp_files() never sees: the ini
    of a migrated fixture still names the build intermediate
    ("tmp_path/TextExporter_2_consensus_tsv.tmp.tsv") whose reference is
    "TextExporter_2_consensus_tsv.tsv".  Apply the same mapping here.
    """

    def replace(match):
        value = match.group(2)
        reference = diff_pairs.get(os.path.basename(value))
        if not reference:
            return match.group(0)
        return f"{match.group(1)}{reference}\""

    return re.sub(r'(<output [^>]*value=")([^"]*)"', replace, xml)


# Outputs which may only be checked for existence and format, as
# "<tool>": {"<output>"}.  Upstream compares these with FuzzyDiff, which parses
# numbers with a relative tolerance; Galaxy compares by size (or byte equality),
# so a formatting change alone makes the test fail although the content agrees.
PUBLISH_ONLY_OUTPUTS = {
    # OpenMS 3.6 writes doubles with full precision and in scientific notation
    #   "826.031"                -> "826.030999999999949"
    #   "928753024"              -> "9.28753e08"
    # which grows these 2011 era references by ~75%.
    "TextExporter": {"consensus_centroids", "consensus_elements", "consensus_features"},
}


def strip_uncomparable_outputs(
    xml: str, uncomparable: Set[str], tool_id: str = ""
) -> str:
    """Turn an output into a presence/format check checks only.

    Some outputs are compared upstream with a whitelist that removes the whole
    payload: `${ZLIB_NG_MZML_WHITELIST}` ("encodedLength", "<binary>", "<offset")
    exists because zlib-ng produces byte different but functionally equivalent
    compressed mzML, and FuzzyDiff then compares the surrounding structure
    only.  Galaxy can compare such a file by size, content or nothing; neither
    size nor content is a function of what the tool computed, so assert only
    that the output exists and is valid mzML.
    """
    def replace(match):
        tag = match.group(0)
        reference = re.search(r'value="([^"]*)"', tag)
        if not reference:
            return tag
        name = re.search(r'name="([^"]*)"', tag).group(1)
        if (os.path.basename(reference.group(1)) not in uncomparable
                and name not in PUBLISH_ONLY_OUTPUTS.get(tool_id, ())):
            return tag
        ftype = re.search(r'ftype="([^"]*)"', tag)
        ftype = f' ftype="{ftype.group(1)}"' if ftype else ""
        return f'<output name="{name}"{ftype}/>'

    return re.sub(r'<output [^>]*?/>', replace, xml)


def fix_empty_collection_count(xml: str) -> str:
    """Replace a `count` that CTDConverter could not fill in.

    When the members of an output collection are compared upstream through a
    templated file name (MzMLSplitter writes `<prefix>_part<N>of<M>.mzML` and
    the DIFF steps name them one by one), CTDConverter cannot map the references
    and emits `<output_collection name="out" count=""/>`, which is not a valid
    Galaxy test (`count` must be an integer).  Without the attribute the test
    can express neither: Galaxy's test parser rejects an empty `count`, while its
    linter rejects a collection without `count`/`min`/`max`/`element`.  `min="1"`
    says exactly what is known - the collection was produced and is not empty.
    """
    return re.sub(r'(<output_collection\b[^>]*?)\s+count=""', r'\1 min="1"', xml)


def fix_expect_num_outputs(xml: str) -> str:
    """Make `expect_num_outputs` agree with the outputs the test declares.

    CTDConverter counts the outputs it could resolve, so a collection whose
    members are unknown (see fix_empty_collection_count) leaves the number one
    too low and Galaxy fails the job with

        Incorrect number of outputs - expected 1, found 2
        (dataset(s): ctd_out collection(s): out)

    The number is only ever *raised*: every `<output>` and `<output_collection>`
    the test declares is produced (that is what makes it a failure the first
    time), while the opposite - a test that declares fewer outputs than the tool
    writes, e.g. `TOPP_FileInfo_12`, which compares only the CTD dump and leaves
    `-out` unchecked - is a legitimate assertion and must be left alone.
    """
    match = re.search(r'<test[^>]*\sexpect_num_outputs="([0-9]+)"[^>]*>', xml)
    if not match:
        return xml
    declared = len(re.findall(r'<output(?:_collection)?\s', xml[match.end():]))
    if declared <= int(match.group(1)):
        return xml
    tag = match.group(0).replace(match.group(1), str(declared))
    return xml[:match.start()] + tag + xml[match.end():]


def check_multi_inputs(xml: str, multi: Dict[str, List[str]]) -> bool:
    """Check that a multi file parameter carries all of its files in the test.

    A CTD ITEMLIST becomes a multiple data parameter and CTDConverter writes its
    files as one comma separated `value`, which Galaxy splits.  When the wrapper
    deliberately declares the parameter as single valued - `OpenSwathWorkflow:in`
    is forced by `aux/hardcoded_params.json` (`CTD:is_list: false`), because the
    workflow takes one run per invocation - the generated test can only carry
    the first file and the tool would silently process half of its input.
    Returns False in that case, so that the caller skips the test.
    """
    for name, files in multi.items():
        pattern = re.compile(r'<param\s+name="%s"[^>]*?/>' % re.escape(name))
        match = pattern.search(xml)
        if not match:
            return False
        value = re.search(r'value="([^"]*)"', match.group(0))
        if not value:
            return False
        emitted = [os.path.basename(v) for v in value.group(1).split(",")]
        if sorted(emitted) != sorted(files):
            return False
    return True


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


FILE_CTD_TYPES = {"input-file", "input-dir", "output-file", "output-dir",
                  "output-prefix"}


def ctd_arguments(path: str) -> Dict[str, str]:
    """Map the command line argument of every CTD <ITEM> to its CTD type."""
    arguments = {}

    def walk(node, prefix: List[str]):
        # ITEMLIST declares a list-valued parameter (e.g. OpenSwathWorkflow -in
        # "Input files separated by blank") whose CTD type is still input-file
        for item in node.findall("ITEM") + node.findall("ITEMLIST"):
            name = item.get("name")
            if name:
                arguments["-" + ":".join(prefix + [name])] = item.get("type")
        for child in node.findall("NODE"):
            name = child.get("name")
            if not name or name.isdigit():
                # the tool itself and the unnamed parameter groups
                walk(child, prefix)
            else:
                walk(child, prefix + [name])

    parameters = ET.parse(path).getroot().find("PARAMETERS")
    if parameters is None:
        return arguments
    for tool in parameters.findall("NODE"):
        # the first NODE is the tool itself: its name is not part of an argument
        walk(tool, [])
    return arguments


def text_params_with_files(line: str, tool_id: str) -> List[str]:
    """Fixture files handed to a parameter which is not a file parameter.

    A CTD parameter of type string is passed to the tool as given, so the
    generated test would hand OpenMS a bare file name which Galaxy never
    stages ("Error: File not found (the file 'X.trafoXML' could not be
    found)").  OpenMS declares such parameters upstream, e.g.
    -Calibration:files:linear_irt_file is a string holding a space separated
    list of iRT files.  Either the CTD is patched (aux/ctd_patches.json, as
    done for -Calibration:rt_norm) or the test is skipped here.
    """
    ctd = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "ctd", f"{tool_id}.ctd")
    if not os.path.exists(ctd):
        return []
    types = ctd_arguments(ctd)

    cmd = shlex.split(line)
    bad: List[str] = []
    for i, argument in enumerate(cmd):
        if i == 0 or not argument.startswith("-") or i + 1 >= len(cmd):
            continue
        if argument not in types or types[argument] in FILE_CTD_TYPES:
            continue
        # the value may be one file or a quoted, space separated list of files
        values = [v for v in shlex.split(cmd[i + 1]) if not v.startswith("-")]
        if any(is_fixture(v) for v in values):
            bad.append(f"{argument} ({types[argument]})")
    return bad


def multi_value_arguments(line: str, tool_id: str) -> Dict[str, List[str]]:
    """File parameters which receive more than one file on the command line.

    An ITEMLIST (or a plain space separated list, as in
    TOPP_OpenSwathWorkflow_25 which passes two chromatograms to -in) becomes a
    single data parameter in the wrapper, and CTDConverter puts only the first
    file into the test, so the tool silently processed half of the input.  The
    files are returned as {parameter: [file, ...]}, so that the caller can emit
    <param name="in" values="a,b"/> instead (Galaxy splits `values` on commas).
    """
    ctd = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "ctd", f"{tool_id}.ctd")
    if not os.path.exists(ctd):
        return []
    types = ctd_arguments(ctd)

    cmd = shlex.split(line)
    bad: Dict[str, List[str]] = {}
    for i, argument in enumerate(cmd):
        if i == 0 or not argument.startswith("-"):
            continue
        # only inputs: an ITEMLIST of output files becomes an output
        # collection, not a data parameter
        if types.get(argument) != "input-file":
            continue
        values = []
        for token in cmd[i + 1:]:
            if token.startswith("-"):
                break
            values.extend(shlex.split(token))
        files = [v for v in values if is_fixture(v)]
        if len(files) > 1:
            bad[argument.lstrip("-")] = files
    return bad


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
        # one option can carry a whitespace-separated file list in a single
        # (quoted) token, e.g.
        #   -Calibration:files:linear_irt_file "a.irt.TraML a.irt.TraML ..."
        # (TOPP_OpenSwathWorkflow_27 passes the same file six times)
        for part in tok.split():
            # a file name: an alphabetic extension, and not a number like "0.05"
            # (the value of an unrelated option, which looks deceptively similar)
            looks_like_file = re.search(r"\.[A-Za-z][A-Za-z0-9]{1,9}$", part) is not None
            is_input_value = i > 0 and re.fullmatch(r"-in[0-9]*", tokens[i - 1]) is not None
            if part.startswith("-") or not (looks_like_file or is_input_value):
                continue
            if i > 0 and tokens[i - 1].startswith("-out"):
                continue
            if not is_fixture(part):
                missing.append(part)
    return missing


# OpenMS 3.6 moved the parquet format into the (blacklisted) Parquet* tools and
# the remaining readers cannot open the files the 3.6 tests ship, so tests
# feeding them can only fail (FeatureLinkerUnlabeled: "ZIP archive contains 5
# file entries; expected exactly 1").
# the parquet family: 3.6 moved the readers into the blacklisted Parquet* tools
# (.oswpq is the OpenSWATH parquet flavour, see TOPP_OpenSwathAssayGenerator_parquet)
UNREADABLE_SUFFIXES = (".parquet", ".featureparquet", ".idparquet",
                       ".consensusparquet", ".oswpq")


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
    version: str,
    uncomparable: Optional[Set[str]] = None
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

    if test_id in DISABLED:
        sys.stderr.write(f"    skip disabled {test_id} (with_* option is OFF)\n")
        return

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
    # .tmp. files on the *input* side are intermediates produced by another test
    # of the same tool (upstream chains them with set_tests_properties(... DEPENDS
    # ...), see e.g. TOPP_IDMerger_idparquet_convert which consumes the output of
    # TOPP_IDMerger_idparquet).  Galaxy tests cannot express such a dependency and
    # the intermediate is never uploaded, so skip these tests instead of emitting
    # tests which can only fail.  Detect them *before* fix_tmp_files(), which maps
    # every known intermediate onto the reference name it is compared with - that
    # mapping is meant for outputs only (TOPP_FileFilter_43_read_again then looked
    # like a test reading FileFilter_43_output.mzML while writing an uncompared
    # FileFilter_43.dummy.tmp.mzML, which no fixture backs).
    chained = chained_inputs(line)
    if chained:
        sys.stderr.write(
            f"    skip chained {test_id} (input is the output of another test: {', '.join(sorted(chained))})\n"
        )
        return
    # map each intermediate output onto the reference file it is compared with
    # (and symlink it into test-data/): the temp extension is a build artefact,
    # the reference name is what the wrapper has to declare as its output
    line = fix_tmp_files(line, diff_pairs)
    blacklisted_outputs = only_blacklisted_outputs(line, tool_id)
    if blacklisted_outputs:
        sys.stderr.write(
            f"    skip {test_id} (only blacklisted outputs: {', '.join(sorted(set(blacklisted_outputs)))})\n"
        )
        return
    line = pin_mz_name(line)
    text_files = text_params_with_files(line, tool_id)
    if text_files:
        sys.stderr.write(
            f"    skip {test_id} (fixture handed to a non-file parameter: {', '.join(text_files)})\n"
        )
        return
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
    # needs the renamed files of unique_files(): the same fixture used twice in
    # one command line becomes <name>_0.<ext> / <name>_1.<ext>
    multi = multi_value_arguments(line, tool_id)
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
        try:
            fill_ctd_clargs(ini, line, ctd_tmp)
        except SystemExit:
            # e.g. TOPP_IDRipper_1 ... -out tmp_path/ : stripping the build
            # directory leaves an option without a value and the CTD's own
            # parser aborts the *whole* run, which silently dropped every test
            # of that tool.  Galaxy cannot express an output directory anyway
            # (the tool writes a set of files whose names it chooses), so skip
            # the test instead of dying.
            sys.stderr.write(
                f"    skip unparseable {test_id} (an option lost its value when "
                f"the build paths were stripped) {line}\n"
            )
            return
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
        with open(xml_tmp.name, "r") as xml_fh:
            body = map_output_references(xml_fh.read(), diff_pairs)
        body = strip_uncomparable_outputs(body, uncomparable or set(), tool_id)
        body = fix_empty_collection_count(body)
        body = fix_expect_num_outputs(body)
        if multi and not check_multi_inputs(body, multi):
            sys.stderr.write(
                f"    skip {test_id} (more than one file for a single input "
                f"parameter: {', '.join(multi)})\n"
            )
            return
        if "tmp_path/" in body:
            sys.stderr.write(
                f"    skip {test_id} (output is a build temporary: "
                f"{', '.join(re.findall(r'value=\"([^\"]*tmp_path/[^\"]*)\"', body))})\n"
            )
            return
        test.append(body)

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
DISABLED = disabled_tests(args.cmake)
failing_tests = get_failing_tests(args.cmake) + get_message_tests(args.cmake)
tests = []

# process the given CMake files and compile lists of
# - test lines .. essentially add_test(...)
# - and pairs of files that are diffed
jline = ""
test_lines = []
diff_pairs = {}
uncomparable = set()
re_payload_whitelist = re.compile(r"ZLIB_NG_MZML_WHITELIST|<binary>|<offset\b")
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
                if re_payload_whitelist.search(line):
                    uncomparable.add(in2)
            elif re_add_test.match(line):
                test_lines.append(line)

for line in test_lines:
    test = process_test_line(args.id, line, failing_tests, SKIP_LIST, diff_pairs,
                             args.version, uncomparable)
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
