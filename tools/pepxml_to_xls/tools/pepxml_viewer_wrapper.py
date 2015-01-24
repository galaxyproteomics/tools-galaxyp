#!/usr/bin/env python
import optparse
import os
import sys
import tempfile
import subprocess
import shutil
import logging

assert sys.version_info[:2] >= ( 2, 6 )

log = logging.getLogger(__name__)
working_directory = os.getcwd()
tmp_stderr_name = tempfile.NamedTemporaryFile(dir=working_directory, suffix='.stderr').name
tmp_stdout_name = tempfile.NamedTemporaryFile(dir=working_directory, suffix='.stdout').name


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


def run_script():
    parser = optparse.OptionParser()
    parser.add_option("--input")
    parser.add_option("--export_spreadsheet", action="store_true", dest="export_spreadsheet")
    parser.add_option("--append_unmodified_peptide", action="store_true", dest="append_unmodified_peptide", default=False)
    parser.set_defaults(export_spreadsheet=False)
    (options, args) = parser.parse_args()

    copy_to_working_directory(options.input, "input.pep.xml")
    # Trans-Proteomic Pipeline - cgi-bin/PepXMLViewer.cgi
    cmd = "PepXMLViewer.cgi -I input.pep.xml"
    cmd = "%s %s" % (cmd, "-B exportSpreadsheet")
    if options.export_spreadsheet:
        cmd = "%s %s" % (cmd, "1")
    else:
        cmd = "%s %s" % (cmd, "0")
    execute(cmd)
    if options.append_unmodified_peptide:
        from csv import reader
        csv_opts = {'delimiter': '\t'}
        first = True
        with open("tmp.xls", "w") as output:
            peptide_index = None
            for row in reader(open("input.pep.xls", "r"), **csv_opts):
                if first:
                    peptide_index = row.index("peptide")
                    row.append("unmodified_peptide")
                    output.write("\t".join(row))
                    output.write("\n")
                    first = False
                else:
                    row.append(unmodify(row[peptide_index]))
                    output.write("\t".join(row))
                    output.write("\n")
        execute("mv tmp.xls input.pep.xls")


def unmodify(peptide):
    """

    >>> from re import sub
    >>> sub(r'\[(\-|\d|\.)+\]', '', 'A[-12.34]B')
    'AB'
    """
    from re import sub
    peptide = sub(r'\[(\-|\d|\.)+\]', '', peptide)
    peptide = sub(r'^.\.|\..$|n|c', '', peptide)
    #peptide = sub(r'\..$', '', peptide)
    #peptide = sub(r'\[.+\]', '', peptide)
    return peptide


if __name__ == '__main__':
    __main__()
