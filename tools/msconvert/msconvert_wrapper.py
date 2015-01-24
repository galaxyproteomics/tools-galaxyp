#!/usr/bin/env python
import optparse
import os
import sys
import tempfile
import shutil
import subprocess
import re
import logging

assert sys.version_info[:2] >= (2, 6)

log = logging.getLogger(__name__)
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
        print(( open(tmp_stderr_name, "r").read() ))
        print(( open(tmp_stdout_name, "r").read() ))


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
        symlink(data_file, relative_path)
    return relative_path


def __main__():
    run_script()

#ENDTEMPLATE

to_extensions = ['mzML', 'mzXML', 'unindexed_mzML', 'unindexed_mzXML', 'mgf', 'txt', 'ms2', 'cms2']


def str_to_bool(v):
    """ From http://stackoverflow.com/questions/715417/converting-from-a-string-to-boolean-in-python """
    return v.lower() in ["yes", "true", "t", "1"]


def _add_filter(filters_file, contents):
    filters_file.write("filter=%s\n" % contents)


def _skip_line(options, file_num, line_parts):
    file_num_column = options.filter_table_file_column
    if not file_num_column:
        return False
    else:
        target_file_num_val = str(file_num).strip()
        query_file_num_val = line_parts[int(file_num_column) - 1].strip()
        #print "target %s, query %s" % (target_file_num_val, query_file_num_val)
        return target_file_num_val != query_file_num_val


def _read_table_numbers(path, options, file_num=None):
    unique_numbers = set([])
    column_num = options.filter_table_column
    input = open(path, "r")
    first_line = True
    for line in input:
        if not line:
            continue
        line = line.strip()
        if line.startswith("#"):
            first_line = False
            continue
        if column_num == None:
            column = line
        else:
            line_parts = line.split("\t")
            if _skip_line(options, file_num, line_parts):
                continue
            column = line_parts[int(column_num) - 1]
        match = re.match("\d+", column)
        if match:
            unique_numbers.add(int(match.group()))
        first_line = False
    return unique_numbers


def shellquote(s):
    return '"' + s.replace('"', '\\"') + '"'


def _add_filter_line_from_file(filter_file, options, file_num=None):
    file = options.filter_table
    if not file:
        return
    numbers = _read_table_numbers(file, options, file_num)
    msconvert_int_set = " ".join([str(number) for number in numbers])
    filter_type = options.filter_table_type
    if filter_type == 'number':
        filter_prefix = 'scanNumber'
    else:
        filter_prefix = 'index'
    _add_filter(filter_file, "%s %s" % (filter_prefix, msconvert_int_set))


def _create_filters_file(options, file_num=None, debug=False):
    suffix = "" if not file_num else str(file_num)
    filters_file_path = "filters%s" % suffix
    filters_file = open(filters_file_path, "w")
    if options.filters_file:
        filters_file.write(open(options.filters_file, "r").read())
    for filter in options.filter:
        _add_filter(filters_file, filter)
    _add_filter_line_from_file(filters_file, options, file_num=file_num)

    filters_file.close()
    if debug:
        print(( open(filters_file_path, "r").read() ))
    return filters_file_path


def _build_base_cmd(options):
    to_extension = options.toextension
    if to_extension.startswith("unindexed_"):
        to_extension = to_extension[len("unindexed_"):]
        to_params = "--noindex"
    else:
        to_params = ""
    cmd = "msconvert --%s %s" % (to_extension, to_params)
    if str_to_bool(options.zlib):
        cmd = "%s %s" % (cmd, "--zlib")
    if options.binaryencoding:
        cmd = "%s --%s" % (cmd, options.binaryencoding)
    if options.mzencoding:
        cmd = "%s --mz%s" % (cmd, options.mzencoding)
    if options.intensityencoding:
        cmd = "%s --inten%s" % (cmd, options.intensityencoding)
    return cmd


