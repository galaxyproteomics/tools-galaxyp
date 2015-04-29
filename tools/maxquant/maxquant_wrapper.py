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
import xml.etree.ElementTree as ET

import re

log = logging.getLogger(__name__)

DEBUG = True

working_directory = os.getcwd()
tmp_stderr_name = tempfile.NamedTemporaryFile(dir=working_directory, suffix='.stderr').name
tmp_stdout_name = tempfile.NamedTemporaryFile(dir=working_directory, suffix='.stdout').name

class Data:
    def __init__(self, name, fraction, experiment):
        self.name = name
        self.fraction = fraction
        self.experiment = experiment



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


## Lock File Stuff
## http://www.evanfosmark.com/2009/01/cross-platform-file-locking-support-in-python/
import os
import time
import errno


class FileLockException(Exception):
    pass


class FileLock(object):
    """ A file locking mechanism that has context-manager support so
        you can use it in a with statement. This should be relatively cross
        compatible as it doesn't rely on msvcrt or fcntl for the locking.
    """

    def __init__(self, file_name, timeout=10, delay=.05):
        """ Prepare the file locker. Specify the file to lock and optionally
            the maximum timeout and the delay between each attempt to lock.
        """
        self.is_locked = False
        self.lockfile = os.path.join(os.getcwd(), "%s.lock" % file_name)
        self.file_name = file_name
        self.timeout = timeout
        self.delay = delay

    def acquire(self):
        """ Acquire the lock, if possible. If the lock is in use, it check again
            every `wait` seconds. It does this until it either gets the lock or
            exceeds `timeout` number of seconds, in which case it throws
            an exception.
        """
        start_time = time.time()
        while True:
            try:
                self.fd = os.open(self.lockfile, os.O_CREAT | os.O_EXCL | os.O_RDWR)
                break
            except OSError as e:
                if e.errno != errno.EEXIST:
                    raise
                if (time.time() - start_time) >= self.timeout:
                    raise FileLockException("Timeout occured.")
                time.sleep(self.delay)
        self.is_locked = True

    def release(self):
        """ Get rid of the lock by deleting the lockfile.
            When working in a `with` statement, this gets automatically
            called at the end.
        """
        if self.is_locked:
            os.close(self.fd)
            os.unlink(self.lockfile)
            self.is_locked = False
            
    def __enter__(self):
        """ Activated when used in the with statement.
            Should automatically acquire a lock to be used in the with block.
        """
        if not self.is_locked:
            self.acquire()
        return self

    def __exit__(self, type, value, traceback):
        """ Activated at the end of the with statement.
            It automatically releases the lock if it isn't locked.
        """
        if self.is_locked:
            self.release()

    def __del__(self):
        """ Make sure that the FileLock instance doesn't leave a lockfile
            lying around.
        """
        self.release()

