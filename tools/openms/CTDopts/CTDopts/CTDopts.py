import argparse
from itertools import chain
import collections
import collections.abc
from xml.etree.ElementTree import Element, SubElement, tostring, parse
from xml.dom.minidom import parseString
import warnings

# dummy classes for input-file and output-file CTD types.


class _ASingleton(type):
    """
    A metaclass for singletons
    """
    _instances = {}

    def __call__(cls, *args, **kwargs):
        if cls not in cls._instances:
            cls._instances[cls] = super(_ASingleton, cls).__call__(*args, **kwargs)
        else:
            cls._instances[cls].__init__(*args, **kwargs)
        return cls._instances[cls]


class _Null(object):
    """
    A null singleton for non-initialized fields to distinguish between initialized=None and non-initialized members
    """
    __metaclass__ = _ASingleton

    def __str__(self):
        return ""


class _InFile(str):
    """Dummy class for input-file CTD type. I think most users would want to just get the file path
    string but if it's required to open these files for reading or writing, one could do it in these
    classes in a later release. Otherwise, it's equivalent to str with the information that we're
    dealing with a file argument.
    """
    pass


class _OutFile(str):
    """Same thing, a dummy class for output-file CTD type."""
    pass


class _OutPrefix(str):
    """Same thing, a dummy class for output-prefix CTD type."""
    pass


class _InPrefix(str):
    """Same thing, a dummy class for output-prefix CTD type."""
    pass


# module globals for some common operations (python types to CTD-types back and forth)
TYPE_TO_CTDTYPE = {int: 'int', float: 'double', str: 'string', bool: 'bool',
                   _InFile: 'input-file', _OutFile: 'output-file',
                   _OutPrefix: 'output-prefix', _InPrefix: 'input-prefix'}
CTDTYPE_TO_TYPE = {'int': int, 'float': float, 'double': float, 'string': str,
                   'boolean': bool, 'bool': bool,
                   'input-file': _InFile, 'output-file': _OutFile,
                   'output-prefix': _OutPrefix, 'input-prefix': _InPrefix,
                   int: int, float: float, str: str,
                   bool: bool, _InFile: _InFile, _OutFile: _OutFile,
                   _OutPrefix: _OutPrefix, _InPrefix: _InPrefix}
PARAM_DEFAULTS = {'advanced': False, 'required': False, 'restrictions': None, 'description': None,
                  'supported_formats': None, 'tags': None, 'position': None}  # unused. TODO.


def CAST_BOOLEAN(x):
    """
    a boolean type caster to circumvent bool('false')==True when we cast CTD
    'value' attributes to their correct type
    """
    if not isinstance(x, str):
        return bool(x)
    else:
        return x in ('true', 'True', '1')


# instead of using None or _Null, we define non-present 'position' attribute values as -1
NO_POSITION = -1


# Module-level functions for querying and manipulating argument dictionaries.
def get_nested_key(arg_dict, key_list):
    """Looks up a nested key in an arbitrarily nested dictionary. `key_list` should be an iterable:

    get_nested_key(args, ['group', 'subgroup', 'param']) returns args['group']['subgroup']['param']
    """
    key_list = [key_list] if isinstance(key_list, str) else key_list  # just to be safe.
    res = arg_dict
    for key in key_list:
        res = res[key]
    else:
        return res


def set_nested_key(arg_dict, key_list, value):
    """Inserts a value into an arbitrarily nested dictionary, creating nested sub-dictionaries on
    the way if needed:

    set_nested_key(args, ['group', 'subgroup', 'param'], value) sets args['group']['subgroup']['param'] = value
    """
    key_list = [key_list] if isinstance(key_list, str) else key_list  # just to be safe.
    res = arg_dict
    for key in key_list[:-1]:
        if key not in res:
            res[key] = {}  # OrderedDict()
        res = res[key]
    else:
        res[key_list[-1]] = value


def flatten_dict(arg_dict, as_string=False):
    """Creates a flattened dictionary out of a nested dictionary. New keys will be tuples, with the
    nesting information. Ie. arg_dict['group']['subgroup']['param1'] will be
    result[('group', 'subgroup', 'param1')] in the flattened dictionary.

    `as_string` joins the nesting levels into a single string with a semicolon, so the same entry
    would be under result['group:subgroup:param1']
    """
    result = {}

    def flattener(subgroup, level):
        # recursive closure that accesses and modifies result dict and registers nested elements
        # as it encounters them
        for key, value in subgroup.items():
            if isinstance(value, collections.abc.Mapping):  # collections.Mapping instead of dict for generality
                flattener(value, level + [key])
            else:
                result[tuple(level + [key])] = value

    flattener(arg_dict, [])
    if as_string:
        return {':'.join(keylist): value for keylist, value in result.items()}
    else:
        return result


def override_args(*arg_dicts):
    """Takes any number of (nested or flat) argument dictionaries and combines them, giving preference
    to the last one if more than one have the same entry. Typically would be used like:

    combined_args = override_args(args_from_ctd, args_from_commandline)
    """
    overridden_args = dict(chain(*(flatten_dict(d).items() for d in arg_dicts)))
    result = {}
    for keylist, value in overridden_args.items():
        set_nested_key(result, keylist, value)
    return result


def _translate_ctd_to_param(attribs):
    """Translates a CTD <ITEM> or <ITEMLIST> XML-node's attributes to keyword arguments that Parameter's
    constructor expects. One should be able to call Parameter(*result) with the output of this function.
    For list parameters, adding is_list=True and getting <LISTITEM> values is needed after translation,
    as they are not stored as XML attributes.
    """

    # right now value is a required field, but it shouldn't be for required parameters.
    if 'value' in attribs:  # TODO 1_6_3, this line will be deleted.
        attribs['default'] = attribs.pop('value')  # rename 'value' to 'default' (Parameter constructor takes 'default')

    if 'supported_formats' in attribs:  # supported_formats in CTD xml is called file_formats in CTDopts
        attribs['file_formats'] = attribs.pop('supported_formats')  # rename that attribute too

    if 'restrictions' in attribs:  # find out whether restrictions are choices ('this,that') or numeric range ('3:10')
        if ',' in attribs['restrictions']:
            attribs['choices'] = attribs['restrictions'].split(',')
        elif ':' in attribs['restrictions']:
            n_min, n_max = attribs['restrictions'].split(':')
            n_min = None if n_min == '' else n_min
            n_max = None if n_max == '' else n_max
            attribs['num_range'] = (n_min, n_max)
        else:
            # there is nothing we can split with... so we will assume that this is a restriction of one possible
            # value... anyway, the user should be warned about it
            warnings.warn("Restriction [%s] of a single value found for parameter [%s]. \n"
                          "Restrictions should be comma separated value lists or colon separated values to "
                          "indicate numeric ranges (e.g., 'true,false', '0:14', '1:', ':2.8')\n"
                          "Will use a restriction with one possible value of choice." %
                          (attribs['restrictions'], attribs['name']))
            attribs['choices'] = [attribs['restrictions']]

    # TODO: advanced. Should it be stored as a tag, or should we extend Parameter class to have that attribute?
    # what we can do is keep it as a tag in the model, and change Parameter._xml_node() so that if it finds
    # 'advanced' among its tag-list, make it output it as a separate attribute.
    return attribs


