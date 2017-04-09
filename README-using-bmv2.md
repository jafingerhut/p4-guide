Clone the p4lang git repositories named below and follow their README
build/install instructions.

From following install instructions for `p4lang/behavioral-model`
repository, all of these should exist in /usr/local/bin:

    bm_CLI
    bm_nanomsg_events
    bm_p4dbg
    simple_switch
    simple_switch_CLI

From following install instructions for `p4lang/p4c-bm` repository,
this should exist in /usr/local/bin:

    p4c-bmv2

Note: p4c-bmv2 only compiles P4_14 programs.  p4c-bm2-ss below can
compile P4_14 or P4_16 programs, but it is still somewhere around
alpha or beta readiness as of April 2017, so you may want to stick
with p4c-bmv2 for P4_14 programs until p4c catches up on features,
probably by May 2017 or soon afterwards.

From following install instructions for `p4lang/p4c` repository, these
should exist in `$P4C/build`, where `P4C` is a shell varaible
containing the path to your copy of the `p4lang/p4c` repository.

    p4c-bm2-ss

It can be convenient to have all of these commands in your shell's
command path, e.g. for bash:

    P4C=/path/to/your/copy/of/p4c
    export PATH=$P4C/build:/usr/local/bin:$PATH

    BMV2=/path/to/your/copy/of/behavioral-model

To create veth interfaces:

    sudo $BMV2/tools/veth_setup.sh
    # Verify that it created many veth<number> interfaces
    ifconfig | grep ^veth

To watch packets cross veth2 and veth4 as they occur:

    # tcpdump options used:
    # -e Print the link-level header (i.e. Ethernet) on each dump line.
    # -n Don't convert addresses to names
    # --number Print an optional packet number at the beginning of the line.
    # -v slightly more verbose output, e.g. TTL values

    # Note: Some versions of tcpdump do not accept the --number
    # option.  If so, just remove that one.
    sudo tcpdump -e -n --number -v -i veth2
    sudo tcpdump -e -n --number -v -i veth4

    # Add -xx option to get raw hex dump of packet data:
    sudo tcpdump -xx -e -n --number -v -i veth2
    sudo tcpdump -xx -e -n --number -v -i veth4

    # If you want to use tshark for even more details about decoded
    # packets, but the output for each packet can often spread over 30
    # to 40 lines:
    sudo tshark -V -i veth2
    sudo tshark -V -i veth4

    # Add -x option to get raw hex dump of packet data:
    sudo tshark -x -V -i veth2
    sudo tshark -x -V -i veth4
