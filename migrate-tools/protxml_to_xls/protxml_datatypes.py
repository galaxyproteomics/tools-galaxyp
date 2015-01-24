from galaxy.datatypes.tabular import Tabular
import logging

log = logging.getLogger(__name__)


class ProtXmlReport(Tabular):
    """protxml converted to tabular report"""
    file_ext = "tsv"
    comment_lines = 1

    def __init__(self, **kwd):
        Tabular.__init__( self, **kwd )
        self.column_names = ["Entry Number", "Group Probability", "Protein", "Protein Link", "Protein Probability", "Percent Coverage", "Number of Unique Peptides", "Total Independent Spectra", "Percent Share of Spectrum ID's", "Description", "Protein Molecular Weight", "Protein Length", "Is Nondegenerate Evidence", "Weight", "Precursor Ion Charge", "Peptide sequence", "Peptide Link", "NSP Adjusted Probability", "Initial Probability", "Number of Total Termini", "Number of Sibling Peptides Bin", "Number of Instances", "Peptide Group Designator", "Is Evidence?"]

    def set_meta( self, dataset, **kwd ):
        Tabular.set_meta( self, dataset, **kwd )

    #def display_peek( self, dataset ):
    #    """Returns formated html of peek"""
    #    return Tabular.make_html_table( self, dataset, column_names=self.column_names )