class ArgumentError(Exception):
    """Base exception class for argument related problems.
    """
    def __init__(self, parameter):
        self.parameter = parameter
        self.param_name = ':'.join(self.parameter.get_lineage(name_only=True))


class ArgumentMissingError(ArgumentError):
    """Exception for missing required arguments.
    """
    def __init__(self, parameter):
        super(ArgumentMissingError, self).__init__(parameter)

    def __str__(self):
        return 'Required argument %s missing' % self.param_name


class ArgumentTypeError(ArgumentError):
    """Exception for arguments that can't be casted to the type defined in the model.
    """
    def __init__(self, parameter, value):
        super(ArgumentTypeError, self).__init__(parameter)
        self.value = value

    def __str__(self):
        return "Argument %s is of wrong type. Expected: %s, got %s" % (
            self.param_name, TYPE_TO_CTDTYPE[self.parameter.type], self.value)


class ArgumentRestrictionError(ArgumentError):
    """Exception for arguments violating numeric, file format or controlled vocabulary restrictions.
    """
    def __init__(self, parameter, value):
        super(ArgumentRestrictionError, self).__init__(parameter)
        self.value = value

    def __str__(self):
        return 'Argument restrictions for %s failed. Restriction: %s. Value: %s' % (
            self.param_name, self.parameter.restrictions.ctd_restriction_string(), self.value)


class ModelError(Exception):
    """Exception for errors related to CTDModel building
    """
    def __init__(self):
        super(ModelError, self).__init__()


class ModelTypeError(ModelError):
    """Exception if file of wrong type is provided
    """
    def __init__(self, message):
        super(ModelTypeError, self).__init__()
        self.message = message

    def __str__(self):
        return "An error occurred while parsing the CTD file: %s" % self.message

    def __repr__(self):
        return str(self)


class ModelParsingError(ModelError):
    """Exception for errors related to CTD parsing
    """
    def __init__(self, message):
        super(ModelParsingError, self).__init__()
        self.message = message

    def __str__(self):
        return "An error occurred while parsing the CTD file: %s" % self.message

    def __repr__(self):
        return str(self)


class UnsupportedTypeError(ModelError):
    """Exception for attempting to use unsupported types in the model
    """
    def __init__(self, wrong_type):
        super(UnsupportedTypeError, self).__init__()
        self.wrong_type = wrong_type

    def __str__(self):
        return 'Unsupported type encountered during model construction: %s' % self.wrong_type


class DefaultError(ModelError):
    def __init__(self, parameter):
        super(DefaultError, self).__init__()
        self.parameter = parameter

    def __str__(self):
        pass


class _Restriction(object):
    """Superclass for restriction classes (numeric, file format, controlled vocabulary).
    """
    def __init__(self):
        pass

    # if Python had virtual methods, this one would have a _single_check() virtual method, as all
    # subclasses have to implement for check() to go through. check() expects them to be present,
    # and validates normal and list parameters accordingly.
    def check(self, value):
        """Checks whether `value` satisfies the restriction conitions. For list parameters it checks
        every element individually.
        """
        if isinstance(value, list):  # check every element of list (in case of list parameters)
            return all((self._single_check(v) for v in value))
        else:
            return self._single_check(value)


class _NumericRange(_Restriction):
    """Class for numeric range restrictions. Stores valid numeric ranges, checks values against
    them and outputs CTD restrictions attribute strings.
    """
    def __init__(self, n_type, n_min=None, n_max=None):
        super(_NumericRange, self).__init__()
        self.n_type = n_type
        self.n_min = self.n_type(n_min) if n_min is not None else None
        self.n_max = self.n_type(n_max) if n_max is not None else None

    def ctd_restriction_string(self):
        n_min = str(self.n_min) if self.n_min is not None else ''
        n_max = str(self.n_max) if self.n_max is not None else ''
        return '%s:%s' % (n_min, n_max)

    def _single_check(self, value):
        if self.n_min is not None and value < self.n_min:
            return False
        elif self.n_max is not None and value > self.n_max:
            return False
        else:
            return True

    def __repr__(self):
        return 'numeric range: %s to %s' % (self.n_min, self.n_max)


class _FileFormat(_Restriction):
    """Class for file format restrictions. Stores valid file formats, checks filenames against them
    and outputs CTD supported_formats attribute strings.
    """
    def __init__(self, formats):
        super(_FileFormat, self).__init__()
        if isinstance(formats, str):  # to handle ['txt', 'csv', 'tsv'] and '*.txt,*.csv,*.tsv'
            formats = [x.replace('*.', '').strip() for x in formats.split(',')]
        self.formats = formats

    def ctd_restriction_string(self):
        return ','.join(('*.' + f for f in self.formats))

    def _single_check(self, value):
        for f in self.formats:
            if value.endswith('.' + f):
                return True
        return False

    def __repr__(self):
        return 'file formats: %s' % (', '.join(self.formats))


class _Choices(_Restriction):
    """Class for controlled vocabulary restrictions. Stores controlled vocabulary elements, checks
    values against them and outputs CTD restrictions attribute strings.
    """
    def __init__(self, choices):
        super(_Choices, self).__init__()
        if isinstance(choices, str):  # If it actually has to run, a user is screwing around...
            choices = choices.replace(', ', ',').split(',')
        self.choices = choices

    def _single_check(self, value):
        return value in self.choices

    def ctd_restriction_string(self):
        return ','.join(self.choices)

    def __repr__(self):
        return 'choices: %s' % (', '.join(map(str, self.choices)))


