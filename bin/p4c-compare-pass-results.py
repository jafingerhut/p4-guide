#! /usr/bin/env python
# Copyright 2019 Andy Fingerhut
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0


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
