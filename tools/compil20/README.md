This is a work-in-progress implementation of a Galaxy wrapper to search ComPIL 2.0 databases. It consists of two components:

ProLuCID-ComPIL: The search component of ComPIL 2.0.
DTASelect: Used for post-processing of the ProLuCID-ComPIL results.

A conda package has not yet been created, so the following dependencies must be in the $__tool_directory__:
    - $__tool_directory__/prolucid_compil.jar
    - $__tool_directory__/DTASelect - containing DTASelect class files
