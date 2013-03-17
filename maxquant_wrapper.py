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


TEMPLATE = """<MaxQuantParams runOnCluster="false" processFolder="$process_folder">
  <rawFileInfo>
    $file_paths
    $file_names
    <paramGroups><int>1</int></paramGroups>
    <Fractions/>
    <Values/>
  </rawFileInfo>
  <experimentalDesignFilename/>
  <slicePeaks>$slice_peaks</slicePeaks>
  <tempFolder/>
  <ncores>$num_cores</ncores>
  <ionCountIntensities>false</ionCountIntensities>
  <maxFeatureDetectionCores>1</maxFeatureDetectionCores>
  <verboseColumnHeaders>false</verboseColumnHeaders>
  <minTime>NaN</minTime>
  <maxTime>NaN</maxTime>
  <calcPeakProperties>false</calcPeakProperties>
  <useOriginalPrecursorMz>false</useOriginalPrecursorMz>
  <fixedModifications>
    <string>Carbamidomethyl (C)</string>
  </fixedModifications>
  <multiModificationSearch>false</multiModificationSearch>
  <fastaFiles>$database</fastaFiles>
  <fastaFilesFirstSearch/>
  <fixedSearchFolder/>
  <advancedRatios>false</advancedRatios>
  <rtShift>$rt_shift</rtShift>
  <fastLfq>$fast_lfq</fastLfq>
  <randomize>$randomize</randomize>
  <specialAas>$specialAas</specialAas>
  <includeContamiants>$include_contamiants</includeContamiants>
  <equalIl>$equal_il</equalIl>
  <topxWindow>100</topxWindow>
  <maxPeptideMass>5000</maxPeptideMass>
  <reporterPif>0.75</reporterPif>
  <reporterFraction>0</reporterFraction>
  <reporterBasePeakRatio>0</reporterBasePeakRatio>
  <scoreThreshold>0</scoreThreshold>
  <filterAacounts>true</filterAacounts>
  <secondPeptide>true</secondPeptide>
  <matchBetweenRuns>false</matchBetweenRuns>
  <matchBetweenRunsFdr>false</matchBetweenRunsFdr>
  <reQuantify>true</reQuantify>
  <dependentPeptides>false</dependentPeptides>
  <dependentPeptideFdr>0.01</dependentPeptideFdr>
  <dependentPeptideMassBin>0.0055</dependentPeptideMassBin>
  <labelFree>false</labelFree>
  <lfqMinEdgesPerNode>3</lfqMinEdgesPerNode>
  <lfqAvEdgesPerNode>6</lfqAvEdgesPerNode>
  <hybridQuantification>false</hybridQuantification>
  <msmsConnection>false</msmsConnection>
  <ibaq>false</ibaq>
  <msmsRecalibration>false</msmsRecalibration>
  <ibaqLogFit>true</ibaqLogFit>
  <razorProteinFdr>true</razorProteinFdr>
  <calcSequenceTags>false</calcSequenceTags>
  <deNovoVarMods>true</deNovoVarMods>
  <massDifferenceSearch>false</massDifferenceSearch>
  <minPepLen>7</minPepLen>
  <peptideFdr>0.01</peptideFdr>
  <peptidePep>1</peptidePep>
  <proteinFdr>0.01</proteinFdr>
  <siteFdr>0.01</siteFdr>
  <minPeptideLengthForUnspecificSearch>8</minPeptideLengthForUnspecificSearch>
  <maxPeptideLengthForUnspecificSearch>25</maxPeptideLengthForUnspecificSearch>
  <useNormRatiosForOccupancy>true</useNormRatiosForOccupancy>
  <minPeptides>1</minPeptides>
  <minRazorPeptides>1</minRazorPeptides>
  <minUniquePeptides>0</minUniquePeptides>
  <useCounterparts>false</useCounterparts>
  <minRatioCount>2</minRatioCount>
  <lfqMinRatioCount>2</lfqMinRatioCount>
  <restrictProteinQuantification>true</restrictProteinQuantification>
  <restrictMods>
    <string>Oxidation (M)</string>
    <string>Acetyl (Protein N-term)</string>
  </restrictMods>
  <matchingTimeWindow>2</matchingTimeWindow>
  <numberOfCandidatesMultiplexedMsms>50</numberOfCandidatesMultiplexedMsms>
  <numberOfCandidatesMsms>15</numberOfCandidatesMsms>
  <separateAasForSiteFdr>true</separateAasForSiteFdr>
  <massDifferenceMods />
  <aifParams aifSilWeight="4" aifIsoWeight="2" aifTopx="50" aifCorrelation="0.8" aifCorrelationFirstPass="0.8" aifMinMass
="0" aifMsmsTol="10" aifSecondPass="false" aifIterative="false" aifThresholdFdr="0.01" />
  <groups>
    <ParameterGroups>
      $group_params
    </ParameterGroups>
  </groups>
  <qcSettings>
    <qcSetting xsi:nil="true" />
  </qcSettings>
  <msmsParams>
    $ftms_fragment_settings
    $itms_fragment_settings
    $tof_fragment_settings
    $unknown_fragment_settings
  </msmsParams>
  <keepLowScoresMode>0</keepLowScoresMode>
  <msmsCentroidMode>1</msmsCentroidMode>
  <quantMode>1</quantMode>
  <siteQuantMode>0</siteQuantMode>
  <groupParams>
    <groupParam>
      $group_params
    </groupParam>
  </groupParams>
</MaxQuantParams>
"""