TEMPLATE = """<?xml version="1.0" encoding="utf-8"?>
<MaxQuantParams xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" runOnCluster="false" processFolder="$process_folder">
  $raw_file_info
  <experimentalDesignFilename/>
  <slicePeaks>$slice_peaks</slicePeaks>
  <tempFolder/>
  <ncores>$num_cores</ncores>
  <ionCountIntensities>false</ionCountIntensities>
  <maxFeatureDetectionCores>1</maxFeatureDetectionCores>
  <verboseColumnHeaders>false</verboseColumnHeaders>
  <minTime>NaN</minTime>
  <maxTime>NaN</maxTime>
  <calcPeakProperties>$calc_peak_properties</calcPeakProperties>
  <useOriginalPrecursorMz>$use_original_precursor_mz</useOriginalPrecursorMz>
  $fixed_mods
  <multiModificationSearch>$multi_modification_search</multiModificationSearch>
  <fastaFiles>$database</fastaFiles>
  <fastaFilesFirstSearch/>
  <fixedSearchFolder/>
  <advancedRatios>$advanced_ratios</advancedRatios>
  <rtShift>$rt_shift</rtShift>
  <fastLfq>$fast_lfq</fastLfq>
  <randomize>$randomize</randomize>
  <specialAas>$special_aas</specialAas>
  <includeContamiants>$include_contamiants</includeContamiants>
  <equalIl>$equal_il</equalIl>
  <topxWindow>100</topxWindow>
  <maxPeptideMass>$max_peptide_mass</maxPeptideMass>
  <reporterPif>$reporter_pif</reporterPif>
  <reporterFraction>$reporter_fraction</reporterFraction>
  <reporterBasePeakRatio>$reporter_base_peak_ratio</reporterBasePeakRatio>
  <scoreThreshold>$score_threshold</scoreThreshold>
  <filterAacounts>$filter_aacounts</filterAacounts>
  <secondPeptide>$second_peptide</secondPeptide>
  <matchBetweenRuns>$match_between_runs</matchBetweenRuns>
  <matchBetweenRunsFdr>$match_between_runs_fdr</matchBetweenRunsFdr>
  <reQuantify>$re_quantify</reQuantify>
  <dependentPeptides>$dependent_peptides</dependentPeptides>
  <dependentPeptideFdr>$dependent_peptide_fdr</dependentPeptideFdr>
  <dependentPeptideMassBin>$dependent_peptide_mass_bin</dependentPeptideMassBin>
  <labelFree>$label_free</labelFree>
  <lfqMinEdgesPerNode>$lfq_min_edges_per_node</lfqMinEdgesPerNode>
  <lfqAvEdgesPerNode>$lfq_av_edges_per_node</lfqAvEdgesPerNode>
  <hybridQuantification>$hybrid_quantification</hybridQuantification>
  <msmsConnection>$msms_connection</msmsConnection>
  <ibaq>$ibaq</ibaq>
  <msmsRecalibration>$msms_recalibration</msmsRecalibration>
  <ibaqLogFit>$ibaq_log_fit</ibaqLogFit>
  <razorProteinFdr>$razor_protein_fdr</razorProteinFdr>
  <calcSequenceTags>$calc_sequence_tags</calcSequenceTags>
  <deNovoVarMods>$de_novo_var_mods</deNovoVarMods>
  <massDifferenceSearch>$mass_difference_search</massDifferenceSearch>
  <minPepLen>$min_pep_len</minPepLen>
  <peptideFdr>$peptide_fdr</peptideFdr>
  <peptidePep>$peptide_pep</peptidePep>
  <proteinFdr>$protein_fdr</proteinFdr>
  <siteFdr>$site_fdr</siteFdr>
  <minPeptideLengthForUnspecificSearch>$min_peptide_length_for_unspecific_search</minPeptideLengthForUnspecificSearch>
  <maxPeptideLengthForUnspecificSearch>$max_peptide_length_for_unspecific_search</maxPeptideLengthForUnspecificSearch>
  <useNormRatiosForOccupancy>$use_norm_ratios_for_occupancy</useNormRatiosForOccupancy>
  <minPeptides>$min_peptides</minPeptides>
  <minRazorPeptides>$min_razor_peptides</minRazorPeptides>
  <minUniquePeptides>$min_unique_peptides</minUniquePeptides>
  <useCounterparts>$use_counterparts</useCounterparts>
  <minRatioCount>$min_ratio_count</minRatioCount>
  <lfqMinRatioCount>$lfq_min_ratio_count</lfqMinRatioCount>
  <restrictProteinQuantification>$restrict_protein_quantification</restrictProteinQuantification>
  $restrict_mods
  <matchingTimeWindow>$matching_time_window</matchingTimeWindow>
  <numberOfCandidatesMultiplexedMsms>$number_of_candidates_multiplexed_msms</numberOfCandidatesMultiplexedMsms>
  <numberOfCandidatesMsms>$number_of_candidates_msms</numberOfCandidatesMsms>
  <separateAasForSiteFdr>$separate_aas_for_site_fdr</separateAasForSiteFdr>
  <massDifferenceMods />
  <aifParams aifSilWeight="$aif_sil_weight"
             aifIsoWeight="$aif_iso_weight"
             aifTopx="$aif_topx"
             aifCorrelation="$aif_correlation"
             aifCorrelationFirstPass="$aif_correlation_first_pass"
             aifMinMass="$aif_min_mass"
             aifMsmsTol="$aif_msms_tol"
             aifSecondPass="$aif_second_pass"
             aifIterative="$aif_iterative"
             aifThresholdFdr="$aif_threhold_fdr" />
  <groups>
    <ParameterGroups>
      $group_params
    </ParameterGroups>
  </groups>
  <qcSettings>
    $qcSetting
  </qcSettings>
  <msmsParams>
    $ftms_fragment_settings
    $itms_fragment_settings
    $tof_fragment_settings
    $unknown_fragment_settings
  </msmsParams>
  <keepLowScoresMode>$keep_low_scores_mode</keepLowScoresMode>
  <msmsCentroidMode>$msms_centroid_mode</msmsCentroidMode>
  <quantMode>$quant_mode</quantMode>
  <siteQuantMode>$site_quant_mode</siteQuantMode>
  <groupParams>
      $group_params_multi
  </groupParams>
</MaxQuantParams>
"""

