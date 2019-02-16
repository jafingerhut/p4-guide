#! /usr/bin/env python

from __future__ import print_function
import os, sys
import glob
import re
import subprocess


def extract_pass_numbers(fname_lst):
    pass_num_to_fname = {}
    number_strs = []
    for fname in fname_lst:
        match = re.match(r"""^.+-.+_(\d+)_[^_]+\.p4$""", fname)
        assert match
        pass_num = int(match.group(1))
        assert pass_num not in pass_num_to_fname
        pass_num_to_fname[pass_num] = fname
    return pass_num_to_fname


frontend_fnames = glob.glob('*-FrontEnd_*.p4')
midend_fnames = glob.glob('*MidEnd_*.p4')

fd = extract_pass_numbers(frontend_fnames)
md = extract_pass_numbers(midend_fnames)

assert sorted(fd.keys()) == range(len(fd))
assert sorted(md.keys()) == range(len(md))

all_fnames = []
for pass_num in sorted(fd.keys()):
    all_fnames.append(fd[pass_num])
for pass_num in sorted(md.keys()):
    all_fnames.append(md[pass_num])

for i in range(len(all_fnames) - 1):
    print('----------------------------------------------------------------------')
    print('diff %s %s' % (all_fnames[i], all_fnames[i+1]))
    sys.stdout.flush()
    args = ['diff', all_fnames[i], all_fnames[i+1]]
    subprocess.call(args)
    sys.stdout.flush()
