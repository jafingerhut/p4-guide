#! /usr/bin/env python3
# Copyright 2020 Andy Fingerhut
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


import re
import sys

print("py3localpath.py debug output.  sys.path contains:", file=sys.stderr)
for x in sys.path:
    print("    %s" % (x), file=sys.stderr)

l1=[x for x in sys.path if re.match(r'/usr/local/lib/python3.[0-9]+/dist-packages', x)]

if len(l1) == 1:
    py3distdir = l1[0]
    m = re.match(r'(/usr/local/lib/python3.[0-9]+)/dist-packages', l1[0])
    if m:
        print(m.group(1))
    else:
        print("Inconceivable!  Somehow the second pattern did not match but the first did.", file=sys.stderr)
        sys.exit(1)
else:
    print("Found %d matching entries in Python3 sys.path instead of 1: %s"
          % (len(l1), l1), file=sys.stderr)
    sys.exit(1)

sys.exit(0)
