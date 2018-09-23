Program: resubmit-maybe-violates-p416-spec.p4

This program was created as a fairly short one that demonstrates the
behavior asked about in this issue:
https://github.com/p4lang/p4c/issues/1514

No table entries need to be added for this simple test program.

    p4c --target bmv2 --arch v1model resubmit-maybe-violates-p416-spec.p4

    sudo simple_switch --log-console -i 0@veth2 -i 1@veth4 -i 2@veth6 -i 3@veth8 -i 4@veth10 -i 5@veth12 -i 6@veth14 -i 7@veth16 resubmit-maybe-violates-p416-spec.json

The contents of a test packet sent in shouldn't matter much, although
at least a complete Ethernet header is probably best.

```
sudo scapy

resub_pkt=Ether() / IP() / TCP()
sendp(resub_pkt, iface="veth2")
```

The log messages appearing on the simple_switch output when sending
the packet above are copied below, using latest version of p4c and
behavioral-model as of 2018-Sep-22.

Highlights:

+ The packet arrives from port 0 and is parsed without error.
+ At beginning of ingress, egress_spec is 0:
```
* stdmeta.ingress_port            : 0000
* stdmeta.egress_spec             : 0000
* stdmeta.instance_type           : 00000000
```

+ The first `if` statement condition in ingress is false, because
  packet is new from port, not a resubmitted packet.
+ egress_spec assigned the value 1.
+ resubmit() is called *when egress_spec is 1*.
+ resubmit_invoked is assigned true
+ Second `if` statement condition `resubmit_invoked` in ingress is
  true.  egress_spec assigned the value 5
+ Packet finishes ingress processing.  It is resubmitted.

+ Parsing occurs again, same as before.

+ The debug table at beginning of ingress shows these values.  NOTE:
  *egress_spec is 5*, the value it had during the first time through
  ingress at *the end* of ingress processing, not 1, the value it had at
  the time the resubmit() operation was called.  instance_type 6 is
  expected, as that is the value that v1model uses to indicate the
  packet is a resubmitted one, not a new one from an input port.
```
* stdmeta.egress_spec             : 0005
* stdmeta.instance_type           : 00000006
```

All of the steps after this point are expected, given the current
value of egress_spec of 5.

+ First `if` statement condition in ingress is true, because packet is
  is resubmitted.
+ Assign resubmit_invoked=false.
+ Second `if` statement condition `resubmit_invoked` in ingress is
  false.  Nothing to do there.
+ Packet ends ingress with egress_spec value of 5, as expected since
  it began with that value, and no assignments were made to it.
+ Packet goes to packet buffer, then to egress processing with
  egress_port=5.  Packet finishes egress processing and goes out port
  5.


