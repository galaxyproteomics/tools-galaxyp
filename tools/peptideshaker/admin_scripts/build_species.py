#!/usr/bin/env python

import sys

for line in open(sys.argv[1]):
    line = line.strip()
    if line and not line.startswith('>'):
        name, id = line.split('\t')
        line = '<option value="%s">%s</option>' % (name, name)
    print(line)
