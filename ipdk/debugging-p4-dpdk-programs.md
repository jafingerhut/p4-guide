# Notes on debugging P4 programs on the DPDK software switch

If you have used the BMv2 software switch before, i.e. the processes
called `simple_switch` or `simple_switch_grpc` compiled from source
code in this repository:

+ https://github.com/p4lang/behavioral-model

then you may have debugged P4 programs running on BMv2 by enabling
logging, e.g. via the `--log-console` or `--log-file` command line
options, and/or by adding `log_msg` extern function calls in the P4
program.

As of 2024-Feb-02, there is nothing like this available for debugging
of P4 programs running on the DPDK software switch.

As of this time, the best option available is to modify your P4
program in order to make key information that you care about for
learning the behavior of your program visible to you.  Some available
choices of making your program behavior visible are:

+ Change the output packet(s) in a way that makes it obvious which
  branches were taken in your code, or key intermediate values
  calculated inside your P4 code that you wish to observe.
  + One example of this can be seen in the program `add_on_miss0.p4`,
    where the P4 code assigns one numeric value to the least
    significant 8 bits of the packet's source Ethernet address if a
    table named `ct_tcp_table` gets a hit on a lookup, but assigns a
    different numeric value to those 8 bits if that table gets a miss
    on a lookup.  When you or some software observes the packets
    output by the DPDK software switch, you can look at those 8 bits
    of the source MAC address to learn whether that table lookup got a
    hit or a miss while processing that packet.
+ Update externs in your P4 program whose state can be read by control
  plane software after the packet has been processed, e.g.
  + Update P4 counters differently in different branches of your code.
  + Write to P4 register extern entries differently in different
    branches of your code, and/or write intermediate calculated values
    of header fields or metadata fields of interest to you into
    register entries.

Perhaps in the future other debugging options will be developed for P4
programs running on the DPDK software switch, but these are the best
known methods at present.
