#!/usr/bin/env python
"""
#
# Author:
#
#  James E Johnson
#
#------------------------------------------------------------------------------
"""
import json
import optparse
import re
import sys
import urllib.error
import urllib.parse
import urllib.request


try:
    import xml.etree.cElementTree as ET
except ImportError:
    import xml.etree.ElementTree as ET


def warn_err(msg, exit_code=1):
    sys.stderr.write(msg)
    if exit_code:
        sys.exit(exit_code)


go_types = ['biological process', 'molecular function', 'cellular component']
ipr_types = ['Domain', 'Family', 'Homologous_superfamily', 'Repeat', 'Conserved_site', 'Active_site', 'Binding_site', 'PTM']
ec_name_dict = {
    '1': 'Oxidoreductase',
    '1.1': 'act on the CH-OH group of donors',
    '1.2': 'act on the aldehyde or oxo group of donors',
    '1.3': 'act on the CH-CH group of donors',
    '1.4': 'act on the CH-NH2 group of donors',
    '1.5': 'act on CH-NH group of donors',
    '1.6': 'act on NADH or NADPH',
    '1.7': 'act on other nitrogenous compounds as donors',
    '1.8': 'act on a sulfur group of donors',
    '1.9': 'act on a heme group of donors',
    '1.10': 'act on diphenols and related substances as donors',
    '1.11': 'act on peroxide as an acceptor -- peroxidases',
    '1.12': 'act on hydrogen as a donor',
    '1.13': 'act on single donors with incorporation of molecular oxygen',
    '1.14': 'act on paired donors with incorporation of molecular oxygen',
    '1.15': 'act on superoxide radicals as acceptors',
    '1.16': 'oxidize metal ions',
    '1.17': 'act on CH or CH2 groups',
    '1.18': 'act on iron-sulfur proteins as donors',
    '1.19': 'act on reduced flavodoxin as donor',
    '1.20': 'act on phosphorus or arsenic as donors',
    '1.21': 'act on X-H and Y-H to form an X-Y bond',
    '1.97': 'other oxidoreductases',
    '2': 'Transferase',
    '2.1': 'transfer one-carbon groups, Methylase',
    '2.2': 'transfer aldehyde or ketone groups',
    '2.3': 'acyltransferases',
    '2.4': 'glycosyltransferases',
    '2.5': 'transfer alkyl or aryl groups, other than methyl groups',
    '2.6': 'transfer nitrogenous groups',
    '2.7': 'transfer phosphorus-containing groups',
    '2.8': 'transfer sulfur-containing groups',
    '2.9': 'transfer selenium-containing groups',
    '3': 'Hydrolase',
    '3.1': 'act on ester bonds',
    '3.2': 'act on sugars - glycosylases',
    '3.3': 'act on ether bonds',
    '3.4': 'act on peptide bonds - Peptidase',
    '3.5': 'act on carbon-nitrogen bonds, other than peptide bonds',
    '3.6': 'act on acid anhydrides',
    '3.7': 'act on carbon-carbon bonds',
    '3.8': 'act on halide bonds',
    '3.9': 'act on phosphorus-nitrogen bonds',
    '3.10': 'act on sulfur-nitrogen bonds',
    '3.11': 'act on carbon-phosphorus bonds',
    '3.12': 'act on sulfur-sulfur bonds',
    '3.13': 'act on carbon-sulfur bonds',
    '4': 'Lyase',
    '4.1': 'carbon-carbon lyases',
    '4.2': 'carbon-oxygen lyases',
    '4.3': 'carbon-nitrogen lyases',
    '4.4': 'carbon-sulfur lyases',
    '4.5': 'carbon-halide lyases',
    '4.6': 'phosphorus-oxygen lyases',
    '5': 'Isomerase',
    '5.1': 'racemases and epimerases',
    '5.2': 'cis-trans-isomerases',
    '5.3': 'intramolecular oxidoreductases',
    '5.4': 'intramolecular transferases -- mutases',
    '5.5': 'intramolecular lyases',
    '5.99': 'other isomerases',
    '6': 'Ligase',
    '6.1': 'form carbon-oxygen bonds',
    '6.2': 'form carbon-sulfur bonds',
    '6.3': 'form carbon-nitrogen bonds',
    '6.4': 'form carbon-carbon bonds',
    '6.5': 'form phosphoric ester bonds',
    '6.6': 'form nitrogen-metal bonds',
}
pept2lca_column_order = ['peptide', 'taxon_rank', 'taxon_id', 'taxon_name']
pept2lca_extra_column_order = ['peptide', 'superkingdom', 'kingdom', 'subkingdom', 'superphylum', 'phylum', 'subphylum', 'superclass', 'class', 'subclass', 'infraclass', 'superorder', 'order', 'suborder', 'infraorder', 'parvorder', 'superfamily', 'family', 'subfamily', 'tribe', 'subtribe', 'genus', 'subgenus', 'species_group', 'species_subgroup', 'species', 'subspecies', 'varietas', 'forma']
pept2lca_all_column_order = pept2lca_column_order + pept2lca_extra_column_order[2:]
pept2prot_column_order = ['peptide', 'uniprot_id', 'taxon_id']
pept2prot_extra_column_order = pept2prot_column_order + ['taxon_name', 'ec_references', 'go_references', 'refseq_ids', 'refseq_protein_ids', 'insdc_ids', 'insdc_protein_ids']
pept2ec_column_order = [['peptide', 'total_protein_count'], ['ec_number', 'protein_count']]
pept2ec_extra_column_order = [['peptide', 'total_protein_count'], ['ec_number', 'protein_count', 'name']]
pept2go_column_order = [['peptide', 'total_protein_count'], ['go_term', 'protein_count']]
pept2go_extra_column_order = [['peptide', 'total_protein_count'], ['go_term', 'protein_count', 'name']]
pept2interpro_column_order = [['peptide', 'total_protein_count'], ['code', 'protein_count']]
pept2interpro_extra_column_order = [['peptide', 'total_protein_count'], ['code', 'protein_count', 'type', 'name']]
pept2funct_column_order = ['peptide', 'total_protein_count', 'ec', 'go', 'ipr']


