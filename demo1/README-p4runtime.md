# Compiling

See [README-using-bmv2.md](../README-using-bmv2.md) for some things
that are common across different P4 programs executed using bmv2.

To compile the P4_16 version of the code, in file `demo1.p4_16.p4`:

    p4c --target bmv2 --arch v1model --p4runtime-file demo1.p4_16.p4rt.txt --p4runtime-format text demo1.p4_16.p4

Running that command will create these files:

    demo1.p4_16.p4i - the output of running only the preprocessor on
        the P4 source program.
    demo1.p4_16.json - the JSON file format expected by BMv2
        behavioral model `simple_switch`.
    demo1.p4_16.p4rt - the binary format of the file that describes
        the P4Runtime API of the program.

Only the two files with the `.json` suffix are needed to run your P4
program.  You can ignore the file with suffix `.p4i` unless you
suspect that the preprocessor is doing something unexpected with your
program.

To compile the P4_14 version of the code:

    TBD: update this
    p4c --std p4-14 --target bmv2 --arch v1model demo1.p4_14.p4
                                                 ^^^^^^^^^^^^^^ source code
        ^^^^^^^^^^^ specify P4_14 source code

The .dot and .png files in the subdirectory 'graphs' were created with
the p4c-graphs program, which is also installed when you build and
install p4c:

     p4c-graphs -I $HOME/p4c/p4include demo1.p4_16.p4

The '-I' option is only necessary if you did _not_ install the P4
compiler in your system-wide /usr/local/bin directory.


# Running

Once after booting your system, you should run the sysrepod daemon
using this command, preferably in a separate terminal window where you
can watch for error messages in its output:

    sudo sysrepod -d

Run this command to install some YANG data models into the sysrepo
daemon:

    sudo $PI_SYSREPO/install_yangs.sh

Note: It is _normal_ to see many error messages in the window where
you started `sysrepod` when this command is run.  To check whether the command had the intended side effect, run this command:

    sysrepoctl -l

and compare to see if it is at least similar to the output here: 

    https://github.com/p4lang/PI/blob/master/proto/README.md



To run the behavioral model with 8 ports numbered 0 through 7:

    sudo simple_switch_grpc --log-console -i 0@veth2 -i 1@veth4 -i 2@veth6 -i 3@veth8 -i 4@veth10 -i 5@veth12 -i 6@veth14 -i 7@veth16 --no-p4

To get the log to go to a file instead of the console:

    sudo simple_switch_grpc --log-file ss-log --log-flush -i 0@veth2 -i 1@veth4 -i 2@veth6 -i 3@veth8 -i 4@veth10 -i 5@veth12 -i 6@veth14 -i 7@veth16 --no-p4

