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

def str_to_bool(v):
    """ From http://stackoverflow.com/questions/715417/converting-from-a-string-to-boolean-in-python """
    return v.lower() in ["yes", "true", "t", "1"]

def shellquote(s):
    return '"' + s.replace('"', '\\"') + '"'

def run_script():
    parser = optparse.OptionParser()
    parser.add_option('--input', dest='inputs', action='append', default=[])
    parser.add_option('--input_name', dest='input_names', action='append', default=[])
    parser.add_option('--implicit', dest='implicits', action='append', default=[], help='input files that should NOT be on the AB SCIEX MS Data Converter command line.')
    parser.add_option('--output', dest='output')
    parser.add_option('--fromextension', dest='fromextension')
    parser.add_option('--toextension', dest='toextension', default='mzML', choices=['mzML', 'mgf'])
    parser.add_option('--content_type', dest='content_type', default='centroid', choices=['profile', 'centroid', 'proteinpilot'])
    parser.add_option('--binaryencoding', dest='binaryencoding', choices=['32', '64'])
    parser.add_option('--zlib', dest='zlib', default="false")
    parser.add_option('--index', dest='index', default="false")
    parser.add_option('--debug', dest='debug', action='store_true', default=False)

    (options, args) = parser.parse_args()
    if len(options.inputs) < 1:
        stop_err("No input files to ms_data_convert specified")
    if len(options.input_names) > 0 and len(options.input_names) != len(options.inputs):
        stop_err("Number(s) of supplied input names and input files do not match")
    if not options.output:
        stop_err("Must specify output location")
    input_files = []
    for i, input in enumerate(options.inputs):
        # the commnadline template cannot determine if optional files exists, so do it here
        if not os.path.exists(input):  
            continue
        input_base = None
        if len(options.input_names) > i:
            input_base = options.input_names[i]
            input_base = input_base.replace("'", "").replace("\"", "")
            print("1- input_base: %s" % input_base)
        if not input_base:
            input_base = 'input%s' % i
            print("2- input_base: %s" % input_base)
        if not input_base.lower().endswith(options.fromextension.lower()) and input not in options.implicits:
            input_file = '%s.%s' % (input_base, options.fromextension)
            print("3- input_base: %s" % input_base)
            print("3- input_file: %s" % input_file)
        else:
            input_file = input_base
            print("4- input_base: %s" % input_base)
            print("4- input_file: %s" % input_file)
        input_file = input_file
        copy_to_working_directory(input, input_file)
        if input not in options.implicits:
            input_files.append(input_file)
    ## AB_SCIEX_MS_Converter <input format> <input data> <output content type> <output format> <output file> [data compression setting] [data precision setting] [create index flag]
    inputs_as_str = " ".join(['%s' % shellquote(input) for input in input_files])
    output_file = re.sub('(%s)?$' % options.fromextension.lower(), options.toextension, input_files[0].lower())
    cmd = "AB_SCIEX_MS_Converter %s %s -%s %s %s" % (options.fromextension.upper(), inputs_as_str, options.content_type, options.toextension.upper(), output_file )
    if str_to_bool(options.zlib):
        cmd = "%s %s" % (cmd, "/zlib")
    if options.binaryencoding:
        cmd = "%s %s" % (cmd, "/singleprecision" if options.binaryencoding == '32' else "")
    if str_to_bool(options.zlib):
        cmd = "%s %s" % (cmd, "/index")
    if options.debug:
        print(cmd)
    execute(cmd)
    shutil.copy(output_file, options.output)

if __name__ == '__main__':
    __main__()
