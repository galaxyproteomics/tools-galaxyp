#!/usr/bin/env python

import xml.etree.ElementTree as ET
from os.path import exists

mods_path = "extended_modifications.xml"

if not exists(mods_path):
    mods_path = "modifications.xml"

tree = ET.parse(mods_path)
modifications_el = tree.getroot()

with open("maxquant_mods.loc", "w") as output:
    for mod in modifications_el.getchildren():
        if mod.find("type").text.strip() == "standard":
            output.write("%s\n" % mod.attrib["title"])
