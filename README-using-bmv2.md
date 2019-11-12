# What are the pieces involved in running these demos?

Normally when you have a switch in a production setting, you would
have a physical switch device, often consisting of a switch ASIC plus
a nearby general purpose CPU (e.g. Intel, PowerPC, etc.) running
control plane software that manages the contents of the tables in the
switch ASIC.  The switch ASIC would be connected to physical Ethernet
ports, and those in turn would be connected to ports on other
switches, or to Ethernet ports on hosts.  The control plane software
in commercial switches can easily contain up to tens of millions of
lines of source code, and be developed and maintained by teams of
hundreds of developers.

However, the purpose of these demos is not to teach you how to set
that up.  The focus here is on learning how P4 programs behave, by
using a P4 program for processing data packets, and running it on an
open source switch emulator software called `simple_switch` (or the
similar program `simple_switch_grpc`, but we will often simply say
`simple_switch` here to refer to either program).

Instead of loading the compiled P4 program into a switch ASIC, you
will start up the `simple_switch` process as a normal process running
on a Linux machine (or virtual machine).

Instead of physically connecting multiple devices to each other via
Ethernet cables, we will create 'virtual' Ethernet ports on your Linux
machine, and tell `simple_switch` to treat every packet sent to one of
those virtual Ethernet ports as one that arrived at the software
emulated switch, and it will process the packet via the P4 program.
Any packets sent out by the emulated switch will be transmitted to one
of those virtual Ethernet ports.  A virtual Ethernet port simply means
it is not a physical Ethernet port, but instead one created purely via
a configuration command.  We use them here because they are cheap.

There are existing open source tools for monitoring all packets that
go across an Ethernet port of a system (regardless of whether that
Ethernet port is physical or virtual), and print out some or all of
the contents of those packets in various formats.  Search for
`tcpdump` or `tshark` below for example commands to run those
programs.

There are also multiple open source tools for constructing packets in
memory, or reading them from files, and transmitting them on Ethernet
ports.  The instructions here show a few examples of how to use a
Python library called Scapy for that purpose.  `tcpreplay` is another
open source program that can read packets from a file in `pcap` format
and send them to a port.

Instead of running a complex collection of control plane software, you
will be running simple programs that give you complete control over
exactly which table entries are added to the tables of your P4
program.

+ If you use the newer P4Runtime API with `simple_switch_grpc`, there
  are instructions (currently only for the demo1 program) for running an
  interactive Python session using a small library that creates the
  necessary P4Runtime request messages and sends them to the
  `simple_switch_grpc` process.
+ If you are using the older Thrift API with `simple_switch`
  (`simple_switch_grpc` can also accept such connections), there are
  instructions for running a tiny program called `simple_switch_CLI`
  that has its own custom syntax for commands to add, delete, and
  modify table entries, and other controller operations.

Using a simple command line interface for adding all table entries is
not good for a production switch, as such a device might require
adding hundreds or thousands of table entries before it is in a
sufficiently usable state.  It _is_ good for the demo P4 programs
here, which typically only need 3 to 5 table entries to be added in
order to forward packets.  By requiring you to add any necessary table
entries via a relatively simple command line interface, you can be
fully aware of exactly which table entries have been installed,
because if you did not enter the command to add it, it will not be
there.

