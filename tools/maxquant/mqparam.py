"""
Create a project-specific MaxQuant parameter file.

TODO: add support for parameter groups
      add reporter ion MS2

Author: Damian Glaetzer <d.glaetzer@mailbox.org>
"""

import copy
import ntpath
import os
import re
import xml.etree.ElementTree as ET
from itertools import zip_longest
from xml.dom import minidom

def et_add_child(el, name, text, attrib=None):
    "Add a child element to an xml.etree.Element"
    child = ET.SubElement(el, name, attrib=attrib if attrib else {})
    child.text = str(text)


class ParamGroup:
    "Represents one parameter Group"

    def __init__(self, root):
        "Initialize with its xml.etree.ElementTree root Element."
        self.root = root
        
        
    def set_list_params(self, key, vals):
        """Set a list parameter.
        >>> t = MQParam(None, './test-data/template.xml', None)
        >>> t.set_list_params('proteases', ('test 1', 'test 2'))
        >>> len(t.root.find('.parameterGroups/parameterGroup/enzymes'))
        2
        >>> t.set_list_params('var_mods', ('Oxidation (M)', ))
        >>> var_mods = '.parameterGroups/parameterGroup/variableModifications'
        >>> t.root.find(var_mods)[0].text
        'Oxidation (M)'
        """
        
        # params = 'variableModifications','fixedModifications','enzymes'
        
        node = self.root[key]
        if node is None:
            raise ValueError('Element {} not found in parameter file'
                             .format(params[key]))
        node.clear()
        node.tag = key
        for e in vals:
            et_add_child(node, name='string', text=e)
                 
    def set_simple_param(self, key, value):
        """Set a simple parameter.
        >>> t = MQParam(None, './test-data/template.xml', None)
        >>> t.set_simple_param('min_unique_pep', 4)
        >>> t.root.find('.minUniquePeptides').text
        '4'
        """
        node = self.root[key]
        if node is None:
            raise ValueError('Element {} not found in parameter file'
                             .format(simple_params[key]))
        node.text = str(value)

    def set_silac(self, light_mods, medium_mods, heavy_mods):
        """Set label modifications.
        >>> t1 = MQParam('test', './test-data/template.xml', None)
        >>> t1.set_silac(None, ('test1', 'test2'), None)
        >>> t1.root.find('.parameterGroups/parameterGroup/maxLabeledAa').text
        '2'
        >>> t1.root.find('.parameterGroups/parameterGroup/multiplicity').text
        '3'
        >>> t1.root.find('.parameterGroups/parameterGroup/labelMods')[1].text
        'test1;test2'
        >>> t1.root.find('.parameterGroups/parameterGroup/labelMods')[2].text
        ''
        """
        multiplicity = 3 if medium_mods else 2 if heavy_mods else 1
        max_label = str(max(len(light_mods) if light_mods else 0,
                            len(medium_mods) if medium_mods else 0,
                            len(heavy_mods) if heavy_mods else 0))
        self.root['multiplicity'].text = str(multiplicity)
        self.root['maxLabeledAa'].text = max_label

        node = self.root['labelMods']
        node[0].text = ';'.join(light_mods) if light_mods else ''
        if multiplicity == 3:
            et_add_child(node, name='string', text=';'.join(medium_mods))
        if multiplicity > 1:
            et_add_child(node, name='string',
                               text=';'.join(heavy_mods) if heavy_mods else '')


