import subprocess
import sys


def main():
    args = sys.argv[1:]
    filetype_out = args[-1]
    pinput = args[-2]
    poutput = args[-3]
    fileflag = '-J' if filetype_out == 'tsv' else '-X'
    options = parse_options(args[0:-3])
    command = ['percolator', fileflag, poutput, '--decoy-xml-output']
    run_percolator_command(command, options, [pinput])


def run_percolator_command(command, options, infiles):
    command.extend(['--verbose', '0'])
    command.extend(options)
    command.extend(infiles)
    print(command)
    error = subprocess.call(command)
    if error != 0:
        sys.exit(error)


def parse_options(options):
    parsed = []
    options = [x.split('=') for x in options]
    options = [['--{0}'.format(x[0]), x[1]] for x in options]
    for option in options:
        if not option[1] or option[1] in ['false', 'False', False]:
            pass
        elif option[1] in ['true', 'True', True]:
            parsed.append(option[0])
        else:
            parsed.extend([option[0], option[1]])
    return parsed


if __name__ == '__main__':
    main()
