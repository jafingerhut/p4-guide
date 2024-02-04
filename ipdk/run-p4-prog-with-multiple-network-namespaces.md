# Compiling a P4 program, loading it into infrap4d, sending packets in, and capturing packets out, with Linux network namespaces

Prerequisites: You have started the container, and followed the steps
described in the section [Useful extra software to install in the
container](general-ipdk-notes.md#useful-extra-software-to-install-in-the-container).

The scripts below were adapted with minor variations from
`rundemo_TAP_IO.sh`, which is included with IPDK.  The scripts perform
these functions:

+ `setup_2tapports.sh` - Starts up an `infrap4d` process, creates a
  network namespace, and connects that namespace via two TAP
  interfaces to the `infrap4d` process.
+ `compile-in-cont.sh` - Compiles the source code of a P4 program to
  produce a P4Info file and a DPDK binary file.
  + The `-in-cont` part of its name means that this shell script is
    only intended for using within the container, not in the base OS.
    That is true of most of the scripts with `*.sh` names described
    here, but there is also a `compile-base-os.sh` script described
    later that performs a similar task, but is only intended for using
    in the base OS (if you have installed the `p4c-dpdk` compiler in
    the base OS).
+ `load_p4_prog.sh` - Loads a P4Info file and compiled DPDK binary
  file into into the running `infrap4d` process.

`rundemo_TAP_IO.sh` does very similar steps as all of the above
combined, one after the other, followed by running a couple of `ping`
commands to test packet forwarding through `infrap4d`.  These separate
scripts give a user a little bit more fine-grained control over when
they want to perform these steps.

Example command lines for these commands are described below.

In the container:
```bash
/tmp/bin/setup_2tapports.sh
```

This directory in the container already has the source code for a
small P4 program, as well as a `.conf` file, although one of the
scripts below will overwrite that `.conf` file with its own contents.

In the container:
```bash
cd /root/examples/simple_l3
```

For `compile-in-cont.sh`, `-p` specifies the directory where the
source file specified by `-s` can be found, and is also the directory
where the compiled output files are written if compilation succeeds.
The `-a` option specifies whether to compile the program with the
`pna` or `psa` architecture, defaulting to `pna` if not specified.

In the container:
```bash
/tmp/bin/compile-in-cont.sh -p . -s simple_l3.p4 -a psa
cd /root/examples/simple_l3/out
/tmp/bin/tdi_pipeline_builder.sh -p . -s simple_l3.p4
```

For `load_p4_prog.sh`, `-p` specifies the compiled binary file to load
into the `infrap4d` process, which has a suffix of `.pb.bin` in place
of the `.p4` when created by the `compile-in-cont.sh` script.  The
option `-i` specifies the P4Info file, which when created by
`compile-in-cont.sh` always has the suffix `.p4Info.txt`.

In the container:
```bash
/tmp/bin/load_p4_prog.sh -p simple_l3.pb.bin -i simple_l3.p4Info.txt
```

Troubleshooting: In my testing, attempting to load a P4 program into
the same `infrap4d` process more than once fails after the first time
with an error message like this:

```
Error: P4Runtime RPC error (FAILED_PRECONDITION): Only a single forwarding pipeline can be pushed for any node so far.
```

This might be a restriction imposed by `infrap4d`.  A workaround is to
kill the `infrap4d` process, start a new one, and load the desired P4
program into the new `infrap4d` process.


## An exercise in using those scripts

Prerequisites: You have started the container, and followed the steps
described in the section [Useful extra software to install in the
container](general-ipdk-notes.md#useful-extra-software-to-install-in-the-container).

Copy a modified version of the `simple_l3.p4` P4 program that we have
been using up to this point.

In the base OS:
```bash
cp -pr ~/p4-guide/ipdk/simple_l3_modecr/ ~/.ipdk/volume/
```

The directory `simple_l3_modecr` already contains a pcap file that can
be used for sending packets.  See the program `gen-pcaps.py` in that
directory for how it was created.

In the container:
```bash
source $HOME/my-venv/bin/activate
cp -pr /tmp/simple_l3_modecr/ /root/examples/
cd /root/examples/simple_l3_modecr

/tmp/bin/compile-in-cont.sh -p . -s simple_l3_modecr.p4 -a psa
cd /root/examples/simple_l3_modecr/out
/tmp/bin/tdi_pipeline_builder.sh -p . -s simple_l3_modecr.p4
/tmp/bin/setup_2tapports.sh
/tmp/bin/load_p4_prog.sh -p simple_l3_modecr.pb.bin -i simple_l3_modecr.p4Info.txt

# Run tiny controller program that adds a couple of table entries via
# P4Runtime API
PYTHON_PATH="/tmp/pylib" /root/examples/simple_l3_modecr/controller.py

# Check if table entries have been added
p4rt-ctl dump-entries br0
```

The output from the `p4rt-ctl dump-entries br0` command above should
look very similar to this if everything went well:

```bash
Table entries for bridge br0:
  table=ingress.ipv4_host hdr.ipv4.dst_addr=0x01010101 actions=ingress.send(port=0x00000000)
  table=ingress.ipv4_host hdr.ipv4.dst_addr=0x02020202 actions=ingress.send(port=0x00000001)
```

Set up `tcpdump` to capture packets coming out of the switch to the TAP1
interface:

In the container:
```bash
cd /root/examples/simple_l3_modecr
ip netns exec VM0 tcpdump -i TAP1 -w TAP1-try1.pcap &
```

Use `tcpreplay` to send packets into the switch on TAP0 interface:

In the container:
```bash
ip netns exec VM0 tcpreplay -i TAP0 pkt1.pcap
```

Kill the `tcpdump` process so it completes writing packets to the file
and stops appending more data to the file.

In the container:
```bash
killall tcpdump
```

You can copy the file `TAP1-try1.pcap` to the base OS and use
`tshark`, `wireshark`, or any program you like to examine it.

In the container:
```bash
cp TAP1-try1.pcap /tmp
```

Now use commands like one of those below.  There are many command line
options that cause `tshark` to generate different output formats
describing packets.

In the base OS:
```bash
tshark -V -r ~/.ipdk/volume/TAP1-try1.pcap
wireshark ~/.ipdk/volume/TAP1-try1.pcap
```