fragment_settings = {
  "FTMS":    {"InPpm": "true", "Deisotope": "true", "Topx": "10", "HigherCharges": "true",
              "IncludeWater": "true", "IncludeAmmonoia": "true", "DependentLosses": "true",
              "tolerance_value": "20", "tolerance_unit": "Ppm", "name": "FTMS"},
  "ITMS":    {"InPpm": "false", "Deisotope": "false", "Topx": "6", "HigherCharges": "true",
              "IncludeWater": "true", "IncludeAmmonoia": "true", "DependentLosses": "true",
              "tolerance_value": "0.5", "tolerance_unit": "Dalton", "name": "ITMS"},
  "TOF":     {"InPpm": "false", "Deisotope": "true", "Topx": "10", "HigherCharges": "true",
              "IncludeWater": "true", "IncludeAmmonoia": "true", "DependentLosses": "true",
              "tolerance_value": "0.1", "tolerance_unit": "Dalton", "name": "TOF"},
  "Unknown": {"InPpm": "false", "Deisotope": "false", "Topx": "6", "HigherCharges": "true",
              "IncludeWater": "true", "IncludeAmmonoia": "true", "DependentLosses": "true",
              "tolerance_value": "0.5", "tolerance_unit": "Dalton", "name": "Unknown"},
}


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
    return "<filePaths>%s</filePaths>" % "".join([xml_string(path) for path in files])


def get_file_names(file_names):
    return "<fileNames>%s</fileNames>" % ("".join([xml_string(name) for name in file_names]))


def xml_string(str):
    return "<string>%s</string>" % escape(str)


def get_properties(options, inputs):
    props = {
      "slice_peaks": "true",
      "num_cores": str(options.num_cores),
      "database": xml_string(options.database),
      "rt_shift": "false",
      "fast_lfq": "true",
      "randomize": "false",
      "specialAas": "KR",
      "include_contamiants": "true",
      "equal_il": "false",
    }
    file_paths = get_file_paths(inputs)
    file_names = get_file_names([os.path.basename(input) for input in inputs])
    props["file_paths"] = file_paths
    props["file_names"] = file_names

    for name, fragment_options in fragment_settings.iteritems():
        key = "%s_fragment_settings" % name.lower()
        props[key] = to_fragment_settings(name, fragment_options)

    return props


def setup_inputs(inputs, input_names):
    links = []
    for input, input_name in zip(inputs, input_names):
        if DEBUG:
            print "Processing input %s with name %s and size %d" % (input, input_name, os.stat(input).st_size)
        if not input_name.upper().endswith(".RAW"):
            input_name = "%s.RAW" % input_name
        link_path = os.path.abspath(input_name)
        symlink(input, link_path)
        links.append(link_path)
    return links


def run_script():
    parser = optparse.OptionParser()
    parser.add_option("--input", dest="input", action="append", default=[])
    parser.add_option("--input_name", dest="input_name", action="append", default=[])
    parser.add_option("--database")
    parser.add_option("--database_name")
    parser.add_option("--num_cores", type="int", default=4)
    add_fragment_options(parser)

    (options, args) = parser.parse_args()
    update_fragment_settings(options)

    inputs = setup_inputs(options.input, options.input_name)
    properties = get_properties(options, inputs)
    driver_contents = Template(TEMPLATE).substitute(properties)
    open("mqpar.xml", "w").write(driver_contents)
    execute("MaxQuantCmd.exe mqpar.xml %d" % options.num_cores)

if __name__ == '__main__':
    __main__()
