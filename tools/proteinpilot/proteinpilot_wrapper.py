#!/usr/bin/env python
import optparse
import os
import sys
import tempfile
import subprocess
import time
import shutil
import logging
from xml.sax.saxutils import escape

log = logging.getLogger(__name__)

DEBUG = True

working_directory = os.getcwd()
tmp_stderr_name = tempfile.NamedTemporaryFile(dir=working_directory, suffix='.stderr').name
tmp_stdout_name = tempfile.NamedTemporaryFile(dir=working_directory, suffix='.stdout').name


def stop_err(msg):
    sys.stderr.write("%s\n" % msg)
    sys.exit()


def read_stderr():
    stderr = ''
    if(os.path.exists(tmp_stderr_name)):
        with open(tmp_stderr_name, 'rb') as tmp_stderr:
            buffsize = 1048576
            try:
                while True:
                    stderr += tmp_stderr.read(buffsize)
                    if not stderr or len(stderr) % buffsize != 0:
                        break
            except OverflowError:
                pass
    return stderr


def execute(command, stdin=None):
    try:
        with open(tmp_stderr_name, 'wb') as tmp_stderr:
            with open(tmp_stdout_name, 'wb') as tmp_stdout:
                proc = subprocess.Popen(args=command, shell=True, stderr=tmp_stderr.fileno(), stdout=tmp_stdout.fileno(), stdin=stdin, env=os.environ)
                returncode = proc.wait()
                if returncode != 0:
                    raise Exception("Program returned with non-zero exit code %d. stderr: %s" % (returncode, read_stderr()))
    finally:
        print open(tmp_stderr_name, "r").read(64000)
        print open(tmp_stdout_name, "r").read(64000)


def delete_file(path):
    if os.path.exists(path):
        try:
            os.remove(path)
        except:
            pass

def delete_directory(directory):
    if os.path.exists(directory):
        try:
            shutil.rmtree(directory)
        except:
            pass

def symlink(source, link_name):
    import platform
    if platform.system() == 'Windows':
        try:
            import win32file
            win32file.CreateSymbolicLink(source, link_name, 1)
        except:
            shutil.copy(source, link_name)
    else:
        os.symlink(source, link_name)


def copy_to_working_directory(data_file, relative_path):
    if os.path.abspath(data_file) != os.path.abspath(relative_path):
        shutil.copy(data_file, relative_path)
    return relative_path

def __main__():
    run_script()

#ENDTEMPLATE

from string import Template

METHOD_TEMPLATE = """<UISETTINGS>
<UI_SAMPLE_TYPE>$sample_type</UI_SAMPLE_TYPE>
<UI_QUANT_TYPE>$quant_type</UI_QUANT_TYPE>
<UI_BACKGROUND_CORRECTION>$background_correction</UI_BACKGROUND_CORRECTION>
<UI_BIAS_CORRECTION>$bias_correction</UI_BIAS_CORRECTION>
<UI_CYS_ALKYLATION>$cys_alkylation</UI_CYS_ALKYLATION>
<UI_DIGESTION>$digestion</UI_DIGESTION>
<UI_SPECIAL_FACTOR>$special_factors</UI_SPECIAL_FACTOR>
<UI_INSTRUMENT>$instrument</UI_INSTRUMENT>
<UI_SPECIES></UI_SPECIES>
<UI_USER_NAME></UI_USER_NAME>
<UI_MACHINE_NAME></UI_MACHINE_NAME>
<UI_START_TIME></UI_START_TIME>
<UI_SEARCH_ID></UI_SEARCH_ID>
<UI_ID_FOCUS>$search_foci</UI_ID_FOCUS>
<UI_SEARCH_EFFORT>$search_effort</UI_SEARCH_EFFORT>
<UI_SEARCH_RESOURCE>$database_name</UI_SEARCH_RESOURCE>
<UI_MIN_UNUSED_PROTSCORE>$min_unused_protscore</UI_MIN_UNUSED_PROTSCORE>
<UI_PSPEP>$pspep</UI_PSPEP>
<UI_MAX_QUANT_LABELS>$max_quant_labels</UI_MAX_QUANT_LABELS>
$quant_labels
</UISETTINGS>
"""

quant_special_cases = {
    "iTRAQ 4plex (Peptide Labeled)": "iTRAQ4PLEX",
    "iTRAQ 4plex (Protein Labeled)": "iTRAQ4PLEX",
    "iTRAQ 8plex (Peptide Labeled)": "iTRAQ8PLEX",
    "iTRAQ 8plex (Protein Labeled)": "iTRAQ8PLEX",
    "mTRAQ (Peptide Labeled - M00, M04)": "mTRAQ_0-4",
    "mTRAQ (Peptide Labeled - M00, M08)": "mTRAQ_0-8",
    "mTRAQ (Peptide Labeled - M04, M08)": "mTRAQ_4-8",
    "mTRAQ (Peptide Labeled - M00, M04, M08)": "mTRAQ_0-4-8",
    "Proteolytic O-18 labeling": "Proteolytic O-18 v O-16",
    "Cleavable ICAT": "ICAT9",
    "ICPL Light, Heavy (Peptide Labeled)": "ICPL peptide",
    "ICPL Light, Heavy (Protein Labeled)": "ICPL protein",
}


