#!/usr/bin/env python
import optparse
import os
import sys
import tempfile
import shutil
import subprocess
import re
from os.path import basename
import logging

assert sys.version_info[:2] >= ( 2, 6 )

log = logging.getLogger(__name__)
working_directory = os.getcwd()
tmp_stderr_name = tempfile.NamedTemporaryFile(dir = working_directory, suffix = '.stderr').name
tmp_stdout_name = tempfile.NamedTemporaryFile(dir = working_directory, suffix = '.stdout').name

def stop_err( msg ):
    sys.stderr.write( "%s\n" % msg )
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
    with open(tmp_stderr_name, 'wb') as tmp_stderr:
        with open(tmp_stdout_name, 'wb') as tmp_stdout:
            proc = subprocess.Popen(args=command, shell=True, stderr=tmp_stderr.fileno(), stdout=tmp_stdout.fileno(), stdin=stdin, env=os.environ)
            returncode = proc.wait()
            if returncode != 0:
                raise Exception("Program returned with non-zero exit code %d. stderr: %s" % (returncode, read_stderr()))

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
        import win32file
        win32file.CreateSymbolicLink(source, link_name, 1)
    else:
        os.symlink(source, link_name)


def copy_to_working_directory(data_file, relative_path):
    if os.path.abspath(data_file) != os.path.abspath(relative_path):
        shutil.copy(data_file, relative_path)
    return relative_path

def __main__():
    run_script()

#ENDTEMPLATE

to_extensions = ['mzML', 'mzXML', 'mgf', 'txt', 'ms2', 'cms2']

def str_to_bool(v):
    """ From http://stackoverflow.com/questions/715417/converting-from-a-string-to-boolean-in-python """
    return v.lower() in ["yes", "true", "t", "1"]


def run_script():
    parser = optparse.OptionParser()
    parser.add_option('--input', dest='input')
    parser.add_option('--output', dest='output')
    parser.add_option('--fromextension', dest='fromextension')
    parser.add_option('--toextension', dest='toextension', default='mzML', choices=to_extensions)
    parser.add_option('--binaryencoding', dest='binaryencoding', choices=['32', '64'])
    parser.add_option('--mzencoding', dest='mzencoding', choices=['32', '64'])
    parser.add_option('--intensityencoding', dest='intensityencoding', choices=['32', '64'])
    parser.add_option('--noindex', dest='noindex')
    parser.add_option('--zlib', dest='zlib')
    parser.add_option('--filter', dest='filter', action='append', default=[])

    (options, args) = parser.parse_args()

    filter_commands = ''
    for filter in options.filter:
        filter_commands = "%s --filter \"%s\"" % (filter_commands, filter)

    input_file = 'input.%s' % options.fromextension
    copy_to_working_directory(options.input, input_file)
    os.mkdir('output')
    cmd = "msconvert --%s -o output" % (options.toextension)
    if str_to_bool(options.noindex):
        cmd = "%s %s" % (cmd, "--noindex")
    if str_to_bool(options.zlib):
        cmd = "%s %s" % (cmd, "--zlib")
    cmd = "%s --%s" % (cmd, options.binaryencoding)
    cmd = "%s --mz%s" % (cmd, options.mzencoding)
    cmd = "%s --inten%s" % (cmd, options.intensityencoding)
    cmd = "%s %s" % (cmd, input_file)
    cmd = "%s %s" % (cmd, filter_commands)
    print(cmd)
    execute(cmd)
    output_files = os.listdir('output')
    assert len(output_files) == 1
    output_file = output_files[0]
    shutil.copy(os.path.join('output', output_file), options.output)

if __name__ == '__main__': __main__()
