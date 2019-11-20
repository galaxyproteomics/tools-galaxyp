#!/usr/bin/env python3
"""Initialize MaxQuant tool for use with a new version of
modifications/enzymes.xml.

TODO: Append function: only add modifications that are not
already present, add modification entries to conda maxquant

Usage: init.py [-m MODS_FILE] [-e ENZYMES_FILE]
FILES are the modifications/enzymes.xml of MaxQuant, located at
<ANACONDA_DIR>/pkgs/maxquant-<VERSION>/bin/conf/.
(for conda installations)

Updates modification parameters in macros.xml.
"""

import argparse
import re
import xml.etree.ElementTree as ET
from xml.dom import minidom


def build_list(node, name, mod_list, append=False):
    """Build the modifications list in macros.xml"""
    node.clear()
    node.tag = 'xml'
    node.set('name', name)
    for m in mod_list:
        ET.SubElement(node, 'expand', attrib={'macro': 'mod_option',
                                              'value': m})

parser = argparse.ArgumentParser()
parser.add_argument("-m", "--modifications",
                    help="modifications.xml of maxquant")
parser.add_argument("-e", "--enzymes",
                    help="enzymes.xml of maxquant")
args = parser.parse_args()

if args.modifications:
    mods_root = ET.parse(args.modifications).getroot()
    mods = mods_root.findall('modification')
    standard_mods = []
    label_mods = []
    iso_labels = []
    for m in mods:
        if (m.findtext('type') == 'Standard' or m.findtext('type') == 'AaSubstitution'):
            standard_mods.append(m.get('title'))
        elif m.findtext('type') == 'Label':
            label_mods.append(m.get('title'))
        elif m.findtext('type') == 'IsobaricLabel':
            iso_labels.append(m.get('title'))

if args.enzymes:
    enzymes_root = ET.parse(args.enzymes).getroot()
    enzymes = enzymes_root.findall('enzyme')
    enzymes_list = [e.get('title') for e in enzymes]

macros_root = ET.parse('./macros.xml').getroot()
for child in macros_root:
    if child.get('name') == 'modification' and args.modifications:
        build_list(child, 'modification', standard_mods)
    elif child.get('name') == 'label' and args.modifications:
        build_list(child, 'label', label_mods)
    elif child.get('name') == 'iso_labels' and args.modifications:
        build_list(child, 'iso_labels', iso_labels)
    elif child.get('name') == 'proteases' and args.enzymes:
        build_list(child, 'proteases', enzymes_list)

rough_string = ET.tostring(macros_root, 'utf-8')
reparsed = minidom.parseString(rough_string)
pretty = reparsed.toprettyxml(indent="    ")
even_prettier = re.sub(r"\n\s+\n", r"\n", pretty)
with open('./macros.xml', 'w') as f:
    print(even_prettier, file=f)
