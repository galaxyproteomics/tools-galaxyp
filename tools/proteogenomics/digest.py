#   Copyright 2012 Anton Goloborodko, Lev Levitsky
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

import itertools as it
import re
from collections import deque


def cleave(sequence, rule, missed_cleavages=0, min_length=None):
    """Cleaves a polypeptide sequence using a given rule.

    Parameters
    ----------
    sequence : str
        The sequence of a polypeptide.

        .. note::
            The sequence is expected to be in one-letter uppercase notation.
            Otherwise, some of the cleavage rules in :py:data:`expasy_rules`
            will not work as expected.

    rule : str or compiled regex
        A regular expression describing the site of cleavage. It is recommended
        to design the regex so that it matches only the residue whose
        C-terminal bond is to be cleaved. All additional requirements should be
        specified using `lookaround assertions
        <http://www.regular-expressions.info/lookaround.html>`_.
        :py:data:`expasy_rules` contains cleavage rules
        for popular cleavage agents.
    missed_cleavages : int, optional
        Maximum number of allowed missed cleavages. Defaults to 0.
    min_length : int or None, optional
        Minimum peptide length. Defaults to :py:const:`None`.

        ..note ::
            This checks for string length, which is only correct for one-letter
            notation and not for full *modX*. Use :py:func:`length` manually if
            you know what you are doing and apply :py:func:`cleave` to *modX*
            sequences.

    Returns
    -------
    out : set
        A set of unique (!) peptides.

    Examples
    --------
    >>> cleave('AKAKBK', expasy_rules['trypsin'], 0) == {'AK', 'BK'}
    True
    >>> cleave('GKGKYKCK', expasy_rules['trypsin'], 2) == \
    {'CK', 'GKYK', 'YKCK', 'GKGK', 'GKYKCK', 'GK', 'GKGKYK', 'YK'}
    True

    """
    return set(_cleave(sequence, rule, missed_cleavages, min_length))


def _cleave(sequence, rule, missed_cleavages=0, min_length=None):
    """Like :py:func:`cleave`, but the result is a list. Refer to
    :py:func:`cleave` for explanation of parameters.
    """
    peptides = []
    ml = missed_cleavages+2
    trange = range(ml)
    cleavage_sites = deque([0], maxlen=ml)
    cl = 1
    for i in it.chain([x.end() for x in re.finditer(rule, sequence)],
                      [None]):
        cleavage_sites.append(i)
        if cl < ml:
            cl += 1
        for j in trange[:cl-1]:
            seq = sequence[cleavage_sites[j]:cleavage_sites[-1]]
            if seq:
                if min_length is None or len(seq) >= min_length:
                    peptides.append(seq)
    return peptides


def num_sites(sequence, rule, **kwargs):
    """Count the number of sites where `sequence` can be cleaved using
    the given `rule` (e.g. number of miscleavages for a peptide).

    Parameters
    ----------
    sequence : str
        The sequence of a polypeptide.
    rule : str or compiled regex
        A regular expression describing the site of cleavage. It is recommended
        to design the regex so that it matches only the residue whose
        C-terminal bond is to be cleaved. All additional requirements should be
        specified using `lookaround assertions
        <http://www.regular-expressions.info/lookaround.html>`_.
    labels : list, optional
        A list of allowed labels for amino acids and terminal modifications.

    Returns
    -------
    out : int
        Number of cleavage sites.
    """
    return len(_cleave(sequence, rule, **kwargs)) - 1


expasy_rules = {
    'arg-c':         r'R',
    'asp-n':         r'\w(?=D)',
    'bnps-skatole': r'W',
    'caspase 1':     r'(?<=[FWYL]\w[HAT])D(?=[^PEDQKR])',
    'caspase 2':     r'(?<=DVA)D(?=[^PEDQKR])',
    'caspase 3':     r'(?<=DMQ)D(?=[^PEDQKR])',
    'caspase 4':     r'(?<=LEV)D(?=[^PEDQKR])',
    'caspase 5':     r'(?<=[LW]EH)D',
    'caspase 6':     r'(?<=VE[HI])D(?=[^PEDQKR])',
    'caspase 7':     r'(?<=DEV)D(?=[^PEDQKR])',
    'caspase 8':     r'(?<=[IL]ET)D(?=[^PEDQKR])',
    'caspase 9':     r'(?<=LEH)D',
    'caspase 10':    r'(?<=IEA)D',
    'chymotrypsin high specificity': r'([FY](?=[^P]))|(W(?=[^MP]))',
    'chymotrypsin low specificity':
        r'([FLY](?=[^P]))|(W(?=[^MP]))|(M(?=[^PY]))|(H(?=[^DMPW]))',
    'clostripain':   r'R',
    'cnbr':          r'M',
    'enterokinase':  r'(?<=[DE]{3})K',
    'factor xa':     r'(?<=[AFGILTVM][DE]G)R',
    'formic acid':   r'D',
    'glutamyl endopeptidase': r'E',
    'granzyme b':    r'(?<=IEP)D',
    'hydroxylamine': r'N(?=G)',
    'iodosobenzoic acid': r'W',
    'lysc':          r'K',
    'ntcb':          r'\w(?=C)',
    'pepsin ph1.3':  r'((?<=[^HKR][^P])[^R](?=[FLWY][^P]))|'
                     r'((?<=[^HKR][^P])[FLWY](?=\w[^P]))',
    'pepsin ph2.0':  r'((?<=[^HKR][^P])[^R](?=[FL][^P]))|'
                     r'((?<=[^HKR][^P])[FL](?=\w[^P]))',
    'proline endopeptidase': r'(?<=[HKR])P(?=[^P])',
    'proteinase k':  r'[AEFILTVWY]',
    'staphylococcal peptidase i': r'(?<=[^E])E',
    'thermolysin':   r'[^DE](?=[AFILMV])',
    'thrombin':      r'((?<=G)R(?=G))|'
                     r'((?<=[AFGILTVM][AFGILTVWA]P)R(?=[^DE][^DE]))',
    'trypsin':       r'([KR](?=[^P]))|((?<=W)K(?=P))|((?<=M)R(?=P))'
    }
"""
This dict contains regular expressions for cleavage rules of the most
popular proteolytic enzymes. The rules were taken from the
`PeptideCutter tool
<http://ca.expasy.org/tools/peptidecutter/peptidecutter_enzymes.html>`_
at Expasy.
"""