class Parameter(object):

    def __init__(self, name=None, parent=None, node=None, **kwargs):
        if node is None:
            kwargs["name"] = name
            self._init_from_kwargs(parent, **kwargs)
        else:
            self._init_from_node(parent, node)

    def _init_from_node(self, parent, nd):
        setup = _translate_ctd_to_param(dict(nd.attrib))
        assert nd.tag in ["ITEM", "ITEMLIST"], "Tried to init Parameter from %s" % nd.tag
        if nd.tag == 'ITEMLIST':
            if len(nd) > 0:
                setup['default'] = [listitem.attrib['value'] for listitem in nd]
            else:
                setup['default'] = []
            setup['is_list'] = True
        self._init_from_kwargs(parent, **setup)

    def _init_from_kwargs(self, parent, **kwargs):
        """Required positional arguments: `name` string and `parent` ParameterGroup object

        Optional keyword arguments:
            `type`: Python type object, or a string of a valid CTD types.
                    For all valid values, see: CTDopts.CTDTYPE_TO_TYPE.keys()
            `default`: default value. Will be casted to the above type (default None)
            `is_list`: bool, indicating whether this is a list parameter (default False)
            `required`: bool, indicating whether this is a required parameter (default False)
            `description`: string containing parameter description (default None)
            `tags`: list of strings or comma separated string (default [])
            `num_range`: (min, max) tuple. None in either position makes it unlimited
            `choices`: list of allowed values (controlled vocabulary)
            `file_formats`: list of allowed file extensions
            `short_name`: string for short name annotation
            `position`: index (1-based) of the position on which the parameter appears on the command-line
        """
        assert "name" in kwargs, "Parameter initialisation without name"
        self.name = kwargs["name"]
        self.parent = parent
        self.short_name = kwargs.get('short_name', _Null())
        try:
            self.type = CTDTYPE_TO_TYPE[kwargs.get('type', str)]
        except KeyError:
            raise UnsupportedTypeError(kwargs.get('type'))

        self.tags = kwargs.get('tags', [])
        if isinstance(self.tags, str):  # so that tags can be passed as ['tag1', 'tag2'] or 'tag1,tag2'
            self.tags = filter(bool, self.tags.split(','))  # so an empty string doesn't produce ['']
        self.required = CAST_BOOLEAN(kwargs.get('required', False))
        self.is_list = CAST_BOOLEAN(kwargs.get('is_list', False))
        self.description = kwargs.get('description', None)
        self.advanced = CAST_BOOLEAN(kwargs.get('advanced', False))
        self.position = int(kwargs.get('position', str(NO_POSITION)))

        default = kwargs.get('default', _Null())

        self._validate_numerical_defaults(default)

        # TODO 1_6_3: right now the CTD schema requires the 'value' attribute to be present for every parameter.
        # So every time we build a model from a CTD file, we find at least a default='' or default=[]
        # for every parameter. This should change soon, but for the time being, we have to get around this
        # and disregard such default attributes. The below two lines will be deleted after fixing 1_6_3.
        if default == '' or (self.is_list and default == []):
            default = _Null()

        # enforce that default is the correct type if exists. Elementwise for lists
        if type(default) is _Null:
            self.default = _Null()
        elif default is None:
            self.default = None
        else:
            if self.is_list:
                self.default = list(map(self.type, default))
            else:
                self.default = self.type(default)

        # same for choices. I'm starting to think it's really unpythonic and we should trust input. TODO

        if self.type is bool:
            assert self.is_list is False, "Boolean flag can't be a list type"
            self.required = False  # override whatever we found. Boolean flags can't be required...
            self.default = CAST_BOOLEAN(default)
        # Default value should exist IFF argument is not required.
        # TODO: if we can have optional list arguments they don't have to have a default? (empty list)
        # TODO: CTD Params 1.6.3 have a required value attrib. That's very wrong for parameters that are required.
        # ... until that's ironed out, we have to comment this part out.
        #
        # ACTUALLY now that I think of it, letting required fields have value attribs set too
        # can be useful for users who want to abuse CTD and build models from argument-storing CTDs.
        # I know some users will do this (who are not native CTD users just want to convert their stuff
        # with minimal effort) so we might as well let them.
        #
        # if self.required:
        #     assert self.default is None, ('Required field `%s` has default value' % self.name)
        # else:
        #     assert self.default is not None, ('Optional field `%s` has no default value' % self.name)

        self.restrictions = None
        if 'num_range' in kwargs:
            try:
                self.restrictions = _NumericRange(self.type, *kwargs['num_range'])
            except ValueError:
                num_range = kwargs['num_range']
                raise ModelParsingError("Provided range [%s, %s] is not of type %s" %
                                        (num_range[0], num_range[1], self.type))
        elif 'choices' in kwargs:
            self.restrictions = _Choices(list(map(self.type, kwargs['choices'])))
        elif 'file_formats' in kwargs:
            self.restrictions = _FileFormat(kwargs['file_formats'])

    # perform some basic validation on the provided default values...
    # an empty string IS NOT a float/int!
    def _validate_numerical_defaults(self, default):
        if default is not None and type(default) is not _Null:
            if self.type is int or self.type is float:
                defaults_to_validate = []
                errors_so_far = []
                if self.is_list:
                    # for lists, validate each provided element
                    defaults_to_validate.extend(default)
                else:
                    defaults_to_validate.append(default)
                for default_to_validate in defaults_to_validate:
                    try:
                        if self.type is int:
                            int(default_to_validate)
                        else:
                            float(default_to_validate)
                    except ValueError:
                        errors_so_far.append(default_to_validate)

                if len(errors_so_far) > 0:
                    raise ModelParsingError("Invalid default value(s) provided for parameter %(name)s of type %(type)s:"
                                            " '%(default)s'"
                                            % {"name": self.name,
                                               "type": self.type,
                                               "default": ', '.join(map(str, errors_so_far))})

    def get_lineage(self, name_only=False, short_name=False):
        """Returns a list of zero or more ParameterGroup objects plus this Parameter object at the end,
        ie. the nesting lineage of the Parameter object. With `name_only` setting on, it only returns
        the names of said objects. For top level parameters, it's a list with a single element.
        """
        if name_only:
            n = self.name
        elif short_name:
            n = self.short_name
        else:
            n = self
        if self.parent is None:
            return [n]
        else:
            return self.parent.get_lineage(name_only, short_name) + [n]

    def get_parameters(self, nodes=False):
        """return an iterator over all parameters
        """
        yield self

    def __repr__(self):
        info = []
        info.append('PARAMETER %s%s' % (self.name, ' (required)' if self.required else ''))
        info.append('  type: %s%s%s' % ('list of ' if self.is_list else '', TYPE_TO_CTDTYPE[self.type],
                                        's' if self.is_list else ''))
        if self.default:
            info.append('  default: %s' % self.default)
        if self.tags:
            info.append('  tags: %s' % ', '.join(self.tags))
        if self.restrictions:
            info.append('  restrictions on %s' % self.restrictions)
        if self.description:
            info.append('  description: %s' % self.description)
        return '\n'.join(info)

    def _xml_node(self, arg_dict=None):
        if arg_dict is not None:  # if we call this function with an argument dict, get value from there
            try:
                value = get_nested_key(arg_dict, self.get_lineage(name_only=True))
            except KeyError:
                value = self.default
        else:  # otherwise take the parameter default
            value = self.default
        # XML attributes to be created (depending on whether they are needed or not):
        # name, value, type, description, tags, restrictions, supported_formats

        attribs = collections.OrderedDict()  # LXML keeps the order, ElemenTree doesn't. We use ElementTree though.
        attribs['name'] = self.name
        if not self.is_list:  # we'll deal with list parameters later, now only normal:
            # TODO: once Param_1_6_3.xsd gets fixed, we won't have to set an empty value='' attrib.
            # but right now value is a required attribute.
            attribs['value'] = str(value)
            if self.type is bool or type(value) is bool:  # for booleans str(True) returns 'True' but the XS standard is lowercase
                attribs['value'] = 'true' if value else 'false'
        attribs['type'] = TYPE_TO_CTDTYPE[self.type]
        if self.description:
            attribs['description'] = self.description
        if self.tags:
            attribs['tags'] = ','.join(self.tags)
        attribs['required'] = str(self.required).lower()
        attribs['advanced'] = str(self.advanced).lower()

        # Choices and NumericRange restrictions go in the 'restrictions' attrib, FileFormat has
        # its own attribute 'supported_formats' for whatever historic reason.
        if isinstance(self.restrictions, _Choices) or isinstance(self.restrictions, _NumericRange):
            attribs['restrictions'] = self.restrictions.ctd_restriction_string()
        elif isinstance(self.restrictions, _FileFormat):
            attribs['supported_formats'] = self.restrictions.ctd_restriction_string()

        if self.is_list:  # and now list parameters
            top = Element('ITEMLIST', attribs)
            # (lzimmermann) I guess _Null has to be exluded here, too
            if value is None or type(value) is _Null:
                pass
            elif type(value) is list:
                for d in value:
                    SubElement(top, 'LISTITEM', {'value': str(d)})
            return top
        else:
            return Element('ITEM', attribs)

    def _cli_node(self, parent_name, prefix='--'):
        lineage = self.get_lineage(name_only=True)
        top_node = Element('clielement', {"optionIdentifier": prefix + ':'.join(lineage)})
        SubElement(top_node, 'mapping', {"referenceName": parent_name + "." + self.name})
        return top_node

    def is_positional(self):
        return self.position != NO_POSITION


