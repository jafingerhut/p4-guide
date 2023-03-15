#! /usr/bin/env python3

import sys

import p4runtime_sh.shell as sh
import p4runtime_sh.p4runtime as p4rt


if len(sys.argv) == 1:
    certs_dir = '/usr/share/stratum/certs'
elif len(sys.argv) == 2:
    certs_dir = sys.argv[1]

my_dev1_addr='localhost:9559'
my_dev1_id=1

root_certificate = certs_dir + '/ca.crt'
private_key = certs_dir + '/client.key'
certificate_chain = certs_dir + '/client.crt'
ssl_opts = p4rt.SSLOptions(False, root_certificate, certificate_chain,
                           private_key)

sh.setup(device_id=my_dev1_id,
         grpc_addr=my_dev1_addr,
         election_id=(0, 1),
         ssl_options=ssl_opts)

def add_ipv4_host_entry_action_send(ipv4_addr_str, port_int):
    te = sh.TableEntry('ipv4_host')(action='send')
    te.match['dst_addr'] = '%s' % (ipv4_addr_str)
    te.action['port'] = '%d' % (port_int)
    te.insert()

add_ipv4_host_entry_action_send('1.1.1.1', 0)
add_ipv4_host_entry_action_send('2.2.2.2', 1)

sh.teardown()
