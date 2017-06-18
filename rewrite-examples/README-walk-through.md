One example sequential flow through the program, which can help see
what happens to a single packet, is to consider the case where a
program receives a packet that looks like this:

    Ethernet + IPv4 + payload

The control plane sets up the table contents so that the following
packet should be sent out:

    outer_Ethernet + outer_IPv4 + outer_GRE + IPv4 + payload

with correct length and checksum fields.  The received Ethernet header
should be discarded.

In this case, the flow of control through the program
rewrite-examples.p4 would be as follows:

(1) parser ParserImpl - parses the Ethernet + IPv4 headers in the
received packet, making the variables hdr.ethernet and hdr.ipv4 valid,
and their fields values defined and filled in with the values in the
header of the received packet.

(2) ingress control block - I have deleted all of the switch.p4 code
from this control block, to make a smaller example program that
focuses on rewrite.

(3) egress control block - calls process_tunnel_encap control block

(4) process_tunnel_encap block - look at the 'apply { ... }' block to
see the sequential steps below.

(5) tunnel_encap_process_inner.apply() - The P4 source code doesn't
tell you what table entries the control plane would put in, but in
this case a reasonable thing for the control plane to add would be "if
the hdr.ipv4 header is valid, then invoke action
'inner_ipv4_rewrite'".

(6) action inner_ipv4_rewrite - this just saves the hdr.ipv4.totalLen
field in a metadata field for the length of the packet being
encapsulated.  It is filled in differently in other actions, depending
upon the type of the inner packet.  It also remembers the inner packet
is IPv4.

(7) tunnel_encap_process_outer.apply() - Assume the control plane has
added an entry that matches the 'meta.tunnel.egress_tunnel_type' of
the packet, which is some #define'd integer that is like an enum,
indicating that the ipv4_gre_rewrite action should be invoked.

(8) action ipv4_gre_rewrite - calls action f_insert_gre_header that
makes 'hdr.outer_gre' valid, and initializes most of that header's
fields.  Then calls f_insert_ipv4_header that makes 'hdr.outer_ipv4'
valid and initializes most of its fields.  Then action
ipv4_gre_rewrite initializes the fields of those headers that were not
initialized yet, as well as hdr.outer_ethernet.  Any fields not
initialized here will be filled in by later code.

(9) tunnel_rewrite.apply() - assume the control plane has added an
entry to match the 'meta.tunnel.tunnel_index' value of this packet,
which would have been initialized earlier if this program were a bit
more complete, e.g. from the result of a FIB lookup.  It calls the
action set_tunnel_rewrite_details.

(10) action set_tunnel_rewrite_details remembers an index for later
table lookups that will get the full Ethernet SA and DA, and IPv4 SA
and DA.

(11) tunnel_mtu.apply() - the MTU code here is incomplete, in that it
doesn't actually do any sending of too-large packets to a control CPU
for fragmentation, but it could do that.  I will skip that here.

(12) tunnel_src_rewrite.apply() - looks up an index determined in step
(10) to fill in the IPv4 SA.

(13) tunnel_dst_rewrite.apply() - similar to (12) but for filling in
IPv4 DA.

(14) tunnel_smac_rewrite.apply() - ditto, but for Ethernet SA

(15) tunnel_dmac_rewrite.apply() - ditto, but for Ethernet SA

Note: all of steps (10) through (15) could be done in one P4 table,
with an action that fills in all of those fields.  The extra levels of
indirection can be useful to make the SA lookup tables smaller than
the DA lookup tables, for example, and reduce table sizes.  This is a
design choice for the P4 program writer.  It can certainly be done in
multiple different ways that all give the same "packet in to packet
out" behavior.

(16) control computeChecksum - this is done after the egress control
block, just before the deparser.  It calculates whatever checksums you
want in the outgoing headers.  In this case, it calculates a fresh
correct checksum for any valid IPv4 headers in the outgoing packet.

(17) control DeparserImpl - the packet.emit() method on a header
checks whether the header is valid.  If not, the emit() call is a no
op.  If the header is valid, then its contents are appended to the
output packet being constructed.  Most of these headers would be
invalid in this example.



If you wanted to add 'raw bytes' encapsulation to the packet, without
any special length or checksums needed that varies from packet to
packet, one way to do that is shown in the headers and actions that
contain the string 'generic_20' and also 'generic_28' and
'generic_40'.  The header would be filled in at step (7), with a
different action than the 'ipv4_gre_rewrite' mentioned in the example
above.