def _run(base_cmd, output_dir='output', inputs=[], debug=False):
    inputs_as_str = " ".join(['%s' % shellquote(input) for input in inputs])
    os.mkdir(output_dir)
    cmd = "%s -o %s %s" % (base_cmd, shellquote(output_dir), inputs_as_str)
    if debug:
        print(cmd)
    execute(cmd)
    output_files = os.listdir(output_dir)
    assert len(output_files) == 1
    output_file = output_files[0]
    return os.path.join(output_dir, output_file)


def run_script():
    parser = optparse.OptionParser()
    parser.add_option('--input', dest='inputs', action='append', default=[])
    parser.add_option('--input_name', dest='input_names', action='append', default=[])
    parser.add_option('--output', dest='output')
    parser.add_option('--fromextension', dest='fromextension')
    parser.add_option('--toextension', dest='toextension', default='mzML', choices=to_extensions)
    parser.add_option('--binaryencoding', dest='binaryencoding', choices=['32', '64'])
    parser.add_option('--mzencoding', dest='mzencoding', choices=['32', '64'])
    parser.add_option('--intensityencoding', dest='intensityencoding', choices=['32', '64'])
    parser.add_option('--zlib', dest='zlib', default="false")
    parser.add_option('--filter', dest='filter', action='append', default=[])
    parser.add_option('--filters_file', dest='filters_file', default=None)
    parser.add_option('--filter_table', default=None)
    parser.add_option('--filter_table_type', default='index', choices=['index', 'number'])
    parser.add_option('--filter_table_column', default=None)
    parser.add_option('--filter_table_file_column', default=None)
    parser.add_option('--debug', dest='debug', action='store_true', default=False)

    (options, args) = parser.parse_args()
    if len(options.inputs) < 1:
        stop_err("No input files to msconvert specified")
    if len(options.input_names) > 0 and len(options.input_names) != len(options.inputs):
        stop_err("Number(s) of supplied input names and input files do not match")
    if not options.output:
        stop_err("Must specify output location")
    input_files = []
    for i, input in enumerate(options.inputs):
        input_base = None
        if len(options.input_names) > i:
            input_base = options.input_names[i]
            input_base = input_base.replace("'", "").replace("\"", "")
            print("1- input_base: %s" % input_base)
        if not input_base:
            input_base = 'input%s' % i
            print("2- input_base: %s" % input_base)
        if not input_base.lower().endswith(options.fromextension.lower()):
            input_file = '%s.%s' % (input_base, options.fromextension)
            print("3- input_base: %s" % input_base)
            print("3- input_file: %s" % input_file)
        else:
            input_file = input_base
            print("4- input_base: %s" % input_base)
            print("4- input_file: %s" % input_file)
        input_file = input_file
        copy_to_working_directory(input, input_file)
        input_files.append(input_file)

    cmd = _build_base_cmd(options)
    file_column = options.filter_table_file_column
    if not file_column:
        # Apply same filters to all files, just create a unviersal filter files
        # and run msconvert once.
        filters_file_path = _create_filters_file(options, debug=options.debug)
        cmd = "%s -c %s" % (cmd, filters_file_path)
    else:
        # Dispatching on a column to filter different files differently, need to filter
        # each input once with msconvert and then merge once.
        filtered_files = []
        for index, input_file in enumerate(input_files):
            filters_file_path = _create_filters_file(options, index + 1, debug=options.debug)
            filter_cmd = "%s -c %s" % (cmd, filters_file_path)
            filtered_output_file = _run(filter_cmd, output_dir='output%d' % index, inputs=[input_file], debug=options.debug)
            filtered_files.append(filtered_output_file)
        input_files = filtered_files
    if len(input_files) > 1:
        cmd = "%s --merge" % cmd
    output_file = _run(cmd, output_dir='output', inputs=input_files, debug=options.debug)
    shutil.copy(output_file, options.output)


if __name__ == '__main__':
    __main__()
