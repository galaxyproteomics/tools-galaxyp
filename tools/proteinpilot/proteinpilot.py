from galaxy.datatypes.binary import Binary
from galaxy.datatypes.xml import GenericXml


class Group( Binary ):
    """Class describing a ProteinPilot group files"""
    file_ext = "group"

Binary.register_unsniffable_binary_ext('group')


class ProteinPilotXml( GenericXml ):
    file_ext = "proteinpilot.xml"