CHECK THIS: If you see "Add port operation failed" messages in the
output of the simple_switch command, it means that one or more of the
virtual Ethernet interfaces veth2, veth4, etc. have not been created
on your system.  Search for "veth" in the file
[`README-using-bmv2.md`](../README-using-bmv2.md`) (top level
directory of this repository) for a command to create them.

If you see this error message:

    [16:36:10.433] [bmv2] [E] [thread 7845] Error by sr_module_change_subscribe for 'openconfig-interfaces': Requested schema model is not known

Then you need to run the commands starting with `sysrepod` above.


See the file
[`README-troubleshooting.md`](../README-troubleshooting.md) in case
you run into troubles.  It describes symptoms of some problems, and
things you can do to resolve them.

To start an interactive Python session that can be used to load the
compiled P4 program into the running `simple_switch_grpc` process, and
install table entries:

```bash
cd $P4INSTALL/p4-guide/demo1
python
```

Enter these commands at the `>>> ` prompt of the Python session:

```python
# Note: 50051 is the default TCP port number on which the
# simple_switch_grpc process is listening for connections.
my_dev1_addr='localhost:50051'
my_dev1_id=0

import base_test

# Convert BMv2 JSON file from p4c compiler into the binary format
# expected by BMv2 over P4Runtime.
base_test.bmv2_json_to_device_config('demo1.p4_16.json', 'demo1.p4_16.bin')

# Load the binary version of the compiled P4 program, and the text
# version of the P4Runtime info file, into the device.
base_test.update_config('demo1.p4_16.bin', 'demo1.p4_16.p4rt.txt', my_dev1_addr, my_dev1_id)
h=base_test.P4RuntimeTest()
h.setUp(my_dev1_addr, 'demo1.p4_16.p4rt.txt')
```

----------------------------------------------------------------------
demo1.p4_14.p4 or demo1.p4_16.p4 (same commands work for both)
----------------------------------------------------------------------

```python
# The full names of the tables and actions begin with 'ingress.' or
# 'egress.', but some layer of software between here and there adds
# these on for you, as long as the table/action name is unique after
# that point.

# assign default actions for tables using a key of None
h.table_add('ipv4_da_lpm', None, 'my_drop', [])
h.table_add('mac_da', None, 'my_drop', [])
h.table_add('send_frame', None, 'my_drop', [])

# add new non-default table entries by filling in at least one key field

# base_test.ipv4_to_binary takes an IPv4 address written as a string
# in dotted decimal notation, and converts it to a string with binary
# contents expected by table add operation.

# base_test.mac_to_binary is similar, but takes a MAC address as a
# string, with colons separating each byte, specified in hex.

# base_test.stringify takes an integer value, and an integer width in
# _bytes_ as the second parameter, and returns a string with binary
# contents expected by table add operation.

# Define a few small helper functions that help construct parameters
# for the function table_add()

def ipv4_da_lpm_key(h, ipv4_addr_string, prefix_len):
    return [h.Lpm('hdr.ipv4.dstAddr',
                  base_test.ipv4_to_binary(ipv4_addr_string), prefix_len)]

def set_l2ptr_params(h, l2ptr_int_val):
    return [('l2ptr', base_test.stringify(l2ptr_int_val, 4))]

def mac_da_key(h, l2ptr_int_val):
    return [h.Exact('meta.fwd_metadata.l2ptr',
                    base_test.stringify(l2ptr_int_val, 4))]

def set_bd_dmac_intf_params(h, bd_int_val, dmac_string, intf_int_val):
    return [('bd', base_test.stringify(bd_int_val, 3)),
            ('dmac', base_test.mac_to_binary(dmac_string)),
	    ('intf', base_test.stringify(intf_int_val, 2))]

def send_frame_key(h, bd_int_val):
    return [h.Exact('meta.fwd_metadata.out_bd',
                    base_test.stringify(bd_int_val, 3))]

def rewrite_mac_params(h, smac_string):
    return [('smac', base_test.mac_to_binary(smac_string))]

h.table_add('ipv4_da_lpm', ipv4_da_lpm_key(h, '10.1.0.1', 32), 'set_l2ptr', set_l2ptr_params(h, 58))
h.table_add('mac_da', mac_da_key(h, 58), 'set_bd_dmac_intf', set_bd_dmac_intf_params(h, 9, '02:13:57:ab:cd:ef', 2))
h.table_add('send_frame', send_frame_key(h, 9), 'rewrite_mac', rewrite_mac_params(h, '00:11:22:33:44:55'))

```

Another set of table entries to forward packets to a different output
interface:

```python
h.table_add('ipv4_da_lpm', ipv4_da_lpm_key(h, '10.1.0.200', 32), 'set_l2ptr', set_l2ptr_params(h, 81))
h.table_add('mac_da', mac_da_key(h, 81), 'set_bd_dmac_intf', set_bd_dmac_intf_params(h, 15, '08:de:ad:be:ef:00', 4))
h.table_add('send_frame', send_frame_key(h, 15), 'rewrite_mac', rewrite_mac_params(h, 'ca:fe:ba:be:d0:0d'))
```

You can examine the existing entries in a table using the
`simple_switch_CLI` command (best from a separate terminal window)
with the 'table_dump' command:

```bash
simple_switch_CLI
```

```
table_dump ipv4_da_lpm
==========
TABLE ENTRIES
**********
Dumping entry 0x0
Match key:
* ipv4.dstAddr        : LPM       0a010001/32
Action entry: set_l2ptr - 3a
**********
Dumping entry 0x1
Match key:
* ipv4.dstAddr        : LPM       0a0100c8/32
Action entry: set_l2ptr - 3a
==========
Dumping default entry
Action entry: my_drop - 
==========
```


----------------------------------------------------------------------
scapy session for sending packets
----------------------------------------------------------------------
Any process that you want to have permission to send and receive
packets on Ethernet interfaces (such as the veth virtual interfaces)
must run as the super-user root, hence the use of `sudo`:

```base
sudo scapy
```

```python
fwd_pkt1=Ether() / IP(dst='10.1.0.1') / TCP(sport=5793, dport=80)
drop_pkt1=Ether() / IP(dst='10.1.0.34') / TCP(sport=5793, dport=80)

# Send packet at layer2, specifying interface
sendp(fwd_pkt1, iface="veth2")
sendp(drop_pkt1, iface="veth2")

fwd_pkt2=Ether() / IP(dst='10.1.0.1') / TCP(sport=5793, dport=80) / Raw('The quick brown fox jumped over the lazy dog.')
sendp(fwd_pkt2, iface="veth2")
```

----------------------------------------


# Patterns

The example table entries and sample packet given above can be
generalized to the following pattern.

If you send an input packet like this, specified as Python code when
using the Scapy library:

    input port: anything
    Ether() / IP(dst=<hdr.ipv4.dstAddr>, ttl=<ttl>)

and you create the following table entries:

    table_add ipv4_da_lpm set_l2ptr <hdr.ipv4.dstAddr>/32 => <l2ptr>
    table_add mac_da set_bd_dmac_intf <l2ptr> => <out_bd> <dmac> <out_intf>
    table_add send_frame rewrite_mac <out_bd> => <smac>

then the P4 program should produce an output packet like the one
below, matching the input packet in every way except, except for the
fields explicitly mentioned:

    output port: <out_intf>
    Ether(src=<smac>, dst=<dmac>) / IP(dst=<hdr.ipv4.dstAddr>, ttl=<ttl>-1)
