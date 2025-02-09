#!/usr/bin/env python

# Copyright 2018 Cisco Systems, Inc.
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
from collections import OrderedDict
import json
import os
import sys

if len(sys.argv) != 4:
    print("usage: %s <config-file> <config-file-backup-name> <dot-cmd-path>"
          "" % (sys.argv[0]))
    sys.exit(1)

config_fname = sys.argv[1]
config_backup_fname = sys.argv[2]
dot_cmd_path = sys.argv[3]
#print("config_fname=:%s:" % (config_fname))
#print("[2]=:%s:" % (config_backup_fname))
#print("[3]=:%s:" % (dot_cmd_path))
#sys.exit(0)

os.rename(config_fname, config_backup_fname)
with open(config_backup_fname, 'r') as f:
    contents_str = f.read()
# Use object_pairs_hook=OrderedDict so that when printing the JSON
# back out, it should preserve the order of key/value pairs that was
# read in.  This makes it easier to compare the original and modified
# files to each other.
contents_dat = json.loads(contents_str, object_pairs_hook=OrderedDict)
contents_dat['locations']['graphviz'] = dot_cmd_path
with open(config_fname, 'w') as f:
    print(json.dumps(contents_dat, indent=8), file=f)
sys.exit(0)
