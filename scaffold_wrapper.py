#!/usr/bin/env python
import optparse
import os
import shutil
import sys
import tempfile
import subprocess
import logging
from string import Template
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


# Extra database attributes: name, databaseAccessionRegEx, databaseDescriptionRegEx, decoyProteinRegEx
# Extra export types: protxml, spectrum-report, statistics, peptide-report, protein-report, experiment-report
RUN_TEMPLATE = """<Scaffold>
<Experiment name="Galaxy Scaffold Experiment">
<FastaDatabase id="database"
               path="$database_path"
               name="$database_name"
               databaseAccessionRegEx="$database_accession_regex"
               databaseDescriptionRegEx="$database_description_regex"
               decoyProteinRegEx="$database_decoy_regex"
               />
$samples
$display_thresholds
<Export type="sf3" path="$output_path" thresholds="thresh" />
</Experiment>
</Scaffold>
"""

EXPORT_TEMPLATE = """<Scaffold>
<Experiment load="$sf3_path">
$display_thresholds
<Export $export_options path="$output_path" thresholds="thresh" />
</Experiment>
</Scaffold>
"""

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


def build_samples(samples_file):
    group_data = parse_groups(samples_file, group_parts=["sample", "mudpit", "category"], input_parts=["name", "path", "ext"])
    samples_description = ""
    for sample_name, sample_data in group_data.iteritems():
        files = sample_data["inputs"]
        mudpit = sample_data["group_data"]["mudpit"]
        category = sample_data["group_data"]["category"]
        samples_description += """<BiologicalSample database="database" name="%s" mudpit="%s" category="%s">\n""" % (sample_name, mudpit, category)
        for (name, path, ext) in files:
            name = os.path.basename(name)
            if not name.lower().endswith(ext.lower()):
                name = "%s.%s" % (name, ext)
            symlink(path, name)
            samples_description += "<InputFile>%s</InputFile>\n" % os.path.abspath(name)
        samples_description += """</BiologicalSample>\n"""
    return samples_description


def run_script():
    action = sys.argv[1]
    if action == "run":
        proc = scaffold_run
    elif action == "export":
        proc = scaffold_export
    proc()


def scaffold_export():
    parser = optparse.OptionParser()
    parser.add_option("--sf3")
    parser.add_option("--output")
    parser.add_option("--export_type")
    populate_threshold_options(parser)
    (options, args) = parser.parse_args()

    template_parameters = {}

    template_parameters["sf3_path"] = options.sf3
    template_parameters["export_options"] = """ type="%s" """ % options.export_type
    template_parameters["display_thresholds"] = build_display_thresholds(options)

    execute_scaffold(options, EXPORT_TEMPLATE, template_parameters)


def build_display_thresholds(options):
    attributes = ['id="thresh"']
    if options.protein_probability is not None:
        attributes.append('proteinProbability="%s"' % options.protein_probability)
    if options.peptide_probability is not None:
        attributes.append('peptideProbability="%s"' % options.peptide_probability)
    if options.minimum_peptide_count is not None:
        attributes.append('minimumPeptideCount="%s"' % options.minimum_peptide_count)
    if options.minimum_peptide_length is not None:
        attributes.append('minimumPeptideLength="%s"' % options.minimum_peptide_length)
    if options.minimum_ntt is not None:
        attributes.append('minimumNTT="%s"' % options.minimum_ntt)
    attributes.append('useCharge="%s"' % build_use_charge_option(options))
    tag_open = "<DisplayThresholds " + " ".join(attributes) + ">"
    tag_body = "".join([f(options) for f in [tandem_opts, omssa_opts]])
    tag_close = "</DisplayThresholds>"
    return tag_open + tag_body + tag_close


def tandem_opts(options):
    element = ""
    tandem_score = options.tandem_score
    if tandem_score:
        element = '<TandemThresholds logExpectScores="%s,%s,%s,%s" />' % ((tandem_score,) * 4)
    return element


def omssa_opts(options):
    return ""