class ParameterGroup(object):
    def __init__(self, name=None, parent=None, node=None, description=None):
        self.parameters = collections.OrderedDict()
        self.name = name
        self.parent = parent
        self.description = description
        if node is None:
            return

        validate_contains_keys(node.attrib, ['name'], 'NODE')
        self.name = node.attrib['name']
        if "description" in node.attrib:
            self.description = node.attrib['description']
        for c in node:
            if c.tag == 'NODE':
                self.parameters[c.attrib['name']] = ParameterGroup(parent=self, node=c)
            elif c.tag in ["ITEMLIST", "ITEM"]:
                self.parameters[c.attrib['name']] = Parameter(parent=self, node=c)

    def add(self, name, **kwargs):
        """Registers a parameter in a ParameterGroup. Required: `name` string.

        Optional keyword arguments:
            `type`: Python type object, or a string of a valid CTD types.
                    For all valid values, see: CTDopts.CTDTYPE_TO_TYPE.keys()
            `default`: default value. Will be casted to the above type (default None)
            `is_list`: bool, indicating whether this is a list parameter (default False)
            `required`: bool, indicating whether this is a required parameter (default False)
            `description`: string containing parameter description (default None)
            `tags`: list of strings or comma separated string (default [])
            `num_range`: (min, max) tuple. None in either position makes it unlimited
            `choices`: list of allowed values (controlled vocabulary)
            `short_name`: string for short name annotation
        """
        # TODO assertion if name already exists? It just overrides now, but I'm not sure if allowing this behavior is OK
        self.parameters[name] = Parameter(name, self, **kwargs)
        return self.parameters[name]

    def add_group(self, name, description=None):
        """Registers a child parameter group under a ParameterGroup. Required: `name` string. Optional: `description`
        """
        # TODO assertion if name already exists? It just overrides now, but I'm not sure if allowing this behavior is OK
        self.parameters[name] = ParameterGroup(name, parent=self, description=description)
        return self.parameters[name]

    def _get_children(self):
        children = []
        for child in self.parameters.values():
            if isinstance(child, Parameter):
                children.append(child)
            elif isinstance(child, ParameterGroup):
                children.extend(child._get_children())
        return children

    def _xml_node(self, arg_dict=None):
        xml_attribs = {'name': self.name}
        if self.description:
            xml_attribs['description'] = self.description

        top = Element('NODE', xml_attribs)
        # TODO: if a Parameter comes after an ParameterGroup, the CTD won't validate. BTW, that should be changed.
        # Of course this should never happen if the argument tree is built properly but it would be
        # nice to take care of it if a user happens to randomly define his arguments and groups.
        # So first we could sort self.parameters (Items first, Groups after them).
        for arg in self.parameters.values():
            top.append(arg._xml_node(arg_dict))
        return top

    def _cli_node(self, parent_name="", prefix='--'):
        """
        Generates a list of clielements of that group
        :param arg_dict: dafualt values for elements
        :return: list of clielements
        """
        for arg in self.parameters.values():
            yield arg._cli_node(parent_name=parent_name + "." + self.name, prefix=prefix)

    def __repr__(self):
        info = []
        info.append('PARAMETER GROUP %s (' % self.name)
        for subparam in self.parameters.values():
            info.append(subparam.__repr__())
        info.append(')')
        return '\n'.join(info)

    def get_lineage(self, name_only=False, short_name=False):
        """Returns a list of zero or more ParameterGroup objects plus this one object at the end,
        ie. the nesting lineage of the ParameterGroup object. With `name_only` setting on, it only returns
        the names of said objects. For top level parameters, it's a list with a single element.
        """
        if name_only:
            n = self.name
        elif short_name:
            n = self.short_name
        else:
            n = self
        if self.parent is None:
            return [n]
        else:
            return self.parent.get_lineage(name_only, short_name) + [n]

    def get_parameters(self, nodes=False):
        """return an iterator over all parameters
        """
        if nodes:
            yield self
        for p in self.parameters.values():
            yield from p.get_parameters(nodes)