def parse_groups(inputs_file, group_parts=["group"], input_parts=["name", "path"]):
    inputs_lines = [line.strip() for line in open(inputs_file, "r").readlines()]
    inputs_lines = [line for line in inputs_lines if line and not line.startswith("#")]
    cur_group = None
    i = 0
    group_prefixes = ["%s:" % group_part  for group_part in group_parts]
    input_prefixes = ["%s:" % input_part for input_part in input_parts]
    groups = {}
    while i < len(inputs_lines):
        line = inputs_lines[i]
        if line.startswith(group_prefixes[0]):
            # Start new group
            cur_group = line[len(group_prefixes[0]):]
            group_data = {}
            for j, group_prefix in enumerate(group_prefixes):
                group_line = inputs_lines[i + j]
                group_data[group_parts[j]] = group_line[len(group_prefix):]
            i += len(group_prefixes)
        elif line.startswith(input_prefixes[0]):
            input = []
            for j, input_prefix in enumerate(input_prefixes):
                part_line = inputs_lines[i + j]
                part = part_line[len(input_prefixes[j]):]
                input.append(part)
            if cur_group not in groups:
                groups[cur_group] = {"group_data": group_data, "inputs": []}
            groups[cur_group]["inputs"].append(input)
            i += len(input_prefixes)
        else:
            # Skip empty line
            i += 1
    return groups


def get_env_property(name, default):
    if name in os.environ:
        return os.environ[name]
    else:
        return default


def build_quant_label(reagent, quant_type="Not Used", treatment="", minus2="0", minus1="0", plus1="0", plus2="0"):
    return {
    "reagent": reagent,
    "type": quant_type,
    "treatment": treatment,
    "minus2": minus2,
    "minus1": minus1,
    "plus1": plus1,
    "plus2": plus2,
    }


def build_quant_labels(options, quant_type):
    if quant_type == "iTRAQ8PLEX":
        return [
            build_quant_label("iTRAQ113", plus1="6.89", plus2="0.24"),
            build_quant_label("iTRAQ114", minus1="0.94", plus1="5.9", plus2="0.16"),
            build_quant_label("iTRAQ115", minus1="1.88", plus1="4.9", plus2="0.1"),
            build_quant_label("iTRAQ116", minus1="2.82", plus1="3.9", plus2="0.07"),
            build_quant_label("iTRAQ117", minus2="0.06", minus1="3.77", plus1="2.88"),
            build_quant_label("iTRAQ118", minus2="0.09", minus1="4.71", plus1="1.91"),
            build_quant_label("iTRAQ119", minus2="0.14", minus1="5.66", plus1="0.87"),
            build_quant_label("iTRAQ121", minus2="0.27", minus1="7.44", plus1="0.18"),
        ]
    elif quant_type == "iTRAQ4PLEX":
        return [
            build_quant_label("iTRAQ114", minus1="1.00", plus1="5.9", plus2="0.20"),
            build_quant_label("iTRAQ115", minus1="2.00", plus1="5.6", plus2="0.1"),
            build_quant_label("iTRAQ116", minus1="3.00", plus1="4.5", plus2="0.1"),
            build_quant_label("iTRAQ117", minus2="0.10", minus1="4.00", plus1="3.50", plus2="0.1"),
        ]
    else:
        return []


def join_quant_labels(labels):
    template = '<QUANT_LABEL_SETTING reagent="$reagent" type="$type" treatment="$treatment" minus2="$minus2" minus1="$minus1" plus1="$plus1" plus2="$plus2"/>'
    return "\n".join([Template(template).substitute(quant_label) for quant_label in labels])


def handle_sample_type(options, parameter_dict):
    sample_type = options.sample_type
    if sample_type in quant_special_cases:
        quant_type = quant_special_cases[sample_type]
    else:
        quant_type = sample_type
    if options.quantitative.upper() != "TRUE":
        quant_type = ""
    parameter_dict["sample_type"] = sample_type
    parameter_dict["quant_type"] = quant_type
    parameter_dict["quant_labels"] = join_quant_labels(build_quant_labels(options, quant_type))


def setup_database(options):
    PROTEINPILOT_DATABASE_DIR = get_env_property("PROTEIN_PILOT_DATABASE_FOLDER", "C:\\AB SCIEX\\ProteinPilot Data\\SearchDatabases")
    database_path = options.database
    database_name = options.database_name
    database_name = database_name.replace(" ", "_")
    (database_basename, extension) = os.path.splitext(database_name)
    base = os.path.join(PROTEINPILOT_DATABASE_DIR, "gx_%s" % database_basename)
    database_destination = get_unique_path(base, ".fasta")
    symlink(database_path, database_destination)
    return (database_destination, os.path.basename(os.path.splitext(database_destination)[0]))


def extract_list(parameter):
    if parameter == None or parameter == "None":
        parameter = ""
    return parameter.replace(",", ";")