def build_use_charge_option(options):
    use_charge_array = []
    for i in ["1", "2", "3", "4"]:
        use_charge_i = getattr(options, "use_charge_%s" % i, True)
        use_charge_array.append("true" if use_charge_i else "false")
    return ",".join(use_charge_array)


def populate_threshold_options(option_parser):
    option_parser.add_option("--protein_probability", default=None)
    option_parser.add_option("--peptide_probability", default=None)
    option_parser.add_option("--minimum_peptide_count", default=None)
    option_parser.add_option("--ignore_charge_1", action="store_false", dest="use_charge_1", default=True)
    option_parser.add_option("--ignore_charge_2", action="store_false", dest="use_charge_2", default=True)
    option_parser.add_option("--ignore_charge_3", action="store_false", dest="use_charge_3", default=True)
    option_parser.add_option("--ignore_charge_4", action="store_false", dest="use_charge_4", default=True)
    option_parser.add_option("--minimum_peptide_length", default=None)
    option_parser.add_option("--minimum_ntt", default=None)
    option_parser.add_option("--tandem_score", default=None)
    option_parser.add_option("--omssa_peptide_probability", default=None)
    option_parser.add_option("--omssa_log_expect_score", default=None)


def database_rules(database_type):
    rules_dict = {
      "ESTNR": (">(gi\\|[0-9]*)", ">[^ ]* (.*)"),
      "IPI": (">IPI:([^\\| .]*)", ">[^ ]* Tax_Id=[0-9]* (.*)"),
      "SWISSPROT": (">([^ ]*)", ">[^ ]* \\([^ ]*\\) (.*)"),
      "UNIPROT": (">[^ ]*\\|([^ ]*)", ">[^ ]*\\|[^ ]* (.*)"),
      "UNIREF": (">UniRef100_([^ ]*)", ">[^ ]* (.*)"),
      "ENSEMBL": (">(ENS[^ ]*)", ">[^ ]* (.*)"),
      "MSDB": (">([^ ]*)", ">[^ ]* (.*)"),
      "GENERIC": (">([^ ]*)", ">[^ ]* (.*)"),
    }
    database_type = database_type if database_type in rules_dict else "GENERIC"
    return rules_dict[database_type]


def scaffold_run():
    parser = optparse.OptionParser()
    parser.add_option("--samples")
    parser.add_option("--database")
    parser.add_option("--database_name")
    parser.add_option("--database_type")
    parser.add_option("--database_decoy_regex")
    parser.add_option("--output")
    parser.add_option("--output_driver")
    populate_threshold_options(parser)
    (options, args) = parser.parse_args()

    template_parameters = {}

    # Read samples from config file and convert to XML
    template_parameters["samples"] = build_samples(options.samples)
    template_parameters["display_thresholds"] = build_display_thresholds(options)

    # Setup database parameters
    database_path = options.database
    database_name = options.database_name
    database_type = options.database_type
    database_decoy_regex = options.database_decoy_regex

    (accession_regex, description_regex) = database_rules(database_type)

    template_parameters["database_path"] = database_path
    template_parameters["database_name"] = database_name
    template_parameters["database_accession_regex"] = escape(accession_regex)
    template_parameters["database_description_regex"] = escape(description_regex)
    template_parameters["database_decoy_regex"] = escape(database_decoy_regex)

    execute_scaffold(options, RUN_TEMPLATE, template_parameters)

    if options.output_driver:
        shutil.copy("driver.xml", options.output_driver)


def execute_scaffold(options, template, template_parameters):
    # Setup output parameter
    output_path = options.output
    template_parameters["output_path"] = output_path

    # Prepare and create driver file
    driver_contents = Template(template).substitute(template_parameters)
    print driver_contents
    driver_path = os.path.abspath("driver.xml")
    open(driver_path, "w").write(driver_contents)

    # Run Scaffold
    execute("ScaffoldBatch3 '%s'" % driver_path)

if __name__ == '__main__':
    __main__()
