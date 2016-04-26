"""
Usage:
python hardklor.py ms1extenstion ms2extension ms1file
ms2file outputfile
"""
import sys
import os
import subprocess


CONFIG_FILE = 'hk.conf'
extension_lookup = {
    'mzml'  :   'mzML',
    'mzxml' :   'mzXML',
    'ms1'   :   'MS1',
    }

# input:
ms1_ext = sys.argv[1]
ms1_file = sys.argv[2]
output_file = sys.argv[3]
config_load = os.path.join(os.path.split(sys.argv[0])[0], 'hardklor.conf')

# parse options
options = {}
for arg in [x.split('=') for x in sys.argv[4:]]:
    if arg[1] != '':
        options[arg[0].replace('-', '')] = arg[1]


# create softlinks since hardklor needs "proper" extensions for input files
if ms1_ext in extension_lookup:
    ms1_ext = extension_lookup[ms1_ext]
    linkname = 'ms1_dsetlink.{0}'.format(ms1_ext)
    os.symlink(ms1_file, linkname)
    ms1_file = linkname 

# load template and dump to config file
with open(config_load) as fp:
    config_str = fp.read()
config_to_dump = config_str.format(
    instrument=options['instrument'],
    resolution=options['resolution'],
    centroided=options['centroided'],
    mslvl=options['mslvl'],
    depth=options['depth'],
    algorithm=options['algorithm'],
    charge_algo=options['charge_algo'],
    mincharge=options['mincharge'],
    maxcharge=options['maxcharge'],
    correlation=options['correlation'],
    sensitivity=options['sensitivity'],
    maxfeat=options['maxfeat'],
    inputfile=ms1_file,
    outputfile=output_file,
    )
with open(CONFIG_FILE, 'w') as fp:
    fp.write(config_to_dump)

# Run hardklor
err = subprocess.call(['hardklor', CONFIG_FILE])
sys.exit(err)
