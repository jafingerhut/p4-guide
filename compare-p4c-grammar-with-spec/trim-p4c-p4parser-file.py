#! /usr/bin/env python3

import os, sys
import fileinput
import re

# Read the entire file in as one big string.

lines = []
keep = False
for line in fileinput.input():
    match = re.match(r"^program\s*:", line)
    if match:
        keep = True
        #print("First line kept:\n%s" % (line))
    if keep:
        lines.append(line)

content = ''.join(lines)

# Temporarily replace all occurrences of "{" and "}" (with the double
# quotes there) with a string that does not exist anywhere else in the
# file (I checked manually).  The plan is that later we will replace
# the temporary substitutions back with their original form, but
# we will take advantage of the fact that there are no occurrences of
# { or } inside of strings to do simpler string manipulations.

#content = re.sub(pattern, replacement, content)
content = re.sub('"{"', '"leftbrace"', content)
content = re.sub('"}"', '"rightbrace"', content)

# Try replacing all balanced sets of curly braces, and whatever is
# between them, with empty strings.

while True:
    next = re.sub(r"\{[^{}]*\}", "", content)
    if next == content:
        break
    content = next

# Change curly brackes in strings back
content = re.sub('"leftbrace"', '"{"', content)
content = re.sub('"rightbrace"', '"}"', content)

content = re.sub('%empty', '/* empty */', content)
content = re.sub('l_angle', '"<"', content)
content = re.sub('r_angle', '">"', content)

# Remove blank lines that occur in the middle of the definition of a
# non-terminal.  Relies on the following assumptions, which are
# currently true of the file p4parser.ypp:

# + Non-terminals are first non-whitespace character on a line.
# + The ';' ending the definition of a non-terminal is always on a
#   line by itself.

lines = content.split('\n')
lines2 = []

i = 0
while i < len(lines):
    lines2.append(lines[i])
    i += 1
    nonterminal = re.match(r"^[a-zA-Z]", lines[i])
    if nonterminal:
        while i < len(lines):
            end_of_defn = re.match(r"^\s+;", lines[i])
            if end_of_defn:
                lines2.append(lines[i])
                i += 1
                break
            else:
                blank = re.match(r"^\s*$", lines[i])
                if not blank:
                    lines2.append(lines[i])
                i += 1

content = '\n'.join(lines2)
print(content)