```
[23:18:13.591] [bmv2] [D] [thread 31232] [0.0] [cxt 0] Processing packet received on port 0
[23:18:13.591] [bmv2] [D] [thread 31232] [0.0] [cxt 0] Parser 'parser': start
[23:18:13.591] [bmv2] [D] [thread 31232] [0.0] [cxt 0] Parser 'parser' entering state 'start'
[23:18:13.591] [bmv2] [D] [thread 31232] [0.0] [cxt 0] Extracting header 'ethernet'
[23:18:13.591] [bmv2] [D] [thread 31232] [0.0] [cxt 0] Parser state 'start': key is 0800
[23:18:13.591] [bmv2] [T] [thread 31232] [0.0] [cxt 0] Bytes parsed: 14
[23:18:13.591] [bmv2] [D] [thread 31232] [0.0] [cxt 0] Parser 'parser' entering state 'parse_ipv4'
[23:18:13.591] [bmv2] [D] [thread 31232] [0.0] [cxt 0] Extracting header 'ipv4'
[23:18:13.591] [bmv2] [D] [thread 31232] [0.0] [cxt 0] Parser state 'parse_ipv4' has no switch, going to default next state
[23:18:13.591] [bmv2] [T] [thread 31232] [0.0] [cxt 0] Bytes parsed: 34
[23:18:13.591] [bmv2] [D] [thread 31232] [0.0] [cxt 0] Parser 'parser': end
[23:18:13.591] [bmv2] [D] [thread 31232] [0.0] [cxt 0] Pipeline 'ingress': start
[23:18:13.591] [bmv2] [T] [thread 31232] [0.0] [cxt 0] Applying table 'ingress.debug_tables_ingress_start.dbg_table'
[23:18:13.591] [bmv2] [D] [thread 31232] [0.0] [cxt 0] Looking up key:
* stdmeta.ingress_port            : 0000
* stdmeta.egress_spec             : 0000
* stdmeta.egress_port             : 0000
* stdmeta.clone_spec              : 00000000
* stdmeta.instance_type           : 00000000
* stdmeta.drop                    : 00
* stdmeta.recirculate_port        : 0000
* stdmeta.packet_length           : 00000044
* stdmeta.enq_timestamp           : 00000000
* stdmeta.enq_qdepth              : 000000
* stdmeta.deq_timedelta           : 00000000
* stdmeta.deq_qdepth              : 000000
* stdmeta.ingress_global_timestamp: 0000031d0652
* stdmeta.egress_global_timestamp : 000000000000
* stdmeta.lf_field_list           : 00000000
* stdmeta.mcast_grp               : 0000
* stdmeta.resubmit_flag           : 00000000
* stdmeta.egress_rid              : 0000
* stdmeta.checksum_error          : 00
* stdmeta.recirculate_flag        : 00000000
* hdr.ipv4.srcAddr                : 7f000001
* hdr.ipv4.dstAddr                : 7f000001

[23:18:13.591] [bmv2] [D] [thread 31232] [0.0] [cxt 0] Table 'ingress.debug_tables_ingress_start.dbg_table': miss
[23:18:13.591] [bmv2] [D] [thread 31232] [0.0] [cxt 0] Action entry is NoAction - 
[23:18:13.591] [bmv2] [T] [thread 31232] [0.0] [cxt 0] Action NoAction
[23:18:13.591] [bmv2] [T] [thread 31232] [0.0] [cxt 0] resubmit-maybe-violates-p416-spec.p4(132) Condition "stdmeta.instance_type == PKT_INSTANCE_TYPE_RESUBMIT" (node_3) is false
[23:18:13.591] [bmv2] [T] [thread 31232] [0.0] [cxt 0] Applying table 'tbl_act_0'
[23:18:13.591] [bmv2] [D] [thread 31232] [0.0] [cxt 0] Looking up key:

[23:18:13.591] [bmv2] [D] [thread 31232] [0.0] [cxt 0] Table 'tbl_act_0': miss
[23:18:13.591] [bmv2] [D] [thread 31232] [0.0] [cxt 0] Action entry is act_0 - 
[23:18:13.591] [bmv2] [T] [thread 31232] [0.0] [cxt 0] Action act_0
[23:18:13.591] [bmv2] [T] [thread 31232] [0.0] [cxt 0] resubmit-maybe-violates-p416-spec.p4(141) Primitive stdmeta.egress_spec = 1
[23:18:13.591] [bmv2] [T] [thread 31232] [0.0] [cxt 0] Primitive (no source info)
[23:18:13.591] [bmv2] [T] [thread 31232] [0.0] [cxt 0] resubmit-maybe-violates-p416-spec.p4(147) Primitive resubmit_invoked = true
[23:18:13.591] [bmv2] [T] [thread 31232] [0.0] [cxt 0] resubmit-maybe-violates-p416-spec.p4(149) Condition "resubmit_invoked" (node_6) is true
[23:18:13.591] [bmv2] [T] [thread 31232] [0.0] [cxt 0] Applying table 'tbl_act_1'
[23:18:13.591] [bmv2] [D] [thread 31232] [0.0] [cxt 0] Looking up key:

[23:18:13.591] [bmv2] [D] [thread 31232] [0.0] [cxt 0] Table 'tbl_act_1': miss
[23:18:13.591] [bmv2] [D] [thread 31232] [0.0] [cxt 0] Action entry is act_1 - 
[23:18:13.591] [bmv2] [T] [thread 31232] [0.0] [cxt 0] Action act_1
[23:18:13.592] [bmv2] [T] [thread 31232] [0.0] [cxt 0] resubmit-maybe-violates-p416-spec.p4(150) Primitive stdmeta.egress_spec = 5
[23:18:13.592] [bmv2] [T] [thread 31232] [0.0] [cxt 0] Applying table 'ingress.debug_tables_ingress_end.dbg_table'
[23:18:13.592] [bmv2] [D] [thread 31232] [0.0] [cxt 0] Looking up key:
* stdmeta.ingress_port            : 0000
* stdmeta.egress_spec             : 0005
* stdmeta.egress_port             : 0000
* stdmeta.clone_spec              : 00000000
* stdmeta.instance_type           : 00000000
* stdmeta.drop                    : 00
* stdmeta.recirculate_port        : 0000
* stdmeta.packet_length           : 00000044
* stdmeta.enq_timestamp           : 00000000
* stdmeta.enq_qdepth              : 000000
* stdmeta.deq_timedelta           : 00000000
* stdmeta.deq_qdepth              : 000000
* stdmeta.ingress_global_timestamp: 0000031d0652
* stdmeta.egress_global_timestamp : 000000000000
* stdmeta.lf_field_list           : 00000000
* stdmeta.mcast_grp               : 0000
* stdmeta.resubmit_flag           : 00000001
* stdmeta.egress_rid              : 0000
* stdmeta.checksum_error          : 00
* stdmeta.recirculate_flag        : 00000000
* hdr.ipv4.srcAddr                : 7f000001
* hdr.ipv4.dstAddr                : 7f000001

[23:18:13.592] [bmv2] [D] [thread 31232] [0.0] [cxt 0] Table 'ingress.debug_tables_ingress_end.dbg_table': miss
[23:18:13.592] [bmv2] [D] [thread 31232] [0.0] [cxt 0] Action entry is NoAction - 
[23:18:13.592] [bmv2] [T] [thread 31232] [0.0] [cxt 0] Action NoAction
[23:18:13.592] [bmv2] [D] [thread 31232] [0.0] [cxt 0] Pipeline 'ingress': end
[23:18:13.592] [bmv2] [D] [thread 31232] [0.0] [cxt 0] Resubmitting packet
[23:18:13.592] [bmv2] [D] [thread 31232] [0.1] [cxt 0] Processing packet received on port 0
[23:18:13.592] [bmv2] [D] [thread 31232] [0.1] [cxt 0] Parser 'parser': start
[23:18:13.592] [bmv2] [D] [thread 31232] [0.1] [cxt 0] Parser 'parser' entering state 'start'
[23:18:13.592] [bmv2] [D] [thread 31232] [0.1] [cxt 0] Extracting header 'ethernet'
[23:18:13.592] [bmv2] [D] [thread 31232] [0.1] [cxt 0] Parser state 'start': key is 0800
[23:18:13.592] [bmv2] [T] [thread 31232] [0.1] [cxt 0] Bytes parsed: 14
[23:18:13.592] [bmv2] [D] [thread 31232] [0.1] [cxt 0] Parser 'parser' entering state 'parse_ipv4'
[23:18:13.592] [bmv2] [D] [thread 31232] [0.1] [cxt 0] Extracting header 'ipv4'
[23:18:13.592] [bmv2] [D] [thread 31232] [0.1] [cxt 0] Parser state 'parse_ipv4' has no switch, going to default next state
[23:18:13.592] [bmv2] [T] [thread 31232] [0.1] [cxt 0] Bytes parsed: 34
[23:18:13.592] [bmv2] [D] [thread 31232] [0.1] [cxt 0] Parser 'parser': end
[23:18:13.592] [bmv2] [D] [thread 31232] [0.1] [cxt 0] Pipeline 'ingress': start
[23:18:13.592] [bmv2] [T] [thread 31232] [0.1] [cxt 0] Applying table 'ingress.debug_tables_ingress_start.dbg_table'
[23:18:13.592] [bmv2] [D] [thread 31232] [0.1] [cxt 0] Looking up key:
* stdmeta.ingress_port            : 0000
* stdmeta.egress_spec             : 0005
* stdmeta.egress_port             : 0000
* stdmeta.clone_spec              : 00000000
* stdmeta.instance_type           : 00000006
* stdmeta.drop                    : 00
* stdmeta.recirculate_port        : 0000
* stdmeta.packet_length           : 00000044
* stdmeta.enq_timestamp           : 00000000
* stdmeta.enq_qdepth              : 000000
* stdmeta.deq_timedelta           : 00000000
* stdmeta.deq_qdepth              : 000000
* stdmeta.ingress_global_timestamp: 0000031d0652
* stdmeta.egress_global_timestamp : 000000000000
* stdmeta.lf_field_list           : 00000000
* stdmeta.mcast_grp               : 0000
* stdmeta.resubmit_flag           : 00000000
* stdmeta.egress_rid              : 0000
* stdmeta.checksum_error          : 00
* stdmeta.recirculate_flag        : 00000000
* hdr.ipv4.srcAddr                : 7f000001
* hdr.ipv4.dstAddr                : 7f000001

[23:18:13.592] [bmv2] [D] [thread 31232] [0.1] [cxt 0] Table 'ingress.debug_tables_ingress_start.dbg_table': miss
[23:18:13.592] [bmv2] [D] [thread 31232] [0.1] [cxt 0] Action entry is NoAction - 
[23:18:13.592] [bmv2] [T] [thread 31232] [0.1] [cxt 0] Action NoAction
[23:18:13.592] [bmv2] [T] [thread 31232] [0.1] [cxt 0] resubmit-maybe-violates-p416-spec.p4(132) Condition "stdmeta.instance_type == PKT_INSTANCE_TYPE_RESUBMIT" (node_3) is true
[23:18:13.592] [bmv2] [T] [thread 31232] [0.1] [cxt 0] Applying table 'tbl_act'
[23:18:13.593] [bmv2] [D] [thread 31232] [0.1] [cxt 0] Looking up key:

[23:18:13.593] [bmv2] [D] [thread 31232] [0.1] [cxt 0] Table 'tbl_act': miss
[23:18:13.593] [bmv2] [D] [thread 31232] [0.1] [cxt 0] Action entry is act - 
[23:18:13.593] [bmv2] [T] [thread 31232] [0.1] [cxt 0] Action act
[23:18:13.593] [bmv2] [T] [thread 31232] [0.1] [cxt 0] resubmit-maybe-violates-p416-spec.p4(137) Primitive resubmit_invoked = false
[23:18:13.593] [bmv2] [T] [thread 31232] [0.1] [cxt 0] resubmit-maybe-violates-p416-spec.p4(149) Condition "resubmit_invoked" (node_6) is false
[23:18:13.593] [bmv2] [T] [thread 31232] [0.1] [cxt 0] Applying table 'ingress.debug_tables_ingress_end.dbg_table'
[23:18:13.593] [bmv2] [D] [thread 31232] [0.1] [cxt 0] Looking up key:
* stdmeta.ingress_port            : 0000
* stdmeta.egress_spec             : 0005
* stdmeta.egress_port             : 0000
* stdmeta.clone_spec              : 00000000
* stdmeta.instance_type           : 00000006
* stdmeta.drop                    : 00
* stdmeta.recirculate_port        : 0000
* stdmeta.packet_length           : 00000044
* stdmeta.enq_timestamp           : 00000000
* stdmeta.enq_qdepth              : 000000
* stdmeta.deq_timedelta           : 00000000
* stdmeta.deq_qdepth              : 000000
* stdmeta.ingress_global_timestamp: 0000031d0652
* stdmeta.egress_global_timestamp : 000000000000
* stdmeta.lf_field_list           : 00000000
* stdmeta.mcast_grp               : 0000
* stdmeta.resubmit_flag           : 00000000
* stdmeta.egress_rid              : 0000
* stdmeta.checksum_error          : 00
* stdmeta.recirculate_flag        : 00000000
* hdr.ipv4.srcAddr                : 7f000001
* hdr.ipv4.dstAddr                : 7f000001

[23:18:13.593] [bmv2] [D] [thread 31232] [0.1] [cxt 0] Table 'ingress.debug_tables_ingress_end.dbg_table': miss
[23:18:13.593] [bmv2] [D] [thread 31232] [0.1] [cxt 0] Action entry is NoAction - 
[23:18:13.593] [bmv2] [T] [thread 31232] [0.1] [cxt 0] Action NoAction
[23:18:13.593] [bmv2] [D] [thread 31232] [0.1] [cxt 0] Pipeline 'ingress': end
[23:18:13.593] [bmv2] [D] [thread 31232] [0.1] [cxt 0] Egress port is 5
[23:18:13.593] [bmv2] [D] [thread 31234] [0.1] [cxt 0] Pipeline 'egress': start
[23:18:13.593] [bmv2] [T] [thread 31234] [0.1] [cxt 0] Applying table 'egress.debug_tables_egress_start.dbg_table'
[23:18:13.593] [bmv2] [D] [thread 31234] [0.1] [cxt 0] Looking up key:
* stdmeta.ingress_port            : 0000
* stdmeta.egress_spec             : 0000
* stdmeta.egress_port             : 0005
* stdmeta.clone_spec              : 00000000
* stdmeta.instance_type           : 00000006
* stdmeta.drop                    : 00
* stdmeta.recirculate_port        : 0000
* stdmeta.packet_length           : 6570735f
* stdmeta.enq_timestamp           : 031d0f4a
* stdmeta.enq_qdepth              : 000000
* stdmeta.deq_timedelta           : 00000079
* stdmeta.deq_qdepth              : 000000
* stdmeta.ingress_global_timestamp: 0000031d0652
* stdmeta.egress_global_timestamp : 0000031d0fbf
* stdmeta.lf_field_list           : 00000000
* stdmeta.mcast_grp               : 0000
* stdmeta.resubmit_flag           : 00000000
* stdmeta.egress_rid              : 0000
* stdmeta.checksum_error          : 00
* stdmeta.recirculate_flag        : 00000000
* hdr.ipv4.srcAddr                : 7f000001
* hdr.ipv4.dstAddr                : 7f000001

[23:18:13.593] [bmv2] [D] [thread 31234] [0.1] [cxt 0] Table 'egress.debug_tables_egress_start.dbg_table': miss
[23:18:13.593] [bmv2] [D] [thread 31234] [0.1] [cxt 0] Action entry is NoAction - 
[23:18:13.593] [bmv2] [T] [thread 31234] [0.1] [cxt 0] Action NoAction
[23:18:13.593] [bmv2] [D] [thread 31234] [0.1] [cxt 0] Pipeline 'egress': end
[23:18:13.593] [bmv2] [D] [thread 31234] [0.1] [cxt 0] Deparser 'deparser': start
[23:18:13.593] [bmv2] [D] [thread 31234] [0.1] [cxt 0] Deparsing header 'ethernet'
[23:18:13.593] [bmv2] [D] [thread 31234] [0.1] [cxt 0] Deparsing header 'ipv4'
[23:18:13.593] [bmv2] [D] [thread 31234] [0.1] [cxt 0] Deparser 'deparser': end
[23:18:13.593] [bmv2] [D] [thread 31237] [0.1] [cxt 0] Transmitting packet of size 68 out of port 5
```