GROUP_TEMPLATE = """
         <maxCharge>$max_charge</maxCharge>
         <lcmsRunType>$lcms_run_type</lcmsRunType>
         <msInstrument>$ms_instrument</msInstrument>
         <groupIndex>$group_index</groupIndex>
         <maxLabeledAa>$max_labeled_aa</maxLabeledAa>
         <maxNmods>$max_n_mods</maxNmods>
         <maxMissedCleavages>$max_missed_cleavages</maxMissedCleavages>
         <multiplicity>$multiplicity</multiplicity>
         <protease>$protease</protease>
         <proteaseFirstSearch>$protease</proteaseFirstSearch>
         <useProteaseFirstSearch>false</useProteaseFirstSearch>
         <useVariableModificationsFirstSearch>false</useVariableModificationsFirstSearch>
         $variable_mods
         $isobaric_labels
         <variableModificationsFirstSearch>
            <string>Oxidation (M)</string>
            <string>Acetyl (Protein N-term)</string>
         </variableModificationsFirstSearch>
         <hasAdditionalVariableModifications>false</hasAdditionalVariableModifications>
         <additionalVariableModifications>
            <ArrayOfString />
         </additionalVariableModifications>
         <additionalVariableModificationProteins>
            <ArrayOfString />
         </additionalVariableModificationProteins>
         <doMassFiltering>$do_mass_filtering</doMassFiltering>
         <firstSearchTol>$first_search_tol</firstSearchTol>
         <mainSearchTol>$main_search_tol</mainSearchTol>
         $labels
"""

#         <labels>
#            <string />
#            <string>Arg10; Lys8</string>
#         </labels>

fragment_settings = {
  "FTMS":    {"InPpm": "true", "Deisotope": "true", "Topx": "10", "HigherCharges": "true",
              "IncludeWater": "true", "IncludeAmmonia": "true", "DependentLosses": "true",
              "tolerance_value": "20", "tolerance_unit": "Ppm", "name": "FTMS"},
  "ITMS":    {"InPpm": "false", "Deisotope": "false", "Topx": "6", "HigherCharges": "true",
              "IncludeWater": "true", "IncludeAmmonia": "true", "DependentLosses": "true",
              "tolerance_value": "0.5", "tolerance_unit": "Dalton", "name": "ITMS"},
  "TOF":     {"InPpm": "false", "Deisotope": "true", "Topx": "10", "HigherCharges": "true",
              "IncludeWater": "true", "IncludeAmmonia": "true", "DependentLosses": "true",
              "tolerance_value": "0.1", "tolerance_unit": "Dalton", "name": "TOF"},
  "Unknown": {"InPpm": "false", "Deisotope": "false", "Topx": "6", "HigherCharges": "true",
              "IncludeWater": "true", "IncludeAmmonia": "true", "DependentLosses": "true",
              "tolerance_value": "0.5", "tolerance_unit": "Dalton", "name": "Unknown"},
}


