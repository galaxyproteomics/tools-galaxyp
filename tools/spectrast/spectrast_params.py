#!/usr/bin/env python

from __future__ import print_function

import argparse
import re
import sys

search_opts = [
    'libraryFile',
    'databaseFile',
    'databaseType',
    'indexCacheAll',
    # 'filterSelectedListFileName',
    'precursorMzTolerance',
    'precursorMzUseAverage',
    'searchAllCharges',
    'detectHomologs',
    'fvalFractionDelta',
    'useSp4Scoring',
    'fvalUseDotBias',
    'usePValue',
    'useTierwiseOpenModSearch',
    # 'expectedCysteineMod',
    # 'ignoreSpectraWithUnmodCysteine',
    # 'ignoreChargeOneLibSpectra',
    # 'ignoreAbnormalSpectra',
    'outputExtension',
    'outputDirectory',
    'hitListTopHitFvalThreshold',
    'hitListLowerHitsFvalThreshold',
    'hitListShowHomologs',
    'hitListShowMaxRank',
    'hitListOnlyTopHit',
    'hitListExcludeNoMatch',
    'enzymeForPepXMLOutput',
    'printFingerprintingSummary',
    'filterMinPeakCount',
    'filterAllPeaksBelowMz',
    'filterMaxIntensityBelow',
    'filterMinMzRange',
    'filterCountPeakIntensityThreshold',
    'filterRemovePeakIntensityThreshold',
    'filterMaxPeaksUsed',
    'filterMaxDynamicRange',
    'peakScalingMzPower',
    'peakScalingIntensityPower',
    'peakScalingUnassignedPeaks',
    'peakNoBinning',
    'peakBinningNumBinsPerMzUnit',
    'peakBinningFractionToNeighbor',
    'filterLibMaxPeaksUsed',
    'filterLightIonsMzThreshold',
    'filterITRAQReporterPeaks',
    'filterTMTReporterPeaks',
    # 'filterRemoveHuge515Threshold',
]


def __main__():
    parser = argparse.ArgumentParser(
        description='Parse SpectraST search.params files' +
                    ' to create an updated search.params')
    parser.add_argument(
        'param_files', nargs='*',
        help='A SpectraST search.params files')
    parser.add_argument(
        '-o', '--output',
        help='Output file  (-) for stdout')
    args = parser.parse_args()

    output_wtr = open(args.output, 'w')\
        if args.output and args.output != '-' else sys.stdout

    optpat = re.compile('^([a-z]\w+)\s*[=:]\s*([^=]+)$')
    search_params = dict()

    # Collect all search_params
    def parse_params(param_file, fh):
        for i, line in enumerate(fh):
            try:
                m = optpat.match(line.rstrip())
                if m:
                    k, v = m.groups()
                    if k in search_opts:
                        search_params[k] = v
            except Exception, e:
                print('%s(%d): %s %s' % (param_file, i, line, e),
                      file=sys.stderr)

    if args.param_files:
        for param_file in args.param_files:
            try:
                with open(param_file, 'r') as fh:
                    parse_params(param_file, fh)
            except Exception, e:
                print('parse_params: %s' % e, file=sys.stderr)
    else:
        try:
            parse_params('stdin', sys.stdin)
        except Exception, e:
            print('parse_params: %s' % e, file=sys.stderr)

    # Write search_params
    for search_opt in search_opts:
        if search_opt in search_params:
            print('%s = %s' % (search_opt, search_params[search_opt]), file=output_wtr)


if __name__ == "__main__":
    __main__()