class Mapping(object):
    def __init__(self, reference_name=None):
        self.reference_name = reference_name


class CLIElement(object):
    def __init__(self, option_identifier=None, mappings=[]):
        self.option_identifier = option_identifier
        self.mappings = mappings


class CLI(object):
    def __init__(self, cli_elements=[]):
        self.cli_elements = cli_elements


class Parameters(ParameterGroup):
    def __init__(self, name=None, version=None, from_file=None, from_node=None, **kwargs):
        self.name = None
        self.version = None
        self.description = None
        self.opt_attribs = dict()  # little helper to have similar access as to CTDModel;

        if from_file is not None or from_node is not None:
            if from_file is not None:
                root = parse(from_file).getroot()
            else:
                root = from_node
            if root.tag != 'PARAMETERS':
                raise ModelTypeError("Invalid PARAMETERS file root is not <PARAMETERS>")
            # tool_element.attrib['version'] == '1.6.2'  # check whether the schema matches the one CTDOpts uses?
            params_container_node = root.find('NODE')

            one = root.find('./NODE/NODE[@name="1"]')
            version = root.find('./NODE/ITEM[@name="version"]')

            if one is not None and version is not None:
                super(Parameters, self).__init__(name=None, parent=None, node=one, description=None)
            else:
                super(Parameters, self).__init__(name=None, parent=None, node=params_container_node, description=None)
            self.description = params_container_node.attrib.get("description", "")
            self.name = params_container_node.attrib.get("name", "")
            if version is not None:
                self.version = version.attrib["value"]
        else:
            self.name = name
            self.version = version
            super(Parameters, self).__init__(name=name, parent=None, node=None, description=kwargs.get("description", ""))

        self.opt_attribs['description'] = self.description

    def _xml_node(self, arg_dict):
        params = Element('PARAMETERS', {
            'version': "1.7.0",
            'xmlns:xsi': "http://www.w3.org/2001/XMLSchema-instance",
            'xsi:noNamespaceSchemaLocation': "https://github.com/genericworkflownodes/CTDopts/raw/master/schemas/Param_1_7_0.xsd"
        })
        node = Element("NODE", {"name": self.name, 'description': self.description})
        params.append(node)

        if self.version is not None:
            node.append(Element("ITEM", {"name": "version", 'value': self.version, 'type': "string", 'description': "Version of the tool that generated this parameters file.", "required": "false", "advanced": "true"}))
        one_node = Element("NODE", {"name": "1", 'description': "Instance &apos;1&apos; section for &apos;%s&apos;" % self.name})
        node.append(one_node)

        for arg in self.parameters.values():
            n = arg._xml_node(arg_dict)
            one_node.append(n)

        return params

    def get_lineage(self, name_only=False, short_name=False):
        """Returns a list of zero or more ParameterGroup objects plus this one object at the end,
        ie. the nesting lineage of the ParameterGroup object. With `name_only` setting on, it only returns
        the names of said objects. For top level parameters, it's a list with a single element.
        """
        return []

    def get_parameters(self, nodes=False):
        """return an iterator over all parameters
        """
        for p in self.parameters.values():
            yield from p.get_parameters(nodes)

    def parse_cl_args(self, cl_args=None, prefix='--', short_prefix="-", get_remaining=False, ignore_required=False):
        """Parses command line arguments `cl_args` (either a string or a list like sys.argv[1:])
        assuming that parameter names are prefixed by `prefix` (default '--').

        Returns a nested dictionary with found arguments. Note that parameters have to be registered
        in the model to be parsed and returned.

        Remaining (unmatchable) command line arguments can be accessed if the method is called with
        `get_remaining`. In this case, the method returns a tuple, whose first element is the
        argument dictionary, the second a list of unmatchable command line options.
        """

        class StoreFirst(argparse._StoreAction):
            """
            OpenMS command line parser uses the value of the first
            occurence of an argument. This action does the same
            (contrary to the default behaviour of the store action)
            see also https://github.com/OpenMS/OpenMS/issues/4545
            """
            def __init__(self, option_strings, dest, nargs=None, **kwargs):
                self._seen_args = set()
                super(StoreFirst, self).__init__(option_strings, dest, nargs, **kwargs)

            def __call__(self, parser, namespace, values, option_strings=None):
                if self.dest not in self._seen_args:
                    self._seen_args.add(self.dest)
                    setattr(namespace, self.dest, values)

        cl_arg_list = cl_args.split() if isinstance(cl_args, str) else cl_args
        # if no arguments are given print help
        if not cl_arg_list:
            cl_arg_list.append("-h")

        cl_parser = argparse.ArgumentParser()
        for param in self.get_parameters():
            lineage = param.get_lineage(name_only=True)
            short_lineage = param.get_lineage(name_only=True, short_name=True)
            cli_param = prefix + ':'.join(lineage)
            cli_short_param = short_prefix + ':'.join(short_lineage)
            idx = -1
            if cli_param in cl_arg_list:
                idx = cl_arg_list.index(cli_param)
            elif cli_short_param in cl_arg_list:
                idx = cl_arg_list.index(cli_short_param)

            cl_arg_kws = {}  # argument processing info passed to argparse in keyword arguments, we build them here
            if idx >= 0 and idx + 1 < len(cl_arg_list) and cl_arg_list[idx + 1] in ['true', 'false']:
                cl_arg_kws['type'] = str
                cl_arg_kws['action'] = StoreFirst
            elif param.type is bool or (param.type is str and type(param.restrictions) is _Choices and set(param.restrictions.choices) == set(["true", "false"])):  # boolean flags are not followed by a value, only their presence is required
                cl_arg_kws['action'] = 'store_true'
            else:
                # we take every argument as string and cast them only later in validate_args() if
                # explicitly asked for. This is because we don't want to deal with type exceptions
                # at this stage, and prefer the multi-leveled strictness settings in validate_args()
                cl_arg_kws['type'] = str
                cl_arg_kws['action'] = StoreFirst

            if param.is_list:
                # or '+' rather? Should we allow empty lists here? If default is a proper list with elements
                # that we want to clear, this would be the only way to do it so I'm inclined to use '*'
                cl_arg_kws['nargs'] = '*'

            if type(param.default) is not _Null():
                cl_arg_kws['default'] = param.default

            if param.required and not ignore_required:
                cl_arg_kws['required'] = True

            # hardcoded 'group:subgroup:param'
            if all(type(a) is not _Null for a in short_lineage):
                cl_parser.add_argument(cli_short_param, cli_param, **cl_arg_kws)
            else:
                cl_parser.add_argument(cli_param, **cl_arg_kws)

        parsed_args, rest = cl_parser.parse_known_args(cl_arg_list)
        res_args = {}  # OrderedDict()
        for param_name, value in vars(parsed_args).items():
            # None values are created by argparse if it didn't find the argument or default=None, we skip params
            # that dont have a default value
            if value is not None or value == self.parameters.parameters[param_name].default:
                set_nested_key(res_args, param_name.split(':'), value)
        return res_args if not get_remaining else (res_args, rest)

    def generate_ctd_tree(self, arg_dict=None, *args):
        """Generates an XML ElementTree from the parameters model and returns
        the top <parameters> Element object, that can be output to a file
        (Parameters.write_ctd() does everything needed if the user
        doesn't need access to the actual element-tree).
        Calling this function without any arguments generates the tool-describing CTD with default
        values. For parameter-storing and logging optional arguments can be passed:

        `arg_dict`: nested dictionary with values to be used instead of defaults.
        other arguments are irnored
        """
        return self._xml_node(arg_dict)

    def write_ctd(self, out_file, arg_dict=None, log=None, cli=False):
        """Generates a CTD XML from the model and writes it to `out_file`, which is either a string
        to a file path or a stream with a write() method.

        Calling this function without any arguments besides `out_file` generates the tool-describing
        CTD with default values. For parameter-storing and logging optional arguments can be passed:

        `arg_dict`: nested dictionary with values to be used instead of defaults.
        `log`: dictionary with the following optional keys:
            'time_start' and 'time_finish': proper XML date strings (eg. datetime.datetime.now(pytz.utc).isoformat())
            'status': exit status
            'output': standard output or whatever output the user intends to log
            'warning': warning logs
            'error': standard error or whatever error log the user wants to store
        `cli`: boolean whether or not cli elements should be generated (needed for GenericKNIMENode for example)
        """
        write_ctd(self, out_file, arg_dict, log, cli)


