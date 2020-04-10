"""Tests for mqparam class. If testing a new MaxQuant version,
create a new parameter file using '<MAXQUANT_CMD> -c ./mqpar.xml'
"""

import pytest
import xml.etree.ElementTree as ET
from mqparam import MQParam, ParamGroup

TEMPLATE_PATH = './test-data/template.xml'


def mk_pg_root():
    mqpar = ET.parse(TEMPLATE_PATH).getroot()
    return mqpar.find('.parameterGroups/parameterGroup')


class TestParamGroup:
    def test_list_param(self):
        t = ParamGroup(mk_pg_root())
        t.set_list_param('enzymes', ('test 1', 'test 2'))
        assert len(t._root.find('enzymes')) == 2

        t.set_list_param('variableModifications', ('Oxidation (M)', ))
        assert t._root.find('variableModifications')[0].text == 'Oxidation (M)'

        with pytest.raises(ValueError):
            t.set_list_param('foo', [])

    def test_simple_params(self):
        t = ParamGroup(mk_pg_root())
        t.set_simple_param('fastLfq', False)
        assert t._root.find('.fastLfq').text == 'False'

        with pytest.raises(ValueError):
            t.set_simple_param('foo', 2)

    def test_silac(self):
        t = ParamGroup(mk_pg_root())
        t.set_silac(None, None, ('Arg10', 'Lys4'))
        assert t._root.find('.maxLabeledAa').text == '2'
        assert t._root.find('.multiplicity').text == '2'
        assert t._root.find('.labelMods')[1].text == 'Arg10;Lys4'
        assert t._root.find('.labelMods')[0].text == ''

    def test_isobaric_label(self):
        t = ParamGroup(mk_pg_root())
        t.set_isobaric_label('iTRAQ4plex-Lys114', 'iTRAQ4plex-Nter114', 0.3, 1, 1.2, 0, True)

        assert len(t._root.find('isobaricLabels')) == 1
        assert len(t._root.find('isobaricLabels')[0]) == 7

        t.set_isobaric_label('iTRAQ4plex-Lys115', 'iTRAQ4plex-Nter115', 0.3, 1.0, 1.2, 0, True)

        assert len(t._root.find('isobaricLabels')) == 2

        tag_list = [el.tag for el in t._root.find('isobaricLabels')[1]]
        assert tag_list == ['internalLabel', 'terminalLabel', 'correctionFactorM2',
                            'correctionFactorM1', 'correctionFactorP1', 'correctionFactorP2',
                            'tmtLike']

        text_list = [el.text for el in t._root.find('isobaricLabels')[1]]
        assert text_list == ['iTRAQ4plex-Lys115', 'iTRAQ4plex-Nter115',
                             '0.3', '1', '1.2', '0', 'True']


