# Introduction

The program `psa-example-drop-all.p4` is not quite the simplest P4_16
program for the PSA architecture, but it is close.

Its ingress parser extracts an Ethernet header, and then an IPv4
header if the Ethernet protocol is 0x0800.  Its ingress control block
does nothing at all, and its ingress deparser emits the two headers
that the ingress parser can extract.

Its egress parser extracts nothing, its egress control block does
nothing, and its egress deparser emits the ethernet and IPv4 headers,
although since the egress parser does nothing, they should always be
invalid, and those two emit statements will do nothing.


# Test results

Commit of https://github.com/p4lang/p4c last tested with:
5ae390430bd025b301854cd04c78b1ff9902180f 2019-Feb-20

Commit of https://github.com/p4lang/behavioral-model last tested with:
258341e1f4354bda3ec5c3710b405c19c81c31c1 2019-Feb-21

The command:
```bash
$ make compile
```

produced the output file `psa-example-drop-all.json`.  After that,
attempting to run the PSA version of BMv2 `psa_switch` using this
command produced the error message shown below:

```bash
$ make run
psa_switch --log-console -i 1@veth2 -i 2@veth4 psa-example-drop-all.json
Calling target program-options parser
Field standard_metadata.clone_spec is required by switch target but is not defined
Makefile:5: recipe for target 'run' failed
make: *** [run] Error 1
```

This is an error message produced by this line of behavioral-model
code:
https://github.com/p4lang/behavioral-model/blob/master/src/bm_sim/P4Objects.cpp#L2411-L2413

I believe that `psa_switch` and `simple_switch` are sharing this part
of their implementation right now, and it makes sense for
`simple_switch` implementing the v1model architecture to require that
the JSON file must have a field named `standard_metadata.clone_spec`.

However, whether such a field should be required for `psa_switch` JSON
input files is for the PSA implementers to decide.  I suspect it would
be best _not_ to require such a field to be present in the JSON input
file for `psa_switch`.  If any fields with particular names are
required to be present in the JSON input file for `psa_switch`, they
should be the names of PSA standard metadata fields defined in the PSA
specification, and `clone_spec` is not one of these.

As a quick hack, I created another file
`psa-example-drop-all.hand-edited3.json` that I copied and pasted a
definition of the v1model `standard_metadata` struct from the BMv2
JSON file for a simple_switch v1model program, just to see what might
go wrong next.  It starts up fine, but as soon as you send a packet in
for it to process, it crashes, I believe because like simple_switch it
is looking for a parser named "parser" in the JSON file, not
"ingress_parser" as I have changed it to.


# psa-indexed-counter.p4

`psa-indexed-counter.p4` is about the simplest PSA program one could
write that updates an (indexed) counter and drops all received
packets.  The choice of which counter index to update is based on the
least significant 8 bits of the Ethernet destination address.

`v1model-indexed-counter.p4` should behave the same way in processing
all packets, but is written for the v1model architecture.  I wrote it
because as of now, p4c produces more complete results for more v1model
architecture programs than it does for the PSA architecture.

Commit of https://github.com/p4lang/p4c used to create these files:
```
commit b79021f377e5e6689c30a697c12bdd55b0d8d713
Author: hemant-avatar3 <48018461+hemant-avatar3@users.noreply.github.com>
Date:   Tue Feb 26 13:30:27 2019 -0500
```

Commands run:
```
$ p4c-bm2-ss v1model-indexed-counter.p4 -o v1model-indexed-counter.json
$ p4c-bm2-psa psa-indexed-counter.p4 -o psa-indexed-counter.json
$ cp psa-indexed-counter.json psa-indexed-counter.hand-edited.json
```

I then hand-edited the file `psa-indexed-counter.hand-edited.json` to
add some content based on the v1model-indexed-counter.json file for
the ingress pipeline code to update the counter, because the original
`psa-indexed-counter.json` did nothing during ingress to update the
counter.  That is a bug in p4c-bm2-psa that should be fixed at some
point, but I have not attempted to analyze the cause.

Antonin Bas then created his own edited version of that, and the
result of his changes is called
`psa-indexed-counter.hand-edited.antonin.json`.  It shows the desired
additions to the `"extern_instances"` data.


