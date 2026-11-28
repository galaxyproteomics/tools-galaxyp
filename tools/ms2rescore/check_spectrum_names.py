"""Reject ambiguous run names before MS2Rescore's prefix-based file discovery."""

import json
import sys


def main():
    with open(sys.argv[1]) as handle:
        names = sorted(json.load(handle))
    for first, second in zip(names, names[1:]):
        if second.startswith(first):
            sys.exit(
                f"Ambiguous spectrum run names: {first!r} and {second!r}. "
                "MS2Rescore matches spectrum filenames by prefix. Use unique run names "
                "that are not prefixes of each other, updating the PSM run names too."
            )


if __name__ == "__main__":
    main()