class CTDModel(object):
    def __init__(self, name=None, version=None, from_file=None, **kwargs):
        """The parameter model of a tool.

        `name`: name of the tool
        `version`: version of the tool
        `from_file`: create the model from a CTD file at provided path

        Other (self-explanatory) keyword arguments:
        `docurl`, `description`, `manual`, `executableName`, `executablePath`, `category`
        """
        if from_file is not None:
            self._load_from_file(from_file)
        else:
            self.name = name
            self.version = version
            # TODO: check whether optional attributes in kwargs are all allowed or just ignore the rest?
            self.opt_attribs = kwargs  # description, manual, docurl, category (+executable stuff).
            self.parameters = Parameters(name=self.name, version=version, **kwargs)
            self.cli = []

    def _load_from_file(self, filename):
        """Builds a CTDModel from a CTD XML file.
        """
        root = parse(filename).getroot()
        if root.tag != 'tool':
            raise ModelTypeError("Invalid CTD file, root is not <tool>")

        self.opt_attribs = {}
        self.cli = []

        for tool_required_attrib in ['name', 'version']:
            assert tool_required_attrib in root.attrib, "CTD tool is missing a %s attribute" % tool_required_attrib
            setattr(self, tool_required_attrib, root.attrib[tool_required_attrib])

        for tool_opt_attrib in ['docurl', 'category']:
            if tool_opt_attrib in root.attrib:
                self.opt_attribs[tool_opt_attrib] = root.attrib[tool_opt_attrib]

        for tool_element in root:
            # ignoring: cli, logs, relocators. cli and relocators might be useful later.
            if tool_element.tag in ['manual', 'description', 'executableName', 'executablePath']:
                self.opt_attribs[tool_element.tag] = tool_element.text

            if tool_element.tag == 'cli':
                self._build_cli(tool_element.findall('clielement'))

            if tool_element.tag == 'PARAMETERS':
                self.parameters = Parameters(from_node=tool_element)

    def _build_cli(self, xml_cli_elements):
        for xml_cli_element in xml_cli_elements:
            mappings = []
            for xml_mapping in xml_cli_element.findall('mapping'):
                mappings.append(Mapping(xml_mapping.attrib['referenceName'] if 'referenceName' in xml_mapping.attrib else None))
            self.cli.append(CLIElement(xml_cli_element.attrib['optionIdentifier'] if 'optionIdentifier' in xml_cli_element.attrib else None, mappings))

    def _build_param_model(self, element, base):
        if element.tag == 'NODE':
            validate_contains_keys(element.attrib, ['name'], 'NODE')
            if base is None:  # top level group (<NODE name="1">) has to be created on its own
                current_group = ParameterGroup(element.attrib['name'], base, element.attrib.get('description', ''))
            else:  # other groups can be registered as a subgroup, as they'll always have parent base nodes
                current_group = base.add_group(element.attrib['name'], element.attrib.get('description', ''))
            for child in element:
                self._build_param_model(child, current_group)
            return current_group
        elif element.tag == 'ITEM':
            setup = _translate_ctd_to_param(dict(element.attrib))
            validate_contains_keys(setup, ['name'], 'ITEM')
            base.add(**setup)  # register parameter in model
        elif element.tag == 'ITEMLIST':
            setup = _translate_ctd_to_param(dict(element.attrib))
            setup['default'] = [listitem.attrib['value'] for listitem in element]
            setup['is_list'] = True
            validate_contains_keys(setup, ['name'], 'ITEMLIST')
            base.add(**setup)  # register list parameter in model

    def add(self, name, **kwargs):
        """Registers a top level parameter to the model. Required: `name` string.

        Optional keyword arguments:
            `type`: Python type object, or a string of a valid CTD types.
                    For all valid values, see: CTDopts.CTDTYPE_TO_TYPE.keys()
            `default`: default value. Will be casted to the above type (default None)
            `is_list`: bool, indicating whether this is a list parameter (default False)
            `required`: bool, indicating whether this is a required parameter (default False)
            `description`: string containing parameter description (default None)
            `tags`: list of strings or comma separated string (default [])
            `num_range`: (min, max) tuple. None in either position makes it unlimited
            `choices`: list of allowed values (controlled vocabulary)
            `file_formats`: list of allowed file extensions
            `short_name`: string for short name annotation
        """
        return self.parameters.add(name, **kwargs)

    def add_group(self, name, description=None):
        """Registers a top level parameter group to the model. Required: `name` string. Optional: `description`
        """
        return self.parameters.add_group(name, description)

    def list_parameters(self):
        """Returns a list of all Parameter objects registered in the model.
        """
        # root node will list all its children (recursively, if they are nested in ParameterGroups)
        return self.parameters._get_children()

    def get_defaults(self):
        """Returns a nested dictionary with all parameters of the model having default values.
        """
        params_w_default = (p for p in self.list_parameters() if type(p.default) is not _Null)
        defaults = {}
        for param in params_w_default:
            set_nested_key(defaults, param.get_lineage(name_only=True), param.default)
        return defaults

    def validate_args(self, args_dict, enforce_required=0, enforce_type=0, enforce_restrictions=0):
        """Validates an argument dictionary against the model, and returns a type-casted argument
        dictionary with defaults for missing arguments. Valid values for `enforce_required`,
        `enforce_type` and `enforce_restrictions` are 0, 1 and 2, where the different levels are:
            * 0: doesn't enforce anything,
            * 1: raises a warning
            * 2: raises an exception
        """
        # iterate over model parameters, look them up in the argument dictionary, convert to correct type,
        # use default if argument is not present and raise exception if required argument is missing.
        validated_args = {}  # OrderedDict()
        all_params = self.list_parameters()
        for param in all_params:
            lineage = param.get_lineage(name_only=True)
            try:
                arg = get_nested_key(args_dict, lineage)
                # boolean values are the only ones that don't get casted correctly with, say, bool('false')
                typecast = param.type if param.type is not bool else CAST_BOOLEAN
                try:
                    validated_value = list(map(typecast, arg)) if param.is_list else typecast(arg)
                except ValueError:  # type casting failed
                    validated_value = arg  # just keep it as a string (or list of strings)
                    if enforce_type:  # but raise a warning or exception depending on enforcement level
                        if enforce_type == 1:
                            warnings.warn('Argument %s is of wrong type. Expected %s, got: %s' %
                                          (':'.join(lineage), TYPE_TO_CTDTYPE[param.type], arg))
                        else:
                            raise ArgumentTypeError(param, arg)

                if enforce_restrictions and param.restrictions and not param.restrictions.check(validated_value):
                    if enforce_restrictions == 1:
                        warnings.warn('Argument restrictions for %s violated. Restriction: %s. Value: %s' %
                                      (':'.join(lineage), param.restrictions.ctd_restriction_string(), validated_value))
                    else:
                        raise ArgumentRestrictionError(param, validated_value)

                set_nested_key(validated_args, lineage, validated_value)
            except KeyError:  # argument was not found, checking whether required and using defaults if not
                if param.required:
                    if not enforce_required:
                        continue  # this argument will be missing from the dict as required fields have no default value
                    elif enforce_required == 1:
                        warnings.warn('Required argument %s missing' % ':'.join(lineage), UserWarning)
                    else:
                        raise ArgumentMissingError(param)
                else:
                    set_nested_key(validated_args, lineage, param.default)
        return validated_args

    def parse_cl_args(self, cl_args=None, prefix='--', short_prefix="-",
                      get_remaining=False, ignore_required=False):
        return self.parameters.parse_cl_args(cl_args, prefix, short_prefix,
                                             get_remaining, ignore_required)

    def generate_ctd_tree(self, arg_dict=None, log=None, cli=False, prefix='--'):
        """Generates an XML ElementTree from the model and returns the top <tool> Element object,
        that can be output to a file (CTDModel.write_ctd() does everything needed if the user
        doesn't need access to the actual element-tree).
        Calling this function without any arguments generates the tool-describing CTD with default
        values. For parameter-storing and logging optional arguments can be passed:

        `arg_dict`: nested dictionary with values to be used instead of defaults.
        `log`: dictionary with the following optional keys:
            'time_start' and 'time_finish': proper XML date strings (eg. datetime.datetime.now(pytz.utc).isoformat())
            'status': exit status
            'output': standard output or whatever output the user intends to log
            'warning': warning logs
            'error': standard error or whatever error log the user wants to store
        `cli`: boolean whether or not cli elements should be generated (needed for GenericKNIMENode for example)
        """
        tool_attribs = collections.OrderedDict()
        tool_attribs['version'] = self.version
        tool_attribs['name'] = self.name
        tool_attribs['xmlns:xsi'] = "http://www.w3.org/2001/XMLSchema-instance"
        tool_attribs['xsi:schemaLocation'] = "https://github.com/genericworkflownodes/CTDopts/raw/master/schemas/CTD_0_3.xsd"

        opt_attribs = ['docurl', 'category']
        for oo in opt_attribs:
            if oo in self.opt_attribs:
                tool_attribs[oo] = self.opt_attribs[oo]

        tool = Element('tool', tool_attribs)  # CTD root

        opt_elements = ['manual', 'description', 'executableName', 'executablePath']

        for oo in opt_elements:
            if oo in self.opt_attribs:
                SubElement(tool, oo).text = self.opt_attribs[oo]

        if log is not None:
            # log is supposed to be a dictionary, with the following keys (none of them being required):
            # time_start, time_finish, status, output, warning, error
            # generate
            log_node = SubElement(tool, 'log')
            if 'time_start' in log:  # expect proper XML date string like datetime.datetime.now(pytz.utc).isoformat()
                log_node.attrib['executionTimeStart'] = log['time_start']
            if 'time_finish' in log:
                log_node.attrib['executionTimeStop'] = log['time_finish']
            if 'status' in log:
                log_node.attrib['executionStatus'] = log['status']
            if 'output' in log:
                SubElement(log_node, 'executionMessage').text = log['output']
            if 'warning' in log:
                SubElement(log_node, 'executionWarning').text = log['warning']
            if 'error' in log:
                SubElement(log_node, 'executionError').text = log['error']

        # all the above was boilerplate, now comes the actual parameter tree generation
        tool.append(self.parameters._xml_node(arg_dict))

        if cli:
            cli_node = SubElement(tool, "cli")
            for e in self.parameters._cli_node(parent_name=self.name, prefix=prefix):
                cli_node.append(e)

        # # LXML w/ pretty print syntax
        # return tostring(tool, pretty_print=True, xml_declaration=True, encoding="UTF-8")

        # xml.etree syntax (no pretty print available, so we use xml.dom.minidom stuff)
        return tool

    def get_parameters(self, nodes=False):
        """return an iterator over all parameters
        """
        yield from self.parameters.get_parameters(nodes)

    def write_ctd(self, out_file, arg_dict=None, log=None, cli=False):
        """Generates a CTD XML from the model and writes it to `out_file`, which is either a string
        to a file path or a stream with a write() method.

        Calling this function without any arguments besides `out_file` generates the tool-describing
        CTD with default values. For parameter-storing and logging optional arguments can be passed:

        `arg_dict`: nested dictionary with values to be used instead of defaults.
        `log`: dictionary with the following optional keys:
            'time_start' and 'time_finish': proper XML date strings (eg. datetime.datetime.now(pytz.utc).isoformat())
            'status': exit status
            'output': standard output or whatever output the user intends to log
            'warning': warning logs
            'error': standard error or whatever error log the user wants to store
        `cli`: boolean whether or not cli elements should be generated (needed for GenericKNIMENode for example)
        """
        write_ctd(self, out_file, arg_dict, log, cli)