# psa-unicast-or-drop.p4

This program is an even slightly simpler version of the
psa-example-hello-world.p4 program here:
https://github.com/p4lang/p4-spec/tree/master/p4-16/psa/examples

There is also a v1model version of the same program behavior, because
p4c's support for v1model is better than for PSA.

Commit of https://github.com/p4lang/p4c used to create these files:
```
commit b79021f377e5e6689c30a697c12bdd55b0d8d713
Author: hemant-avatar3 <48018461+hemant-avatar3@users.noreply.github.com>
Date:   Tue Feb 26 13:30:27 2019 -0500
```

Commands run:
```
$ p4c-bm2-ss v1model-unicast-or-drop.p4 -o v1model-unicast-or-drop.json
$ p4c-bm2-psa psa-unicast-or-drop.p4 -o psa-unicast-or-drop.json
```

## Creating and running an STF test for v1model-unicast-or-drop.p4

I believe that STF is an acronym for Simple Test Framework.

There are programs that are part of the `p4c` automated test suite
that, when you build `p4c` on that system, and then run the commands:

```
$ cd p4c/build
$ make check
```

will run over 1200 tests on nearly as many P4_14 and P4_16 programs.
The source code of the P4_14 programs are in the directory
`testdata/p4_14_samples`, and P4_16 programs in
`testdata/p4_16_samples`.

For most of these programs, the automated tests only include running
`p4c` on the source code, and then checking parts of the compiler
output, such as the error messages printed, and intermediate compiler
output files after it has run its front end and mid end passes.  Most
often, these compiler output files are compared to see if they are
identical to files stored in the `p4c` code repository, e.g. in
directories `testdata/p4_14_samples_outputs` and
`testdata/p4_16_samples_outputs`.

These tests are useful, in that they do exercise a significant portion
of `p4c`'s functionality, and check that it is behaving as expected.
However, for those P4 programs that include all of the pieces needed
to run on a P4-programmable switch device, what those tests do _not_
check is: does the compiled version of the program behave as it
should?

Some of the test programs are accompanies by another file that has the
same name, except the suffix `.p4` is replaced with `.stf`.  For these
P4 programs, if you have earlier installed BMv2 `simple_switch` on the
system, then not only is the P4 program compiled, but it is also
executed using `simple_switch`, and exercised as follows:

+ Create entries in P4 tables (optional)
+ Make other kinds of runtime configurations e.g. create mirror/clone
  sessions, or assign lists of output ports to multicast configuration
  groups (optional)
+ Send packets with contents specified in the STF file into the switch
  input port numbers, also specified in the file.
+ Record any packets sent by the switch to its output ports.  For each
  one, compare its contents against the expected contents specified in
  the STF file.
+ If there are any mismatches in packets that are sent out by the
  switch vs. what is expected, including any extra or missing packets,
  the test fails.

The `.stf` file is a text file in a relatively simple format, read by
a Python program.  I will start with an example that only contains
lines that describe packets to send in to the switch, and lines that
describe the contents of packets expected to be sent out by the
switch.

To describe a packet to send in to the switch, use a line like this:

```
packet <port_number> <packet data in hexadecimal digits and optional spaces>
```

An expected packet is the same syntax, except with `packet` replaced
with `expect`.

Here are the contents of a few simple test packets for the program
`v1model-unicast-or-drop.p4`.  It does not ever change the contents of
packets.  It either sends the packet as received out of the port
number that is the least significant 2 bits of the destination
Ethernet address, unless those 2 bits are 0, in which case it drops
the packet.

This simple set of packet tests tries packets with all 4 possible
values for the least significant 2 bits of the Ethernet destination
address.

Blank lines are ignored, as are comments starting with a `#`
character, continuing up to the end of the line.

```
packet 4 000000000001 000000000000 ffff
expect 1 000000000001 000000000000 ffff

packet 4 000000000002 000000000000 ffff
expect 2 000000000002 000000000000 ffff

packet 4 000000000003 000000000000 ffff
expect 3 000000000003 000000000000 ffff

# This packet should be dropped
packet 2 000000000000 000000000000 ffff
```

