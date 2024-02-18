# Testing a P4 program for the PNA architecture using add-on-miss

(Verified this section is updated and working on 2024-Feb-03)

I was especially interested in DPDK's implementation of this new
feature in the P4 Portable NIC Architecture
(https://github.com/p4lang/pna), where you can do an apply on a P4
table, and if it gets a miss, the miss action can optionally cause an
entry to be added to the table, without the control plane having to do
so.

Prerequisites: You have started the container, and followed the steps
described in the section [Useful extra software to install in the
container](general-ipdk-notes.md#useful-extra-software-to-install-in-the-container).

In the base OS:
```bash
cp -pr ~/p4-guide/ipdk/add_on_miss0/ ~/.ipdk/volume/
```

This only needs to be run in the container once:
```bash
source $HOME/my-venv/bin/activate
export PYTHON_PATH="/tmp/pylib"
```

In the container:
```bash
cp -pr /tmp/add_on_miss0/ /root/examples/
cd /root/examples/add_on_miss0

/tmp/bin/compile-in-cont.sh -p . -s add_on_miss0.p4 -a pna
cd /tmp/add_on_miss0/out
/tmp/bin/tdi_pipeline_builder.sh -p . -s add_on_miss0.p4
/tmp/bin/setup_2tapports.sh
/tmp/bin/load_p4_prog.sh -p add_on_miss0.pb.bin -i add_on_miss0.p4Info.txt

# Run tiny controller program that adds a couple of table entries via
# P4Runtime API
cd /root/examples/add_on_miss0
./controller.py

# Check if table entries have been added
p4rt-ctl dump-entries br0
```

The directory `/root/examples/add_on_miss0` already contains several
pcap files that can be used for sending packets.  See the program
`gen-pcaps.py` for how they were created.

Set up `tcpdump` to capture packets coming out of the switch to the
TAP1 interface.

In the container:
```bash
ip netns exec VM0 tcpdump -i TAP1 -w TAP1-try1.pcap &
```

Send TCP SYN packet on TAP0 interface, which should cause new entry to
be added to table `ct_tcp_entry`, and also be forwarded out the TAP1
port.  Immediately check the table entries.

In the container:
```bash
ip netns exec VM0 tcpreplay -i TAP0 /root/examples/add_on_miss0/tcp-syn1.pcap
p4rt-ctl dump-entries br0 ct_tcp_table
```

Note: I have asked the DPDK data plane developers, and confirmed that
for p4c-dpdk add-on-miss tables as of 2023-Mar-15, there is currently
no way to read the current set of entries from the control plane.  If
you try, you get back no entries.  That matches the behavior I have
seen.  I have confirmed using `add_on_miss0.p4`, which modifies output
packets differently depending upon whether a `ct_tcp_table` hit or
miss occurred, that I sometimes see misses, then hits for later
packets that are sent before the original table entry ages out.  I
have never seen any entries when trying to read `ct_tcp_table` from
the control plane.

Kill the `tcpdump` process so it completes writing packets to the file
and stops appending more data to the file.

In the container:
```bash
killall tcpdump
```

Attempting to add an entry to the add-on-miss table `ct_tcp_table`
from the control plane returns an error, as shown below:

In the container:
```bash
root@48ac7ef995ac:~/scripts# /root/examples/add_on_miss0/write-ct-tcp-table.py

[ ... some lines of output omitted here for brevity ... ]

Traceback (most recent call last):
  File "/root/examples/add_on_miss0/write-ct-tcp-table.py", line 41, in <module>
    add_ct_tcp_table_entry_action_ct_tcp_table_hit("1.1.1.1", "2.2.2.2",
  File "/root/examples/add_on_miss0/write-ct-tcp-table.py", line 39, in add_ct_tcp_table_entry_action_ct_tcp_table_hit
    te.insert()
  File "/usr/local/lib/python3.8/dist-packages/p4runtime_sh/shell.py", line 694, in insert
    self._write(p4runtime_pb2.Update.INSERT)
  File "/usr/local/lib/python3.8/dist-packages/p4runtime_sh/shell.py", line 688, in _write
    client.write_update(update)
  File "/usr/local/lib/python3.8/dist-packages/p4runtime_sh/p4runtime.py", line 124, in handle
    raise P4RuntimeWriteException(e) from None
p4runtime_sh.p4runtime.P4RuntimeWriteException: Error(s) during Write:
	* At index 0: INTERNAL, 'Error adding table entry with table_name: pipe.MainControlImpl.ct_tcp_table, table_id: 35731637, table_type: 2048, tdi_table_key { hdr.ipv4.src_addr { field_id: 1 key_type: 0 field_size: 32 value: 0x01010101 } hdr.ipv4.dst_addr { field_id: 2 key_type: 0 field_size: 32 value: 0x02020202 } hdr.ipv4.protocol { field_id: 3 key_type: 0 field_size: 8 value: 0x06 } hdr.tcp.src_port { field_id: 4 key_type: 0 field_size: 16 value: 0x0014 } hdr.tcp.dst_port { field_id: 5 key_type: 0 field_size: 16 value: 0x0050 } }, tdi_table_data { action_id: 17749373 }'
```
