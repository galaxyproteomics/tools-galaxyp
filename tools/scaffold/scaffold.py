from galaxy.datatypes.binary import Binary


class Sf3(Binary):
    """Class describing a Scaffold SF3 files"""
    file_ext = "sf3"

Binary.register_unsniffable_binary_ext('sf3')
