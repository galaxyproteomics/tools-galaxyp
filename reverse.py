from os.path import dirname, join, abspath
import sys
from optparse import OptionParser
from ConfigParser import SafeConfigParser
import subprocess

DEBUG = False


def main():
    (options, args) = _parse_args()
    format_args = (options.input, options.output)
    _run_shell("cat '%s' > '%s'" % format_args)
    _run_dbtoolkit("com.compomics.dbtoolkit.toolkit.ReverseFASTADB", "'%s' | head --lines -4 >> '%s'" % \
                       format_args)


def _run_shell(command):
    if DEBUG:
        print "Running shell command %s" % command
    _exec(command)


def _run_dbtoolkit(java_class, args):
    command_prefix = "java -cp %s" % _dbtoolkit_jar_path()
    _exec("%s %s %s" % (command_prefix, java_class, args))


def _dbtoolkit_jar_path():
    py_path = __file__
    jar_path = join(dirname(py_path), "dbtoolkit-4.2", "dbtoolkit-4.2.jar")
    return jar_path

def _exec(command):
    proc = subprocess.Popen(args=command, shell=True)
    return_code = proc.wait()
    if return_code != 0:
        print "Error executing command [%s], return code is %d" % (command, return_code)
        sys.exit(return_code)


def _parse_args():
    parser = OptionParser()
    parser.add_option("-i", "--input")
    parser.add_option("-o", "--output")
    return parser.parse_args()


if __name__ == "__main__":
    main()
