"""Tests for mqparam class. If testing a new MaxQuant version, 
create a new parameter file using '<MAXQUANT_CMD> -c ./mqpar.xml'
"""

import pytest
import xml.etree.ElementTree as ET
from mqparam import MQParam, ParamGroup

TEMPLATE_DIR = './test-data/template.xml'
def mk_pg_root():
    mqpar = ET.parse(TEMPLATE_DIR).getroot()
    return mqpar.find('.parameterGroups/parameterGroup')


class TestParamGroup:

    def test_list_params(self):
        t = ParamGroup(mk_pg_root())
        t.set_list_params('enzymes', ('test 1', 'test 2'))
        assert len(t._root.find('enzymes')) == 2

        t.set_list_params('variableModifications', ('Oxidation (M)', ))
        assert t._root.find('variableModifications')[0].text == 'Oxidation (M)'

        with pytest.raises(ValueError):
            t.set_list_params('foo', [])

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
        # assert len(t._root.find('IsobaricLabelInfo')) == 7

        t.set_isobaric_label('iTRAQ4plex-Lys115', 'iTRAQ4plex-Nter115', 0.3, 1, 1.2, 0, True)

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
        t = MQParam("test", TEMPLATE_DIR, None)
        assert t._root.find('maxQuantVersion').text == '1.6.3.4'

    def test_validity_check(self):
        design = {'Name': ['Test1','Test2'],
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
        t = MQParam("test", TEMPLATE_DIR, None)
        design = t._make_exp_design((0, 0), ('./Test1.mzXML', './Test2.mzXML'))
        assert design['Name'] == ('./Test1.mzXML', './Test2.mzXML')
        assert design['Fraction'] == ('32767', '32767')

        # valid experimental design
        e1 = tmpdir / "e1.txt"
        e1.write('Name\tExperiment\tFraction\tPTM\n' +
                'Test1\te1\n' +
                'Test2\te1\t\tfalse')
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
        t = MQParam("test", TEMPLATE_DIR, None)
        t.add_infiles([('/path/Test1.mzXML', '/path/Test2.mzXML'),
                       ('/path/Test3.mzXML', '/path/Test4.mzXML')])

        assert [e.text for e in t._root.find('filePaths')] == ['/path/Test1.mzXML',
                                                               '/path/Test2.mzXML',
                                                               '/path/Test3.mzXML',
                                                               '/path/Test4.mzXML']

        assert [e.text for e in t._root.find('paramGroupIndices')] == ['0', '0', '1', '1']
        assert t[1]

    def test_translate(self):
        t = MQParam("test", TEMPLATE_DIR, None)
        t.add_infiles([('/posix/path/to/Test1.mzXML',
                        '/posix/path/to/Test2.mzXML'),
                       ('/path/dummy.mzXML',)])  # mqparam is not designed for windows

        t._root.find('filePaths')[2].text = 'D:\\Windows\Path\Test3.mzXML'

        t.translate(('/galaxy/working/Test3.mzXML',
                     '/galaxy/working/Test1.mzXML',
                     '/galaxy/working/Test2.mzXML',
                     '/galaxy/working/Test4.mzXML'))

        assert [e.text for e in t._root.find('filePaths')] == ['/galaxy/working/Test1.mzXML',
                                                               '/galaxy/working/Test2.mzXML',
                                                               '/galaxy/working/Test3.mzXML']


    def test_fasta_files(self):
        t = MQParam('test', TEMPLATE_DIR, None)
        t.add_fasta_files(('test1', 'test2'))
        assert len(t._root.find('fastaFiles')) == 2
        assert t._root.find('fastaFiles')[0].find("fastaFilePath").text == 'test1'
        assert t._root.find('fastaFiles')[0].find("identifierParseRule").text == '>([^\\s]*)'

    def test_simple_param(self):
        t = MQParam(None, TEMPLATE_DIR, None)
        t.set_simple_param('minUniquePeptides', 4)
        assert t._root.find('.minUniquePeptides').text == '4'

        with pytest.raises(ValueError):
            t.set_simple_param('foo', 3)