def setup_methods(options):
    ## Setup methods file
    (database_path, database_name) = setup_database(options)
    special_factors = extract_list(options.special_factors)
    search_foci = extract_list(options.search_foci)
    method_parameters = {
        "background_correction": options.background_correction,
        "bias_correction": options.bias_correction,
        "cys_alkylation": options.cys_alkylation,
        "digestion": options.digestion,
        "instrument": options.instrument,
        "search_effort": options.search_effort,
        "search_foci": search_foci,
        "pspep": options.pspep,
        "min_unused_protscore": options.min_unused_protscore,
        "max_quant_labels": "3",
        "database_name": database_name,
        "quantitative": options.quantitative,
        "special_factors": special_factors
    }
    handle_sample_type(options, method_parameters)
    method_contents = Template(METHOD_TEMPLATE).substitute(method_parameters)
    PROTEINPILOT_METHODS_DIR = get_env_property("PROTEIN_PILOT_METHODS_FOLDER", "C:\\ProgramData\\AB SCIEX\\ProteinPilot\\ParagonMethods\\")
    methods_name = "gx_%s" % os.path.split(os.getcwd())[-1]
    methods_path = os.path.join(PROTEINPILOT_METHODS_DIR, "%s.xml" % methods_name)
    open(methods_path, "w").write(method_contents)
    return (methods_name, methods_path, database_path)


def setup_inputs(inputs):
    links = []
    for input_data in inputs:
        input_name = input_data[0]
        input = input_data[1]
        if DEBUG:
            print "Processing input %s with name %s and size %d" % (input, input_name, os.stat(input).st_size)
        if not input_name.upper().endswith(".MGF"):
            input_name = "%s.mgf" % input_name
        link_path = os.path.abspath(input_name)
        symlink(input, link_path)
        links.append(link_path)
    return ",".join(["<DATA type=\"MGF\" filename=\"%s\" />" % escape(link) for link in links])


def get_unique_path(base, extension):
    """
    """
    return "%s_%d%s" % (base, int(time.time() * 1000), extension)


def move_pspep_output(options, destination, suffix):
    if destination:
        source = "%s__FalsePositiveAnalysis__%s.csv" % (options.output, suffix)
        shutil.move(source, destination)


def run_script():
    parser = optparse.OptionParser()
    parser.add_option("--input_config")
    parser.add_option("--database")
    parser.add_option("--database_name")
    parser.add_option("--instrument")
    parser.add_option("--sample_type")  # TODO: Restrict values
    parser.add_option("--bias_correction", default="False")
    parser.add_option("--background_correction", default="False")
    parser.add_option("--cys_alkylation", default="None")
    parser.add_option("--digestion", default="Trypsin")
    parser.add_option("--special_factors", default="")
    parser.add_option("--search_foci", default="")
    parser.add_option("--search_effort", default="Rapid")
    parser.add_option("--min_unused_protscore", default="3")
    parser.add_option("--quantitative", default="False")
    parser.add_option("--pspep", default="TRUE")
    parser.add_option("--output")
    parser.add_option("--output_methods")
    #parser.add_option("--output_pspep_peptide", default="")
    #parser.add_option("--output_pspep_protein", default="")
    #parser.add_option("--output_pspep_spectra", default="")
    parser.add_option("--output_pspep_report", default="")
    (options, args) = parser.parse_args()

    (methods_name, methods_path, database_path) = setup_methods(options)
    try:
        group_file = "%s.group" % options.output
        input_contents_template = """<PROTEINPILOTPARAMETERS>
    <METHOD name="$methods_name" />
    $inputs
    <RESULT filename="$output" />
</PROTEINPILOTPARAMETERS>"""
        input_config = options.input_config
        group_data = parse_groups(input_config)
        group_values = group_data.values()
        # Not using groups right now.
        assert len(group_values) == 1, len(group_values)
        inputs = group_data.values()[0]["inputs"]
        input_parameters = {
            "inputs": setup_inputs(inputs),
            "output": group_file,
            "methods_name": methods_name
        }

        input_contents = Template(input_contents_template).substitute(input_parameters)
        open("input.xml", "w").write(input_contents)

        protein_pilot_path = get_env_property("PROTEIN_PILOT_PATH", "")
        if protein_pilot_path and not protein_pilot_path.endswith("\\"):
            protein_pilot_path = "%s" % protein_pilot_path
        execute("%sProteinPilot.exe input.xml" % protein_pilot_path)
        shutil.move(group_file, options.output)
        #move_pspep_output(options, options.output_pspep_spectra, "SpectralLevelData")
        #move_pspep_output(options, options.output_pspep_peptide, "DistinctPeptideLevelData")
        #move_pspep_output(options, options.output_pspep_protein, "ProteinLevelData")
        if options.output_pspep_report:
            source = "%s__FDR.xlsx" % (options.output)
            shutil.move(source, options.output_pspep_report)
        shutil.move(methods_path, options.output_methods)
    finally:
        delete_file(database_path)
        delete_file(methods_path)

if __name__ == '__main__':
    __main__()
