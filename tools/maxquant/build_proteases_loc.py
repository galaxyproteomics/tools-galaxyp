#!/usr/bin/env python

import xml.etree.ElementTree as ET
from os.path import exists

proteases_path = "proteases.xml"

tree = ET.parse(proteases_path)
proteases_el = tree.getroot()

with open("maxquant_proteases.loc", "w") as output:
    for protease in proteases_el.getchildren():
        output.write("%s\n" % protease.attrib["name"])