def build_isobaric_labels(reporter_type):
    if not reporter_type:
        return "<isobaricLabels />"
    if reporter_type == "itraq_4plex":
        prefix = "iTRAQ4plex"
        mzs = [114, 115, 116, 117]
    elif reporter_type == "itraq_8plex":
        prefix = "iTRAQ8plex"
        mzs = [113, 114, 115, 116, 117, 118, 119, 121]
    elif reporter_type == "tmt_2plex":
        prefix = "TMT2plex"
        mzs = [126, 127]
    elif reporter_type == "tmt_6plex":
        prefix = "TMT6plex"
        mzs = [126, 127, 128, 129, 130, 131]
    else:
        raise Exception("Unknown reporter type - %s" % reporter_type)
    labels = ["%s-%s%d" % (prefix, term, mz) for term in ["Nter", "Lys"] for mz in mzs]
    return wrap(map(xml_string, labels), "isobaricLabels")


def parse_groups(inputs_file):
    inputs_lines = [line.strip() for line in open(inputs_file, "r").readlines()]
    inputs_lines = [line for line in inputs_lines if line and not line.startswith("#")]

    i = 0
    groups = []
    while i < len(inputs_lines):
        groups.append({"path": inputs_lines[i],
                       "name": re.sub(r'.raw$', "", inputs_lines[i+1])})
        i += 2
    return groups


def add_fragment_options(parser):
    for name, options in fragment_settings.iteritems():
        for key, value in options.iteritems():
            option_key = ("%s_%s" % (name, key)).lower()
            parser.add_option("--%s" % option_key, default=value)


def update_fragment_settings(arg_options):
    for name, options in fragment_settings.iteritems():
        for key, value in options.iteritems():
            arg_option_key = ("%s_%s" % (name, key)).lower()
            options[key] = getattr(arg_options, arg_option_key)


def to_fragment_settings(name, values):
    """
    """

    fragment_settings_template = """
    <FragmentSpectrumSettings Name="$name" InPpm="$InPpm" Deisotope="$Deisotope"
     Topx="$Topx" HigherCharges="$HigherCharges" IncludeWater="$IncludeWater" IncludeAmmonia="$IncludeAmmonia"
     DependentLosses="$DependentLosses">
      <Tolerance>
        <Value>$tolerance_value</Value>
        <Unit>$tolerance_unit</Unit>
      </Tolerance>
    </FragmentSpectrumSettings>
    """
    safe_values = dict(values)
    for key, value in safe_values.iteritems():
        safe_values[key] = escape(value)
    return Template(fragment_settings_template).substitute(safe_values)


def get_file_paths(files):
    return wrap([xml_string(name) for name in files], "filePaths")


def get_file_names(file_names):
    return wrap([xml_string(name) for name in file_names], "fileNames")

def get_file_groups(file_groups):
    return wrap([xml_int(file_group) for file_group in file_groups], "paramGroups")


def get_file_fractions(names, file_fractions):
    return wrap([get_fraction(name, fraction) for name,fraction in zip(names, file_fractions)], "Fractions")

def get_fraction(name, fraction):
    return wrap(xml_type("Key", "string", name) + xml_type("Value", "short", fraction),"fraction")

def get_file_experiments(names, file_experiments):
    return wrap(wrap_with_param(wrap([get_experiment(name, exp) for name, exp in zip(names, file_experiments)], "Items"), "column", "Name", "Experiment"), "Values")

def get_experiment(name, exp):
    return wrap(xml_type("Key", "string", name) + xml_type("Value", "string", exp),"Item")    

def wrap(values, tag):
    return "<%s>%s</%s>" % (tag, "".join(values), tag)

def wrap_with_param(values, tag, param_type, param):
    return "<%s %s=\"%s\">%s</%s>" % (tag, param_type, param, "".join(values), tag)


