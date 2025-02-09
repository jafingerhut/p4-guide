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
my_dev1_id=1

ssl_opts = shu.ssl_opts_for_certs_directory(certs_dir)

sh.setup(device_id=my_dev1_id,
         grpc_addr=my_dev1_addr,
         election_id=(0, 1),
         ssl_options=ssl_opts,
         verbose=False)

def add_ct_tcp_table_entry_action_ct_tcp_table_hit(ipv4_src_addr_str,
                                                   ipv4_dst_addr_str,
                                                   ipv4_proto_int,
                                                   tcp_src_port_int,
                                                   tcp_dst_port_int):
    te = sh.TableEntry('ct_tcp_table')(action='ct_tcp_table_hit')
    te.match['src_addr'] = '%s' % (ipv4_src_addr_str)
    te.match['dst_addr'] = '%s' % (ipv4_dst_addr_str)
    te.match['protocol'] = '%d' % (ipv4_proto_int)
    te.match['src_port'] = '%d' % (tcp_src_port_int)
    te.match['dst_port'] = '%d' % (tcp_dst_port_int)
    te.insert()

add_ct_tcp_table_entry_action_ct_tcp_table_hit("1.1.1.1", "2.2.2.2",
                                               6, 20, 80)

sh.teardown()