class MQParam:
    """Represents a mqpar.xml and provides methods to modify
    some of its parameters.
    """

    fasta_template = """<FastaFileInfo>
    <fastaFilePath></fastaFilePath>
    <identifierParseRule></identifierParseRule>
    <descriptionParseRule></descriptionParseRule>
    <taxonomyParseRule></taxonomyParseRule>
    <variationParseRule></variationParseRule>
    <modificationParseRule></modificationParseRule>
    <taxonomyId></taxonomyId>
    </FastaFileInfo>"""

    def __init__(self, mqpar_out, mqpar_in, exp_design,
                 substitution_rx=r'[^\s\S]'):  # no sub by default
        """Initialize MQParam class. mqpar_in can either be a template
        or a already suitable mqpar file.
        >>> t = MQParam("test", './test-data/template.xml', None)
        >>> t.root.tag
        'MaxQuantParams'
        >>> (t.root.find('maxQuantVersion')).text
        '1.6.3.4'
        """

        self.orig_mqpar = mqpar_in
        self.exp_design = exp_design
        self.mqpar_out = mqpar_out
        self.root = ET.parse(mqpar_in).getroot()
        self.version = self.root.find('maxQuantVersion').text
        # regex for substitution of certain file name characters
        self.substitution_rx = substitution_rx
        self._paramGroupTemplate = copy.deepcopy(self.root['parameterGroups']
                                                 ['parameterGroup'])
        self._paramGroups = []

    @staticmethod
    def _check_validity(design, len_infiles):
        "Perform some checks on the exp. design template"
        design_len = len(design['Name'])
        match = len(list(filter(lambda x: bool(x), design['Name'])))
        if match < len_infiles:
            raise Exception("Error parsing experimental design template: " +
                            "Found only {} matching entries ".format(design_len) +
                            "for {} input files".format(len_infiles))
        for i in range(0, design_len):
            msg = "Error in line " + str(i + 2) + " of experimental design: "
            if not (design['Name'][i] and design['Experiment'][i]):
                raise Exception(msg + " Name or Experiment is empty.")
            if design['PTM'][i].lower() not in ('true', 'false'):
                raise Exception(msg + "Defines invalid PTM value, " +
                                "should be 'True' or 'False'.")
            try:
                int(design['Fraction'][i])
            except ValueError as e:
                raise Exception(msg + str(e))

    def _make_exp_design(self, infiles):
        """Create a dict representing an experimental design from
        an experimental design template and a list of input files.
        If the experimental design template is None, create a default
        design with one experiment for each input file, no fractions and
        parameter group 0 for all files.
        >>> t2 = MQParam("test", './test-data/template.xml', \
                         './test-data/two/exp_design_template.txt')
        >>> design = t2._make_exp_design(['./test-data/BSA_min_21.mzXML', \
                                          './test-data/BSA_min_22.mzXML'])
        >>> design['Name']
        ['./test-data/BSA_min_21.mzXML', './test-data/BSA_min_22.mzXML']
        >>> design['Fraction']
        ['1', '2']
        """

        design = {s: [] for s in ("Name", "PTM", "Fraction", "Experiment")}
        if not self.exp_design:
            design["Name"] = infiles
            design["Fraction"] = ('32767',) * len(infiles)
            design["Experiment"] = [os.path.split(f)[1] for f in infiles]
            design["PTM"] = ('False',) * len(infiles)
        else:
            with open(self.exp_design) as design_file:
                index_line = design_file.readline().strip()
                index = []
                for i in index_line.split('\t'):
                    if i in design:
                        index.append(i)
                    else:
                        raise Exception("Invalid column index in experimental"
                                        + " design template: {}".format(i))

                for line in design_file:
                    row = line.strip().split('\t')
                    for e, i in zip_longest(row, index):
                        if i == "Fraction" and e == '':
                            e = 32767
                        elif i == "PTM" and not e:
                            e = 'False'
                        design[i].append(e)

            # map infiles to names in exp. design template
            names = []
            names_to_paths = {}
            # strip path and extension
            for f in infiles:
                b = os.path.basename(f)
                basename = b[:-6] if b.endswith('.mzXML') else b[:-11]
                names_to_paths[basename] = f
            for name in design['Name']:
                # same substitution as in maxquant.xml,
                # when passing the element identifiers
                fname = re.sub(self.substitution_rx, '_', name)
                names.append(names_to_paths[fname] if fname in names_to_paths
                             else None)
            # replace orig. file names with matching links to galaxy datasets
            design['Name'] = names
            MQParam._check_validity(design, len(infiles))

        return design

    def add_infiles(self, infiles, interactive):
        """Add a list of raw/mzxml files to the mqpar.xml.
        If experimental design template was specified,
        modify other parameters accordingly.
        The files must be specified as absolute paths
        for maxquant to find them.
        >>> t1 = MQParam("test", './test-data/template.xml', None)
        >>> t1.add_infiles(('test1', ), True)
        >>> t1.root.find("filePaths")[0].text
        'test1'
        >>> t1.root.find("fractions")[0].text
        '32767'
        >>> len(t1.root.find("fractions"))
        1
        >>> t2 = MQParam("test", './test-data/template.xml', \
                         './test-data/exp_design_test.txt')
        >>> t2.add_infiles(('test-data/QEplus021874.thermo.raw', \
                             'test-data/QEplus021876.thermo.raw'), True)
        >>> len(t2.root.find("filePaths"))
        2
        >>> t2.root.find("filePaths")[1].text
        'test-data/QEplus021876.thermo.raw'
        >>> t2.root.find("experiments")[1].text
        '2'
        >>> t2.root.find("fractions")[0].text
        '3'
        """

        # Create experimental design for interactive mode.
        # In non-interactive mode only filepaths are modified, but
        # their order from the original mqpar must be kept.
        if interactive:
            index = range(len(infiles))
            nodenames = ('filePaths', 'experiments', 'fractions',
                         'ptms', 'paramGroupIndices', 'referenceChannel')
            design = self._make_exp_design(infiles)
        else:
            index = [-1] * len(infiles)
            # kind of a BUG: fails if filename starts with '.'
            infilenames = [os.path.basename(f).split('.')[0] for f in infiles]
            i = 0
            for child in self.root.find('filePaths'):
                # either windows or posix path
                win = ntpath.basename(child.text)
                posix = os.path.basename(child.text)
                basename = win if len(win) < len(posix) else posix
                basename_with_sub = re.sub(self.substitution_rx, '_',
                                           basename.split('.')[0])
                # match infiles to their names in mqpar.xml,
                # ignore files missing in mqpar.xml
                if basename_with_sub in infilenames:
                    index[i] = infilenames.index(basename_with_sub)
                    i += 1
                else:
                    raise ValueError("no matching infile found for "
                                     + child.text)

            nodenames = ('filePaths', )
            design = {'Name': infiles}

        # Get parent nodes from document
        nodes = dict()
        for nodename in nodenames:
            node = self.root.find(nodename)
            if node is None:
                raise ValueError('Element {} not found in parameter file'
                                 .format(nodename))
            nodes[nodename] = node
            node.clear()
            node.tag = nodename

        # Append sub-elements to nodes (one per file)
        for i in index:
            if i > -1 and design['Name'][i]:
                et_add_child(nodes['filePaths'], 'string',
                                   design['Name'][i])
                if interactive:
                    et_add_child(nodes['experiments'], 'string',
                                       design['Experiment'][i])
                    et_add_child(nodes['fractions'], 'short',
                                       design['Fraction'][i])
                    et_add_child(nodes['ptms'], 'boolean',
                                       design['PTM'][i])
                    et_add_child(nodes['paramGroupIndices'], 'int', 0)
                    et_add_child(nodes['referenceChannel'], 'string', '')

    def add_fasta_files(self, files,
                        identifier=r'>([^\s]*)',
                        description=r'>(.*)'):
        """Add fasta file groups.
        >>> t = MQParam('test', './test-data/template.xml', None)
        >>> t.add_fasta_files(('test1', 'test2'))
        >>> len(t.root.find('fastaFiles'))
        2
        >>> t.root.find('fastaFiles')[0].find("fastaFilePath").text
        'test1'
        """
        fasta_node = self.root.find("fastaFiles")
        fasta_node.clear()
        fasta_node.tag = "fastaFiles"

        for index in range(len(files)):
            filepath = '<fastaFilePath>' + files[index]
            identifier = identifier.replace('<', '&lt;')
            description = description.replace('<', '&lt;')
            fasta = self.fasta_template.replace('<fastaFilePath>', filepath)
            fasta = fasta.replace('<identifierParseRule>',
                                  '<identifierParseRule>' + identifier)
            fasta = fasta.replace('<descriptionParseRule>',
                                  '<descriptionParseRule>' + description)
            ff_node = self.root.find('.fastaFiles')
            fastaentry = ET.fromstring(fasta)
            ff_node.append(fastaentry)

    def set_simple_param(self, key, value):
        """Set a simple parameter.
        >>> t = MQParam(None, './test-data/template.xml', None)
        >>> t.set_simple_param('min_unique_pep', 4)
        >>> t.root.find('.minUniquePeptides').text
        '4'
        """
        node = self.root[key]
        if node is None:
            raise ValueError('Element {} not found in parameter file'
                             .format(simple_params[key]))
        node.text = str(value)

    def write(self):
        """Write pretty formatted xml parameter file.
        Compose it from global parameters and parameter Groups.
        """
        
        template_pg = self.root['ParamGroups']['ParamGroup']
        self.root['ParamGroups'].remove(template_pg)
        for group in self.ParamGroups:
            self.root['ParamGroups'].append(group)
            
        rough_string = ET.tostring(self.root, 'utf-8', short_empty_elements=False)
        reparsed = minidom.parseString(rough_string)
        pretty = reparsed.toprettyxml(indent="\t")
        even_prettier = re.sub(r"\n\s+\n", r"\n", pretty)
        with open(self.mqpar_out, 'w') as f:
            print(even_prettier, file=f)