def xml_type(tag, xml_type, value):
    return "<%s xsi:type=\"xsd:%s\">%s</%s>" % (tag, xml_type, value, tag)

def xml_string(str):
    if str:
        return "<string>%s</string>" % escape(str)
    else:
        return "<string />"

def xml_int(value):
    return "<int>%d</int>" % int(value)


def get_properties(options):
    direct_properties = ["lcms_run_type",
                         "max_missed_cleavages",
                         "protease",
                         "first_search_tol",
                         "main_search_tol",
                         "max_n_mods",
                         "max_charge",
                         "max_labeled_aa",
                         "do_mass_filtering",
                         "calc_peak_properties",
                         "use_original_precursor_mz",
                         "multi_modification_search",
                         "keep_low_scores_mode",
                         "msms_centroid_mode",
                         "quant_mode",
                         "site_quant_mode",
                         "advanced_ratios",
                         "rt_shift",
                         "fast_lfq",
                         "randomize",
                         "aif_sil_weight",
                         "aif_iso_weight",
                         "aif_topx",
                         "aif_correlation",
                         "aif_correlation_first_pass",
                         "aif_min_mass",
                         "aif_msms_tol",
                         "aif_second_pass",
                         "aif_iterative",
                         "aif_threhold_fdr",
                         "restrict_protein_quantification",
                         "matching_time_window",
                         "number_of_candidates_multiplexed_msms",
                         "number_of_candidates_msms",
                         "separate_aas_for_site_fdr",
                         "special_aas",
                         "include_contamiants",
                         "equal_il",
                         "topx_window",
                         "max_peptide_mass",
                         "reporter_pif",
                         "reporter_fraction",
                         "reporter_base_peak_ratio",
                         "score_threshold",
                         "filter_aacounts",
                         "second_peptide",
                         "match_between_runs",
                         "match_between_runs_fdr",
                         "re_quantify",
                         "dependent_peptides",
                         "dependent_peptide_fdr",
                         "dependent_peptide_mass_bin",
                         "label_free",
                         "lfq_min_edges_per_node",
                         "lfq_av_edges_per_node",
                         "hybrid_quantification",
                         "msms_connection",
                         "ibaq",
                         "msms_recalibration",
                         "ibaq_log_fit",
                         "razor_protein_fdr",
                         "calc_sequence_tags",
                         "de_novo_var_mods",
                         "mass_difference_search",
                         "min_pep_len",
                         "peptide_fdr",
                         "peptide_pep",
                         "protein_fdr",
                         "site_fdr",
                         "min_peptide_length_for_unspecific_search",
                         "max_peptide_length_for_unspecific_search",
                         "use_norm_ratios_for_occupancy",
                         "min_peptides",
                         "min_razor_peptides",
                         "min_unique_peptides",
                         "use_counterparts",
                         "min_ratio_count",
                         "lfq_min_ratio_count",
                        ]

    props = {
      "slice_peaks": "true",
      "num_cores": str(options.num_cores),
      "database": xml_string(setup_database(options)),
      "process_folder": os.path.join(os.getcwd(), "process"),
    }
    for prop in direct_properties:
        props[prop] = str(getattr(options, prop))

    for name, fragment_options in fragment_settings.iteritems():
        key = "%s_fragment_settings" % name.lower()
        props[key] = to_fragment_settings(name, fragment_options)

    restrict_mods_string = wrap(map(xml_string, options.restrict_mods), "restrictMods")
    props["restrict_mods"] = restrict_mods_string
    fixed_mods_string = wrap(map(xml_string, options.fixed_mods), "fixedModifications")
    props["fixed_mods"] = fixed_mods_string
    variable_mods_string = wrap(map(xml_string, options.variable_mods), "variableModifications")
    props["variable_mods"] = variable_mods_string
    return props