def write_ctd(model, out_file, arg_dict=None, log=None, cli=False):
    xml_content = parseString(tostring(model.generate_ctd_tree(arg_dict, log, cli), encoding="UTF-8")).toprettyxml(indent="  ")

    if isinstance(out_file, str):  # if out_file is a string, we create and write the file
        with open(out_file, 'w') as f:
            f.write(xml_content)
    else:  # otherwise we assume it's a writable stream and write into that.
        out_file.write(xml_content)


def args_from_file(filename):
    """Takes a CTD file and returns a nested dictionary with all argument values found. It's not
    linked to a model, so there's no type casting or validation done on the arguments. This is useful
    for users who just want to access arguments in CTD files without having to deal with building a CTD model.

    If type casting or validation is required, two things can be done to hack one's way around it:

    Build a model from the same file and call get_defaults() on it. This takes advantage from the
    fact that when building a model from a CTD, the value attributes are used as defaults. Although
    one shouldn't build a model from an argument storing CTD (as opposed to tool describing CTDs)
    there's no technical obstacle to do so.
    """
    def get_args(element, base=None):
        # recursive argument lookup if encountering <NODE>s
        if element.tag == 'NODE':
            current_group = {}  # OrderedDict()
            for child in element:
                get_args(child, current_group)

            if base is not None:
                base[element.attrib['name']] = current_group
            else:
                # top level <NODE name='1'> is the only one called with base=None.
                # As the argument parsing is recursive, whenever the top node finishes, we are done
                # with the parsing and have to return the results.
                return current_group
        elif element.tag == 'ITEM':
            if 'value' in element.attrib:
                base[element.attrib['name']] = element.attrib['value']
        elif element.tag == 'ITEMLIST':
            if element.getchildren():
                base[element.attrib['name']] = [listitem.attrib['value'] for listitem in element]

    root = parse(filename).getroot()
    param_root = root if root.tag == 'PARAMETERS' else root.find('PARAMETERS')
    parameters = param_root.find('NODE').find('NODE')
    return get_args(parameters, base=None)


