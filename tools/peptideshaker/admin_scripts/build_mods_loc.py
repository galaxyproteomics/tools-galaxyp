#!/usr/bin/env python

import xml.etree.ElementTree as ET
from os.path import exists

with open("searchgui_mods.loc.sample", "w") as output:
    for mods_path in ["searchGUI_mods.xml", "searchGUI_usermods.xml"]:
        tree = ET.parse(mods_path)
        modifications_el = tree.getroot()
        for mod in modifications_el.findall("{http://www.ncbi.nlm.nih.gov}MSModSpec"):
            name_el = mod.find("{http://www.ncbi.nlm.nih.gov}MSModSpec_name")
            output.write("%s\n" % name_el.text.lower())