# http://stackoverflow.com/questions/377017/test-if-executable-exists-in-python
def which(program):
    import os

    fpath, fname = os.path.split(program)
    path = os.getcwd()
    drive, tail = os.path.splitdrive(path)
    drive += '\\'
    for root, dirs, files in os.walk(drive):
        if fname in files:
            return os.path.join(root, fname)

    return None

def get_unique_path(base, extension):
    """
    """
    return "%s_%d%s" % (base, int(time.time() * 1000), extension)


def get_env_property(name, default):
    if name in os.environ:
        return os.environ[name]
    else:
        return default


def setup_database(options):
    database_path = options.database
    database_name = options.database_name
    database_name = database_name.replace(" ", "_")
    (database_basename, extension) = os.path.splitext(database_name)
    database_destination = get_unique_path(database_basename, ".fasta")
    database_id = options.andromeda_config
    if(database_id == 'all_include'):
        database_regex = '(.*)'
    elif(database_id == 'all_after'):
        database_regex = '>(.*)'
    elif(database_id == 'upTofirst_space'):
        database_regex = '>([^ ]*)'
    elif(database_id == 'ipi_acc'):
        database_regex = '>IPI:([^\| .]*)'
    elif(database_id == 'ncbi_acc'):
        database_regex = '>(gi\|[0-9]*)'
    elif(database_id == 'upTofirst_tab'):
        database_regex = '>([^\t]*)'
    elif(database_id == 'uniprot'):
        database_regex = '>.*\|(.*)\|'
    elif(database_id == 'upTofirst_slash'):
        database_regex = '>([^\|]*)'


    assert database_destination == os.path.basename(database_destination)
    symlink(database_path, database_destination)

    database_conf = get_env_property("MAXQUANT_DATABASE_CONF", None)


    if not database_conf:
        exe_path = which("MaxQuantCmd.exe")

        database_conf = os.path.join(os.path.dirname(exe_path), "conf", "databases.xml")
    with FileLock(database_conf + ".galaxy_lock"):
        tree = ET.parse(database_conf)
        root = tree.getroot()
        databases_node = root.find("Databases")
        database_node = ET.SubElement(databases_node, 'databases')
        database_node.attrib["search_expression"] = database_regex
        database_node.attrib["replacement_expression"] = "%1"
        database_node.attrib["filename"] = database_destination
        tree.write(database_conf)
    return os.path.abspath(database_destination)

def read_expdesign(experimental_design):
    table_data = []
    with open(experimental_design, 'r') as e:
        for line in e:
            row_data = line.split('\t')
            table_data.append(Data(row_data[0], row_data[1], row_data[2].rstrip()))
    return table_data


def find_data_expdesign(table, raw):
    for row in table:
        if row.name == raw:
            return row

def setup_inputs(input_groups_path, experimental_design):
    parsed_groups = parse_groups(input_groups_path)
    
    names = [x['name'] for x in parsed_groups]
    paths = [os.path.abspath(name+".raw") for name in names]
    paths_intermediate = [x['path'] for x in parsed_groups]

    samples = []
    experiments = []
    groups = []
    for name in names:
        table_row = find_data_expdesign(experimental_design, name)
        samples.append(table_row.fraction)
        experiments.append(table_row.experiment)
        groups.append(1)


    for (name,path) in zip(names, paths_intermediate):
        symlink(path, name+".raw")

    file_data = (get_file_paths(paths), get_file_names(names), get_file_groups(groups),
                 get_file_fractions(names, samples), get_file_experiments(names, experiments))

    return "<rawFileInfo>%s%s%s%s%s</rawFileInfo> " % file_data


def set_group_params(properties, options):
    labels = [""]
    if options.labels:
        labels = options.labels
    labels_string = wrap([xml_string(label.replace(",", "; ")) for label in labels], "labels")
    group_properties = dict(properties)
    group_properties["labels"] = labels_string
    group_properties["multiplicity"] = len(labels)
    group_properties["group_index"] = "1"
    group_properties["ms_instrument"] = "0"
    group_params = Template(GROUP_TEMPLATE).substitute(group_properties)
    properties["group_params"] = group_params


