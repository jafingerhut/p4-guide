#! /usr/bin/env python3
# Copyright 2024 Andy Fingerhut
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


import sys

import p4runtime_sh.shell as sh
import p4runtime_sh.p4runtime as p4rt
import p4runtime_shell_utils as shu


if len(sys.argv) == 1:
    certs_dir = '/usr/share/stratum/certs'
elif len(sys.argv) == 2:
    certs_dir = sys.argv[1]

my_dev1_addr='localhost:9559'
# Note: In my attempts, using my_dev1_id=0 failed to connect
my_dev1_id=1

ssl_opts = shu.ssl_opts_for_certs_directory(certs_dir)

sh.setup(device_id=my_dev1_id,
         grpc_addr=my_dev1_addr,
         election_id=(0, 1),
         ssl_options=ssl_opts,
         verbose=False)

# TODO: Is there a more recommended way in a Python program using the
# p4runtime_sh module to access context than the following?

c = sh.context

print()
print("----- all tables in P4Info -----")
tables = list(c.get_tables())
print(tables)

# The following are useful for interactive experiments, at least.
#len(tables)   # 1
#t1 = tables[0]
#type(t1)      # tuple
#len(t1)       # 2
#type(t1[0])   # str
#type(t1[1])   # <class 'p4.config.v1.p4info_pb2.Table'>

if False:
    print()
    print("----- all actions in P4Info -----")
    actions = list(c.get_actions())
    print(actions)

#len(actions)  # 3
#a1 = actions[0]
#type(a1)      # tuple
#len(a1)       # 2
#type(a1[0])   # str
#type(a1[1])   # <class 'p4.config.v1.p4info_pb2.Action'>

print()
print("----- entries in table ipv4_host -----")
te = sh.TableEntry('ipv4_host')
for x in te.read():
	print(x)

sh.teardown()
