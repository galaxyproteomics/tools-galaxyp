from galaxy.datatypes.proteomics import ProteomicsXml


class PercolatorOutXml(ProteomicsXml):
    """Percolator output data in XML format"""
    file_ext = 'percout'
    blurb = 'percolator out XML'
