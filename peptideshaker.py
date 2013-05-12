from galaxy.datatypes.binary import Binary


class Cps(Binary):
    """Class describing a PeptideShaker CPS files"""
    file_ext = "cps"

Binary.register_unsniffable_binary_ext('cps')