def parse_cl_directives(cl_args, write_tool_ctd='write_tool_ctd', write_param_ctd='write_param_ctd',
                        input_ctd='input_ctd', prefix='--'):
    '''Parses command line CTD processing directives. `write_tool_ctd`, `write_param_ctd` and `input_ctd`
    string are customizable, and will be parsed for in command line. `prefix` should be one or two dashes,
    default is '--'.

    Returns a dictionary with keys
        'write_tool_ctd': if flag set, either True or the filename provided in command line. Otherwise None.
        'write_param_ctd': if flag set, either True or the filename provided in command line. Otherwise None.
        'input_ctd': filename if found, otherwise None
    '''
    def transform(x):
        if x is None:
            return None
        elif x == []:
            return True
        else:
            return x[0]

    parser = argparse.ArgumentParser()
    parser.add_argument(prefix + write_tool_ctd, nargs='*')
    parser.add_argument(prefix + write_param_ctd, nargs='*')
    parser.add_argument(prefix + input_ctd, type=str)

    cl_arg_list = cl_args.split() if isinstance(cl_args, str) else cl_args  # string or list of args
    directives, rest = parser.parse_known_args(cl_arg_list)
    directives = vars(directives)

    parsed_directives = {}
    parsed_directives['write_tool_ctd'] = transform(directives[write_tool_ctd])
    parsed_directives['write_param_ctd'] = transform(directives[write_param_ctd])
    parsed_directives['input_ctd'] = directives[input_ctd]

    return parsed_directives


# TODO: ElementTree does not provide line information... maybe refactor using lxml or other parser that does support it?
def validate_contains_keys(dictionary, keys, element_tag):
    for key in keys:
        assert key in dictionary, "Missing required attribute '%s' in %s element. Present attributes: %s" % \
                                  (key, element_tag,
                                   ', '.join(['{0}="{1}"'.format(k, v) for k, v in dictionary.items()]))
