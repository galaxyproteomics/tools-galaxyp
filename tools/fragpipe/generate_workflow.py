#!/usr/bin/env python3

#
# Generates a FragPipe Workflow file.
#

import pathlib
import sys

default_workflow = sys.argv[1]
user_params_filename = sys.argv[2]
output_workflow_filename = sys.argv[3]

# Default workflow as packaged in the Galaxy $__tool_directory__
default_workflow_path = pathlib.Path(__file__).resolve().parent.joinpath(f'workflows/{default_workflow}.workflow')

# Collect comments separately from parameters
comments = []

# Dictionary with workflow parameters
wfdict = {}

# Initialize workflow dictionary with defaults
with open(default_workflow_path, 'r') as inf:
    for line in inf:
        if line.startswith('#'):
            comments.append(line)
        elif line.strip() != '':
            kv = line.strip().split('=')
            if len(kv) < 2:
                kv.append('')
            wfdict[kv[0]] = '='.join(kv[1:])

# Overwrite with user parameters from Galaxy
with open(user_params_filename, 'r') as inf:
    for line in inf:
        if line.strip() != '':
            kv = line.strip().split('=')
            if len(kv) < 2:
                kv.append('')
            wfdict[kv[0]] = '='.join(kv[1:])

# Output comments and parameter definitions to workflow file
with open(output_workflow_filename, 'w') as outf:
    for comment in comments:
        print(comment, file=outf)
    for k in sorted(wfdict.keys()):
        kv = f'{k}={wfdict[k]}'
        print(kv, file=outf)
