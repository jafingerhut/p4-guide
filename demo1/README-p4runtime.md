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
you started `sysrepod` when this command is run.  To check whether the command had the intended side effect, run this command, and compare to see if it is at least similar to the output here: 

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

One-time setup for Python packages:

```bash
# Note: On 2018-Oct-15 on an Ubuntu 16.04 machine, this installed
# grpcio 1.15.0
pip install grpcio

# Note: On 2018-Oct-15 on an Ubuntu 16.04 machine, this installed
# protobuf 3.6.1
pip install protobuf
```

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

import grpc
from p4.v1 import p4runtime_pb2
from p4.config.v1 import p4info_pb2
from p4.tmp import p4config_pb2
import google.protobuf.text_format
from gnmi import gnmi_pb2

# I copied and adapted the function bmv2_json_to_device_config() from
# some similar code in the program gen_bmv2_config.py

def bmv2_json_to_device_config(bmv2_json_fname, bmv2_bin_fname):
    with open(bmv2_bin_fname, 'wf') as f_out:
        with open(bmv2_json_fname, 'r') as f_json:
            device_config = p4config_pb2.P4DeviceConfig()
            device_config.device_data = f_json.read()
            f_out.write(device_config.SerializeToString())

# Copied update_config from $P4_INSTALL/PI/proto/ptf/ptf_runner.py,
# then modified it slightly:

def update_config(config_path, p4info_path, grpc_addr, device_id):
    '''
    Performs a SetForwardingPipelineConfig on the device with provided
    P4Info and binary device config
    '''
    channel = grpc.insecure_channel(grpc_addr)
    stub = p4runtime_pb2.P4RuntimeStub(channel)
    print("Sending P4 config")
    request = p4runtime_pb2.SetForwardingPipelineConfigRequest()
    request.device_id = device_id
    config = request.config
    with open(p4info_path, 'r') as p4info_f:
        google.protobuf.text_format.Merge(p4info_f.read(), config.p4info)
    with open(config_path, 'rb') as config_f:
        config.p4_device_config = config_f.read()
    request.action = p4runtime_pb2.SetForwardingPipelineConfigRequest.VERIFY_AND_COMMIT
    try:
        response = stub.SetForwardingPipelineConfig(request)
    except Exception as e:
        print("Error during SetForwardingPipelineConfig")
        print(str(e))
        return False
    return True


# Convert BMv2 JSON file from p4c compiler into the binary format
# expected by BMv2 over P4Runtime.

bmv2_json_to_device_config('demo1.p4_16.json', 'demo1.p4_16.bin')

# This failed when my_dev1_id was 17, with an error message of "Error
# when trying to assign device".  It gave no error when I instead used
# my_dev1_id=0.

update_config('demo1.p4_16.bin', 'demo1.p4_16.p4rt.txt', my_dev1_addr, my_dev1_id)

```
    
To run CLI for controlling and examining simple_switch's table
contents:

    simple_switch_CLI

General syntax for table_add commands at simple_switch_CLI prompt:

    RuntimeCmd: help table_add
    Add entry to a match table: table_add <table name> <action name> <match fields> => <action parameters> [priority]

----------------------------------------------------------------------
demo1.p4_14.p4 or demo1.p4_16.p4 (same commands work for both)
----------------------------------------------------------------------

    table_set_default ipv4_da_lpm my_drop
    table_set_default mac_da my_drop
    table_set_default send_frame my_drop

    table_add ipv4_da_lpm set_l2ptr 10.1.0.1/32 => 58
    table_add mac_da set_bd_dmac_intf 58 => 9 02:13:57:ab:cd:ef 2
    table_add send_frame rewrite_mac 9 => 00:11:22:33:44:55

Another set of table entries to forward packets to a different output
interface:

    # Version with dotted decimal IPv4 address and : separators inside
    # of hexadecimal Ethernet addresses.
    table_add ipv4_da_lpm set_l2ptr 10.1.0.200/32 => 81
    table_add mac_da set_bd_dmac_intf 81 => 15 08:de:ad:be:ef:00 4
    table_add send_frame rewrite_mac 15 => ca:fe:ba:be:d0:0d

    # Version with hex values instead of the above versions.
    # Note: the prefix length after the / character must be decimal.
    # I tried 0x20 and simple_switch_CLI raised an exception and
    # exited.
    table_add ipv4_da_lpm set_l2ptr 0x0a0100c8/32 => 0x51
    table_add mac_da set_bd_dmac_intf 0x51 => 0xf 0x08deadbeef00 0x4
    table_add send_frame rewrite_mac 0xf => 0xcafebabed00d

You can examine the existing entries in a table with 'table_dump':

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

The numbers on the "Dumping entry <number>" lines are 'table entry
handle ids'.  The table API implementation allocates a unique handle
id when adding a new entry, and you must provide that value to delete
the table entry.  The handle id is unique per entry, as long as the
entry remains in the table.  After removing an entry, its handle id
may be reused for a future entry added to the table.

Handle ids are _not_ unique across all tables.  Only the pair
<table,handle_id> is unique.


----------------------------------------------------------------------
scapy session for sending packets
----------------------------------------------------------------------
Any process that you want to have permission to send and receive
packets on Ethernet interfaces (such as the veth virtual interfaces)
must run as the super-user root, hence the use of `sudo`:

    sudo scapy

    fwd_pkt1=Ether() / IP(dst='10.1.0.1') / TCP(sport=5793, dport=80)
    drop_pkt1=Ether() / IP(dst='10.1.0.34') / TCP(sport=5793, dport=80)

    # Send packet at layer2, specifying interface
    sendp(fwd_pkt1, iface="veth2")
    sendp(drop_pkt1, iface="veth2")

    fwd_pkt2=Ether() / IP(dst='10.1.0.1') / TCP(sport=5793, dport=80) / Raw('The quick brown fox jumped over the lazy dog.')
    sendp(fwd_pkt2, iface="veth2")

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
