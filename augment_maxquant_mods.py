#!/usr/bin/env python
"""
Usage:
    python augment_maxquant_mods.py

Assuming Unimod XML file (unimod.xml) and stock MaxQuant modifications
file (modifications.xml) are in this same directory, this script will
create a new MaxQuant modifications file (extended_modifications.xml)
with an a new modification for each unimod entry. These new entires
will be suffixed with [Unimod] to distinguish them from existing
MaxQuant entries. This file should be copied to
<MaxQuant Path>\bin\conf\modifications.xml

"""
import xml.etree.ElementTree as ET
import re

FAKE_DATE = "2012-06-11T21:21:24.4946343+02:00"

POSITION_MAP = {
    "Anywhere": "anywhere",
    "Any N-term": "anyNterm",
    "Any C-term": "anyCterm",
    "Protein N-term": "proteinNterm",
    "Protein C-term": "proteinCterm",
}

unimod_tree = ET.parse('unimod.xml')
unimod_ns = '{http://www.unimod.org/xmlns/schema/unimod_2}'
unimod_modifications_el = unimod_tree.getroot().find('%smodifications' % unimod_ns)
mq_tree = ET.parse("modifications.xml")
mq_root = mq_tree.getroot()


def to_label(title, site):
    return "%s (%s) [Unimod]" % (title, site)


def copy_modification(unimod_modification):
    if unimod_modification.hidden:
        return False
    if unimod_modification.delta_el is None:
        return False
    comp_array = unimod_modification.composition_array
    for aa, count in comp_array:
        if len(aa) > 1 and aa not in COMP_REPLACES.keys():
            # Complex stuff like Hep, that I cannot translate into MaxQuant.
            return False
    return True


COMP_REPLACES = {
    "15N": "Nx",
    "13C": "Cx",
    "18O": "Ox",
    "2H": "Hx",
}

## HEP?


def convert_composition(unimod_composition):
    """
    Convert Unimod representation of composition to MaxQuant
    """
    composition = unimod_composition
    for key, value in COMP_REPLACES.iteritems():
        composition = composition.replace(key, value)
    print composition
    return composition


def populate_modification(modification, unimod_modification):
    """
    Copy unimod entry ``unimod_modification`` to MaxQuant entry ``modification``.
    """
    attrib = modification.attrib
    attrib["create_date"] = FAKE_DATE
    attrib["last_modified_date"] = FAKE_DATE
    attrib["reporterCorrectionM1"] = str(0)
    attrib["reporterCorrectionM2"] = str(0)
    attrib["reporterCorrectionP1"] = str(0)
    attrib["reporterCorrectionP2"] = str(0)
    attrib["user"] = "build_mods_script"
    label = unimod_modification.label
    attrib["title"] = label
    attrib["description"] = label
    attrib["composition"] = convert_composition(unimod_modification.raw_composition)
    unimod_position = unimod_modification.position
    maxquant_position = POSITION_MAP[unimod_position]
    assert maxquant_position != None
    position_el = ET.SubElement(modification, "position")
    position_el.text = maxquant_position
    modification_site_el = ET.SubElement(modification, "modification_site")
    modification_site_el.attrib["index"] = "0"
    unimod_site = unimod_modification.site
    modification_site_el.attrib["site"] = "-" if len(unimod_site) > 1 else unimod_site
    type_el = ET.SubElement(modification, "type")
    type_el.text = "standard"
    return modification


class UnimodModification:

    def __init__(self, modification, specificity):
        self.modification = modification
        self.specificity = specificity

    @property
    def title(self):
        return self.modification.attrib["title"]

    @property
    def site(self):
        return self.specificity.attrib["site"]

    @property
    def label(self):
        return "%s (%s) [Unimod]" % (self.title, self.site)

    @property
    def delta_el(self):
        return self.modification.find("%sdelta" % unimod_ns)

    @property
    def raw_composition(self):
        return self.delta_el.attrib["composition"]

    @property
    def composition_array(self):
        raw_composition = self.raw_composition
        aa_and_counts = re.split("\s+", raw_composition)
        comp_array = []
        for aa_and_count in aa_and_counts:
            match = re.match(r"(\w+)(\((-?\d+)\))?", aa_and_count)
            aa = match.group(1)
            count = match.group(3) or 1
            comp_array.append((aa, count))
        return comp_array

    @property
    def position(self):
        return self.specificity.attrib["position"]

    @property
    def hidden(self):
        return self.specificity.attrib["hidden"] == "true"

unimod_modifications = []
for mod in unimod_modifications_el.findall('%smod' % unimod_ns):
    for specificity in mod.findall('%sspecificity' % unimod_ns):
        unimod_modifications.append(UnimodModification(mod, specificity))

max_index = 0
for modification in mq_root.getchildren():
    index = int(modification.attrib["index"])
    max_index = max(max_index, index)

for unimod_modification in unimod_modifications:
    if copy_modification(unimod_modification):
        print unimod_modification.composition_array
        max_index += 1
        modification = ET.SubElement(mq_root, "modification", attrib={"index": str(max_index)})
        populate_modification(modification, unimod_modification)

mq_tree.write("extended_modifications.xml")
