import re
import subprocess
import argparse


"""This module exists to run msslookup spectra, while detecting set name
patterns in the passed spectra files using regexes, which can be problematic
in bash"""


def get_setnames(filenames, setpatterns, setnames):
    """Returns a list of setnames that correspond to passed list of filenames.
    Setnames are passed together with their respective patterns.
    """
    setnames_found = []
    # cheetah converts square brackets, put them back
    setpatterns_fixed = [x.replace('__ob__', '[').replace('__cb__', ']')
                         for x in setpatterns]
    pretty_patterns = ', '.join(['"{}"'.format(x) for x in setpatterns_fixed])
    for fn in filenames:
        found_setname = False
        for setpattern, setname in zip(setpatterns_fixed, setnames):
            if re.search(setpattern, fn) is not None:
                setnames_found.append(setname)
                found_setname = True
                break
        if not found_setname:
            raise RuntimeError('Could not find set pattern in filename {}\n'
                               'Patterns tested: {}'.format(fn,
                                                            pretty_patterns))
    return setnames_found


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--infiles', dest='infiles', nargs='+')
    parser.add_argument('--setpatterns', dest='setpatterns', nargs='+')
    parser.add_argument('--setnames', dest='setnames', nargs='+')
    args = parser.parse_args()
    cmd = ['msslookup', 'spectra', '-i']
    cmd.extend(args.infiles)
    cmd.append('--setnames')
    cmd.extend(get_setnames(args.infiles, args.setpatterns, args.setnames))
    subprocess.call(cmd)


if __name__ == '__main__':
    main()