def split_mods(mods_string):
    return [mod for mod in mods_string.split(",") if mod] if mods_string else []


def run_script():
    parser = optparse.OptionParser()
    parser.add_option("--input_groups")
    parser.add_option("--exp_design")
    parser.add_option("--database")
    parser.add_option("--andromeda_config")
    parser.add_option("--database_name")
    parser.add_option("--num_cores", type="int", default=1)
    parser.add_option("--max_missed_cleavages", type="int", default=2)
    parser.add_option("--protease", default="Trypsin/P")
    parser.add_option("--first_search_tol", default="20")
    parser.add_option("--main_search_tol", default="6")
    parser.add_option("--max_n_mods", type="int", default=5)
    parser.add_option("--max_charge", type="int", default=7)
    parser.add_option("--do_mass_filtering", default="true")
    parser.add_option("--labels", action="append", default=[])
    parser.add_option("--max_labeled_aa", type="int", default=3)
    parser.add_option("--keep_low_scores_mode", type="int", default=0)
    parser.add_option("--msms_centroid_mode", type="int", default=1)
    # 0 = all peptides, 1 = Use razor and unique peptides, 2 = use unique peptides
    parser.add_option("--quant_mode", type="int", default=1)
    parser.add_option("--site_quant_mode", type="int", default=0)
    parser.add_option("--aif_sil_weight", type="int", default=4)
    parser.add_option("--aif_iso_weight", type="int", default=2)
    parser.add_option("--aif_topx", type="int", default=50)
    parser.add_option("--aif_correlation", type="float", default=0.8)
    parser.add_option("--aif_correlation_first_pass", type="float", default=0.8)
    parser.add_option("--aif_min_mass", type="float", default=0)
    parser.add_option("--aif_msms_tol", type="float", default=10)
    parser.add_option("--aif_second_pass", default="false")
    parser.add_option("--aif_iterative", default="false")
    parser.add_option("--aif_threhold_fdr", default="0.01")
    parser.add_option("--restrict_protein_quantification", default="true")
    parser.add_option("--matching_time_window", default="2")
    parser.add_option("--number_of_candidates_multiplexed_msms", default="50")
    parser.add_option("--number_of_candidates_msms", default="15")
    parser.add_option("--separate_aas_for_site_fdr", default="true")
    parser.add_option("--advanced_ratios", default="false")
    parser.add_option("--rt_shift", default="false")
    parser.add_option("--fast_lfq", default="true")
    parser.add_option("--randomize", default="false")
    parser.add_option("--special_aas", default="KR")
    parser.add_option("--include_contamiants", default="false")
    parser.add_option("--equal_il", default="false")
    parser.add_option("--topx_window", default="100")
    parser.add_option("--max_peptide_mass", default="5000")
    parser.add_option("--reporter_pif", default="0.75")
    parser.add_option("--reporter_fraction", default="0")
    parser.add_option("--reporter_base_peak_ratio", default="0")
    parser.add_option("--score_threshold", default="0")
    parser.add_option("--filter_aacounts", default="true")
    parser.add_option("--second_peptide", default="true")
    parser.add_option("--match_between_runs", default="false")
    parser.add_option("--match_between_runs_fdr", default="false")
    parser.add_option("--re_quantify", default="true")
    parser.add_option("--dependent_peptides", default="false")
    parser.add_option("--dependent_peptide_fdr", default="0.01")
    parser.add_option("--dependent_peptide_mass_bin", default="0.0055")
    parser.add_option("--label_free", default="false")
    parser.add_option("--lfq_min_edges_per_node", default="3")
    parser.add_option("--lfq_av_edges_per_node", default="6")
    parser.add_option("--hybrid_quantification", default="false")
    parser.add_option("--msms_connection", default="false")
    parser.add_option("--ibaq", default="false")
    parser.add_option("--msms_recalibration", default="false")
    parser.add_option("--ibaq_log_fit", default="true")
    parser.add_option("--razor_protein_fdr", default="true")
    parser.add_option("--calc_sequence_tags", default="false")
    parser.add_option("--de_novo_var_mods", default="true")
    parser.add_option("--mass_difference_search", default="false")
    parser.add_option("--min_pep_len", default="7")
    parser.add_option("--peptide_fdr", default="0.01")
    parser.add_option("--peptide_pep", default="1")
    parser.add_option("--protein_fdr", default="0.01")
    parser.add_option("--site_fdr", default="0.01")
    parser.add_option("--min_peptide_length_for_unspecific_search", default="8")
    parser.add_option("--max_peptide_length_for_unspecific_search", default="25")
    parser.add_option("--use_norm_ratios_for_occupancy", default="true")
    parser.add_option("--min_peptides", default="1")
    parser.add_option("--min_razor_peptides", default="1")
    parser.add_option("--min_unique_peptides", default="0")
    parser.add_option("--use_counterparts", default="false")
    parser.add_option("--min_ratio_count", default="2")
    parser.add_option("--lfq_min_ratio_count", default="2")
    parser.add_option("--calc_peak_properties", default="false")
    parser.add_option("--use_original_precursor_mz", default="false")
    parser.add_option("--multi_modification_search", default="false")
    parser.add_option("--lcms_run_type", default="0")
    parser.add_option("--reporter_type", default=None)
    parser.add_option("--output_mqpar", default=None)
    text_outputs = {
                    "aif_msms": "aifMsms",
                    "all_peptides": "allPeptides",
                    "evidence": "evidence",
                    "modification_specific_peptides": "modificationSpecificPeptides",
                    "msms": "msms",
                    "msms_scans": "msmsScans",
                    "mz_range": "mzRange",
                    "parameters": "parameters",
                    "peptides": "peptides",
                    "protein_groups": "proteinGroups",
                    "sim_peptides": "simPeptides",
                    "sim_scans": "simScans",
                    "summary": "summary"
                   }
    for output in text_outputs.keys():
        parser.add_option("--output_%s" % output, default=None)

    parser.add_option("--variable_mods", default="Oxidation (M),Acetyl (Protein N-term)")
    parser.add_option("--restrict_mods", default="Oxidation (M),Acetyl (Protein N-term)")
    parser.add_option("--fixed_mods", default="Carbamidomethyl (C)")

    add_fragment_options(parser)

    (options, args) = parser.parse_args()
    options.restrict_mods = split_mods(options.restrict_mods)
    options.fixed_mods = split_mods(options.fixed_mods)
    options.variable_mods = split_mods(options.variable_mods)

    update_fragment_settings(options)

    experimental_design = read_expdesign(options.exp_design)

    raw_file_info = setup_inputs(options.input_groups, experimental_design)

    properties = get_properties(options)
    properties["raw_file_info"] = raw_file_info
    properties["isobaric_labels"] = build_isobaric_labels(options.reporter_type)
    set_group_params(properties, options)

    number_of_raws = raw_file_info.count('<int>')
    properties["group_params_multi"] = ""
    properties["qcSetting"] = ""
    for s in range(number_of_raws):
        properties["qcSetting"] += "<qcSetting xsi:nil=\"true\" />\n"
        properties["group_params_multi"] += "<groupParam>"+properties["group_params"]+"</groupParam>\n"


    driver_contents = Template(TEMPLATE).substitute(properties)
    open("mqpar.xml", "w").write(driver_contents)
    print driver_contents

    execute("%s mqpar.xml %d" % (which("MaxQuantCmd.exe"),options.num_cores))

    for key, basename in text_outputs.iteritems():
        attribute = "output_%s" % key
        destination = getattr(options, attribute, None)
        if destination:
            source = os.path.join("combined", "txt", "%s.txt" % basename)
            shutil.copy(source, destination)
    output_mqpar = options.output_mqpar
    if output_mqpar:
        shutil.copy("mqpar.xml", output_mqpar)

if __name__ == '__main__':
    __main__()
