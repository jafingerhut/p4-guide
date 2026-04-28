#! /usr/bin/env python3

import argparse
import collections
import fileinput
import os
import re
import sys

# parse arguments to get:

# path_lst_fname - A file name containing one file path per line.  The
# user is interested to know which of these files were opened,
# vs. which were not.

# accessed_paths_fname - A file name containing the output of the
# program file-access-stats.py, with one line for each file name that
# was opened.

# The main reason that this task has a separate program for it is that
# while the paths in path_lst should all be absolute paths starting
# with /, the paths in accessed_paths may be a mix of some absolute
# paths and some relative paths.  We do not have information on the
# current working directory of the relative paths, but we can
# determine whether a relative path is a suffix of a path in path_lst,
# and therefore _might_ be a match.

def suffixes_of(path):
    segments = path.split('/')
    if segments[0] == "":
        segments = segments[1:]
    ret = []
    for j in range(1, len(segments)):
        suffix = '/'.join(segments[j:])
        ret.append(suffix)
    return ret

# TODO: Use argparse to get values of these parameters:
path_lst_fname = sys.argv[1]
accessed_paths_fname = sys.argv[2]

# Read path_lst_fname into paths
paths = set()
for line in fileinput.input([path_lst_fname]):
    path = line.strip()
    if path in paths:
        print("WARNING: path '%s' occurs multiple times in file '%s'"
              "" % (path, path_lst_fname))
    else:
        paths.add(path)

# For each suffix of an absolute path in paths, add a key of that
# suffix to the dict suffixes.  The value is a list of elements of
# paths for which the key is a suffix.
suffixes = collections.defaultdict(list)
for path in paths:
    suffixes_of_path = suffixes_of(path)
    for s in suffixes_of_path:
        suffixes[s].append(path)

# Read accessed_paths_fname into accessed_paths
accessed_paths = set()
for line in fileinput.input([accessed_paths_fname]):
    match = re.match(r"""^ERROR: """, line)
    if match:
        continue
    match = re.match(r"""^\s*\d+\s+PROC=\s+(.*)\s+PATH=\s+(.*)$""", line)
    if not match:
        print("ERROR: Unrecognized line data format in file '%s': %s"
              "" % (accessed_paths_fname, line))
        continue
    proc = match.group(1)
    accessed_path = match.group(2)
    accessed_paths.add(accessed_path)

# Determine which accessed_paths are exact matches of a full path, and
# which are potential matches of a suffix.
path_matched_exactly = {}
path_matched_by_suffix = {}
for accessed_path in accessed_paths:
    if accessed_path in paths:
        path_matched_exactly[accessed_path] = None
    elif accessed_path in suffixes:
        for s in suffixes:
            path_matched_by_suffix[s] = None

# For all paths in `path`, print out which of these 3 categories they
# fall under:
#
# (1) The path was definitely accessed, because we found a full
# accessed path that matches exactly
#
# (2) The path may have been accessed, because we only found an
# accessed relative path that matches a suffix of the absolute path.
#
# (3) The path was definitely not accessed, because we found no
# accessed paths that put it in category (1) nor (2).
print("Meaning of first letter on the line:")
print("    N - file was definitely not accessed")
print("    A - file was definitely accessed, because found a full path exact match")
print("    M - file may have been accessed, because found one or more relative paths that match a suffix of this path")
print("----------------------------------------")
     
for path in sorted(paths):
    path_accessed = "N"
    if path in path_matched_exactly:
        path_accessed = "A"
    elif path in path_matched_by_suffix:
        path_accessed = "M"
    print("%s %s" % (path_accessed, path))