The instructions here, unlike the ones in the
[`p4lang/tutorials`](https://github.com/p4lang/tutorials) repository,
have you run only a single emulated switch at a time.  Running
multiple emulated switches is certainly possible, and often useful,
but when you are first learning P4 a single emulated switch is easier
to debug when things are not behaving as you expect.


# What to install for compiling P4 programs and running them on bmv2

See [here](bin/README-install-troubleshooting.md) for a choice among a
couple of scripts included in this repository that, on a freshly
installed Ubuntu Linux machine, will download, compile, and install
the open source P4 development tools on that Linux machine.

That install script will install the following programs into your
`/usr/local/bin` directory (plus more that will rarely or never be
mentioned in the demos in this repository):

    p4c
    simple_switch
    simple_switch_grpc
    simple_switch_CLI


# Other useful commands

See the file [`README-troubleshooting.md`](README-troubleshooting.md)
in case you run into troubles.  It describes symptoms of some
problems, and things you can do to resolve them.

Useful for quickly creating multiple terminal windows and tabs:

```bash
create-terminal-windows.sh
```

To create veth interfaces (replace `p4-guide` with the path to your
copy of the `p4-guide` repository on your machine):

```bash
sudo p4-guide/bin/veth_setup.sh
# Verify that it created many veth<number> interfaces
ip link show | grep veth
```

`tcpdump` and `tshark` are two similar programs that can show the
contents of packets "live" as they cross Ethernet interfaces of your
Linux system, including virtual Ethernet interfaces like veth2 and
veth6.  You only need one of them.  Use `tcpdump` if you are not sure
which one to use.  `tcpdump` is simpler and does not parse as many
different kinds of packet headers.  `tshark` is a text version of
Wireshark, and can parse more packet header types than I have ever
heard of.

```bash
# tcpdump options used:
# -e Print the link-level header (i.e. Ethernet) on each dump line.
# -n Do not convert addresses to names
# --number Print an optional packet number at the beginning of the line.
# -v slightly more verbose output, e.g. TTL values

# Note: Some versions of tcpdump do not accept the --number
# option.  If so, just remove that one.
sudo tcpdump -e -n --number -v -i veth2
sudo tcpdump -e -n --number -v -i veth6

# Add -xx option to get raw hex dump of packet data:
sudo tcpdump -xx -e -n --number -v -i veth2
sudo tcpdump -xx -e -n --number -v -i veth6

# If you want to use tshark for even more details about decoded
# packets, but the output for each packet can often spread over 30
# to 40 lines:
sudo tshark -V -i veth2
sudo tshark -V -i veth6

# Add -x option to get raw hex dump of packet data:
sudo tshark -x -V -i veth2
sudo tshark -x -V -i veth6
```


# Automated running of compiler and bmv2 with checking of results

This is _not_ needed for straightforward running of P4 programs.  This
semi-advanced info, only useful if you want some gory details on how
to run some of the bmv2-based automated tests that come with the open
source p4c compiler.

If you have followed the instructions above to install both the `p4c`
and `behavioral-model` repositories, you should have these two files
of Python code as part of your local copy of the p4lang/p4c
repository, where `$P4C` is the root directory of your copy of the p4c
repository (e.g. if you ran the install script from your home
directory, then `$P4C` is `$HOME/p4c`):

```bash
$P4C/backends/bmv2/run-bmv2-test.py
$P4C/backends/bmv2/bmv2stf.py
```

The first file `import`s the code of the second and uses it.

After you have built your own copy of the p4c compiler, you should
have a directory `$P4C/build` on disk.  If you run these commands:

```bash
cd $P4C/build
make check
```

then as part of running the hundreds of test cases included with p4c,
it runs the `run-bmv2-test.py` program many times.  To run only one of
those test cases, but with extra log message printing enabled, try
these commands:

```bash
cd $P4C/build
../backends/bmv2/run-bmv2-test.py .. -b -v ../testdata/p4_16_samples/issue447-5-bmv2.p4
```

The `-v` is optional, and enables the extra log message printing.
Similarly `-b` is optional, and causes a temporary directory that is
created by `run-bmv2-test.py` to be left on disk after it completes,
instead of being deleted.

There are many sample P4_16 programs in the
`$P4C/testdata/p4_16_samples/` directory, and a command like the one
above should work for all of them.  Some of the `<basename>.p4` files
have a corresponding `<basename>.stf` file in the same directory.  The
`.stf` files are a simple text file format parsed by
`run-bmv2-test.py` with packets to be sent in, packets to expect out
(which `run-bmv2-test.py` checks the actual output packets against the
expected ones, and reports any differences), and P4 table entries to
be added.

`run-bmv2-test.py` uses `p4c-bm2-ss` to compile P4_16 source files to
a bmv2 JSON configuration file, then runs `simple_switch` with the
`--use-files 0` command line option (among other options).
`--use-files 0` causes `simple_switch` to read packets from `.pcap`
files instead of sniffing them on virtual Ethernet interfaces, and to
write output packets to `.pcap` files.  This has 2 benefits:

+ There are separate pcap files for input vs. output packets, so it is
  easy for the test environment to distinguish input vs. output
  packets.  It is not obvious to me if it is possible to do this for
  packets sniffed on veth interfaces.

+ By default, Linux sends occasional IPv6 Neighbor Discovery packets
  to veth interfaces, which can throw off your `simple_switch` test
  results.  While there is some way to disable this behavior, Linux
  will not send such packets to pcap files.

To successfully take advantage of the `--use-files 0` option, you
still must specify interfaces on the `simple_switch` command line
using one or more `-i` options.  For example, if you use the option
`-i 0@pcap0`, then the P4 program port 0 will get input packets from
file `pcap0_in.pcap`, and write output packets to file
`pcap0_out.pcap`.

The packet out pcap files created by `simple_switch` are not Ethernet
type pcap files, the way that a pcap file captured from an Ethernet
interface using tcpdump or Wireshark is.  They are type 0, which is
shown as 'No link-layer encapsulation' from the output of the Linux
`file` command, and causes a warning like the one below when using
Scapy's `rdpcap` function to read the file:

```python
>>> pkts2=rdpcap('pcap0_out.pcap')
WARNING: PcapReader: unknown LL type [0]/[0x0]. Using Raw packets
```

If you want to change such a file (named `pcap0_out.pcap` in the
sample command below) to one with a link type of Ethernet, which makes
it more useful when reading into Wireshark, use a command like this:

```bash
editcap -F pcap -T ether pcap0_out.pcap pcap0_out_ether.pcap
```

From the output of the commands below, it appears that this also
changes the capture length from 0 to 262144.  A capture length of 0
seems to cause trouble for some programs that read pcap files, too.

```bash
% file pcap0_out.pcap
pcap0_out.pcap: tcpdump capture file (little-endian) - version 2.4 (No link-layer encapsulation, capture length 0)

% file pcap0_out_ether.pcap
pcap0_out_ether.pcap: tcpdump capture file (little-endian) - version 2.4 (Ethernet, capture length 262144)
```

The sample `scapy` interactive session below shows that the original
`pcap0_out.pcap` file contents are read in using Scapy's `rdpcap`
function as `Raw` packets, whereas the Scapy packet objects created
from reading file `pcap0_out_ether.pcap` are decoded as Ethernet
frames.  They also demonstrate that the packet contents after
converting them to strings with `str()` are the same byte sequences as
each other.

```python
[02:22:05] $ scapy
INFO: Can't import matplotlib. Won't be able to plot.
INFO: Can't import PyX. Won't be able to use psdump() or pdfdump().
WARNING: No route found for IPv6 destination :: (no default route?)
INFO: Can't import python Crypto lib. Won't be able to decrypt WEP.
INFO: Can't import python Crypto lib. Disabled certificate manipulation tools
INFO: Can't import python ecdsa lib. Disabled certificate manipulation tools
Welcome to Scapy (2.3.3)
>>> p1=rdpcap('pcap0_out.pcap')
WARNING: PcapReader: unknown LL type [0]/[0x0]. Using Raw packets
>>> type(p1[0])
<class 'scapy.packet.Raw'>
>>> p2=rdpcap('pcap0_out_ether.pcap')
>>> type(p2[0])
<class 'scapy.layers.l2.Ether'>
>>> p1[0]
<Raw  load="RT\x00\x125\x02\x08\x00'\x01\x8b\xbc\x08\x00E\x00\x00(\x00\x01\x00\x00?\x06e\xbb\n\x00\x02\x0f\n\x01\x00\x05\x16\xa2\x00P\x00\x00\x00\x00\x00\x00\x00\x00P\x02 \x00b\xe1\x00\x00" |>
>>> p2[0]
<Ether  dst=52:54:00:12:35:02 src=08:00:27:01:8b:bc type=0x800 |<IP  version=4L ihl=5L tos=0x0 len=40 id=1 flags= frag=0L ttl=63 proto=tcp chksum=0x65bb src=10.0.2.15 dst=10.1.0.5 options=[] |<TCP  sport=5794 dport=http seq=0 ack=0 dataofs=5L reserved=0L flags=S window=8192 chksum=0x62e1 urgptr=0 |>>>
>>> p1[0]==p2[0]
False
>>> str(p1[0])==str(p2[0])
True
>>> p1[1]==p2[1]
False
>>> str(p1[1])==str(p2[1])
True
```

There are many `.stf` files in the `$P4C/testdata/p4_16_samples/`
directory, but there are also many more `.p4` files that do not have a
corresponding `.stf` file in that directory.  For all of those, I
believe that the behavior of `run-bmv2-test.py` is to use the file
`empty.stf` in that directory instead.  In this case, I believe no
`simple_switch` process is started by `run-bmv2-test.py` - it just
compiles the source files and checks whether the compiler crashed,
gave errors or warnings, etc. (I believe - I have not gone through that
carefully yet).

After running `run-bmv2-test.py` with the options above, you should be
able to find a directory with a name like `tmpXXXXXX` where XXXXXX is
replaced with random-looking letters and digits, and that directory
should contain files created near the time you ran the command.  I saw
files with names like this:

+ issue447-5-bmv2.p4-stderr - From the name, probably the stderr
  output from running `simple_switch`.

+ pcap0_in.pcap - I know that `run-bmv2-test.py` creates the input
  pcap files read by `simple_switch` as named pipes with a `mkfifo`
  Python method, and I believe this file is a named pipe.  It has size
  0, even though packets were sent to `simple_switch`, I believe
  because it is a named pipe rather than a regular file.

+ pcap0_out.pcap - A sequence of packets sent out on port 0 by
  `simple_switch` process.  In general there can be more than one of
  these files, with the '0' replaced by the port number for each
  simulated Ethernet port.

+ switch.log.txt - The log file produced when you give the `--log-file
  switch.log --flush-log` options to the `simple_switch` command.  This
  is the same kinds of details you see on the console when you use the
  `--log-console` command line option to simple_switch, except written
  to a file instead.  It contains details about all packets received,
  processed, and sent, including every P4 table searched, the search
  key, whether the search result was a hit or miss, and if the search
  found a matching table entry, the action and action parameters for
  that matching entry, etc.
