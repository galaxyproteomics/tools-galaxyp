import sys
import os
import re
import string
import commands
from optparse import OptionParser
from tempfile import NamedTemporaryFile

def main():
  parser = OptionParser()
  parser.add_option("--input", dest="input")
  parser.add_option("--output", dest="output")
  parser.add_option("--pattern", dest="patterns", action="append",
                    help="regex pattern for replacement")
  parser.add_option("--replacement", dest="replacements", action="append",
                    help="replacement for regex match")
  parser.add_option("--column", dest="column", default=None)
  (options, args) = parser.parse_args()

  mapped_chars = { '\'' :'__sq__', '\\' : '__backslash__' }

  column = None
  if options.column is not None:
    column = int(options.column) - 1 # galaxy tabular is 1-based, python array are zero-based 

  with open(options.input, 'r') as input:
    with open(options.output, 'w') as output:
      while True:
        line = input.readline()
        if line == "":
          break
        for (pattern, replacement) in zip(options.patterns, options.replacements):
          for key, value in mapped_chars.items():
            pattern = pattern.replace(value, key)
            replacement = replacement.replace(value, key)
          if column is None:
            line = re.sub(pattern, replacement, line)
          else:
            cells = line.split("\t")
            if cells and len(cells) > column:
              cell = cells[column]
              cell = re.sub(pattern, replacement, cell)
              cells[column] = cell
              line = "\t".join(cells)
        output.write(line)

if __name__ == "__main__":
    main()