class TestMQParam:

    def test_version(self):
        t = MQParam(TEMPLATE_PATH)
        assert t._root.find('maxQuantVersion').text == '1.6.10.43'

    def test_validity_check(self):
        design = {'Name': ['Test1', 'Test2'],
                  'Fraction': ['2', 32767],
                  'PTM': ['False', 'False'],
                  'Experiment': ['e1', 'e1'],
                  'paramGroup': [0, 0]}

        assert MQParam._check_validity(design, 2) is None

        design['Name'][0] = None
        with pytest.raises(Exception):
            MQParam._check_validity(design, 2)
        design['Name'][0] = 'Test1'

        design['Experiment'][0] = ''
        with pytest.raises(ValueError):
            MQParam._check_validity(design, 2)
        design['Experiment'][0] = 'e1'

        design['Fraction'][0] = 'foo'
        with pytest.raises(ValueError):
            MQParam._check_validity(design, 2)

    def test_exp_design(self, tmpdir):
        # default experimental design when None is specified
        t = MQParam(TEMPLATE_PATH)
        design = t._make_exp_design((0, 0), ('./Test1.mzXML', './Test2.mzXML'))
        assert design['Name'] == ('./Test1.mzXML', './Test2.mzXML')
        assert design['Fraction'] == ('32767', '32767')

        # valid experimental design
        e1 = tmpdir / "e1.txt"
        e1.write('Name\tExperiment\tFraction\tPTM\nTest1\te1\nTest2\te1\t\tfalse')
        t.exp_design = str(e1)
        design = t._make_exp_design((0, 0), ('./Test1.mzXML', './Test2.mzXML'))

        assert design == {'Name': ['./Test1.mzXML', './Test2.mzXML'],
                          'Experiment': ['e1', 'e1'],
                          'Fraction': ['32767', '32767'],
                          'PTM': ['False', 'false'],
                          'paramGroup': (0, 0)}

        # invalid header
        e2 = tmpdir / "e2.txt"
        e2.write('Name\tExperiment\tFraction\tPTM\tparamGroup\n')
        t.exp_design = str(e2)

        with pytest.raises(Exception):
            design = t._make_exp_design(('./Test2.mzXML',), (0,))

    def test_add_infiles(self):
        t = MQParam(TEMPLATE_PATH)
        t.add_infiles([('/path/Test1.mzXML', '/path/Test2.mzXML'),
                       ('/path/Test3.mzXML', '/path/Test4.mzXML')])

        assert [e.text for e in t._root.find('filePaths')] == ['/path/Test1.mzXML',
                                                               '/path/Test2.mzXML',
                                                               '/path/Test3.mzXML',
                                                               '/path/Test4.mzXML']

        assert [e.text for e in t._root.find('paramGroupIndices')] == ['0', '0', '1', '1']
        assert t[1]

    def test_translate(self):
        t = MQParam(TEMPLATE_PATH)
        t.add_infiles([('/posix/path/to/Test1.mzXML',
                        '/posix/path/to/Test2.mzXML'),
                       ('/path/dummy.mzXML',)])  # mqparam is not designed for windows

        t._root.find('filePaths')[2].text = r'D:\Windows\Path\Test3.mzXML'

        t.translate(('/galaxy/working/Test3.mzXML',
                     '/galaxy/working/Test1.mzXML',
                     '/galaxy/working/Test2.mzXML',
                     '/galaxy/working/Test4.mzXML'))

        assert [e.text for e in t._root.find('filePaths')] == ['/galaxy/working/Test1.mzXML',
                                                               '/galaxy/working/Test2.mzXML',
                                                               '/galaxy/working/Test3.mzXML']

    def test_fasta_files(self):
        t = MQParam(TEMPLATE_PATH)
        t.add_fasta_files(('test1', 'test2'),
                          parse_rules={'identifierParseRule': r'>([^\s]*)'})
        assert len(t._root.find('fastaFiles')) == 2
        assert t._root.find('fastaFiles')[0].find("fastaFilePath").text == 'test1'
        assert t._root.find('fastaFiles')[0].find("identifierParseRule").text == '>([^\\s]*)'

    def test_simple_param(self):
        t = MQParam(TEMPLATE_PATH)
        t.set_simple_param('minUniquePeptides', 4)
        assert t._root.find('.minUniquePeptides').text == '4'

        with pytest.raises(ValueError):
            t.set_simple_param('foo', 3)

    def test_from_yaml(self, tmpdir):
        conf1 = tmpdir / "conf1.yml"
        conf1.write(r"""
        numThreads: 4
        fastaFiles: [test1.fasta,test2.fasta]
        parseRules:
          identifierParseRule: ^>.*\|(.*)\|.*$
        paramGroups:
          - files: [Test1.mzXML,Test2.mzXML] # paramGroup 0
            fixedModifications: [mod1,mod2]
            lfqMode: 1
          - files: [Test3.mzXML,Test4.mzXML] # paramGroup 1
            labelMods:
              - []
              - []
              - [label1,label2]
        """)

        t = MQParam(TEMPLATE_PATH)
        t._from_yaml(str(conf1))
        assert t['numThreads'] == '4'
        assert [child.text for child in t[1]._root.find('labelMods')] == ['', 'label1;label2']

    def test_write(self, tmpdir):
        yaml_conf = tmpdir / "conf.yml"
        yaml_conf.write(r"""
        numThreads: 4
        fastaFiles: [test1.fasta,test2.fasta]
        parseRules:
          identifierParseRule: ^>.*\|(.*)\|.*$
        paramGroups:
          - files: [Test1.mzXML,Test2.mzXML] # paramGroup 0
            fixedModifications: [mod1]
            variableModifications: [mod2,mod3]
            maxMissedCleavages: 1
        """)
        mqpar_out = tmpdir / "mqpar.xml"

        t = MQParam(TEMPLATE_PATH, yaml=str(yaml_conf))
        t.write(str(mqpar_out))

        test = ET.parse(str(mqpar_out)).getroot()
        assert test.find('numThreads').text == '4'
        assert test.find('fastaFiles')[1].find('identifierParseRule').text == '^>.*\\|(.*)\\|.*$'
        assert [el.text for el in test.find('parameterGroups')[0].find('variableModifications')] == ['mod2', 'mod3']