def __main__():
    version = '4.3'
    pep_pat = '^([ABCDEFGHIKLMNPQRSTVWXYZ]+)$'

    def read_tabular(filepath, col):
        peptides = []
        with open(filepath) as fp:
            for i, line in enumerate(fp):
                if line.strip() == '' or line.startswith('#'):
                    continue
                fields = line.rstrip('\n').split('\t')
                peptide = fields[col]
                if not re.match(pep_pat, peptide):
                    warn_err('"%s" is not a peptide (line %d column %d of tabular file: %s)\n' % (peptide, i, col, filepath), exit_code=invalid_ec)
                peptides.append(peptide)
        return peptides

    def get_fasta_entries(fp):
        name, seq = None, []
        for line in fp:
            line = line.rstrip()
            if line.startswith(">"):
                if name:
                    yield (name, ''.join(seq))
                name, seq = line, []
            else:
                seq.append(line)
        if name:
            yield (name, ''.join(seq))

    def read_fasta(filepath):
        peptides = []
        with open(filepath) as fp:
            for id, peptide in get_fasta_entries(fp):
                if not re.match(pep_pat, peptide):
                    warn_err('"%s" is not a peptide (id %s of fasta file: %s)\n' % (peptide, id, filepath), exit_code=invalid_ec)
                peptides.append(peptide)
        return peptides

    def read_mzid(fp):
        peptides = []
        for event, elem in ET.iterparse(fp):
            if event == 'end':
                if re.search('PeptideSequence', elem.tag):
                    peptides.append(elem.text)
        return peptides

    def read_pepxml(fp):
        peptides = []
        for event, elem in ET.iterparse(fp):
            if event == 'end':
                if re.search('search_hit', elem.tag):
                    peptides.append(elem.get('peptide'))
        return peptides

    def best_match(peptide, matches):
        if not matches:
            return None
        elif len(matches) == 1:
            return matches[0].copy()
        elif 'taxon_rank' in matches[0]:
            # find the most specific match (peptide is always the first column order field)
            for col in reversed(pept2lca_extra_column_order[1:]):
                col_id = col + "_id" if options.extra else col
                for match in matches:
                    if 'taxon_rank' in match and match['taxon_rank'] == col:
                        return match.copy()
                    if col_id in match and match[col_id]:
                        return match.copy()
        else:
            return sorted(matches, key=lambda x: len(x['peptide']))[-1].copy()
        return None

    def get_taxon_json(resp):
        found_keys = set()
        for i, pdict in enumerate(resp):
            found_keys |= set(pdict.keys())
        taxa_cols = []
        for col in pept2lca_extra_column_order[-1:0:-1]:
            if col + '_id' in found_keys:
                taxa_cols.append(col)
        id_to_node = dict()

        def get_node(id, name, rank, child, seq):
            if id not in id_to_node:
                data = {'count': 0, 'self_count': 0, 'valid_taxon': 1, 'rank': rank, 'sequences': []}
                node = {'id': id, 'name': name, 'children': [], 'kids': [], 'data': data}
                id_to_node[id] = node
            else:
                node = id_to_node[id]
            node['data']['count'] += 1
            if seq is not None and seq not in node['data']['sequences']:
                node['data']['sequences'].append(seq)
            if child is None:
                node['data']['self_count'] += 1
            elif child['id'] not in node['kids']:
                node['kids'].append(child['id'])
                node['children'].append(child)
            return node
        root = get_node(1, 'root', 'no rank', None, None)
        for i, pdict in enumerate(resp):
            sequence = pdict.get('peptide', pdict.get('tryptic_peptide', None))
            seq = sequence
            child = None
            for col in taxa_cols:
                col_id = col + '_id'
                if col_id in pdict and pdict.get(col_id):
                    col_name = col if col in found_keys else col + '_name'
                    child = get_node(pdict.get(col_id, None), pdict.get(col_name, ''), col, child, seq)
                    seq = None
            if child is not None:
                get_node(1, 'root', 'no rank', child, None)
        return root

    def get_ec_json(resp):
        ecMap = dict()
        for pdict in resp:
            if 'ec' in pdict:
                for ec in pdict['ec']:
                    ec_number = ec['ec_number']
                    if ec_number not in ecMap:
                        ecMap[ec_number] = []
                    ecMap[ec_number].append(pdict)

        def get_ids(ec):
            ids = []
            i = len(ec)
            while i >= 0:
                ids.append(ec[:i])
                i = ec.rfind('.', 0, i - 1)
            return ids
        id_to_node = dict()

        def get_node(id, name, child, seq):
            if id not in id_to_node:
                data = {'count': 0, 'self_count': 0, 'sequences': []}
                node = {'id': id, 'name': name, 'children': [], 'kids': [], 'data': data}
                id_to_node[id] = node
            else:
                node = id_to_node[id]
            node['data']['count'] += 1
            if seq is not None and seq not in node['data']['sequences']:
                node['data']['sequences'].append(seq)
            if child is None:
                node['data']['self_count'] += 1
            elif child['id'] not in node['kids']:
                node['kids'].append(child['id'])
                node['children'].append(child)
            return node
        root = get_node(0, '-.-.-.-', None, None)
        for i in range(1, 7):
            child = get_node(str(i), '%s\n%s' % (str(i), ec_name_dict[str(i)]), None, None)
            get_node(0, '-.-.-.-', child, None)
        for i, pdict in enumerate(resp):
            sequence = pdict.get('peptide', pdict.get('tryptic_peptide', None))
            seq = sequence
            if 'ec' in pdict:
                for ec in pdict['ec']:
                    child = None
                    ec_number = ec['ec_number']
                    for ec_id in get_ids(ec_number):
                        ec_name = str(ec_id)
                        child = get_node(ec_id, ec_name, child, seq)
                        seq = None
                    if child:
                        get_node(0, '-.-.-.-', child, None)
        return root

    def get_taxon_dict(resp, column_order, extra=False, names=False):
        found_keys = set()
        results = []
        for i, pdict in enumerate(resp):
            results.append(pdict)
            found_keys |= set(pdict.keys())
            # print >> sys.stderr, "%s\n%s" % (pdict.keys(), found_keys)
        column_names = []
        column_keys = []
        for col in column_order:
            if col in found_keys:
                column_names.append(col)
                column_keys.append(col)
            elif names:
                col_id = col + '_id'
                col_name = col + '_name'
                if extra:
                    if col_id in found_keys:
                        column_names.append(col_id)
                        column_keys.append(col_id)
                if names:
                    if col_name in found_keys:
                        column_names.append(col)
                        column_keys.append(col_name)
            else:
                if col + '_name' in found_keys:
                    column_names.append(col)
                    column_keys.append(col + '_name')
                elif col + '_id' in found_keys:
                    column_names.append(col)
                    column_keys.append(col + '_id')
        # print >> sys.stderr, "%s\n%s" % (column_names, column_keys)
        taxa = dict()  # peptide: [taxonomy]
        for i, pdict in enumerate(results):
            peptide = pdict['peptide'] if 'peptide' in pdict else None
            if peptide and peptide not in taxa:
                vals = [str(pdict[x]) if x in pdict and pdict[x] else '' for x in column_keys]
                taxa[peptide] = vals
        return (taxa, column_names)

    def get_ec_dict(resp, extra=False):
        ec_cols = ['ec_numbers', 'ec_protein_counts']
        if extra:
            ec_cols.append('ec_names')
        ec_dict = dict()
        for i, pdict in enumerate(resp):
            peptide = pdict['peptide']
            ec_numbers = []
            protein_counts = []
            ec_names = []
            if 'ec' in pdict:
                for ec in pdict['ec']:
                    ec_numbers.append(ec['ec_number'])
                    protein_counts.append(str(ec['protein_count']))
                    if extra:
                        ec_names.append(ec['name'] if 'name' in ec and ec['name'] else '')
            vals = [','.join(ec_numbers), ','.join(protein_counts)]
            if extra:
                vals.append(','.join(ec_names))
            ec_dict[peptide] = vals
        return (ec_dict, ec_cols)

    def get_go_dict(resp, extra=False):
        go_cols = ['go_terms', 'go_protein_counts']
        if extra:
            go_cols.append('go_names')
        go_dict = dict()
        for i, pdict in enumerate(resp):
            peptide = pdict['peptide']
            go_terms = []
            protein_counts = []
            go_names = []
            if 'go' in pdict:
                for go in pdict['go']:
                    if 'go_term' in go:
                        go_terms.append(go['go_term'])
                        protein_counts.append(str(go['protein_count']))
                        if extra:
                            go_names.append(go['name'] if 'name' in go and go['name'] else '')
                    else:
                        for go_type in go_types:
                            if go_type in go:
                                for _go in go[go_type]:
                                    go_terms.append(_go['go_term'])
                                    protein_counts.append(str(_go['protein_count']))
                                    if extra:
                                        go_names.append(_go['name'] if 'name' in _go and _go['name'] else '')
            vals = [','.join(go_terms), ','.join(protein_counts)]
            if extra:
                vals.append(','.join(go_names))
            go_dict[peptide] = vals
        return (go_dict, go_cols)

    def get_ipr_dict(resp, extra=False):
        ipr_cols = ['ipr_codes', 'ipr_protein_counts']
        if extra:
            ipr_cols.append('ipr_types')
            ipr_cols.append('ipr_names')
        ipr_dict = dict()
        for i, pdict in enumerate(resp):
            peptide = pdict['peptide']
            ipr_codes = []
            protein_counts = []
            ipr_names = []
            ipr_types = []
            if 'ipr' in pdict:
                for ipr in pdict['ipr']:
                    if 'code' in ipr:
                        ipr_codes.append(ipr['code'])
                        protein_counts.append(str(ipr['protein_count']))
                        if extra:
                            ipr_types.append(ipr['type'] if 'type' in ipr else '')
                            ipr_names.append(ipr['name'] if 'name' in ipr else '')
                    else:
                        for ipr_type in ipr_types:
                            if ipr_type in ipr:
                                for _ipr in ipr[ipr_type]:
                                    ipr_codes.append(_ipr['code'])
                                    protein_counts.append(str(_ipr['protein_count']))
                                    if extra:
                                        ipr_types.append(ipr_type)
                                        ipr_names.append(_ipr['name'] if 'name' in _ipr else '')
            vals = [','.join(ipr_codes), ','.join(protein_counts)]
            if extra:
                vals.append(','.join(ipr_types))
                vals.append(','.join(ipr_names))
            ipr_dict[peptide] = vals
        return (ipr_dict, ipr_cols)

    def write_ec_table(outfile, resp, column_order):
        with open(outfile, 'w') as fh:
            for i, pdict in enumerate(resp):
                if 'ec' in pdict:
                    tvals = [str(pdict[x]) if x in pdict and pdict[x] else '' for x in column_order[0]]
                    for ec in pdict['ec']:
                        vals = [str(ec[x]) if x in ec and ec[x] else '' for x in column_order[-1]]
                        fh.write('%s\n' % '\t'.join(tvals + vals))

    def write_go_table(outfile, resp, column_order):
        with open(outfile, 'w') as fh:
            for i, pdict in enumerate(resp):
                if 'go' in pdict:
                    tvals = [str(pdict[x]) if x in pdict and pdict[x] else '' for x in column_order[0]]
                    for go in pdict['go']:
                        if 'go_term' in go:
                            vals = [str(go[x]) if x in go and go[x] else '' for x in column_order[-1]]
                            fh.write('%s\n' % '\t'.join(tvals + vals))
                        else:
                            for go_type in go_types:
                                if go_type in go:
                                    for _go in go[go_type]:
                                        vals = [str(_go[x]) if x in _go and _go[x] else '' for x in column_order[-1]]
                                        vals.append(go_type)
                                        fh.write('%s\n' % '\t'.join(tvals + vals))

    def write_ipr_table(outfile, resp, column_order):
        with open(outfile, 'w') as fh:
            for i, pdict in enumerate(resp):
                if 'ipr' in pdict:
                    tvals = [str(pdict[x]) if x in pdict and pdict[x] else '' for x in column_order[0]]
                    for ipr in pdict['ipr']:
                        if 'code' in ipr:
                            vals = [str(ipr[x]) if x in ipr and ipr[x] else '' for x in column_order[-1]]
                            fh.write('%s\n' % '\t'.join(tvals + vals))
                        else:
                            for ipr_type in ipr_types:
                                if ipr_type in ipr:
                                    for _ipr in ipr[ipr_type]:
                                        vals = [str(_ipr[x]) if x in _ipr and _ipr[x] else '' for x in column_order[-1]]
                                        vals.append(ipr_type)
                                        fh.write('%s\n' % '\t'.join(tvals + vals))

    # Parse Command Line
    parser = optparse.OptionParser()
    # unipept API choice
    parser.add_option('-a', '--api', dest='unipept', default='pept2lca', choices=['pept2lca', 'pept2taxa', 'pept2prot', 'pept2ec', 'pept2go', 'pept2interpro', 'pept2funct', 'peptinfo'],
                      help='The unipept application: pept2lca, pept2taxa, pept2prot, pept2ec, pept2go, pept2funct, or peptinfo')
    # input files
    parser.add_option('-t', '--tabular', dest='tabular', default=None, help='A tabular file that contains a peptide column')
    parser.add_option('-c', '--column', dest='column', type='int', default=0, help='The column (zero-based) in the tabular file that contains peptide sequences')
    parser.add_option('-f', '--fasta', dest='fasta', default=None, help='A fasta file containing peptide sequences')
    parser.add_option('-m', '--mzid', dest='mzid', default=None, help='A mxIdentML file containing peptide sequences')
    parser.add_option('-p', '--pepxml', dest='pepxml', default=None, help='A pepxml file containing peptide sequences')
    # Unipept Flags
    parser.add_option('-e', '--equate_il', dest='equate_il', action='store_true', default=False, help='isoleucine (I) and leucine (L) are equated when matching tryptic peptides to UniProt records')
    parser.add_option('-x', '--extra', dest='extra', action='store_true', default=False, help='return the complete lineage of the taxonomic lowest common ancestor')
    parser.add_option('-n', '--names', dest='names', action='store_true', default=False, help='return the names of all ranks in the lineage of the taxonomic lowest common ancestor')
    parser.add_option('-D', '--domains', dest='domains', action='store_true', default=False, help='group response by GO namaspace: biological process, molecular function, cellular component')
    parser.add_option('-M', '--max_request', dest='max_request', type='int', default=200, help='The maximum number of entries per unipept request')

    # output fields
    parser.add_option('-A', '--allfields', dest='allfields', action='store_true', default=False, help='inlcude fields: taxon_rank,taxon_id,taxon_name csv and tsv outputs')
    # Warn vs Error Flag
    parser.add_option('-S', '--strict', dest='strict', action='store_true', default=False, help='Print exit on invalid peptide')
    # output files
    parser.add_option('-J', '--json', dest='json', default=None, help='Output file path for json formatted results')
    parser.add_option('-j', '--ec_json', dest='ec_json', default=None, help='Output file path for json formatted results')
    parser.add_option('-E', '--ec_tsv', dest='ec_tsv', default=None, help='Output file path for EC TAB-separated-values (.tsv) formatted results')
    parser.add_option('-G', '--go_tsv', dest='go_tsv', default=None, help='Output file path for GO TAB-separated-values (.tsv) formatted results')
    parser.add_option('-I', '--ipr_tsv', dest='ipr_tsv', default=None, help='Output file path for InterPro TAB-separated-values (.tsv) formatted results')
    parser.add_option('-L', '--lineage_tsv', dest='lineage_tsv', default=None, help='Output file path for Lineage TAB-separated-values (.tsv) formatted results')
    parser.add_option('-T', '--tsv', dest='tsv', default=None, help='Output file path for TAB-separated-values (.tsv) formatted results')
    parser.add_option('-C', '--csv', dest='csv', default=None, help='Output file path for Comma-separated-values (.csv) formatted results')
    parser.add_option('-U', '--unmatched', dest='unmatched', default=None, help='Output file path for peptide with no matches')
    parser.add_option('-u', '--url', dest='url', default='https://api.unipept.ugent.be/api/v1/', help='unipept url https://api.unipept.ugent.be/api/v1/')
    parser.add_option('-P', '--peptide_match', dest='peptide_match', choices=['best', 'full', 'report'], default='best', help='Match whole peptide')
    parser.add_option('--unmatched_aa', dest='unmatched_aa', default=None, help='Show unmatched AA in peptide as')
    # debug
    parser.add_option('-g', '--get', dest='get', action='store_true', default=False, help='Use GET instead of POST')
    parser.add_option('-d', '--debug', dest='debug', action='store_true', default=False, help='Turning on debugging')
    parser.add_option('-v', '--version', dest='version', action='store_true', default=False, help='print version and exit')
    (options, args) = parser.parse_args()
    if options.version:
        print('%s' % version)
        sys.exit(0)

    def tryptic_match_string(peptide, tryptic_matches):
        if options.unmatched_aa:
            p = peptide.lower()
            for m in tryptic_matches:
                p = p.replace(m.lower(), m)
            return re.sub('[a-z]', options.unmatched_aa, p)
        else:
            return ','.join(tryptic_matches)

    invalid_ec = 2 if options.strict else None
    peptides = []
    # Get peptide sequences
    if options.mzid:
        peptides += read_mzid(options.mzid)
    if options.pepxml:
        peptides += read_pepxml(options.pepxml)
    if options.tabular:
        peptides += read_tabular(options.tabular, options.column)
    if options.fasta:
        peptides += read_fasta(options.fasta)
    if args and len(args) > 0:
        for i, peptide in enumerate(args):
            if not re.match(pep_pat, peptide):
                warn_err('"%s" is not a peptide (arg %d)\n' % (peptide, i), exit_code=invalid_ec)
            peptides.append(peptide)
    if len(peptides) < 1:
        warn_err("No peptides input!", exit_code=1)
    column_order = pept2lca_column_order
    if options.unipept == 'pept2prot':
        column_order = pept2prot_extra_column_order if options.extra else pept2prot_column_order
    else:
        if options.extra or options.names:
            column_order = pept2lca_all_column_order if options.allfields else pept2lca_extra_column_order
        else:
            column_order = pept2lca_column_order
    # map to tryptic peptides
    if options.peptide_match == 'full':
        pepToParts = {p: [p] for p in peptides}
    else:
        pepToParts = {p: re.split('\n', re.sub(r'(?<=[RK])(?=[^P])', '\n', p)) for p in peptides}
    if options.debug:
        print("column_order: %s\n" % (column_order), file=sys.stderr)
    partToPeps = {}
    for peptide, parts in pepToParts.items():
        if options.debug:
            print("peptide: %s\ttryptic: %s\n" % (peptide, parts), file=sys.stderr)
        for part in parts:
            if len(part) > 50:
                warn_err("peptide: %s tryptic fragment len %d > 50 for %s\n" % (peptide, len(part), part), exit_code=None)
            if 5 <= len(part) <= 50:
                partToPeps.setdefault(part, []).append(peptide)
    trypticPeptides = list(partToPeps.keys())
    # unipept
    unipept_resp = []
    idx = list(range(0, len(trypticPeptides), options.max_request))
    idx.append(len(trypticPeptides))
    for i in range(len(idx) - 1):
        post_data = []
        if options.equate_il:
            post_data.append(('equate_il', 'true'))
        else:
            post_data.append(('equate_il', 'false'))
        if options.names or options.json:
            post_data.append(('extra', 'true'))
            post_data.append(('names', 'true'))
        elif options.extra or options.json:
            post_data.append(('extra', 'true'))
        if options.domains:
            post_data.append(('domains', 'true'))
        post_data += [('input[]', x) for x in trypticPeptides[idx[i]:idx[i + 1]]]
        if options.debug:
            print('post_data: %s\n' % (str(post_data)), file=sys.stderr)
        headers = {'Content-Type': 'application/x-www-form-urlencoded', 'Accept': 'application/json'}
        url = '%s/%s' % (options.url.rstrip('/'), options.unipept)
        if options.get:
            params = '&'.join(["%s=%s" % (i[0], i[1]) for i in post_data])
            url = '%s.json?%s' % (url, params)
            req = urllib.request.Request(url)
        else:
            url = '%s.json' % (url)
            data = urllib.parse.urlencode(post_data).encode()
            params = '&'.join(["%s=%s" % (i[0], i[1]) for i in post_data])
            if options.debug:
                print('data:\n%s\n' % (data), file=sys.stderr)
            req = urllib.request.Request(url, headers=headers, data=urllib.parse.urlencode(post_data).encode(), method='POST')
        if options.debug:
            print("url: %s\n" % (str(url)), file=sys.stderr)
        try:
            resp = urllib.request.urlopen(req)
            rdata = resp.read()
            if options.debug:
                print("%s %s\n" % (url, str(resp.getcode())), file=sys.stderr)
            if resp.getcode() == 200:
                if options.debug:
                    print("rdata: \n%s\n\n" % (rdata), file=sys.stderr)
                unipept_resp += json.loads(rdata)
                # unipept_resp += json.loads(urllib.request.urlopen(req).read())
        except Exception as e:
            warn_err('HTTP Error %s\n' % (str(e)), exit_code=None)
    unmatched_peptides = []
    peptideMatches = []
    if options.debug:
        print("unipept response: %s\n" % str(unipept_resp), file=sys.stderr)
    if options.unipept in ['pept2prot', 'pept2taxa']:
        dupkey = 'uniprot_id' if options.unipept == 'pept2prot' else 'taxon_id'  # should only keep one of these per input peptide
        # multiple entries per trypticPeptide for pep2prot or pep2taxa
        mapping = {}
        for match in unipept_resp:
            mapping.setdefault(match['peptide'], []).append(match)
        for peptide in peptides:
            # Get the intersection of matches to the tryptic parts
            keyToMatch = None
            tryptic_match = []
            for part in pepToParts[peptide]:
                if part in mapping:
                    tryptic_match.append(part)
                    temp = {match[dupkey]: match for match in mapping[part]}
                    if keyToMatch:
                        dkeys = set(keyToMatch.keys()) - set(temp.keys())
                        for k in dkeys:
                            del keyToMatch[k]
                    else:
                        keyToMatch = temp
                    # keyToMatch = keyToMatch.fromkeys([x for x in keyToMatch if x in temp]) if keyToMatch else temp
            if not keyToMatch:
                unmatched_peptides.append(peptide)
            else:
                for key, match in keyToMatch.items():
                    match['tryptic_match'] = tryptic_match_string(peptide, tryptic_match)
                    match['tryptic_peptide'] = match['peptide']
                    match['peptide'] = peptide
                    peptideMatches.append(match)
    elif options.unipept in ['pept2lca', 'peptinfo']:
        # should be one response per trypticPeptide for pep2lca
        respMap = {v['peptide']: v for v in unipept_resp}
        # map resp back to peptides
        for peptide in peptides:
            matches = list()
            tryptic_match = []
            for part in pepToParts[peptide]:
                if part in respMap:
                    tryptic_match.append(part)
                    matches.append(respMap[part])
            match = best_match(peptide, matches)
            if not match:
                unmatched_peptides.append(peptide)
                longest_tryptic_peptide = sorted(pepToParts[peptide], key=lambda x: len(x))[-1]
                match = {'peptide': longest_tryptic_peptide}
            match['tryptic_match'] = tryptic_match_string(peptide, tryptic_match)
            match['tryptic_peptide'] = match['peptide']
            match['peptide'] = peptide
            peptideMatches.append(match)
    else:
        respMap = {v['peptide']: v for v in unipept_resp}
        # map resp back to peptides
        for peptide in peptides:
            matches = list()
            tryptic_match = []
            for part in pepToParts[peptide]:
                if part in respMap and 'total_protein_count' in respMap[part]:
                    tryptic_match.append(part)
                    matches.append(respMap[part])
            match = best_match(peptide, matches)
            if not match:
                unmatched_peptides.append(peptide)
                longest_tryptic_peptide = sorted(pepToParts[peptide], key=lambda x: len(x))[-1]
                match = {'peptide': longest_tryptic_peptide}
            match['tryptic_match'] = tryptic_match_string(peptide, tryptic_match)
            match['tryptic_peptide'] = match['peptide']
            match['peptide'] = peptide
            peptideMatches.append(match)
    resp = peptideMatches
    if options.debug:
        print("\nmapped response: %s\n" % str(resp), file=sys.stderr)
    # output results
    if not (options.unmatched or options.json or options.tsv or options.csv):
        print(str(resp))
    if options.unmatched:
        with open(options.unmatched, 'w') as outputFile:
            for peptide in peptides:
                if peptide in unmatched_peptides:
                    outputFile.write("%s\n" % peptide)
    if options.json:
        if options.unipept in ['pept2lca', 'pept2taxa', 'peptinfo']:
            root = get_taxon_json(resp)
            with open(options.json, 'w') as outputFile:
                outputFile.write(json.dumps(root))
        elif options.unipept in ['pept2prot', 'pept2ec', 'pept2go', 'pept2interpro', 'pept2funct']:
            with open(options.json, 'w') as outputFile:
                outputFile.write(str(resp))
    if options.ec_json:
        if options.unipept in ['pept2ec', 'pept2funct', 'peptinfo']:
            root = get_ec_json(resp)
            with open(options.ec_json, 'w') as outputFile:
                outputFile.write(json.dumps(root))
    if options.tsv or options.csv:
        rows = []
        column_names = None
        if options.unipept in ['pept2ec', 'pept2go', 'pept2interpro', 'pept2funct', 'peptinfo']:
            taxa = None
            ec_dict = None
            go_dict = None
            ipr_dict = None
            if options.unipept in ['peptinfo']:
                (taxa, taxon_cols) = get_taxon_dict(resp, column_order, extra=options.extra, names=options.names)
            if options.unipept in ['pept2ec', 'pept2funct', 'peptinfo']:
                (ec_dict, ec_cols) = get_ec_dict(resp, extra=options.extra)
            if options.unipept in ['pept2go', 'pept2funct', 'peptinfo']:
                (go_dict, go_cols) = get_go_dict(resp, extra=options.extra)
            if options.unipept in ['pept2interpro', 'pept2funct', 'peptinfo']:
                (ipr_dict, ipr_cols) = get_ipr_dict(resp, extra=options.extra)
            for i, pdict in enumerate(resp):
                peptide = pdict['peptide']
                total_protein_count = str(pdict['total_protein_count']) if 'total_protein_count' in pdict else '0'
                column_names = ['peptide', 'total_protein_count']
                vals = [peptide, total_protein_count]
                if options.peptide_match == 'report':
                    column_names = ['peptide', 'tryptic_match', 'total_protein_count']
                    tryptic_match = pdict.get('tryptic_match', '')
                    vals = [peptide, tryptic_match, total_protein_count]
                if ec_dict:
                    vals += ec_dict[peptide]
                    column_names += ec_cols
                if go_dict:
                    vals += go_dict[peptide]
                    column_names += go_cols
                if ipr_dict:
                    vals += ipr_dict[peptide]
                    column_names += ipr_cols
                if taxa:
                    vals += taxa[peptide][1:]
                    column_names += taxon_cols[1:]
                rows.append(vals)
        elif options.unipept in ['pept2lca', 'pept2taxa', 'pept2prot']:
            if options.peptide_match == 'report':
                column_order.insert(1, 'tryptic_match')
            (taxa, taxon_cols) = get_taxon_dict(resp, column_order, extra=options.extra, names=options.names)
            column_names = taxon_cols
            rows = list(taxa.values())
        if options.tsv:
            with open(options.tsv, 'w') as outputFile:
                if column_names:
                    outputFile.write("#%s\n" % '\t'.join(column_names))
                for vals in rows:
                    outputFile.write("%s\n" % '\t'.join(vals))
        if options.csv:
            with open(options.csv, 'w') as outputFile:
                if column_names:
                    outputFile.write("%s\n" % ','.join(column_names))
                for vals in rows:
                    outputFile.write("%s\n" % ','.join(['"%s"' % (v if v else '') for v in vals]))
    if options.ec_tsv and options.unipept in ['pept2ec', 'pept2funct', 'peptinfo']:
        column_order = pept2ec_extra_column_order if options.extra else pept2ec_column_order
        write_ec_table(options.ec_tsv, resp, column_order)
    if options.go_tsv and options.unipept in ['pept2go', 'pept2funct', 'peptinfo']:
        column_order = pept2go_extra_column_order if options.extra else pept2go_column_order
        write_go_table(options.go_tsv, resp, column_order)
    if options.ipr_tsv and options.unipept in ['pept2interpro', 'pept2funct', 'peptinfo']:
        column_order = pept2interpro_extra_column_order if options.extra else pept2interpro_column_order
        write_ipr_table(options.ipr_tsv, resp, column_order)


if __name__ == "__main__":
    __main__()