I am assuming you have created a clone of this repository on your
local machine: https://github.com/p4lang/p4c repository in the
directory p4c, and you have already installed `simple_switch`.  If you
have not done this, you can do so with one of the install scripts
described
[here](https://github.com/jafingerhut/p4-guide/blob/master/bin/README-install-troubleshooting.md).

These are the commands to build `p4c` from source code for the first
time, assuming you have all of the necessary dependencies installed
first.

```
$ cd p4c
$ mkdir build
$ cd build
$ cmake .. -DCMAKE_BUILD_TYPE=DEBUG
$ make -j3
```

Copy the program `v1model-unicast-or-drop.p4` to the directory
`p4c/testdata/p4_16_samples` but change its name to
`v1model-unicast-or-drop-bmv2.p4`.  The test infrastructure will only
run the STF test if there is an `.stf` file, but also only if the
program's name ends with `-bmv2.p4`, not merely `.p4`.

Create a file in that same directory named
`v1model-unicast-or-drop-bmv2.stf` with the same STF contents above.

The `cmake` command is the one that creates the small test scripts, so
if you have already built `p4c` from source code, and have not made
any changes to its source code, you can cause the test scripts to be
created again with only these commands, which is significantly faster:

```
$ cd p4c/build
$ cmake .. -DCMAKE_BUILD_TYPE=DEBUG
```

One way to find the name of the test script for the program and STF
file you added above is this:

```
$ find . | grep v1model-unicast-or-drop
./bmv2/testdata/p4_16_samples/v1model-unicast-or-drop-bmv2.p4.test
./p4/testdata/p4_16_samples/v1model-unicast-or-drop-bmv2.p4.test
```

You can copy and paste either of those path names as a command to run.
They are executable scripts.  The second one only runs the P4 compiler
on the code.  The first compiles the code and run BMv2
`simple_switch`.

Below is sample output when there are no failures:
```
$ ./bmv2/testdata/p4_16_samples/v1model-unicast-or-drop-bmv2.p4.testCheck for  /home/jafinger/p4c/testdata/p4_16_samples/v1model-unicast-or-drop-bmv2.stf
Calling target program-options parser
Adding interface pcap1 as port 1 (files)
Adding interface pcap2 as port 2 (files)
Adding interface pcap3 as port 3 (files)
Adding interface pcap4 as port 4 (files)
Obtaining JSON from switch...
Done
Control utility for runtime P4 table manipulation
RuntimeCmd: 
WARNING: PcapReader: unknown LL type [0]/[0x0]. Using Raw packets
WARNING: PcapReader: unknown LL type [0]/[0x0]. Using Raw packets
WARNING: more PcapReader: unknown LL type [0]/[0x0]. Using Raw packets
```

You can edit the STF file to make a test that should fail.  For
example, in the first expect line, change any of the hex digits for
the contents of the expected output packet.  I changed this line:

```
expect 1 000000000001 000000000000 ffff
```

to this:

```
expect 1 200000000001 000000000000 ffff
```

You can then run the test script again and see what a failure looks
like, with some error messages briefly describing why it failed:

```
$ ./bmv2/testdata/p4_16_samples/v1model-unicast-or-drop-bmv2.p4.test
Check for  /home/jafinger/p4c/testdata/p4_16_samples/v1model-unicast-or-drop-bmv2.stf
Calling target program-options parser
Adding interface pcap1 as port 1 (files)
Adding interface pcap2 as port 2 (files)
Adding interface pcap3 as port 3 (files)
Adding interface pcap4 as port 4 (files)
Obtaining JSON from switch...
Done
Control utility for runtime P4 table manipulation
RuntimeCmd: 
WARNING: PcapReader: unknown LL type [0]/[0x0]. Using Raw packets
WARNING: PcapReader: unknown LL type [0]/[0x0]. Using Raw packets
WARNING: more PcapReader: unknown LL type [0]/[0x0]. Using Raw packets
*** Received packet  000000000001000000000000FFFF
*** Packet different at position 0 : expected 2 , received 0
*** Full expected packet is  200000000001000000000000FFFF
*** Full received packet is  000000000001000000000000FFFF
*** Packet 0 on port 1 differs
*** Test failed
```
