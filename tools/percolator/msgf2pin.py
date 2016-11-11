import sys

from percolator import parse_options, run_percolator_command


def main():
    decoy = sys.argv[-1]
    target = sys.argv[-2]
    output = sys.argv[-3]
    options = parse_options(sys.argv[1:-3])
    command = ['msgf2pin', '-o', output]
    run_percolator_command(command, options, [target, decoy])


if __name__ == '__main__':
    main()
