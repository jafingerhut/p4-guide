#! /usr/bin/env python3

import argparse
import collections
import fileinput
import os
import re

# s1='2433   gnome-terminal-    24   0 /usr/share/icons/Yaru/scalable/ui/tab-new-symbolic.svg'
# s2='2433   gnome-terminal-    24   0 /usr/share/icons/Yaru/scalable/ui/tab-new-symbolic. svg'
# s1.split(maxsplit=4)
# s2.split(maxsplit=4)

procname_to_counts = {}
n = 0
for line in fileinput.input():
    line = line.rstrip()
    n += 1
    if n <= 2:
        # Ignore the first 2 lines of opensnoop-bpfcc output, as it
        # seems to usually be somewhat garbled.
        continue
    match = re.match(r"^Possibly lost \d+ samples$", line)
    if match:
        continue
    try:
        pid_str, procname, filedesc_str, err_str, path = line.split(maxsplit=4)
    except Exception as e:
        print("ERROR: exception trying to split line %d: %s"
              "" % (n, line))
        continue
    if procname not in procname_to_counts:
        procname_to_counts[procname] = collections.defaultdict(int)
    procname_to_counts[procname][path] += 1

for procname in sorted(procname_to_counts.keys()):
    for path in sorted(procname_to_counts[procname].keys()):
        print("%6d PROC= %-20s PATH= %s" % (procname_to_counts[procname][path],
                                            procname, path))
