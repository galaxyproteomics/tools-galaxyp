from galaxy.datatypes.tabular import Tabular
import logging

log = logging.getLogger(__name__)


class PepXmlReport(Tabular):
    """pepxml converted to tabular report"""
    file_ext = "tsv"

    def __init__(self, **kwd):
        Tabular.__init__( self, **kwd )
        self.column_names = ['Protein', 'Peptide', 'Assumed Charge', 'Neutral Pep Mass (calculated)', 'Neutral Mass', 'Retention Time', 'Start Scan', 'End Scan', 'Search Engine', 'PeptideProphet Probability', 'Interprophet Probabaility']

    def set_meta( self, dataset, **kwd ):
        Tabular.set_meta( self, dataset, **kwd )

    #def display_peek( self, dataset ):
    #    """Returns formated html of peek"""
    #    return Tabular.make_html_table( self, dataset, column_names=self.column_names )
